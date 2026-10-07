# Phase 1: Foundation

**Status:** Done (2026-10-07, session 2), except the first deploy through the workflow, which waits for the owner's `VERCEL_TOKEN`. **Depends on:** nothing; runs beside Phase 0 (D6). Builds no user-facing screen.

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

Built in session 2 (Claude Opus 5.5, D17) from `phase-01-plan.md`, tests first, in seven pull requests:

| PR | What |
|---|---|
| [#1](https://github.com/arunkpatra/tutor_central/pull/1) | Brewfile, root scripts, `sh`; XcodeGen project, `TutorCentralKit` (every module a marker), `Money`, `Period`, `SupabaseConfig`, smoke test; SwiftFormat, SwiftLint, `bun check` with its input-hash cache |
| [#2](https://github.com/arunkpatra/tutor_central/pull/2) | Migration 0001 (every table, RLS, `is_member`, `create_centre`, `generate_fees`, `delete_centre`), seed, 13 RLS tests, the `db` step |
| [#3](https://github.com/arunkpatra/tutor_central/pull/3) | The Hono API: `/health`, the three AI routes validated and answering 501, `requireUser`; the `api` step |
| [#4](https://github.com/arunkpatra/tutor_central/pull/4) | Bun's hoisted linker, so Vercel's TypeScript check finds Node's types |
| [#5](https://github.com/arunkpatra/tutor_central/pull/5) | The API runs on Vercel (Node ESM imports, the preset's entry, `bom1`); `deploy.yml` and `tools/smoke.ts` (D21) |
| [#6](https://github.com/arunkpatra/tutor_central/pull/6) | `check.yml` on `xcode-27` and Ubuntu with caches, actions pinned by SHA, `testflight.yml` stub; `bun shots`, `bun pr-shots` (D22) |
| [#7](https://github.com/arunkpatra/tutor_central/pull/7) | Dark appearance by default (D23); `AppShellTests` |

**Acceptance.**
- `bun check` is green locally from a clean install; a second run skips every step in 0.1 s.
- The app launches on the iPhone 17 simulator to the placeholder.
- `supabase db reset` applies the migration and the seed; 13 RLS tests pass.
- CI is green on every PR. Cold: iOS job 2 min 49 s, api-db job 2 min 51 s. With no change: 33 s and 2 min 7 s, every step "unchanged, not run" (the api-db time is mostly starting Supabase).
- `GET /health` answered on a preview deployment built exactly as the workflow builds: `{"ok":true,"commit":…}` in `bom1`.
- Production through the workflow is pending the owner's `VERCEL_TOKEN`.

**Deviations from the plan, and why.**
- Package at `ios/TutorCentralKit` (spec section 4 says `ios/TutorCentral`): a package named TutorCentral collides with the app target and scheme of that name.
- Supabase CLI from homebrew-core, not `supabase/tap`: brew refuses the untrusted tap, and trusting it is a security setting.
- Root workspaces start empty and gain `supabase` and `api` as those directories appear: bun refuses a missing workspace.
- `project.yml` has no `info:` block (XcodeGen would overwrite `App/Info.plist`). Package tests are built with `xcodebuild` for the simulator: the package is iOS only.
- SwiftFormat owns import order, trailing commas and multi-line braces. SwiftLint's `sorted_imports` is off, `trailing_comma` is set to mandatory, and SwiftFormat's `wrapMultilineStatementBraces` is off, because each pair contradicted the other tool.
- Schema, beyond the plan, each with a test:
  - composite `(centre_id, id)` foreign keys between centre tables
  - `unique nulls not distinct` on attendance sessions
  - the owner can read their centre before membership exists (the plan's `create_centre` failed without it)
  - no grants for anonymous
  - `create_centre` refuses a null user
  - `search_path = ''` on functions
  - a catalogue test that every public table has RLS and a policy
- Seed: invoices inserted directly (the plan's note) and four weeks of attendance added (the scope asks for "a month of fees and attendance").
- `bun check` order: format, lint, ios, tools, api, db. The `tools` step also runs `tsc` (root `tsconfig.json`); the `db` step type-checks the tests first.
- Deployment (D21) replaces the plan's `vercel link && vercel deploy --prod`:
  - deploys only through `deploy.yml`, by hand, built on the runner, `--prebuilt`, with a smoke
  - git deploys off; functions in `bom1`
- Found on Vercel:
  - the isolated bun linker breaks its type check (PR 4)
  - Node ESM needs `.js` on relative imports
  - the Hono preset picks the first of `app`/`index`/`server`/`src/*` that imports `"hono"`
  - Hobby blocks deployments whose commit author it does not know (`arun@astronuts.io`); `main`'s squash commits (`arunkpatra@gmail.com`) are fine
- CI (D22):
  - iOS on the `xcode-27` image (`macos-26` stops at Xcode 26.6)
  - simulator iPhone 17 everywhere (the owner's switch; CI's image has no 17 Pro), `TC_SIMULATOR` overrides it
  - every action pinned to a SHA (security review)
- The app opens dark by default (D23, the owner's preference); `bun shots` passes `--appearance`.

**What remains.**
- The first production deploy through `deploy.yml`, once `VERCEL_TOKEN` is in the Production environment.
- The hosted Supabase project has no schema yet: `supabase db push`, owner-run, when Phase 2 needs it.
- The stray Vercel project `api` (errored) in "Arun's projects" is the owner's to delete.
