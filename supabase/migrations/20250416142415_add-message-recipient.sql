revoke delete on table "public"."chat_messages" from "anon";

revoke insert on table "public"."chat_messages" from "anon";

revoke references on table "public"."chat_messages" from "anon";

revoke select on table "public"."chat_messages" from "anon";

revoke trigger on table "public"."chat_messages" from "anon";

revoke truncate on table "public"."chat_messages" from "anon";

revoke update on table "public"."chat_messages" from "anon";

revoke delete on table "public"."chat_messages" from "authenticated";

revoke insert on table "public"."chat_messages" from "authenticated";

revoke references on table "public"."chat_messages" from "authenticated";

revoke select on table "public"."chat_messages" from "authenticated";

revoke trigger on table "public"."chat_messages" from "authenticated";

revoke truncate on table "public"."chat_messages" from "authenticated";

revoke update on table "public"."chat_messages" from "authenticated";

revoke delete on table "public"."chat_messages" from "service_role";

revoke insert on table "public"."chat_messages" from "service_role";

revoke references on table "public"."chat_messages" from "service_role";

revoke select on table "public"."chat_messages" from "service_role";

revoke trigger on table "public"."chat_messages" from "service_role";

revoke truncate on table "public"."chat_messages" from "service_role";

revoke update on table "public"."chat_messages" from "service_role";

revoke delete on table "public"."chat_messages" from "supabase_auth_admin";

revoke insert on table "public"."chat_messages" from "supabase_auth_admin";

revoke references on table "public"."chat_messages" from "supabase_auth_admin";

revoke select on table "public"."chat_messages" from "supabase_auth_admin";

revoke trigger on table "public"."chat_messages" from "supabase_auth_admin";

revoke truncate on table "public"."chat_messages" from "supabase_auth_admin";

revoke update on table "public"."chat_messages" from "supabase_auth_admin";

revoke delete on table "public"."custom_gift_cards" from "anon";

revoke insert on table "public"."custom_gift_cards" from "anon";

revoke references on table "public"."custom_gift_cards" from "anon";

revoke select on table "public"."custom_gift_cards" from "anon";

revoke trigger on table "public"."custom_gift_cards" from "anon";

revoke truncate on table "public"."custom_gift_cards" from "anon";

revoke update on table "public"."custom_gift_cards" from "anon";

revoke delete on table "public"."custom_gift_cards" from "authenticated";

revoke insert on table "public"."custom_gift_cards" from "authenticated";

revoke references on table "public"."custom_gift_cards" from "authenticated";

revoke select on table "public"."custom_gift_cards" from "authenticated";

revoke trigger on table "public"."custom_gift_cards" from "authenticated";

revoke truncate on table "public"."custom_gift_cards" from "authenticated";

revoke update on table "public"."custom_gift_cards" from "authenticated";

revoke delete on table "public"."custom_gift_cards" from "service_role";

revoke insert on table "public"."custom_gift_cards" from "service_role";

revoke references on table "public"."custom_gift_cards" from "service_role";

revoke select on table "public"."custom_gift_cards" from "service_role";

revoke trigger on table "public"."custom_gift_cards" from "service_role";

revoke truncate on table "public"."custom_gift_cards" from "service_role";

revoke update on table "public"."custom_gift_cards" from "service_role";

alter table "public"."chat_messages" drop constraint "chat_messages_gift_id_fkey";

alter table "public"."custom_gift_cards" drop constraint "custom_gift_cards_user_id_fkey";

drop function if exists "public"."create_conversation"(participant_phone_numbers text[]);

drop function if exists "public"."find_conversation_by_participants"(participant_phone_numbers text[]);

alter table "public"."custom_gift_cards" drop constraint "custom_gift_cards_pkey";

drop index if exists "public"."custom_gift_cards_pkey";

drop table "public"."chat_messages";

drop table "public"."custom_gift_cards";

alter table "public"."conversations" drop column "last_message_id";

alter table "public"."conversations" drop column "user_phone";

alter table "public"."messages" add column "recipient_id" uuid;

CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id);

alter table "public"."conversations" add constraint "conversations_pkey" PRIMARY KEY using index "conversations_pkey";

alter table "public"."conversation_participants" add constraint "conversation_participants_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."conversation_participants" validate constraint "conversation_participants_conversation_id_fkey";

alter table "public"."messages" add constraint "messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."messages" validate constraint "messages_conversation_id_fkey";

alter table "public"."messages" add constraint "messages_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES users(id) ON DELETE SET NULL not valid;

alter table "public"."messages" validate constraint "messages_recipient_id_fkey";


