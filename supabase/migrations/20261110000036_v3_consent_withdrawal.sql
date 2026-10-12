-- V3, Phase 18: a parent's withdrawal is recorded as an event with how and the day (D79; P18-Consent-Withdraw), in one
-- transaction with the clear of the current-state columns the gate reads. 0032's trigger records a clear by itself
-- (build 27's Remove); while this function runs it skips, so the event is written once, by this function, with its how.

create or replace function public.students_consent_history() returns trigger language plpgsql set search_path = '' as $$
begin
  perform set_config('tc.consent', 'on', true);
  if new.consent_at is not null and (tg_op = 'INSERT' or old.consent_at is null
       or old.consent_at is distinct from new.consent_at or old.consent_phone is distinct from new.consent_phone
       or old.consent_how is distinct from new.consent_how) then
    insert into public.consent_events (centre_id, student_id, kind, phone, how, at, by_user)
    values (new.centre_id, new.id, 'given', new.consent_phone, new.consent_how, new.consent_at, auth.uid());
  elsif tg_op = 'UPDATE' and new.consent_at is null and old.consent_at is not null
        and current_setting('tc.withdrawn', true) is distinct from 'on' then
    insert into public.consent_events (centre_id, student_id, kind, at, by_user)
    values (new.centre_id, new.id, 'withdrawn', now(), auth.uid());
  end if;
  perform set_config('tc.consent', 'off', true);
  return null;
end $$;

-- The day is today or earlier in India, never before the last agreement. A day before today is recorded at its noon.
create function public.withdraw_consent(p_centre uuid, p_student uuid, p_how text, p_on date)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_given timestamptz;
  v_today date := (now() at time zone 'Asia/Kolkata')::date;
  v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_how is null or p_how not in ('in_person', 'call', 'whatsapp') then
    raise exception 'consent_how' using errcode = 'P0001';
  end if;
  select consent_at into v_given from public.students where centre_id = p_centre and id = p_student for update;
  if v_given is null then raise exception 'consent_not_given' using errcode = 'P0001'; end if;
  if p_on is null or p_on < (v_given at time zone 'Asia/Kolkata')::date or p_on > v_today then
    raise exception 'consent_day' using errcode = 'P0001';
  end if;
  perform set_config('tc.consent', 'on', true);
  insert into public.consent_events (centre_id, student_id, kind, how, at, by_user)
  values (p_centre, p_student, 'withdrawn', p_how,
          case when p_on = v_today then now() else (p_on::timestamp + time '12:00') at time zone 'Asia/Kolkata' end,
          auth.uid())
  returning id into v_id;
  perform set_config('tc.consent', 'off', true);
  perform set_config('tc.withdrawn', 'on', true);
  update public.students set consent_at = null, consent_phone = null, consent_how = null
   where centre_id = p_centre and id = p_student;
  perform set_config('tc.withdrawn', 'off', true);
  -- What stops at once: the note requests waiting for this student (the gate refuses the rest by itself).
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'cancelled', finished_at = now()
   where centre_id = p_centre and kind = 'note_day' and state in ('queued', 'waiting')
     and input->>'student_id' = p_student::text;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;
revoke all on function public.withdraw_consent(uuid, uuid, text, date) from public, anon;
grant execute on function public.withdraw_consent(uuid, uuid, text, date) to authenticated, service_role;
