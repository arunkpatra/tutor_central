# Tutor Central V3: the platform

Approved by the owner on 2026-10-12 (decisions D70 to D82 in `plan/README.md`), drafted the same day from his interview
(`docs/v3/interview.md`, session 33). V1 (`docs/spec.md`) and
V2 (`docs/spec-v2.md`) are the product: what a tutor does and sees. V3 is what is under it. Nothing a tutor sees changes
without a board (rule 1); where V3 changes a screen, the board comes first. Each choice below names the interview entry it
rests on (Q1 to Q7, or "decided" for the items the owner left to the session, interview message 7). The decisions it needs are
section 15, numbered from D70.

## 1. Why, and the bounds

The owner's review of build 26 (Q1) found four things wrong with the platform as built:

1. The phone starts and runs long work. The plan for a batch is up to twenty AI calls made one after another from the app;
   when iOS suspends the app the work stops and what was paid for is lost; a second open can start a second run. Work of this
   kind will get longer (agents, several rounds), so it must run in a process with its own persistence and explicit states,
   independent of any phone.
2. Nothing is tracked. Cost, the tutor's activity, the jobs, the errors: none is recorded in a way anyone can see.
3. Limits are literals in a database function, with no identity able to set them per centre.
4. The AI output is naive: crude text, no mathematics in a proper form, one prompt per kind with no check on quality.

V3 puts the platform in order: the backend is the platform, the app is its presentation layer (Q1, Q2); long work is jobs;
cost, activity and limits are recorded and controlled; an admin portal gives the owner the data, the analytics and the eyes to
debug and monitor (Q1, message 5); the AI layer is rebuilt as specialised agents with evaluation, and its output is rendered
properly (Q1, decided).

**Bounds.** One person builds and runs it, with Claude (Q4). Paid plans are fine where needed, chosen with care (Q5). One
environment; staging later (Q1). No third-party error, tracing or support service now; the platform's own tables and the
portal are the eyes (message 5). Nothing a tutor sees changes without a board. No tutor's or student's data in the repo
(D55). No secret in the app or the repo (D11).

**Order.** V3's core and the AI overhaul first; the external testing round (Phase 15's Tasks 20 to 23, by D52 to D55) on the first
build that carries them; Phase 16 (Release, D64) after the round (Q3).

**What V3 does not do.** It adds no feature a tutor asked for and drops none (rule 10). It does not change the WhatsApp deep
links (D3, D61), the consent gate's meaning (D62), the figures as typed specs (D59), the syllabus-facts rule (D58) or the
price (D64). It does not stand up staging, a second region or a second platform.

## 2. Principles

1. **The backend is the platform.** State lives in Postgres; work runs on the server; the app reads and writes through APIs
   and shows what it is given (Q1).
2. **The app keeps a copy and a small queue, nothing more.** It shows the last copy of what it has seen and queues the four
   writes a class needs offline: the close, attendance, Mark paid, the absence log (D39, Q2). It runs no work for the
   platform's sake.
3. **Long work is a job.** A job has a row, a state, an idempotency key, a step reached and a result. It survives the phone,
   the function and the deploy. The portal shows it.
4. **A paid call is recorded once, with what it cost.** An idempotency key makes a retry free; the row holds the model,
   the prompt version, the tokens, the cost, the latency and the outcome.
5. **Quality is checked, not hoped for.** A kind of AI work is an agent with a drafting step and a checking step, with
   a golden set and a gate in CI; the tutor's edits are kept as feedback.
6. **Eyes on what happens, in our own tables.** Activity, jobs, generations, requests, admin actions. No third party sees a
   tutor's data for the sake of a dashboard (D18, message 5).
7. **The tutor notices nothing but that things are faster, arrive on time and read better.** Words stay plain (D41).

## 3. Jobs: the persistence-backed process (Q7, D71)

### The table

