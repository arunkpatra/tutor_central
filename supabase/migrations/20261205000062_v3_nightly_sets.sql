-- V3, Phase 21 (decision 8): the nightly evals run the job kinds on a weekday (`input.set` 'nightly': Phase 20's nine and
-- the kinds the jobs make, named in api/src/evals/cases.ts) and every kind on Sunday in India.
create or replace function public.schedule_evals(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_day date := (p_now at time zone 'Asia/Kolkata')::date;
  v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  values (null, 'eval_run', 'evals:' || v_day,
          jsonb_build_object('day', v_day) || case when extract(isodow from v_day) = 7 then '{}'::jsonb else '{"set": "nightly"}'::jsonb end,
          (v_day + time '02:00') at time zone 'Asia/Kolkata')
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;
