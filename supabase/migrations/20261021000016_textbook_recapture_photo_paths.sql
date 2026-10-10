-- Phase 10's review (session 22): two functions of migrations 0009 and 0011 replaced; those files are not edited.
--
-- 1. copy_textbook_chapters keeps a student's progress when the book is captured again. It used to delete the student's
--    chapters from the book and insert them anew, and the cascade took the skill states and the checks with them.
--    Now a chapter is matched by its position in the book and a skill by its position in the chapter: names follow the
--    book, states, last_checked_at and checks stay; a chapter or skill the book no longer has is removed.
-- 2. photo_centre reads the centre's id in any case (Swift writes a UUID in capitals) and is stable, not immutable
--    (storage.foldername is not immutable). Photos stay add-only: there is no update policy, so an upload over an
--    existing path, a move or a copy is refused; a new photo takes a new path.

create or replace function public.copy_textbook_chapters(p_centre uuid, p_textbook uuid, p_student uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_subject text; v_chapters jsonb;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.subject, t.chapters into v_subject, v_chapters from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_subject is null then raise exception 'no such textbook' using errcode = '22023'; end if;

  -- Chapters: the book's list by position.
  delete from public.chapters c
   where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
     and not exists (select 1 from jsonb_array_elements(v_chapters) ch where (ch->>'position')::integer = c.position);
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

  -- Skills: each chapter's list by position (the same list, "wanted", in each of the three statements).
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

create or replace function public.photo_centre(p_name text) returns uuid
language sql stable set search_path = '' as $$
  select case when (storage.foldername(p_name))[1] ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
              then ((storage.foldername(p_name))[1])::uuid end
$$;
