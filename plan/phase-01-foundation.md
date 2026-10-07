# Phase 1: Foundation

**Status:** Not started. **Depends on:** nothing; runs beside Phase 0 (D6). Builds no user-facing screen.

## Goal

A repo where one command checks everything, the app builds and launches in the simulator as an empty shell,
the database schema and its security run locally, the API answers on Vercel, and CI does the same with caches
so a pull request is checked in minutes.

## Scope

1. **Monorepo layout.** `ios/`, `api/`, `supabase/`, `tools/`, `.github/workflows/`; root `package.json` with
   Bun scripts (`check`, `gen`, `shots`), `bunfig.toml`, `.nvmrc`-equivalent for Bun version, `.gitignore`.
2. **iOS project.** `ios/project.yml` for XcodeGen (D9): app target `TutorCentral`, bundle id per D19,
   iOS 26 deployment, Swift 6 strict concurrency, both appearances, portrait only. Local package
   `ios/TutorCentral/Package.swift` with targets `DesignSystem`, `Domain`, `Data`, `AppShell`, and the feature
   targets as empty shells, plus test targets for Domain and Data. `supabase-swift` pinned (D14). SwiftFormat
   and SwiftLint configs. The app launches to a placeholder (one line of text), no design yet.
3. **Supabase.** `supabase/` initialised with the CLI; migration 0001 with every table in `docs/spec.md`
   section 5, RLS policies, the `generate_fees` and `delete_centre` functions, triggers for `updated_at`; a seed
   for local development (one centre, ten students, two classes, a month of fees and attendance); generated
   TypeScript types; a Bun test suite that proves RLS (a user sees their centre and nothing else, anonymous sees
   nothing, `generate_fees` is idempotent).
4. **API.** `api/` Hono on Vercel: `GET /health`; JWT verification middleware against Supabase; Zod schemas for
   the three AI routes returning `501` with their contract (the bodies come in Phase 6); Bun tests for the
   middleware and the schemas. Deployed to a Vercel project (the owner creates it, one step at a time).
5. **Check.** `bun check` runs, in order and stopping at the first failure: SwiftFormat (lint mode), SwiftLint,
   `xcodebuild build-for-testing` and `test-without-building` for the package tests with `xcbeautify`, API
   typecheck and tests, Supabase RLS tests when the local stack is up (skipped with a line when it is not). A
   step whose inputs have not changed since it was last green is skipped (Turbo-style hashing in
   `tools/check/`).
6. **CI.** `.github/workflows/check.yml` on pull requests and `main`: the same check on a macOS runner with
   Xcode 27 selected, caching the SPM checkouts, DerivedData's build products keyed on the package resolution
   and the Swift toolchain, and Bun's cache. Target: a no-change rerun under five minutes, a one-file change
   under ten. `testflight.yml` is a manual trigger stub until Phase 2 wires signing.
7. **Screenshots tooling.** `tools/shots.ts`: boots the named simulator, installs the built app, drives it to a
   named state through launch arguments, takes `xcrun simctl io screenshot` in both appearances, and
   `tools/pr-shots.ts` commits the pictures to the orphan branch `pr-shots` and prints the link table (D7).
8. **Rules files.** `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` with each part's local rules and
   commands.

## Owner steps (one at a time, checked before the next)

1. Create the Supabase project (region closest to India); hand over the project ref and the anon key; the
   service role key goes only into Vercel and `api/.env.local`.
2. Create the Vercel project for `api/`, linked to this repo's `api/` directory.
3. Create the GitHub Actions secrets the workflows name.

## Acceptance

- `bun check` is green locally from a fresh clone after `bun install`, `brew bundle` (tools) and
  `supabase start`.
- CI is green on a pull request, and a second run with no change finishes with every step skipped.
- The app launches in the iPhone 17 Pro simulator from `xcodegen generate && xcodebuild`.
- `supabase db reset` applies the migrations and the seed; the RLS tests pass.
- `GET /health` answers on the Vercel deployment.

## Out of scope

Any screen, any token, any component (Phase 2, after the Phase 0 direction). Signing and TestFlight (Phase 2).

## As built

(Written when the phase ends.)
