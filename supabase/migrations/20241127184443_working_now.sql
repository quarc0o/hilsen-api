drop function if exists "public"."insert_chat_message_data"(chat_data jsonb);

drop function if exists "public"."trigger_send_email_function"();

alter table "public"."gifts" alter column "sent_at" set default now();

alter table "public"."gifts" alter column "sent_at" drop not null;

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_conversation(participant_phone_numbers text[])
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_conversation_id UUID;
BEGIN
    -- Generate a new conversation ID
    v_conversation_id := gen_random_uuid();

    -- Insert each participant into the conversation
    INSERT INTO conversations (id, user_phone)
    SELECT v_conversation_id, unnest(participant_phone_numbers);

    RETURN v_conversation_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.find_conversation_by_participants(participant_phone_numbers text[])
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT id
        FROM conversations
        WHERE id IN (
            SELECT id
            FROM conversations
            WHERE user_phone = ANY(participant_phone_numbers)
            GROUP BY id
            HAVING array_agg(user_phone ORDER BY user_phone) = (
                SELECT array_agg(phone_number ORDER BY phone_number)
                FROM unnest(participant_phone_numbers) AS phone_number
            )
        )
        LIMIT 1
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_gift_data_test(data json)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    new_gift_id UUID;
    new_greeting_card_id UUID;
    sender_user_id UUID;
BEGIN
    -- Insert the greeting card details
    INSERT INTO public.greeting_cards (card_frontside_url, card_backside_url)
    VALUES (
        data->'gift'->'greeting_card'->>'card_frontside_url',
        data->'gift'->'greeting_card'->>'card_backside_url'
    )
    RETURNING id INTO new_greeting_card_id;

    -- Insert the gift details with explicit casting for sent_at
    INSERT INTO public.gifts (sent_at, greeting_card_id)
    VALUES (
        (data->'gift'->>'sent_at')::timestamp with time zone,
        new_greeting_card_id
    )
    RETURNING id INTO new_gift_id;

    -- Check if conversation_id is provided and not null
    IF data->>'conversation_id' IS NOT NULL THEN
        -- Insert the chat message
        INSERT INTO public.chat_messages (sent_at, message, user_phone, gift_id, conversation_id)
        VALUES (
            (data->>'sent_at')::timestamp with time zone,
            data->>'message',
            data->>'user_phone',
            new_gift_id,
            (data->>'conversation_id')::uuid  -- Cast to uuid
        );
    END IF;

    -- Insert or update the sender user
    SELECT id INTO sender_user_id
    FROM public.users
    WHERE email = data->'sender_user'->>'email';

    IF sender_user_id IS NULL THEN
        -- If the user does not exist, insert a new user
        INSERT INTO public.users (id, email, first_name, last_name, phone_number)
        VALUES (
            data->'sender_user'->>'id',
            data->'sender_user'->>'email',
            data->'sender_user'->>'first_name',
            data->'sender_user'->>'last_name',
            data->'sender_user'->>'phone_number'
        );
    END IF;

    -- Optionally, handle participant phone numbers if needed
    -- This part can be customized based on how you want to store participant data

    RAISE NOTICE 'Gift and related data inserted successfully with gift ID: %', new_gift_id;

    -- Return the ID of the inserted gift
    RETURN new_gift_id;

END; $function$
;

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

    RETURN v_new_message_id;
END;
$function$
;


