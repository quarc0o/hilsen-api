-- ============================================================
-- Age verification + phone-level auth blocks
-- ============================================================
-- Adds an age-verification gate at signup. The flow:
--   1. New auth.users insert → handle_new_user trigger checks
--      auth_blocks first; if the phone is blocked the trigger
--      raises and the auth.users insert is rolled back.
--   2. Once a user exists in public.users, age_verified_at = NULL
--      means onboarding isn't done. The API gates feature routes
--      on age_verified_at IS NOT NULL.
--   3. If the user submits an age < 13, the API inserts the phone
--      into auth_blocks ('underage') and then deletes the account
--      via the existing cascade. They can't re-OTP back in.
--
-- auth_blocks is phone-keyed, RLS-enabled with no policies, so
-- only service_role (which bypasses RLS) can read or write it.
-- Same shape as sms_opt_outs.
--
-- Existing users are backfilled to now() — they accepted the
-- prior ToS, so we treat them as grandfathered in rather than
-- forcing them through a gate on next login.
-- ============================================================

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS age_verified_at timestamp with time zone;

UPDATE public.users
SET age_verified_at = now()
WHERE age_verified_at IS NULL;

CREATE TABLE IF NOT EXISTS public.auth_blocks (
    phone_number text PRIMARY KEY,
    reason text NOT NULL,
    blocked_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT auth_blocks_reason_check CHECK (reason IN ('underage', 'banned', 'abuse'))
);

ALTER TABLE public.auth_blocks OWNER TO postgres;
ALTER TABLE public.auth_blocks ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.auth_blocks TO service_role;

-- ============================================================
-- Trigger update: reject blocked phones before linking/inserting
-- ============================================================
-- Phones in auth_blocks must not produce a public.users row.
-- Raising here rolls back the auth.users insert in the same
-- transaction, so the OTP-completed account is also discarded.
-- The client sees a generic auth failure (no leak about why).
-- ============================================================

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM public.auth_blocks WHERE phone_number = NEW.phone) THEN
        RAISE EXCEPTION 'phone_blocked'
            USING ERRCODE = 'check_violation';
    END IF;

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
