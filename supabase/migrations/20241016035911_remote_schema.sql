
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

CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgsodium" WITH SCHEMA "pgsodium";

CREATE EXTENSION IF NOT EXISTS "http" WITH SCHEMA "public";

CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";

CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";

CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";

CREATE OR REPLACE FUNCTION "public"."handle_deleted_auth_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
DELETE FROM public.users
WHERE id = OLD.id;

RETURN OLD;
END;
$$;

ALTER FUNCTION "public"."handle_deleted_auth_user"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$begin
  insert into public.users (id, phone_number)
  values (new.id, new.phone);
  return new;
end;$$;

ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."send_gift"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    card_frontside_url TEXT;
    card_backside_url TEXT;
    recipient_phone_number TEXT;
    request_url TEXT := 'https://pknyigmenaxchcvkwnko.supabase.co/functions/v1/send_gift_email';  -- Replace with your actual Edge Function URL
    request_headers JSONB := '{"Content-Type": "application/json"}';
BEGIN
    -- Find the greeting card details based on the inserted gift's ID
    SELECT gc.card_frontside_url, gc.card_backside_url, g.recipient_phone_number
    INTO card_frontside_url, card_backside_url, recipient_phone_number
    FROM greeting_cards gc
    JOIN gifts g ON g.id = NEW.id
    WHERE gc.gift_id = NEW.id;

    -- Log the retrieved values to debug
    RAISE NOTICE 'Retrieved card_frontside_url: %, card_backside_url: %, recipient_phone_number: %',
                 card_frontside_url, card_backside_url, recipient_phone_number;

    -- If values are null, log an additional message
    IF card_frontside_url IS NULL OR card_backside_url IS NULL OR recipient_phone_number IS NULL THEN
        RAISE NOTICE 'Some or all of the retrieved values are null';
    END IF;

    -- Perform an asynchronous HTTP POST request using pg_net
    PERFORM net.http_post(
        url := request_url,
        body := json_build_object(
            'card_frontside_url', 'test',
            'card_backside_url', card_backside_url,
            'recipient_phone_number', recipient_phone_number
        )::jsonb,
        headers := request_headers
    );

    -- Optionally log the request ID (you can query this later in the net._http_response table if needed)
    RAISE NOTICE 'HTTP POST request initiated for gift ID: %', NEW.id;

    RETURN NEW;
END;
$$;

ALTER FUNCTION "public"."send_gift"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."test_email"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $_$BEGIN
CREATE OR REPLACE FUNCTION send_gift()
RETURNS trigger AS $$
BEGIN
    DECLARE
        card_frontside_url TEXT;
        card_backside_url TEXT;
        recipient_phone_number TEXT;
        request_url TEXT := 'https://pknyigmenaxchcvkwnko.supabase.co/functions/v1/send_gift_email';  -- Replace with your actual Edge Function URL
    BEGIN
        -- Find the greeting card details based on the inserted gift's ID
        SELECT gc.card_frontside_url, gc.card_backside_url, g.recipient_phone_number
        INTO card_frontside_url, card_backside_url, recipient_phone_number
        FROM greeting_cards gc
        JOIN gifts g ON g.id = NEW.id
        WHERE gc.gift_id = NEW.id;

        -- Make an HTTP POST request to the Supabase Edge Function
        PERFORM http_post(
            request_url,
            json_build_object(
                'card_frontside_url', card_frontside_url,
                'card_backside_url', card_backside_url,
                'recipient_phone_number', recipient_phone_number
            )::text,
            'application/json'
        );

        RETURN NEW;
    END;
END;
$$ LANGUAGE plpgsql;
END;$_$;

ALTER FUNCTION "public"."test_email"() OWNER TO "postgres";

CREATE OR REPLACE FUNCTION "public"."trigger_send_email_function"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $_$BEGIN 
BEGIN
CREATE OR REPLACE FUNCTION send_gift()
RETURNS trigger AS $$
DECLARE
    card_frontside_url TEXT;
    card_backside_url TEXT;
    recipient_phone_number TEXT;
    request_url TEXT := 'https://<your-supabase-project>.functions.supabase.co/send-gift';  -- Replace with your Edge Function URL
    response TEXT;
BEGIN
    -- Find the greeting card details based on the inserted gift's ID
    SELECT gc.card_frontside_url, gc.card_backside_url, g.recipient_phone_number
    INTO card_frontside_url, card_backside_url, recipient_phone_number
    FROM greeting_cards gc
    JOIN gifts g ON g.id = NEW.id
    WHERE gc.gift_id = NEW.id;

    -- Make an HTTP POST request to the Supabase Edge Function
    -- You can use the `http` Postgres extension to perform HTTP requests (this requires enabling the extension in Supabase)
    PERFORM http_post(
        request_url,
        json_build_object(
            'card_frontside_url', card_frontside_url,
            'card_backside_url', card_backside_url,
            'recipient_phone_number', recipient_phone_number
        )::text,
        'application/json'
    );

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
END;
END;$_$;

