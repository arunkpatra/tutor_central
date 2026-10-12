-- V3, Phase 17: two writes made idempotent (D76, plan decision 15). A made artefact is kept once per key (the app sends
-- its generation's id); a replayed keep answers the first row. The absence log holds one row a child and day, so a
-- replayed queued log is done, not a second message. Additive: keep_artefact gains a ninth parameter with a default, so
-- build 26's eight-argument call (and build 25's seven) still resolves.
--
-- The absence index fails if production already holds two absence logs for one child and day; the deploy's migrate job
-- then stops before the API and nothing changes. The build asked for that count before Deploy 1 (the session's ledger).

alter table public.artefacts add column idempotency_key text check (idempotency_key is null or char_length(idempotency_key) between 1 and 200);
create unique index artefacts_key on public.artefacts (centre_id, idempotency_key) where idempotency_key is not null;

drop function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text);

create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null,
                                     p_made_from text default null, p_key text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  if p_key is not null then
    select a.id into v_id from public.artefacts a where a.centre_id = p_centre and a.idempotency_key = p_key;
    if found then return v_id; end if;
  end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, school_item_id, title, content, photo_path,
                                generation_id, regenerated_from, made_from, idempotency_key)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_school_item, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb),
          p_artefact->>'photo_path', (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid, p_made_from,
          p_key)
  on conflict (centre_id, idempotency_key) where idempotency_key is not null do nothing
  returning id into v_id;
  -- Two keeps of one key at once: the second meets the first's row and answers it.
  if v_id is null then
    select a.id into v_id from public.artefacts a where a.centre_id = p_centre and a.idempotency_key = p_key;
    return v_id;
  end if;
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text, text) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text, text) to authenticated, service_role;

create unique index message_log_one_absence_a_day on public.message_log (centre_id, student_id, about_date) where kind = 'absence';
