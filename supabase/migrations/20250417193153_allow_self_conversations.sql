set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_conversation(p_user_id_1 uuid, p_user_id_2 uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
 v_conversation_id UUID;
 v_result JSONB;
 v_last_message JSONB;
 v_last_message_content TEXT;
 v_participants JSONB;
 v_unread_count INTEGER;
 v_is_self_conversation BOOLEAN;
BEGIN
-- Check if users exist
 IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id_1) THEN
   RAISE EXCEPTION 'User with id % does not exist', p_user_id_1;
 END IF;
 
-- Check if it's a self-conversation
 v_is_self_conversation := (p_user_id_1 = p_user_id_2);
 
-- If it's not a self-conversation, verify the second user exists
 IF NOT v_is_self_conversation THEN
   IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id_2) THEN
     RAISE EXCEPTION 'User with id % does not exist', p_user_id_2;
   END IF;
 END IF;

-- Check if conversation already exists
 IF v_is_self_conversation THEN
   -- For self-conversations, look for a conversation with exactly one participant
   -- that is the specified user
   SELECT c.id INTO v_conversation_id
   FROM conversations c
   WHERE EXISTS (
     SELECT 1 
     FROM conversation_participants cp 
     WHERE cp.conversation_id = c.id AND cp.user_id = p_user_id_1
   )
   AND (
     SELECT COUNT(*) 
     FROM conversation_participants cp 
     WHERE cp.conversation_id = c.id
   ) = 1
   LIMIT 1;
 ELSE
   -- For regular conversations between two different users
   SELECT c.id INTO v_conversation_id
   FROM conversations c
   JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = p_user_id_1
   JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id = p_user_id_2
   LIMIT 1;
 END IF;

-- If conversation doesn't exist, create it
 IF v_conversation_id IS NULL THEN
   -- Create new conversation with UUID
   v_conversation_id := gen_random_uuid();
   INSERT INTO conversations (id, created_at)
   VALUES (v_conversation_id, CURRENT_TIMESTAMP);
   
   -- Add participant(s)
   IF v_is_self_conversation THEN
     -- For self-conversation, add the user only once
     INSERT INTO conversation_participants (conversation_id, user_id)
     VALUES (v_conversation_id, p_user_id_1);
   ELSE
     -- For regular conversation, add both users
     INSERT INTO conversation_participants (conversation_id, user_id)
     VALUES (v_conversation_id, p_user_id_1), (v_conversation_id, p_user_id_2);
   END IF;
 END IF;

-- The rest of the function remains the same
-- Get last message details
WITH last_msg AS (
SELECT
 m.id,
 m.sender_id,
 m.message_type,
 m.created_at
FROM messages m
WHERE m.conversation_id = v_conversation_id
ORDER BY m.created_at DESC
LIMIT 1
)
SELECT
 COALESCE(
 jsonb_build_object(
'id', lm.id,
'sender_id', lm.sender_id,
'message_type', lm.message_type,
'created_at', lm.created_at
),
 jsonb_build_object(
'id', NULL,
'sender_id', NULL,
'message_type', NULL,
'created_at', NULL
)
)
FROM last_msg lm INTO v_last_message;

-- Get participants details
SELECT
 jsonb_agg(
 jsonb_build_object(
'id', u.id,
'first_name', u.first_name,
'last_name', u.last_name,
'phone_number', u.phone_number,
'email', u.email
)
)
FROM users u
JOIN conversation_participants cp ON u.id = cp.user_id
WHERE cp.conversation_id = v_conversation_id
INTO v_participants;

-- Get unread count for user_id_1
SELECT
 COUNT(*)
FROM messages m
WHERE
 m.conversation_id = v_conversation_id AND
 m.sender_id != p_user_id_1 AND
(m.read_at IS NULL OR m.read_at > now())
INTO v_unread_count;

-- Build the final result
 v_result := jsonb_build_object(
'conversation_id', v_conversation_id,
'participants', v_participants,
'last_message', v_last_message,
'unread_count', v_unread_count
);

 RETURN v_result;
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id uuid)
 RETURNS SETOF jsonb
 LANGUAGE plpgsql
AS $function$BEGIN
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
 self_conversations AS (
   -- Identify self-conversations (conversations with only one participant)
   SELECT conversation_id 
   FROM conversation_participants
   GROUP BY conversation_id
   HAVING COUNT(*) = 1
 ),
 conversation_participants AS (
   -- For regular conversations (not self-conversations)
   SELECT
     cp.conversation_id,
     jsonb_agg(
       (SELECT row_to_json(u) FROM users u WHERE u.id = cp.user_id)
     ) AS participants
   FROM conversation_participants cp
   WHERE cp.conversation_id IN (
     SELECT conversation_id
     FROM conversation_participants
     WHERE user_id = p_user_id
   )
   AND (
     -- Include all participants for self-conversations
     cp.conversation_id IN (SELECT conversation_id FROM self_conversations)
     -- Exclude current user for regular conversations
     OR cp.user_id != p_user_id
   )
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
END;$function$
;


