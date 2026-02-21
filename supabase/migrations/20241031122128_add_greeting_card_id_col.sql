alter table "public"."gifts" add column "greeting_card_id" uuid;

alter table "public"."greeting_cards" add column "id" uuid not null default gen_random_uuid();

CREATE UNIQUE INDEX greeting_cards_pkey ON public.greeting_cards USING btree (id);

alter table "public"."greeting_cards" add constraint "greeting_cards_pkey" PRIMARY KEY using index "greeting_cards_pkey";

alter table "public"."gifts" add constraint "gifts_greeting_card_id_fkey" FOREIGN KEY (greeting_card_id) REFERENCES greeting_cards(id) ON UPDATE CASCADE ON DELETE SET NULL not valid;

alter table "public"."gifts" validate constraint "gifts_greeting_card_id_fkey";


