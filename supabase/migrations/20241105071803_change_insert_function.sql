set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.insert_chat_message_data(chat_data jsonb)
 RETURNS void
 LANGUAGE plpgsql
AS $function$DECLARE
    -- Declare variables for each extracted value
    v_sent_at TIMESTAMPTZ := NOW();
    v_gift_id UUID;
    v_gift_sent_at TIMESTAMPTZ;
    v_card_backside_url TEXT;
    v_card_frontside_url TEXT;
    v_message TEXT;
    v_user_phone BIGINT;
    v_conversation_id UUID;
    v_inserted_gift_id UUID;
    v_inserted_greeting_card_id UUID;
    v_participant_phone_numbers TEXT[];
    v_temp_conversation_id UUID;
BEGIN
    -- Extract fields from the JSON data
    v_sent_at := COALESCE((chat_data->>'sent_at')::TIMESTAMPTZ, v_sent_at);
    v_gift_id := NULLIF(chat_data->>'gift_id', 'null')::UUID;
    v_message := chat_data->>'message';
    v_user_phone := (chat_data->>'user_phone')::BIGINT;
    v_conversation_id := NULLIF(chat_data->>'conversation_id', 'null')::UUID;
    v_participant_phone_numbers := ARRAY(SELECT jsonb_array_elements_text(chat_data->'participant_phone_numbers'));

    -- Check for existing conversation_id, or find/create conversation if missing
    IF v_conversation_id IS NULL THEN
        -- Attempt to find a matching conversation by checking conversations with exact participant matches
        SELECT id INTO v_temp_conversation_id
        FROM conversations
        WHERE id IN (
            SELECT id
            FROM conversations
            WHERE user_phone = ANY(v_participant_phone_numbers)
            GROUP BY id
            HAVING array_agg(user_phone ORDER BY user_phone) = v_participant_phone_numbers
        )
        LIMIT 1;

        -- If no existing conversation, create a new one
        IF v_temp_conversation_id IS NULL THEN
            -- Generate a new conversation ID
            v_temp_conversation_id := gen_random_uuid();

            -- Insert each participant with the new conversation ID
            INSERT INTO conversations (id, user_phone)
            SELECT v_temp_conversation_id, unnest(v_participant_phone_numbers);
        END IF;

        -- Set conversation_id to the found or newly created conversation
        v_conversation_id := v_temp_conversation_id;
    END IF;

    -- Extract gift information if it exists
    IF chat_data ? 'gift' THEN
        v_gift_sent_at := (chat_data->'gift'->>'sent_at')::TIMESTAMPTZ;

        -- Extract greeting card information if it exists within gift
        IF chat_data->'gift' ? 'greeting_card' THEN
            v_card_backside_url := chat_data->'gift'->'greeting_card'->>'card_backside_url';
            v_card_frontside_url := chat_data->'gift'->'greeting_card'->>'card_frontside_url';
            
            -- Insert into greeting_cards table and get the ID
            INSERT INTO greeting_cards (card_backside_url, card_frontside_url)
            VALUES (v_card_backside_url, v_card_frontside_url)
            RETURNING id INTO v_inserted_greeting_card_id;
        END IF;

        -- Insert into gifts table and get the ID, linking to greeting_card if available
        INSERT INTO gifts (sent_at, greeting_card_id)
        VALUES (v_gift_sent_at, v_inserted_greeting_card_id)
        RETURNING id INTO v_inserted_gift_id;
    END IF;

    -- Insert into chat_messages table
    INSERT INTO chat_messages (sent_at, gift_id, message, user_phone, conversation_id)
    VALUES (v_sent_at, COALESCE(v_inserted_gift_id, v_gift_id), v_message, v_user_phone, v_conversation_id);

END;$function$
;


