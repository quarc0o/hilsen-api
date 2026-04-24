-- ============================================================
-- demo_send_recipients
-- ============================================================
-- Lifetime-1 tracking for the public example-card-send feature.
-- phone_number as PK means attempting to re-send to the same
-- number raises a unique-violation (SQLSTATE 23505), which the
-- API catches and returns as "already_sent".
--
-- No IP column by design: we rely on in-memory per-IP rate limit
-- (fastify/rate-limit) and phone uniqueness, so we don't persist
-- identifiers that would trigger extra GDPR obligations.
--
-- RLS enabled without policies — service_role only, since this
-- is used by an unauthenticated endpoint.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.demo_send_recipients (
    phone_number text PRIMARY KEY,
    first_sent_at timestamp with time zone NOT NULL DEFAULT now()
);

ALTER TABLE public.demo_send_recipients OWNER TO postgres;
ALTER TABLE public.demo_send_recipients ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.demo_send_recipients TO service_role;

-- Supports the global daily cap query (count per day).
CREATE INDEX idx_demo_send_recipients_first_sent_at
    ON public.demo_send_recipients (first_sent_at);
