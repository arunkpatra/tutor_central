-- Phase 11 (docs/spec-v2.md sections 5 and 6; plan/phase-11-plan.md Task 1). Additive (D26): three new functions, two
-- replaced (0010's close_session gains an eighth argument with a default; 0016's copy_textbook_chapters moves the
-- student's own chapters of the subject behind the book's). Nothing from 0001 to 0016 is edited.

-- 1. The close also moves the skill states the app worked out (plan decision 7): p_states [{"skill_id", "state"}].
--    The seven-argument call of build 19 still resolves to this one through the default.
drop function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb);

create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb, p_states jsonb default '[]'::jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid; v_plan uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_homework) <> 'array' or jsonb_typeof(p_track) <> 'object'
     or jsonb_typeof(p_states) <> 'array' then
    raise exception 'checks, homework and states must be arrays, track an object' using errcode = '22023';
  end if;
  sid := public.save_attendance(p_centre, p_class, p_date, p_marks);
  delete from public.checks c where c.centre_id = p_centre and c.session_id = sid;
  insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct)
  select p_centre, sid, (c->>'student_id')::uuid, (c->>'skill_id')::uuid, coalesce(c->>'kind', 'check'),
         coalesce(c->'question', '{}'::jsonb), (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  update public.skills s set state = (st->>'state')::public.skill_state, state_at = now()
    from jsonb_array_elements(p_states) st
   where s.centre_id = p_centre and s.id = (st->>'skill_id')::uuid and s.state <> (st->>'state')::public.skill_state;
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
  update public.attendance_sessions a set closed_at = now(), plan_id = v_plan where a.id = sid and a.centre_id = p_centre;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb) to authenticated;

-- 2. The placement taken from the student's page (P10-Placement): its answers as checks of kind 'placement' with no
--    session, the states the app worked out, and the student's stored status, in one write.
create function public.record_placement(p_centre uuid, p_student uuid, p_checks jsonb, p_states jsonb, p_track jsonb)
returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_states) <> 'array' or jsonb_typeof(p_track) <> 'object' then
    raise exception 'checks and states must be arrays, track an object' using errcode = '22023';
  end if;
  insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct)
  select p_centre, null, p_student, (c->>'skill_id')::uuid, 'placement', coalesce(c->'question', '{}'::jsonb),
         (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.student_id = p_student
    and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  update public.skills s set state = (st->>'state')::public.skill_state, state_at = now()
    from jsonb_array_elements(p_states) st
   where s.centre_id = p_centre and s.student_id = p_student and s.id = (st->>'skill_id')::uuid
     and s.state <> (st->>'state')::public.skill_state;
  if p_track ? 'status' then
    update public.students s
       set track_since = case when s.track_status is distinct from p_track->>'status' then now() else s.track_since end,
           track_status = p_track->>'status',
           track_reasons = coalesce(p_track->'reasons', '[]'::jsonb),
           tracked_at = now()
     where s.centre_id = p_centre and s.id = p_student;
  end if;
end $$;

revoke all on function public.record_placement(uuid, uuid, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.record_placement(uuid, uuid, jsonb, jsonb, jsonb) to authenticated;

-- 3. copy_textbook_chapters keeps a tutor's own chapter (no book, no syllabus, no ladder) of the same subject after the
--    book's. The book's chapters it no longer has go first; then the own chapters move behind the book's last chapter,
--    in two steps through a high offset, so the unique (student, subject, position) is never hit mid-update; then the
--    book's rows are written as 0016 wrote them.
create or replace function public.copy_textbook_chapters(p_centre uuid, p_textbook uuid, p_student uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_subject text; v_chapters jsonb; v_last integer;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.subject, t.chapters into v_subject, v_chapters from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_subject is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  select coalesce(max((ch->>'position')::integer), 0) into v_last from jsonb_array_elements(v_chapters) ch;

  -- Chapters: the book's list by position.
  delete from public.chapters c
   where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
     and not exists (select 1 from jsonb_array_elements(v_chapters) ch where (ch->>'position')::integer = c.position);

  -- The student's own chapters of the subject, behind the book's, in their order.
  update public.chapters c set position = c.position + 100000
   where c.centre_id = p_centre and c.student_id = p_student and c.subject = v_subject
     and c.textbook_id is null and c.syllabus_id is null and c.ladder is null;
  update public.chapters c set position = v_last + own.rank
    from (select c2.id, row_number() over (order by c2.position) as rank from public.chapters c2
           where c2.centre_id = p_centre and c2.student_id = p_student and c2.subject = v_subject
             and c2.textbook_id is null and c2.syllabus_id is null and c2.ladder is null) own
   where c.id = own.id;

  update public.chapters c set name = ch->>'name', subject = v_subject
    from jsonb_array_elements(v_chapters) ch
   where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
     and c.position = (ch->>'position')::integer and (c.name, c.subject) is distinct from (ch->>'name', v_subject);
  insert into public.chapters (centre_id, student_id, subject, position, name, textbook_id)
  select p_centre, p_student, v_subject, (ch->>'position')::integer, ch->>'name', p_textbook
    from jsonb_array_elements(v_chapters) ch
   where not exists (select 1 from public.chapters c
                      where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
                        and c.position = (ch->>'position')::integer);

  -- Skills: each chapter's list by position (0016's three statements, unchanged).
  delete from public.skills k
   using public.chapters c
   where k.centre_id = p_centre and k.chapter_id = c.id and c.centre_id = p_centre and c.student_id = p_student
     and c.textbook_id = p_textbook
     and not exists (select 1 from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w where w.chapter_id = k.chapter_id and w.position = k.position);
  update public.skills k set name = w.name
    from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w
   where k.centre_id = p_centre and k.chapter_id = w.chapter_id and k.position = w.position and k.name <> w.name;
  insert into public.skills (centre_id, chapter_id, student_id, position, name)
  select p_centre, w.chapter_id, p_student, w.position, w.name
    from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w
   where not exists (select 1 from public.skills k where k.centre_id = p_centre and k.chapter_id = w.chapter_id and k.position = w.position);
end $$;

-- 4. Keep copies the book to every active student of its school and class (P10-Textbook-Chapters' Keep); the count copied.
create function public.copy_textbook_to_class(p_centre uuid, p_textbook uuid) returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_school uuid; v_class text; v_count integer := 0; r record;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.school_id, t.class_level into v_school, v_class from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_school is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  for r in select s.id from public.students s
            where s.centre_id = p_centre and s.school_id = v_school and s.class_level = v_class and s.archived_at is null
  loop
    perform public.copy_textbook_chapters(p_centre, p_textbook, r.id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

revoke all on function public.copy_textbook_to_class(uuid, uuid) from public, anon;
grant execute on function public.copy_textbook_to_class(uuid, uuid) to authenticated;

-- 5. A student saved with a school and class gets every book of that school and class (the scope's "a later student of
--    the class gets them at add time"); the count of books.
create function public.copy_textbooks_to_student(p_centre uuid, p_student uuid) returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_count integer := 0; r record;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  for r in select t.id from public.textbooks t
             join public.students s on s.centre_id = t.centre_id and s.school_id = t.school_id and s.class_level = t.class_level
            where t.centre_id = p_centre and s.id = p_student
  loop
    perform public.copy_textbook_chapters(p_centre, r.id, p_student);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

revoke all on function public.copy_textbooks_to_student(uuid, uuid) from public, anon;
grant execute on function public.copy_textbooks_to_student(uuid, uuid) to authenticated;
