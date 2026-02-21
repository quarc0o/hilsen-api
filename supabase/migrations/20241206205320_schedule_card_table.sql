
create table "public"."scheduled_cards" (
    "created_at" timestamp with time zone default now(),
    "sender_first_name" text,
    "recipient_email" text,
    "gift_id" uuid,
    "card_frontside_url" text,
    "chat_message_id" uuid default gen_random_uuid(),
    "conversation_id" uuid default gen_random_uuid(),
    "scheduled_at" timestamp with time zone,
    "id" uuid not null default gen_random_uuid()
);


CREATE UNIQUE INDEX scheduled_cards_pkey ON public.scheduled_cards USING btree (id);

alter table "public"."scheduled_cards" add constraint "scheduled_cards_pkey" PRIMARY KEY using index "scheduled_cards_pkey";

alter table "public"."scheduled_cards" add constraint "scheduled_cards_chat_message_id_fkey" FOREIGN KEY (chat_message_id) REFERENCES chat_messages(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."scheduled_cards" validate constraint "scheduled_cards_chat_message_id_fkey";

alter table "public"."scheduled_cards" add constraint "scheduled_cards_gift_id_fkey" FOREIGN KEY (gift_id) REFERENCES gifts(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."scheduled_cards" validate constraint "scheduled_cards_gift_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_scheduled_chat_messages()
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE
    scheduled_message RECORD;
    response jsonb;
BEGIN
    FOR scheduled_message IN
        SELECT *
        FROM public.chat_messages
        WHERE delivery_status = 'SCHEDULED'::delivery_status
          AND sent_at <= now() AT TIME ZONE 'UTC'
    LOOP
        RAISE LOG 'Current Time: %, Message ID: %, Sent At: %, Delivery Status: %',
            now(), scheduled_message.id, scheduled_message.sent_at, scheduled_message.delivery_status;

        -- Make the HTTP call
        response := (
            SELECT content
            FROM http_post(
                'http://10.149.56.177:3000/api/update_delivery_status',
                jsonb_build_object(
                    'id', scheduled_message.id,
                    'conversation_id', scheduled_message.conversation_id
                )::text,
                'application/json'
            )
        );

        RAISE LOG 'API Response: %', response;
    END LOOP;
END;$function$
;

grant delete on table "public"."scheduled_cards" to "anon";

grant insert on table "public"."scheduled_cards" to "anon";

grant references on table "public"."scheduled_cards" to "anon";

grant select on table "public"."scheduled_cards" to "anon";

grant trigger on table "public"."scheduled_cards" to "anon";

grant truncate on table "public"."scheduled_cards" to "anon";

grant update on table "public"."scheduled_cards" to "anon";

grant delete on table "public"."scheduled_cards" to "authenticated";

grant insert on table "public"."scheduled_cards" to "authenticated";

grant references on table "public"."scheduled_cards" to "authenticated";

grant select on table "public"."scheduled_cards" to "authenticated";

grant trigger on table "public"."scheduled_cards" to "authenticated";

grant truncate on table "public"."scheduled_cards" to "authenticated";

grant update on table "public"."scheduled_cards" to "authenticated";

grant delete on table "public"."scheduled_cards" to "service_role";

grant insert on table "public"."scheduled_cards" to "service_role";

grant references on table "public"."scheduled_cards" to "service_role";

grant select on table "public"."scheduled_cards" to "service_role";

grant trigger on table "public"."scheduled_cards" to "service_role";

grant truncate on table "public"."scheduled_cards" to "service_role";

grant update on table "public"."scheduled_cards" to "service_role";


