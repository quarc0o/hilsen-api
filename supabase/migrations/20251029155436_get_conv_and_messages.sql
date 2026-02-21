set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_conversation_messages(p_user_id uuid, p_conversation_id uuid, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  is_participant boolean;
BEGIN
  -- Check if the user is a participant in this conversation
  SELECT EXISTS (
    SELECT 1
    FROM conversation_participants
    WHERE conversation_id = p_conversation_id
      AND user_id = p_user_id
  ) INTO is_participant;

  -- If user is not a participant, return empty array
  IF NOT is_participant THEN
    RETURN '[]'::jsonb;
  END IF;

  -- Return messages as JSON array
  RETURN (
    SELECT COALESCE(jsonb_agg(
      jsonb_build_object(
        'id', m.id,
        'created_at', m.created_at,
        'read_at', m.read_at,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'recipient_id', m.recipient_id,
        'greeting_card_id', m.greeting_card_id,
        'recipient_email', m.recipient_email,
        'text_content', m.text_content
      ) ORDER BY m.created_at ASC
    ), '[]'::jsonb)
    FROM (
      SELECT *
      FROM messages
      WHERE conversation_id = p_conversation_id
      ORDER BY created_at ASC
      LIMIT p_limit
      OFFSET p_offset
    ) m
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id uuid)
 RETURNS TABLE(conversation_id uuid, conversation_updated_at timestamp with time zone, participant jsonb, last_message jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
  RETURN QUERY
  WITH user_conversations AS (
    -- Get all conversations where the user is a participant
    SELECT DISTINCT c.id, c.updated_at
    FROM conversations c
    INNER JOIN conversation_participants cp ON c.id = cp.conversation_id
    WHERE cp.user_id = p_user_id
  ),
  other_participants AS (
    -- Get the other participant(s) in each conversation
    SELECT
      cp.conversation_id,
      jsonb_build_object(
        'id', u.id,
        'email', u.email,
        'first_name', u.first_name,
        'last_name', u.last_name,
        'phone_number', u.phone_number,
        'supabase_id', u.supabase_id,
        'display_name', COALESCE(
          NULLIF(TRIM(CONCAT(u.first_name, ' ', u.last_name)), ''),
          u.phone_number,
          u.email,
          'Unknown'
        )
      ) as participant_json
    FROM conversation_participants cp
    INNER JOIN users u ON cp.user_id = u.id
    WHERE cp.user_id != p_user_id
      AND cp.conversation_id IN (SELECT id FROM user_conversations)
  ),
  last_messages AS (
    -- Get the last message for each conversation
    SELECT DISTINCT ON (m.conversation_id)
      m.conversation_id,
      jsonb_build_object(
        'id', m.id,
        'created_at', m.created_at,
        'read_at', m.read_at,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'recipient_id', m.recipient_id,
        'greeting_card_id', m.greeting_card_id,
        'recipient_email', m.recipient_email,
        'text_content', m.text_content
      ) as message_json
    FROM messages m
    WHERE m.conversation_id IN (SELECT id FROM user_conversations)
    ORDER BY m.conversation_id, m.created_at DESC
  )
  SELECT
    uc.id as conversation_id,
    uc.updated_at as conversation_updated_at,
    op.participant_json as participant,
    lm.message_json as last_message
  FROM user_conversations uc
  LEFT JOIN other_participants op ON uc.id = op.conversation_id
  LEFT JOIN last_messages lm ON uc.id = lm.conversation_id
  ORDER BY uc.updated_at DESC;
END;
$function$
;


