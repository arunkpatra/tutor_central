# V3: the interview

The record of the owner's interview for `docs/spec-v3.md` (D69), written as it goes so nothing depends on memory. One entry
per question: the question, the options and the recommendation given, the owner's answer word for word, and what it
settles. Sessions 033 and on (`plan/sessions/033/record.md`).

Conventions: the owner's words are quoted; a recommendation is marked; "Settles" names what the spec may now rely on and
which decision it would supersede (D1 to D69 in `plan/README.md`). Research is cited where it was done.

## What the reading found

Skimmed on 2026-10-12 by four agents with written briefs, their reports read and condensed here. Each line names a fact a
question may rest on; a weakness is marked **W**.

### The database (`supabase/`)

- 27 migrations, 1,842 lines of SQL; about 98 tests (`tests/v2.test.ts` 54, `rls.test.ts` 38). Twenty centre tables, three
  tenancy tables, `ai_generations`, `message_log`, `syllabi`. One policy per centre table through `is_member`; the catalogue
  test fails on any table without RLS or a policy.
- `start_ai_generation` (0027's body): member, consent (centre notice for V1's photo kinds; the student's `consent_at` for the
  personal kinds), the limit, then a `pending` row. The limits are literals in plpgsql: V1 40 a day for the four
  generations, 20 each for scan and check; V2 600 a calendar month (Asia/Kolkata) across sixteen kinds, a hard cap at 1.5×.
  **W** No column, no table: a per-centre allowance (Phase 16's) needs a column the owner cannot raise (the owner may update
  every column of `centres` today) and an identity to set it, which does not exist.
- Idempotency by unique keys: one attendance session per class and day, one invoice per student and period, one plan per batch
  and day, one mark per session and student; `close_session` replaces its checks. **W** None on `ai_generations` or
  `keep_artefact`: a retry makes a second artefact; `record_placement` resent duplicates its checks.
- **W** `ai_generations` carries no cost, latency, error or prompt-version column; cost is worked out offline by `bun cost`.
  **W** Members keep a table-wide INSERT grant on `ai_generations` (0001), so a row can bypass the gate; the count-then-insert
  has no lock. **W** The `teacher` role exists but RLS treats every member alike.
- DPDP: consent is three mutable columns (`consent_at`, `consent_phone`, `consent_how`), **W** no history, no withdrawal
  record; **W** no per-student export; **W** Storage photos are not removed when a student or account is deleted; **W** no
  retention rule on `ai_generations.input`.
- Operations: migrations only through `deploy.yml` (D26), dry run before and after; **W** no down migrations, forward fixes
  only; **W** backups are Supabase's defaults, nothing in the repo, no restore drill; no audit or event table; no admin role.

### The API, the workflows and the tools (`api/`, `.github/workflows/`, `tools/`)

