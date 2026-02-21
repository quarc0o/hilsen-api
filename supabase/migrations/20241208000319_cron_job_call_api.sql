
drop function if exists "public"."get_scheduled_chat_messages"();

create table "public"."environment_metadata" (
    "key" text not null,
    "value" text
);


CREATE UNIQUE INDEX environment_metadata_pkey ON public.environment_metadata USING btree (key);

alter table "public"."environment_metadata" add constraint "environment_metadata_pkey" PRIMARY KEY using index "environment_metadata_pkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_message_delivery_status()
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    environment TEXT;
    base_url TEXT;
    full_url TEXT;
    response JSONB;
BEGIN
    -- Get the environment from the environment_metadata table
    SELECT value INTO environment
    FROM environment_metadata
    WHERE key = 'environment';

    -- Determine the base URL based on the environment
    IF environment = 'dev' THEN
        base_url := 'http://host.docker.internal:3000/api';
    ELSIF environment = 'stage' THEN
        base_url := 'https://www.dev.hilsen.app/api';
    ELSIF environment = 'prod' THEN
        base_url := 'https://www.hilsen.app/api';
    ELSE
        RAISE EXCEPTION 'Unknown environment: %', environment;
    END IF;

    -- Construct the full URL
    full_url := base_url || '/update_delivery_status';

    -- Make the HTTP GET request
    SELECT content INTO response
    FROM http_get(full_url);

    -- Return the response from the HTTP call
    RETURN response;
END;$function$
;

grant delete on table "public"."environment_metadata" to "anon";

grant insert on table "public"."environment_metadata" to "anon";

grant references on table "public"."environment_metadata" to "anon";

grant select on table "public"."environment_metadata" to "anon";

grant trigger on table "public"."environment_metadata" to "anon";

grant truncate on table "public"."environment_metadata" to "anon";

grant update on table "public"."environment_metadata" to "anon";

grant delete on table "public"."environment_metadata" to "authenticated";

grant insert on table "public"."environment_metadata" to "authenticated";

grant references on table "public"."environment_metadata" to "authenticated";

grant select on table "public"."environment_metadata" to "authenticated";

grant trigger on table "public"."environment_metadata" to "authenticated";

grant truncate on table "public"."environment_metadata" to "authenticated";

grant update on table "public"."environment_metadata" to "authenticated";

grant delete on table "public"."environment_metadata" to "service_role";

grant insert on table "public"."environment_metadata" to "service_role";

grant references on table "public"."environment_metadata" to "service_role";

grant select on table "public"."environment_metadata" to "service_role";

grant trigger on table "public"."environment_metadata" to "service_role";

grant truncate on table "public"."environment_metadata" to "service_role";

grant update on table "public"."environment_metadata" to "service_role";


