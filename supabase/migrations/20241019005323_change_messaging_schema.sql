alter table "public"."chat_messages" drop constraint "public_chat_messages_conversation_id_fkey";

alter table "public"."chat_messages" drop constraint "public_chat_messages_recipient_phone_number_fkey";

alter table "public"."chat_messages" drop constraint "public_chat_messages_sender_phone_number_fkey";

alter table "public"."conversations" drop constraint "conversations_pkey";

drop index if exists "public"."conversations_pkey";

alter table "public"."chat_messages" drop column "recipient_phone_number";

alter table "public"."chat_messages" drop column "sender_phone_number";

alter table "public"."chat_messages" drop column "test_row";

alter table "public"."chat_messages" add column "user_phone" text;

alter table "public"."conversations" drop column "participant_one_phone";

alter table "public"."conversations" drop column "participant_two_phone";

alter table "public"."conversations" add column "user_phone" text not null default '535335'::text;

CREATE UNIQUE INDEX conversations_pkey ON public.conversations USING btree (id, user_phone);

alter table "public"."conversations" add constraint "conversations_pkey" PRIMARY KEY using index "conversations_pkey";

alter table "public"."chat_messages" add constraint "fk_chat_messages_conversation" FOREIGN KEY (conversation_id, user_phone) REFERENCES conversations(id, user_phone) ON DELETE CASCADE not valid;

alter table "public"."chat_messages" validate constraint "fk_chat_messages_conversation";


