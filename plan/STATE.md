# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-08, session 10 (the Phase 5 boards, on Fable). **Session 10:** Phase 0 step 0.6 done: 27 Phase 5 boards in row 8 of the canvas, approved by the owner, mirrored into `docs/design/`; the Phase 5 plan in progress. Before that, session 9 (Phase 4 built, on Opus 5.5). **Session 9:** Phase 4 done: PRs #36 to #42 as
the plan's seven, the final review's fixes #44 (one Critical, four Important); migrations 0004 `save_attendance` and
0005 `message_log.about_date` in production; the D32 hand run of every Phase 4 write path (issue #43, four bugs found
and fixed); build 0.1.0 (7) on TestFlight, tested on the owner's iPhone: all good. U1 to U4 done. The schedule's
14-day Coming up confirmed; the boards' figures are illustrative, so none is redrawn. **Next:** Phase 0 step 0.6 (the
Phase 5 boards) and the Phase 5 plan on Fable, from `resume/009-phase-5-boards-and-plan.md`.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 to 0.6 approved, plus the app icon (D29); 0.7 (Phase 6 boards) next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 the Phase 4 boards, row 8 the Phase 5 boards |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 to 7 | Not started | Scoped in their files |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them) |

## In flight

Nothing open. No branch but `main` and `pr-shots` (the merged `phase-2/*`, `phase-3/*` and `phase-4/*` branches remain on
the remote; delete them when convenient). `main`'s check is green; build 0.1.0 (7) is on TestFlight.

## Production

- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0005 (0004
  `save_attendance` by deploy run 37758056602 after PR #37; 0005 `message_log.about_date` by run 37773505389 after PR
  #44; nothing pending after). Migrations go up only
  through `deploy.yml`'s migrate job, before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and
  `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`api-ten-orpin-51.vercel.app`), commit `8e79ce0` (deploy run 37773505389).
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays
  `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number.

## Open items

- **The owner's call (from Phase 3):** the register cache stays on disk after sign-out, as the Phase 3 plan settled; the
  final review would remove it on sign-out and write it with complete file protection, for a shared phone.
- **Review minors:** Phase 2's in `plan/sessions/004/record.md`, Phase 3's in `plan/sessions/006/record.md`, Phase 4's
  eight in `plan/sessions/009/record.md`.
- **Google's mark** on sign-in is a hand-drawn stand-in; Google's branding rules for the official asset are the
  owner's call before App Store review.
- **UI polish:** `plan/ui-polish.md`: U5 to U12 open (seen in session 9); U1 to U4 done in #42.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- Phase 6 constraint: six 8 MB base64 images exceed Vercel's 4.5 MB request body. Downscale on the device or upload
  to Storage.
- Vercel's production domain is the generated one; a nicer domain is the owner's call (tutorcentral.in exists).
- Accounts still to create when their phase needs them: Anthropic API key (Phase 6).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
