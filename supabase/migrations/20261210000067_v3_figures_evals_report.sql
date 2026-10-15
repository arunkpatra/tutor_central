-- V3, Phase 22 (D114 to D116): the product figures, the golden sets' runs, the syllabus data, the weekly report.
-- 1. `admin_figures(weeks)`: each week (Monday to Sunday in India, the current one so far first) from the tables already
--    kept (D82: no new event); `admin_reasons_week(monday)`: the week's made-again reasons and edits. An internal centre
--    (0066) is left out of every figure.
-- 2. `admin_eval_runs()`: per kind the newest done `eval_run` job's figures, the newest job's failures, a run in flight;
--    `admin_run_evals(admin, kinds)`: a run a person starts from the portal (D112, D116), audited.
-- 3. `admin_syllabi()`, `admin_syllabus(id)`: the syllabus data, read only.
-- 4. The job kind `weekly_report` (no centre), queued Monday 08:00 IST by `schedule_weekly_report()` and now by
--    `admin_send_report(admin)`; `admin_report_last()` for the page's card.
-- Every function is the platform's alone, as every admin read (0047).

alter type public.job_kind add value 'weekly_report';
alter table public.jobs drop constraint jobs_check;
alter table public.jobs add constraint jobs_check
  check (centre_id is not null or kind::text in ('sweep', 'eval_run', 'alerts', 'weekly_report'));

-- The Monday of the week a day is in.
create function public.admin_monday(p_day date)
returns date language sql immutable security invoker set search_path = '' as $$
  select (p_day - ((extract(isodow from p_day)::int - 1)))::date;
$$;

-- A centre that counts: a tutor's, not the platform's own (0066).
create function public.admin_counted(p_centre uuid)
returns boolean language sql stable security invoker set search_path = '' as $$
  select coalesce((select not c.internal from public.centres c where c.id = p_centre), false);
$$;

-- The parents' messages (the weekly note, what a young student can now do, the test tomorrow, not on track, V1's
-- progress note); never the consent ask, a fee reminder, a receipt, an absence or homework.
create function public.admin_note_kinds()
returns public.message_kind[] language sql immutable security invoker set search_path = '' as $$
  select array['progress', 'note', 'can_do', 'test_tomorrow', 'not_on_track']::public.message_kind[];
$$;

create function public.admin_figures(p_weeks int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with weeks as (
         select (public.admin_monday(public.admin_today()) - 7 * n)::date as monday, n = 0 as so_far, n
           from generate_series(0, greatest(least(p_weeks, 52), 1) - 1) n),
       ist as (select w.monday, w.so_far, w.n, (w.monday::timestamp at time zone 'Asia/Kolkata') as from_at,
                      ((w.monday + 7)::timestamp at time zone 'Asia/Kolkata') as to_at
                 from weeks w),
       figures as (
         select w.monday, w.so_far, w.n,
           (select count(distinct e.user_id) from public.events e
             where e.kind = 'app_opened' and e.at >= w.from_at and e.at < w.to_at and public.admin_counted(e.centre_id))::int
             as tutors_active,
           (select count(*) from public.attendance_sessions s
             where s.closed_at >= w.from_at and s.closed_at < w.to_at and public.admin_counted(s.centre_id))::int as closes,
           (select count(*) from public.plans p
             where p.made_at >= w.from_at and p.made_at < w.to_at and public.admin_counted(p.centre_id))::int as plans_made,
           (select count(*) from public.plans p
             where p.made_at >= w.from_at and p.made_at < w.to_at and p.session_id is not null
               and public.admin_counted(p.centre_id))::int as plans_followed,
           (select count(*) from public.message_log m
             where m.kind = any (public.admin_note_kinds()) and m.opened_at >= w.from_at and m.opened_at < w.to_at
               and public.admin_counted(m.centre_id))::int as notes_sent,
           (select count(*) from public.artefacts a
             where a.source = 'made' and a.created_at >= w.from_at and a.created_at < w.to_at
               and public.admin_counted(a.centre_id))::int as made,
           (select count(*) from public.generation_feedback f
             where f.kind = 'again' and f.created_at >= w.from_at and f.created_at < w.to_at
               and public.admin_counted(f.centre_id))::int as again,
           (select count(*) from public.artefacts a
             where a.made_from = 'make' and a.created_at >= w.from_at and a.created_at < w.to_at
               and public.admin_counted(a.centre_id))::int as make,
           (select count(*) from public.consent_events c
             where c.kind = 'given' and c.at >= w.from_at and c.at < w.to_at and public.admin_counted(c.centre_id))::int
             as consent_given,
           (select coalesce(sum(g.cost_paise), 0) from public.ai_generations g
             where g.created_at >= w.from_at and g.created_at < w.to_at and public.admin_counted(g.centre_id))::bigint
             as cost_paise
           from ist w)
  select coalesce(jsonb_agg(jsonb_build_object(
           'week_monday', f.monday, 'so_far', f.so_far, 'tutors_active', f.tutors_active, 'closes', f.closes,
           'plans_made', f.plans_made, 'plans_followed', f.plans_followed, 'notes_sent', f.notes_sent, 'made', f.made,
           'again', f.again, 'make', f.make, 'consent_given', f.consent_given, 'cost_paise', f.cost_paise,
           'per_active_tutor_paise', case when f.tutors_active > 0 then round(f.cost_paise::numeric / f.tutors_active) else 0 end)
         order by f.n), '[]'::jsonb)
    from figures f;
$$;

-- The menus' reasons (the app's RegenerateReason, BriefReason, MockReason, NoteReason labels, as the prompt reads them);
-- any other reason is the tutor's own words, counted as "typed" and never shown here.
create function public.admin_reason_presets()
returns text[] language sql immutable security invoker set search_path = '' as $$
  select array['easier', 'harder', 'shorter', 'more sums', 'different numbers', 'simpler words', 'a different example',
               'more on the mistakes', 'different questions', 'closer to the school''s papers', 'warmer', 'plainer words',
               'less about marks'];
