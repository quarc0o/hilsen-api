set check_function_bodies = off;

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
        MIN(c.created_at) AS created_at,  -- Use MIN/MAX to avoid grouping issues
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
            ) AS cm  -- Ensure only one row is returned for last_message
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
                ORDER BY cm.created_at ASC
                LIMIT 20
            ) AS cm  -- Fetch the latest 20 messages
        ) AS latest_messages
    FROM conversations c
    LEFT JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE c.id = ANY(conversation_ids)
    GROUP BY c.id, c.last_message_id, cp.participant_phone_numbers;
END;
$function$
;


