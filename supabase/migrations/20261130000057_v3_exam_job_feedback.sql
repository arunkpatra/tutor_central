-- V3, Phase 21 (D106, D107, D108): exam preparation as one job, a tutor's feedback kept, a batched call marked.
-- 1. The job kind `exam_prep` (one per exam item, keyed `exam:<item>`) and the split it writes on the item
--    (`school_items.preparation`, read by the page and the plan alike).
-- 2. `request_exam_prep`: a member asks (Try again, a Save of marks); a waiting job is woken at once.
-- 3. `schedule_exam_preps` (00:10 in India) and the trigger on a confirmed exam: every exam in its window has one job.
-- 4. `generation_feedback`, written only through `record_feedback`: a note's edit at Send, a reason at Make it again or
--    Write again, a replacement at Use my own.
-- 5. `ai_generations.batched`: the platform marks a call made through the Message Batches API (priced at half).
-- 6. The portal's job subject names the exam.
-- A `pdf` job's input may name `generation_id` (V1's results, D90's last half): jsonb, no change here.

alter type public.job_kind add value if not exists 'exam_prep';

alter table public.school_items
  add column preparation jsonb check (preparation is null or jsonb_typeof(preparation) = 'array');

-- An exam is prepared while it is ahead of India's day and within its window (window_days, else 14): the day itself has
-- nothing left to prepare.
create function public.exam_in_window(p_date date, p_window integer, p_now timestamptz default now())
returns boolean language sql stable set search_path = '' as $$
  select p_date > (p_now at time zone 'Asia/Kolkata')::date
     and p_date <= (p_now at time zone 'Asia/Kolkata')::date + coalesce(p_window, 14);
$$;

-- The one writer of exam_prep jobs: the live job of the item woken (run_at now) and answered; else one queued, keyed
-- `exam:<item>`, or `exam:<item>:<ms>` after an earlier job of the plain key ended. It checks its own arguments (it is
-- reachable by a member's call): a confirmed exam of the centre in its window, else not_found. Runs as the caller, so a
-- member sees only their centre's items (RLS); the platform, the trigger and the schedule see the item they name.
create function public.exam_prep_enqueue(p_centre uuid, p_item uuid, p_now timestamptz default now())
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_id uuid;
  v_key text := 'exam:' || p_item;
begin
  if not exists (select 1 from public.school_items i
                  where i.centre_id = p_centre and i.id = p_item and i.kind = 'exam' and i.confirmed_at is not null
                    and public.exam_in_window(i.date, i.window_days, p_now)) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  perform set_config('tc.jobs', 'on', true);
  update public.jobs j set run_at = now()
   where j.centre_id = p_centre and j.kind = 'exam_prep' and j.idempotency_key like v_key || '%'
     and j.state = 'waiting' and j.run_at > now();
  select j.id into v_id from public.jobs j
   where j.centre_id = p_centre and j.kind = 'exam_prep' and j.idempotency_key like v_key || '%'
     and j.state in ('queued', 'running', 'waiting')
   order by j.created_at desc limit 1;
  if v_id is null then
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, 'exam_prep', v_key, jsonb_build_object('item_id', p_item))
    on conflict do nothing returning id into v_id;
  end if;
  if v_id is null then
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, 'exam_prep', v_key || ':' || (extract(epoch from clock_timestamp()) * 1000)::bigint,
            jsonb_build_object('item_id', p_item))
    returning id into v_id;
  end if;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;

-- A member asks: an exam of their centre in its window (the writer checks the item), else not_found.
create function public.request_exam_prep(p_centre uuid, p_item uuid)
returns uuid language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  return public.exam_prep_enqueue(p_centre, p_item);
end $$;

-- A confirmed exam in its window queues its job in the writer's own transaction (a member's add or change, the seed).
create function public.school_items_exam_prep() returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  if new.kind = 'exam' and new.confirmed_at is not null and public.exam_in_window(new.date, new.window_days) then
    perform public.exam_prep_enqueue(new.centre_id, new.id);
  end if;
  return null;
end $$;
create trigger school_items_exam_prep after insert or update of date, portions, window_days, confirmed_at on public.school_items
  for each row execute function public.school_items_exam_prep();

