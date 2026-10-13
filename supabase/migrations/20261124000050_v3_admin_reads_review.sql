-- V3, Phase 19's review (R-a2, R-db-6 to R-db-8): a V1 call that names its student with no id has its input held, as
-- one without consent; a job's step shows the attempt of its latest row (an admin's retry starts again at 1); the record
-- is served again only to the admin who opened it; an old open alert is never cut off by newer acknowledged ones.

create or replace function public.admin_call(p_id uuid)
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
    -- Held: a named student without current consent; or a V1 input that names its student with no id (progress_note,
    -- a typed-scheme check_paper), whose consent cannot be known.
    cross join lateral (select case
        when g.student_id is not null then not exists (
          select 1 from public.students s where s.id = g.student_id and s.consent_at is not null)
        else coalesce(g.input ->> 'studentName', g.input ->> 'parentName', g.input ->> 'observations') is not null end as v) held
   where g.id = p_id;
$$;

create or replace function public.admin_job(p_id uuid)
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
        from (select st.step, (array_agg(st.attempt order by st.created_at desc, st.attempt desc))[1] as attempt, min(st.created_at) as first_at,
                     max(st.updated_at) as last_at,
                     sum(st.cost_paise)::int as cost_paise,
                     (array_agg(st.state order by st.created_at desc, st.attempt desc))[1] as state,
                     (array_agg(st.error order by st.created_at desc, st.attempt desc))[1] as error,
                     (array_agg(st.generation_id order by st.created_at desc, st.attempt desc))[1] as generation_id
                from public.job_steps st where st.job_id = j.id group by st.step) s))
    from public.jobs j where j.id = p_id;
$$;

create or replace function public.admin_alerts(p_open_first boolean)
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
        -- Open ones first before the limit, so an old open alert is never cut off by newer acknowledged ones.
        from (select * from public.alerts order by (acknowledged_at is null) desc, raised_at desc limit 200) a));
$$;

drop function public.admin_record_opened(uuid);

-- The record again for a fresh open by this admin (an open_record row of theirs under ten minutes old).
create function public.admin_record_opened(p_audit uuid, p_admin uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select public.admin_record(a.centre_id) || jsonb_build_object('audit_id', a.id, 'opened_at', a.created_at, 'reason', a.reason)
    from public.admin_audit a
   where a.id = p_audit and a.admin_user_id = p_admin and a.action = 'open_record' and a.centre_id is not null
     and a.created_at > now() - interval '10 minutes';
$$;
revoke all on function public.admin_record_opened(uuid, uuid) from public, anon, authenticated;
grant execute on function public.admin_record_opened(uuid, uuid) to service_role;
