set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_delete_user()
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  -- First update the public.users table to remove personal data
  UPDATE public.users 
  SET 
    first_name = NULL,
    last_name = NULL,
    email = NULL
  WHERE supabase_id = auth.uid();
  
  -- Then delete the auth user
  DELETE FROM auth.users WHERE id = auth.uid();
$function$
;


