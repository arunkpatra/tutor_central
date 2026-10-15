-- V3, Phase 22 (D117, D118, the push retry): what the round's privacy words and the second batch need.
-- 1. Retention (D79, D117): `reduce_old_inputs(before, limit)` replaces what was sent about a student with a reference
--    after 90 days (the sweep calls it); the output, the cost and every other column stay. `admin_call` says so, and
--    shows a reason the tutor typed as "typed" (it may name a student).
-- 2. The split per batch (D118, R-api-4): `school_items.preparations`, batch id to its days, beside `preparation` (the
--    first batch's, read by build 31).
-- 3. A push Apple refused for a while (a 429, a 5xx, no answer) is set due again a minute later, three times at most.
-- 4. The cost line leaves an internal centre out (the review: a golden sets' run would raise cost_day on the Smoke centre).

-- 1. A row about a student: one with its id, or a V1 input that names its student with no id (as admin_call's Held).
create function public.reduce_old_inputs(p_before timestamptz, p_limit int)
returns int language plpgsql security invoker set search_path = '' as $$
declare v_count int;
begin
  with old as (
    select g.id from public.ai_generations g
     where g.status <> 'pending' and g.created_at < p_before and not (g.input ? 'reduced_at')
       and (g.student_id is not null
            or coalesce(g.input ->> 'studentName', g.input ->> 'parentName', g.input ->> 'observations') is not null)
     order by g.created_at
     limit greatest(p_limit, 0)
     for update skip locked)
  update public.ai_generations g
     set input = jsonb_build_object('reduced_at', now(), 'kind', g.kind::text, 'student_id', g.student_id)
    from old where g.id = old.id;
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- The call's page: a reduced input is never shown and says so (0061's body otherwise).
create or replace function public.admin_call(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select public.admin_call_row(g.id) || jsonb_build_object(
    'input_held', held.v,
    'input_reduced', g.input ? 'reduced_at',
    'input', case when held.v or g.input ? 'reduced_at' then null else g.input end,
    'output', g.output, 'request_id', g.request_id, 'idempotency_key', g.idempotency_key,
    'fallback_model', g.fallback_model, 'stop_reason', g.stop_reason, 'prompt_hash', g.prompt_hash,
    'finished_at', g.finished_at,
    'job', (select jsonb_build_object('id', j.id, 'kind', j.kind,
                     'subject', public.admin_job_subject(j.kind, j.input, j.idempotency_key),
                     'step', (select st.step from public.job_steps st where st.job_id = j.id and st.generation_id = g.id order by st.created_at limit 1))
              from public.jobs j where j.id = g.job_id),
    -- The tutor's word on the call (D107): its kind and reason, never the revised text (a parent's message); a reason
    -- the tutor typed may name a student, so it reads "typed", as the figures count it (0067).
    'feedback', (select coalesce(jsonb_agg(jsonb_build_object('kind', f.kind,
                   'reason', case when f.reason is null or lower(btrim(f.reason)) = any (public.admin_reason_presets())
                                  then f.reason else 'typed' end,
                   'created_at', f.created_at)
                   order by f.created_at), '[]'::jsonb)
                   from public.generation_feedback f where f.centre_id = g.centre_id and f.generation_id = g.id))
    from public.ai_generations g
    -- Held: a named student without current consent; or a V1 input that names its student with no id (progress_note,
    -- a typed-scheme check_paper), whose consent cannot be known.
    cross join lateral (select case
        when g.student_id is not null then not exists (
          select 1 from public.students s where s.id = g.student_id and s.consent_at is not null)
        else coalesce(g.input ->> 'studentName', g.input ->> 'parentName', g.input ->> 'observations') is not null end as v) held
   where g.id = p_id;
$$;

-- 2. Each batch's days of an exam (D118).
alter table public.school_items
  add column preparations jsonb check (preparations is null or jsonb_typeof(preparations) = 'object');

-- 3. The tries of a push Apple refused for a while.
alter table public.notifications add column attempts int not null default 0 check (attempts >= 0);

create function public.retry_notification(p_id uuid, p_due_at timestamptz)
returns boolean language plpgsql security invoker set search_path = '' as $$
begin
  update public.notifications set state = 'due', due_at = p_due_at, attempts = attempts + 1, apns = null
   where id = p_id and attempts < 3;
  return found;
end $$;

-- 4. 0066's body, the internal centre left out of the day's cost.
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
                 -- The Smoke centre's calls (the golden sets' runs) are the platform's own, not a centre's day.
                 and public.admin_counted(g.centre_id)
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

revoke all on function public.reduce_old_inputs(timestamptz, int) from public, anon, authenticated;
revoke all on function public.retry_notification(uuid, timestamptz) from public, anon, authenticated;
grant execute on function public.reduce_old_inputs(timestamptz, int) to service_role;
grant execute on function public.retry_notification(uuid, timestamptz) to service_role;
