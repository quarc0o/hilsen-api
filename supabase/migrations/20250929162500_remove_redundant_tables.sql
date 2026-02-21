revoke delete on table "public"."persons" from "anon";

revoke insert on table "public"."persons" from "anon";

revoke references on table "public"."persons" from "anon";

revoke select on table "public"."persons" from "anon";

revoke trigger on table "public"."persons" from "anon";

revoke truncate on table "public"."persons" from "anon";

revoke update on table "public"."persons" from "anon";

revoke delete on table "public"."persons" from "authenticated";

revoke insert on table "public"."persons" from "authenticated";

revoke references on table "public"."persons" from "authenticated";

revoke select on table "public"."persons" from "authenticated";

revoke trigger on table "public"."persons" from "authenticated";

revoke truncate on table "public"."persons" from "authenticated";

revoke update on table "public"."persons" from "authenticated";

revoke delete on table "public"."persons" from "service_role";

revoke insert on table "public"."persons" from "service_role";

revoke references on table "public"."persons" from "service_role";

revoke select on table "public"."persons" from "service_role";

revoke trigger on table "public"."persons" from "service_role";

revoke truncate on table "public"."persons" from "service_role";

revoke update on table "public"."persons" from "service_role";

revoke delete on table "public"."persons" from "supabase_auth_admin";

revoke insert on table "public"."persons" from "supabase_auth_admin";

revoke references on table "public"."persons" from "supabase_auth_admin";

revoke select on table "public"."persons" from "supabase_auth_admin";

revoke trigger on table "public"."persons" from "supabase_auth_admin";

revoke truncate on table "public"."persons" from "supabase_auth_admin";

revoke update on table "public"."persons" from "supabase_auth_admin";

revoke delete on table "public"."scheduled_cards" from "anon";

revoke insert on table "public"."scheduled_cards" from "anon";

revoke references on table "public"."scheduled_cards" from "anon";

revoke select on table "public"."scheduled_cards" from "anon";

revoke trigger on table "public"."scheduled_cards" from "anon";

revoke truncate on table "public"."scheduled_cards" from "anon";

revoke update on table "public"."scheduled_cards" from "anon";

revoke delete on table "public"."scheduled_cards" from "authenticated";

revoke insert on table "public"."scheduled_cards" from "authenticated";

revoke references on table "public"."scheduled_cards" from "authenticated";

revoke select on table "public"."scheduled_cards" from "authenticated";

revoke trigger on table "public"."scheduled_cards" from "authenticated";

revoke truncate on table "public"."scheduled_cards" from "authenticated";

revoke update on table "public"."scheduled_cards" from "authenticated";

revoke delete on table "public"."scheduled_cards" from "service_role";

revoke insert on table "public"."scheduled_cards" from "service_role";

revoke references on table "public"."scheduled_cards" from "service_role";

revoke select on table "public"."scheduled_cards" from "service_role";

revoke trigger on table "public"."scheduled_cards" from "service_role";

revoke truncate on table "public"."scheduled_cards" from "service_role";

revoke update on table "public"."scheduled_cards" from "service_role";

revoke delete on table "public"."tag_categories" from "anon";

revoke insert on table "public"."tag_categories" from "anon";

revoke references on table "public"."tag_categories" from "anon";

revoke select on table "public"."tag_categories" from "anon";

revoke trigger on table "public"."tag_categories" from "anon";

revoke truncate on table "public"."tag_categories" from "anon";

revoke update on table "public"."tag_categories" from "anon";

revoke delete on table "public"."tag_categories" from "authenticated";

revoke insert on table "public"."tag_categories" from "authenticated";

revoke references on table "public"."tag_categories" from "authenticated";

revoke select on table "public"."tag_categories" from "authenticated";

revoke trigger on table "public"."tag_categories" from "authenticated";

revoke truncate on table "public"."tag_categories" from "authenticated";

revoke update on table "public"."tag_categories" from "authenticated";

revoke delete on table "public"."tag_categories" from "service_role";

revoke insert on table "public"."tag_categories" from "service_role";

revoke references on table "public"."tag_categories" from "service_role";

revoke select on table "public"."tag_categories" from "service_role";

revoke trigger on table "public"."tag_categories" from "service_role";

revoke truncate on table "public"."tag_categories" from "service_role";

revoke update on table "public"."tag_categories" from "service_role";

revoke delete on table "public"."tag_categories" from "supabase_auth_admin";

revoke insert on table "public"."tag_categories" from "supabase_auth_admin";

revoke references on table "public"."tag_categories" from "supabase_auth_admin";

revoke select on table "public"."tag_categories" from "supabase_auth_admin";

revoke trigger on table "public"."tag_categories" from "supabase_auth_admin";

revoke truncate on table "public"."tag_categories" from "supabase_auth_admin";

revoke update on table "public"."tag_categories" from "supabase_auth_admin";

alter table "public"."persons" drop constraint "persons_person_tag_category_id_fkey";

alter table "public"."persons" drop constraint "persons_user_id_fkey";

alter table "public"."scheduled_cards" drop constraint "scheduled_cards_greeting_card_id_fkey";

alter table "public"."scheduled_cards" drop constraint "scheduled_cards_recipient_id_fkey";

alter table "public"."scheduled_cards" drop constraint "scheduled_cards_sender_id_fkey";

alter table "public"."persons" drop constraint "persons_pkey";

alter table "public"."scheduled_cards" drop constraint "scheduled_cards_pkey";

alter table "public"."tag_categories" drop constraint "tag_categories_pkey";

drop index if exists "public"."persons_pkey";

drop index if exists "public"."scheduled_cards_pkey";

drop index if exists "public"."tag_categories_pkey";

drop table "public"."persons";

drop table "public"."scheduled_cards";

drop table "public"."tag_categories";


