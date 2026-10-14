# State of the work

The single place that says where the project stands. Every session reads it first and updates it last. Keep it
short and true. History belongs in git and in the phase files, not here.

**Last updated:** 2026-10-14, session 41's close (Phase 20's build, on Opus 5.5). **Session 41:** Phase 20 built, PRs #291 to #317:
the agent (draft, verify, check by the other tier, one repair, refuse) for nine kinds; `ai_models` with the kill switch; prompts as
versioned files; the golden sets, `bun evals` and its gate (D101, a failed case retried once, D103); the nightly `eval_run`
through Message Batches; mathematics in LaTeX drawn by SwiftMath on the phone and mitex in the PDFs; the figure's PDF; the
portal's agent step. Hand runs issue #313 (nine of ten; VoiceOver by the Inspector not done); two fresh reviews on Fable 5.1,
every finding fixed; D103 and D104 by the owner. Deployed (Deploy C, run 38400290327, 29e79fb, migrations to 0056); 1.0.0 (30)
checked by the owner on his iPhone ("build 30 ok", 14 October). The phase's real calls about ₹700 (₹520 approved). The first
production nightly (14 October, ₹34.04) passed 4 of 9 kinds; its findings are Phase 21's first work (D105, the owner's). The
first scheduled plan job on Phase 20's code ran at 05:30 IST on 14 October: 12 calls, ₹4.85, no repair. The record in
`plan/sessions/041/`.
**Next:** resume 040 (`plan/resume/040-phase-21-boards-and-plan.md`, on Fable 5.1): the nightlies since 14 October read, Phase
21's boards, `plan/phase-21-plan.md` with D105 as Task 1, then resume 041 for the build. The order (D81): V3's Phases 17 to 22,
then the external testing round, then Phase 16.

**App Store page (D51):** filled and saved by the owner on 2026-10-09, not submitted. With D66 the first submission is V2's
(Phase 16); the page's words and screenshots are redone there.

## Where we are

| Phase | Status | Notes |
|---|---|---|
| 0 Design | Every step approved: 0.1 to 0.9 (0.9, the website, on 2026-10-09), plus the app icon (D29) | Canvas https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; sources `docs/design/`; plan `phase-00-plan.md`; row 6 holds the Phase 3 boards, row 7 Phase 4, row 8 Phase 5, row 9 Phase 6, row 10 Phase 7, row 11 (y 16000) Phase 8's pages, row 12 U33, row 13 the Store boards, rows 14 to 20 (y 37200 on) Phase 10's steps, row 21 (y 47000) Phase 12's two boards, row 22 (y 48400) the AI forms' class, row 23 (y 49800) Phase 13's three boards (approved 2026-10-11), row 24 (y 51200) Phase 14's seven boards (approved 2026-10-11), row 25 (y 52600) Phase 15's five boards (approved 2026-10-11), row 26 (y 56600) Phase 18's fourteen boards (approved 2026-10-12), row 27 (y 58000) Phase 19's sixty boards, the admin portal's fifteen pages at 1280 and 390 (approved 2026-10-13), and below them (y 77000) its twelve loading boards (D97, approved 2026-10-13), row 28 (y 82000) Phase 20's fifteen boards with mathematics (approved 2026-10-13) |
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
| 15 Make and polish | Built (session 32, 2026-10-12), PRs #152 to #183; hand runs #174; the external testing round waits for V3 (D69, D81) | "As built, the build" in `phase-15-make-and-polish.md`; device test T15; the round's documents ready |
| 16 Release | Not started | Scope file `phase-16-release.md`; after V3 and the external testing round (D81) |
| 17 V3 platform foundation | Done (session 35, 2026-10-12), PRs #184 to #214; hand runs #212 | "As built" in `phase-17-platform-foundation.md`; deployed; 1.0.0 (27) |
| 18 V3 the server's work and push | Done (session 37, 2026-10-13), PRs #215 to #261; hand runs #260 | "As built" in `phase-18-server-work-and-push.md`; deployed (0036 to 0045); 1.0.0 (29); device tests T16, T17 |
| 19 V3 the admin portal, reading | Done (session 39, 2026-10-13), PRs #262 to #289; hand runs #286 | "As built" in `phase-19-admin-portal-reading.md`; admin.tutorcentral.in live in `bom1` with loading states (D97); 0046 to 0051 and the API at `bf4af37` deployed |
| 20 V3 AI quality, the material | Built (session 41, 2026-10-13), PRs #291 to #317; hand runs #313 | "As built" in `phase-20-ai-quality-material.md`; deployed (0052 to 0056, API 29e79fb); 1.0.0 (30); D103, D104 |
| 21 V3 AI quality, parents and exams | Not started | Scope file `phase-21-ai-quality-parents-and-exams.md`; depends on 20 |
| 22 V3 the admin portal, control and analytics | Not started | Scope file `phase-22-admin-portal-control.md`; depends on 19, 21 |
| V3 Platform | Spec approved 2026-10-12 (D70 to D82); Phases 17, 18 and 19 built and deployed (D83 to D98); Phase 20 planned (D99 to D102) | `docs/spec-v3.md`; the interview `docs/v3/interview.md`; Phases 17 to 22 above, before the round and Phase 16 (D81) |

