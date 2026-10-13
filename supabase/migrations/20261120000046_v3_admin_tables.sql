-- V3, Phase 19 (D78, D94, D95): the admin allow-list, the alerts' key and message, the alert kinds, and the platform's
-- write functions. The reads are 0047. No member reads admin_users; every function here is the platform's (service_role):
-- the admin portal's server and the API's worker.

-- An admin is an account of its own on this list (D94), keyed by the user as the tenancy tables are. The notify columns
-- name the tutor account and centre whose iPhone gets the alert pushes (the owner's own; the admin account has no device).
-- Rows are written by the session with `supabase db query`, never by the portal.
create table public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  email text not null check (char_length(email) between 3 and 200),
  notify_user_id uuid references auth.users(id) on delete set null,
  notify_centre_id uuid references public.centres(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger admin_users_updated before update on public.admin_users for each row execute function public.set_updated_at();
alter table public.admin_users enable row level security;
create policy admin_users_platform_only on public.admin_users for select to authenticated using (false);
revoke insert, update, delete, truncate on public.admin_users from authenticated;

-- An alert is raised once by its key (`job_failed:<job>`, `cost_day:<centre>:<day>`, `error_rate:<hour>`,
-- `job_stuck:<job>`); the table has had no writer, so any row is given a key of its own before the column is required.
alter table public.alerts
  add column key text,
  add column message text check (message is null or char_length(message) <= 400),
  add column acknowledged_by uuid;
update public.alerts set key = 'legacy:' || id where key is null;
alter table public.alerts
  alter column key set not null,
  add constraint alerts_key_unique unique (key),
  add constraint alerts_key_length check (char_length(key) between 1 and 120);

-- The alerts job (D95), and the push it sends the admin's iPhone. Nothing in this migration uses the new value.
alter type public.job_kind add value 'alerts';
alter table public.jobs drop constraint jobs_check;
alter table public.jobs add constraint jobs_check check (centre_id is not null or kind::text in ('sweep', 'eval_run', 'alerts'));
alter table public.notifications drop constraint notifications_kind_check;
alter table public.notifications add constraint notifications_kind_check
  check (kind in ('class', 'event', 'fees', 'plan_ready', 'notes_ready', 'plan_fetch', 'alert'));

-- Every admin action and every open of a centre's record (D77, D78).
create function public.admin_audit_write(p_admin uuid, p_action text, p_centre uuid, p_target jsonb, p_reason text, p_ip text)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  insert into public.admin_audit (admin_user_id, action, centre_id, target, reason, ip)
  values (p_admin, p_action, p_centre, coalesce(p_target, '{}'), p_reason, p_ip)
  returning id into v_id;
  return v_id;
end $$;

-- True when the alert is new; false when its key was raised before (the email and push go only for a new one).
create function public.raise_alert(p_key text, p_kind text, p_centre uuid, p_threshold numeric, p_value numeric, p_message text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  insert into public.alerts (key, kind, centre_id, threshold, value, message)
  values (p_key, p_kind, p_centre, p_threshold, p_value, p_message)
  on conflict (key) do nothing
  returning id into v_id;
  return v_id is not null;
end $$;

-- What the four lines compare (D95): jobs failed in the last 30 minutes, each centre's cost in India's day, the last
-- hour's requests and errors, jobs running over ten minutes.
create function public.alert_facts(p_now timestamptz)
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
       where r.created_at > p_now - interval '1 hour' and r.created_at <= p_now),
    'stuck_jobs', (
      select coalesce(jsonb_agg(jsonb_build_object('id', j.id, 'kind', j.kind, 'centre_id', j.centre_id,
                                                   'started_at', j.started_at) order by j.started_at), '[]'::jsonb)
        from public.jobs j
       where j.state = 'running' and j.started_at < p_now - interval '10 minutes'));
$$;

-- The tutor accounts (and their centres) whose iPhones get the alert pushes.
create function public.admin_push_targets()
returns table (user_id uuid, centre_id uuid) language sql stable security invoker set search_path = '' as $$
  select a.notify_user_id, a.notify_centre_id from public.admin_users a
   where a.notify_user_id is not null and a.notify_centre_id is not null;
$$;

create function public.admin_acknowledge_alert(p_admin uuid, p_alert uuid, p_ip text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v public.alerts;
begin
  update public.alerts set acknowledged_at = now(), acknowledged_by = p_admin
   where id = p_alert and acknowledged_at is null
  returning * into v;
  if not found then return false; end if;
  perform public.admin_audit_write(p_admin, 'acknowledge_alert', v.centre_id,
    jsonb_build_object('alert', v.id, 'kind', v.kind, 'centre', v.centre_id), null, p_ip);
  return true;
end $$;

-- A failed job back to the queue at its failed step: the step data stays, so it resumes where it failed and a paid step
-- replays by its key. started_at is cleared so the next claim starts the clock again (a retried job is not a stuck one).
create function public.admin_retry_job(p_admin uuid, p_job uuid, p_ip text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v public.jobs;
begin
  select * into v from public.jobs where id = p_job and state = 'failed' for update;
  if not found then return false; end if;
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'queued', attempts = 0, error = null, leased_by = null, lease_until = null,
         started_at = null, finished_at = null, run_at = now()
   where id = p_job;
  perform set_config('tc.jobs', 'off', true);
  perform public.admin_audit_write(p_admin, 'retry_job', v.centre_id,
    jsonb_build_object('job', v.id, 'kind', v.kind, 'centre', v.centre_id, 'step', v.step ->> 'at'), null, p_ip);
  return true;
end $$;

-- cancel_job's effect (0028) as the platform, for any centre's live job.
create function public.admin_cancel_job(p_admin uuid, p_job uuid, p_ip text)
returns boolean language plpgsql security invoker set search_path = '' as $$
declare v public.jobs;
begin
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'cancelled', finished_at = now()
   where id = p_job and state in ('queued', 'waiting', 'running')
  returning * into v;
  perform set_config('tc.jobs', 'off', true);
  if v.id is null then return false; end if;
  perform public.admin_audit_write(p_admin, 'cancel_job', v.centre_id,
    jsonb_build_object('job', v.id, 'kind', v.kind, 'centre', v.centre_id, 'step', v.step ->> 'at'), null, p_ip);
  return true;
end $$;

revoke all on function public.admin_audit_write(uuid, text, uuid, jsonb, text, text) from public, anon, authenticated;
revoke all on function public.raise_alert(text, text, uuid, numeric, numeric, text) from public, anon, authenticated;
revoke all on function public.alert_facts(timestamptz) from public, anon, authenticated;
revoke all on function public.admin_push_targets() from public, anon, authenticated;
revoke all on function public.admin_acknowledge_alert(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.admin_retry_job(uuid, uuid, text) from public, anon, authenticated;
revoke all on function public.admin_cancel_job(uuid, uuid, text) from public, anon, authenticated;
grant execute on function public.admin_audit_write(uuid, text, uuid, jsonb, text, text) to service_role;
grant execute on function public.raise_alert(text, text, uuid, numeric, numeric, text) to service_role;
grant execute on function public.alert_facts(timestamptz) to service_role;
grant execute on function public.admin_push_targets() to service_role;
grant execute on function public.admin_acknowledge_alert(uuid, uuid, text) to service_role;
grant execute on function public.admin_retry_job(uuid, uuid, text) to service_role;
grant execute on function public.admin_cancel_job(uuid, uuid, text) to service_role;
