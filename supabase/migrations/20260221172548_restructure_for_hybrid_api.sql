-- ============================================================
-- Migration: Restructure schema for hybrid API architecture
-- ============================================================
-- Supabase = dumb infrastructure (auth, DB, storage, realtime)
-- API = all business logic
--
-- What this migration does:
--   1. Drop old functions, triggers, enums (business logic → API)
--   2. Drop old tables that are being replaced
--   3. Alter users table (add created_at)
--   4. Create card_templates (replaces Hygraph CMS)
--   5. Recreate greeting_cards (new schema with template FK)
--   6. Create card_sends (delivery events, replaces old message-based flow)
--   7. Recreate conversations (simplified, no last_message_id)
--   8. Recreate conversation_participants
--   9. Recreate messages (simplified, references card_sends)
--  10. Add indexes
--  11. Enable RLS + policies (defense in depth)
--  12. Set up realtime
--  13. Create storage buckets
--  14. Recreate handle_new_user trigger (the one keeper)
-- ============================================================

BEGIN;

-- ============================================================
-- 1. DROP OLD TRIGGERS
-- ============================================================

DROP TRIGGER IF EXISTS trigger_update_conversation_on_message ON messages;

-- ============================================================
-- 2. DROP OLD FUNCTIONS (business logic moves to API)
-- ============================================================

DROP FUNCTION IF EXISTS find_or_create_conversation;
DROP FUNCTION IF EXISTS find_or_create_user_by_phone;
DROP FUNCTION IF EXISTS get_conversation_messages;
DROP FUNCTION IF EXISTS get_user_conversations;
DROP FUNCTION IF EXISTS handle_delete_user;
DROP FUNCTION IF EXISTS update_conversation_on_message_insert;

-- Keep handle_new_user — we'll recreate it below with the updated schema

-- ============================================================
-- 3. DROP OLD TABLES (order matters for FK deps)
-- ============================================================

DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS conversation_participants CASCADE;
DROP TABLE IF EXISTS conversations CASCADE;
DROP TABLE IF EXISTS greeting_cards CASCADE;

-- ============================================================
-- 4. DROP OLD ENUMS
-- ============================================================

DROP TYPE IF EXISTS delivery_status;
DROP TYPE IF EXISTS message_type;

-- ============================================================
-- 5. ALTER USERS TABLE
-- ============================================================
-- Add created_at if missing. Keep existing columns.

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'created_at'
    ) THEN
        ALTER TABLE users ADD COLUMN created_at TIMESTAMPTZ NOT NULL DEFAULT now();
    END IF;
END $$;

-- ============================================================
-- 6. CREATE card_templates (replaces Hygraph CMS)
-- ============================================================