`jobs` is a centre table (RLS through `is_member`, so the app may read its own centre's jobs) with: `kind` (plan, artefact,
note_day, reminder_sweep, export, pdf, eval_run, sweep), `state` (queued, running, waiting, done, failed, cancelled),
`idempotency_key` (unique per centre), `attempts`, `max_attempts`, `lease_until`, `leased_by`, `step` (the step reached and
its data, jsonb), `input` (jsonb), `result` (jsonb or null), `error` (a reason and a message, jsonb), `run_at`, `started_at`,
`finished_at`, `cost_paise`. `job_steps` records each step taken: `job_id`, `step`, `state`, `started_at`, `finished_at`,
`generation_id?`, `error?`. A step is small enough to finish inside one function run; the job continues at the next wake.

The state is the truth. The portal reads it; the app reads it to say "Planning today's class" or "Ready"; a worker never
holds state outside the row.

### Schedules

pg_cron inside the database (Supabase Cron, Beta label; pg_cron itself is mature) writes the day's jobs: each batch's plan at
a time before the batch (06:00 IST by default, the tutor's reminder time where set), the note day's notes on its evening,
the reminder sweep, the pending-row sweep, the eval run. A schedule writes rows; it runs no work itself.

### Workers

Hono routes on Vercel Pro (Fluid compute, 800 s a function, functions in `bom1`) do the work. Two things wake a worker: Vercel
Cron each minute (a drain route that takes due jobs) and a database webhook (`pg_net`) the moment a job is queued, so a tap in
the app is answered without the minute's wait. A worker takes a lease (`lease_until`, one row, `for update skip locked`),
does one step, writes the row and the step, and either continues in the same run while time allows or returns and leaves the
rest to the next wake. A lease that expires is retaken; `attempts` bounds retries with backoff; a job past `max_attempts` is
failed with its reason and shows in the portal.

### Identity

The worker writes as the platform, not as a tutor: a server-only key (Supabase's service role, or a dedicated Postgres role
with exactly the grants the workers need, chosen in the phase plan) that lives in Vercel's environment and nowhere else. No
app ever holds it (D11). The tutor's own API calls keep running as the tutor (D5). This supersedes D60's "no server job, no
cron, no service-role key" and the matching words of D5 and spec-v2 section 9.

### What is not chosen

Vercel Workflows (GA April 2026) keeps the run's state in Vercel's persistence; a job row would be a mirror and the portal
would read two places. Vercel Queues is beta. Supabase Queues is Public Alpha; Edge Functions have a 400 s wall clock and two
seconds of CPU, too little for a worker. Inngest, Trigger.dev and Temporal hold the history on their side and add a bill.
The price of the choice is writing the lease, retry and idempotency rules ourselves: one migration and one module, tested first.

## 4. AI: specialised agents (Q1, decided; D73, D74)

### One agent per kind of work

Each kind (the sheet, the worked example, the figure, the brief, the check, the placement, the mock, the gap report, the
note, can-now-do, test tomorrow, not on track, read marks, the two parsers, the plan's naming, V1's four kinds and two photo
tools) is an agent: a pipeline on the Messages API with

1. a **draft** step: strict tools and structured output, the kind's rules and the record's facts, prompt caching on the shared
   prefix (the syllabus facts, the kind's rules, the voice);
2. a **check** step by a different model against the kind's rubric: only facts from the record (no invented parts, the Phase
   14 finding), the level, the format (lengths and limits, the schema), the language and script for a parent's message, the
   answer key by computation where it is numeric;
3. a **repair** step when the check fails, once, then a refusal in words.

An orchestrator with sub-agents only where the work is open-ended: exam preparation (the split, the mock, the marking, the
gap report as one job) and the plan (groups, lines and the artefacts to make). Everything else is a pipeline, kept simple on
purpose. Not the Claude Agent SDK (it runs a `claude` subprocess and needs a container) and not Managed Agents (beta) now;
each agent is written behind one interface so a kind can move to either later.

### Models and fallbacks

The model for each kind and step lives in a table in the database with a history (`ai_models`: kind, step, model, effort,
since, by whom), seeded from `api/models.json` and set in the portal (section 10). A step names a fallback model for an
overload, a timeout or a refusal; a fallback used is recorded on the row. This supersedes D35's "no fallbacks", D63's one
model per kind and D67's checked-in file as the place of truth (the file remains the seed and the tests' fixture).

