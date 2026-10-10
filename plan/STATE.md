# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-10, session 21 (the Phase 10 boards, on Fable 5.1). **Session 21:** Part A of Phase 10 done: steps 10.1 to 10.7
approved by the owner and mirrored (96 boards in rows 14 to 20 of the canvas; `docs/design/information-architecture.md` "Phase 10 boards",
`components.md` "Phase 10 parts", `design-tokens.md`); the owner's rulings: "Batch everywhere" for V1's class on screen (the table stays
`classes`), the WhatsApp consent ask optional; `resume/020-phase-10-build.md` written; the record in `plan/sessions/021/`. **Next:** Part B
(the plumbing) on Opus from `resume/020-phase-10-build.md` (it may already be running); then Phase 11's plan on Fable from
`resume/021-phase-11-boards-and-plan.md`, which Part B's Task 10 writes. **Session 19:** the Phase 9 run began (on Opus 5.5).
**Phase 9's next:** each later session opens from `plan/resume/018-phase-9-run.md` with what the owner brings: Apple's answer on build 18
(approved, or a message to answer), the tester's lines for D1 to D6 and D8 (Task 4, sent to the tester on 2026-10-09), then
D7 and the invitations (Task 5, where the testers' facts T1 to T6 are filled and checked against D52 first), then the readings
(Task 6, Monday and Thursday).

**App Store page (D51):** filled and saved by the owner on 2026-10-09, not submitted (the version page, App Information, App
Privacy published, 4+, App Review Information with the demo account `review@tutorcentral.in`, seeded by `seed-review` #89,
every parent +919611385678). Left for Phase 9's end (Owner step 6): attach the final build, Add for Review, Submit.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Every step approved: 0.1 to 0.9 (0.9, the website, on 2026-10-09), plus the app icon (D29) | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 Phase 4, row 8 Phase 5, row 9 Phase 6, row 10 Phase 7, row 11 (y 16000) Phase 8's pages, row 12 U33, row 13 the Store boards, rows 14 to 20 (y 37200 on) Phase 10's steps |
| 1 Foundation | Done, PRs #1 to #8 | "As built" in `phase-01-foundation.md` |
| 2 Shell and sign-in | Done, PRs #9 to #23 | "As built" in `phase-02-shell-and-sign-in.md` |
| 3 Students and classes | Done, PRs #24 to #31 | "As built" in `phase-03-students-and-classes.md` |
| 4 Attendance, schedule, tasks, Today live | Done, PRs #36 to #42, review fixes #44 | "As built" in `phase-04-attendance-schedule-today.md`; closed U1 to U4 |
| 5 Fees, UPI settings, reminders, receipts, reports | Done, PRs #45 to #49, #51, #52 | "As built" in `phase-05-fees-and-reports.md` |
| 6 AI tools | Done, PRs #53 to #60, #62; hand run #61 | "As built" in `phase-06-ai-tools.md`; device tests in `docs/testing/device-tests.md` |
| 7 Settings, account, notifications, offline, hardening, release candidate | Done, PRs #63 to #73 | "As built" in `phase-07-settings-and-hardening.md`; the accessibility record in `docs/design/accessibility-pass.md`; the release checklist in `docs/release.md` |
| 8 Website | Done, PRs #76 to #82 | "As built" in `phase-08-website.md`; then #83 to #89 after the close (the 30-day words, the crash fix, the minors, U33, the sheet title, store-shots, seed-review) |
| 9 User testing | Running since session 19 (2026-10-09) | `phase-09-plan.md` (D52 to D55): Tasks 1 to 3 done, build 18 in Beta App Review; Task 4 (the tester) next; the run by `resume/018-phase-9-run.md`; findings in `phase-09-findings.md` |
| 10 to 16 V2 (`docs/spec-v2.md`) | Phase 10 running (session 21) | Scope files `phase-10-v2-design-and-foundation.md` to `phase-16-release.md`; `phase-10-plan.md`: Part A done: 96 boards in rows 14 to 20 (`docs/design/mockups/P10-*`); Part B on Opus from `resume/020-phase-10-build.md` |

## In flight

Nothing open on GitHub. Phase 9 (session 19): Tasks 1 and 2 done (the API at `999e881`, run 37965871936; the checklist and
build 18's notes; the guide and the findings file); Owner steps 1 to 3 done: Test Information saved, the "Tutors" group made,
**build 18 submitted to Beta App Review on 2026-10-09 (Waiting for Review)**. Next: Task 4, the tester's D1 to D6 and D8 on
the internal install while Apple reviews; D7 and the invitations after approval. The testers' facts (T1 to T6) wait for
Owner step 4 (the owner does not know the tutors yet). No reading yet. TestFlight 1.0.0 (18) from run 37950611572 is the candidate for Beta App Review. The remote holds
`main`, `pr-shots` and two branches of merged pull requests (`tools/review-seed`, `tools/store-shots`), the owner's to delete.

## Production

- **Website:** tutorcentral.in on Vercel `tutor-central-web` (id in `VERCEL_WEB_PROJECT_ID`, root `web`, git deploys off),
  deployed only by `deploy-web.yml` (D45), at `e455ba0` (run 37943683483, "normally within 30 days"), smoke green. GoDaddy DNS:
  `A @ 216.198.79.1`, `www` CNAME → `tutorcentral.in` (Vercel redirects www with a 307); Resend's records and
  `api.tutorcentral.in` (a CNAME to Vercel, attached to `tutor-central-api`) untouched. `APP_STORE_URL` unset (Home shows the
  email call to action) until the app is in the App Store.
- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0008 (0008 `delete_account()` by deploy
  run 37897295893 after PR #70; nothing pending after). Migrations go up only through `deploy.yml`'s migrate job, before the
  API (D26); secrets `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`https://api.tutorcentral.in` since build 16; the generated
  `api-ten-orpin-51.vercel.app` still answers for builds 15 and earlier), commit `999e881` (deploy run 37965871936, 2026-10-09, Phase 9's Task 1: #81's phone trunk 0 and D48's limits are
  live); nothing pending in the database.
  The Sign in with Apple key (id `LZXF45DB8U`, "tutor-central-signin") is in Vercel's Production environment as
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` and in `api/.env.local`; Apple accepts its signed secret.
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number. 1.0.0 (18) by run 37950611572 (the sheet title, #87) is on TestFlight's internal group; 17 by run 37948604787
  (U33, #86); 16 by run 37944725866 (the API at api.tutorcentral.in); 15 by run 37943689238 (the crash fix #84, the minors
  #85, "normally within 30 days" #83). `ITSAppUsesNonExemptEncryption` is false in `Info.plist`, so no build waits on a
  compliance question. Each run revokes the Apple Development certificate it makes (#75).

## Open items

- **Phase 9:** the owner's seven App Store Connect steps are in `phase-09-plan.md` (Tasks 3, 5, 7, 8); the tester's D1 to D8
  before the tutors (D52); the three-week clock starts at Owner step 4.
- **Phase 8 review minors (deferred):** in `plan/sessions/017/record.md` (nine; one is the owner's wording: "deletes it
  within 30 days" is absolute while Anthropic keeps flagged inputs longer; also the terms' "What it costs" for him to read).
- **Phase 7 review minors (deferred):** in `plan/sessions/015/record.md`: sign-out does not stop a run in progress; a
  timed-out delete says "Nothing was removed"; the fee reminder after its day names next month with this month's count; a
  timed-out absence log can be noted twice; the API reads `APPLE_*` at boot and does not refuse `APPLE_FAKE` in production;
  two tests the plan named. Earlier phases' minors: `plan/sessions/004`, `006`, `009`, `011`, `013` records (Phase 6's 1, 6
  and 7 done in #81).
- **Sign-in's buttons** follow Google's and Apple's guidelines since #74 (P7-SignIn-Google).
- **Vercel Preview** has no `APPLE_*` variables (Production only); nothing deploys to Preview today.
- **UI polish:** `plan/ui-polish.md`: U5, U8, U10, U11, U13 to U15, U17 to U23, U25 to U30, U32 open; U1 to U4, U6, U7, U9,
  U12, U16, U24, U31, U33 done. Phase 9's Polish findings add rows; none is taken in the phase unless the owner says.
- **Phase 5's deferred minors** (`plan/sessions/011/record.md`) stay the owner's.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- **Device tests:** `docs/testing/device-tests.md` (S1 passed on build 9); D1 to D8 run in Phase 9's Task 4.
- The Anthropic API key: Vercel's `ANTHROPIC_API_KEY` on `tutor-central-api` and `api/.env.local` (ignored). `AI_FAKE=1`
  is for local runs only.
- Crash reporting: no decision yet (D18 leaves it open); TestFlight's crash reports cover Phase 9 (D55's readings).
- After App Store approval (a later slice): `APP_STORE_URL` on Vercel's `tutor-central-web`, then `gh workflow run deploy-web`
  for Home's badge (D47).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
