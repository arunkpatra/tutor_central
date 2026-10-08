# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-08, session 5. **Phase 0 step 0.4 approved** (the 22 Phase 3 boards, row 6 of the canvas,
mirrored into `docs/design/`). **Phase 3 planned:** `plan/phase-03-plan.md` approved by the owner. **Next:** the
Phase 3 build in a fresh Opus 5.5 session from `plan/resume/005-phase-3-build.md` (eight pull requests, then the
review). After it: Phase 0 step 0.5 (the Phase 4 boards) on Fable, or the owner's UI polish pass, or the website.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 to 0.4 approved, plus the app icon (D29); 0.5 next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Planned, not started | `phase-03-plan.md` (19 tasks, 8 PRs, one migration: 0003 `archive_class`); build from `resume/005-phase-3-build.md` |
| 4 to 7 | Not started | Scoped in their files |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them) |

## In flight

Nothing open. No branch but `main` and `pr-shots` (the merged `phase-2/*` branches remain on the remote; delete them
when convenient). `main`'s check is green; build 0.1.0 (4) is on TestFlight.

## Production

- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 and 0002. Migrations go up
  only through `deploy.yml`'s migrate job, before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and
  `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`. Phase 3 adds 0003 (`archive_class`) through the
  same lane.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`api-ten-orpin-51.vercel.app`), commit `bf6c3d2`.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays
  `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number.

## Open items

- **Design documents to correct at the end of the Phase 3 build** (plan Task 19): the "+" menu is a popover with the
  board's rows, not a system `Menu`; removal from a class is the row's context menu, not a swipe; the
  `class-archive-confirm` launch state joins the table in `information-architecture.md`.
- **Review minors** (Phase 2's final review): the list is in `plan/sessions/004/record.md`, "Deferred minors". The
  Phase 3 plan takes the ones in its files (Task 18: ASCII digits, shadows parsed once, two haptics); the rest wait
  for the polish slice or the phase that touches them.
- **Google's mark** on sign-in is a hand-drawn stand-in; Google's branding rules for the official asset are the
  owner's call before App Store review.
- **UI polish** (owner, after the first install): a pass over the built screens; seen so far: Today's content
  scrolls under the status bar. Its own slice with its own boards where anything changes.
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