$$;

create function public.admin_reasons_week(p_monday date)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with win as (select (p_monday::timestamp at time zone 'Asia/Kolkata') as from_at,
                      ((p_monday + 7)::timestamp at time zone 'Asia/Kolkata') as to_at),
       again as (
         select case when lower(btrim(f.reason)) = any (public.admin_reason_presets())
                     then lower(btrim(f.reason)) else 'typed' end as reason
           from public.generation_feedback f, win
          where f.kind = 'again' and f.created_at >= win.from_at and f.created_at < win.to_at
            and public.admin_counted(f.centre_id))
  select jsonb_build_object(
    'again', (select coalesce(jsonb_agg(jsonb_build_object('reason', x.reason, 'count', x.n) order by x.n desc, x.reason), '[]'::jsonb)
                from (select a.reason, count(*)::int as n from again a group by a.reason) x),
    'edits', (select count(*) from public.generation_feedback f, win
               where f.kind = 'edit' and f.created_at >= win.from_at and f.created_at < win.to_at
                 and public.admin_counted(f.centre_id))::int,
    'made', (select count(*) from public.artefacts a, win
              where a.source = 'made' and a.created_at >= win.from_at and a.created_at < win.to_at
                and public.admin_counted(a.centre_id))::int,
    'notes', (select count(*) from public.message_log m, win
               where m.kind = any (public.admin_note_kinds()) and m.opened_at >= win.from_at and m.opened_at < win.to_at
                 and public.admin_counted(m.centre_id))::int);
$$;

-- 2. The golden sets: each kind's newest done run (a job holds the kinds it ran), the newest run's failures, and a run
-- queued or under way (the portal's card waits for it).
create function public.admin_eval_runs()
returns jsonb language sql stable security invoker set search_path = '' as $$
  with done as (
         select j.id, j.finished_at, j.result, j.idempotency_key from public.jobs j
          where j.kind = 'eval_run' and j.state = 'done' and jsonb_typeof(j.result -> 'kinds') = 'object'),
       per_kind as (
         select distinct on (k.key) k.key as kind, d.id as job_id, d.finished_at as run_at, k.value as v,
                d.idempotency_key like '%:admin:%' as by_admin
           from done d cross join lateral jsonb_each(d.result -> 'kinds') k
          order by k.key, d.finished_at desc),
       newest as (select d.* from done d order by d.finished_at desc limit 1)
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'kinds', (select count(*) from per_kind),
      'passed', (select count(*) from per_kind p where (p.v ->> 'gate')::boolean),
      'below', (select count(*) from per_kind p where not (p.v ->> 'gate')::boolean),
      'last_run_at', (select n.finished_at from newest n),
      'last_run_paise', coalesce((select (n.result ->> 'cost_paise')::bigint from newest n), 0)),
    'rows', (select coalesce(jsonb_agg(jsonb_build_object(
        'kind', p.kind, 'run_at', p.run_at, 'job_id', p.job_id, 'by_admin', p.by_admin,
        'cases', (p.v ->> 'cases')::int, 'schema', (p.v ->> 'schema')::int, 'verify', (p.v ->> 'verify')::int,
        'check_pass', (p.v ->> 'check_pass')::int, 'grade_pass', (p.v ->> 'grade_pass')::int,
        'grade_rate', (p.v ->> 'grade_rate')::numeric, 'gate', (p.v ->> 'gate')::boolean,
        'cost_paise', coalesce((p.v ->> 'cost_paise')::bigint, 0)) order by p.kind), '[]'::jsonb) from per_kind p),
    -- With no run yet the subquery answers no row: the lists stay lists (hand run 6).
    'failures', coalesce((select n.result -> 'failures' from newest n), '[]'::jsonb),
    'failures_job', (select n.id from newest n),
    'queued', (select j.id from public.jobs j where j.kind = 'eval_run' and j.state in ('queued', 'running', 'waiting')
                order by j.created_at desc limit 1));
