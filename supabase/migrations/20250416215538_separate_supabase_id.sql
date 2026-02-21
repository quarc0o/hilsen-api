alter table "public"."users" add column "supabase_id" uuid;

alter table "public"."users" alter column "id" set default gen_random_uuid();

alter table "public"."users" add constraint "users_supabase_id_fkey" FOREIGN KEY (supabase_id) REFERENCES auth.users(id) not valid;

alter table "public"."users" validate constraint "users_supabase_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Check if phone number exists in public.users
  IF EXISTS (SELECT 1 FROM public.users WHERE phone_number = NEW.phone) THEN
    -- Update existing record with new supabase_id
    UPDATE public.users
    SET supabase_id = NEW.id
    WHERE phone_number = NEW.phone;
  ELSE
    -- Insert new record if phone number doesn't exist
    INSERT INTO public.users (supabase_id, phone_number)
    VALUES (NEW.id, NEW.phone);
  END IF;
  
  RETURN NEW;
END;
$function$
;


