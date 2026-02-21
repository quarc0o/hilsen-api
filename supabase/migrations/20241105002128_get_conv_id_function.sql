set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_conversation_id(phone_numbers text[])
 RETURNS uuid
 LANGUAGE plpgsql
AS $function$
declare
    conversation_id uuid;
begin
    select id::uuid into conversation_id
    from conversations c
    where id in (
        select id::uuid
        from conversations
        where user_phone = any(phone_numbers)
        group by id
        having count(user_phone) = array_length(phone_numbers, 1)
    )
    and (
        select array_agg(user_phone order by user_phone)
        from conversations
        where id = c.id
    ) = array(select unnest(phone_numbers) order by 1);

    return conversation_id;
exception
    when no_data_found then
        return null;
end;
$function$
;


