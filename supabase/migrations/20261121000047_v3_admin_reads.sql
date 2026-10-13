-- V3, Phase 19 (D78, D94): what the admin portal reads, one function per page or section, granted to the platform alone
-- (the portal's server calls them with the service key; a member gets 42501). Every aggregation is here, not in the
-- portal; a function selects only what its board shows. Never a parent's number, a photo, a message's text, or a personal
-- kind's input while the student's consent is not current. A student's name only through the audited record
-- (admin_open_record, admin_record_opened). Days are India's (Asia/Kolkata); a month is its first day.

-- What a job is about, in the board's words: a batch and its day, "a student", a file's title, "hourly".
create function public.admin_job_subject(p_kind public.job_kind, p_input jsonb, p_key text)
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
    else p_kind::text
  end;
$$;

-- One job as a list row: the subject, the step reached, the made counts, the reason it failed. It takes the id, not the
-- row: PostgREST would expose a function of a table's row as a column of that table.
create function public.admin_job_row(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'id', j.id, 'kind', j.kind, 'centre_id', j.centre_id,
    'centre', (select c.name from public.centres c where c.id = j.centre_id),
    'subject', public.admin_job_subject(j.kind, j.input, j.idempotency_key),
    'state', j.state,
    'step', case when j.step ? 'at' then (j.step ->> 'at') || coalesce(':' || (j.step ->> 'n'), '') end,
    'run_at', j.run_at, 'started_at', j.started_at, 'finished_at', j.finished_at, 'created_at', j.created_at,
    'seconds', case when j.started_at is not null and j.finished_at is not null
                    then round(extract(epoch from j.finished_at - j.started_at)::numeric, 1) end,
    'attempts', j.attempts, 'cost_paise', j.cost_paise,
    'made', (j.result ->> 'made')::int,
    'not_made', case when jsonb_typeof(j.result -> 'not_made') = 'array' then jsonb_array_length(j.result -> 'not_made')
                     else (j.result ->> 'not_made')::int end,
    'reason', j.error ->> 'reason',
    'by_member', j.created_by is not null)
    from public.jobs j where j.id = p_id;
$$;

-- The cost of a centre (or of all, p_centre null) in a month, in paise, and its calls.
create function public.admin_month_cost(p_month date, p_centre uuid)
returns table (paise bigint, calls bigint) language sql stable security invoker set search_path = '' as $$
  select coalesce(sum(g.cost_paise), 0)::bigint, count(*)::bigint
    from public.ai_generations g
   where (p_centre is null or g.centre_id = p_centre)
     and (g.created_at at time zone 'Asia/Kolkata')::date >= p_month
     and (g.created_at at time zone 'Asia/Kolkata')::date < (p_month + interval '1 month')::date;
$$;

-- Today in India.
create function public.admin_today() returns date language sql stable security invoker set search_path = '' as $$
  select (now() at time zone 'Asia/Kolkata')::date;
$$;

create function public.admin_centres(p_month date)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with rows as (
    select c.id, c.name, p.display_name as owner_name, c.created_at as since,
           (select count(*) from public.students s where s.centre_id = c.id and s.archived_at is null)::int as students,
           (select count(*) from public.centre_members m where m.centre_id = c.id)::int as tutors,
           (select max(e.at) from public.events e where e.centre_id = c.id and e.kind = 'app_opened') as last_opened,
           (select mc.paise from public.admin_month_cost(p_month, c.id) mc)::int as cost_paise,
           public.centre_in_use(c.id, now()) as in_use,
           (select count(*) from public.jobs j where j.centre_id = c.id
               and (j.created_at at time zone 'Asia/Kolkata')::date = public.admin_today())::int as jobs_today,
           (select count(*) from public.jobs j where j.centre_id = c.id and j.state = 'failed'
               and (j.finished_at at time zone 'Asia/Kolkata')::date = public.admin_today())::int as failed_today
      from public.centres c left join public.profiles p on p.user_id = c.owner_id)
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'centres', (select count(*) from rows),
      'active_week', (select count(distinct e.centre_id) from public.events e
                       where e.kind = 'app_opened' and e.at > now() - interval '7 days'),
      'cost_paise', (select mc.paise from public.admin_month_cost(p_month, null) mc),
      'failed_today', (select count(*) from public.jobs j where j.state = 'failed'
                        and (j.finished_at at time zone 'Asia/Kolkata')::date = public.admin_today())),
    'rows', coalesce((select jsonb_agg(to_jsonb(r) order by r.cost_paise desc, r.name) from rows r), '[]'::jsonb));
