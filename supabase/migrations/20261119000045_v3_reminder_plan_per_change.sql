-- V3, Phase 18 review (R-db-5): a change that moves a reminder queues its own reminder plan. 0039 skipped it while a
-- plan was queued, but a worker can claim that plan and read the classes before the change commits: the change was then
-- missed until the hourly plan, too late for a class within the hour. Now only a plan queued in the same transaction
-- (one statement over many rows, a month's fees) answers for the change; a duplicate plan is idempotent and cheap.

create or replace function public.queue_reminder_plan() returns trigger language plpgsql set search_path = '' as $$
declare v_centre uuid;
begin
  if tg_op = 'DELETE' then v_centre := old.centre_id; else v_centre := new.centre_id; end if;
  if not exists (select 1 from public.centres c where c.id = v_centre) then return null; end if;
  -- `now()` is the transaction's start: a job with it as `created_at` was queued by this transaction.
  if exists (select 1 from public.jobs j
              where j.centre_id = v_centre and j.kind = 'reminder_sweep' and j.state = 'queued' and j.created_at = now()) then
    return null;
  end if;
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input)
  values (v_centre, 'reminder_sweep', 'reminders:' || v_centre || ':' || (extract(epoch from clock_timestamp()) * 1000)::bigint,
          jsonb_build_object('centre_id', v_centre))
  on conflict do nothing;
  perform set_config('tc.jobs', 'off', true);
  return null;
end $$;
