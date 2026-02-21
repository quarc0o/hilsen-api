create type "public"."message_type" as enum ('text', 'gift');

-- revoke delete on table "public"."chat_messages" from "anon";

-- revoke insert on table "public"."chat_messages" from "anon";

-- revoke references on table "public"."chat_messages" from "anon";

-- revoke select on table "public"."chat_messages" from "anon";

-- revoke trigger on table "public"."chat_messages" from "anon";

-- revoke truncate on table "public"."chat_messages" from "anon";

-- revoke update on table "public"."chat_messages" from "anon";

-- revoke delete on table "public"."chat_messages" from "authenticated";

-- revoke insert on table "public"."chat_messages" from "authenticated";

-- revoke references on table "public"."chat_messages" from "authenticated";

-- revoke select on table "public"."chat_messages" from "authenticated";

-- revoke trigger on table "public"."chat_messages" from "authenticated";

-- revoke truncate on table "public"."chat_messages" from "authenticated";

-- revoke update on table "public"."chat_messages" from "authenticated";

-- revoke delete on table "public"."chat_messages" from "service_role";

-- revoke insert on table "public"."chat_messages" from "service_role";

-- revoke references on table "public"."chat_messages" from "service_role";

-- revoke select on table "public"."chat_messages" from "service_role";

-- revoke trigger on table "public"."chat_messages" from "service_role";

-- revoke truncate on table "public"."chat_messages" from "service_role";

-- revoke update on table "public"."chat_messages" from "service_role";

-- revoke delete on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke insert on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke references on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke select on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke trigger on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke truncate on table "public"."chat_messages" from "supabase_auth_admin";

-- revoke update on table "public"."chat_messages" from "supabase_auth_admin";

-- alter table "public"."chat_messages" drop constraint "chat_messages_gift_id_fkey";

-- alter table "public"."conversations" drop constraint "conversations_last_message_id_fkey";

-- alter table "public"."scheduled_cards" drop constraint "scheduled_cards_chat_message_id_fkey";

-- drop function if exists "public"."create_conversation"(participant_phone_numbers text[]);

-- drop function if exists "public"."find_conversation_by_participants"(participant_phone_numbers text[]);

drop function if exists "public"."get_conversation_id"(phone_numbers text[]);

drop function if exists "public"."get_initial_conversations"(conversation_ids uuid[]);

drop function if exists "public"."get_user_conversations"(p_conversation_id uuid);

drop function if exists "public"."handle_gift_data_test"(data json);

drop function if exists "public"."insert_chat_message_with_gift"(chat_data json);

drop function if exists "public"."insert_conversation_message"(sender_phone_number text, participant_phone_numbers text[], message_content text);

drop function if exists "public"."update_conversation_last_message"(p_chat_message_id uuid, p_conversation_id uuid);

drop function if exists "public"."update_message_delivery_status"();

-- First drop the foreign keys that reference chat_messages
alter table "public"."scheduled_cards" drop constraint if exists "scheduled_cards_chat_message_id_fkey";
alter table "public"."conversations" drop constraint if exists "conversations_last_message_id_fkey";
-- Add any other foreign keys that might reference chat_messages

alter table "public"."chat_messages" drop constraint "chat_messages_pkey";

alter table "public"."conversations" drop constraint "conversations_pkey";

drop index if exists "public"."chat_messages_pkey";

drop index if exists "public"."conversations_pkey";

-- drop table "public"."chat_messages";

create table "public"."conversation_participants" (
    "conversation_id" uuid not null,
    "user_id" uuid not null
);


alter table "public"."conversation_participants" enable row level security;

create table "public"."gift_messages" (
    "message_id" uuid not null,
    "greeting_card_id" uuid not null,
    "gift_card_id" uuid,
    "transaction_id" uuid
);


alter table "public"."gift_messages" enable row level security;

create table "public"."messages" (
    "id" uuid not null default gen_random_uuid(),
    "created_at" timestamp with time zone not null default now(),
    "read_at" timestamp with time zone,
    "conversation_id" uuid not null,
    "sender_id" uuid not null,
    "message_type" message_type not null
);


create table "public"."text_messages" (
    "message_id" uuid not null default gen_random_uuid(),
    "content" text not null
);


alter table "public"."text_messages" enable row level security;

-- alter table "public"."conversations" drop column "last_message_id";

-- alter table "public"."conversations" drop column "user_phone";

