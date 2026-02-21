alter table "public"."chat_messages" drop constraint "fk_chat_messages_conversation";

alter table "public"."chat_messages" drop constraint "public_chat_messages_gift_id_fkey";

alter table "public"."chat_messages" alter column "sent_at" set default now();

alter table "public"."chat_messages" add constraint "chat_messages_gift_id_fkey" FOREIGN KEY (gift_id) REFERENCES gifts(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."chat_messages" validate constraint "chat_messages_gift_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_conversation_by_id(p_conversation_id uuid)
 RETURNS TABLE(id uuid, created_at timestamp with time zone, updated_at timestamp with time zone, last_message_id uuid, participant_phone_numbers text[], last_message json)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH conversation_participants AS (
        SELECT 
            c.id AS conversation_id,
            ARRAY_AGG(DISTINCT c.user_phone) AS participant_phone_numbers
        FROM conversations c
        WHERE c.id = p_conversation_id  -- Fetch the conversation by its ID
        GROUP BY c.id
    )
    SELECT 
        c.id,
        MIN(c.created_at) AS created_at,  -- Use MIN to avoid grouping issues
        MIN(c.updated_at) AS updated_at,
        c.last_message_id,
        cp.participant_phone_numbers,
        (
            SELECT row_to_json(cm)
            FROM chat_messages cm
            WHERE cm.id = c.last_message_id
            LIMIT 1  -- Ensure only one row is returned for last_message
        ) AS last_message
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE c.id = p_conversation_id  -- Fetch based on conversation ID
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_conversations(conversation_ids uuid[])
 RETURNS TABLE(id uuid, created_at timestamp with time zone, updated_at timestamp with time zone, last_message_id uuid, participant_phone_numbers text[], last_message json)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH conversation_participants AS (
        SELECT 
            c.id AS conversation_id,
            ARRAY_AGG(DISTINCT c.user_phone) AS participant_phone_numbers
        FROM conversations c
        WHERE c.id = ANY(conversation_ids)
        GROUP BY c.id
    )
    SELECT 
        c.id,
        MIN(c.created_at) AS created_at,  -- Use MIN/MAX to avoid grouping issues
        MIN(c.updated_at) AS updated_at,
        c.last_message_id,
        cp.participant_phone_numbers,
        (
            SELECT row_to_json(cm)
            FROM chat_messages cm
            WHERE cm.id = c.last_message_id
            LIMIT 1  -- Ensure only one row is returned for last_message
        ) AS last_message
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE c.id = ANY(conversation_ids)
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test(p_user_phone text)
 RETURNS TABLE(id uuid, created_at timestamp with time zone, updated_at timestamp with time zone, last_message_id uuid, participant_phone_numbers text[], last_message json)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH conversation_participants AS (
        SELECT 
            c.id AS conversation_id,
            ARRAY_AGG(DISTINCT c.user_phone) AS participant_phone_numbers
        FROM conversations c
        WHERE c.id IN (
            -- Find conversation IDs where the provided user is a participant
            SELECT c2.id 
            FROM conversations c2
            WHERE c2.user_phone = p_user_phone
        )
        GROUP BY c.id
    )
    SELECT 
        c.id,
        MIN(c.created_at) AS created_at,  -- Use MIN to avoid grouping issues
        MIN(c.updated_at) AS updated_at,
        c.last_message_id,
        cp.participant_phone_numbers,
        (
            SELECT row_to_json(cm)
            FROM chat_messages cm
            WHERE cm.id = c.last_message_id
            LIMIT 1  -- Ensure only one row is returned for last_message
        ) AS last_message
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE cp.participant_phone_numbers IS NOT NULL  -- Only return conversations with participants
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.test_conv(p_user_phone text)
 RETURNS TABLE(id uuid, created_at timestamp without time zone, updated_at timestamp without time zone, last_message_id uuid, participant_phone_numbers text[], last_message json)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH conversation_participants AS (
        SELECT 
            c.id AS conversation_id,
            ARRAY_AGG(DISTINCT c.user_phone) AS participant_phone_numbers
        FROM conversations c
        WHERE c.id = ANY(conversation_ids)
        GROUP BY c.id
    )
    SELECT 
        c.id,
        MIN(c.created_at) AS created_at,  -- Use MIN/MAX to avoid grouping issues
        MIN(c.updated_at) AS updated_at,
        c.last_message_id,
        cp.participant_phone_numbers,
        (
            SELECT row_to_json(cm)
            FROM chat_messages cm
            WHERE cm.id = c.last_message_id
            LIMIT 1  -- Ensure only one row is returned for last_message
        ) AS last_message
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE c.id = ANY(conversation_ids)
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;
$function$
;


