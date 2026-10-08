# Resume prompts

One file per resumption the owner asks for, numbered `NNN-<slug>.md`. A resume prompt is a work order: which
phase and slice, what to read first, what is already true, what to do and what to show. It sends the session to
`STATE.md` and `SESSIONS.md`; it never repeats them.

| # | File | For |
|---|---|---|
| 001 | `001-phase-1-foundation.md` | Phase 1, foundation, executed natively on Opus 5.5 from `plan/phase-01-plan.md` |
| 002 | `002-phase-2-plan.md` | Phase 2 (shell, sign-in, onboarding, first TestFlight): write and approve `plan/phase-02-plan.md` on Fable 5.1, then resume 003 for the build |
| 003 | `003-phase-2-build.md` | Phase 2, the build: execute `plan/phase-02-plan.md` natively on Opus 5.5, nine pull requests, then the review |
| 004 | `004-phase-3-boards-and-plan.md` | Phase 3 (students and classes): Phase 0 step 0.4 (the Phase 3 boards) and `plan/phase-03-plan.md` on Fable 5.1, then resume 005 for the build |
| 005 | `005-phase-3-build.md` | Phase 3, the build: execute `plan/phase-03-plan.md` natively on Opus 5.5, eight pull requests, then the review |
| 006 | `006-simulator-runbook.md` | Issue #34: research how to drive the app in the Simulator against the local stack reliably, write the runbook, link it from `CLAUDE.md`, prove it end to end; Opus 5.5 |
| 007 | `007-phase-4-boards-and-plan.md` | Phase 4 (attendance, schedule, tasks, Today live): Phase 0 step 0.5 (the Phase 4 boards) and `plan/phase-04-plan.md` on Fable 5.1, then resume 008 for the build |
| 008 | `008-phase-4-build.md` | Phase 4, the build: execute `plan/phase-04-plan.md` natively on Opus 5.5, seven pull requests, the hand runs by the runbook, then the review |
| 009 | `009-phase-5-boards-and-plan.md` | Phase 5 (fees, UPI settings, reminders, receipts, reports): Phase 0 step 0.6 (the Phase 5 boards) and `plan/phase-05-plan.md` on Fable 5.1, then resume 010 for the build |
