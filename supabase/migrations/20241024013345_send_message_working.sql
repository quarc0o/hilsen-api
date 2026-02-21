alter table "public"."conversations" drop constraint "public_conversations_last_message_id_fkey";

alter table "public"."conversations" add constraint "conversations_last_message_id_fkey" FOREIGN KEY (last_message_id) REFERENCES chat_messages(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."conversations" validate constraint "conversations_last_message_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.insert_conversation_message(sender_phone_number text, participant_phone_numbers text[], message_content text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    conversation_id UUID;
    new_message_id UUID;
    new_conversation_id UUID;
BEGIN
    -- Step 1: Check if a conversation with the same set of participants exists
    WITH grouped_conversations AS (
        SELECT id AS conversation_id, ARRAY_AGG(DISTINCT user_phone ORDER BY user_phone) AS participants
        FROM conversations
        GROUP BY id
    )
    SELECT gc.conversation_id INTO conversation_id
    FROM grouped_conversations gc
    WHERE gc.participants = participant_phone_numbers
    LIMIT 1;

    -- Step 2: If the conversation does not exist, create it
    IF conversation_id IS NULL THEN
        new_conversation_id := uuid_generate_v4();  -- Generate a new conversation ID

        -- Insert a new conversation row for each participant
        INSERT INTO conversations (id, user_phone, last_message_id)
        SELECT new_conversation_id, UNNEST(participant_phone_numbers), NULL;

        -- Set the conversation ID to the newly created conversation
        conversation_id := new_conversation_id;
    END IF;

    -- Step 3: Insert the new chat message into the chat_messages table
    INSERT INTO chat_messages (conversation_id, user_phone, message, created_at)
    VALUES (conversation_id, sender_phone_number, message_content, NOW())
    RETURNING id INTO new_message_id;

    -- Step 4: Update the last_message_id for each participant in the conversation
    UPDATE conversations
    SET last_message_id = new_message_id
    WHERE id = conversation_id;

    -- Step 5: Return the conversation ID
    RETURN conversation_id;
END;
$function$
;


