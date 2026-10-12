# Phase 18: V3 the server's work and push

**Status:** Not started. **Depends on:** Phase 17; boards for the states that change (consent withdrawal, the export, "plan
ready").

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
