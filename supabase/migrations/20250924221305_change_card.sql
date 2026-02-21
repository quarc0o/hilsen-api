alter table "public"."greeting_cards" add column "overlay_items" jsonb[];

alter table "public"."greeting_cards" add column "user_id" uuid;

alter table "public"."greeting_cards" add constraint "greeting_cards_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) not valid;

alter table "public"."greeting_cards" validate constraint "greeting_cards_user_id_fkey";


