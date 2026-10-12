# Phase 18 plan: V3 the server's work and push

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-12 (session 36, Fable 5.1) from `phase-18-server-work-and-push.md`, `docs/spec-v3.md` (sections 3, 5, 6, 7,
8), Phase 17's "As built" and ledger (`plan/sessions/035/`), the 14 approved boards of row 26 (`docs/design/mockups/P18-*`,
"Phase 18 boards" in `docs/design/information-architecture.md`) and the code as it is. Shown whole to the owner for approval.
The build runs on Opus 5.5 from `resume/035-phase-18-build.md`, inline, task by task, with one ledger
(`plan/sessions/037/ledger.md`) as sessions 22 to 35 kept.

**Goal:** the work the phone did for the platform runs on the server as jobs, and the platform reaches the phone through
APNs. A batch's plan and its material are made before the batch by a job and announced by a push; the note day's notes are
written by a job and wait in the app; reminders are planned and sent by the server, so they arrive on a phone that has not
opened the app; a sheet's, mock's and brief's PDF is made on the server; a student's export is a PDF made by a job; a
parent's withdrawal of consent is an event shown on the student's page and stops the personal kinds at once; a deleted
student's photos leave Storage. The stores show their copy at once (one data layer, U10, U27).

**Architecture:** Phase 17's jobs carry the work (D71). pg_cron writes the day's jobs (plans, note days, an hourly
reminder plan) and triggers write the jobs a change needs (a reminder plan after a class, event, fee or setting changes; a
PDF after a printable artefact is kept); a schedule runs no work itself. The `plan` job gains its material as steps (the
budget, the spaced queue and the exam split ported to TypeScript and held equal to Domain's by shared case files written
from the Swift rules before those are retired), handles exam weeks and holidays, and ends by queueing two notifications
(an alert and a background push). The `note_day` job writes each consented student's note through the same keep the phone
used. The `reminder_sweep` job plans the next 26 hours of reminders from the rules ported from `ReminderPlanner` and the
tutor's settings (now a table) into a `notifications` outbox; the worker's minute tick sends what is due through APNs
(`@parse/node-apn`, pinned), retiring a token Apple answers 410. The `pdf` and `export` jobs render with Typst (the
renderer D75 chose, brought forward) and write to two private buckets; the `sweep` gains Storage's clean-up. The app
registers its device token, reads its settings from the server, reads a plan's job and plan instead of making one, asks
for work through three member functions limited to their kind and the centre's own rows, and shows withdrawal, the export
and plan-ready to the boards. `PlanMaker`, `BackgroundRefresh`, `ReminderScheduler` and the share path of `PDFMaker` for
sheets, mocks and briefs are retired.

**Tech stack:** as Phase 17 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI 2.120.0, Postgres 17, pg_cron,
pg_net, Vault; Bun 1.3.11; Hono 4.13.13, zod 4.6.5, `@anthropic-ai/sdk` 0.132.1, `@supabase/supabase-js` 2.117.2) plus two
API dependencies, each pinned with a decision (D14): `@parse/node-apn` 8.1.0 (D88) and
`@myriaddreamin/typst-ts-node-compiler` 0.7.0 (D89), with Noto Sans, Noto Sans Devanagari and Noto Sans Kannada (OFL)
committed under `api/fonts/`. No new iOS dependency. Vercel Hobby and Supabase Free stay (D85).

**Spec:** `docs/spec-v3.md` sections 3 (jobs, schedules), 5 (what leaves the phone), 6 (notifications), 7 (robustness:
offline, one data layer), 8 (DPDP: consent as a history, the export, delete per student); the scope
`plan/phase-18-server-work-and-push.md` (items 1 to 6, the acceptance); D70 to D72, D76, D79, D83 to D87; the boards of
row 26.

## Global constraints

- A screen changes only to an approved board (rule 1): the 14 boards of row 26 and the words "Phase 18 boards" settles
  (the no-batch hero, the failed plan card). A pull request that would change any other state stops and asks.
  `ErrorWordsTests` still bans technical words (D41); every new sentence on screen is from the boards or
  `docs/design/feedback.md`.
- Migrations are additive (D26): build 27 keeps working against every migration and API of this phase (its calls,
  `make_plan`, `keep_artefact`, `start_ai_call`, the consent columns, its local reminders and background refresh). The
  TestFlight lane refuses a build while a migration is pending.
- Every new table: `id`, `created_at`, `updated_at` with `set_updated_at`, RLS on, a policy, a line in `rls.test.ts`'s
  catalogue, grants revoked to what the app may do (Supabase's default privileges grant `authenticated` everything on a
  new table). `centre_id` on every centre table; `reminder_settings` and `notifications` also carry `user_id` (per tutor,
  like `device_tokens`). `storage_deletions` is the platform's (no member policy; decision 21).
- Functions: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, an explicit grant. No new
  `security definer` function: the four stay four (D37, D83). The member requests write `jobs` through Phase 17's `tc.jobs`
  setting, as `enqueue_job` does.
- No secret in the repository or the app (D11): the APNs `.p8`, its key id and the team id live in Vercel's Production
  environment and `api/.env.local`; the session pipes the file straight to the store, never printing it (D87).
- No tutor's or student's name, email or number in the repository (D55) or in a push payload (D72): a payload carries the
  tutor's batch label, a time, a count, a link and an opaque id.
- Bun only (D16); dependencies pinned (D14), the two new ones by D88 and D89; `bun check` before every commit; one change per
  pull request; merge on local green (D86); documents to `main` directly (D12).
- Real AI calls in testing are allowed without asking; this phase's are named in "The cost" with their figures.
- D68: what this phase finds, it fixes before it closes.

## Decisions this plan takes

Small and medium decisions, written here so they are not re-decided. Five become numbered decisions in `plan/README.md`
with the approval commit (D88 to D92).

1. **`@parse/node-apn` 8.1.0 sends to APNs (D88).** Published 2026-04-12, maintained by the Parse community, HTTP/2 with a
   token-based `.p8` provider, Node 20 to 24; its four dependencies (`debug`, `jsonwebtoken`, `node-forge`, `verror`) come
   pinned by its lockfile entry. Weighed: our own HTTP/2 client with Node's `http2` and the ES256 signer `apple.ts` already
   has (about 120 lines, no dependency): rejected because the spec and resume name the library, and connection reuse, retry
   on GOAWAY and the error codes are its tested work. One provider per APNs environment (`sandbox` for Debug builds and the
   simulator, `production` for TestFlight and the App Store), opened per worker run and shut at the run's end.
