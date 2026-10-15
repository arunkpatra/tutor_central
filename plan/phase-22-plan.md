# Phase 22 plan: V3 the admin portal, control and analytics

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-15 (session 44, Fable 5.1) from `phase-22-admin-portal-control.md`, `docs/spec-v3.md` sections 8, 10, 11
and 13, Phase 19's, 20's and 21's "As built" and ledgers, the 41 boards of row 30 on canvas 2 (`docs/design/mockups/P22-*`,
"Phase 22 boards" in `docs/design/information-architecture.md`), the production reads of session 44 (`plan/sessions/044/ledger.md`)
and the code as it is. The boards were approved by the owner 2026-10-15 ("1, all three groups approved, keep the card"); the
plan waits for his review. The build runs on Opus 5.5 from `resume/043-phase-22-build.md`, inline, task by task, with one ledger
(`plan/sessions/045/ledger.md`) as sessions 22 to 43 kept.

**Goal:** the owner controls the platform from the portal (a kind's model, effort, fallback and switch with its history; a
centre's allowance; the alert lines; a read-only view of the syllabus data) and reads its product figures as a page and a weekly
email; a person can start the golden sets from the portal; a tutor's feedback shows on a call; a personal kind's input is reduced
to a reference after 90 days and the trust page says so; the exam's split follows each batch; a push Apple refused is tried again;
the round's documents read true to V3.

**Architecture:** every portal write is a named `security invoker` function granted to `service_role` alone that writes its own
audit row (0046's shape); the controls append rows (`ai_models`, a new `alert_lines`), the allowance updates the centre's two
columns with the old values in the audit. The API reads the lines and the models from the tables each minute as it reads
`ai_models_current()` today. The figures are one SQL function over the tables already kept (`events`, `attendance_sessions`,
`plans`, `message_log`, `artefacts`, `generation_feedback`, `consent_events`, `ai_generations`), no new collection on the phone.
A new job kind `weekly_report` renders the email in code and sends it through the alerts' Resend sender; the `sweep` job's
retention step calls one function that reduces old personal inputs. The portal's new pages follow Phase 19's `Data` interface,
preview fixtures and `bun admin-shots`.

**Tech stack:** as Phase 21 (Supabase CLI 2.120.0, Postgres 17, pg_cron; Bun 1.3.11; Hono 4.13.13, zod 4.6.5; Next.js 16.4.0,
`@supabase/ssr` 0.12.7; promptfoo 0.124.1). No new dependency.

**Spec:** `docs/spec-v3.md` sections 8 (D79), 10 (D78), 11 (D82), 13; the scope `plan/phase-22-admin-portal-control.md` (items 1
to 5, the acceptance); D41, D55, D62, D64, D67, D68, D73, D74, D76, D78, D79, D81, D82, D83, D86, D87, D94 to D97, D100, D107,
D109, D112; the boards of row 30 (canvas 2).

## Global constraints

- A screen changes only to an approved board (rule 1): the 41 boards of row 30 and what "Phase 22 boards" settles. Every other
  page of the portal, the website and the app is as it is; the one app change (the split per batch) changes no screen.
- The portal uses the trade's words (D78); the website and the app no technical words (D41): `web/test/unit/words.test.ts` and
  `ErrorWordsTests` hold it. "model", "agent", "eval", "batch", "job" never reach the trust page or the app.
- Never a parent's number, a photo, a message's text, a personal kind's input while consent is not current, nor the revised text
  of a feedback row, on any portal page (D78, D55, D107). A student's name only on the record page.
- Every write from the portal: a named function, `security invoker`, `set search_path = ''`, granted to `service_role` alone,
  `revoke`d from `public, anon, authenticated`, writing its own `admin_audit` row through `admin_audit_write` in the same
  transaction; a test proves a member gets 42501 (`supabase/tests/admin-controls.test.ts`). The catalogue test (`rls.test.ts`)
  lists every new table.
- Migrations are additive (D26): build 31 keeps working (new tables, new columns with defaults, a new job kind, new functions;
  `school_items.preparation` stays beside `preparations`). The TestFlight lane refuses a build while a migration is pending:
  every deploy comes before its build. Before replacing a function, read **every** migration that defines it
  (`grep -l "function public.<name>(" supabase/migrations/*.sql`, then open each) and build on the newest body.
- No automation spends on AI calls (D112): nothing in this phase makes a Claude call on a schedule, a push, a pull request or a
  deploy; the weekly report and the figures make none; the golden sets run only when a person presses the portal's button, runs
  `bun evals` or the workflow. `bun evals-changed` is expected to name no kind (no prompt, agent, schema or `models.json` change);
  if it names one, the build stops and asks the owner once, with a recommendation.
- No secret in the repository (D11); production set through the signed-in CLIs (D87); the Smoke centre's id read from the
  repository variable `SMOKE_CENTRE_ID` (`gh variable get SMOKE_CENTRE_ID`) into a command, never into a file.
- Bun only (D16); dependencies pinned (D14); documents only to `main` directly (D12); merge on local green (D86) with the pre-PR
  proof (`docs/working/pre-pr-proof.md`) in every body: tests first with RED and GREEN noted in the ledger, `bun check`,
  `bun evals-changed`, the pictures (`bun admin-shots --pages …`, `bun web-shots --pages /trust`, `bun shots` where a screen
  changes: none here), `bun pr-shots` for the table.
- Phase 21's lessons, binding: never a database test (`bun check`'s api or db step, `bun test` in `api/` or `supabase/`) while
  local jobs run (they clear the jobs and the calls); `git add` only the files a commit is for, documents never in a code commit;
  a docs push to `main` cancels a pending check, so push documents after a deploy has its check; zsh does not split a variable
  into words: pass file lists through `xargs`; the full `bun check` before every push; restart the local API after a branch
  switch.
- The ledger `plan/sessions/045/ledger.md`: a line after each named test run, each ruling with its cost if wrong, the spend (none
  expected) summed from the tables after any paid run.

## Decisions this plan takes

Everything below was mine to decide and is stated so it can be pushed back on. D113 to D118 go into `plan/README.md` with the
plan's approval, as D106 to D110 did.

1. **The controls write rows (D113).** `admin_set_model(p_admin, p_kind, p_step, p_model, p_effort, p_fallback, p_enabled,
   p_note, p_ip)` appends an `ai_models` row (`set_by` the admin's email from `admin_users`, `note` the admin's note or reason)
   and the audit row `set_model`; a kind with no row in the table is refused (`unknown_kind`), the step and effort by the table's
   own checks. Switch off is the same function on the draft step with `p_enabled false` and the current values (D100: the draft row
   is the switch); Switch on the same with true. `admin_set_alert_lines(p_admin, p_cost_day_paise, p_error_rate_pct,
   p_error_rate_min_requests, p_stuck_minutes, p_ip)` appends an `alert_lines` row (a new append-only table seeded with the
   constants of `api/src/alerts/lines.ts`: 6000, 5, 20, 10) and the audit row `set_alert_lines`; the alerts job reads
   `alert_lines_current()` on every run and `api/src/alerts/lines.ts` keeps only the shape and the comparison. `admin_set_allowance
   (p_admin, p_centre, p_calls, p_paise, p_reason, p_ip)` updates `centres.ai_allowance` and `ai_allowance_paise` as the platform
   (0029: members cannot) with the audit row `set_allowance` carrying the old and new values and the reason, refused with no reason
   as the record's open is. A model name the portal does not know (not one of `api/models.json`'s price sheet, held equal by a
   test) is refused under the field before any write; the API's table refresh refuses a row whose model is not priced, keeps the
   table it had and logs it, so a bad row written by SQL cannot stop the calls.
