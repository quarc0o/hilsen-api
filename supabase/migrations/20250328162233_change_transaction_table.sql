alter table "public"."transactions" add column "recipient_id" uuid not null default gen_random_uuid();

alter table "public"."transactions" add column "stripe_payment_status" text;

alter table "public"."transactions" add constraint "transactions_recipient_id_fkey" FOREIGN KEY (recipient_id) REFERENCES users(id) not valid;

alter table "public"."transactions" validate constraint "transactions_recipient_id_fkey";


