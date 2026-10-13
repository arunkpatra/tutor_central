-- V3, Phase 20 (D73, D99, D100, D101): the model per kind of AI work and step (draft, check, repair) in the database,
-- seeded from api/models.json, append-only (the current row of a kind and step is the newest `since`), read by the
-- platform alone; Phase 22's portal writes it. A call's agent step and cached tokens; only a draft counts against the
-- allowance, every row against the cost. The nightly evals' schedule. The portal's calls carry the step.

create table public.ai_models (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (char_length(kind) between 1 and 40),
  step text not null check (step in ('draft', 'check', 'repair')),
  model text not null check (char_length(model) between 1 and 60),
  effort text not null check (effort in ('low', 'medium', 'high')),
  fallback_model text check (fallback_model is null or char_length(fallback_model) between 1 and 60),
  enabled boolean not null default true,
  since timestamptz not null default now(),
  set_by text not null default 'seed' check (char_length(set_by) between 1 and 200),
  note text check (note is null or char_length(note) <= 400),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_models_current_idx on public.ai_models (kind, step, since desc);
create trigger ai_models_updated before update on public.ai_models for each row execute function public.set_updated_at();
alter table public.ai_models enable row level security;
-- No member reads it (as admin_users): a select answers nothing rather than an error.
create policy ai_models_platform_only on public.ai_models for select to authenticated using (false);
revoke insert, update, delete, truncate on public.ai_models from anon, authenticated;
revoke update, delete, truncate on public.ai_models from service_role;

-- The newest row per kind and step.
create function public.ai_models_current()
returns table (kind text, step text, model text, effort text, fallback_model text, enabled boolean, since timestamptz)
language sql stable security invoker set search_path = '' as $$
  select distinct on (m.kind, m.step) m.kind, m.step, m.model, m.effort, m.fallback_model, m.enabled, m.since
    from public.ai_models m order by m.kind, m.step, m.since desc
$$;
revoke all on function public.ai_models_current() from public, anon, authenticated;
grant execute on function public.ai_models_current() to service_role;

alter table public.ai_generations
  add column agent_step text not null default 'draft' check (agent_step in ('draft', 'check', 'repair', 'grade')),
  add column tokens_cached integer check (tokens_cached is null or tokens_cached >= 0);

-- The seed: the draft on the file's model, the check on the other tier (Haiku 5.5 checks Sonnet 5.5, Sonnet 5.5 checks
-- Haiku 5.5 and Opus 5.5), the repair on the draft's; each falls back to the other tier. As of 0052; a test holds the
-- rows equal to api/models.json.
insert into public.ai_models (kind, step, model, effort, fallback_model, note) values
  ('paper', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('paper', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('paper', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('homework', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('homework', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('homework', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('worksheet', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('worksheet', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('worksheet', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('progress_note', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('progress_note', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('progress_note', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('scan_register', 'draft', 'claude-opus-5-5', 'high', 'claude-sonnet-5-5', '0052'),
  ('scan_register', 'check', 'claude-sonnet-5-5', 'medium', 'claude-opus-5-5', '0052'),
  ('scan_register', 'repair', 'claude-opus-5-5', 'high', 'claude-sonnet-5-5', '0052'),
  ('check_paper', 'draft', 'claude-opus-5-5', 'high', 'claude-sonnet-5-5', '0052'),
  ('check_paper', 'check', 'claude-sonnet-5-5', 'medium', 'claude-opus-5-5', '0052'),
  ('check_paper', 'repair', 'claude-opus-5-5', 'high', 'claude-sonnet-5-5', '0052'),
  ('plan', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('plan', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('plan', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('sheet_to_5', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('sheet_to_5', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('sheet_to_5', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('sheet_from_6', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('sheet_from_6', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('sheet_from_6', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('worked_example', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('worked_example', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('worked_example', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('figure', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('figure', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('figure', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('brief', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('brief', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('brief', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('mock', 'draft', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0052'),
  ('mock', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('mock', 'repair', 'claude-sonnet-5-5', 'high', 'claude-haiku-5-5', '0052'),
  ('gap_report', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('gap_report', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('gap_report', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('parse_school', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('parse_school', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('parse_school', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('parse_textbook', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('parse_textbook', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('parse_textbook', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('check', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('check', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('check', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('placement', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('placement', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('placement', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('note', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('note', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('note', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('can_do', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('can_do', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('can_do', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('test_tomorrow', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('test_tomorrow', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('test_tomorrow', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('not_on_track', 'draft', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('not_on_track', 'check', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('not_on_track', 'repair', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('read_marks', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('read_marks', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('read_marks', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052');

-- start_ai_call takes the call's agent step; the allowance counts drafts alone (a check and a repair are the platform's
-- guard, not the tutor's use), the cost every row. 0035's body otherwise. The old signature goes: PostgREST resolves a
-- function by its argument names, and only the API calls it. A step other than a draft must name its draft by its key.
drop function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid);
create function public.start_ai_call(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
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
  values (p_centre, p_kind, p_input, p_model, 'pending', p_student, p_key, p_input_hash, p_request_id, p_job, auth.uid(),
          p_agent_step)
  returning id into v_id;
  perform set_config('tc.gate', 'off', true);
  return jsonb_build_object('id', v_id, 'replay', false, 'status', 'pending', 'output', null);
end $$;
revoke all on function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid, text) from public, anon;
grant execute on function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid, text) to authenticated, service_role;

-- The nightly evals: one eval_run job for India's day at 02:00 there, no centre (the runner records its calls under the
-- Smoke centre). pg_cron runs it at 20:35 UTC, 02:05 in India; the function names the day by India's clock.
create function public.schedule_evals(p_now timestamptz default now())
returns integer language plpgsql security invoker set search_path = '' as $$
declare
  v_day date := (p_now at time zone 'Asia/Kolkata')::date;
  v_count integer;
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input, run_at)
  values (null, 'eval_run', 'evals:' || v_day, jsonb_build_object('day', v_day), (v_day + time '02:00') at time zone 'Asia/Kolkata')
  on conflict do nothing;
  get diagnostics v_count = row_count;
  perform set_config('tc.jobs', 'off', true);
  return v_count;
end $$;
revoke all on function public.schedule_evals(timestamptz) from public, anon, authenticated;
grant execute on function public.schedule_evals(timestamptz) to service_role;
select cron.schedule('schedule_evals', '35 20 * * *', 'select public.schedule_evals()');

-- The portal: the nightly evals' job is named; a call's row (the list and the page) carries its agent step.
create or replace function public.admin_job_subject(p_kind public.job_kind, p_input jsonb, p_key text)
returns text language sql stable security invoker set search_path = '' as $$
  select case
    when p_kind in ('plan', 'note_day') and p_input ? 'class_id' then
      coalesce((select c.name from public.classes c where c.id = (p_input ->> 'class_id')::uuid), 'a batch')
        || coalesce(' · ' || to_char((p_input ->> 'date')::date, 'FMDD Mon'), '')
    when p_kind in ('note_day', 'export') then 'a student'
    when p_kind = 'pdf' then
      coalesce((select a.title from public.artefacts a where a.id = (p_input ->> 'artefact_id')::uuid), 'a file')
    when p_kind = 'reminder_sweep' then case when p_key ~ 'T[0-9]{2}$' then 'hourly' else 'after a change' end
    when p_kind in ('sweep', 'alerts') then 'every 10 minutes'
    when p_kind = 'eval_run' then 'nightly evals'
    else null
  end;
$$;

create or replace function public.admin_call_row(p_id uuid)
returns jsonb language sql stable security invoker set search_path = '' as $$
  select jsonb_build_object(
    'id', g.id, 'created_at', g.created_at, 'centre_id', g.centre_id,
    'centre', (select c.name from public.centres c where c.id = g.centre_id),
    'kind', g.kind, 'model', g.model, 'prompt_version', g.prompt_version, 'status', g.status, 'error_reason', g.error_reason,
    'tokens_in', g.tokens_in, 'tokens_out', g.tokens_out, 'latency_ms', g.latency_ms, 'cost_paise', g.cost_paise,
    'agent_step', g.agent_step, 'tokens_cached', g.tokens_cached,
    'student', g.student_id is not null,
    'started_by', case when g.job_id is not null then 'job ' || coalesce((select j.kind::text from public.jobs j where j.id = g.job_id), 'gone')
                       when g.idempotency_key like 'smoke-%' then 'deploy' else 'tap' end)
    from public.ai_generations g where g.id = p_id;
$$;
