-- V3, Phase 17: the worker is woken from inside the database (D85, plan decision 6): a job queued posts to the API's
-- /jobs/wake at once, and pg_cron gets /jobs/tick each minute (the platform's one scheduler; Phase 18 adds its schedules
-- beside this one). Both read the worker's address and secret from Vault, which the deploy writes from the Production
-- environment (WORKER_SECRET, API_ORIGIN); without them both do nothing and the jobs wait for a tick that has them.

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;

-- The third security definer function (D37, D83): vault.decrypted_secrets is readable by postgres alone, and the worker's
-- address and secret are never in a migration (D11). A wake that cannot be queued never blocks the insert.
create function public.wake_worker() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return new; end if;
  perform net.http_post(
    url := v_url || '/jobs/wake',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_secret),
    body := jsonb_build_object('job', new.id),
    timeout_milliseconds := 3000);
  return new;
exception when others then
  return new;
end $$;
revoke all on function public.wake_worker() from public, anon, authenticated;
create trigger jobs_wake after insert on public.jobs for each row execute function public.wake_worker();

-- The fourth (D83): the minute wake, as pg_cron's job runs it (as postgres). A GET, as the deploy's smoke makes it.
create function public.wake_worker_tick() returns void language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_get(url := v_url || '/jobs/tick', headers := jsonb_build_object('Authorization', 'Bearer ' || v_secret),
                       timeout_milliseconds := 3000);
end $$;
revoke all on function public.wake_worker_tick() from public, anon, authenticated;

select cron.schedule('wake_worker_minute', '* * * * *', 'select public.wake_worker_tick()');