2. **Typst renders the server's PDFs from this phase (D89).** `@myriaddreamin/typst-ts-node-compiler` 0.7.0 (published
   2026-05-31; a native module with prebuilt `linux-x64-gnu` and `darwin-arm64` packages; the deploy builds on the Ubuntu
   runner, so Vercel gets the Linux one), with the fonts committed under `api/fonts/` (Noto Sans regular and bold, Noto Sans
   Devanagari, Noto Sans Kannada; OFL, the licence beside them). D75 chose Typst for Phase 20's maths; the export needs a
   renderer now and shapes Hindi and Kannada (a parent's messages), which `pdf-lib` and the like cannot. Phase 20 adds
   `mitex` to the same compiler. The deploy checks that the native module and the fonts are in the function's output, and
   the smoke renders one page (decision 26).
3. **What the server's PDF covers (D90).** Sheets (a set or homework), mocks and briefs: the printable artefacts the phone
   shares today with `ShareLink` (the scope's "a sheet or mock", the brief beside them since it is text alone). Figures stay
   drawn on the phone (their spec is drawn by `Artefacts/Figures`; drawing them in Typst is Phase 20's, with the maths), and
   so do V1's results (paper, homework, worksheet, progress note: Phase 21 moves V1's kinds). Printing keeps the phone's path
   (spec section 5). Share takes the server's file, downloaded once and kept with the artefact's copy; when the file is not on
   the iPhone and the iPhone is offline, Share draws it on the phone as today (no tutor loses an offline share they have now;
   `PDFMaker` stays for Print anyway).
4. **Automatic AI work only for a centre in use (D91).** pg_cron writes a centre's plan and note-day jobs only when its
   tutor opened the app in the last 14 days (an `events` row of kind `app_opened`, Phase 17's activity log). The phone made
   material only when opened; the server would otherwise pay every morning for a tutor who stopped. A tutor back after 14
   days gets the day's plan from Today's ask (decision 9) within a minute.
5. **The export is a PDF kept seven days (D92).** For the parent (the DPDP Act's right to a summary of what is kept): the
   board's sections, each message sent (the message log keeps its day and kind, not its words) and every note and message
   the AI service wrote about the student with its words (from `artefacts` and `ai_generations.output`), in English with
   those words in their language. In the private bucket `exports` at
   `<centre>/<student>/<job>.pdf`; the sweep removes it after seven days. No photo goes in it (none is kept beyond the
   marks', which are the tutor's evidence, not the parent's data; a marks photo is named in the file as "kept").
6. **Reminder settings go with the account.** `reminder_settings` (per tutor and centre) replaces the iPhone's
   `UserDefaults` record; the new build writes the old values once on its first launch (`ReminderSettingsMigration`), then
   removes the local key and every pending local reminder. Defaults as today (class 60 minutes before, events an hour before,
   fees on the 5th at 09:00) plus Plan ready and Notes ready on. The Reminders screen follows P18-Reminders.
7. **The notifications outbox.** `notifications` holds every push to be sent: the user, the kind (`class`, `event`, `fees`,
   `plan_ready`, `notes_ready`, `plan_fetch`), a key unique per user (`<kind>:<subject>:<when>`), `due_at`, the title, body
   and link (or none for the background `plan_fetch`), the state (`due`, `sent`, `failed`, `expired`, `cancelled`) and what
   Apple answered. The reminder plan replaces a user's future unsent rows of its kinds in one transaction; the tick sends rows
   due in the last 30 minutes (older ones expire unsent: a reminder for a class already begun helps no one).
8. **When the jobs run.** `schedule_plans()` each 15 minutes: every active batch of a centre in use (decision 4) meeting
   today in India, with no plan and no plan job for the day, gets `plan:<class>:<date>` at 05:30 IST, or two hours before a
   batch starting before 07:30, never before 03:30; a batch made later in the day is planned at once. 05:30 keeps the job
   ahead of build 27's background refresh (asked for 06:00), so the two do not race on the installed build.
   `schedule_note_days()` each 15 minutes: every batch whose note day is today gets `note_day:<class>:<date>` two hours
   before its note time (Sunday 18:00 when unset). `schedule_reminders()` hourly: `reminders:<centre>:<hour>` for every
   centre with a live device token; triggers on `classes`, `calendar_events`, `fee_invoices` and `reminder_settings` queue
   `reminders:<centre>:<minute>` so a change reaches the outbox within a minute.
9. **What a member may queue.** Three functions, granted to `authenticated`, each limited to its kind and the centre's own
   rows, each answering the live job for the same subject when one exists (a second tap starts nothing): `request_plan(
   p_centre, p_class, p_date, p_choices)` (Today's Try Again, the Change sheet's Make the plan again with the choices, a
   school item's change; `p_choices` set means replace an open plan, never a closed one), `request_note(p_centre, p_student,
   p_week)` (a note the job did not write: a student whose consent came after the job), `request_export(p_centre,
   p_student)`. Each writes its row with `tc.jobs` set, so the 0028 trigger lets it in; `enqueue_job` stays the platform's.
   `cancel_job` (granted since 0028) cancels a plan job from Today's planning card.
10. **The plan job's material.** After `write`, a step `budget` computes the requests with the ported `ArtefactBudget`
    (the spaced queue, the exam split and the shared mock included), stored in `jobs.step`; then one step per request
    (`make:<n>`), each a recorded call (`<job>:make:<n>`) through `makeRequest` (the route's builders, decision 12) and a
    keep through `keep_artefact` with the key `<job>:make:<n>`, linked to its lines as the phone's `PlanMaker.makeAll` did;
    a failed call leaves its mark "not made" and the job goes on; then `notify` (decision 7). A mock is made once per exam:
    its call and keep use the key `mock:<school item>`, so two batches' jobs share one (the phone's `MockRuns`). The job
    never replaces a plan unless its input says `replace` (decision 9), and never a closed one.
11. **Exam weeks and holidays are the job's.** The `exam_mode` early return goes: the job feeds `revisions`, `hints` and
    `holidays` to the rules as `PlanMaker.input` does (the split from `ExamPreparation.days`, ported), so the seed's Science
    unit test week is planned on the server. Holidays that cover the whole batch end the job `done {reason: "holiday"}` (the
    phone's `.holiday`).
12. **One builder of a made kind.** `api/src/make.ts` exports `makeRequest(input: MakeInput)` (the `switch` that
    `routes/v2.ts` holds today, with each kind's `empty` check and its student) so the route and the jobs build the same
    call; `recordedCall` gains `student` (the gate's consent) and `empty`.
13. **The note day job.** Input `{class_id, date}` or `{student_id, week}` (a request). It reads the week of each student
    with a parent's number (the ported `NoteRecordReader` and `NoteDayStore+Week` rules, held equal by shared cases), makes
    each student's `note` or `can_do` as the phone does on Read (a recorded call with the student, so a student without
    consent is refused by the gate and recorded "held", never paid), keeps it with `keep_artefact` key `note:<student>:<week>`,
    then queues one `notes_ready` per tutor. The phone's Read opens the kept note; a missing one is asked with
    `request_note` and shows the note screen's making state (P10-Note's), never a call from the phone. Write again stays a
    tap call (its own fresh key, Phase 17).
14. **What stays a call from the phone.** The kinds made at a tap that names them: a Make form, Make it again and Write
    again, Check a paper, the photo readers (scan, textbook, school, marks), a test tomorrow or not-on-track message the
    tutor opened, the gap report and a placement the tutor opened, the close's checks for a student the plan did not cover.
    What goes: the plan and its material made on open, in the background refresh and on a school item's change, and a note
    made on opening it. The gap report and the mock move with Phase 21's exam orchestrator.
15. **Withdrawal (P18 boards).** `withdraw_consent(p_centre, p_student, p_how, p_on)` records `withdrawn` with how and the
    day (today or earlier, not before the last agreement) and clears the three columns in one transaction; 0032's trigger
    skips its own `withdrawn` while `tc.withdrawn` is on, so the event is written once. It cancels the student's queued or
    waiting `note_day` request jobs. A note kept and not sent stays and shows Held (the page's existing reason). The record
    sheet's Remove is replaced by Parent withdrew (the boards); `ConsentStore.remove()` goes.
16. **The history on the page.** `consent_events` read per student, newest first; shown under the consent row whenever
    there is more than the first agreement (the boards' rule), on every consent state.
17. **Push in the app.** The app asks for remote notifications after the user allows notifications (the same prompt as
    today's reminders), sends its token to `device_tokens` with `environment` (`sandbox` in Debug, `production` in Release,
    from a build setting), the device id (`identifierForVendor`) and the build; sign-out and deletion remove the row before
    the wipe (D40). `aps-environment` joins the entitlements; `remote-notification` replaces `fetch` in `UIBackgroundModes`
    and the background task's identifier leaves `Info.plist`. A tap opens the payload's `link` (as today's local reminders);
    a `plan_fetch` push reads today's plans into `PlanCache` within the 30 seconds iOS allows.
18. **PlanStore reads.** `PlanStore` reads the plan row and the day's plan job: no plan and a live job is `.planning(nil)`
    (P10-Today-Planning, its Cancel calls `cancel_job`); a plan and a live job is `.planning(plan)` with marks on their way
    and the line "Made at <time>, before the batch…" (P18-Today-Plan-Making); a plan and no live job is `.made`; no plan and a
    failed job is `.failed("Couldn't make today's plan. Try again in a minute.")` with Try Again (`request_plan`); no plan and
    no job before the batch is `.planning(nil)` after asking (`request_plan`), as a batch added today. Offline keeps the copy.
    The read is polled every 10 seconds while a job is live and the app is in front (no realtime subscription: one fewer
    moving part; a push ends the wait sooner).
19. **The data layer (D76, U10, U27).** `CopyFirst<Value>` (Data) is the one path: show the saved copy at once with its
    time, then read; a good read replaces it and is kept; a failed read keeps what is shown and says so in place (U33), or
    the unavailable view when nothing is saved. Every list store that reads through `CachedRead` moves onto it (twelve, named
    in Task 22); `AttendanceStore` is the one that today shows its copy only after a failure (U27) and shows nothing while a
    slow read runs (U10). Phase 17's hand run 3 found the screen showing everyone present after a queued replay until a cold
    launch: the replay's end now reloads the open day through the same path (D68: found while this layer is built).
20. **Storage.** Two private buckets made by migration: `exports` (`application/pdf`, 10 MB) and `pdfs` (`application/pdf`,
    5 MB), paths beginning with the centre's id; members read their centre's objects (the `photo_centre` rule), only the
    platform writes. `storage_deletions` (bucket, path or prefix, why) is filled by triggers: a row with a `photo_path`
    deleted (`artefacts`, `school_items`, `marks`, `textbooks`), an artefact deleted (its PDF), a student deleted (their
    exports' prefix), a centre deleted (the centre's prefix in all three buckets); the sweep's `storage` step removes them
    through the Storage API as the platform and deletes the row. The app's `photos.removeAll` before an account's deletion
    stays (it frees the files before the cascade; the sweep is the guarantee).
21. **The platform's tables.** `notifications` (members read their own rows, for the hand runs and the portal later; no
    member write), `storage_deletions` (no member policy at all, like `alerts`), `reminder_settings` (the tutor's own row:
    select, insert, update).
22. **Ports and their cases.** As Phase 17's plan cases: a Swift test writes each case file from Domain's rules
    (`TC_WRITE_BUDGET_CASES`, `TC_WRITE_REMINDER_CASES`, `TC_WRITE_NOTE_CASES`), `bun contract` copies it, and the TypeScript
    port must answer every case alike. The cases are written before the Swift rules they come from are retired; after
    retirement the files stay as the TypeScript's fixtures and the Swift side of each case test goes with its rules.
23. **What is retired, and when.** In the pull request that moves the work: `PlanMaker`, `PlanMaker+Calls`, `+Exam`,
    `+FirstChecks` and `RefreshHandler` (PR 17); `BackgroundRefresh` (PR 16); `ReminderScheduler`, `ReminderPlanner`,
    `UNClient`'s scheduling and the local settings store (PR 16); the share path of `PDFMaker` for sheets, mocks and briefs
    (PR 20). Domain's `PlanRules`, `ArtefactBudget`, `SpacedQueue` and the plan cases' Swift test go when nothing on the phone
    uses them (the compiler decides; `ExamPreparation` stays for the School tab). No dead code (the engineering standard).
24. **Branches and the ledger.** `phase-18/<slug>` in the main checkout, one per pull request; the ledger is
    `plan/sessions/037/ledger.md`, written by hand after each named test run, each ruling with its cost if wrong.
25. **Order of deploys.** Deploy 1 after PR 15 (0036 to 0040 and the API: the jobs, the schedules, push and the PDFs live;
    build 27 untouched: it registers no token, so no push reaches it, and its own plans meet the job's at 05:30). Deploy 2
    after the review's fixes; then build 28.
26. **The deploy proves the new parts.** `deploy.yml`'s "The function's time" step also checks the built function holds the
    Typst module for `linux-x64-gnu` and `fonts/*.ttf`; the smoke gets `GET /jobs/health` with `WORKER_SECRET`'s bearer,
    which renders a one-page PDF with a Devanagari line and opens (then shuts) an APNs provider for production, answering
    `{ pdf: <pages>, apns: true }`.
27. **The sweep's retention.** Besides Storage: `notifications` older than 30 days, `jobs` of kinds `reminder_sweep` and
    `sweep` done more than 7 days ago (with their steps), exports older than 7 days.
28. **The trust page changes with what is kept** (web rule): the export (a PDF, kept seven days), withdrawal recorded with
    how and the day, push carrying no student's name, photos removed with the student. Its words are the page's own (Phase 8's
    rule: the board settles the layout); `/trust`'s "Last changed" moves.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that owns
the code.

1. **A push to a token Apple retired.** A tutor reinstalls; the old token answers 410 (or 400 `BadDeviceToken`): the row is
   retired, the send is recorded failed for that token only, the new token gets it, and no retry loops. Tests: Task 10
   (`apns: a 410 retires the token and the other token still receives`, `a BadDeviceToken retires it too`).
2. **A reminder whose class moved after it was planned.** The tutor changes the batch's time at 16:00; the 16:45 reminder
   for 17:00 must not fire, the new one must. The change's trigger queues a plan; the plan replaces the future unsent rows
   in one transaction. Tests: Task 5 (`a class update queues a reminder plan for its centre within the minute`), Task 11
   (`a replan cancels the unsent row of a moved class and writes its new one`).
3. **Two batches with the same exam's mock planned at once.** Two plan jobs on the mock day, claimed by two runs: one call,
   one artefact, both plans linked. Test: Task 12 (`two plan jobs on the mock day share one mock call and one artefact`).
4. **A withdrawal while the note day job runs.** The job's next step for that student is refused by the gate (recorded
   `held`, no charge); a note already kept shows Held; the request job queued for the student is cancelled. Tests: Task 2
   (`withdraw_consent cancels the student's queued note request`), Task 13 (`a student withdrawn mid-job is held, not
   paid`).
5. **A plan job retaken after a lost lease in the middle of its material.** Step `make:3`'s call finished but its keep did
   not: the retaken step replays the call (key) and keeps once (key). Test: Task 12 (`a material step retaken after its
   call keeps once and pays once`).
6. **The export of a student with Hindi messages.** The Devanagari text shapes (no boxes, no broken conjuncts); a long
   history runs to further pages with the foot's "Page n of m". Tests: Task 15 (`the export renders a Hindi message and
   pages`), the hand run's picture of page 3.
7. **Build 27 beside the new server.** No token, no push; its background refresh at 06:00 finds the job's plan of 05:30
   and only fills what is missing (none); its `Remove` still writes a `withdrawn` event through 0032's trigger. Tests: Task 2
   (`a clear of the columns still records a withdrawal`), Task 5 (`no plan job is written for a centre idle 14 days`), hand
   run 10.
8. **The background push while the app is suspended.** iOS gives 30 seconds: the read fills `PlanCache` or gives up and
   reports `.failed` to iOS; nothing else runs. Test: Task 18 (`the plan fetch reads today's plans into the copy and calls
   back once`).

## File structure

Created or changed, by part. A file has one job.

**Database (`supabase/`)**
- `migrations/20261110000036_v3_consent_withdrawal.sql`: `withdraw_consent`, the history trigger's skip.
- `migrations/20261111000037_v3_member_requests.sql`: `request_plan`, `request_note`, `request_export`.
- `migrations/20261112000038_v3_notifications.sql`: `reminder_settings`, `notifications`, `replace_notifications`,
  `due_notifications`, `mark_notification`.
- `migrations/20261113000039_v3_schedules.sql`: `centre_in_use`, `schedule_plans`, `schedule_note_days`,
  `schedule_reminders`, the change triggers, the three cron entries.
- `migrations/20261114000040_v3_storage_files.sql`: the `exports` and `pdfs` buckets and their policies,
  `storage_deletions` and its triggers, the printable artefact's `pdf` job trigger, `taken_storage_deletions`.
- `tests/consent.test.ts` (new), `tests/requests.test.ts` (new), `tests/notifications.test.ts` (new),
  `tests/schedules.test.ts` (new), `tests/storage.test.ts` (new), `tests/rls.test.ts` (the catalogue), `types.ts`.

**API (`api/`)**
- `src/make.ts` (the builder per made kind), `src/routes/v2.ts` (uses it), `src/jobs/call.ts` (`student`, `empty`).
- `src/plan/budget.ts`, `src/plan/spaced.ts`, `src/plan/exam-prep.ts`, `src/plan/material.ts` (a request to its
  `MakeInput` and its lines), `src/jobs/kinds/plan.ts` (material, exam weeks, replace, notify), `src/jobs/record.ts`
  (the reads the budget needs, `keep`, `link`, `mockFor`).
- `src/notes/week.ts` (the week's facts), `src/notes/record.ts` (the note's reads), `src/jobs/kinds/note-day.ts`.
- `src/reminders/planner.ts`, `src/reminders/settings.ts`, `src/jobs/kinds/reminder-sweep.ts`.
- `src/push/apns.ts` (providers, send, the answer), `src/push/apns-fake.ts`, `src/push/payload.ts`, `src/push/send-due.ts`,
  `src/push/db.ts` (the outbox and tokens through named functions and the service client).
- `src/pdf/render.ts` (the compiler, fonts, page count), `src/pdf/typst.ts` (escaping, shared markup), `src/pdf/sheet.ts`,
  `src/pdf/mock.ts`, `src/pdf/brief.ts`, `src/pdf/export.ts`, `src/jobs/kinds/pdf.ts`, `src/jobs/kinds/export.ts`,
  `src/export/record.ts` (the student's whole record).
- `src/jobs/kinds/sweep.ts` (storage, retention), `src/jobs/kinds/index.ts`, `src/routes/jobs.ts` (send-due in the tick,
  `/jobs/health`), `src/index.ts` (the APNs and Storage dependencies), `vercel.json` (`includeFiles`), `fonts/` (four TTFs,
  `OFL.txt`), `package.json` (the two dependencies), `.env.example`.
- Tests: `test/make.test.ts`, `test/budget-cases.test.ts`, `test/reminder-cases.test.ts`, `test/note-cases.test.ts`,
  `test/plan-job.test.ts` (extended), `test/note-day.test.ts`, `test/reminder-sweep.test.ts`, `test/apns.test.ts`,
  `test/send-due.test.ts`, `test/pdf.test.ts`, `test/export-job.test.ts`, `test/pdf-job.test.ts`, `test/sweep.test.ts`,
  `test/jobs-routes.test.ts`, `test/platform-db.test.ts` (the local stack).

**Tools and workflows**
- `tools/contract.ts` (three more case files copied and checked), `tools/contract/{budget,reminder,note}-cases.json`;
  `tools/smoke.ts` (`/jobs/health`); `.github/workflows/deploy.yml` (the module and fonts check); `tools/check/steps.ts`
  (`api`'s inputs gain `fonts/**`).
- `docs/runbooks/simulator.md`: "13. A push to the simulator" (a real sandbox push to the iPhone 17 simulator through the
  local API, and `xcrun simctl push` for a payload alone).

**App (`ios/`)**
- `App/TutorCentral.entitlements` (`aps-environment`), `App/Info.plist` (`remote-notification`; the refresh identifier
  out), `project.yml` (`APS_ENVIRONMENT` per configuration).
- `Data/Push/DeviceTokenRepository.swift`, `SupabaseDeviceTokenRepository.swift`, `FakeDeviceTokenRepository.swift`,
  `Data/Push/PushRegistrar.swift`; `Data/Notifications/ReminderSettingsRepository.swift` (+ Supabase, Fake),
  `ReminderSettingsMigration.swift`; `Data/Jobs/JobsRepository.swift` (+ Supabase, Fake: a job's state for a subject,
  the three requests, cancel); `Data/Consent/ConsentHistoryRepository.swift` (+ Supabase, Fake);
  `Data/Files/ServerFiles.swift` (download a bucket's object into the copy); `Data/Cache/CopyFirst.swift`.
- `AppShell/AppDelegate.swift` (the token, the background push), `AppShell/PlanFetch.swift`, `AppShell/RootView*.swift`
  (registration at sign-in, the wipe, the stores' new dependencies), `AppShell/LaunchState.swift` (the nine states).
- `Features/Today/PlanStore*.swift`, `PlanSections.swift`, `TodayStore+Hero.swift`; `Features/Artefacts/NoteStore+Make.swift`,
  `SheetView.swift`, `MockView.swift`, `BriefView.swift`; `Features/Students/ConsentStore.swift`, `ConsentSection.swift`,
  `ConsentRecordSheet.swift`, `ConsentWithdrawSheet.swift` (new), `ExportSection.swift` and `ExportStore.swift` (new),
  `StudentDetailView.swift`; `Features/Settings/Reminders/RemindersView.swift`, `RemindersStore.swift`;
  `Features/Attendance/AttendanceStore*.swift` and the other stores Task 22 names.
- Removed: `Features/Today/PlanMaker*.swift`, `AppShell/RefreshHandler.swift`, `AppShell/ReminderScheduler.swift`,
  `Data/Refresh/BackgroundRefresh.swift`, `Domain/Reminders/ReminderPlanner.swift`, the local scheduling in `UNClient`,
  `Data/Notifications/ReminderSettingsStore.swift`, and Domain's plan rules when nothing uses them (decision 23).
- Tests: `DataTests/CopyFirstTests.swift`, `PushRegistrarTests.swift`, `ReminderSettingsMigrationTests.swift`,
  `JobsRepositoryTests.swift`, `ServerFilesTests.swift`; `TodayTests/PlanStoreJobTests.swift`; `StudentsTests/ConsentWithdrawTests.swift`,
  `ExportStoreTests.swift`; `SettingsTests/RemindersStoreTests.swift` (rewritten); `AppShellTests/PlanFetchTests.swift`,
  `PushTapTests.swift`; `AttendanceTests/AttendanceCopyFirstTests.swift`; the three case writers in `DomainTests`.

**Web (`web/`)**: `content/trust.ts`, `content/site.ts` ("Last changed").

**Documents:** `api/CLAUDE.md`, `ios/CLAUDE.md`, `supabase/CLAUDE.md`, `CLAUDE.md` (no command changes expected),
`plan/README.md` (D88 to D92, the phase's status), `plan/phase-18-server-work-and-push.md` ("As built"), `plan/STATE.md`,
`plan/sessions/037/`, `docs/testing/device-tests.md` (T16 and T17: a push on a real iPhone, the background fetch).

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 2 | `phase-18/db-withdrawal` | Migration 0036: `withdraw_consent`, the withdrawal recorded once with how and the day | none |
| 2 | 3 | `phase-18/db-requests` | Migration 0037: `request_plan`, `request_note`, `request_export`, each limited to its kind and the centre's rows | none |
| 3 | 4 | `phase-18/db-notifications` | Migration 0038: `reminder_settings`, the `notifications` outbox and its functions | none |
| 4 | 5 | `phase-18/db-schedules` | Migration 0039: the day's plans, note days and reminder plans written by pg_cron; the change triggers | none |
| 5 | 6 | `phase-18/db-storage` | Migration 0040: the `exports` and `pdfs` buckets, `storage_deletions` and its triggers, the PDF's job on a keep | none |
| 6 | 7 | `phase-18/case-files` | The budget, reminder and note-week case files written from Domain's rules; `bun contract` copies and checks them | none |
| 7 | 8 | `phase-18/api-make` | `makeRequest`: one builder per made kind for the route and the jobs; `recordedCall` takes a student and an empty check | none |
| 8 | 9 | `phase-18/api-budget` | The budget, the spaced queue and the exam split in TypeScript, equal to Domain's on the cases | none |
| 9 | 10 | `phase-18/api-push` | APNs: `@parse/node-apn` 8.1.0 (D88), the payloads, the outbox sent by the tick, a 410 retires a token | none |
| 10 | 11 | `phase-18/api-reminders` | The reminder rules in TypeScript, equal to Domain's; the `reminder_sweep` job plans the outbox | none |
| 11 | 12 | `phase-18/api-plan-material` | The `plan` job makes its material, plans exam weeks and holidays, replaces on request, and says it is ready | none |
| 12 | 13 | `phase-18/api-note-day` | The note week in TypeScript, equal to Domain's; the `note_day` job writes the notes and says they are ready | none |
| 13 | 14 | `phase-18/api-pdf` | Typst (D89) with the fonts; the `pdf` job for sheets, mocks and briefs; `/jobs/health`; the deploy's check | page 1 of each PDF |
| 14 | 15 | `phase-18/api-export` | The `export` job: the student's whole record as a PDF in `exports` | the file's pages |
| 15 | 16 | `phase-18/api-sweep-storage` | The sweep removes Storage's deleted files and old exports, notifications and jobs | none |
| main | | | `gh workflow run deploy` (Deploy 1): 0036 to 0040, the jobs, the schedules, push and the renderer live | |
| 16 | 17 | `phase-18/app-push-reminders` | The app: the device token, reminder settings on the account, the Reminders screen (P18-Reminders); `ReminderScheduler` and `BackgroundRefresh` retired | `reminders` (and `reminders-all-off`, `-refused`, `-not-asked`, `-day-picker` as they change) dark and light; a push on the simulator |
| 17 | 18 | `phase-18/app-plan-job` | The app: Today reads the plan's job (P18-Today-Plan-Making); asks for a plan; the background fetch; `PlanMaker` retired | `today-plan-making` dark and light, `today-planning`, the failed card, `today-no-batch` |
| 18 | 19 | `phase-18/app-note-day` | The app: the note day's notes from the job; a missing note asked of the server | `note` making, `today-note-day` |
| 19 | 20 | `phase-18/app-withdrawal` | The app: Parent withdrew, the withdrawal sheet, the page withdrawn with its history (P18 boards) | `student-consent-change`, `-withdraw`, `student-withdrawn` dark and light |
| 20 | 21 | `phase-18/app-export-pdfs` | The app: the Export section and Share (P18 boards); sheets, mocks and briefs share the server's PDF | `student-export*` (five), the file |
| 21 | 22 | `phase-18/app-copy-first` | The app: one copy-then-refresh path for every store (U10, U27); the replay's reload | `attendance` offline at launch, a slow read |
| 22 | 23 | `phase-18/web-trust` | `/trust` says what this phase keeps and removes | `/trust` at 1280 and 390, dark and light |
| 23+ | 24, 25 | `phase-18/fix-<what>` | The hand runs' and the review's fixes (D68) | as the change |
| main | 1, 24, 25 | | The owner's step, Deploy 2, build 28, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked; pictures by `bun shots`
and `bun pr-shots` for every changed state, both appearances where the board has both (D7); "Nothing on screen changes;
no pictures (D6, D7)" in a server pull request's description.

## The order

| When | What |
|---|---|
| Start | Reality against `STATE.md`; `bun check` green; the owner's step (Task 1) asked at once, the Vercel variables set when he answers, while PRs 1 to 8 are built |
| PRs 1 to 5 | Tasks 2 to 6, the migrations, against the local stack |
| PRs 6 to 15 | Tasks 7 to 16, the API; Deploy 1 after PR 15 (needs Task 1 done for the smoke's APNs check) |
| PRs 16 to 22 | Tasks 17 to 23, the app and the web, each to its boards; Task 24's hand runs after PR 21 |
| Close | Task 25: the review (Fable 5.1, two fresh reviewers), every finding fixed, Deploy 2, build 28, the documents |

---

### Task 1: The owner's step: the push key and the App ID's push (asked once, at the start)

The one thing no CLI can do: an APNs key is made in the owner's Apple developer account, and the App ID's capability is set
there. The session asks with the numbered list below as soon as it starts, goes on with Task 2 meanwhile, and does
everything after the download itself (D87).

- [ ] **Owner step 1: the APNs key and the App ID.** Send the owner exactly this:

  1. Open https://developer.apple.com/account in Safari and sign in with the Apple ID of the team "Arun Patra" (team id
     `Y7SW6436RD`).
  2. Under **Certificates, IDs & Profiles**, click **Keys**.
  3. Click the blue **+** next to "Keys".
  4. In **Key Name**, type `tutor-central-push`.
  5. Tick **Apple Push Notifications service (APNs)**, then click **Configure** on that row.
  6. In **Environment**, choose **Sandbox & Production**. In **Key Restriction**, choose **Team Scoped (All Topics)**.
     Click **Save**.
  7. Click **Continue**, then **Register**.
  8. Click **Download**. Safari saves a file named `AuthKey_` followed by ten letters and digits, ending `.p8`, in your
     **Downloads** folder. Apple lets you download it once only.
  9. On the same page, copy the **Key ID** (the same ten letters and digits).
  10. Click **Identifiers** in the left column, then the row **in.tutorcentral.app** (Tutor Central).
  11. Scroll to **Push Notifications**, tick it, and click **Save** at the top right. If a box says that changing
      capabilities makes the profiles invalid, click **Confirm**. Nothing else on that page changes.
  12. Reply here with the Key ID (step 9). Do not send the file or open it.

  Success: the key's page shows "tutor-central-push" with APNs enabled; the identifier shows Push Notifications ticked.
- [ ] **The session's part (D87).** With the Key ID from the reply and the file in `~/Downloads/AuthKey_<id>.p8`:

```bash
cd api
vercel env add APNS_KEY production < ~/Downloads/AuthKey_<id>.p8
printf '%s' '<id>' | vercel env add APNS_KEY_ID production
printf '%s' 'Y7SW6436RD' | vercel env add APNS_TEAM_ID production
printf '%s' 'in.tutorcentral.app' | vercel env add APNS_TOPIC production
vercel env ls production | grep APNS_
```

  Then `api/.env.local` gains the same four (the key on one line with `\n`, as `APPLE_SIGNIN_KEY` is held:
  `printf 'APNS_KEY=%s\n' "$(awk 'BEGIN{ORS="\\\\n"} {print}' ~/Downloads/AuthKey_<id>.p8)" >> api/.env.local`), never
  printed. The ledger records the names, not the values. The owner is told to keep the `.p8` in his password manager and
  delete it from Downloads; the testflight lane's cloud signing makes the profile with push on its next run.

---

### Task 2: Migration 0036: the withdrawal recorded once, with how and the day (PR 1)

**Files:**
- Create: `supabase/migrations/20261110000036_v3_consent_withdrawal.sql`
- Create: `supabase/tests/consent.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the function's grant in the catalogue's probe), `supabase/types.ts`

**Interfaces:**
- Produces: `withdraw_consent(p_centre uuid, p_student uuid, p_how text, p_on date) returns uuid` (the event's id); errors
  `42501` (not a member), `consent_not_given` (P0001: nothing to withdraw), `consent_day` (P0001: the day before the last
  agreement or after today in India); `p_how in ('in_person','call','whatsapp')`.

- [ ] **Step 1: the failing tests** (`supabase/tests/consent.test.ts`, the jobs test's frame: a member `a` of centre A with
  a student who has consent, a member `b` of centre B, the service client, `sql`):

```ts
test("withdraw_consent records one withdrawn event with how and the day, and clears the columns", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  const { data, error } = await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() });
  expect(error).toBeNull();
  const events = await sql`select kind, how, (at at time zone 'Asia/Kolkata')::date::text as day, by_user from public.consent_events
                           where student_id = ${id} order by created_at`;
  expect(events.map((e: { kind: string }) => e.kind)).toEqual(["given", "withdrawn"]);
  expect(events[1]).toMatchObject({ how: "call", day: today(), by_user: userA });
  const [s] = await sql`select consent_at, consent_phone, consent_how from public.students where id = ${id}`;
  expect(s).toEqual({ consent_at: null, consent_phone: null, consent_how: null });
  expect(data).toBe((await sql`select id from public.consent_events where student_id = ${id} and kind = 'withdrawn'`)[0].id);
});

test("a day before the agreement, or after today, is refused", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-05");
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: "2026-10-04" })).error?.message).toContain("consent_day");
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: tomorrow() })).error?.message).toContain("consent_day");
});

test("a student without consent has nothing to withdraw", async () => {
  const id = await student(a, centreA);
  expect((await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() })).error?.message).toContain("consent_not_given");
});

test("another centre's member cannot withdraw", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  expect((await b.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "call", p_on: today() })).error?.code).toBe("42501");
});

test("a clear of the columns still records a withdrawal (build 27's Remove)", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  await a.from("students").update({ consent_at: null, consent_phone: null, consent_how: null }).eq("id", id);
  const kinds = await sql`select kind from public.consent_events where student_id = ${id} order by created_at`;
  expect(kinds.map((k: { kind: string }) => k.kind)).toEqual(["given", "withdrawn"]);
});

test("withdraw_consent cancels the student's queued note request", async () => {
  const id = await studentWithConsent(a, centreA, "2026-10-01");
  const job = (await a.rpc("request_note", { p_centre: centreA, p_student: id, p_week: weekStart() })).data as string;
  await a.rpc("withdraw_consent", { p_centre: centreA, p_student: id, p_how: "in_person", p_on: today() });
  expect((await sql`select state from public.jobs where id = ${job}`)[0].state).toBe("cancelled");
});
```

  The last test needs Task 3's `request_note`; it is written here `test.skip` and turned on in PR 2 (the ledger says so).
  `today()` and `tomorrow()` are the IST day (`supabase/CLAUDE.md`: `current_date` is UTC).

- [ ] **Step 2: run, expect RED.** `cd supabase && bun test tests/consent.test.ts` → the function does not exist.

- [ ] **Step 3: the migration.**

```sql
-- V3, Phase 18: a parent's withdrawal is recorded as an event with how and the day (D79; P18-Consent-Withdraw), in one
-- transaction with the clear of the current-state columns the gate reads. 0032's trigger records a clear by itself
-- (build 27's Remove); while this function runs it skips, so the event is written once, by this function, with its how.

create or replace function public.students_consent_history() returns trigger language plpgsql set search_path = '' as $$
begin
  perform set_config('tc.consent', 'on', true);
  if new.consent_at is not null and (tg_op = 'INSERT' or old.consent_at is null
       or old.consent_at is distinct from new.consent_at or old.consent_phone is distinct from new.consent_phone
       or old.consent_how is distinct from new.consent_how) then
    insert into public.consent_events (centre_id, student_id, kind, phone, how, at, by_user)
    values (new.centre_id, new.id, 'given', new.consent_phone, new.consent_how, new.consent_at, auth.uid());
  elsif tg_op = 'UPDATE' and new.consent_at is null and old.consent_at is not null
        and current_setting('tc.withdrawn', true) is distinct from 'on' then
    insert into public.consent_events (centre_id, student_id, kind, at, by_user)
    values (new.centre_id, new.id, 'withdrawn', now(), auth.uid());
  end if;
  perform set_config('tc.consent', 'off', true);
  return null;
end $$;

create function public.withdraw_consent(p_centre uuid, p_student uuid, p_how text, p_on date)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_given timestamptz;
  v_today date := (now() at time zone 'Asia/Kolkata')::date;
  v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_how not in ('in_person', 'call', 'whatsapp') then raise exception 'consent_how' using errcode = 'P0001'; end if;
  select consent_at into v_given from public.students where centre_id = p_centre and id = p_student for update;
  if v_given is null then raise exception 'consent_not_given' using errcode = 'P0001'; end if;
  if p_on < (v_given at time zone 'Asia/Kolkata')::date or p_on > v_today then
    raise exception 'consent_day' using errcode = 'P0001';
  end if;
  perform set_config('tc.consent', 'on', true);
  insert into public.consent_events (centre_id, student_id, kind, how, at, by_user)
  values (p_centre, p_student, 'withdrawn', p_how,
          case when p_on = v_today then now() else (p_on::timestamp + time '12:00') at time zone 'Asia/Kolkata' end,
          auth.uid())
  returning id into v_id;
  perform set_config('tc.consent', 'off', true);
  perform set_config('tc.withdrawn', 'on', true);
  update public.students set consent_at = null, consent_phone = null, consent_how = null
   where centre_id = p_centre and id = p_student;
  perform set_config('tc.withdrawn', 'off', true);
  -- What stops at once: the note requests waiting for this student (the gate refuses the rest by itself).
  perform set_config('tc.jobs', 'on', true);
  update public.jobs set state = 'cancelled', finished_at = now()
   where centre_id = p_centre and kind = 'note_day' and state in ('queued', 'waiting')
     and input->>'student_id' = p_student::text;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;
revoke all on function public.withdraw_consent(uuid, uuid, text, date) from public, anon;
grant execute on function public.withdraw_consent(uuid, uuid, text, date) to authenticated;
```

  Check at build time: 0028's `jobs_through_functions` trigger lets an update through when `tc.jobs` is on (as
  `cancel_job` does); if it only lets `cancel_job`'s exact update through, call `public.cancel_job(p_centre, id)` for each
  row instead and record the ruling.

- [ ] **Step 4: GREEN.** `bun test tests/consent.test.ts` (five pass, one skipped), then `bun check --only=db,tools`;
  `supabase gen types typescript --local > types.ts`; `bun contract`.
- [ ] **Step 5: commit, PR 1, merge on local green (D86).**

---

### Task 3: Migration 0037: the member requests (PR 2)

**Files:**
- Create: `supabase/migrations/20261111000037_v3_member_requests.sql`, `supabase/tests/requests.test.ts`
- Modify: `supabase/tests/consent.test.ts` (the skipped test on), `supabase/tests/rls.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: `request_plan(p_centre uuid, p_class uuid, p_date date, p_choices jsonb default null) returns uuid`;
  `request_note(p_centre uuid, p_student uuid, p_week date) returns uuid`; `request_export(p_centre uuid, p_student uuid)
  returns uuid`. Each answers the live job (`queued`, `running`, `waiting`) for the same subject when one exists. Input
  shapes the jobs read: plan `{class_id, date, replace?: true, choices?: {groups, subjects}}`, note `{student_id, week}`,
  export `{student_id}`. Keys: `plan:<class>:<date>` for the first, `plan:<class>:<date>:<epoch ms>` after one exists;
  `note:<student>:<week>[:<epoch ms>]`; `export:<student>:<epoch ms>`.

- [ ] **Step 1: the failing tests** (`supabase/tests/requests.test.ts`):

```ts
test("request_plan queues one plan job for the batch and day; a second ask answers the same job", async () => {
  const first = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  const again = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  expect(again).toBe(first);
  const [job] = await sql`select kind, idempotency_key, input, created_by from public.jobs where id = ${first}`;
  expect(job).toMatchObject({ kind: "plan", idempotency_key: `plan:${classA}:${today()}`, input: { class_id: classA, date: today() }, created_by: userA });
});

test("after a failed plan job, a new ask is a new job", async () => {
  const first = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  await sql`update public.jobs set state = 'failed' where id = ${first}`;
  const next = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).data as string;
  expect(next).not.toBe(first);
});

test("choices make a replacing plan job", async () => {
  const choices = { groups: 2, subjects: { "1": "Science" } };
  const id = (await a.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today(), p_choices: choices })).data;
  expect((await sql`select input from public.jobs where id = ${id}`)[0].input).toMatchObject({ replace: true, choices });
});

test("a class of another centre, or a student of another centre, is refused", async () => {
  expect((await b.rpc("request_plan", { p_centre: centreB, p_class: classA, p_date: today() })).error?.message).toContain("not_found");
  expect((await b.rpc("request_export", { p_centre: centreB, p_student: studentA })).error?.message).toContain("not_found");
  expect((await b.rpc("request_plan", { p_centre: centreA, p_class: classA, p_date: today() })).error?.code).toBe("42501");
});

test("request_export and request_note queue their own kind with the student", async () => {
  const e = (await a.rpc("request_export", { p_centre: centreA, p_student: studentA })).data;
  const n = (await a.rpc("request_note", { p_centre: centreA, p_student: studentA, p_week: weekStart() })).data;
  const rows = await sql`select kind, input from public.jobs where id in (${e}, ${n}) order by kind`;
  expect(rows).toEqual([{ kind: "export", input: { student_id: studentA } }, { kind: "note_day", input: { student_id: studentA, week: weekStart() } }]);
});

test("a member still cannot call enqueue_job or insert a job", async () => {
  expect((await a.rpc("enqueue_job", { p_centre: centreA, p_kind: "plan", p_key: "x" })).error).not.toBeNull();
  expect((await a.from("jobs").insert({ centre_id: centreA, kind: "export", idempotency_key: "y" })).error).not.toBeNull();
});
```

- [ ] **Step 2: RED** (`bun test tests/requests.test.ts`).
- [ ] **Step 3: the migration.** One private helper does the insert for the three (security invoker, no grant to
  `authenticated`: called only inside the three, which the caller runs as itself — so `authenticated` needs execute on it;
  grant it, and it re-checks `is_member` itself, so a direct call can queue nothing a request could not):

```sql
create function public.request_job(p_centre uuid, p_kind public.job_kind, p_subject text, p_key text, p_input jsonb)
returns uuid language plpgsql security invoker set search_path = '' as $$
declare v_live uuid; v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_kind not in ('plan', 'note_day', 'export') then raise exception 'job_kind' using errcode = 'P0001'; end if;
  select id into v_live from public.jobs
   where centre_id = p_centre and kind = p_kind and state in ('queued', 'running', 'waiting')
     and (input->>'class_id' = p_subject or input->>'student_id' = p_subject)
     and (p_kind <> 'plan' or input->>'date' = p_input->>'date')
   order by created_at desc limit 1;
  if v_live is not null then return v_live; end if;
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input)
  values (p_centre, p_kind, p_key, p_input)
  on conflict do nothing returning id into v_id;
  if v_id is null then  -- the plain key was used by an earlier, finished job: a fresh one
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, p_kind, p_key || ':' || (extract(epoch from clock_timestamp()) * 1000)::bigint, p_input)
    returning id into v_id;
  end if;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;
```

  `request_plan` checks the class is the centre's and not archived (`not_found`), builds `{class_id, date}` plus `replace:
  true, choices` when given, and calls `request_job(p_centre, 'plan', p_class::text, 'plan:'||p_class||':'||p_date, …)`;
  `request_note` checks the student (`not_found`) and that the week is a Monday; `request_export` checks the student. A
  replacing ask whose live job is a plain one waits behind it (answers the live job: the Change sheet's Make the plan again
  while the morning's job runs is refused in place with the planning card; the tutor asks again after). Grants: the three
  and `request_job` to `authenticated` and `service_role`.

- [ ] **Step 4: GREEN**, the consent test's skipped case on and green; `bun check --only=db,tools`; types; contract.
- [ ] **Step 5: commit, PR 2, merge.**

---

### Task 4: Migration 0038: reminder settings and the notifications outbox (PR 3)

**Files:**
- Create: `supabase/migrations/20261112000038_v3_notifications.sql`, `supabase/tests/notifications.test.ts`
- Modify: `supabase/tests/rls.test.ts` (two tables in the catalogue), `supabase/types.ts`

**Interfaces:**
- Produces: tables `reminder_settings` (`id, centre_id, user_id default auth.uid(), class_on bool default true,
  class_minutes smallint default 60 check in (5,10,15,30,60), events_on bool default true, event_lead text default 'hour1'
  check in ('min15','min30','hour1','day_before'), fees_on bool default true, fees_day smallint default 5 check 1..28,
  plan_ready_on bool default true, notes_ready_on bool default true, created_at, updated_at, unique (centre_id, user_id)`)
  and `notifications` (`id, centre_id, user_id, kind text check in ('class','event','fees','plan_ready','notes_ready',
  'plan_fetch'), key text (1–200), due_at timestamptz, title text, body text, link text, background bool default false,
  state text default 'due' check in ('due','sent','failed','expired','cancelled'), sent_at, apns jsonb, created_at,
  updated_at, unique (user_id, key)`). Functions (platform only): `replace_notifications(p_centre uuid, p_user uuid,
  p_kinds text[], p_from timestamptz, p_rows jsonb) returns int` (cancels the user's `due` rows of those kinds from
  `p_from` whose key is not among the new rows, upserts the new rows by key, leaving sent rows alone; the count written),
  `due_notifications(p_now timestamptz, p_limit int default 200) returns setof notifications` (state `due`, `due_at <=
  p_now`, marks `expired` those older than 30 minutes first, `for update skip locked`), `mark_notification(p_id uuid,
  p_state text, p_apns jsonb) returns void`, `live_tokens(p_user uuid) returns table(id uuid, token text, environment text)`,
  `retire_token(p_id uuid) returns void`.

- [ ] **Step 1: the failing tests** (`notifications.test.ts`):

```ts
test("a tutor reads and writes their own reminder settings, not another's", async () => {
  expect((await a.from("reminder_settings").insert({ centre_id: centreA, class_minutes: 15 })).error).toBeNull();
  expect((await a.from("reminder_settings").select("class_minutes, plan_ready_on")).data).toEqual([{ class_minutes: 15, plan_ready_on: true }]);
  expect((await b.from("reminder_settings").select("*")).data).toEqual([]);
  expect((await b.from("reminder_settings").insert({ centre_id: centreA })).error).not.toBeNull();
});

test("a member reads their own notifications and writes none", async () => {
  await svc.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: ["class"], p_from: iso(0), p_rows: [row("class:c1:t1", 30)] });
  expect((await a.from("notifications").select("key")).data).toEqual([{ key: "class:c1:t1" }]);
  expect((await a.from("notifications").insert({ centre_id: centreA, user_id: userA, kind: "class", key: "k", due_at: iso(1), title: "t", body: "b" })).error).not.toBeNull();
  expect((await a.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: [], p_from: iso(0), p_rows: [] })).error).not.toBeNull();
});

test("a replan cancels a future unsent row it no longer writes, keeps sent rows, and upserts the rest", async () => {
  await svc.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: ["class"], p_from: iso(0), p_rows: [row("class:c1:16:45", 45), row("class:c1:tomorrow", 1500)] });
  await sql`update public.notifications set state = 'sent' where key = 'class:c1:tomorrow'`;
  await svc.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: ["class"], p_from: iso(0), p_rows: [row("class:c1:17:15", 75)] });
  const rows = await sql`select key, state from public.notifications where user_id = ${userA} order by key`;
  expect(rows).toEqual([
    { key: "class:c1:16:45", state: "cancelled" },
    { key: "class:c1:17:15", state: "due" },
    { key: "class:c1:tomorrow", state: "sent" },
  ]);
});

test("due rows come once to two takers; rows older than thirty minutes expire unsent", async () => {
  await svc.rpc("replace_notifications", { p_centre: centreA, p_user: userA, p_kinds: ["fees"], p_from: iso(-3600), p_rows: [row("fees:old", -45), row("fees:now", -1)] });
  const [x, y] = await Promise.all([svc.rpc("due_notifications", { p_now: iso(0) }), svc.rpc("due_notifications", { p_now: iso(0) })]);
  expect([...(x.data ?? []), ...(y.data ?? [])].map((n: { key: string }) => n.key)).toEqual(["fees:now"]);
  expect((await sql`select state from public.notifications where key = 'fees:old'`)[0].state).toBe("expired");
});
```

  `row(key, minutes)` builds `{ kind, key, due_at: iso(minutes * 60), title: "t", body: "b", link: "tutorcentral://today" }`.
  "Once to two takers" needs `due_notifications` to move what it hands out to a held state in the same statement; it sets
  `state = 'sent'` optimistically with `sent_at = now()` and the sender marks `failed` on Apple's refusal (one fewer state:
  the tick is the only taker, and a crash mid-send loses at most that minute's pushes, which the ledger names).

- [ ] **Step 2: RED.** **Step 3: the migration** (tables with RLS: `reminder_settings_self` for select, insert, update
  `using (user_id = auth.uid() and public.is_member(centre_id))`; `notifications_self_read` for select; revoke insert,
  update, delete on `notifications` and delete on `reminder_settings` from `authenticated`; the five functions granted to
  `service_role` only). **Step 4: GREEN** with `bun check --only=db,tools`, types, contract. **Step 5: commit, PR 3, merge.**

---

### Task 5: Migration 0039: the day's jobs written by pg_cron; the change triggers (PR 4)

**Files:**
- Create: `supabase/migrations/20261113000039_v3_schedules.sql`, `supabase/tests/schedules.test.ts`
- Modify: `supabase/types.ts`

**Interfaces:**
- Consumes: `jobs`, `events` (Phase 17's activity), `device_tokens`, `centre_members`, `classes` (`meeting_days`,
  `start_time`, `note_weekday`, `note_time`, `archived_at`), `plans`.
- Produces: `centre_in_use(p_centre uuid, p_now timestamptz default now()) returns boolean` (an `app_opened` event in the
  last 14 days, D91); `schedule_plans(p_now timestamptz default now()) returns int`; `schedule_note_days(p_now) returns
  int`; `schedule_reminders(p_now) returns int`; the trigger function `queue_reminder_plan()` on `classes`,
  `calendar_events`, `fee_invoices`, `reminder_settings` (insert, update, delete; statement-level, one job per centre per
  minute by key `reminders:<centre>:<yyyy-mm-dd-hh-mi>`); the cron entries `schedule_plans` (`*/15 * * * *`),
  `schedule_note_days` (`*/15 * * * *`), `schedule_reminders` (`5 * * * *`). All take `p_now` so tests fix the time; all
  write with `tc.jobs` on (they run as `postgres` under pg_cron with no request, which 0028's trigger lets in anyway).

- [ ] **Step 1: the failing tests** (`schedules.test.ts`; times in IST through `p_now`):

```ts
test("a batch meeting today in a centre in use gets one plan job at 05:30", async () => {
  await opened(centreA, "2026-11-02T08:00:00+05:30");          // an app_opened event the day before
  await batch(centreA, { days: [1], start: "17:00" });          // Monday
  expect((await sql`select public.schedule_plans('2026-11-02T00:15:00+05:30')`)[0].schedule_plans).toBe(1);
  expect((await sql`select public.schedule_plans('2026-11-02T00:30:00+05:30')`)[0].schedule_plans).toBe(0);
  const [j] = await sql`select idempotency_key, input, (run_at at time zone 'Asia/Kolkata')::text as at from public.jobs where kind = 'plan'`;
  expect(j.at).toBe("2026-11-02 05:30:00");
  expect(j.input).toEqual({ class_id: classId, date: "2026-11-02" });
});

test("an early batch is planned two hours before it, never before 03:30", async () => {
  await batch(centreA, { days: [1], start: "06:30" });
  await sql`select public.schedule_plans('2026-11-02T00:15:00+05:30')`;
  expect((await sql`select (run_at at time zone 'Asia/Kolkata')::time::text as t from public.jobs where kind = 'plan'`)[0].t).toBe("04:30:00");
});

test("no plan job is written for a centre idle 14 days", async () => {
  await opened(centreA, "2026-10-18T08:00:00+05:30");
  await batch(centreA, { days: [1], start: "17:00" });
  expect((await sql`select public.schedule_plans('2026-11-02T00:15:00+05:30')`)[0].schedule_plans).toBe(0);
});

test("a batch with today's plan, a batch not meeting today and an archived batch get nothing", async () => {
  await opened(centreA, "2026-11-01T08:00:00+05:30");
  const planned = await batch(centreA, { days: [1], start: "17:00" });
  await sql`insert into public.plans (centre_id, class_id, date) values (${centreA}, ${planned}, '2026-11-02')`;
  await batch(centreA, { days: [2], start: "17:00" });                                   // Tuesdays only
  const archived = await batch(centreA, { days: [1], start: "17:00" });
  await sql`update public.classes set archived_at = now() where id = ${archived}`;
  expect((await sql`select public.schedule_plans('2026-11-02T00:15:00+05:30')`)[0].schedule_plans).toBe(0);
});

test("the note day is planned two hours before its time; Sunday 18:00 when unset", async () => {
  await opened(centreA, "2026-11-07T08:00:00+05:30");
  await batch(centreA, { days: [1, 3, 5], start: "17:00" });
  await sql`select public.schedule_note_days('2026-11-08T00:15:00+05:30')`;   // a Sunday
  expect((await sql`select (run_at at time zone 'Asia/Kolkata')::text as at from public.jobs where kind = 'note_day'`)[0].at).toBe("2026-11-08 16:00:00");
});

test("a class update queues a reminder plan for its centre within the minute, once a minute", async () => {
  const id = await batch(centreA, { days: [1], start: "17:00" });
  await a.from("classes").update({ start_time: "17:30" }).eq("id", id);
  await a.from("classes").update({ start_time: "17:45" }).eq("id", id);
  expect((await sql`select count(*)::int as n from public.jobs where kind = 'reminder_sweep' and centre_id = ${centreA}`)[0].n).toBe(1);
});

test("schedule_reminders queues a plan for each centre with a live token, and none without", async () => {
  await a.from("device_tokens").insert({ device_id: "sim-1", token: "aa", environment: "sandbox" });
  await b.from("device_tokens").insert({ device_id: "sim-2", token: "bb", environment: "sandbox", retired_at: new Date().toISOString() });
  expect((await sql`select public.schedule_reminders('2026-11-02T10:05:00+05:30')`)[0].schedule_reminders).toBe(1);
  expect((await sql`select centre_id from public.jobs where kind = 'reminder_sweep'`).map((r: { centre_id: string }) => r.centre_id)).toEqual([centreA]);
});
```

  `batch()` makes a class with a member through the member client; `opened()` inserts an `events` row with `kind
  'app_opened'` and `at`. A test clears `jobs` first (the claim tests' rule).

- [ ] **Step 2: RED.** **Step 3: the migration.** The plan's time:

```sql
-- 05:30 in India, or two hours before a batch that starts before 07:30, never before 03:30 (plan decision 8).
create function public.plan_time(p_day date, p_start time) returns timestamptz language sql immutable set search_path = '' as $$
  select (p_day::timestamp + case
            when p_start is not null and p_start < time '07:30' then greatest(p_start - interval '2 hours', time '03:30')
            else time '05:30' end) at time zone 'Asia/Kolkata'
$$;
```

  `schedule_plans` selects classes `where archived_at is null and extract(isodow from v_day) = any(meeting_days)` with an
  active member, `public.centre_in_use(centre_id, p_now)`, no `plans` row for `(class_id, v_day)` and no `jobs` row with key
  `plan:<id>:<day>`, and inserts `('plan', 'plan:'||id||':'||v_day, {class_id, date}, greatest(p_now, plan_time(v_day,
  start_time)))` with `on conflict do nothing`; it returns the count inserted. `schedule_note_days` likewise for
  `coalesce(note_weekday, 7) = isodow` at `(day + coalesce(note_time, '18:00') - 2 hours)`; `schedule_reminders` for each
  centre with a member holding a token `retired_at is null` and `last_seen_at > now() - 60 days`. `cron.schedule` the three.

- [ ] **Step 4: GREEN**; `bun check --only=db,tools`; types. **Step 5: commit, PR 4, merge.**

---

### Task 6: Migration 0040: the buckets, Storage's deletions, the PDF's job (PR 5)

**Files:**
- Create: `supabase/migrations/20261114000040_v3_storage_files.sql`, `supabase/tests/storage.test.ts`
- Modify: `supabase/tests/rls.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: buckets `exports` and `pdfs` (private, `application/pdf`; 10 MB and 5 MB); policies `exports_member_read`,
  `pdfs_member_read` (`is_member(public.photo_centre(name))`, select only); table `storage_deletions` (`id, bucket text,
  path text, prefix boolean default false, why text, created_at, updated_at`; RLS on, no policy); trigger function
  `forget_photo()` (after delete on `artefacts`, `school_items`, `marks`, `textbooks` where `old.photo_path is not null`:
  `('photos', old.photo_path, false, tg_table_name)`; and for `artefacts` also `('pdfs', centre||'/'||id||'.pdf', false,
  'artefact')`), `forget_student()` (after delete on `students`: `('exports', centre||'/'||id||'/', true, 'student')`),
  `forget_centre()` (after delete on `centres`: the three buckets' `centre||'/'` as prefixes); `queue_pdf()` (after insert
  on `artefacts` where `kind in ('sheet','mock','brief')` and `source = 'made'`: a `pdf` job keyed `pdf:<artefact>` with
  `{artefact_id}`); `taken_storage_deletions(p_limit int default 100) returns setof storage_deletions` (platform: takes and
  deletes in one statement, `for update skip locked`).

- [ ] **Step 1: the failing tests** (`storage.test.ts`):

```ts
test("a deleted student's marks photo and exports are queued for deletion", async () => {
  const s = await student(a, centreA);
  await sql`insert into public.marks (centre_id, student_id, subject, test, date, score, max, photo_path)
            values (${centreA}, ${s}, 'Maths', 'Unit test 1', '2026-10-01', 19, 25, ${`${centreA}/mark/x.jpg`})`;
  await a.from("students").delete().eq("id", s);
  const rows = await sql`select bucket, path, prefix from public.storage_deletions order by bucket`;
  expect(rows).toEqual([
    { bucket: "exports", path: `${centreA}/${s}/`, prefix: true },
    { bucket: "photos", path: `${centreA}/mark/x.jpg`, prefix: false },
  ]);
});

test("a deleted account queues its centre's three prefixes", async () => { /* delete_account as a fresh member; three rows */ });
test("a kept sheet queues its PDF job once; a check does not", async () => { /* keep_artefact twice with one key; one pdf job */ });
test("a member reads their centre's exports and pdfs objects, never another's, and writes none", async () => { /* storage.objects inserted by the service client */ });
test("taken_storage_deletions hands each row out once and removes it", async () => { /* two concurrent takes */ });
```

- [ ] **Step 2: RED. Step 3: the migration** (buckets by `insert into storage.buckets (id, name, public, file_size_limit,
  allowed_mime_types) values … on conflict (id) do nothing`, as 0011 made `photos`). **Step 4: GREEN**, `bun check
  --only=db,tools`, types. **Step 5: commit, PR 5, merge.**

---

### Task 7: The case files: the budget, the reminders, the note week, written from Domain's rules (PR 6)

**Files:**
- Create: `ios/TutorCentralKit/Tests/DomainTests/BudgetCasesTests.swift`, `ReminderCasesTests.swift`, `NoteCasesTests.swift`
  (each: the scenarios, the writer behind its environment flag, and the test that Domain answers the file's cases)
- Create: `tools/contract/budget-cases.json`, `reminder-cases.json`, `note-cases.json` (written by the writers)
- Modify: `tools/contract.ts` (copy each into `ios/TutorCentralKit/Tests/DomainTests/Cases/`, `--check` names a stale one),
  `tools/contract.test.ts`, `ios/TutorCentralKit/Package.swift` (the three resources)

**Interfaces:**
- Produces, for Tasks 9, 11 and 13: `{cases: [{name, input, expected}]}` in plain JSON (dates `YYYY-MM-DD`, times
  `HH:MM`, instants as ISO strings with `+05:30`, ids fixed UUIDs), as `plan-cases.json` is.
  - **budget:** `input` = `{draft: PlanDraft, record: {chapters, skills, checks}, exams: [{item, members, days}],
    mocksMade: [itemId], briefsMade: [chapter], date}`; `expected` = the ordered requests of `ArtefactBudget.requests`
    (`{kind: "checks"|"personalChecks"|"sheet"|"workedExample"|"figure"|"brief"|"mock"|"placement", group?, student?,
    skills?, questions?, forHomework?, light?, figure?, chapter?, item?}`) and, per exam, `ExamPreparation.days`' split
    (`[{date, kind: "revise"|"mock"|"afterMock"|"exam", portions}]`).
  - **reminder:** `input` = `{now, settings, classes: [{id, name, days, start, end, members}], events: [{id, title, date,
    start, end, note}], dueFees: {month, count, total}|null}`; `expected` = `ReminderPlanner.plan`'s reminders (`{id, kind,
    title, body, at, link}`).
  - **note:** `input` = `{record: NoteRecord as JSON, noteDay, ladder: {chapters, skills}}`; `expected` = `{facts:
    NoteWeek.facts, topic: NoteWeek.topic, canDo: CanDoWeek.facts | null, isLadder}`.

- [ ] **Step 1: the scenarios.** Budget (at least 24): a normal group of three, two groups, the light homework, a figure
  skill, a brief above class 7 and one asked for, personal checks for four and for five (the cap), a spaced pair, an empty
  queue becoming a placement, twenty requests cut, an exam group on a revise day, on the mock day (mock made, and already
  made), after the mock with gap skills and without, a member on holiday, the exam day itself, the split for 2, 3 and 9
  meeting days and a custom window. Reminders (at least 16): the ten `ReminderPlannerTests` cases as data plus a fees day
  already past this month, a class on a holiday-free day, 61 reminders cut to 60, a timed and an untimed event, the day
  before at 18:00, every switch off. Note week (at least 14): a week with checks, absences, homework not done, a mark, a
  ladder student moving up and not, a holiday week, no sessions.
- [ ] **Step 2: write the files.** `TEST_RUNNER_TC_WRITE_BUDGET_CASES=$PWD/tools/contract/budget-cases.json` (and the two
  others) with `xcodebuild test -only-testing:DomainTests/writeTheBudgetCases` etc., `-collect-test-diagnostics never`; read
  each file's first cases by eye against the Swift tests' assertions (the ledger says which were read).
- [ ] **Step 3: the contract.** `tools/contract.test.ts` first (RED: a changed `budget-cases.json` is named stale by
  `--check`), then `tools/contract.ts` copies the three; `bun contract`; `bun check` green (the Domain case tests pass on
  their own files).
- [ ] **Step 4: commit, PR 6, merge.**

---

### Task 8: `makeRequest`: one builder per made kind; `recordedCall` with a student (PR 7)

**Files:**
- Create: `api/src/make.ts`, `api/test/make.test.ts`
- Modify: `api/src/routes/v2.ts` (the `/make` switch calls `makeRequest`), `api/src/jobs/call.ts`, `api/test/runner.test.ts`
  (or the call's own test file)

**Interfaces:**
- Produces: `makeRequest(v: MakeInput): { kind: AIKind; request: ClaudeRequest<unknown>; student?: string; studentName?:
  string; empty?: (made: unknown) => boolean }` — exactly the arguments `run` takes today per kind; `recordedCall(ctx, {
  centre, kind, input, request, job, step, key?, student?, empty? })` (`key` overrides `<job>:<step>`; `student` reaches
  `startCall`; `empty` marks an answer failed `refused` as the route does).

- [ ] **Step 1: the failing tests.** `make.test.ts`: for each of the twelve kinds a body from `DataTests/Contract` samples'
  inputs answers the same `kind`, `student` and request model as the route does today (`routes/v2.ts` before the change, the
  test's expectations written from it); a mock whose marks miss the pattern is `empty`; a figure of another template is
  `empty`. `call` tests: `recordedCall` with `student` passes it to `startCall` (the fake db records it); a personal kind
  without consent comes back `failed` with reason `student_consent` and costs nothing; `key` overrides the step key; an
  `empty` answer is `failed` `refused` with its tokens recorded.
- [ ] **Step 2: RED** (`cd api && bun test test/make.test.ts`). **Step 3:** move the switch into `make.ts`, the route
  becomes `const m = makeRequest(v); return run(c, deps, body.centre, { input: v, ...m });`; extend `recordedCall`.
- [ ] **Step 4: GREEN**: `bun run check` (tsc and every test: the route's own tests unchanged prove the move).
- [ ] **Step 5: commit, PR 7, merge.**

---

### Task 9: The budget, the spaced queue and the exam split in TypeScript (PR 8)

**Files:**
- Create: `api/src/plan/budget.ts`, `api/src/plan/spaced.ts`, `api/src/plan/exam-prep.ts`, `api/test/budget-cases.test.ts`
- Modify: `api/src/plan/types.ts` (the request and the split's types)

**Interfaces:**
- Consumes: `PlanDraft`, `Chapter`, `Skill` (`plan/types.ts`), the budget cases (Task 7).
- Produces: `budget(draft: PlanDraft, record: BudgetRecord, exams: ExamGroupInput[], made: { mocks: string[]; briefs:
  string[] }): MaterialRequest[]` (the order and the 20-cap of `ArtefactBudget.requests`; constants `MAX_CALLS = 20`,
  `MAX_PERSONAL_CHECKS = 4`, `CHECKS_PER_CLASS = 3`, `SET_QUESTIONS = 10`, `HOMEWORK_QUESTIONS = 10`,
  `LIGHT_HOMEWORK_QUESTIONS = 5`); `spacedPair(skills, checks, date)` and `spacedQueue(...)` (`SpacedQueue`'s);
  `examDays(item: { date; windowDays?; arrivedOn }, meetingDays: number[], holidays: DayRange[]): ExamDay[]`
  (`ExamPreparation.days` with `start(of:)`, `MOCK_DAYS_BEFORE = 2`, `WINDOW_DAYS = 14`) and `revisionLines(...)`
  (`PlanMaker.exams`' per-member lines, skipping members on holiday and the exam day).

- [ ] **Step 1: the failing test.**

```ts
import cases from "../../tools/contract/budget-cases.json";
import { budget } from "../src/plan/budget.js";
import { examDays } from "../src/plan/exam-prep.js";

for (const c of cases.cases) {
  test(`budget: ${c.name}`, () => {
    expect(budget(c.input.draft, c.input.record, c.input.exams, { mocks: c.input.mocksMade, briefs: c.input.briefsMade }))
      .toEqual(c.expected.requests);
  });
  for (const [i, e] of (c.input.exams ?? []).entries()) {
    test(`exam split: ${c.name} #${i}`, () => {
      expect(examDays(e.item, e.meetingDays, e.holidays)).toEqual(c.expected.splits[i]);
    });
  }
}
```

- [ ] **Step 2: RED. Step 3: the port**, line by line from `ArtefactBudget.swift`, `Domain/Record/SpacedQueue.swift` and
  `Domain/School/ExamPreparation.swift`, each function's doc comment naming its Swift original. **Step 4: GREEN**, `bun run
  check`. **Step 5: commit, PR 8, merge.**

---

### Task 10: APNs: the library, the payloads, the outbox sent by the tick (PR 9)

**Files:**
- Create: `api/src/push/apns.ts`, `api/src/push/apns-fake.ts`, `api/src/push/payload.ts`, `api/src/push/send-due.ts`,
  `api/src/push/db.ts`, `api/test/apns.test.ts`, `api/test/send-due.test.ts`
- Modify: `api/package.json` (`"@parse/node-apn": "8.1.0"`), `bun.lock`, `api/src/routes/jobs.ts` (the tick sends before it
  drains), `api/src/index.ts` (the providers from `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC`; absent locally:
  the fake that records), `api/src/env.ts`, `api/.env.example`, `api/test/jobs-routes.test.ts`

**Interfaces:**
- Produces: `type Push = { token: string; environment: "sandbox" | "production"; payload: PushPayload }`;
  `type PushAnswer = { ok: true; apnsId: string } | { ok: false; status: number; reason: string; retire: boolean }`;
  `interface Pusher { send(p: Push): Promise<PushAnswer>; close(): Promise<void> }`; `makeApnsPusher(env)` (two
  `apn.Provider`s, made at the first send of an environment, closed by `close()`); `alertPayload(n: { id; title; body; link
  })` → `{ aps: { alert: { title, body }, sound: "default", "thread-id": kind }, link, id }`; `fetchPayload(n: { id })` →
  `{ aps: { "content-available": 1 }, fetch: "plan", id }` (push type `background`, priority 5); `sendDue(deps: { outbox:
  OutboxDb; pusher: Pusher; clock }, limit = 200): Promise<{ sent: number; failed: number; retired: number }>`; `OutboxDb`
  = `{ due(now, limit), tokens(user), mark(id, state, apns), retire(tokenId) }` over 0038's functions.
- `retire` is true for 410 (any reason) and for 400 `BadDeviceToken` or `DeviceTokenNotForTopic`; a 429 or 5xx is
  `failed` for this minute's row and not retried (a reminder is late or not at all; the ledger names it).

- [ ] **Step 1: the failing tests.**

```ts
test("apns: a 410 retires the token and the other token still receives", async () => {
  const pusher = fakePusher({ "tok-old": { ok: false, status: 410, reason: "Unregistered", retire: true } });
  const outbox = fakeOutbox([notif("n1", USER, "class")], { [USER]: [tok("t1", "tok-old"), tok("t2", "tok-new")] });
  const r = await sendDue({ outbox, pusher, clock: fakeClock("2026-11-02T11:00:00Z") });
  expect(r).toEqual({ sent: 1, failed: 0, retired: 1 });
  expect(outbox.retired).toEqual(["t1"]);
  expect(pusher.sent.map((p) => p.token)).toEqual(["tok-old", "tok-new"]);
  expect(outbox.marks).toEqual([{ id: "n1", state: "sent", apns: [{ token: "t1", status: 410 }, { token: "t2", apnsId: "a-tok-new" }] }]);
});

test("apns: a BadDeviceToken retires it too; a 503 fails the row without retiring", async () => {
  const bad = await sendDue({ outbox: fakeOutbox([notif("n1", USER, "class")], { [USER]: [tok("t1", "tok-bad")] }),
    pusher: fakePusher({ "tok-bad": { ok: false, status: 400, reason: "BadDeviceToken", retire: true } }), clock: CLOCK });
  expect(bad).toEqual({ sent: 0, failed: 1, retired: 1 });
  const busy = fakeOutbox([notif("n2", USER, "class")], { [USER]: [tok("t2", "tok-busy")] });
  expect(await sendDue({ outbox: busy, pusher: fakePusher({ "tok-busy": { ok: false, status: 503, reason: "ServiceUnavailable", retire: false } }), clock: CLOCK }))
    .toEqual({ sent: 0, failed: 1, retired: 0 });
  expect(busy.retired).toEqual([]);
});
test("a user with no live token: the row is failed with reason no_token", async () => {
  const outbox = fakeOutbox([notif("n1", USER, "fees")], { [USER]: [] });
  await sendDue({ outbox, pusher: fakePusher({}), clock: CLOCK });
  expect(outbox.marks).toEqual([{ id: "n1", state: "failed", apns: { reason: "no_token" } }]);
});
test("the payloads carry the words, the link and an opaque id, never more", () => {
  expect(alertPayload({ id: "n1", kind: "plan_ready", title: "Evening batch: today’s plan is ready", body: "17:00–18:30 · 3 groups. Tap to see it.", link: "tutorcentral://today" }))
    .toEqual({ aps: { alert: { title: "Evening batch: today’s plan is ready", body: "17:00–18:30 · 3 groups. Tap to see it." }, sound: "default", "thread-id": "plan_ready" }, link: "tutorcentral://today", id: "n1" });
  expect(fetchPayload({ id: "n2" })).toEqual({ aps: { "content-available": 1 }, fetch: "plan", id: "n2" });
});
test("the tick sends what is due before it drains, and answers both", async () => { /* jobs-routes with a fake pusher */ });
```

  `apns.test.ts` also proves `makeApnsPusher` maps `@parse/node-apn`'s `{ sent, failed: [{ status, response: { reason } }] }`
  to `PushAnswer` (the provider stubbed by injecting a `send` function; no network in tests).
- [ ] **Step 2: RED. Step 3:** `bun add --exact @parse/node-apn@8.1.0` in `api/` (Bun only, D16); the modules; the tick
  calls `sendDue` and logs its counts in the JSON line. **Step 4: GREEN**, `bun run check`; the local stack's
  `platform-db.test.ts` gains one case: `due_notifications` → `sendDue` with the fake pusher marks the row `sent`.
- [ ] **Step 5: the real push, once, by hand** (after Task 1's key is in `api/.env.local`): the simulator's sandbox token
  is not available until PR 16, so this step is the hand run 1 of Task 24; here `bun run check` is the gate.
- [ ] **Step 6: commit, PR 9, merge.**

---

### Task 11: The reminder rules in TypeScript; the `reminder_sweep` job (PR 10)

**Files:**
- Create: `api/src/reminders/planner.ts`, `api/src/reminders/settings.ts`, `api/src/jobs/kinds/reminder-sweep.ts`,
  `api/test/reminder-cases.test.ts`, `api/test/reminder-sweep.test.ts`
- Modify: `api/src/jobs/kinds/index.ts`, `api/src/jobs/record.ts` (the reads: classes with members and times, the next
  26 hours' events, this month's due fees, each member's settings and live tokens)

**Interfaces:**
- Produces: `planReminders(input: ReminderInput, now: string): Reminder[]` (`ReminderPlanner.plan`: 14 days ahead, at most
  60, soonest first; the words of P7-Notifications and the board's notes); `notificationsFor(reminders, settings, user,
  window = 26 h): NotificationRow[]` (kinds `class`, `event`, `fees`; keys `class:<class>:<at>`, `event:<id>:<at>`,
  `fees:<yyyy-mm>`; the link as the phone's); the job `reminderSweep(source)`: one step, `plan`, which for each member of
  the job's centre with a live token writes `replace_notifications(centre, user, ['class','event','fees'], now, rows)`
  and finishes `{users, rows}`.

- [ ] **Step 1: the failing tests.** `reminder-cases.test.ts` as Task 9's shape over `reminder-cases.json`. `reminder-sweep`:

```ts
test("a replan cancels the unsent row of a moved class and writes its new one", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [USER] });
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  src.classes[0].start = "17:30";
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T16:00:00+05:30"));
  expect(src.replaced.at(-1)!.rows.map((r) => [r.key, r.due_at])).toContainEqual(["class:c1:2026-11-02T17:30", "2026-11-02T16:30:00+05:30"]);
  expect(src.replaced.at(-1)!.rows.map((r) => r.key)).not.toContain("class:c1:2026-11-02T17:00");
});
test("the tutor's settings decide: classes off writes no class rows; 15 minutes moves them", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [USER], settings: { [USER]: { classOn: false } } });
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  expect(src.replaced.at(-1)!.rows.filter((r) => r.kind === "class")).toEqual([]);
  src.settings[USER] = { classOn: true, classMinutes: 15 };
  await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:01:00+05:30"));
  expect(src.replaced.at(-1)!.rows.find((r) => r.kind === "class")!.due_at).toBe("2026-11-02T16:45:00+05:30");
});
test("a member without a live token gets nothing; the job is done with users 0", async () => {
  const src = fakeReminderSource({ classes: [cls("c1", "Class 10 Maths", [1], "17:00")], users: [], settings: {} });
  const out = await run(reminderSweep(src), jobFor(CENTRE), at("2026-11-02T10:00:00+05:30"));
  expect(out).toMatchObject({ kind: "done", result: { users: 0, rows: 0 } });
  expect(src.replaced).toEqual([]);
});
```

- [ ] **Step 2: RED. Step 3: the port and the job. Step 4: GREEN**, `bun run check`; one local-stack case in
  `platform-db.test.ts`: a centre with a token and a class today gets its class row in `notifications`.
- [ ] **Step 5: commit, PR 10, merge.**

---

### Task 12: The `plan` job makes its material, plans exam weeks and holidays, and says it is ready (PR 11)

**Files:**
- Create: `api/src/plan/material.ts`
- Modify: `api/src/jobs/kinds/plan.ts`, `api/src/jobs/record.ts` (`readForBudget`, `keep`, `link`, `mockFor`,
  `plannedMembers`, `replacePlan`), `api/test/plan-job.test.ts`, `api/test/platform-db.test.ts`

**Interfaces:**
- Consumes: `budget`, `examDays`, `revisionLines` (Task 9), `makeRequest`, `recordedCall` with `key` (Task 8), 0037's input
  shape, 0038's `replace_notifications` through `push/db.ts`.
- Produces: the job's steps `read` → `groups` → `name` → `write` → `budget` → `make:<n>`… → `notify`; its result `{plan_id,
  made: n, not_made: m, cost_paise}` or `{plan_id: null, reason: "closed"|"no_members"|"holiday"|"made"}`;
  `materialInput(req: MaterialRequest, record, draft): MakeInput` (the body `PlanMaker+Calls` sent for that request);
  `RecordSource.keep(centre, artefact, planId, groupNo, studentId, itemKind, schoolItemId, key): Promise<string>` over
  `keep_artefact`'s nine parameters; `mockFor(centre, item): Promise<string | null>`; the two notifications per member with
  Plan ready on: `plan_ready:<class>:<date>` (title `<batch>: today’s plan is ready`, body `<start>–<end> · <n> groups. Tap
  to see it.`, link `tutorcentral://today`) and `plan_fetch:<class>:<date>` (background, every member with a token, whatever
  the setting).

