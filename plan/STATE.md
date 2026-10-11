# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-12, session 32 (Phase 15 built, on Opus 5.5). **Session 32:** the plan's twelve pull requests
(#152 to #165), the D62 fix for Check a paper (#166), the fifteen hand runs (issue #174) and their fixes (#167 to #173, #176),
the cost run (30 calls, ₹22.54; the price sheet #175), the review on Fable 5.1 with every finding fixed (#177 to #183), 0026
and 0027 deployed, the trust page live, the TestFlight build (below); the record in `plan/sessions/032/`.
**Next:** the round (Tasks 18 to 23 of `phase-15-plan.md`) from `resume/030-phase-15-build.md` (its step 8, pasted at each session of the round), starting with one question
to the owner: did the Phase 15 build pass on his iPhone (D68)? Then the release notes, the guide, his App Store Connect steps
one at a time, the tester's device checks, the invitations (about 21 October), the readings Monday and Thursday.

**App Store page (D51):** filled and saved by the owner on 2026-10-09, not submitted. With D66 the first submission is V2's
(Phase 16); the page's words and screenshots are redone there.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Every step approved: 0.1 to 0.9 (0.9, the website, on 2026-10-09), plus the app icon (D29) | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 Phase 4, row 8 Phase 5, row 9 Phase 6, row 10 Phase 7, row 11 (y 16000) Phase 8's pages, row 12 U33, row 13 the Store boards, rows 14 to 20 (y 37200 on) Phase 10's steps, row 21 (y 47000) Phase 12's two boards, row 22 (y 48400) the AI forms' class, row 23 (y 49800) Phase 13's three boards (approved 2026-10-11), row 24 (y 51200) Phase 14's seven boards (approved 2026-10-11), row 25 (y 52600) Phase 15's five boards (approved 2026-10-11) |
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
| 11 The record and the close | Done (sessions 23 and 24, 2026-10-10), PRs #97 to #106, #108, #109; hand runs #107 | "As built" in `phase-11-record-and-close.md`; device tests T1 to T3 |
| 12 The plan | Done (sessions 25 and 26, 2026-10-10 and 11), PRs #110 to #119; hand runs #120 | "As built" in `phase-12-class-plan.md`; device tests T4 to T7 |
| 13 School | Done (sessions 27 and 28, 2026-10-11), PRs #123 to #126, #128 to #134 | "As built" in `phase-13-school.md`; device tests T8 to T10 |
| 14 Parents | Done (session 30, 2026-10-11), PRs #135 to #149 | "As built" in `phase-14-parents.md`; device tests T11 to T14 |
| 15 Make and polish | Built (session 32, 2026-10-12), PRs #152 to #183; hand runs #174; the round next | "As built, the build" in `phase-15-make-and-polish.md`; device test T15; the round from `resume/030-phase-15-build.md` (step 8) |
| 16 Release | Not started | Scope file `phase-16-release.md`; depends on Phase 15's round |

## In flight

Nothing open on GitHub but the hand-run records #107 and #120 (issues, kept open as earlier phases' are); Phase 13's and
Phase 14's hand runs are in `plan/sessions/028/ledger.md` and `plan/sessions/030/ledger.md`. A student link while
another student's page was open showed the first student: fixed in #121 (every pushed screen takes its route as its
identity). The remote holds `main`,
`pr-shots`, and the merged `phase-10/*` to `phase-14/*` and `fix/*` branches, the owner's to delete.

## Production

- **Website:** tutorcentral.in on Vercel `tutor-central-web` (id in `VERCEL_WEB_PROJECT_ID`, root `web`, git deploys off),
  deployed only by `deploy-web.yml` (D45), at `54adb24` (run 38181756154: the trust page `/trust` with its corrected words; first
  live by run 38169497847), smoke green on five pages. GoDaddy DNS:
  `A @ 216.198.79.1`, `www` CNAME → `tutorcentral.in` (Vercel redirects www with a 307); Resend's records and
  `api.tutorcentral.in` (a CNAME to Vercel, attached to `tutor-central-api`) untouched. `APP_STORE_URL` unset (Home shows the
  email call to action) until the app is in the App Store.
- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0027: 0009 to 0013 by deploy run
  38042680418, 0014 to 0016 by run 38046925061, 0017 by run 38052646487 (after #97), 0018 by run 38062264863 (after #108),
  0019 by run 38067327168 (after #110), 0020 by run 38075931282 (after #117), 0021 by run 38110074045 (after #124), 0022 by
  run 38123899264 (after #134), 0023 and 0024 by run 38137427740 (after #138 and #139), 0025 by run 38151333693 (after
  #149), 0026 by run 38159898956 (after #154), 0027 by run 38181486512 (after #180; a student's AI records and messages go with the
  student, a progress note needs the parent's consent); nothing pending after. The
  `photos` bucket (private, JPEG, 3 MB, add-only) is made by 0011. Migrations go up only through `deploy.yml`'s migrate job,
  before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`https://api.tutorcentral.in` since build 16; the generated
  `api-ten-orpin-51.vercel.app` still answers for builds 15 and earlier), commit `54adb24` (deploy run 38181486512, 2026-10-12: Phase 15's `tutorSays` carried whole and quoted, a progress note named
  for the consent gate; before it `bb2ab25`, run 38159898956); the model table `api/models.json` with `AI_MODEL_<WORK_TYPE>`
  overrides (none set on Vercel); nothing pending in the database.
  The Sign in with Apple key (id `LZXF45DB8U`, "tutor-central-signin") is in Vercel's Production environment as
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` and in `api/.env.local`; Apple accepts its signed secret.
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline.
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  The share extension `in.tutorcentral.app.share` and the app group `group.in.tutorcentral` (on both App IDs) were
  registered by the owner on 2026-10-10; the extension is embedded from build 19.
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number. 1.0.0 (26) by run 38184444260 (Phase 15: Make something, Check a paper under Make, Reports' Progress, the Kit, the polish rows, the review's fixes; `main` at `f5218ab`), the round's candidate, waiting for the owner's own test (D68); 1.0.0 (25) by run 38151541726 (Phase 14: the note day, the weekly note and can-now-do, the cadence, the sent log,
  not on track and the next step, marks from a photo, the School leftovers) on the internal group; 1.0.0 (24) by run 38124050257 (Phase 13: the School tab, exam preparation, the mock, marks, the gap report, the
  messages to parents) on the internal group; 1.0.0 (23) by run 38105466595 (the AI forms by class level, #122) on the internal group; 1.0.0 (22) by
  run 38100960937 (Phase 12 with the student-link fix #121) on the owner's iPhone, fine;
  1.0.0 (21) by run 38099197755 (Phase 12: the plan on Today, the material, the close from the plan) on the internal group;
  1.0.0 (20) by run 38062450111 (Phase 11: the five tabs, the V2 student, consent, the textbook, the placement,
  the batch hero and the close) on the owner's iPhone, fine; 1.0.0 (19) by run 38047105651 (Phase 10: the share extension and the background refresh; nothing new on screen) on the internal group (the owner's iPhone: V1 screens fine); 1.0.0 (18) by run 37950611572 (the sheet title, #87) is on TestFlight's internal group; 17 by run 37948604787
  (U33, #86); 16 by run 37944725866 (the API at api.tutorcentral.in); 15 by run 37943689238 (the crash fix #84, the minors
  #85, "normally within 30 days" #83). `ITSAppUsesNonExemptEncryption` is false in `Info.plist`, so no build waits on a
  compliance question. Each run revokes the Apple Development certificate it makes (#75).

## Open items

- **Phase 15's build closed with nothing of its own open (D68):** every hand-run fault and review finding fixed (#167 to
  #183). A CI database job failed twice on a runner whose port 54322 was taken (#183; passed on the third attempt).
- **Phase 14 closed with nothing of its own open (D68).** Two review findings ruled, not changed, and approved by the owner
  (the not-on-track message is not held by the cadence; a copy made offline is not logged); U46 and U47 done (#150, #151). CI's run 38148815276 crashed once in SchoolTests after every suite passed (not reproduced; watch for it).
- **CI warnings kept (the owner's ask, #127):** `VNDetectBarcodesRequestRevision1` (QRDecoder's deliberate fallback for
  the simulator and CI), the AuthorizationController underscored-module note (Apple's SDK), and the runner's Homebrew lines.
- **The cost of marking:** ₹8.18 a paper on Opus (two pages) is most of an exam's cost; D64's price reads it; D67 lets the
  model per work type change without code.
- **Phase 12 review minors (deferred):** eight of the ten `Final: minor (deferred)` lines of `plan/sessions/026/ledger.md`
  (two fold into Phase 13's tasks: a check's skill matched by name first, the 200-character line cut); the two rulings left
  open (an unnamed group, a new batch's first checks) are Phase 13's PR 10 (the owner, 2026-10-11).
- **Phase 11 review minors (deferred):** the `Final: minor (deferred)` lines of `plan/sessions/024/ledger.md` (six), and its
  two noted minors (the page's Messages not refreshing after a consent ask; offline, Today's hero worked out again only after
  the counts' read gives up).
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
- **UI polish:** `plan/ui-polish.md`: U5, U8, U10, U13 to U15, U25, U27 to U30, U48 open; the rest done (Phase 15: U11, U17 to
  U23, U26, U32, U34, U40; U36 by #133).
- **Phase 5's deferred minors** (`plan/sessions/011/record.md`) stay the owner's.
- CI's `xcode-27` runner image is a public preview; move to the GA label when GitHub ships one. The ubuntu-latest
  label moves to Ubuntu 26 from 19 October 2026.
- The four brew tools are unpinned in CI (Homebrew cannot pin a formula; the toolchain salt makes drift loud).
- **Device tests:** `docs/testing/device-tests.md` (S1 passed on build 9; T1 to T15 wait for the tester; the owner tests the builds
  together after the last phase, D68); D1 to D8 were Phase 9's and run on the Phase 15 build before the round, with T1 to T14 and
  the C, A, N and W tests on their V2 paths (`phase-15-plan.md` Task 20).
- The Anthropic API key: Vercel's `ANTHROPIC_API_KEY` on `tutor-central-api` and `api/.env.local` (ignored). `AI_FAKE=1`
  is for local runs only.
- Crash reporting: no decision yet (D18 leaves it open); TestFlight's crash reports through Phase 15's round.
- **The trust page** is live (#165, #181); per-student export (D62) stays for later (`phase-15-plan.md` decision 25).
- After App Store approval (a later slice): `APP_STORE_URL` on Vercel's `tutor-central-web`, then `gh workflow run deploy-web`
  for Home's badge (D47).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
