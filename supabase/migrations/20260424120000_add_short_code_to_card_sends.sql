-- ============================================================
-- Add short_code to card_sends
-- ============================================================
-- Public-facing identifier used in SMS links (hilsen.app/s/<code>).
-- 12 URL-safe base64 chars = 72 bits of entropy. With rate limiting
-- on the public route, unguessable enough for PII-bearing links.
-- UUID remains the primary key; short_code is the external handle.
-- ============================================================

CREATE OR REPLACE FUNCTION "public"."generate_send_short_code"() RETURNS "text"
    LANGUAGE "sql" VOLATILE
    AS $$
  SELECT translate(encode(gen_random_bytes(9), 'base64'), '+/', '-_');
$$;

ALTER TABLE "public"."card_sends"
    ADD COLUMN "short_code" "text" DEFAULT "public"."generate_send_short_code"();

UPDATE "public"."card_sends"
    SET "short_code" = "public"."generate_send_short_code"()
    WHERE "short_code" IS NULL;

ALTER TABLE "public"."card_sends"
    ALTER COLUMN "short_code" SET NOT NULL,
    ADD CONSTRAINT "card_sends_short_code_key" UNIQUE ("short_code");
