drop trigger if exists "test_send_email" on "public"."gifts";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.insert_chat_message_with_gift(chat_data json)
 RETURNS chat_messages
 LANGUAGE plpgsql
AS $function$DECLARE
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
    v_new_message chat_messages;
BEGIN
    -- Extract fields from JSON
    v_sent_at := COALESCE((chat_data->>'sent_at')::TIMESTAMPTZ, v_sent_at);
    v_gift_id := NULLIF(chat_data->>'gift_id', 'null')::UUID;
    v_message := chat_data->>'message';
    v_user_phone := chat_data->>'user_phone';
    v_conversation_id := (chat_data->>'conversation_id')::UUID;

    -- Insert gift if present
    IF json_typeof(chat_data->'gift') IS NOT NULL AND json_typeof(chat_data->'gift') <> 'null' THEN
        RAISE LOG 'inside gift not null clause';
        v_gift_sent_at := (chat_data->'gift'->>'sent_at')::TIMESTAMPTZ;

        IF chat_data->'gift'->'greeting_card' IS NOT NULL THEN
            v_card_backside_url := chat_data->'gift'->'greeting_card'->>'card_backside_url';
            v_card_frontside_url := chat_data->'gift'->'greeting_card'->>'card_frontside_url';

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
    RETURNING * INTO v_new_message;

    RETURN v_new_message;
END;$function$
;


