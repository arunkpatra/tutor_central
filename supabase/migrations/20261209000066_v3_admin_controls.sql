-- V3, Phase 22 (D113): the portal's controls. Each write is a named function of the platform's (service_role alone)
-- that writes its own audit row in the same transaction (0046's shape):
-- 1. `admin_set_model`: a new `ai_models` row for a kind and step (the switch is the draft row's `enabled`, D100).
-- 2. `alert_lines` (append-only, seeded with api/src/alerts/lines.ts's constants) and `admin_set_alert_lines`; the alerts
--    job reads `alert_lines_current()` each run, and `alert_facts`' stuck jobs follow its minutes.
-- 3. `admin_set_allowance`: the centre's two allowance columns, the old values in the audit, a reason required.
-- 4. The reads: `admin_models`, `admin_model`; `admin_alerts` gains `lines`.
-- 5. `centres.internal` (the Smoke centre, set by the session): left out of the active counts.

-- 2. The alert lines: the newest row is current; no member reads it; the platform only appends.
create table public.alert_lines (
  id uuid primary key default gen_random_uuid(),
  cost_day_paise integer not null check (cost_day_paise >= 0),
  error_rate_pct numeric not null check (error_rate_pct >= 0 and error_rate_pct <= 100),
  error_rate_min_requests integer not null check (error_rate_min_requests >= 0),
  stuck_minutes integer not null check (stuck_minutes >= 0),
  since timestamptz not null default now(),
  set_by text not null default 'seed' check (char_length(set_by) between 1 and 200),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index alert_lines_since_idx on public.alert_lines (since desc);
create trigger alert_lines_updated before update on public.alert_lines for each row execute function public.set_updated_at();
alter table public.alert_lines enable row level security;
create policy alert_lines_platform_only on public.alert_lines for select to authenticated using (false);
revoke insert, update, delete, truncate on public.alert_lines from anon, authenticated;
revoke update, delete, truncate on public.alert_lines from service_role;

insert into public.alert_lines (cost_day_paise, error_rate_pct, error_rate_min_requests, stuck_minutes, set_by)
values (6000, 5, 20, 10, 'seed 0066');

create function public.alert_lines_current()
returns table (cost_day_paise integer, error_rate_pct numeric, error_rate_min_requests integer, stuck_minutes integer,
               since timestamptz, set_by text)
language sql stable security invoker set search_path = '' as $$
  select l.cost_day_paise, l.error_rate_pct, l.error_rate_min_requests, l.stuck_minutes, l.since, l.set_by
    from public.alert_lines l order by l.since desc limit 1
$$;

-- 5. The Smoke centre (the evals' and the deploy's calls) is the platform's own, not a tutor's.
alter table public.centres add column internal boolean not null default false;

-- The admin's email for a row's `set_by` (admin_users holds it; auth.users is not the platform's to read in SQL).
create function public.admin_email(p_admin uuid)
returns text language sql stable security invoker set search_path = '' as $$
  select coalesce((select u.email from public.admin_users u where u.user_id = p_admin), p_admin::text);
$$;

-- 1. A model change: a new row from now, the history kept. A kind the table has never held is refused (a typo would
-- otherwise make a row no call reads); the step and effort by the table's checks.
create function public.admin_set_model(p_admin uuid, p_kind text, p_step text, p_model text, p_effort text,
                                       p_fallback text, p_enabled boolean, p_note text, p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_id uuid;
  v_note text := nullif(btrim(coalesce(p_note, '')), '');
  v_fallback text := nullif(btrim(coalesce(p_fallback, '')), '');
begin
  if not exists (select 1 from public.ai_models m where m.kind = p_kind) then
    raise exception 'unknown_kind' using errcode = 'P0001';
  end if;
  insert into public.ai_models (kind, step, model, effort, fallback_model, enabled, set_by, note)
  values (p_kind, p_step, p_model, p_effort, v_fallback, p_enabled, public.admin_email(p_admin), v_note)
  returning id into v_id;
  perform public.admin_audit_write(p_admin, 'set_model', null,
    jsonb_build_object('kind', p_kind, 'step', p_step, 'model', p_model, 'effort', p_effort, 'fallback', v_fallback,
                       'enabled', p_enabled), v_note, p_ip);
  return v_id;
end $$;

create function public.admin_set_alert_lines(p_admin uuid, p_cost_day_paise integer, p_error_rate_pct numeric,
                                             p_error_rate_min_requests integer, p_stuck_minutes integer, p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  insert into public.alert_lines (cost_day_paise, error_rate_pct, error_rate_min_requests, stuck_minutes, set_by)
  values (p_cost_day_paise, p_error_rate_pct, p_error_rate_min_requests, p_stuck_minutes, public.admin_email(p_admin))
  returning id into v_id;
  perform public.admin_audit_write(p_admin, 'set_alert_lines', null,
    jsonb_build_object('cost_day_paise', p_cost_day_paise, 'error_rate_pct', p_error_rate_pct,
                       'error_rate_min_requests', p_error_rate_min_requests, 'stuck_minutes', p_stuck_minutes), null, p_ip);
  return v_id;
end $$;

-- 3. The allowance (0029: members cannot change it), with the reason asked as the record's open asks it. False for a
-- centre that is gone.
create function public.admin_set_allowance(p_admin uuid, p_centre uuid, p_calls integer, p_paise integer, p_reason text,
                                           p_ip text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare
  v_reason text := btrim(coalesce(p_reason, ''));
  v_before record;
begin
  if char_length(v_reason) not between 1 and 200 then raise exception 'reason_required' using errcode = 'P0001'; end if;
  select c.ai_allowance as calls, c.ai_allowance_paise as paise into v_before
    from public.centres c where c.id = p_centre for update;
  if not found then return false; end if;
  update public.centres set ai_allowance = p_calls, ai_allowance_paise = p_paise where id = p_centre;
  perform public.admin_audit_write(p_admin, 'set_allowance', p_centre,
    jsonb_build_object('calls', p_calls, 'paise', p_paise,
                       'before', jsonb_build_object('calls', v_before.calls, 'paise', v_before.paise)), v_reason, p_ip);
  return true;
end $$;

-- 4. The Models page: every kind by its three current steps, the kind's newest row (when, by whom, its note), the tiles.
create function public.admin_models()
returns jsonb language sql stable security invoker set search_path = '' as $$
  with cur as (
         select distinct on (m.kind, m.step) m.kind, m.step,
                jsonb_build_object('model', m.model, 'effort', m.effort, 'fallback_model', m.fallback_model,
                                   'enabled', m.enabled, 'since', m.since, 'set_by', m.set_by, 'note', m.note) as row,
                m.enabled
           from public.ai_models m order by m.kind, m.step, m.since desc),
       newest as (
         select distinct on (m.kind) m.kind, m.since, m.set_by, m.note
           from public.ai_models m order by m.kind, m.since desc)
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'kinds', (select count(*) from newest),
      'off', (select count(*) from cur c where c.step = 'draft' and not c.enabled),
      'changes_month', (select count(*) from public.ai_models m
                         where m.set_by <> 'seed'
                           and (m.since at time zone 'Asia/Kolkata')::date >= date_trunc('month', public.admin_today())::date),
      'last_change', (select max(m.since) from public.ai_models m where m.set_by <> 'seed')),
    'rows', coalesce((select jsonb_agg(jsonb_build_object(
        'kind', n.kind,
        'draft', (select c.row from cur c where c.kind = n.kind and c.step = 'draft'),
        'check', (select c.row from cur c where c.kind = n.kind and c.step = 'check'),
        'repair', (select c.row from cur c where c.kind = n.kind and c.step = 'repair'),
        'changed_at', n.since, 'changed_by', n.set_by, 'note', n.note) order by n.kind) from newest n), '[]'::jsonb));
$$;

-- One kind: its three current steps and every row it has had, newest first. Null for a kind the table never held.
create function public.admin_model(p_kind text)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select case when not exists (select 1 from public.ai_models m where m.kind = p_kind) then null else jsonb_build_object(
    'kind', p_kind,
    'current', (select coalesce(jsonb_agg(to_jsonb(c) order by array_position(array['draft', 'check', 'repair'], c.step)), '[]'::jsonb)
                  from (select distinct on (m.step) m.step, m.model, m.effort, m.fallback_model, m.enabled, m.since, m.set_by, m.note
                          from public.ai_models m where m.kind = p_kind order by m.step, m.since desc) c),
    'history', (select coalesce(jsonb_agg(jsonb_build_object(
                    'id', m.id, 'since', m.since, 'step', m.step, 'model', m.model, 'effort', m.effort,
                    'fallback_model', m.fallback_model, 'enabled', m.enabled, 'set_by', m.set_by, 'note', m.note)
                  order by m.since desc, array_position(array['draft', 'check', 'repair'], m.step)), '[]'::jsonb)
                  from public.ai_models m where m.kind = p_kind)) end;
$$;

-- The alerts page gains the lines (its form). 0050's body otherwise.
create or replace function public.admin_alerts(p_open_first boolean)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'tiles', jsonb_build_object(
      'open', (select count(*) from public.alerts where acknowledged_at is null),
      'acknowledged_week', (select count(*) from public.alerts where acknowledged_at > now() - interval '7 days'),
      'last_raised', (select max(raised_at) from public.alerts)),
    'lines', (select to_jsonb(l) from public.alert_lines_current() l),
    'rows', (select coalesce(jsonb_agg(jsonb_build_object(
        'id', a.id, 'kind', a.kind, 'message', a.message, 'centre_id', a.centre_id,
        'centre', (select c.name from public.centres c where c.id = a.centre_id),
        'value', a.value, 'threshold', a.threshold, 'raised_at', a.raised_at, 'acknowledged_at', a.acknowledged_at,
        'acknowledged_by_email', (select u.email from public.admin_users u where u.user_id = a.acknowledged_by))
        order by case when p_open_first and a.acknowledged_at is null then 0 else 1 end, a.raised_at desc), '[]'::jsonb)
        -- Open ones first before the limit, so an old open alert is never cut off by newer acknowledged ones.
        from (select * from public.alerts order by (acknowledged_at is null) desc, raised_at desc limit 200) a));
$$;

-- The stuck line's minutes come from the lines (0049's body otherwise): a line set under ten minutes must see the jobs
-- stuck that long.
create or replace function public.alert_facts(p_now timestamptz)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'failed_jobs', (
      select coalesce(jsonb_agg(jsonb_build_object('id', j.id, 'kind', j.kind, 'centre_id', j.centre_id, 'input', j.input,
                                                   'finished_at', j.finished_at) order by j.finished_at), '[]'::jsonb)
        from public.jobs j
       where j.state = 'failed' and j.finished_at > p_now - interval '30 minutes' and j.finished_at <= p_now),
    'cost_today', (
      select coalesce(jsonb_agg(jsonb_build_object('centre_id', c.centre_id, 'paise', c.paise) order by c.paise desc), '[]'::jsonb)
        from (select g.centre_id, sum(g.cost_paise)::bigint as paise
                from public.ai_generations g
               where (g.created_at at time zone 'Asia/Kolkata')::date = (p_now at time zone 'Asia/Kolkata')::date
                 and g.cost_paise > 0
               group by g.centre_id) c),
    'requests_hour', (
      select jsonb_build_object('total', count(*), 'errors', count(*) filter (where r.status >= 400))
        from public.api_requests r
       where r.created_at > p_now - interval '1 hour' and r.created_at <= p_now
         -- The worker's ticks (each minute, from pg_cron) are not the API's answers to tutors.
         and r.route not like '/jobs/%'),
    -- Stuck is no progress: a job keeps its first started_at across waits and retries; one whose last step (or start) is
    -- older than the line's minutes is.
    'stuck_jobs', (
      select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'kind', s.kind, 'centre_id', s.centre_id, 'since', s.since)
                                order by s.since), '[]'::jsonb)
        from (select j.id, j.kind, j.centre_id,
                     greatest(j.started_at, (select max(st.updated_at) from public.job_steps st where st.job_id = j.id)) as since
                from public.jobs j where j.state = 'running') s
       where s.since < p_now - make_interval(mins => coalesce((select l.stuck_minutes from public.alert_lines_current() l), 10))));
