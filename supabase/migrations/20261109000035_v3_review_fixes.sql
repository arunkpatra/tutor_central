-- V3, Phase 17: the phase's review (D68), in one migration before the phase's first deploy.
--
-- 1. keep_artefact answered by its key still links the plan's lines it is kept to (the app review's finding 1): two
--    batches alike on one day share one made sheet, and each plan's lines take it.
-- 2. No member queues a job (finding 2): nothing in the app asks yet; Phase 18's screens grant what they need, limited to
--    their kinds and the centre's own batches.
-- 3. The money cap holds for every kind and sums the month (finding 5): V1's calls never read it; their counts stay
--    daily, the cap is the month's cost (D76).
-- 4. A call names only its own centre's job (finding 6): the reference is composite, as every centre reference is.
-- 5. A member writes no ai_generations row (finding 7): the API finishes rows as the platform (D83), so a member cannot
--    mark their own pending row failed or free to leave the soft count and the cap.
-- 6. The wakes keep their request open while the worker drains (finding 9): 290 s, under Vercel's 300, so the database
--    sees the answer.

create or replace function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null,
                                     p_made_from text default null, p_key text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  if p_key is not null then
    select a.id into v_id from public.artefacts a where a.centre_id = p_centre and a.idempotency_key = p_key;
  end if;
  if v_id is null then
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
    end if;
  end if;
  -- A keep answered by its key still links this plan's lines: a replayed keep links what it linked, and a second plan
  -- whose material is the same call (two batches alike on one day) takes the one artefact.
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke execute on function public.enqueue_job(uuid, public.job_kind, text, jsonb, timestamptz, integer) from authenticated;

create or replace function public.start_ai_call(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                     p_student uuid default null, p_key text default null, p_input_hash text default null,
                                     p_request_id uuid default null, p_job uuid default null)
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
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('ai_call:' || p_centre::text, 0));

  -- The same key within a day: a finished or pending call answers again; another body is refused; a failed one is new.
  if p_key is not null then
    select g.id, g.status, g.output, g.input_hash into v_prior
      from public.ai_generations g
     where g.centre_id = p_centre and g.idempotency_key = p_key and g.status <> 'failed'
       and g.created_at >= now() - interval '24 hours'
     order by g.created_at desc limit 1;
    if found then
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
    select c.ai_allowance into v_limit from public.centres c where c.id = p_centre;
    v_since := v_month;
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  select c.ai_allowance_paise into v_paise from public.centres c where c.id = p_centre;
  if v_paise > 0 and (select coalesce(sum(g.cost_paise), 0) from public.ai_generations g
                       where g.centre_id = p_centre and g.created_at >= v_month) >= v_paise then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;

  perform set_config('tc.gate', 'on', true);
  insert into public.ai_generations (centre_id, kind, input, model, status, student_id, idempotency_key, input_hash,
                                     request_id, job_id, user_id)
  values (p_centre, p_kind, p_input, p_model, 'pending', p_student, p_key, p_input_hash, p_request_id, p_job, auth.uid())
  returning id into v_id;
  perform set_config('tc.gate', 'off', true);
  return jsonb_build_object('id', v_id, 'replay', false, 'status', 'pending', 'output', null);
end $$;

alter table public.ai_generations drop constraint ai_generations_job_id_fkey;
alter table public.ai_generations add constraint ai_generations_job_fkey
  foreign key (centre_id, job_id) references public.jobs (centre_id, id) on delete set null (job_id);

revoke update on public.ai_generations from authenticated;

create or replace function public.wake_worker() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return new; end if;
  perform net.http_post(
    url := v_url || '/jobs/wake',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_secret),
    body := jsonb_build_object('job', new.id),
    timeout_milliseconds := 290000);
  return new;
exception when others then
  return new;
end $$;

create or replace function public.wake_worker_tick() returns void language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_get(url := v_url || '/jobs/tick', headers := jsonb_build_object('Authorization', 'Bearer ' || v_secret),
                       timeout_milliseconds := 290000);
end $$;
