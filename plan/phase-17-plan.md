# Phase 17 plan: V3 platform foundation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-12 (session 34, Fable 5.1) from `phase-17-platform-foundation.md`, `docs/spec-v3.md` (sections 3, 7, 9, 12),
`docs/v3/interview.md` ("What the reading found"), the Phase 18 and 19 scope files (what builds on these tables) and the
code as it is. Shown whole to the owner for approval; its one question is under "Owner's question". The build runs on Opus
5.5 from `resume/033-phase-17-build.md`, inline, task by task, with one ledger (`plan/sessions/035/ledger.md`) as sessions
22 to 32 kept. Nothing new on screen (D6): no board waits on this phase and no pull request carries pictures.

**Goal:** the backend becomes the platform. A job can run on the server with its state in Postgres and survive the phone,
the function and the deploy; a paid call is recorded once with what it cost and a retry of it is free; the centre's
allowance is a column the owner cannot raise and the gate cannot be passed by two calls at once; what happens is written in
our own tables; a limit lives once and the app and the API are held to it by generated types; the deploy refuses a commit
whose check is not green and proves the real model with one call; the database has been restored once into a scratch
project. The seed centre's plan is made by a job and read by the app.

**Architecture:** `jobs` and `job_steps` are the truth (D71); a Hono worker in the same API function takes a lease with
`for update skip locked`, does one step, writes the row and the step, and continues while its time budget allows; pg_cron
inside the database wakes it each minute through `pg_net`, and a trigger wakes it the moment a job is queued (D85: no
Vercel Cron, no paid plan this phase). The platform's identity is Supabase's
service role key, in Vercel's environment only (decision 1); `is_member` answers true for it, so the functions the app uses
(`make_plan`, `keep_artefact`, `start_ai_call`) serve the worker unchanged. Every paid call goes through `start_ai_call`,
which locks the centre's row, replays a finished call for the same idempotency key within a day, reads the allowance from
`centres.ai_allowance`, and records cost, latency, prompt hash, stop reason, request id and job on `ai_generations`. The
app adds two headers to every AI call (the key and a request id), posts its activity in batches to `events`, and treats
the absence log and a made artefact's keep as idempotent. `tools/contract.ts` generates the API's database types from
`supabase/types.ts` and the app's limits and the fakes' sample answers from the API's schemas; `bun check` fails on drift.
`deploy.yml` gains a gate (a green `check` for the commit) and a smoke that signs in as a smoke account and makes one
`check` on the real model. The plan rules move to TypeScript, proven equal to Domain's by one shared case file, so the
`plan` job can group and name a batch and write its plan; the artefacts stay the phone's `complete()` until Phase 18.

**Tech stack:** as Phase 15 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI 2.120.0, Postgres 17, Bun 1.3.11;
Hono 4.13.13, zod 4.6.5, `@anthropic-ai/sdk` 0.132.1, `@supabase/supabase-js` 2.117.2; XcodeGen) plus the Postgres
extensions `pg_cron`, `pg_net` and `supabase_vault` (all three ship with Supabase, local and hosted, Free included).
Vercel Hobby's 300 s functions. No new package dependency, no paid plan (D85).

**Spec:** `docs/spec-v3.md` sections 3 (jobs), 7 (robustness), 9 (observability), 12 (process), 13 (cost), 15 (D70 to
D82); the scope `plan/phase-17-platform-foundation.md` (items 1 to 8, the acceptance); `plan/phase-18-server-work-and-push.md`
and `plan/phase-19-admin-portal-reading.md` (the readers of these tables); `docs/v3/interview.md` "What the reading found"
(each **W** this phase closes is named in its task); `plan/sessions/033/research.md` (the sources); `plan/sessions/032/ledger.md`
(the double spends and the faults the keys remove).

## Global constraints

- Nothing a tutor sees changes (D6, D69); a pull request that would change a screen stops and asks. `ErrorWordsTests`
  still bans technical words in the app's sources (D41); the API's new refusals carry words from `docs/design/feedback.md`
  or map to words the app already has.
- Every migration is additive (D26): build 26's calls (`start_ai_generation` with five arguments, `keep_artefact` with
  eight, every table it reads) keep resolving; a replaced function keeps its signature or gains a defaulted parameter;
  `types.ts` regenerated and committed with each migration. Migrations reach production only through `deploy.yml`.
- Every new table: `id`, `created_at`, `updated_at` with `set_updated_at`, RLS enabled, at least one policy, a line in
  `rls.test.ts`'s catalogue, writes granted only to who writes it (the 0001 blanket grant does not reach new tables, but
  Supabase's default privileges grant `authenticated` on them: each migration revokes what the app may not do). `centre_id`
  on every table about a centre; the three exceptions and their reasons are decision 3 and go into `supabase/CLAUDE.md`.
- Functions: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, an explicit grant. The two
  `security definer` functions become three (`wake_worker` reads Vault; decision 6), named in `supabase/CLAUDE.md` beside D37.
- No secret in the repository or the app (D11): the service role key, `WORKER_SECRET`, the smoke account's password live in
  Vercel's environment, GitHub's `Production` environment and Vault; `api/.env.local` holds the local stack's.
- No tutor's name, email or number in the repository (D55): the smoke account's email is a secret; the owner's centre is
  named by his email at the workflow's prompt, never in a file.
- Bun only (D16); dependencies pinned (D14); no new dependency (none is needed); `bun check` before every commit; one change
  per pull request; code reaches `main` through a green pull request; documents go to `main` directly (D12).
- Real AI calls in testing are allowed without asking (the owner's standing approval); this phase's are the smoke (one
  `check` on Haiku per deploy, about ₹0.05), the production plan run (one `plan` naming call, about ₹0.35) and the hand
  runs' three calls: under ₹5, recorded in the ledger.
- D68: a fault this phase finds, this phase fixes before it closes.

## Decisions this plan takes

Small and medium decisions, written here so they are not re-decided. Two become numbered decisions in `plan/README.md`
with the approval commit (D83, D84); the owner's ruling on the paid plans is D85 (below).

1. **The job key is Supabase's service role (D83).** Weighed: (a) the service role key: already exists, supabase-js takes
   it, bypasses RLS, one secret to hold, Supabase's own supported server identity; (b) a dedicated Postgres role: least
   privilege, but PostgREST needs a JWT minted for it (the project's legacy JWT secret, a second secret to hold and rotate)
   or a direct connection through the pooler (a new dependency, D14, and a password), and every existing function's
   membership check would still need a clause for it. The functions the worker calls (`make_plan`, `name_plan_group`,
   `keep_artefact`, `start_ai_call`) check `is_member`, which reads `auth.uid()`; a worker has none. So: the service role,
   and `is_member(c)` answers true when the request's role claim is `service_role` (decision 2). The blast radius is
   bounded in code: the worker reaches the database only through named functions (`api/src/jobs/db.ts`; a test greps the
   module for `.from(` and finds none), every job function takes the centre from the job's own row, never from a request,
   and the key is read in `index.ts` alone and handed to the worker's and the observability client, never to the tutor
   routes' `Db`. Phase 19's portal holds the same key on its server (D78). A dedicated role gets a new number if a second
   server identity ever appears.
2. **`is_member`'s platform clause:** `(select auth.jwt() ->> 'role') = 'service_role' or exists (…)`. The claim is
   PostgREST's `request.jwt.claims`, set per request and unchanged by `security definer`; `psql` and the seed have no claim
   and read false, as today. Tested: the service client calls `make_plan` for the seed centre and succeeds; a member's call
   for another centre still fails.
3. **Three tables without `centre_id` as rule 6 means it,** each with its reason in `supabase/CLAUDE.md`: `jobs.centre_id`
   is nullable for the platform's own kinds (`sweep`, `eval_run`; a check constraint holds every other kind to a centre),
   `device_tokens` is keyed by the user like `profiles` (D72: per user and device), and `api_requests.centre_id`,
   `alerts.centre_id`, `admin_audit.centre_id` are nullable (a 401 names no centre; an alarm or an admin's action may be
   the platform's). `job_steps` carries `centre_id` from its job.
4. **Leases, attempts and backoff.** A claim is an attempt (`attempts + 1`); the lease is 180 s and the worker extends it
   before each step while it holds the job; a write by a worker that no longer holds the lease (`leased_by` differs, or the
   state is no longer `running`) raises `job_lease_lost` or `job_cancelled` and that worker stops; a lease past its time is
   retaken by the next claim; a job retried after a failure waits 30 s × 2^(attempts − 1), at most 10 minutes; past
   `max_attempts` (3 by default, at most 10) it is `failed` with its last error. A step is small enough to finish in one
   run; a job that needs the next wake goes `waiting` with the step reached in `jobs.step`.
5. **The function's time.** `vercel.json` sets `maxDuration` 300 (Hobby's ceiling with Fluid compute) on the one
   function; the worker's run budget is 200 s (`JOB_RUN_BUDGET_MS`), so the step in flight (bounded by its own deadline: a
   Claude call's 110 s, plus its writes) always finishes before Vercel's limit; a run that reaches its budget leaves the
   rest to the next wake, a minute away at most. The pattern under `functions` is checked after `vercel build` in
   `.vercel/output/functions/*/.vc-config.json` (the file names the duration it took). On Pro, later, the two numbers
   rise together.
6. **Two wakes from inside the database, one secret.** A pg_cron job `wake_worker_minute` (`* * * * *`) calls
   `public.wake_worker_tick()`, which reads `worker_url` and `worker_secret` from Vault and makes `net.http_get(<url>/jobs/tick)`
   with `Authorization: Bearer <secret>`; `wake_worker()`, an `after insert` trigger on `jobs`, posts to `POST /jobs/wake`
   the same way. Both do nothing when the secrets are absent (the local stack without them; the tests). `deploy.yml` writes
   the two Vault secrets on every deploy from the `Production` environment's `WORKER_SECRET` and the `API_ORIGIN` variable,
   so nothing is typed by hand. The two functions are `security definer` because `vault.decrypted_secrets` is readable by
   `postgres` alone; the reason is in their migration. pg_cron carries Phase 18's schedules too, so the platform has one
   scheduler; Vercel Cron is not used (D85).
7. **Idempotency keys (D84).** The app sends `Idempotency-Key` with every AI call (at most 200 characters). The key is
   deterministic by default, `tc-` and the SHA-256 of the route and the body's bytes (the body encoded with sorted keys),
   so a repeat of the same request within a day (a second open, a replayed run, a retry) costs nothing and answers the
   same; a screen whose meaning is "another one" (V1's Create again from History) sends a fresh UUID. The API accepts a
   missing header this phase (build 26 sends none) and then replays nothing. A key with a finished row answers that row's
   `{ id, result }` with `Idempotent-Replayed: true` and no new row; a key whose row is still pending answers 409 `reason:
   "in_progress"` (the app shows its timed-out words); a key reused with a different body (the body's hash differs) answers
   409 `reason: "key_reused"` (the app shows its service words); a key whose row failed is a new call. A job step's key is
   `<job id>:<step>`, so a step retaken after a lost lease replays the paid call rather than paying again.
8. **The gate.** `start_ai_call(p_centre, p_kind, p_input, p_model, p_student, p_key, p_input_hash, p_request_id, p_job)`
   returns jsonb `{ id, replay, status, output }`; it locks the centre's row (`select … for update`) before the key lookup
   and the count, so two calls at once are served in turn. `start_ai_generation` keeps its signature as a wrapper over it
   (build 26's API during the minutes between the migration and the API). A `before insert` trigger on `ai_generations`
   refuses a row that did not come through the gate (`current_setting('tc.gate', true) = 'on'`, set by the function for
   the transaction) unless the request is the platform's or there is no request at all (the seed, `psql`, the tests'
   fixtures): closes the reading's **W** "a table-wide INSERT grant lets a row bypass the gate".
9. **The allowance.** `centres.ai_allowance integer not null default 600` and `ai_allowance_paise integer not null default
   0` (0 means no money cap yet; the portal sets it in Phase 22); the gate reads them for the V2 group; V1's daily 40 and 20
   stay literals until Phase 16 folds V1 into the one allowance. The owner cannot raise them: `revoke update on centres from
   authenticated; grant update (name, upi_id, upi_confirmed_at, payment_link, send_receipts, whatsapp_number,
   ai_consent_at) on centres to authenticated` (the columns the app updates, each confirmed against the Swift update sites
   at build time; `currency` is not among them). The service role sets them.
10. **The enriched row.** `ai_generations` gains `cost_paise integer`, `latency_ms integer`, `prompt_version text`,
    `prompt_hash text`, `stop_reason text`, `error_reason text`, `request_id uuid`, `job_id uuid` (to `jobs`, on delete set
    null), `fallback_model text`, `idempotency_key text`, `input_hash text`, `finished_at timestamptz`, `user_id uuid`
    (null for the platform's calls). The API finishes the row as the user with all of them (the column grant extends);
    `cost_paise` is computed from `api/models.json`'s prices at finish (`api/src/price.ts`, the same arithmetic as
    `tools/cost.ts`, which now prefers `cost_paise` where set); `prompt_hash` is the SHA-256 of the system words this phase,
    `prompt_version` is Phase 20's; `fallback_model` is Phase 20's; `error_reason` is one of `timeout`, `api <status>`,
    `unfit`, `refused`, `truncated`, `swept`, `error`. Billed tokens are recorded on every answer that came back, a refusal
    and an unfit answer included (decision 11).
11. **`claude.ts` calls `messages.create` and parses the answer itself** (zod `safeParse` of the text block) instead of
    `messages.parse`, so `usage` and `stop_reason` are known for every answer that came back; `output_config.format` keeps
    `zodOutputFormat`'s schema. `stop_reason: max_tokens` is answered as `truncated`: recorded with its tokens, answered as a
    service failure (502, "The AI service didn't answer. Try again."), never as a refusal of the topic; the repair step
    comes with the pipeline in Phase 20 (D73), where this decision is extended.
12. **The request's envelope.** `X-Request-Id` (a UUID the app makes per request; the API makes one when absent or
    malformed) is on every log line, on the generation row and in `api_requests`; the API's logs are one JSON line per
    event (`api/src/log.ts`: `t`, `level`, `requestId`, `route`, `status`, `ms`, `userId`, `centre`, `reason`), and the
    six `console.error` calls move onto it. `api_requests` is written by the observability client (the service role) before
    the answer is sent, for every route but `/health`. Rate limits: 20 calls a minute per user on `/ai/*` and `/account/*`
    (a count of `api_requests` in the last minute, read before the gate) and 60 a minute per IP in the function's memory
    (best effort across instances, said so in `api/CLAUDE.md`); both answer 429 `reason: "rate"`. A body over 4.4 MB is 413
    by Hono's `bodyLimit` (Vercel's own 4.5 MB would answer first otherwise, in its words).
13. **The observability tables' shapes.** `events` (`centre_id`, `user_id` default `auth.uid()`, `kind` text matching
    `^[a-z_]{2,40}$`, `screen` text ≤ 40 or null, `at` timestamptz from the device, never content): members insert rows of
    their own centre and user and may read their centre's; no update or delete. `api_requests` (`request_id`, `route`,
    `method`, `status`, `latency_ms`, `user_id`, `centre_id`, `reason`): members may read their centre's rows; only the
    platform writes. `alerts` (`kind`, `threshold`, `value`, `centre_id`, `raised_at`, `acknowledged_at`) and `admin_audit`
    (`admin_user_id`, `action`, `centre_id`, `target` jsonb, `reason`, `ip`): a policy `using (false)` for the app (the
    catalogue test wants one), the platform alone reads and writes; both are empty until Phase 19. `device_tokens`
    (`user_id`, `device_id`, `token`, `environment` in sandbox or production, `app_build`, `last_seen_at`, `retired_at`,
    unique per user and device): the user's own rows; filled in Phase 18.
14. **`consent_events` by trigger.** `after insert or update of consent_at, consent_phone, consent_how on students`:
    null → set writes `given` (phone, how, `at` = `consent_at`, `by_user` = `auth.uid()`), set → null writes `withdrawn`, set →
    another value writes `given` again; the migration backfills `given` for every student with `consent_at` set (`by_user`
    null). Members read their centre's; the trigger's insert runs as the member and passes the insert policy; no update or
    delete. The three columns stay the gate's current state (D79). Withdrawal on screen is Phase 18's board.
15. **Two writes made idempotent.** `keep_artefact` gains a ninth parameter `p_key text default null` and
    `artefacts.idempotency_key` with a partial unique index per centre: a key already kept returns that row's id and
    writes nothing; the app sends the artefact's `generationID` as the key (a made artefact; an own sheet has none and two
    own sheets are two by intent). The absence log gains a unique index on `(centre_id, student_id, about_date) where kind
    = 'absence'`; the app's `logAbsence` reads the existing row on `23505` and answers it, so a replayed queue entry is done,
    not failed.
