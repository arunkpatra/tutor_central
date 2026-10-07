# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 1. **Scoped, specified, Phase 0 started.** The reference app is
inventoried (`docs/reference/`), the design is approved (`docs/spec.md`, D1 to D19), the phases are scoped
(`plan/`). Phase 0: step 0.1 done, direction A Ember chosen (D20); step 0.2, the design system (tokens, components,
guidelines, four Kit boards), is approved; step 0.3, the Phase 2 boards, is drawn and awaiting approval
(`docs/design/README.md`). Phase 1's implementation plan is written (`phase-01-plan.md`) and awaits the owner's
review and choice of execution method. **Next:** approvals, then Phase 1 execution (a fresh session, Opus 5.5 per
D17) beside step 0.4.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 and 0.2 approved; 0.3 drawn, awaiting approval | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/directions/`; plan `phase-00-plan.md` |
| 1 Foundation | Planned (`phase-01-plan.md`, 9 tasks, 4 PRs) | Starts when the owner picks the execution method. Needs Docker for the local database; the owner creates the Supabase and Vercel projects at Tasks 4 and 6 |
| 2 to 7 | Not started | Scoped in their files |

## In flight

Phase 0, step 0.3 (approval). Phase 1 plan review. Repo holds documents only.

## Open items

- App icon: a Phase 0 board (name settled as Tutor Central, D20).
- Accounts the owner creates when a phase needs them, one step at a time: Supabase project (Phase 1), Vercel
  project for `api/` (Phase 1), App Store Connect app record and API key (Phase 2), Google OAuth client
  (Phase 2), Anthropic API key (Phase 6).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`. Read only. Never copy its colours or layouts |
