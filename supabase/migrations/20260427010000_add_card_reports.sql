-- ============================================================
-- Card reports
-- ============================================================
-- Anyone who receives a card can flag it as inappropriate. Required
-- by Apple Guideline 1.2 for any UGC app. Same rationale as
-- sms_opt_outs: keep submission frictionless because the cost of a
-- false report is low (manual review) and the cost of suppressing
-- legitimate reports is high (Apple rejection / harm to recipients).
--
-- One row per report, not per send: a single problematic send can
-- be reported by multiple people, and we want each report's reason
-- preserved verbatim for review.
--
-- card_send_id cascades on send deletion (no orphan reports for
-- removed cards). reporter_id is nullable so anonymous reports
-- (public via short-code page) work; if it's set, ON DELETE SET
-- NULL keeps the report when the reporter deletes their account.
--
-- RLS is enabled with no policies, so only service_role can read
-- or write. Reports are admin-facing only — reporters do not see
-- their submission history (would let abusers probe what's on the
-- moderation queue).
-- ============================================================

CREATE TABLE IF NOT EXISTS public.card_reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    card_send_id uuid NOT NULL,
    reporter_id uuid,
    reason text NOT NULL,
    status text NOT NULL DEFAULT 'open',
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    reviewed_at timestamp with time zone,
    resolution text,
    CONSTRAINT card_reports_pkey PRIMARY KEY (id),
    CONSTRAINT card_reports_card_send_id_fkey
        FOREIGN KEY (card_send_id) REFERENCES public.card_sends(id) ON DELETE CASCADE,
    CONSTRAINT card_reports_reporter_id_fkey
        FOREIGN KEY (reporter_id) REFERENCES public.users(id) ON DELETE SET NULL,
    CONSTRAINT card_reports_status_check
        CHECK (status IN ('open', 'reviewed', 'actioned', 'dismissed'))
);

ALTER TABLE public.card_reports OWNER TO postgres;
ALTER TABLE public.card_reports ENABLE ROW LEVEL SECURITY;

GRANT ALL ON TABLE public.card_reports TO service_role;

CREATE INDEX IF NOT EXISTS idx_card_reports_card_send
    ON public.card_reports(card_send_id);
CREATE INDEX IF NOT EXISTS idx_card_reports_open
    ON public.card_reports(created_at)
    WHERE status = 'open';
