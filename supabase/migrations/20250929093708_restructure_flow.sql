revoke delete on table "public"."gift_messages" from "anon";

revoke insert on table "public"."gift_messages" from "anon";

revoke references on table "public"."gift_messages" from "anon";

revoke select on table "public"."gift_messages" from "anon";

revoke trigger on table "public"."gift_messages" from "anon";

revoke truncate on table "public"."gift_messages" from "anon";

revoke update on table "public"."gift_messages" from "anon";

revoke delete on table "public"."gift_messages" from "authenticated";

revoke insert on table "public"."gift_messages" from "authenticated";

revoke references on table "public"."gift_messages" from "authenticated";

revoke select on table "public"."gift_messages" from "authenticated";

revoke trigger on table "public"."gift_messages" from "authenticated";

revoke truncate on table "public"."gift_messages" from "authenticated";

revoke update on table "public"."gift_messages" from "authenticated";

revoke delete on table "public"."gift_messages" from "service_role";

revoke insert on table "public"."gift_messages" from "service_role";

revoke references on table "public"."gift_messages" from "service_role";

revoke select on table "public"."gift_messages" from "service_role";

revoke trigger on table "public"."gift_messages" from "service_role";

revoke truncate on table "public"."gift_messages" from "service_role";

revoke update on table "public"."gift_messages" from "service_role";

revoke delete on table "public"."gifts" from "anon";

revoke insert on table "public"."gifts" from "anon";

revoke references on table "public"."gifts" from "anon";

revoke select on table "public"."gifts" from "anon";

revoke trigger on table "public"."gifts" from "anon";

revoke truncate on table "public"."gifts" from "anon";

revoke update on table "public"."gifts" from "anon";

revoke delete on table "public"."gifts" from "authenticated";

revoke insert on table "public"."gifts" from "authenticated";

revoke references on table "public"."gifts" from "authenticated";

revoke select on table "public"."gifts" from "authenticated";

revoke trigger on table "public"."gifts" from "authenticated";

revoke truncate on table "public"."gifts" from "authenticated";

revoke update on table "public"."gifts" from "authenticated";

revoke delete on table "public"."gifts" from "service_role";

revoke insert on table "public"."gifts" from "service_role";

revoke references on table "public"."gifts" from "service_role";

revoke select on table "public"."gifts" from "service_role";

revoke trigger on table "public"."gifts" from "service_role";

revoke truncate on table "public"."gifts" from "service_role";

revoke update on table "public"."gifts" from "service_role";

revoke delete on table "public"."gifts" from "supabase_auth_admin";

revoke insert on table "public"."gifts" from "supabase_auth_admin";

revoke references on table "public"."gifts" from "supabase_auth_admin";

revoke select on table "public"."gifts" from "supabase_auth_admin";

revoke trigger on table "public"."gifts" from "supabase_auth_admin";

revoke truncate on table "public"."gifts" from "supabase_auth_admin";

revoke update on table "public"."gifts" from "supabase_auth_admin";

revoke delete on table "public"."text_messages" from "anon";

revoke insert on table "public"."text_messages" from "anon";

revoke references on table "public"."text_messages" from "anon";

revoke select on table "public"."text_messages" from "anon";

revoke trigger on table "public"."text_messages" from "anon";

revoke truncate on table "public"."text_messages" from "anon";

revoke update on table "public"."text_messages" from "anon";

revoke delete on table "public"."text_messages" from "authenticated";

revoke insert on table "public"."text_messages" from "authenticated";

revoke references on table "public"."text_messages" from "authenticated";

revoke select on table "public"."text_messages" from "authenticated";

revoke trigger on table "public"."text_messages" from "authenticated";

revoke truncate on table "public"."text_messages" from "authenticated";

revoke update on table "public"."text_messages" from "authenticated";

revoke delete on table "public"."text_messages" from "service_role";

revoke insert on table "public"."text_messages" from "service_role";

revoke references on table "public"."text_messages" from "service_role";

revoke select on table "public"."text_messages" from "service_role";

revoke trigger on table "public"."text_messages" from "service_role";

revoke truncate on table "public"."text_messages" from "service_role";

revoke update on table "public"."text_messages" from "service_role";

alter table "public"."gift_messages" drop constraint "gift_messages_greeting_card_id_fkey";

alter table "public"."gift_messages" drop constraint "gift_messages_message_id_fkey";

alter table "public"."gifts" drop constraint "gifts_greeting_card_id_fkey";

alter table "public"."text_messages" drop constraint "text_messages_message_id_fkey";

alter table "public"."gift_messages" drop constraint "gift_messages_pkey";

alter table "public"."gifts" drop constraint "gifts_pkey";

alter table "public"."text_messages" drop constraint "text_messages_pkey";

drop index if exists "public"."gift_messages_pkey";

drop index if exists "public"."gifts_pkey";

drop index if exists "public"."text_messages_pkey";

drop table "public"."gift_messages";

drop table "public"."gifts";

drop table "public"."text_messages";

alter table "public"."messages" drop column "message_type";

alter table "public"."messages" add column "greeting_card_id" uuid;

alter table "public"."messages" add column "recipient_email" text;

alter table "public"."messages" add column "text_content" text;

alter table "public"."messages" add constraint "messages_greeting_card_id_fkey" FOREIGN KEY (greeting_card_id) REFERENCES greeting_cards(id) not valid;

alter table "public"."messages" validate constraint "messages_greeting_card_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.find_or_create_user_by_phone(input_phone_number text)
 RETURNS SETOF users
 LANGUAGE plpgsql
AS $function$
DECLARE
    user_record RECORD;
BEGIN
    -- Try to find existing user by phone number
    SELECT * INTO user_record 
    FROM users 
    WHERE users.phone_number = input_phone_number
    LIMIT 1;
    
    -- If user doesn't exist, create new user
    IF NOT FOUND THEN
        INSERT INTO users (phone_number)
        VALUES (input_phone_number)
        RETURNING * INTO user_record;
    END IF;
    
    -- Always return the whole user row (either existing or newly created)
    RETURN QUERY 
    SELECT * FROM users 
    WHERE users.phone_number = input_phone_number
    LIMIT 1;
END;
$function$
;


