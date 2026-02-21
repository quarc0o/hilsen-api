alter table "public"."users" drop constraint "users_supabase_id_fkey";

alter table "public"."users" add constraint "users_supabase_id_fkey" FOREIGN KEY (supabase_id) REFERENCES auth.users(id) ON DELETE SET NULL not valid;

alter table "public"."users" validate constraint "users_supabase_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_deleted_auth_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
DELETE FROM public.users
WHERE id = OLD.id;

RETURN OLD;
END;$function$
;


