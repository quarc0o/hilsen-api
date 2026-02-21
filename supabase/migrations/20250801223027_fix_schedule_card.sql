alter table "public"."scheduled_cards" drop constraint "scheduled_cards_chat_message_id_fkey";

alter table "public"."scheduled_cards" drop column "chat_message_id";

alter table "public"."scheduled_cards" drop column "conversation_id";

alter table "public"."scheduled_cards" add column "sender_id" uuid;

alter table "public"."scheduled_cards" add constraint "scheduled_cards_sender_id_fkey" FOREIGN KEY (sender_id) REFERENCES users(id) not valid;

alter table "public"."scheduled_cards" validate constraint "scheduled_cards_sender_id_fkey";