$$;

-- The plan's kinds, the notes' and the exams' (the centre's cost split); the rest are "other".
create function public.admin_kind_group(p_kind text) returns text
language sql immutable security invoker set search_path = '' as $$
  select case
    when p_kind in ('plan', 'sheet', 'worked_example', 'figure', 'brief', 'check', 'placement') then 'plan'
    when p_kind in ('note', 'can_do', 'test_tomorrow', 'not_on_track', 'progress_note') then 'notes'
    when p_kind in ('mock', 'check_paper', 'gap_report', 'read_marks') then 'exams'
    else 'other' end;
$$;

create function public.admin_centre(p_centre uuid, p_month date)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with month as (
    select g.kind::text as kind, g.model, coalesce(g.cost_paise, 0) as paise
      from public.ai_generations g
     where g.centre_id = p_centre
       and (g.created_at at time zone 'Asia/Kolkata')::date >= p_month
       and (g.created_at at time zone 'Asia/Kolkata')::date < (p_month + interval '1 month')::date)
  select jsonb_build_object(
    'id', c.id, 'name', c.name, 'owner_name', p.display_name, 'since', c.created_at,
    'students', (select count(*) from public.students s where s.centre_id = c.id and s.archived_at is null),
    'batches', (select count(*) from public.classes k where k.centre_id = c.id and k.archived_at is null),
    'in_use', public.centre_in_use(c.id, now()),
    'cost_paise', (select coalesce(sum(m.paise), 0) from month m),
    'calls', (select count(*) from month),
    'allowance', c.ai_allowance, 'allowance_paise', c.ai_allowance_paise,
    'cost_by_kind', (select jsonb_build_object(
        'plan', coalesce(sum(m.paise) filter (where public.admin_kind_group(m.kind) = 'plan'), 0),
        'notes', coalesce(sum(m.paise) filter (where public.admin_kind_group(m.kind) = 'notes'), 0),
        'exams', coalesce(sum(m.paise) filter (where public.admin_kind_group(m.kind) = 'exams'), 0),
        'other', coalesce(sum(m.paise) filter (where public.admin_kind_group(m.kind) = 'other'), 0)) from month m),
    'cost_by_model', (select coalesce(jsonb_agg(jsonb_build_object('model', x.model, 'paise', x.paise) order by x.paise desc), '[]'::jsonb)
                        from (select coalesce(m.model, 'none') as model, sum(m.paise) as paise from month m group by 1) x),
    'jobs_today', (select count(*) from public.jobs j where j.centre_id = c.id
                    and (j.created_at at time zone 'Asia/Kolkata')::date = public.admin_today()),
    'failed_today', (select count(*) from public.jobs j where j.centre_id = c.id and j.state = 'failed'
                      and (j.finished_at at time zone 'Asia/Kolkata')::date = public.admin_today()),
    'last_close', (select max(s.closed_at) from public.attendance_sessions s where s.centre_id = c.id),
    -- The tutors' emails are not here: auth.users is not the platform's to read in SQL; the portal's server asks the Auth
    -- admin API for each user (a handful a centre).
    'tutors', (select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', m.user_id, 'name', tp.display_name, 'role', m.role,
        'last_sign_in', (select max(e.at) from public.events e where e.user_id = m.user_id and e.kind = 'signed_in'),
        'push', (select jsonb_build_object('build', d.app_build, 'env', d.environment) from public.device_tokens d
                  where d.user_id = m.user_id and d.retired_at is null order by d.last_seen_at desc limit 1))
        order by m.role, m.created_at), '[]'::jsonb)
        from public.centre_members m
        left join public.profiles tp on tp.user_id = m.user_id
       where m.centre_id = c.id))
  from public.centres c left join public.profiles p on p.user_id = c.owner_id
  where c.id = p_centre;
$$;

