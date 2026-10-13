-- V3, Phase 19's hand runs (F2, F3): every row the portal lists carries its own id, so two rows at one moment are two
-- rows (the activity's fee payments, the record's students and what was made); a job kind with nothing to name (an
-- artefact, an eval run) has no subject, not its kind twice. The functions' signatures and grants are unchanged.

create or replace function public.admin_job_subject(p_kind public.job_kind, p_input jsonb, p_key text)
returns text language sql stable security invoker set search_path = '' as $$
  select case
    when p_kind in ('plan', 'note_day') and p_input ? 'class_id' then
      coalesce((select c.name from public.classes c where c.id = (p_input ->> 'class_id')::uuid), 'a batch')
        || coalesce(' · ' || to_char((p_input ->> 'date')::date, 'FMDD Mon'), '')
    when p_kind in ('note_day', 'export') then 'a student'
    when p_kind = 'pdf' then
      coalesce((select a.title from public.artefacts a where a.id = (p_input ->> 'artefact_id')::uuid), 'a file')
    when p_kind = 'reminder_sweep' then case when p_key ~ 'T[0-9]{2}$' then 'hourly' else 'after a change' end
    when p_kind in ('sweep', 'alerts') then 'every 10 minutes'
    else null
  end;
$$;

create or replace function public.admin_activity(p_centre uuid, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(to_jsonb(a) order by a.at desc), '[]'::jsonb) from (
    select * from (
      select e.id, e.at, e.kind, e.screen, null::text as what, split_part(p.display_name, ' ', 1) as who
        from public.events e left join public.profiles p on p.user_id = e.user_id
       where e.centre_id = p_centre
      union all
      select s.id, s.closed_at, 'close', null, 'Closed a class · ' || k.name || ' · '
               || (select count(*) from public.attendance_marks am where am.session_id = s.id and am.status = 'present') || ' present', null
        from public.attendance_sessions s join public.classes k on k.id = s.class_id
       where s.centre_id = p_centre and s.closed_at is not null
      union all
      select m.id, m.created_at, 'message', null,
             case when m.kind in ('note', 'progress', 'can_do') then 'Sent a note' else 'Sent a message · ' || replace(m.kind::text, '_', ' ') end
               || case when m.channel = 'whatsapp_link' then ' · WhatsApp' else ' · copied' end, null
        from public.message_log m where m.centre_id = p_centre
      union all
      select f.id, f.paid_at, 'fee_paid', null, 'Marked a fee paid', null
        from public.fee_invoices f where f.centre_id = p_centre and f.paid_at is not null
      union all
      select a.id, a.created_at, 'made_again', null, 'Made a ' || replace(a.kind::text, '_', ' ') || ' again', null
        from public.artefacts a where a.centre_id = p_centre and a.regenerated_from is not null
    ) u order by u.at desc limit p_limit) a;
$$;

create or replace function public.admin_record(p_centre uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'centre', jsonb_build_object('id', c.id, 'name', c.name),
    'students', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id, 'name', s.name, 'class_level', s.class_level, 'batch', k.name,
        'consent', case
          when s.consent_at is not null then jsonb_build_object('state', 'given', 'day', (s.consent_at at time zone 'Asia/Kolkata')::date)
          when w.at is not null and not exists (select 1 from public.message_log m where m.student_id = s.id and m.kind = 'consent' and m.created_at > w.at)
            then jsonb_build_object('state', 'withdrawn', 'day', (w.at at time zone 'Asia/Kolkata')::date)
          when exists (select 1 from public.message_log m where m.student_id = s.id and m.kind = 'consent')
            then jsonb_build_object('state', 'asked', 'day', null)
          else jsonb_build_object('state', 'not_asked', 'day', null) end,
        'tracking', s.track_status) order by k.name nulls last, s.name), '[]'::jsonb)
        from public.students s
        left join public.classes k on k.id = s.class_id
        left join lateral (select max(ce.at) as at from public.consent_events ce where ce.student_id = s.id and ce.kind = 'withdrawn') w on true
       where s.centre_id = c.id and s.archived_at is null),
    'batches', (select coalesce(jsonb_agg(jsonb_build_object(
        'name', k.name, 'days', to_jsonb(k.meeting_days), 'start_time', k.start_time, 'end_time', k.end_time,
        'students', (select count(*) from public.students s where s.class_id = k.id and s.archived_at is null)) order by k.name), '[]'::jsonb)
        from public.classes k where k.centre_id = c.id and k.archived_at is null),
    'made', (select coalesce(jsonb_agg(jsonb_build_object('id', g.id, 'at', g.created_at, 'kind', g.kind, 'title', a.title,
               'student', s.name, 'cost_paise', coalesce(g.cost_paise, 0)) order by g.created_at desc), '[]'::jsonb)
        from (select * from public.ai_generations g0 where g0.centre_id = c.id and g0.status = 'ok' order by g0.created_at desc limit 20) g
        left join public.artefacts a on a.generation_id = g.id
        left join public.students s on s.id = g.student_id))
  from public.centres c where c.id = p_centre;
$$;