alter table "public"."transactions" drop column "gift_id";

alter table "public"."transactions" add column "sender_id" uuid not null;

CREATE UNIQUE INDEX conversation_participants_pkey ON public.conversation_participants USING btree (conversation_id, user_id);

CREATE UNIQUE INDEX gift_messages_pkey ON public.gift_messages USING btree (message_id);

CREATE UNIQUE INDEX text_messages_pkey ON public.text_messages USING btree (message_id);

CREATE UNIQUE INDEX chat_messages_pkey ON public.messages USING btree (id);

-- CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id);

alter table "public"."conversation_participants" add constraint "conversation_participants_pkey" PRIMARY KEY using index "conversation_participants_pkey";

alter table "public"."gift_messages" add constraint "gift_messages_pkey" PRIMARY KEY using index "gift_messages_pkey";

alter table "public"."messages" add constraint "chat_messages_pkey" PRIMARY KEY using index "chat_messages_pkey";

alter table "public"."text_messages" add constraint "text_messages_pkey" PRIMARY KEY using index "text_messages_pkey";

-- alter table "public"."conversations" add constraint "conversations_pkey" PRIMARY KEY using index "conversations_pkey";

-- alter table "public"."conversation_participants" add constraint "conversation_participants_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

-- alter table "public"."conversation_participants" validate constraint "conversation_participants_conversation_id_fkey";

alter table "public"."conversation_participants" add constraint "conversation_participants_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."conversation_participants" validate constraint "conversation_participants_user_id_fkey";

alter table "public"."gift_messages" add constraint "gift_messages_gift_card_id_fkey" FOREIGN KEY (gift_card_id) REFERENCES gift_cards(id) ON UPDATE RESTRICT ON DELETE RESTRICT not valid;

alter table "public"."gift_messages" validate constraint "gift_messages_gift_card_id_fkey";

alter table "public"."gift_messages" add constraint "gift_messages_greeting_card_id_fkey" FOREIGN KEY (greeting_card_id) REFERENCES greeting_cards(id) ON UPDATE RESTRICT ON DELETE RESTRICT not valid;

alter table "public"."gift_messages" validate constraint "gift_messages_greeting_card_id_fkey";

alter table "public"."gift_messages" add constraint "gift_messages_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."gift_messages" validate constraint "gift_messages_message_id_fkey";

alter table "public"."gift_messages" add constraint "gift_messages_transaction_id_fkey" FOREIGN KEY (transaction_id) REFERENCES transactions(id) ON UPDATE RESTRICT ON DELETE RESTRICT not valid;

alter table "public"."gift_messages" validate constraint "gift_messages_transaction_id_fkey";

-- alter table "public"."messages" add constraint "messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

-- alter table "public"."messages" validate constraint "messages_conversation_id_fkey";

alter table "public"."messages" add constraint "messages_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE RESTRICT not valid;

alter table "public"."messages" validate constraint "messages_sender_id_fkey";

