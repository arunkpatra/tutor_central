-- Phase 15: material made from Make something (plan/phase-15-plan.md decision 4). Additive (D26): one nullable column; the
-- function gains an eighth parameter with a default, so build 25's seven-argument call still resolves.
alter table public.artefacts
  add column made_from text check (made_from is null or made_from = 'make');

drop function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid);

create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null,
                                     p_made_from text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, school_item_id, title, content, photo_path,
                                generation_id, regenerated_from, made_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_school_item, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb),
          p_artefact->>'photo_path', (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid, p_made_from)
  returning id into v_id;
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text) to authenticated;

create index artefacts_made_from_idx on public.artefacts (centre_id, created_at desc) where made_from = 'make';
