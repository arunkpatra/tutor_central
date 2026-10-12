-- V3, Phase 17: the recorded call (D76, D84). Every paid call goes through start_ai_call: it serialises the centre's calls,
-- replays a finished call for the same idempotency key within a day, reads the allowance from the centre's own columns,
-- and records the key, the body's hash, the request id, the job and the user. The row gains what the platform reads:
-- cost, latency, prompt hash, stop reason, error reason. Additive: start_ai_generation keeps its signature (build 26's API
-- during the minutes between this migration and the API) as a wrapper over the new gate.

alter table public.ai_generations
  add column cost_paise integer check (cost_paise is null or cost_paise >= 0),
  add column latency_ms integer check (latency_ms is null or latency_ms >= 0),
  add column prompt_version text,
  add column prompt_hash text,
  add column stop_reason text,
  add column error_reason text,
  add column request_id uuid,
  add column job_id uuid references public.jobs(id) on delete set null,
  add column fallback_model text,
  add column idempotency_key text check (idempotency_key is null or char_length(idempotency_key) between 1 and 200),
  add column input_hash text,
  add column finished_at timestamptz,
  add column user_id uuid;
create index ai_generations_key on public.ai_generations (centre_id, idempotency_key, created_at) where idempotency_key is not null;
create index ai_generations_request on public.ai_generations (request_id) where request_id is not null;
create index ai_generations_job on public.ai_generations (job_id) where job_id is not null;

-- The API finishes the row as the user with every field it learnt (0007's grant, extended).
grant update (cost_paise, latency_ms, prompt_version, prompt_hash, stop_reason, error_reason, fallback_model, finished_at)
  on public.ai_generations to authenticated;

-- A row is finished once (the commit review, 2026-10-12): the member's grant above lets the API finish a pending row as
-- the user, and only a pending one; a finished or failed row is final for the member, so a cost already recorded (which
-- the money cap sums) or a status cannot be rewritten from the app. The platform and a session with no request may.
create function public.ai_generations_finish_once() returns trigger language plpgsql set search_path = '' as $$
begin
  if old.status <> 'pending' and coalesce((select auth.jwt() ->> 'role'), '') not in ('service_role', '') then
    raise exception 'ai_row_final' using errcode = '42501';
  end if;
  return new;
end $$;
revoke all on function public.ai_generations_finish_once() from public, anon, authenticated;
create trigger ai_generations_finish_once before update on public.ai_generations
  for each row execute function public.ai_generations_finish_once();

-- The allowance is the centre's (plan decision 9): calls a month for the V2 group, and a money cap in paise (0, none yet;
-- the portal sets it in Phase 22). V1's daily 40 and 20 stay literals until Phase 16 folds V1 into one allowance.
alter table public.centres
  add column ai_allowance integer not null default 600 check (ai_allowance >= 0),
  add column ai_allowance_paise integer not null default 0 check (ai_allowance_paise >= 0);

-- The owner cannot raise them: members update only the columns the app writes (SupabaseCentreRepository, checked
-- 2026-10-12: name, whatsapp_number, upi_id with upi_confirmed_at, payment_link, send_receipts, ai_consent_at). The
-- platform (service role) keeps every column.
revoke update on public.centres from authenticated;
grant update (name, upi_id, upi_confirmed_at, payment_link, send_receipts, whatsapp_number, ai_consent_at)
  on public.centres to authenticated;

-- A row comes through start_ai_call (which sets tc.gate for its transaction), from the platform, or from no request at
-- all (the seed, psql, the tests' fixtures); never from the app's own insert (the reading's W, 2026-10-12).
create function public.ai_generations_gate_only() returns trigger language plpgsql set search_path = '' as $$
begin
  if current_setting('tc.gate', true) is distinct from 'on'
     and coalesce((select auth.jwt() ->> 'role'), '') not in ('service_role', '') then
    raise exception 'ai_insert_through_the_gate' using errcode = '42501';
  end if;
  return new;
end $$;
revoke all on function public.ai_generations_gate_only() from public, anon, authenticated;
create trigger ai_generations_gate before insert on public.ai_generations
  for each row execute function public.ai_generations_gate_only();

-- The gate. Answers { id, replay, status, output }. Two calls of one centre are served in turn: a transaction lock on
-- the centre is taken before the key lookup and the count (D84), so an allowance exactly reached by two calls at once
-- lets one through. An advisory lock rather than `select … for update` on the centre's row: the row lock would need the
-- centre's update policy (the owner's alone) and the platform's calls take it the same way.
create function public.start_ai_call(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
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
    select c.ai_allowance, c.ai_allowance_paise into v_limit, v_paise from public.centres c where c.id = p_centre;
    v_since := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  if v_paise > 0 and (select coalesce(sum(g.cost_paise), 0) from public.ai_generations g
                       where g.centre_id = p_centre and g.created_at >= v_since) >= v_paise then
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

revoke all on function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid) from public, anon;
grant execute on function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid) to authenticated, service_role;

-- Build 26's API, until the new API is deployed minutes later: the same signature, the same gate.
create or replace function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                                      p_student uuid default null)
returns uuid
language sql security invoker set search_path = '' as $$
  select (public.start_ai_call(p_centre, p_kind, p_input, p_model, p_student) ->> 'id')::uuid
$$;

-- The sweep (plan decision 28): a row left pending past its time (a function killed between the call and the finish)
-- is closed as failed, so it stops counting against the hard cap and its key becomes a new call.
create function public.close_pending_generations(p_older_than interval default '10 minutes') returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_count integer;
begin
  update public.ai_generations set status = 'failed', error_reason = 'swept', finished_at = now()
   where status = 'pending' and created_at < now() - p_older_than;
  get diagnostics v_count = row_count;
  return v_count;
end $$;
revoke all on function public.close_pending_generations(interval) from public, anon, authenticated;
grant execute on function public.close_pending_generations(interval) to service_role;
