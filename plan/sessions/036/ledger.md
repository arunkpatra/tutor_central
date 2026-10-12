# Session 36 ledger: Phase 18's boards and plan (from resume 034)

Setup: `main` clean at c92393d, no open PR, matches STATE.md (session 35's close); `bun check` all green (every step unchanged since its last green run, cached); local Supabase up.
Read: the five rule files, design README and feedback, STATE, SESSIONS, README (D1–D87), the phase 18 scope, spec-v3, phase 17 as built, session 35 record and ledger, session 34 record, phase-17-plan's form; three code surveys (API jobs and migrations; the phone's platform work; the student page, consent, polish, canvas).
Finding: the phone has no note-day reminder today, and reminder settings live only in the iPhone's UserDefaults; the Reminders screen's "On this iPhone · Refresh · set two weeks ahead" stops being true with push, so board set 3 adds the Reminders screen.
Finding: the "Remove" on an agreed consent already writes a `withdrawn` event (0032's trigger), with no how and no day; nothing reads `consent_events` yet.
Finding: `SpacedQueue` was never ported (phase-17-plan named `spaced.ts` and `hints.ts`; neither exists); Phase 18 ports it with `ArtefactBudget`.
Ruling: board sets drawn by a script in the scratchpad (lib.py), each rendered with headless Chrome at 2x and looked at before publishing; the canvas's row 26 at y 56600 (row 25's tallest board ends at 56167) — cost if wrong: none.
Ruling: withdrawal replaces Remove (a record made by mistake is withdrawn too; the history is honest) — cost if wrong: the owner asks for Remove back; one button.
Boards set 1 (consent withdrawn): P18-Consent-Change, P18-Consent-Withdraw, P18-Student-Withdrawn, -Light; published to the canvas (version 1791814443-5b65), shown to the owner.
Owner: set 1 approved ("Approved"); mirrored into docs/design/mockups and directions/canvas.json.
Boards set 2 (the export): P18-Export-Ask, -Making, -Ready, -Ready-Light, -Failed, -File (the PDF's page 1, A4); published (version 1791816178-5866).
Ruling: the export is a PDF for the parent (readable, shares on WhatsApp), on the page's foot above Archive and Delete, kept 7 days in Storage then swept — cost if wrong: a machine-readable copy is asked for later; a second file from the same job.
Owner: set 2 approved; "All your current and future design boards for this session are pre-approved." Mirrored.
Boards set 3 (plan ready): P18-Notification-PlanReady, P18-Today-Plan-Making, -Light, P18-Reminders; published (version 1791816272-3b36); pre-approved by the owner; mirrored.
Plan: `plan/phase-18-plan.md` written (25 tasks, 22 PRs, decisions 1–28, D88–D92 in README); self-review done (scope coverage, placeholders filled where bare, names across tasks, review focus).
Ruling: the plan job runs at 05:30 IST (or 2 h before a batch starting before 07:30, never before 03:30), so it is ahead of build 27's background refresh asked for 06:00 — cost if wrong: a morning's material made twice on the installed build, once.
Ruling: the tick sends the outbox optimistically (`due_notifications` marks rows sent as it hands them out) — cost if wrong: a crash mid-send loses that minute's pushes.
Ruling: no realtime subscription for a plan's job; the app reads every 10 s while a job is live and in front — cost if wrong: up to 10 s later than possible.
Resume 035 written and indexed; record, owner messages, STATE; documents to main (D12).
