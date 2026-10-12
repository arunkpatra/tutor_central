-- V3, Phase 18: what the sweep keeps and for how long (plan decision 27), through named functions the platform alone may
-- call (D83: the worker reaches the database through named functions): a student's export is kept seven days; the
-- outbox's rows thirty; the platform's own done sweeps and reminder plans seven. A plan, a note or an export job stays
-- (the app reads its state).

-- The exports made before a time: the sweep removes each through the Storage API (Storage refuses a row's delete).
create function public.old_exports(p_before timestamptz, p_limit integer default 100)
returns table (name text) language sql stable security invoker set search_path = '' as $$
  select o.name from storage.objects o
   where o.bucket_id = 'exports' and o.created_at < p_before
   order by o.created_at limit p_limit;
$$;

create function public.trim_platform(p_now timestamptz default now())
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare v_notifications integer; v_jobs integer;
begin
  delete from public.notifications where created_at < p_now - interval '30 days';
  get diagnostics v_notifications = row_count;
  delete from public.jobs
   where kind in ('reminder_sweep', 'sweep') and state = 'done' and finished_at < p_now - interval '7 days';
  get diagnostics v_jobs = row_count;
  return jsonb_build_object('notifications', v_notifications, 'jobs', v_jobs);
end $$;

revoke all on function public.old_exports(timestamptz, integer) from public, anon, authenticated;
revoke all on function public.trim_platform(timestamptz) from public, anon, authenticated;
grant execute on function public.old_exports(timestamptz, integer) to service_role;
grant execute on function public.trim_platform(timestamptz) to service_role;
