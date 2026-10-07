# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 1. **Scoped, specified, Phase 0 started.** The reference app is
inventoried (`docs/reference/`), the design is approved (`docs/spec.md`, D1 to D19), the phases are scoped
(`plan/`). Phase 0: step 0.1 done, direction A Ember chosen (D20); step 0.2, the design system (tokens, components,
guidelines, four Kit boards) and step 0.3 (the Phase 2 boards, `information-architecture.md`) are approved.
Phase 1's implementation plan is written (`phase-01-plan.md`); the owner chose native execution in a fresh
Opus 5.5 session (D17): resume prompt `resume/001-phase-1-foundation.md`. **Next:** Phase 1 from that prompt;
step 0.4 (Students and classes boards) on the design side when the owner wants it.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1, 0.2 and 0.3 approved; 0.4 next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/directions/`; plan `phase-00-plan.md` |
| 1 Foundation | Planned (`phase-01-plan.md`, 9 tasks, 4 PRs); resume `resume/001` | Native execution on Opus 5.5. Needs Docker for the local database; the owner creates the Supabase and Vercel projects at Tasks 4 and 6 |
| 2 to 7 | Not started | Scoped in their files |

## In flight

Nothing open. Session 1 ended with everything approved and planned. Repo holds documents only.

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
