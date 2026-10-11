-- Phase 14 (plan/phase-14-plan.md Task 16). The tutor's next step belongs to the status it was chosen for: a student whose
-- track_status changes has next_step set to null, so the plan takes its own step again. One trigger covers the close
-- (close_session), the placement and a close sent later from the queue; an update that sets the step with the status
-- keeps the step it sets.
create function public.clear_next_step_on_status() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if new.track_status is distinct from old.track_status and new.next_step is not distinct from old.next_step then
    new.next_step := null;
  end if;
  return new;
end;
$$;

create trigger students_clear_next_step
  before update of track_status on public.students
  for each row execute function public.clear_next_step_on_status();
