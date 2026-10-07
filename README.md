# Tutor Central

A native iPhone app for tutors who run a small tuition centre: students and their parents, classes and when
they meet, who came today, who has paid this month, and the papers and homework the tutor hands out. India
first: rupees, UPI, WhatsApp.

| Part | What | Where |
|---|---|---|
| iOS app | Swift 6, SwiftUI, iOS 26, one local package of modules | `ios/` |
| API | Hono on Vercel, for AI and scanning only | `api/` |
| Database | Supabase: Auth, Postgres with row-level security, Storage | `supabase/` |
| Design | The approved boards, tokens, components, guidelines | `docs/design/` (Phase 0) |
| Spec | Product and technical design | `docs/spec.md` |
| Plan | Phases, state, sessions, decisions | `plan/` |

## Prerequisites

| Tool | Version | How |
|---|---|---|
| Xcode | 27.0, with an iOS simulator runtime and the iPhone 17 | App Store |
| Bun | 1.3.11 | bun.sh |
| Homebrew | any | brew.sh |
| xcodegen, swiftformat, swiftlint, xcbeautify, supabase | as the Brewfile installs them | `brew bundle` |
| Docker Desktop or OrbStack | running, for the local database | docker.com or orbstack.dev |

## Set up

```bash
bun install
brew bundle
cp ios/Config/Local.xcconfig.example ios/Config/Local.xcconfig   # then the anon key from `supabase status -o env`
cd supabase && supabase start && cd ..
bun check
```

`bun check` is green when everything is: format, lint, the iOS build and tests, the tools, the API, and the
database's row-level security tests. The commands are in `CLAUDE.md`.

## Working on it

Read `CLAUDE.md`, then `plan/STATE.md`. The process for a session is `plan/SESSIONS.md`. Nothing on screen is
built without an approved board (`docs/design/`).

## Status

Phase 1 (foundation) is built (2026-10-07): the app launches to a placeholder, the schema and its security run
locally, the API is on Vercel, CI checks every pull request. Phase 0 (design) continues; Phase 2 builds the first
screens. See `plan/README.md`.