$$;

-- 5. The centres' active count leaves the internal centre out (0047's body otherwise).
create or replace function public.admin_centres(p_month date)
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
                       join public.centres c on c.id = e.centre_id and not c.internal
                       where e.kind = 'app_opened' and e.at > now() - interval '7 days'),
      'cost_paise', (select mc.paise from public.admin_month_cost(p_month, null) mc),
      'failed_today', (select count(*) from public.jobs j where j.state = 'failed'
                        and (j.finished_at at time zone 'Asia/Kolkata')::date = public.admin_today())),
    'rows', coalesce((select jsonb_agg(to_jsonb(r) order by r.cost_paise desc, r.name) from rows r), '[]'::jsonb));
$$;

-- The month's active centres leave the internal centre out, and so does the cost per active centre (the evals' calls
-- are the platform's, not a tutor's); the month's total keeps every call (0061's body otherwise).
create or replace function public.admin_cost_by_month(p_centre uuid default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with months as (
         select (date_trunc('month', public.admin_today()) - make_interval(months => n))::date as month
           from generate_series(5, 0, -1) n),
       calls as (
         select date_trunc('month', (g.created_at at time zone 'Asia/Kolkata'))::date as month, g.centre_id,
                (select c.internal from public.centres c where c.id = g.centre_id) as internal,
                count(*) as calls, coalesce(sum(g.cost_paise), 0)::bigint as paise,
                coalesce(sum(g.cost_paise) filter (where g.batched), 0)::bigint as batched_paise
           from public.ai_generations g
          where (p_centre is null or g.centre_id = p_centre)
            and (g.created_at at time zone 'Asia/Kolkata')::date >= (select min(month) from months)
          group by 1, 2)
  select jsonb_agg(jsonb_build_object(
           'month', r.month, 'calls', r.calls, 'paise', r.paise, 'batched_paise', r.batched_paise,
           'active_centres', r.active_centres,
           'per_active_centre_paise', case when r.active_centres > 0 then round(r.tutor_paise::numeric / r.active_centres) else 0 end)
         order by r.month)
    from (select m.month, coalesce(sum(c.calls), 0)::bigint as calls, coalesce(sum(c.paise), 0)::bigint as paise,
                 coalesce(sum(c.batched_paise), 0)::bigint as batched_paise,
                 count(c.centre_id) filter (where not coalesce(c.internal, false)) as active_centres,
                 coalesce(sum(c.paise) filter (where not coalesce(c.internal, false)), 0)::bigint as tutor_paise
            from months m left join calls c on c.month = m.month
           group by m.month) r;
$$;

do $$
declare f text;
begin
  foreach f in array array[
    'alert_lines_current()', 'admin_email(uuid)',
    'admin_set_model(uuid, text, text, text, text, text, boolean, text, text)',
    'admin_set_alert_lines(uuid, integer, numeric, integer, integer, text)',
    'admin_set_allowance(uuid, uuid, integer, integer, text, text)', 'admin_models()', 'admin_model(text)']
  loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;