$$;

-- A run a person starts (D112, D116): one eval_run job with the kinds chosen (none: every kind), queued now. Its day
-- names the minute, so its calls never replay another run's of the same day. Null while a run is queued or under way.
create function public.admin_run_evals(p_admin uuid, p_kinds text[], p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_at timestamp := now() at time zone 'Asia/Kolkata';
  v_day text := to_char(v_at, 'YYYY-MM-DD-HH24MI');
  v_kinds text[] := coalesce(p_kinds, array[]::text[]);
  v_id uuid;
begin
  if exists (select 1 from unnest(v_kinds) k where k !~ '^[a-z_]{1,40}$') then
    raise exception 'unknown_kind' using errcode = 'P0001';
  end if;
  if exists (select 1 from public.jobs j where j.kind = 'eval_run' and j.state in ('queued', 'running', 'waiting')) then
    return null;
  end if;
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  values (null, 'eval_run', 'evals:' || to_char(v_at, 'YYYY-MM-DD') || ':admin:' || to_char(v_at, 'HH24MI'),
          case when cardinality(v_kinds) = 0 then jsonb_build_object('day', v_day)
               else jsonb_build_object('day', v_day, 'kinds', to_jsonb(v_kinds)) end,
          now())
  on conflict do nothing
  returning id into v_id;
  perform set_config('tc.jobs', 'off', true);
  if v_id is null then return null; end if;
  perform public.admin_audit_write(p_admin, 'run_evals', null,
    jsonb_build_object('job', v_id, 'kind', 'eval_run', 'kinds', to_jsonb(v_kinds)), null, p_ip);
  return v_id;
end $$;

-- 3. The syllabus data, read only.
create function public.admin_syllabi()
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'syllabi', (select count(*) from public.syllabi),
      'boards', (select coalesce(jsonb_agg(distinct s.board), '[]'::jsonb) from public.syllabi s),
      'classes', (select coalesce(jsonb_agg(distinct s.class_level), '[]'::jsonb) from public.syllabi s),
      'chapters', (select coalesce(sum(jsonb_array_length(s.chapters)), 0) from public.syllabi s)),
    'rows', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id, 'board', s.board, 'class_level', s.class_level, 'subject', s.subject, 'edition', s.edition,
        'chapters', jsonb_array_length(s.chapters),
        'skills', (select coalesce(sum(jsonb_array_length(coalesce(c -> 'skills', '[]'::jsonb))), 0)
                     from jsonb_array_elements(s.chapters) c),
        'blueprint', s.blueprint is not null, 'updated_at', s.updated_at)
        order by s.board, s.class_level::int, s.subject), '[]'::jsonb) from public.syllabi s));
$$;

-- One syllabus with its chapters; a chapter's marks when the blueprint names it (`blueprint.chapters`), else null.
create function public.admin_syllabus(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'id', s.id, 'board', s.board, 'class_level', s.class_level, 'subject', s.subject, 'edition', s.edition,
    'blueprint', case when s.blueprint is null then null
                      else jsonb_build_object('marks', s.blueprint -> 'marks',
                                              'sections', jsonb_array_length(coalesce(s.blueprint -> 'sections', '[]'::jsonb)),
                                              'minutes', s.blueprint -> 'durationMinutes') end,
    'chapters', (select coalesce(jsonb_agg(jsonb_build_object(
        'no', coalesce((c ->> 'position')::int, o::int), 'name', c ->> 'name',
        'skills', coalesce(c -> 'skills', '[]'::jsonb),
        'marks', (s.blueprint -> 'chapters' ->> (c ->> 'name'))::numeric) order by o), '[]'::jsonb)
        from jsonb_array_elements(s.chapters) with ordinality as x(c, o)))
    from public.syllabi s where s.id = p_id;
