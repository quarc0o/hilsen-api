set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.insert_chat_message_data(chat_data json)
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
    v_new_message_id UUID;
BEGIN
    -- Initial debug output
    RAISE NOTICE 'Starting function execution.';

    -- Extract fields from the JSON data
    v_sent_at := COALESCE((chat_data#>>'{sent_at}')::TIMESTAMPTZ, v_sent_at);
    v_gift_id := NULLIF(chat_data#>>'{gift_id}', 'null')::UUID;
    v_message := chat_data#>>'{message}';
    v_user_phone := (chat_data#>>'{user_phone}')::BIGINT;
    v_conversation_id := NULLIF(chat_data#>>'{conversation_id}', 'null')::UUID;
    v_participant_phone_numbers := ARRAY(SELECT json_array_elements_text(chat_data#>'{participant_phone_numbers}'));

    -- Output the extracted variables for debugging
    RAISE NOTICE 'Extracted values - sent_at: %, gift_id: %, message: %, user_phone: %, conversation_id: %, participant_phone_numbers: %',
        v_sent_at, v_gift_id, v_message, v_user_phone, v_conversation_id, v_participant_phone_numbers;

    -- Check for existing conversation_id, or find/create conversation if missing
    IF v_conversation_id IS NULL THEN
        RAISE NOTICE 'Conversation ID is NULL. Looking for existing conversation.';

        -- Attempt to find a matching conversation by checking conversations with exact participant matches
        SELECT id INTO v_temp_conversation_id
        FROM conversations
        WHERE id IN (
            SELECT id
            FROM conversations
            WHERE user_phone = ANY(v_participant_phone_numbers)
            GROUP BY id
            HAVING array_agg(user_phone ORDER BY user_phone) = (
                SELECT array_agg(phone_number ORDER BY phone_number)
                FROM unnest(v_participant_phone_numbers) AS phone_number
            )
        )
        LIMIT 1;
        
        

        -- Debug output for conversation lookup
        RAISE NOTICE 'Matching conversation found: %', v_temp_conversation_id;

        -- If no existing conversation, create a new one
        IF v_temp_conversation_id IS NULL THEN
            RAISE NOTICE 'No matching conversation found. Creating new conversation.';

            -- Generate a new conversation ID
            v_temp_conversation_id := gen_random_uuid();

            -- Insert each participant with the new conversation ID
            INSERT INTO conversations (id, user_phone)
            SELECT v_temp_conversation_id, unnest(v_participant_phone_numbers);

            RAISE NOTICE 'New conversation created with ID: %', v_temp_conversation_id;
        END IF;

        -- Set conversation_id to the found or newly created conversation
        v_conversation_id := v_temp_conversation_id;
    END IF;

    -- Output conversation ID after checking
    RAISE NOTICE 'Final conversation ID: %', v_conversation_id;

    -- Insert gift and greeting card only if `gift` object exists in the JSON data
    IF chat_data#>'{gift}' IS NOT NULL THEN
        v_gift_sent_at := (chat_data#>'{gift,sent_at}'#>>'{}')::TIMESTAMPTZ;

        -- Debug output for gift information
        RAISE NOTICE 'Gift information - sent_at: %', v_gift_sent_at;

        -- Extract greeting card information if it exists within gift
        IF chat_data#>'{gift,greeting_card}' IS NOT NULL THEN
            v_card_backside_url := NULLIF(chat_data#>'{gift,greeting_card}'#>>'{card_backside_url}', 'null');
            v_card_frontside_url := NULLIF(chat_data#>'{gift,greeting_card}'#>>'{card_frontside_url}', 'null');

            -- Debug output for greeting card information
            RAISE NOTICE 'Greeting card information - backside_url: %, frontside_url: %', v_card_backside_url, v_card_frontside_url;

            -- Insert into greeting_cards table only if URLs are provided
            IF v_card_backside_url IS NOT NULL OR v_card_frontside_url IS NOT NULL THEN
                INSERT INTO greeting_cards (card_backside_url, card_frontside_url)
                VALUES (v_card_backside_url, v_card_frontside_url)
                RETURNING id INTO v_inserted_greeting_card_id;

                RAISE NOTICE 'Inserted greeting card ID: %', v_inserted_greeting_card_id;
            END IF;
        END IF;

        -- Only insert into gifts if v_gift_sent_at is not NULL
        IF v_gift_sent_at IS NOT NULL THEN
            INSERT INTO gifts (sent_at, greeting_card_id)
            VALUES (v_gift_sent_at, v_inserted_greeting_card_id)
            RETURNING id INTO v_inserted_gift_id;

            RAISE NOTICE 'Inserted gift ID: %', v_inserted_gift_id;
        END IF;
    END IF;

    -- Insert into chat_messages table
    INSERT INTO chat_messages (sent_at, gift_id, message, user_phone, conversation_id)
    VALUES (v_sent_at, COALESCE(v_inserted_gift_id, v_gift_id), v_message, v_user_phone, v_conversation_id)
    RETURNING id INTO v_new_message_id;

    RAISE NOTICE 'Chat message inserted successfully with conversation ID: %', v_conversation_id;

    -- Update last_message_id in the conversations table
    UPDATE conversations
    SET last_message_id = v_new_message_id
    WHERE id = v_conversation_id;

    RAISE NOTICE 'Updated last_message_id in conversations table for conversation ID: %', v_conversation_id;

END;
$function$
;