### Cost levers

Prompt caching on the shared prefixes (cache reads at a tenth of the input price). The Message Batches API, at half price,
for work no one waits for: the morning's plans and artefacts, the note day, the evals. The tutor waits only for the kinds made
at a tap (a note's edit, Check a paper, a Make form); those run live, inside one function, as today.

### Prompts as versioned artefacts

Prompts stay in the repo, one file per kind and step, each exporting a version and a hash recorded on every generation row.
A change to a prompt is a pull request; its evals run in CI and gate the merge. No external prompt service now (message 5);
the portal reads our rows.

### Evaluation

A golden set per kind in the repo: inputs and expected properties (never a tutor's or student's data; the seed's names),
small at first and grown from the cost runs and the tutor's edits. promptfoo, self-hosted in CI, runs the kinds whose prompts
or schemas changed: a schema check first (free), then rubric graders by a model other than the generator, gated on a pass
rate the phase plan sets (judges are noisy; 100% is not the gate). For Hindi and Kannada notes, an anchor set labelled by a
native speaker, with script fidelity and code-mixing scored separately (the 2026 papers in `plan/sessions/033/research.md`
find judge agreement weaker for Dravidian languages). A nightly run of the whole set through the Batches API; its result is a
page in the portal. The cost runs of Phases 12 to 15 become a standing report there: cost per kind, model and centre.

### Feedback

A tutor's edit to a note, a regeneration with its reason, a sheet replaced by their own: each is kept beside the generation
(`generation_feedback`) and read by the eval set's growth and the portal.

### Mathematics and the artefacts' form (D75)

Every artefact's content carries formulae in LaTeX maths mode, the form Claude writes most reliably and every renderer reads.
On the phone, SwiftMath (MIT, pure Swift, offline, no web view) renders it: the second iOS dependency after supabase-swift,
pinned (D14). PDFs made on the server use Typst with `mitex` (LaTeX maths inside Typst), compiled in Node within Vercel's
bundle. The sheets, the worked example, the mock and the board view change in look, so their boards come first (rule 1); the
Kit gains a maths preview. Text inside a formula in Hindi or Kannada needs a fallback font; the phase plan checks it.

## 5. What leaves the phone (decided; D70)

| Work | Today | V3 |
|---|---|---|
| The plan and its artefacts | `PlanMaker` on the phone, up to 20 calls in sequence | A `plan` job per batch per day, run before the batch; the app shows the row's state and the result as it lands; a background push when ready |
| The note day's notes | Made on open | A `note_day` job on the evening; the notes wait in the app for reading and sending |
| Exam preparation (mock, marking, gap report) | The phone, call by call | One orchestrated job per exam; marking from a photo stays a tap (the photo comes from the phone) |
| Reminders (class, fee, note day) | Local notifications planned by `ReminderScheduler` | A `reminder_sweep` job and APNs (section 6) |
| PDFs for sharing | `PDFMaker` on the phone | A `pdf` job writes to Storage under the centre; the app shares the file. Printing from the phone keeps its path |
| The per-student export (D62) | Not built | An `export` job producing a file the tutor shares |
| Background refresh | `BGAppRefreshTask` | Retired |

The phone keeps: the copy of what it shows (`CachedRead`, `PlanCache`), the four-write queue (D39), figures drawn from specs
(D59), maths rendering, the camera and photo reduction (D36), the WhatsApp links (D3). Each retirement happens in the phase
that stands up its replacement, with a board where a state changes.

## 6. Notifications (decided; D72)

Today the app plans local notifications from its own copy; nothing reaches a phone that has not opened the app. In V3 the
platform decides and sends through APNs:

- The app registers for remote notifications and sends its device token to the API; `device_tokens` keeps one row per user
  and device, retired on Apple's 410.
- The workers send over HTTP/2 with `@parse/node-apn` (8.1.0, maintained, pinned), signing the ES256 token from a `.p8` key
  held in Vercel's environment only, like the Sign in with Apple key. A function opens its connection per run and sends the
  due notifications in bulk.
- Alerts carry plain words (D41, `docs/design/feedback.md`) and an opaque id the app resolves after sign-in; never a student's
  name, a mark or a parent's number (Apple's rule, and ours). A background push (`content-available`, two or three an hour at
  most) tells the app a plan is ready; the app fetches.
- The rules that decide what and when (the reminder before a batch, the fee reminder, the note day, "plan ready") move from
  `ReminderScheduler` to the `reminder_sweep` job, tested first in TypeScript.
- D3 and D61 stand: messages to parents stay WhatsApp deep links.

## 7. Robustness (area e; D76)

- **Idempotency.** The app sends an idempotency key with every paid call; the API answers the same result for the same key
  within a day. Every job and job step has one. `start_ai_generation` takes a lock on the centre's row before it counts, so
  the limit cannot be passed by two calls at once. `keep_artefact` and the absence log become idempotent (a key, or a unique
  constraint).
- **The generation row.** `ai_generations` gains `cost_paise`, `latency_ms`, `prompt_version`, `prompt_hash`, `stop_reason`,
  `error_reason`, `request_id`, `job_id?`, `fallback_model?`. Billed tokens are recorded on a failure too. `max_tokens` is
  handled as truncation, with a repair, never shown as a refusal of the topic. A `sweep` job closes rows left pending.
- **Limits.** `centres.ai_allowance` (calls a month) and `ai_allowance_paise` replace the plpgsql literals; a column-level
  policy keeps the owner from raising it; the portal sets it. Per-user and per-IP rate limits and a body limit at the API.
- **Offline.** Last write wins for the four queued writes stays: one tutor, one device (Q2). The copy is shown at once and
  refreshed, never shown only after a network read fails: the 20 s waits of the hand runs go with one data layer the stores
  share (the stale-store faults of four reviews).
- **Contracts.** Types generated from the database for the API, and from the API's schemas for the app, so every limit lives
  once (the 0022 drift, the 180- and 600-character faults). Contract tests between the app and the API run in `bun check`.
- **Backups.** Supabase Pro's daily backups with point-in-time recovery; a restore drill into a scratch project once a
  quarter, recorded in `docs/runbooks/restore.md`. Migrations stay forward-only (D26).
- **Security.** `APPLE_FAKE` and `AI_FAKE` refused when `VERCEL_ENV` is production; the service-role or job key only in the
  workers' and the portal's environments; every function's `maxDuration` set, not defaulted.

## 8. Privacy and the DPDP Act (D79)

- **Consent as a history.** `consent_events` (student, kind: given or withdrawn, phone, how, when, by which user) replaces the
  three mutable columns as the record; the columns remain as the current state for the gate. A withdrawal stops the personal
  kinds at once and is shown on the student's page as the board draws it.
- **Export per student (D62).** An `export` job writes a file (the record, the messages, the generations' outputs about the
  student) the tutor shares with the parent; its state shows on the student's page (a board).
- **Delete per student.** The cascades of 0027 plus the Storage photos, by a trigger-queued `sweep` step.
- **Retention.** `ai_generations.input` for a personal kind is reduced to a reference after a period the spec's decision
  sets (90 days), the output and the cost kept; the trust page says so (web rule: a change in what is kept changes `/trust`
  in the same phase).
- **What an admin sees.** Section 10. Never a parent's number; a student's name only on an audited open of a record; never a
  generation's input for a student without consent.
- **Push payloads** carry nothing personal (section 6).

## 9. Observability (message 5; D77)

Our own tables, read by the portal:

| Table | Holds |
|---|---|
| `events` | The tutor's activity: an event kind (opened, closed a class, sent a note, made a sheet, regenerated, signed in), the screen kind, the time, the centre and user; never content. The app posts them in batches; the API and workers write their own |
| `api_requests` | One row per API call: request id (made by the app, carried in a header, kept on the generation row), route, status, latency, the centre, the error reason |
| `jobs`, `job_steps` | Section 3 |
| `ai_generations` | Section 7, enriched |
| `admin_audit` | Section 10 |
| `alerts` | Each alarm raised: kind, threshold, value, when, acknowledged |

Vercel Pro's one-day logs and Supabase Pro's seven are the raw layer behind them; no drain, no Sentry, no Langfuse now.
Crashes come from Xcode Organizer and TestFlight, with no SDK in the app; D18's open question is closed for V3 that way.
Alerts are the portal's own thresholds (failed jobs, a centre's cost a day, the error rate, a stuck job, evals failing) sent
to the owner by email through Resend (D30) and as a push to his own device. Logs in the API are structured JSON with the
request id, so a line in Vercel's log and a row in `api_requests` meet.

