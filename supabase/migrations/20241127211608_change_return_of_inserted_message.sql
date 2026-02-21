set check_function_bodies = off;

DROP FUNCTION IF EXISTS public.insert_chat_message_with_gift(json);
CREATE OR REPLACE FUNCTION public.insert_chat_message_with_gift(chat_data json)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_sent_at TIMESTAMPTZ := NOW();
    v_gift_id UUID;
    v_gift_sent_at TIMESTAMPTZ;
    v_card_backside_url TEXT;
    v_card_frontside_url TEXT;
    v_message TEXT;
    v_user_phone TEXT;
    v_conversation_id UUID;
    v_inserted_gift_id UUID;
    v_inserted_greeting_card_id UUID;
    v_new_message_id UUID;
BEGIN
    -- Extract fields from JSON
    v_sent_at := COALESCE((chat_data->>'sent_at')::TIMESTAMPTZ, v_sent_at);
    v_gift_id := NULLIF(chat_data->>'gift_id', 'null')::UUID;
    v_message := chat_data->>'message';
    v_user_phone := chat_data->>'user_phone';

    -- Debug: Log raw conversation_id
    RAISE NOTICE 'Raw conversation_id: %', chat_data->>'conversation_id';

    -- Validate and extract conversation_id
    IF chat_data->>'conversation_id' IS NOT NULL THEN
        IF NOT TRIM(chat_data->>'conversation_id') ~* '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$' THEN
            RAISE EXCEPTION 'Invalid UUID format for conversation_id: %', chat_data->>'conversation_id';
        END IF;
        v_conversation_id := TRIM(chat_data->>'conversation_id')::UUID;
    ELSE
        RAISE EXCEPTION 'conversation_id is missing or null';
    END IF;

    -- Insert gift if present
    IF chat_data::JSON->'gift' IS NOT NULL THEN
        v_gift_sent_at := (chat_data::JSON->'gift'->>'sent_at')::TIMESTAMPTZ;

        IF chat_data::JSON->'gift'->'greeting_card' IS NOT NULL THEN
            v_card_backside_url := chat_data::JSON->'gift'->'greeting_card'->>'card_backside_url';
            v_card_frontside_url := chat_data::JSON->'gift'->'greeting_card'->>'card_frontside_url';

            INSERT INTO greeting_cards (card_backside_url, card_frontside_url)
            VALUES (v_card_backside_url, v_card_frontside_url)
            RETURNING id INTO v_inserted_greeting_card_id;
        END IF;

        INSERT INTO gifts (sent_at, greeting_card_id)
        VALUES (v_gift_sent_at, v_inserted_greeting_card_id)
        RETURNING id INTO v_inserted_gift_id;
    END IF;

    -- Insert chat message
    INSERT INTO chat_messages (sent_at, gift_id, message, user_phone, conversation_id)
    VALUES (v_sent_at, COALESCE(v_inserted_gift_id, v_gift_id), v_message, v_user_phone, v_conversation_id)
    RETURNING id INTO v_new_message_id;

    UPDATE conversations
    SET last_message_id = v_new_message_id
    WHERE id = v_conversation_id;

    RETURN v_inserted_gift_id;
END;
$function$
;