-- What the tutor did, by kind and time, never the content: the events (their words are the portal's, by kind and
-- screen), closes, notes sent, fees marked paid, material made again. A batch is named; a student never is.
create function public.admin_activity(p_centre uuid, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(to_jsonb(a) order by a.at desc), '[]'::jsonb) from (
    select * from (
      select e.at, e.kind, e.screen, null::text as what, split_part(p.display_name, ' ', 1) as who
        from public.events e left join public.profiles p on p.user_id = e.user_id
       where e.centre_id = p_centre
      union all
      select s.closed_at, 'close', null, 'Closed a class · ' || k.name || ' · '
               || (select count(*) from public.attendance_marks am where am.session_id = s.id and am.status = 'present') || ' present', null
        from public.attendance_sessions s join public.classes k on k.id = s.class_id
       where s.centre_id = p_centre and s.closed_at is not null
      union all
      select m.created_at, 'message', null,
             case when m.kind in ('note', 'progress', 'can_do') then 'Sent a note' else 'Sent a message · ' || replace(m.kind::text, '_', ' ') end
               || case when m.channel = 'whatsapp_link' then ' · WhatsApp' else ' · copied' end, null
        from public.message_log m where m.centre_id = p_centre
      union all
      select f.paid_at, 'fee_paid', null, 'Marked a fee paid', null
        from public.fee_invoices f where f.centre_id = p_centre and f.paid_at is not null
      union all
      select a.created_at, 'made_again', null, 'Made a ' || replace(a.kind::text, '_', ' ') || ' again', null
        from public.artefacts a where a.centre_id = p_centre and a.regenerated_from is not null
    ) u order by u.at desc limit p_limit) a;
$$;

create function public.admin_centre_jobs(p_centre uuid, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(public.admin_job_row(j.id) order by j.created_at desc), '[]'::jsonb)
    from (select * from public.jobs where centre_id = p_centre order by created_at desc limit p_limit) j;
$$;

