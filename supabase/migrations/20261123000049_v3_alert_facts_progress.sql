-- V3, Phase 19's review (R-db-1 to R-db-3): the alerts' facts measure what they mean. A stuck job is one with no progress
-- for ten minutes (its last step, or its start), not one whose first start is old: claim_jobs keeps started_at across
-- waits, so a long plan was taken for a stuck one each morning. The hour's requests and the errors page's tiles leave out
-- the worker's ticks (sixty a minute's hour), which diluted the error rate. The alerts jobs are trimmed as the sweeps
-- are. Signatures and grants unchanged.

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
    -- Stuck is no progress: a job keeps its first started_at across waits and retries, so a long plan that steps every
    -- few minutes is not stuck; one whose last step (or start) is over ten minutes old is.
    'stuck_jobs', (
      select coalesce(jsonb_agg(jsonb_build_object('id', s.id, 'kind', s.kind, 'centre_id', s.centre_id, 'since', s.since)
                                order by s.since), '[]'::jsonb)
        from (select j.id, j.kind, j.centre_id,
                     greatest(j.started_at, (select max(st.updated_at) from public.job_steps st where st.job_id = j.id)) as since
                from public.jobs j where j.state = 'running') s
       where s.since < p_now - interval '10 minutes'));
$$;

create or replace function public.admin_errors_by_route(p_hours int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with win as (select * from public.api_requests r where r.created_at > now() - make_interval(hours => p_hours) and r.route not like '/jobs/%'),
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

create or replace function public.trim_platform(p_now timestamptz default now())
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare v_notifications integer; v_jobs integer;
begin
  delete from public.notifications where created_at < p_now - interval '30 days';
  get diagnostics v_notifications = row_count;
  delete from public.jobs
   where kind in ('reminder_sweep', 'sweep', 'alerts') and state = 'done' and finished_at < p_now - interval '7 days';
  get diagnostics v_jobs = row_count;
  return jsonb_build_object('notifications', v_notifications, 'jobs', v_jobs);
end $$;
