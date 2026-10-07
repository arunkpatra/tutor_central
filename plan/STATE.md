# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 1. **Scoped, specified, Phase 0 started.** The reference app is
inventoried (`docs/reference/`), the design is approved (`docs/spec.md`, D1 to D19), the phases are scoped
(`plan/`). Phase 0's plan is written (`phase-00-plan.md`); step 0.1, three visual directions, is on the canvas
(`docs/design/README.md`) awaiting the owner's choice. **Next:** the owner picks a direction (or a blend) and the
brand name; then step 0.2 (design system) and Phase 1's plan beside it (D6).

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: step 0.1 drawn, awaiting choice | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/directions/`; plan `phase-00-plan.md` |
| 1 Foundation | Not started | May start beside Phase 0 (D6). Tools to install: xcodegen, swiftformat, swiftlint, xcbeautify, supabase CLI |
| 2 to 7 | Not started | Scoped in their files |

## In flight

Phase 0, step 0.1: the owner's choice of direction. Repo holds documents only.

## Open items

- Final brand name and app icon (D19): a Phase 0 board.
- Accounts the owner creates when a phase needs them, one step at a time: Supabase project (Phase 1), Vercel
  project for `api/` (Phase 1), App Store Connect app record and API key (Phase 2), Google OAuth client
  (Phase 2), Anthropic API key (Phase 6).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`. Read only. Never copy its colours or layouts |
