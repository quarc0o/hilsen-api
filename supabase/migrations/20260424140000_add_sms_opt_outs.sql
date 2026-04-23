-- ============================================================
-- SMS opt-out list
-- ============================================================
-- Recipients who have requested not to receive SMS from Hilsen.
-- Queried before every send; an entry here blocks the recipient
-- from getting any further SMS regardless of sender.
--
-- Phone numbers are stored without a leading '+' to match the
-- format used in card_sends.recipient_phone.
--
-- RLS is enabled with no policies, so only service_role (which
-- bypasses RLS) can read or write this table. We never want
-- authenticated users to query other recipients' opt-out status.
-- ============================================================

CREATE TABLE IF NOT EXISTS public.sms_opt_outs (
    phone_number text PRIMARY KEY,
    opted_out_at timestamp with time zone NOT NULL DEFAULT now(),
    source text NOT NULL,
    CONSTRAINT sms_opt_outs_source_check CHECK (source IN ('form', 'email', 'api'))
);

ALTER TABLE public.sms_opt_outs OWNER TO postgres;
ALTER TABLE public.sms_opt_outs ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.sms_opt_outs TO service_role;
