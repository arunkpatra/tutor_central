# Resume 023: Phase 12 (the plan), the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 12's boards are already approved (Phase 10 Part A, steps 10.3 and 10.4); this
session writes the plan and the build's resume prompt, then stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors. V2 is the product that goes to market (D66). Phase 11
(the record and the close) is done: the five tabs, New student V2, the student's page with tracking and consent, the
textbook capture, the placement, and the close from Today's batch hero (attendance, three checks per student from the
spaced queue or the placement, homework, one write, offline by the queue). Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` (Phase 11 added rules to each).
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66), `plan/ui-polish.md` (U34 to U39 are Phase
   11's).
3. `docs/spec-v2.md` (sections 4 to 7: the plan, the material, when it is made, the close from the plan, the cost),
   `plan/phase-12-class-plan.md` (the scope), `plan/phase-11-record-and-close.md`'s "As built" (what the close, the rules
   and the hero settled, and what Phase 12 changes: the checks move from the close to the plan; the hero's "its plan is
   made when you open the app" becomes true), and `plan/phase-10-v2-design-and-foundation.md`'s Part B "As built" (the
   plans table, the artefacts, `close_session`'s plan link, the monthly allowance, the background refresh).
4. `docs/design/information-architecture.md`, "Phase 10 boards", steps 10.3 (Today's plan: the hero over the plan's cards,
   the group cards and their lines, Change the plan, the planning card, the close's group checklist, "To parents" after the
   close, the note day, Tomorrow) and 10.4 (the artefacts: the sheet, its three forms, the result footer, the figures, the
   brief); `components.md` "Phase 10 parts" with its "As built in Phase 11" note; `design-tokens.md`; `feedback.md`. Open
   the boards on the canvas (rows 16 and 17) or in `docs/design/mockups/P10-*`.
5. `plan/sessions/024/record.md` and its `ledger.md` (Phase 11's rulings: the hero's rule, the close's reopen, the
   placement in Domain, the checks per subject, the queue's close), and `plan/sessions/023/record.md` (Phase 11's plan).
6. What Phase 12 builds on: `supabase/migrations/` 0010 (plans, artefacts) and 0017 (`close_session` with states),
   `api/src/routes/v2.ts` (`/make` check and placement live; `/plan` and the other kinds answer 501), `api/src/schemas.ts`,
   `ios/TutorCentralKit/Sources/Domain/Record/` (SpacedQueue, SkillProgress, TrackingRules, Placement),
   `Sources/Features/Today/` (TodayStore and its hero, CloseStore and its parts), `Sources/Data/AI/`.

**What is already true:** production holds migrations 0001 to 0017 and the API with `/parse-textbook` and `/make` (check,
placement) live; TestFlight carries Phase 11's build; the close works without a plan (D57).

**Your work:** write `plan/phase-12-plan.md` with `superpowers:writing-plans`: tasks in order, tests first (the plan's Domain
rules: groups by level, the subject per student, the four lines, catch-up lines, the artefact budget; the API's `/ai/plan`
and the set, sheet, brief and figure kinds of `/ai/make` with the fake; the stores against fakes), the file structure, the
pull requests (one change each, screenshots per D7 for each board state), the launch states the boards name, the D32 hand
runs (the plan made on open, a regenerate, the close from a plan online and offline), the cost measurement for D64 (a
twelve-student batch across three groups), the review focus (what a person meets that no happy path exercises: a batch with
new students and no record, a student without consent, a plan made offline, a plan for a day with no batch, a regenerate
that fails, a sheet with a figure). Decide small things in the plan and list them; ask the owner one question at a time
only for what is his. Then write `plan/resume/024-phase-12-build.md` for the build on Opus 5.5 and index both in
`plan/resume/README.md`. Show the owner the plan before any build starts. Documents only, to `main` (D12).

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time; no technical
words in anything a tutor reads (D41); plain voice in documents (no slogans, no "every"); nothing from V1 renamed in the
model (D56); migrations additive (D26); no service-role key (D37, D60). Update `plan/STATE.md` before you stop; write
`plan/sessions/025/record.md` (or the next number) at the end.
