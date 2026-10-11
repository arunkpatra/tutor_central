-- Phase 13 (plan/phase-13-plan.md Task 10's write proof): the app writes plans.groups with PlanGroup's own keys
-- ("number", "memberIDs", …), so name_plan_group (0021) finds the group by "number", else "group_no" (the shape 0021's
-- test wrote). The body is otherwise 0021's; the arguments are the same, so nothing that calls it changes.
create or replace function public.name_plan_group(p_centre uuid, p_plan uuid, p_group_no integer, p_chapter text, p_skill text)
returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_chapter is null or p_skill is null or char_length(p_skill) = 0 then
    raise exception 'a chapter and a skill are needed' using errcode = '22023';
  end if;
  update public.plans p
     set groups = (
       select coalesce(jsonb_agg(case when coalesce(g->>'number', g->>'group_no')::integer = p_group_no
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
