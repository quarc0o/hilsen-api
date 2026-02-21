drop function if exists "public"."send_gift"(p_sender_id integer, p_conversation_id integer, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric, p_gift_card_currency character varying, p_gift_card_retailer character varying, p_stripe_payment_intent_id character varying);

drop function if exists "public"."send_text_message"(p_sender_id integer, p_conversation_id integer, p_content text);

drop function if exists "public"."send_gift"(p_sender_id uuid, p_conversation_id uuid, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric, p_gift_card_currency character varying, p_gift_card_retailer character varying, p_stripe_payment_id character varying);

drop function if exists "public"."send_text_message"(p_sender_id uuid, p_conversation_id uuid, p_content text);

set check_function_bodies = off;

DROP FUNCTION IF EXISTS public.create_conversation(uuid, uuid);

CREATE OR REPLACE FUNCTION public.create_conversation(p_user_id_1 uuid, p_user_id_2 uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_conversation_id UUID;
  v_result JSONB;
  v_last_message JSONB;
  v_last_message_content TEXT;
  v_participants JSONB;
  v_unread_count INTEGER;
BEGIN
  -- Check if users exist
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id_1) THEN
    RAISE EXCEPTION 'User with id % does not exist', p_user_id_1;
  END IF;
  
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = p_user_id_2) THEN
    RAISE EXCEPTION 'User with id % does not exist', p_user_id_2;
  END IF;
  
  -- Check if conversation already exists between these users
  SELECT c.id INTO v_conversation_id
  FROM conversations c
  JOIN conversation_participants cp1 ON c.id = cp1.conversation_id AND cp1.user_id = p_user_id_1
  JOIN conversation_participants cp2 ON c.id = cp2.conversation_id AND cp2.user_id = p_user_id_2
  LIMIT 1;
  
  -- If conversation doesn't exist, create it
  IF v_conversation_id IS NULL THEN
    -- Create new conversation with UUID
    v_conversation_id := gen_random_uuid();
    INSERT INTO conversations (id, created_at)
    VALUES (v_conversation_id, CURRENT_TIMESTAMP);
    
    -- Add participants
    INSERT INTO conversation_participants (conversation_id, user_id)
    VALUES (v_conversation_id, p_user_id_1), (v_conversation_id, p_user_id_2);
  END IF;
  
  -- Get last message details
  -- First get basic message info
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
END;
$function$
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
 conversation_participants AS (
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
END;$function$
;

CREATE OR REPLACE FUNCTION public.send_gift(p_sender_id uuid, p_conversation_id uuid, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric DEFAULT NULL::numeric, p_gift_card_currency character varying DEFAULT 'USD'::character varying, p_gift_card_retailer character varying DEFAULT NULL::character varying, p_stripe_payment_id character varying DEFAULT NULL::character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    v_message_id UUID;
    v_greeting_card_id UUID;
    v_gift_card_id UUID := NULL;
    v_payment_id UUID := NULL;
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

    -- If gift card is included, create payment and gift card
    IF p_gift_card_amount IS NOT NULL AND p_gift_card_retailer IS NOT NULL AND p_stripe_payment_id IS NOT NULL THEN
        -- Generate UUIDs for payment and gift card
        v_payment_id := gen_random_uuid();
        v_gift_card_id := gen_random_uuid();
        
        -- Create payment record
        INSERT INTO payments (
            id,
            sender_id,
            stripe_payment_id,
            amount,
            currency,
            status,
            created_at,
            updated_at
        ) VALUES (
            v_payment_id,
            p_sender_id,
            p_stripe_payment_id,
            p_gift_card_amount,
            p_gift_card_currency,
            'completed',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        );

        -- Create gift card
        INSERT INTO gift_cards (
            id,
            amount,
            currency,
            retailer,
            created_at
        ) VALUES (
            v_gift_card_id,
            p_gift_card_amount,
            p_gift_card_currency,
            p_gift_card_retailer,
            CURRENT_TIMESTAMP
        );
    END IF;

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
        greeting_card_id,
        gift_card_id,
        transaction_id
    ) VALUES (
        v_message_id,
        v_greeting_card_id,
        v_gift_card_id,
        v_payment_id
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
            ),
            'gift_card', CASE WHEN gft.id IS NOT NULL THEN jsonb_build_object(
                'id', gft.id,
                'amount', gft.amount,
                'currency', gft.currency,
                'retailer', gft.retailer
            ) ELSE NULL END
        )
    ) INTO v_result
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    JOIN gift_messages gm ON m.id = gm.message_id
    JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
    LEFT JOIN gift_cards gft ON gm.gift_card_id = gft.id
    WHERE m.id = v_message_id;

    RETURN v_result;
END;$function$
;

CREATE OR REPLACE FUNCTION public.send_text_message(p_sender_id uuid, p_conversation_id uuid, p_content text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$DECLARE
    v_message_id UUID;
    v_result JSONB;
BEGIN
    -- Check if sender is part of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = p_conversation_id AND user_id = p_sender_id
    ) THEN
        RAISE EXCEPTION 'User % is not a participant in conversation %', p_sender_id, p_conversation_id;
    END IF;

    -- Generate UUID for message
    v_message_id := gen_random_uuid();

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
        'text', 
        CURRENT_TIMESTAMP
    );

    -- Insert into text_messages table
    INSERT INTO text_messages (
        message_id, 
        content
    ) VALUES (
        v_message_id, 
        p_content
    );

    -- Get the complete message data
    SELECT jsonb_build_object(
        'message_id', m.id,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'message_type', m.message_type,
        'content', tm.content,
        'created_at', m.created_at,
        'read_at', m.read_at
    ) INTO v_result
    FROM messages m
    JOIN users u ON m.sender_id = u.id
    JOIN text_messages tm ON m.id = tm.message_id
    WHERE m.id = v_message_id;

    RETURN v_result;
END;$function$
;


