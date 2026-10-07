# Tutor Central

A native iPhone app for tutors who run a small tuition centre: students and their parents, classes and when
they meet, who came today, who has paid this month, and the papers and homework the tutor hands out. India
first: rupees, UPI, WhatsApp.

| Part | What | Where |
|---|---|---|
| iOS app | Swift 6, SwiftUI, iOS 26, one local package of modules | `ios/` (Phase 1) |
| API | Hono on Vercel, for AI and scanning only | `api/` (Phase 1) |
| Database | Supabase: Auth, Postgres with row-level security, Storage | `supabase/` (Phase 1) |
| Design | The approved boards, tokens, components, guidelines | `docs/design/` (Phase 0) |
| Spec | Product and technical design | `docs/spec.md` |
| Plan | Phases, state, sessions, decisions | `plan/` |

## Working on it

Read `CLAUDE.md`, then `plan/STATE.md`. The process for a session is `plan/SESSIONS.md`. Nothing on screen is
built without an approved board (`docs/design/`).

## Status

Scoped and specified (2026-10-07). Phase 0 (design) and Phase 1 (foundation) are next; see `plan/README.md`.
