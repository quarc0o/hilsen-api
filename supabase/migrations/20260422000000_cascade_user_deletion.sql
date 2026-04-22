-- ============================================================
-- Migration: Cascade user deletion through all FK chains
-- ============================================================
-- Deleting a row from auth.users should remove every trace of
-- the user from the public schema. Chain:
--   auth.users
--     └─ public.users            (via supabase_id)
--          ├─ greeting_cards     (via creator_id)
--          └─ card_sends         (via sender_id)
--
-- The users.supabase_id FK was previously ON DELETE SET NULL
-- (migration 20250417175512), left over from when a
-- handle_deleted_auth_user trigger did the cleanup. That trigger
-- was dropped in 20250417235016, so the SET NULL is now
-- vestigial. Storage and PostHog are handled by the API layer.
-- ============================================================

BEGIN;

-- users.supabase_id → auth.users: SET NULL → CASCADE
ALTER TABLE public.users DROP CONSTRAINT users_supabase_id_fkey;
ALTER TABLE public.users
    ADD CONSTRAINT users_supabase_id_fkey
    FOREIGN KEY (supabase_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- greeting_cards.creator_id → users: add CASCADE
ALTER TABLE public.greeting_cards DROP CONSTRAINT greeting_cards_creator_id_fkey;
ALTER TABLE public.greeting_cards
    ADD CONSTRAINT greeting_cards_creator_id_fkey
    FOREIGN KEY (creator_id) REFERENCES public.users(id) ON DELETE CASCADE;

-- card_sends.sender_id → users: add CASCADE
ALTER TABLE public.card_sends DROP CONSTRAINT card_sends_sender_id_fkey;
ALTER TABLE public.card_sends
    ADD CONSTRAINT card_sends_sender_id_fkey
    FOREIGN KEY (sender_id) REFERENCES public.users(id) ON DELETE CASCADE;

COMMIT;
