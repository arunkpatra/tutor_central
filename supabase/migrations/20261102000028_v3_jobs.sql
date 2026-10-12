-- V3, Phase 17: the jobs (D71). `jobs` and `job_steps` are the truth of work the server does: explicit states, a lease,
-- attempts, an idempotency key, the step reached, the result, the cost. The worker (the API's /jobs routes) calls the
-- functions below as the platform, Supabase's service role (D83); the app may enqueue and cancel its own centre's jobs.

-- The platform passes the membership check (D83, plan decision 2). The claim is PostgREST's request.jwt.claims, set per
-- request and unchanged by security definer; psql, the seed and the tests' fixtures have no claim and read false, as
-- before. The functions the app uses (make_plan, keep_artefact, start_ai_call) serve the worker unchanged.
create or replace function public.is_member(c uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select coalesce((select auth.jwt() ->> 'role'), '') = 'service_role'
      or exists (select 1 from public.centre_members m where m.centre_id = c and m.user_id = auth.uid())
$$;

create type public.job_kind as enum ('plan', 'artefact', 'note_day', 'reminder_sweep', 'export', 'pdf', 'eval_run', 'sweep');
create type public.job_state as enum ('queued', 'running', 'waiting', 'done', 'failed', 'cancelled');

-- centre_id is null for the platform's own kinds only (plan decision 3); every other kind belongs to a centre.
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid references public.centres(id) on delete cascade,
  kind public.job_kind not null,
  state public.job_state not null default 'queued',
  idempotency_key text not null check (char_length(idempotency_key) between 1 and 200),
  input jsonb not null default '{}',
  step jsonb not null default '{}',
  result jsonb,
  error jsonb,
  attempts integer not null default 0 check (attempts >= 0),
  max_attempts integer not null default 3 check (max_attempts between 1 and 10),
  run_at timestamptz not null default now(),
  leased_by text,
  lease_until timestamptz,
  started_at timestamptz,
  finished_at timestamptz,
  cost_paise integer not null default 0 check (cost_paise >= 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  check (centre_id is not null or kind in ('sweep', 'eval_run'))
);
create unique index jobs_key on public.jobs (coalesce(centre_id, '00000000-0000-0000-0000-000000000000'::uuid), idempotency_key);
create index jobs_due on public.jobs (run_at) where state in ('queued', 'waiting', 'running');
create index jobs_centre on public.jobs (centre_id, created_at);
create trigger jobs_updated before update on public.jobs for each row execute function public.set_updated_at();

create table public.job_steps (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid,
  job_id uuid not null references public.jobs(id) on delete cascade,
  step text not null check (char_length(step) between 1 and 40),
  attempt integer not null check (attempt >= 1),
  state public.job_state not null,
  generation_id uuid,
  error jsonb,
  cost_paise integer not null default 0 check (cost_paise >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (centre_id, job_id) references public.jobs (centre_id, id) on delete cascade,
  foreign key (centre_id, generation_id) references public.ai_generations (centre_id, id) on delete set null (generation_id)
);
create index job_steps_job on public.job_steps (job_id, created_at);
create trigger job_steps_updated before update on public.job_steps for each row execute function public.set_updated_at();

alter table public.jobs enable row level security;
alter table public.job_steps enable row level security;
create policy jobs_member on public.jobs for select to authenticated using (public.is_member(centre_id));
create policy jobs_member_enqueue on public.jobs for insert to authenticated with check (public.is_member(centre_id));
create policy jobs_member_cancel on public.jobs for update to authenticated using (public.is_member(centre_id)) with check (public.is_member(centre_id));
create policy job_steps_member on public.job_steps for select to authenticated using (public.is_member(centre_id));
revoke delete on public.jobs from authenticated;
revoke insert, update, delete on public.job_steps from authenticated;

-- A member writes a job only through enqueue_job and cancel_job, which set tc.jobs for their transaction; the platform
-- and a session with no request (the seed, psql) write as they need. An insert around the functions is refused; an
-- update around them changes nothing, as a missing policy would.
create function public.jobs_through_functions() returns trigger language plpgsql set search_path = '' as $$
begin
  if current_setting('tc.jobs', true) is distinct from 'on'
     and coalesce((select auth.jwt() ->> 'role'), '') not in ('service_role', '') then
    if tg_op = 'INSERT' then raise exception 'jobs_through_the_functions' using errcode = '42501'; end if;
    return null;
  end if;
  return new;
end $$;
create trigger jobs_through_functions before insert or update on public.jobs
  for each row execute function public.jobs_through_functions();

-- Enqueue once per centre and key: a second call with the same key answers the first job's id and changes nothing.
create function public.enqueue_job(p_centre uuid, p_kind public.job_kind, p_key text, p_input jsonb default '{}',
                                   p_run_at timestamptz default now(), p_max_attempts integer default 3)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  -- For a null centre only the platform passes (exists on null is false; the role clause is true for the service role).
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at, max_attempts)
  values (p_centre, p_kind, p_key, coalesce(p_input, '{}'), coalesce(p_run_at, now()), coalesce(p_max_attempts, 3))
  on conflict do nothing
  returning id into v_id;
  if v_id is null then
    select j.id into v_id from public.jobs j
     where coalesce(j.centre_id, '00000000-0000-0000-0000-000000000000'::uuid)
           = coalesce(p_centre, '00000000-0000-0000-0000-000000000000'::uuid)
       and j.idempotency_key = p_key;
  end if;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;

-- A claim is an attempt; a job that waited (a budget reached, a key in progress) continues within its attempt.
create function public.claim_jobs(p_worker text, p_limit integer default 5, p_lease_seconds integer default 180)
returns setof public.jobs language plpgsql security invoker set search_path = '' as $$
begin
  -- A lease that lapsed on the last attempt is failed here, so the portal sees why it stopped.
  update public.jobs set state = 'failed', finished_at = now(), leased_by = null, lease_until = null,
         error = coalesce(error, '{}'::jsonb) || jsonb_build_object('reason', 'attempts', 'message', 'the lease lapsed on the last attempt')
   where state = 'running' and lease_until < now() and attempts >= max_attempts;
  -- The rows are picked once, in a materialized CTE: a sub-select with LIMIT under `in (…)` may be planned so that two
  -- workers at once come away with fewer jobs than are due (seen once in session 35).
  return query
    with picked as materialized (
      select q.id from public.jobs q
       where (q.state = 'waiting' and q.run_at <= now())
          or (q.state = 'queued' and q.run_at <= now() and q.attempts < q.max_attempts)
          or (q.state = 'running' and q.lease_until < now() and q.attempts < q.max_attempts)
       order by q.run_at for update skip locked limit p_limit)
    update public.jobs j
       set state = 'running', leased_by = p_worker, lease_until = now() + make_interval(secs => p_lease_seconds),
           started_at = coalesce(j.started_at, now()),
           attempts = j.attempts + case when j.state = 'waiting' then 0 else 1 end
      from picked where j.id = picked.id
    returning j.*;
end $$;

-- The worker holds the job: it is running and its lease is this worker's. Raises what the worker matches.
create function public.job_held(p_job uuid, p_worker text) returns public.jobs
language plpgsql security invoker set search_path = '' as $$
declare v public.jobs;
begin
  select * into v from public.jobs where id = p_job for update;
  if not found then raise exception 'job_not_running' using errcode = 'P0002'; end if;
  if v.state = 'cancelled' then raise exception 'job_cancelled' using errcode = 'P0001'; end if;
  if v.state <> 'running' then raise exception 'job_not_running' using errcode = 'P0001'; end if;
  if v.leased_by is distinct from p_worker then raise exception 'job_lease_lost' using errcode = 'P0001'; end if;
  return v;
end $$;

create function public.extend_lease(p_job uuid, p_worker text, p_lease_seconds integer default 180) returns boolean
language plpgsql security invoker set search_path = '' as $$
begin
  update public.jobs set lease_until = now() + make_interval(secs => p_lease_seconds)
   where id = p_job and state = 'running' and leased_by = p_worker;
  return found;
end $$;

-- One step written: its row, the job's cost and the step reached, the lease extended. Returns the step's id.
create function public.record_step(p_job uuid, p_worker text, p_step text, p_state public.job_state,
                                   p_generation uuid default null, p_error jsonb default null, p_cost_paise integer default 0,
                                   p_step_data jsonb default null)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v public.jobs; v_id uuid;
begin
  v := public.job_held(p_job, p_worker);
  insert into public.job_steps (centre_id, job_id, step, attempt, state, generation_id, error, cost_paise)
  values (v.centre_id, v.id, p_step, greatest(v.attempts, 1), p_state, p_generation, p_error, coalesce(p_cost_paise, 0))
  returning id into v_id;
  update public.jobs set cost_paise = cost_paise + coalesce(p_cost_paise, 0), step = coalesce(p_step_data, step),
         lease_until = now() + interval '180 seconds'
   where id = p_job;
  return v_id;
end $$;

create function public.wait_job(p_job uuid, p_worker text, p_step jsonb, p_run_at timestamptz) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  perform public.job_held(p_job, p_worker);
  update public.jobs set state = 'waiting', step = coalesce(p_step, step), run_at = coalesce(p_run_at, now()),
         leased_by = null, lease_until = null
   where id = p_job;
end $$;

create function public.finish_job(p_job uuid, p_worker text, p_result jsonb) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  perform public.job_held(p_job, p_worker);
  update public.jobs set state = 'done', result = p_result, finished_at = now(), leased_by = null, lease_until = null
   where id = p_job;
end $$;

-- A retry waits 30 s × 2^(attempts − 1), at most 10 minutes; past max_attempts the job fails with its last error.
create function public.fail_job(p_job uuid, p_worker text, p_error jsonb, p_retry boolean) returns public.job_state
language plpgsql security invoker set search_path = '' as $$
declare v public.jobs;
begin
  v := public.job_held(p_job, p_worker);
  if p_retry and v.attempts < v.max_attempts then
    update public.jobs set state = 'queued', error = p_error, leased_by = null, lease_until = null,
           run_at = now() + least(interval '10 minutes', interval '30 seconds' * power(2, greatest(v.attempts, 1) - 1))
     where id = p_job;
    return 'queued';
  end if;
  update public.jobs set state = 'failed', error = p_error, finished_at = now(), leased_by = null, lease_until = null
   where id = p_job;
  return 'failed';
end $$;

-- A member cancels their centre's job while it is live; the worker's next write meets job_cancelled.
create function public.cancel_job(p_centre uuid, p_job uuid) returns boolean
language plpgsql security invoker set search_path = '' as $$
declare v_count integer;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'cancelled', finished_at = now()
   where id = p_job and centre_id = p_centre and state in ('queued', 'waiting', 'running');
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count > 0;
end $$;

revoke all on function public.claim_jobs(text, integer, integer) from public, anon, authenticated;
revoke all on function public.job_held(uuid, text) from public, anon, authenticated;
revoke all on function public.extend_lease(uuid, text, integer) from public, anon, authenticated;
revoke all on function public.record_step(uuid, text, text, public.job_state, uuid, jsonb, integer, jsonb) from public, anon, authenticated;
revoke all on function public.wait_job(uuid, text, jsonb, timestamptz) from public, anon, authenticated;
revoke all on function public.finish_job(uuid, text, jsonb) from public, anon, authenticated;
revoke all on function public.fail_job(uuid, text, jsonb, boolean) from public, anon, authenticated;
revoke all on function public.enqueue_job(uuid, public.job_kind, text, jsonb, timestamptz, integer) from public, anon;
revoke all on function public.cancel_job(uuid, uuid) from public, anon;
revoke all on function public.jobs_through_functions() from public, anon, authenticated;
grant execute on function public.claim_jobs(text, integer, integer) to service_role;
grant execute on function public.job_held(uuid, text) to service_role;
grant execute on function public.extend_lease(uuid, text, integer) to service_role;
grant execute on function public.record_step(uuid, text, text, public.job_state, uuid, jsonb, integer, jsonb) to service_role;
grant execute on function public.wait_job(uuid, text, jsonb, timestamptz) to service_role;
grant execute on function public.finish_job(uuid, text, jsonb) to service_role;
grant execute on function public.fail_job(uuid, text, jsonb, boolean) to service_role;
grant execute on function public.enqueue_job(uuid, public.job_kind, text, jsonb, timestamptz, integer) to authenticated, service_role;
grant execute on function public.cancel_job(uuid, uuid) to authenticated, service_role;
