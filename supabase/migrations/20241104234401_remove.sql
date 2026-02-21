alter table "public"."greeting_cards" drop constraint "greeting_cards_gift_id_key";

alter table "public"."greeting_cards" drop constraint "public_greeting_cards_gift_id_fkey";

drop index if exists "public"."greeting_cards_gift_id_key";

alter table "public"."greeting_cards" drop column "gift_id";


