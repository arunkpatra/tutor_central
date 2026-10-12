-- V3, Phase 17: a parent's consent has a history (D79, plan decision 14). `consent_events` is append-only (given,
-- withdrawn, the phone, how, when, by whom), written by a trigger on the student's three consent columns, which stay the
-- gate's current state. The students who have consent today get their `given` now (by_user unknown). The history goes
-- with the student (0027's rule).

create table public.consent_events (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  student_id uuid not null,
  kind text not null check (kind in ('given', 'withdrawn')),
  phone text,
  how text,
  at timestamptz not null,
  by_user uuid,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (centre_id, student_id) references public.students (centre_id, id) on delete cascade
);
create index consent_events_student on public.consent_events (student_id, created_at);
create trigger consent_events_updated before update on public.consent_events for each row execute function public.set_updated_at();
alter table public.consent_events enable row level security;
create policy consent_events_member_read on public.consent_events for select to authenticated using (public.is_member(centre_id));
create policy consent_events_member_insert on public.consent_events for insert to authenticated with check (public.is_member(centre_id));

-- Runs as the member who changed the student, so its insert passes the policy above.
create function public.students_consent_history() returns trigger language plpgsql set search_path = '' as $$
begin
  if new.consent_at is not null and (tg_op = 'INSERT' or old.consent_at is null
       or old.consent_at is distinct from new.consent_at or old.consent_phone is distinct from new.consent_phone
       or old.consent_how is distinct from new.consent_how) then
    insert into public.consent_events (centre_id, student_id, kind, phone, how, at, by_user)
    values (new.centre_id, new.id, 'given', new.consent_phone, new.consent_how, new.consent_at, auth.uid());
  elsif tg_op = 'UPDATE' and new.consent_at is null and old.consent_at is not null then
    insert into public.consent_events (centre_id, student_id, kind, at, by_user)
    values (new.centre_id, new.id, 'withdrawn', now(), auth.uid());
  end if;
  return null;
end $$;
revoke all on function public.students_consent_history() from public, anon, authenticated;
create trigger students_consent_history after insert or update of consent_at, consent_phone, consent_how on public.students
  for each row execute function public.students_consent_history();

insert into public.consent_events (centre_id, student_id, kind, phone, how, at, by_user)
select s.centre_id, s.id, 'given', s.consent_phone, s.consent_how, s.consent_at, null
  from public.students s where s.consent_at is not null;
