# Resume 026: Phase 13 (School), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan and the three Phase 13 boards (P13-School-Reading, P13-Today-Revision,
P13-Student-Marks with their twins, row 23 of the canvas) were approved by the owner on 2026-10-11 ("The plan is approved; the boards are approved too").

---

You are building Phase 13 of Tutor Central, a native iPhone app for tutors. V2 is the product (D66). Phase 12 gave the app
the plan; Phase 13 gives it the school: what a school sends becomes items the tutor checks, the School tab lists them, an
exam within fourteen days turns its students' lines on Today into revision with a daily set, a mock two days before, marking
from a photo and a gap report, a holiday takes its students out of the plan, Ask parents to forward starts the flow, Test
tomorrow reaches the parent in their language, and marks show on the student's page. Read, in this order, before doing
anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66), `plan/ui-polish.md` (U36 is this phase's),
   `docs/working/pushback.md`.
3. `plan/phase-13-plan.md` in full: the goal, the global constraints, the 32 decisions it takes and what it leaves for
   later, the review focus, the file structure, the launch states, the ten pull requests, Tasks 1 to 28, the self-review.
   Then `plan/phase-13-school.md` (the scope) and `docs/spec-v2.md` sections 2, 3, 5, 6, 7, 8 and 9.
4. `docs/design/information-architecture.md` "Phase 10 boards" 10.5 (and 10.4's mock and gap report, 10.2's Marks, 10.3's
   To parents) and "Phase 13 boards"; `components.md` "Phase 10 parts" 10.5, 10.4, 10.2 and "Phase 13 parts";
   `design-tokens.md` "Numbers in code"; `feedback.md`. Open the boards on the canvas (rows 18, 17, 15, 16 and 23) or in
   `docs/design/mockups/P10-School-*`, `P10-TestTomorrow`, `P10-Mock`, `P10-GapReport`, `P10-Student-Record`,
   `P10-Today-AfterClose`, `P13-*`.
5. `plan/sessions/027/record.md` (this plan's session) and `plan/sessions/026/record.md` with its `ledger.md` (Phase 12's
   build: the rulings the plan, the budget and the close carry).
6. What the phase builds on: `supabase/migrations/` 0011, 0013, 0019 and 0020; `api/src/routes/ai.ts`, `v2.ts`,
   `common.ts`, `schemas.ts`, `models.ts`, `claude-fake.ts`, `db.ts`; `ios/Share/ShareViewController.swift` and
   `Sources/AppShell/SharedInbox.swift`; `Sources/Domain/Plan/` (PlanRules, PlanTypes, ArtefactBudget, Artefact),
   `Sources/Domain/Record/` (SpacedQueue, TrackingRules, Skill); `Sources/Features/Today/` (PlanMaker and its calls,
   PlanStore, TodayStore); `Sources/Features/Artefacts/`; `Sources/Features/AITools/CheckStore*`;
   `Sources/Features/Students/RecordSections.swift`; `Sources/Data/Plans/`, `Data/AI/`, `Data/Photos/`, `Data/Messages/`;
   `Sources/AppShell/` (RootView+Today, RootView+Artefacts, RootView+AITools, RefreshHandler, Fixtures+Plan, LaunchState).

**What is already true:** production holds migrations 0001 to 0020 and the API at `6a23563` (`/plan` and `/make` for the
Phase 12 kinds live; `/parse-school` and the mock, gap report and test tomorrow kinds answer 501); TestFlight carries 1.0.0
(23); the share extension writes the inbox and nothing reads it; `PlanRules` takes `schoolItems` and the maker passes none.

**Your work:** execute `plan/phase-13-plan.md` with `superpowers:executing-plans`, inline, task by task, tests first, one
pull request per row of its table (ten), each with `bun check` green and the pictures per D7 (`bun shots`, `bun pr-shots`,
the table in the description), merged when green. Keep one ledger as sessions 22, 24 and 26 did (each ruling with what
it costs if wrong; the hand runs; the review). After PR 2, `gh workflow run deploy` (Task 27 step 1). The hand runs of
Task 26 follow the pull requests they name; the runbook's share path (Task 25) is written before hand run 1. Before the
cost run (Task 27 step 2, the local API without `AI_FAKE`, about ₹8), tell the owner and wait for his yes. After PR 10:
the review (Task 27 step 3), `gh workflow run testflight`, then the documents (Task 28) to `main` (D12), `plan/STATE.md`
last, and `plan/sessions/028/record.md`, `ledger.md` and `owner-messages.md`.

**The owner's rules:** check each request against the spec, the decisions, the boards and the code, and push back with a
concrete reason when it is wrong (`docs/working/pushback.md`); be brief; decide small things and say what you decided; ask
one question at a time, only for what is his; no technical words on screen (D41); plain voice in documents (no slogans,
no "every"); nothing from V1 renamed in the model (D56); migrations additive (D26); no service-role key (D37, D60); boards
before code (rule 1); screenshots in each pull request that changes what is seen (rule 2); tokens only (rule 3); features
never import each other (rule 4: `School` is its own feature, reached by AppShell's routes; the mock and gap report are
`Artefacts`'; the Marks section is `Students`'; To parents is Today's; the rules are Domain's).
