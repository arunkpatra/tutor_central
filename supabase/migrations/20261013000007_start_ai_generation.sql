-- One call before an AI call: the member check, the consent for a child's data (a scan, a check, a progress note), the
-- day's limit per kind group (40 generations; 20 scans; 20 checks; failed calls do not count), and the pending record.
-- The API finishes the row with a plain update as the user (docs/spec.md section 6). Because that user can also mark
-- their own rows failed, every call started in the day also meets a hard cap of half as many again (60, 30, 30), and
-- a member can neither delete a call nor change its centre, kind or time (the grants at the end).
create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
  v_started integer;
  v_id uuid;
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  if p_kind in ('scan_register', 'check_paper', 'progress_note')
     and (select c.ai_consent_at from public.centres c where c.id = p_centre) is null then
    raise exception 'ai_consent_missing';
  end if;
  if p_kind in ('paper', 'homework', 'worksheet', 'progress_note') then
    v_group := array['paper', 'homework', 'worksheet', 'progress_note']::public.ai_kind[];
    v_limit := 40;
  else
    v_group := array[p_kind];
    v_limit := 20;
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= now() - interval '24 hours';
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) from public;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) to authenticated;

-- The record of a call is the API's: a member may finish it (status, output, model, tokens) and nothing else.
revoke delete, update on public.ai_generations from authenticated;
grant update (status, output, model, tokens_in, tokens_out) on public.ai_generations to authenticated;
