# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 2. **Phase 1 built.** The repo has the iOS project (the app launches dark
to a placeholder), the Supabase schema with RLS and its tests, the Hono API on Vercel, `bun check` with its
cache, CI on every pull request, and the screenshot tools. Decisions D21 (deploys by hand through `deploy.yml`),
D22 (CI on `xcode-27`, iPhone 17 everywhere) and D23 (dark by default) were taken. The API is in production through `deploy.yml`
(`https://api-ten-orpin-51.vercel.app`, `bom1`). **Next:** Phase 2 (shell and sign-in) from its plan, which Phase
0's approved Phase 2 boards make possible; step 0.4 on the design side when the owner wants it.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1, 0.2 and 0.3 approved; 0.4 next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/directions/`; plan `phase-00-plan.md` |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md`. API in production through `deploy.yml` |
| 2 to 7 | Not started | Scoped in their files. Phase 2 starts with its plan file |

## In flight

Nothing open. No branch but `main` and `pr-shots`.

## Open items

- Hosted Supabase (`ctxtacacrbkrmctluahk`, Mumbai) has no schema yet: `supabase db push`, owner-run (his database
  password), before Phase 2 signs anyone in. Moving migrations into CI is a later decision.
- Vercel: a stray project `api` (errored) in "Arun's projects" is the owner's to delete. Production domain is
  `api-ten-orpin-51.vercel.app` (repo variable `API_ORIGIN`); a nicer domain is the owner's call.
- Vercel Hobby blocks deployments whose commit author it does not know. This repo's git email is
  `arunkpatra@gmail.com`; keep it so (a direct commit to `main` by another address cannot be deployed).
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one.
- Deferred from the Phase 1 review (minor; take them when their files are next touched):
  - Supabase's default privileges still grant anon on future tables and functions. RLS protects; add an
    `alter default privileges … revoke … from anon` migration or an anon-grant check in the catalogue test.
  - `tools/check/steps.ts` is not among the steps' inputs, so a changed step command keeps its old stamp locally.
  - The four brew tools are unpinned in CI. The salt makes drift loud, not silent.
  - `check.yml`'s `cancel-in-progress` also cancels `main`'s `--fresh` runs; limit it to pull requests.
  - `deploy.yml` passes `--token` on the command line; the CLI reads `VERCEL_TOKEN` from the environment.
  - Rule 6's "every table has id, centre_id…" really means every centre table (`centre_members` and `profiles`
    are tenancy tables). Also `docs/spec.md` section 4 says `ios/TutorCentral`; the package is
    `ios/TutorCentralKit`. Both are wording for the owner to approve.
  - Phase 6 constraint: six 8 MB base64 images exceed Vercel's 4.5 MB request body. Downscale on the device or
    upload to Storage.
  - `pr-shots`: see a picture render on a PR page on the first screen PR; refuse duplicate basenames and
    folders containing "/".
  - A fresh clone without `ios/Config/Local.xcconfig` fails inside XcodeGen; give a one-line hint.
  - `supabase/types.ts` drift is not checked in the `db` step.
- App icon: a Phase 0 board (name settled as Tutor Central, D20).
- Accounts the owner creates when a phase needs them, one step at a time: App Store Connect app record and API key
  (Phase 2), Google OAuth client (Phase 2), Anthropic API key (Phase 6).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
