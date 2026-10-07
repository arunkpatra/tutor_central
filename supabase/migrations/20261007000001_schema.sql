-- Tutor Central schema, Phase 1 (docs/spec.md section 5).
-- Every table: id, centre_id, created_at, updated_at, row-level security through is_member.
-- References between centre tables are composite (centre_id, id) so a row can never point into another centre.

create extension if not exists pgcrypto with schema extensions;

create type public.centre_role as enum ('owner', 'teacher');
create type public.attendance_status as enum ('present', 'absent');
create type public.fee_status as enum ('due', 'paid', 'waived');
create type public.paid_method as enum ('upi', 'cash', 'other');
create type public.message_kind as enum ('reminder', 'receipt', 'absence', 'progress');
create type public.message_channel as enum ('whatsapp_link');
create type public.ai_kind as enum ('paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper');
create type public.ai_status as enum ('ok', 'failed');

create function public.set_updated_at() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- Tenancy -------------------------------------------------------------------

create table public.centres (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 120),
  currency text not null default 'INR' check (currency = 'INR'),
  upi_id text check (upi_id is null or upi_id ~ '^[a-zA-Z0-9._-]{2,}@[a-zA-Z]{2,}$'),
  upi_confirmed_at timestamptz,
  payment_link text,
  send_receipts boolean not null default true,
  whatsapp_number text check (whatsapp_number is null or whatsapp_number ~ '^\+[1-9][0-9]{7,14}$'),
  ai_consent_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger centres_updated before update on public.centres for each row execute function public.set_updated_at();
create index centres_owner on public.centres(owner_id);

create table public.centre_members (
  centre_id uuid not null references public.centres(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role public.centre_role not null default 'owner',
  created_at timestamptz not null default now(),
  primary key (centre_id, user_id)
);
create index centre_members_user on public.centre_members(user_id);

create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  display_name text check (display_name is null or char_length(display_name) between 1 and 80),
  has_password boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at();

-- Membership check used by every centre policy. security definer so it reads centre_members without recursion.
create function public.is_member(c uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.centre_members m where m.centre_id = c and m.user_id = auth.uid())
$$;

-- Data ----------------------------------------------------------------------

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  name text not null check (char_length(name) between 1 and 80),
  subject text,
  monthly_fee integer check (monthly_fee is null or monthly_fee >= 0),
  meeting_days smallint[] not null default '{}' check (meeting_days <@ '{1,2,3,4,5,6,7}'::smallint[]),
  start_time time,
  end_time time,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  check (start_time is null or end_time is null or end_time > start_time)
);
create trigger classes_updated before update on public.classes for each row execute function public.set_updated_at();

create table public.students (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  class_id uuid,
  name text not null check (char_length(name) between 1 and 80),
  monthly_fee integer check (monthly_fee is null or monthly_fee >= 0),
  parent_name text,
  parent_phone text check (parent_phone is null or parent_phone ~ '^\+[1-9][0-9]{7,14}$'),
  date_of_birth date,
  gender text check (gender is null or gender in ('female', 'male', 'other')),
  notes text check (notes is null or char_length(notes) <= 2000),
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  foreign key (centre_id, class_id) references public.classes(centre_id, id) on delete set null (class_id)
);
create trigger students_updated before update on public.students for each row execute function public.set_updated_at();
create index students_class on public.students(class_id);

-- class_id null is the session for all students; nulls not distinct keeps that to one per day too.
create table public.attendance_sessions (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  class_id uuid,
  date date not null,
  saved_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, id),
  unique nulls not distinct (centre_id, class_id, date),
  foreign key (centre_id, class_id) references public.classes(centre_id, id) on delete set null (class_id)
);
create trigger attendance_sessions_updated before update on public.attendance_sessions
  for each row execute function public.set_updated_at();

create table public.attendance_marks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  session_id uuid not null,
  student_id uuid not null,
  status public.attendance_status not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (session_id, student_id),
  foreign key (centre_id, session_id) references public.attendance_sessions(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger attendance_marks_updated before update on public.attendance_marks
  for each row execute function public.set_updated_at();
create index attendance_marks_student on public.attendance_marks(student_id);

create table public.fee_invoices (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  period date not null check (period = date_trunc('month', period)::date),
  amount integer not null check (amount >= 0),
  status public.fee_status not null default 'due',
  paid_at timestamptz,
  paid_method public.paid_method,
  waived_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (student_id, period),
  check ((status = 'paid') = (paid_at is not null)),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade
);
create trigger fee_invoices_updated before update on public.fee_invoices for each row execute function public.set_updated_at();
create index fee_invoices_centre_period on public.fee_invoices(centre_id, period);

create table public.calendar_events (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  date date not null,
  start_time time,
  end_time time,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (start_time is null or end_time is null or end_time > start_time)
);
create trigger calendar_events_updated before update on public.calendar_events
  for each row execute function public.set_updated_at();
create index calendar_events_centre_date on public.calendar_events(centre_id, date);

create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 200),
  due_date date,
  done_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger tasks_updated before update on public.tasks for each row execute function public.set_updated_at();
