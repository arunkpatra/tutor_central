# Session 2 (2026-10-07): Phase 1 foundation built

Model: Claude Opus 5.5 (D17), executing `plan/phase-01-plan.md` inline (superpowers:executing-plans), tests first.
Outcome: Phase 1 built and merged in PRs #1 to #8; decisions D21 to D23; the API in production through
`deploy.yml` (0414a73, `bom1`, smoke green).

## What was done, in order

1. Tools (Brewfile), root scripts, `sh`; the XcodeGen project and `TutorCentralKit`; `Money`, `Period`,
   `SupabaseConfig`; SwiftFormat, SwiftLint, `bun check` with an input-hash cache. PR #1.
2. The local Supabase stack (Docker was running); migration 0001, seed, RLS tests (13), the `db` step. PR #2.
3. The API: `/health`, three AI routes answering 501 with their contract, `requireUser`. PR #3. The owner created
   the Supabase project (Mumbai) and the Vercel project `tutor-central-api`.
4. The first Vercel build failed (`Cannot find name 'process'`): bun's isolated linker. Reproduced with
   `vercel build` on a scratch clone; hoisted linker. PR #4. The build passed, but every request crashed: Node ESM
   needed `.js` on imports, and the Hono preset had taken `src/app.ts` as its entry. The owner logged the CLI in;
   runtime logs found both. Fixed with tests that encode each rule. PR #5.
5. The owner pointed at the rooftop app's CI/CD. Adopted its pattern for the API (D21): git deploys off, a manual
   `deploy.yml` building with the pinned CLI, `--prebuilt`, a smoke. Rehearsed locally as a preview: `/health`
   reported the deployed commit, in `bom1`.
6. CI (`check.yml`) on `xcode-27` and Ubuntu with caches; actions pinned by SHA after a security review flagged a
   moving tag; `bun shots`, `bun pr-shots`. Cold run under 3 min a job; a no-change run skips every step. PR #6.
7. The owner asked for dark by default: `AppShell.Appearance` with `preferredColorScheme`, light and "match iPhone"
   kept (D23). PR #7.
8. Rules files (`ios/`, `api/`, `supabase/` `CLAUDE.md`), commands, README, "As built", state, this record.
9. A fresh reviewer (Fable 5.1) read PRs #1 to #7. It found no Critical issues and one Important one: a
   deployment missing its Supabase settings would tell every tutor "sign in again" and still pass the smoke.
   That was fixed test-first in PR #8. Eleven minors are deferred to `STATE.md`.
10. The owner added `VERCEL_TOKEN`. The first workflow deploy sat at UNKNOWN: `main`'s head was a documents
    commit authored `arun@astronuts.io`. Cancelled; the repo's git email set to `arunkpatra@gmail.com` (the
    owner's instruction); the deploy step limited to 5 minutes. After PR #8 the deploy went through in 92 s,
    and production answers with its commit from `bom1`.

## Why things are as they are

- **Composite foreign keys between centre tables:** foreign keys bypass RLS. Without them, a user who learns
  another centre's student id could hang their own rows on it. Each constraint is pinned by a test that was
  mutation-checked.
- **The owner can read their own centre before membership exists:** the plan's `members_owner_insert` looked the
  centre up through a select policy that only admitted members, so `create_centre` could never succeed.
- **Deploys by hand through a workflow (D21), not git deploys:** the owner's pattern in his other apps. Nothing
  deploys on its own (cost), and each deploy is smoked against the commit it claims. It also sidesteps Vercel
  Hobby's block on unknown commit authors.
- **Hoisted bun linker:** `@vercel/node` type-checks through a language service host with no `realpath`, so the
  isolated linker's symlinks hide `@types/node` from `bun-types`.
- **`src/make-app.ts`, not `src/app.ts`:** Vercel's Hono preset takes the first of `app`, `index`, `server`,
  `src/app`, `src/index`, `src/server` that imports `"hono"`.
- **`xcode-27` runner, iPhone 17 (D22):** `macos-26` has no Xcode 27; the Xcode 27 image has only iOS 27
  simulators and no 17 Pro. The owner had switched to the iPhone 17 anyway.
- **Dark by default with `preferredColorScheme` (D23):** the owner's preference, done without locking light out
  (`UIUserInterfaceStyle` would). Apple's HIG prefers following the system; "match iPhone" stays a choice.
- **SwiftFormat owns formatting:** three times SwiftLint's default contradicted SwiftFormat's output; each time
  the SwiftLint side was set to agree, never the code bent.

## Tried and dropped

- `supabase/tap` in the Brewfile: brew refused the untrusted tap.
- `swift test` for the package: the package is iOS only, and supabase-swift needs macOS 13 on the host.
- Deploying from this machine with the CLI: deployments sat at UNKNOWN, blocked because the commit author
  (`arun@astronuts.io`) is not on the Vercel account. A scratch copy without `.git` deployed; the workflow
  deploys `main`, whose squash commits carry `arunkpatra@gmail.com`.
- `VERCEL_GIT_COMMIT_SHA` for `/health`: unset on CLI deploys; the workflow passes `TC_COMMIT`.

## Machine

Xcode 27.0 (27A266a), iPhone 17 simulator (iOS 26.4), bun 1.3.11, Docker Desktop 29.8, Homebrew with xcodegen
2.46.0, swiftformat 0.63.1, swiftlint 0.65.1, xcbeautify 3.2.1, supabase 2.120.0; Vercel CLI 59.25.2 logged in
as `arunkpatra-journium`; `api/` linked to `tutor-central-api`.

## Next

Phase 2 starts with its plan file. The hosted database needs `supabase db push` (owner-run) before anyone signs
in. The deferred minors in `STATE.md` are taken as their files are next touched.