16. **Events from the app.** Five kinds this phase, the ones the record's own tables cannot show: `app_opened`,
    `signed_in`, `signed_out`, `tab_opened` (screen: `today`, `students`, `school`, `fees`, `more`), `link_opened` (screen:
    the link's kind). Closes, plans, notes, artefacts and consent are read from their own tables (D82). `ActivityLog`
    (Data) keeps them in `activity-<centre>.json`, posts when 20 have gathered or the app goes to the background or comes
    back, keeps them on failure, caps the file at 500 (the oldest go), and is wiped by sign-out with the rest (D40,
    `Wipe.belongs`). The kinds are an enum in Domain whose raw values the generated contract lists.
17. **The contract.** `tools/contract.ts` writes three things: `api/src/generated/database.ts` (a copy of
    `supabase/types.ts` with a header; `db.ts` types its clients with it, so an RPC's argument names and a column's type are
    checked by `tsc`: the 0022 `group_no` drift would have failed there); `ios/TutorCentralKit/Sources/Domain/Generated/
    APIContract.swift` (the limits and lists `api/src/contract.ts` exports by reading the zod schemas' checks: `tutorSaysMax`,
    the note's counts and lengths, the sheet's skills and questions, the check's and placement's counts, the mock's title
    and portions, the pages, the image and body sizes, the plan's groups, the event kinds, the error reasons); and the
    fake's sample answers as JSON under `ios/TutorCentralKit/Tests/DataTests/Contract/`, which `ContractTests` decodes with
    the app's own decoders (an answer shape the app cannot read fails there). `bun check`'s `tools` step runs
    `bun tools/contract.ts --check` (regenerate to a temporary place, diff) with the three sources among its inputs. The
    Swift literals the contract replaces are named in Task 8; a Domain test holds that every `ActivityKind` is in the list.
18. **The deploy's gate.** `tools/check-gate.ts <sha>` asks GitHub for the `check` workflow's runs with that head SHA on
    `main`; `success` passes; `in_progress` or `queued` fails with "the check for <sha> is still running; wait for it";
    `failure` or `cancelled` fails; no run (a documents-only commit, D31) walks back the first-parent history to the nearest
    commit that has one and passes only when the files changed between the two are all documents (D12's paths; the token
    document is not a document for this purpose). It runs as a `gate` job before `migrate` with `actions: read`.
19. **The smoke.** `tools/smoke.ts` keeps its two checks and adds two: it signs in as the smoke account (secrets
    `SMOKE_EMAIL`, `SMOKE_PASSWORD`; the password grant at `SUPABASE_URL/auth/v1/token` with the anon key from the repo's
    variables) and posts `/ai/make` kind `check` (Haiku, no student, no consent) for the smoke centre (variable
    `SMOKE_CENTRE_ID`) with `Idempotency-Key: smoke-<commit>` (a re-run for the same commit is free), expecting 200 and at
    least one question; then `GET /jobs/tick` with `WORKER_SECRET`, expecting 200 (the worker's route, the service key and the
    cron secret all proven). The smoke centre is an ordinary centre named Smoke with no students, made by the owner in the
    app on a simulator pointed at production (Owner step 1); the portal excludes it by its id later.
20. **The `plan` job's cut this phase.** Steps `read` (the batch's members, their chapters and skills, this and last
    month's sessions, the centre's school items, through the service client), `groups` (the rules), `name` (one `plan`
    call through `start_ai_call` as the platform for the groups the record leaves unnamed, then the named chapter and skill
    written into each member's record as `PlanMaker.writeNamedSkills` does), `write` (`make_plan`, with the brief chapters
    already made). The result is `{ plan_id }`. The app opens Today, finds the plan, shows it and runs `complete()` for its
    material as today; Phase 18 moves the artefact steps onto the job and retires the maker. The rules (`PlanRules`,
    `+Step`, `+Exam`, `PlanTypes`, `SpacedQueue`, `SchoolItemRules.hints`) are ported to `api/src/plan/` and proven equal to
    Domain's by one shared case file (`tools/contract/plan-cases.json`: inputs and expected drafts, written from
    `PlanRulesTests`' cases) that `DomainTests` and the API's tests both run; `ArtefactBudget` is Phase 18's port.
21. **`run-job.yml`:** a hand-started workflow (D21's shape) taking the owner's email, the batch's name and a date (default
    tomorrow in IST) that finds the centre by the email, the class by its name, calls `enqueue_job` with the key
    `plan:<class id>:<date>`, hits `/jobs/tick`, and polls the job's state for three minutes into the run's summary. Phase
    18's schedules replace it for the plan; it stays for support.
22. **The restore drill** is a hand-started workflow `restore-drill.yml`: `supabase projects create tc-restore-<date>` in the
    linked project's organisation (ap-south-1, a generated password kept in the runner only), wait until healthy,
    `supabase db dump --linked` of production's roles, schema and data, `psql` them into the scratch project, count the
    rows of every public table on both sides and print the two columns and the elapsed time to the summary, then
    `supabase projects delete` the scratch project. On the Free organisation the scratch project is its second free project
    (the workflow stops in words if two already exist). `docs/runbooks/restore.md` holds the steps, says that until Supabase
    Pro is bought (D85) this dump is the only copy that ever exists and lives for the minutes of the drill, names the
    dashboard's backups page as the route Pro adds, and keeps a dated log line per drill.
23. **CI's two flakes.** The database port: `check.yml` prints what listens on 54320 to 54324 and frees it (`sudo fuser -k`)
    before `supabase start`, and starts again once if the first start fails with the port message. The SchoolTests crash
    (run 38148815276): reproduced first (`xcodebuild test-without-building -only-testing SchoolTests -test-iterations-count
    20`), its cause fixed (the likely shape, from Phase 15's fix of `CheckStoreTests`: a store's task outliving its test;
    every School store test awaits the task it starts, and the stores' `deinit` does nothing on the main actor); if 20
    iterations cannot reproduce it, the plan records that and the fix is the awaiting rule applied to the School suites.
24. **Branches and the ledger:** `phase-17/<slug>` in the main checkout, one per pull request, as sessions 22 to 32; the
    ledger is `plan/sessions/035/ledger.md`, written by hand after each named test run, each ruling with its cost if wrong.
25. **Order of deploys.** Deploy 1 after PR 9 (0028 to 0033 and the API's envelope and recorded call, no worker yet: a
    build-26 app keeps working, now recorded); Deploy 2 after PR 12 (0034, the worker, the minute wake); Deploy
    3 after the review's fixes. The gate and the smoke (PR 2) are in before Deploy 1, so every deploy of this phase is
    gated and makes its real call.
26. **New tables and the blanket grant.** Supabase's default privileges grant `authenticated` everything on a new table;
    each migration revokes what the app may not do (`revoke insert, update, delete on public.jobs from authenticated`), and
    `rls.test.ts` probes the grants of every new table (a member's insert into `jobs` is refused; into `events` allowed).
27. **The fakes in production:** `index.ts` throws at start when `VERCEL_ENV === "production"` and `AI_FAKE` or
    `APPLE_FAKE` is `1`, so the deploy's smoke fails rather than a tutor's call answering from a fake.
28. **The sweep** is a job kind this phase (`sweep`, the platform's, no centre): `/jobs/tick` enqueues one with the key
    `sweep:<yyyy-mm-dd-hh>` when none is queued or running, and its one step calls `close_pending_generations('10
    minutes')`, which marks rows left `pending` as `failed` with `error_reason: 'swept'`; Phase 18 adds the photo step.

### The owner's ruling on the paid plans (D85, 2026-10-12)

Asked whether Supabase Pro's backups were mission critical, the owner ruled: "yes, skip both for now and update the plan"
(after: "if not, we don't need teh pro subscribtion even"). Neither plan is needed for the platform to work: pg_cron,
pg_net and Vault are on Free, the per-minute wake keeps a Free project from pausing, Hobby's 300 s holds a 110 s step, and
the minute wake comes from the database. What is carried without them, said plainly in the runbook and `STATE.md`: no
copy of the database exists anywhere (a bad migration or a deletion is final until Pro's daily backups), logs keep an hour
on Vercel and a day on Supabase (our own tables are the eyes, D77), and Vercel's Hobby terms are for non-commercial use.
Both plans are bought before the external testing round (the first time other people's data is in it), as a step of that
round's checklist; D71's "bought" clause is superseded to that extent by D85. Point-in-time recovery is not bought then
either; it is Phase 16's call with the price. The plan's shape with the plans later: `maxDuration` and the budget rise, the
restore runbook gains the backups page, nothing else moves.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A lease that expires mid-step.** Worker A's step runs past 180 s (a slow Claude call), the lease lapses, worker B
   claims the job; A's `record_step` is refused with `job_lease_lost` and A stops without writing; B's step asks
   `start_ai_call` with the same key `<job>:<step>` and either replays A's finished row or meets `in_progress` and goes
   `waiting` for 30 s. Nothing is paid twice. Tests: Task 4 (`a write by a worker that lost the lease is refused`), Task 11
   (`RunnerTests: a step whose lease was taken stops the worker`, `a step that meets an in-progress key waits`).
2. **A function killed after the Claude call and before the row's finish.** The row stays `pending` and counts against
   the hard cap; the `sweep` closes it after ten minutes as `failed`/`swept` with no tokens; a retry of the same key after
   the sweep is a new call (a failed row does not replay); before the sweep it meets `in_progress`. The loss is bounded to
   one call. Tests: Task 5 (`close_pending_generations closes a 10-minute pending row and leaves a 2-minute one`), Task 10
   (`a pending key answers 409 in_progress`).
3. **A key reused with a different body.** 409 `key_reused`, nothing paid, the first row untouched; the app shows its
   service words. Tests: Task 5 (`a key with another body is refused`), Task 10 (`a reused key with another body is 409`),
   Task 14 (`APIClientTests.aReusedKeyReadsAsTheServiceWords`).
4. **An allowance exactly reached by two calls at once.** With `ai_allowance` 1 and no rows, two `start_ai_call`s in
   parallel: one row, one `ai_limit_reached`, never two rows. Test: Task 5 (`two starts at once cannot both pass the
   allowance`).
5. **A deploy whose check is pending rather than red.** The gate fails with "still running", not "no run"; a
   documents-only head passes on the last code commit's green run; a head whose nearest run is red fails. Tests: Task 3
   (`check-gate.test.ts`: `a run in progress is not green`, `a documents-only commit takes the nearest run`, `a code change
   after the nearest run is refused`).
6. **A worker run that reaches its budget mid-job.** The job goes `waiting` with the step reached and `run_at` now; the
   next tick continues at that step; no step runs twice. Test: Task 11 (`RunnerTests: the budget ends between steps`).
7. **A job cancelled while running.** The worker's next write is refused with `job_cancelled`; a paid call made in that
   step is still recorded on its row with the job id. Tests: Task 4 (`cancel refuses the worker's next write`), Task 11
   (`a cancelled job's step records its generation and stops`).
8. **Build 26 against the new API.** No key header: the call runs and is recorded with a null key; a 429 `rate` shows
   build 26's daily-limit words (a human cannot reach 20 a minute; said in the ledger); every old call's answer shape is
   unchanged. Tests: Task 10 (`a call without a key is recorded and never replayed`), Task 8 (the contract's sample answers
   decode).
9. **The events batch offline.** Twenty events gathered with the gateway down stay in the file; the next foreground posts
   them in order; the five-hundred-and-first pushes the oldest out; sign-out deletes the file before anything is posted
   again. Tests: Task 15 (`ActivityLogTests`: four cases).
10. **The owner's own centre update after the column grants.** Settings' name, UPI id, payment link, receipts, WhatsApp
    number and the consent notice still save; a direct update of `ai_allowance` by the owner is refused. Tests: Task 5
    (`the owner cannot raise the allowance; Settings' columns still save`); hand run 4.

## File structure

Created or changed, by part. A file has one job.

**Database (`supabase/`)**
- `migrations/20261102000028_v3_jobs.sql`: `job_kind`, `job_state`, `jobs`, `job_steps`, `is_member`'s platform clause,
  `enqueue_job`, `claim_jobs`, `extend_lease`, `record_step`, `wait_job`, `finish_job`, `fail_job`, `cancel_job`.
- `migrations/20261103000029_v3_recorded_call.sql`: `ai_generations`' twelve columns, `start_ai_call`, `start_ai_generation`
  as its wrapper, the gate trigger, `centres.ai_allowance` and `ai_allowance_paise`, the column grants,
  `close_pending_generations`.
- `migrations/20261104000030_v3_observability.sql`: `events`, `api_requests`, `alerts`, `admin_audit`.
- `migrations/20261105000031_v3_device_tokens.sql`.
- `migrations/20261106000032_v3_consent_events.sql`: the table, the trigger, the backfill.
- `migrations/20261107000033_v3_idempotent_writes.sql`: `artefacts.idempotency_key`, `keep_artefact`'s ninth parameter,
  the absence log's unique index.
- `migrations/20261108000034_v3_wake_worker.sql`: `pg_cron`, `pg_net`, `wake_worker` and its trigger, `wake_worker_tick`
  and its minute schedule.
- `tests/jobs.test.ts` (new), `tests/gate.test.ts` (new; `start_ai_call`, the allowance, the sweep), `tests/rls.test.ts`
  (the catalogue, `PLATFORM_TABLES`, the grants probe), `tests/v2.test.ts` (`keep_artefact`'s key, the absence index,
  `consent_events`), `types.ts`, `seed.sql` (nothing; the seed centre keeps the default allowance).

**API (`api/`)**
- `src/jobs/types.ts` (Job, StepOutcome, JobHandler, Clock), `src/jobs/db.ts` (JobsDb over the named functions, the
  service client), `src/jobs/db-fake.ts` (in memory, the same rules, a fake clock), `src/jobs/runner.ts` (`drain`),
  `src/jobs/kinds/sweep.ts`, `src/jobs/kinds/plan.ts`, `src/jobs/kinds/index.ts` (the registry), `src/routes/jobs.ts`
  (`/jobs/tick`, `/jobs/wake`).
- `src/plan/types.ts`, `src/plan/rules.ts`, `src/plan/exam.ts`, `src/plan/step.ts`, `src/plan/spaced.ts`,
  `src/plan/hints.ts`, `src/plan/dates.ts` (IST days without a library).
- `src/request.ts` (request id, timing, the `api_requests` row, the rate limits), `src/log.ts`, `src/observe.ts` (the
  observability client: `recordRequest`, `recentCount`), `src/price.ts`, `src/contract.ts` (what the contract exports),
  `src/generated/database.ts` (generated), `src/env.ts` (two names), `src/index.ts`, `src/make-app.ts` (the new deps),
  `src/db.ts` (`startCall`, `finish` with the new fields, typed), `src/db-fake.ts`, `src/claude.ts` (decision 11),
  `src/claude-fake.ts` (stop reason, usage on a refusal), `src/routes/common.ts` (`run` with the key, the hash, the
  replay, cost and latency), `src/errors.ts` (`inProgress`, `keyReused`, `rate`, `tooLarge`), `vercel.json` (functions,
  no `crons`), `.env.example`.
- Tests: `test/jobs-db.test.ts`, `test/runner.test.ts`, `test/jobs-routes.test.ts`, `test/plan-rules.test.ts` (the shared
  cases), `test/plan-job.test.ts`, `test/request.test.ts`, `test/log.test.ts`, `test/price.test.ts`, `test/contract.test.ts`,
  `test/claude.test.ts`, `test/ai.test.ts`, `test/v2.test.ts`, `test/entry.test.ts` (the fakes refused), `test/app.test.ts`.

**Tools and workflows**
- `tools/contract.ts` and `tools/contract.test.ts`; `tools/contract/plan-cases.json`; `tools/check-gate.ts` and its test;
  `tools/smoke.ts` and `tools/smoke.test.ts`; `tools/cost.ts` (`cost_paise` first); `tools/check/steps.ts` (the `tools`
  step's inputs and the contract check; `api`'s inputs gain `src/generated/**`).
- `.github/workflows/deploy.yml` (the gate job, the Vault step, the smoke's env), `check.yml` (the port step),
  `run-job.yml` (new), `restore-drill.yml` (new).
- `docs/runbooks/restore.md` (new); `docs/runbooks/simulator.md` gains "12. The worker locally" (how a job is queued and
  drained against the local stack).

**App (`ios/TutorCentralKit`)**
- `Sources/Domain/Generated/APIContract.swift` (generated), `Sources/Domain/Activity/ActivityKind.swift`,
  `Sources/Data/AI/IdempotencyKey.swift`, `Sources/Data/AI/APIClient.swift` (the headers, the mappings),
  `Sources/Data/AI/APIFailure.swift` (no new case; the mappings reuse `timedOut` and `service`),
  `Sources/Data/Activity/ActivityLog.swift`, `ActivityRepository.swift`, `SupabaseActivityRepository.swift`,
  `FakeActivityRepository.swift`, `Sources/Data/Messages/SupabaseMessageLogRepository.swift` (`23505`),
  `Sources/Data/Plans/SupabasePlansRepository.swift` (`p_key`), `Sources/Data/Cache/Wipe.swift` (`activity-`),
  `Sources/AppShell/RootView*.swift` (the log's owner, the five records), `Sources/Features/Make/*` (History's Create
  again sets `again`), the Swift literals Task 8 names.
- Tests: `DataTests/APIClientTests.swift`, `IdempotencyKeyTests.swift`, `ActivityLogTests.swift`, `ContractTests.swift` (+
  `Contract/*.json` resources), `MessageLogIdempotencyTests.swift`, `DomainTests/ActivityKindTests.swift`,
  `PlanCasesTests.swift` (the shared cases), `AppShellTests/ActivityRecordsTests.swift`, `WipeTests`.

**Documents:** `api/CLAUDE.md`, `ios/CLAUDE.md`, `supabase/CLAUDE.md`, `CLAUDE.md` (the commands table: `run-job`,
`restore-drill`, `bun contract`), `plan/README.md` (D83 to D85, the phase's status), `plan/phase-17-platform-foundation.md`
("As built"), `plan/STATE.md`, `plan/sessions/035/`.

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-17/ci-flakes` | CI: the database port freed before `supabase start`; the SchoolTests teardown crash fixed | none |
| 2 | 3 | `phase-17/deploy-gate-smoke` | The deploy requires a green check for its commit and makes one real `check` call as the smoke account | none |
| 3 | 4 | `phase-17/db-jobs` | Migration 0028: `jobs`, `job_steps`, the lease and step functions; `is_member` for the platform | none |
| 4 | 5 | `phase-17/db-recorded-call` | Migration 0029: `start_ai_call` (the lock, the key, the request id), the enriched row, the allowance columns the owner cannot raise, the sweep function | none |
| 5 | 6 | `phase-17/db-observability` | Migrations 0030 and 0031: `events`, `api_requests`, `alerts`, `admin_audit`, `device_tokens` | none |
| 6 | 7 | `phase-17/db-consent-idempotent` | Migrations 0032 and 0033: `consent_events` with its trigger and backfill; `keep_artefact`'s key; one absence log a day | none |
| 7 | 8 | `phase-17/contract` | `tools/contract.ts`: the API's database types, the app's limits and the sample answers generated; `bun check` fails on drift; the first contract tests | none |
| 8 | 9 | `phase-17/api-envelope` | The API: request ids, JSON logs, `api_requests`, rate and body limits, the fakes refused in production, `maxDuration` | none |
| 9 | 10 | `phase-17/api-recorded-call` | The API: `start_ai_call`, idempotency keys, cost, latency, stop reason, tokens on every answer, truncation | none |
| main | | | `gh workflow run deploy` (Deploy 1): 0028 to 0033 up, the API at `main`'s head, the gate and the smoke green | |
| 10 | 11 | `phase-17/worker` | The worker: the lease loop with a fake clock, `/jobs/tick` and `/jobs/wake`, the cron, migration 0034 (`wake_worker`), the `sweep` kind | none |
| 11 | 12 | `phase-17/plan-rules` | The plan rules in TypeScript, equal to Domain's on the shared cases | none |
| 12 | 13 | `phase-17/plan-job` | The `plan` job: read, groups, name, write; `run-job.yml` | none |
| main | | | `gh workflow run deploy` (Deploy 2): 0034 up, the worker and the minute wake live; Owner step 3 (his centre's first plan job) | |
| 13 | 14 | `phase-17/app-keys` | The app: the idempotency key and request id on every AI call, the 409 and 429 mappings, the absence log and a made artefact's keep idempotent | none |
| 14 | 15 | `phase-17/app-events` | The app: activity posted in batches to `events`; wiped at sign-out | none |
| 15 | 17 | `phase-17/restore-drill` | `restore-drill.yml` and `docs/runbooks/restore.md` | none |
| 16+ | 16, 18 | `phase-17/fix-<what>` | The hand runs' and the review's fixes (D68) | none unless a screen changes, which stops and asks |
| main | 2, 16, 18 | | The owner's steps, Deploy 3, the TestFlight build, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked; "Nothing on screen
changes; no pictures (D6, D7)" in its description. Tasks 3 to 7 can start before the owner's steps finish; Deploy 1 needs
steps 1 and 2 done.

## The order

| When | What |
|---|---|
| Start | Reality against `STATE.md`; `bun check` green; the owner's steps 1 and 2 asked one at a time (Task 2) while PRs 1 to 9 are built |
| PRs 1 to 9 | Tasks 1, 3 to 10; Deploy 1 |
| PRs 10 to 12 | Tasks 11 to 13; Deploy 2; Owner step 3 (his first plan job), the next morning's check |
| PRs 13 to 15 | Tasks 14, 15, 17; Task 16's hand runs after PRs 12 and 14 |
| Close | Task 18: the review (Fable 5.1, two fresh reviewers), every finding fixed, Deploy 3, the TestFlight build with nothing new on screen, the documents |

---

### Task 1: CI's two flakes (PR 1)

**Files:**
- Modify: `.github/workflows/check.yml` (the Ubuntu job's "Local Supabase" step)
- Modify: the School store tests that start a task and return (`ios/TutorCentralKit/Tests/SchoolTests/*StoreTests.swift`),
  and any School store whose `deinit` or `onChange` touches the main actor from a background task

- [ ] **Step 1: reproduce the crash.** Build once (`bun check --only=ios` or `xcodebuild build-for-testing`), then:

```bash
cd ios && xcodebuild -project TutorCentral.xcodeproj -scheme TutorCentral -destination 'platform=iOS Simulator,name=iPhone 17' \
  test-without-building -only-testing:SchoolTests -test-iterations-count 20 -collect-test-diagnostics never 2>&1 | xcbeautify --quiet
```

  Expected: either a crash in some iteration (read the `.xcresult` under DerivedData/Logs/Test: the crashed thread names the
  store and the line) or twenty green runs, which the ledger records as "not reproduced in 20".

- [ ] **Step 2: the failing test (if a cause shows) or the rule (if not).** The cause's test: a test that starts the store's
  task and awaits it with the fake's answer delayed, asserting the store's state after `await store.task?.value` rather
  than after a sleep. The rule applied to every School store test: no fixed `Task.sleep` to wait for a store; `await` the
  task the store exposes (`begin()` returns it, as `CheckStore` does since #176).

- [ ] **Step 3: `check.yml`.** Before `supabase start`:

```yaml
      - name: Free the local ports
        run: |
          for p in 54320 54321 54322 54323 54324; do
            if sudo lsof -iTCP:$p -sTCP:LISTEN -Pn; then echo "::warning::port $p was held; freeing it"; sudo fuser -k $p/tcp || true; fi
          done
      - name: Local Supabase
        working-directory: supabase
        run: |
          start() { supabase start -x realtime,imgproxy,mailpit,postgres-meta,studio,edge-runtime,logflare,vector,supavisor; }
          start || { echo "::warning::supabase start failed once; stopping and starting again"; supabase stop --no-backup || true; start; }
```

- [ ] **Step 4: `bun check --only=format,lint,ios` green; commit; PR 1; merge** when CI's two jobs are green. The ledger
  records what the 20 iterations showed.

---

### Task 2: The owner's steps 1 and 2 (asked one at a time, each checked before the next)

Nothing here is a question; each is a step he does himself with the result checked. The session asks for step 1 as soon
as it starts and goes on with Task 3 while waiting. No plan is bought (D85).

- [ ] **Owner step 1: the smoke account.** The session writes `ios/Config/Local.xcconfig` with production's URL and anon key
  (`gh variable get SUPABASE_URL`, `SUPABASE_ANON_KEY`; `API_ORIGIN` the production one), runs `bun gen` and a Debug build,
  boots the simulator and launches the app without a launch state, then hands over: the owner signs in with a plus-address
  of his own email (`…+smoke@…`, so the code reaches his inbox), finishes the setup screen with the centre name "Smoke", opens
  Settings and sets a password, and says "done" (never the password). The session restores `Local.xcconfig` to the local
  values. Check: the owner reads the Smoke centre's id from the dashboard's Table editor (`centres`, the row named Smoke)
  and pastes it; the session confirms it is a UUID.
- [ ] **Owner step 2: the secrets and variables.** GitHub → Settings → Environments → `Production` → secrets `SMOKE_EMAIL`,
  `SMOKE_PASSWORD`, `WORKER_SECRET` (made with `openssl rand -hex 24`); repository variable `SMOKE_CENTRE_ID`. Vercel →
  `tutor-central-api` → Settings → Environment Variables (Production): `SUPABASE_SERVICE_ROLE_KEY` (Supabase dashboard →
  Project Settings → API keys: the service role key, or the new secret key `sb_secret_…`, which the gateway exchanges for
  the same role; the smoke proves whichever he pastes) and `WORKER_SECRET` (the same value as GitHub's). Check: `gh secret
  list --env Production` and `gh variable list` show the names; the Vercel page shows the two names.

---

### Task 3: The deploy's gate and the real smoke (PR 2)

**Files:**
- Create: `tools/check-gate.ts`, `tools/check-gate.test.ts`
- Modify: `tools/smoke.ts`, `tools/smoke.test.ts`, `.github/workflows/deploy.yml`

**Interfaces:**
- Produces: `gate(sha, { runs, changedFiles, parents }): Promise<string | null>` (null passes; else the reason);
  `smoke(site, commit, { attempts, waitMs, account?: { url, anon, email, password, centre }, workerSecret? })`.

- [ ] **Step 1: the failing tests (`tools/check-gate.test.ts`):**

```ts
import { expect, test } from "bun:test";
import { gate, isDocument } from "./check-gate";

const sha = "a".repeat(40);
const older = "b".repeat(40);
const runs = (m: Record<string, { status: string; conclusion: string | null }[]>) => async (s: string) => m[s] ?? [];

test("a green run for the commit passes", async () => {
  expect(await gate(sha, { runs: runs({ [sha]: [{ status: "completed", conclusion: "success" }] }), parents: async () => [], changedFiles: async () => [] })).toBeNull();
});
test("a run in progress is not green", async () => {
  const why = await gate(sha, { runs: runs({ [sha]: [{ status: "in_progress", conclusion: null }] }), parents: async () => [], changedFiles: async () => [] });
  expect(why).toContain("still running");
});
test("a red run fails", async () => {
  expect(await gate(sha, { runs: runs({ [sha]: [{ status: "completed", conclusion: "failure" }] }), parents: async () => [], changedFiles: async () => [] })).toContain("not green");
});
test("a documents-only commit takes the nearest run", async () => {
  const deps = { runs: runs({ [older]: [{ status: "completed", conclusion: "success" }] }), parents: async () => [older], changedFiles: async () => ["plan/STATE.md", "docs/x.md"] };
  expect(await gate(sha, deps)).toBeNull();
});
test("a code change after the nearest run is refused", async () => {
  const deps = { runs: runs({ [older]: [{ status: "completed", conclusion: "success" }] }), parents: async () => [older], changedFiles: async () => ["plan/STATE.md", "api/src/x.ts"] };
  expect(await gate(sha, deps)).toContain("api/src/x.ts");
});
test("the token document is not a document here", () => {
  expect(isDocument("docs/design/design-tokens.md")).toBe(false);
  expect(isDocument("ios/CLAUDE.md")).toBe(true);
});
```

  And in `tools/smoke.test.ts` (its existing fake-fetch style): `the smoke signs in and makes one check` (the fake fetch
  answers the token route with an access token, `/ai/make` with `{ id, result: { questions: [{}] } }`, `/jobs/tick` 200; the
  test asserts the `Idempotency-Key` is `smoke-<commit>`, the bearer is the token, the body's `kind` is `check` and
  `centreId` the centre); `an empty answer fails the smoke`; `a tick without 200 fails the smoke`; `without an account the
  two old checks still run` (so a local `bun tools/smoke.ts` without secrets keeps working).

  Run: `bun test tools`. Expected: the new ones fail (no `check-gate`, no `account`).

- [ ] **Step 2: `tools/check-gate.ts`.** `isDocument(path)`: `plan/`, `docs/` (except `docs/design/design-tokens.md`),
  `README.md`, any `CLAUDE.md`. `gate(sha, deps)`: the runs for `sha`; the latest by `created_at`: `completed`/`success` →
  null; `queued`/`in_progress` → "the check for <sha> is still running; wait for it and run the deploy again"; another
  conclusion → "the check for <sha> is not green (<conclusion>)"; no run → the first parent in `deps.parents(sha)` (up to
  50) that has one, then the same verdict on it, plus `changedFiles(that, sha)` all `isDocument` else "<file> changed since
  the last check run <that>". `main`: `gh api "repos/$GITHUB_REPOSITORY/actions/workflows/check.yml/runs?head_sha=<sha>&branch=main"`
  through `fetch` with `GITHUB_TOKEN`; `git rev-list --first-parent --max-count=50 <sha>^`; `git diff --name-only a b`.
  Exit 1 with the reason as `::error::`.

- [ ] **Step 3: `tools/smoke.ts`.** After the two existing checks, when `account` is given: `POST
  ${url}/auth/v1/token?grant_type=password` with `apikey: anon` and `{ email, password }` → `access_token`; `POST
  ${site}/ai/make` with `Authorization: Bearer`, `Idempotency-Key: smoke-${commit}`, `X-Request-Id` (a UUID), body `{ kind:
  "check", centreId: centre, classLevel: "5", subject: "Mathematics", skills: ["Adding fractions"] }`; 200 and
  `result.questions.length >= 1` else a problem in words (the status and the `reason` if any; never the password). When
  `workerSecret` is given: `GET ${site}/jobs/tick` with its bearer → 200 (a 404 before PR 10 is deployed is a problem too, so
  the smoke's tick check is turned on by the env var's presence and the env var is added at Deploy 2). `main` reads
  `SMOKE_EMAIL`, `SMOKE_PASSWORD`, `SMOKE_CENTRE_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `WORKER_SECRET` from the environment.

- [ ] **Step 4: `deploy.yml`.** A `gate` job before `migrate` (`needs: gate` on `migrate`): checkout with `fetch-depth: 0`,
  the same commit step, `permissions: actions: read, contents: read`, `bun tools/check-gate.ts "$sha"` with
  `GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}` and `GITHUB_REPOSITORY`. In `migrate`, after the push, "The worker's secrets":
  writes `$RUNNER_TEMP/vault.sql` from a heredoc with the values from env (`delete from vault.secrets where name in
  ('worker_url', 'worker_secret'); select vault.create_secret('<API_ORIGIN>', 'worker_url'); select
  vault.create_secret('<WORKER_SECRET>', 'worker_secret');`, quotes escaped) and runs `supabase db query --linked -f` on it
  (the file is never printed; the step's name alone shows). The smoke step's env gains the six names (`SUPABASE_URL` and
  `SUPABASE_ANON_KEY` from `vars`, the rest from `secrets` and `vars`). The summary's smoke block now says "one `check` made
  for the smoke centre, N questions".

- [ ] **Step 5: `bun check --only=tools` green; commit; PR 2; merge.** The gate's first real pass is Deploy 1 (Task 10).

---

### Task 4: Migration 0028: `jobs`, `job_steps`, the lease and step functions; `is_member` for the platform (PR 3)

**Files:**
- Create: `supabase/migrations/20261102000028_v3_jobs.sql`, `supabase/tests/jobs.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the catalogue and `PLATFORM_TABLES`), `supabase/types.ts`

**Interfaces:**
- Produces (the worker calls these as the service role, Task 11): `enqueue_job(p_centre uuid, p_kind job_kind, p_key text,
  p_input jsonb default '{}', p_run_at timestamptz default now(), p_max_attempts integer default 3) returns uuid`;
  `claim_jobs(p_worker text, p_limit integer default 5, p_lease_seconds integer default 180) returns setof jobs`;
  `extend_lease(p_job uuid, p_worker text, p_lease_seconds integer default 180) returns boolean`;
  `record_step(p_job uuid, p_worker text, p_step text, p_state job_state, p_generation uuid default null, p_error jsonb
  default null, p_cost_paise integer default 0, p_step_data jsonb default null) returns uuid`;
  `wait_job(p_job uuid, p_worker text, p_step jsonb, p_run_at timestamptz) returns void`;
  `finish_job(p_job uuid, p_worker text, p_result jsonb) returns void`;
  `fail_job(p_job uuid, p_worker text, p_error jsonb, p_retry boolean) returns job_state` (the state it left the job in);
  `cancel_job(p_centre uuid, p_job uuid) returns boolean` (members and the platform).
- Errors raised, matched by the worker: `job_lease_lost`, `job_cancelled`, `job_not_running`, `not a member` (42501).

- [ ] **Step 1: the failing tests (`supabase/tests/jobs.test.ts`;** `serviceClient(l)` is added to `tests/client.ts` as
  `createClient(l.url, l.service, options)`):

```ts
import { SQL } from "bun";
import { beforeAll, expect, test } from "bun:test";
import { type Local, local, serviceClient, userClient } from "./client";

let l: Local; let svc: ReturnType<typeof serviceClient>; let a: Awaited<ReturnType<typeof userClient>>; let b: typeof a;
let centreA: string; let centreB: string;
const stamp = Date.now();
const enqueue = (centre: string, key: string, input = {}) => svc.rpc("enqueue_job", { p_centre: centre, p_kind: "plan", p_key: key, p_input: input });
const claim = (worker: string, limit = 5) => svc.rpc("claim_jobs", { p_worker: worker, p_limit: limit });

beforeAll(async () => {
  l = await local(); svc = serviceClient(l);
  a = await userClient(l, `jobs-a-${stamp}@example.com`); b = await userClient(l, `jobs-b-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Jobs A" })).data as string;
  centreB = (await b.rpc("create_centre", { p_name: "Jobs B" })).data as string;
});

test("the platform passes is_member for any centre; a member still fails for another's", async () => {
  expect((await svc.rpc("is_member", { c: centreA })).data).toBe(true);
  expect((await b.rpc("is_member", { c: centreA })).data).toBe(false);
});
test("enqueue is idempotent per centre and key, and the same key in another centre is another job", async () => {
  const first = await enqueue(centreA, "plan:x:2026-10-13", { class_id: "c" });
  expect(first.error).toBeNull();
  const again = await enqueue(centreA, "plan:x:2026-10-13", { class_id: "changed" });
  expect(again.data).toBe(first.data);
  const row = await svc.from("jobs").select("input, state, attempts").eq("id", first.data as string).single();
  expect(row.data).toEqual({ input: { class_id: "c" }, state: "queued", attempts: 0 });
  expect((await enqueue(centreB, "plan:x:2026-10-13")).data).not.toBe(first.data);
});
test("a member may enqueue for their centre and read it, not another's; a member cannot write the table", async () => {
  const mine = await a.rpc("enqueue_job", { p_centre: centreA, p_kind: "export", p_key: `export:${stamp}` });
  expect(mine.error).toBeNull();
  expect((await b.rpc("enqueue_job", { p_centre: centreA, p_kind: "export", p_key: "x" })).error?.code).toBe("42501");
  expect((await a.from("jobs").select("id").eq("id", mine.data as string)).data?.length).toBe(1);
  expect((await b.from("jobs").select("id").eq("id", mine.data as string)).data).toEqual([]);
  expect((await a.from("jobs").insert({ centre_id: centreA, kind: "plan", idempotency_key: "direct" })).error).not.toBeNull();
  expect((await a.from("jobs").update({ state: "done" }).eq("id", mine.data as string).select("id")).data).toEqual([]);
});
test("a claim takes due jobs in run_at order with a lease, skips the future and what another worker holds", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.jobs where centre_id in (${centreA}, ${centreB})`;
    await enqueue(centreA, "due-1"); await enqueue(centreA, "due-2");
    await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "later", p_run_at: new Date(Date.now() + 3_600_000).toISOString() });
    const [one, two] = await Promise.all([claim("w1", 1), claim("w2", 1)]);
    const ids = [one.data![0].id, two.data![0].id];
    expect(new Set(ids).size).toBe(2);
    expect(one.data![0]).toMatchObject({ state: "running", leased_by: "w1", attempts: 1 });
    expect(new Date(one.data![0].lease_until).getTime()).toBeGreaterThan(Date.now() + 100_000);
    expect((await claim("w3")).data).toEqual([]);
  } finally { await sql.close(); }
});
test("a write by a worker that lost the lease is refused; the lease past its time is retaken", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.jobs where centre_id = ${centreA}`;
    const id = (await enqueue(centreA, "lease")).data as string;
    expect((await claim("w1")).data?.length).toBe(1);
    expect((await svc.rpc("record_step", { p_job: id, p_worker: "w2", p_step: "read", p_state: "done" })).error?.message).toContain("job_lease_lost");
    await sql`update public.jobs set lease_until = now() - interval '1 second' where id = ${id}`;
    const retaken = await claim("w2");
    expect(retaken.data![0]).toMatchObject({ id, leased_by: "w2", attempts: 2 });
    expect((await svc.rpc("finish_job", { p_job: id, p_worker: "w1", p_result: {} })).error?.message).toContain("job_lease_lost");
    const step = await svc.rpc("record_step", { p_job: id, p_worker: "w2", p_step: "read", p_state: "done", p_cost_paise: 12, p_step_data: { at: "read" } });
    expect(step.error).toBeNull();
    const row = await svc.from("jobs").select("cost_paise, step").eq("id", id).single();
    expect(row.data).toEqual({ cost_paise: 12, step: { at: "read" } });
    expect((await svc.from("job_steps").select("step, attempt, state, centre_id").eq("job_id", id)).data).toEqual([{ step: "read", attempt: 2, state: "done", centre_id: centreA }]);
  } finally { await sql.close(); }
});
test("a failure retries with backoff until max_attempts, then fails with its error", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.jobs where centre_id = ${centreA}`;
    const id = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "retry", p_max_attempts: 2 })).data as string;
    await claim("w1");
    expect((await svc.rpc("fail_job", { p_job: id, p_worker: "w1", p_error: { reason: "timeout" }, p_retry: true })).data).toBe("queued");
    const queued = await svc.from("jobs").select("run_at, leased_by, attempts").eq("id", id).single();
    expect(queued.data!.leased_by).toBeNull();
    expect(new Date(queued.data!.run_at).getTime()).toBeGreaterThan(Date.now() + 20_000);
    await sql`update public.jobs set run_at = now() where id = ${id}`;
    await claim("w1");
    expect((await svc.rpc("fail_job", { p_job: id, p_worker: "w1", p_error: { reason: "timeout" }, p_retry: true })).data).toBe("failed");
    const failed = await svc.from("jobs").select("state, error, finished_at").eq("id", id).single();
    expect(failed.data).toMatchObject({ state: "failed", error: { reason: "timeout" } });
    expect(failed.data!.finished_at).not.toBeNull();
    expect((await claim("w1")).data).toEqual([]);
  } finally { await sql.close(); }
});
test("waiting continues at the step reached; done keeps its result", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.jobs where centre_id = ${centreA}`;
    const id = (await enqueue(centreA, "wait")).data as string;
    await claim("w1");
    expect((await svc.rpc("wait_job", { p_job: id, p_worker: "w1", p_step: { at: "name" }, p_run_at: new Date().toISOString() })).error).toBeNull();
    const again = await claim("w2");
    expect(again.data![0]).toMatchObject({ id, step: { at: "name" } });
    expect((await svc.rpc("finish_job", { p_job: id, p_worker: "w2", p_result: { plan_id: "p" } })).error).toBeNull();
    expect((await svc.from("jobs").select("state, result").eq("id", id).single()).data).toEqual({ state: "done", result: { plan_id: "p" } });
  } finally { await sql.close(); }
});
test("cancel: a member cancels their own queued job, not another's; cancel refuses the worker's next write", async () => {
  const sql = new SQL(l.db);
  try {
    await sql`delete from public.jobs where centre_id = ${centreA}`;
    const id = (await enqueue(centreA, "cancel")).data as string;
    expect((await b.rpc("cancel_job", { p_centre: centreA, p_job: id })).error?.code).toBe("42501");
    await claim("w1");
    expect((await a.rpc("cancel_job", { p_centre: centreA, p_job: id })).data).toBe(true);
    expect((await svc.rpc("record_step", { p_job: id, p_worker: "w1", p_step: "read", p_state: "done" })).error?.message).toContain("job_cancelled");
    expect((await svc.from("jobs").select("state").eq("id", id).single()).data).toEqual({ state: "cancelled" });
  } finally { await sql.close(); }
});
test("a platform job has no centre and no member sees it; a centre kind needs a centre", async () => {
  const id = (await svc.rpc("enqueue_job", { p_centre: null, p_kind: "sweep", p_key: `sweep:${stamp}` })).data as string;
  expect((await a.from("jobs").select("id").eq("id", id)).data).toEqual([]);
  expect((await svc.rpc("enqueue_job", { p_centre: null, p_kind: "plan", p_key: "no-centre" })).error).not.toBeNull();
});
test("the worker's functions are not the app's", async () => {
  for (const fn of ["claim_jobs", "record_step", "finish_job", "wait_job", "fail_job", "extend_lease"]) {
    const r = await a.rpc(fn, fn === "claim_jobs" ? { p_worker: "me" } : { p_job: "00000000-0000-0000-0000-000000000000", p_worker: "me" } as never);
    expect({ fn, code: r.error?.code }).toEqual({ fn, code: "42501" });
  }
});
```

  In `rls.test.ts`: the catalogue's expected list gains `jobs` and `job_steps` (Tasks 6 and 7 add theirs); a new
  `PLATFORM_TABLES` list with a test "the platform's tables are read by their centre's members alone and written by none":
  for each, a row inserted as `svc` for centre A (a job; a job step on it), read by `a` (1), by `b` (0), by anonymous (0);
  `a`'s insert, update and delete refused. The 0001 `CENTRE_TABLES` loop is unchanged.

  Run: `cd supabase && bun test tests/jobs.test.ts tests/rls.test.ts`. Expected: every new test fails (no table, no function).

- [ ] **Step 2: the migration.** The tables as decision 3 and 4 describe (the DDL in the architecture note above; `jobs`
  with `check ((centre_id is not null) or kind in ('sweep', 'eval_run'))`, the unique index on `(coalesce(centre_id,
  '00000000-…'), idempotency_key)`, the partial index on `run_at` for live states, the `set_updated_at` triggers; `job_steps`
  with the composite foreign keys to `jobs (centre_id, id)` and `ai_generations (centre_id, id)` on delete set null for the
  generation). RLS on both; `create policy jobs_member on public.jobs for select to authenticated using
  (public.is_member(centre_id))`, the same for `job_steps`; `revoke insert, update, delete on public.jobs, public.job_steps
  from authenticated`. `is_member` replaced (decision 2) with the reason in a comment. The functions:

```sql
create function public.claim_jobs(p_worker text, p_limit integer default 5, p_lease_seconds integer default 180)
returns setof public.jobs language plpgsql security invoker set search_path = '' as $$
begin
  -- A lease that lapsed past its last attempt is failed here, so the portal sees why it stopped.
  update public.jobs set state = 'failed', finished_at = now(), leased_by = null, lease_until = null,
         error = coalesce(error, '{}'::jsonb) || jsonb_build_object('reason', 'attempts', 'message', 'the lease lapsed on the last attempt')
   where state = 'running' and lease_until < now() and attempts >= max_attempts;
  return query
    update public.jobs j
       set state = 'running', leased_by = p_worker, lease_until = now() + make_interval(secs => p_lease_seconds),
           started_at = coalesce(j.started_at, now()), attempts = j.attempts + 1
     where j.id in (select id from public.jobs
                     where ((state in ('queued', 'waiting') and run_at <= now()) or (state = 'running' and lease_until < now()))
                       and attempts < max_attempts
                     order by run_at for update skip locked limit p_limit)
    returning j.*;
end $$;
```

  `holds(p_job, p_worker)` is a private helper (`security invoker`, no grant) that selects the row `for update` and raises
  `job_cancelled` when its state is `cancelled`, `job_not_running` when not `running`, `job_lease_lost` when `leased_by <>
  p_worker`. `record_step` inserts the step (`centre_id` from the job, `attempt` from the job), adds `p_cost_paise`, sets
  `step = coalesce(p_step_data, step)`, extends the lease, returns the step's id. `wait_job` sets `waiting`, `step`,
  `run_at`, clears the lease. `finish_job` sets `done`, `result`, `finished_at`, clears the lease. `fail_job`: retry and
  `attempts < max_attempts` → `queued`, `run_at = now() + least(interval '10 minutes', interval '30 seconds' * power(2,
  attempts - 1))`, the error kept, the lease cleared; else `failed`, `finished_at`. `cancel_job`: `is_member` (42501
  otherwise); queued, waiting or running → `cancelled`, `finished_at`; done or failed → false. `enqueue_job`: `is_member`
  (for a null centre only the platform passes, since `exists` on null is false and the claim clause is true for the
  service role); the insert `on conflict do nothing`, then the existing id by the key. Grants: the worker's six to
  `service_role` only (`revoke all … from public, anon, authenticated`); `enqueue_job` and `cancel_job` to `authenticated`
  and `service_role`.

- [ ] **Step 3: `supabase db reset`, then the two test files green; `supabase gen types typescript --local > types.ts`;
  `bun check --only=db` green. Commit; PR 3; merge.**

---

### Task 5: Migration 0029: the recorded call, the locked gate, the allowance, the sweep function (PR 4)

**Files:**
- Create: `supabase/migrations/20261103000029_v3_recorded_call.sql`, `supabase/tests/gate.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the four `start_ai_generation` tests keep passing; the catalogue's `ai_generations`
  insert in the isolation loop moves to the RPC, decision 8), `supabase/types.ts`

**Interfaces:**
- Produces: `start_ai_call(p_centre uuid, p_kind ai_kind, p_input jsonb, p_model text, p_student uuid default null, p_key
  text default null, p_input_hash text default null, p_request_id uuid default null, p_job uuid default null) returns
  jsonb` as `{ "id": uuid, "replay": boolean, "status": "pending"|"ok", "output": text|null }`; the exceptions
  `ai_not_a_member`, `ai_consent_missing`, `ai_limit_reached` (detail: the allowance), `ai_key_reused`;
  `close_pending_generations(p_older_than interval default '10 minutes') returns integer` (service role);
  the twelve columns of decision 10; `centres.ai_allowance`, `centres.ai_allowance_paise`.

- [ ] **Step 1: the failing tests (`supabase/tests/gate.test.ts`,** the same setup as `jobs.test.ts` with a user `a`, their
  centre, `svc` and `sql`):

```ts
const start = (args: Record<string, unknown>) => a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: { topic: "Fractions" }, p_model: "claude-haiku-5-5", ...args });

test("a first call makes a pending row with its key, hash, request id and user", async () => {
  const r = await start({ p_key: "k1", p_input_hash: "h1", p_request_id: "11111111-1111-1111-1111-111111111111" });
  expect(r.error).toBeNull();
  expect(r.data).toMatchObject({ replay: false, status: "pending" });
  const row = await sql`select idempotency_key, input_hash, request_id, user_id, job_id, status from public.ai_generations where id = ${r.data.id}`;
  expect(row[0]).toMatchObject({ idempotency_key: "k1", input_hash: "h1", request_id: "11111111-1111-1111-1111-111111111111", job_id: null, status: "pending" });
  expect(row[0].user_id).not.toBeNull();
});
test("the same key with the same body replays: pending while pending, the output once finished; never a new row", async () => {
  const first = await start({ p_key: "k2", p_input_hash: "h2" });
  const pending = await start({ p_key: "k2", p_input_hash: "h2" });
  expect(pending.data).toEqual({ id: first.data.id, replay: true, status: "pending", output: null });
  await a.from("ai_generations").update({ status: "ok", output: '{"q":1}', tokens_in: 5, tokens_out: 7, cost_paise: 3, latency_ms: 900, stop_reason: "end_turn", finished_at: new Date().toISOString() }).eq("id", first.data.id);
  const done = await start({ p_key: "k2", p_input_hash: "h2" });
  expect(done.data).toEqual({ id: first.data.id, replay: true, status: "ok", output: '{"q":1}' });
  expect((await sql`select count(*)::int as n from public.ai_generations where idempotency_key = 'k2'`)[0].n).toBe(1);
});
test("a key with another body is refused; a key whose row failed is a new call; a key older than a day is a new call", async () => {
  const first = await start({ p_key: "k3", p_input_hash: "h3" });
  expect((await start({ p_key: "k3", p_input_hash: "other" })).error?.message).toContain("ai_key_reused");
  await a.from("ai_generations").update({ status: "failed" }).eq("id", first.data.id);
  const again = await start({ p_key: "k3", p_input_hash: "h3" });
  expect(again.data.replay).toBe(false);
  await sql`update public.ai_generations set created_at = now() - interval '25 hours' where id = ${again.data.id}`;
  expect((await start({ p_key: "k3", p_input_hash: "h3" })).data.replay).toBe(false);
});
test("the allowance is the centre's column; two starts at once cannot both pass it", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`update public.centres set ai_allowance = 1 where id = ${centreA}`;
  const [one, two] = await Promise.all([start({ p_key: "race-1" }), start({ p_key: "race-2" })]);
  const errors = [one, two].filter((r) => r.error?.message.includes("ai_limit_reached"));
  expect(errors.length).toBe(1);
  expect(errors[0].error?.details).toBe("1");
  expect((await sql`select count(*)::int as n from public.ai_generations where centre_id = ${centreA}`)[0].n).toBe(1);
  await sql`update public.centres set ai_allowance = 600 where id = ${centreA}`;
});
test("a money cap, when set, is read from the month's cost", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`update public.centres set ai_allowance_paise = 100 where id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, cost_paise) values (${centreA}, 'sheet', '{}', 'ok', 100)`;
  expect((await start({})).error?.message).toContain("ai_limit_reached");
  await sql`update public.centres set ai_allowance_paise = 0 where id = ${centreA}`;
  expect((await start({})).error).toBeNull();
});
test("the owner cannot raise the allowance; Settings' columns still save", async () => {
  expect((await a.from("centres").update({ ai_allowance: 5000 }).eq("id", centreA)).error?.code).toBe("42501");
  expect((await a.from("centres").update({ ai_allowance_paise: 1 }).eq("id", centreA)).error?.code).toBe("42501");
  const ok = await a.from("centres").update({ name: "Gate A", upi_id: "gate@okbank", payment_link: "https://pay.example/g", send_receipts: false, whatsapp_number: "+919999999991", ai_consent_at: new Date().toISOString(), upi_confirmed_at: null }).eq("id", centreA).select("name").single();
  expect(ok.data).toEqual({ name: "Gate A" });
  expect((await svc.from("centres").update({ ai_allowance: 700 }).eq("id", centreA).select("ai_allowance").single()).data).toEqual({ ai_allowance: 700 });
  await sql`update public.centres set ai_allowance = 600 where id = ${centreA}`;
});
test("a row cannot be inserted around the gate; the platform and the seed can", async () => {
  expect((await a.from("ai_generations").insert({ centre_id: centreA, kind: "sheet", input: {} })).error?.code).toBe("42501");
  expect((await svc.from("ai_generations").insert({ centre_id: centreA, kind: "sheet", input: {}, status: "ok" })).error).toBeNull();
  expect((await sql`insert into public.ai_generations (centre_id, kind, input) values (${centreA}, 'sheet', '{}') returning id`).length).toBe(1);
});
test("the platform starts a call for a job with no user", async () => {
  const job = (await svc.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: `gate-job-${Date.now()}` })).data as string;
  const r = await svc.rpc("start_ai_call", { p_centre: centreA, p_kind: "plan", p_input: {}, p_model: "claude-sonnet-5-5", p_key: `${job}:name`, p_job: job });
  expect(r.error).toBeNull();
  const row = await sql`select user_id, job_id from public.ai_generations where id = ${r.data.id}`;
  expect(row[0]).toEqual({ user_id: null, job_id: job });
});
test("start_ai_generation still answers an id and shares the gate", async () => {
  const r = await a.rpc("start_ai_generation", { p_centre: centreA, p_kind: "homework", p_input: {}, p_model: "m" });
  expect(r.error).toBeNull();
  expect(typeof r.data).toBe("string");
});
test("close_pending_generations closes a 10-minute pending row and leaves a 2-minute one", async () => {
  await sql`delete from public.ai_generations where centre_id = ${centreA}`;
  await sql`insert into public.ai_generations (centre_id, kind, input, status, created_at) values
    (${centreA}, 'sheet', '{}', 'pending', now() - interval '11 minutes'), (${centreA}, 'sheet', '{}', 'pending', now() - interval '2 minutes')`;
  expect((await a.rpc("close_pending_generations")).error?.code).toBe("42501");
  expect((await svc.rpc("close_pending_generations")).data).toBe(1);
  const rows = await sql`select status, error_reason from public.ai_generations where centre_id = ${centreA} order by created_at`;
  expect(rows.map((r) => [r.status, r.error_reason])).toEqual([["failed", "swept"], ["pending", null]]);
});
```

  Run: `cd supabase && bun test tests/gate.test.ts`. Expected: all fail (no function, no columns).

- [ ] **Step 2: the migration.** The columns (decision 10; `job_id` references `jobs(id) on delete set null`, `user_id`
  plain uuid); indexes `ai_generations_key on (centre_id, idempotency_key) where idempotency_key is not null` and
  `ai_generations_request on (request_id) where request_id is not null`; `centres.ai_allowance` and `ai_allowance_paise`;
  the column grants (decision 9: `revoke update on public.centres from authenticated; grant update (…) …`); the extended
  `ai_generations` update grant (`status, output, model, tokens_in, tokens_out, cost_paise, latency_ms, prompt_version,
  prompt_hash, stop_reason, error_reason, fallback_model, finished_at`); the gate trigger:

```sql
create function public.ai_generations_gate_only() returns trigger language plpgsql set search_path = '' as $$
begin
  -- A row comes through start_ai_call (which sets tc.gate for its transaction), from the platform, or from no request at
  -- all (the seed, psql, the tests' fixtures); never from the app's own insert (the reading's W, 2026-10-12).
  if current_setting('tc.gate', true) is distinct from 'on'
     and coalesce((select auth.jwt() ->> 'role'), '') not in ('service_role', '') then
    raise exception 'ai_insert_through_the_gate' using errcode = '42501';
  end if;
  return new;
end $$;
create trigger ai_generations_gate before insert on public.ai_generations for each row execute function public.ai_generations_gate_only();
```

  `start_ai_call`: `is_member`; `perform 1 from public.centres c where c.id = p_centre for update` (the lock; the members'
  column update grant keeps `for update` allowed); the key lookup (`status <> 'failed'`, within a day, the newest): the hash
  differs → `ai_key_reused`; found → `jsonb_build_object('id', id, 'replay', true, 'status', status, 'output', output)`;
  the consent checks as 0027; the limit: V1 as before; V2: `v_limit := c.ai_allowance`, and when `c.ai_allowance_paise > 0`
  the month's `sum(cost_paise)` at or over it also raises `ai_limit_reached` with the allowance as detail; `perform
  set_config('tc.gate', 'on', true)`; the insert with `idempotency_key, input_hash, request_id, job_id, user_id = auth.uid()`;
  the answer with `replay false`. `start_ai_generation` (same signature) becomes `select (public.start_ai_call(p_centre,
  p_kind, p_input, p_model, p_student) ->> 'id')::uuid`. `close_pending_generations` as decision 28, granted to
  `service_role` only. Grants on `start_ai_call`: `authenticated` and `service_role`.

- [ ] **Step 3: `rls.test.ts`.** The isolation loop's `ai_generations` entry becomes `null` and its row is made by
  `a.rpc("start_ai_generation", …)` before the loop (as `students` and `plans` are). `supabase db reset`; `bun test tests`;
  `types.ts`; `bun check --only=db` green. Commit; PR 4; merge.

---

### Task 6: Migrations 0030 and 0031: `events`, `api_requests`, `alerts`, `admin_audit`, `device_tokens` (PR 5)

**Files:**
- Create: `supabase/migrations/20261104000030_v3_observability.sql`, `supabase/migrations/20261105000031_v3_device_tokens.sql`
- Modify: `supabase/tests/rls.test.ts`, `supabase/types.ts`

- [ ] **Step 1: the failing tests (in `rls.test.ts`):** the catalogue list gains the five names; `CENTRE_TABLES` gains
  `events` with the insert `{ kind: "tab_opened", screen: "today", at: new Date().toISOString() }` (a member may insert
  and read their own); `PLATFORM_TABLES` gains `api_requests` (read by the centre's member), `alerts` and `admin_audit`
  (read by no member even for their centre: `using (false)`); new tests:

```ts
test("an event is the member's own, of a kind the check allows, and cannot be changed", async () => {
  const { data: me } = await a.auth.getUser();
  const ok = await a.from("events").insert({ centre_id: centreA, kind: "app_opened", at: new Date().toISOString() }).select("user_id").single();
  expect(ok.data!.user_id).toBe(me.user!.id);
  expect((await a.from("events").insert({ centre_id: centreA, kind: "Opened App", at: new Date().toISOString() })).error).not.toBeNull();
  expect((await a.from("events").insert({ centre_id: centreA, kind: "app_opened", at: new Date().toISOString(), user_id: "00000000-0000-0000-0000-000000000000" })).error).not.toBeNull();
  expect((await a.from("events").update({ kind: "signed_in" }).eq("centre_id", centreA).select("id")).data).toEqual([]);
  expect((await a.from("events").delete().eq("centre_id", centreA).select("id")).data).toEqual([]);
});
test("a device token is its user's alone, one per device, and the environment is sandbox or production", async () => {
  const ok = await a.from("device_tokens").insert({ device_id: "sim-1", token: "abc", environment: "sandbox", app_build: 27 }).select("id").single();
  expect(ok.error).toBeNull();
  expect((await a.from("device_tokens").upsert({ device_id: "sim-1", token: "def", environment: "sandbox" }, { onConflict: "user_id,device_id" })).error).toBeNull();
  expect((await a.from("device_tokens").select("token")).data).toEqual([{ token: "def" }]);
  expect((await b.from("device_tokens").select("id")).data).toEqual([]);
  expect((await a.from("device_tokens").insert({ device_id: "sim-2", token: "x", environment: "staging" })).error).not.toBeNull();
});
```

  Run: `cd supabase && bun test tests/rls.test.ts`. Expected: the catalogue test and the new ones fail.

- [ ] **Step 2: the migrations** as decision 13: `events` (`user_id uuid not null default auth.uid() references
  auth.users(id) on delete cascade`, the kind check, `screen` ≤ 40, `at`, an index `(centre_id, at)`; policies: insert `with
  check (public.is_member(centre_id) and user_id = auth.uid())`, select `using (public.is_member(centre_id))`; `revoke
  update, delete`); `api_requests` (an index on `created_at`, one on `(user_id, created_at)`; select for members by
  `centre_id`; `revoke insert, update, delete`); `alerts` and `admin_audit` (`create policy … for select to authenticated
  using (false)`; `revoke insert, update, delete`); `device_tokens` (`unique (user_id, device_id)`, the environment check;
  `create policy device_tokens_self for all to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid())`).
  Each table's `updated_at` trigger.

- [ ] **Step 3: `supabase db reset`; tests green; `types.ts`; `bun check --only=db`. Commit; PR 5; merge.**

---

### Task 7: Migrations 0032 and 0033: `consent_events`; `keep_artefact`'s key; one absence log a day (PR 6)

**Files:**
- Create: `supabase/migrations/20261106000032_v3_consent_events.sql`, `supabase/migrations/20261107000033_v3_idempotent_writes.sql`
- Modify: `supabase/tests/v2.test.ts`, `supabase/tests/rls.test.ts` (the catalogue), `supabase/types.ts`

- [ ] **Step 1: the failing tests (`v2.test.ts`, in its style on the shared centre):**

```ts
test("consent given, changed and withdrawn write their history; the backfill wrote the seed's", async () => {
  const s = await a.from("students").insert({ centre_id: centre, name: "History Child" }).select("id").single();
  await a.from("students").update({ consent_at: "2026-10-01T04:00:00Z", consent_phone: "+919876500011", consent_how: "in_person" }).eq("id", s.data!.id);
  await a.from("students").update({ consent_phone: "+919876500012" }).eq("id", s.data!.id);
  await a.from("students").update({ consent_at: null, consent_phone: null, consent_how: null }).eq("id", s.data!.id);
  const rows = await a.from("consent_events").select("kind, phone, how, at, by_user").eq("student_id", s.data!.id).order("created_at");
  expect(rows.data!.map((r) => [r.kind, r.phone, r.how])).toEqual([["given", "+919876500011", "in_person"], ["given", "+919876500012", "in_person"], ["withdrawn", null, null]]);
  expect(rows.data![0].at).toBe("2026-10-01T04:00:00+00:00");
  expect(rows.data![0].by_user).not.toBeNull();
  expect((await a.from("consent_events").delete().eq("student_id", s.data!.id).select("id")).data).toEqual([]);
  expect((await b.from("consent_events").select("id").eq("student_id", s.data!.id)).data).toEqual([]);
});
test("keep_artefact with a key keeps once", async () => {
  const params = { p_centre: centre, p_artefact: { kind: "sheet", source: "made", title: "Keyed", content: {} }, p_plan: null, p_group_no: null, p_student: null, p_item_kind: null, p_school_item: null, p_made_from: "make", p_key: "gen-keyed-1" };
  const first = await a.rpc("keep_artefact", params);
  expect(first.error).toBeNull();
  expect((await a.rpc("keep_artefact", params)).data).toBe(first.data);
  expect((await a.from("artefacts").select("id").eq("idempotency_key", "gen-keyed-1")).data?.length).toBe(1);
  expect((await a.rpc("keep_artefact", { ...params, p_key: null })).data).not.toBe(first.data);
});
test("one absence log per child and day", async () => {
  const s = await a.from("students").select("id").eq("name", "Aarav Mehta").single();
  const first = await a.from("message_log").insert({ centre_id: centre, student_id: s.data!.id, kind: "absence", about_date: "2026-10-09" }).select("id").single();
  expect(first.error).toBeNull();
  const again = await a.from("message_log").insert({ centre_id: centre, student_id: s.data!.id, kind: "absence", about_date: "2026-10-09" });
  expect(again.error?.code).toBe("23505");
  expect((await a.from("message_log").insert({ centre_id: centre, student_id: s.data!.id, kind: "reminder", about_date: "2026-10-09" })).error).toBeNull();
});
```

  The catalogue gains `consent_events`; `CENTRE_TABLES` gains it with insert `null` and a row made by a consent update on
  the loop's student before it. A seed assertion in `v2.test.ts`'s setup block: `select count(*) from consent_events`
  equals the seed's students with `consent_at` set, each `given`.

  Run: `cd supabase && bun test tests/v2.test.ts tests/rls.test.ts`. Expected: fail.

- [ ] **Step 2: the migrations.** 0032: the table (`kind text check (kind in ('given', 'withdrawn'))`, `phone`, `how`,
  `at timestamptz not null`, `by_user uuid`, the composite student key on delete cascade), RLS (select and insert for
  members; `revoke update, delete`), the trigger function `students_consent_history()` (`after insert or update of
  consent_at, consent_phone, consent_how`: the three cases of decision 14, `by_user = auth.uid()`), the backfill insert.
  0033: `alter table public.artefacts add column idempotency_key text`; `create unique index artefacts_key on
  public.artefacts (centre_id, idempotency_key) where idempotency_key is not null`; `keep_artefact` re-created with
  `p_key text default null` (the 0026 body plus: `if p_key is not null then select id into v_id from public.artefacts
  where centre_id = p_centre and idempotency_key = p_key; if found then return v_id; end if; end if;` and the key on the
  insert); `create unique index message_log_one_absence_a_day on public.message_log (centre_id, student_id, about_date)
  where kind = 'absence'` (the seed has at most one a day; the migration's comment says a duplicate in production, if any,
  must be removed first and the deploy's dry run would show the failure, so the build checks production's count by a
  `select` in the ledger before Deploy 1: `select student_id, about_date, count(*) from message_log where kind = 'absence'
  group by 1, 2 having count(*) > 1`, run through `run-job`'s sibling step or asked of the owner's dashboard SQL editor).

- [ ] **Step 3: `supabase db reset`; tests green; `types.ts`; `bun check --only=db`. Commit; PR 6; merge.**

---

### Task 8: The contract: generated types both ways, the check step, the first contract tests (PR 7)

**Files:**
- Create: `tools/contract.ts`, `tools/contract.test.ts`, `api/src/contract.ts`, `api/test/contract.test.ts`,
  `api/src/generated/database.ts` (generated), `ios/TutorCentralKit/Sources/Domain/Generated/APIContract.swift`
  (generated), `ios/TutorCentralKit/Tests/DataTests/Contract/*.json` (generated), `ios/TutorCentralKit/Tests/DataTests/ContractTests.swift`
- Modify: `tools/check/steps.ts`, `package.json` (`"contract": "bun tools/contract.ts"`), `ios/TutorCentralKit/Package.swift`
  (`DataTests` resources), `api/src/db.ts` (typed clients), `api/tsconfig.json` (`resolveJsonModule` already; nothing),
  the Swift files whose literals the contract replaces: `Sources/Data/AI/APIClient.swift` (`bodyLimit`),
  `Sources/Data/AI/APIBodies+Parents.swift` (the `cut` counts and lengths: 6/200, 3, 3/200, 4/80, 160, 3/80, 3/200,
  4/200, 12/80), `Sources/Data/AI/APIBodies+School.swift` (`maxDays`, `maxSkills`), `Sources/Domain/…` where `tutorSays`'s
  300 and the pages' 6 live (found by `grep -rn "300\|maxPages\|== 6" Sources/Domain Sources/Data/AI`)

**Interfaces:**
- Produces: `APIContract` (Swift, `public enum APIContract` with `static let` integers and `[String]` lists), the
  `Database` type for `api/src/db.ts`, the sample files `Contract/<kind>.json` (one per `SAMPLE` key of `claude-fake.ts`,
  the fake's answer for that kind as the API would send `result`).
- `api/src/contract.ts` exports `contract(): { limits: Record<string, number>; lists: Record<string, string[]> }`, read
  from the zod schemas (`MakeInput.options[…].shape.tutorSays.maxLength` and so on; zod 4 exposes `minLength`/`maxLength`
  on string schemas and `minimum`/`maximum` on numbers, `Image`'s `imageBase64` max, `CheckPaperInput`'s pages max), with
  `lists.eventKinds = ["app_opened", "signed_in", "signed_out", "tab_opened", "link_opened"]` (a constant here, the
  database's check is the regex) and `lists.errorReasons = ["invalid", "consent", "student_consent", "member",
  "unreachable", "in_progress", "key_reused", "rate"]`.

- [ ] **Step 1: the failing tests.** `tools/contract.test.ts`: `renderSwift({limits:{tutorSaysMax:300},lists:{eventKinds:["a"]}})`
  contains `public static let tutorSaysMax = 300` and `public static let eventKinds = ["a"]` and the header `// Generated by
  bun contract from api/src/schemas.ts. Do not edit.`; `databaseFile("export type Json = …")` starts with the header and
  ends with the source; `check()` returns the three paths that differ when a temp copy is edited. `api/test/contract.test.ts`:
  `contract().limits` has `tutorSaysMax: 300`, `sheetSkillsMax: 6`, `checkSkillsMax: 3`, `pagesMax: 6`, `imageBase64Max:
  4_000_000`, `planGroupsMax: 3`; every number is an integer; `samples()` has a key per `SAMPLE` kind. Swift
  `ContractTests`: for each JSON in `Contract/`, decode with the app's decoder for that kind (`GenerationResult.decode` for
  V1's four, `ScanEnvelope`'s rows, `CheckEnvelope`'s result, the V2 `Made*` decoders through `APIClient`'s private helpers
  made `internal` for the test) and `#expect` non-nil; a `DomainTests/APIContractTests`: `APIContract.tutorSaysMax == 300`
  and `APIContract.eventKinds.count == 5` (the generated file compiles and carries the values).
  Run: `bun test tools api/test/contract.test.ts` and the Swift targets. Expected: fail (nothing generated yet).

- [ ] **Step 2: `tools/contract.ts`.** Reads `supabase/types.ts` → `api/src/generated/database.ts`; runs
  `bun -e 'import { contract, samples } from "./api/src/contract.ts"; console.log(JSON.stringify({ contract: contract(), samples: samples() }))'`
  (from the repo root, cwd `api` so its imports resolve) → renders the Swift file (`// swiftformat:disable all` on top so
  the generated layout is not fought, and `swiftlint:disable` for the file; both tools still run on the rest) and the
  sample files (JSON, two-space, sorted keys). `--check`: render to the scratch directory and `diff -q` each; print the
  stale paths and exit 1. `tools/check/steps.ts`: the `tools` step's inputs gain `supabase/types.ts`, `api/src/schemas.ts`,
  `api/src/contract.ts`, `api/src/claude-fake.ts`, and its run gains `await run("bun tools/contract.ts --check")`; the
  `api` step's inputs already cover `src/**`; the `ios` step's inputs cover the Swift.

- [ ] **Step 3: the consumers.** `api/src/db.ts`: `createClient<Database>(…)` with `import type { Database } from
  "./generated/database.js"`; the `rpc` calls now type-check their argument names (`tsc` will point at any drift; fix the
  call, not the type). The Swift literals named above become `APIContract.<name>` (a test per changed site is not
  needed: the values are equal and the existing tests hold them; `bun check` proves the build). `Package.swift`:
  `.testTarget(name: "DataTests", dependencies: ["Data"], resources: [.copy("Contract")])`.

- [ ] **Step 4: `bun contract`; `bun check` green (every step: the Swift changes rebuild iOS); commit the generated files
  with the tool; PR 7; merge.** `CLAUDE.md`'s commands table gains `bun contract`.

---

### Task 9: The API's envelope: request ids, JSON logs, `api_requests`, the limits, the fakes refused, `maxDuration` (PR 8)

**Files:**
- Create: `api/src/log.ts`, `api/src/request.ts`, `api/src/observe.ts`, `api/src/observe-fake.ts`, `api/test/log.test.ts`,
  `api/test/request.test.ts`
- Modify: `api/src/env.ts`, `api/src/index.ts`, `api/src/make-app.ts` (`Deps` gains `observe: Observe`), `api/src/errors.ts`
  (`rate`, `tooLarge`), `api/src/auth.ts` (logs), `api/src/claude.ts` and `api/src/db.ts` (`console.error` → `log`),
  `api/vercel.json`, `api/.env.example`, `api/test/entry.test.ts`, `api/test/app.test.ts`, `api/test/ai.test.ts`

**Interfaces:**
- Produces: `type Observe = { recordRequest(row: RequestRow): Promise<void>; recentCount(userId: string, seconds: number):
  Promise<number> }` where `RequestRow = { requestId, route, method, status, latencyMs, userId?, centreId?, reason? }`;
  `makeObserve(url, serviceKey): Observe`; `fakeObserve(): Observe & { rows: RequestRow[]; recent: number }`;
  `log.info|warn|error(fields: Record<string, unknown>)` printing one JSON line with `t` and `level`;
  `Vars` gains `requestId: string` and `bodyHash: string` (set by `parse`, Task 10).

- [ ] **Step 1: the failing tests.** `log.test.ts`: `line("info", { requestId: "r", route: "/x" })` is parseable JSON with
  `level`, `t` (ISO), the fields; a nested `Error` becomes `{ name, message }`. `request.test.ts` (through `makeApp` with
  `fakeObserve`): `a request without X-Request-Id gets one and the row records it` (the response header `X-Request-Id` is a
  UUID; `observe.rows[0]` has `route: "/ai/generate"`, `status`, `latencyMs >= 0`, `userId: "u1"`, `centreId`); `a valid
  X-Request-Id is kept, a malformed one replaced`; `/health leaves no row`; `the 21st call in a minute is 429 rate and leaves
  a row with reason rate` (`fakeObserve.recent = 20`); `a body over the limit is 413 in words before any call` (`db.started`
  empty); `an unreachable observe does not fail the answer` (`recordRequest` throws → the answer is still 200, the error
  logged). `entry.test.ts`: `the entry refuses AI_FAKE and APPLE_FAKE in production` (spawn with `VERCEL_ENV=production
  AI_FAKE=1` and the other env it already sets; exit non-zero with "refused in production" on stderr); `the entry needs
  SUPABASE_SERVICE_ROLE_KEY and WORKER_SECRET` (the missing-name message).
  Run: `cd api && bun test`. Expected: fail.

- [ ] **Step 2: the code.** `request.ts`: `makeRequest(observe)` middleware on every route: reads or makes the request
  id, sets `c.set("requestId")` and the response header, times `next()`, then (not for `/health`) `await observe.recordRequest`
  in a try that logs a failure, and `log.info` the line. `makeRateLimit(observe, perMinute = 20)` after `requireUser`:
  `recentCount(userId, 60) >= perMinute` → `answer(c, errors.rate())`; the in-memory IP map (`c.req.header("x-forwarded-for")`'s
  first address, a `Map<string, number[]>` pruned each call, 60 a minute). `bodyLimit({ maxSize: 4_400_000, onError: (c) =>
  answer(c, errors.tooLarge()) })` from `hono/body-limit` on `/ai/*`. `errors.rate = { status: 429, body: { error: "Too
  many requests in a minute. Try again shortly.", reason: "rate" } }` and `errors.tooLarge = { status: 413, body: { error:
  "That's too many pages. Up to six, and try sharper, smaller photos." } }` (the app's own words for the same case).
  `observe.ts`: the service client (`createClient<Database>(url, serviceKey, …)`), `recordRequest` inserts into
  `api_requests`, `recentCount` counts `api_requests` by `user_id` and `created_at > now() - seconds`. `env.ts` gains
  `SUPABASE_SERVICE_ROLE_KEY` and `WORKER_SECRET`. `index.ts`: the production refusal (decision 27), `makeObserve(url,
  env("SUPABASE_SERVICE_ROLE_KEY"))`, `WORKER_SECRET` read (used by Task 11). `vercel.json`:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "regions": ["bom1"],
  "git": { "deploymentEnabled": false },
  "functions": { "src/index.ts": { "maxDuration": 300 } }
}
```

  No `crons` (D85: the minute wake is pg_cron's, Task 11). The `functions` pattern is verified with `bun x vercel@59.19.0
  build` locally (the `.vc-config.json` under `.vercel/output/functions` names `maxDuration: 300`); if the Hono builder
  names its function otherwise, the pattern is changed to the path it prints, and the ledger says which.

- [ ] **Step 3: `bun run check` in `api`; `bun check --only=api` green; commit; PR 8; merge.** `.env.example` gains the two
  names and loses the sentence "The service role key is never used by this API" (the rule file changes in Task 18).

---

### Task 10: The recorded call in the API: `start_ai_call`, keys, cost, latency, stop reason, tokens on every answer (PR 9)

**Files:**
- Create: `api/src/price.ts`, `api/test/price.test.ts`
- Modify: `api/src/db.ts` (`startCall`, `finish`), `api/src/db-fake.ts`, `api/src/claude.ts`, `api/src/claude-fake.ts`,
  `api/src/routes/common.ts` (`run`, `parse` sets the body hash), `api/src/errors.ts` (`inProgress`, `keyReused`),
  `api/test/claude.test.ts`, `api/test/claude-fake.test.ts`, `api/test/ai.test.ts`, `api/test/v2.test.ts`, `api/test/db-fake.test.ts`,
  `tools/cost.ts` and `tools/cost.test.ts` (`cost_paise` summed where set, tokens priced otherwise)

**Interfaces:**
- Produces: `Db.startCall(token, { centre, kind, input, model, student?, key?, inputHash?, requestId?, job? }): Promise<{
  id: string; replay: boolean; status: "pending" | "ok"; output: string | null }>`; `Finish` gains `costPaise, latencyMs,
  promptHash, stopReason, errorReason, finishedAt`; `ClaudeAnswer` becomes `{ kind: "ok" | "refused" | "truncated" |
  "failed"; model; tokensIn: number | null; tokensOut: number | null; stopReason: string | null; latencyMs: number; reason?:
  string; parsed?: T }`; `costPaise(model, tokensIn, tokensOut): number | null`; `promptHash(system): string`.
  The worker (Task 11) calls `startCall` and `finish` with the service client through the same `makeDb` given the service
  key: `makeDb(url, anonKey)` gains a sibling `makePlatformDb(url, serviceKey)` whose `startCall` passes no token.

- [ ] **Step 1: the failing tests.** `price.test.ts`: `costPaise("claude-haiku-5-5", 1_000_000, 0)` is `850`
  (0.1 × 85 × 100); `costPaise("unknown", 1, 1)` is null; rounding to the nearest paisa. `claude.test.ts` (its fake fetch):
  `an answer carries tokens, stop reason and latency`; `a refusal carries its tokens` (stop_reason `refusal` with usage);
  `an answer that does not fit the schema is refused with its tokens`; `max_tokens is truncated, with tokens`; `a timeout is
  failed with reason timeout and no tokens`. `ai.test.ts` / `v2.test.ts`: `the key and request id reach start and the row is
  finished with cost, latency, hash and stop reason` (`db.started[0]` has `key: "k"`, `inputHash` 64 hex, `requestId`; `db.finished[0]`
  has `costPaise` from the fake's 812/1460 tokens on Sonnet, `latencyMs >= 0`, `promptHash` 64 hex, `stopReason: "end_turn"`);
  `a replayed key answers the stored result with the header and no call` (`fakeDb({ replays: { k: { status: "ok", output:
  "{…}" } } })`; `claude.requests` empty; header `Idempotent-Replayed: true`); `a pending key answers 409 in_progress`; `a
  reused key with another body is 409 key_reused` (`fakeDb` throws `DbFailure("key_reused")`); `a call without a key is
  recorded and never replayed`; `a truncated answer is 502 and the row says truncated`; `a refused answer records its tokens`.
  `cost.test.ts`: rows with `cost_paise` sum it; rows without are priced by tokens.
  Run: `cd api && bun test; bun test tools/cost.test.ts`. Expected: fail.

- [ ] **Step 2: the code.** `claude.ts` as decision 11: `client.messages.create({ …, output_config: { effort, format:
  zodOutputFormat(schema) } })`, `latencyMs` around it, the text block parsed with `schema.safeParse(JSON.parse(text))`
  (a parse failure → `refused` with `reason: "unfit"` and the tokens), `stop_reason` `refusal` → `refused`, `max_tokens` →
  `truncated`; the catch as before with `reason`. `common.ts` `parse` sets `c.set("bodyHash", sha256(rawBody))` (the raw
  text read once with `c.req.text()` then parsed). `run`: `key = c.req.header("idempotency-key")` (≤ 200 chars else
  ignored), `requestId = c.get("requestId")`; `startCall`; `replay && status === "ok"` → `c.json({ id, result:
  JSON.parse(output) }, 200, { "Idempotent-Replayed": "true" })`; `replay && pending` → `errors.inProgress()` (409, the
  app's timed-out words); `DbFailure("key_reused")` → `errors.keyReused()` (409, "That didn't go through. Try again.",
  checked against `docs/design/feedback.md`); then the call, and `finish` with `costPaise(result.model, tokens)`,
  `latencyMs`, `promptHash(call.request.system)`, `stopReason`, `errorReason` (`refused`/`unfit`/`truncated`/the failure's
  reason), `finishedAt`; a `truncated` answer → `errors.service()`. `db.ts` maps the new exceptions (`ai_key_reused` →
  `DbFailure("key_reused")`). `tools/cost.ts`: `coalesce(cost_paise, …)` in its query and a `paise` column in its sum.

- [ ] **Step 3: `bun check --only=api,tools` green; commit; PR 9; merge.** Then **Deploy 1** (Task 16 step 1).

---

### Task 11: The worker: the lease loop with a fake clock, the two routes, the cron, the wake trigger, the sweep (PR 10)

**Files:**
- Create: `api/src/jobs/types.ts`, `api/src/jobs/db.ts`, `api/src/jobs/db-fake.ts`, `api/src/jobs/runner.ts`,
  `api/src/jobs/kinds/index.ts`, `api/src/jobs/kinds/sweep.ts`, `api/src/routes/jobs.ts`, `api/test/jobs-db.test.ts`,
  `api/test/runner.test.ts`, `api/test/jobs-routes.test.ts`, `supabase/migrations/20261108000034_v3_wake_worker.sql`,
  `supabase/tests/wake.test.ts`
- Modify: `api/src/make-app.ts` (`Deps` gains `jobs: JobsDb`, `workerSecret: string`, `clock?: Clock`), `api/src/index.ts`,
  `supabase/types.ts`, `docs/runbooks/simulator.md` (section 12: the worker locally)

**Interfaces:**
- `types.ts`:

```ts
export type JobKind = "plan" | "artefact" | "note_day" | "reminder_sweep" | "export" | "pdf" | "eval_run" | "sweep";
export type Job = { id: string; centreId: string | null; kind: JobKind; attempts: number; step: Record<string, unknown>; input: Record<string, unknown>; leaseUntil: string };
export type StepOutcome =
  | { kind: "continue"; name: string; step: Record<string, unknown>; generationId?: string; costPaise?: number }
  | { kind: "done"; name: string; result: Record<string, unknown>; generationId?: string; costPaise?: number }
  | { kind: "wait"; name: string; step: Record<string, unknown>; runAt: Date; generationId?: string }
  | { kind: "fail"; name: string; error: { reason: string; message?: string }; retry: boolean; generationId?: string };
export type StepContext = { db: Db; jobs: JobsDb; claude: ClaudeClient; clock: Clock; requestId: string; worker: string; deadlineMs: number };
export type JobHandler = { step(job: Job, ctx: StepContext): Promise<StepOutcome> };
export type Clock = { now(): number; sleep(ms: number): Promise<void> };
export type JobsDb = {
  claim(worker: string, limit: number): Promise<Job[]>;
  extend(job: string, worker: string): Promise<boolean>;
  record(job: string, worker: string, outcome: StepOutcome, attempt: number): Promise<void>;  // record_step, then wait/finish/fail
  enqueue(centre: string | null, kind: JobKind, key: string, input?: Record<string, unknown>, runAt?: Date): Promise<string>;
  live(kind: JobKind): Promise<number>;  // queued or running jobs of a kind (the tick's sweep guard)
  closePending(): Promise<number>;
};
```

- `runner.ts`: `drain(opts: { jobs: JobsDb; handlers: Record<JobKind, JobHandler>; ctx: Omit<StepContext, "jobs" | "worker" |
  "deadlineMs">; worker: string; budgetMs: number; limit?: number }): Promise<{ claimed: number; steps: number; done: number;
  waiting: number; failed: number; lost: number }>`.
- `routes/jobs.ts`: `GET /jobs/tick` and `POST /jobs/wake`, both behind the bearer `workerSecret` (constant-time compare),
  both running `drain` with `budgetMs` 200 000 (the tick first enqueues the hour's `sweep` when `live("sweep") === 0`);
  401 `{ error: "sign in again" }` without the bearer (the same body the AI routes give, so nothing new leaks).

- [ ] **Step 1: the failing tests.** `runner.test.ts` with `fakeJobsDb(clock)` and a fake clock (`now` advanced by the
  test; `sleep` advances it):

```ts
test("a job's steps run in order in one run while the budget allows, and done is written once", …);  // three "continue" then "done": steps 4, done 1, the fake's rows in order
test("the budget ends between steps: the job waits at the step reached and the next run continues there", …);  // budget covers two steps; drain twice; the handler sees step {at:"name"} on the second run
test("a step whose lease was taken stops the worker", …);  // the fake marks the lease taken by "w2" during step 2; record throws job_lease_lost; result.lost 1; no further step for that job
test("a step that meets an in-progress key waits", …);  // the handler returns wait with runAt +30 s; the row is waiting; a drain before runAt claims nothing; after, it continues
test("a cancelled job's step records its generation and stops", …);  // the fake cancels during the step; record throws job_cancelled after writing the step row with generationId
test("a failing step retries with backoff and fails after max_attempts", …);  // fake clock; attempts 3; the third fail leaves failed
test("the lease is extended before each step", …);  // the fake counts extend calls = steps
test("two workers draining at once never run the same job's step twice", …);  // the fake's claim hands each job to one worker (skip locked semantics); Promise.all of two drains
```

  `jobs-db.test.ts` (against the local stack, skipped when `supabase status` is not 0, as the RLS tests are run only in
  the db step — this file runs under `bun check --only=api` only when the stack is up; the `skipIf` prints why): the real
  `JobsDb` over the service client enqueues, claims, records a `continue`, a `wait`, a `done`, a `fail`, and `closePending`
  returns an integer. `jobs-routes.test.ts`: `tick without the secret is 401`; `tick with it drains and answers the counts`;
  `wake with it drains`; `the tick enqueues the hour's sweep once` (two ticks, one sweep job in the fake); `a sweep step
  calls closePending and is done`. `supabase/tests/wake.test.ts`:

```ts
test("queuing a job posts to the worker when the secrets are set, and does nothing when they are not", async () => {
  const sql = new SQL(l.db);
  try {
    await sql.begin(async (tx) => {
      await tx`insert into public.jobs (centre_id, kind, idempotency_key) values (${centreA}, 'plan', 'wake-none')`;
      expect((await tx`select count(*)::int as n from net.http_request_queue`)[0].n).toBe(0);
      throw new Error("rollback");
    }).catch(() => {});
    await sql.begin(async (tx) => {
      await tx`select vault.create_secret('http://127.0.0.1:3000', 'worker_url')`;
      await tx`select vault.create_secret('s3cret', 'worker_secret')`;
      await tx`insert into public.jobs (centre_id, kind, idempotency_key) values (${centreA}, 'plan', 'wake-one')`;
      const q = await tx`select url, headers from net.http_request_queue`;
      expect(q[0].url).toBe("http://127.0.0.1:3000/jobs/wake");
      expect(q[0].headers.Authorization).toBe("Bearer s3cret");
      throw new Error("rollback");
    }).catch(() => {});
  } finally { await sql.close(); }
});
test("the minute wake is scheduled and reads the same secrets", async () => {
  const sql = new SQL(l.db);
  try {
    const job = await sql`select schedule, command, active from cron.job where jobname = 'wake_worker_minute'`;
    expect(job[0]).toEqual({ schedule: "* * * * *", command: "select public.wake_worker_tick()", active: true });
    await sql.begin(async (tx) => {
      await tx`select vault.create_secret('http://127.0.0.1:3000', 'worker_url')`;
      await tx`select vault.create_secret('s3cret', 'worker_secret')`;
      await tx`select public.wake_worker_tick()`;
      const q = await tx`select method, url, headers from net.http_request_queue`;
      expect(q[0]).toMatchObject({ method: "GET", url: "http://127.0.0.1:3000/jobs/tick" });
      expect(q[0].headers.Authorization).toBe("Bearer s3cret");
      throw new Error("rollback");
    }).catch(() => {});
  } finally { await sql.close(); }
});
test("wake_worker is nobody's to call", async () => {
  expect((await a.rpc("wake_worker")).error).not.toBeNull();  // a trigger function: not callable through PostgREST at all
});
```

  Run: `cd api && bun test`; `cd supabase && bun test tests/wake.test.ts`. Expected: fail.

- [ ] **Step 2: the code.** `db.ts`: the real `JobsDb` over `createClient<Database>(url, serviceKey)` calling the eight
  functions; `record` maps an outcome to `record_step` (+ `p_generation`, `p_cost_paise`, `p_step_data`) then `wait_job` /
  `finish_job` / `fail_job`; a `PostgrestError` whose message contains `job_lease_lost` or `job_cancelled` becomes
  `LeaseLost`. `runner.ts`: claim up to `limit` (5); for each job while `clock.now() - start < budgetMs - 120_000`
  (room for one step: the Claude deadline plus the writes): `extend`, `handlers[job.kind].step(job, ctx)`, `record`;
  `continue` → the job's `step` updated in memory and the loop goes on; anything else → next job; `LeaseLost` → `lost++`
  and next job; a thrown error from a handler → `record` a `fail` with `reason: "error"` and `retry: true`, logged with the
  request id. Out of budget mid-job → `record({ kind: "wait", step: job.step, runAt: now })`. `kinds/sweep.ts`: one step
  `pending` → `closePending()` → `done { closed: n }`. `routes/jobs.ts` as the interface says; the worker name is
  `${process.env.VERCEL_REGION ?? "local"}-${crypto.randomUUID().slice(0, 8)}` per run. `index.ts` builds `jobs` with the
  service key and passes `workerSecret: env("WORKER_SECRET")`. The migration 0034: `create extension if not exists pg_net with
  schema extensions;` the function:

```sql
-- The third security definer function (D37, D83): vault.decrypted_secrets is readable by postgres alone, and the worker's
-- address and secret must never be in a migration (D11). It does nothing when the secrets are absent: the cron drains.
create function public.wake_worker() returns trigger language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return new; end if;
  perform net.http_post(
    url := v_url || '/jobs/wake',
    headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_secret),
    body := jsonb_build_object('job', new.id),
    timeout_milliseconds := 3000);
  return new;
exception when others then
  return new;  -- a wake that cannot be queued never blocks the insert; the next tick takes the job
end $$;
revoke all on function public.wake_worker() from public, anon, authenticated;
create trigger jobs_wake after insert on public.jobs for each row execute function public.wake_worker();

-- The minute wake (D85: pg_cron in place of Vercel Cron). The same secrets; a GET, as the smoke makes it.
create function public.wake_worker_tick() returns void language plpgsql security definer set search_path = '' as $$
declare v_url text; v_secret text;
begin
  select decrypted_secret into v_url from vault.decrypted_secrets where name = 'worker_url';
  select decrypted_secret into v_secret from vault.decrypted_secrets where name = 'worker_secret';
  if v_url is null or v_secret is null then return; end if;
  perform net.http_get(url := v_url || '/jobs/tick', headers := jsonb_build_object('Authorization', 'Bearer ' || v_secret),
                       timeout_milliseconds := 3000);
end $$;
revoke all on function public.wake_worker_tick() from public, anon, authenticated;
create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;
select cron.schedule('wake_worker_minute', '* * * * *', 'select public.wake_worker_tick()');
```

  `pg_cron` runs its jobs as the role that scheduled them (`postgres` here), so the definer function reads Vault; its runs
  are in `cron.job_run_details` (the owner's dashboard shows them under Integrations → Cron). Phase 18 adds its schedules
  beside this one. The local image preloads `pg_cron`; `supabase db reset` keeps the schedule.

  `docs/runbooks/simulator.md` section 12: the local API with the local service key and `WORKER_SECRET=local` in
  `api/.env.local`; `psql … -c "select enqueue_job('<centre>', 'plan', 'plan:<class>:<date>', '{"class_id": "…", "date": "…"}')"`
  (as the superuser the claim clause is false and `is_member` fails: the runbook queues through the service client instead:
  `bun -e` with supabase-js, or `curl` to PostgREST `rpc/enqueue_job` with the service key); `curl -H "Authorization: Bearer
  local" http://127.0.0.1:3000/jobs/tick`; the job's row and steps read back.

- [ ] **Step 3: `bun check --only=api,db` green (the runbook's commands run once by hand against the local stack with a
  `sweep`: the ledger records the tick's answer and the job's rows); commit; PR 10; merge.**

---

### Task 12: The plan rules in TypeScript, equal to Domain's on shared cases (PR 11)

**Files:**
- Create: `api/src/plan/types.ts`, `api/src/plan/dates.ts`, `api/src/plan/spaced.ts`, `api/src/plan/hints.ts`,
  `api/src/plan/exam.ts`, `api/src/plan/step.ts`, `api/src/plan/rules.ts`, `api/test/plan-rules.test.ts`,
  `tools/contract/plan-cases.json`, `ios/TutorCentralKit/Tests/DomainTests/PlanCasesTests.swift`
- Modify: `tools/check/steps.ts` (the `api` and `ios` steps' inputs gain `tools/contract/plan-cases.json`),
  `ios/TutorCentralKit/Package.swift` (`DomainTests` resources: `.copy("../../../../tools/contract/plan-cases.json")` is
  outside the target; instead `tools/contract.ts` copies the file into `Tests/DomainTests/Cases/plan-cases.json` as a
  fourth generated output and `--check` diffs it)

**Interfaces:**
- Produces: `planRules(input: PlanInput): PlanDraft` with the types mirroring Domain's `PlanInput` (classroom, date,
  students, chapters by student, skills by student, sessions, school item hints, now, groupCount, subjects, revisions,
  holidays) and `PlanDraft` (classID, date, groups `[{ number, subject, chapter, skill, memberIDs, examItemID }]`, lines
  `[{ studentID, groupNo, kind, skillID, words, personalChecks }]`, leftOut); `istDay(date)`, `weekday(day)`, `addDays`.
- The case file's shape: `{ "cases": [{ "name": string, "input": PlanInputJSON, "expected": PlanDraftJSON }] }`, dates as
  ISO strings, UUIDs as given, `now` as an ISO instant; the words of each line verbatim.

- [ ] **Step 1: the case file, from `PlanRulesTests`.** Read `Tests/DomainTests/PlanRulesTests.swift` (and `+Exam`, `+Step`
  tests): write one case per test that builds an input and asserts a draft, with the expected draft as the Swift test
  asserts it (at least: a fresh batch with no record; members with records in two subjects; the group count from the
  pattern and from a choice; a member on holiday; an exam near for some members (`revisions`); a closed session's day;
  the spaced revision pick; a left-out member; the brief prefix). Where a Swift test asserts only part of the draft, the
  expected draft is completed by running `PlanRules.plan` once in a scratch Swift test that prints JSON, read by eye against
  the rules (the ledger says which cases were completed that way).

- [ ] **Step 2: the failing tests.** `PlanCasesTests.swift`: decodes the file (a test-only `PlanCase` Codable mapping to
  Domain's types) and for each case `#expect(PlanRules.plan(input) == expected, "\(name)")` with `PlanDraft` compared field
  by field (it is `Hashable`). `plan-rules.test.ts`: the same loop over `planRules`. Run: the Swift suite (green at once:
  it is the source of truth; a red case means the case file is wrong, fix the file) and `cd api && bun test
  test/plan-rules.test.ts` (red: nothing ported).

- [ ] **Step 3: the port**, file by file in Domain's order (`PlanTypes` → `types.ts`; `SpacedQueue` → `spaced.ts`;
  `SchoolItemRules.hints` → `hints.ts`; `PlanRules+Exam` → `exam.ts`; `PlanRules+Step` → `step.ts`; `PlanRules` →
  `rules.ts`), each function named as in Swift, each Swift comment carried over, the IST calendar as fixed `+05:30` (no
  DST) in `dates.ts`; sorting rules (`sorted(by:)` stability, `Dictionary` iteration order) made explicit where Swift
  relied on them. `bun test` until every case is green; a case that disagrees is read against both sources, and the
  Swift side is the truth unless the Swift test itself is wrong (then both change and the ledger says so).

- [ ] **Step 4: `bun check` green (the Swift test target rebuilds); commit; PR 11; merge.**

---

### Task 13: The `plan` job: read, groups, name, write; `run-job.yml` (PR 12)

**Files:**
- Create: `api/src/jobs/kinds/plan.ts`, `api/src/jobs/record.ts` (the reads and the record writes through the service
  client: members, chapters, skills, sessions, items, brief chapters; `addChapter`, `addSkill`, `makePlan`),
  `api/test/plan-job.test.ts`, `.github/workflows/run-job.yml`, `tools/run-job.ts` (the SQL and the polling, tested)
- Modify: `api/src/jobs/kinds/index.ts`, `api/src/prompts/plan.ts` (the `request()` is reused as the route uses it),
  `supabase/types.ts` (nothing new; the job uses existing functions)

**Interfaces:**
- The job's `input`: `{ class_id: string; date: "YYYY-MM-DD" }`; its steps by `step.at`: `read` → `{ at: "groups", record }`
  → `{ at: "name", draft, record }` → `{ at: "write", draft }` → done `{ plan_id }`. Its failures: `no_members` (done with
  `{ plan_id: null, reason }`, not a failure: a batch with no active member has no plan), `closed` (the session is closed:
  done, no plan), `read_failed` (retry), `name_failed` (the groups stay unnamed and the plan is written: the app's
  `complete()` names them on open, as today), `write_failed` (retry).
- `record.ts`: `readRecord(svc, centre, classId, date)`, `writeNamedSkills(svc, centre, draft, record)`, `makePlan(svc,
  centre, draft)` (the `make_plan` parameters exactly as `SupabasePlansRepository.makeParams` builds them), `briefChapters`.

- [ ] **Step 1: the failing tests (`plan-job.test.ts`,** the handler with a fake record source and the fake Claude):
  `read gathers the batch and continues to groups`; `a batch with no active member is done with no plan`; `a closed session
  is done with no plan`; `groups applies the rules and continues to name`; `name calls plan once through start_ai_call with
  the key <job>:name and writes the named skills, then continues to write` (`db.started[0].key` is `${id}:name`,
  `job: id`; the fake record's `addSkill` called for each member of the named group without the skill); `a failed naming
  still writes the plan with the groups unnamed`; `write calls make_plan with the draft and is done with the plan id`;
  `a read that throws fails with retry`. Run: `cd api && bun test test/plan-job.test.ts`. Expected: fail.

- [ ] **Step 2: the code.** `plan.ts` as the interface says, each step bounded: `read` by the queries, `name` by the
  Claude deadline (`startCall` through `makePlatformDb`, the `plan` prompt's `request()` with the groups the rules left
  unnamed, `empty` as the route's), `write` by one RPC. `record.ts` reads as `PlanMaker.read` does (students active in the
  class; chapters and skills by student; sessions this month and last; items), and `writeNamedSkills` ports
  `PlanMaker.writeNamedSkills`/`writeSkill` (a chapter of the name in the subject or a new one at the end; the skill in it
  or a new one). `kinds/index.ts` registers `plan` and `sweep`. `run-job.yml`: inputs `email`, `batch`, `date` (default
  empty → tomorrow IST, computed in the script); `tools/run-job.ts --email … --batch … --date … --out file.sql` writes the
  SQL (`do $$ … select u.id … from auth.users u join public.centres c on c.owner_id = u.id where u.email = …; select id
  from public.classes where centre_id = c and name = … and archived_at is null; perform public.enqueue_job(c, 'plan',
  'plan:' || cls || ':' || d, jsonb_build_object('class_id', cls, 'date', d)); raise notice 'job %', …$$`) and refuses a
  missing centre or batch in words; the workflow runs it with `supabase db query --linked -f`, then `curl -fsS -H
  "Authorization: Bearer $WORKER_SECRET" "$API_ORIGIN/jobs/tick"`, then polls `select state, step, result, error from jobs
  where idempotency_key = …` every 15 s for three minutes and prints the last answer to the summary (the plan's id, never a
  student's name).

- [ ] **Step 3: `bun check --only=api,tools` green; the local proof** (ledger): `supabase db reset`; the seed's Evening
  batch for today queued through the runbook's section 12; `curl …/jobs/tick`; `select state, step->>'at', result from jobs`
  reads `done`, `write`, `{ plan_id }`; `select count(*) from plan_items where plan_id = …` matches the draft; the
  `ai_generations` row for the naming has `job_id`, `user_id null`, `idempotency_key <job>:name`, `cost_paise`. Commit; PR 12;
  merge. Then **Deploy 2** and **Owner step 3** (Task 16).

---

### Task 14: The app: the key and request id on every AI call, the mappings, two writes made idempotent (PR 13)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Data/AI/IdempotencyKey.swift`, `Tests/DataTests/IdempotencyKeyTests.swift`,
  `Tests/DataTests/APIClientTests.swift` (a `URLProtocol` stub), `Tests/DataTests/MessageLogIdempotencyTests.swift`
- Modify: `Sources/Data/AI/APIClient.swift` (`exchange` adds the two headers; `post` takes `fresh: Bool = false`;
  `failure(status:body:)` gains 409 and 429 `rate` and 413), `Sources/Data/AI/AIRepository.swift` (`GenerateContext`
  gains `again: Bool = false`), `Sources/Features/Make/*History*` (Create again passes `again: true`),
  `Sources/Data/Messages/SupabaseMessageLogRepository.swift` (`logAbsence` on `23505` reads the row),
  `Sources/Data/Plans/SupabasePlansRepository.swift` (`keepParams` adds `p_key` for an artefact with a `generationID`),
  the `AISamples`/fake repositories if a signature changes

**Interfaces:**
- `IdempotencyKey.forBody(route: String, body: Data) -> String` (`"tc-" + sha256 hex`, 67 characters);
  `IdempotencyKey.fresh() -> String` (`"tc-" + UUID`); the body encoder's `outputFormatting = [.sortedKeys]` so the same
  request hashes the same.

- [ ] **Step 1: the failing tests.** `IdempotencyKeyTests`: the same route and body give the same key; another body
  another key; `fresh()` differs each time; both ≤ 200 characters. `APIClientTests` (stubbed session recording the request):
  `every AI call carries Idempotency-Key and X-Request-Id` (two calls of the same body: the same key, different request
  ids); `Create again sends a fresh key` (`generate(_, context: .init(…, again: true))`); `a replayed answer reads like a
  first one` (200 with the header → the same `Generation`); `an in-progress answer reads as timed out` (409
  `in_progress` → `.timedOut`); `aReusedKeyReadsAsTheServiceWords` (409 `key_reused` → `.service`); `a rate 429 reads as
  timed out` (429 `reason: rate` → `.timedOut`, not `.limit`); `a 413 reads as too large`. `MessageLogIdempotencyTests`
  (the Supabase repository over a stubbed session): the insert answers PostgREST's `23505` body, the following select answers
  the row → `logAbsence` returns it; any other code throws. A `QueueRunnerTests` case: a messages fake that throws
  `23505`-shaped error on the first send is not what the runner sees any more (the repository absorbs it), so the runner
  test asserts `sent: 1` with a fake whose `logAbsence` returns the existing row. `PlansRepositoryTests`: `keepParams` of an
  artefact with a generation id carries `p_key` = that id; without one, no `p_key`.
  Run: the Data and Make targets. Expected: fail.

- [ ] **Step 2: the code** as the interfaces say. The write path proof (ios/CLAUDE.md's rule): a throwaway Swift test
  against the local stack with an in-memory session: `logAbsence` twice for one child and day → the same row id;
  `keep` twice of a made artefact → the same artefact id; deleted after the run; the ledger records both.

- [ ] **Step 3: `bun check` green; commit; PR 13; merge.**

---

### Task 15: The app: activity posted in batches to `events` (PR 14)

**Files:**
- Create: `Sources/Domain/Activity/ActivityKind.swift`, `Sources/Data/Activity/ActivityEvent.swift`, `ActivityLog.swift`,
  `ActivityRepository.swift`, `SupabaseActivityRepository.swift`, `FakeActivityRepository.swift`,
  `Tests/DomainTests/ActivityKindTests.swift`, `Tests/DataTests/ActivityLogTests.swift`,
  `Tests/AppShellTests/ActivityRecordsTests.swift`
- Modify: `Sources/Data/Cache/Wipe.swift` (`activity-<centre>.json` belongs), `Tests/DataTests/WipeTests.swift`,
  `Sources/AppShell/RootView.swift` and its sign-in, sign-out, link and tab paths (`ShellState.activity`), `Sources/Data/
  Account/*SignOut*` (the log is posted, then wiped)

**Interfaces:**
- `public enum ActivityKind: String, CaseIterable, Sendable { case appOpened = "app_opened", signedIn = "signed_in", signedOut
  = "signed_out", tabOpened = "tab_opened", linkOpened = "link_opened" }`;
  `public struct ActivityEvent: Codable, Sendable { kind: ActivityKind; screen: String?; at: Date }`;
  `public actor ActivityLog { init(centre: UUID, repository: any ActivityRepository, directory: URL?, now:, batch: Int = 20,
  cap: Int = 500); func record(_ kind: ActivityKind, screen: String? = nil) async; func flush() async; var pending: Int }`;
  `public protocol ActivityRepository: Sendable { func post(_ events: [ActivityEvent], centre: UUID) async throws }`
  (one PostgREST insert of the batch; `user_id` is the column default).

- [ ] **Step 1: the failing tests.** `ActivityKindTests`: every case's raw value is in `APIContract.eventKinds`, and the
  counts match. `ActivityLogTests`: `the twentieth event posts the batch in order`; `a failed post keeps the events for the
  next flush` (the fake throws once; `pending` stays 20; the next `flush` posts them); `the file holds at most 500, the
  oldest going`; `events survive a new log on the same file` (the file is read on init); `flush with nothing posts nothing`.
  `WipeTests`: `activity-<id>.json` is removed, another centre's stays. `ActivityRecordsTests` (AppShell with the fake):
  the scene going active records `app_opened`; a sign-in `signed_in`; a tab change `tab_opened` with the tab's name; a link
  `link_opened` with its kind; sign-out records `signed_out`, flushes, then wipes (the fake's posted list holds it and the
  file is gone).
  Run: the three targets. Expected: fail.

- [ ] **Step 2: the code.** `ActivityLog` keeps the file with complete file protection until first unlock as the other
  caches (D40); `flush` posts a copy and removes exactly what it posted (the queue's rule); `RootView` owns one log per
  centre (`centreActivity()` beside `centreQueue()`), records at the five places, flushes on `scenePhase` `.background`
  and `.active`. `SupabaseActivityRepository.post` inserts `[{ centre_id, kind, screen, at }]`.

- [ ] **Step 3: `bun check` green; commit; PR 14; merge.** Nothing on screen changes.

---

### Task 16: The deploys, the owner's production plan run, the hand runs (D32), the cost record (main)

- [ ] **Step 1: Deploy 1** after PR 9: `gh workflow run deploy`; the gate passes (`main`'s head is green), the summary shows
  0028 to 0033 pending then none, the API's commit, the smoke's "one `check` made for the smoke centre" (the tick check is
  not on yet). Before it: the duplicate-absence query (Task 7 step 2) answers no rows, or the owner removes the duplicates
  in the dashboard's SQL editor first. After it: build 26 on the owner's phone still works (he opens Today and Make once
  and says so, or the ledger notes it was not asked); `api_requests` fills (the owner can see the count in the dashboard's
  Table editor if asked; the session does not read production).
- [ ] **Step 2: Deploy 2** after PR 12 (the `WORKER_SECRET` smoke env added to `deploy.yml`'s smoke step in PR 10): 0034
  pending then none; the Vault step; the smoke's tick 200; `cron.job_run_details` fills a row a minute (the owner reads it
  once in the dashboard under Integrations → Cron, or the `api_requests` count of `/jobs/tick` grows by one a minute).
- [ ] **Step 3: Owner step 3.** `gh workflow run run-job -f email=<his email> -f batch="<his batch's name>"` (the session
  runs it with his values typed by him in the chat, never written to a file) in the evening; the summary shows `done` and a
  plan id. Next morning he opens Today: the plan is there before he opened the app (the app completes its material as
  today). He says what he saw; a fault is D68's.
- [ ] **Step 4: the hand runs,** by `docs/runbooks/simulator.md` against a fresh seed, signed in as Meera, each write
  confirmed in the database, the screenshots in `.shots/run/` and on the phase's issue ("Phase 17 hand run"); the local API
  with the real models for runs 1 and 2 (the owner's standing approval; about ₹1), `AI_FAKE=1` for the rest:

| Run | After PR | Through the screens | Confirm |
|---|---|---|---|
| 1 Same request, one call | 13 | More → Make something → Sheet → For → Class → Class 5 → Mathematics → "Fractions" → Make the sheet → the sheet → Back → the same form again, the same choices → Make the sheet | `select count(*), max(idempotency_key), max(request_id), max(cost_paise), max(latency_ms), max(stop_reason) from ai_generations where kind = 'sheet'`: 1 row with every column set; `api_requests` has two rows for `/ai/make`, the second with status 200 and the first's key replayed (the API's log line says `replay: true`) |
| 2 A note with the tutor's words | 13 | Students → a student with consent → Note → words → Write → the note | one `ai_generations` row of kind note with `user_id`, `request_id`, `cost_paise`; `message_log` as Phase 15's run 6 |
| 3 The absence log replayed | 13 | The gateway stopped → Students → a student → Absent today → the alert's log queued (Pending changes shows it) → `docker start` → foreground → the queue empties; then by psql insert the same child and day again → `23505`; then queue the same alert again offline and replay | `select count(*) from message_log where kind = 'absence' and about_date = current_date`: 1 after each replay; the queue file empty |
| 4 Settings still save; the allowance is not the owner's | 13 | More → Settings → the centre's name changed → Saved; UPI id changed → Saved | `select name, upi_id, ai_allowance from centres`: the new values, 600; `update centres set ai_allowance = 1` as the seed's user through PostgREST (curl with Meera's token) answers 42501 |
| 5 The plan made by a job | 12, 13 | `supabase db reset` (no plan today); the Evening batch's `plan` job queued and the tick run (runbook section 12) → the app launched → Today: the plan's groups and lines show at once (no "Planning") and its material fills in | `jobs` row done with `result.plan_id`; `plans.id` equals it; `plan_items` count; the naming row's `job_id`; the artefacts kept by the phone carry `idempotency_key` = their generation ids |
| 6 Events | 14 | Launch → Today → Students → School → More → a link from a reminder (`simctl openurl`) → background (HOME) → foreground | `select kind, screen from events order by at`: app_opened, tab_opened ×3 with the tab names, link_opened, app_opened; then Sign out → `events` has `signed_out`; the file `activity-<centre>.json` gone |
| 7 Offline events kept | 14 | The gateway stopped → five tab changes → HOME → `docker start` → foreground | nothing in `events` while stopped; the six rows after, in order |

  A fault found is fixed in its own pull request with a test first (D68), and the run repeated on the fixed build.

- [ ] **Step 5: the cost record** in the ledger: every real call this phase (the smokes, the production plan naming, runs 1
  and 2) with `bun cost --since …` (which now reads `cost_paise`) and the sum.

---

### Task 17: The restore drill and its runbook (PR 15, then the drill itself)

**Files:**
- Create: `.github/workflows/restore-drill.yml`, `docs/runbooks/restore.md`, `tools/restore-count.sql` (the per-table
  count query both sides run)

- [ ] **Step 1: the workflow.** `workflow_dispatch`, `environment: Production`, `concurrency: restore-drill`:
  `supabase projects create "tc-restore-$(date +%Y%m%d)" --org-id "$(supabase projects list -o json | jq -r '.[] |
  select(.ref == "esowihbxawvoexflekxa") | .organization_id')" --region ap-south-1 --db-password "$(openssl rand -hex
  24)"` with the password kept in the job's env (masked); poll `supabase projects list -o json` until the new ref's status
  is `ACTIVE_HEALTHY` (up to 10 minutes); `supabase link` to production and `supabase db dump --linked --role-only -f
  roles.sql`, `supabase db dump --linked -f schema.sql`, `supabase db dump --linked --data-only --use-copy -f data.sql`;
  `psql "$SCRATCH_DB_URL" -f roles.sql -f schema.sql -f data.sql` (the scratch URL from `supabase projects api-keys` /
  the pooler host printed by `projects list`; `-v ON_ERROR_STOP=1`); `psql … -f tools/restore-count.sql` on both; a table
  of the two columns and the elapsed time into the summary; `if: always()` → `supabase projects delete <ref> --yes`.
  No tutor's data leaves the runner: the dumps are in `$RUNNER_TEMP`, never an artifact.
- [ ] **Step 2: the runbook.** `docs/runbooks/restore.md`: when (a quarter; after any migration that drops or rewrites
  data), the workflow's run and what to read in its summary, the dashboard's own route (Database → Backups → Restore, which
  replaces the project's data in place, once Pro is bought, D85), and a log table (date,
  run, duration, the counts equal or not, who read it).
- [ ] **Step 3: `bun check --only=tools` (the SQL file is read by a small test that it names every public table of
  `types.ts`); commit; PR 15; merge; `gh workflow run restore-drill`;** the first log line written from its summary in the
  documents commit. A step that fails (a CLI flag that differs, a pooler host) is fixed in a `fix` pull request and run again
  the same day.

---

### Task 18: The review, Deploy 3, the TestFlight build, the documents (main)

- [ ] **Step 1: the review** on Fable 5.1, two reviewers in fresh contexts (the database and the API: the migrations, the
  gate, the worker, the plan rules against Domain; the app and the tools: the keys, the events, the contract, the
  workflows), over `main` since Phase 15's close, with this plan's "Review focus" and the ledger's rulings; every finding
  fixed (D68) in `phase-17/fix-*` pull requests, tests first; the two re-rulings allowed are the owner's.
- [ ] **Step 2: Deploy 3** with the fixes; then `gh workflow run testflight`: a build with nothing new on screen (the two
  headers, the events, the idempotent writes). The owner installs it with the others (D68).
- [ ] **Step 3: the rule files** (D80): `api/CLAUDE.md` (the stale "mock and the personal kinds answer 501" line out; the
  worker, the job key, `/jobs/*`, the request id and logs, `start_ai_call` and the key, the rate and body limits, the
  fakes refused, `maxDuration`, `.env.local`'s two new names, `bun contract`); `ios/CLAUDE.md` (four queued writes, not
  three; the headers and `IdempotencyKey`; `ActivityLog` and its file; the absence log's `23505`; the keep's key; the
  contract's generated file is never edited); `supabase/CLAUDE.md` (the job identity beside D37's two functions and the
  third definer `wake_worker`; the three `centre_id` exceptions; the lock and the gate trigger; the allowance's column
  grants; `jobs.test.ts`, `gate.test.ts`, `wake.test.ts`; the Vault secrets written by the deploy); `CLAUDE.md` (the
  commands: `bun contract`, `gh workflow run run-job`, `gh workflow run restore-drill`; rule 6's exceptions point at
  `supabase/CLAUDE.md`).
- [ ] **Step 4: the documents** to `main` (D12): `plan/phase-17-platform-foundation.md` "As built" (what exists, what
  deviated and why, what Phase 18 takes: the artefact steps, `ArtefactBudget`'s port, the app's `complete()` retired);
  `plan/README.md` (the phase's status; D83 to D85 if not yet recorded); `plan/STATE.md` (production: 0028 to 0034, the
  API's commit, the worker live, both plans still Free and Hobby with what that carries (D85); the build number);
  `plan/sessions/035/record.md`, `ledger.md`,
  `owner-messages.md`; `docs/runbooks/restore.md`'s first log line; `plan/ui-polish.md` untouched unless something was
  seen; this plan's boxes ticked.

## Self-review (done 2026-10-12)

1. **Spec coverage** against `phase-17-platform-foundation.md`'s eight items: the plans, not bought by D85 (the ruling
   above; the scope file's item 1 is amended in "As built"); the job tables with
   their four tests (Task 4: duplicate key, lease, retry, cancel); the worker with its wakes, the key, `maxDuration`, the
   `plan` job locally and in production (Tasks 11, 13, 16); the recorded call (Tasks 5, 10, 14: the key, the request id, the
   lock, the twelve columns, billed tokens on failure, truncation, the allowance, `keep_artefact` and the absence log, the
   sweep, the limits, the fakes); the observability tables (Tasks 6, 7, 9, 15); the contract (Task 8, 12); process (Tasks
   1, 3, 17); the rule files (Task 18). The acceptance's five lines map to Tasks 4 and 13, 10 and 14, 5, 3 and 17, 18.
   Spec-v3 section 7's "per-user and per-IP rate limits and a body limit" is Task 9; "structured JSON logs with the request
   id" Task 9; D79's `consent_events` Task 7; D72's `device_tokens` Task 6. Not in this phase by the spec's own table: pg_cron
   schedules, APNs, the artefact steps, `ai_models`, prompt versions (Phases 18 and 20).
2. **Placeholders:** none found; every step names its files, tests and code or SQL; the two places that depend on a tool's
   answer (the Hono builder's function name in Task 9; the restore CLI's flags in Task 17) say what to do when the answer
   differs.
3. **Type consistency:** `start_ai_call`'s jsonb shape is the same in Task 5's tests, Task 10's `Db.startCall` and Task
   13's platform call; `JobsDb`'s `record(outcome)` and the SQL functions of Task 4 agree on `p_step_data` and
   `p_cost_paise`; `APIContract.eventKinds` (Task 8) and `ActivityKind` (Task 15) hold the same five strings; the key
   `<job>:<step>` is spelled the same in decision 7, Task 5's test and Task 13's test; `IdempotencyKey`'s prefix `tc-`
   and the 200-character bound match the API's header rule.
4. **Review focus:** each of the ten lines names its test and the task that owns the code; lines 1 to 5 are the resume's
   five; 6 to 10 came from reading the runner, the cancel path, build 26 against the new API, the events file and the
   column grants.