-- The record (D78, D79): the students with their consent and tracking, the batches, what the AI service made. Never a
-- parent's number, never a photo, never a message's text. Served only by the two audited functions below.
create function public.admin_record(p_centre uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'centre', jsonb_build_object('id', c.id, 'name', c.name),
    'students', (select coalesce(jsonb_agg(jsonb_build_object(
        'name', s.name, 'class_level', s.class_level, 'batch', k.name,
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
    'made', (select coalesce(jsonb_agg(jsonb_build_object('at', g.created_at, 'kind', g.kind, 'title', a.title,
               'student', s.name, 'cost_paise', coalesce(g.cost_paise, 0)) order by g.created_at desc), '[]'::jsonb)
        from (select * from public.ai_generations g0 where g0.centre_id = c.id and g0.status = 'ok' order by g0.created_at desc limit 20) g
        left join public.artefacts a on a.generation_id = g.id
        left join public.students s on s.id = g.student_id))
  from public.centres c where c.id = p_centre;
$$;

-- The audit row first, then the record, in one transaction: the record is never read without its row.
create function public.admin_open_record(p_admin uuid, p_centre uuid, p_reason text, p_ip text)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare v_reason text := btrim(coalesce(p_reason, ''));
declare v_audit uuid;
declare v_record jsonb;
begin
  if char_length(v_reason) not between 1 and 200 then raise exception 'reason_required' using errcode = 'P0001'; end if;
  v_record := public.admin_record(p_centre);
  if v_record is null then return null; end if;
  v_audit := public.admin_audit_write(p_admin, 'open_record', p_centre, '{}'::jsonb, v_reason, p_ip);
  return v_record || jsonb_build_object('audit_id', v_audit, 'opened_at', now(), 'reason', v_reason);
end $$;

-- The record again for a fresh open (an open_record row under ten minutes old): a bookmark of the page asks again.
create function public.admin_record_opened(p_audit uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select public.admin_record(a.centre_id) || jsonb_build_object('audit_id', a.id, 'opened_at', a.created_at, 'reason', a.reason)
    from public.admin_audit a
   where a.id = p_audit and a.action = 'open_record' and a.centre_id is not null
     and a.created_at > now() - interval '10 minutes';
$$;

-- Cost (D64, D67): by day, by centre, by kind and model, and the tiles; a centre narrows the day chart and the kinds.
create function public.admin_cost_by_day(p_month date, p_centre uuid default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_agg(jsonb_build_object('day', d.day, 'paise', coalesce(x.paise, 0)) order by d.day)
    from (select generate_series(p_month, (p_month + interval '1 month' - interval '1 day')::date, interval '1 day')::date as day) d
    left join (select (g.created_at at time zone 'Asia/Kolkata')::date as day, sum(g.cost_paise)::bigint as paise
                 from public.ai_generations g where p_centre is null or g.centre_id = p_centre group by 1) x on x.day = d.day;
$$;

create function public.admin_cost_by_centre(p_month date)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', r.id, 'name', r.name, 'calls', r.calls, 'paise', r.paise,
           'per_student_paise', case when r.students > 0 then round(r.paise::numeric / r.students) end) order by r.paise desc, r.name), '[]'::jsonb)
    from (select c.id, c.name, mc.calls, mc.paise,
                 (select count(*) from public.students s where s.centre_id = c.id and s.archived_at is null) as students
            from public.centres c cross join lateral public.admin_month_cost(p_month, c.id) mc
           where mc.calls > 0) r;
$$;

create function public.admin_cost_by_kind(p_month date, p_centre uuid default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('kind', x.kind, 'model', x.model, 'calls', x.calls, 'paise', x.paise) order by x.paise desc, x.kind), '[]'::jsonb)
    from (select g.kind::text as kind, coalesce(g.model, 'none') as model, count(*) as calls, coalesce(sum(g.cost_paise), 0)::bigint as paise
            from public.ai_generations g
           where (p_centre is null or g.centre_id = p_centre)
             and (g.created_at at time zone 'Asia/Kolkata')::date >= p_month
             and (g.created_at at time zone 'Asia/Kolkata')::date < (p_month + interval '1 month')::date
           group by 1, 2) x;
$$;

create function public.admin_cost_tiles(p_month date)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with active as (select count(*) as n from public.centres c cross join lateral public.admin_month_cost(p_month, c.id) mc where mc.calls > 0),
       total as (select paise from public.admin_month_cost(p_month, null))
  select jsonb_build_object(
    'month_paise', (select paise from total),
    'per_active_centre_paise', (select case when a.n > 0 then round(t.paise::numeric / a.n) else 0 end from active a, total t),
    'today_paise', (select coalesce(sum(g.cost_paise), 0) from public.ai_generations g
                     where (g.created_at at time zone 'Asia/Kolkata')::date = public.admin_today()),
    'active_centres', (select n from active));
$$;

-- The AI calls of a day: who started each (a job, the deploy's smoke, a tap), the tiles, the filters.
create function public.admin_call_row(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'id', g.id, 'created_at', g.created_at, 'centre_id', g.centre_id,
    'centre', (select c.name from public.centres c where c.id = g.centre_id),
    'kind', g.kind, 'model', g.model, 'prompt_version', g.prompt_version, 'status', g.status, 'error_reason', g.error_reason,
    'tokens_in', g.tokens_in, 'tokens_out', g.tokens_out, 'latency_ms', g.latency_ms, 'cost_paise', g.cost_paise,
    'student', g.student_id is not null,
    'started_by', case when g.job_id is not null then 'job ' || coalesce((select j.kind::text from public.jobs j where j.id = g.job_id), 'gone')
                       when g.idempotency_key like 'smoke-%' then 'deploy' else 'tap' end)
    from public.ai_generations g where g.id = p_id;
$$;

create function public.admin_calls(p_day date, p_centre uuid, p_kind text, p_status text, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with day as (
    select * from public.ai_generations g
     where (p_day is null or (g.created_at at time zone 'Asia/Kolkata')::date = p_day)
       and (p_centre is null or g.centre_id = p_centre)
       and (p_kind is null or g.kind::text = p_kind)
       and (p_status is null or g.status::text = p_status
            or (p_status = 'refused' and g.error_reason in ('refused', 'unfit'))))
  select jsonb_build_object(
    'tiles', (select jsonb_build_object(
        'calls', count(*),
        'failed', count(*) filter (where d.status = 'failed' and coalesce(d.error_reason, '') not in ('refused', 'unfit')),
        'refused', count(*) filter (where d.error_reason in ('refused', 'unfit')),
        'median_latency_ms', percentile_cont(0.5) within group (order by d.latency_ms)) from day d),
    'rows', (select coalesce(jsonb_agg(public.admin_call_row(r.id) order by r.created_at desc), '[]'::jsonb)
               from (select * from day order by created_at desc limit p_limit) r));
$$;

-- One call. A personal kind's input is held while the named student's consent is not current (D79).
create function public.admin_call(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select public.admin_call_row(g.id) || jsonb_build_object(
    'input_held', held.v,
    'input', case when held.v then null else g.input end,
    'output', g.output, 'request_id', g.request_id, 'idempotency_key', g.idempotency_key,
    'fallback_model', g.fallback_model, 'stop_reason', g.stop_reason, 'prompt_hash', g.prompt_hash,
    'finished_at', g.finished_at,
    'job', (select jsonb_build_object('id', j.id, 'kind', j.kind,
                     'subject', public.admin_job_subject(j.kind, j.input, j.idempotency_key),
                     'step', (select st.step from public.job_steps st where st.job_id = j.id and st.generation_id = g.id order by st.created_at limit 1))
              from public.jobs j where j.id = g.job_id))
    from public.ai_generations g
    cross join lateral (select g.student_id is not null and not exists (
        select 1 from public.students s where s.id = g.student_id and s.consent_at is not null) as v) held
   where g.id = p_id;
$$;

-- Jobs of a day (created, run or finished that day) with the live counts; one job with its steps.
create function public.admin_jobs(p_day date, p_state text, p_kind text, p_centre uuid, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with day as (
    select * from public.jobs j
     where (p_day is null or p_day in ((j.created_at at time zone 'Asia/Kolkata')::date, (j.run_at at time zone 'Asia/Kolkata')::date,
                                       (j.finished_at at time zone 'Asia/Kolkata')::date))
       and (p_centre is null or j.centre_id = p_centre)
       and (p_kind is null or j.kind::text = p_kind))
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'today', (select count(*) from day),
      'failed', (select count(*) from day d where d.state = 'failed'),
      'running', (select count(*) from public.jobs j where j.state = 'running' and (p_centre is null or j.centre_id = p_centre)),
      'waiting', (select count(*) from public.jobs j where j.state in ('waiting', 'queued') and (p_centre is null or j.centre_id = p_centre))),
    'rows', (select coalesce(jsonb_agg(public.admin_job_row(r.id) order by r.created_at desc), '[]'::jsonb)
               from (select * from day d where p_state is null or d.state::text = p_state order by d.created_at desc limit p_limit) r));
$$;

create function public.admin_job(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select public.admin_job_row(j.id) || jsonb_build_object(
    'error', j.error, 'input', j.input, 'idempotency_key', j.idempotency_key,
    'steps', (select coalesce(jsonb_agg(jsonb_build_object(
        'step', s.step, 'attempt', s.attempt, 'state', s.state, 'error', s.error, 'cost_paise', s.cost_paise,
        'generation_id', s.generation_id, 'created_at', s.first_at,
        'seconds', round(extract(epoch from s.last_at - s.first_at)::numeric, 1),
        'call', (select jsonb_build_object('kind', g.kind, 'model', g.model, 'status', g.status, 'error_reason', g.error_reason,
                                           'latency_ms', g.latency_ms, 'replayed', g.job_id is distinct from j.id)
                   from public.ai_generations g where g.id = s.generation_id)) order by s.first_at), '[]'::jsonb)
        -- One row a step: its last try's state, error and call; the tries' cost added.
        from (select st.step, max(st.attempt) as attempt, min(st.created_at) as first_at, max(st.updated_at) as last_at,
                     sum(st.cost_paise)::int as cost_paise,
                     (array_agg(st.state order by st.created_at desc))[1] as state,
                     (array_agg(st.error order by st.created_at desc))[1] as error,
                     (array_agg(st.generation_id order by st.created_at desc))[1] as generation_id
                from public.job_steps st where st.job_id = j.id group by st.step) s))
    from public.jobs j where j.id = p_id;
$$;

-- The API's answers over 400 by route and reason (24 h or the window asked, and 7 days); the latest.
create function public.admin_errors_by_route(p_hours int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with win as (select * from public.api_requests r where r.created_at > now() - make_interval(hours => p_hours)),
       week as (select case when r.status = 401 then 'any' else r.method || ' ' || r.route end as route, r.status, r.reason, r.created_at
                  from public.api_requests r where r.status >= 400 and r.created_at > now() - interval '7 days')
  select jsonb_build_object(
    'tiles', (select jsonb_build_object(
        'requests', count(*), 'errors', count(*) filter (where w.status >= 400),
        'rate_pct', case when count(*) > 0 then round(100.0 * count(*) filter (where w.status >= 400) / count(*), 1) else 0 end,
        'timeouts', count(*) filter (where w.status = 502 and w.reason = 'timeout'),
        'median_latency_ms', percentile_cont(0.5) within group (order by w.latency_ms)) from win w),
    'rows', (select coalesce(jsonb_agg(jsonb_build_object('route', x.route, 'status', x.status, 'reason', x.reason,
                                                          'last_24h', x.recent, 'last_7d', x.week) order by x.recent desc, x.week desc, x.route), '[]'::jsonb)
               from (select k.route, k.status, k.reason, count(*) as week,
                            count(*) filter (where k.created_at > now() - make_interval(hours => p_hours)) as recent
                       from week k group by 1, 2, 3) x));
$$;

create function public.admin_errors_recent(p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('created_at', r.created_at, 'route', r.method || ' ' || r.route, 'status', r.status,
           'reason', r.reason, 'request_id', r.request_id,
           'centre', (select c.name from public.centres c where c.id = r.centre_id)) order by r.created_at desc), '[]'::jsonb)
    from (select * from public.api_requests where status >= 400 order by created_at desc limit p_limit) r;
$$;

create function public.admin_alerts(p_open_first boolean)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'open', (select count(*) from public.alerts where acknowledged_at is null),
      'acknowledged_week', (select count(*) from public.alerts where acknowledged_at > now() - interval '7 days'),
      'last_raised', (select max(raised_at) from public.alerts)),
    'rows', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', a.id, 'kind', a.kind, 'message', a.message, 'centre_id', a.centre_id,
        'centre', (select c.name from public.centres c where c.id = a.centre_id),
        'value', a.value, 'threshold', a.threshold, 'raised_at', a.raised_at, 'acknowledged_at', a.acknowledged_at,
        'acknowledged_by_email', (select u.email from public.admin_users u where u.user_id = a.acknowledged_by))
        order by case when p_open_first and a.acknowledged_at is null then 0 else 1 end, a.raised_at desc), '[]'::jsonb)
        from (select * from public.alerts order by raised_at desc limit 200) a));
