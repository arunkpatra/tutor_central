-- Phase 15's review (plan/sessions/032/ledger.md, R-web-1 and R-web-3). What was written about a student goes with the
-- student: ai_generations names the student a call was about (written by start_ai_generation; the rows before this read
-- from their input) and is deleted with them; message_log's rows, which keep the words sent, are deleted with the student
-- instead of keeping them under no one. A V1 progress note now needs the parent's consent (D62). Additive: one column, one
-- index; the foreign key re-made with its new delete rule; start_ai_generation replaced with the same signature, 0024's
-- body otherwise unchanged.

alter table public.ai_generations add column student_id uuid;
alter table public.ai_generations
  add constraint ai_generations_centre_id_student_id_fkey foreign key (centre_id, student_id)
  references public.students (centre_id, id) on delete cascade;
create index ai_generations_student on public.ai_generations (student_id) where student_id is not null;

update public.ai_generations g
   set student_id = (g.input ->> 'studentId')::uuid
 where g.input ->> 'studentId' ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
   and exists (select 1 from public.students s where s.id = (g.input ->> 'studentId')::uuid and s.centre_id = g.centre_id);

alter table public.message_log drop constraint message_log_centre_id_student_id_fkey;
alter table public.message_log
  add constraint message_log_centre_id_student_id_fkey foreign key (centre_id, student_id)
  references public.students (centre_id, id) on delete cascade;

create or replace function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                                      p_student uuid default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report', 'not_on_track', 'read_marks']::public.ai_kind[];
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
    -- A progress note is about one student: it needs their parent's consent, as the V2 note does (D62).
    if p_kind = 'progress_note' and (p_student is null or (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null) then
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
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook', 'not_on_track', 'read_marks']::public.ai_kind[];
    v_limit := 600;
    v_since := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status, student_id)
  values (p_centre, p_kind, p_input, p_model, 'pending', p_student)
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) from public, anon;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) to authenticated;

