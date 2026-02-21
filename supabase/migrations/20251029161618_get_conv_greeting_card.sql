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

  -- Return messages as JSON array with greeting card data
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
        'text_content', m.text_content,
        'greeting_card', CASE
          WHEN gc.id IS NOT NULL THEN
            jsonb_build_object(
              'id', gc.id,
              'card_frontside_url', gc.card_frontside_url,
              'card_backside_url', gc.card_backside_url,
              'message', gc.message
            )
          ELSE NULL
        END
      ) ORDER BY m.created_at ASC
    ), '[]'::jsonb)
    FROM (
      SELECT m.*, gc.id as gc_id, gc.card_frontside_url, gc.card_backside_url, gc.message as gc_message
      FROM messages m
      LEFT JOIN greeting_cards gc ON m.greeting_card_id = gc.id
      WHERE m.conversation_id = p_conversation_id
      ORDER BY m.created_at ASC
      LIMIT p_limit
      OFFSET p_offset
    ) m
    LEFT JOIN greeting_cards gc ON m.greeting_card_id = gc.id
  );
END;
$function$
;


