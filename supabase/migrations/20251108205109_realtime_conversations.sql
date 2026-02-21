alter table "public"."conversations" add column "last_message_id" uuid;

CREATE INDEX idx_conversations_last_message_id ON public.conversations USING btree (last_message_id);

alter table "public"."conversations" add constraint "conversations_last_message_id_fkey" FOREIGN KEY (last_message_id) REFERENCES messages(id) not valid;

alter table "public"."conversations" validate constraint "conversations_last_message_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.update_conversation_on_message_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE conversations
  SET
    last_message_id = NEW.id,
    updated_at = NEW.created_at
  WHERE id = NEW.conversation_id;

  RETURN NEW;
END;
$function$
;

CREATE TRIGGER trigger_update_conversation_on_message AFTER INSERT ON public.messages FOR EACH ROW EXECUTE FUNCTION update_conversation_on_message_insert();


