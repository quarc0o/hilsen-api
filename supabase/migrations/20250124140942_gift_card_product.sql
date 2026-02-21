create extension if not exists "pg_cron" with schema "public" version '1.4-1';

create table "public"."gift_card_products" (
    "title" text not null,
    "image_url" text,
    "id" uuid not null default gen_random_uuid()
);


CREATE UNIQUE INDEX gift_card_products_id_key ON public.gift_card_products USING btree (id);

CREATE UNIQUE INDEX gift_card_products_pkey ON public.gift_card_products USING btree (id);

alter table "public"."gift_card_products" add constraint "gift_card_products_pkey" PRIMARY KEY using index "gift_card_products_pkey";

alter table "public"."gift_card_products" add constraint "gift_card_products_id_key" UNIQUE using index "gift_card_products_id_key";

grant delete on table "public"."gift_card_products" to "anon";

grant insert on table "public"."gift_card_products" to "anon";

grant references on table "public"."gift_card_products" to "anon";

grant select on table "public"."gift_card_products" to "anon";

grant trigger on table "public"."gift_card_products" to "anon";

grant truncate on table "public"."gift_card_products" to "anon";

grant update on table "public"."gift_card_products" to "anon";

grant delete on table "public"."gift_card_products" to "authenticated";

grant insert on table "public"."gift_card_products" to "authenticated";

grant references on table "public"."gift_card_products" to "authenticated";

grant select on table "public"."gift_card_products" to "authenticated";

grant trigger on table "public"."gift_card_products" to "authenticated";

grant truncate on table "public"."gift_card_products" to "authenticated";

grant update on table "public"."gift_card_products" to "authenticated";

grant delete on table "public"."gift_card_products" to "service_role";

grant insert on table "public"."gift_card_products" to "service_role";

grant references on table "public"."gift_card_products" to "service_role";

grant select on table "public"."gift_card_products" to "service_role";

grant trigger on table "public"."gift_card_products" to "service_role";

grant truncate on table "public"."gift_card_products" to "service_role";

grant update on table "public"."gift_card_products" to "service_role";


