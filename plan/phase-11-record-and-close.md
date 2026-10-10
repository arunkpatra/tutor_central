# Phase 11: The record and the close

**Status:** Done (sessions 23 and 24, 2026-10-10): plan `phase-11-plan.md`, PRs #97 to #106, hand runs #107, review fixes #108 and #109. **Depends on:** Phase 10's boards (10.1, 10.2, part of 10.3) and plumbing.

## Goal

A tutor can add a student with their class, school and parent, capture the textbook's contents once per class and
subject, record consent, run a placement, close a class with attendance, three checks and homework, and see the
student's record and tracking status. Usable without a plan (D57).

## Scope

1. **Five tabs.** Today, Students, School (empty state), Fees, More; Attendance and Schedule under More unchanged
   (D65). V1's deep links keep working.
2. **Add student V2.** Class level LKG to 10, school (pick or add), board from class 8, parent name and phone,
   message language; edit; archive as V1. Existing students default to class level "not set" and keep working.
3. **Consent.** The WhatsApp message, the record of the reply (date, phone) on the student's page, the trust page on
   tutorcentral.in and the App Privacy answers (spec section 9, Privacy).
4. **Textbook capture.** Camera or Photos to `/ai/parse-textbook`, the chapters shown for confirmation and edit,
   saved once per school, class and subject, copied as chapters and skills to the students of that class; a later
   student of the class gets them at add time.
5. **The ladder and the placement.** LKG and UKG on the ladder; classes 1 to 3 on the ladder for reading, writing and
   numbers; the placement kind through `/ai/make` for classes 4 to 10, tapped right or wrong, setting the starting
   chapter.
6. **The close.** From Today's batch: came (default present), three checks per student (from the spaced queue through
   `/ai/make`, or none if the student has no skills yet), homework given; `close_session` in one write; offline by
   D39's queue; writes V1's attendance session.
7. **The student's page.** This week, the record (skills by subject with states, check trend, marks, attendance,
   homework), school items (empty), messages, consent, fees (V1), notes.
8. **Tracking status.** The Domain rules with tests; stored at the close and on a change; the list sorted by it; "not
   known yet" for a student without checks.

## Acceptance

- Each screen matches its board in both appearances; pictures in the PRs (D7); the D32 hand run of each write.
- A V1 student with no class level, no textbook and no consent still appears, is marked present, and gets fees as
  before.
- RLS tests for each table touched; Domain tests for the rules; a TestFlight build to the internal group.

## As built (session 24, 2026-10-10)

Ten pull requests from `plan/phase-11-plan.md`, on Opus 5.5: #97 (migration 0017, the seed's class levels and school),
#98 (the API's `/parse-textbook` and `/make` for check and placement), #99 (Domain), #100 (Data), #101 (the five tabs),
#102 (the list and New student V2), #103 (the student's page and consent), #104 (Add a textbook), #105 (the placement),
#106 (the batch hero and the close). Deployed by run 38052646487 (0017 applied; API at `8dde6d0`). The rulings are in
`plan/sessions/024/ledger.md`; the hand runs (D32) in #107.

1. **Five tabs:** Today, Students, School (the Later card until Phase 13), Fees, More; Attendance pushed under More (D65);
   V1's links land there.
2. **New student V2:** class LKG to 10 on a wheel, school picked or added (its board set once), board from class 8,
   message language; Class required for a new student only, so a V1 student edits without one. A saved student gets the
   school's books for their class (`copy_textbooks_to_student`) or the ladder (LKG to class 3).
3. **Consent:** the WhatsApp ask (optional, its message from `ConsentMessage`), the Parent agreed sheet (how, the day, the
   number), Change and Remove; the section sits under the parent until agreed, then after the messages. The trust page and
   App Privacy wait for Phase 14 (the plan's decision 3).
4. **Textbook capture:** the photo goes to `/parse-textbook` and is never kept (`photo_path` null); the chapters are checked
   and edited, kept once per school, class and subject, and copied to the class (`copy_textbook_to_class`); a second capture
   keeps the students' states by position; a later student gets them at save.
5. **The ladder and the placement:** the ladder's areas as chapters with steps as skills; the placement asks one question
   per chapter (or ladder step) per subject, tapped right or wrong, and `record_placement` keeps the checks, the chapters
   made secure before the first wrong, and the status, in one write.
6. **The close:** Today's hero is the 10.3 batch hero: Start class while a batch not yet closed is soon or running; the
   latest close today reads what happened ("5 of 6 came", the checks right, the homework, who was away) with Open the class
   until the next batch is soon; "No batch today" names the next one. The close lists the batch's students at once, makes
   three checks per student from the spaced queue (one `/make` call per subject) or the placement when nothing is taught
   yet, or none without a book; Done writes the marks, the tapped checks, the homework, the skill states and every
   student's status in one `close_session` call. Opened again the same day it shows what was kept; a second close replaces
   the session's checks and homework and moves a skill only for a changed tap. Offline it waits in the queue (one per batch
   and day), Today's hero reads "saved on this iPhone", Pending changes lists it, and the queue sends it.
7. **The student's page:** tracking card with the reasons and Next, This week, the record by subject (chapters and skills
   with states, the trend), checks, homework (its status changed in place), school (empty), messages, consent, fees, notes.
   Marks are not built (decision 16; U36).
8. **Tracking status:** `TrackingRules` (accuracy over three weeks, absences over four, homework, chapters behind),
   stored at the close and by the placement; the list sorts by it; "Not known yet" until there are checks.

**The hero ruling:** the plan built the 10.3 batch hero over V1's Today content without the plan's cards; the owner
approved it on 2026-10-10 ("The hero is approved; go ahead").

**Found by the hand runs and fixed in #106:** the hero passing from a closed batch to the next one soon; the latest close
holding the hero; the close listing students before its reads (offline each read took about 20 s in turn); a book read
that failed offline saying the checks need a connection; a student who joined after a close starting present with
homework given; two wording slips.

**The review** (Fable 5.1, fresh context): a close kept on this iPhone now opens again with its taps, and Done waits for
the checks being made (#106); a student moved up a class gets the new class's book with last year's chapters behind it
(migration 0018, #108); a contents page with no chapters is refused in words (#109). Six minors are deferred in the ledger.

**Deferred:** the trust page and App Privacy (Phase 14); export (Phase 14); Marks on the page (U36); the School tab's own
screens (Phase 13); the plan, and with it the close's group checklist and the "Plan" link (Phase 12).
