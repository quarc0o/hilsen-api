drop function if exists "public"."create_conversation"(p_user_id_1 uuid, p_user_id_2 uuid);

drop function if exists "public"."gc_create_greeting_card"(p_front_image_url text, p_back_image_url text, p_greeting_message text);

drop function if exists "public"."gc_create_message_entry"(p_conversation_id uuid, p_sender_id uuid, p_greeting_card_id uuid);

drop function if exists "public"."gc_get_gift_message_json"(p_message_id uuid);

drop function if exists "public"."gc_insert_scheduled_card"(p_greeting_card_id uuid, p_sender_id uuid, p_recipient_id uuid, p_recipient_email text, p_scheduled_at timestamp with time zone);

drop function if exists "public"."gc_schedule_card"(p_front_image_url text, p_back_image_url text, p_greeting_message text, p_sender_id uuid, p_recipient_id uuid, p_recipient_email text, p_scheduled_at timestamp with time zone);

drop function if exists "public"."gc_send_gift_now"(p_conversation_id uuid, p_sender_id uuid, p_front_image_url text, p_back_image_url text, p_greeting_message text);

drop function if exists "public"."get_conversation_messages"(p_user_id uuid, p_conversation_id uuid, p_limit integer, p_offset integer);

drop function if exists "public"."get_user_conversations"(p_user_id uuid);

drop function if exists "public"."send_gift"(p_conversation_id uuid, p_sender_id uuid, p_front_image_url text, p_back_image_url text, p_greeting_message text);

drop function if exists "public"."send_text_message"(p_sender_id uuid, p_conversation_id uuid, p_content text);

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.find_or_create_conversation(p_user_id_1 uuid, p_user_id_2 uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_conversation_id UUID;
BEGIN
  -- Check if the users are the same
  IF p_user_id_1 = p_user_id_2 THEN
    RAISE EXCEPTION 'Cannot create conversation with the same user';
  END IF;

  -- First, check if a conversation already exists between these two users
  -- We need to find conversations where both users are participants (order doesn't matter)
  SELECT cp1.conversation_id INTO v_conversation_id
  FROM conversation_participants cp1
  INNER JOIN conversation_participants cp2
    ON cp1.conversation_id = cp2.conversation_id
  WHERE ((cp1.user_id = p_user_id_1 AND cp2.user_id = p_user_id_2)
      OR (cp1.user_id = p_user_id_2 AND cp2.user_id = p_user_id_1))
    AND cp1.user_id != cp2.user_id  -- Ensure they're different participants
  LIMIT 1;

  -- If conversation exists, return it
  IF v_conversation_id IS NOT NULL THEN
    RETURN v_conversation_id;
  END IF;

  -- If no conversation exists, create a new one
  INSERT INTO conversations (id, created_at, updated_at)
  VALUES (gen_random_uuid(), NOW(), NOW())
  RETURNING id INTO v_conversation_id;

  -- Add both users as participants
  INSERT INTO conversation_participants (conversation_id, user_id)
  VALUES
    (v_conversation_id, p_user_id_1),
    (v_conversation_id, p_user_id_2);

  -- Return the new conversation ID
  RETURN v_conversation_id;
END;
$function$
;


