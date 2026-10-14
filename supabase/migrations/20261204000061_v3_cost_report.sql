-- V3, Phase 21 (D109): the standing cost report, and a call's feedback on its page.
-- 1. `admin_cost_by_step(month, centre)`: the month's calls by kind, step, model and whether a Message Batch answered
--    them (at half price), the dearest first.
-- 2. `admin_cost_by_month(centre)`: the last six months in India: calls, paise, the batched share, the centres that made a
--    call and the cost per such centre.
-- 3. `admin_call` gains `feedback`: the tutor's edits, reasons and replacements on the call (D107), oldest first.
-- Each is the platform's alone, as every admin read (0047).

create function public.admin_cost_by_step(p_month date, p_centre uuid default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object('kind', x.kind, 'step', x.step, 'model', x.model, 'batched', x.batched,
           'calls', x.calls, 'paise', x.paise) order by x.paise desc, x.kind, x.step), '[]'::jsonb)
    from (select g.kind::text as kind, g.agent_step as step, coalesce(g.model, 'none') as model, g.batched,
                 count(*) as calls, coalesce(sum(g.cost_paise), 0)::bigint as paise
            from public.ai_generations g
           where (p_centre is null or g.centre_id = p_centre)
             and (g.created_at at time zone 'Asia/Kolkata')::date >= p_month
             and (g.created_at at time zone 'Asia/Kolkata')::date < (p_month + interval '1 month')::date
           group by 1, 2, 3, 4) x;
$$;

create function public.admin_cost_by_month(p_centre uuid default null)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with months as (
         select (date_trunc('month', public.admin_today()) - make_interval(months => n))::date as month
           from generate_series(5, 0, -1) n),
       calls as (
         select date_trunc('month', (g.created_at at time zone 'Asia/Kolkata'))::date as month, g.centre_id,
                count(*) as calls, coalesce(sum(g.cost_paise), 0)::bigint as paise,
                coalesce(sum(g.cost_paise) filter (where g.batched), 0)::bigint as batched_paise
           from public.ai_generations g
          where (p_centre is null or g.centre_id = p_centre)
            and (g.created_at at time zone 'Asia/Kolkata')::date >= (select min(month) from months)
          group by 1, 2)
  select jsonb_agg(jsonb_build_object(
           'month', r.month, 'calls', r.calls, 'paise', r.paise, 'batched_paise', r.batched_paise,
           'active_centres', r.active_centres,
           'per_active_centre_paise', case when r.active_centres > 0 then round(r.paise::numeric / r.active_centres) else 0 end)
         order by r.month)
    from (select m.month, coalesce(sum(c.calls), 0)::bigint as calls, coalesce(sum(c.paise), 0)::bigint as paise,
                 coalesce(sum(c.batched_paise), 0)::bigint as batched_paise, count(c.centre_id) as active_centres
            from months m left join calls c on c.month = m.month
           group by m.month) r;
$$;

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
              from public.jobs j where j.id = g.job_id),
    -- The tutor's word on the call (D107): its kind and reason, never the revised text (a parent's message).
    'feedback', (select coalesce(jsonb_agg(jsonb_build_object('kind', f.kind, 'reason', f.reason, 'created_at', f.created_at)
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

revoke all on function public.admin_cost_by_step(date, uuid) from public, anon, authenticated;
revoke all on function public.admin_cost_by_month(uuid) from public, anon, authenticated;
grant execute on function public.admin_cost_by_step(date, uuid) to service_role;
grant execute on function public.admin_cost_by_month(uuid) to service_role;
