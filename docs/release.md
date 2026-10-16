# Release checklist

Each build that goes past the internal group runs this list, in order. A box is ticked only with its proof (a run's
link, a screenshot, a line in a log).

## Before the build

The round's build for the Tutors group, after V3 (D69, D81): **1.0.0 (32)** (D121): the brand mark (Phase 23, D120, D122)
and #363 (formulae drawn in rows, found by the owner on build 31). Build 31's proofs are in git history (this file at
`b56660f7`), build 26's at `24b11609`.

- [x] `main` is green, and every pull request of the phase is merged. Phase 23: #364, #365 merged after #363; `check` green
  on `main` (the run is in `plan/sessions/046/ledger.md`); nothing open on GitHub but the hand-run issues.
- [x] No migration is pending. 0066 by deploy run 38694563888; 0067 and 0068 by Deploy B (its run in the ledger); 0001 to 0068
  in production.
- [x] The API's `/health` reports the last commit that changed the API (Deploy B's).
- [x] `bun check` is green locally (session 46).
- [x] The hand runs: Phases 17 to 22 on issues #212, #260, #286, #313, #343 and #359; each write confirmed in the database,
  each fault fixed with a test first. Phase 23 touches no write path (D32: no hand run).
- [x] `MARKETING_VERSION` in `ios/project.yml` is `1.0.0`.

## The build

- [x] Build 1.0.0 (32), run 38870869498 (`main` at `5675c376`); the owner's iPhone: "icon fine", "maths fine" (session 46).
- [ ] The tester's lines in `docs/testing/device-tests.md` for this build all Pass (T16, T17, T21, T22 first), or each Fail
  has its fix merged and a new build.

## App Store Connect

- [x] The privacy policy URL is set: `https://tutorcentral.in/privacy` (live in Phase 8): App Information and TestFlight's Test Information, 2026-10-09.
- [ ] The test information is filled in with V2's words, with the feedback email `hello@tutorcentral.in` (owner step 1).
- [ ] The external group "Tutors" shows no V1 build (build 18 expired) and build 32 is added to it with its notes as What to Test (owner steps 2 and 3).
- [ ] Beta App Review is submitted and approved for build 32.

## After

- [x] The release notes are written in this file, under "1.0 (build 32)".
- [ ] `plan/STATE.md` is updated with the build and the group.

**Rollback:** the previous build stays in the group. Expire the bad one in App Store Connect.

## Release notes

### 1.0 (build 32), the round's build for the Tutors group

Tutor Central plans each class for you, makes the material, keeps a record for each student from a few taps at the end of
class, writes the weekly note to parents in their language, and keeps students, attendance and fees. Much of the work
happens before you open the app: each day's plan is made overnight and ready before your first batch, the weekly notes are
written on the note day, and a school test is prepared over its days, with a mock test on its morning.

In the first week, try:
- Allow notifications when the app asks. The next morning, "Today's plan is ready" arrives before your first batch; tap it.
- Add your students with their class (LKG to 10) and school, and put them in a batch.
- On a batch day, open Today before the class, open a sheet and share it as a PDF.
- After the class, tap "Start class": mark who came, tap the three questions right or wrong, and Done.
- Forward a school's message about a test to Tutor Central from WhatsApp. On the test's page, see its days.
- Ask one parent for consent from the student's page, record it, and on the note day read and send the weekly note in the
  parent's language.
- On a student's page, under Export, make the file and share it to yourself: everything the app keeps about that student.
- Make something on your own: More, then "Make something".

If something is slow, confusing, wrong or missing: take a screenshot, tap it, tap Done, then "Share Beta Feedback".
Or write to hello@tutorcentral.in from More, then Help.

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
