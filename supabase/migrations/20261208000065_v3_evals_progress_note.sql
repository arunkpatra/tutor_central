-- V3, Phase 21 (the review, R-api-3): the nightly's progress_note cases were refused at the gate (0063 let the platform's own
-- eval_run job start the V2 parents' kinds with no student, but the V1 progress note kept 0055's rule), so a run naming
-- progress_note could never pass. The eval_run job starts a progress note with no student too. The rest is 0063's.
create or replace function public.start_ai_call(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                     p_student uuid default null, p_key text default null, p_input_hash text default null,
                                     p_request_id uuid default null, p_job uuid default null, p_agent_step text default 'draft')
returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report', 'not_on_track', 'read_marks']::public.ai_kind[];
  v_group public.ai_kind[];
  v_limit integer;
  v_paise integer := 0;
  v_count integer;
  v_started integer;
  v_since timestamptz;
  v_month timestamptz := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  v_prior record;
  v_id uuid;
  v_root text := regexp_replace(p_key, ':(check|repair|repair:check|grade)$', '');
  -- The platform's own nightly (its eval_run job has no centre, so the row names no job: the reference is the centre's).
  v_evals boolean := coalesce((select auth.jwt() ->> 'role'), '') = 'service_role'
    and exists (select 1 from public.jobs j where j.id = p_job and j.kind = 'eval_run' and j.centre_id is null);
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('ai_call:' || p_centre::text, 0));

  -- A check, repair or grade guards a draft already allowed, so it is not counted; it must hang off one: its key is the
  -- draft's with `:check`, `:repair`, `:repair:check` or `:grade` after it (a key replays its own row, so a draft has four at
  -- most), a draft of this centre within a day.
  if p_agent_step <> 'draft' and (p_key is null or v_root = p_key or not exists (
       select 1 from public.ai_generations g
        where g.centre_id = p_centre and g.idempotency_key = v_root and g.agent_step = 'draft'
          and g.created_at >= now() - interval '24 hours')) then
    raise exception 'ai_step_orphan';
  end if;

  -- The same key within a day: a finished or pending call answers again; another body is refused; a failed one is new.
  if p_key is not null then
    select g.id, g.status, g.output, g.input_hash into v_prior
      from public.ai_generations g
     where g.centre_id = p_centre and g.idempotency_key = p_key and g.status <> 'failed'
       and g.created_at >= now() - interval '24 hours'
     order by g.created_at desc limit 1;
    -- A check, repair or grade under a key whose row was for another draft (the step taken again after a lost function
    -- made a new draft under the same key) is a new row, not a reuse: its hash names the draft it guards.
    if found and not (p_agent_step <> 'draft' and v_prior.input_hash is distinct from p_input_hash) then
      if v_prior.input_hash is distinct from p_input_hash then
        raise exception 'ai_key_reused';
      end if;
      return jsonb_build_object('id', v_prior.id, 'replay', true, 'status', v_prior.status, 'output', v_prior.output);
    end if;
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
    -- A progress note is about one student: it needs their parent's consent, as the V2 note does (D62); the platform's own
    -- eval_run job starts a golden case with none (0065).
    if p_kind = 'progress_note' and not (v_evals and p_student is null) and (p_student is null or (
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
    -- The nightly's golden cases name no real student (invented, the seed's names): the platform's own eval_run job starts a
    -- parent's-message kind with none; every other call names a student with consent.
    if p_kind = any (v_personal) and not (v_evals and p_student is null) and (p_student is null or (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null) then
      raise exception 'ai_consent_missing';
    end if;
    v_group := array['plan', 'sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock', 'note', 'can_do',
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook', 'not_on_track', 'read_marks']::public.ai_kind[];
    select c.ai_allowance into v_limit from public.centres c where c.id = p_centre;
    v_since := v_month;
  end if;
  -- A check, repair or grade is never refused by the count: it guards a draft already allowed.
  if p_agent_step = 'draft' then
    select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
      from public.ai_generations g
     where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since and g.agent_step = 'draft';
    if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
      raise exception 'ai_limit_reached' using detail = v_limit::text;
    end if;
  end if;
  select c.ai_allowance_paise into v_paise from public.centres c where c.id = p_centre;
  if v_paise > 0 and (select coalesce(sum(g.cost_paise), 0) from public.ai_generations g
                       where g.centre_id = p_centre and g.created_at >= v_month) >= v_paise then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;

  perform set_config('tc.gate', 'on', true);
  insert into public.ai_generations (centre_id, kind, input, model, status, student_id, idempotency_key, input_hash,
                                     request_id, job_id, user_id, agent_step)
  values (p_centre, p_kind, p_input, p_model, 'pending', p_student, p_key, p_input_hash, p_request_id,
          case when v_evals then null else p_job end, auth.uid(),
          p_agent_step)
  returning id into v_id;
  perform set_config('tc.gate', 'off', true);
  return jsonb_build_object('id', v_id, 'replay', false, 'status', 'pending', 'output', null);
end $$;
