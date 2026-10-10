# Resume 024: Phase 12 (the plan), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). The plan and the two Phase 12 boards (P12-Close-Cards, P12-Pending-Close, row 21 of the
canvas) were approved by the owner on 2026-10-10.

---

You are building Phase 12 of Tutor Central, a native iPhone app for tutors. V2 is the product (D66). Phase 11 gave the
app the record and the close; Phase 12 gives it the plan: Today shows each batch's level groups and lines with the
material made ahead, the tutor changes any of it where it appears, and the close follows the plan online and offline.
Read, in this order, before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D66), `plan/ui-polish.md` (U35, U37, U38, U39
   are this phase's).
3. `plan/phase-12-plan.md` in full: the goal, the global constraints, the 24 decisions it takes, the review focus, the
   file structure, the launch states, the nine pull requests, Tasks 1 to 25, the self-review. Then
   `plan/phase-12-class-plan.md` (the scope) and `docs/spec-v2.md` sections 6, 7 and 9.
4. `docs/design/information-architecture.md` "Phase 10 boards" 10.3 and 10.4 and "Phase 12 boards"; `components.md`
   "Phase 10 parts" 10.3 and 10.4 and "Phase 12 parts"; `design-tokens.md` "Numbers in code"; `feedback.md`. Open the
   boards on the canvas (rows 16, 17 and 21) or in `docs/design/mockups/P10-Today-*`, `P10-Close*`, `P10-Sheet*`,
   `P10-WorkedExample`, `P10-Figure-*`, `P10-Brief`, `P12-*`.
5. `plan/sessions/025/record.md` (this plan's session) and `plan/sessions/024/record.md` with its `ledger.md` (Phase
   11's build: the rulings the close and the hero carry).
6. What the phase builds on: `supabase/migrations/` 0010 and 0017; `api/src/routes/v2.ts`, `schemas.ts`, `models.ts`,
   `claude-fake.ts`; `ios/TutorCentralKit/Sources/Domain/Record/` (SpacedQueue, SkillProgress, TrackingRules, Placement,
   FigureSpec), `Sources/Features/Today/` (TodayStore and its hero, CloseStore and its parts), `Sources/Data/AI/`,
   `Sources/Data/Refresh/BackgroundRefresh.swift`, `Sources/AppShell/` (RootView+Today, RootView+Close, Fixtures,
   LaunchState).

**What is already true:** production holds migrations 0001 to 0018 and the API with `/parse-textbook` and `/make`
(check, placement) live; TestFlight carries build 20 (Phase 11); the close works without a plan (D57).

**Your work:** execute `plan/phase-12-plan.md` with `superpowers:executing-plans`, inline, task by task, tests first,
one pull request per row of its table (nine), each with `bun check` green and the pictures per D7 (`bun shots`, `bun
pr-shots`, the table in the description), merged when green. Keep one ledger as sessions 22 and 24 did (each ruling
with what it costs if wrong; the hand runs; the review). After PR 2, `gh workflow run deploy` (Task 24 step 1). Before Task 24's cost run (run 8, the local API without `AI_FAKE`, about ₹10), tell the owner and
wait for his yes. After PR 9: the hand runs (Task 24), the cost run, the reviewer pass (Task 25), `gh workflow run
testflight`, then the documents (Task 25) to `main` (D12), `plan/STATE.md` last, and `plan/sessions/026/record.md`,
`ledger.md` and `owner-messages.md`.

**The owner's rules:** be brief; decide small things and say what you decided; ask one question at a time, only for what
is his; no technical words on screen (D41); plain voice in documents (no slogans, no "every"); nothing from V1 renamed
in the model (D56); migrations additive (D26); no service-role key (D37, D60); boards before code (rule 1); screenshots
in each pull request that changes what is seen (rule 2); tokens only (rule 3); features never import each other (rule
4: the artefact screens are the new `Artefacts` feature, reached by AppShell's routes).