ALTER FUNCTION "public"."trigger_send_email_function"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";

CREATE TABLE IF NOT EXISTS "public"."chat_messages" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sent_at" timestamp with time zone NOT NULL,
    "opened_at" timestamp with time zone,
    "message" "text",
    "recipient_phone_number" "text" NOT NULL,
    "sender_phone_number" "text" NOT NULL,
    "gift_id" "uuid",
    "conversation_id" "uuid" NOT NULL
);

ALTER TABLE "public"."chat_messages" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "participant_one_phone" "text" NOT NULL,
    "participant_two_phone" "text" NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "last_message_id" "uuid"
);

ALTER TABLE "public"."conversations" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."gift_cards" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "gift_id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "card_design_url" "text",
    "title" "text",
    "is_activated" boolean DEFAULT false
);

ALTER TABLE "public"."gift_cards" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."gifts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "sent_at" timestamp with time zone NOT NULL,
    "opened_at" timestamp with time zone,
    "recipient_phone_number" "text" NOT NULL,
    "sender_phone_number" "text"
);

ALTER TABLE "public"."gifts" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."greeting_cards" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "gift_id" "uuid" NOT NULL,
    "message" "text",
    "card_backside_url" "text",
    "card_frontside_url" "text"
);

ALTER TABLE "public"."greeting_cards" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."persons" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "first_name" "text" NOT NULL,
    "person_birthdate" "date",
    "person_reminder" boolean DEFAULT false NOT NULL,
    "person_tag_category_id" bigint,
    "person_image_url" "text",
    "last_name" "text"
);

ALTER TABLE "public"."persons" OWNER TO "postgres";

CREATE TABLE IF NOT EXISTS "public"."tag_categories" (
    "id" bigint NOT NULL,
    "tag_name" "text" NOT NULL,
    "tag_colour" "text"
);

ALTER TABLE "public"."tag_categories" OWNER TO "postgres";

ALTER TABLE "public"."tag_categories" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."tag_categories_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);

CREATE TABLE IF NOT EXISTS "public"."users" (
    "id" "uuid" NOT NULL,
    "email" "text",
    "first_name" "text",
    "last_name" "text",
    "phone_number" "text"
);

ALTER TABLE "public"."users" OWNER TO "postgres";

ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "chat_messages_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."gift_cards"
    ADD CONSTRAINT "gift_cards_gift_id_key" UNIQUE ("gift_id");

ALTER TABLE ONLY "public"."gift_cards"
    ADD CONSTRAINT "gift_cards_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."gifts"
    ADD CONSTRAINT "gifts_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."greeting_cards"
    ADD CONSTRAINT "greeting_cards_gift_id_key" UNIQUE ("gift_id");

ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "persons_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."tag_categories"
    ADD CONSTRAINT "tag_categories_pkey" PRIMARY KEY ("id");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_phone_number_key" UNIQUE ("phone_number");

ALTER TABLE ONLY "public"."users"
    ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

CREATE OR REPLACE TRIGGER "test_send_email" AFTER INSERT ON "public"."gifts" FOR EACH ROW EXECUTE FUNCTION "supabase_functions"."http_request"('https://pknyigmenaxchcvkwnko.supabase.co/functions/v1/send_gift_email', 'POST', '{"Content-type":"application/json"}', '{}', '5000');

ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "persons_person_tag_category_id_fkey" FOREIGN KEY ("person_tag_category_id") REFERENCES "public"."tag_categories"("id") ON DELETE SET NULL;

ALTER TABLE ONLY "public"."persons"
    ADD CONSTRAINT "persons_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE CASCADE;

ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "public_chat_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "public_chat_messages_gift_id_fkey" FOREIGN KEY ("gift_id") REFERENCES "public"."gifts"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "public_chat_messages_recipient_phone_number_fkey" FOREIGN KEY ("recipient_phone_number") REFERENCES "public"."users"("phone_number") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."chat_messages"
    ADD CONSTRAINT "public_chat_messages_sender_phone_number_fkey" FOREIGN KEY ("sender_phone_number") REFERENCES "public"."users"("phone_number") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "public_conversations_last_message_id_fkey" FOREIGN KEY ("last_message_id") REFERENCES "public"."chat_messages"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."gift_cards"
    ADD CONSTRAINT "public_gift_cards_gift_id_fkey" FOREIGN KEY ("gift_id") REFERENCES "public"."gifts"("id") ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE ONLY "public"."greeting_cards"
    ADD CONSTRAINT "public_greeting_cards_gift_id_fkey" FOREIGN KEY ("gift_id") REFERENCES "public"."gifts"("id") ON UPDATE CASCADE ON DELETE CASCADE;

