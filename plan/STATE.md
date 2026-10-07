# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 1. **Scoped and specified.** The reference app is inventoried
(`docs/reference/`), the design is approved (`docs/spec.md`, D1 to D19), the phases are scoped (`plan/`).
**Next:** Phase 0's plan (`phase-00-plan.md`), then the visual directions on the canvas; Phase 1's plan beside it
(D6).

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Not started | First: two or three visual directions for the shell and Today, at iPhone size, for the owner to choose |
| 1 Foundation | Not started | May start beside Phase 0 (D6). Tools to install: xcodegen, swiftformat, swiftlint, xcbeautify, supabase CLI |
| 2 to 7 | Not started | Scoped in their files |

## In flight

Nothing. Repo holds documents only: `docs/`, `plan/`, `CLAUDE.md`, `README.md`.

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
