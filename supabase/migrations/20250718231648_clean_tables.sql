revoke delete on table "public"."gift_card_products" from "anon";

revoke insert on table "public"."gift_card_products" from "anon";

revoke references on table "public"."gift_card_products" from "anon";

revoke select on table "public"."gift_card_products" from "anon";

revoke trigger on table "public"."gift_card_products" from "anon";

revoke truncate on table "public"."gift_card_products" from "anon";

revoke update on table "public"."gift_card_products" from "anon";

revoke delete on table "public"."gift_card_products" from "authenticated";

revoke insert on table "public"."gift_card_products" from "authenticated";

revoke references on table "public"."gift_card_products" from "authenticated";

revoke select on table "public"."gift_card_products" from "authenticated";

revoke trigger on table "public"."gift_card_products" from "authenticated";

revoke truncate on table "public"."gift_card_products" from "authenticated";

revoke update on table "public"."gift_card_products" from "authenticated";

revoke delete on table "public"."gift_card_products" from "service_role";

revoke insert on table "public"."gift_card_products" from "service_role";

revoke references on table "public"."gift_card_products" from "service_role";

revoke select on table "public"."gift_card_products" from "service_role";

revoke trigger on table "public"."gift_card_products" from "service_role";

revoke truncate on table "public"."gift_card_products" from "service_role";

revoke update on table "public"."gift_card_products" from "service_role";

revoke delete on table "public"."gift_cards" from "anon";

revoke insert on table "public"."gift_cards" from "anon";

revoke references on table "public"."gift_cards" from "anon";

revoke select on table "public"."gift_cards" from "anon";

revoke trigger on table "public"."gift_cards" from "anon";

revoke truncate on table "public"."gift_cards" from "anon";

revoke update on table "public"."gift_cards" from "anon";

revoke delete on table "public"."gift_cards" from "authenticated";

revoke insert on table "public"."gift_cards" from "authenticated";

revoke references on table "public"."gift_cards" from "authenticated";

revoke select on table "public"."gift_cards" from "authenticated";

revoke trigger on table "public"."gift_cards" from "authenticated";

revoke truncate on table "public"."gift_cards" from "authenticated";

revoke update on table "public"."gift_cards" from "authenticated";

revoke delete on table "public"."gift_cards" from "service_role";

revoke insert on table "public"."gift_cards" from "service_role";

revoke references on table "public"."gift_cards" from "service_role";

revoke select on table "public"."gift_cards" from "service_role";

revoke trigger on table "public"."gift_cards" from "service_role";

revoke truncate on table "public"."gift_cards" from "service_role";

revoke update on table "public"."gift_cards" from "service_role";

revoke delete on table "public"."gift_cards" from "supabase_auth_admin";

revoke insert on table "public"."gift_cards" from "supabase_auth_admin";

revoke references on table "public"."gift_cards" from "supabase_auth_admin";

revoke select on table "public"."gift_cards" from "supabase_auth_admin";

revoke trigger on table "public"."gift_cards" from "supabase_auth_admin";

revoke truncate on table "public"."gift_cards" from "supabase_auth_admin";

revoke update on table "public"."gift_cards" from "supabase_auth_admin";

revoke delete on table "public"."transactions" from "anon";

revoke insert on table "public"."transactions" from "anon";

revoke references on table "public"."transactions" from "anon";

revoke select on table "public"."transactions" from "anon";

revoke trigger on table "public"."transactions" from "anon";

revoke truncate on table "public"."transactions" from "anon";

revoke update on table "public"."transactions" from "anon";

revoke delete on table "public"."transactions" from "authenticated";

revoke insert on table "public"."transactions" from "authenticated";

revoke references on table "public"."transactions" from "authenticated";

revoke select on table "public"."transactions" from "authenticated";

revoke trigger on table "public"."transactions" from "authenticated";

revoke truncate on table "public"."transactions" from "authenticated";

revoke update on table "public"."transactions" from "authenticated";

revoke delete on table "public"."transactions" from "service_role";

revoke insert on table "public"."transactions" from "service_role";

revoke references on table "public"."transactions" from "service_role";

revoke select on table "public"."transactions" from "service_role";

revoke trigger on table "public"."transactions" from "service_role";

revoke truncate on table "public"."transactions" from "service_role";

revoke update on table "public"."transactions" from "service_role";

alter table "public"."gift_card_products" drop constraint "gift_card_products_id_key";

alter table "public"."gift_messages" drop constraint "gift_messages_gift_card_id_fkey";

alter table "public"."gift_messages" drop constraint "gift_messages_transaction_id_fkey";

alter table "public"."scheduled_cards" drop constraint "scheduled_cards_gift_id_fkey";

alter table "public"."transactions" drop constraint "transactions_recipient_id_fkey";

alter table "public"."transactions" drop constraint "transactions_sender_id_fkey";

alter table "public"."gift_card_products" drop constraint "gift_card_products_pkey";

alter table "public"."gift_cards" drop constraint "gift_cards_pkey";

alter table "public"."transactions" drop constraint "transactions_pkey";

drop index if exists "public"."gift_card_products_id_key";

drop index if exists "public"."gift_card_products_pkey";

drop index if exists "public"."gift_cards_pkey";

drop index if exists "public"."transactions_pkey";

drop table "public"."gift_card_products";

drop table "public"."gift_cards";

drop table "public"."transactions";

alter table "public"."gift_messages" drop column "gift_card_id";

alter table "public"."gift_messages" drop column "transaction_id";

alter table "public"."scheduled_cards" drop column "gift_id";


