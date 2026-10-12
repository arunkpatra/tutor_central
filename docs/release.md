# Release checklist

Each build that goes past the internal group runs this list, in order. A box is ticked only with its proof (a run's
link, a screenshot, a line in a log).

## Before the build

The V2 build for the Tutors group (Phase 15, build 26). Build 18's proofs are in git history (this file at `b0ead54`).

- [x] `main` is green, and every pull request of the phase is merged. Build 26: `check` run 38183210414 green on #183's merge (`f5218ab`); #152 to #183 merged, nothing open on GitHub but the hand-run issues (2026-10-12).
- [x] No migration is pending (the summary of `gh workflow run deploy` says so). Build 26: deploy run 38181486512 pushed 0027, the database job green (it fails when anything is still pending), 0001 to 0027 in production; the TestFlight run 38184444260 passed its migration gate.
- [x] The API's `/health` reports `main`'s head commit. Build 26: `{"ok":true,"commit":"54adb24…"}`, the last commit that changed the API (#180's merge); #181 to #183 and the documents after it change the website and the app only (2026-10-12).
- [x] `bun check --fresh` is green locally. Build 26: "check: all green in 137.4s", format, lint, ios, tools, api, web, db (2026-10-12, `22277fd`).
- [x] The D32 hand run of every write path is done, and its screenshots are on the phase's issue. Build 26: Phase 15's fifteen runs on issue #174 (each write confirmed in the database; their faults fixed in #167 to #173 with tests); Phases 11 and 12 on #107 and #120, Phases 13 and 14 in `plan/sessions/028/ledger.md` and `030/ledger.md`.
- [x] `MARKETING_VERSION` in `ios/project.yml` is set for this release: `1.0.0` (line 15).

## The build

- [x] `gh workflow run testflight` has run; its build number is noted below, under the release notes. Run 38184444260, build 1.0.0 (26).
- [x] The internal group has installed the build. Build 26: the owner's iPhone, passed (his "go ahead", 2026-10-12).
- [ ] The tester's lines in `docs/testing/device-tests.md` for this build all Pass, or each Fail has its fix merged
  and a new build.

## App Store Connect

- [x] The privacy policy URL is set: `https://tutorcentral.in/privacy` (live in Phase 8): App Information and TestFlight's Test Information, 2026-10-09.
- [ ] The test information is filled in with V2's words, with the feedback email `hello@tutorcentral.in` (owner step 1).
- [ ] The external group "Tutors" shows no V1 build (build 18 expired) and build 26 is added to it with its notes as What to Test (owner steps 2 and 3).
- [ ] Beta App Review is submitted and approved for build 26.

## After

- [x] The release notes are written in this file, under "1.0 (build 26)".
- [ ] `plan/STATE.md` is updated with the build and the group.

**Rollback:** the previous build stays in the group. Expire the bad one in App Store Connect.

## Release notes

### 1.0 (build 26), the first V2 build for the Tutors group

Tutor Central plans each class for you, makes the material, keeps a record for each student from a few taps at the end of
class, writes the weekly note to parents in their language, and keeps students, attendance and fees as before. This is the
app as it will go to the App Store; you are among the first tutors to use it.

In the first week, try:
- Add your students with their class (LKG to 10) and school, and put them in a batch. Or photograph the register you keep.
- Photograph the contents page of one textbook: Students, a student, then "Add a textbook". The chapters and skills come
  into the record for every student of that class at that school.
- On a batch day, open Today before the class: the plan is made for you. Open a sheet and share it as a PDF.
- After the class, tap "Start class": mark who came, tap the three questions right or wrong, and Done.
- Forward a school's message about a test to Tutor Central from WhatsApp (Share, then Tutor Central). See it in School.
- Ask one parent for consent from the student's page, record it, and on Sunday evening read and send the weekly note.
- Make something on your own: More, then "Make something". Try a sheet for a class and a mock for a test.
- Open More, then Reports, then Progress.
- Once, switch off Wi-Fi and mobile data, open the app, and close a class; then switch them back on.

If something is slow, confusing, wrong or missing: take a screenshot, tap it, tap Done, then "Share Beta Feedback".
Or write to hello@tutorcentral.in from More, then Help.

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
