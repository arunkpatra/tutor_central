-- Save a class's attendance for a day (Phase 4): the session is made or found, its marks replaced by p_marks
-- ({"<student id>": "present" | "absent"}), saved_at moved. Two tables in one transaction, so a function; security
-- invoker, so RLS decides what the caller may touch (a student of another centre fails the composite foreign key).
-- p_class null is the session for all students; the unique index (nulls not distinct) keeps one per day.

create function public.save_attendance(p_centre uuid, p_class uuid, p_date date, p_marks jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_marks) <> 'object' then raise exception 'marks must be an object' using errcode = '22023'; end if;
  insert into public.attendance_sessions (centre_id, class_id, date)
  values (p_centre, p_class, p_date)
  on conflict (centre_id, class_id, date) do update set saved_at = now()
  returning id into sid;
  delete from public.attendance_marks m
  where m.session_id = sid and not (p_marks ? m.student_id::text);
  insert into public.attendance_marks (centre_id, session_id, student_id, status)
  select p_centre, sid, key::uuid, value::public.attendance_status
  from jsonb_each_text(p_marks)
  on conflict (session_id, student_id) do update set status = excluded.status;
  return sid;
end $$;

revoke all on function public.save_attendance(uuid, uuid, date, jsonb) from public, anon;
grant execute on function public.save_attendance(uuid, uuid, date, jsonb) to authenticated;
