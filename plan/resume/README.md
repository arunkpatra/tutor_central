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
| 010 | `010-phase-5-build.md` | Phase 5, the build: execute `plan/phase-05-plan.md` natively on Opus 5.5, six pull requests, the hand runs by the runbook, the owner's camera check, then the review |
| 011 | `011-phase-6-boards-and-plan.md` | Phase 6 (AI tools): Phase 0 step 0.7 (the Phase 6 boards) and `plan/phase-06-plan.md` on Fable 5.1, then resume 012 for the build |
| 012 | `012-phase-6-build.md` | Phase 6, the build: execute `plan/phase-06-plan.md` natively on Opus 5.5, six pull requests, the deploy with the owner's key, the hand runs by the runbook, the owner's phone checks, then the review |
| 013 | `013-phase-7-boards-and-plan.md` | Phase 7 (settings, account, notifications, offline, hardening, release candidate): Phase 0 step 0.8 (the Phase 7 boards) and `plan/phase-07-plan.md` on Fable 5.1, with the tester's device tests, then resume 014 for the build |
| 014 | `014-phase-7-build.md` | Phase 7, the build: execute `plan/phase-07-plan.md` natively on Opus 5.5, eight pull requests, the deploy with the Apple key, the hand runs by the runbook, the review, the release candidate on TestFlight and the owner's App Store Connect steps |
| 015 | `015-phase-8-boards-and-plan.md` | Phase 8 (the website, tutorcentral.in, Next.js on Vercel, D42): Phase 0 step 0.9 (the website's boards) and `plan/phase-08-plan.md` on Fable 5.1, then resume 016 for the build |
| 016 | `016-phase-8-build.md` | Phase 8, the build: execute `plan/phase-08-plan.md` natively on Opus 5.5, six pull requests, the owner's Vercel, GoDaddy and App Store Connect steps, the deploy and its smoke, the hand runs by the runbook, the TestFlight build with the polish slice |
| 017 | `017-phase-9-plan.md` | Phase 9 (user testing, D43): `plan/phase-09-plan.md` on Fable 5.1 (who tests and for how long, the external group, the tester's guide, the findings log and triage), then resume 018 for the run |
| 018 | `018-phase-9-run.md` | Phase 9, the run: execute `plan/phase-09-plan.md` on Opus 5.5 over the phase's weeks (the API deploy, the guide and findings file, the owner's App Store Connect steps, the tester's checks, the readings, the fix pull requests and Thursday builds, the close and the App Store submission); pasted at each session of the phase |
| 019 | `019-phase-10-boards.md` | Phase 10, Part A: the V2 boards on Fable 5.1, steps 10.1 to 10.7 of `plan/phase-10-plan.md`, each approved by the owner, published to the canvas and mirrored; resume 020 for Part B once 10.2 is approved |
| 020 | `020-phase-10-build.md` | Phase 10, Part B: the plumbing on Opus 5.5 from `plan/phase-10-plan.md` (migrations 0009 to 0014 with RLS tests, the syllabus data, the API skeletons, Domain types and Phase 11's repositories, the share extension and background refresh), six pull requests, the deploy, a build that shows nothing new; runs beside Part A's steps 10.3 to 10.7 |
| 021 | `021-phase-11-boards-and-plan.md` | Phase 11 (the record and the close): its boards are Phase 10's (10.1, 10.2, the close of 10.3); `plan/phase-11-plan.md` on Fable 5.1, then resume 022 for the build on Opus 5.5 |
| 022 | `022-phase-11-build.md` | Phase 11, the build: execute `plan/phase-11-plan.md` natively on Opus 5.5, ten pull requests (migration 0017, the two live API routes, Domain's rules, Data, the shell, Students' list and form, the student's page and consent, the textbook, the placement, the close), the deploy, the hand runs by the runbook, the review, a TestFlight build; resume 023 for Phase 12's plan |
