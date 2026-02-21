create type "public"."delivery_status" as enum ('SCHEDULED', 'DELIVERED', 'OPENED');

alter table "public"."chat_messages" add column "delivery_status" delivery_status;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_conversation_last_message(p_chat_message_id uuid, p_conversation_id uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Update all conversations with the given conversation_id
    UPDATE conversations
    SET last_message_id = p_chat_message_id
    WHERE id = p_conversation_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_initial_conversations(conversation_ids uuid[])
 RETURNS TABLE(id uuid, created_at timestamp with time zone, updated_at timestamp with time zone, last_message_id uuid, participant_phone_numbers text[], last_message json, latest_messages json[])
 LANGUAGE plpgsql
AS $function$BEGIN
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
        MIN(c.created_at) AS created_at,
        MIN(c.updated_at) AS updated_at,
        c.last_message_id,
        cp.participant_phone_numbers,
        (
            SELECT row_to_json(cm)
            FROM (
                SELECT 
                    cm.*, 
                    json_build_object(
                        'id', g.id,
                        'sent_at', g.sent_at,
                        'greeting_card', json_build_object(
                            'card_frontside_url', gc.card_frontside_url,
                            'card_backside_url', gc.card_backside_url
                        )
                    ) AS gift
                FROM chat_messages cm
                LEFT JOIN gifts g ON cm.gift_id = g.id
                LEFT JOIN greeting_cards gc ON g.greeting_card_id = gc.id
                WHERE cm.id = c.last_message_id
                LIMIT 1
            ) AS cm
        ) AS last_message,
        (
            SELECT array_agg(row_to_json(cm))
            FROM (
                SELECT 
                    cm.*, 
                    json_build_object(
                        'id', g.id,
                        'sent_at', g.sent_at,
                        'greeting_card', json_build_object(
                            'card_frontside_url', gc.card_frontside_url,
                            'card_backside_url', gc.card_backside_url
                        )
                    ) AS gift
                FROM chat_messages cm
                LEFT JOIN gifts g ON cm.gift_id = g.id
                LEFT JOIN greeting_cards gc ON g.greeting_card_id = gc.id
                WHERE cm.conversation_id = c.id
                  AND (cm.delivery_status = 'DELIVERED' OR cm.delivery_status = 'OPENED') 
                ORDER BY cm.created_at ASC
            ) AS cm
        ) AS latest_messages
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE c.id = ANY(conversation_ids)
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;$function$
;

DROP FUNCTION IF EXISTS public.insert_chat_message_with_gift(json);
CREATE OR REPLACE FUNCTION public.insert_chat_message_with_gift(chat_data json)
 RETURNS chat_messages
 LANGUAGE plpgsql
AS $function$DECLARE
    v_sent_at TIMESTAMPTZ := NOW();
    v_gift_id UUID;
    v_gift_sent_at TIMESTAMPTZ;
    v_card_backside_url TEXT;
    v_card_frontside_url TEXT;
    v_message TEXT;
    v_user_phone TEXT;
    v_conversation_id UUID;
    v_inserted_gift_id UUID;
    v_inserted_greeting_card_id UUID;
    v_new_message chat_messages;
BEGIN
    -- Extract fields from JSON
    v_sent_at := COALESCE((chat_data->>'sent_at')::TIMESTAMPTZ, v_sent_at);
    v_gift_id := NULLIF(chat_data->>'gift_id', 'null')::UUID;
    v_message := chat_data->>'message';
    v_user_phone := chat_data->>'user_phone';
    v_conversation_id := (chat_data->>'conversation_id')::UUID;

    -- Insert gift if present
    IF chat_data->'gift' IS NOT NULL THEN
        v_gift_sent_at := (chat_data->'gift'->>'sent_at')::TIMESTAMPTZ;

        IF chat_data->'gift'->'greeting_card' IS NOT NULL THEN
            v_card_backside_url := chat_data->'gift'->'greeting_card'->>'card_backside_url';
            v_card_frontside_url := chat_data->'gift'->'greeting_card'->>'card_frontside_url';

            INSERT INTO greeting_cards (card_backside_url, card_frontside_url)
            VALUES (v_card_backside_url, v_card_frontside_url)
            RETURNING id INTO v_inserted_greeting_card_id;
        END IF;

        INSERT INTO gifts (sent_at, greeting_card_id)
        VALUES (v_gift_sent_at, v_inserted_greeting_card_id)
        RETURNING id INTO v_inserted_gift_id;
    END IF;

    -- Insert chat message
    INSERT INTO chat_messages (sent_at, gift_id, message, user_phone, conversation_id)
    VALUES (v_sent_at, COALESCE(v_inserted_gift_id, v_gift_id), v_message, v_user_phone, v_conversation_id)
    RETURNING * INTO v_new_message;

    RETURN v_new_message;
END;$function$
;