- [ ] **Step 1: the failing tests** (`plan-job.test.ts`, the fake source and fake claude of Phase 17):

```ts
test("after the write, the budget's requests are made one a step, kept and linked; the job ends by notifying", async () => {
  const src = source(read({ /* two members, a named group */ }));
  const outcomes = await drainAll(planJob(src), job({ class_id: CLASS, date: DAY }));
  expect(outcomes.map((o) => o.name)).toEqual(["read", "groups", "name", "write", "budget", "make:0", "make:1", "make:2", "make:3", "notify"]);
  expect(src.kept.map((k) => [k.kind, k.key])).toEqual([["check", `${JOB}:make:0`], ["sheet", `${JOB}:make:1`], ["sheet", `${JOB}:make:2`], ["worked_example", `${JOB}:make:3`]]);
  expect(src.notified.map((n) => n.key)).toEqual([`plan_ready:${CLASS}:${DAY}`, `plan_fetch:${CLASS}:${DAY}`]);
});

test("a material step retaken after its call keeps once and pays once", async () => {
  const claude = fakeClaude();
  const src = source(read(), { failKeepOnce: true });
  await drainAll(planJob(src), job(), { claude });
  expect(claude.calls.filter((c) => c.kind === "check")).toHaveLength(1);     // the retake replayed the key
  expect(src.kept.filter((k) => k.kind === "check")).toHaveLength(1);
});

test("a failed call leaves its mark not made and the job goes on", async () => { /* claude refuses make:1 */ });

test("two plan jobs on the mock day share one mock call and one artefact", async () => {
  const src = source(read({ items: [exam("unit-3", "2026-11-06", { arrivedOn: "2026-10-23" })], members: [dev(), meher()] }));
  await Promise.all([drainAll(planJob(src), job({ class_id: CLASS, date: "2026-11-04" })), drainAll(planJob(src), job({ class_id: CLASS2, date: "2026-11-04" }))]);
  expect(claudeCalls("mock")).toBe(1);
  expect(src.kept.filter((k) => k.kind === "mock")).toHaveLength(1);
  expect(src.links.filter((l) => l.kind === "mock")).toHaveLength(2);
});

test("an exam week is planned on the server: revision lines, no exam_mode", async () => { /* the seed's Science unit test */ });
test("a holiday covering the whole batch ends the job done with reason holiday", async () => {
  const src = source(read({ items: [holiday("2026-11-01", "2026-11-08")] }));
  const out = await drainAll(planJob(src), job({ class_id: CLASS, date: "2026-11-04" }));
  expect(out.at(-1)).toMatchObject({ kind: "done", result: { plan_id: null, reason: "holiday" } });
  expect(src.made).toEqual([]);
});
test("a replacing job writes over an open plan, never a closed one", async () => { /* input.replace, closed: true */ });
test("Plan ready is not queued for a tutor who turned it off; the fetch still is", async () => { /* settings */ });
```

  The local-stack test (`platform-db.test.ts`, skipped when the stack is down): `run-job` on the seed's Class 10 Maths with
  `AI_FAKE`'s fake claude: the plan, its artefacts linked to lines (`plan_items.artefact_id`), each `artefacts.idempotency_key`
  `<job>:make:<n>`, two `notifications` rows per member with a token.
