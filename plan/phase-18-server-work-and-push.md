# Phase 18: V3 the server's work and push

**Status:** Built (session 37, 2026-10-13) from `phase-18-plan.md` in #215 to #261 (hand runs #260); deployed (0036 to 0045, the worker, push and Typst live); 1.0.0 (29) on TestFlight. "As built" below. **Depends on:** Phase 17; the 14 boards of row 26 (approved 2026-10-12).
ready").

## As built (session 37, 2026-10-13)

Built from `plan/phase-18-plan.md` in pull requests #215 to #261; the hand runs are issue #260. Every ruling, hand run, fix and
review finding is in `plan/sessions/037/ledger.md`.

**The pull requests.** #215 to #220 migrations 0036 to 0040 (consent's withdrawal; the member requests; reminder settings and
the outbox; the schedules and change triggers; the buckets, the deletion queue and the PDF's job). #221 to #231 the API: the
shared case files, `makeRequest`, the budget, spaced queue and exam split ported, APNs, the reminder rules and
`reminder_sweep`, the `plan` job's material, exam weeks and pushes, the `note_day` job, Typst and the `pdf` job, the `export`
job, the sweep and 0041, the outbox's subject. #232 to #238 the app and web: push and the settings on the account, Today on
the server's plan (PlanMaker retired), the note from the job, withdrawal and its history, the Export section and the server's
PDFs, `CopyFirst`, `/trust`. #239 to #243 what the hand runs found (a step name over 40 characters, a dropped APNs stream, the
note's week, the copies offline) and #240 a lean local stack. #244 to #259 every finding of the two fresh reviews on Fable 5.1
(#251 a lint fix). #261 the TestFlight run prints the app's push entitlement and stops without it.

**What runs on the server.** pg_cron queues each batch's plan for the day (from 05:30 India time), each note day, and an hourly
reminder plan; a change to a class, event, fee or the settings queues the centre's reminder plan at once (0045: each change its
own). The worker (`/jobs/tick` each minute, `/jobs/wake` on a queue) runs `plan` (groups, names, the material as recorded calls,
exam weeks with one mock shared across batches, a replace on request, then Plan ready and the background fetch, keyed by the
job), `note_day` (one note per consented student, held otherwise; a note already kept is not made again; the week an ISO day),
`pdf` (Typst with the committed fonts), `export` (everything about a student, kept seven days), `reminder_sweep` and `sweep`
(pending calls closed, queued files removed under a lease (0044), retention). A plan job ends `not_meeting` for a day its batch
no longer meets.

**Push.** APNs by token key (D88); the outbox (`notifications`) is sent on the minute's tick; a token answering 410 is retired; a
dropped connection is tried once more. The tutor's choices are the account's (`reminder_settings`); build 27's local choices
move once, into an account that has none. A sign-out deletes the iPhone's row and unregisters it from APNs; a token another
tutor registered later on the same iPhone is theirs (0042).

**The app.** Today follows the server's plan (made, being made, failed, holiday) and the note day's notes; Change shows the
phone's rules before asking again. Consent can be withdrawn, with its history. A student's Export. Share takes the server's
PDF (the kept copy at once, else online within five seconds, else the phone's drawing: D93). Lists, Today's plans, the note day
and the material show what the iPhone has before any read answers. A background push fills today's plans within 25 seconds.

**Checked.** `bun check` green before every merge; hand runs 1 to 11 (#260); a plan job and a note day on the real models
(₹3.05); two fresh reviews (16 findings: 15 fixed with a test that failed first or by removing the failing path, one ruled
transitional); Deploy 1 (run 38282034144) and Deploy 2 (run 38311560782), each smoke green with a real check, the tick, a rendered
page and APNs; 1.0.0 (28) by run 38312753433 and (29) by run 38314213195, whose log shows the archive's `aps-environment`.

## Goal

The work the phone did for the platform runs on the server as jobs, and the platform reaches the phone through APNs. A tutor
notices only that plans are ready before the batch and that reminders arrive whether or not the app was opened.

## Scope

1. **The jobs** (D70, D71): `plan` (per batch per day, before the batch, the plan and its artefacts as steps, the budget and
   groups as today's Domain rules moved to TypeScript with their tests), `note_day` (the notes on the evening), `reminder_sweep`
   (class, fee, note day, "plan ready": the rules of `ReminderScheduler` moved and tested first), `pdf` (a sheet or mock to
   Storage under the centre; the app shares the file; printing from the phone keeps its path), `export` (the per-student
   export of D62 and D79 as a file the tutor shares), `sweep` (pending rows, Storage photos of deleted students and accounts).
2. **Schedules** (D71): pg_cron writes the day's jobs (the plan at the tutor's reminder time or 06:00 IST, the note day, the
   sweeps); a schedule runs no work itself.
3. **Push** (D72): the app registers for remote notifications and posts its device token; `device_tokens` retired on 410;
   the workers send with `@parse/node-apn` (pinned), the `.p8` on Vercel only (the owner's Apple step); alerts with plain words
   from `docs/design/feedback.md` and an opaque id; a background push when a plan is ready; the simulator runbook extended
   for a push.
4. **The phone's retirements** (D70): `PlanMaker` and its calls, `BackgroundRefresh`, `ReminderScheduler`, `PDFMaker`'s
   sharing path; the app shows a job's state and result (`PlanStore` reads the row); the copy and the four-write queue stay
   (D39, D40).
5. **One data layer** (D76): the stores share one copy-then-refresh path, so a copy shows at once and never only after a
   network read fails; U10 and U27 close with it.
6. **DPDP on screen** (D79): consent withdrawal recorded as an event and shown on the student's page; the export's state on the
   student's page; both to their boards (drawn and approved before the phase's plan).

## Acceptance

- A reminder arrives on a phone that has not opened the app that day; a plan is ready before the batch with its artefacts,
  made by a job; the note day's notes wait in the app.
- No AI call starts from the phone except the kinds made at a tap (a note's edit, Check a paper, a Make form).
- A student's export file holds their record, messages and outputs; a withdrawal stops the personal kinds at once.
- A photo of a deleted student is gone from Storage.
- Pictures for each changed state (D7); the hand runs (D32); a build on TestFlight.
