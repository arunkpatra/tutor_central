# Resume 030: Phase 15 (Make and polish), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan is `plan/phase-15-plan.md`, approved by the owner with his answers to its
two questions (the polish rows taken; when the round starts); the boards are Phase 10's step 10.7 (approved 2026-10-10) and
the website's trust page, drawn in this session's first step and built only once approved. This session builds the phase's
pull requests, runs the hand runs and the cost run, has the work reviewed, ships the TestFlight build, then sets the tutor
round up and runs its readings over its three weeks (one session per reading or fix; this prompt is pasted again at each).

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 14
(Parents) is built and in production; Phase 15 (Make and polish) is planned. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D68; D52 to D55 are the tutor round's method, D66 moves it to
   V2, D68 says what a phase finds the phase fixes).
3. `plan/phase-15-plan.md` in full: the goal, the constraints, the 30 decisions (the owner's answers to its two questions are
   in `plan/sessions/031/owner-messages.md` and the ledger), the review focus, the file structure, the launch states, the
   pull requests, the calendar, Tasks 1 to 23, the self-review. Then `plan/phase-15-make-and-polish.md` (the scope),
   `docs/spec-v2.md` sections 2, 4, 7, 8 and 9, and `plan/phase-09-plan.md` (the round's method, which Tasks 18 to 23 follow).
4. The boards: `docs/design/information-architecture.md` ("Phase 10 boards", step 10.7, and the "As built" notes of Phases
   12 to 14), `components.md` ("Phase 10 parts" 10.7), `design-tokens.md` ("Numbers in code"), `feedback.md`; the mockups
   `docs/design/mockups/P10-Make*`, `P10-Reports-Progress*`, `P10-Kit-*`, `P6-Check-*`, `P12-Form-Paper-*`, `P8-Privacy-*`
   (the trust page's pattern).
5. `plan/sessions/031/record.md` (this plan's session), `plan/sessions/030/record.md` and `ledger.md` (Phase 14's build: the
   rulings, the hand runs, the review), `docs/runbooks/simulator.md` (D32).
6. What the phase builds on: `Sources/Features/AITools/` (becomes `Make` in PR 1: `AIStore`, the forms, `CheckStore*`,
   `CheckPreset`, History), `Sources/Features/Artefacts/` (the sheet, worked example, figure, brief, mock and note stores
   and screens), `Sources/Features/Today/PlanMaker*.swift` and `Domain/Plan/ArtefactBudget.swift` (how the plan calls
   `/ai/make`), `Sources/Features/Fees/ReportsStore.swift` and `ReportsView.swift`, `Data/Parents/NoteRecordReader.swift`,
   `Domain/Record/TrackingRules.swift`, `Domain/CSV.swift`, `DesignSystem/Kit/*`, `AppShell/RootView+AITools.swift`,
   `RootView+LaunchStates.swift`, `Fixtures*.swift`, `api/src/routes/v2.ts`, `schemas.ts`, `prompts/note.ts`,
   `supabase/migrations/20261026000021_*.sql` (`keep_artefact`), `seed.sql`, `web/content/privacy.ts`.

**What is already true:** production holds migrations 0001 to 0025 and the API at `bc68758`; the website at `e455ba0`;
TestFlight carries 1.0.0 (25), Phase 14; `main` is ahead of it by U46 and U47. The owner installs and tests the builds together
after the last phase (D68), so the hand runs in the simulator against the local stack are the check until then. The owner
approved real AI calls in testing without asking each time (be judicious; the plan's cost run is about ₹20; record what ran
and what it cost). Scan register stays in Students (D36).

**Your work, in order:**

1. The session's setup as `plan/SESSIONS.md` says (reality against `STATE.md`; `bun check` from green). Open the ledger
   `plan/sessions/032/ledger.md` (the shape of `plan/sessions/030/ledger.md`); write the polish rows the owner took as Task
   12's items in it.
2. Draw the trust page's board (Task 13, step 1: P15-Web-Trust at 1280 and 390, dark and light, in P8's page pattern, from the
   privacy page's board and the consent sheet's words; D50's rules), publish it to row 25 of the canvas, mirror it, and show
   the owner. Do not build PR 12 before his approval; the other pull requests do not wait on it.
3. Execute `plan/phase-15-plan.md` with `superpowers:executing-plans`, inline, task by task, tests first: PRs 1 to 12 in order
   (the rename; migration 0026 with the seed's checks; the API's `tutorSays`; the deploy; Domain; Progress' rules; Make's home;
   the forms with the For sheet; Check a paper under Make with U22 and U23; Reports' Progress with U26; the Kit; the polish
   rows; the trust page), each `bun check` green, one change, pictures by D7 (`bun shots <state>`, `bun pr-shots`) for every
   state the plan's table names, merged when green. A ruling the plan did not foresee goes in the ledger with its cost if
   wrong; a question that is the owner's is asked one at a time.
4. The hand runs (Task 14's fifteen rows) by `docs/runbooks/simulator.md`, each write confirmed in the database, the
   screenshots on the phase's issue; a fault found is fixed in a fix pull request with a test that failed first (D68).
5. The cost run (Task 15) on the real models; the figures into the record and `PriceSheet.typical`.
6. The deploys (Task 16: `deploy` after PR 3, `deploy-web` after PR 12); the review on Fable 5.1 with every finding of any
   grade fixed; `gh workflow run testflight`.
7. The documents of the build (Task 17), to `main` (D12).
8. The round (Tasks 18 to 23): the release notes and the checklist; the V2 guide and the findings file; the owner's App
   Store Connect steps one at a time, each checked before the next; the tester's device checks on the review build; the
   invitations and the guide; a reading every Monday and Thursday (a crash the day it is seen), the triage proposed in one
   table and confirmed by the owner in one reply, fixes in their own pull requests, builds on Thursdays; the close and its
   documents. The start date is the owner's answer to the plan's question 2.
9. `plan/STATE.md` before you stop, every session; `plan/sessions/032/record.md`, `ledger.md` and `owner-messages.md` at the
   end of the build; a record per reading session after.

**The owner's rules:** check each request against the spec, the decisions, the boards and the code, and push back with a
concrete reason when it is wrong (`docs/working/pushback.md`); be brief; decide small things and say what you decided; ask one
question at a time; no technical words in anything a tutor reads (D41); plain voice in documents; the word is Students, and
Batch on screen; nothing from V1 renamed in the model (D56); migrations additive (D26); no service-role key (D37, D60);
nothing found in the phase is deferred (D68); no tutor's name, email or number in the repository (D55).
