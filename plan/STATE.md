# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-09, session 14 (the Phase 7 boards and the Phase 7 plan, on Fable 5.1). **Session 14:** Phase 0
step 0.8 done: 41 boards in row 10 of the canvas, approved and mirrored (`docs/design/mockups/P7-*`); `plan/phase-07-plan.md`
written and approved (23 tasks, 8 pull requests; D37 to D40 to be numbered in the pull requests that act on them); the
owner chose option A for deletion (`delete_account()` as a `security definer`, proven locally) plus Apple token revocation
through the API; the polish slice and Phase 6's minors 1, 6 and 7 moved to Phase 8; `docs/testing/device-tests.md` gained
D1 to D7; `resume/014-phase-7-build.md` written. No code.
**Next:** the Phase 7 build on Opus 5.5 from `resume/014-phase-7-build.md`.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Boards complete: 0.1 to 0.8 approved (0.8 on 2026-10-09), plus the app icon (D29) | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 Phase 4, row 8 Phase 5, row 9 Phase 6, row 10 Phase 7 |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 Fees, UPI settings, reminders, receipts, reports | Done, PRs #45 to #49, #51, #52 | "As built" in `phase-05-fees-and-reports.md` |
| 6 AI tools | Done, PRs #53 to #60, #62; hand run #61 | "As built" in `phase-06-ai-tools.md`; device tests in `docs/testing/device-tests.md` |
| 7 Settings, account, notifications, offline, hardening, release candidate | Planned, not built | `phase-07-plan.md` approved 2026-10-09; the boards in row 10; the build is resume 014 |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them; TestFlight's external group needs the privacy URL too); plus the polish slice and Phase 6's minors 1, 6, 7 (the owner, 2026-10-09) |

## In flight

Nothing open. No open branch: the merged `phase-*` branches remain on the remote, and Phase 4's and 5's also in the
local checkout (squash-merged, so `git branch -D`); delete them when convenient. `main`'s check is green; build 0.1.0 (9) is on TestFlight. A tester runs `docs/testing/device-tests.md` on
a test centre (production AI, the daily limits apply) and writes the log there.

## Production

- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0007 (0004
  `save_attendance` by deploy run 37758056602 after PR #37; 0005 `message_log.about_date` by run 37773505389 after PR
  #44; 0006 `pending` on `ai_status` and 0007 `start_ai_generation` by run 37829835784 after PR #53; nothing pending
  after). Migrations go up only
  through `deploy.yml`'s migrate job, before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and
  `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`api-ten-orpin-51.vercel.app`), commit `6eea8b8` (deploy run 37869867840, after #62).
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays
  `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number.

## Open items

- **Settled by the Phase 7 plan (D40, in PR 4 of the build):** the register cache and every other cache go on sign-out and
  after deletion; caches are written with complete file protection. (The Phase 3 open call, closed.)
- **Review minors:** Phase 2's in `plan/sessions/004/record.md`, Phase 3's in `plan/sessions/006/record.md`, Phase 4's
  eight in `plan/sessions/009/record.md`, Phase 5's thirteen in `plan/sessions/011/record.md`, Phase 6's eleven in
  `plan/sessions/013/record.md` (its 1, 6 and 7, the retain cycles, the trunk-0 phone and the grapheme limits, are
  Phase 8's: the owner, 2026-10-09; the rest stay the owner's).
- **Google's mark** on sign-in is a hand-drawn stand-in; the Phase 7 plan (Task 18, step 8) offers Google's official
  sign-in logo asset; the owner has not yet said to take it.
- **Phase 8 before Beta App Review:** TestFlight's external group needs the privacy policy URL; the Phase 7 plan's Task 22
  step 5 waits for `tutorcentral.in/privacy`. Everything up to the internal build proceeds.
- **The Sign in with Apple key** (the owner's step 1 of the Phase 7 build): a `.p8` from the developer portal into
  Vercel (`APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY`) and `api/.env.local`; the deploy after PR 2 needs it.
- **UI polish:** `plan/ui-polish.md`: U5 to U11 and U13 to U24 open (U16 to U24 from Phase 6); U1 to U4 done in #42,
  U12 in #47. U6, U7, U9, U16 and U24 are Phase 8's (the owner, 2026-10-09); Phase 7 takes none.
- **Phase 5's deferred minors** (the final review's, `plan/sessions/011/record.md`): a failed read's toasts and the ₹0
  ledger under the error line, Reports' Share while loading, "The's fee" fallback copy, one retry slot for reads and
  writes, a double haptic, the UPI field's double write and autocorrect, archived students in Reports' attendance, a
  failed due-before read failing the month, a QR image kept when its id did not save, CSV formula injection.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- Phase 6's answer to Vercel's 4.5 MB body: photos are reduced on the device to 2000 px JPEG; no Storage. Six pages
  went through against Claude (16,871 tokens in, 16 s).
- **Device tests:** `docs/testing/device-tests.md` (S1 passed on build 9, the owner); the rest wait for the tester.
- Vercel's production domain is the generated one; a nicer domain is the owner's call (tutorcentral.in exists).
- The Anthropic API key (the owner, 2026-10-09): Vercel's `ANTHROPIC_API_KEY` on `tutor-central-api` and
  `api/.env.local` (ignored). `AI_FAKE=1` is for local runs only.
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