-- Every confirmed exam in its window with no live job, as the platform (00:10 in India): an exam that came into its
-- window overnight, or whose job ended. Answers the count queued.
create function public.schedule_exam_preps(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_count integer := 0;
  v_item record;
begin
  for v_item in
    select i.centre_id, i.id from public.school_items i
     where i.kind = 'exam' and i.confirmed_at is not null and public.exam_in_window(i.date, i.window_days, p_now)
       and not exists (select 1 from public.jobs j where j.centre_id = i.centre_id and j.kind = 'exam_prep'
                         and j.idempotency_key like 'exam:' || i.id || '%' and j.state in ('queued', 'running', 'waiting'))
  loop
    perform public.exam_prep_enqueue(v_item.centre_id, v_item.id, p_now);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

-- 4. Feedback (D107).
create table public.generation_feedback (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  generation_id uuid not null,
  student_id uuid,
  kind text not null check (kind in ('edit', 'again', 'replace')),
  reason text check (reason is null or char_length(reason) between 1 and 200),
  revised jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (centre_id, generation_id) references public.ai_generations(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  check ((kind = 'again' and reason is not null) or (kind <> 'again' and revised is not null))
);
create index generation_feedback_generation on public.generation_feedback (centre_id, generation_id);
create trigger generation_feedback_updated before update on public.generation_feedback for each row execute function public.set_updated_at();
alter table public.generation_feedback enable row level security;
create policy generation_feedback_member on public.generation_feedback for select to authenticated using (public.is_member(centre_id));
create policy generation_feedback_record on public.generation_feedback for insert to authenticated with check (public.is_member(centre_id));
grant select, insert on public.generation_feedback to authenticated;
grant select, insert, update, delete on public.generation_feedback to service_role;

-- A member writes feedback only through record_feedback, which sets tc.feedback for its transaction; the platform and a
-- session with no request write as they need.
create function public.generation_feedback_through_function() returns trigger language plpgsql set search_path = '' as $$
begin
  if current_setting('tc.feedback', true) is distinct from 'on'
     and coalesce((select auth.jwt() ->> 'role'), '') not in ('service_role', '') then
    raise exception 'feedback_through_the_function' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger generation_feedback_through_function before insert on public.generation_feedback
  for each row execute function public.generation_feedback_through_function();

-- The feedback on one generation of the member's centre: the student is the generation's own (a personal kind's).
create function public.record_feedback(p_centre uuid, p_generation uuid, p_kind text, p_reason text, p_revised jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_student uuid;
  v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select g.student_id into v_student from public.ai_generations g where g.centre_id = p_centre and g.id = p_generation;
  if not found then raise exception 'not_found' using errcode = 'P0001'; end if;
  perform set_config('tc.feedback', 'on', true);
  insert into public.generation_feedback (centre_id, generation_id, student_id, kind, reason, revised)
  values (p_centre, p_generation, v_student, p_kind, nullif(btrim(p_reason), ''), p_revised)
  returning id into v_id;
  perform set_config('tc.feedback', 'off', true);
  return v_id;
end $$;

-- 5. A batched call (D108, D109): set by the platform at the finish.
alter table public.ai_generations add column batched boolean not null default false;

-- 6. The portal's subject (0052's) for an exam's job: the exam's title; for a V1 result's file, the result's kind.
create or replace function public.admin_job_subject(p_kind public.job_kind, p_input jsonb, p_key text)
returns text language sql stable security invoker set search_path = '' as $$
  select case
    when p_kind in ('plan', 'note_day') and p_input ? 'class_id' then
      coalesce((select c.name from public.classes c where c.id = (p_input ->> 'class_id')::uuid), 'a batch')
        || coalesce(' · ' || to_char((p_input ->> 'date')::date, 'FMDD Mon'), '')
    when p_kind in ('note_day', 'export') then 'a student'
    when p_kind = 'pdf' then
      coalesce((select a.title from public.artefacts a where a.id = (p_input ->> 'artefact_id')::uuid),
               (select g.kind || ' · a result' from public.ai_generations g where g.id = (p_input ->> 'generation_id')::uuid), 'a file')
    when p_kind::text = 'exam_prep' then  -- text: the new value cannot be used in the transaction that adds it
      coalesce((select nullif(i.title, '') from public.school_items i where i.id = (p_input ->> 'item_id')::uuid), 'an exam')
    when p_kind = 'reminder_sweep' then case when p_key ~ 'T[0-9]{2}$' then 'hourly' else 'after a change' end
    when p_kind in ('sweep', 'alerts') then 'every 10 minutes'
    when p_kind = 'eval_run' then 'nightly evals'
    else null
  end;
$$;

revoke all on function public.exam_in_window(date, integer, timestamptz) from public, anon;
revoke all on function public.exam_prep_enqueue(uuid, uuid, timestamptz) from public, anon;
revoke all on function public.request_exam_prep(uuid, uuid) from public, anon;
revoke all on function public.school_items_exam_prep() from public, anon;
revoke all on function public.schedule_exam_preps(timestamptz) from public, anon, authenticated;
revoke all on function public.generation_feedback_through_function() from public, anon;
revoke all on function public.record_feedback(uuid, uuid, text, text, jsonb) from public, anon;
grant execute on function public.exam_in_window(date, integer, timestamptz) to authenticated, service_role;
grant execute on function public.exam_prep_enqueue(uuid, uuid, timestamptz) to authenticated, service_role;
grant execute on function public.request_exam_prep(uuid, uuid) to authenticated, service_role;
grant execute on function public.school_items_exam_prep() to authenticated, service_role;
grant execute on function public.schedule_exam_preps(timestamptz) to service_role;
grant execute on function public.generation_feedback_through_function() to authenticated, service_role;
grant execute on function public.record_feedback(uuid, uuid, text, text, jsonb) to authenticated, service_role;

select cron.schedule('schedule_exam_preps', '40 18 * * *', 'select public.schedule_exam_preps()');