CREATE TABLE card_templates (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title        TEXT NOT NULL,
    subtitle     TEXT,
    description  TEXT,
    category     TEXT NOT NULL,
    tags         TEXT[],
    slug         TEXT UNIQUE NOT NULL,
    image_url    TEXT NOT NULL,
    is_premium   BOOLEAN NOT NULL DEFAULT false,
    is_published BOOLEAN NOT NULL DEFAULT true,
    sort_order   INT DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 7. CREATE greeting_cards (user-created card = template + backside)
-- ============================================================

CREATE TABLE greeting_cards (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id        UUID NOT NULL REFERENCES users(id),
    template_id       UUID NOT NULL REFERENCES card_templates(id),
    status            TEXT NOT NULL DEFAULT 'draft'
                      CHECK (status IN ('draft', 'ready')),
    card_backside_url TEXT,
    message           TEXT,
    overlay_items     JSONB,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 8. CREATE conversations (simplified)
-- ============================================================

CREATE TABLE conversations (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE conversation_participants (
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    PRIMARY KEY (conversation_id, user_id)
);

-- ============================================================
-- 9. CREATE card_sends (delivery events)
-- ============================================================

CREATE TABLE card_sends (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_id         UUID NOT NULL REFERENCES greeting_cards(id),
    sender_id       UUID NOT NULL REFERENCES users(id),
    recipient_id    UUID REFERENCES users(id),
    recipient_phone TEXT,
    recipient_email TEXT,
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'scheduled', 'sent', 'delivered', 'opened')),
    scheduled_at    TIMESTAMPTZ,
    sent_at         TIMESTAMPTZ,
    opened_at       TIMESTAMPTZ,
    conversation_id UUID REFERENCES conversations(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- 10. CREATE messages
-- ============================================================

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id),
    card_send_id    UUID REFERENCES card_sends(id),
    text_content    TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    read_at         TIMESTAMPTZ
);

-- ============================================================
-- 11. INDEXES
-- ============================================================

-- Templates
CREATE INDEX idx_templates_category   ON card_templates(category);
CREATE INDEX idx_templates_slug       ON card_templates(slug);
CREATE INDEX idx_templates_published  ON card_templates(is_published) WHERE is_published = true;

-- Greeting cards
CREATE INDEX idx_greeting_cards_creator  ON greeting_cards(creator_id);
CREATE INDEX idx_greeting_cards_template ON greeting_cards(template_id);
CREATE INDEX idx_greeting_cards_drafts   ON greeting_cards(creator_id, status) WHERE status = 'draft';

-- Card sends
CREATE INDEX idx_card_sends_card            ON card_sends(card_id);
CREATE INDEX idx_card_sends_sender          ON card_sends(sender_id);
CREATE INDEX idx_card_sends_recipient       ON card_sends(recipient_id);
CREATE INDEX idx_card_sends_status          ON card_sends(status);
CREATE INDEX idx_card_sends_scheduled       ON card_sends(scheduled_at)
             WHERE status = 'scheduled' AND scheduled_at IS NOT NULL;
CREATE INDEX idx_card_sends_recipient_phone ON card_sends(recipient_phone)
             WHERE recipient_id IS NULL AND recipient_phone IS NOT NULL;

-- Conversations + messages
CREATE INDEX idx_conv_participants_user ON conversation_participants(user_id);
CREATE INDEX idx_messages_conversation  ON messages(conversation_id, created_at);
CREATE INDEX idx_messages_sender        ON messages(sender_id);

-- ============================================================
-- 12. RLS (defense in depth — API uses service_role which bypasses)
-- ============================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE greeting_cards ENABLE ROW LEVEL SECURITY;
ALTER TABLE card_sends ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- Templates: publicly readable
CREATE POLICY templates_read ON card_templates
    FOR SELECT USING (is_published = true);

-- Users: can read own row
CREATE POLICY users_read_own ON users
    FOR SELECT USING (supabase_id = auth.uid());

CREATE POLICY users_update_own ON users
    FOR UPDATE USING (supabase_id = auth.uid());

-- Greeting cards: owner only
CREATE POLICY cards_select_own ON greeting_cards
    FOR SELECT USING (creator_id IN (SELECT id FROM users WHERE supabase_id = auth.uid()));

CREATE POLICY cards_insert_own ON greeting_cards
    FOR INSERT WITH CHECK (creator_id IN (SELECT id FROM users WHERE supabase_id = auth.uid()));

CREATE POLICY cards_update_own ON greeting_cards
    FOR UPDATE USING (creator_id IN (SELECT id FROM users WHERE supabase_id = auth.uid()));

CREATE POLICY cards_delete_own ON greeting_cards
    FOR DELETE USING (creator_id IN (SELECT id FROM users WHERE supabase_id = auth.uid()));

-- Card sends: sender or recipient can read
CREATE POLICY sends_select_own ON card_sends
    FOR SELECT USING (
        sender_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        OR recipient_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
    );

-- Conversations: participants only
CREATE POLICY conversations_select_own ON conversations
    FOR SELECT USING (
        id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        )
    );

-- Conversation participants: participants only
CREATE POLICY conv_participants_select_own ON conversation_participants
    FOR SELECT USING (
        user_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        OR conversation_id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        )
    );

-- Messages: participants of the conversation
CREATE POLICY messages_select_own ON messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        )
    );

CREATE POLICY messages_insert_own ON messages
    FOR INSERT WITH CHECK (
        sender_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        AND conversation_id IN (
            SELECT conversation_id FROM conversation_participants
            WHERE user_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
        )
    );

-- ============================================================
-- 13. REALTIME
-- ============================================================

ALTER TABLE messages REPLICA IDENTITY FULL;
ALTER TABLE conversations REPLICA IDENTITY FULL;

-- ============================================================
-- 14. STORAGE BUCKETS
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('card-templates', 'card-templates', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO storage.buckets (id, name, public)
VALUES ('card-images', 'card-images', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for card-templates (public read)
CREATE POLICY "Public read card-templates" ON storage.objects
    FOR SELECT USING (bucket_id = 'card-templates');

-- Storage policies for card-images
CREATE POLICY "Authenticated upload card-images" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'card-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users read own card-images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'card-images'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM users WHERE supabase_id = auth.uid()
        )
    );

CREATE POLICY "Users delete own card-images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'card-images'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM users WHERE supabase_id = auth.uid()
        )
    );

-- ============================================================
-- 15. RECREATE handle_new_user (the one keeper)
-- ============================================================
-- Links auth.users signup to public.users.
-- Handles lazy users: if a row already exists with matching
-- phone_number, it links the supabase_id rather than creating a duplicate.

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.users WHERE phone_number = NEW.phone) THEN
        UPDATE public.users
        SET supabase_id = NEW.id
        WHERE phone_number = NEW.phone;
    ELSE
        INSERT INTO public.users (supabase_id, phone_number)
        VALUES (NEW.id, NEW.phone);
    END IF;
    RETURN NEW;
END;
$$;

-- The trigger on auth.users already exists (on_auth_user_created),
-- so we don't need to recreate it. It calls handle_new_user().

COMMIT;