## In flight

Nothing open on GitHub but the hand-run records (issues #107, #120, #174, #212, #260, #286, #313, kept open as earlier phases' are). One task
offered to the owner (a chip in session 35): Attendance shows everyone present after a queued replay until a cold launch
(Phase 7's code, found in Phase 17's hand run 3). The remote holds `main`, `pr-shots`, and merged branches, the owner's to
delete.

## Production

- **Admin portal:** admin.tutorcentral.in on Vercel `tutor-central-admin` (id in `VERCEL_ADMIN_PROJECT_ID`, root `admin`, no git
  link), deployed only by `deploy-admin.yml` (D78), at `5cc7b7b` (run 38354450043, the loading states; before it `8231731`, run 38351407848, and `f37ffc3`, run 38347870083). GoDaddy: `CNAME admin` →
  `508a3866c0199c9f.vercel-dns-017.com`. Production's variables: `SUPABASE_URL`, `SUPABASE_ANON_KEY` (the publishable key),
  `SUPABASE_SERVICE_ROLE_KEY` (the default secret key), set from `supabase projects api-keys --reveal`. The owner's admin
  account (his Gmail's `+admin` alias) is on `admin_users` with TOTP, his tutor account the alerts' push target. Repo variable
  `ADMIN_ORIGIN`. Functions in `bom1` (`vercel.json` and the project's `serverlessFunctionRegion`): a page answers in about
  0.2 to 0.6 s against 2 s from `iad1`.
- **Vercel's Git links:** none of the three projects is linked to GitHub since 2026-10-13 (each push had made a cancelled
  deployment that counted against Hobby's 100 a day); deploys are the workflows' alone. The account is on Pro since 2026-10-13
  (D98).
- **Website:** tutorcentral.in on Vercel `tutor-central-web` (id in `VERCEL_WEB_PROJECT_ID`, root `web`, git deploys off),
  deployed only by `deploy-web.yml` (D45), at `f37ffc3` (run 38347873084: `/trust`'s staff sentence); before it `54adb24` (run
  38181756154: the trust page `/trust` with its corrected words; first live by run 38169497847), smoke green on five pages. GoDaddy DNS:
  `A @ 216.198.79.1`, `www` CNAME → `tutorcentral.in` (Vercel redirects www with a 307); Resend's records and
  `api.tutorcentral.in` (a CNAME to Vercel, attached to `tutor-central-api`) untouched. `APP_STORE_URL` unset (Home shows the
  email call to action) until the app is in the App Store.
- **Database:** Supabase `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), migrations 0001 to 0056: 0055 and 0056 by deploy run 38400290327 (Phase 20: a retaken step's check, placements on Sonnet); 0053 and 0054 by run 38382638833 (the figure's PDF, check refusals); 0052 by run 38371143677 (`ai_models`, the agent step, the nightly's schedule); 0051 by deploy run 38356937909 (the cost of the calls made before Phase 17's deploy, #290); 0048 to 0050 by deploy run 38347866740 (the hand runs' and the review's fixes: row ids, the alerts' facts, the reads), 0046 and 0047 by run 38345041694 (Phase 19: the admin tables and reads); 0042 to 0045 by deploy run
  38311560782 (Phase 18's review fixes: the token handover, own-centre photos, the deletion lease, a reminder plan per change);
  0036 to 0041 by run 38282034144 (Phase 18: withdrawal, the member requests, reminder settings and the outbox, the schedules,
  the buckets `pdfs` and `exports`, retention); 0028 to 0035 by run 38256073141 (Phase 17); nothing pending. pg_cron also
  queues the day's plans and note days (each 15 minutes) and the hourly reminder plans.
  pg_cron's `wake_worker_minute` gets the worker's `/jobs/tick` each minute through pg_net, with `worker_url` and
  `worker_secret` in Vault (written by the deploy). The Smoke centre (`SMOKE_CENTRE_ID`, the owner's +smoke account) takes
  the deploy's one real check. The
  `photos` bucket (private, JPEG, 3 MB, add-only) is made by 0011. Migrations go up only through `deploy.yml`'s migrate job,
  before the API (D26); secrets `SUPABASE_ACCESS_TOKEN` and `SUPABASE_DB_PASSWORD` in the GitHub environment `Production`.
- **Auth:** Apple (client id `in.tutorcentral.app`), Google (a web OAuth client in Google Cloud; Supabase holds its id
  and secret), email code, password; redirect URL `tutorcentral://auth-callback`. Email through Resend SMTP from
  `Tutor Central <hello@tutorcentral.in>` (D30): domain verified at GoDaddy (DKIM, SPF via `send`, DMARC), 30
  emails an hour, the code templates, OTP 6 digits for 600 s.
- **API:** Vercel `tutor-central-api`, `bom1`, at `API_ORIGIN` (`https://api.tutorcentral.in` since build 16; the generated
  `api-ten-orpin-51.vercel.app` still answers for builds 15 and earlier), commit `29e79fb` (deploy run 38400290327, 2026-10-13: Phase 20 whole, 0055, 0056; before it `c08d6d9`, run 38382638833, and `739102d`, run 38371143677); the agents' models in `ai_models`, Vercel's `SMOKE_CENTRE_ID` for the nightly, the repository's secret `ANTHROPIC_API_KEY` for the evals in CI; before Phase 20 `bf4af37` (deploy run 38356937909: 0051); before it `8231731` (run 38351404374: Phase 19 whole, 0049's stuck rule and the failure's key); before it `4d8294e` (run 38345041694: the alerts job; `RESEND_API_KEY` and `ALERT_EMAIL` in Production); before it `6d973b9` (deploy run 38311560782, 2026-10-13:
  Phase 18 with its review fixes; before it `ed0077f`, run 38282034144, and `a3c6012`, run 38256073141); the deploy is gated on `main`'s
  green check and smokes a real check and a tick. Vercel's Production holds `SUPABASE_SERVICE_ROLE_KEY` (the new `sb_secret`
  key, D83) and `WORKER_SECRET`; GitHub's `Production` holds `SMOKE_EMAIL`, `SMOKE_PASSWORD`, `WORKER_SECRET`. The model
  table `api/models.json` with `AI_MODEL_<WORK_TYPE>` overrides (none set on Vercel).
  The Sign in with Apple key (id `LZXF45DB8U`, "tutor-central-signin") is in Vercel's Production environment as
  `APPLE_TEAM_ID`, `APPLE_KEY_ID`, `APPLE_SIGNIN_KEY` and in `api/.env.local`; Apple accepts its signed secret.
  `ANTHROPIC_API_KEY` is in its environment; the Claude calls run under one 110 s deadline. APNs (D88): the token key (id
  `5TN9CJ8CRL`) as `APNS_KEY`, `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_TOPIC` in Vercel's Production and `api/.env.local`; the
  deploy's smoke sends to a dummy token and APNs takes the key. Typst renders the PDFs with the fonts in `api/fonts` (D89).
  Vercel Hobby refuses deploys whose commit author it does not know; this repo's git email stays `arunkpatra@gmail.com`.
- **iOS:** bundle id `in.tutorcentral.app` (D27), team `Y7SW6436RD`, App Store Connect record "Tutor Central".
  The share extension `in.tutorcentral.app.share` and the app group `group.in.tutorcentral` (on both App IDs) were
  registered by the owner on 2026-10-10; the extension is embedded from build 19.
  `testflight.yml` (D24): an Admin App Store Connect API key in secrets (App Manager cannot use cloud-managed
  distribution certificates); variables `APPLE_TEAM_ID`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. Build number = the
  run number. 1.0.0 (30) by run 38400789743 (`main` at `29e79fb`: Phase 20's maths on the phone, the switched-off alert; the owner's check to come); 1.0.0 (29) by run 38314213195 (`main` at `a778350`: build 28 and the run's push check, which printed the
  archive's `aps-environment`; the App Store export re-signs it for production), the one to test; 1.0.0 (28) by run
  38312753433 (Phase 18: push, Today on the server's plan, the note from the job, withdrawal, the export, the copies first;
  `main` at `e3bbe97`), the first build with push; 1.0.0 (27) by run 38258868771 (Phase 17: the keys, request ids and activity log; nothing new on screen;
  `main` at `e89927c`); 1.0.0 (26) by run 38184444260 (Phase 15: Make something, Check a paper under Make, Reports' Progress, the Kit, the polish rows, the review's fixes; `main` at `f5218ab`), the round's candidate, waiting for the owner's own test (D68); 1.0.0 (25) by run 38151541726 (Phase 14: the note day, the weekly note and can-now-do, the cadence, the sent log,
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

- **Phase 19 closed with its findings fixed (D68):** the hand runs' F1 to F6 (#279 to #281), the thirteen review findings
  (#277, #283 to #285), the footer seen in production (#287). Open: hand run 7's push on a simulator not driven (the owner's iPhone proved it). The API's deploy of `main` is done (`bf4af37`); the first
  morning's `alerts` rows were read by session 40: only the proof, no false alarm.
- **Phase 18 closed with nothing of its own open (D68):** the hand runs' faults fixed (#239, #241 to #243), every review
  finding fixed (#244 to #259) but one ruled transitional (build 27 filling a line while the job makes the material; ends
  with build 28). The real calls cost ₹3.05. U27 done; U10 narrowed to the spinner (no board); U49 opened.
- **Phase 17 closed with nothing of its own open (D68):** every finding of both reviews fixed (#207 to #211), and the faults
  found after (#213, #214). The hand runs' real calls cost ₹4.57.
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
- **Vercel Preview** has no `APPLE_*` variables (Production only); nothing deploys to Preview today. One environment until the owner says (D80).
- **Supabase Free stays until the external testing round (D85); Vercel is on Pro (D98).** The worker lives within 300 s (a 200 s run budget; the wakes hold their request 290 s); no copy of the database exists anywhere (a bad migration or a deletion is final); Vercel's logs keep an hour, Supabase's a day; Supabase Pro is bought before the external testing round, as a step of its checklist; point-in-time recovery is Phase 16's call.
- **V3 covers** the platform-shaped minors below where they are the platform's (duplicate paid calls, the 20 s offline waits, the pending rows, `APPLE_FAKE` in production, the limits copied across layers, orphaned photos): each is closed by the V3 phase that owns it, not on its own.
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
- Crash reporting: D77 (2026-10-12) settles it for V3: Xcode Organizer and TestFlight, no SDK in the app.
- **The trust page** is live (#165, #181); the per-student export (D62) is Phase 18's job (D79, D92), and the page's words change with it (plan Task 23).
- After App Store approval (a later slice): `APP_STORE_URL` on Vercel's `tutor-central-web`, then `gh workflow run deploy-web`
  for Home's badge (D47).

## Paths outside this repo

| What | Where | Use |
|---|---|---|
| Rooftop design app (design discipline reference, process reference) | `../rooftop-design-app` | `docs/design/`, `plan/SESSIONS.md`, `tools/pr-shots.ts`, `.github/workflows/deploy.yml`. Read only. Never copy its colours or layouts |