- [ ] **Step 2: RED. Step 3:** the steps, the exam inputs (`planInput` takes the revisions from `examDays` and
  `revisionLines`, the hints from `school.ts`, the holidays), the `exam_mode` return removed, the `replace` path (`make_plan`
  over an open plan; a closed plan is `done {reason: "closed"}`), the mock under `key: mock:<item>` for both the call and the
  keep. **Step 4: GREEN**, `bun run check`, `bun check --only=api,tools,db`.
- [ ] **Step 5: the real-model proof (local, about ₹4.5).** With the real key in `api/.env.local` and no `AI_FAKE`, `run-job`
  for the seed's Evening batch tomorrow: the ledger records each step, the calls (kinds, models, cost) and the job's cost.
- [ ] **Step 6: commit, PR 11, merge.**

---

### Task 13: The note week in TypeScript; the `note_day` job (PR 12)

**Files:**
- Create: `api/src/notes/week.ts`, `api/src/notes/record.ts`, `api/src/jobs/kinds/note-day.ts`, `api/test/note-cases.test.ts`,
  `api/test/note-day.test.ts`
- Modify: `api/src/jobs/kinds/index.ts`, `api/test/platform-db.test.ts`

**Interfaces:**
- Consumes: the note cases (Task 7), `makeRequest` for `note` and `can_do`, `recordedCall` with `student`, `keep`.
- Produces: `noteFacts(record, week)`, `noteTopic(facts, chapters, skills)`, `canDoFacts(chapters, skills, week)`,
  `isLadderNote(student, chapters)` (equal to Domain's on the cases); the job `noteDay(source)`: input `{class_id, date}`
  (every member with a parent's number and the batch's note day today) or `{student_id, week}` (one); steps `read` → one
  `note:<student>` per student (a recorded call with `student` and key `note:<student>:<week>`, the body `NoteRequest` as the
  phone's `NoteStore` builds it, the kept artefact under the same key) → `notify` (`notes_ready:<class>:<date>`, `<n> weekly
  notes are ready`, `For the note day. Read each as the parent will, then send.`, link `tutorcentral://today?note-day`;
  none for a one-student request). A student whose call the gate refuses for consent is recorded `held` (no cost) and the
  job goes on; one whose note for the week is already kept is skipped.

- [ ] **Step 1: the failing tests.** The cases test; and:

```ts
test("each consented student's note is made and kept; the job says the notes are ready", async () => { /* three members */ });
test("a student withdrawn mid-job is held, not paid", async () => {
  const db = fakeDb({ consent: { [RIYA]: false } });
  const out = await drainAll(noteDay(src), job({ class_id: CLASS, date: SUNDAY }), { db });
  expect(out.find((o) => o.name === `note:${RIYA}`)).toMatchObject({ kind: "continue", step: expect.objectContaining({ held: [RIYA] }) });
  expect(db.finished.filter((f) => f.student === RIYA)).toHaveLength(0);
});
test("a note already kept for the week is not made again", async () => { /* keep exists */ });
test("a one-student request makes that note and notifies no one", async () => { /* input {student_id, week} */ });
```

- [ ] **Step 2: RED. Step 3: the port and the job. Step 4: GREEN**, `bun run check`; the local stack: `request_note` for the
  seed's Aarav, the job's note in `artefacts` with the key. **Real-model proof (about ₹0.3):** the seed's Evening batch note
  day with three consented students; the ledger records the notes' languages and costs.
- [ ] **Step 5: commit, PR 12, merge.**

---

### Task 14: Typst with the fonts; the `pdf` job for sheets, mocks and briefs; `/jobs/health` (PR 13)

**Files:**
- Create: `api/src/pdf/render.ts`, `api/src/pdf/typst.ts`, `api/src/pdf/sheet.ts`, `api/src/pdf/mock.ts`, `api/src/pdf/brief.ts`,
  `api/src/jobs/kinds/pdf.ts`, `api/fonts/NotoSans-Regular.ttf`, `NotoSans-Bold.ttf`, `NotoSansDevanagari-Regular.ttf`,
  `NotoSansKannada-Regular.ttf`, `api/fonts/OFL.txt`, `api/test/pdf.test.ts`, `api/test/pdf-job.test.ts`
- Modify: `api/package.json` (`"@myriaddreamin/typst-ts-node-compiler": "0.7.0"`), `bun.lock`, `api/vercel.json`
  (`"includeFiles": "fonts/**"` under `functions["**/*"]`), `api/src/routes/jobs.ts` (`GET /jobs/health`), `api/src/index.ts`
  (the Storage client: the service role's `storage.from(bucket).upload`), `.github/workflows/deploy.yml` (the check),
  `tools/smoke.ts`, `tools/smoke.test.ts`, `tools/check/steps.ts` (`api` inputs gain `fonts/**`)

**Interfaces:**
- Produces: `renderPdf(source: string): Promise<{ bytes: Uint8Array; pages: number }>` (one `NodeCompiler` per process,
  made with `fontArgs: [{ fontPaths: [<api>/fonts] }]`, no system fonts); `esc(text)` (Typst markup escaping: a backslash before each of the characters that start markup, backslash,
  hash, dollar, star, underscore, backtick, angle brackets, at sign and square brackets); `sheetPdf(content: SheetContent, meta)`, `mockPdf(content: MockContent, meta, withKey)`,
  `briefPdf(content, meta)` → Typst source, A4, the layout of the phone's `PDFMaker` for that kind (heading, the class and
  skill line, numbered questions with space to write, the key on its own page where the phone has it); the job `pdfJob(src)`
  input `{artefact_id}`: steps `render` → `upload` (`pdfs/<centre>/<artefact>.pdf`, `upsert: true`) → done `{path, pages,
  bytes}`; `GET /jobs/health` (bearer) → `{ pdf: pages, apns: true }`.

- [ ] **Step 1: the failing tests.**

```ts
test("a sheet renders as an A4 PDF with its questions", async () => {
  const { bytes, pages } = await renderPdf(sheetPdf(SHEET, { title: "Balancing equations · Set 1", line: "Class 8 Science" }));
  expect(new TextDecoder("latin1").decode(bytes.slice(0, 5))).toBe("%PDF-");
  expect(pages).toBe(1);
});
test("Devanagari and Kannada shape with the bundled fonts", async () => {
  const { bytes } = await renderPdf(`#set text(font: ("Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"))\nनमस्ते, ಹೆಮಂತ್`);
  expect(fontsIn(bytes)).toEqual(expect.arrayContaining(["NotoSansDevanagari", "NotoSansKannada"]));
});
test("markup in a question is text, not Typst", async () => {
  const src = sheetPdf({ ...SHEET, questions: [{ text: "Find #x when $2x = 4$ [hint]" }] }, META);
  expect(src).toContain("Find \\#x when \\$2x = 4\\$ \\[hint\\]");
});
test("the pdf job renders and uploads under the centre, and is done with the pages", async () => { /* fake storage */ });
test("/jobs/health renders one page and answers apns true behind the bearer", async () => { /* fake pusher */ });
```

- [ ] **Step 2: RED. Step 3:** `bun add --exact @myriaddreamin/typst-ts-node-compiler@0.7.0`; the fonts from
  github.com/notofonts (the `NotoSans`, `NotoSansDevanagari` and `NotoSansKannada` releases, hinted TTF), their OFL beside
  them; the modules. `deploy.yml`'s "The function's time" step also fails a build whose `.vercel/output/functions/*.func`
  holds no `typst-ts-node-compiler-linux-x64-gnu` `.node` file or no `fonts/NotoSans-Regular.ttf`; `tools/smoke.ts` gets
  `/jobs/health` with `WORKER_SECRET` and checks `pdf >= 1` and `apns === true`.
- [ ] **Step 4: GREEN**, `bun run check`, `bun check --only=api,tools`; a local `vercel build` (the Phase 17 Task 9
  practice) shows the module and the fonts in the output (the ledger records the output's size).
- [ ] **Step 5: pictures.** Page 1 of a sheet, a mock (with and without the key) and a brief, rendered by `sips -s format
  png` from the job's files on the local stack, beside the phone's PDF of the same artefact; in the PR by `bun pr-shots`.
- [ ] **Step 6: commit, PR 13, merge.**

---

### Task 15: The `export` job (PR 14)

**Files:**
- Create: `api/src/export/record.ts`, `api/src/pdf/export.ts`, `api/src/jobs/kinds/export.ts`, `api/test/export-job.test.ts`
- Modify: `api/src/jobs/kinds/index.ts`, `api/test/platform-db.test.ts`

**Interfaces:**
- Produces: `readStudentRecord(centre, student): Promise<StudentRecord>` (the student with class, school, board, batch,
  joined, the parent's name, number and language, the fee; `consent_events`; attendance sessions and marks; `fee_invoices`;
  chapters and skills with states; checks; school marks; homework; `message_log` (day, kind, channel); `artefacts` of kinds
  `note` and `can_do` for the student and `ai_generations` with `student_id` and status `ok` (day, kind, output's words));
  `exportPdf(record, centre: { name; tutor; phone }, asOf)` → Typst (P18-Export-File's sections in its order, each as label and
  value rows, "Page n of m" in the foot, nothing the record does not hold); the job `exportJob(src)` input `{student_id}`:
  `read` → `render` → `upload` (`exports/<centre>/<student>/<job>.pdf`) → done `{path, pages, bytes, made_at}`.

- [ ] **Step 1: the failing tests.**

```ts
test("the export renders a Hindi message and pages", async () => {
  const rec = record({ notes: Array.from({ length: 30 }, (_, i) => note(`2026-0${(i % 9) + 1}-04`, "hi", "हेमंत ने इस हफ्ते भिन्न सीखे।")) });
  const { pages } = await renderPdf(exportPdf(rec, CENTRE_META, "2026-10-13"));
  expect(pages).toBeGreaterThan(1);
});
test("the file holds each section the record has and none it does not", async () => {
  const src = exportPdf(record({ marks: [] }), CENTRE_META, "2026-10-13");
  for (const s of ["About him", "Consent", "Attendance", "Fees", "His record", "Messages to his parent", "Made about him"]) expect(src).toContain(s);
  expect(src).not.toContain("School marks");
});
test("the export job uploads under the centre and the student and is done with its path", async () => { /* fake storage */ });
test("a student of another centre is never read: the job's centre names every query", async () => { /* source records the centre per call */ });
```

  The pronoun follows the student's `gender` as the app's words do (`him`, `her`, or the name when unset).
- [ ] **Step 2: RED. Step 3: the reader, the template, the job. Step 4: GREEN**; the local stack: `request_export` for the
  seed's Hemanth, the PDF downloaded, pages 1 and 3 rendered to PNG and looked at (Devanagari shaped). **Step 5:** pictures
  of the pages in the PR; commit, PR 14, merge.

---

### Task 16: The sweep: Storage's deletions and the retention (PR 15)

**Files:**
- Modify: `api/src/jobs/kinds/sweep.ts`, `api/src/jobs/db.ts` (`takeStorageDeletions`, `removeObjects`, `removePrefix`,
  `trimOld`), `api/test/sweep.test.ts`, `api/test/platform-db.test.ts`

**Interfaces:**
- Produces: the sweep's steps `pending` (Phase 17) → `storage` (take up to 100 rows; a path is removed; a prefix is listed
  page by page and removed; a missing object counts as removed) → `retention` (exports older than 7 days by their object's
  `created_at`; `notifications` older than 30 days; done `reminder_sweep` and `sweep` jobs older than 7 days with their
  steps) → done `{closed, removed, trimmed}`.

- [ ] **Step 1: the failing tests**: a photo path and a prefix taken and removed through a fake storage; an object already
  gone counts and the row is deleted; an export of 8 days removed, one of 6 kept; the local stack: delete the seed's student
  with a marks photo uploaded, run the sweep, the object is gone (`storage.objects` has no row).
- [ ] **Step 2: RED. Step 3: the steps. Step 4: GREEN**, `bun check --only=api,tools,db`. **Step 5: commit, PR 15, merge.**

- [ ] **Deploy 1** (main): Task 1 done (the four `APNS_*` names on Vercel). `gh workflow run deploy`; the run's summary:
  0036 to 0040 applied, nothing pending; the function's time, the Typst module and the fonts checked; the smoke's check, tick
  and `/jobs/health` (`pdf 1, apns true`). After: `cron.job` holds the three new schedules; at the next quarter hour
  `schedule_plans` ran (`cron.job_run_details` succeeded); the owner's centre gets its plan job for the next meeting day at
  05:30 (if he opened the app in 14 days), and the ledger records the job, its steps and its cost the next morning; no
  notification is sent (no token yet); `storage.buckets` holds `exports` and `pdfs`.

---

### Task 17: The app: the device token, the settings on the account, the Reminders screen; the scheduler and the refresh retired (PR 16)

**Files:**
- Create: `Data/Push/DeviceTokenRepository.swift` (+ `Supabase…`, `Fake…`), `Data/Push/PushRegistrar.swift`,
  `Data/Notifications/ReminderSettingsRepository.swift` (+ `Supabase…`, `Fake…`), `Data/Notifications/ReminderSettingsMigration.swift`;
  tests `DataTests/PushRegistrarTests.swift`, `ReminderSettingsMigrationTests.swift`, `AppShellTests/PushTapTests.swift`
- Modify: `App/TutorCentral.entitlements` (`aps-environment` = `$(APS_ENVIRONMENT)`), `ios/project.yml` (`APS_ENVIRONMENT`:
  `development` for Debug, `production` for Release; `PUSH_ENVIRONMENT` `sandbox`/`production` into Info.plist),
  `App/Info.plist` (`UIBackgroundModes` = `remote-notification`; `BGTaskSchedulerPermittedIdentifiers` removed),
  `AppShell/AppDelegate.swift` (`didRegisterForRemoteNotificationsWithDeviceToken`, the failure, the background push),
  `AppShell/RootView.swift` and `+Reminders` (registration after sign-in when allowed; the wipe removes the token row first),
  `Features/Settings/Reminders/RemindersView.swift`, `RemindersStore.swift` (P18-Reminders), `Data/Cache/Wipe.swift`
- Remove: `AppShell/ReminderScheduler.swift`, `Data/Refresh/BackgroundRefresh.swift`, `Domain/Reminders/ReminderPlanner.swift`
  (and its tests: the reminder cases now hold the rules, Task 7), `Data/Notifications/ReminderSettingsStore.swift`, the
  scheduling half of `UNClient` (the permission and `removeAll` stay)

**Interfaces:**
- Produces: `PushRegistrar` (`@MainActor`): `register(centre:)` asks `UIApplication.registerForRemoteNotifications()` when
  the permission is `.authorized`; `received(token: Data)` hex-encodes and upserts `{user_id, device_id, token, environment,
  app_build, last_seen_at}` on `(user_id, device_id)`; `forget()` deletes this device's row (sign-out, deletion: before the
  wipe, D40). `ReminderSettingsRepository`: `read(centre) async throws -> ReminderSettings` (defaults when no row),
  `save(_:centre:) async throws`. `ReminderSettingsMigration.run(defaults:repository:notifications:)`: once per install,
  when the old `reminders` key exists, saves its values to the server, removes the key and every pending local reminder.
  `ReminderSettings` gains `planReady: Bool`, `notesReady: Bool`.

- [ ] **Step 1: the failing tests.** `PushRegistrarTests`: a token received is upserted hex-encoded with the environment
  from the bundle and the build; registration is not asked while the permission is not determined or denied; `forget()`
  deletes before `Wipe.everything` runs (the shell's order, through a recorder). `ReminderSettingsMigrationTests`: the old
  key's values (15 minutes, events a day before, fees on the 10th) reach the repository and the key is gone; a second run does
  nothing; a failed save keeps the key for the next launch. `RemindersStoreTests` (rewritten): the screen reads the server's
  settings, saves each switch and picker, shows "Plan ready" and "Notes ready" on by default, and has no Refresh.
  `PushTapTests`: a remote payload's `link` opens through `RootView.openLink` as a local reminder's does; a payload with no
  link opens Today.
- [ ] **Step 2: RED** (compile failures with the sources set aside count, Phase 17's practice). **Step 3:** the code; the
  board's screen (P18-Reminders: the groups as Phase 7 drew them, "Plans and notes", the footnote; "On this iPhone" gone).
- [ ] **Step 4: GREEN**: `bun check --only=format,lint,ios`. **Step 5: pictures**: `bun shots reminders` (both appearances),
  and the states the screen's changes touch; the hand run's push on the simulator (Task 24, run 1) is added to the PR when it
  runs. **Step 6: commit, PR 16, merge.**

---

### Task 18: The app: Today reads the plan's job; asks for a plan; the background fetch; `PlanMaker` retired (PR 17)

**Files:**
- Create: `Data/Jobs/JobsRepository.swift` (+ `Supabase…`, `Fake…`), `AppShell/PlanFetch.swift`; tests
  `TodayTests/PlanStoreJobTests.swift`, `AppShellTests/PlanFetchTests.swift`, `DataTests/JobsRepositoryTests.swift`
- Modify: `Features/Today/PlanStore.swift`, `PlanStore+Change.swift`, `PlanSections.swift`, `TodayStore.swift`,
  `TodayStore+Hero.swift` (the no-batch words), `AppShell/AppDelegate.swift` (the fetch), `AppShell/LaunchState.swift`
  (`todayPlanMaking = "today-plan-making"`), `RootView+LaunchStates.swift`, `Fixtures+Plan.swift`
- Remove: `Features/Today/PlanMaker.swift`, `PlanMaker+Calls.swift`, `PlanMaker+Exam.swift`, `PlanMaker+FirstChecks.swift`,
  `AppShell/RefreshHandler.swift` and their tests; Domain's plan rules and budget if nothing else uses them (decision 23)

**Interfaces:**
- Consumes: `request_plan`, `cancel_job` (Task 3); the plan job's result and `jobs` rows (`kind = 'plan'`, `input.class_id`,
  `input.date`).
- Produces: `JobsRepository`: `planJob(centre:classID:date:) async throws -> JobState?` (the newest plan job for the batch
  and day: `.live(startedAt:)`, `.done`, `.failed`, `.cancelled`), `requestPlan(centre:classID:date:choices:) async throws ->
  UUID`, `cancel(centre:job:) async throws`, `exportJob(centre:student:)`, `requestExport(centre:student:)`,
  `requestNote(centre:student:week:)`; `PlanStore` states as decision 18, the line "Made at <time>, before the batch. The
  sheets and checks are still being made; each mark turns green when it is ready." while the job is live; `PlanFetch.run(
  centre:) async -> Bool` (today's plans into `PlanCache`, every batch, within the time it is given).

- [ ] **Step 1: the failing tests** (`PlanStoreJobTests`, with fake plans and jobs repositories and a fake clock):

```swift
@Test func aPlanWithALiveJobShowsItsMarksOnTheirWayAndTheLine() async {
    let store = PlanStore.test(plan: .fixture(made: ["set"]), job: .live(startedAt: .at("06:00")))
    await store.load()
    #expect(store.state == .planning(.fixture(made: ["set"])))
    #expect(store.madeLine == "Made at 06:00, before the batch. The sheets and checks are still being made; each mark turns green when it is ready.")
    #expect(store.cards[0].marks.map(\.state) == [.made, .onItsWay, .onItsWay, .onItsWay])
}

