drop function if exists "public"."send_gift"(p_sender_id uuid, p_conversation_id uuid, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric, p_gift_card_currency character varying, p_gift_card_retailer character varying, p_stripe_payment_id character varying);

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.send_gift(p_conversation_id uuid, p_sender_id uuid, p_front_image_url text, p_back_image_url text, p_greeting_message text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_message_id UUID;
  v_greeting_card_id UUID;
  v_result JSONB;
BEGIN
  -- Check if sender is part of the conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = p_sender_id
  ) THEN
    RAISE EXCEPTION 'User % is not a participant in conversation %', p_sender_id, p_conversation_id;
  END IF;

  -- Generate UUIDs
  v_message_id := gen_random_uuid();
  v_greeting_card_id := gen_random_uuid();

  -- Create greeting card
  INSERT INTO greeting_cards (
    id,
    card_frontside_url,
    card_backside_url,
    message,
    created_at
  ) VALUES (
    v_greeting_card_id,
    p_front_image_url,
    p_back_image_url,
    p_greeting_message,
    CURRENT_TIMESTAMP
  );

  -- Insert into messages table
  INSERT INTO messages (
    id,
    conversation_id,
    sender_id,
    message_type,
    created_at
  ) VALUES (
    v_message_id,
    p_conversation_id,
    p_sender_id,
    'gift',
    CURRENT_TIMESTAMP
  );

  -- Insert into gift_messages table
  INSERT INTO gift_messages (
    message_id,
    greeting_card_id
  ) VALUES (
    v_message_id,
    v_greeting_card_id
  );

  -- Get the complete gift message data
  SELECT jsonb_build_object(
    'message_id', m.id,
    'conversation_id', m.conversation_id,
    'sender_id', m.sender_id,
    'message_type', m.message_type,
    'created_at', m.created_at,
    'read_at', m.read_at,
    'gift', jsonb_build_object(
      'greeting_card', jsonb_build_object(
        'id', gc.id,
        'card_frontside_url', gc.card_frontside_url,
        'card_backside_url', gc.card_backside_url,
        'message', gc.message
      )
    )
  ) INTO v_result
  FROM messages m
  JOIN users u ON m.sender_id = u.id
  JOIN gift_messages gm ON m.id = gm.message_id
  JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
  WHERE m.id = v_message_id;

  RETURN v_result;
END;
$function$
;