2. **The figures are one function (D114).** `admin_figures(p_weeks int)` answers the last `p_weeks` weeks (Monday to Sunday in
   India, the current week so far first): tutors active (distinct users with an `app_opened` event), closes (`attendance_sessions.
   closed_at`), plans made (`plans.made_at`) and followed (`session_id` set), notes sent (`message_log` rows of the parents' kinds),
   made (`artefacts` with `source = 'made'`) and again (`generation_feedback` `again`), Make (`artefacts.made_from = 'make'`),
   consent given (`consent_events` `given`), cost (`ai_generations.cost_paise`) and per active tutor; `admin_reasons_week
   (p_monday)` the week's `again` rows by reason and the `edit` count. An internal centre (`centres.internal`, new, set by the
   session for the Smoke centre) is left out of every figure, of `admin_centres`' active count and of `admin_cost_by_month`'s
   active centres (Phase 21's minor). No new event on the phone: D82's list is answered by the tables already kept.
3. **The weekly report is a job (D115).** Job kind `weekly_report`, queued by `schedule_weekly_report()` (pg_cron Monday 02:30
   UTC, 08:00 IST) keyed `report:<week's Monday>` with input `{ week_monday }`, and by the portal's Send now through
   `admin_send_report(p_admin, p_ip)` keyed `report:now:<minute>` with `{ week_monday, so_far: true }` and the audit row
   `send_report`. The job reads `admin_figures(2)`, renders plain text in code (`api/src/report/text.ts`, pure, tested on fixed
   figures: the board's words), sends through the alerts' `Sender` to `ALERT_EMAIL`, and records `{ sent, to, week }`; Resend's
   failure fails the step with a retry. No AI call. Nothing in it names a tutor or a student.
4. **The golden sets' page and the run a person starts (D116).** `admin_eval_runs()` reads the done `eval_run` jobs: per kind the
   newest job's figures (`result -> 'kinds' -> kind`), when, its cost, and the newest job's `failures`; the gate is the job's own
   `gate`. `admin_run_evals(p_admin, p_kinds text[], p_ip)` inserts an `eval_run` job as `schedule_evals` does (`tc.jobs` on) keyed
   `evals:<day>:admin:<HHMM>` with `{ day, kinds }`, refuses a kind without a golden set (the list is `api/src/evals/cases.ts`'
   `EVAL_KINDS`, carried to the portal by `bun contract` as the call kinds are) and answers null while an `eval_run` is queued or
   running (the page says so); the audit row `run_evals` names the kinds. The owner's choice ("keep the card").
5. **Retention (D117).** `reduce_old_inputs(p_before timestamptz, p_limit int)` replaces `ai_generations.input` with
   `{ "reduced_at", "kind", "student_id" }` on rows with a student, finished, created before `p_before` and not yet reduced; the
   output, the cost and every other column stay. The `sweep` job's retention step calls it with 90 days and 500 rows each run (the
   trigger lets the service role update a finished row). `admin_call` answers `input_reduced`; the portal's Input block shows
   "Reduced after 90 days: only what came back is kept (D79)" in the Held line's place. The trust page gains its paragraph and the
   staff sentence (`web/content/trust.ts`, `TRUST_UPDATED` the deploy's day), with its smoke.
6. **The split per batch (R-api-4, D118).** `school_items.preparations jsonb` (an object: batch id → the days) beside
   `preparation` (the first batch's, as today, for build 31); the `exam_prep` job's split writes both; the app reads the student's
   batch's split from `preparations`, else `preparation`. The job's one mock per exam stays shared.
7. **A push Apple refused is tried again** (Phase 19's gap): `notifications.attempts` (new, default 0); a row that failed on a
   429, a 5xx or no answer is set due again a minute later up to three times through `retry_notification(p_id, p_due_at)`, which
   answers false past the third; a bad token still retires at once. Every kind of push, not alerts alone.
8. **The portal's new reads** (0047's shape, `security invoker`, `service_role` alone): `admin_models()`, `admin_model(p_kind)`,
   `admin_syllabi()`, `admin_syllabus(p_id)`, `admin_figures(p_weeks)`, `admin_reasons_week(p_monday)`, `admin_eval_runs()`;
   `admin_alerts` gains `lines`; `admin_centre` keeps `allowance` and `allowance_paise`; `admin_call` gains `input_reduced`.
9. **The nav and the pages.** Eleven pages in the order the boards draw; `/figures`, `/models`, `/models/[kind]`, `/evals`,
   `/syllabi` each with `loading.tsx` in `P19-Loading-Centres`' grammar and a preview fixture; `bun admin-shots`' `DEFAULT_PAGES`
   gains `/models`, `/models/preview?off=1`, `/models/preview`, `/centres/preview?allowance=1`, `/alerts`, `/syllabi?open=preview`,
   `/figures`, `/evals`, `/calls/preview-feedback`.
10. **Production's one-time steps are the session's (D87):** `update public.centres set internal = true where id = …` for the Smoke
    centre; the first switch off and on of a kind (`scan_register`, a minute each, in production, free: a refusal pays nothing);
    one `weekly_report` job queued by SQL for the week before (`enqueue_job(null, 'weekly_report', 'report:proof', …)`) so the
    email is seen before Monday.
11. **Out of scope, ruled.** U53 stays on `plan/ui-polish.md` (the owner's to take). The placement made each morning for a
    student never closed (session 44's read) is Phase 12's open ruling, listed in STATE, not changed here. A per-student page in
    the portal is not drawn: the record page lists the students and what was made about them (spec 10 met).
12. **Branches and the ledger.** `phase-22/<slug>` in the main checkout, one per pull request; the ledger
    `plan/sessions/045/ledger.md`.
13. **Order of deploys.** Deploy A after PR 4 (0066, the API reading the lines and refusing a bad model row); the portal after
    PR 4. Deploy B after PR 9 (0067, 0068, the weekly report, retention, the split, the push retry); the portal after PR 8;
    `deploy-web` after PR 10. Build 32 after PR 11 and the hand runs.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that owns
the code.

1. **A switched-off kind the tutor keeps tapping.** The API refreshes the table once a minute; a tap within that minute still
   pays. Task 3's `a table refreshed within the minute answers the row it had` and the hand run's clock (Task 12: the refusal
   seen by 60 s).
2. **A model row the API cannot price.** `admin_set_model` with a mistyped model written by SQL: the refresh must keep the last
   good table, not stop the API or make unpriced calls. Task 3's `a row with an unpriced model is refused and the table kept`.
3. **The allowance lowered under a centre's use.** A centre at 650 calls given an allowance of 600: the next draft is refused in
   the app's words, nothing already made is touched. Task 2's `the next call meets the new allowance`.
4. **A week with no active tutor.** Cost per active tutor divides by zero: the row answers 0 and the page shows "—". Task 6's
   `a week with no active tutor shows zero per tutor`.
5. **A reduced input on the portal and in the job's replay.** A call whose input was reduced must still replay by its key (D84)
   without exposing the old input, and the page must say reduced, not held. Task 9's `a reduced row's page says reduced, not held`
   and `a replay of a reduced row answers its output`.
6. **A push failed three times.** The fourth failure marks the row failed and stops; a retired token never retries. Task 9's
   `a push Apple refused is tried three times a minute apart, then failed`.
7. **Two batches, one exam, one student in each.** Each batch's page shows its own days; the plan of each follows its own. Task
   10's `two batches get two splits` and the SchoolTests case.

## File structure

**Database (`supabase/`)**
- `migrations/20261209000066_v3_admin_controls.sql`: `alert_lines` with `alert_lines_current()`; `centres.internal`;
  `admin_set_model`, `admin_set_alert_lines`, `admin_set_allowance`; `admin_models`, `admin_model`; `admin_alerts` with
  `lines`; `admin_centres` and `admin_cost_by_month` leaving internal centres out of the active counts.
- `migrations/20261210000067_v3_figures_evals_report.sql`: `admin_figures`, `admin_reasons_week`, `admin_eval_runs`,
  `admin_run_evals`, `admin_syllabi`, `admin_syllabus`; job kind `weekly_report` (the null-centre check), `schedule_weekly_report`
  and its cron, `admin_send_report`.
- `migrations/20261211000068_v3_retention_split_push.sql`: `reduce_old_inputs`; `admin_call` with `input_reduced`;
  `school_items.preparations`; `notifications.attempts` and `retry_notification`.
- `tests/admin-controls.test.ts`, `tests/figures.test.ts`, `tests/evals-runs.test.ts`, `tests/retention.test.ts`,
  `tests/push-retry.test.ts` (new); `tests/rls.test.ts` (the catalogue), `tests/admin-reads.test.ts`, `tests/schedules.test.ts`,
  `tests/jobs.test.ts` (Task 1), `types.ts`, `seed.sql` (an `alert_lines` row is the migration's; nothing else).

**API (`api/`)**
- `src/alerts/lines.ts` (`Lines`, `alertsFor(facts, now, lines)`), `src/alerts/db.ts` (`lines()`), `src/jobs/kinds/alerts.ts`;
  `src/models.ts` (the refresh refuses an unpriced model), `src/models-db.ts` (unchanged);
  `src/report/text.ts` (new), `src/jobs/kinds/weekly-report.ts` (new), `src/jobs/kinds/index.ts`, `src/jobs/types.ts`
  (the kind), `src/index.ts` (the source);
  `src/jobs/kinds/sweep.ts` and `src/jobs/sweep-db.ts` (`reduceInputs`); `src/jobs/kinds/exam-prep.ts` and `src/jobs/exam-source.ts`
  (`writePreparation` with the map); `src/push/send-due.ts`, `src/push/db.ts` (`retry`); `src/contract.ts` (`evalKinds`).
- Tests: `test/alerts.test.ts`, `test/models-table.test.ts` (new), `test/report-text.test.ts` (new), `test/weekly-report.test.ts`
  (new), `test/sweep.test.ts`, `test/exam-prep-job.test.ts`, `test/send-due.test.ts`, `test/contract.test.ts`.

**Admin (`admin/`)**
- `app/models/page.tsx`, `app/models/loading.tsx`, `app/models/[kind]/page.tsx`, `app/models/[kind]/loading.tsx`,
  `app/models/actions.ts`; `app/centres/[id]/page.tsx` and `actions.ts` (the allowance); `app/alerts/page.tsx` and `actions.ts`
  (the lines); `app/syllabi/page.tsx`, `loading.tsx`; `app/figures/page.tsx`, `loading.tsx`, `actions.ts` (Send now);
  `app/evals/page.tsx`, `loading.tsx`, `actions.ts` (the run); `app/calls/[id]/page.tsx` (the Feedback row, the reduced line).
- `components/Frame.tsx` (the nav), `components/parts.tsx` (`Select`, `FormRow`, `KindChips`), `app/globals.css` (the nav's size).
- `content/models.ts` (`MODELS`, `MODEL`, `KNOWN_MODELS`), `content/figures.ts`, `content/evals.ts`, `content/syllabi.ts` (new);
  `content/alerts.ts` (`LINES_FORM`, the audit's actions), `content/centres.ts` (`ALLOWANCE`), `content/calls.ts` (`FEEDBACK`,
  `REDUCED`), `content/words.ts` (`PENDING`).
- `lib/data/types.ts`, `real.ts`, `preview.ts`; `preview/{models,model,syllabi,syllabus,figures,evals,call-feedback}.json`,
  `preview/alerts.json` (`lines`), `preview/centre.json`.
- Tests: `test/unit/models.test.tsx`, `figures.test.tsx`, `evals.test.tsx`, `syllabi.test.tsx` (new), `alerts.test.tsx`,
  `centres.test.tsx`, `calls.test.tsx`, `frame.test.tsx`, `words.test.ts`, `loading.test.tsx`, `known-models.test.ts` (new).
- `tools/admin-shots.ts` (`DEFAULT_PAGES`), `tools/contract.ts` (the eval kinds for the portal).

**Website (`web/`)**: `content/trust.ts`, `content/site.ts` (`TRUST_UPDATED`), `test/unit/trust.test.ts`.

**iOS (`ios/`)**: `Sources/Domain/School/SchoolItem.swift` (`preparations`), `Sources/Domain/School/ExamPreparation.swift`
(`days(forBatch:)`), `Sources/Features/School/ItemStore+Preparation.swift`, `Sources/Features/Today/PlanPreview+Exam.swift`,
`Sources/Data/School/*` (the decoder); `Tests/SchoolTests/PreparationByBatchTests.swift`, `Tests/DomainTests`.

**Documents:** `api/CLAUDE.md`, `admin/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`, `ios/CLAUDE.md`, `CLAUDE.md`,
`docs/runbooks/admin.md` (the controls' hand run), `docs/release.md`, `docs/testing/tester-guide.md`,
`docs/testing/device-tests.md` (T21), `plan/README.md` (D113 to D118 with the approval; the status), the phase file ("As
built"), `plan/STATE.md`, `plan/sessions/045/`, `docs/design/information-architecture.md` (what the build settles).

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-22/jobs-test-clock` | The jobs test hands `wait_job` a time in the past: deterministic against the database's clock | none |
| 2 | 2 | `phase-22/db-controls` | Migration 0066: the alert lines, the controls' writers with their audit rows, the models' reads, internal centres | none |
| 3 | 3 | `phase-22/api-lines-models` | The alerts job reads the lines from the table; the model table's refresh refuses an unpriced row | none |
| 4 | 4, 5 | `phase-22/admin-controls` | The portal's Models pages with Switch off, the allowance dialog, the alert lines form; the nav of eleven | /models, /models/preview, /models/preview?off=1, /centres/preview?allowance=1, /alerts (1280 and 390, both) |
| 5 | 6 | `phase-22/db-figures-evals` | Migration 0067: the figures, the reasons, the eval runs and the run a person starts, the syllabi, the weekly report's job and schedule | none |
| 6 | 7 | `phase-22/api-weekly-report` | The `weekly_report` job: the text, the send, the result | none |
| 7 | 8 | `phase-22/admin-figures-evals` | Figures with the report card, Golden sets with the run card, Syllabus data, the call page's Feedback row | /figures, /evals, /syllabi?open=preview, /calls/preview-feedback (1280 and 390, both) |
| 8 | 9 | `phase-22/db-api-retention` | Migration 0068: old inputs reduced by the sweep, the split per batch, a refused push tried again; the call page's reduced line | /calls/preview-reduced (1280 and 390, both) |
| 9 | 10 | `phase-22/ios-split-by-batch` | The exam page reads its student's batch's split | none (no screen changes; the fixture's page unchanged) |
| 10 | 11 | `phase-22/web-trust-retention` | The trust page's retention paragraph and the staff sentence | /trust (1280 and 390, both) |
| 11 | 12 | `phase-22/hand-runs` | What the hand runs find (D68) | the hand runs' pictures on the issue |
| 12 | 14 | `phase-22/round-documents` | The round's documents read against V3: the checklist for build 32, the tester's guide, T21 | none |

Every PR with pictures carries them by `bun pr-shots` (D7): `bun admin-shots --pages …` for the portal, `bun web-shots --pages
/trust` for the website.

## The order

Task 1 → 2 → 3 → 4 → 5 (Deploy A, the portal) → 6 → 7 → 8 (the portal) → 9 → 10 (Deploy B) → 11 (deploy-web) → 12 (the hand
runs) → 13 (build 32, production's steps) → 14 (the round's documents) → 15 (the review, the documents). Task 4 needs 2's
functions; Task 8 needs 6's; Task 10 needs 9's column. No owner question is expected before Task 13 (build 32 is his to try).

---

### Task 1: The jobs test's clock (PR 1)

**Files:**
- Modify: `supabase/tests/jobs.test.ts` (the test "waiting continues at the step reached and is not another attempt; done keeps
  its result")

**Interfaces:** none.

- [ ] **Step 1: the change.** `p_run_at: new Date().toISOString()` becomes `p_run_at: new Date(Date.now() - 60_000).toISOString()`,
  with the comment `// A minute ago: the Mac's clock can run ahead of Postgres's, and a job due in the future is not claimed.`
- [ ] **Step 2: run it ten times** to see it hold: `cd supabase && for i in 1 2 3 4 5 6 7 8 9 10; do bun test tests/jobs.test.ts
  --timeout 20000 || break; done` (local Supabase up, no local worker running). Expected: ten passes.
- [ ] **Step 3: `bun check --only=db`** green. Commit, PR 1, merge on local green. Ledger line (the flake seen in session 44, the
  fix, ten runs).

---

### Task 2: Migration 0066: the controls (PR 2)

**Files:**
- Create: `supabase/migrations/20261209000066_v3_admin_controls.sql`, `supabase/tests/admin-controls.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the catalogue: `alert_lines`), `supabase/tests/admin-reads.test.ts`, `supabase/types.ts`
  (`supabase gen types typescript --local > supabase/types.ts`), then `bun contract`

**Interfaces:**
- Produces:
  - `alert_lines` (`id`, `cost_day_paise int`, `error_rate_pct numeric`, `error_rate_min_requests int`, `stuck_minutes int`,
    `since timestamptz`, `set_by text`, `created_at`, `updated_at`; each number `>= 0`; RLS, no member reads, `service_role`
    inserts only: `revoke update, delete, truncate` as `ai_models` has); seeded `(6000, 5, 20, 10, 'seed 0066')`.
  - `alert_lines_current() returns table (cost_day_paise int, error_rate_pct numeric, error_rate_min_requests int, stuck_minutes
    int, since timestamptz, set_by text)`: the newest row.
  - `centres.internal boolean not null default false`.
  - `admin_set_model(p_admin uuid, p_kind text, p_step text, p_model text, p_effort text, p_fallback text, p_enabled boolean,
    p_note text, p_ip text) returns uuid`: refuses a kind with no `ai_models` row (`raise exception 'unknown_kind'`, errcode
    `P0001`); inserts the row with `set_by` the admin's email (`admin_users`), `note` = `p_note`; audit `set_model`, target
    `{ kind, step, model, effort, fallback, enabled }`, reason `p_note`; returns the row's id.
  - `admin_set_alert_lines(p_admin uuid, p_cost_day_paise int, p_error_rate_pct numeric, p_error_rate_min_requests int,
    p_stuck_minutes int, p_ip text) returns uuid`: inserts; audit `set_alert_lines`, target the four values.
  - `admin_set_allowance(p_admin uuid, p_centre uuid, p_calls int, p_paise int, p_reason text, p_ip text) returns boolean`:
    `reason_required` as `admin_open_record`; false for a centre that is gone; updates the two columns; audit `set_allowance`
    with target `{ calls, paise, before: { calls, paise } }` and the reason.
  - `admin_models() returns jsonb`: `{ tiles: { kinds, off, changes_month, last_change }, rows: [{ kind, draft: { model, effort,
    fallback_model, enabled, since, set_by, note }, check: {…}, repair: {…}, changed_at, changed_by, note }] }` ordered by kind;
    `changes_month` counts rows this month in India whose `set_by` is not `seed`; `off` counts kinds whose draft row is disabled.
  - `admin_model(p_kind text) returns jsonb`: `{ kind, current: [the three steps' rows], history: [every row of the kind, newest
    first, with since, step, model, effort, fallback_model, enabled, set_by, note] }`, null for a kind with no row.
  - `admin_alerts(p_open_first)` gains `lines: { cost_day_paise, error_rate_pct, error_rate_min_requests, stuck_minutes, since,
    set_by }` (build on 0047's body; read every migration that defines `admin_alerts` first).
  - `admin_centres(p_month)`' `active_week` and `admin_cost_by_month(p_centre)`' `active_centres` leave out centres with `internal`
    (read every migration that defines each: 0047, 0061 and any later).

- [ ] **Step 1: the failing tests** (`supabase/tests/admin-controls.test.ts`, the fixtures and clients of `admin-reads.test.ts`:
  `svc` the service client, `a` a member of centre A, `adminId` an `admin_users` row made in `beforeAll`):

```ts
test("a model change is a new row with the admin's name, the newest row is current, and the audit names it", async () => {
  const id = (await svc.rpc("admin_set_model", { p_admin: adminId, p_kind: "brief", p_step: "draft", p_model: "claude-sonnet-5-5", p_effort: "high", p_fallback: "claude-haiku-5-5", p_enabled: true, p_note: "high effort: the slips were shallow", p_ip: "127.0.0.1" })).data as string;
  expect(id).toMatch(/^[0-9a-f-]{36}$/);
  const current = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; effort: string }[];
  expect(current.find((r) => r.kind === "brief" && r.step === "draft")?.effort).toBe("high");
  const rows = await svc.from("ai_models").select("set_by, note").eq("kind", "brief").eq("step", "draft").order("since", { ascending: false });
  expect(rows.data?.[0]).toMatchObject({ set_by: adminEmail, note: "high effort: the slips were shallow" });
  const audit = await svc.from("admin_audit").select("action, target, reason").eq("admin_user_id", adminId).order("created_at", { ascending: false }).limit(1).single();
  expect(audit.data).toMatchObject({ action: "set_model", target: { kind: "brief", step: "draft", effort: "high", enabled: true } });
});
test("switching a kind off is a disabled draft row; the current read says so", async () => {
  await svc.rpc("admin_set_model", { p_admin: adminId, p_kind: "mock", p_step: "draft", p_model: "claude-sonnet-5-5", p_effort: "high", p_fallback: "claude-haiku-5-5", p_enabled: false, p_note: "a wrong marks total in two mocks", p_ip: null });
  const current = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; enabled: boolean }[];
  expect(current.find((r) => r.kind === "mock" && r.step === "draft")?.enabled).toBe(false);
  const models = (await svc.rpc("admin_models")).data as { tiles: { off: number }; rows: { kind: string; draft: { enabled: boolean } }[] };
  expect(models.tiles.off).toBe(1);
  expect(models.rows.find((r) => r.kind === "mock")?.draft.enabled).toBe(false);
});
test("a kind with no row is refused", async () => {
  const r = await svc.rpc("admin_set_model", { p_admin: adminId, p_kind: "nonsense", p_step: "draft", p_model: "claude-sonnet-5-5", p_effort: "medium", p_fallback: null, p_enabled: true, p_note: null, p_ip: null });
  expect(r.error?.message).toContain("unknown_kind");
});
test("the lines: the seed is the code's constants, a new row is current, the alerts read carries it", async () => {
  const seed = (await svc.rpc("alert_lines_current")).data as { cost_day_paise: number; error_rate_pct: number; error_rate_min_requests: number; stuck_minutes: number }[];
  expect(seed[0]).toMatchObject({ cost_day_paise: 6000, error_rate_pct: 5, error_rate_min_requests: 20, stuck_minutes: 10 });
  await svc.rpc("admin_set_alert_lines", { p_admin: adminId, p_cost_day_paise: 9000, p_error_rate_pct: 4, p_error_rate_min_requests: 30, p_stuck_minutes: 15, p_ip: null });
  expect(((await svc.rpc("alert_lines_current")).data as { cost_day_paise: number }[])[0].cost_day_paise).toBe(9000);
  const alerts = (await svc.rpc("admin_alerts", { p_open_first: true })).data as { lines: { stuck_minutes: number; set_by: string } };
  expect(alerts.lines).toMatchObject({ stuck_minutes: 15, set_by: adminEmail });
});
test("the allowance: the next call meets the new allowance, the audit keeps the old values, no reason is refused", async () => {
  expect((await svc.rpc("admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: 1, p_paise: 0, p_reason: "", p_ip: null })).error?.message).toContain("reason_required");
  expect((await svc.rpc("admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: 1, p_paise: 0, p_reason: "a test", p_ip: null })).data).toBe(true);
  // One draft this month already (the fixture's), so the second is refused by start_ai_call's allowance.
  await startCall(a, centreA, "sheet", "k-1");
  const second = await startCall(a, centreA, "sheet", "k-2");
  expect(second.error?.message).toContain("allowance");
  const audit = await svc.from("admin_audit").select("target").eq("action", "set_allowance").order("created_at", { ascending: false }).limit(1).single();
  expect(audit.data?.target).toMatchObject({ calls: 1, paise: 0, before: { calls: 600, paise: 0 } });
});
test("an internal centre is not an active centre", async () => {
  await svc.from("centres").update({ internal: true }).eq("id", centreB);
  await svc.from("events").insert({ centre_id: centreB, user_id: userB, kind: "app_opened", at: new Date().toISOString() });
  const centres = (await svc.rpc("admin_centres", { p_month: month })).data as { tiles: { active_week: number } };
  expect(centres.tiles.active_week).toBe(0);
});
test("a member calls none of the writers", async () => {
  for (const [fn, args] of [["admin_set_model", { p_admin: adminId, p_kind: "brief", p_step: "draft", p_model: "x", p_effort: "low", p_fallback: null, p_enabled: true, p_note: null, p_ip: null }], ["admin_set_alert_lines", { p_admin: adminId, p_cost_day_paise: 1, p_error_rate_pct: 1, p_error_rate_min_requests: 1, p_stuck_minutes: 1, p_ip: null }], ["admin_set_allowance", { p_admin: adminId, p_centre: centreA, p_calls: 1, p_paise: 0, p_reason: "x", p_ip: null }], ["admin_models", {}], ["alert_lines_current", {}]] as const) {
    expect((await a.rpc(fn, args)).error?.code).toBe("42501");
  }
});
```

  `startCall` is the helper `admin-reads.test.ts` or `ai-models.test.ts` uses for `start_ai_call` as a member (copy it if it is
  local to that file). `admin-reads.test.ts` gains `admin_cost_by_month leaves an internal centre out of the active centres`.
- [ ] **Step 2: RED** (`cd supabase && bun test tests/admin-controls.test.ts`: every test fails on a missing function or column),
  then the migration. The functions in 0046's and 0047's shape; `admin_alerts`, `admin_centres` and `admin_cost_by_month` with
  `create or replace` on their newest bodies. Then `supabase gen types typescript --local > supabase/types.ts` and `bun contract`.
- [ ] **Step 3: GREEN** (`bun check --only=db,tools,api`; the api step only for the generated types). Commit, PR 2, merge on
  local green. Ledger line.

---

### Task 3: The API reads the lines; the model table refuses an unpriced row (PR 3)

**Files:**
- Modify: `api/src/alerts/lines.ts`, `api/src/alerts/db.ts`, `api/src/jobs/kinds/alerts.ts`, `api/src/models.ts` (the install
  and the refresh of the table: `installModelTable`), `api/test/alerts.test.ts`
- Create: `api/test/models-table.test.ts`

**Interfaces:**
- Produces: `type Lines = { costDayPaise: number; errorRatePct: number; errorRateMinRequests: number; stuckMinutes: number }`;
  `DEFAULT_LINES: Lines` (6000, 5, 20, 10: a test's and a local run's fallback); `alertsFor(facts: Facts, now: Date, lines: Lines):
  Alert[]`; `AlertsSource.lines(): Promise<Lines>` (`alert_lines_current`); the alerts job reads `lines()` once per run and names
  the line's value in each message as today. `installModelTable(source)` keeps its signature; a refreshed row whose `model` is not
  a key of `models.json`'s price sheet (`priced(model)` from `src/price.ts`) is dropped with `log.error({ message: "a model row is
  not priced", kind, step, model })` and the previous row for that kind and step stays.

- [ ] **Step 1: the failing tests.** `api/test/alerts.test.ts`: `the lines come from the source: a centre at ₹72 is quiet under a
  ₹90 line` (the fake source answers `{ costDayPaise: 9000, … }`; `alertsFor` raises nothing for 7200). `api/test/models-table.test.ts`:
  `a row with an unpriced model is refused and the table kept` (a fake source answering `brief`/`draft` as `claude-sonnet-5-5`
  first, then as `claude-sonnet-6-0`: the second refresh keeps Sonnet 5.5 and logs once) and `a table refreshed within the minute
  answers the row it had` (two reads 10 s apart on a fake clock: one source call).
- [ ] **Step 2: RED** (`cd api && bun test test/alerts.test.ts test/models-table.test.ts`), then the code. `src/index.ts` passes
  nothing new: the source gains `lines()`.
- [ ] **Step 3: GREEN** (`bun check --only=api`). Commit, PR 3, merge. Ledger line.

---

### Task 4: The portal's Models pages, Switch off, the nav of eleven (PR 4, part 1)

**Files:**
- Create: `admin/app/models/page.tsx`, `admin/app/models/loading.tsx`, `admin/app/models/[kind]/page.tsx`,
  `admin/app/models/[kind]/loading.tsx`, `admin/app/models/actions.ts`, `admin/preview/models.json`, `admin/preview/model.json`,
  `admin/test/unit/models.test.tsx`, `admin/test/unit/known-models.test.ts`
- Modify: `admin/components/Frame.tsx` (the nav: Centres, Figures, Cost, Calls, Jobs, Errors, Alerts, Models, Evals, Syllabi,
  Audit), `admin/app/globals.css` (the nav 14/600, 8 × 10, gap 2 at 1280), `admin/components/parts.tsx` (`Select`: a labelled
  `<select>` in the field's grammar; `FormRow`: the four-across grid), `admin/content/models.ts` (`MODELS`, `MODEL`, `KNOWN_MODELS`,
  `modelName` as is), `admin/content/words.ts` (`PENDING.save: "Saving…"`, `PENDING.switchOff: "Switching off…"`, `PENDING.switchOn:
  "Switching on…"`), `admin/lib/data/{types,real,preview}.ts`, `admin/test/unit/frame.test.tsx`, `admin/test/unit/words.test.ts`,
  `admin/test/unit/loading.test.tsx`, `tools/admin-shots.ts`

**Interfaces:**
- Consumes: `admin_models()`, `admin_model(p_kind)`, `admin_set_model(…)` (Task 2).
- Produces: `Data.models(): Promise<Models>`, `Data.model(kind: string): Promise<Model | null>`, `Data.setModel(admin: string,
  change: ModelChange, ip: string | null): Promise<string>` with `type ModelChange = { kind: string; step: "draft" | "check" |
  "repair"; model: string; effort: "low" | "medium" | "high"; fallback: string | null; enabled: boolean; note: string | null }`;
  `KNOWN_MODELS = ["claude-opus-5-5", "claude-sonnet-5-5", "claude-haiku-5-5"] as const`; the words of `content/models.ts` from
  P22-Models, P22-Model and P22-Model-SwitchOff (the title, the lead, the tiles' labels, the heads, the "How a change takes effect"
  lines, the form's labels, the dialog's words quoting the tutor's: "Briefs can’t be made right now. Making briefs is switched off
  for a short while so we can fix something. Everything else works as usual. Try again later." built from the kind's words as
  `api/src/errors.ts`'s `paused` builds them: carry `KIND_WORDS` and `DOING` to the portal by `bun contract` as `kindWords`); the
  actions `saveStep(form)` (fields `kind`, `step`, `model`, `effort`, `fallback`, `note`; a model not in `KNOWN_MODELS` redirects
  to `/models/<kind>?bad=model` and the page shows "Not a model this API knows" under the field; a blank note is null), `switchOff
  (form)` (`kind`, `reason`; an empty reason redirects `?off=1&empty=1`; writes the draft step disabled with the current draft's
  values) and `switchOn(form)` (the draft step enabled, the current values, note "switched on"). Pages: `/models` (the tiles, the
  table, the card), `/models/[kind]` (Current, Change a step, History; `?off=1` opens the dialog; the title's chip and button follow
  `current.draft.enabled`).

- [ ] **Step 1: the failing tests.** `models.test.tsx` (preview): `/models` holds "AI models", a row "mock" with the chip "off" and
  "Change"; `/models/brief` holds "Current", "Change a step", "History", a history row "high effort: the slips were shallow";
  `/models/brief?off=1` holds "Switch off brief?" and the tutor's words. `known-models.test.ts`: `KNOWN_MODELS` equals the keys of
  `api/models.json`'s price sheet (read the file from the repo root). `frame.test.tsx`: the nav has eleven links in the boards'
  order. `words.test.ts`: every page under `app/models` calls `requireAdmin` first (the existing rule). `loading.test.tsx`: the
  two new `loading.tsx` render `PageLoading` with their titles.
- [ ] **Step 2: RED** (`cd admin && bun test test/unit/models.test.tsx test/unit/known-models.test.ts test/unit/frame.test.tsx`),
  then the pages per the boards, the fixtures with the boards' figures (the preview's kinds are the board's twelve), the actions.
- [ ] **Step 3: GREEN** (`bun check --only=admin,tools`). Then Task 5 on the same branch.

---

### Task 5: The allowance dialog and the alert lines form (PR 4, part 2)

**Files:**
- Modify: `admin/app/centres/[id]/page.tsx` (the Change link on the allowance line; `?allowance=1` opens the dialog; `?allowance=1
  &empty=1` the empty-reason line), `admin/app/centres/[id]/actions.ts` (`setAllowance`), `admin/content/centres.ts` (`ALLOWANCE`:
  the dialog's words from P22-Centre-Allowance), `admin/app/alerts/page.tsx` (the lines card as a form, from P22-Alerts-Lines:
  the four fields, Save the lines, the last change line; the Phase 19 note "The lines change in Phase 22." gone),
  `admin/app/alerts/actions.ts` (`saveLines`), `admin/content/alerts.ts` (`LINES_FORM`; `AUDIT.actions` gains `set_model`,
  `set_alert_lines`, `set_allowance`, `run_evals`, `send_report`), `admin/content/words.ts` (`PENDING.saveLines: "Saving the
  lines…"`, `PENDING.saveAllowance: "Saving the allowance…"`), `admin/lib/data/{types,real,preview}.ts` (`Alerts.lines`,
  `Data.setAllowance(admin, centre, calls, paise, reason, ip): Promise<boolean>`, `Data.setLines(admin, lines, ip): Promise<void>`),
  `admin/preview/alerts.json` (`lines`), `admin/test/unit/alerts.test.tsx`, `admin/test/unit/centres.test.tsx`, `tools/admin-shots.ts`
  (`DEFAULT_PAGES` gains `/models`, `/models/preview`, `/models/preview?off=1`, `/centres/preview?allowance=1`)

**Interfaces:**
- Consumes: `admin_set_allowance`, `admin_set_alert_lines`, `admin_alerts.lines` (Task 2).
- Produces: the two actions; a number field refused when not a whole number ≥ 0 (`?allowance=1&bad=1`, "Whole numbers, 0 or
  more" under the fields; the lines likewise `?bad=lines`).

- [ ] **Step 1: the failing tests.** `centres.test.tsx`: `/centres/preview` holds "Change" beside the allowance line;
  `/centres/preview?allowance=1` holds "Change the allowance of Sunrise Tuition Centre?", "Calls a month", "0 is no cap", "Save the
  allowance". `alerts.test.tsx`: `/alerts` holds "Save the lines", "cost_day · ₹ a centre in a day", "last changed", and no longer
  "The lines change in Phase 22."
- [ ] **Step 2: RED**, then the code.
- [ ] **Step 3: GREEN** (`bun check --only=admin,tools`); `bun admin-shots --pages /models,/models/preview,/models/preview?off=1,
  /centres/preview?allowance=1,/alerts` (1280 and 390, both appearances) beside the boards; `bun pr-shots`. Commit, PR 4, merge
  on local green. Then **Deploy A**: `gh workflow run deploy` (0066, the API's lines and the model refresh), then
  `gh workflow run deploy-admin`. Read back in production: `select * from public.alert_lines_current()` (the seed), the portal's
  `/models` by the owner's eye is Task 13's. Ledger lines with the run numbers.

---

### Task 6: Migration 0067: the figures, the eval runs and the run a person starts, the syllabi, the weekly report's job (PR 5)

**Files:**
- Create: `supabase/migrations/20261210000067_v3_figures_evals_report.sql`, `supabase/tests/figures.test.ts`,
  `supabase/tests/evals-runs.test.ts`
- Modify: `supabase/tests/schedules.test.ts`, `supabase/tests/admin-reads.test.ts`, `supabase/types.ts`, then `bun contract`

**Interfaces:**
- Produces:
  - `admin_figures(p_weeks int) returns jsonb`: `[{ week_monday, so_far, tutors_active, closes, plans_made, plans_followed,
    notes_sent, made, again, make, consent_given, cost_paise, per_active_tutor_paise }]`, the current week first, `so_far` true on
    it; internal centres left out everywhere; `per_active_tutor_paise` 0 when `tutors_active` is 0. Notes sent: `message_log`
    rows whose `kind` is one of the parents' message kinds (the enum `message_kind`'s values for the weekly note, can-now-do, test
    tomorrow, not on track and the progress note: read the enum in `20261007000001_schema.sql` and its later additions and name
    them in the function; never `consent`, the absence alert or the fee reminder).
  - `admin_reasons_week(p_monday date) returns jsonb`: `{ again: [{ reason, count }] ordered by count desc, edits: n, made: n }`.
  - `admin_syllabi() returns jsonb`: `{ tiles: { syllabi, boards, classes, chapters }, rows: [{ id, board, class_level, subject,
    edition, chapters, skills }] }` ordered by board, class, subject; `admin_syllabus(p_id uuid) returns jsonb`: `{ id, board,
    class_level, subject, edition, chapters: [{ no, name, skills: [names], marks }] }` (`marks` from `blueprint` when it names the
    chapter, else null).
  - `admin_eval_runs() returns jsonb`: `{ tiles: { kinds, passed, below, last_run_at, last_run_paise }, rows: [{ kind, run_at,
    job_id, cases, schema, verify, check_pass, grade_pass, grade_rate, gate, cost_paise }] for every kind in the newest done
    `eval_run` jobs (the newest job that holds the kind), failures: [{ id, reasons }] of the newest done job, queued: a queued or
    running eval_run's id or null }`.
  - `admin_run_evals(p_admin uuid, p_kinds text[], p_ip text) returns uuid`: null when an `eval_run` is queued or running; else an
    `eval_run` row inserted with `tc.jobs` on (as `schedule_evals` does) keyed `evals:<India's day>:admin:<HH24MI>`, input
    `{ day, kinds }` (`p_kinds` null or empty means every kind: no `kinds` key), `run_at now()`; audit `run_evals` with target
    `{ kinds }`.
  - `job_kind` gains `weekly_report`; the `jobs_check` constraint lists it among the kinds with no centre.
  - `schedule_weekly_report(p_now timestamptz default now()) returns integer`: a `weekly_report` job keyed `report:<the Monday of
    the week before p_now in India>` with input `{ week_monday }`, `run_at p_now`, `on conflict do nothing`; `cron.schedule
    ('schedule_weekly_report', '30 2 * * 1', 'select public.schedule_weekly_report()')`.
  - `admin_send_report(p_admin uuid, p_ip text) returns uuid`: a `weekly_report` job keyed `report:now:<HH24MI>` with
    `{ week_monday: this week's Monday, so_far: true }`; audit `send_report`.

- [ ] **Step 1: the failing tests** (`figures.test.ts`, fixtures through the product's own functions where they exist: a close
  through `close_session`, a plan row, a `message_log` row, an artefact, a `record_feedback` row, a `consent_events` row, an
  `ai_generations` row of 100 paise; `weeks` the function's answer):

```ts
test("the week's figures count what the tables hold, the current week first and so far", async () => {
  const weeks = (await svc.rpc("admin_figures", { p_weeks: 2 })).data as Figures[];
  expect(weeks).toHaveLength(2);
  expect(weeks[0]).toMatchObject({ so_far: true, tutors_active: 1, closes: 1, plans_made: 1, plans_followed: 1, notes_sent: 1, made: 1, again: 1, make: 1, consent_given: 1, cost_paise: 100, per_active_tutor_paise: 100 });
});
test("a week with no active tutor shows zero per tutor", async () => {
  const weeks = (await svc.rpc("admin_figures", { p_weeks: 2 })).data as Figures[];
  expect(weeks[1]).toMatchObject({ tutors_active: 0, per_active_tutor_paise: 0 });
});
test("an internal centre is left out of the figures", async () => {
  await svc.from("centres").update({ internal: true }).eq("id", centreB);
  // centre B's event and call of this week
  const weeks = (await svc.rpc("admin_figures", { p_weeks: 1 })).data as Figures[];
  expect(weeks[0].tutors_active).toBe(1);
});
test("the reasons of the week", async () => {
  const r = (await svc.rpc("admin_reasons_week", { p_monday: monday })).data as { again: { reason: string; count: number }[]; edits: number };
  expect(r.again[0]).toMatchObject({ reason: "Less about marks", count: 1 });
  expect(r.edits).toBe(1);
});
test("the weekly report is scheduled once a week and sent now by an admin", async () => {
  expect((await svc.rpc("schedule_weekly_report", { p_now: "2026-10-19T02:30:00Z" })).data).toBe(1);
  expect((await svc.rpc("schedule_weekly_report", { p_now: "2026-10-19T02:31:00Z" })).data).toBe(0);
  const job = await svc.from("jobs").select("kind, idempotency_key, input").eq("kind", "weekly_report").order("created_at", { ascending: false }).limit(1).single();
  expect(job.data).toMatchObject({ idempotency_key: "report:2026-10-12", input: { week_monday: "2026-10-12" } });
  const id = (await svc.rpc("admin_send_report", { p_admin: adminId, p_ip: null })).data as string;
  expect((await svc.from("jobs").select("input").eq("id", id).single()).data?.input).toMatchObject({ so_far: true });
});
```

  `evals-runs.test.ts`: `the newest done run answers each kind's figures and the failures` (two done `eval_run` jobs inserted as
  the platform with `result` in the shape of production's: the newer holds `plan` and `brief`, the older `check`; the read gives
  `plan` and `brief` from the newer, `check` from the older, `failures` the newer's), `a run started by an admin is a job with its
  kinds and an audit row; a second while one is queued answers null`, `a member reads and starts nothing (42501)`. `admin-reads.test.ts`:
  `the syllabi and one syllabus with its chapters`. `schedules.test.ts`: `cron.job` holds `schedule_weekly_report` at `30 2 * * 1`.
- [ ] **Step 2: RED**, then the migration (every function 0047's shape; `jobs_check` rebuilt as 0046 did; the enum value added
  before anything uses it, in its own statement).
- [ ] **Step 3: GREEN** (`bun check --only=db,tools,api`). Commit, PR 5, merge. Ledger line.

---

### Task 7: The `weekly_report` job (PR 6)

**Files:**
- Create: `api/src/report/text.ts`, `api/src/jobs/kinds/weekly-report.ts`, `api/test/report-text.test.ts`,
  `api/test/weekly-report.test.ts`
- Modify: `api/src/jobs/types.ts` (`JobKind` gains `weekly_report`), `api/src/jobs/kinds/index.ts` (`report?: { source:
  ReportSource; sender: Sender; email: string }`), `api/src/jobs/db.ts` or a new `api/src/report/db.ts` (`makeReportSource`:
  `figures(weeks)` through `admin_figures`, `reasons(monday)` through `admin_reasons_week`, `centres()` through `admin_centres`'
  tiles for the centres and in-use counts, `openAlerts()` through `admin_alerts`), `api/src/index.ts` (the source, the alerts'
  sender and email reused)

**Interfaces:**
- Consumes: `admin_figures`, `admin_reasons_week` (Task 6); `Sender` (`src/alerts/resend.ts`).
- Produces: `reportText(input: { week: Figures; before: Figures; reasons: Reasons; centres: { total: number; inUse: number };
  openAlerts: number; soFar: boolean }): { subject: string; text: string }`: the board's words (P22-Weekly-Email): the subject
  "Tutor Central, the week of 6 to 12 October" (or "…, the week of 13 October so far" when `soFar`), the lines in the board's order
  with the week before in brackets, the reasons line, "The figures, by week: https://admin.tutorcentral.in/figures", the closing
  line. The job: one step `send`: reads, renders, `sender.send(email, subject, text)`, result `{ sent: true, to: email, week:
  week_monday }`; a thrown send fails the step with `retry: true` (the runner's backoff); the step is keyed by the job (one send per
  job).

- [ ] **Step 1: the failing tests.** `report-text.test.ts`: `the text is the board's: a line per figure with the week before in
  brackets, no name` (fixed figures → the exact lines of P22-Weekly-Email), `a week so far says so in the subject`, `a week with no
  reason has no reasons line`. `weekly-report.test.ts`: `the job sends one email and records it` (a fake source and `fakeSender`),
  `a send that fails retries` (`fakeSender({ fail: true })` → `{ kind: "fail", retry: true }`).
- [ ] **Step 2: RED** (`cd api && bun test test/report-text.test.ts test/weekly-report.test.ts`), then the code.
- [ ] **Step 3: GREEN** (`bun check --only=api`). A local run: `supabase db query --local "select public.admin_send_report('<the
  local admin's user id>', null)"` with the local API's worker up (`AI_FAKE=1`, no `RESEND_API_KEY`): the API's log shows `an alert
  email (fake sender)` with the report's text; the job's result `sent: true`. Commit, PR 6, merge. Ledger line.

---

### Task 8: Figures, Golden sets, Syllabus data, the call page's Feedback row (PR 7)

**Files:**
- Create: `admin/app/figures/page.tsx`, `loading.tsx`, `actions.ts` (`sendReport`), `admin/app/evals/page.tsx`, `loading.tsx`,
  `actions.ts` (`runEvals`), `admin/app/syllabi/page.tsx`, `loading.tsx`, `admin/content/figures.ts`, `admin/content/evals.ts`,
  `admin/content/syllabi.ts`, `admin/preview/{figures,evals,syllabi,syllabus,call-feedback}.json`, `admin/test/unit/{figures,evals,
  syllabi}.test.tsx`
- Modify: `admin/app/calls/[id]/page.tsx` (the Feedback row after Started by: "made again · <reason> · <when>" with "edited at
  Send · <when> · the text is never shown here" as its sub-line, "—" with no feedback; the title's button "Open the centre" for a
  tap's call, "Open the job" for a job's), `admin/content/calls.ts` (`FEEDBACK`), `admin/content/words.ts` (`PENDING.send:
  "Sending…"`, `PENDING.run: "Queuing the run…"`), `admin/components/parts.tsx` (`KindChips`: the filter chips as checkboxes in a
  form), `admin/lib/data/{types,real,preview}.ts` (`Data.figures(weeks)`, `reasons(monday)`, `evalRuns()`, `runEvals(admin, kinds,
  ip)`, `sendReport(admin, ip)`, `syllabi()`, `syllabus(id)`), `admin/test/unit/calls.test.tsx`, `admin/test/unit/loading.test.tsx`,
  `admin/test/unit/words.test.ts`, `tools/admin-shots.ts` (`DEFAULT_PAGES` gains `/figures`, `/evals`, `/syllabi?open=preview`,
  `/calls/preview-feedback`), `tools/contract.ts` (the eval kinds and the kind words for the portal: `admin/lib/generated/
  contract.ts`, never edited, `bun check` fails when stale)

**Interfaces:**
- Consumes: Task 6's functions.
- Produces: the three pages per P22-Figures, P22-Evals and P22-Syllabi; `/figures?weeks=8|12|26` (the Weeks pill); the report
  card's "Send this week so far, now" posts `sendReport` and answers `?sent=1` ("Sent to the alert address" in the card);
  `/evals`' run card posts `runEvals` with the chosen kinds (checkboxes drawn as the filter chips; "every kind" clears the choice)
  and answers `?queued=<job>` ("Queued: the result lands here when the batches end", a link to the job) or `?queued=busy` ("A run
  is already queued: see the Jobs page"); the button's words count the chosen kinds and the cost at ₹10 a kind; `/syllabi?open=<id>`
  opens one row in place.

- [ ] **Step 1: the failing tests.** `figures.test.tsx` (preview): "Product figures", a row "6 to 12 Oct", "Made again this week,
  by reason", "The weekly report", "Send this week so far, now"; `?sent=1` holds "Sent to the alert address". `evals.test.tsx`:
  "Golden sets", a row "plan" with "below the gate", "What failed on the last run", "Run golden sets now", the button "Run 4 kinds
  now · about ₹40"; `?queued=busy` holds "A run is already queued". `syllabi.test.tsx`: "Syllabus data", a row "CBSE · 8 ·
  Mathematics" open with "Rational Numbers". `calls.test.tsx`: `/calls/preview-feedback` holds "Feedback", "made again · Less about
  marks", "edited at Send", and not the revised text; `/calls/preview` (no feedback) holds "—" in the row.
- [ ] **Step 2: RED**, then the pages, the fixtures with the boards' figures, the actions, the contract's generated file.
- [ ] **Step 3: GREEN** (`bun check --only=admin,tools`); `bun admin-shots --pages /figures,/evals,/syllabi?open=preview,
  /calls/preview-feedback` (both widths, both appearances) beside the boards; `bun pr-shots`. Commit, PR 7, merge. Then
  `gh workflow run deploy-admin` only after Deploy B (Task 10: the functions must be in production first); until then the portal
  stays at PR 4's deploy. Ledger line.

---

### Task 9: Migration 0068 and the API: retention, the split per batch, a refused push tried again (PR 8)

**Files:**
- Create: `supabase/migrations/20261211000068_v3_retention_split_push.sql`, `supabase/tests/retention.test.ts`,
  `supabase/tests/push-retry.test.ts`
- Modify: `supabase/tests/exam-job.test.ts`, `supabase/types.ts`, then `bun contract`; `api/src/jobs/kinds/sweep.ts`,
  `api/src/jobs/sweep-db.ts` (`reduceInputs(before: string, limit: number): Promise<number>`), `api/test/sweep.test.ts`;
  `api/src/jobs/kinds/exam-prep.ts`, `api/src/jobs/exam-source.ts` (`writePreparation(centre, item, days, byBatch: Record<string,
  Record<string, unknown>[]>)`), `api/test/exam-prep-job.test.ts`; `api/src/push/send-due.ts`, `api/src/push/db.ts`
  (`OutboxDb.retry(id: string, dueAt: string): Promise<boolean>` through `retry_notification`), `api/test/send-due.test.ts` (the
  file that tests `sendDue`: `grep -l sendDue api/test/*.ts`); `admin/app/calls/[id]/page.tsx` (the reduced line), `admin/content/
  calls.ts` (`REDUCED: "Reduced after 90 days: only what came back is kept (D79)"`), `admin/lib/data/types.ts` (`Call.input_reduced`),
  `admin/preview/call-reduced.json`, `admin/test/unit/calls.test.tsx`, `tools/admin-shots.ts` (`/calls/preview-reduced`)

**Interfaces:**
- Produces:
  - `reduce_old_inputs(p_before timestamptz, p_limit int) returns int`: rows with `student_id` set, `status <> 'pending'`,
    `created_at < p_before`, `not (input ? 'reduced_at')`, the oldest first up to `p_limit`: `input` becomes `jsonb_build_object
    ('reduced_at', now(), 'kind', kind::text, 'student_id', student_id)`; returns the count. `service_role` alone.
  - `admin_call(p_id)` gains `input_reduced` (`input ? 'reduced_at'`); `input` is null when reduced (build on 0061's body; read
    every migration that defines `admin_call`).
  - `school_items.preparations jsonb check (preparations is null or jsonb_typeof(preparations) = 'object')`.
  - `notifications.attempts int not null default 0`; `retry_notification(p_id uuid, p_due_at timestamptz) returns boolean`: when
    `attempts < 3` sets `state 'due'`, `due_at p_due_at`, `attempts + 1`, `apns null` and answers true; else false. `service_role`.
  - The sweep's retention step: `reduced = await source.reduceInputs(new Date(now - 90 days).toISOString(), 500)` in its result.
  - The exam job's split: `byBatch` holds every batch the exam's students sit in (each batch's own days from `src/plan/exam-prep.ts`
    on that batch's meeting days); `preparation` stays the first batch's.
  - `sendDue`: a row whose answers hold a 429, a 5xx or no answer, and no delivery, is retried (`outbox.retry(id, now + 60 s)`);
    when `retry` answers false the row is marked failed as today; `no_token` and a retired token are never retried.

- [ ] **Step 1: the failing tests.** `retention.test.ts`: `an input older than 90 days becomes a reference; the output, the cost and
  a younger row stay` (two rows, one with `created_at` set back 91 days by SQL), `a replay of a reduced row answers its output`
  (`start_ai_call` with the row's key answers the row as a replay with its output), `a reduced row's page says reduced, not held`
  (`admin_call` → `input_reduced true`, `input null`, `input_held false` for a student with consent), `a member calls none of it`.
  `push-retry.test.ts`: `a push is set due again three times, then refused`. `exam-job.test.ts`: `preparations holds a split per
  batch`. `api/test/sweep.test.ts`: `the retention step reduces old inputs and names the count`. `api/test/exam-prep-job.test.ts`:
  `two batches get two splits, each on its own days; preparation stays the first batch's`. `api/test/send-due.test.ts`: `a push
  Apple refused is tried three times a minute apart, then failed` and `a bad token is retired, never retried`.
  `admin/test/unit/calls.test.tsx`: `/calls/preview-reduced` holds "Reduced after 90 days" and no Input block.
- [ ] **Step 2: RED**, then the migration and the code.
- [ ] **Step 3: GREEN** (`bun check --only=db,api,admin,tools`); `bun admin-shots --pages /calls/preview-reduced`; `bun pr-shots`.
  A local run: a personal row set back 91 days by SQL, the sweep queued by the runbook's SQL (`docs/runbooks/simulator.md` section
  12), its result `reduced: 1`, the row's input read back. Commit, PR 8, merge. Ledger line.

---

### Task 10: The app reads its student's batch's split (PR 9, iOS)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Domain/School/SchoolItem.swift` (`preparations: [UUID: [ExamPreparation.Day]]?`, decoded
  from `preparations`), `Sources/Domain/School/ExamPreparation.swift` (`static func days(of item: SchoolItem, forBatch batch:
  UUID?) -> [Day]?`: the batch's from `preparations`, else `preparation`), `Sources/Features/School/ItemStore+Preparation.swift`
  and `Sources/Features/Today/PlanPreview+Exam.swift` (read through it with the student's `class_id`), the School data decoder
  (`Sources/Data/School/…`, the column added to the select)
- Create: `Tests/SchoolTests/PreparationByBatchTests.swift`

**Interfaces:**
- Consumes: `school_items.preparations` (Task 9).
- Produces: nothing new on screen; the exam page shows the days of the batch the student sits in.

- [ ] **Step 1: the failing test** (`PreparationByBatchTests`): an item with `preparations` for two batches and `preparation` the
  first's: `days(of:forBatch: second)` answers the second's days; `forBatch: nil` and an item without `preparations` answer
  `preparation`.
- [ ] **Step 2: RED** (`bun check --only=ios` or the targeted `xcodebuild test` with `-collect-test-diagnostics never`), then the
  code.
- [ ] **Step 3: GREEN** (`bun check --only=format,lint,ios`). Then **Deploy B** (`gh workflow run deploy`: 0067, 0068, the weekly
  report, retention, the split, the push retry) and `gh workflow run deploy-admin` (PRs 7 and 8's pages). Read back: `cron.job`
  holds `schedule_weekly_report` at `30 2 * * 1`; `select count(*) from public.alert_lines`. Commit, PR 9, merge. Ledger lines.

---

### Task 11: The trust page's retention words (PR 10, web)

**Files:**
- Modify: `web/content/trust.ts` (after the AI service's paragraph: "What was sent about a student for a message, a reading of
  marks or the plan for the last days is kept beside what came back for 90 days, so the tutor can see what a note was written
  from. After 90 days only what came back is kept, with a mark that something was sent and when."; the staff sentence: "The tutor,
  signed in, sees the centre’s records; one tutor can never read another’s. Tutor Central’s own staff can open a centre’s records
  only to help with a problem, with the reason and the time written down. They never see a parent’s number, a photo, or what was
  sent about a student whose parent has not agreed. Nothing is sold and nothing is shared, except with the services that run the
  app and the AI service as described above."), `web/content/site.ts` (`TRUST_UPDATED` the deploy's day), `web/test/unit/trust.test.ts`
  (the two sentences present; no technical word: `words.test.ts` runs on it)

- [ ] **Step 1: the failing test**, **Step 2: RED**, then the words. **Step 3: GREEN** (`bun check --only=web`); `bun web-shots
  --pages /trust` (1280 and 390, both) beside P22-Web-Trust; `bun pr-shots`. Commit, PR 10, merge. `gh workflow run deploy-web`
  (its smoke on the five pages). Ledger line with the run number.

---

### Task 12: The hand runs (PR 11 for what they find)

By `docs/runbooks/admin.md` (the portal in the built-in browser against the local stack: a settled page before every click,
every write confirmed in the database) and `docs/runbooks/simulator.md` (the app on the local stack, `AI_FAKE=1`, the local
worker up: **no database test while it runs**). Each run's pictures on a GitHub issue "Phase 22 hand run"; each fault its own
failing test first (D68). The runbook gains a section for the controls (what to click, what to read back).

1. **Switch off, then on (the acceptance).** `/models/brief` → Switch off → the reason → Switch off: the dialog closes, the
   title's chip reads off; `ai_models` has the disabled draft row with the reason; the audit `set_model`. On the simulator
   (Make → Brief): the system alert in the kind's words within 60 s (watch the clock from Save: the API's refresh is each
   minute). Switch on: the next brief is made (the fake). The audit shows both rows.
2. **Change a step.** `/models/sheet_to_5` → Change a step: Model Sonnet 5.5, Effort high, a note → Save: the Current table and
   History show it; `ai_models_current()` says so; a mistyped model (typed into the select's option by the browser's inspector) is
   refused under the field.
3. **The allowance.** The centre page → Change → Calls 1, Cap 0, a reason → Save: the line reads "allowance 1 calls"; the audit
   row holds the old values; on the simulator a second Make this month is refused in the app's words ("You've made this month's
   1. More next month."); Change back to 600.
4. **The lines.** `/alerts` → cost_day 1 (one rupee) → Save: the next alerts job (within ten minutes, or queued by the runbook's
   SQL) raises `cost_day` for the centre with calls today; the email in the API's log (the fake sender); the push row; Save back to
   60.
5. **The figures.** `/figures`: the week's row agrees with counts read by SQL (closes, plans, notes, made, again, make, consent,
   cost); Send this week so far, now: the card says sent; the job's result; the email's text in the log.
6. **The golden sets.** `/evals` on the local stack: the last run's rows from the local `eval_run` jobs (queue one on the fake
   first: `select public.schedule_evals()` locally, the worker runs it on the fake); the run card: two kinds → Run: "Queued" with
   the job's link; a second press: "A run is already queued".
7. **Syllabus data.** `/syllabi` → a row's Open: the chapters, the skills, the marks; the filters.
8. **The call page.** A note made again on the simulator with a reason → `/calls/<id>`: the Feedback row; a row set back 91 days by
   SQL and the sweep run: the reduced line, no Input.
9. **The split per batch.** Two batches with class 8 students, one exam from the school's message: the `exam_prep` job's split
   writes `preparations` with two keys; each batch's student page shows its own days; Today's plan preview for each batch follows
   its own.
10. **A refused push.** The local pusher made to answer 503 once (the fake pusher's `failNext`): the row is due again a minute
    later and sent on the next tick; `attempts` 1.
11. **Pictures of every page at phone width in the built-in browser** (`resize_window` 390): nothing scrolls sideways.

---

### Task 13: Build 32 and production

- [ ] `gh workflow run testflight` after Deploys A and B and PR 9: build 32 (the split per batch; nothing new on screen). Ledger
  line with the run number.
- [ ] Production's steps (D87, the session): `update public.centres set internal = true where id = '<SMOKE_CENTRE_ID>'` (the id by
  `gh variable get SMOKE_CENTRE_ID` into the command); then the acceptance in production, free: `admin_set_model` for
  `scan_register`'s draft with `enabled false` through the portal by the owner (step 1 below) or by SQL with the owner's admin id;
  a `POST /ai/scan-register` from the simulator signed in as the Smoke account answers 503 `paused` within a minute (the refusal
  pays nothing; the smoke account's token as `tools/smoke.ts` gets it); switched on again, a scan on the fake is not possible in
  production, so the proof of "works again" is `ai_models_current()` and the next morning's plan job made (the ledger reads it).
  One `weekly_report` queued by SQL (`select public.enqueue_job(null, 'weekly_report', 'report:proof', '{"week_monday":
  "2026-10-13","so_far":true}')` as the platform): the email reaches `ALERT_EMAIL`; the job's result.
- [ ] **The owner's steps**, one at a time, each confirmed before the next:
  1. Open https://admin.tutorcentral.in/models in Safari, sign in with your admin email and password, then the code from your
     authenticator. The page "AI models" shows 22 kinds, every one on. Tell me "models fine".
  2. Open brief → Switch off → type the reason "trying the switch" → Switch off. The chip by the title reads off. On your iPhone,
     More → Make something → Brief → fill it → Make the brief: the alert "Briefs can't be made right now. Making briefs is switched
     off for a short while so we can fix something. Everything else works as usual. Try again later." Tap OK. Tell me "off fine".
  3. Back in the portal, Switch on. On the iPhone, Make the brief again: it is made. Open https://admin.tutorcentral.in/audit:
     two rows set_model with your email and the reason. Tell me "on fine".
  4. Open https://admin.tutorcentral.in/figures: the week's row and the report card. Press "Send this week so far, now": within a
     minute the email "Tutor Central, the week of … so far" is in your inbox (the alert address). Tell me "report fine".
  5. Install build 32 from TestFlight; if an exam is in its window, open its page: the days are your batch's. Tell me "build 32
     fine", or what you saw.

---

### Task 14: The round's documents read against V3 (PR 12, documents)

**Files:**
- Modify: `docs/release.md` (the checklist for build 32: every box with its proof: `main` green, no migration pending with the
  deploy run numbers, `/health` at the commit, `bun check --fresh`, the hand runs of Phases 17 to 22 by issue, build 32's run;
  the release notes "1.0 (build 32), the first V3 build for the Tutors group": the plan made overnight and ready before the first
  batch, the notes made on the note day, the exam prepared over its days, reminders and "plan ready" on the iPhone, a student's
  export, the weekly note in the parent's language; "In the first week, try" gains: allow notifications when asked and see the
  morning's "Today's plan is ready"; on a student's page share the record as a file), `docs/testing/tester-guide.md` ("Getting
  started" step 4 gains "When the app asks, allow notifications: the plan for each day is made overnight and the app tells you it
  is ready"; "In the first week, try" gains item 10: a student's page → the export → share the file to yourself; "Good to know"
  gains "What the app sent about a student for a note or a marked paper is kept for 90 days beside what came back, then only what
  came back"), `docs/testing/device-tests.md` (section "Phase 22" with T21: a student's page → Export → Share → Files or WhatsApp
  on a real iPhone: the file opens and holds the record, the messages and the outputs; the existing T16 and T17 are the push and
  the plan that arrives: say so under the section head)
- [ ] Read each document through against V3 (D70 to D118) and change every sentence that is no longer true (no technical word: the
  website's `words.test.ts` does not run on these, so read them for "server", "sync", "job", "model"). Commit to `main` directly
  (D12, documents only) after Deploy B has its check.

---

### Task 15: The review, the rule files, the documents (`main`)

- [ ] Two fresh reviewers on Fable 5.1 over the phase's diff (`git diff <main before PR 1>..main`), each finding fixed with a test
  first or ruled in the ledger with its cost if wrong (D68); the fixes as PRs; the deploys and the portal again if the API or the
  database changed.
- [ ] The rule files: `admin/CLAUDE.md` (the controls' functions, the eleven pages, the run card and D112, the generated contract
  file), `api/CLAUDE.md` (the lines from the table, the model refresh's refusal, the `weekly_report` job, the retention step, the
  split per batch, the push retry), `supabase/CLAUDE.md` (0066 to 0068, `alert_lines`, `centres.internal`, the writers), `web/CLAUDE.md`
  (the trust page's retention words), `ios/CLAUDE.md` (`preparations`), `CLAUDE.md` (the admin runbook's controls section).
- [ ] `docs/design/information-architecture.md` ("Phase 22 boards": what the build settled), `plan/README.md` (D113 to D118 as
  approved, the phase's status), `plan/phase-22-admin-portal-control.md` ("As built"), `plan/STATE.md`, `plan/sessions/045/record.md`
  and `owner-messages.md`, `plan/ui-polish.md` (anything seen). One documents commit to `main` after the last deploy's check.

## The cost

No real-call budget is asked: no prompt, agent, schema or `models.json` changes, so `bun evals-changed` names nothing; the hand
runs are on the fake; the production acceptance is a refusal that pays nothing and a plan job that runs anyway. If a run is
queued from the portal's new card to prove it in production, it is the owner's press (about ₹10 a kind, D112 allows it) and goes in
the ledger. The ledger keeps the count without troubling him.

## Self-review (done 2026-10-15)

1. **Spec coverage.** Scope 1 controls: Tasks 2 to 5 (models with history and the switch, the allowance, the lines, the syllabi
   in 6 and 8). Scope 2 support within consent: built in Phase 19; the reduced input (Task 9) and the staff sentence (Task 11)
   complete D79's words. Scope 3 analytics: Tasks 6 to 8 (every figure of D82, the page, the email). Scope 4 retention: Tasks 9
   and 11. Scope 5 the round's documents: Task 14. The acceptance: the switch within a minute (Tasks 3, 12 run 1, 13), the
   allowance (Task 2's test, run 3), the weekly email (Tasks 7, 13), an open without a reason refused (Phase 19, unchanged), the
   reduced input and the trust page with its smoke (Tasks 9, 11), the pictures (Tasks 5, 8, 9, 11). Phase 21's list: R-api-4
   (Tasks 9, 10), the Feedback row (Task 8), the Smoke centre (Tasks 2, 6, 13), the push retry (Task 9), U53 ruled the owner's.
2. **Placeholders.** None: every function has its signature and shape; the words are the boards'; the message kinds' names are
   read from the enum by the implementer, named in the function.
3. **Types.** `Lines` (Task 3) matches `alert_lines_current()` (Task 2); `ModelChange` (Task 4) matches `admin_set_model`'s
   arguments; `Figures` (Tasks 6, 7, 8) is `admin_figures`' row; `input_reduced` (Task 9) is read by the call page (Task 9);
   `preparations` (Task 9) is decoded by Task 10.
4. **Review focus.** Each of the seven lines names its test in Tasks 2, 3, 6, 9 and 10.
