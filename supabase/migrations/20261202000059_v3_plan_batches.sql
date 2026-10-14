-- V3, Phase 21 (D108): the morning's plans go through the Message Batches API.
-- 1. `plan_time`: every batch's plan job runs from 00:05 in India (was 05:30, or two hours before an early batch, never
--    before 03:30), so the job's batch has the night; a batch made later in the day is still planned at once.
-- 2. `close_pending_generations` leaves a batched row pending for a day: a Message Batch may take hours (up to 24), and
--    its rows are finished when it ends. The platform marks a row batched when it sends it.

create or replace function public.plan_time(p_day date, p_start time)
returns timestamptz language sql immutable set search_path = '' as $$
  select (p_day::timestamp + time '00:05') at time zone 'Asia/Kolkata';
$$;

create or replace function public.close_pending_generations(p_older_than interval default '10 minutes') returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_count integer;
begin
  update public.ai_generations set status = 'failed', error_reason = 'swept', finished_at = now()
   where status = 'pending'
     and created_at < now() - case when batched then interval '25 hours' else p_older_than end;
  get diagnostics v_count = row_count;
  return v_count;
end $$;
