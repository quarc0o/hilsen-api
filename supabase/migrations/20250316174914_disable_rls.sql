drop function if exists "public"."get_conversation_messages"(p_user_id integer, p_conversation_id integer, p_limit integer, p_offset integer);

drop function if exists "public"."get_user_conversations"(p_user_id integer);

drop function if exists "public"."get_user_conversations"(p_user_id uuid);

alter table "public"."conversation_participants" disable row level security;

alter table "public"."text_messages" disable row level security;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id uuid)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.id AS message_id,
            m.sender_id,
            m.message_type,
            m.created_at,
            CASE 
                WHEN m.message_type = 'text' THEN tm.content
                WHEN m.message_type = 'gift' THEN gc.message
                ELSE NULL
            END AS preview_text,
            (SELECT COUNT(*) FROM messages 
             WHERE conversation_id = m.conversation_id 
             AND sender_id != p_user_id 
             AND read_at IS NULL) AS unread_count
        FROM messages m
        LEFT JOIN text_messages tm ON m.id = tm.message_id AND m.message_type = 'text'
        LEFT JOIN gift_messages gm ON m.id = gm.message_id AND m.message_type = 'gift'
        LEFT JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
        WHERE m.conversation_id IN (
            SELECT conversation_id 
            FROM conversation_participants 
            WHERE user_id = p_user_id
        )
        ORDER BY m.conversation_id, m.created_at DESC
    ),
    conversation_participants AS (
        SELECT 
            cp.conversation_id,
            jsonb_agg(
                jsonb_build_object(
                    'user_id', cp.user_id
                )
            ) AS participants
        FROM conversation_participants cp
        WHERE cp.conversation_id IN (
            SELECT conversation_id 
            FROM conversation_participants 
            WHERE user_id = p_user_id
        )
        AND cp.user_id != p_user_id -- Exclude the current user
        GROUP BY cp.conversation_id
    )
    SELECT 
        jsonb_build_object(
            'conversation_id', lm.conversation_id,
            'participants', cp.participants,
            'last_message', jsonb_build_object(
                'message_id', lm.message_id,
                'sender_id', lm.sender_id,
                'message_type', lm.message_type,
                'preview_text', lm.preview_text,
                'created_at', lm.created_at
            ),
            'unread_count', lm.unread_count
        )
    FROM latest_messages lm
    JOIN conversation_participants cp ON lm.conversation_id = cp.conversation_id
    ORDER BY lm.created_at DESC;
END;
$function$
;