@Test func noPlanAndAFailedJobShowsTheFailedCardAndTryAgainAsksTheServer() async {
    let jobs = FakeJobsRepository(plan: .failed)
    let store = PlanStore.test(plan: nil, jobs: jobs)
    await store.load()
    #expect(store.state == .failed("Couldn't make today's plan. Try again in a minute."))
    await store.tryAgain()
    #expect(jobs.requested == [.plan(classID: .evening, date: .today, choices: nil)])
}

@Test func noPlanAndNoJobBeforeTheBatchAsksForOneAndShowsPlanning() async { /* a batch added today */ }
@Test func cancelOnThePlanningCardCancelsTheJob() async { /* jobs.cancelled == [job] */ }
@Test func makeThePlanAgainSendsTheChoicesAndWaits() async { /* PlanStore+Change.useToday → requestPlan(choices:) */ }
@Test func aSchoolItemChangeAsksForAReplacingPlanForADayNotClosed() async { /* remake(for:) */ }
@Test func whileTheJobIsLiveTheStoreReadsAgainEveryTenSeconds() async { /* the fake clock advances; two reads */ }
@Test func offlineTheCopyStays() async { /* the copy shown, the read fails, state .made with savedAt */ }
@Test func theStoreNeverCallsTheAI() async { /* a FakeAIRepository that records: zero calls through every path */ }
```

  `PlanFetchTests`: `theFetchReadsTodaysPlansIntoTheCopyAndCallsBackOnce` (two batches, both kept, `true`), `aFailedReadCallsBackFalse`,
  `signedOutTheFetchDoesNothing`.
- [ ] **Step 2: RED. Step 3:** the store, the sections (the line under "Today's plan" while live; the failed card's words;
  the no-batch hero's "its plan is ready before the batch on <day>"), the background push handler calling `PlanFetch` with
  iOS's completion, the retirements. `ErrorWordsTests` passes on the new sentences.
- [ ] **Step 4: GREEN**: `bun check --only=format,lint,ios`. **Step 5: pictures**: `today-plan-making` (dark, light),
  `today-planning`, the failed card (a launch state `today-plan-failed` if none exists: it is the Phase 12 card with the
  new words, so the PR names it), `today-no-batch`. **Step 6: commit, PR 17, merge.**

---

### Task 19: The app: the note day's notes from the job (PR 18)

**Files:**
- Modify: `Features/Artefacts/NoteStore+Make.swift` (`load` shows the copy, then the server's kept note, else asks
  `requestNote` and shows its `writing` stage while it reads again every 5 seconds, up to two minutes), `NoteStore.swift`;
  tests `ArtefactsTests/NoteStoreJobTests.swift`
- Keep: `writeAgain` (a tap, its fresh key); `NoteDayStore` (reads only, unchanged)

**Interfaces:**
- Consumes: `JobsRepository.requestNote` (Task 18), the job's kept artefact (key `note:<student>:<week>`).

- [ ] **Step 1: the failing tests**: `aKeptNoteOpensWithNoCall` (the fake AI records zero calls), `aMissingNoteIsAskedOfTheServerAndShowsMaking`,
  `theAskedNoteAppearsWhenTheJobKeepsIt` (the fake plans repository answers the note on the second read), `twoMinutesWithoutItShowTheTimedOutWords`
  (the note's `.failed` stage with `APIFailure.timedOut`'s existing words; no new sentence),
  `aStudentWithoutConsentIsNotAsked` (Held, as today), `writeAgainStillCallsWithAFreshKey`.
- [ ] **Step 2: RED. Step 3: the code. Step 4: GREEN**: `bun check --only=format,lint,ios`. **Step 5: pictures**: the note's
  making state and `today-note-day` (unchanged in look; the PR says so). **Step 6: commit, PR 18, merge.**

---

### Task 20: The app: Parent withdrew, the withdrawal sheet, the page withdrawn with its history (PR 19)

**Files:**
- Create: `Features/Students/ConsentWithdrawSheet.swift`, `Data/Consent/ConsentHistoryRepository.swift` (+ `Supabase…`,
  `Fake…`), `DesignSystem/Components/ConsentHistory.swift`; tests `StudentsTests/ConsentWithdrawTests.swift`
- Modify: `Features/Students/ConsentStore.swift` (`withdraw(how:on:)`, `history`, the withdrawn state; `remove()` gone),
  `ConsentSection.swift`, `ConsentRecordSheet.swift` (Parent withdrew in Remove's place, the helper's words),
  `StudentDetailView.swift` (consent under the parent when withdrawn), `Data/Students/StudentsRepository.swift`
  (`withdrawConsent`), `AppShell/LaunchState.swift` (`studentConsentChange`, `studentConsentWithdraw`, `studentWithdrawn`),
  `StudentDetailView+Board.swift`, `Fixtures+Record.swift`

**Interfaces:**
- Consumes: `withdraw_consent` (Task 2); `consent_events` (select by student, newest first).
- Produces: `ConsentStore.State.withdrawn(ConsentEvent)`; `ConsentEvent { kind: .given | .withdrawn, how: ConsentMethod?,
  on: Day, phone: String? }`; the sheet's words and the page's from "Phase 18 boards".

- [ ] **Step 1: the failing tests**: `withdrawingCallsTheServerWithHowAndTheDayAndShowsWithdrawn`, `theDayCannotBeBeforeTheAgreementOrAfterToday`
  (the picker's range), `theHistoryShowsNewestFirstOnlyBeyondTheFirstAgreement`, `withdrawnPutsConsentUnderTheParent`,
  `offlineTheWithdrawalIsRefusedWithTheConsentWordsAndTheSheetStays` (D39), `parentAgreedAfterAWithdrawalRecordsAGivenAgain`,
  `theRecordSheetOffersParentWithdrewNotRemove`, and the copy test: every new sentence is on the boards (`ErrorWordsTests`
  passes).
- [ ] **Step 2: RED. Step 3: the code. Step 4: GREEN**: `bun check --only=format,lint,ios`. **Step 5: pictures**:
  `student-consent-change`, `student-consent-withdraw`, `student-withdrawn` (dark and light). **Step 6: commit, PR 19, merge.**

---

### Task 21: The app: the Export section and Share; the server's PDFs for sheets, mocks and briefs (PR 20)

**Files:**
- Create: `Features/Students/ExportSection.swift`, `ExportStore.swift`, `Data/Files/ServerFiles.swift`; tests
  `StudentsTests/ExportStoreTests.swift`, `DataTests/ServerFilesTests.swift`, `ArtefactsTests/ServerPDFShareTests.swift`
- Modify: `StudentDetailView.swift` (the section after Notes, before Archive and Delete), `Features/Artefacts/SheetView.swift`,
  `SheetSections.swift`, `MockView.swift`, `BriefView.swift` (Share takes `ServerFiles`' file, else draws offline),
  `AppShell/LaunchState.swift` (`studentExport`, `studentExportMaking`, `studentExportReady`, `studentExportFailed`),
  `Data/Cache/Wipe.swift` (the files' folder)

**Interfaces:**
- Consumes: `request_export`, the export job's result `{path, pages, made_at}` (Task 15); `pdfs/<centre>/<artefact>.pdf`
  (Task 14).
- Produces: `ExportStore.State`: `.ask`, `.making(askedAt:)`, `.ready(madeAt:pages:path:)`, `.failed`; `.ready` older than
  7 days reads as `.ask`; while `.making`, a read every 5 seconds while the page is in front. `ServerFiles.file(bucket:path:)
  async throws -> URL` (downloads once into `Application Support/TutorCentral/files-<centre>/`, file protection as the copies,
  D40's wipe removes the folder); Share on a sheet, mock or brief: the server's file when it can be had, else the phone's
  drawing (decision 3).

- [ ] **Step 1: the failing tests**: `ExportStoreTests`: `makeTheFileAsksOnceAndShowsMaking`, `aDoneJobShowsReadyWithTheTimeAndPages`,
  `aFailedJobShowsTryAgainAndTryAgainAsksAgain`, `aFileOlderThanSevenDaysReadsAsTheAsk`, `offlineMakeTheFileIsRefusedWithTheConsentWords`,
  `shareDownloadsTheFileOnceAndHandsItOver`. `ServerFilesTests`: one download for two asks; the folder under the centre;
  the wipe removes it. `ServerPDFShareTests`: a sheet shares the server's file; offline without it, the phone's drawing.
- [ ] **Step 2: RED. Step 3: the code. Step 4: GREEN**: `bun check --only=format,lint,ios`. **Step 5: pictures**:
  `student-export`, `-making`, `-ready` (dark, light), `-failed`; the file's page 1 from the hand run. **Step 6: commit, PR 20,
  merge.**

---

### Task 22: The app: one copy-then-refresh path (U10, U27); the replay's reload (PR 21)

**Files:**
- Create: `Data/Cache/CopyFirst.swift`; tests `DataTests/CopyFirstTests.swift`, `AttendanceTests/AttendanceCopyFirstTests.swift`
- Modify: the twelve stores that read through `CachedRead` (`RegisterStore`, `TodayStore`, `TasksStore`, `PlanStore`,
  `FeesStore`, `SchoolStore`, `ReportsStore`, `HistoryStore`, `ScheduleStore`, `MakeStore`, `AIStore`, `AttendanceStore`),
  `Features/Attendance/AttendanceView.swift` (U10: the spinner by the date while a read runs; "Everyone starts present…"
  hidden beside an error line), `AppShell/RootView+Offline.swift` (a replay's end reloads the open attendance day)

**Interfaces:**
- Produces: `struct CopyFirst<Value: Codable & Sendable>` with `func load(show: @MainActor (Value, Date) -> Void, read:
  @Sendable () async throws -> Value) async -> CopyFirstOutcome` (`.fresh`, `.keptCopy(Error)`, `.nothing(Error)`): the copy
  is shown before `read` starts; a good read is shown and kept; a failed read keeps the copy shown. Each store's existing
  generation rule stays around it (a stale answer is dropped).

- [ ] **Step 1: the failing tests.** `CopyFirstTests`: the copy is shown before the read returns (the fake read waits on a
  continuation the test resumes after asserting); a good read replaces and keeps; a failed read keeps; nothing saved and a
  failure is `.nothing`. `AttendanceCopyFirstTests`: offline at launch the day's copy shows at once (U27); a slow read shows
  the spinner and no "Everyone starts present" beside an error (U10); after a queued replay the open day shows the replayed
  absences without a cold launch (Phase 17's hand run 3). One test per other store: its copy shows before its read returns
  (a shared helper drives the eleven).
- [ ] **Step 2: RED. Step 3:** `CopyFirst`, then each store in its own commit inside the PR. **Step 4: GREEN**: `bun check
  --only=format,lint,ios`. **Step 5: pictures**: `attendance` with the gateway stopped (the copy at once) and during a slow
  read (the spinner); both appearances. U10 and U27 move to `plan/ui-polish.md`'s "Done" with this PR. **Step 6: commit, PR 21,
  merge.**

---

### Task 23: `/trust` says what this phase keeps and removes (PR 22)

**Files:** `web/content/trust.ts`, `web/content/site.ts` (the trust page's "Last changed"), `web/test/unit/words.test.ts`
(unchanged rule)

- [ ] **Step 1:** the sentences, each checked against the code (the web rule): a parent can withdraw consent and the tutor
  records how and when, after which nothing about the student goes to the AI service; the tutor can make a file of
  everything kept about a student for the parent, removed from Tutor Central after seven days; notifications carry no
  student's name; a deleted student's photos are removed with them. **Step 2:** `bun check --only=web`, `bun web-shots
  --pages /trust`. **Step 3: pictures** (1280 and 390, dark and light), PR 22, merge. Deploy of the site by `gh workflow run
  deploy-web` after merge (D45), its smoke green.

---

### Task 24: The hand runs (D32), Deploy 2's checks, the cost record (main)

Against the local stack with the local API (`AI_FAKE=1` unless a run says real), by `docs/runbooks/simulator.md` (its waits;
every write confirmed in the database). Pictures and results on one issue, "Phase 18 hand run". The runbook gains "13. A push
to the simulator" (the iPhone 17 simulator on this Mac receives sandbox pushes from APNs with a real token: the local API with
`api/.env.local`'s `APNS_*`; `xcrun simctl push booted in.tutorcentral.app payload.json` for a payload alone).

- [ ] **Run 1, a reminder with the app closed:** sign in as the seed's tutor, allow notifications; `device_tokens` has the
  row (`sandbox`); set Evening batch to start in 20 minutes with the class lead at 15; quit the app (swipe it away); the
  reminder plan's job writes the row; at its minute the banner shows on the simulator's lock screen (screenshot); the row is
  `sent` with an `apns-id`.
- [ ] **Run 2, plan ready:** `run-job` for Evening batch today (the local `run-job` SQL, `docs/runbooks/simulator.md` 12): the job's steps to `notify`; the Plan ready alert
  arrives (screenshot); open Today: the line and the marks while material steps run (slow the fake to 5 s), then all made.
- [ ] **Run 3, an exam week on the server:** the seed's Science unit test week: revision lines, the mock made once for two
  batches (`ai_generations` one `mock` row; both plans' items link the same artefact).
- [ ] **Run 4, the note day:** the job for Evening batch: notes ready arrives; Read opens a kept note with no call (API log);
  a student given consent after the job: Read asks, making, the note appears.
- [ ] **Run 5, withdrawal:** Parent withdrew on Hemanth (a call, today): the event row with how; the columns null; his
  queued note request cancelled; a progress note for him refused (403 `student_consent`, the app's consent words); Parent
  agreed again: a `given` row; the history shows both.
- [ ] **Run 6, the export:** Make the file → making → ready; Share → Save to Files; the PDF opened (pages 1 and 3 in the
  issue); the API stopped → Try Again → failed card; restarted → ready; the object's `created_at` moved back 8 days by SQL,
  the sweep → gone, the section back to the ask.
- [ ] **Run 7, a deleted student's photos:** a marks photo for a throwaway student; delete the student; the sweep; the
  object gone from `storage.objects`.
- [ ] **Run 8, offline:** gateway stopped: Attendance shows its copy at once (U27); Today's plan from the copy; a sheet's
  server PDF shared offline (downloaded before); a sheet never opened before shares the phone's drawing.
- [ ] **Run 9, the settings move:** a build-27-shaped `reminders` key written into the app's defaults by
  `xcrun simctl spawn booted defaults write in.tutorcentral.app reminders …` before the new build's first launch: the
  server's row holds the values; the key and the local pending reminders are gone (`getPendingNotificationRequests` count 0
  in the log).
- [ ] **Run 10, beside build 27:** the build-27 app (`git worktree` at `e89927c`, its Debug build installed under another
  simulator) opens the day the job planned: no second plan, no material call (the API's log), its `Remove` writes a
  `withdrawn` event.
- [ ] **Real calls:** Task 12's plan job and Task 13's note day ran on the real models; the ledger sums them (below).
- [ ] **After Deploy 2** (Task 25): the owner's centre's morning job in production, read by `supabase db query --linked`
  (the steps, the made and not made, the cost); `notifications` empty for him until build 28 is installed (D68: he tests at the
  end).

---

### Task 25: The review, Deploy 2, build 28, the documents (main)

- [ ] **The review** on Fable 5.1, two fresh reviewers as Phase 17's: (a) the app and tooling, (b) the database and the API,
  each given this plan, the boards and the diff from `c92393d`; every finding fixed with a test that failed first (D68), each
  in its own `phase-18/fix-<what>` pull request, the ledger's `Review` and `Fix` lines.
- [ ] **Deploy 2** (`gh workflow run deploy`): the review's fixes and any migration they add; the smoke green.
- [ ] **Build 28** (`gh workflow run testflight`): with push (the profile from the cloud signing has `aps-environment`
  production; the run's log shows the entitlement); on the internal group.
- [ ] **Device tests**: `docs/testing/device-tests.md` gains T16 (a reminder arrives on an iPhone that has not opened the app
  that day; Plan ready arrives before the batch and a tap opens Today) and T17 (the background fetch: the plan is on the
  iPhone in airplane mode after a Plan ready arrived), for the owner's end-of-V3 test (D68).
- [ ] **The rule files** (D80): `api/CLAUDE.md` (the kinds, push and its variables, Typst and the fonts, the outbox, what
  the tick does, `/jobs/health`), `ios/CLAUDE.md` (push, the retired parts, `CopyFirst`, the server PDFs, what stays a call
  from the phone), `supabase/CLAUDE.md` (the schedules, the requests, the buckets and the deletions, the outbox), `web/CLAUDE.md`
  if the trust page's rule changed.
- [ ] **The documents**: "As built" in `phase-18-server-work-and-push.md`; `plan/README.md` (Phase 18 built; D88 to D92 were
  written with the plan's approval); `STATE.md`; `plan/sessions/037/{record,owner-messages}.md`; the resume for Phase 19 if
  the owner asks.

## The cost

| What | Calls | About |
|---|---|---|
| Task 12's real plan job (the seed's Evening batch, two or three groups) | 12 to 20 (Haiku and Sonnet by `models.json`) | ₹4.5 (Phase 17's measure of the same material made by the phone: ₹4.43) |
| Task 13's real note day (three consented students) | 3 | ₹0.3 |
| The deploys' smokes (Phase 17's `check` each) | 2 | ₹0.02 |
| Production after Deploy 1: the owner's own centre's plan each day its batch meets, while he opened the app in 14 days (D91) | 12 to 20 a day | about ₹4.5 a day, as the phone spent on open; the ledger records the first two mornings |
| Hand runs 1 to 10 | none (the fake) | ₹0 |

Under ₹10 for the session's own runs; the production line is the product working as designed, recorded in the ledger.

## Self-review (done 2026-10-12)

1. **Scope coverage** (`phase-18-server-work-and-push.md`): jobs `plan` with material (Tasks 9, 12), `note_day` (13),
   `reminder_sweep` (11), `pdf` (14), `export` (15), `sweep` with Storage (6, 16); schedules by pg_cron (5); push: the
   token (17), `@parse/node-apn` pinned (10, D88), 410 retirement (10), the background push (12, 18), the runbook (24); the
   phone's retirements (17, 18, 21, decision 23); one data layer with U10 and U27 (22); DPDP on screen (20, 21) to the
   boards; the trust page (23). Acceptance: a reminder on a phone that did not open the app (run 1, T16); a plan before the
   batch with its material (run 2, the production morning); the note day's notes waiting (run 4); no AI call from the phone
   but at a tap (decision 14, `theStoreNeverCallsTheAI`, run 4's log); the export's contents (15, run 6); a withdrawal
   stops the personal kinds at once (2, run 5); a deleted student's photo gone (16, run 7); pictures (each app PR), hand runs
   (24), build 28 (25).
2. **Placeholders:** the test bodies left as one-line comments name exactly what they assert and against which fake; each is
   written in full in its task's Step 1 before Step 3 (the build's rule, as Phase 17's were).
3. **Names across tasks:** `request_plan`, `request_note`, `request_export` (3) → `JobsRepository` (18, 19, 21);
   `replace_notifications`, `due_notifications`, `mark_notification`, `live_tokens`, `retire_token` (4) → `push/db.ts` (10),
   the reminder sweep (11), the plan and note jobs' notify steps (12, 13); `makeRequest`, `recordedCall`'s `key`, `student`,
   `empty` (8) → 12, 13; `budget`, `examDays`, `revisionLines` (9) → 12; `renderPdf`, `esc` (14) → 15; `taken_storage_deletions`
   (6) → 16; the notification keys `plan_ready:<class>:<date>`, `plan_fetch:<class>:<date>`, `notes_ready:<class>:<date>`
   are the same in 12, 13 and the app's `PushTapTests`.
4. **Review focus:** eight lines, each with its test in its owning task.
