# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-10, session 22 (Phase 10 Part B, on Opus 5.5). **Session 22:** Phase 10 done. Part B, the plumbing,
merged as PRs #90 to #96: migrations 0009 to 0016 (the V2 tables, `close_session`, `copy_textbook_chapters`, the `photos`
bucket, the monthly allowance, the syllabus data for CBSE and Karnataka state, classes 8 to 10), the API's four V2 routes
answering 501, the iOS Domain types and Phase 11's repositories, the share extension (embedded) and background refresh;
a fresh review on Fable 5.1, its three Important findings fixed in #96. Both deploys done, nothing pending; TestFlight 1.0.0 (19), run 38047105651, the first with the share extension: archived, cloud-signed and uploaded (it shows no new screen; the share sheet gains the "Tutor Central" entry, which saves and does nothing visible until Phase 13).
**The owner, 2026-10-10 (D66):** V2 is the product; V1 was the proof of concept. Phase 9's tester run on V1 is cancelled;
the tutor round is Phase 15's, on V2. **Next:** Phase 11's plan on Fable from `resume/021-phase-11-boards-and-plan.md`
(its boards are Phase 10's, approved), then its build on Opus.

**App Store page (D51):** filled and saved by the owner on 2026-10-09, not submitted. With D66 the first submission is V2's
(Phase 16); the page's words and screenshots are redone there.

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
| 9 User testing | Cancelled by the owner, 2026-10-10 (D66) | V1 was the proof of concept; the tutor round is Phase 15's, on V2, by Phase 9's method (D52 to D55); `phase-09-plan.md` kept as that method |
| 10 V2 design and foundation | Done (sessions 21 and 22, 2026-10-10) | Part A: 96 boards in rows 14 to 20 (`docs/design/mockups/P10-*`); Part B: PRs #90 to #96; "As built" in `phase-10-v2-design-and-foundation.md` |
| 11 to 16 V2 (`docs/spec-v2.md`) | Phase 11 next | Scope files `phase-11-record-and-close.md` to `phase-16-release.md`; Phase 11's plan from `resume/021-phase-11-boards-and-plan.md` |

## In flight

Nothing open on GitHub after #96. Build 19 is on the owner's iPhone from the internal group, the V1 screens fine (the owner, 2026-10-10). The remote holds `main`, `pr-shots`, and the merged branches
`tools/review-seed`, `tools/store-shots` and `phase-10/*` (seven), the owner's to delete. Build 18's Beta App Review for the "Tutors" group was withdrawn by the owner (2026-10-10, D66).

## Production

- **Website:** tutorcentral.in on Vercel `tutor-central-web` (id in `VERCEL_WEB_PROJECT_ID`, root `web`, git deploys off),
  deployed only by `deploy-web.yml` (D45), at `e455ba0` (run 37943683483, "normally within 30 days"), smoke green. GoDaddy DNS:
  `A @ 216.198.79.1`, `www` CNAME → `tutorcentral.in` (Vercel redirects www with a 307); Resend's records and
  `api.tutorcentral.in` (a CNAME to Vercel, attached to `tutor-central-api`) untouched. `APP_STORE_URL` unset (Home shows the
  email call to action) until the app is in the App Store.
- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0016: 0009 to 0013 by deploy run
  38042680418 (after #90, #91, #92), 0014 to 0016 by deploy run 38046925061 (after #93 to #96); nothing pending after. The
  `photos` bucket (private, JPEG, 3 MB, add-only) is made by 0011. Migrations go up only through `deploy.yml`'s migrate job,
  before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`https://api.tutorcentral.in` since build 16; the generated
  `api-ten-orpin-51.vercel.app` still answers for builds 15 and earlier), commit `d98e8e5` (deploy run 38046925061,
  2026-10-10: the four V2 routes answer 401 without a token and 501 after validation); nothing pending in the database.
  The Sign in with Apple key (id `LZXF45DB8U`, "tutor-central-signin") is in Vercel's Production environment as
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` and in `api/.env.local`; Apple accepts its signed secret.
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  The share extension `in.tutorcentral.app.share` and the app group `group.in.tutorcentral` (on both App IDs) were
  registered by the owner on 2026-10-10; the extension is embedded from build 19.
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number. 1.0.0 (19) by run 38047105651 (Phase 10: the share extension and the background refresh; nothing new on screen) on the internal group (the owner's iPhone: V1 screens fine); 1.0.0 (18) by run 37950611572 (the sheet title, #87) is on TestFlight's internal group; 17 by run 37948604787
  (U33, #86); 16 by run 37944725866 (the API at api.tutorcentral.in); 15 by run 37943689238 (the crash fix #84, the minors
  #85, "normally within 30 days" #83). `ITSAppUsesNonExemptEncryption` is false in `Info.plist`, so no build waits on a
  compliance question. Each run revokes the Apple Development certificate it makes (#75).

## Open items

- **Phase 10 review minors (deferred):** the `Final: minor (deferred)` lines of `plan/sessions/022/ledger.md` (eight), and
  the contracts later phases build to in the phase file's "As built, Part B" (photos add-only and not yet deleted with a
  student; "today's" in the limit's words; `FigureSpec`'s wire format; shared images named `.jpg`).
- **The syllabus data's soft spots** (`supabase/syllabi/`): English skills are short names for each lesson's task headings;
  a few chapters took their key topics where they print fewer than three headings; some Karnataka headings were read by
  OCR. A correction is a JSON edit, `bun syllabi`, and a new migration (0014 and 0015 have run).
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
  U12, U16, U24, U31, U33 done. Rows for screens V2 rebuilds are taken or closed as Phase 11 on touch those screens.
- **Phase 5's deferred minors** (`plan/sessions/011/record.md`) stay the owner's.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- **Device tests:** `docs/testing/device-tests.md` (S1 passed on build 9); D1 to D8 were Phase 9's and now run on V2 before
  Phase 15's round.
- The Anthropic API key: Vercel's `ANTHROPIC_API_KEY` on `tutor-central-api` and `api/.env.local` (ignored). `AI_FAKE=1`
  is for local runs only.
- Crash reporting: no decision yet (D18 leaves it open); TestFlight's crash reports until Phase 15's round.
- After App Store approval (a later slice): `APP_STORE_URL` on Vercel's `tutor-central-web`, then `gh workflow run deploy-web`
  for Home's badge (D47).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