REVOKE USAGE ON SCHEMA "public" FROM PUBLIC;
GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_deleted_auth_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_deleted_auth_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_deleted_auth_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";

GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "postgres";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "anon";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "authenticated";
GRANT ALL ON FUNCTION "public"."http"("request" "public"."http_request") TO "service_role";

GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_delete"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying, "data" "jsonb") TO "postgres";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying, "data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying, "data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_get"("uri" character varying, "data" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_head"("uri" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_header"("field" character varying, "value" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_list_curlopt"() TO "postgres";
GRANT ALL ON FUNCTION "public"."http_list_curlopt"() TO "anon";
GRANT ALL ON FUNCTION "public"."http_list_curlopt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_list_curlopt"() TO "service_role";

GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_patch"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "data" "jsonb") TO "postgres";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "data" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_post"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_put"("uri" character varying, "content" character varying, "content_type" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "postgres";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "anon";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_reset_curlopt"() TO "service_role";

GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_set_curlopt"("curlopt" character varying, "value" character varying) TO "service_role";

GRANT ALL ON FUNCTION "public"."send_gift"() TO "anon";
GRANT ALL ON FUNCTION "public"."send_gift"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."send_gift"() TO "service_role";

GRANT ALL ON FUNCTION "public"."test_email"() TO "anon";
GRANT ALL ON FUNCTION "public"."test_email"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."test_email"() TO "service_role";

GRANT ALL ON FUNCTION "public"."trigger_send_email_function"() TO "anon";
GRANT ALL ON FUNCTION "public"."trigger_send_email_function"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."trigger_send_email_function"() TO "service_role";

GRANT ALL ON FUNCTION "public"."urlencode"("string" "bytea") TO "postgres";
GRANT ALL ON FUNCTION "public"."urlencode"("string" "bytea") TO "anon";
GRANT ALL ON FUNCTION "public"."urlencode"("string" "bytea") TO "authenticated";
GRANT ALL ON FUNCTION "public"."urlencode"("string" "bytea") TO "service_role";

GRANT ALL ON FUNCTION "public"."urlencode"("data" "jsonb") TO "postgres";
GRANT ALL ON FUNCTION "public"."urlencode"("data" "jsonb") TO "anon";
GRANT ALL ON FUNCTION "public"."urlencode"("data" "jsonb") TO "authenticated";
GRANT ALL ON FUNCTION "public"."urlencode"("data" "jsonb") TO "service_role";

GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "postgres";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "anon";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "authenticated";
GRANT ALL ON FUNCTION "public"."urlencode"("string" character varying) TO "service_role";

GRANT ALL ON TABLE "public"."chat_messages" TO "anon";
GRANT ALL ON TABLE "public"."chat_messages" TO "authenticated";
GRANT ALL ON TABLE "public"."chat_messages" TO "service_role";

GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";

GRANT ALL ON TABLE "public"."gift_cards" TO "anon";
GRANT ALL ON TABLE "public"."gift_cards" TO "authenticated";
GRANT ALL ON TABLE "public"."gift_cards" TO "service_role";

GRANT ALL ON TABLE "public"."gifts" TO "anon";
GRANT ALL ON TABLE "public"."gifts" TO "authenticated";
GRANT ALL ON TABLE "public"."gifts" TO "service_role";

GRANT ALL ON TABLE "public"."greeting_cards" TO "anon";
GRANT ALL ON TABLE "public"."greeting_cards" TO "authenticated";
GRANT ALL ON TABLE "public"."greeting_cards" TO "service_role";

GRANT ALL ON TABLE "public"."persons" TO "anon";
GRANT ALL ON TABLE "public"."persons" TO "authenticated";
GRANT ALL ON TABLE "public"."persons" TO "service_role";

GRANT ALL ON TABLE "public"."tag_categories" TO "anon";
GRANT ALL ON TABLE "public"."tag_categories" TO "authenticated";
GRANT ALL ON TABLE "public"."tag_categories" TO "service_role";

GRANT ALL ON SEQUENCE "public"."tag_categories_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."tag_categories_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."tag_categories_id_seq" TO "service_role";

GRANT ALL ON TABLE "public"."users" TO "anon";
GRANT ALL ON TABLE "public"."users" TO "authenticated";
GRANT ALL ON TABLE "public"."users" TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";

ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";

RESET ALL;
