-- Phase 12 (docs/spec-v2.md section 6; plan/phase-12-plan.md Task 1). Additive (D26): two columns on classes, two on
-- plan_items, two new functions, close_session replaced with a ninth argument that defaults, so build 20's
-- eight-argument call still resolves. Nothing from 0001 to 0018 is edited.

-- 1. The batch's kept choices (P10-Today-Plan-Change): how many groups, and the subjects per weekday ("Keep this for
--    Wednesdays"). plan_pattern: {"<iso weekday 1..7>": {"groups": n, "subjects": ["Science", "Mathematics"]}}.
alter table public.classes
  add column plan_groups integer check (plan_groups is null or plan_groups between 1 and 3),
  add column plan_pattern jsonb not null default '{}'::jsonb check (jsonb_typeof(plan_pattern) = 'object');

-- 2. A line skipped today, a student moved from another group (both for today only).
alter table public.plan_items
  add column skipped_at timestamptz,
  add column moved_from integer check (moved_from is null or moved_from between 1 and 9),
  add column words text not null default '' check (char_length(words) <= 200);

-- 3. The day's plan for a batch in one write: the plan row made or replaced (plans_one_per_day), its items replaced.
--    p_groups  [{"group_no", "subject", "chapter", "skill"}] (kept as made, for the cards)
--    p_subjects {"<group_no>": "<subject>"}
--    p_items   [{"student_id"?, "group_no", "kind", "skill_id"?, "words"}]
--    Answers {"plan_id", "items": [{"id", "student_id", "group_no", "kind"}]} so the app links artefacts by item.
create function public.make_plan(p_centre uuid, p_class uuid, p_date date, p_groups jsonb, p_subjects jsonb, p_items jsonb)
returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare v_plan uuid; v_items jsonb;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_groups) <> 'array' or jsonb_typeof(p_subjects) <> 'object' or jsonb_typeof(p_items) <> 'array' then
    raise exception 'groups and items must be arrays, subjects an object' using errcode = '22023';
  end if;
  insert into public.plans (centre_id, class_id, date, made_at, groups, subjects)
  values (p_centre, p_class, p_date, now(), p_groups, p_subjects)
  on conflict (centre_id, class_id, date) do update
    set made_at = now(), groups = excluded.groups, subjects = excluded.subjects
  returning id into v_plan;
  delete from public.plan_items i where i.centre_id = p_centre and i.plan_id = v_plan;
  with written as (
    insert into public.plan_items (centre_id, plan_id, student_id, group_no, kind, skill_id, words)
    select p_centre, v_plan, (i->>'student_id')::uuid, (i->>'group_no')::integer, (i->>'kind')::public.plan_item_kind,
           (i->>'skill_id')::uuid, coalesce(i->>'words', '')
    from jsonb_array_elements(p_items) i
    returning id, student_id, group_no, kind
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', w.id, 'student_id', w.student_id, 'group_no', w.group_no, 'kind', w.kind)), '[]'::jsonb)
    into v_items from written w;
  return jsonb_build_object('plan_id', v_plan, 'items', v_items);
end $$;

revoke all on function public.make_plan(uuid, uuid, date, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.make_plan(uuid, uuid, date, jsonb, jsonb, jsonb) to authenticated;

-- 4. An artefact kept with the plan and linked to the lines it serves, in one write: the group's items of the kind
--    (p_student null) or one student's item (p_student set). A regenerate names regenerated_from; the old row stays.
--    p_artefact {"kind", "source"?, "title", "content", "photo_path"?, "generation_id"?, "regenerated_from"?}
create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, title, content, photo_path, generation_id, regenerated_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb), p_artefact->>'photo_path',
          (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid)
  returning id into v_id;
  update public.plan_items i set artefact_id = v_id
   where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
     and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind) to authenticated;

-- 5. The close also marks the plan's lines the tutor ticked (P10-Close's checklist): p_done, the item ids. The
--    eight-argument call of build 20 still resolves through the default.
drop function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb);

create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb, p_states jsonb default '[]'::jsonb,
                                     p_done uuid[] default '{}') returns uuid
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
  update public.plan_items i set done_at = now()
   where i.centre_id = p_centre and i.plan_id = v_plan and i.id = any (p_done) and i.done_at is null;
  update public.attendance_sessions a set closed_at = now(), plan_id = v_plan where a.id = sid and a.centre_id = p_centre;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb, uuid[]) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb, uuid[]) to authenticated;