alter table "public"."text_messages" add constraint "text_messages_message_id_fkey" FOREIGN KEY (message_id) REFERENCES messages(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."text_messages" validate constraint "text_messages_message_id_fkey";

alter table "public"."transactions" add constraint "transactions_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES users(id) ON UPDATE RESTRICT ON DELETE RESTRICT not valid;

alter table "public"."transactions" validate constraint "transactions_sender_id_fkey";

alter table "public"."scheduled_cards" add constraint "scheduled_cards_chat_message_id_fkey" FOREIGN KEY (chat_message_id) REFERENCES messages(id) ON UPDATE CASCADE ON DELETE CASCADE not valid;

alter table "public"."scheduled_cards" validate constraint "scheduled_cards_chat_message_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.create_conversation(p_user_id_1 uuid, p_user_id_2 uuid)
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_conversation_id UUID;
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
    
    RETURN v_conversation_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_conversation_messages(p_user_id integer, p_conversation_id integer, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(message_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if user is part of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = p_conversation_id AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % is not a participant in conversation %', p_user_id, p_conversation_id;
    END IF;

    -- Mark unread messages as read
    UPDATE messages
    SET read_at = CURRENT_TIMESTAMP
    WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND read_at IS NULL;
    
    RETURN QUERY
    WITH message_data AS (
        SELECT 
            m.id,
            m.sender_id,
            u.username AS sender_username,
            u.profile_picture_url AS sender_profile_picture,
            m.message_type,
            m.created_at,
            m.read_at,
            -- Text message content
            CASE WHEN m.message_type = 'text' THEN
                jsonb_build_object('content', tm.content)
            ELSE NULL END AS text_data,
            -- Gift message content
            CASE WHEN m.message_type = 'gift' THEN
                jsonb_build_object(
                    'greeting_card', jsonb_build_object(
                        'id', gc.id,
                        'front_image_url', gc.front_image_url,
                        'back_image_url', gc.back_image_url,
                        'message', gc.message
                    ),
                    'gift_card', CASE WHEN gft.id IS NOT NULL THEN jsonb_build_object(
                        'id', gft.id,
                        'amount', gft.amount,
                        'currency', gft.currency,
                        'retailer', gft.retailer
                    ) ELSE NULL END
                )
            ELSE NULL END AS gift_data
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN text_messages tm ON m.id = tm.message_id AND m.message_type = 'text'
        LEFT JOIN gift_messages gm ON m.id = gm.message_id AND m.message_type = 'gift'
        LEFT JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
        LEFT JOIN gift_cards gft ON gm.gift_card_id = gft.id
        WHERE m.conversation_id = p_conversation_id
        ORDER BY m.created_at DESC
        LIMIT p_limit OFFSET p_offset
    )
    SELECT 
        jsonb_build_object(
            'message_id', md.id,
            'sender_id', md.sender_id,
            'sender_username', md.sender_username,
            'sender_profile_picture', md.sender_profile_picture,
            'message_type', md.message_type,
            'created_at', md.created_at,
            'read_at', md.read_at,
            'data', CASE 
                WHEN md.message_type = 'text' THEN md.text_data
                WHEN md.message_type = 'gift' THEN md.gift_data
                ELSE NULL
            END
        ) AS message_data
    FROM message_data md
    ORDER BY md.created_at ASC; -- Re-order for display (newest messages at bottom)
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_conversation_messages(p_user_id uuid, p_conversation_id uuid, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(message_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Check if user is part of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = p_conversation_id AND user_id = p_user_id
    ) THEN
        RAISE EXCEPTION 'User % is not a participant in conversation %', p_user_id, p_conversation_id;
    END IF;

    -- Mark unread messages as read
    UPDATE messages
    SET read_at = CURRENT_TIMESTAMP
    WHERE conversation_id = p_conversation_id
    AND sender_id != p_user_id
    AND read_at IS NULL;
    
    RETURN QUERY
    WITH message_data AS (
        SELECT 
            m.id,
            m.sender_id,
            u.username AS sender_username,
            u.profile_picture_url AS sender_profile_picture,
            m.message_type,
            m.created_at,
            m.read_at,
            -- Text message content
            CASE WHEN m.message_type = 'text' THEN
                jsonb_build_object('content', tm.content)
            ELSE NULL END AS text_data,
            -- Gift message content
            CASE WHEN m.message_type = 'gift' THEN
                jsonb_build_object(
                    'greeting_card', jsonb_build_object(
                        'id', gc.id,
                        'front_image_url', gc.front_image_url,
                        'back_image_url', gc.back_image_url,
                        'message', gc.message
                    ),
                    'gift_card', CASE WHEN gft.id IS NOT NULL THEN jsonb_build_object(
                        'id', gft.id,
                        'amount', gft.amount,
                        'currency', gft.currency,
                        'retailer', gft.retailer
                    ) ELSE NULL END
                )
            ELSE NULL END AS gift_data
        FROM messages m
        JOIN users u ON m.sender_id = u.id
        LEFT JOIN text_messages tm ON m.id = tm.message_id AND m.message_type = 'text'
        LEFT JOIN gift_messages gm ON m.id = gm.message_id AND m.message_type = 'gift'
        LEFT JOIN greeting_cards gc ON gm.greeting_card_id = gc.id
        LEFT JOIN gift_cards gft ON gm.gift_card_id = gft.id
        WHERE m.conversation_id = p_conversation_id
        ORDER BY m.created_at DESC
        LIMIT p_limit OFFSET p_offset
    )
    SELECT 
        jsonb_build_object(
            'message_id', md.id,
            'sender_id', md.sender_id,
            'sender_username', md.sender_username,
            'sender_profile_picture', md.sender_profile_picture,
            'message_type', md.message_type,
            'created_at', md.created_at,
            'read_at', md.read_at,
            'data', CASE 
                WHEN md.message_type = 'text' THEN md.text_data
                WHEN md.message_type = 'gift' THEN md.gift_data
                ELSE NULL
            END
        ) AS message_data
    FROM message_data md
    ORDER BY md.created_at ASC; -- Re-order for display (newest messages at bottom)
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id integer)
 RETURNS TABLE(conversation_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.id AS message_id,
            m.sender_id,
            u.username AS sender_username,
            m.message_type,
            m.created_at,
            CASE WHEN m.message_type = 'text' THEN tm.content
                 ELSE gc.message
            END AS preview_text,
            (SELECT COUNT(*) FROM messages 
             WHERE conversation_id = m.conversation_id 
             AND sender_id != p_user_id 
             AND read_at IS NULL) AS unread_count
        FROM messages m
        JOIN users u ON m.sender_id = u.id
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
                jsonb_build_object(
                    'user_id', u.id,
                    'username', u.username,
                    'profile_picture_url', u.profile_picture_url
                )
            ) AS participants
        FROM conversation_participants cp
        JOIN users u ON cp.user_id = u.id
        WHERE cp.conversation_id IN (
            SELECT conversation_id 
            FROM conversation_participants 
            WHERE user_id = p_user_id
        )
        GROUP BY cp.conversation_id
    )
    SELECT 
        jsonb_build_object(
            'conversation_id', lm.conversation_id,
            'participants', cp.participants,
            'last_message', jsonb_build_object(
                'message_id', lm.message_id,
                'sender_id', lm.sender_id,
                'sender_username', lm.sender_username,
                'message_type', lm.message_type,
                'preview_text', lm.preview_text,
                'created_at', lm.created_at
            ),
            'unread_count', lm.unread_count
        ) AS conversation_data
    FROM latest_messages lm
    JOIN conversation_participants cp ON lm.conversation_id = cp.conversation_id
    ORDER BY lm.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_user_conversations(p_user_id uuid)
 RETURNS TABLE(conversation_data jsonb)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    WITH latest_messages AS (
        SELECT DISTINCT ON (m.conversation_id)
            m.conversation_id,
            m.id AS message_id,
            m.sender_id,
            u.username AS sender_username,
            m.message_type,
            m.created_at,
            CASE WHEN m.message_type = 'text' THEN tm.content
                 ELSE gc.message
            END AS preview_text,
            (SELECT COUNT(*) FROM messages 
             WHERE conversation_id = m.conversation_id 
             AND sender_id != p_user_id 
             AND read_at IS NULL) AS unread_count
        FROM messages m
        JOIN users u ON m.sender_id = u.id
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
                jsonb_build_object(
                    'user_id', u.id,
                    'username', u.username,
                    'profile_picture_url', u.profile_picture_url
                )
            ) AS participants
        FROM conversation_participants cp
        JOIN users u ON cp.user_id = u.id
        WHERE cp.conversation_id IN (
            SELECT conversation_id 
            FROM conversation_participants 
            WHERE user_id = p_user_id
        )
        GROUP BY cp.conversation_id
    )
    SELECT 
        jsonb_build_object(
            'conversation_id', lm.conversation_id,
            'participants', cp.participants,
            'last_message', jsonb_build_object(
                'message_id', lm.message_id,
                'sender_id', lm.sender_id,
                'sender_username', lm.sender_username,
                'message_type', lm.message_type,
                'preview_text', lm.preview_text,
                'created_at', lm.created_at
            ),
            'unread_count', lm.unread_count
        ) AS conversation_data
    FROM latest_messages lm
    JOIN conversation_participants cp ON lm.conversation_id = cp.conversation_id
    ORDER BY lm.created_at DESC;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_gift(p_sender_id integer, p_conversation_id integer, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric DEFAULT NULL::numeric, p_gift_card_currency character varying DEFAULT 'USD'::character varying, p_gift_card_retailer character varying DEFAULT NULL::character varying, p_stripe_payment_intent_id character varying DEFAULT NULL::character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_message_id INTEGER;
    v_greeting_card_id INTEGER;
    v_gift_card_id INTEGER := NULL;
    v_payment_id INTEGER := NULL;
    v_result JSONB;
BEGIN
    -- Check if sender is part of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = p_conversation_id AND user_id = p_sender_id
    ) THEN
        RAISE EXCEPTION 'User % is not a participant in conversation %', p_sender_id, p_conversation_id;
    END IF;

    -- Create greeting card
    INSERT INTO greeting_cards (
        front_image_url,
        back_image_url,
        message,
        created_at
    ) VALUES (
        p_front_image_url,
        p_back_image_url,
        p_greeting_message,
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_greeting_card_id;

    -- If gift card is included, create payment and gift card
    IF p_gift_card_amount IS NOT NULL AND p_gift_card_retailer IS NOT NULL AND p_stripe_payment_intent_id IS NOT NULL THEN
        -- Create payment record
        INSERT INTO transactions (
            sender_id,
            stripe_payment_intent_id,
            amount,
            currency,
            status,
            created_at,
            updated_at
        ) VALUES (
            p_sender_id,
            p_stripe_payment_intent_id,
            p_gift_card_amount,
            p_gift_card_currency,
            'completed',
            CURRENT_TIMESTAMP,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO v_payment_id;

        -- Create gift card
        INSERT INTO gift_cards (
            amount,
            currency,
            retailer,
            created_at
        ) VALUES (
            p_gift_card_amount,
            p_gift_card_currency,
            p_gift_card_retailer,
            CURRENT_TIMESTAMP
        ) RETURNING id INTO v_gift_card_id;
    END IF;

    -- Insert into messages table
    INSERT INTO messages (
        conversation_id,
        sender_id,
        message_type,
        created_at
    ) VALUES (
        p_conversation_id,
        p_sender_id,
        'gift',
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_message_id;

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
        v_transaction_id
    );

    -- Get the complete gift message data
    SELECT jsonb_build_object(
        'message_id', m.id,
        'conversation_id', m.conversation_id,
        'sender_id', m.sender_id,
        'sender_username', u.username,
        'message_type', m.message_type,
        'created_at', m.created_at,
        'read_at', m.read_at,
        'gift', jsonb_build_object(
            'greeting_card', jsonb_build_object(
                'id', gc.id,
                'front_image_url', gc.front_image_url,
                'back_image_url', gc.back_image_url,
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
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_gift(p_sender_id uuid, p_conversation_id uuid, p_front_image_url character varying, p_back_image_url character varying, p_greeting_message text, p_gift_card_amount numeric DEFAULT NULL::numeric, p_gift_card_currency character varying DEFAULT 'USD'::character varying, p_gift_card_retailer character varying DEFAULT NULL::character varying, p_stripe_payment_id character varying DEFAULT NULL::character varying)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
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
        front_image_url,
        back_image_url,
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
        payment_id
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
        'sender_username', u.username,
        'message_type', m.message_type,
        'created_at', m.created_at,
        'read_at', m.read_at,
        'gift', jsonb_build_object(
            'greeting_card', jsonb_build_object(
                'id', gc.id,
                'front_image_url', gc.front_image_url,
                'back_image_url', gc.back_image_url,
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
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_text_message(p_sender_id integer, p_conversation_id integer, p_content text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_message_id INTEGER;
    v_result JSONB;
BEGIN
    -- Check if sender is part of the conversation
    IF NOT EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_id = p_conversation_id AND user_id = p_sender_id
    ) THEN
        RAISE EXCEPTION 'User % is not a participant in conversation %', p_sender_id, p_conversation_id;
    END IF;

    -- Insert into messages table
    INSERT INTO messages (
        conversation_id, 
        sender_id, 
        message_type, 
        created_at
    ) VALUES (
        p_conversation_id, 
        p_sender_id, 
        'text', 
        CURRENT_TIMESTAMP
    ) RETURNING id INTO v_message_id;

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
        'sender_username', u.username,
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
END;
$function$
;

CREATE OR REPLACE FUNCTION public.send_text_message(p_sender_id uuid, p_conversation_id uuid, p_content text)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
DECLARE
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
        'sender_username', u.username,
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
END;
$function$
;

grant delete on table "public"."conversation_participants" to "anon";

grant insert on table "public"."conversation_participants" to "anon";

grant references on table "public"."conversation_participants" to "anon";

grant select on table "public"."conversation_participants" to "anon";

grant trigger on table "public"."conversation_participants" to "anon";

grant truncate on table "public"."conversation_participants" to "anon";

grant update on table "public"."conversation_participants" to "anon";

grant delete on table "public"."conversation_participants" to "authenticated";

grant insert on table "public"."conversation_participants" to "authenticated";

grant references on table "public"."conversation_participants" to "authenticated";

grant select on table "public"."conversation_participants" to "authenticated";

grant trigger on table "public"."conversation_participants" to "authenticated";

grant truncate on table "public"."conversation_participants" to "authenticated";

grant update on table "public"."conversation_participants" to "authenticated";

grant delete on table "public"."conversation_participants" to "service_role";

grant insert on table "public"."conversation_participants" to "service_role";

grant references on table "public"."conversation_participants" to "service_role";

grant select on table "public"."conversation_participants" to "service_role";

grant trigger on table "public"."conversation_participants" to "service_role";

grant truncate on table "public"."conversation_participants" to "service_role";

grant update on table "public"."conversation_participants" to "service_role";

grant delete on table "public"."gift_messages" to "anon";

grant insert on table "public"."gift_messages" to "anon";

grant references on table "public"."gift_messages" to "anon";

grant select on table "public"."gift_messages" to "anon";

grant trigger on table "public"."gift_messages" to "anon";

grant truncate on table "public"."gift_messages" to "anon";

grant update on table "public"."gift_messages" to "anon";

grant delete on table "public"."gift_messages" to "authenticated";

grant insert on table "public"."gift_messages" to "authenticated";

grant references on table "public"."gift_messages" to "authenticated";

grant select on table "public"."gift_messages" to "authenticated";

grant trigger on table "public"."gift_messages" to "authenticated";

grant truncate on table "public"."gift_messages" to "authenticated";

grant update on table "public"."gift_messages" to "authenticated";

grant delete on table "public"."gift_messages" to "service_role";

grant insert on table "public"."gift_messages" to "service_role";

grant references on table "public"."gift_messages" to "service_role";

grant select on table "public"."gift_messages" to "service_role";

grant trigger on table "public"."gift_messages" to "service_role";

grant truncate on table "public"."gift_messages" to "service_role";

grant update on table "public"."gift_messages" to "service_role";

grant delete on table "public"."messages" to "anon";

grant insert on table "public"."messages" to "anon";

grant references on table "public"."messages" to "anon";

grant select on table "public"."messages" to "anon";

grant trigger on table "public"."messages" to "anon";

grant truncate on table "public"."messages" to "anon";

grant update on table "public"."messages" to "anon";

grant delete on table "public"."messages" to "authenticated";

grant insert on table "public"."messages" to "authenticated";

grant references on table "public"."messages" to "authenticated";

grant select on table "public"."messages" to "authenticated";

grant trigger on table "public"."messages" to "authenticated";

grant truncate on table "public"."messages" to "authenticated";

grant update on table "public"."messages" to "authenticated";

grant delete on table "public"."messages" to "service_role";

grant insert on table "public"."messages" to "service_role";

grant references on table "public"."messages" to "service_role";

grant select on table "public"."messages" to "service_role";

grant trigger on table "public"."messages" to "service_role";

grant truncate on table "public"."messages" to "service_role";

grant update on table "public"."messages" to "service_role";

grant delete on table "public"."messages" to "supabase_auth_admin";

grant insert on table "public"."messages" to "supabase_auth_admin";

grant references on table "public"."messages" to "supabase_auth_admin";

grant select on table "public"."messages" to "supabase_auth_admin";

grant trigger on table "public"."messages" to "supabase_auth_admin";

grant truncate on table "public"."messages" to "supabase_auth_admin";

grant update on table "public"."messages" to "supabase_auth_admin";

grant delete on table "public"."text_messages" to "anon";

grant insert on table "public"."text_messages" to "anon";

grant references on table "public"."text_messages" to "anon";

grant select on table "public"."text_messages" to "anon";

grant trigger on table "public"."text_messages" to "anon";

grant truncate on table "public"."text_messages" to "anon";

grant update on table "public"."text_messages" to "anon";

grant delete on table "public"."text_messages" to "authenticated";

grant insert on table "public"."text_messages" to "authenticated";

grant references on table "public"."text_messages" to "authenticated";

grant select on table "public"."text_messages" to "authenticated";

grant trigger on table "public"."text_messages" to "authenticated";

grant truncate on table "public"."text_messages" to "authenticated";

grant update on table "public"."text_messages" to "authenticated";

grant delete on table "public"."text_messages" to "service_role";

grant insert on table "public"."text_messages" to "service_role";

grant references on table "public"."text_messages" to "service_role";

grant select on table "public"."text_messages" to "service_role";

grant trigger on table "public"."text_messages" to "service_role";

grant truncate on table "public"."text_messages" to "service_role";

grant update on table "public"."text_messages" to "service_role";