## 10. The admin portal (Q6, decided; D78)

For internal admin personnel of Tutor Central: today the owner alone (Q4). Its screens are boards first (rule 1); it may use
the trade's words, since no tutor reads it.

- **Where.** `admin/` beside `web/`: Next.js with server code (not a static export), a third Vercel project, deployed only by
  its own hand-started workflow (D21's shape), at a subdomain of tutorcentral.in.
- **Sign-in.** The same Supabase project's Auth; an `admin_users` table allows the account; a TOTP second factor is required
  (Supabase MFA, the `aal2` level checked on the server on every request); the service-role key lives only in the portal's
  server environment and every read runs in server code behind the admin check (Q6).
- **Audit.** `admin_audit`: who did what to which centre or setting, when, from where; an open of a centre's record is a
  row. The portal shows its own audit.
- **It shows:** centres and their tutors (a tutor's name and email, never a parent's number), sign-ins and activity from
  `events`; usage and cost per centre, kind, model and day against the allowance and D64's price; the AI calls with prompt
  version, tokens, latency, outcome and fallback; the jobs and their states, with a retry and a cancel; the API's errors by
  route and reason; the evals' last run and the cost report; the alerts.
- **It controls:** the model and effort per kind and step with its history (`ai_models`); the allowance per centre;
  feature flags and kill switches per kind (a kind switched off refuses in the tutor's words); the syllabus data (a view of
  `syllabi`, edits still by migration in V3); the alert thresholds.
- **Support, within consent and privacy (D55, D62).** An admin opens a centre's records only on an audited action with a
  reason; sees a student's record and the outputs made about them; never sees a generation's input for a student without
  consent, a parent's number, or a photo. Nothing in the portal writes a tutor's records.

## 11. Data and analytics (D18 kept; D82)

Product metrics come from `events` and the record's own tables, computed in the portal: tutors active a week, closes a week,
plans made and followed, notes sent, artefacts made and regenerated with reasons, Make's use, consent given, cost per active
tutor. No third-party tracker, no SDK (D18). The owner's weekly report is a portal page and an email from the `reminder_sweep`
job's sibling.

## 12. Engineering process (area f; D80)

- One environment until the owner says otherwise (Q1); Vercel Preview stays unused.
- `deploy.yml` requires a green `check` run for its commit; its smoke makes one authenticated call to a smoke centre with the
  real model (a bad key or a rejected model id fails the deploy). The portal's workflow does the same.
- Shared generated types (section 7) and contract tests; CI's database port collision and the SchoolTests teardown crash fixed
  in the foundation phase; the `xcode-27` image replaced when GitHub ships the GA label.
- Prompt changes run their evals in CI (section 4).
- The session rules (`plan/SESSIONS.md`), D17 (plan on Fable, build on Opus), D68 (a phase fixes what it finds) and the
  review on Fable with every finding fixed stay as they are.
- The rule files change: `api/CLAUDE.md` (the 501 note is stale; the workers, the job key, the push), `ios/CLAUDE.md` (four
  queued writes, not three; what the phone no longer does), `supabase/CLAUDE.md` (the job identity beside D37's two
  functions), a new `admin/CLAUDE.md`.

## 13. Cost and money (Q5; D64 stands)

| Item | A month |
|---|---|
| Vercel Pro (functions to 800 s, cron each minute, one-day logs) | about $20 |
| Supabase Pro (daily backups, seven-day logs, compute) | about $25 plus compute |
| APNs, pg_cron, promptfoo, SwiftMath, Typst | nothing |
| AI | per centre, recorded; about ₹280 to ₹310 a month for twelve students with two exams at today's models, Opus marking 60 to 70% of it |

The portal shows AI spend per centre against D64's ₹499 and raises an alarm at a daily threshold; caching, batching and the
checking step's model choice are the levers, measured by the standing cost report. The price itself is Phase 16's, set after
V3's cost runs (D64).

## 14. Phases

V3's phases are 17 to 22, built in that order and all before the external testing round and Phase 16 (Q3). Each has a scope file
(`plan/phase-NN-*.md`) and, when it starts, a plan file; each ends with something to show.

| # | Phase | Ends with | Depends on |
|---|---|---|---|
| 17 | Platform foundation | Vercel Pro and Supabase Pro; `jobs`, `job_steps`, `events`, `api_requests`, `consent_events`, the enriched `ai_generations`, `centres.ai_allowance`, `device_tokens`; the worker, the lease, the wakes, the job key; idempotency keys on every paid call; the request id across app, API and row; the locked gate; `maxDuration` set; the fakes refused in production; generated shared types and the first contract tests; the deploy gated on a green check and a real smoke; CI's two flakes fixed; the restore drill run once. Shown: the seed centre's plan made by a job and read by the app; a build with nothing new on screen (D6) | Phase 15 |
| 18 | The server's work and push | The `plan`, `note_day`, `reminder_sweep`, `pdf`, `export` and `sweep` jobs; pg_cron's schedules; APNs with the device tokens; the app's plan maker, background refresh, reminder scheduler and PDF sharing retired; the one data layer the stores share (the copy at once); the student's export and consent withdrawal on their boards. Shown: a reminder arriving on a phone that has not opened the app; a plan ready before the batch; a build on TestFlight | 17 |
| 19 | The admin portal, reading | `admin/` with its boards; sign-in with TOTP, the service role on the server, `admin_audit`; centres, activity, cost, generations, jobs, errors, alerts (email and push to the owner). Shown: the portal live at its subdomain with the owner signed in | 17 |
| 20 | AI quality, the material | The agent pipeline (draft, check, repair) behind one interface; `ai_models` with fallbacks; prompt versions and hashes; the golden sets and promptfoo in CI; LaTeX in the content, SwiftMath on the phone, Typst PDFs, the Kit's maths preview; the sheet, worked example, figure, brief, check, placement, plan-naming and the two parsers moved onto it, with their boards. Shown: a sheet with proper equations; the evals' first green run; a build | 17, 18 |
| 21 | AI quality, parents and exams | The note, can-now-do, test tomorrow, not on track and read marks with the language anchors; the exam orchestrator (split, mock, marking, gap report) as one job; Make's and V1's kinds; `generation_feedback`; the Batches API for the morning and the nightly evals; the standing cost report. Shown: a note day made by a job, checked, read on the phone; the cost report in the portal; a build | 20 |
| 22 | The admin portal, control and analytics | The model table, allowances, flags and kill switches, syllabus view, alert thresholds; the audited support open; the product metrics and the owner's weekly report; retention on personal inputs and the trust page's words. Shown: a kind switched off from the portal and refused in the tutor's words; the weekly report | 19, 21 |

Then: the external testing round on the Phase 21 or 22 build (Phase 15's Tasks 20 to 23), Phase 16.

## 15. Decisions

Numbered in `plan/README.md` on 2026-10-12.

| # | Decision | Supersedes |
|---|---|---|
| D70 | **The backend is the platform; the app is the presentation layer.** The app shows a local copy of what it has seen and queues the four offline writes of D39; it runs no work for the platform. Plan making, artefacts, the note day, reminders, PDFs for sharing, exports and schedules run on the server as jobs (Q1, Q2) | D60; the "no job, no service role" clauses of D5 and spec-v2 section 9. D39, D40 stand |
| D71 | **Jobs in Postgres.** `jobs` and `job_steps` are the truth, with explicit states, leases, attempts and idempotency keys; pg_cron writes schedules; Hono workers on Vercel Pro, woken by Vercel Cron each minute and by a database webhook on enqueue, do one step at a time; a server-only key (never in an app) is the workers' identity. Vercel Pro and Supabase Pro are bought (Q5, Q7) | D37's count of server identities is extended by the job key; D11 holds |
| D72 | **Push through APNs**, sent by the workers with `@parse/node-apn`, the `.p8` on Vercel only; `device_tokens` per user and device; opaque payloads, plain words; a background push when a plan is ready; the reminder rules move to a job (decided) | D60's local-reminder clause. D3, D61 stand |
| D73 | **An agent per kind of AI work**: draft with strict tools and structured output, check by a different model against the kind's rubric, repair once; an orchestrator with sub-agents for exam preparation and the plan only; prompt caching on shared prefixes; the Batches API for work not waited on; the model, effort and fallback per kind and step in `ai_models` in the database with a history, seeded from `api/models.json` and set in the portal (Q1, decided) | D35 (no fallbacks), D63 (one model per kind), D67 (the file as the place of truth; it stays the seed) |
| D74 | **Prompts versioned, evals gated.** Each prompt carries a version and hash recorded on every generation row; a golden set per kind in the repo with no real tutor's or student's data; promptfoo in CI on changed prompts with a pass-rate gate; native-speaker anchor sets for Hindi and Kannada; a nightly run through the Batches API; the cost runs as a standing portal report (decided) | New |
| D75 | **Mathematics in LaTeX**, rendered by SwiftMath on the phone (the second iOS dependency, pinned) and Typst with `mitex` in server PDFs; the sheets', worked example's, mock's and board view's boards redrawn first (decided) | Extends D14's dependency list |
| D76 | **Idempotency and the recorded call.** An idempotency key on every paid call and job step, answered the same for a day; `start_ai_generation` locks the centre's row; `ai_generations` gains cost, latency, prompt version and hash, stop reason, error reason, request id, job and fallback; truncation is repaired, never shown as a refusal; `centres.ai_allowance` the owner cannot raise replaces the literals; per-user and per-IP limits and a body limit at the API (decided) | Extends 0007's gate |
| D77 | **Observability in our own tables**: `events`, `api_requests`, `jobs`, `ai_generations`, `admin_audit`, `alerts`, read by the portal; structured JSON logs with the request id; alerts by email (Resend) and push to the owner; no Sentry, no drain, no Langfuse now; crashes from Xcode Organizer and TestFlight with no SDK (message 5) | Closes D18's open crash-reporting question for V3 |
| D78 | **The admin portal** in `admin/`: Next.js with server code, a third Vercel project, its own workflow, at a tutorcentral.in subdomain; the same Supabase Auth with an `admin_users` allow-list and TOTP (`aal2` on the server); the service-role key on its server only; `admin_audit` on every action and every open of a centre's record; one role; the trade's words allowed; boards first. An admin never sees a parent's number, a photo, or a personal input without consent (Q6, decided) | New |
| D79 | **DPDP records**: `consent_events` as an append-only history with withdrawal; the per-student export as a job (D62 built); Storage photos deleted with the student and the account; personal inputs reduced after 90 days with the trust page saying so (decided) | Extends D62 |
| D80 | **Process**: one environment until the owner says; the deploy requires a green check and makes a real authenticated smoke call; types generated once for every limit with contract tests; prompt changes run their evals; the rule files updated in the phase that changes what they describe (Q1, decided) | Extends D21, D26 |
| D81 | **Order and phases.** V3 is Phases 17 to 22 as section 14; then the external testing round (Phase 15's Tasks 20 to 23); then Phase 16 (Q3) | Extends D69 |
| D82 | **Product metrics** from `events` and the record's tables, in the portal and a weekly email; no third-party tracker (decided) | Extends D18 |
