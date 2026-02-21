-- Modular gift card functions
-- This migration breaks down the monolithic send_gift function into smaller, reusable pieces

-- 1. Core function to create greeting card
CREATE OR REPLACE FUNCTION gc_create_greeting_card(
  p_front_image_url TEXT,
  p_back_image_url TEXT,
  p_greeting_message TEXT
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_greeting_card_id UUID;
BEGIN
  -- Validation
  IF p_front_image_url IS NULL OR p_back_image_url IS NULL THEN
    RAISE EXCEPTION 'Card images cannot be null';
  END IF;

  v_greeting_card_id := gen_random_uuid();
  
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
  
  RETURN v_greeting_card_id;
END;
$$;

-- 2. Core function to create message entry
CREATE OR REPLACE FUNCTION gc_create_message_entry(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_greeting_card_id UUID
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_message_id UUID;
BEGIN
  -- Validation: Check if sender is in conversation
  IF NOT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id AND user_id = p_sender_id
  ) THEN
    RAISE EXCEPTION 'User % is not a participant in conversation %', p_sender_id, p_conversation_id;
  END IF;

  -- Validation: Check if greeting card exists
  IF NOT EXISTS (
    SELECT 1 FROM greeting_cards WHERE id = p_greeting_card_id
  ) THEN
    RAISE EXCEPTION 'Greeting card % does not exist', p_greeting_card_id;
  END IF;

  v_message_id := gen_random_uuid();
  
  -- Insert message
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
  
  -- Link to gift
  INSERT INTO gift_messages (
    message_id, 
    greeting_card_id
  ) VALUES (
    v_message_id, 
    p_greeting_card_id
  );
  
  RETURN v_message_id;
END;
$$;

-- 3. Helper function to get formatted gift message result
CREATE OR REPLACE FUNCTION gc_get_gift_message_json(
  p_message_id UUID
) RETURNS JSONB
LANGUAGE plpgsql
AS $$
DECLARE
  v_result JSONB;
BEGIN
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
  JOIN gift_messages gm ON m.id = gm.message_id
  JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
  WHERE m.id = p_message_id;
  
  IF v_result IS NULL THEN
    RAISE EXCEPTION 'Gift message % not found', p_message_id;
  END IF;
  
  RETURN v_result;
END;
$$;

-- 4. Main orchestration function for immediate sending
CREATE OR REPLACE FUNCTION gc_send_gift_now(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_front_image_url TEXT,
  p_back_image_url TEXT,
  p_greeting_message TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_greeting_card_id UUID;
  v_message_id UUID;
  v_result JSONB;
BEGIN
  -- Create greeting card
  v_greeting_card_id := gc_create_greeting_card(
    p_front_image_url,
    p_back_image_url,
    p_greeting_message
  );
  
  -- Create message entry
  v_message_id := gc_create_message_entry(
    p_conversation_id,
    p_sender_id,
    v_greeting_card_id
  );
  
  -- Get formatted result
  v_result := gc_get_gift_message_json(v_message_id);
  
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error details for debugging
    RAISE NOTICE 'Error in gc_send_gift_now: %', SQLERRM;
    RAISE;
END;
$$;

-- Create alias for backward compatibility
-- This allows existing code to continue working
CREATE OR REPLACE FUNCTION send_gift(
  p_conversation_id UUID,
  p_sender_id UUID,
  p_front_image_url TEXT,
  p_back_image_url TEXT,
  p_greeting_message TEXT
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Simply delegate to the new modular function
  RETURN gc_send_gift_now(
    p_conversation_id,
    p_sender_id,
    p_front_image_url,
    p_back_image_url,
    p_greeting_message
  );
END;
$$;

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION gc_create_greeting_card TO authenticated;
GRANT EXECUTE ON FUNCTION gc_create_message_entry TO authenticated;
GRANT EXECUTE ON FUNCTION gc_get_gift_message_json TO authenticated;
GRANT EXECUTE ON FUNCTION gc_send_gift_now TO authenticated;
GRANT EXECUTE ON FUNCTION send_gift TO authenticated;