set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  INSERT INTO public.users (id, phone_number)
  VALUES (NEW.id, NEW.phone);
  RETURN NEW;
END;
$function$
;

grant delete on table "public"."chat_messages" to "supabase_auth_admin";

grant insert on table "public"."chat_messages" to "supabase_auth_admin";

grant references on table "public"."chat_messages" to "supabase_auth_admin";

grant select on table "public"."chat_messages" to "supabase_auth_admin";

grant trigger on table "public"."chat_messages" to "supabase_auth_admin";

grant truncate on table "public"."chat_messages" to "supabase_auth_admin";

grant update on table "public"."chat_messages" to "supabase_auth_admin";

grant delete on table "public"."conversations" to "supabase_auth_admin";

grant insert on table "public"."conversations" to "supabase_auth_admin";

grant references on table "public"."conversations" to "supabase_auth_admin";

grant select on table "public"."conversations" to "supabase_auth_admin";

grant trigger on table "public"."conversations" to "supabase_auth_admin";

grant truncate on table "public"."conversations" to "supabase_auth_admin";

grant update on table "public"."conversations" to "supabase_auth_admin";

grant delete on table "public"."gift_cards" to "supabase_auth_admin";

grant insert on table "public"."gift_cards" to "supabase_auth_admin";

grant references on table "public"."gift_cards" to "supabase_auth_admin";

grant select on table "public"."gift_cards" to "supabase_auth_admin";

grant trigger on table "public"."gift_cards" to "supabase_auth_admin";

grant truncate on table "public"."gift_cards" to "supabase_auth_admin";

grant update on table "public"."gift_cards" to "supabase_auth_admin";

grant delete on table "public"."gifts" to "supabase_auth_admin";

grant insert on table "public"."gifts" to "supabase_auth_admin";

grant references on table "public"."gifts" to "supabase_auth_admin";

grant select on table "public"."gifts" to "supabase_auth_admin";

grant trigger on table "public"."gifts" to "supabase_auth_admin";

grant truncate on table "public"."gifts" to "supabase_auth_admin";

grant update on table "public"."gifts" to "supabase_auth_admin";

grant delete on table "public"."greeting_cards" to "supabase_auth_admin";

grant insert on table "public"."greeting_cards" to "supabase_auth_admin";

grant references on table "public"."greeting_cards" to "supabase_auth_admin";

grant select on table "public"."greeting_cards" to "supabase_auth_admin";

grant trigger on table "public"."greeting_cards" to "supabase_auth_admin";

grant truncate on table "public"."greeting_cards" to "supabase_auth_admin";

grant update on table "public"."greeting_cards" to "supabase_auth_admin";

grant delete on table "public"."persons" to "supabase_auth_admin";

grant insert on table "public"."persons" to "supabase_auth_admin";

grant references on table "public"."persons" to "supabase_auth_admin";

grant select on table "public"."persons" to "supabase_auth_admin";

grant trigger on table "public"."persons" to "supabase_auth_admin";

grant truncate on table "public"."persons" to "supabase_auth_admin";

grant update on table "public"."persons" to "supabase_auth_admin";

grant delete on table "public"."tag_categories" to "supabase_auth_admin";

grant insert on table "public"."tag_categories" to "supabase_auth_admin";

grant references on table "public"."tag_categories" to "supabase_auth_admin";

grant select on table "public"."tag_categories" to "supabase_auth_admin";

grant trigger on table "public"."tag_categories" to "supabase_auth_admin";

grant truncate on table "public"."tag_categories" to "supabase_auth_admin";

grant update on table "public"."tag_categories" to "supabase_auth_admin";

grant delete on table "public"."users" to "supabase_auth_admin";

grant insert on table "public"."users" to "supabase_auth_admin";

grant references on table "public"."users" to "supabase_auth_admin";

grant select on table "public"."users" to "supabase_auth_admin";

grant trigger on table "public"."users" to "supabase_auth_admin";

grant truncate on table "public"."users" to "supabase_auth_admin";

grant update on table "public"."users" to "supabase_auth_admin";


