-- ============================================================
-- Initial baseline
-- ============================================================
-- Squashes 76 prior migrations (2024-10 → 2026-04) into a single
-- file representing the current schema. Generated from
-- `supabase db dump --local --schema public` with manual additions
-- for storage buckets, policies, and the auth.users trigger.
--
-- Known fix: pg_dump emitted `status DEFAULT 'pending'` for
-- card_sends, but 'pending' is no longer a valid enum value.
-- Default is now 'scheduled' (matches the "just inserted" state).
-- ============================================================

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

-- ============================================================
-- Extensions
-- ============================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ============================================================
-- public schema
-- ============================================================

COMMENT ON SCHEMA "public" IS 'standard public schema';

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
BEGIN
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

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';
SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."card_sends" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "card_id" "uuid" NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "recipient_phone" "text",
    "status" "text" DEFAULT 'scheduled'::"text" NOT NULL,
    "scheduled_at" timestamp with time zone,
    "sent_at" timestamp with time zone,
    "opened_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "send_group_id" "uuid",
    "error" "text",
    CONSTRAINT "card_sends_status_check" CHECK (("status" = ANY (ARRAY['scheduled'::"text", 'sent'::"text", 'failed'::"text", 'canceled'::"text"])))
);

ALTER TABLE "public"."card_sends" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."greeting_cards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "creator_id" "uuid" NOT NULL,
    "design_id" "uuid" NOT NULL,
    "message" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."greeting_cards" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "email" "text",
    "first_name" "text",
    "last_name" "text",
    "phone_number" "text",
    "supabase_id" "uuid",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL
);

ALTER TABLE "public"."users" OWNER TO "postgres";

ALTER TABLE ONLY "public"."card_sends"
    ADD CONSTRAINT "card_sends_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."greeting_cards"
    ADD CONSTRAINT "greeting_cards_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_phone_number_key" UNIQUE ("phone_number");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

CREATE INDEX "idx_card_sends_card" ON "public"."card_sends" USING "btree" ("card_id");
CREATE INDEX "idx_card_sends_group" ON "public"."card_sends" USING "btree" ("send_group_id") WHERE ("send_group_id" IS NOT NULL);
CREATE INDEX "idx_card_sends_scheduled" ON "public"."card_sends" USING "btree" ("scheduled_at") WHERE (("status" = 'scheduled'::"text") AND ("scheduled_at" IS NOT NULL));
CREATE INDEX "idx_card_sends_sender" ON "public"."card_sends" USING "btree" ("sender_id");
CREATE INDEX "idx_card_sends_status" ON "public"."card_sends" USING "btree" ("status");
CREATE INDEX "idx_greeting_cards_creator" ON "public"."greeting_cards" USING "btree" ("creator_id");
CREATE INDEX "idx_greeting_cards_design" ON "public"."greeting_cards" USING "btree" ("design_id");

ALTER TABLE ONLY "public"."card_sends"
    ADD CONSTRAINT "card_sends_card_id_fkey" FOREIGN KEY ("card_id") REFERENCES "public"."greeting_cards"("id");

ALTER TABLE ONLY "public"."card_sends"
    ADD CONSTRAINT "card_sends_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."greeting_cards"
    ADD CONSTRAINT "greeting_cards_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_supabase_id_fkey" FOREIGN KEY ("supabase_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;

-- ============================================================
-- RLS
-- ============================================================

ALTER TABLE "public"."card_sends" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."greeting_cards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "public"."users" ENABLE ROW LEVEL SECURITY;

CREATE POLICY "cards_delete_own" ON "public"."greeting_cards" FOR DELETE USING (("creator_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."supabase_id" = "auth"."uid"()))));

CREATE POLICY "cards_insert_own" ON "public"."greeting_cards" FOR INSERT WITH CHECK (("creator_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."supabase_id" = "auth"."uid"()))));

CREATE POLICY "cards_select_own" ON "public"."greeting_cards" FOR SELECT USING (("creator_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."supabase_id" = "auth"."uid"()))));

CREATE POLICY "cards_update_own" ON "public"."greeting_cards" FOR UPDATE USING (("creator_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."supabase_id" = "auth"."uid"()))));

CREATE POLICY "sends_select_own" ON "public"."card_sends" FOR SELECT USING (("sender_id" IN ( SELECT "users"."id"
   FROM "public"."users"
  WHERE ("users"."supabase_id" = "auth"."uid"()))));

CREATE POLICY "users_read_own" ON "public"."users" FOR SELECT USING (("supabase_id" = "auth"."uid"()));

CREATE POLICY "users_update_own" ON "public"."users" FOR UPDATE USING (("supabase_id" = "auth"."uid"()));

-- ============================================================
-- Grants
-- ============================================================

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON TABLE "public"."card_sends" TO "anon";
GRANT ALL ON TABLE "public"."card_sends" TO "authenticated";
GRANT ALL ON TABLE "public"."card_sends" TO "service_role";

GRANT ALL ON TABLE "public"."greeting_cards" TO "anon";
GRANT ALL ON TABLE "public"."greeting_cards" TO "authenticated";
GRANT ALL ON TABLE "public"."greeting_cards" TO "service_role";

GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";
GRANT ALL ON TABLE "public"."users" TO "supabase_auth_admin";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";

-- ============================================================
-- Auth trigger: link new auth.users signups into public.users
-- ============================================================

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================================
-- Storage buckets
-- ============================================================

INSERT INTO storage.buckets (id, name, public)
VALUES ('card-images', 'card-images', false)
ON CONFLICT (id) DO NOTHING;

-- card-images: per-user folder access (scoped by public.users.id)
CREATE POLICY "Users read own card-images" ON storage.objects
    FOR SELECT USING (
        bucket_id = 'card-images'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM public.users WHERE supabase_id = auth.uid()
        )
    );

CREATE POLICY "Users upload own card-images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'card-images'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM public.users WHERE supabase_id = auth.uid()
        )
    );

CREATE POLICY "Users delete own card-images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'card-images'
        AND (storage.foldername(name))[1] IN (
            SELECT id::text FROM public.users WHERE supabase_id = auth.uid()
        )
    );
