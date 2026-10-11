-- Phase 13 (docs/spec-v2.md sections 5, 6 and 8; plan/phase-13-plan.md Task 1). Additive (D26): columns with defaults or
-- nullable, one enum value, two functions replaced with one more argument that defaults (build 23's calls resolve), one
-- new function. Nothing from 0001 to 0020 is edited.

-- 1. What the boards show on an item that 0011 did not hold: the title, a holiday's last day, how it reached the app and
--    when (an extension cannot name the sender app, so the words are "Shared", not "from WhatsApp").
alter table public.school_items
  add column title text not null default '' check (char_length(title) <= 120),
  add column end_date date check (end_date is null or end_date >= date),
  add column source text not null default 'typed'
    check (source in ('shared_text', 'shared_photo', 'photo', 'pasted', 'typed')),
  add column received_at timestamptz not null default now();

-- 2. A mark from a marked mock: the exam, the mock and the marks per question (the gap report's input). The exam and the
--    mock may go; the mark stays ("what was already taught stays in the record").
alter table public.marks
  add column school_item_id uuid,
  add column artefact_id uuid,
  add column questions jsonb check (questions is null or jsonb_typeof(questions) = 'array'),
  add foreign key (centre_id, school_item_id) references public.school_items(centre_id, id) on delete set null (school_item_id),
  add foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete set null (artefact_id);

-- 3. Ask parents to forward is logged once per parent (P10-School-Ask's Sent marks).
alter type public.message_kind add value 'forward_ask';

-- 4. keep_artefact links the mock and the gap report to the exam they serve; with no plan it links no line. The
--    six-argument call of build 23 resolves through the default.
drop function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind);

create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, school_item_id, title, content, photo_path,
                                generation_id, regenerated_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_school_item, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb),
          p_artefact->>'photo_path', (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid)
  returning id into v_id;
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid) to authenticated;

-- 5. Marking a paper that names a student needs the student's recorded consent (D62): check_paper with p_student set.
--    V1's call (no student) keeps the centre's consent and its daily rule; 0013's body otherwise unchanged.
drop function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid);

create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                           p_student uuid default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report']::public.ai_kind[];
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
  v_started integer;
  v_since timestamptz;
  v_id uuid;
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  if p_kind = any (v_v1) then
    if p_kind in ('scan_register', 'check_paper', 'progress_note')
       and (select c.ai_consent_at from public.centres c where c.id = p_centre) is null then
      raise exception 'ai_consent_missing';
    end if;
    if p_kind = 'check_paper' and p_student is not null and (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null then
      raise exception 'ai_consent_missing';
    end if;
    if p_kind in ('paper', 'homework', 'worksheet', 'progress_note') then
      v_group := array['paper', 'homework', 'worksheet', 'progress_note']::public.ai_kind[];
      v_limit := 40;
    else
      v_group := array[p_kind];
      v_limit := 20;
    end if;
    v_since := now() - interval '24 hours';
  else
    if p_kind = any (v_personal) and (p_student is null or (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null) then
      raise exception 'ai_consent_missing';
    end if;
    v_group := array['plan', 'sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock', 'note', 'can_do',
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook']::public.ai_kind[];
    v_limit := 600;
    v_since := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) from public, anon;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) to authenticated;

-- 6. A group /ai/plan could not name at the make is named later (plan decision 30): the group's chapter and skill in
--    plans.groups and the teach lines that still read "Teach: with the group"; the artefact links are not touched.
create function public.name_plan_group(p_centre uuid, p_plan uuid, p_group_no integer, p_chapter text, p_skill text)
returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_chapter is null or p_skill is null or char_length(p_skill) = 0 then
    raise exception 'a chapter and a skill are needed' using errcode = '22023';
  end if;
  update public.plans p
     set groups = (
       select coalesce(jsonb_agg(case when (g->>'group_no')::integer = p_group_no
                                      then g || jsonb_build_object('chapter', p_chapter, 'skill', p_skill) else g end), '[]'::jsonb)
         from jsonb_array_elements(p.groups) g)
   where p.centre_id = p_centre and p.id = p_plan;
  update public.plan_items i set words = left('Teach: ' || p_skill, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'teach'
     and i.words = 'Teach: with the group';
  update public.plan_items i set words = left(i.words || ' · then ' || p_skill, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'catch_up'
     and i.words not like '%· then %';
  update public.plan_items i set words = left('Your brief · ' || p_chapter, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'brief'
     and i.words = 'Your brief';
end $$;

revoke all on function public.name_plan_group(uuid, uuid, integer, text, text) from public, anon;
grant execute on function public.name_plan_group(uuid, uuid, integer, text, text) to authenticated;
