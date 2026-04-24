-- ============================================================
-- User ban (soft ban)
-- ============================================================
-- A banned user cannot create new card_sends (POST or PATCH-add)
-- and any scheduled rows they still own are canceled at delivery
-- time by the worker. They retain read access to their own data
-- — login/view/export continue to work so account data stays
-- accessible (GDPR Art. 15/20 friendly).
--
-- banned_at doubles as a flag and an audit timestamp. NULL = not
-- banned. banned_reason is admin-facing bookkeeping.
--
-- No index: checks are always by users.id (PK-indexed).
-- Bans are set manually via SQL until volume justifies an admin UI.
-- ============================================================

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS banned_at timestamp with time zone,
    ADD COLUMN IF NOT EXISTS banned_reason text;
