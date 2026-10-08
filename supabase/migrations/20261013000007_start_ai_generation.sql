-- One call before an AI call: the member check, the consent for a child's data (a scan, a check, a progress note), the
-- day's limit per kind group (40 generations; 20 scans; 20 checks; failed calls do not count), and the pending record.
-- The API finishes the row with a plain update as the user (docs/spec.md section 6).
create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
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
  select count(*) into v_count from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.status <> 'failed'
     and g.created_at >= now() - interval '24 hours';
  if v_count >= v_limit then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) from public;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text) to authenticated;
