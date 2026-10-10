-- V2 (docs/spec-v2.md section 9): the student's class, school, board, language and consent; schools; textbooks
-- captured once per school, class and subject; chapters and skills copied per student. Additive (D26): a V1 student
-- reads back with no class, no school, English, no consent and "not known yet".

create type public.skill_state as enum ('not_started', 'taught', 'practising', 'secure', 'revisit');

create table public.schools (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  board text check (board is null or board in ('cbse', 'icse', 'karnataka', 'other')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id)
);
create trigger schools_updated before update on public.schools for each row execute function public.set_updated_at();

-- consent_how: how the parent agreed (the boards' record sheet: in person, on a call, on WhatsApp; D62).
-- track_since: when the stored status last changed (the tracking card's "since"); tracked_at: when it was last worked out.
alter table public.students
  add column class_level text check (class_level is null or class_level in ('lkg', 'ukg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')),
  add column school_id uuid,
  add column board text check (board is null or board in ('cbse', 'icse', 'karnataka', 'other')),
  add column message_language text not null default 'en' check (message_language in ('en', 'hinglish', 'hi', 'kn')),
  add column consent_at timestamptz,
  add column consent_phone text check (consent_phone is null or consent_phone ~ '^\+[1-9][0-9]{7,14}$'),
  add column consent_how text check (consent_how is null or consent_how in ('in_person', 'call', 'whatsapp')),
  add column track_status text not null default 'not_known' check (track_status in ('not_known', 'on_track', 'watch', 'not_on_track')),
  add column track_reasons jsonb not null default '[]'::jsonb,
  add column track_since timestamptz,
  add column tracked_at timestamptz,
  add foreign key (centre_id, school_id) references public.schools(centre_id, id) on delete set null (school_id);
create index students_school on public.students(centre_id, school_id);

-- chapters: the contents page as read ([{"position": 1, "name": "...", "skills": ["...", "..."]}]), kept on the book
-- so a student who joins the class later gets the same list (copy_textbook_chapters).
create table public.textbooks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  school_id uuid not null,
  class_level text not null check (class_level in ('lkg', 'ukg', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10')),
  subject text not null check (char_length(subject) between 1 and 80),
  title text not null check (char_length(title) between 1 and 200),
  publisher text check (publisher is null or char_length(publisher) <= 120),
  edition text check (edition is null or char_length(edition) <= 40),
  photo_path text,
  chapters jsonb not null default '[]'::jsonb check (jsonb_typeof(chapters) = 'array'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, school_id, class_level, subject),
  foreign key (centre_id, school_id) references public.schools(centre_id, id) on delete cascade
);
create trigger textbooks_updated before update on public.textbooks for each row execute function public.set_updated_at();

-- A chapter comes from a textbook, the board's syllabus (syllabus_id, referenced from migration 0011), the tutor, or
-- the ladder: for LKG to class 3, one chapter per domain (reading, writing, numbers) whose skills are the ladder's steps,
-- so the close's checks and the skill states work the same for the ladder (docs/spec-v2.md section 5).
create table public.chapters (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  subject text not null check (char_length(subject) between 1 and 80),
  position integer not null check (position >= 1),
  name text not null check (char_length(name) between 1 and 200),
  textbook_id uuid,
  syllabus_id uuid,
  ladder text check (ladder is null or ladder in ('reading', 'writing', 'numbers')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, student_id, subject, position),
  unique (centre_id, student_id, ladder),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  foreign key (centre_id, textbook_id) references public.textbooks(centre_id, id) on delete set null (textbook_id)
);
create trigger chapters_updated before update on public.chapters for each row execute function public.set_updated_at();
create index chapters_student on public.chapters(centre_id, student_id);

create table public.skills (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  chapter_id uuid not null,
  student_id uuid not null,
  position integer not null check (position >= 1),
  name text not null check (char_length(name) between 1 and 200),
  state public.skill_state not null default 'not_started',
  state_at timestamptz not null default now(),
  last_checked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique (centre_id, chapter_id, position),
  foreign key (centre_id, chapter_id) references public.chapters(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger skills_updated before update on public.skills for each row execute function public.set_updated_at();
create index skills_student on public.skills(centre_id, student_id);

do $$
declare t text;
begin
  foreach t in array array['schools', 'textbooks', 'chapters', 'skills'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
    execute format('grant select, insert, update, delete on public.%I to authenticated', t);
  end loop;
end $$;

-- Copies a textbook's chapters and skills to a student, replacing the student's chapters that came from this textbook
-- and keeping the rest (their own, another book's). Run again, it gives the same rows. security invoker: RLS decides.
create function public.copy_textbook_chapters(p_centre uuid, p_textbook uuid, p_student uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_subject text; v_chapters jsonb;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.subject, t.chapters into v_subject, v_chapters from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_subject is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  delete from public.chapters c where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook;
  insert into public.chapters (centre_id, student_id, subject, position, name, textbook_id)
  select p_centre, p_student, v_subject, (ch->>'position')::integer, ch->>'name', p_textbook
  from jsonb_array_elements(v_chapters) ch;
  insert into public.skills (centre_id, chapter_id, student_id, position, name)
  select p_centre, c.id, p_student, s.ordinality, s.value
  from public.chapters c
  join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
  cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
  where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook;
end $$;

revoke all on function public.copy_textbook_chapters(uuid, uuid, uuid) from public, anon;
grant execute on function public.copy_textbook_chapters(uuid, uuid, uuid) to authenticated;
