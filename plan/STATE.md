# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-08, session 8 (Phase 0 step 0.5 and the Phase 4 plan, on Fable). Session 7: the simulator runbook
(D32, issue #34, PR #35). Session 6: Phase 3 done (PRs #24 to #31, review fixes #33); build 0.1.0 (6) on TestFlight
(build 5 has a save bug: do not use it). **Session 8:** the 27 Phase 4 boards are approved (row 7 of the canvas,
`docs/design/mockups/P4-*`; the Kit's attendance row redrawn as one pill); `plan/phase-04-plan.md` is approved (20
tasks, 7 PRs, migration 0004 `save_attendance`); the owner took U1 (the status bar on glass) and U4 (tiles share a
height, seen on build 6) into Phase 4 with U2 and U3. **Next:** the Phase 4 build in a fresh Opus 5.5 session from
`plan/resume/008-phase-4-build.md`.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | In progress: 0.1 to 0.5 approved, plus the app icon (D29); 0.6 (Phase 5 boards) next | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 the Phase 4 boards |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Planned: boards and `phase-04-plan.md` approved 2026-10-08; build next (resume 008, Opus 5.5) | Closes U1 to U4 |
| 5 to 7 | Not started | Scoped in their files |
| 8 Website | Not started | `phase-08-website.md`: tutorcentral.in; `/privacy` and `/terms` live before the first App Store submission (the app links them) |

## In flight

Nothing open. No branch but `main` and `pr-shots` (the merged `phase-2/*` and `phase-3/*` branches remain on the
remote; delete them when convenient). `main`'s check is green; build 0.1.0 (6) is on TestFlight (build 5 has the save bug: do not use it).

## Production

- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0003 (0003
  `archive_class` by deploy run 37724513096 after PR #25; nothing pending at run 37731454614). Migrations go up only
  through `deploy.yml`'s migrate job, before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and
  `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`api-ten-orpin-51.vercel.app`), commit `7a5596a`.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays
  `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number.

## Open items

- **Build 6 on the owner's phone:** one thing reported (session 8): the "Classes today" tile is taller than the other
  two (U4, taken into Phase 4). Nothing else reported yet.
- **The owner's call:** the register cache (children's names, parents' numbers, notes) stays on disk after sign-out,
  as the Phase 3 plan settled; the final review would remove it on sign-out and write it with complete file
  protection, for a shared phone.
- **Board content to confirm:** P3-Students-Searching draws "3 of 10 match" for "sh"; the rule finds 4 (Lakshmi).
- **Review minors:** Phase 2's remaining list is in `plan/sessions/004/record.md` (Phase 3 took the digits,
  shadows and haptics); Phase 3's deferred minors are in `plan/sessions/006/record.md`.
- **Google's mark** on sign-in is a hand-drawn stand-in; Google's branding rules for the official asset are the
  owner's call before App Store review.
- **UI polish:** `plan/ui-polish.md`: U1 to U4 are taken into Phase 4 (they move to Done with PR 7 of its plan). Items
  are taken when the owner chooses, singly or as a slice; a board first where what is seen changes.
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
