# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-09, session 13 (the Phase 6 build, on Opus 5.5). **Session 13:** Phase 6 done: PRs #53 to
#59 as the plan's six (#55 the SDK's named import for Vercel), #60 the hand run's two focus fixes, #62 the final
review's six Important fixes; the D32 hand run on issue #61, against the fake API and against Claude; D35 (the SDK) and
D36 (Scan register in Students); migrations 0006 and 0007 in production; build 0.1.0 (9) on TestFlight, the owner's
camera scan on the iPhone: "Works". The remaining device checks are a tester's: `docs/testing/device-tests.md`.
**Next:** Phase 0 step 0.8 (the Phase 7 boards) and the Phase 7 plan, on Fable.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 to 0.7 approved, plus the app icon (D29); 0.8 (Phase 7 boards) next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 the Phase 4 boards, row 8 the Phase 5 boards, row 9 the Phase 6 boards |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 Fees, UPI settings, reminders, receipts, reports | Done, PRs #45 to #49, #51, #52 | "As built" in `phase-05-fees-and-reports.md` |
| 6 AI tools | Done, PRs #53 to #60, #62; hand run #61 | "As built" in `phase-06-ai-tools.md`; device tests in `docs/testing/device-tests.md` |
| 7 Settings, account, hardening, release candidate | Not started | Scoped in `phase-07-settings-and-hardening.md`; boards are Phase 0 step 0.8 |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them) |

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

- **The owner's call (from Phase 3):** the register cache stays on disk after sign-out, as the Phase 3 plan settled; the
  final review would remove it on sign-out and write it with complete file protection, for a shared phone.
- **Review minors:** Phase 2's in `plan/sessions/004/record.md`, Phase 3's in `plan/sessions/006/record.md`, Phase 4's
  eight in `plan/sessions/009/record.md`, Phase 5's thirteen in `plan/sessions/011/record.md`, Phase 6's eleven in
  `plan/sessions/013/record.md` (among them: an 11-digit phone with a trunk 0 reads as no number; homework and
  worksheet schemes carry no marks; two concurrent calls at 39 can pass the limit; retain cycles in two AppShell
  closures).
- **Google's mark** on sign-in is a hand-drawn stand-in; Google's branding rules for the official asset are the
  owner's call before App Store review.
- **UI polish:** `plan/ui-polish.md`: U5 to U11 and U13 to U24 open (U16 to U24 from Phase 6); U1 to U4 done in #42,
  U12 in #47. U9 was offered with the Phase 5 plan and not taken.
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