$$;

-- The audit, newest first: the admin's email (or, for a refusal, the email that was refused), the job's subject.
create function public.admin_audit(p_days int, p_admin uuid, p_action text, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
      'id', a.id, 'created_at', a.created_at, 'admin_user_id', a.admin_user_id,
      'admin_email', coalesce((select u.email from public.admin_users u where u.user_id = a.admin_user_id), a.target ->> 'email'),
      'action', a.action, 'centre_id', a.centre_id,
      'centre', (select c.name from public.centres c where c.id = a.centre_id),
      'target', a.target, 'reason', a.reason, 'ip', a.ip,
      'subject', (select public.admin_job_subject(j.kind, j.input, j.idempotency_key) from public.jobs j
                   where a.target ? 'job' and j.id = (a.target ->> 'job')::uuid)) order by a.created_at desc), '[]'::jsonb)
    from (select * from public.admin_audit x
           where x.created_at > now() - make_interval(days => p_days)
             and (p_admin is null or x.admin_user_id = p_admin)
             and (p_action is null or x.action = p_action)
           order by x.created_at desc limit p_limit) a;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'admin_job_subject(public.job_kind, jsonb, text)', 'admin_job_row(uuid)', 'admin_month_cost(date, uuid)',
    'admin_today()', 'admin_centres(date)', 'admin_kind_group(text)', 'admin_centre(uuid, date)', 'admin_activity(uuid, int)',
    'admin_centre_jobs(uuid, int)', 'admin_record(uuid)', 'admin_open_record(uuid, uuid, text, text)',
    'admin_record_opened(uuid)', 'admin_cost_by_day(date, uuid)', 'admin_cost_by_centre(date)', 'admin_cost_by_kind(date, uuid)',
    'admin_cost_tiles(date)', 'admin_call_row(uuid)', 'admin_calls(date, uuid, text, text, int)',
    'admin_call(uuid)', 'admin_jobs(date, text, text, uuid, int)', 'admin_job(uuid)', 'admin_errors_by_route(int)',
    'admin_errors_recent(int)', 'admin_alerts(boolean)', 'admin_audit(int, uuid, text, int)']
  loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;
