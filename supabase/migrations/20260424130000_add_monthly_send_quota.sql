-- ============================================================
-- Monthly send quota
-- ============================================================
-- Free users are capped at 10 card sends per calendar month (UTC).
-- Enforcement lives in the API layer before insert; this RPC
-- returns the current usage so the handler can compare against
-- the limit and reject over-quota requests.
--
-- Counted statuses: 'scheduled' and 'sent'. 'canceled' and 'failed'
-- do not consume a slot — the user hasn't used SMS capacity.
--
-- Period anchor: created_at. Slots are claimed when the send is
-- requested, not when it delivers. Scheduling 10 cards today for
-- next month still consumes this month's quota.
--
-- Partial index on (sender_id, created_at) filtered to counted
-- statuses keeps this a tiny index scan regardless of historical
-- volume of canceled/failed rows.
-- ============================================================

CREATE INDEX "idx_card_sends_sender_quota"
    ON "public"."card_sends" ("sender_id", "created_at")
    WHERE "status" IN ('scheduled', 'sent');

CREATE OR REPLACE FUNCTION public.count_card_sends_this_month(p_sender_id uuid)
    RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  SELECT COUNT(*)::integer
  FROM public.card_sends
  WHERE sender_id = p_sender_id
    AND status IN ('scheduled', 'sent')
    AND created_at >= date_trunc('month', now());
$$;

ALTER FUNCTION public.count_card_sends_this_month(uuid) OWNER TO postgres;

GRANT EXECUTE ON FUNCTION public.count_card_sends_this_month(uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.count_card_sends_this_month(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.count_card_sends_this_month(uuid) TO service_role;
