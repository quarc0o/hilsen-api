-- ============================================================
-- Gift-card attempts (fake-door)
-- ============================================================
-- Backs the digital gift-card fake-door in the Flutter send flow.
-- Real gift cards are not implemented yet; this table measures
-- intent so we know whether to build them. One row per attempt:
-- written when the user taps "Legg til gavekort" (logAttempt),
-- then flipped to opted_in = true if they ask to be notified by
-- SMS (markOptedIn). The client writes here DIRECTLY via the
-- anon/authenticated Supabase key — the API never touches this
-- table — so RLS below is the only thing guarding it.
--
-- supabase_user_id stores auth.uid() directly (not public.users.id)
-- and defaults to auth.uid(), so the client never has to send it.
-- This diverges from card_sends/greeting_cards, which key off
-- public.users.id — deliberate: the module is self-contained and
-- meant to be easy to delete once we decide on real gift cards.
--
-- Logging fails SOFT on the client (Sentry-captured, never blocks
-- the user), so we keep data constraints permissive: a rejected
-- insert means lost signal, which is worse than a slightly odd row.
--
-- updated_at is maintained by a BEFORE UPDATE trigger so the gap
-- between created_at and updated_at measures time-to-opt-in
-- regardless of what the client sends.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.giftcard_attempts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    supabase_user_id uuid NOT NULL DEFAULT auth.uid(),
    phone_number text,
    brand text NOT NULL,
    amount_nok integer NOT NULL,
    fee_pct numeric NOT NULL DEFAULT 3.0,
    fee_nok numeric NOT NULL,
    opted_in boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    updated_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT giftcard_attempts_pkey PRIMARY KEY (id),
    CONSTRAINT giftcard_attempts_supabase_user_id_fkey
        FOREIGN KEY (supabase_user_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT giftcard_attempts_amount_nok_check CHECK (amount_nok >= 0),
    CONSTRAINT giftcard_attempts_fee_nok_check CHECK (fee_nok >= 0)
);

ALTER TABLE public.giftcard_attempts OWNER TO postgres;
ALTER TABLE public.giftcard_attempts ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.giftcard_attempts TO anon;
GRANT ALL ON TABLE public.giftcard_attempts TO authenticated;
GRANT ALL ON TABLE public.giftcard_attempts TO service_role;

-- Own-row access only. The client inserts (relying on the auth.uid()
-- default), selects its own row back, and updates it to set opted_in.
CREATE POLICY "giftcard_attempts_insert_own" ON public.giftcard_attempts
    FOR INSERT TO authenticated
    WITH CHECK (supabase_user_id = auth.uid());

CREATE POLICY "giftcard_attempts_select_own" ON public.giftcard_attempts
    FOR SELECT TO authenticated
    USING (supabase_user_id = auth.uid());

CREATE POLICY "giftcard_attempts_update_own" ON public.giftcard_attempts
    FOR UPDATE TO authenticated
    USING (supabase_user_id = auth.uid())
    WITH CHECK (supabase_user_id = auth.uid());

-- Lookup for the markOptedIn update and own-row queries.
CREATE INDEX IF NOT EXISTS idx_giftcard_attempts_user
    ON public.giftcard_attempts(supabase_user_id);
-- Funnel: attempts over time, and the converted subset.
CREATE INDEX IF NOT EXISTS idx_giftcard_attempts_created
    ON public.giftcard_attempts(created_at);
CREATE INDEX IF NOT EXISTS idx_giftcard_attempts_opted_in
    ON public.giftcard_attempts(created_at)
    WHERE opted_in;

-- Keep updated_at honest on opt-in (and any later update).
CREATE OR REPLACE FUNCTION public.touch_giftcard_attempts_updated_at()
    RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

ALTER FUNCTION public.touch_giftcard_attempts_updated_at() OWNER TO postgres;

DROP TRIGGER IF EXISTS trg_giftcard_attempts_updated_at ON public.giftcard_attempts;
CREATE TRIGGER trg_giftcard_attempts_updated_at
    BEFORE UPDATE ON public.giftcard_attempts
    FOR EACH ROW
    EXECUTE FUNCTION public.touch_giftcard_attempts_updated_at();
