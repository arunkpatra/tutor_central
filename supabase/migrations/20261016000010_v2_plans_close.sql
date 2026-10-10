-- V2 (docs/spec-v2.md sections 6 and 9): plans and their lines, artefacts, the checks and homework of a session, and
-- the close in one write. Additive (D26): attendance_sessions gains two columns; save_attendance stays.

create type public.plan_item_kind as enum ('teach', 'practise', 'check', 'homework', 'brief', 'catch_up');
create type public.artefact_kind as enum ('sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock',
  'note', 'can_do', 'test_tomorrow', 'gap_report');
create type public.artefact_source as enum ('made', 'own');
create type public.homework_status as enum ('given', 'done', 'partial', 'not_done');

create table public.plans (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  class_id uuid,
  date date not null,
  made_at timestamptz not null default now(),
  groups jsonb not null default '[]'::jsonb,
  subjects jsonb not null default '{}'::jsonb,
  session_id uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, class_id) references public.classes(centre_id, id) on delete set null (class_id),
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete set null (session_id)
);
create trigger plans_updated before update on public.plans for each row execute function public.set_updated_at();
create unique index plans_one_per_day on public.plans(centre_id, class_id, date) nulls not distinct;

create table public.artefacts (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  kind public.artefact_kind not null,
  source public.artefact_source not null default 'made',
  student_id uuid,
  plan_id uuid,
  school_item_id uuid,
  title text not null check (char_length(title) between 1 and 200),
  content jsonb not null default '{}'::jsonb,
  photo_path text,
  generation_id uuid,
  regenerated_from uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete set null (plan_id),
  foreign key (centre_id, regenerated_from) references public.artefacts(centre_id, id) on delete set null (regenerated_from)
);
-- ai_generations has no (centre_id, id) key in migration 0001; the artefact names its generation by id, and RLS on
-- ai_generations keeps another centre's row unreadable.
alter table public.ai_generations add constraint ai_generations_centre_id_id_key unique (centre_id, id);
alter table public.artefacts
  add foreign key (centre_id, generation_id) references public.ai_generations(centre_id, id) on delete set null (generation_id);
create trigger artefacts_updated before update on public.artefacts for each row execute function public.set_updated_at();
create index artefacts_student on public.artefacts(centre_id, student_id);
create index artefacts_plan on public.artefacts(centre_id, plan_id);

create table public.plan_items (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  plan_id uuid not null,
  student_id uuid,
  group_no integer check (group_no is null or group_no between 1 and 9),
  kind public.plan_item_kind not null,
  skill_id uuid,
  artefact_id uuid,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, skill_id) references public.skills(centre_id, id) on delete set null (skill_id),
  foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete set null (artefact_id)
);
create trigger plan_items_updated before update on public.plan_items for each row execute function public.set_updated_at();
create index plan_items_plan on public.plan_items(centre_id, plan_id);

alter table public.attendance_sessions
  add column plan_id uuid,
  add column closed_at timestamptz,
  add foreign key (centre_id, plan_id) references public.plans(centre_id, id) on delete set null (plan_id);

-- A check is one question tapped right or wrong, tied to a skill. kind 'placement' is the placement's (docs/spec-v2.md
-- section 5): inside the close it has the session; taken from the student's page it has none.
create table public.checks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  session_id uuid,
  student_id uuid not null,
  skill_id uuid not null,
  kind text not null default 'check' check (kind in ('check', 'placement')),
  question jsonb not null default '{}'::jsonb,
  correct boolean not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  check (session_id is not null or kind = 'placement'),
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, skill_id) references public.skills(centre_id, id) on delete cascade
);
create trigger checks_updated before update on public.checks for each row execute function public.set_updated_at();
create index checks_student on public.checks(centre_id, student_id, created_at);
create index checks_session on public.checks(centre_id, session_id);

-- Homework given in a session. artefact_id is the sheet; none when the close runs without a plan (Phase 11) or the
-- homework is the school's.
create table public.homework (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  session_id uuid not null,
  artefact_id uuid,
  given_at timestamptz not null default now(),
  status public.homework_status not null default 'given',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, session_id, student_id),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete cascade,
  foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete set null (artefact_id)
);
create trigger homework_updated before update on public.homework for each row execute function public.set_updated_at();
create index homework_student on public.homework(centre_id, student_id, given_at);

do $$
declare t text;
begin
  foreach t in array array['plans', 'plan_items', 'artefacts', 'checks', 'homework'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- The close: attendance (through save_attendance, so V1's rule of one session per batch and day holds), then the
-- session's checks and homework replaced, each checked skill's last_checked_at moved, the students' stored tracking
-- status written (track_since moves only when the status changes), the day's plan for the batch linked both ways,
-- closed_at set. One transaction; security invoker, so RLS decides.
--   p_marks    {"<student id>": "present" | "absent"}, as save_attendance takes
--   p_checks   [{"student_id", "skill_id", "question": {...}, "correct": true, "kind"?: "check" | "placement"}]
--   p_homework [{"student_id", "artefact_id"?, "status"?: "given"}]
--   p_track    {"<student id>": {"status": "on_track", "reasons": [...]}}, may be {}
create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid; v_plan uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_homework) <> 'array' or jsonb_typeof(p_track) <> 'object' then
    raise exception 'checks and homework must be arrays, track an object' using errcode = '22023';
  end if;
  sid := public.save_attendance(p_centre, p_class, p_date, p_marks);
  delete from public.checks c where c.centre_id = p_centre and c.session_id = sid;
  insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct)
  select p_centre, sid, (c->>'student_id')::uuid, (c->>'skill_id')::uuid, coalesce(c->>'kind', 'check'),
         coalesce(c->'question', '{}'::jsonb), (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  delete from public.homework h where h.centre_id = p_centre and h.session_id = sid;
  insert into public.homework (centre_id, student_id, session_id, artefact_id, status)
  select p_centre, (h->>'student_id')::uuid, sid, (h->>'artefact_id')::uuid,
         coalesce(h->>'status', 'given')::public.homework_status
  from jsonb_array_elements(p_homework) h;
  update public.students s
     set track_since = case when s.track_status is distinct from t.value->>'status' then now() else s.track_since end,
         track_status = t.value->>'status',
         track_reasons = coalesce(t.value->'reasons', '[]'::jsonb),
         tracked_at = now()
    from jsonb_each(p_track) t
   where s.centre_id = p_centre and s.id = t.key::uuid;
  update public.plans p set session_id = sid
   where p.centre_id = p_centre and p.class_id is not distinct from p_class and p.date = p_date
  returning p.id into v_plan;
  update public.attendance_sessions a set closed_at = now(), plan_id = v_plan where a.id = sid;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb) to authenticated;
