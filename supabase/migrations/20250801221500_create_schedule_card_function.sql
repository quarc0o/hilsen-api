-- Add greeting_card_id column if it doesn't exist
ALTER TABLE scheduled_cards 
  ADD COLUMN IF NOT EXISTS greeting_card_id UUID;

-- Fix the scheduled_cards foreign key constraint
ALTER TABLE scheduled_cards DROP CONSTRAINT IF EXISTS scheduled_cards_greeting_card_id_fkey;
ALTER TABLE scheduled_cards 
  ADD CONSTRAINT scheduled_cards_greeting_card_id_fkey 
  FOREIGN KEY (greeting_card_id) REFERENCES greeting_cards(id) ON DELETE CASCADE;

-- Add recipient_id column if it doesn't exist
ALTER TABLE scheduled_cards 
  ADD COLUMN IF NOT EXISTS recipient_id UUID REFERENCES users(id);

-- Create function to insert into scheduled_cards table
CREATE OR REPLACE FUNCTION gc_insert_scheduled_card(
  p_greeting_card_id UUID,
  p_sender_id UUID,
  p_recipient_id UUID,
  p_recipient_email TEXT,
  p_scheduled_at TIMESTAMPTZ
) RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
  v_scheduled_card_id UUID;
BEGIN
  -- Validation
  IF NOT EXISTS (SELECT 1 FROM greeting_cards WHERE id = p_greeting_card_id) THEN
    RAISE EXCEPTION 'Greeting card % does not exist', p_greeting_card_id;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_sender_id) THEN
    RAISE EXCEPTION 'Sender % does not exist', p_sender_id;
  END IF;
  
  IF p_recipient_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE id = p_recipient_id) THEN
    RAISE EXCEPTION 'Recipient % does not exist', p_recipient_id;
  END IF;
  
  IF p_scheduled_at < NOW() THEN
    RAISE EXCEPTION 'Scheduled time must be in the future';
  END IF;

  -- Insert into scheduled_cards
  INSERT INTO scheduled_cards (
    greeting_card_id,
    sender_id,
    recipient_id,
    recipient_email,
    scheduled_at,
    created_at
  ) VALUES (
    p_greeting_card_id,
    p_sender_id,
    p_recipient_id,
    p_recipient_email,
    p_scheduled_at,
    NOW()
  )
  RETURNING id INTO v_scheduled_card_id;
  
  RETURN v_scheduled_card_id;
END;
$$;

-- Main function to schedule a card (RPC callable)
CREATE OR REPLACE FUNCTION gc_schedule_card(
  p_front_image_url TEXT,
  p_back_image_url TEXT,
  p_greeting_message TEXT,
  p_sender_id UUID,
  p_recipient_id UUID,
  p_recipient_email TEXT,
  p_scheduled_at TIMESTAMPTZ
) RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_greeting_card_id UUID;
  v_scheduled_card_id UUID;
  v_result JSONB;
BEGIN
  -- Create the greeting card first
  v_greeting_card_id := gc_create_greeting_card(
    p_front_image_url,
    p_back_image_url,
    p_greeting_message
  );
  
  -- Insert into scheduled_cards
  v_scheduled_card_id := gc_insert_scheduled_card(
    v_greeting_card_id,
    p_sender_id,
    p_recipient_id,
    p_recipient_email,
    p_scheduled_at
  );
  
  -- Build result JSON
  SELECT jsonb_build_object(
    'scheduled_card_id', sc.id,
    'scheduled_at', sc.scheduled_at,
    'recipient_email', sc.recipient_email,
    'greeting_card', jsonb_build_object(
      'id', gc.id,
      'card_frontside_url', gc.card_frontside_url,
      'card_backside_url', gc.card_backside_url,
      'message', gc.message
    ),
    'sender', jsonb_build_object(
      'id', u.id,
      'first_name', u.first_name,
      'last_name', u.last_name
    )
  ) INTO v_result
  FROM scheduled_cards sc
  JOIN greeting_cards gc ON sc.greeting_card_id = gc.id
  JOIN users u ON sc.sender_id = u.id
  WHERE sc.id = v_scheduled_card_id;
  
  RETURN v_result;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error in gc_schedule_card: %', SQLERRM;
    RAISE;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION gc_insert_scheduled_card TO authenticated;
GRANT EXECUTE ON FUNCTION gc_schedule_card TO authenticated;