-- V3, Phase 18: what a member may queue (plan decision 9; 0035 left members none). Three requests, each limited to its
-- kind and the centre's own rows, each answering the live job for the same subject, so a second tap starts nothing:
-- request_plan (Today's Try Again, Make the plan again with choices, a school item's change), request_note (a note the
-- note day did not write), request_export (the student's file). enqueue_job stays the platform's.

-- The one writer of the three. It is granted to members because the requests run as the caller (security invoker), so
-- it checks everything itself: the membership, the kind, the subject in the centre and named by the input, and it names
-- the key. A direct call can queue nothing a request could not.
create function public.request_job(p_centre uuid, p_kind public.job_kind, p_subject uuid, p_input jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_live uuid;
  v_id uuid;
  v_key text;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_kind not in ('plan', 'note_day', 'export') then raise exception 'job_kind' using errcode = 'P0001'; end if;
  if p_kind = 'plan' then
    if p_input->>'class_id' is distinct from p_subject::text or (p_input->>'date') is null or not exists (
         select 1 from public.classes c where c.centre_id = p_centre and c.id = p_subject and c.archived_at is null) then
      raise exception 'not_found' using errcode = 'P0001';
    end if;
    v_key := 'plan:' || p_subject || ':' || (p_input->>'date')::date;
  else
    if p_input->>'student_id' is distinct from p_subject::text or not exists (
         select 1 from public.students s where s.centre_id = p_centre and s.id = p_subject) then
      raise exception 'not_found' using errcode = 'P0001';
    end if;
    v_key := case p_kind when 'note_day' then 'note:' || p_subject || ':' || (p_input->>'week')::date
                         else 'export:' || p_subject end;
  end if;

  select j.id into v_live from public.jobs j
   where j.centre_id = p_centre and j.kind = p_kind and j.state in ('queued', 'running', 'waiting')
     and (j.input->>'class_id' = p_subject::text or j.input->>'student_id' = p_subject::text)
     and (p_kind <> 'plan' or j.input->>'date' = p_input->>'date')
     and (p_kind <> 'note_day' or j.input->>'week' = p_input->>'week')
   order by j.created_at desc limit 1;
  if v_live is not null then return v_live; end if;

  perform set_config('tc.jobs', 'on', true);
  if p_kind <> 'export' then
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, p_kind, v_key, p_input)
    on conflict do nothing returning id into v_id;
  end if;
  if v_id is null then  -- the plain key was used by an earlier, finished job (an export is always fresh)
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, p_kind, v_key || ':' || (extract(epoch from clock_timestamp()) * 1000)::bigint, p_input)
    returning id into v_id;
  end if;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;

-- p_choices set means a replacing plan (Make the plan again); the job never replaces a closed one.
create function public.request_plan(p_centre uuid, p_class uuid, p_date date, p_choices jsonb default null)
returns uuid language plpgsql security invoker set search_path = '' as $$
begin
  if p_date is null then raise exception 'not_found' using errcode = 'P0001'; end if;
  return public.request_job(p_centre, 'plan', p_class,
    jsonb_build_object('class_id', p_class, 'date', p_date)
    || case when p_choices is null then '{}'::jsonb else jsonb_build_object('replace', true, 'choices', p_choices) end);
end $$;

-- A week is named by its Monday, as the note day's facts are.
create function public.request_note(p_centre uuid, p_student uuid, p_week date)
returns uuid language plpgsql security invoker set search_path = '' as $$
begin
  if p_week is null or extract(isodow from p_week) <> 1 then raise exception 'note_week' using errcode = 'P0001'; end if;
  return public.request_job(p_centre, 'note_day', p_student, jsonb_build_object('student_id', p_student, 'week', p_week));
end $$;

create function public.request_export(p_centre uuid, p_student uuid)
returns uuid language plpgsql security invoker set search_path = '' as $$
begin
  return public.request_job(p_centre, 'export', p_student, jsonb_build_object('student_id', p_student));
end $$;

revoke all on function public.request_job(uuid, public.job_kind, uuid, jsonb) from public, anon;
revoke all on function public.request_plan(uuid, uuid, date, jsonb) from public, anon;
revoke all on function public.request_note(uuid, uuid, date) from public, anon;
revoke all on function public.request_export(uuid, uuid) from public, anon;
grant execute on function public.request_job(uuid, public.job_kind, uuid, jsonb) to authenticated, service_role;
grant execute on function public.request_plan(uuid, uuid, date, jsonb) to authenticated, service_role;
grant execute on function public.request_note(uuid, uuid, date) to authenticated, service_role;
grant execute on function public.request_export(uuid, uuid) to authenticated, service_role;
