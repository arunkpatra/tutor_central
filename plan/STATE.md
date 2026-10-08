# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-09, session 12 (the Phase 6 boards and plan, on Fable 5.1). **Session 11:** Phase 5 done: PRs #45 to #49 and
#51 as the plan's six, #52 the hand run's and the final review's fixes (four Important: Undo after paying a waived fee,
Settings' stale workspace, the camera's permission and the scanner's way out); the D32 hand run on issue #50 (two bugs
found and fixed); D34 (a waived month offers Mark paid alone, the owner's call); no migration; build 0.1.0 (8) on
TestFlight, tested by the owner on the iPhone (the QR camera included): all good. **Session 12:** Phase 0 step 0.7 done (44 boards in row 9, approved), `phase-06-plan.md` approved (20 tasks, 6 PRs, two migrations,
the SDK dependency D35 and Scan register in Students D36 to be numbered in their PRs), `resume/012-phase-6-build.md` written. No
code. **Next:** the Phase 6 build on Opus 5.5 from `resume/012-phase-6-build.md`.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 to 0.7 approved, plus the app icon (D29); 0.8 (Phase 7 boards) next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 the Phase 4 boards, row 8 the Phase 5 boards, row 9 the Phase 6 boards |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 Fees, UPI settings, reminders, receipts, reports | Planned: boards approved, plan approved (session 10) | `phase-05-plan.md`; build from `resume/010-phase-5-build.md` |
| 6 and 7 | Not started | Scoped in their files |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them) |

## In flight

Nothing open. No branch but `main` and `pr-shots` (the merged `phase-*` branches remain on the remote; delete them when
convenient). `main`'s check is green; build 0.1.0 (8) is on TestFlight and the owner tested it, the QR camera
included: all good.

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
  eight in `plan/sessions/009/record.md`, Phase 5's thirteen in `plan/sessions/011/record.md`.
- **Google's mark** on sign-in is a hand-drawn stand-in; Google's branding rules for the official asset are the
  owner's call before App Store review.
- **UI polish:** `plan/ui-polish.md`: U5 to U11 and U13 to U15 open; U1 to U4 done in #42, U12 in #47. U9 was offered
  with the Phase 5 plan and not taken.
- **Phase 5's deferred minors** (the final review's, `plan/sessions/011/record.md`): a failed read's toasts and the ₹0
  ledger under the error line, Reports' Share while loading, "The's fee" fallback copy, one retry slot for reads and
  writes, a double haptic, the UPI field's double write and autocorrect, archived students in Reports' attendance, a
  failed due-before read failing the month, a QR image kept when its id did not save, CSV formula injection.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- Phase 6's answer to Vercel's 4.5 MB body: photos are reduced on the device to 2000 px JPEG (the plan's decisions table);
  no Storage.
- Vercel's production domain is the generated one; a nicer domain is the owner's call (tutorcentral.in exists).
- Accounts still to create when their phase needs them: the Anthropic API key (Phase 6, Task 20 steps 1 and 2: into Vercel's
  `ANTHROPIC_API_KEY` and `api/.env.local`, after PR 2 and before the deploy).
- Crash reporting: no decision yet (D18 leaves it open).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
