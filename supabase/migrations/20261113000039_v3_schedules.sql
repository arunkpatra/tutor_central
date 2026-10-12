-- V3, Phase 18: the day's jobs are written in the database (plan decision 8). pg_cron runs three schedules that only
-- queue jobs (a schedule runs no work itself): each batch's plan before it, each batch's note day before its note time,
-- and each hour the reminders of every centre a tutor can be reached in. A change to a class, an event, a fee or the
-- reminder settings queues the centre's reminder plan at once, so a moved class's reminder is replaced within a minute.
-- Plans and note days are written only for a centre in use (D91): its tutor opened the app in the last 14 days.

-- An `app_opened` event (Phase 17's activity log) in the 14 days before p_now.
create function public.centre_in_use(p_centre uuid, p_now timestamptz default now())
returns boolean language sql stable security invoker set search_path = '' as $$
  select exists (select 1 from public.events e
                  where e.centre_id = p_centre and e.kind = 'app_opened'
                    and e.at > p_now - interval '14 days' and e.at <= p_now + interval '1 day');
$$;

-- 05:30 in India, or two hours before a batch that starts before 07:30, never before 03:30. 05:30 keeps the job ahead
-- of build 27's background refresh (asked for 06:00).
create function public.plan_time(p_day date, p_start time)
returns timestamptz language sql immutable set search_path = '' as $$
  select (p_day::timestamp + case
            when p_start is not null and p_start < time '07:30' then greatest(p_start - interval '2 hours', time '03:30')
            else time '05:30' end) at time zone 'Asia/Kolkata';
$$;

-- Every active batch of a centre in use meeting today, not yet begun, with no plan and no plan job for the day. A batch
-- made later in the day is planned at once. Answers the count written.
create function public.schedule_plans(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_day date := (p_now at time zone 'Asia/Kolkata')::date;
  v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  select c.centre_id, 'plan', 'plan:' || c.id || ':' || v_day, jsonb_build_object('class_id', c.id, 'date', v_day),
         greatest(p_now, public.plan_time(v_day, c.start_time))
    from public.classes c
   where c.archived_at is null
     and extract(isodow from v_day)::smallint = any (c.meeting_days)
     and (c.start_time is null or (v_day + c.start_time) at time zone 'Asia/Kolkata' > p_now)
     and public.centre_in_use(c.centre_id, p_now)
     and not exists (select 1 from public.plans p where p.centre_id = c.centre_id and p.class_id = c.id and p.date = v_day)
     and not exists (select 1 from public.jobs j where j.centre_id = c.centre_id and j.kind = 'plan'
                       and j.idempotency_key like 'plan:' || c.id || ':' || v_day || '%')
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;

-- Every active batch of a centre in use whose note day is today (Sunday when unset), two hours before its note time
-- (18:00 when unset).
create function public.schedule_note_days(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_day date := (p_now at time zone 'Asia/Kolkata')::date;
  v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  select c.centre_id, 'note_day', 'note_day:' || c.id || ':' || v_day, jsonb_build_object('class_id', c.id, 'date', v_day),
         greatest(p_now, (v_day + coalesce(c.note_time, time '18:00') - interval '2 hours') at time zone 'Asia/Kolkata')
    from public.classes c
   where c.archived_at is null
     and coalesce(c.note_weekday, 7) = extract(isodow from v_day)
     and public.centre_in_use(c.centre_id, p_now)
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;

-- Each hour, every centre with a member holding a live token seen in the last 60 days.
create function public.schedule_reminders(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  select distinct m.centre_id, 'reminder_sweep'::public.job_kind,
         'reminders:' || m.centre_id || ':' || to_char(p_now at time zone 'Asia/Kolkata', 'YYYY-MM-DD"T"HH24'),
         jsonb_build_object('centre_id', m.centre_id), p_now
    from public.centre_members m
    join public.device_tokens t on t.user_id = m.user_id
   where t.retired_at is null and t.last_seen_at > p_now - interval '60 days'
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;

-- A change that moves a reminder queues the centre's reminder plan, unless one already waits to run. Row-level (a
-- statement trigger cannot carry transition tables for three events); the wait check keeps it to one job. A centre
-- being deleted queues nothing (its row is gone by the time the cascade reaches its classes).
create function public.queue_reminder_plan() returns trigger language plpgsql set search_path = '' as $$
declare v_centre uuid;
begin
  if tg_op = 'DELETE' then v_centre := old.centre_id; else v_centre := new.centre_id; end if;
  if not exists (select 1 from public.centres c where c.id = v_centre) then return null; end if;
  if exists (select 1 from public.jobs j where j.centre_id = v_centre and j.kind = 'reminder_sweep' and j.state = 'queued') then
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
create trigger classes_reminder_plan after insert or update or delete on public.classes
  for each row execute function public.queue_reminder_plan();
create trigger calendar_events_reminder_plan after insert or update or delete on public.calendar_events
  for each row execute function public.queue_reminder_plan();
create trigger fee_invoices_reminder_plan after insert or update or delete on public.fee_invoices
  for each row execute function public.queue_reminder_plan();
create trigger reminder_settings_reminder_plan after insert or update or delete on public.reminder_settings
  for each row execute function public.queue_reminder_plan();

revoke all on function public.centre_in_use(uuid, timestamptz) from public, anon, authenticated;
revoke all on function public.plan_time(date, time) from public, anon, authenticated;
revoke all on function public.schedule_plans(timestamptz) from public, anon, authenticated;
revoke all on function public.schedule_note_days(timestamptz) from public, anon, authenticated;
revoke all on function public.schedule_reminders(timestamptz) from public, anon, authenticated;
revoke all on function public.queue_reminder_plan() from public, anon, authenticated;
grant execute on function public.centre_in_use(uuid, timestamptz) to service_role;
grant execute on function public.plan_time(date, time) to service_role;
grant execute on function public.schedule_plans(timestamptz) to service_role;
grant execute on function public.schedule_note_days(timestamptz) to service_role;
grant execute on function public.schedule_reminders(timestamptz) to service_role;

select cron.schedule('schedule_plans', '*/15 * * * *', 'select public.schedule_plans()');
select cron.schedule('schedule_note_days', '*/15 * * * *', 'select public.schedule_note_days()');
select cron.schedule('schedule_reminders', '5 * * * *', 'select public.schedule_reminders()');
