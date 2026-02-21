set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_conversation_messages(p_user_id uuid, p_conversation_id uuid, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(message_data jsonb)
 LANGUAGE plpgsql
AS $function$BEGIN
  -- Check if user is part of the conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'User % is not a participant in conversation %', p_user_id, p_conversation_id;
  END IF;
  
  -- Mark unread messages as read
  UPDATE messages
  SET read_at = CURRENT_TIMESTAMP
  WHERE conversation_id = p_conversation_id
  AND sender_id != p_user_id
  AND read_at IS NULL;
  
  RETURN QUERY
  WITH message_data AS (
    SELECT
      m.id,
      m.sender_id,
      m.message_type,
      m.created_at,
      m.read_at,
      -- Text message content
      CASE WHEN m.message_type = 'text' THEN
        jsonb_build_object('content', tm.content)
      ELSE NULL END AS text_data,
      -- Gift message content
      CASE WHEN m.message_type = 'gift' THEN
        jsonb_build_object(
          'greeting_card', jsonb_build_object(
            'id', gc.id,
            'front_image_url', gc.card_frontside_url,
            'back_image_url', gc.card_backside_url,
            'message', gc.message
          )
        )
      ELSE NULL END AS gift_data
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    LEFT JOIN text_messages tm ON m.id = tm.message_id AND m.message_type = 'text'
    LEFT JOIN gift_messages gm ON m.id = gm.message_id AND m.message_type = 'gift'
    LEFT JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
    WHERE m.conversation_id = p_conversation_id
    ORDER BY m.created_at DESC
    LIMIT p_limit OFFSET p_offset
  )
  SELECT
    jsonb_build_object(
      'message_type', md.message_type,
      'message_id', md.id,
      'sender_id', md.sender_id,
      'created_at', md.created_at,
      'read_at', md.read_at,
      'data', CASE
        WHEN md.message_type = 'text' THEN md.text_data
        WHEN md.message_type = 'gift' THEN md.gift_data
        ELSE NULL
      END
    ) AS message_data
  FROM message_data md
  ORDER BY md.created_at ASC; -- Re-order for display (newest messages at bottom)
END;$function$
;


