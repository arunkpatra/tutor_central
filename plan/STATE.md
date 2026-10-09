# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-09, session 16 (the Phase 8 boards and plan, on Fable 5.1). **Session 16:** Phase 0 step 0.9 done: the
website's 27 boards in row 11 of the canvas (the five pages at 1280 and 390, dark and light, as fluid frames; U7 and U24),
approved and mirrored (`1af47d1`); `plan/phase-08-plan.md` approved (14 tasks, 6 PRs, 6 owner steps); decisions D44 to D49.
**Session 15:** Phase 7 done in PRs #63 to #75; build 1.0.0 (13) on TestFlight; Phases 8 and 9 set (D42, D43).
**Next:** Phase 8's build on Opus 5.5 from `resume/016-phase-8-build.md`: PRs 1 to 3 and the owner's steps put tutorcentral.in
live and the privacy URL into App Store Connect (what Phase 9 waits for); PRs 4 to 6 and build 14 follow.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Every step approved: 0.1 to 0.9 (0.9, the website, on 2026-10-09), plus the app icon (D29) | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 Phase 4, row 8 Phase 5, row 9 Phase 6, row 10 Phase 7, row 11 (y 16000) Phase 8's pages |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 Fees, UPI settings, reminders, receipts, reports | Done, PRs #45 to #49, #51, #52 | "As built" in `phase-05-fees-and-reports.md` |
| 6 AI tools | Done, PRs #53 to #60, #62; hand run #61 | "As built" in `phase-06-ai-tools.md`; device tests in `docs/testing/device-tests.md` |
| 7 Settings, account, notifications, offline, hardening, release candidate | Done, PRs #63 to #73 | "As built" in `phase-07-settings-and-hardening.md`; the accessibility record in `docs/design/accessibility-pass.md`; the release checklist in `docs/release.md` |
| 8 Website | Boards and plan approved 2026-10-09; the build next (resume 016) | `phase-08-plan.md`: `web/` in Next.js (static export, D44) on a second Vercel project by `deploy-web.yml` (D45), pictures by `web-shots` (D46), the `web` check step (D47); U7, U16, U24 and Phase 6's minors 1, 6, 7 as PRs 4 to 6 (D48, D49) |
| 9 User testing | Not started | `phase-09-user-testing.md` (D43): tutors on TestFlight's external group, the tester's device tests, triage, before the App Store |

## In flight

Nothing open. The Phase 8 build has not started: no `web/` yet, no Vercel project `tutor-central-web`, no DNS records for the
web root (Resend's records stand). The legal pages carry `[OWNER: …]` placeholders until the owner answers Owner step 0 of the plan. TestFlight 1.0.0 (13) from `d7ee9f5` (run 37913258080) is for the owner's phone. Merged `phase-7/*` branches
remain on the remote; delete them when convenient. The tester's device tests (D1 to D7) wait for Phase 9's external group.

## Production

- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0008 (0008 `delete_account()` by deploy run
  37897295893 after PR #70) (0004
  `save_attendance` by deploy run 37758056602 after PR #37; 0005 `message_log.about_date` by run 37773505389 after PR
  #44; 0006 `pending` on `ai_status` and 0007 `start_ai_generation` by run 37829835784 after PR #53; nothing pending
  after). Migrations go up only
  through `deploy.yml`'s migrate job, before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and
  `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`api-ten-orpin-51.vercel.app`), commit `2448295` (deploy run 37897295893, after #70).
  The Sign in with Apple key (id `LZXF45DB8U`, "tutor-central-signin") is in Vercel's Production environment as
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` and in `api/.env.local`; Apple accepts its signed secret.
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays
  `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number. 1.0.0 (13) by run 37913258080 is the latest. Each run revokes the Apple Development certificate it makes (#75): a
  fresh runner makes one per run and the account's cap stopped run 12 after eleven (the owner revoked them, 2026-10-09).

## Open items

- **Phase 7 review minors (deferred):** in `plan/sessions/015/record.md`: sign-out does not stop a run in progress; a
  timed-out delete says "Nothing was removed"; the fee reminder after its day names next month with this month's count; a
  timed-out absence log can be noted twice; the API reads `APPLE_*` at boot and does not refuse `APPLE_FAKE` in production;
  two tests the plan named. Earlier phases' minors: `plan/sessions/004`, `006`, `009`, `011`, `013` records (Phase 6's 1, 6
  and 7 are Phase 8's).
- **Sign-in's buttons** follow Google's and Apple's guidelines since #74 (P7-SignIn-Google): Google's own G and colours, the three buttons pills; in build 13.
- **TestFlight's external group and Beta App Review** wait for Phase 8's `tutorcentral.in/privacy`; Phase 9 runs them (D43).
- **Vercel Preview** has no `APPLE_*` variables (Production only); nothing deploys to Preview today.
- **UI polish:** `plan/ui-polish.md`: U5, U7, U8, U10, U11, U13 to U30 open; U1 to U4, U6, U9, U12 done. U7, U16 and U24
  are Phase 8's (the owner, 2026-10-09): boards P8-Event-Edit-Keyboard, P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled; U16 needs
  none (P6-Check-Saved already draws the toast above the footer).
- **Phase 5's deferred minors** (`plan/sessions/011/record.md`) stay the owner's.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- **Device tests:** `docs/testing/device-tests.md` (S1 passed on build 9); D1 to D7 wait for the tester (Phase 9).
- Vercel's production domain for the API is the generated one; the website gets tutorcentral.in (Phase 8, D45: project
  `tutor-central-web`, variables `VERCEL_WEB_PROJECT_ID` and `WEB_ORIGIN`, the owner's steps in `phase-08-plan.md`).
- The Anthropic API key: Vercel's `ANTHROPIC_API_KEY` on `tutor-central-api` and `api/.env.local` (ignored). `AI_FAKE=1`
  is for local runs only.
- Crash reporting: no decision yet (D18 leaves it open); TestFlight's crash reports cover Phase 9.

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
