# Release checklist

Each build that goes past the internal group runs this list, in order. A box is ticked only with its proof (a run's
link, a screenshot, a line in a log).

## Before the build

- [x] `main` is green, and every pull request of the phase is merged. Build 18: `check` run 37956293284 green on #89's merge; nothing open on GitHub (2026-10-09).
- [x] No migration is pending (the summary of `gh workflow run deploy` says so). Build 18: deploy run 37965871936, the database job green (it fails when anything is still pending), 0001 to 0008 in production; the TestFlight lane of run 37950611572 passed its migration gate.
- [x] The API's `/health` reports `main`'s head commit. Build 18: `{"ok":true,"commit":"999e881…"}` after deploy run 37965871936, smoke green (2026-10-09).
- [x] `bun check --fresh` is green locally. Build 18: "check: all green in 93.4s", format, lint, ios, tools, api, web, db (2026-10-09, `999e881`).
- [x] The D32 hand run of every write path is done, and its screenshots are on the phase's issue. Build 18: the full hand run on the code of build 14 (session 17, from a cold simulator); since then #83 to #87 changed no write itself: #85 hand-ran Scan's Add and Undo (in its description), #86 changed only how a refused write is told (the system alert, its launch states and `NoticeCenterTests`), #84 and #87 touch no write.
- [x] `MARKETING_VERSION` in `ios/project.yml` is set for this release: `1.0.0` (line 15).

## The build

- [x] `gh workflow run testflight` has run; its build number is noted below, under the release notes. Run 37950611572, build 1.0.0 (18).
- [x] The internal group has installed the build. Build 18: the owner's iPhone, passed (U33's alerts and in-place successes, a long class name on Add to class), 2026-10-09.
- [ ] The tester's lines in `docs/testing/device-tests.md` for this build all Pass, or each Fail has its fix merged
  and a new build.

## App Store Connect

- [x] The privacy policy URL is set: `https://tutorcentral.in/privacy` (live in Phase 8): App Information and TestFlight's Test Information, 2026-10-09.
- [x] The test information is filled in, with the feedback email `hello@tutorcentral.in` (2026-10-09).
- [ ] The external group is made and the build is added to it.
- [ ] Beta App Review is submitted and approved.

## After

- [ ] The release notes are written in this file, under "1.0 (build N)".
- [ ] `plan/STATE.md` is updated with the build and the group.

**Rollback:** the previous build stays in the group. Expire the bad one in App Store Connect.

## Release notes

### 1.0 (build 18), the first build for the Tutors group

Tutor Central keeps your tuition centre on your iPhone: students and parents, who came to class, who has paid this
month, your classes and events, and tools that prepare papers and check answers. This is the app as it will go to
the App Store; you are among the first tutors to use it.

In the first week, try:
- Add your students and their classes, with each parent's WhatsApp number and the monthly fee. Or photograph the
  register you already keep: Students, then "+", then "Scan paper register".
- Mark attendance on each day you teach, and try "Tell parent" for an absent student.
- Open Fees for this month: send a reminder, mark a fee paid, share the receipt.
- Turn on reminders in More, then Settings, and see one arrive before your next class.
- Make a question paper or a worksheet in AI Assistant, and share it as a PDF.
- Check a photographed answer sheet against your marking scheme, and write a progress note.
- Once, switch off Wi-Fi and mobile data, open the app and mark attendance; then switch them back on.

If something is slow, confusing, wrong or missing: take a screenshot, tap it, tap Done, then "Share Beta Feedback".
Or write to hello@tutorcentral.in from More, then Help.

### Earlier

Builds 10 to 18 (internal group only) brought Settings, Account (a password, signing out, deleting the account), teacher
reminders, working without a connection, larger text and VoiceOver, and Help.
