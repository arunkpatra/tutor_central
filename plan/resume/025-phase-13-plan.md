# Resume 025: Phase 13 (School), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 13's boards are Phase 10's step 10.5 (approved); the Marks section on the
student's page (U36) has no board yet. This session writes the plan and the build's resume prompt, then stops for the
owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 12
(the plan) is done: Today shows each batch's level groups and lines with the material made ahead (sets, sheets, checks, a
worked example per group, seven figure templates, the brief above class 7), the tutor changes it where it shows, and the
close follows the plan online and offline. Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` (Phase 12 added rules to each).
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66), `plan/ui-polish.md` (U36 is this phase's;
   U40 is new from Phase 12).
3. `docs/spec-v2.md` (the School sections: the share extension, items, the calendar, test tomorrow, exam preparation, the
   mock, marking, the gap report), `plan/phase-13-school.md` (the scope), `plan/phase-12-class-plan.md`'s "As built" (the
   plan's rules, the budget, the artefacts, the close from the plan, the cost measured, what was left open), and
   `plan/phase-10-v2-design-and-foundation.md`'s Part B "As built" (the share extension and the app group, the school
   tables, `/ai/parse-school`'s skeleton, the background refresh).
4. `docs/design/information-architecture.md`, "Phase 10 boards", step 10.5 (School: the tab, the share sheet's items for
   confirmation, the calendar, Ask parents to forward, test tomorrow, exam preparation, the mock, the gap report);
   `components.md` "Phase 10 parts" (10.5) and its "As built in Phase 12" notes; `design-tokens.md` ("Numbers in code",
   Phase 10 step 10.5 and Phase 12); `feedback.md`. Open the boards on the canvas or in `docs/design/mockups/P10-*`.
5. `plan/sessions/026/record.md` and its `ledger.md` (Phase 12's rulings, the hand runs' eleven faults, the review's
   findings and the ten deferred minors), and `plan/sessions/025/record.md` (Phase 12's plan).
6. What Phase 13 builds on: `supabase/migrations/` (0009 and 0011: schools, school items, marks, syllabi, photos; 0019
   and 0020), `api/src/routes/v2.ts` and `schemas.ts` (`/plan`, `/make`; `mock` answers 501), `api/src/routes/ai.ts`
   (`/parse-school` is a skeleton), `ios/Share/` (the share extension) and the app group, `Sources/Domain/Plan/`
   (`PlanRules` already reads `SchoolItemHint`), `Sources/Features/Today/` (PlanMaker, PlanStore), `Sources/Features/
   Artefacts/`, `Sources/Data/Plans/` (PlanCache), the School tab's placeholder.

**What is already true:** production holds migrations 0001 to 0020 and the API at `6a23563` with `/plan` and `/make` (sheet,
worked example, figure, brief, check, placement) live; TestFlight carries 1.0.0 (22), Phase 12 with the student-link fix
(#121). The plan's subject per student already takes "the nearest school item" as an input with no items behind it.

**Your work:** write `plan/phase-13-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (the item rules:
kind, student or class of a school, subject, date, portions; a holiday removing the day's plan; the exam window and the
split of portions across days; the cadence rule holding test tomorrow; the API's `/ai/parse-school` and the mock kind of
`/ai/make` with the fake; marking a mock from a photo through `/ai/check-paper`; the stores against fakes), the file
structure, the pull requests (one change each, screenshots per D7 for each board state), the launch states the boards
name, the share path added to `docs/runbooks/simulator.md` and the D32 hand runs (a forwarded timetable photo of two
subjects becoming two exam items, an exam in the window turning a student's lines to revision on Today, a mock marked from
a photo), the cost of a mock and a gap report measured for D64, the review focus (what a person meets that no happy path
exercises: a forwarded message with no date, an item for a class of a school no student is in, two schools in one batch,
class 10's two dates, a holiday on a closed day, the share extension opened signed out). Name the board U36 needs (the
student page's Marks) and get it approved on the canvas before its task, as Phase 0's steps did. Decide small things in the
plan and list them; ask the owner one question at a time only for what is his. Two of his are waiting from Phase 12:

- **A new batch's first checks:** a batch with no record has no checks at its first close ("No book yet"). Should the
  first topic `/ai/plan` names for a group be written as each member's chapter and skill, so the first class gets checks?
  (The ledger's Final ruling on the review's Important 3.)
- **An unnamed group:** a group `/ai/plan` fails to name at the make stays without material that day until the tutor makes
  the plan again. Fix it in this phase or leave it?

Then write `plan/resume/026-phase-13-build.md` for the build on Opus 5.5 and index both in `plan/resume/README.md`. Show
the owner the plan before any build starts. Documents only, to `main` (D12).

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time; no technical
words in anything a tutor reads (D41); plain voice in documents (no slogans, no "every"); nothing from V1 renamed in the
model (D56); migrations additive (D26); no service-role key (D37, D60). Update `plan/STATE.md` before you stop; write
`plan/sessions/027/record.md` (or the next number) at the end.
