# Resume 029: Phase 15 (Make and polish), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 15's boards are Phase 10's step 10.7 (approved 2026-10-10: Make something, a
kind's form, the For sheet, Check a paper under Make, Reports' Progress by month and by term, the Kit's Phase 10 rows). This
session writes the plan and the build's resume prompt, then stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 14
(Parents) is done: the note day with the weekly note and can-now-do in the parent's language, the three-a-week cadence, the
sent log, not on track with the next step and the message to the parent, marks from a photo, the signature on each message,
D67's model table and D68's leftovers. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` (Phase 14 added rules to each).
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D68; D52 to D55 are the tutor round's method, D66
   moves it to V2, D68 says what a phase finds the phase fixes), `plan/ui-polish.md` (the open rows: Phase 15 works the ones
   the owner picks).
3. `docs/spec-v2.md` (section 4's More and Make; Reports; the kinds and their consent; the models by kind),
   `plan/phase-15-make-and-polish.md` (the scope), `plan/phase-14-parents.md`'s "As built" (what is done and the cost
   measured), `plan/phase-12-class-plan.md` and `plan/phase-13-school.md`'s "As built" (the plan's material, the mock, the
   gap report: the kinds Make offers for one student or group), and `plan/phase-09-plan.md` with
   `docs/testing/tester-guide.md` (the tutor round's method, written for V1: Phase 15 reruns it on V2).
4. `docs/design/information-architecture.md`, "Phase 10 boards", step 10.7 (Make, the form, the For sheet, Check a paper under
   Make, Reports' Progress, the Kit; its launch states), and the "As built" notes of Phases 12 to 14; `components.md`
   ("Phase 10 parts" for 10.7, and the "As built" notes); `design-tokens.md` ("Numbers in code"); `feedback.md`. Open the boards
   on the canvas or in `docs/design/mockups/P10-Make*`, `P10-Reports-Progress*`, `P10-Kit-*`.
5. `plan/sessions/030/record.md` and its `ledger.md` (Phase 14's rulings, hand runs, the cost run and the review's
   eighteen fixes and two rulings), and `plan/sessions/029/record.md` (Phase 14's plan, the house style).
6. What Phase 15 builds on: AI Assistant (`Sources/Features/AITools/`: `AIStore`, the forms, `ResultFooter`, History,
   Check a paper's `CheckStore*`, `CheckPreset`), the AI forms by class level (#122, P12-Form-Paper-Class), the plan's
   material makers (`Sources/Features/Today/PlanMaker*.swift`, `Sources/Features/Artefacts/`: sheet, worked example,
   figure, brief, mock, the note), More's routes (`Sources/AppShell/`), Reports (`Sources/Features/Fees/ReportsStore.swift`: Fees and
   Attendance), the record reads (`NoteRecordReader`, `TrackingRules`, marks),
   `api/models.json` and `bun cost` (D67), and the Kit board's DesignSystem parts.

**What is already true:** production holds migrations 0001 to 0025 and the API at `bc68758`; TestFlight carries 1.0.0 (25),
Phase 14. The owner installs and tests the builds together after the last phase (D68), so the hand runs in the simulator
against the local stack are each phase's check until then: plan them to cover each new screen and each write. The owner
approved real AI calls in testing without asking each time (be judicious; record what ran and what it cost). V1's AI
Assistant still sits under More; Scan register stays in Students (D36).

**Your work:** write `plan/phase-15-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (Make's home and
each kind's form for a student, a group, a batch or a class level, with consent asked where a student is named and none for
a class level alone; Check a paper reached from Make with a made mock's or paper's key; Reports' Progress by month and by
term from the record, its numbers proven against the seed, the term by the school's board, Lowest first, the CSV; the Kit's
rows; the stores against fakes), the file structure, the pull requests (one change each, screenshots per D7 for each board
state and both appearances where the board has both), the launch states step 10.7 names, the D32 hand runs (a sheet for a
group, a note to a parent from Make, a class-level paper with no student data sent, Check a paper with a mock's key from
Make, Progress for a month and a term against the seed), the cost of Make's kinds measured (D64, `bun cost`), and the review
focus (what a person meets that no happy path exercises: a student with no record yet, a group across class levels, a term
that spans the school year's change, a student archived mid-term, a kind made again from Recent).

The polish rows and the tutor round are the owner's to scope:

- **Polish.** List the open rows of `plan/ui-polish.md` in the plan with what each would take (a board first for any that
  changes what is seen beyond an approved board), and ask the owner which to take; fold the chosen ones in as tasks.
- **The tutor round (D52 to D55 on V2, D66).** Plan the round's set-up (the external group, the tester's guide rewritten for
  V2 in plain words, the findings file, the device tests T1 to T14 first, by the tester), the weeks and the triage; name each
  step the owner must do himself (App Store Connect, the invitations) as one step at a time. Ask the owner when the round
  starts relative to the build.

Decide small things in the plan and list them; ask the owner one question at a time only for what is his.

Then write `plan/resume/030-phase-15-build.md` for the build on Opus 5.5 and index both in `plan/resume/README.md`. Show
the owner the plan before any build starts. Documents only, to `main` (D12).

**The owner's rules:** check each request against the spec, the decisions, the boards and the code, and push back with a
concrete reason when it is wrong (`docs/working/pushback.md`); be brief; decide small things and say what you decided; ask
one question at a time; no technical words in anything a tutor reads (D41); plain voice in documents (no slogans, no
"every"); the word is Students, and Batch on screen; nothing from V1 renamed in the model (D56); migrations additive (D26);
no service-role key (D37, D60); nothing found in the phase is deferred (D68). Update `plan/STATE.md` before you stop; write
`plan/sessions/031/record.md` (or the next number) at the end.
