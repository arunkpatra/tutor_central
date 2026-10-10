# Phase 11: The record and the close

**Status:** Not started. **Depends on:** Phase 10's boards (10.1, 10.2, part of 10.3) and plumbing.

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
