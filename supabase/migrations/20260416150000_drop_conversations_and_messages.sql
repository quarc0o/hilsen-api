-- ============================================================
-- Migration: Remove conversations, messages, and participants
-- ============================================================
-- Simplify architecture: greeting cards are sent directly via
-- card_sends without conversation/message wrapping.
-- ============================================================

BEGIN;

-- 1. Drop RLS policies on tables being removed
DROP POLICY IF EXISTS conversations_select_own ON conversations;
DROP POLICY IF EXISTS conv_participants_select_own ON conversation_participants;
DROP POLICY IF EXISTS messages_select_own ON messages;
DROP POLICY IF EXISTS messages_insert_own ON messages;

-- 2. Drop unique index on messages.card_send_id (from 20260412170000)
DROP INDEX IF EXISTS idx_messages_card_send_id_unique;

-- 3. Drop indexes on conversation/message tables
DROP INDEX IF EXISTS idx_conv_participants_user;
DROP INDEX IF EXISTS idx_messages_conversation;
DROP INDEX IF EXISTS idx_messages_sender;

-- 4. Remove conversation_id FK from card_sends before dropping conversations
ALTER TABLE card_sends DROP COLUMN IF EXISTS conversation_id;

-- 5. Drop tables in FK-safe order
DROP TABLE IF EXISTS messages;
DROP TABLE IF EXISTS conversation_participants;
DROP TABLE IF EXISTS conversations;

-- 6. Drop RLS policy that references recipient_id before dropping the column
DROP POLICY IF EXISTS sends_select_own ON card_sends;

-- 7. Remove recipient_id and recipient_email from card_sends (cards are tied to phone number only)
DROP INDEX IF EXISTS idx_card_sends_recipient;
DROP INDEX IF EXISTS idx_card_sends_recipient_phone;
ALTER TABLE card_sends DROP COLUMN IF EXISTS recipient_id;
ALTER TABLE card_sends DROP COLUMN IF EXISTS recipient_email;

-- 8. Recreate card_sends RLS policy (sender only)
CREATE POLICY sends_select_own ON card_sends
    FOR SELECT USING (
        sender_id IN (SELECT id FROM users WHERE supabase_id = auth.uid())
    );

-- 8. Drop legacy environment_metadata table (unused since DB cron functions were removed)
DROP FUNCTION IF EXISTS update_message_delivery_status();
DROP TABLE IF EXISTS environment_metadata;

COMMIT;
