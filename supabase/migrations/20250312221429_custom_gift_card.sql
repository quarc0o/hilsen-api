create table "public"."custom_gift_cards" (
    "id" uuid not null default gen_random_uuid(),
    "created_at" timestamp with time zone not null default now(),
    "brand_name" text,
    "card_value" bigint,
    "card_code" text,
    "expiration_date" date,
    "user_id" uuid not null default gen_random_uuid()
);


CREATE UNIQUE INDEX custom_gift_cards_pkey ON public.custom_gift_cards USING btree (id);

alter table "public"."custom_gift_cards" add constraint "custom_gift_cards_pkey" PRIMARY KEY using index "custom_gift_cards_pkey";

alter table "public"."custom_gift_cards" add constraint "custom_gift_cards_user_id_fkey" FOREIGN KEY (user_id) REFERENCES users(id) not valid;

alter table "public"."custom_gift_cards" validate constraint "custom_gift_cards_user_id_fkey";

grant delete on table "public"."custom_gift_cards" to "anon";

grant insert on table "public"."custom_gift_cards" to "anon";

grant references on table "public"."custom_gift_cards" to "anon";

grant select on table "public"."custom_gift_cards" to "anon";

grant trigger on table "public"."custom_gift_cards" to "anon";

grant truncate on table "public"."custom_gift_cards" to "anon";

grant update on table "public"."custom_gift_cards" to "anon";

grant delete on table "public"."custom_gift_cards" to "authenticated";

grant insert on table "public"."custom_gift_cards" to "authenticated";

grant references on table "public"."custom_gift_cards" to "authenticated";

grant select on table "public"."custom_gift_cards" to "authenticated";

grant trigger on table "public"."custom_gift_cards" to "authenticated";

grant truncate on table "public"."custom_gift_cards" to "authenticated";

grant update on table "public"."custom_gift_cards" to "authenticated";

grant delete on table "public"."custom_gift_cards" to "service_role";

grant insert on table "public"."custom_gift_cards" to "service_role";

grant references on table "public"."custom_gift_cards" to "service_role";

grant select on table "public"."custom_gift_cards" to "service_role";

grant trigger on table "public"."custom_gift_cards" to "service_role";

grant truncate on table "public"."custom_gift_cards" to "service_role";

grant update on table "public"."custom_gift_cards" to "service_role";


