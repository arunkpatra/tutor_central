-- Phase 11 review (finding 2): a student moved up a class (class 5 to 6 at the same school) holds the class-5 book's
-- chapters at positions 1..n; copying the class-6 book of the same subject hit the unique (student, subject, position),
-- and Keep for the whole class failed with it. copy_textbook_chapters now moves the student's chapters of the subject from
-- another book behind this book's, before their own chapters, as 0017 moves their own: last year's states and checks stay.
-- Additive (D26): the function is replaced with the same arguments; nothing else changes.

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

  -- The student's chapters of the subject from another book (an earlier class), then their own, behind this book's.
  update public.chapters c set position = c.position + 100000
   where c.centre_id = p_centre and c.student_id = p_student and c.subject = v_subject
     and c.id in (select x.id from public.chapters x where x.centre_id = p_centre and x.student_id = p_student
                  and x.subject = v_subject and x.ladder is null
                  and ((x.textbook_id is null and x.syllabus_id is null) or x.textbook_id <> p_textbook));
  update public.chapters c set position = v_last + own.rank
    from (select c2.id, row_number() over (order by c2.textbook_id is null, c2.position) as rank from public.chapters c2
           where c2.centre_id = p_centre and c2.student_id = p_student and c2.subject = v_subject and c2.ladder is null
             and ((c2.textbook_id is null and c2.syllabus_id is null) or c2.textbook_id <> p_textbook)) own
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
