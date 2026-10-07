# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-07, session 3. **Phase 2 planned.** `plan/phase-02-plan.md` (17 tasks, 9 pull requests,
tests first, owner steps in Tasks 9 and 16) was approved by the owner; decisions D24 (TestFlight lane) and D25
(tokens as Swift) were taken. **Next:** the build in a fresh Opus 5.5 session from `resume/003-phase-2-build.md`.
Step 0.4 on the design side when the owner wants it.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1, 0.2 and 0.3 approved; 0.4 next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/directions/`; plan `phase-00-plan.md` |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md`. API in production through `deploy.yml` |
| 2 Shell and sign-in | Planned: `phase-02-plan.md`; build from `resume/003-phase-2-build.md` | Boards approved (step 0.3). Owner steps inside Tasks 9 (App Store Connect, Supabase providers, Google web client, email template, legal URLs) and 16 (API key, secrets, first install) |
| 3 to 7 | Not started | Scoped in their files |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in (the owner bought it); `/privacy` and `/terms` must be live before the first App Store submission; the app already links them |

## In flight

Nothing open. No branch but `main` and `pr-shots`.

## Open items

- Hosted Supabase is `esowihbxawvoexflekxa` in ap-south-1 (Mumbai), beside the API in `bom1`, with migration 0001
  (pushed 2026-10-07; checked: signed-out callers are refused on every table and function). Vercel's
  `SUPABASE_URL` and `SUPABASE_ANON_KEY` point at it (Production and Preview). The first project, created in
  Tokyo by mistake, was deleted by the owner.
  Migrations go up only through `deploy.yml` (D26, decided in session 4; built in Phase 2 Task 10b). Migration
  0002 is merged or in review and waits for that lane; it is not on the hosted project.
- Vercel: production domain is `api-ten-orpin-51.vercel.app` (repo variable `API_ORIGIN`); a nicer domain is
  the owner's call.
- Vercel Hobby blocks deployments whose commit author it does not know. This repo's git email is
  `arunkpatra@gmail.com`; keep it so (a direct commit to `main` by another address cannot be deployed).
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one.
- Phase 2, settled by its plan (`phase-02-plan.md`, "Decisions this plan settles"):
  - The password-entry state behind "Use my password instead" had no board; `P2-Email-Password` was drawn in
    session 3 (canvas row 5, `docs/design/mockups/`) and approved by the owner. Task 10 step 7 builds it.
  - The two legal URLs (terms, privacy) are the owner's; asked once at Task 9.
  - Email goes through custom SMTP with Resend from tutorcentral.in (D30): set up in Phase 2's owner steps.
  - The Today board has no AI tools row; Phase 6's board draws it.
- Deferred from the Phase 1 review (minor; the Phase 2 plan takes most of them in Tasks 3 and 4; the brew pins
  stay, Homebrew cannot pin a formula, and the Phase 6 image size is not this phase):
  - Supabase's default privileges still grant anon on future tables and functions. RLS protects; add an
    `alter default privileges … revoke … from anon` migration or an anon-grant check in the catalogue test.
  - `tools/check/steps.ts` is not among the steps' inputs, so a changed step command keeps its old stamp locally.
  - The four brew tools are unpinned in CI. The salt makes drift loud, not silent.
  - `check.yml`'s `cancel-in-progress` also cancels `main`'s `--fresh` runs; limit it to pull requests.
  - `deploy.yml` passes `--token` on the command line; the CLI reads `VERCEL_TOKEN` from the environment.
  - Phase 6 constraint: six 8 MB base64 images exceed Vercel's 4.5 MB request body. Downscale on the device or
    upload to Storage.
  - `pr-shots`: pictures render on a PR page — settled, the owner saw them on PR #10 (2026-10-07); how to check
    one without a browser is in `CLAUDE.md` rule 2. The refusals (duplicate basenames, folders with "/") are in
    PR #11.
  - A fresh clone without `ios/Config/Local.xcconfig` fails inside XcodeGen; give a one-line hint.
  - `supabase/types.ts` drift is not checked in the `db` step.
- Apple: App ID `in.tutorcentral.app` (Sign in with Apple) and the App Store Connect record "Tutor Central" exist (owner, 2026-10-07). Team ID `Y7SW6436RD`: the repository variable `APPLE_TEAM_ID` for the TestFlight lane (D24).
- App icon: settled, D29 (P2-AppIcon C3, in the app with PR #19).
- Accounts the owner creates when a phase needs them, one step at a time: App Store Connect app record and API key
  (Phase 2), Google OAuth client (Phase 2), Anthropic API key (Phase 6).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