create index tasks_centre on public.tasks(centre_id);

create table public.ai_generations (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  kind public.ai_kind not null,
  input jsonb not null,
  output text,
  model text,
  tokens_in integer,
  tokens_out integer,
  status public.ai_status not null default 'ok',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger ai_generations_updated before update on public.ai_generations
  for each row execute function public.set_updated_at();
create index ai_generations_centre_created on public.ai_generations(centre_id, created_at);

create table public.message_log (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid,
  kind public.message_kind not null,
  channel public.message_channel not null default 'whatsapp_link',
  opened_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete set null (student_id)
);
create trigger message_log_updated before update on public.message_log for each row execute function public.set_updated_at();
create index message_log_student on public.message_log(student_id);

-- Row-level security --------------------------------------------------------

alter table public.centres enable row level security;
alter table public.centre_members enable row level security;
alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.attendance_sessions enable row level security;
alter table public.attendance_marks enable row level security;
alter table public.fee_invoices enable row level security;
alter table public.calendar_events enable row level security;
alter table public.tasks enable row level security;
alter table public.ai_generations enable row level security;
alter table public.message_log enable row level security;

-- The owner reads their centre even before the membership row exists (create_centre, members_owner_insert).
create policy centres_member on public.centres for select to authenticated
  using (owner_id = auth.uid() or public.is_member(id));
create policy centres_owner_insert on public.centres for insert to authenticated with check (owner_id = auth.uid());
create policy centres_owner_update on public.centres for update to authenticated
  using (owner_id = auth.uid()) with check (owner_id = auth.uid());
create policy centres_owner_delete on public.centres for delete to authenticated using (owner_id = auth.uid());

create policy members_self on public.centre_members for select to authenticated using (user_id = auth.uid());
create policy members_owner_insert on public.centre_members for insert to authenticated
  with check (exists (select 1 from public.centres c where c.id = centre_id and c.owner_id = auth.uid()));

create policy profiles_self on public.profiles for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

do $$
declare t text;
begin
  foreach t in array array['classes', 'students', 'attendance_sessions', 'attendance_marks', 'fee_invoices',
                           'calendar_events', 'tasks', 'ai_generations', 'message_log'] loop
    execute format('create policy %I on public.%I for all to authenticated '
                   'using (public.is_member(centre_id)) with check (public.is_member(centre_id))', t || '_member', t);
  end loop;
end $$;

-- Functions -----------------------------------------------------------------

-- The centre, its owner membership and the owner's profile, in one call (onboarding).
create function public.create_centre(p_name text, p_whatsapp text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare cid uuid;
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode = '42501'; end if;
  insert into public.centres (owner_id, name, whatsapp_number) values (auth.uid(), p_name, p_whatsapp) returning id into cid;
  insert into public.centre_members (centre_id, user_id, role) values (cid, auth.uid(), 'owner');
  insert into public.profiles (user_id) values (auth.uid()) on conflict (user_id) do nothing;
  return cid;
end $$;

-- One due invoice per active student without one for the period; returns how many were made. Idempotent.
-- Amount: the student's fee, else the class's, else 0.
create function public.generate_fees(p_centre uuid, p_period date) returns integer
language plpgsql security invoker set search_path = '' as $$
declare n integer;
begin
  if p_period <> date_trunc('month', p_period)::date then
    raise exception 'period must be the first of a month' using errcode = '22023';
  end if;
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  insert into public.fee_invoices (centre_id, student_id, period, amount)
  select s.centre_id, s.id, p_period, coalesce(s.monthly_fee, c.monthly_fee, 0)
  from public.students s left join public.classes c on c.id = s.class_id
  where s.centre_id = p_centre and s.archived_at is null
    and not exists (select 1 from public.fee_invoices f where f.student_id = s.id and f.period = p_period)
  on conflict (student_id, period) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

-- Account deletion: the centre and everything in it, immediately (docs/spec.md section 7).
create function public.delete_centre(p_centre uuid) returns void
language plpgsql security invoker set search_path = '' as $$
begin
  delete from public.centres where id = p_centre and owner_id = auth.uid();
  if not found then raise exception 'not the owner' using errcode = '42501'; end if;
end $$;

-- Grants --------------------------------------------------------------------
-- Signed-in users reach tables through RLS; anonymous reaches nothing.

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;

revoke all on function public.is_member(uuid) from public, anon;
revoke all on function public.create_centre(text, text) from public, anon;
revoke all on function public.generate_fees(uuid, date) from public, anon;
revoke all on function public.delete_centre(uuid) from public, anon;
grant execute on function public.is_member(uuid) to authenticated;
grant execute on function public.create_centre(text, text) to authenticated;
grant execute on function public.generate_fees(uuid, date) to authenticated;
grant execute on function public.delete_centre(uuid) to authenticated;