$$;

-- 4. The weekly report (D115): the week before p_now's in India, once (its key), at p_now.
create function public.schedule_weekly_report(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_monday date := public.admin_monday((p_now at time zone 'Asia/Kolkata')::date) - 7;
  v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  values (null, 'weekly_report', 'report:' || v_monday, jsonb_build_object('week_monday', v_monday), p_now)
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;
select cron.schedule('schedule_weekly_report', '30 2 * * 1', 'select public.schedule_weekly_report()');

-- Send now (the figures page): this week so far, keyed by the minute; audited.
create function public.admin_send_report(p_admin uuid, p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_at timestamp := now() at time zone 'Asia/Kolkata';
  v_monday date := public.admin_monday(v_at::date);
  v_id uuid;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  values (null, 'weekly_report', 'report:now:' || to_char(v_at, 'YYYY-MM-DD-HH24MI'),
          jsonb_build_object('week_monday', v_monday, 'so_far', true), now())
  on conflict do nothing
  returning id into v_id;
  perform set_config('tc.jobs', 'off', true);
  if v_id is null then
    select j.id into v_id from public.jobs j
     where j.centre_id is null and j.idempotency_key = 'report:now:' || to_char(v_at, 'YYYY-MM-DD-HH24MI');
    return v_id;
  end if;
  perform public.admin_audit_write(p_admin, 'send_report', null,
    jsonb_build_object('job', v_id, 'kind', 'weekly_report', 'week', v_monday), null, p_ip);
  return v_id;
end $$;

-- The report card: the newest weekly_report job and what it recorded.
create function public.admin_report_last()
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object('id', j.id, 'state', j.state, 'finished_at', j.finished_at, 'created_at', j.created_at,
                            'week_monday', j.input ->> 'week_monday', 'so_far', coalesce((j.input ->> 'so_far')::boolean, false),
                            'sent', coalesce((j.result ->> 'sent')::boolean, false))
    from public.jobs j where j.kind::text = 'weekly_report' order by j.created_at desc limit 1;  -- text: added in this transaction
$$;

-- The jobs page names the new kind's subject and the eval run a person started (0057's body otherwise).
create or replace function public.admin_job_subject(p_kind public.job_kind, p_input jsonb, p_key text)
returns text language sql stable security invoker set search_path = '' as $$
  select case
    when p_kind in ('plan', 'note_day') and p_input ? 'class_id' then
      coalesce((select c.name from public.classes c where c.id = (p_input ->> 'class_id')::uuid), 'a batch')
        || coalesce(' · ' || to_char((p_input ->> 'date')::date, 'FMDD Mon'), '')
    when p_kind in ('note_day', 'export') then 'a student'
    when p_kind = 'pdf' then
      coalesce((select a.title from public.artefacts a where a.id = (p_input ->> 'artefact_id')::uuid),
               (select g.kind || ' · a result' from public.ai_generations g where g.id = (p_input ->> 'generation_id')::uuid), 'a file')
    when p_kind::text = 'exam_prep' then
      coalesce((select nullif(i.title, '') from public.school_items i where i.id = (p_input ->> 'item_id')::uuid), 'an exam')
    when p_kind = 'reminder_sweep' then case when p_key ~ 'T[0-9]{2}$' then 'hourly' else 'after a change' end
    when p_kind in ('sweep', 'alerts') then 'every 10 minutes'
    when p_kind = 'eval_run' then case when p_key like '%:admin:%' then 'golden sets, started here' else 'nightly evals' end
    when p_kind::text = 'weekly_report' then  -- text: the new value cannot be used in the transaction that adds it
      'the week of ' || to_char((p_input ->> 'week_monday')::date, 'FMDD Mon')
        || case when (p_input ->> 'so_far')::boolean then ', so far' else '' end
    else null
  end;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'admin_monday(date)', 'admin_counted(uuid)', 'admin_note_kinds()', 'admin_figures(int)', 'admin_reason_presets()',
    'admin_reasons_week(date)', 'admin_eval_runs()', 'admin_run_evals(uuid, text[], text)', 'admin_syllabi()',
    'admin_syllabus(uuid)', 'schedule_weekly_report(timestamptz)', 'admin_send_report(uuid, text)', 'admin_report_last()']
  loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;