- `api/src`: 43 files, about 2,575 lines; 24 prompt files, one per kind, each exporting `request()` with the model from
  `models.json`, the effort, the system and user text and the zod schema; `schemas.ts` 438 lines; `claude-fake.ts` 516 lines;
  about 147 tests. Routes: `/ai/generate` (V1's four kinds), `/ai/scan-register`, `/ai/check-paper`, `/ai/parse-school`,
  `/ai/parse-textbook`, `/ai/plan`, `/ai/make` (twelve kinds), `/ai/read-marks`, `/account/revoke-apple`, `/health`.
- One call: middleware verifies the JWT with Supabase `auth.getUser` (401 "sign in again"; 503 `unreachable`); `parse` validates
  (400 `invalid`); `run` calls `start_ai_generation` as the user (403 consent or student_consent or member; 429 limit; 502
  other), then Claude once through `messages.parse` with `zodOutputFormat`, `max_tokens` 16000 for every kind, `maxRetries` 1,
  one 110 s deadline across both tries (the app gives up at 125 s); a refusal, a null parse or an answer the route's `empty()`
  rejects is 422 in words; a timeout or API error 502. The row gets `status`, `output`, `model`, `tokens_in`, `tokens_out`.
- **W** No cost, latency, prompt version, request id, stop reason or error reason on the row; a 502 cannot be told apart
  (timeout, 429, 529). **W** A timeout, API error or parse failure records null tokens: billed tokens lost to `bun cost`.
  **W** `stop_reason: max_tokens` is not checked: a truncated answer reads as a refusal and blames the photo or topic.
- Prompts: **W** no version id or hash recorded against a row; no golden set; `test/prompts.test.ts` checks strings and the
  fake's answers only. **W** No prompt caching (`cache_control` nowhere), no batching, no streaming, no fallback (D35).
- Logging: six `console.error` calls in all; **W** no success log, no structured log, no request id, no error service, no metric,
  no alert. `vercel.json` sets only `bom1` and git deploys off; **W** no `maxDuration`, so the 110 s deadline rests on Vercel's
  default; a killed function leaves a `pending` row that counts against the limit with nothing to sweep it.
- Abuse: limits per centre only; **W** no per-user or per-IP limit, no `bodyLimit` (Vercel's 4.5 MB is the guard), every bogus
  token costs a `getUser` call. Photos: magic bytes, base64 round trip, 3 MB, six pages.
- `models.json`: ₹85 a dollar; Haiku $0.1/$0.5, Sonnet $2/$10, Opus $4/$20 per million tokens in/out. Opus: scan_register,
  check_paper. Haiku: sheet_to_5, check, placement, note, can_do, test_tomorrow, not_on_track. Sonnet: the rest. The sheet is
  the only banded kind. `AI_MODEL_<WORK_TYPE>` overrides at deploy. **W** `bun cost` reads the local database by default.
- CI: `check.yml` on PRs and `main` (documents skipped, D31): `ios` on `xcode-27` (40 min timeout) and `api-web-db` on Ubuntu
  (15 min) in parallel; every action pinned to a SHA; Bun 1.3.11, Supabase CLI 2.120.0. Deploys all by hand: `deploy.yml`
  (migrate with dry runs before and after, then Vercel CLI 59.19.0 `--prebuilt --prod`, a smoke of `/health` and a 401, the
  rollback command printed), `deploy-web.yml`, `testflight.yml` (refuses while migrations pend; cloud signing; build = run
  number), `seed-review.yml`. **W** One environment, Production: no staging, no preview. **W** The deploy does not require a
  green check for its SHA. **W** The smoke never makes an authenticated AI call: a bad `ANTHROPIC_API_KEY` or a model Anthropic
  rejects passes.
- Doc drift: `api/CLAUDE.md` still says `mock` and the personal kinds answer 501; `/make` serves them all.

### The app (`ios/TutorCentralKit`)

- 635 Swift files, 67,384 lines in Sources; 275 files, 23,977 lines of tests. One dependency, supabase-swift 2.55.3. Features
  32k lines (Students 7.8k, Today 5.1k, Make 4.3k), DesignSystem 11.3k, Data 10.1k, Domain 8.5k, AppShell 5.4k.
- Reads: a copy per list (`CachedRead`, `cache-<centre>-<key>.json`) and per plan (`PlanCache`), shown at once, refreshed from the
  network; a failed reload keeps the screen. **W** The copy is shown only after the network read fails, and a stopped gateway
  keeps `NWPath` satisfied: about 20 s of waiting at each read, seen in four hand runs. **W** Each store builds its own cache
  and fallback; there is no one local data layer (ten stores said "Nothing saved" over a list on screen, #169).
- Writes: direct to Supabase online; four kinds queue offline (`attendance`, `markPaid`, `absenceLog`, `close`; `ios/CLAUDE.md`
  still says three). `QueueRunner` replays in order, one at a time; a transport error or 5xx waits, a 401 asks for sign-in, a
  PostgREST code fails the change. Conflicts: last write wins, no version check. Replay safety is the server's unique keys
  (`save_attendance` upserts, `close_session` replaces, `make_plan` upserts); **W** `logAbsence` is a plain insert and
  `plans.keep` an insert, so a lost answer doubles them.
- The plan is made on the phone (`PlanMaker`): read the record, apply `PlanRules`, `/ai/plan` to name groups, `make_plan`, then
  up to 20 artefact calls one after another (each up to 125 s), kept and cached as they land; a failed call is skipped
  silently and `complete()` fills gaps on the next open. Background refresh is a `BGAppRefreshTask` asked for 06:00. **W** No
  `beginBackgroundTask`: a foreground run stops when iOS suspends the app and paid work is lost; a result that lands after
  a cancel or a failed keep is dropped and paid again. **W** The refresh handler builds its own `PlanMaker` and `MockRuns`,
  uncoordinated with the foreground run. **W** No id is sent to `/ai/*`: a timeout that "may still finish" is a second paid
  call on retry. PDFs are drawn on the phone (`PDFMaker`); reminders are local notifications (`ReminderScheduler`).
- Errors: `APIClient.failure` maps status and `reason` to `APIFailure`, whose words the tutor reads; `NoticeCenter` shows the
  alert with Try Again where a retry exists; `ErrorWordsTests` bans technical words in source literals. **W** For 422, a plain
  400 and student_consent the API's `error` string is shown as it arrives: the test cannot see it. **W** No automatic retry.
- **W** No `os.Logger`, no crash reporting, no MetricKit, no telemetry: confirmed none. **W** No trace id from the app to the
  API. Failures in the field are invisible.

### What the phases learned (`plan/phase-11-*` to `-15-*`, ledgers 026, 028, 030, 032)

- Cost runs: Phase 12 one plan for twelve students, 13 calls, ₹4.57 ("about ₹91 a month at twenty sessions"); Phase 13 a mock
  ₹3.94, marking two pages on Opus ₹8.18, a gap report ₹0.43 ("about ₹29.77 an exam for a class of three, the marking most of
  it"); Phase 14 fifteen calls ₹2.52 (a week of notes for twelve ₹0.61; read-marks on Sonnet ₹0.56 against Opus ₹1.28); Phase
  15 thirty calls ₹22.54 (two plans ₹7.31; marking ₹7.14). The agent's arithmetic for twelve students a month with two exams:
  about ₹280 to ₹310, 56 to 62% of D64's ₹499 before Apple's cut, Opus marking 60 to 70% of it, about 360 of the 600 calls.
- Faults by cause, and the weakness each names: stale store copies (no one local data layer); 20 s offline waits (copy shown
  only after the network fails); duplicate paid calls (026 critical: a second open started a second run; 028: two batches two
  mocks; 032 R-app-1 critical: a note rewritten with a paid call on every open; `bun cost` missed billed failures): **no
  idempotency key on paid calls, the phone orchestrates them, duplicates found by reading the database**; the model overrunning
  schema limits (gap report 20 skills for 12; lines over 180 characters; a Hindi note's English past 600; a 400 shown as "Check
  your connection"): **limits copied across Swift, TypeScript and SQL, nothing contract-tests them, no eval against the real
  model**; prompts asking for facts that may be absent (030 API Important 2); contract drift (`name_plan_group`'s `group_no`
  against the app's `number`, 0022): **no shared generated types**; consent gaps found late (028's mock marking, #166, R-web-1,
  R-web-3): **consent checked per route, not in one place**; test tooling hiding failures (a crashed run counted green; fixed
  sleeps flaking on CI).
- Review themes across the four ledgers: concurrency and double spend; Domain edge cases (a closed plan still changeable, a
  holiday plan returning); limits between layers; offline-queue interactions; error classification (401 for a lost database
  connection); orphaned photos in Storage; public claims drifting from the code.
- Platform-shaped leftovers: per-student export (D62, "later"); crash reporting (D18 open); server-sent WhatsApp at a tutor
  count (D61); no staging (D21: "when there is something to stage"); CI's port 54322 collision and the SchoolTests teardown
  crash; `APPLE_FAKE` not refused in production; sign-out not stopping a run; `BGAppRefreshTask` for a twenty-call job;
  photos left in Storage after a failed keep; the owner's open ruling on a school message naming a student (R-web-2); device
  tests T1 to T15 not yet run.
- The owner's words on V3: none recorded beyond D69's entry and the resume prompt; "state of the art" is the prompt's phrase,
  not his. His standing rules: D67 ("make some build time affordance to specify the models based on the type of work"), D68
  ("Stop deferring such things"), real AI calls allowed in testing ("be judicious").

## Questions

### Q1. The owner's own review (area b), 2026-10-12

Open question, asked first because his findings shape the rest. What his review of the engineering and technical decisions
found so far: what he wants changed, what he wants kept, and what worried him enough to pause the round (D69). Also whether the
list of weaknesses above matches what he saw.

**Answer** (word for word in `plan/sessions/033/owner-messages.md`, message 2): the phone initiating long-running tasks such
as AI work "is not the correct architecture"; such tasks, which will grow longer with "agentic processes, multi-round
conversations", should be "independently done and managed by a persistence backed process with valid states"; the iOS app
"is just a presentation layer" that talks to the system through APIs; "Backend is the 'platform'". There is no tracking of
cost or of the tutor's activity on their account; an admin app (Next.js) is needed for full visibility, where internal admin
personnel "should be able to see everything about cost consumptions, analytics, metrics" of a tutor and their account. "All
limits etc should be managed properly." He asked how notifications are created today, what the robust Apple way is, what
APNs is, and how the backend can decide when to push; "The platform MUST NOT depend on compute happening or being
orchestrated by teh iOS app at all - think, suggest, push back if needed." One environment is fine for now; staging later.
The AI output is "very naive", "very crude", with no mathematical equations in proper format or rendering. The AI layer
"needs complete overhaul": a proper agentic design that can grow systematically, one specialised agent per kind of work,
"the best possible quality of the outputs".

**Settles:**
1. V3's architecture principle: the backend is the platform; the app is the presentation layer and reaches it through APIs.
   Long-running work runs in a persistence-backed process with explicit states, never from the phone. This supersedes D60
   (the app makes the plan; no server job, no cron, no service-role key) and the "no job, no service role" clauses of D5 and
   spec-v2 section 9; a new decision names the server's identity for jobs (a key that lives only on the server, never in the
   app, D11 kept).
2. Cost and activity are recorded per tutor account; limits are the platform's, managed per centre.
3. An admin portal, Next.js, for internal admin personnel: cost, analytics, metrics per tutor and account. Its design boards
   are needed (rule 1).
4. Notifications: the backend decides and sends (APNs). Supersedes D60's local-reminder clause. D3 and D61 (WhatsApp deep
   links) untouched unless he says otherwise.
5. One environment for now; staging later (D21's "when there is something to stage" stands).
6. AI: an agentic design, one specialised agent per kind of work, quality first. Supersedes D63's one-model-per-kind and
   D35's no-fallbacks as the governing rule (the new rule is settled in area c). Mathematics must be formatted and rendered
   properly: a wire format and a renderer are needed (a new dependency, D14) and the sheets' look changes, so boards (rule 1).

**Left open by this answer, taken next:** where the offline promise sits once the phone is a presentation layer (Q2).

### Q2. Where the offline promise sits (area d, the phone's part), 2026-10-12

Pushback on "the platform MUST NOT depend on compute happening or being orchestrated by the iOS app at all": the orchestration
part is right and nothing in the code argues against it. The one thing on the phone that is not compute for the platform's sake
is the tutor's own offline work: `docs/spec-v2.md` section 1 ("often on mobile data"), section 6 (the close "usable without a
plan"), D39 (four writes queue and replay) and D40. A basement classroom with no signal still has to close a class.

Options offered:
- **A (recommended).** The app is the presentation layer with a local copy of what it shows and the small offline write queue it
  already has (the close, attendance, Mark paid, the absence log). Nothing else stays: plan making, artefacts, scheduling,
  notifications, limits, cost all move to the platform. A client with a cache is still a client (Mail, Gmail). Costs nothing
  new on the server; keeps spec-v2's promise and D39/D40 as built.
- **B.** A pure online client: no copies, no queue. Simplest; loses the offline close and every "saved on this iPhone" state,
  so spec-v2 and the boards change.
- **C.** An offline-first sync engine (PowerSync, ElectricSQL or the like) for two-way sync of the whole record. Heaviest; a
  new dependency on both sides (D14); more than the product needs now.

**Answer:** "A copy and the small write queue (Recommended)" (AskUserQuestion, 2026-10-12).

**Settles:** the app keeps a local copy of what it shows and the offline queue of D39 (the close, attendance, Mark paid, the
absence log); nothing else runs on the phone for the platform's sake. D39 and D40 stand. Plan making, artefacts, scheduling,
notifications, limits and cost move to the platform.

### Q3. Where V3 sits against the round and the release (area a), 2026-10-12

The owner paused the round (D69) and found the AI output crude. The order of V3, the external testing round (Phase 15's Tasks 20 to 23) and
Phase 16 (Release, D64) decides V3's phasing (area k).

Options offered:
- **A (recommended).** V3's platform core and the AI overhaul first; the external testing round on the first build that has them; Phase 16
  after the round. Reasons: tutors would judge content he already calls crude, and every finding on the plan's making, its
  speed or its reminders would be about code V3 replaces; the round's documents are ready and keep.
- **B.** The round now on build 26, beside V3, on the use cases only (the close, the record, the School tab, the notes), with
  the AI quality findings set aside. Gets tutor feedback months earlier; costs the owner's time twice.
- **C.** Release V2 (Phase 16) first for revenue, V3 behind it. Puts money and the ₹499 price on a cost base V3 changes.

**Answer:** "V3 core first, then the round, then release (Recommended)" (AskUserQuestion, 2026-10-12).

**Settles:** the order is V3's platform core and AI overhaul, then the external testing round (Phase 15's Tasks 20 to 23, by D52 to D55) on
the first build that carries them, then Phase 16. D69's pause holds until that build. V3's first phases must end in a build a
tutor can test; the round's documents (`docs/release.md`, `docs/testing/tester-guide.md`, `plan/phase-15-findings.md`) keep.

### Q4. The team (area a), 2026-10-12

Open question: who builds and runs V3 and the platform after it. The owner alone with Claude sessions as now (D17), or others
joining: an engineer, a designer, support or admin staff. It shapes the admin portal's roles, the review process and how much
the house rules may assume one pair of hands.

**Answer:** "Me alone with Claude for now. Exactly as how it has happend till now. `Claude code ` codes . why are you even
asking this question?"

**Settles:** one person; D17's way of working stands. The admin portal has one role (admin) and no role matrix; its sign-in
still needs a second factor and an audit log, because it sees every centre. Review stays Claude's reviewers and the owner's
approval. The question was the map's; the owner found it needless.

### Q5. The platform's monthly budget (area j), 2026-10-12

Open question, asked before the runtime and tooling recommendations because they depend on it: what the platform may cost a
month in services (hosting, database, queues, error reporting, LLM tracing, push) before any AI spend, and whether paid plans
(Vercel Pro, Supabase Pro, a tracing service) are acceptable now or only once there is revenue. Today everything is on free or
hobby tiers except the AI calls.

**Answer:** "Paid plans are fine now - whatever is needed, be judicious"

**Settles:** paid plans may be used where needed, chosen judiciously; no fixed ceiling. Each paid service the spec names
carries its monthly price and the reason the free tier does not do.

### Q6. The admin portal's sign-in and where it lives (area h), 2026-10-12

The portal sees every centre's cost, usage and records, so it is the one place that must bypass row-level security. Small
decisions taken here, not asked: it lives in `admin/` beside `web/`, a third Vercel project, Next.js with server code (not a
static export like the site), deployed by its own hand-started workflow (D21's pattern), its design boards first (rule 1), and it
may use the trade's words (D41 is for tutors).

Options offered:
- **A (recommended).** The same Supabase project's Auth: an `admin_users` table lists the allowed accounts; a TOTP second factor
  is required (Supabase MFA, the session's `aal2` level checked on the server); every read of data runs in the portal's server
  code with the service-role key, which lives only in that Vercel project's environment (D11 kept: never in an app, never in
  the repo); every admin action and every read of a centre's records is written to an `admin_audit` table. One auth system,
  no new vendor, no cost beyond Vercel.
- **B.** A second Supabase project for admin identities only. Isolates admin sign-in from tutor sign-in; a second project to
  run (Pro at about $25 a month) and a second set of keys for one admin.
- **C.** A third-party identity provider (Clerk, Auth0). A new vendor and a per-user price for one user; nothing it adds that A
  lacks at this size.

**Answer:** the dialog was dismissed; the owner wrote instead: "for now, we will not go overobard like sentry , helpdesk
etc...... we just want our platform architecture in order and teh admin portal so that we have teh data the analytics and teh
eyes on what's happening so taht we can debug easily and monitor easily".

**Settles:** (qualifies Q5) no third-party error, tracing or support services for now: observability is the platform's own
tables and the admin portal, built so the owner can debug and monitor from there. Crash reporting stays Apple's (TestFlight
and Xcode Organizer, no SDK), which closes D18's open question for V3. Asked again at his word, Q6 was answered: "Same Supabase Auth + TOTP + server-side service role (Recommended)". The admin
portal signs in through the same Supabase Auth with an `admin_users` allow-list and a TOTP second factor; its server code
alone holds the service-role key (D11 holds: never in an app, never in the repo); every admin action and every read of a
centre's records goes to an `admin_audit` table. It lives in `admin/`, a third Vercel project, Next.js with server code, its
own deploy workflow, boards first.

## Research (2026-10-12)

Done by an agent with WebSearch before the technical questions; sources are in `plan/sessions/033/research.md`. What bears
on the recommendations:

- **Durable jobs.** Vercel Workflows went GA in April 2026 (Hobby: 50,000 events a month; retention 1 day Hobby, 7 days Pro;
  the run state lives in Vercel's persistence unless a self-hosted "Postgres World" runs on a server, which Vercel Functions
  are not). Vercel Queues is still public beta. Vercel Functions on Pro: 800 s a function (GA), Fluid compute; Cron per minute
  on Pro, once a day on Hobby. Supabase Queues (pgmq) is labelled Public Alpha and Supabase Cron (pg_cron) Beta; Edge
  Functions have a 400 s wall clock on paid plans and 2 s of CPU. Inngest, Trigger.dev and Temporal hold the execution history
  on their side and add a bill ($0 to $99 a month).
- **APNs.** HTTP/2 to `api.push.apple.com`, a `.p8` key signing an ES256 JWT (refreshed at most every 20 minutes, valid an
  hour), 4 KB payload, push types alert and background (background pushes: priority 5, two or three an hour at most, not
  guaranteed), 410 `Unregistered` retires a token. Node's `fetch` is HTTP/1.1, so a library: `@parse/node-apn` 8.1.0 (April
  2026, maintained) or `apns2`. A function opens a connection per invocation and sends in bulk. Apple says no sensitive data in
  a payload: the safe pattern is an opaque id and "open the app", the content fetched over the authenticated API. No OneSignal
  or Firebase needed.
- **Agents with Claude.** Prompt caching: cache reads at 10% of input price (Haiku 5.5 $0.01, Sonnet 5.5 $0.10, Opus 5.5 $0.20 a
  million), writes 1.25× (5 min) or 2× (1 h). The Message Batches API is 50% off and stacks with caching, results within an
  hour as a rule, 24 h at most. Structured outputs and strict tools are GA. Managed Agents is beta ($0.08 a session-hour over
  tokens). The Claude Agent SDK runs a `claude` subprocess and needs a container (1 GiB, 1 CPU per agent), not a serverless
  function. Vercel AI SDK 7 (June 2026) has a durable `WorkflowAgent` and OpenTelemetry in one call. In practice a specialised
  agent per kind is a Messages pipeline with strict tools, structured output and a reviewer step; an orchestrator with
  sub-agents only for the open-ended kinds.
- **Prompt management and evals.** Langfuse (MIT, self-hostable, free cloud tier with versions, traces and judge evaluators);
  Braintrust ($249 Pro); PromptLayer ($49). Anthropic's Console has prompt versions and an Evaluate tab but no API or CI hook.
  promptfoo is free and self-hosted, runs in a GitHub Action when prompts change, emits JUnit; teams gate on a pass rate, not
  100%, because judges are noisy; grade with a model other than the generator. For Hindi and Kannada, 2026 papers find judge
  agreement with humans weaker for Dravidian languages: keep a small native-speaker-labelled anchor set per language and score
  script fidelity and code-mixing separately.
- **Mathematics.** No native maths in SwiftUI's `Text` on iOS 26. SwiftMath (MIT, pure Swift, offline, no web view, LaTeX maths
  mode; Latin and Cyrillic only inside `\text{}`) is the usual choice; MathJaxSwift and LaTeXSwiftUI run MathJax in
  JavaScriptCore; KaTeX in a WKWebView is heavy in lists. For PDFs: Typst compiles to PDF in Node (`typst-ts-node-compiler`,
  fits Vercel's bundle) with `mitex` for LaTeX maths; MathJax `tex2svg` is the other route. The wire format every renderer
  takes and Claude writes most reliably is LaTeX maths mode.
- **Observability.** Vercel logs keep 1 h on Hobby, 1 day on Pro, 30 days with Observability Plus; drains on Pro at $0.50 a GB.
  Supabase logs 7 days on Pro; `pg_stat_statements` on request. Apple's Organizer and MetricKit give crashes with no SDK.
  Sentry, Axiom, Better Stack and Grafana have free tiers; the owner has ruled them out for now (message 5).

## Questions, continued

### Q7. The runtime for long-running work (area d), 2026-10-12

The owner's words: "a persistence backed process with valid states", "eyes on what's happening", "not go overboard", paid
plans fine. The research above.

Options offered:
- **A (recommended).** A job table in Postgres is the source of truth: `jobs` with explicit states (queued, running, waiting,
  done, failed, cancelled), attempts, a lease, an idempotency key, the step reached and the result; every AI generation is a
  step of a job. Schedules by pg_cron inside the database (the plan each morning per batch, the note day, fee and class
  reminders); the workers are Hono routes on Vercel Pro (800 s a function), woken within a minute by Vercel Cron and at once
  by a database webhook (`pg_net`) when a job is queued; a worker takes a lease, does one step, writes the row, and the next
  wake continues. The server's identity for jobs is a dedicated key on Vercel only (D11). Cost: Vercel Pro $20, Supabase Pro
  $25 a month. Every state is in our tables, so the admin portal shows it with no vendor between. The price is writing the
  lease, retry and idempotency rules ourselves (about a migration and a module) and bounding each step to the function limit.
- **B.** Vercel Workflows (GA April 2026): durable steps, retries, sleeps and resumption for free; the run's state lives in
  Vercel (1 day on Hobby, 7 on Pro), so a Postgres job row becomes a mirror, not the truth, and the admin portal reads two
  places; moderate lock-in.
- **C.** A job runner (Inngest, Trigger.dev): the same mirror problem, a fourth vendor and bill ($0 to $99 a month), execution
  history on their side.

Ruled out by the research: Supabase Queues (Public Alpha) and Edge Functions as the worker (400 s wall clock, 2 s of CPU).

**Answer:** not asked. Before it was put, the owner wrote: "don't ask me superfluous questions that you are capable of
answering/deciding yourself". Option A is taken as the decision, by his criteria (persistence-backed states, eyes on everything,
no vendor between, judicious spend); the spec carries it as a numbered decision he approves with the spec.

**Settles:** the job table in Postgres as the source of truth, pg_cron for schedules, Hono workers on Vercel Pro woken by Vercel
Cron and a database webhook, a server-only job key; Vercel Pro and Supabase Pro. Supersedes D60 and the "no job, no cron, no
service role" clauses of D5 and D37's spirit (the job key is the server's, never the app's; D11 holds).

## Decided without asking (the owner's instruction, message 7)

The remaining areas are decided here by the reading, the research and the owner's answers; each becomes a numbered decision in
`docs/spec-v3.md` for his approval with the spec, where he may overrule any one.

1. **AI architecture (area c).** One specialised agent per kind of work, each a pipeline on the Messages API: a planning or
   drafting step with strict tools and structured output, a checking step by a different model against the kind's rubric (facts
   from the record only, the level, the format, the language), and a repair step when the check fails; an orchestrator with
   sub-agents only for the open-ended kinds (exam preparation, the plan). Prompt caching on every shared prefix (the syllabus
   facts, the kind's rules); the Message Batches API for work that is not waited on (the morning's plans, the note day), at half
   price. Fallback to a second model on an overload or a refusal, recorded; D35's "no fallbacks" and D63's one-model rule are
   superseded by a per-kind table that names the model for each step. Not the Claude Agent SDK (needs containers) and not
   Managed Agents (beta) now; the pipelines are written so either can host a kind later. Latency: the tutor waits only for the
   kinds made at a tap (a note's edit, Check a paper); everything else is a job whose result the app shows when it lands.
2. **Prompts as versioned artefacts.** Prompts stay in the repo (`api/src/prompts`), each with a version and a content hash
   recorded on every generation row; a change to a prompt is a pull request that runs its evals. No Langfuse or Braintrust now
   (message 5); the admin portal reads our rows.
3. **Evals.** A golden set per kind in the repo (inputs and expected properties, no tutor's or student's data), promptfoo
   self-hosted in CI on the prompts that changed, a schema check first, then rubric graders by a model other than the
   generator, a pass-rate gate; a native-speaker-labelled anchor set for Hindi and Kannada notes. The cost runs become a
   standing report in the admin portal (cost per kind, model and centre) rather than a session's task. The tutor's edits to a
   note are kept beside the generation as feedback.
4. **Mathematics and the artefacts' form.** LaTeX maths mode in every artefact's content where a formula appears; SwiftMath on the
   phone (a second iOS dependency, pinned; D14's decision), Typst with `mitex` for PDFs made on the server. The sheets' and
   worked examples' look changes, so their boards come first (rule 1). Quality rules per kind (a sheet's answer key checked by
   computation where numeric) belong to the agent's checking step.
5. **Which work leaves the phone (area d).** Plan making and every artefact, the note day's notes, the mock and gap report,
   reminders (class, fee, note day, "plan ready"), PDFs for sharing, the per-student export, and every scheduled job. The phone
   keeps the copy and the four-write queue (Q2), draws figures from specs (D59) and renders maths. The app's plan maker,
   `BackgroundRefresh`, `ReminderScheduler` and `PDFMaker`'s sharing path are retired as the server takes each.
6. **Push.** APNs from the Hono workers with `@parse/node-apn` (pinned), the `.p8` on Vercel only; `device_tokens` per user and
   device, retired on 410; alerts carry words and an opaque id, never a student's name or a mark; a background push tells the
   app to fetch when a plan is ready. Supersedes D60's local-reminder clause; D3 and D61 (WhatsApp deep links) stand.
7. **Robustness (area e).** An idempotency key on every paid call and every job step (the app sends one; the server answers the
   same result for the same key); `start_ai_generation` takes a lock and the gate's limit reads a per-centre allowance column
   the owner's policy cannot update; pending rows swept by a job; the row gains cost, latency, prompt version, stop reason and
   error reason; `stop_reason: max_tokens` handled as truncation. Offline stays last-write-wins for the four queued writes (the
   tutor's own device, one user); `logAbsence` and `keep_artefact` made idempotent. Backups: Supabase Pro's daily backups plus
   point-in-time recovery, and a restore drill into a scratch project once a quarter, recorded. Migrations stay forward-only
   (D26). Security: a per-user and per-IP rate limit at the API, a body limit, `APPLE_FAKE` refused in production. DPDP:
   consent as an append-only history (given, withdrawn, by whom, when, how), the per-student export (D62) as a job that
   produces a file, Storage photos deleted with the student and the account, a retention rule on `ai_generations.input`.
8. **Process (area f).** One environment until the owner says (message 2); the deploy requires a green check for its commit;
   the smoke makes one authenticated fake-free call against a smoke centre; shared types generated from the database for the
   API and from the API's schemas for the app (one source for every limit); contract tests between the app and the API; CI's
   port collision and the flaky teardown fixed; the session rules as they are (D17, D68).
9. **Observability (area g).** Our own tables, read by the admin portal (message 5): an `events` table for the tutor's
   activity (what was done, when, on which screen kind; never content), `jobs` and `job_steps`, the enriched `ai_generations`,
   an `api_requests` log with a request id the app sends and the database row keeps, `admin_audit`. Vercel Pro's one-day logs
   and Supabase Pro's seven are the raw layer; no drain, no Sentry, no Langfuse now. Crashes: Xcode Organizer and TestFlight
   (D18 closed for V3: no SDK). Alerts: the admin portal's own thresholds (failed jobs, cost a day per centre, error rate) sent
   to the owner by email through Resend (D30) and by a push to his own device.
10. **The admin portal (area h).** Next.js in `admin/`, server code, Supabase Auth with the allow-list and TOTP, the service-role
    key on its server only, `admin_audit` (Q6). Shows: centres and their tutors (no parent's number; a student's name only
    on a record the admin opens, audited), usage and activity, cost per centre, kind and model against the allowance and
    D64's price, the AI calls with prompt version, tokens, latency and outcome, the jobs and their states, errors, the
    evals' last run. Controls: the model table per kind and step (D67's table moves to the database with its history), the
    allowance per centre, feature flags and kill switches per kind, the syllabus data. Support: an admin sees a centre's
    records only on an audited open, never a generation's input for a student without consent, never a parent's number.
    Boards first (rule 1); the trade's words allowed.
11. **Data and analytics (area i).** Product metrics from the `events` table and the record's own tables, in the portal: active
    tutors, closes a week, plans made and used, notes sent, artefacts made and regenerated, cost per active tutor. No
    third-party tracker (D18). The owner's weekly report is a portal page and an email.
12. **Cost and money (area j).** The platform's standing cost about $45 a month (Vercel Pro, Supabase Pro) plus AI; the
    admin portal shows AI spend per centre against D64's ₹499 and alarms at a daily threshold; the per-centre allowance
    replaces the plpgsql literals. Phase 16's price stays to be set after V3's cost runs (D64 stands).
13. **Phasing (area k).** Cut so each phase ends in a build or a page to show: proposed in the spec for approval.

## The spec

`docs/spec-v3.md` was written on 2026-10-12 after the owner's "yes, write the spec", shown whole, and approved: "Ok, spec
approved. We should not call it 'tutor round' - I got confused. I think it's the external testing round is what you were saying".
The round is the external testing round from here on (D81). While reviewing he asked what product work is pending in V2; the
answer (Phase 16, the round, the items left for later, the open polish rows) is in `plan/sessions/033/record.md`.
