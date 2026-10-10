# Phase 11 plan: the record and the close

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-10 (session 23, Fable 5.1) from `phase-11-record-and-close.md`, `docs/spec-v2.md` and the approved Phase 10
boards (steps 10.1, 10.2 and the close of 10.3). Ticked as it goes. The build runs on Opus 5.5 from
`resume/022-phase-11-build.md`, inline, task by task, with one ledger as sessions 15 and 22 kept.

**Goal:** a tutor adds a student with their class, school and parent, captures a textbook's contents page once per class
and subject, records consent, runs a placement, closes a batch with attendance, three checks and homework, and sees each
student's record and tracking status; the five tabs with Attendance under More; a V1 student keeps working untouched.

**Architecture:** one additive migration (0017) extends the close with skill states and adds the placement and the
class-wide copy as functions; the API's `/ai/parse-textbook` and the `check` and `placement` kinds of `/ai/make` go live
(Sonnet and Haiku, structured outputs); Domain gains the rules (tracking status, the spaced queue, skill progress,
consent words) with tests; Data gains the record's reads, the consent and copy writes, the V2 API client and the queued
close; the screens are Students and Today extended to the 10.2 and 10.3 boards, built on Kit parts from
`components.md` "Phase 10 parts", photographed state by state (D7), each write hand-run (D32).

**Tech stack:** as V1 and Phase 10 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI, Postgres, Bun tests;
Hono, zod 4, `@anthropic-ai/sdk`; XcodeGen). No new dependency.

**Spec:** `docs/spec-v2.md` sections 2, 4, 5, 6 (the close), 8 (consent), 9; scope `plan/phase-11-record-and-close.md`;
the boards and what they settle in `docs/design/information-architecture.md` ("Phase 10 boards", 10.1 to 10.3), the parts
and texts in `components.md` ("Phase 10 parts"), the numbers in `design-tokens.md` ("Numbers in code"); decisions D56 to
D66; what Phase 10 built in `phase-10-v2-design-and-foundation.md` "As built, Part B" and `plan/sessions/022/ledger.md`.

## Global constraints

- No board, no approval, no code for anything seen (rule 1). Each state a board draws gets a `LaunchState` and its
  pictures in the pull request, both appearances where the board has both (D7). What a V2 board does not redraw stays as
  V1 built it (D56).
- Nothing from V1 is renamed, dropped or narrowed in the model (D56, D26): the table is `classes`, the word on screen is
  "Batch". Migration 0017 is additive and never edits 0001 to 0016. `types.ts` regenerated and committed with it.
- A new function: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute … to
  authenticated`; a test for each path it refuses (supabase/CLAUDE.md). No `security definer` beyond `is_member` and
  `delete_account` (D37). No service-role key anywhere (D37, D60).
- The API runs every call as the user (D5); inputs are zod schemas; a route validates first (400 with the issues);
  `start_ai_generation` gates each call (consent, the monthly allowance); no photo is stored by the API; one model per
  kind (D35, D63).
- No textbook text anywhere: chapter names and skill names only (D58). The textbook photo is sent and never kept: the
  approved intro says "We keep no copy" (`components.md`), so `textbooks.photo_path` stays null in this phase.
- Consent is a section, never a gate (spec section 2, D62). Only a student's own notes, marking and messages wait for it,
  none of which this phase makes; sheets, checks and the placement carry no student data.
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4; the record is
  read through Data protocols and Domain's `Register`); tokens only (D10; a value a board uses that `design-tokens.md`
  does not name is added to the document and to `Tokens` in the same commit, D25); Swift Testing in the existing test
  targets.
- No technical words on screen (D41): each new sentence passes `ErrorWordsTests`; each message is one of
  `docs/design/feedback.md`'s rows (the toast only for Undo; a failed write is the system alert; a list that could not
  load says so in its place).
- Text limits count Unicode scalars (D48). Both appearances (D13). Dynamic Type through `AdaptiveRow` and
  `growsWithText()` where a row puts a value beside a title (ios/CLAUDE.md).
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull requests
  with pictures; documents directly to `main` (D12), never mixed with code.
- Plain voice in documents and comments; the word is Students, not Children.

## Decisions this plan takes

Small decisions, written here so they are not re-decided. None needs a number; the one that is the owner's is marked.

1. **Today's way into the close (the owner's to confirm).** The batch hero of P10-Today-Plan replaces V1's hero on Today:
   "Next batch · in 25 min", the batch, the line, **Start class** (while the batch is within 90 minutes or running, as Mark
   attendance was); after the close the closed hero of P10-Today-AfterClose (closed at, N of M came, the checks and
   homework line, Open the class). The "Today's plan" cards (Phase 12) and "To parents" (Phase 14) are absent, as the
   `close` state's own note allows for the close. Mark attendance for any day and batch stays under More. A batch's row
   on Today keeps V1's behaviour (opens the batch) until Phase 12.
2. **The School tab in this phase** is the P2-Later card (`FeatureTile` `building.columns`, "School", one line), state
   `later-school`; `school-empty` with its two buttons is Phase 13's, when the buttons lead somewhere (the 10.1 note).
3. **The trust page and the App Privacy answers** are not this phase's: spec section 9 ties them to "the phase that first
   sends a student's data to testers"; nothing here sends a student's data (a book's contents page is not a student's).
   They go with Phase 14's note (the first personal artefact) and Phase 16's website text. The scope file's item 3 is
   read that way.
4. **Export per student** (spec section 9, Privacy) waits for the first personal data (Phase 14) and needs a board; Delete
   is V1's typed confirmation, and 0009 and 0010's cascades take the chapters, skills, checks and homework with the
   student (a test holds it).
5. **Class is required for a new student only.** Edit student of a student with no class (each V1 student) saves
   without one; the Class tile reads "Choose". Scan register's Fix this row keeps class optional (a scanned register has
   no class), so scanned students join as "class not set" like V1's.
6. **The spaced queue, first version** (Phase 12 refines it with the plan): three skills per student, the most recently
   taught first (the eligible skill with the latest `stateAt`), then the most overdue by state (taught and revisit 1 day,
   practising 3, secure 7, from `lastCheckedAt` or `stateAt`); a skill not started is never checked. Fewer than three when
   fewer are eligible; none when none is: then the placement if the student has chapters, else attendance and homework
   alone.
7. **Skill states move in the close** (0017 adds `p_states` to `close_session`): right moves not started or taught to
   practising, practising to secure when the previous check on it was right too, revisit to practising; wrong moves
   secure to revisit and leaves the rest. The placement makes the skills of every chapter answered right before the first
   wrong secure and leaves the rest; its checks are `kind = 'placement'` without a session (`record_placement`).
8. **Tracking status rules** (Domain, tested): not known yet without a check; otherwise the worst of: check accuracy over
   21 days with at least 6 checks (under 50% not on track, under 70% watch); absences over 28 days (4 or more not on
   track, 2 or more watch); homework not done running (3 not on track, 2 watch); chapters behind the term calendar (June
   to March, 10 months) for the subject furthest behind (3 or more not on track, 2 watch). Reasons are the fired rules'
   sentences; "Next" is the status's default step with the current skill named; the quiet Change (the four next steps)
   is Phase 14's with P10-NextStep, so this phase draws Next without it (Place <name> for not known yet).
9. **Checks are made at the close, per student,** by `/ai/make` kind `check` (Haiku) when the close opens, one call per
   student in parallel; a call that fails shows the student's checks as the in-place load failure with Try again, and
   Done still closes with attendance and homework. Phase 12's plan makes them ahead per group. `MakeInput`'s check takes
   one to three skills (the plan's `length(3)` would refuse a student with fewer).
10. **The monthly allowance's words** are this phase's (the first V2 route reaches it): "You've made this month's 600.
    More next month." (the API's 429 for a V2 kind; `APIFailure.allowance`). V1's daily words stay for V1's kinds.
11. **The textbook's subject** is chosen on a floating sheet like the school sheet: the subjects the student already has,
    then `Subject.common` (Mathematics, Science, English, Hindi, Kannada, Social Science, EVS, Computer), then "Add a
    subject" as a field row. A student needs a class and a school for a book: a page without them shows one line in the
    Record ("Set <name>'s class and school from Edit to add a book.") and no Add the book.
12. **Keep copies the book to the class in one call** (`copy_textbook_to_class`), and a student saved with a school and
    class gets every book of that school and class (`copy_textbooks_to_student`). A tutor's own chapter (Add a chapter) is
    appended after the book's and moved behind the book's on a recapture (0017's `copy_textbook_chapters`).
13. **Consent after clearing:** waiting shows whenever a `consent` log exists and nothing is recorded, so a cleared record
    reads "Asked <parent> on <day>" again (true: the parent was asked; nothing is recorded). The record sheet's "Remove"
    row clears the three columns; the message log is never deleted.
14. **The school's board** is set from the student's when the school has none and the student (class 8 or above) is saved
    with one; the school sheet shows it. Nothing else edits a school in this phase.
15. **Homework status** (Done, Partial, Not done) is tapped on the student's page's Homework rows and written at once; a
    row starts as Given. The close writes Given only (the spec's "next close" update is Phase 12's with the plan).
16. **The Marks section** waits for Phase 14 (Add from a photo is its action); the School section shows its empty row with
    "Nothing from <name>'s school yet" until Phase 13.
17. **The Kit's Phase 10 board** (step 10.7) is built in Phase 15 with Make; this phase's parts are proven on their
    screens.
18. **`SessionClose` moves to Domain** (`Domain/Record/SessionClose.swift`, `Codable`) so a close can be a `QueuedChange`;
    a second close of the same batch and day replaces the first in the queue; an attendance save of the same batch and
    day keeps its own kind and order (last write wins per row).
19. **The seed** (`seed.sql`, local only) gives eight of the ten students a class level and Hemanth, Akshita and Riya the
    school Vidya Niketan (CBSE); Bir Bikram Singh and Lakshmi Menon keep no class level, so a hand run always meets a V1
    student. The fixtures follow the 10.2 boards (Hemanth class 10 on watch, Riya class 5 not known yet, Sahil class 2 on
    the ladder); the figures are illustrative, the screens follow the data.
20. **Branches** `phase-11/<slug>` in the main checkout, one pull request each, as sessions 15 and 22 worked.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A V1 student with no class level, no school, no book and no consent** appears on the list ("Not known yet · Class 10
   Maths"), is marked present in the close with attendance alone, keeps their fees, opens a page whose Record says what
   is missing, and saves from Edit without a class. Tests: Task 4 (`StudentDraftTests.editingAStudentWithoutAClassSaves`),
   Task 8 (`StudentRowTests.aV1RowReadsWithV2Defaults`), Task 6 (`TrackingRulesTests.aStudentWithoutChecksIsNotKnown`),
   Task 21 (`CloseStoreTests.aStudentWithNoChaptersHasAttendanceAndHomeworkOnly`).
2. **A class with no book yet, a second capture of the book, a student who joins the class later:** Keep copies to every
   student of the school and class and to none of another class; a recapture keeps each student's states and checks and
   moves a tutor's own chapter behind the book's; a student saved later with that school and class gets the book's
   chapters at save. Tests: Task 1 (`copy_textbook_to_class…`, `a recapture keeps a tutor's own chapter after the
   book's`, `copy_textbooks_to_student…`), Task 13 (`RegisterStoreTests.addingAStudentWithASchoolAndClassCopiesTheBooks`),
   Task 18 (`TextbookStoreTests.keepSavesOnceAndCopiesToTheClass`).
3. **A close with attendance alone, and a close offline:** Done with nothing tapped writes the session and no checks,
   homework given for everyone present, and the status is worked out again (absences count); offline the close waits in
   the queue, shows "Saved on this iPhone", replays as one `close_session`, and a second close of the same batch and day
   replaces the first. Tests: Task 1 (`close_session with attendance alone…` extended for `p_states`), Task 21
   (`CloseStoreTests.doneWithNothingTappedClosesWithAttendanceAlone`), Task 22 (`CloseQueueTests.offlineACloseIsKeptHere`,
   `aSecondCloseOfTheSameBatchAndDayReplacesTheFirst`, `QueueRunnerTests.aQueuedCloseIsSentAsOne`).
4. **Consent recorded, then cleared; a check or placement never needs it.** Recording writes the three columns, the page
   reads agreed; Remove clears them and the page reads waiting (an ask was logged) or not recorded; `/ai/make` check and
   placement start without `p_student`. Tests: Task 16 (`ConsentStoreTests.recordThenRemove`,
   `waitingShowsAfterAnAskUntilRecorded`), Task 3 (`a check and a placement need no student's consent`).
5. **No photo path is written, whatever the source:** a camera page or a Photos pick (HEIC included) is reduced, sent and
   dropped; Keep leaves `photo_path` null and makes no Storage call. Tests: Task 18 (`TextbookStoreTests.nothingIsKeptOfThePhoto`),
   Task 8 (`TextbookRowTests.theWrittenRowHasNoPhotoPath`).
6. **The five tabs from a V1 deep link:** `tutorcentral://attendance?date=&class=` opens the More tab with the Mark root
   pushed at that day and batch; `student/<id>`, `fees?month=` and `event/<id>` as before; a reminder's tap too. Tests:
   Task 11 (`DeepLinkTests.attendanceOpensOnTheMoreTab`, `TabsStateTests.anAttendanceLinkPushesTheMarkRoot`).
7. **A student with one or two eligible skills, or with the ladder and a book:** the check call takes one to three
   skills; a class 2 student's placement covers the ladder's steps and the book's chapters. Tests: Task 3 (`make check
   takes one to three skills`), Task 5 (`SpacedQueueTests.fewerThanThreeEligibleGivesFewer`), Task 19
   (`PlacementStoreTests.aLadderStudentIsPlacedOnStepsAndChapters`).

## File structure

Created or changed, by module. A file has one job; the stores are small and named for what they do.

| Module | File | Job |
|---|---|---|
| supabase | `migrations/20261022000017_v2_close_states_placement_copy.sql` | `close_session` with `p_states`; `record_placement`; `copy_textbook_to_class`; `copy_textbooks_to_student`; `copy_textbook_chapters` moving own chapters behind the book's |
| supabase | `tests/v2.test.ts` (extended), `seed.sql` (class levels, a school), `types.ts` | The function tests; the local data; the generated types |
| api | `src/schemas.ts` (`TextbookOutput`, `ChecksOutput`, `PlacementOutput`; check skills 1 to 3), `src/errors.ts` (the monthly words), `src/prompts/parse-textbook.ts`, `src/prompts/check.ts`, `src/prompts/placement.ts`, `src/routes/common.ts` (`run`, `parse`, `answer`, `notYet` moved out of `ai.ts`), `src/routes/v2.ts` (`/make` by kind, `/parse-textbook`), `src/routes/ai.ts` (V1 and the two skeletons left), `src/claude-fake.ts` (three samples), `test/v2.test.ts`, `test/prompts.test.ts` | The two routes live |
| Domain | `Student.swift` (V2 fields), `StudentDraft.swift` (V2 fields, `classMissing`), `StudentQuery.swift` (`StudentSort.status`), `Record/ConsentRecord.swift`, `Record/ConsentMessage.swift`, `Record/RecordTypes.swift` (`CheckRecord`, `HomeworkRecord`, `HomeworkStatus`, `SkillStateChange`, `MessageEntry`, `MessageKind`), `Record/SkillProgress.swift`, `Record/SpacedQueue.swift`, `Record/TrackingRules.swift`, `Record/Subject.swift`, `Record/SessionClose.swift` (moved from Data, `states`, `Codable`), `Record/PlacementRecord.swift`, `Queue/QueuedChange.swift` (`.close`), `Queue/PendingChanges.swift` (the close's replace rule), `Queue/OfflineRefusal.swift` (five writes) | The rules and the shapes |
| Data | `Students/StudentRow.swift`, `SupabaseStudentsRepository.swift`, `StudentsRepository.swift` (`setConsent`), `FakeStudentsRepository.swift` (V2 seed), `Schools/*` (`setBoard`), `Textbooks/*` (`copyToClass`, `copyAll`, `addChapter`, the fake's seed), `Record/RecordRepository.swift`, `Record/SupabaseRecordRepository.swift`, `Record/RecordRows.swift`, `Record/FakeRecordRepository.swift`, `Messages/*` (`logConsent`, `messages`), `AI/AIRepository.swift` (three calls, DTOs), `AI/APIClient+V2.swift`, `AI/APIBodies.swift`, `AI/APIFailure.swift` (`.allowance`), `AI/FakeAIRepository.swift`, `AI/AISamples+V2.swift`, `Attendance/SupabaseAttendanceRepository.swift` (`p_states`), `Queue/QueueRunner.swift` (`.close`) | The reads and writes behind the screens |
| DesignSystem | `Components/StatusWord.swift`, `TrackingCard.swift`, `PickerTileHelper.swift`, `ChipRow.swift`, `ChoiceRow.swift` (`ChoiceRow`, `AddFieldRow`), `RecordRows.swift` (`ChapterRow`, `SkillRow`, `StateMark`, `SubjectHead`), `TrendCard.swift`, `LadderRow.swift`, `CheckRow.swift`, `ConsentRows.swift`, `BatchHero.swift`, `FooterBand.swift`, `Tokens/Tokens.swift` and `docs/design/design-tokens.md` where a board's value is new | The Phase 10 parts this phase uses |
| Features/Students | `StudentsView.swift`, `StudentsListSections.swift` (the status word on the row, "Batches"), `RegisterStore.swift` (`sort = .status`, copy at add, consent), `StudentFormStore.swift`, `StudentFormSheet.swift`, `SchoolSheet.swift`, `ClassWheel` use, `StudentDetailStore.swift`, `StudentDetailView.swift`, `StudentDetailSections.swift`, `RecordSections.swift` (This week, Record, Checks, Homework, School, Messages), `ConsentSection.swift`, `ConsentAskSheet.swift`, `ConsentRecordSheet.swift`, `ConsentStore.swift`, `TextbookStore.swift`, `TextbookIntroView.swift`, `SubjectSheet.swift`, `TextbookChaptersView.swift`, `ChapterSheet.swift`, `PlacementStore.swift`, `PlacementView.swift`, `ClassesView.swift`, `ClassFormSheet.swift` (the word Batch) | Students extended |
| Features/Today | `TodayStore.swift` (the batch hero, the closed hero), `TodaySections.swift` (`BatchHeroCard`), `CloseStore.swift`, `CloseStore+Checks.swift`, `CloseStore+Queue.swift`, `CloseView.swift`, `CloseSections.swift` | The close |
| Features/Attendance | `AttendanceView.swift` (pushed: `BackRow`, `FooterBand`, History quiet), `AttendanceSections.swift` (the word Batch) | Unchanged screens, moved |
| AppShell | `TabsView.swift`, `TabsState.swift` (`Route.attendance`, `Route.close`, `Route.textbook`, `Route.placement`), `Domain/AppTab.swift` (school in, attendance out), `DeepLink.swift`, `MoreView.swift`, `SchoolLaterView.swift`, `RootView+Attendance.swift`, `RootView+Students.swift`, `RootView+Today.swift`, `RootView+Close.swift`, `RootView+LaunchStates.swift`, `LaunchState.swift`, `Fixtures.swift`, `Fixtures+Record.swift`, `Dependencies.swift` (`schools`, `textbooks`, `record`), `SessionStore.swift` where the wipe lists files | The shell |
| Tests | `supabase/tests/v2.test.ts`; `api/test/v2.test.ts`; `DomainTests/{StudentDraftTests, StudentQueryTests, ConsentMessageTests, SkillProgressTests, SpacedQueueTests, TrackingRulesTests, SessionCloseTests (moved), PendingChangesTests, OfflineRefusalTests}`; `DataTests/{StudentRowTests, StudentWriteRowTests, TextbookRowTests, RecordRowTests, FakeRecordRepositoryTests, APIClientTests, APIBodiesV2Tests, QueueRunnerTests}`; `StudentsTests/{StudentFormStoreTests, RegisterStoreTests, StudentQueryTests, StudentDetailStoreTests, ConsentStoreTests, TextbookStoreTests, PlacementStoreTests}`; `TodayTests/{TodayStoreTests, CloseStoreTests, CloseQueueTests}`; `AppShellTests/{DeepLinkTests, TabsStateTests, LaunchStateTests}`; `DesignSystemTests/TokenDocumentTests` (unchanged, holds the tokens) | |

## Launch states

Each state the 10.1, 10.2 and 10.3 (close) boards name, with the fixtures' data (the clock Wednesday 7 October 2026,
16:35, India). Light twins from `--appearance light` where the board has both. States that existed keep their names and
take the new words and tabs.

| State | Shows | Board | PR |
|---|---|---|---|
| `today` | Today with the five tabs and the batch hero (Start class) over V1's content | P10-Shell-Today (both), P10-Today-Plan's hero | 5, 10 |
| `today-after-close` | Today after the Evening batch's close: the closed hero | P10-Today-AfterClose's hero | 10 |
| `more` | Organise, Make, App | P10-More (both) | 5 |
| `later-school` | The School tab's Later card | P2-Later's pattern, P10-School-Empty's symbol | 5 |
| `attendance`, `attendance-class-menu`, `-exceptions`, `-saved`, `-alert`, `-past`, `-empty`, `-save-failed` | The Mark root pushed on More with the footer band; "Batch" on the picker | P10-Attendance-Pushed, the P4 boards | 5 |
| `classes`, `classes-empty`, `class-new`, `class-edit`, `class`, `class-archive-confirm`, `class-add-members` | V1's screens with the word Batch | the P3 boards, the 10.1 note | 5 |
| `fees` | The Fees tab with the five tabs | P10-Shell-Today's bar | 5 |
| `students`, `students-empty`, `-few`, `-searching`, `-filtered`, `-add-menu` | The list by status, the status word on each row, Batches | P10-Students-List (both), P10-Students-Empty | 6 |
| `student-new`, `-filled`, `-class9`, `-class-picker`, `-school`, `-end`, `-invalid`, `student-edit` | New student V2 and Edit student | P10-NewStudent, -Filled, -Class9, -ClassPicker, -School, -End | 6 |
| `student`, `student-record`, `student-end`, `student-not-known`, `student-ladder`, `student-archived`, `student-archive-confirm`, `student-delete-confirm` | Hemanth's page and its scrolls; Riya; Sahil; the V1 states | P10-Student (both), -Record, -End, -NotKnown, -Ladder | 7 |
| `student-consent-ask`, `student-consent-record`, `student-consent-waiting` | The ask sheet, the record sheet, Riya's page waiting | P10-Consent-Ask, -Record, P10-Student-Consent-Waiting | 7 |
| `textbook-intro`, `textbook-reading`, `textbook-chapters`, `textbook-chapter-edit` | Add a textbook for Riya's Mathematics | P10-Textbook-Intro, -Reading, -Chapters, -Chapter-Edit | 8 |
| `placement` | The placement for Riya | P10-Placement | 9 |
| `close`, `close-scrolled`, `close-placement` | The close for the Evening batch: nothing tapped; two students' checks tapped and one absent; a student with no checks | P10-Close (both), -Scrolled, -Placement | 10 |
| `pending` | Pending changes with a close waiting | P7-Pending's row pattern | 10 |

The fixtures' Evening batch for the close is a third `Classroom` in `FakeClassesRepository` (Mon to Fri 17:00 to 18:30)
holding Dev, Meher, Nikhil (class 8), Riya (class 5) and Sahil (class 2), used by the `close*` and `today*` states only;
the Students and Attendance states keep the seed's two batches.

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-11/db` | Database: the close with skill states, the placement, the class-wide copy; the seed's class levels | none |
| 2 | 2, 3 | `phase-11/api` | The API: `/ai/parse-textbook`, `/ai/make` check and placement, the monthly allowance's words | none |
| main | | | `gh workflow run deploy` after PR 2: 0017 up, the API at `main`'s head (Task 23) | |
| 3 | 4, 5, 6, 7 | `phase-11/domain` | Domain: the student's V2 fields, the record's types, skill progress, the spaced queue, tracking status, consent words, the queued close | none |
| 4 | 8, 9, 10 | `phase-11/data` | Data: the V2 rows and writes, the record repository, consent and messages, the API client's three calls, the close with states, the runner; the write proofs | none |
| 5 | 11 | `phase-11/shell` | Five tabs, School later, More, Attendance under More, "Batch" on V1's screens, the links | `today`, `more`, `later-school`, `fees`, `attendance`, `attendance-class-menu`, `-exceptions`, `-saved`, `-alert`, `-past`, `-empty`, `-save-failed`, `classes`, `classes-empty`, `class-new`, `class-edit`, `class`; both where the board has both |
| 6 | 12, 13 | `phase-11/students-form` | Students by status; New student and Edit student V2; the school sheet; books copied at save | `students`, `students-empty`, `-few`, `-searching`, `-filtered`, `-add-menu`, `student-new`, `-filled`, `-class9`, `-class-picker`, `-school`, `-end`, `-invalid`, `student-edit`; both for the list |
| 7 | 14, 15, 16 | `phase-11/student-page` | The student's page: tracking, this week, the record, checks, homework, school, messages, consent | `student`, `student-record`, `student-end`, `student-not-known`, `student-ladder`, `student-archived`, `student-consent-ask`, `-record`, `-waiting`; both for `student` |
| 8 | 17, 18 | `phase-11/textbook` | The textbook's contents page: intro, reading, the chapters, a chapter, Keep | `textbook-intro`, `-reading`, `-chapters`, `-chapter-edit` |
| 9 | 19 | `phase-11/placement` | The check row; the placement | `placement` |
| 10 | 20, 21, 22 | `phase-11/close` | The batch hero; the close online and offline | `today`, `today-after-close`, `close`, `close-scrolled`, `close-placement`, `pending`; both for `close` and `today` |
| main | 23, 24 | | The deploy, the hand runs, TestFlight, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked, the pictures by
`bun shots <state>` and `bun pr-shots` (rule 2).

---

### Task 1: Migration 0017: the close with skill states, the placement, the class-wide copy (PR 1)

**Files:**
- Create: `supabase/migrations/20261022000017_v2_close_states_placement_copy.sql`
- Modify: `supabase/seed.sql` (class levels, the school), `supabase/types.ts` (regenerated)
- Test: `supabase/tests/v2.test.ts` (new tests appended)

**Interfaces:**
- Consumes: 0009's `copy_textbook_chapters(p_centre, p_textbook, p_student)` (0016's body), 0010's `close_session`
  (seven arguments), `save_attendance`, `is_member`.
- Produces: `close_session(p_centre, p_class, p_date, p_marks, p_checks, p_homework, p_track, p_states jsonb default
  '[]') returns uuid`, `p_states` is `[{"skill_id": "<uuid>", "state": "practising"}]`;
  `record_placement(p_centre uuid, p_student uuid, p_checks jsonb, p_states jsonb, p_track jsonb) returns void`, the
  checks as `close_session` takes them with `kind` forced to `placement` and no session, `p_track` one student's
  `{"status", "reasons"}` or `{}`; `copy_textbook_to_class(p_centre uuid, p_textbook uuid) returns integer` (students
  copied to); `copy_textbooks_to_student(p_centre uuid, p_student uuid) returns integer` (books copied).

- [ ] **Step 1: Write the failing tests** (appended to `supabase/tests/v2.test.ts`; `a`, `centre`, `l` are the file's)

```ts
async function bookFor(school: string, classLevel: string, subject: string, chapters: unknown[]) {
  return (
    await a
      .from("textbooks")
      .insert({ centre_id: centre, school_id: school, class_level: classLevel, subject, title: `${subject} ${classLevel}`, chapters })
      .select("id")
      .single()
  ).data!.id as string;
}
async function studentIn(school: string | null, classLevel: string | null, name: string) {
  return (await a.from("students").insert({ centre_id: centre, name, class_level: classLevel, school_id: school }).select("id").single()).data!.id as string;
}
const two = [
  { position: 1, name: "Fractions", skills: ["Compare fractions", "Add like fractions"] },
  { position: 2, name: "Decimals", skills: ["Read decimals"] },
];

test("copy_textbook_to_class copies the book to every student of that school and class and to no one else", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Copy School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s1 = await studentIn(school, "6", "C1");
  const s2 = await studentIn(school, "6", "C2");
  const other = await studentIn(school, "7", "C3");
  const { data, error } = await a.rpc("copy_textbook_to_class", { p_centre: centre, p_textbook: book });
  expect(error).toBeNull();
  expect(data).toBe(2);
  for (const s of [s1, s2]) expect((await a.from("chapters").select("id").eq("student_id", s)).data).toHaveLength(2);
  expect((await a.from("chapters").select("id").eq("student_id", other)).data).toHaveLength(0);
  const twice = await a.rpc("copy_textbook_to_class", { p_centre: centre, p_textbook: book });
  expect(twice.data).toBe(2);
  expect((await a.from("skills").select("id").eq("student_id", s1)).data).toHaveLength(3);
});

test("copy_textbooks_to_student gives a student who joins later every book of their school and class", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Later School" }).select("id").single()).data!.id;
  await bookFor(school, "6", "Mathematics", two);
  await bookFor(school, "6", "Science", [{ position: 1, name: "Food", skills: ["Sources of food"] }]);
  await bookFor(school, "7", "Mathematics", two);
  const late = await studentIn(school, "6", "Late Joiner");
  const { data, error } = await a.rpc("copy_textbooks_to_student", { p_centre: centre, p_student: late });
  expect(error).toBeNull();
  expect(data).toBe(2);
  const subjects = (await a.from("chapters").select("subject").eq("student_id", late)).data!.map((c) => c.subject).sort();
  expect(subjects).toEqual(["Mathematics", "Mathematics", "Science"]);
  const none = await a.rpc("copy_textbooks_to_student", { p_centre: centre, p_student: await studentIn(null, "6", "No School") });
  expect(none.data).toBe(0);
});

test("a recapture keeps a tutor's own chapter after the book's chapters", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Own School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Own Chapter");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  await a.from("chapters").insert({ centre_id: centre, student_id: s, subject: "Mathematics", position: 3, name: "Tutor's extra" });
  const three = [...two, { position: 3, name: "Integers", skills: ["Order integers"] }];
  await a.from("textbooks").update({ chapters: three }).eq("id", book);
  const { error } = await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  expect(error).toBeNull();
  const rows = (await a.from("chapters").select("position, name").eq("student_id", s).order("position")).data!;
  expect(rows.map((r) => r.name)).toEqual(["Fractions", "Decimals", "Integers", "Tutor's extra"]);
});

test("close_session moves the skill states it is given and leaves the others", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "States School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "States");
  const cls = (await a.from("classes").insert({ centre_id: centre, name: "States batch" }).select("id").single()).data!.id;
  await a.from("students").update({ class_id: cls }).eq("id", s);
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skills = (await a.from("skills").select("id, name").eq("student_id", s).order("position")).data!;
  const first = skills.find((k) => k.name === "Compare fractions")!.id;
  const { data: sid, error } = await a.rpc("close_session", {
    p_centre: centre, p_class: cls, p_date: "2026-10-07",
    p_marks: { [s]: "present" },
    p_checks: [{ student_id: s, skill_id: first, question: { text: "Which is bigger, 1/2 or 1/3?" }, correct: true }],
    p_homework: [{ student_id: s }],
    p_track: { [s]: { status: "on_track", reasons: [] } },
    p_states: [{ skill_id: first, state: "practising" }],
  });
  expect(error).toBeNull();
  expect(sid).toBeTruthy();
  const after = (await a.from("skills").select("name, state, state_at").eq("student_id", s)).data!;
  expect(after.find((k) => k.name === "Compare fractions")?.state).toBe("practising");
  expect(after.find((k) => k.name === "Read decimals")?.state).toBe("not_started");
  // The seven-argument call still works (the app's build 19 sends none).
  const seven = await a.rpc("close_session", {
    p_centre: centre, p_class: cls, p_date: "2026-10-08", p_marks: { [s]: "present" }, p_checks: [], p_homework: [], p_track: {},
  });
  expect(seven.error).toBeNull();
});

test("record_placement writes placement checks without a session, the states and the status; a non-member is refused", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Place School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Placed");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skills = (await a.from("skills").select("id, name").eq("student_id", s)).data!;
  const id = (name: string) => skills.find((k) => k.name === name)!.id;
  const { error } = await a.rpc("record_placement", {
    p_centre: centre, p_student: s,
    p_checks: [
      { student_id: s, skill_id: id("Compare fractions"), question: { text: "Which is bigger?" }, correct: true, kind: "check" },
      { student_id: s, skill_id: id("Read decimals"), question: { text: "Read 0.5" }, correct: false },
    ],
    p_states: [{ skill_id: id("Compare fractions"), state: "secure" }, { skill_id: id("Add like fractions"), state: "secure" }],
    p_track: { status: "not_known", reasons: [] },
  });
  expect(error).toBeNull();
  const checks = (await a.from("checks").select("kind, session_id, correct").eq("student_id", s)).data!;
  expect(checks).toHaveLength(2);
  expect(checks.every((c) => c.kind === "placement" && c.session_id === null)).toBe(true);
  const states = (await a.from("skills").select("name, state").eq("student_id", s)).data!;
  expect(states.filter((k) => k.state === "secure").map((k) => k.name).sort()).toEqual(["Add like fractions", "Compare fractions"]);
  const row = (await a.from("students").select("track_status, tracked_at").eq("id", s).single()).data!;
  expect(row.track_status).toBe("not_known");
  expect(row.tracked_at).not.toBeNull();
  const b = await userClient(l, `v2-b-${stamp}@example.com`);
  const refused = await b.rpc("record_placement", { p_centre: centre, p_student: s, p_checks: [], p_states: [], p_track: {} });
  expect(refused.error?.code).toBe("42501");
});

test("deleting a student takes their chapters, skills, checks and homework with them", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: "Gone School" }).select("id").single()).data!.id;
  const book = await bookFor(school, "6", "Mathematics", two);
  const s = await studentIn(school, "6", "Gone");
  await a.rpc("copy_textbook_chapters", { p_centre: centre, p_textbook: book, p_student: s });
  const skill = (await a.from("skills").select("id").eq("student_id", s).limit(1).single()).data!.id;
  await a.rpc("record_placement", {
    p_centre: centre, p_student: s, p_checks: [{ student_id: s, skill_id: skill, question: {}, correct: true }], p_states: [], p_track: {},
  });
  expect((await a.from("students").delete().eq("id", s)).error).toBeNull();
  for (const table of ["chapters", "skills", "checks", "homework"]) {
    expect((await a.from(table).select("id").eq("student_id", s)).data).toHaveLength(0);
  }
  expect((await a.from("textbooks").select("id").eq("id", book)).data).toHaveLength(1);
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd supabase && supabase db reset >/dev/null && bun test tests/v2.test.ts`
Expected: the six new tests fail (`copy_textbook_to_class` does not exist; `close_session` refuses `p_states`;
`record_placement` does not exist; the recapture test fails on the unique violation).

- [ ] **Step 3: Write the migration**

```sql
-- Phase 11 (docs/spec-v2.md sections 5 and 6; plan/phase-11-plan.md Task 1). Additive (D26): three new functions, two
-- replaced (0010's close_session gains an eighth argument with a default; 0016's copy_textbook_chapters moves the
-- student's own chapters of the subject behind the book's). Nothing from 0001 to 0016 is edited.

-- 1. The close also moves the skill states the app worked out (plan decision 7): p_states [{"skill_id", "state"}].
drop function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb);

create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb, p_states jsonb default '[]'::jsonb) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare sid uuid; v_plan uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_homework) <> 'array' or jsonb_typeof(p_track) <> 'object'
     or jsonb_typeof(p_states) <> 'array' then
    raise exception 'checks, homework and states must be arrays, track an object' using errcode = '22023';
  end if;
  sid := public.save_attendance(p_centre, p_class, p_date, p_marks);
  delete from public.checks c where c.centre_id = p_centre and c.session_id = sid;
  insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct)
  select p_centre, sid, (c->>'student_id')::uuid, (c->>'skill_id')::uuid, coalesce(c->>'kind', 'check'),
         coalesce(c->'question', '{}'::jsonb), (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  update public.skills s set state = (st->>'state')::public.skill_state, state_at = now()
    from jsonb_array_elements(p_states) st
   where s.centre_id = p_centre and s.id = (st->>'skill_id')::uuid and s.state <> (st->>'state')::public.skill_state;
  delete from public.homework h where h.centre_id = p_centre and h.session_id = sid;
  insert into public.homework (centre_id, student_id, session_id, artefact_id, status)
  select p_centre, (h->>'student_id')::uuid, sid, (h->>'artefact_id')::uuid,
         coalesce(h->>'status', 'given')::public.homework_status
  from jsonb_array_elements(p_homework) h;
  update public.students s
     set track_since = case when s.track_status is distinct from t.value->>'status' then now() else s.track_since end,
         track_status = t.value->>'status',
         track_reasons = coalesce(t.value->'reasons', '[]'::jsonb),
         tracked_at = now()
    from jsonb_each(p_track) t
   where s.centre_id = p_centre and s.id = t.key::uuid;
  update public.plans p set session_id = sid
   where p.centre_id = p_centre and p.class_id is not distinct from p_class and p.date = p_date
  returning p.id into v_plan;
  update public.attendance_sessions a set closed_at = now(), plan_id = v_plan where a.id = sid and a.centre_id = p_centre;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb) to authenticated;

-- 2. The placement taken from the student's page (P10-Placement): its answers as checks of kind 'placement' with no
--    session, the states the app worked out, and the student's stored status, in one write.
create function public.record_placement(p_centre uuid, p_student uuid, p_checks jsonb, p_states jsonb, p_track jsonb)
returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_checks) <> 'array' or jsonb_typeof(p_states) <> 'array' or jsonb_typeof(p_track) <> 'object' then
    raise exception 'checks and states must be arrays, track an object' using errcode = '22023';
  end if;
  insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct)
  select p_centre, null, p_student, (c->>'skill_id')::uuid, 'placement', coalesce(c->'question', '{}'::jsonb),
         (c->>'correct')::boolean
  from jsonb_array_elements(p_checks) c;
  update public.skills s set last_checked_at = now()
  where s.centre_id = p_centre and s.student_id = p_student
    and s.id in (select (c->>'skill_id')::uuid from jsonb_array_elements(p_checks) c);
  update public.skills s set state = (st->>'state')::public.skill_state, state_at = now()
    from jsonb_array_elements(p_states) st
   where s.centre_id = p_centre and s.student_id = p_student and s.id = (st->>'skill_id')::uuid
     and s.state <> (st->>'state')::public.skill_state;
  if p_track ? 'status' then
    update public.students s
       set track_since = case when s.track_status is distinct from p_track->>'status' then now() else s.track_since end,
           track_status = p_track->>'status',
           track_reasons = coalesce(p_track->'reasons', '[]'::jsonb),
           tracked_at = now()
     where s.centre_id = p_centre and s.id = p_student;
  end if;
end $$;

revoke all on function public.record_placement(uuid, uuid, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.record_placement(uuid, uuid, jsonb, jsonb, jsonb) to authenticated;

-- 3. copy_textbook_chapters keeps a tutor's own chapter (no book, no syllabus, no ladder) of the same subject after the
--    book's: its position moves behind the book's last chapter before the book's rows are written. Two steps through a
--    high offset, so the unique (student, subject, position) is never hit mid-update. The rest is 0016's body.
create or replace function public.copy_textbook_chapters(p_centre uuid, p_textbook uuid, p_student uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare v_subject text; v_chapters jsonb; v_last integer;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.subject, t.chapters into v_subject, v_chapters from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_subject is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  select coalesce(max((ch->>'position')::integer), 0) into v_last from jsonb_array_elements(v_chapters) ch;

  -- The student's own chapters of the subject, behind the book's, in their order.
  update public.chapters c set position = c.position + 100000
   where c.centre_id = p_centre and c.student_id = p_student and c.subject = v_subject
     and c.textbook_id is null and c.syllabus_id is null and c.ladder is null;
  update public.chapters c set position = v_last + own.rank
    from (select c2.id, row_number() over (order by c2.position) as rank from public.chapters c2
           where c2.centre_id = p_centre and c2.student_id = p_student and c2.subject = v_subject
             and c2.textbook_id is null and c2.syllabus_id is null and c2.ladder is null) own
   where c.id = own.id;

  delete from public.chapters c
   where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
     and not exists (select 1 from jsonb_array_elements(v_chapters) ch where (ch->>'position')::integer = c.position);
  update public.chapters c set name = ch->>'name', subject = v_subject
    from jsonb_array_elements(v_chapters) ch
   where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
     and c.position = (ch->>'position')::integer and (c.name, c.subject) is distinct from (ch->>'name', v_subject);
  insert into public.chapters (centre_id, student_id, subject, position, name, textbook_id)
  select p_centre, p_student, v_subject, (ch->>'position')::integer, ch->>'name', p_textbook
    from jsonb_array_elements(v_chapters) ch
   where not exists (select 1 from public.chapters c
                      where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook
                        and c.position = (ch->>'position')::integer);
  -- Skills by position in each chapter: 0016's three statements, unchanged.
  delete from public.skills k
   using public.chapters c
   where k.centre_id = p_centre and k.chapter_id = c.id and c.centre_id = p_centre and c.student_id = p_student
     and c.textbook_id = p_textbook
     and not exists (select 1 from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w where w.chapter_id = k.chapter_id and w.position = k.position);
  update public.skills k set name = w.name
    from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w
   where k.centre_id = p_centre and k.chapter_id = w.chapter_id and k.position = w.position and k.name <> w.name;
  insert into public.skills (centre_id, chapter_id, student_id, position, name)
  select p_centre, w.chapter_id, p_student, w.position, w.name
    from (select c.id as chapter_id, s.ordinality::integer as position, s.value as name
            from public.chapters c
            join jsonb_array_elements(v_chapters) ch on (ch->>'position')::integer = c.position
            cross join lateral jsonb_array_elements_text(ch->'skills') with ordinality as s(value, ordinality)
           where c.centre_id = p_centre and c.student_id = p_student and c.textbook_id = p_textbook) w
   where not exists (select 1 from public.skills k where k.centre_id = p_centre and k.chapter_id = w.chapter_id and k.position = w.position);
end $$;

-- 4. Keep copies the book to every active student of its school and class (P10-Textbook-Chapters' Keep); the count copied.
create function public.copy_textbook_to_class(p_centre uuid, p_textbook uuid) returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_school uuid; v_class text; v_count integer := 0; r record;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  select t.school_id, t.class_level into v_school, v_class from public.textbooks t where t.id = p_textbook and t.centre_id = p_centre;
  if v_school is null then raise exception 'no such textbook' using errcode = '22023'; end if;
  for r in select s.id from public.students s
            where s.centre_id = p_centre and s.school_id = v_school and s.class_level = v_class and s.archived_at is null
  loop
    perform public.copy_textbook_chapters(p_centre, p_textbook, r.id);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

revoke all on function public.copy_textbook_to_class(uuid, uuid) from public, anon;
grant execute on function public.copy_textbook_to_class(uuid, uuid) to authenticated;

-- 5. A student saved with a school and class gets every book of that school and class (the scope's "a later student of
--    the class gets them at add time"); the count of books.
create function public.copy_textbooks_to_student(p_centre uuid, p_student uuid) returns integer
language plpgsql security invoker set search_path = '' as $$
declare v_count integer := 0; r record;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  for r in select t.id from public.textbooks t
             join public.students s on s.centre_id = t.centre_id and s.school_id = t.school_id and s.class_level = t.class_level
            where t.centre_id = p_centre and s.id = p_student
  loop
    perform public.copy_textbook_chapters(p_centre, r.id, p_student);
    v_count := v_count + 1;
  end loop;
  return v_count;
end $$;

revoke all on function public.copy_textbooks_to_student(uuid, uuid) from public, anon;
grant execute on function public.copy_textbooks_to_student(uuid, uuid) to authenticated;
```

- [ ] **Step 4: The seed** (`supabase/seed.sql`, after the students' insert): one school and class levels for eight

```sql
-- V2 (Phase 11): one school and class levels for eight of the ten; Bir Bikram Singh and Lakshmi Menon stay as V1 made
-- them, so a hand run always meets a student with no class level.
insert into public.schools (id, centre_id, name, board) values
  ('44444444-4444-4444-4444-444444444441', '22222222-2222-2222-2222-222222222222', 'Vidya Niketan', 'cbse');
update public.students set class_level = '10', school_id = '44444444-4444-4444-4444-444444444441', board = 'cbse'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name in ('Hemanth Reddy', 'Akshita Rao', 'Ananya Iyer');
update public.students set class_level = '8' where centre_id = '22222222-2222-2222-2222-222222222222'
   and name in ('Dev Kumar', 'Meher Shah', 'Nikhil Das');
update public.students set class_level = '5', school_id = '44444444-4444-4444-4444-444444444441'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Riya Sharma';
update public.students set class_level = '2' where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Sahil Verma';
```

- [ ] **Step 5: Run the tests; regenerate the types**

Run: `cd supabase && supabase db reset >/dev/null && bun test tests && supabase gen types typescript --local > types.ts`
Expected: every test passes (the catalogue test sees no new table; the four functions carry no `PUBLIC` execute).

- [ ] **Step 6: `bun check --only=db`, commit, PR 1**

```bash
git checkout -b phase-11/db && git add supabase && git commit -m "Database: the close with skill states, the placement, the class-wide copy (0017); the seed's class levels"
```

### Task 2: The API: `/ai/parse-textbook` (PR 2)

**Files:**
- Create: `api/src/prompts/parse-textbook.ts`, `api/src/routes/common.ts`, `api/src/routes/v2.ts`, `api/test/v2.test.ts`
- Modify: `api/src/schemas.ts` (`TextbookOutput`), `api/src/routes/ai.ts` (`run`, `parse`, `isParsed`, `answer`,
  `notYet`, `safeJSON` move to `common.ts` and are imported; the `/make` and `/parse-textbook` skeletons go; `v2Routes`
  mounted), `api/src/claude-fake.ts` (`SAMPLE.parse_textbook`, `kindOf`), `api/src/models.ts` (unchanged, used),
  `api/test/prompts.test.ts`

**Interfaces:**
- Consumes: `ParseTextbookInput` (0010's schema), `decodeImage`, `modelFor("parse_textbook", classLevel)` (Sonnet),
  `Db.start` with kind `parse_textbook` (the monthly allowance; no consent).
- Produces: `TextbookOutput = { title: string | null, chapters: [{ name: string, skills: string[] (1 to 8) }] (1 to 40) }`;
  the route answers `{ id, result: TextbookOutput }`; the record's input is `{ kind: "parse_textbook", pages: 1, bytes,
  classLevel, subject }` (never the image).

- [ ] **Step 1: Write the failing tests** (`api/test/v2.test.ts`)

```ts
import { expect, test } from "bun:test";
import { fakeApple } from "../src/apple-fake.js";
import { fakeClaude, SAMPLE } from "../src/claude-fake.js";
import { fakeDb } from "../src/db-fake.js";
import { makeApp } from "../src/make-app.js";

const centreId = "22222222-2222-2222-2222-222222222222";
const auth = { authorization: "Bearer good", "content-type": "application/json" };
const verify = async (t: string) => (t === "good" ? { id: "u1" } : null);
const app = (claude = fakeClaude({ answer: SAMPLE.parse_textbook }), db = fakeDb()) => makeApp({ verify, claude, db, apple: fakeApple({}) });
const post = (a: ReturnType<typeof makeApp>, path: string, body: unknown) => a.request(path, { method: "POST", headers: auth, body: JSON.stringify(body) });
const jpeg = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0, 0, 0, 0]).toString("base64");
const image = { imageBase64: jpeg, mediaType: "image/jpeg" };

test("parse-textbook reads a contents page into chapters and skills, records the class and subject, never the image", async () => {
  const claude = fakeClaude({ answer: SAMPLE.parse_textbook });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string | null; chapters: { name: string; skills: string[] }[] } };
  expect(body.result.chapters[0]).toEqual({ name: "The Fish Tale", skills: ["Compare lengths and weights", "Read large numbers", "Use units of measure"] });
  expect(db.started[0]).toMatchObject({ kind: "parse_textbook", model: "claude-sonnet-5-5", input: { pages: 1, bytes: 8, classLevel: "5", subject: "Mathematics" } });
  expect(JSON.stringify(db.started[0])).not.toContain(jpeg);
  expect(claude.requests[0]?.images).toHaveLength(1);
  expect(claude.requests[0]?.text).toContain("contents page");
});

test("parse-textbook checks the photo first and says so when the chapters cannot be read", async () => {
  const db = fakeDb();
  const bad = await post(app(undefined, db), "/ai/parse-textbook", { centreId, image: { imageBase64: "AAAA", mediaType: "image/jpeg" }, classLevel: "5", subject: "Mathematics" });
  expect(bad.status).toBe(400);
  expect(db.started).toHaveLength(0);
  const refused = await post(app(fakeClaude({ refuse: true }), db), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(refused.status).toBe(422);
  expect(await refused.json()).toEqual({ error: "Couldn't read the chapters from this photo. Try a flatter, brighter one." });
});

test("the monthly allowance is worded for the month on a V2 kind", async () => {
  const r = await post(app(undefined, fakeDb({ limit: 0 })), "/ai/parse-textbook", { centreId, image, classLevel: "5", subject: "Mathematics" });
  expect(r.status).toBe(429);
  expect(await r.json()).toEqual({ error: "You've made this month's 0. More next month.", limit: 0, kind: "parse_textbook" });
});
```

And in `api/test/prompts.test.ts`:

```ts
test("the textbook prompt asks for chapter names and short skills, never the book's text", () => {
  const r = textbookRequest({ mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, "5", "Mathematics");
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.system).toContain("chapter names as printed");
  expect(r.system).toContain("never copy");
  expect(r.text).toContain("class 5");
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd api && bun test test/v2.test.ts test/prompts.test.ts`
Expected: FAIL (501 "not yet"; `SAMPLE.parse_textbook` undefined; `textbookRequest` not exported).

- [ ] **Step 3: The schema, the prompt, the sample, the words**

`src/schemas.ts`:

```ts
/** What a contents page reads into (POST /ai/parse-textbook): the chapter names as printed and two to eight short
 *  skills under each, from the section headings; nothing from inside the book (D58). The position is the order. */
export const TextbookOutput = z.object({
  title: z.string().max(200).nullable(),
  chapters: z.array(z.object({ name: z.string().min(1).max(200), skills: z.array(z.string().min(1).max(200)).min(1).max(8) })).min(1).max(40),
});
export type TextbookOutput = z.infer<typeof TextbookOutput>;
```

`src/prompts/parse-textbook.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { modelFor } from "../models.js";
import { type ClassLevel, TextbookOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** One photographed contents page read into chapters, each with the skills a tutor teaches and checks. */
export function request(image: DecodedImage, classLevel: ClassLevel, subject: string): ClaudeRequest<TextbookOutput> {
  return {
    model: modelFor("parse_textbook", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You read photographs of a school textbook's contents page.",
      "Return the chapter names as printed, in the book's order, and the book's title if the page shows it.",
      "Under each chapter give two to eight skills: what a student can do after that chapter, each a short phrase of at most ten words, taken from the section headings on the page.",
      "Never copy sentences, exercises or page text: only chapter names and skill phrases.",
      "Skip prefaces, acknowledgements, answer keys and appendices. If nothing on the page is a chapter, return no chapters.",
    ].join(" "),
    text: `Read this contents page of a class ${classLevel} ${subject} textbook.`,
    images: [{ mediaType: image.mediaType, base64: image.base64 }],
    schema: TextbookOutput,
  };
}
```

`src/claude-fake.ts`: a `parse_textbook` sample (the CBSE class 5 maths contents page, five chapters, three skills each,
the first "The Fish Tale"), added to `SAMPLE`, and `kindOf` returns `parse_textbook` when `request.text.includes("contents
page")`.

`src/errors.ts`: `limit(kind, limit)` words by kind: V1 kinds keep "You've made today's N. Try again tomorrow."; the V2
kinds (every `V2Kind`) say `You've made this month's ${limit}. More next month.`; `REFUSED.parse_textbook` is "Couldn't
read the chapters from this photo. Try a flatter, brighter one."

- [ ] **Step 4: `common.ts` and the route**

`src/routes/common.ts` exports `run`, `parse`, `isParsed`, `answer`, `notYet`, `safeJSON` and the `Call`, `C` types as
`ai.ts` had them (moved, not changed). `src/routes/v2.ts`:

```ts
import { Hono } from "hono";
import type { Vars } from "../auth.js";
import type { ClaudeClient } from "../claude.js";
import type { Db } from "../db.js";
import { errors } from "../errors.js";
import { decodeImage } from "../images.js";
import { request as textbookRequest } from "../prompts/parse-textbook.js";
import { MakeInput, ParseTextbookInput } from "../schemas.js";
import { answer, isParsed, notYet, parse, run } from "./common.js";

/** The V2 routes that are live (docs/spec-v2.md section 9): the textbook's contents page, and `/make` for the kinds this
 *  phase makes (check, placement); every other kind answers 501 until its phase. */
export function v2Routes(deps: { claude: ClaudeClient; db: Db }) {
  const routes = new Hono<Vars>();
  routes.post("/parse-textbook", async (c) => {
    const body = await parse(c, ParseTextbookInput);
    if (!isParsed(body)) return body;
    const image = decodeImage(body.value.image);
    if (typeof image === "string") return answer(c, errors.badImage(image));
    const { classLevel, subject } = body.value;
    const input = { kind: "parse_textbook", pages: 1, bytes: image.bytes, classLevel, subject };
    return run(c, deps, body.centre, { kind: "parse_textbook", input, request: textbookRequest(image, classLevel, subject) });
  });
  routes.post("/make", async (c) => {
    const body = await parse(c, MakeInput);
    if (!isParsed(body)) return body;
    return notYet(c, "/ai/make"); // Task 3 fills the kinds in
  });
  return routes;
}
```

`ai.ts` mounts it: `routes.route("/", v2Routes(deps))` after the two remaining skeletons (`/plan`, `/parse-school`).

- [ ] **Step 5: Run the tests**

Run: `cd api && bun run check`
Expected: tsc clean, every test passes (`entry.test.ts` still finds `src/index.ts` as the one entry: `common.ts` and
`v2.ts` are not reserved names).

- [ ] **Step 6: Commit**

```bash
git checkout -b phase-11/api && git add api && git commit -m "API: /ai/parse-textbook reads a contents page into chapters and skills; the monthly allowance's words"
```

### Task 3: The API: `/ai/make` check and placement (PR 2)

**Files:**
- Create: `api/src/prompts/check.ts`, `api/src/prompts/placement.ts`
- Modify: `api/src/schemas.ts` (`ChecksOutput`, `PlacementOutput`; check skills `.min(1).max(3)`), `api/src/routes/v2.ts`,
  `api/src/claude-fake.ts` (`SAMPLE.check`, `SAMPLE.placement`, `kindOf`), `api/test/v2.test.ts`, `api/test/schemas.test.ts`

**Interfaces:**
- Produces: `ChecksOutput = { questions: [{ skill, question, answer }] (1 to 3) }` for kind `check` (Haiku); `PlacementOutput
  = { questions: [{ chapter, question, answer }] (1 to 30) }` for kind `placement` (Haiku); the record's input is the body
  (skills or chapters, the class and subject; no student); the other `/make` kinds answer 501.

- [ ] **Step 1: Write the failing tests** (`api/test/v2.test.ts`)

```ts
const check = { kind: "check", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants", "Tell a physical from a chemical change"] };

test("make check asks three questions, one per skill, on Haiku, with no student in the record", async () => {
  const claude = fakeClaude({ answer: SAMPLE.check });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", check);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { questions: { skill: string; question: string; answer: string }[] } };
  expect(body.result.questions).toHaveLength(3);
  expect(body.result.questions.map((q) => q.skill)).toEqual(check.skills);
  expect(db.started[0]).toMatchObject({ kind: "check", model: "claude-haiku-5-5", input: { skills: check.skills, classLevel: "8" } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
});

test("make check takes one to three skills", async () => {
  const one = await post(app(fakeClaude({ answer: { questions: [SAMPLE.check.questions[0]] } })), "/ai/make", { ...check, skills: ["Balance a chemical equation"] });
  expect(one.status).toBe(200);
  const four = await post(app(), "/ai/make", { ...check, skills: [...check.skills, "One more"] });
  expect(four.status).toBe(400);
});

test("make placement asks one question per chapter in the book's order", async () => {
  const claude = fakeClaude({ answer: SAMPLE.placement });
  const r = await post(app(claude), "/ai/make", { kind: "placement", centreId, classLevel: "5", subject: "Mathematics", chapters: ["The Fish Tale", "Shapes and Angles", "How Many Squares?"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { questions: { chapter: string; question: string; answer: string }[] } };
  expect(body.result.questions.map((q) => q.chapter)).toEqual(["The Fish Tale", "Shapes and Angles", "How Many Squares?"]);
  expect(claude.requests[0]?.model).toBe("claude-haiku-5-5");
});

test("a check and a placement need no student's consent; the other kinds still answer 501", async () => {
  const db = fakeDb({ consent: false });
  expect((await post(app(undefined, db), "/ai/make", check)).status).toBe(200);
  const sheet = await post(app(undefined, db), "/ai/make", { kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"] });
  expect(sheet.status).toBe(501);
  expect(db.started).toHaveLength(1);
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd api && bun test test/v2.test.ts`
Expected: FAIL (501; `SAMPLE.check` undefined; four skills not refused).

- [ ] **Step 3: The schemas, prompts and samples**

`src/schemas.ts`: in `MakeInput`'s check, `skills: Skills.min(1).max(3)`; and

```ts
/** The close's three questions (one per skill, asked aloud, answered in a few words) and the placement's (one per
 *  chapter, the chapter's most basic idea). The app keeps the question and the tap; the answer is for the tutor's eye. */
export const ChecksOutput = z.object({
  questions: z.array(z.object({ skill: z.string().min(1).max(200), question: z.string().min(1).max(300), answer: z.string().min(1).max(200) })).min(1).max(3),
});
export type ChecksOutput = z.infer<typeof ChecksOutput>;
export const PlacementOutput = z.object({
  questions: z.array(z.object({ chapter: z.string().min(1).max(200), question: z.string().min(1).max(300), answer: z.string().min(1).max(200) })).min(1).max(30),
});
export type PlacementOutput = z.infer<typeof PlacementOutput>;
```

`src/prompts/check.ts`:

```ts
export function request(classLevel: ClassLevel, subject: string, skills: string[]): ClaudeRequest<ChecksOutput> {
  return {
    model: modelFor("check", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write questions a tutor asks a student aloud at the end of a class, one per skill, in the skill's order.",
      "Each question is one sentence a student of that class answers in a few words or one line of working; give the expected answer in at most twelve words.",
      "Use numbers and examples a student would meet in the textbook for that class; no multiple choice, no trick questions.",
      `Return exactly ${skills.length} question${skills.length === 1 ? "" : "s"}, the skill field repeating the skill as given.`,
    ].join(" "),
    text: `Class ${classLevel} ${subject}. Three questions, one for each skill: ${skills.map((s) => `"${s}"`).join(", ")}.`,
    schema: ChecksOutput,
  };
}
```

(the text says "Three questions" only when there are three: `${skills.length === 1 ? "One question" : skills.length === 2 ? "Two questions" : "Three questions"}`.)

`src/prompts/placement.ts`: the same shape on `modelFor("placement", classLevel)`, system "You write one question per
chapter that tells whether a student has the chapter's most basic idea, in the chapters' order; the chapter field repeats
the chapter as given; a student who knows the chapter answers it in a few words", text `Class ${classLevel} ${subject}.
One question for each chapter: …`, schema `PlacementOutput`.

`src/claude-fake.ts`: `SAMPLE.check` (three questions on the three Science skills above) and `SAMPLE.placement` (three
questions on the three class 5 chapters); `kindOf`: "placement" in the text → `placement`; "for each skill" →
`check`.

- [ ] **Step 4: The route's dispatch** (`src/routes/v2.ts`, replacing the `notYet` body)

```ts
  routes.post("/make", async (c) => {
    const body = await parse(c, MakeInput);
    if (!isParsed(body)) return body;
    const v = body.value;
    switch (v.kind) {
      case "check":
        return run(c, deps, body.centre, { kind: "check", input: v, request: checkRequest(v.classLevel, v.subject, v.skills) });
      case "placement":
        return run(c, deps, body.centre, { kind: "placement", input: v, request: placementRequest(v.classLevel, v.subject, v.chapters) });
      default:
        return notYet(c, "/ai/make");
    }
  });
```

- [ ] **Step 5: Run the tests, commit**

Run: `cd api && bun run check` → clean. `bun check --only=api` green.

```bash
git add api && git commit -m "API: /ai/make makes the close's checks and the placement's questions on Haiku"
```

Open PR 2 (`phase-11/api`) with both commits; merge on green. Then `gh workflow run deploy` (Task 23, step 1).

### Task 4: Domain: the student's V2 fields, the draft, the sort by status (PR 3)

**Files:**
- Modify: `Domain/Student.swift`, `Domain/StudentDraft.swift`, `Domain/StudentQuery.swift`
- Create: `Domain/Record/ConsentRecord.swift`
- Test: `Tests/DomainTests/StudentDraftTests.swift`, `StudentQueryTests.swift`, `StudentTests.swift`

**Interfaces:**
- Produces: `ConsentRecord(at: Date, phone: PhoneNumber, how: ConsentMethod)`, `Hashable, Sendable, Codable`.
  `Student` gains `classLevel: ClassLevel?`, `schoolID: UUID?`, `board: Board?`, `messageLanguage: MessageLanguage`,
  `consent: ConsentRecord?`, `trackStatus: TrackStatus`, `trackReasons: [String]`, `trackSince: Date?`, each a
  defaulted trailing `init` parameter (`nil`, `.default`, `.notKnown`, `[]`, `nil`) so every V1 call site compiles;
  `var classTitle: String?` ("Class 10", "LKG"), `var showsBoard: Bool` (`classLevel?.expectsBoard == true`).
  `StudentDraft` gains `classLevel: ClassLevel?`, `schoolID: UUID?`, `board: Board?`, `messageLanguage: MessageLanguage =
  .default` and `Problem.classMissing` ("Choose the student's class."); `problems(today:, requiresClass: Bool = false)`.
  `StudentSort.status` (label "Status"): by `trackStatus` (not on track, watch, on track, not known yet), then name.

- [ ] **Step 1: Write the failing tests**

```swift
// StudentDraftTests additions
@Test func aNewStudentNeedsAClassAndAnEditDoesNot() {
    var draft = StudentDraft()
    draft.name = "Riya Sharma"
    #expect(draft.problems(today: today, requiresClass: true) == [.classMissing])
    #expect(draft.problems(today: today) == [])
    draft.classLevel = .five
    #expect(draft.problems(today: today, requiresClass: true) == [])
}

@Test func editingAStudentWithoutAClassSaves() {
    let v1 = Student(id: UUID(), name: "Bir Bikram Singh", classID: nil, monthlyFee: nil, parentName: nil,
                     parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil)
    let draft = StudentDraft(v1)
    #expect(draft.classLevel == nil && draft.messageLanguage == .english)
    #expect(draft.isValid(today: today))
}

@Test func theDraftCarriesTheV2Fields() {
    var student = Student(id: UUID(), name: "Hemanth Reddy", classID: nil, monthlyFee: nil, parentName: nil,
                          parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil,
                          classLevel: .ten, schoolID: UUID(), board: .cbse, messageLanguage: .kannada)
    student.trackStatus = .watch
    let draft = StudentDraft(student)
    #expect(draft.classLevel == .ten && draft.board == .cbse && draft.messageLanguage == .kannada && draft.schoolID == student.schoolID)
    #expect(student.classTitle == "Class 10" && student.showsBoard)
}

// StudentQueryTests addition
@Test func theStatusSortPutsThoseWhoNeedTheTutorFirstThenByName() {
    func make(_ name: String, _ status: TrackStatus) -> Student {
        var s = Student(id: UUID(), name: name, classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil,
                        dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil)
        s.trackStatus = status
        return s
    }
    let sorted = StudentQuery.apply(
        [make("Zoya", .onTrack), make("Riya", .notKnown), make("Hemanth", .watch), make("Dev", .notOnTrack), make("Ananya", .watch)],
        classes: [], search: "", filter: .all, sort: .status
    )
    #expect(sorted.map(\.name) == ["Dev", "Ananya", "Hemanth", "Zoya", "Riya"])
}
```

- [ ] **Step 2: Run them to see them fail** (the test script of session 22, `xt.sh DomainTests/StudentDraftTests
  DomainTests/StudentQueryTests`; or `bun check --only=ios`) → compile errors on the new members.

- [ ] **Step 3: Implement**

`ConsentRecord`:

```swift
import Foundation

/// The parent's recorded agreement (D62): when, which number, how (`students.consent_at`, `consent_phone`, `consent_how`).
public struct ConsentRecord: Hashable, Sendable, Codable {
    public let at: Date
    public let phone: PhoneNumber
    public let how: ConsentMethod

    public init(at: Date, phone: PhoneNumber, how: ConsentMethod) {
        self.at = at
        self.phone = phone
        self.how = how
    }
}
```

`Student`: the eight stored properties with their defaults in `init`; `classTitle` is `classLevel?.title`; `showsBoard`.
`StudentDraft`: the four fields; `init(_ student:)` copies them; `problems(today:requiresClass:)` inserts `.classMissing`
when `requiresClass && classLevel == nil`; `isValid(today:requiresClass:)` likewise. `StudentQuery`: `case .status:` sorts
by `(lhs.trackStatus, name)` using `TrackStatus`'s `Comparable` (already in the list's order).

- [ ] **Step 4: Run the tests** → pass; the whole `DomainTests` still passes (the V1 initialisers are untouched).

- [ ] **Step 5: Commit**

```bash
git checkout -b phase-11/domain && git add ios && git commit -m "Domain: the student's class, school, board, language, consent and status; the draft; the sort by status"
```

### Task 5: Domain: the record's types, skill progress, the spaced queue (PR 3)

**Files:**
- Create: `Domain/Record/RecordTypes.swift`, `Domain/Record/SkillProgress.swift`, `Domain/Record/SpacedQueue.swift`,
  `Domain/Record/Subject.swift`, `Domain/Record/PlacementRecord.swift`
- Move: `Data/Attendance/SessionClose.swift` → `Domain/Record/SessionClose.swift` (`Codable`; `states:
  [SkillStateChange]` added with a default `[]`); `Tests/DataTests/SessionCloseTests.swift` → `Tests/DomainTests/`
- Test: `Tests/DomainTests/SkillProgressTests.swift`, `SpacedQueueTests.swift`, `SessionCloseTests.swift`

**Interfaces:**
- Produces:

```swift
public enum HomeworkStatus: String, CaseIterable, Hashable, Sendable, Codable { case given, done, partial, notDone = "not_done"
    public var title: String  // "Given", "Done", "Partial", "Not done"
}
public struct CheckRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID; public let studentID: UUID; public let skillID: UUID; public let sessionID: UUID?
    public let question: String; public let correct: Bool; public let at: Date; public let isPlacement: Bool
}
public struct HomeworkRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID; public let studentID: UUID; public let sessionID: UUID; public let givenAt: Date; public var status: HomeworkStatus
}
public struct SkillStateChange: Hashable, Sendable, Codable { public let skillID: UUID; public let state: SkillState }
public enum MessageKind: String, Hashable, Sendable, Codable { case reminder, receipt, absence, progress, note, canDo = "can_do", testTomorrow = "test_tomorrow", homework, consent
    public var title: String  // "Fee reminder", "Receipt", "Absence alert", "Progress note", "Weekly note", "Can now do", "Test tomorrow", "Homework", "Consent"
}
public struct MessageEntry: Identifiable, Hashable, Sendable, Codable { public let id: UUID; public let kind: MessageKind; public let openedAt: Date; public let language: MessageLanguage? }
public enum Subject { public static let common = ["Mathematics", "Science", "English", "Hindi", "Kannada", "Social Science", "EVS", "Computer"] }
public struct PlacementRecord: Hashable, Sendable {
    public let studentID: UUID; public let checks: [SessionClose.Check]; public let states: [SkillStateChange]; public let track: SessionClose.Track?
}
public enum SkillProgress {
    /// The state after one check (plan decision 7); nil when it does not move.
    public static func after(_ state: SkillState, correct: Bool, previousCorrect: Bool?) -> SkillState?
    /// The placement: chapters in position order with their skills and the tap (nil: skipped); every chapter before the
    /// first wrong that was answered right makes its skills secure.
    public static func placementChanges(_ answered: [(chapter: Chapter, skills: [Skill], correct: Bool?)]) -> [SkillStateChange]
}
public enum SpacedQueue {
    public static let count = 3
    public static func interval(for state: SkillState) -> Int?   // days: taught 1, revisit 1, practising 3, secure 7, notStarted nil
    /// The skills to check now: the most recently taught first, then the most overdue; ties by chapter position then
    /// skill position; at most `count`.
    public static func pick(skills: [Skill], chapters: [Chapter], now: Date, calendar: Calendar) -> [Skill]
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@Test func rightAndWrongMoveTheStatesAsDecided() {
    #expect(SkillProgress.after(.notStarted, correct: true, previousCorrect: nil) == .practising)
    #expect(SkillProgress.after(.taught, correct: true, previousCorrect: nil) == .practising)
    #expect(SkillProgress.after(.practising, correct: true, previousCorrect: true) == .secure)
    #expect(SkillProgress.after(.practising, correct: true, previousCorrect: false) == nil)
    #expect(SkillProgress.after(.revisit, correct: true, previousCorrect: nil) == .practising)
    #expect(SkillProgress.after(.secure, correct: true, previousCorrect: true) == nil)
    #expect(SkillProgress.after(.secure, correct: false, previousCorrect: nil) == .revisit)
    #expect(SkillProgress.after(.practising, correct: false, previousCorrect: nil) == nil)
    #expect(SkillProgress.after(.taught, correct: false, previousCorrect: nil) == nil)
}

@Test func thePlacementMakesTheChaptersBeforeTheFirstWrongSecure() {
    let (c1, c2, c3) = (chapter(1), chapter(2), chapter(3))
    let s1 = [skill(c1, 1), skill(c1, 2)], s2 = [skill(c2, 1)], s3 = [skill(c3, 1)]
    let changes = SkillProgress.placementChanges([(c1, s1, true), (c2, s2, nil), (c3, s3, false)])
    #expect(Set(changes.map(\.skillID)) == Set(s1.map(\.id)))
    #expect(changes.allSatisfy { $0.state == .secure })
    #expect(SkillProgress.placementChanges([(c1, s1, false), (c2, s2, true)]).isEmpty)
}

@Test func theQueuePicksTheLatestTaughtThenTheMostOverdue() {
    let now = FakeClock.oct7at1635  // a Date helper in DomainTests
    let day: TimeInterval = 86400
    let c = chapter(1)
    let fresh = skill(c, 1, state: .taught, stateAt: now - day)                       // taught yesterday: today's
    let secureOld = skill(c, 2, state: .secure, stateAt: now - 30 * day, checked: now - 20 * day)   // 13 days over
    let practising = skill(c, 3, state: .practising, stateAt: now - 10 * day, checked: now - 5 * day) // 2 days over
    let secureNew = skill(c, 4, state: .secure, stateAt: now - 30 * day, checked: now - 2 * day)    // not due
    let notStarted = skill(c, 5, state: .notStarted, stateAt: now - day)
    let picked = SpacedQueue.pick(skills: [notStarted, secureNew, practising, secureOld, fresh], chapters: [c], now: now, calendar: DayHeading.india)
    #expect(picked.map(\.id) == [fresh.id, secureOld.id, practising.id])
}

@Test func fewerThanThreeEligibleGivesFewerAndNoneGivesNone() {
    let c = chapter(1)
    let one = skill(c, 1, state: .taught, stateAt: FakeClock.oct7at1635)
    #expect(SpacedQueue.pick(skills: [one, skill(c, 2)], chapters: [c], now: FakeClock.oct7at1635, calendar: DayHeading.india).map(\.id) == [one.id])
    #expect(SpacedQueue.pick(skills: [skill(c, 2)], chapters: [c], now: FakeClock.oct7at1635, calendar: DayHeading.india).isEmpty)
}

@Test func aSessionCloseRoundTripsAsJSON() throws {
    let close = SessionClose(classID: UUID(), date: Day(year: 2026, month: 10, day: 7)!, marks: [UUID(): .present],
                             checks: [.init(studentID: UUID(), skillID: UUID(), question: "Q", correct: true, isPlacement: false)],
                             homework: [.init(studentID: UUID(), artefactID: nil)], track: [:],
                             states: [SkillStateChange(skillID: UUID(), state: .practising)])
    let back = try JSONDecoder().decode(SessionClose.self, from: JSONEncoder().encode(close))
    #expect(back == close)
}
```

(`chapter(_:)` and `skill(_:_:state:stateAt:checked:)` are small helpers at the top of the test file building a `Chapter`
of "Mathematics" at that position and a `Skill` in it.)

- [ ] **Step 2: Run to see them fail** → compile errors.

- [ ] **Step 3: Implement**

`SkillProgress.after`:

```swift
public static func after(_ state: SkillState, correct: Bool, previousCorrect: Bool?) -> SkillState? {
    switch (state, correct) {
    case (.notStarted, true), (.taught, true), (.revisit, true): .practising
    case (.practising, true): previousCorrect == true ? .secure : nil
    case (.secure, false): .revisit
    default: nil
    }
}
```

`placementChanges`: iterate the tuples sorted by `chapter.position`; `nil` continues; `true` appends `.secure` for each
skill; `false` stops.

`SpacedQueue.pick`: `eligible = skills.filter { $0.state != .notStarted }`; `let order: (Skill) -> (Int, Int)` by the
chapter's position (from `chapters`) and the skill's; `current = eligible.max { ($0.stateAt, -order) }`; the rest sorted by
`overdue = days(since: lastCheckedAt ?? stateAt) - interval(for: state)` descending, ties by `order`; `[current] + rest`
prefix `count`. Days through `calendar.dateComponents([.day], from:to:)`.

`SessionClose` moved to Domain with `public var states: [SkillStateChange]` (a defaulted `init` parameter), `Codable`;
Data's `AttendanceRepository`, `FakeAttendanceRepository`, `SupabaseAttendanceRepository` import it from Domain (they
already `import Domain`).

- [ ] **Step 4: Run `DomainTests` and `DataTests`** → pass. **Step 5: Commit** "Domain: the record's types, skill progress,
  the spaced queue; SessionClose moves to Domain".

### Task 6: Domain: the tracking status rules (PR 3)

**Files:**
- Create: `Domain/Record/TrackingRules.swift`
- Test: `Tests/DomainTests/TrackingRulesTests.swift`

**Interfaces:**
- Produces:

```swift
public struct TrackingInput: Hashable, Sendable {
    public var checks: [CheckRecord]          // the student's, newest or oldest, any age
    public var absences: Int                  // in the last 28 days
    public var homework: [HomeworkRecord]     // the student's, any order
    public var skills: [Skill]
    public var chapters: [Chapter]
    public var classLevel: ClassLevel?
    public var now: Date
    public var calendar: Calendar
}
public struct Tracking: Hashable, Sendable {
    public let status: TrackStatus
    public let reasons: [String]     // the fired rules' sentences, worst first; [] for not known yet
    public let nextStep: String      // the "Next" line
}
public enum TrackingRules {
    public static let checkWindowDays = 21, absenceWindowDays = 28, minimumChecks = 6
    public static func evaluate(_ input: TrackingInput) -> Tracking
    /// The first skill not yet secure, by chapter then skill position; nil when there is none.
    public static func currentSkill(skills: [Skill], chapters: [Chapter]) -> Skill?
    /// Chapters started (any skill beyond not started) against the term calendar (June to March, ten months), per subject.
    public static func chaptersBehind(skills: [Skill], chapters: [Chapter], now: Date, calendar: Calendar) -> (subject: String, behind: Int)?
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct TrackingRulesTests {
    let now = FakeClock.oct7at1635
    let day: TimeInterval = 86400
    func input(checks: [CheckRecord] = [], absences: Int = 0, homework: [HomeworkRecord] = [], skills: [Skill] = [], chapters: [Chapter] = []) -> TrackingInput {
        TrackingInput(checks: checks, absences: absences, homework: homework, skills: skills, chapters: chapters, classLevel: .ten, now: now, calendar: DayHeading.india)
    }
    func check(_ correct: Bool, daysAgo: Int) -> CheckRecord {
        CheckRecord(id: UUID(), studentID: UUID(), skillID: UUID(), sessionID: UUID(), question: "", correct: correct, at: now - Double(daysAgo) * day, isPlacement: false)
    }
    func homework(_ status: HomeworkStatus, daysAgo: Int) -> HomeworkRecord {
        HomeworkRecord(id: UUID(), studentID: UUID(), sessionID: UUID(), givenAt: now - Double(daysAgo) * day, status: status)
    }

    @Test func aStudentWithoutChecksIsNotKnown() {
        let t = TrackingRules.evaluate(input(absences: 5))
        #expect(t.status == .notKnown && t.reasons.isEmpty)
        #expect(t.nextStep == "Start with the class's first chapter until the checks say otherwise.")
    }

    @Test func accuracyOverThreeWeeksBands() {
        let poor = (0 ..< 9).map { check($0 < 4, daysAgo: $0 * 2) }           // 4 of 9
        let t = TrackingRules.evaluate(input(checks: poor))
        #expect(t.status == .notOnTrack && t.reasons == ["4 of 9 checks right over three weeks"])
        let fair = (0 ..< 10).map { check($0 < 6, daysAgo: $0) }             // 6 of 10
        #expect(TrackingRules.evaluate(input(checks: fair)).status == .watch)
        let good = (0 ..< 10).map { check($0 < 8, daysAgo: $0) }             // 8 of 10
        #expect(TrackingRules.evaluate(input(checks: good)).status == .onTrack)
        let few = (0 ..< 3).map { check(false, daysAgo: $0) }                // under six checks: accuracy does not fire
        #expect(TrackingRules.evaluate(input(checks: few)).status == .onTrack)
        let old = (0 ..< 9).map { check(false, daysAgo: 22 + $0) }           // outside the window
        #expect(TrackingRules.evaluate(input(checks: old)).status == .onTrack)
    }

    @Test func absencesAndHomeworkBands() {
        let some = [check(true, daysAgo: 1)]
        #expect(TrackingRules.evaluate(input(checks: some, absences: 2)).status == .watch)
        let t = TrackingRules.evaluate(input(checks: some, absences: 4))
        #expect(t.status == .notOnTrack && t.reasons == ["Absent 4 times in four weeks"])
        let twoNotDone = [homework(.notDone, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.done, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: twoNotDone)).status == .watch)
        let three = [homework(.notDone, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.notDone, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: three)).reasons == ["Homework not done three times running"])
        let given = [homework(.given, daysAgo: 1), homework(.notDone, daysAgo: 3), homework(.notDone, daysAgo: 5)]
        #expect(TrackingRules.evaluate(input(checks: some, homework: given)).status == .onTrack) // a row still "given" is not "not done"
    }

    @Test func chaptersBehindTheTermCalendar() {
        // October: five of ten months gone, so a book of 14 chapters expects 7 started.
        let chapters = (1 ... 14).map { chapter($0) }
        let skills = chapters.flatMap { c in [skill(c, 1, state: c.position <= 4 ? .secure : .notStarted, stateAt: now)] }
        let behind = TrackingRules.chaptersBehind(skills: skills, chapters: chapters, now: now, calendar: DayHeading.india)
        #expect(behind?.behind == 3 && behind?.subject == "Mathematics")
        let t = TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)], skills: skills, chapters: chapters))
        #expect(t.status == .notOnTrack && t.reasons == ["3 chapters behind in Mathematics"])
    }

    @Test func theWorstRuleWinsAndEveryFiredReasonIsKept() {
        let fair = (0 ..< 10).map { check($0 < 6, daysAgo: $0) }
        let t = TrackingRules.evaluate(input(checks: fair, absences: 4))
        #expect(t.status == .notOnTrack)
        #expect(t.reasons == ["Absent 4 times in four weeks", "6 of 10 checks right over three weeks"])
    }

    @Test func theNextStepNamesTheCurrentSkill() {
        let c = chapter(1)
        let skills = [skill(c, 1, state: .secure, stateAt: now), skill(c, 2, state: .practising, stateAt: now, name: "Add like fractions"), skill(c, 3, name: "Subtract fractions")]
        let watch = TrackingRules.evaluate(input(checks: (0 ..< 10).map { check($0 < 6, daysAgo: $0) }, skills: skills, chapters: [c]))
        #expect(watch.nextStep == "Teach Add like fractions again with a worked example.")
        let good = TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)], skills: skills, chapters: [c]))
        #expect(good.nextStep == "Continue with Add like fractions.")
        let bad = TrackingRules.evaluate(input(checks: (0 ..< 9).map { check(false, daysAgo: $0) }, skills: skills, chapters: [c]))
        #expect(bad.nextStep == "Step back to the skill before Add like fractions.")
        #expect(TrackingRules.evaluate(input(checks: [check(true, daysAgo: 1)])).nextStep == "Carry on with the next chapter.")
    }
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** as the tests spell out: the accuracy window from
  `now - 21 days`; absences from the input; homework sorted by `givenAt` descending, the run of `.notDone` from the
  newest; `chaptersBehind` groups chapters by subject, `started = chapters with a skill whose state != .notStarted`,
  `monthsElapsed = ((month - 6 + 12) % 12) + 1` clamped to 1 to 10 (June is 1, March 10, April and May 10),
  `expected = Int((Double(total) * Double(monthsElapsed) / 10).rounded(.up))`, `behind = expected - started`, the
  subject with the largest `behind` when it is ≥ 2 (a ladder chapter, `ladder != nil`, is left out). Reasons in severity
  order: absences, homework, chapters, accuracy; each with its sentence. `nextStep` by status with `currentSkill`'s name,
  the two fallbacks given. `evaluate` returns `.notKnown` first when `checks.isEmpty`.

- [ ] **Step 4: Run** → pass. **Step 5: Commit** "Domain: the tracking status rules, with reasons and the next step".

### Task 7: Domain: the consent words, the queued close, the offline refusals (PR 3)

**Files:**
- Create: `Domain/Record/ConsentMessage.swift`
- Modify: `Domain/Queue/QueuedChange.swift`, `Domain/Queue/PendingChanges.swift`, `Domain/Queue/OfflineRefusal.swift`
- Test: `Tests/DomainTests/ConsentMessageTests.swift`, `PendingChangesTests.swift`, `OfflineRefusalTests.swift`

**Interfaces:**
- Produces: `ConsentMessage.text(parentFirstName: String, childFirstName: String, gender: Gender?, tutorName: String,
  centreName: String?) -> String` (the board's text from `components.md`, "her"/"his"/"their", the absence alert's
  signature); `QueuedChangeCase.close`; `QueuedChange.Kind.close(close: SessionClose, className: String, present: Int,
  total: Int)` with `title` "Class closed · <batch>", `line` "Wed 7 Oct · 4 of 5 came · 8 checks · 18:32", `shortName`
  "the close of <batch>"; `PendingChanges.sameRow`: two closes of the same `classID` and `date` are one row;
  `OfflineRefusal.Write` gains `.consent`, `.textbook`, `.placement`, `.homeworkStatus`, `.addChapter` with their words.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func theConsentMessageFollowsTheBoardAndTheGender() {
    let her = ConsentMessage.text(parentFirstName: "Neha", childFirstName: "Riya", gender: .female, tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
    #expect(her.hasPrefix("Hello Neha, I use Tutor Central to plan Riya's classes and keep her progress."))
    #expect(her.contains("her name, class, marks and work may be read by an AI service (Claude, by Anthropic)."))
    #expect(her.contains("Please reply YES if you agree. Thank you."))
    #expect(her.hasSuffix("Meera Nair\nBright Minds Tuition"))
    #expect(ConsentMessage.text(parentFirstName: "Ramesh", childFirstName: "Dev", gender: .male, tutorName: "M", centreName: nil).contains("keep his progress"))
    #expect(ConsentMessage.text(parentFirstName: "A", childFirstName: "B", gender: nil, tutorName: "M", centreName: nil).contains("keep their progress"))
}

@Test func aSecondCloseOfTheSameBatchAndDayReplacesTheFirst() {
    var pending = PendingChanges()
    let batch = UUID(), day = Day(year: 2026, month: 10, day: 7)!
    func close(_ present: Int) -> QueuedChange {
        QueuedChange(kind: .close(close: SessionClose(classID: batch, date: day, marks: [:], checks: [], homework: [], track: [:]), className: "Evening batch", present: present, total: 5), madeAt: FakeClock.oct7at1635)
    }
    pending.add(close(5))
    pending.add(close(4))
    #expect(pending.changes.count == 1)
    if case let .close(_, _, present, _) = pending.changes[0].kind { #expect(present == 4) } else { Issue.record("not a close") }
    pending.add(QueuedChange(kind: .attendance(classID: batch, className: "Evening batch", date: day, marks: [:], present: 5, total: 5), madeAt: FakeClock.oct7at1635))
    #expect(pending.changes.count == 2 && pending.has(kind: .close) && pending.has(kind: .attendance))
}

@Test func theCloseRowReadsAsTheBoardDoes() {
    let change = QueuedChange(kind: .close(close: SessionClose(classID: UUID(), date: Day(year: 2026, month: 10, day: 7)!, marks: [:], checks: [], homework: [], track: [:]), className: "Evening batch", present: 4, total: 5), madeAt: FakeClock.oct7at1832)
    #expect(change.title == "Class closed · Evening batch")
    #expect(change.line(calendar: DayHeading.india) == "Wed 7 Oct · 4 of 5 came · 0 checks · 18:32")
    #expect(change.shortName == "the close of Evening batch")
}

@Test func theNewRefusalsArePlain() {
    for write in [OfflineRefusal.Write.consent, .textbook, .placement, .homeworkStatus, .addChapter] {
        let words = OfflineRefusal.words(for: write)
        #expect(words.hasPrefix("You're offline.") && !words.lowercased().contains("server"))
    }
    #expect(OfflineRefusal.words(for: .textbook) == "You're offline. Reading a contents page needs a connection; nothing was saved.")
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** (`ConsentMessage` builds the sentence with `pronoun`
  "her"/"his"/"their" and `possessive` the same; the signature as `AbsenceMessage` joins it); the queue's case, row words
  and replace rule; the refusals: consent "You're offline. Recording consent needs a connection; nothing was saved.",
  placement "You're offline. The placement's questions need a connection.", homeworkStatus "You're offline. Marking
  homework needs a connection; nothing was changed.", addChapter "You're offline. Adding a chapter needs a connection;
  nothing was saved."

- [ ] **Step 4: Run `DomainTests`** → pass; `ErrorWordsTests` passes over the new strings. **Step 5: Commit** "Domain: the
  consent message, the queued close, the offline refusals"; open PR 3 (`phase-11/domain`), merge on green.

### Task 8: Data: the V2 rows and writes for students, schools and textbooks (PR 4)

**Files:**
- Modify: `Data/Students/StudentRow.swift`, `SupabaseStudentsRepository.swift` (`columns`, `values`, `setConsent`),
  `StudentsRepository.swift`, `FakeStudentsRepository.swift` (the seed's V2 values, `setConsent`),
  `Data/Schools/SchoolsRepository.swift` (`setBoard`), `SupabaseSchoolsRepository.swift`, `FakeSchoolsRepository.swift`,
  `Data/Textbooks/TextbooksRepository.swift` (`copyToClass`, `copyAll`, `addChapter`), `SupabaseTextbooksRepository.swift`,
  `FakeTextbooksRepository.swift` (`seed`, `init(textbooks:chapters:skills:)`, the three calls)
- Test: `Tests/DataTests/StudentRowTests.swift`, `StudentWriteRowTests.swift`, `TextbookRowTests.swift`,
  `FakeStudentsRepositoryTests.swift`, `FakeTextbooksRepositoryTests.swift`

**Interfaces:**
- Produces: `StudentRow` decodes `class_level`, `school_id`, `board`, `message_language`, `consent_at`, `consent_phone`,
  `consent_how`, `track_status`, `track_reasons`, `track_since`; `SupabaseStudentsRepository.columns` names them;
  `values(_ draft:)` writes `class_level`, `school_id`, `board` (null unless `classLevel.expectsBoard`),
  `message_language`. `StudentsRepository.setConsent(id: UUID, _ consent: ConsentRecord?) async throws -> Student`
  (nil clears the three columns). `SchoolsRepository.setBoard(id: UUID, _ board: Board) async throws`.
  `TextbooksRepository.copyToClass(textbookID: UUID, centre: UUID) async throws -> Int`, `copyAll(to studentID: UUID,
  centre: UUID) async throws -> Int`, `addChapter(student: UUID, subject: String, name: String, skills: [String], centre:
  UUID) async throws -> Chapter` (position `max + 1` for the subject, read first; the skills inserted after).
  `FakeTextbooksRepository.seed`: Hemanth's Mathematics (14 chapters of the CBSE class 10 book, the first three taught,
  with skill states as the P10-Student-Record board draws) and Sahil's three ladder chapters (Reading on Sentences,
  Writing on Words, Numbers on To 99: the steps before secure).

- [ ] **Step 1: Write the failing tests**

```swift
// StudentRowTests
@Test func aV1RowReadsWithV2Defaults() throws {
    let json = #"{"id":"6a7b…","name":"Bir Bikram Singh","class_id":null,"monthly_fee":null,"parent_name":null,"parent_phone":null,"date_of_birth":null,"gender":null,"notes":null,"archived_at":null,"class_level":null,"school_id":null,"board":null,"message_language":"en","consent_at":null,"consent_phone":null,"consent_how":null,"track_status":"not_known","track_reasons":[],"track_since":null}"#
    let student = try PostgRESTDecoder.make().decode(StudentRow.self, from: Data(json.utf8)).student(calendar: DayHeading.india)
    #expect(student.classLevel == nil && student.consent == nil && student.trackStatus == .notKnown && student.messageLanguage == .english)
}

@Test func aV2RowReadsItsRecord() throws {
    let json = #"{…,"class_level":"10","school_id":"7a5f1b3e-9c2d-4e8f-a1b2-c3d4e5f60731","board":"cbse","message_language":"kn","consent_at":"2026-10-02T11:00:00+00:00","consent_phone":"+919380260871","consent_how":"whatsapp","track_status":"watch","track_reasons":["Absent 2 times in four weeks"],"track_since":"2026-10-02T12:34:00+00:00"}"#
    let student = try PostgRESTDecoder.make().decode(StudentRow.self, from: Data(json.utf8)).student(calendar: DayHeading.india)
    #expect(student.classLevel == .ten && student.board == .cbse && student.messageLanguage == .kannada)
    #expect(student.consent?.how == .whatsapp && student.consent?.phone.e164 == "+919380260871")
    #expect(student.trackStatus == .watch && student.trackReasons == ["Absent 2 times in four weeks"] && student.trackSince != nil)
}

// StudentWriteRowTests
@Test func theWrittenValuesCarryTheV2Fields() {
    var draft = StudentDraft()
    draft.name = "Riya Sharma"; draft.classLevel = .nine; draft.board = .karnataka; draft.schoolID = FakeSchoolsRepository.vidya.id; draft.messageLanguage = .hindi
    let values = SupabaseStudentsRepository.values(draft)
    #expect(values["class_level"] == .string("9") && values["board"] == .string("karnataka") && values["message_language"] == .string("hi"))
    #expect(values["school_id"] == .string(FakeSchoolsRepository.vidya.id.uuidString.lowercased()))
    draft.classLevel = .five
    #expect(SupabaseStudentsRepository.values(draft)["board"] == .null)   // a board below class 8 is not kept
}

@Test func consentValuesWriteAndClear() {
    let record = ConsentRecord(at: FakeClock.oct7at1635, phone: PhoneNumber(e164: "+919811122233")!, how: .call)
    let set = SupabaseStudentsRepository.consentValues(record)
    #expect(set["consent_how"] == .string("call") && set["consent_phone"] == .string("+919811122233") && set["consent_at"] != .null)
    let cleared = SupabaseStudentsRepository.consentValues(nil)
    #expect(cleared["consent_at"] == .null && cleared["consent_phone"] == .null && cleared["consent_how"] == .null)
}

// TextbookRowTests
@Test func theWrittenRowHasNoPhotoPath() {
    let book = Textbook(id: UUID(), schoolID: UUID(), classLevel: .five, subject: "Mathematics", title: "Maths 5", publisher: nil, edition: nil, chapters: [])
    #expect(SupabaseTextbooksRepository.values(book, centre: UUID())["photo_path"] == nil)
}

// FakeTextbooksRepositoryTests
@Test func copyToClassReachesEveryStudentOfTheSchoolAndClassAndCopyAllReachesALateJoiner() async throws {
    let repo = FakeTextbooksRepository()
    let book = try await repo.save(Textbook(id: UUID(), schoolID: FakeSchoolsRepository.vidya.id, classLevel: .ten, subject: "Mathematics", title: "Maths 10", publisher: nil, edition: nil, chapters: [TextbookChapter(position: 1, name: "Real Numbers", skills: ["Find the HCF by Euclid's method"])]), centre: FakeSchoolsRepository.centre)
    repo.students = FakeStudentsRepository.seed   // the fake copies by the seed's school and class
    let copied = try await repo.copyToClass(textbookID: book.id, centre: FakeSchoolsRepository.centre)
    #expect(copied == 3)   // Hemanth, Akshita, Ananya
    let late = UUID()
    repo.students.append(Student(id: late, name: "Late", classID: nil, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil, gender: nil, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: .ten, schoolID: FakeSchoolsRepository.vidya.id))
    #expect(try await repo.copyAll(to: late, centre: FakeSchoolsRepository.centre) == 1)
    #expect(try await repo.chapters(student: late).count == 1)
}

@Test func addChapterAppendsAfterTheSubjectsLast() async throws {
    let repo = FakeTextbooksRepository(textbooks: [], chapters: FakeTextbooksRepository.seedChapters, skills: FakeTextbooksRepository.seedSkills)
    let hemanth = FakeStudentsRepository.hemanth
    let added = try await repo.addChapter(student: hemanth, subject: "Mathematics", name: "Extra practice", skills: ["Solve mixed sums"], centre: FakeSchoolsRepository.centre)
    #expect(added.position == 15)
    #expect(try await repo.skills(student: hemanth).contains { $0.chapterID == added.id && $0.name == "Solve mixed sums" })
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** the rows, `values`, `consentValues` (a `static func`
  tested above), `setConsent` (an update selecting `columns`, decoded), `setBoard` (an update), the three textbook calls
  (`rpc("copy_textbook_to_class")`, `rpc("copy_textbooks_to_student")`, both decoding `Int`; `addChapter` reads
  `max(position)` for the subject, inserts the chapter, then the skills), and the fakes: `FakeStudentsRepository.seed`
  gains the class levels, school and statuses of decision 19 (Hemanth `.watch` with reasons "5 of 9 checks right over
  three weeks" and "Absent 2 times in four weeks", since Friday 2 October; Riya `.notKnown`; every other `.notKnown`
  except Akshita, Ananya `.onTrack`); `FakeTextbooksRepository` gains `var students: [Student]` for the copy rules,
  `seedChapters`, `seedSkills`, `init(textbooks:chapters:skills:now:)`.

- [ ] **Step 4: Run `DataTests`** → pass. **Step 5: Commit** "Data: the student's V2 columns and consent, the school's
  board, the textbook copies and a chapter of the tutor's own".

### Task 9: Data: the record repository; consent and messages in the log (PR 4)

**Files:**
- Create: `Data/Record/RecordRepository.swift`, `SupabaseRecordRepository.swift`, `RecordRows.swift`,
  `FakeRecordRepository.swift`
- Modify: `Data/Messages/MessageLogRepository.swift`, `SupabaseMessageLogRepository.swift`, `FakeMessageLogRepository.swift`,
  `Data/Attendance/SupabaseAttendanceRepository.swift` (`closeParams` writes `p_states`), `FakeAttendanceRepository.swift`
  (`close` records states), `AppShell/Dependencies.swift` (`schools`, `textbooks`, `record`; `live()` and the fixtures)
- Test: `Tests/DataTests/RecordRowTests.swift`, `FakeRecordRepositoryTests.swift`, `SessionCloseParamsTests.swift` (the
  `closeParams` test moved from `SessionCloseTests`, with `p_states`), `MessageRowTests.swift`

**Interfaces:**
- Produces:

```swift
public protocol RecordRepository: Sendable {
    /// The students' checks since a moment, oldest first (the trend and the rules).
    func checks(centre: UUID, students: [UUID], since: Date) async throws -> [CheckRecord]
    /// The students' homework since a moment, newest first.
    func homework(centre: UUID, students: [UUID], since: Date) async throws -> [HomeworkRecord]
    func setHomeworkStatus(id: UUID, _ status: HomeworkStatus) async throws
    /// `record_placement` (migration 0017): the placement's checks, the states and the status in one write.
    func recordPlacement(_ placement: PlacementRecord, centre: UUID) async throws
}
// MessageLogRepository gains
    /// The consent ask's Open WhatsApp, logged before the link opens (kind `consent`); when.
    func logConsent(centre: UUID, studentID: UUID) async throws -> Date
    /// Everything sent about one student, newest first (the page's Messages section and the consent's "asked on").
    func messages(centre: UUID, student: UUID) async throws -> [MessageEntry]
```

`FakeRecordRepository(checks:homework:)` with `seed`: Hemanth's twelve sessions of checks over three weeks (the trend's
bars: 3, 2, 3, 1, 2, 3, 2, 2, 3, 1, 2, 3 right of three) and his homework rows; `placements: [PlacementRecord]`
recorded; `statusChanges: [(UUID, HomeworkStatus)]`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func aCheckRowAndAHomeworkRowDecode() throws {
    let check = #"{"id":"…","student_id":"…","skill_id":"…","session_id":null,"kind":"placement","question":{"text":"Which is bigger, 1/2 or 1/3?"},"correct":true,"created_at":"2026-10-07T11:02:00+00:00"}"#
    let record = try PostgRESTDecoder.make().decode(CheckRow.self, from: Data(check.utf8)).record
    #expect(record.isPlacement && record.sessionID == nil && record.question == "Which is bigger, 1/2 or 1/3?" && record.correct)
    let homework = #"{"id":"…","student_id":"…","session_id":"…","given_at":"2026-10-07T13:02:00+00:00","status":"not_done"}"#
    #expect(try PostgRESTDecoder.make().decode(HomeworkRow.self, from: Data(homework.utf8)).record.status == .notDone)
}

@Test func closeParamsCarryTheStates() {
    let skill = UUID()
    let close = SessionClose(classID: UUID(), date: Day(year: 2026, month: 10, day: 7)!, marks: [:], checks: [], homework: [], track: [:], states: [SkillStateChange(skillID: skill, state: .secure)])
    let params = SupabaseAttendanceRepository.closeParams(close, centre: UUID())
    #expect(params["p_states"] == .array([.object(["skill_id": .string(skill.uuidString.lowercased()), "state": .string("secure")])]))
}

@Test func placementParamsForceTheKindAndCarryTheStatus() {
    let student = UUID()
    let placement = PlacementRecord(studentID: student, checks: [.init(studentID: student, skillID: UUID(), question: "Q", correct: false, isPlacement: true)], states: [], track: SessionClose.Track(status: .notKnown, reasons: []))
    let params = SupabaseRecordRepository.placementParams(placement, centre: UUID())
    guard case let .array(checks)? = params["p_checks"], case let .object(first)? = checks.first else { return Issue.record("no checks") }
    #expect(first["kind"] == .string("placement"))
    #expect(params["p_track"] == .object(["status": .string("not_known"), "reasons": .array([])]))
}

@Test func theFakeRecordsAPlacementAndAStatusChange() async throws {
    let repo = FakeRecordRepository()
    try await repo.setHomeworkStatus(id: FakeRecordRepository.seedHomework[0].id, .done)
    #expect(try await repo.homework(centre: FakeSchoolsRepository.centre, students: [FakeStudentsRepository.hemanth], since: .distantPast).first?.status == .done)
    let placement = PlacementRecord(studentID: FakeStudentsRepository.riya, checks: [], states: [], track: nil)
    try await repo.recordPlacement(placement, centre: FakeSchoolsRepository.centre)
    #expect(repo.placements == [placement])
}

@Test func aMessageEntryDecodesEveryKind() throws {
    let json = #"[{"id":"…","kind":"consent","opened_at":"2026-10-05T10:00:00+00:00","language":null},{"id":"…","kind":"absence","opened_at":"2026-10-02T13:00:00+00:00","language":"hi"}]"#
    let entries = try PostgRESTDecoder.make().decode([MessageEntryRow].self, from: Data(json.utf8)).map(\.entry)
    #expect(entries.map(\.kind) == [.consent, .absence] && entries[1].language == .hindi)
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** the rows (`CheckRow`, `HomeworkRow`, `MessageEntryRow`),
  the Supabase repository (`checks`: `from("checks").select(...).eq("centre_id").in("student_id", values:).gte("created_at",
  since).order("created_at")`; `homework` likewise on `given_at` descending; `setHomeworkStatus` an update;
  `recordPlacement` an `rpc("record_placement", params: placementParams(...))`), `placementParams` (the checks as
  `closeParams` builds them with `kind` always `placement`, `p_states`, `p_track` the student's `{status, reasons}` or
  `{}`), the log's two calls (`logConsent` inserts `kind: "consent"` and decodes `opened_at`; `messages` selects `id, kind,
  opened_at, language` for the student newest first), the fakes, and `Dependencies` with the three new repositories
  (`SupabaseSchoolsRepository`, `SupabaseTextbooksRepository`, `SupabaseRecordRepository` in `live()`; the fakes in
  `Fixtures.dependencies`).

- [ ] **Step 4: Run `DataTests` and `AppShellTests`** → pass. **Step 5: Commit** "Data: the record repository, the
  placement write, consent and messages in the log, the close's states".

### Task 10: Data: the API client's three calls, the fake, the runner's close; the write proofs (PR 4)

**Files:**
- Create: `Data/AI/APIClient+V2.swift`, `Data/AI/AISamples+V2.swift`
- Modify: `Data/AI/AIRepository.swift` (three calls, `TextbookReading`, `CheckQuestion`, `PlacementQuestion`),
  `APIBodies.swift` (`TextbookBody`, `MakeCheckBody`, `MakePlacementBody`, the three envelopes), `APIFailure.swift`
  (`.allowance(Int)`), `APIClient.swift` (`failure(status:body:)` maps 429 with a V2 `kind` to `.allowance`),
  `FakeAIRepository.swift`, `Data/Queue/QueueRunner.swift` (`.close` → `attendance.close`; the gone words)
- Test: `Tests/DataTests/APIClientTests.swift`, `APIBodiesV2Tests.swift`, `FakeAIRepositoryTests.swift`, `QueueRunnerTests.swift`

**Interfaces:**
- Produces:

```swift
public struct TextbookReading: Hashable, Sendable { public let id: UUID; public let title: String?; public let chapters: [TextbookChapter] }
public struct CheckQuestion: Hashable, Sendable, Codable { public let skill: String; public let question: String; public let answer: String }
public struct PlacementQuestion: Hashable, Sendable, Codable { public let chapter: String; public let question: String; public let answer: String }
// AIRepository gains
    func parseTextbook(_ image: ImageUpload, classLevel: ClassLevel, subject: String, centre: UUID) async throws(APIFailure) -> TextbookReading
    func makeChecks(classLevel: ClassLevel, subject: String, skills: [String], centre: UUID) async throws(APIFailure) -> [CheckQuestion]
    func makePlacement(classLevel: ClassLevel, subject: String, chapters: [String], centre: UUID) async throws(APIFailure) -> [PlacementQuestion]
```

`APIFailure.allowance(Int)` reads "You've made this month's \(n). More next month."; `FakeAIRepository` answers
`AISamples.textbook` (the API's sample: five class 5 chapters), `AISamples.checks(for skills:)` (one question per skill
from a small table, "Which is bigger, 1/2 or 1/3?" for anything unknown), `AISamples.placement(for chapters:)`, records
`textbooks`, `checkCalls: [[String]]`, `placementCalls: [[String]]`.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func theThreeBodiesMatchTheSchemas() throws {
    let centre = UUID()
    let textbook = try JSONSerialization.jsonObject(with: JSONEncoder().encode(TextbookBody(centreId: centre.uuidString.lowercased(), image: ImageBody(ImageUpload(data: Data([1, 2]), mediaType: "image/jpeg")), classLevel: "5", subject: "Mathematics"))) as? [String: Any]
    #expect(textbook?["classLevel"] as? String == "5" && (textbook?["image"] as? [String: Any])?["mediaType"] as? String == "image/jpeg")
    let check = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakeCheckBody(centreId: "c", classLevel: "8", subject: "Science", skills: ["A", "B"]))) as? [String: Any]
    #expect(check?["kind"] as? String == "check" && (check?["skills"] as? [String])?.count == 2)
    let placement = try JSONSerialization.jsonObject(with: JSONEncoder().encode(MakePlacementBody(centreId: "c", classLevel: "5", subject: "Mathematics", chapters: ["X"]))) as? [String: Any]
    #expect(placement?["kind"] as? String == "placement")
}

@Test func a429OnAV2KindIsTheMonthlyAllowance() {
    #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: nil, limit: 600, kind: "check")) == .allowance(600))
    #expect(APIClient.failure(status: 429, body: ErrorBody(error: "x", reason: nil, limit: 40, kind: "paper")) == .limit(40))
    #expect(APIFailure.allowance(600).message == "You've made this month's 600. More next month.")
}

@Test func theClientDecodesTheThreeAnswers() async throws {
    // A URLProtocol stub as APIClientTests already uses for generate: the three envelopes.
    let client = APIClient.stubbed(answering: #"{"id":"6b2d…","result":{"title":"Math-Magic 5","chapters":[{"name":"The Fish Tale","skills":["Compare lengths"]}]}}"#)
    let reading = try await client.parseTextbook(ImageUpload(data: Data([1]), mediaType: "image/jpeg"), classLevel: .five, subject: "Mathematics", centre: UUID())
    #expect(reading.title == "Math-Magic 5" && reading.chapters == [TextbookChapter(position: 1, name: "The Fish Tale", skills: ["Compare lengths"])])
    let checks = try await APIClient.stubbed(answering: #"{"id":"…","result":{"questions":[{"skill":"A","question":"Q","answer":"R"}]}}"#).makeChecks(classLevel: .eight, subject: "Science", skills: ["A"], centre: UUID())
    #expect(checks == [CheckQuestion(skill: "A", question: "Q", answer: "R")])
}

@Test func aQueuedCloseIsSentAsOne() async throws {
    let attendance = FakeAttendanceRepository()
    let queue = ChangeQueue(centre: UUID(), directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    let close = SessionClose(classID: FakeClassesRepository.maths.id, date: Day(year: 2026, month: 10, day: 7)!, marks: [FakeStudentsRepository.hemanth: .absent], checks: [], homework: [], track: [:])
    queue.add(QueuedChange(kind: .close(close: close, className: "Class 10 Maths", present: 0, total: 1), madeAt: FakeClock.oct7at1635))
    let runner = QueueRunner(queue: queue, centre: UUID(), attendance: attendance, fees: FakeFeesRepository(), messages: FakeMessageLogRepository())
    #expect(await runner.run() == .done(sent: 1, failed: 0))
    #expect(attendance.closes == [close] && queue.pending.isEmpty)
}

@Test func aGoneBatchFailsTheCloseInWords() {
    let change = QueuedChange(kind: .close(close: SessionClose(classID: UUID(), date: Day(year: 2026, month: 10, day: 7)!, marks: [:], checks: [], homework: [], track: [:]), className: "Evening batch", present: 0, total: 0), madeAt: .now)
    #expect(QueueRunner.reason(for: change, error: PostgrestError(code: "23503", message: "attendance_sessions")) == "Evening batch is no longer here, so this close can't be saved. Keep it here or discard it.")
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** the DTOs and bodies, `APIClient+V2.swift` (three `post`s,
  decoding `TextbookEnvelope`, `ChecksEnvelope`, `PlacementEnvelope`; the chapters numbered by order; `bodyLimit` checked
  on the image), the 429 mapping (`ErrorBody` gains `kind: String?`; V2 kinds are the `V2Kind` list as a `Set<String>` in
  `APIClient`), the fake, the runner's `.close` case and its gone words ("<batch> is no longer here…", "A student marked
  here is no longer in the register, so this close can't be saved…" when the message names `attendance_marks` or
  `checks`).

- [ ] **Step 4: The write proofs against the local stack** (ios/CLAUDE.md: a throwaway test with an in-memory session,
  deleted before the commit): `setConsent` sets and clears; `copyToClass` on a saved book answers 3 and `chapters` reads
  14 rows for Hemanth; `copyAll` on a new class 10 student at Vidya Niketan answers 1; `addChapter` appends at 15;
  `recordPlacement` writes two placement checks and a state; `close` with a state moves it (psql: `select state from
  skills where …`); `logConsent` writes a `consent` row; `parseTextbook` against `bun run dev` with `AI_FAKE=1` answers the
  sample; `makeChecks` with one skill answers one question. Then `supabase db reset`.

- [ ] **Step 5: Run `DataTests`** → pass; `bun check` green. **Step 6: Commit** "Data: the API client's textbook, checks
  and placement calls, the monthly allowance, the queued close in the runner; the write proofs in the description"; open
  PR 4 (`phase-11/data`), merge on green.

### Task 11: AppShell: five tabs, School later, More, Attendance under More, "Batch" on V1's screens, the links (PR 5)

**Files:**
- Modify: `Domain/AppTab.swift` (`today, students, school, fees, more`), `AppShell/TabsView.swift`, `TabsState.swift`
  (`Route.attendance`), `DeepLink.swift` (`.attendance`'s tab is `.more`), `MoreView.swift`, `RootView+Attendance.swift`
  (`openAttendance` pushes `.attendance` on the current tab; the link on More), `RootView+Students.swift`,
  `RootView+Today.swift` (Mark attendance from Today's V1 hero pushes `.attendance` on Today's stack until Task 20),
  `RootView+LaunchStates.swift`, `LaunchState.swift` (`laterSchool`), `Fixtures.swift`, `Fixtures+Offline.swift`
  (`offlineAttendanceSaved` on More), `Features/Attendance/AttendanceView.swift` (`pushed: Bool`: `BackRow`, the title,
  History as the quiet action, the `FooterBand`, the tab bar hidden), `AttendanceSections.swift` (the picker's "Batch"),
  `Features/Students/ClassesView.swift`, `ClassFormSheet.swift`, `ClassFormStore.swift` (titles), `StudentsListSections.swift`
  ("Batches" row and chips), `RegisterStore.swift` (`countLine`: "in <batch>", "with no batch"), `StudentFormStore.swift`
  (`classLabel` "No batch"), `Features/Today/TodayStore.swift` (the tile "Batches today")
- Create: `AppShell/SchoolLaterView.swift`, `DesignSystem/Components/FooterBand.swift`
- Test: `Tests/AppShellTests/DeepLinkTests.swift`, `TabsStateTests.swift`, `LaunchStateTests.swift`,
  `Tests/StudentsTests/RegisterStoreTests.swift` (the words), `Tests/AttendanceTests/AttendanceStoreTests.swift` (the words)

**Interfaces:**
- Produces: `AppTab.school`; `Route.attendance` (the Mark root; `TabsView` resolves it to `attendance()` on any tab);
  `TabsState.open(.attendance)` sets `paths[.more] = [.attendance]`; `FooterBand { content }` (the band of `ground` 130
  high, the button 50 above the safe area, `pageSide` beside; `FooterButton`'s inset rule for toasts, D49);
  `SchoolLaterView` (the P2-Later card: `FeatureTile(symbol: "building.columns")`, "School", "Tests, homework, notices and
  holidays from your students' schools arrive here in a later build."); `MoreView`'s rows per `components.md` 10.1
  (Make something opens `.aiAssistant`); `AttendanceView(pushed: true)` everywhere it is reached now.
- The words: each "class" meaning V1's group reads "batch" on screen: the Students tab's compact row and chips
  ("Batches"), the "+" menu ("New batch"), the list's title ("Batches"), New batch and Edit batch, the student form's
  "Batch" picker ("No batch yet"), the attendance picker's tile ("Batch"), Today's tile ("Batches today"), the alert's and
  queue's "attendance for <batch>" stays as it names the batch. The database and the Swift types are untouched (D56).

- [ ] **Step 1: Write the failing tests**

```swift
@Test func attendanceOpensOnTheMoreTab() throws {
    let link = try #require(DeepLink(url: URL(string: "tutorcentral://attendance?date=2026-10-05&class=33333333-3333-3333-3333-333333333331")!))
    #expect(link.tab == .more)
    #expect(AppTab.allCases == [.today, .students, .school, .fees, .more])
}

@Test func anAttendanceLinkPushesTheMarkRoot() {
    let tabs = TabsState(selected: .fees)
    tabs.push(.payments)
    #expect(tabs.open(.attendance(date: nil, classID: nil)))
    #expect(tabs.selected == .more && tabs.paths[.more] == [.attendance])
    #expect(tabs.paths[.fees] == [.payments])   // another tab's stack is left alone
}

@Test func theLaterSchoolStateAndTheMovedAttendanceStatesHaveTheirTabs() {
    #expect(RootView.tab(for: .laterSchool) == .school)
    #expect(RootView.tab(for: .attendance) == .more && RootView.initialRoutes(for: .attendance) == [.attendance])
    #expect(RootView.tab(for: .history) == .more && RootView.initialRoutes(for: .history) == [.attendance, .history])
}

// RegisterStoreTests addition
@Test func theCountLineSaysBatch() async {
    let store = await register()
    store.filter = .unassigned
    #expect(store.countLine == "1 with no batch")
    store.filter = .classroom(FakeClassesRepository.maths.id)
    #expect(store.countLine == "6 in Class 10 Maths")
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Implement** the tab enum and bar (`Tab("School", systemImage:
  "building.columns", value: AppTab.school) { stack(.school) { SchoolLaterView() } }` third), the route and its
  destination, the link, More's three cards, the pushed Attendance (its root view keeps `statusBarGlass`; the footer
  becomes `FooterBand`), the words, the fixtures (`laterSchool`), the launch-state tables (`tab(for:)` sends the
  attendance and history states to `.more` with `initialRoutes` `[.attendance]` and `[.attendance, .history]`; the
  `offlineAttendanceSaved` state likewise).

- [ ] **Step 4: Run `AppShellTests`, `StudentsTests`, `AttendanceTests`, `TodayTests`** → pass. `bun check` green.

- [ ] **Step 5: Pictures** (`bun shots <state>` for every state in PR 5's row; `bun pr-shots phase-11-shell <files>`),
  compared with P10-Shell-Today, P10-More, P10-School-Empty's symbol, P10-Attendance-Pushed and the P3 and P4 boards.
  Commit "Shell: five tabs, School on its way, More's three cards, Attendance under More, the word Batch"; open PR 5,
  merge on green with the table.

### Task 12: DesignSystem: the parts for the list and the form (PR 6)

**Files:**
- Create: `DesignSystem/Components/StatusWord.swift`, `PickerTileHelper.swift`, `ChipRow.swift`, `ChoiceRow.swift`
- Modify: `DesignSystem/Tokens/Tokens.swift` and `docs/design/design-tokens.md` only if a board's value is not yet a
  token (the 10.2 parts use `footnote`, `caption`, `rowTitle`, `subhead`, `surface2`, `accentText`, `ok`, `due`,
  `overdue`, `text3`, the tile's 46 and the sheet row's sizes, all named already; check each against `components.md`
  before adding)
- Test: `Tests/DesignSystemTests/StatusWordTests.swift` (a pure mapping)

**Interfaces:**
- Produces: `StatusWord(status: TrackStatus)` (`footnote` 600 in `ok`, `due`, `overdue`, `text3`; `StatusWord.tone(_:)
  -> StatusTone?` and `.symbol(_:)` as a `nonisolated static func` for tests and the tracking card); `PickerTile(label:
  value:helper:placeholder:action:)` (a `PickerTile` overload with a `footnote` `text3` helper line under the tile and a
  placeholder in `text3` when `value` is nil); `ChipRow<Option>(label: String, options: [(Option, String)], selection:
  Binding<Option>, helper: String?)` (the gender chips' row with a label above and a helper under); `ChoiceRow(symbol:
  title: line: chosen: action:)` (the picker's row with a leading `building.columns` tile and a count line, a tick when
  chosen) and `AddFieldRow(placeholder: text: Binding<String>, add: () -> Void)` (the last row: a field and `plus` in
  `accentText`).

- [ ] **Step 1: The test**

```swift
@Test func theStatusWordsAndTones() {
    #expect(StatusWord.tone(.onTrack) == .ok && StatusWord.tone(.watch) == .due && StatusWord.tone(.notOnTrack) == .overdue && StatusWord.tone(.notKnown) == nil)
    #expect(StatusWord.symbol(.watch) == "clock" && StatusWord.symbol(.notKnown) == "circle")
}
```

- [ ] **Step 2: Run to see it fail; Step 3: build the four parts** to `components.md` "Phase 10 parts (step 10.2)";
  **Step 4: run `DesignSystemTests`** (`TokenDocumentTests` holds the tokens); **Step 5: commit** "Kit: the status word,
  the picker tile with a helper, the chip row, the choice rows".

### Task 13: Students: the list by status, New student and Edit student V2, the school sheet, books at save (PR 6)

**Files:**
- Modify: `Features/Students/StudentsView.swift` (`StudentsBoardState` gains `.newStudentClass9`, `.newStudentClassPicker`,
  `.newStudentSchool`, `.newStudentEnd`), `StudentsListSections.swift` (the row's line: the status word, "·", the batch
  or the number as V1 chose), `RegisterStore.swift` (`sort = .status` by default; `addStudent` and `updateStudent` call
  `textbooks.copyAll` when the saved student has a school and a class and either changed; `schools` and `schoolCounts`;
  `addSchool`, `setSchoolBoard`), `StudentFormStore.swift`, `StudentFormSheet.swift`
- Create: `Features/Students/SchoolSheet.swift`, `Features/Students/ClassWheel.swift` (a `WheelPopover<ClassLevel>` use)
- Test: `Tests/StudentsTests/StudentFormStoreTests.swift`, `RegisterStoreTests.swift`

**Interfaces:**
- Consumes: `StudentDraft` V2 (Task 4), `SchoolsRepository`, `TextbooksRepository.copyAll` (Task 8), the Kit parts
  (Task 12), `WheelPopover`, `PhoneWell`, `FittedSheet`.
- Produces: `StudentFormStore` gains `classLevel: ClassLevel?`, `schoolID: UUID?`, `board: Board?`, `messageLanguage:
  MessageLanguage`, `schools: [School]`, `schoolCounts: [UUID: Int]`, `init(mode:classes:schools:schoolCounts:today:
  defaultLanguage:)`, `requiresClass: Bool` (true for `.new`), `showsBoard` (`classLevel?.expectsBoard == true`),
  `classTitle` ("Choose" placeholder), `schoolTitle` ("Choose or add"), `classHelper`, `boardHelper`, `feeHelper` (the
  10.2 words: "Leave empty to use the batch fee once a batch is chosen." / "The batch fee is ₹1,200. This student pays
  this amount instead."), `languageHelper` ("Notes to <parent> are written in this language, with English beside them for
  you."), `schoolLine(_:)` ("3 students · CBSE"), `addSchool(name:) async -> School?`; `RegisterStore.sort` defaults to
  `.status`; `RegisterStore.addStudent` copies the books after the create; `defaultLanguage` comes from AppShell's
  `@AppStorage("lastMessageLanguage")`, written on every save.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func aNewStudentNeedsNameAndClassAndTheBoardShowsFromClassEight() {
    let form = StudentFormStore(mode: .new, classes: [], schools: [FakeSchoolsRepository.vidya], schoolCounts: [:], today: today, defaultLanguage: .english)
    form.name = "Riya Sharma"
    #expect(!form.canSave && form.classTitle == "Choose" && !form.showsBoard)
    form.classLevel = .five
    #expect(form.canSave && form.schoolTitle == "Choose or add")
    form.classLevel = .nine
    #expect(form.showsBoard && form.boardHelper == "Shown from class 8. The chapters follow the board's list.")
}

@Test func editingAV1StudentSavesWithoutAClass() {
    let bir = FakeStudentsRepository.seed.first { $0.name == "Bir Bikram Singh" }!
    let form = StudentFormStore(mode: .edit(bir), classes: FakeClassesRepository.seed, schools: [], schoolCounts: [:], today: today, defaultLanguage: .english)
    form.parentName = "Harjeet S Singh"
    #expect(form.canSave && form.classLevel == nil)
}

@Test func theLanguageStartsFromTheTutorsLastChoiceAndTheHelperNamesTheParent() {
    let form = StudentFormStore(mode: .new, classes: [], schools: [], schoolCounts: [:], today: today, defaultLanguage: .kannada)
    form.parentName = "Neha Sharma"
    #expect(form.messageLanguage == .kannada)
    #expect(form.languageHelper == "Notes to Neha Sharma are written in this language, with English beside them for you.")
}

@Test func theFeeHelperSpeaksOfTheBatch() {
    let form = StudentFormStore(mode: .new, classes: FakeClassesRepository.seed, schools: [], schoolCounts: [:], today: today, defaultLanguage: .english)
    #expect(form.feeHelper == "Leave empty to use the batch fee once a batch is chosen.")
    form.select(classID: FakeClassesRepository.maths.id)
    form.feeText = "1,500"
    #expect(form.feeHelper == "The batch fee is ₹1,200. This student pays this amount instead.")
}

// RegisterStoreTests additions
@Test func addingAStudentWithASchoolAndClassCopiesTheBooks() async {
    let textbooks = FakeTextbooksRepository(textbooks: [FakeTextbooksRepository.mathsTen], chapters: [:], skills: [:])
    let store = await register(textbooks: textbooks)
    var draft = StudentDraft()
    draft.name = "Kavya Nair"; draft.classLevel = .ten; draft.schoolID = FakeSchoolsRepository.vidya.id
    let made = await store.addStudent(draft)
    #expect(textbooks.copyAllCalls == [made!.id])
    var without = StudentDraft(); without.name = "No School"; without.classLevel = .ten
    _ = await store.addStudent(without)
    #expect(textbooks.copyAllCalls.count == 1)
}

@Test func theListSortsByStatusFirst() async {
    let store = await register()
    #expect(store.sort == .status)
    #expect(store.visible.first?.name == "Hemanth Reddy")     // watch, the only one below on track
    #expect(store.visible.last?.trackStatus == .notKnown)
}

@Test func savingABoardOnAStudentSetsTheSchoolsWhenItHasNone() async {
    let schools = FakeSchoolsRepository(schools: [School(id: FakeSchoolsRepository.vidya.id, name: "Vidya Niketan", board: nil)])
    let store = await register(schools: schools)
    var draft = StudentDraft(); draft.name = "K"; draft.classLevel = .nine; draft.board = .karnataka; draft.schoolID = FakeSchoolsRepository.vidya.id
    _ = await store.addStudent(draft)
    #expect(schools.schools.first?.board == .karnataka)
}
```

(`register(textbooks:schools:)` is the test file's helper, extended to take the two fakes; `FakeTextbooksRepository.mathsTen`
is the seed's textbook; `copyAllCalls` is recorded by the fake.)

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the form (the 10.2 order: Name; Class, a `PickerTile` with
  helper opening `WheelPopover` of `ClassLevel.allCases`; School, a `PickerTile` opening `SchoolSheet` (a `FittedSheet` of
  `ChoiceRow`s with "<n> students · CBSE" lines, `AddFieldRow` "Add a school" last, the footnote "One textbook photo per
  school and class serves everyone there. From class 8 the board is asked on the form."); Board, a `ChipRow` shown when
  `showsBoard`; Batch (V1's picker, renamed); Monthly fee (V1, the new helper); Parent's name and WhatsApp number (V1);
  Parent's message language, a `ChipRow`; Date of birth, Gender, Notes (V1)); the list (the status word leads the
  row's line; the sort menu gains Status first); the register's copy and board rules; AppShell passes `schools`,
  `textbooks`, `defaultLanguage` and writes `lastMessageLanguage` on save.

- [ ] **Step 4: Run the Students tests** → pass. `bun check` green. **Step 5: Pictures** for PR 6's states; the form's
  `showsFocus` for `student-new`; `student-new-class-picker` opens the wheel; `student-new-school` the sheet;
  `student-new-end` scrolled. Commit "Students: the list by status, New student and Edit student with class, school,
  board and language, the school sheet, the books copied at save"; open PR 6, merge on green.

### Task 14: DesignSystem: the page's parts (PR 7)

**Files:**
- Create: `DesignSystem/Components/TrackingCard.swift`, `RecordRows.swift` (`ChapterRow`, `SkillRow`, `StateMark`,
  `SubjectHead`), `TrendCard.swift`, `LadderRow.swift`, `ConsentRows.swift`
- Modify: `Tokens.swift` and `design-tokens.md` only for a value a board uses that is not yet named (the trend's 36 high
  bars, radius 3, 4 apart; the ladder's 6 pt bars; the consent buttons 44: check `components.md` and add what is missing
  as tokens in the same commit, D25)
- Test: `Tests/DesignSystemTests/TrendCardTests.swift` (the bar heights are a pure mapping), `StateMarkTests.swift`

**Interfaces:**
- Produces: `TrackingCard(status: TrackStatus, since: String?, reasons: String, next: String, action: (String, () -> Void)?)`
  (the compact hero of `components.md`; the quiet action is "Place <name>" or none); `ChapterRow(position: Int, name:
  String, line: String, open: Bool, action:)`; `SkillRow(name: String, line: String?, state: SkillState)`;
  `StateMark(state:)` with `StateMark.tone(_:) -> StatusTone?`, `.symbol(_:)`, `.word(_:)` ("Secure", "Practising",
  "Taught", "Revisit", "Not started"); `SubjectHead(title: String, line: String, action: (String, () -> Void)?)`;
  `TrendCard(title: String, percent: String, right: [Int], line: String)` with `TrendCard.fraction(right:) -> Double`
  and `.tone(right:) -> StatusTone` (3 `ok`, 2 `due`, else `overdue`); `LadderRow(area: Ladder.Area, states:
  [SkillState], line: String)`; `ConsentNotRecordedRow(child:line:ask:agreed:)`, `ConsentWaitingRow(title:line:askAgain:
  agreed:)`, `ConsentAgreedRow(title:line:change:)` (the three states' rows, the footnotes outside the card).

- [ ] **Step 1: The tests**

```swift
@Test func theTrendsBarsAndTones() {
    #expect(TrendCard.fraction(right: 3) == 1 && TrendCard.fraction(right: 0) == 0 && TrendCard.fraction(right: 2) == 2 / 3)
    #expect(TrendCard.tone(right: 3) == .ok && TrendCard.tone(right: 2) == .due && TrendCard.tone(right: 1) == .overdue)
}

@Test func theStateMarksWordsAndSymbols() {
    #expect(StateMark.word(.secure) == "Secure" && StateMark.symbol(.revisit) == "exclamationmark.circle" && StateMark.tone(.notStarted) == nil)
}
```

- [ ] **Step 2 to 5:** fail, build to `components.md` 10.2, `DesignSystemTests` pass, commit "Kit: the tracking card, the
  record's rows, the trend, the ladder, the consent rows".

### Task 15: Students: the student's page (PR 7)

**Files:**
- Modify: `Features/Students/StudentDetailStore.swift` (`init(id:register:attendance:messages:textbooks:record:schools:
  now:)`; the loads; the sections' lines), `StudentDetailView.swift` (the 10.2 order), `StudentDetailSections.swift`
  (the header's chips and lines)
- Create: `Features/Students/RecordSections.swift` (`ThisWeekSection`, `RecordSection`, `ChecksSection`,
  `HomeworkSection`, `SchoolSection`, `MessagesSection`), `Features/Students/StudentRecordStore.swift` (the record's
  reads and homework writes, kept by the detail store)
- Test: `Tests/StudentsTests/StudentDetailStoreTests.swift`, `StudentRecordStoreTests.swift`

**Interfaces:**
- Consumes: `TextbooksRepository.chapters/skills/addChapter`, `RecordRepository`, `MessageLogRepository.messages`,
  `SchoolsRepository.schools`, `TrackingRules`, `Ladder`, the Kit parts (Task 14).
- Produces (on `StudentDetailStore`): `classChip: String?` ("Class 10"), `batchChip: String?`, `schoolLine: String?`
  ("Vidya Niketan · CBSE"), `tracking: TrackingLines` (`status`, `since` ("since Fri 2 Oct"), `reasons` (the stored
  reasons joined by " · ", or the not-known sentence from `components.md` with the join day), `next`, `placeAction:
  Bool`), `thisWeek: [WeekRow]` (one per session of the week the student was in: the day, "Came · 2 of 3 right ·
  homework given" / "Absent"), `subjects: [SubjectCard]` (per subject: the head's line "14 chapters from the book · 3
  taught", the chapter rows with "4 of 4 secure"-style lines, each chapter's skills with the state and the "checked Mon
  5 Oct" line; a ladder subject renders `LadderRow`s; a subject with no book the empty row with Add the book),
  `missingBookLine: String?` (decision 11), `checks: ChecksLines?` (the twelve sessions' right counts, the percent, the
  line "<n> of <m> right over three weeks · <k> sessions"), `homework: [HomeworkLine]`, `messages: [MessageLine]`
  ("Absence alert · Fri 2 Oct · Hindi"), `schoolLineEmpty: String` ("Nothing from <name>'s school yet"); `openChapter(_:)`,
  `setHomework(_ id:, _ status:) async`, `addChapter(subject:name:skills:) async -> Bool`.
- Consent (Task 16) hangs off the same store.

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct StudentDetailV2Tests {
    func detail(_ id: UUID, record: FakeRecordRepository = FakeRecordRepository(), textbooks: FakeTextbooksRepository = .seeded()) async -> StudentDetailStore {
        let store = StudentDetailStore(id: id, register: await register(), attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), messages: FakeMessageLogRepository(), textbooks: textbooks, record: record, schools: FakeSchoolsRepository(), now: { FakeClock.oct7at1635 })
        await store.load()
        return store
    }

    @Test func hemanthsHeaderAndTrackingCard() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        #expect(store.classChip == "Class 10" && store.batchChip == "Class 10 Maths" && store.schoolLine == "Vidya Niketan · CBSE")
        #expect(store.tracking.status == .watch && store.tracking.since == "since Fri 2 Oct")
        #expect(store.tracking.reasons == "5 of 9 checks right over three weeks · Absent 2 times in four weeks")
        #expect(store.tracking.next.hasPrefix("Teach ") && !store.tracking.placeAction)
    }

    @Test func theRecordListsTheBooksChaptersWithTheirStates() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        let maths = store.subjects.first { $0.title == "Mathematics" }!
        #expect(maths.line == "14 chapters from the book · 3 taught")
        #expect(maths.chapters[0].line == "4 of 4 secure" && maths.chapters[3].line == "Not started")
        store.openChapter(maths.chapters[1].id)
        #expect(store.subjects[0].chapters[1].open && store.subjects[0].chapters[1].skills.count == 3)
    }

    @Test func riyaIsNotKnownYetWithNoBookAndTheRecordSaysWhatWillTell() async {
        let store = await detail(FakeStudentsRepository.riya)
        #expect(store.tracking.status == .notKnown && store.tracking.placeAction == false)   // no chapters yet: nothing to place on
        #expect(store.tracking.reasons == "Riya joined on Mon 5 Oct. Her first week's checks show where she stands; a placement shows it sooner.")
        #expect(store.subjects.isEmpty && store.missingBookLine == nil)   // she has a class and a school: Add a textbook shows
        #expect(store.checks == nil && store.thisWeek.isEmpty)
    }

    @Test func aV1StudentWithoutAClassIsToldWhatToSet() async {
        let bir = FakeStudentsRepository.seed.first { $0.name == "Bir Bikram Singh" }!.id
        let store = await detail(bir)
        #expect(store.classChip == nil && store.schoolLine == nil)
        #expect(store.missingBookLine == "Set Bir's class and school from Edit to add a book.")
    }

    @Test func sahilsLadder() async {
        let store = await detail(FakeStudentsRepository.sahil)
        let reading = store.subjects.first { $0.title == "Reading" }!
        #expect(reading.ladder?.states.prefix(2).allSatisfy { $0 == .secure } == true && reading.ladder?.line == "Sentences · since Mon 28 Sep")
    }

    @Test func theChecksTrendAndHomeworkRows() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        #expect(store.checks?.right == [3, 2, 3, 1, 2, 3, 2, 2, 3, 1, 2, 3] && store.checks?.percent == "75%")
        #expect(store.homework.first?.status == .given)
        await store.setHomework(store.homework[0].id, .notDone)
        #expect(store.homework.first?.status == .notDone)
    }

    @Test func theMessagesSectionNamesKindDayAndLanguage() async {
        let store = await detail(FakeStudentsRepository.hemanth)
        #expect(store.messages.first?.text == "Absence alert · Fri 2 Oct · Hindi")
    }
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the store's loads (chapters, skills, the student's checks and
  homework since 28 days, the messages, the week's sessions, in one `async let` group as the V1 `load()` does; a failed
  read leaves its section with the in-place failure, U33) and the view in the 10.2 order: the nav row, the header,
  `TrackingCard`, `ParentCard`, This week, Record (a `Card` per subject: `SubjectHead`, `ChapterRow`s, the open
  chapter's `SkillRow`s; a ladder subject's three `LadderRow`s; Add the book and Add a textbook push `Route.textbook(id,
  subject?)`, Task 18), Checks (`TrendCard`), Homework (rows with the three chips, each a button), School (the empty row),
  Messages, Consent (Task 16), Fees, Attendance, Notes, the buttons. `student-record` and `student-end` scroll to their
  sections as `today-adding-task` does.

- [ ] **Step 4: Run the Students tests** → pass. **Step 5: commit** "Students: the student's page with tracking, this
  week, the record, checks, homework, school and messages".

### Task 16: Students: consent (PR 7)

**Files:**
- Create: `Features/Students/ConsentStore.swift`, `ConsentSection.swift`, `ConsentAskSheet.swift`, `ConsentRecordSheet.swift`
- Modify: `StudentDetailView.swift` (the section and its two sheets), `StudentDetailStore.swift` (`consent: ConsentStore`),
  `AppShell/RootView+Students.swift` (`StudentDetailBoardState` gains `.consentAsk`, `.consentRecord`), `RootView+LaunchStates.swift`
- Test: `Tests/StudentsTests/ConsentStoreTests.swift`

**Interfaces:**
- Produces: `ConsentStore(student: Student, register: RegisterStore, messages: any MessageLogRepository, tutorName:
  centreName: now:)`: `state: State` (`.notRecorded`, `.waiting(askedOn: Day)`, `.agreed(ConsentRecord)`), `title`,
  `line`, `footnote` (the 10.2 texts), `message: String` (`ConsentMessage.text`), `askFootnote`, `whatsAppURL: URL?`,
  `openWhatsApp() async -> URL?` (logs `consent` first; offline the `OfflineRefusal` words in `message`),
  `recordSheet: RecordSheet` (`how: ConsentMethod = .inPerson`, `agreedOn: Day = today`, `digits` prefilled from the
  parent's number, `canRecord`), `record() async -> Bool` (`register.setConsent(id, ConsentRecord)`), `remove() async ->
  Bool` (`setConsent(id, nil)`), `load()` (the asks from `messages`).

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct ConsentStoreTests {
    func store(_ student: Student, logs: [MessageEntry] = []) async -> (ConsentStore, RegisterStore) {
        let register = await register()
        let messages = FakeMessageLogRepository(entries: logs)
        let store = ConsentStore(student: student, register: register, messages: messages, tutorName: "Meera Nair", centreName: "Bright Minds Tuition", now: { FakeClock.oct7at1635 })
        await store.load()
        return (store, register)
    }

    @Test func notRecordedThenWaitingAfterAnAsk() async throws {
        let riya = FakeStudentsRepository.seed.first { $0.name == "Riya Sharma" }!
        let (store, _) = await store(riya)
        #expect(store.state == .notRecorded && store.title == "Not recorded yet")
        #expect(store.line == "Before Riya's own work, marks or name go to the AI service, her parent agrees once: in person, on a call or on WhatsApp. Note it here.")
        let url = await store.openWhatsApp()
        #expect(url?.absoluteString.hasPrefix("https://wa.me/919811122233?text=") == true)
        #expect(store.state == .waiting(askedOn: Day(year: 2026, month: 10, day: 7)!) && store.title == "Asked Neha Sharma on Wed 7 Oct")
    }

    @Test func recordThenRemove() async {
        let riya = FakeStudentsRepository.seed.first { $0.name == "Riya Sharma" }!
        let (store, register) = await store(riya)
        store.recordSheet.how = .call
        #expect(store.recordSheet.digits == "9811122233" && store.recordSheet.canRecord)
        #expect(await store.record())
        #expect(register.student(riya.id)?.consent?.how == .call)
        #expect(store.title == "Neha Sharma agreed" && store.line == "Wed 7 Oct · +91 98111 22233 · on a call")
        #expect(await store.remove())
        #expect(register.student(riya.id)?.consent == nil && store.state == .notRecorded)
    }

    @Test func waitingShowsAfterAnAskUntilRecorded() async {
        let riya = FakeStudentsRepository.seed.first { $0.name == "Riya Sharma" }!
        let asked = MessageEntry(id: UUID(), kind: .consent, openedAt: FakeClock.oct7at1635 - 2 * 86400, language: nil)
        let (store, _) = await store(riya, logs: [asked])
        #expect(store.state == .waiting(askedOn: Day(year: 2026, month: 10, day: 5)!))
        #expect(store.line == "Waiting for her reply. Riya's own notes and marking wait too; sheets and sets do not.")
        _ = await store.record()
        #expect(store.state != .notRecorded && store.title == "Neha Sharma agreed")
    }

    @Test func theMessageSpeaksOfTheChildAndSignsOff() async {
        let riya = FakeStudentsRepository.seed.first { $0.name == "Riya Sharma" }!
        let (store, _) = await store(riya)
        #expect(store.message.hasPrefix("Hello Neha, I use Tutor Central to plan Riya's classes"))
        #expect(store.message.hasSuffix("Meera Nair\nBright Minds Tuition"))
    }
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the store and the three views: the section is one `Card` row
  in the state's form with the footnote under the card; the ask sheet is the Phase 4 `MessageSheet` with the consent
  message, the footnote and Open WhatsApp (the text copied too, as the fee reminder does); the record sheet is a
  `FittedSheet` with the title "<parent> agreed", the line "<child>'s parent", the How `ChipRow`, Agreed on (a `PickerTile`
  opening the calendar popover, today or earlier), the `PhoneWell`, the footnote, Record it, and "Remove" as a quiet
  destructive row when a record exists (decision 13). `RegisterStore.setConsent(_:_:)` updates the student in place
  (optimistic as `setArchived`).

- [ ] **Step 4: Run the Students tests** → pass; `ErrorWordsTests` passes. `bun check` green. **Step 5: Pictures** for
  PR 7's states (`student-consent-ask` opens the ask sheet over Riya's page; `-record` the record sheet; `-waiting` Riya
  with an ask logged in the fixtures). Commit "Students: consent recorded per student, asked on WhatsApp or noted
  straight away"; open PR 7, merge on green.

### Task 17: DesignSystem: the check row (PR 8 and 9 share it; built here)

**Files:**
- Create: `DesignSystem/Components/CheckRow.swift`
- Modify: `Tokens.swift` and `design-tokens.md` for the pair's 150 × 34 on a 40 track (`checkPairWidth`, `checkSegment`,
  `checkTrack`) if not yet named; `okInk` and `overdueInk` exist from Phase 4
- Test: `Tests/DesignSystemTests/CheckRowTests.swift`

**Interfaces:**
- Produces: `CheckRow(skill: String, question: String, answer: String, tap: Binding<Bool?>)` (nil untapped, true Right,
  false Wrong; the `well` track, two segments, `ok` fill with `okInk` on Right, `overdue` with `overdueInk` on Wrong;
  tapping the lit segment again clears it); `CheckRow.toggled(_ current: Bool?, tapping right: Bool) -> Bool?`
  (`nonisolated static`).

- [ ] **Step 1: The test**

```swift
@Test func tappingASegmentSetsItAndTappingItAgainClears() {
    #expect(CheckRow.toggled(nil, tapping: true) == true)
    #expect(CheckRow.toggled(true, tapping: true) == nil)
    #expect(CheckRow.toggled(true, tapping: false) == false)
}
```

- [ ] **Steps 2 to 5:** fail, build to `components.md` "Check row", `DesignSystemTests` pass, commit "Kit: the check row
  with Right and Wrong".

### Task 18: Students: the textbook's contents page (PR 8)

**Files:**
- Create: `Features/Students/TextbookStore.swift`, `TextbookIntroView.swift`, `SubjectSheet.swift`,
  `TextbookChaptersView.swift`, `ChapterSheet.swift`
- Modify: `AppShell/TabsState.swift` (`Route.textbook(student: UUID, subject: String?)`), `TabsView.swift`,
  `RootView+Students.swift` (builds the store in `@State`; the camera and Photos as Scan register does: `CameraAccess`,
  `DocumentCameraView(maxPages: 1)`, `PhotosPicker`, `PhotoReducer`), `RootView+LaunchStates.swift`, `LaunchState.swift`,
  `Fixtures.swift` (the AI fake's delay for `textbook-reading`), `StudentDetailView.swift` (Add the book, Add a
  textbook, Add a chapter open the route or the chapter sheet)
- Test: `Tests/StudentsTests/TextbookStoreTests.swift`

**Interfaces:**
- Consumes: `AIRepository.parseTextbook`, `TextbooksRepository.save`, `copyToClass`, `SchoolsRepository`, the register.
- Produces: `TextbookStore(student: Student, school: School, register: any Register, ai: any AIRepository, textbooks:
  any TextbooksRepository, centre: UUID, online:)`: `phase: Phase` (`.intro`, `.reading(thumbnail: UIImage)`,
  `.chapters`, `.keeping`), `subject: String?`, `subjects: [String]` (the student's, then `Subject.common`, no repeats),
  `subjectHelper` ("Vidya Niketan, class 5. Riya's classmates there get the same chapters."), `classmatesCount: Int`,
  `canRead: Bool` (a subject chosen), `read(_ photo: ImageUpload, thumbnail: UIImage) async`, `chapters:
  [TextbookChapter]` (editable: `rename`, `setSkills`, `remove`, `add`, positions renumbered), `chaptersTitle` ("5
  chapters read"), `keepTitle` ("Keep 5 chapters"), `keep() async -> Bool` (`save` then `copyToClass`, the count
  answered; `phase = .keeping` meanwhile), `message: String?` (the failures in the API's words through `APIFailure.message`,
  offline `OfflineRefusal.words(for: .textbook)`), `cancel()` (a reading in flight is cancelled and its late answer
  dropped, as `CheckStore` does). Nothing is written before Keep; the photo lives in the request only.

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct TextbookStoreTests {
    func store(ai: FakeAIRepository = FakeAIRepository(), textbooks: FakeTextbooksRepository = FakeTextbooksRepository(), online: Bool = true) async -> TextbookStore {
        let register = await register()
        let riya = register.students.first { $0.name == "Riya Sharma" }!
        textbooks.students = register.students
        return TextbookStore(student: riya, school: FakeSchoolsRepository.vidya, register: register, ai: ai, textbooks: textbooks, centre: FakeSchoolsRepository.centre, online: { online })
    }
    let page = ImageUpload(data: Data([0xFF, 0xD8, 0xFF]), mediaType: "image/jpeg")

    @Test func theIntroNamesTheSchoolAndClassAndNeedsASubject() async {
        let store = await store()
        #expect(store.phase == .intro && !store.canRead)
        #expect(store.subjects.prefix(2) == ["Mathematics", "Science"])
        store.subject = "Mathematics"
        #expect(store.canRead && store.subjectHelper == "Vidya Niketan, class 5. Riya's classmates there get the same chapters.")
    }

    @Test func readingShowsTheChaptersAndKeepSavesOnceAndCopiesToTheClass() async {
        let ai = FakeAIRepository(), textbooks = FakeTextbooksRepository()
        let store = await store(ai: ai, textbooks: textbooks)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: UIImage())
        #expect(store.phase == .chapters && store.chapters.count == 5 && store.chaptersTitle == "5 chapters read")
        #expect(textbooks.textbooks.isEmpty)   // nothing written before Keep
        store.rename(at: 0, to: "The Fish Tale (long)")
        store.remove(at: 4)
        #expect(store.chapters.count == 4 && store.keepTitle == "Keep 4 chapters" && store.chapters.last?.position == 4)
        #expect(await store.keep())
        #expect(textbooks.textbooks.count == 1 && textbooks.textbooks[0].title == "Math-Magic 5" && textbooks.textbooks[0].chapters.count == 4)
        #expect(textbooks.copyToClassCalls == [textbooks.textbooks[0].id])
    }

    @Test func nothingIsKeptOfThePhoto() async {
        let ai = FakeAIRepository(), textbooks = FakeTextbooksRepository()
        let store = await store(ai: ai, textbooks: textbooks)
        store.subject = "Science"
        await store.read(page, thumbnail: UIImage())
        _ = await store.keep()
        #expect(ai.textbooks.count == 1)                       // sent once
        #expect(textbooks.textbooks[0].photoPath == nil)      // never a path (decision: "We keep no copy")
        #expect(Mirror(reflecting: store).children.allSatisfy { !($0.value is ImageUpload) })
    }

    @Test func aFailedReadSaysSoAndKeepsTheIntroAndOfflineIsRefusedBeforeTheCall() async {
        let ai = FakeAIRepository()
        ai.script = .failure(.refused("Couldn't read the chapters from this photo. Try a flatter, brighter one."))
        let store = await store(ai: ai)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: UIImage())
        #expect(store.phase == .intro && store.message == "Couldn't read the chapters from this photo. Try a flatter, brighter one.")
        let offline = await self.store(ai: ai, online: false)
        offline.subject = "Mathematics"
        await offline.read(page, thumbnail: UIImage())
        #expect(offline.message == OfflineRefusal.words(for: .textbook) && ai.textbooks.count == 1)
    }

    @Test func aSecondCaptureReplacesTheBookAndTheCopyKeepsProgress() async {
        let textbooks = FakeTextbooksRepository()
        let store = await store(textbooks: textbooks)
        store.subject = "Mathematics"
        await store.read(page, thumbnail: UIImage())
        _ = await store.keep()
        let riya = FakeStudentsRepository.riya
        let first = try? await textbooks.skills(student: riya).first
        try? await textbooks.setState(skillID: first!.id, .secure)
        let again = await self.store(textbooks: textbooks)
        again.subject = "Mathematics"
        await again.read(page, thumbnail: UIImage())
        _ = await again.keep()
        #expect(textbooks.textbooks.count == 1)
        #expect(try! await textbooks.skills(student: riya).first?.state == .secure)
    }
}
```

(`Textbook` gains no `photoPath` in Swift; the third test's `photoPath` line is written against the fake's recorded
`values`, `textbooks.lastWrittenValues["photo_path"] == nil`, when the plan is executed: the fake records what
`SupabaseTextbooksRepository.values` would write.) The fake's `copyChapters` keeps a matching skill's state by position,
as 0016 does, for the last test.

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the store (the read in a task the store owns, cancelled by
  Back; `TextbookChapter`s numbered by order; the title from the reading or "<Subject>, class <n>") and the screens to
  the 10.2 boards and texts: the intro (`IntroHero` "Photograph the contents page", the subject `PickerTile` with its
  helper, the `NoticesCard` of three notices, the AI line, Take a photo and Choose from Photos as Scan's intro); reading
  (the intro dimmed under `CreatingCard(title: "Reading the contents page", line: "Usually under a minute. Mathematics
  · Vidya Niketan · class 5", thumbnail:)`); the chapters (a `Card` of `ChapterRow`s with "<k> skills read", Add a chapter,
  the footer "Keep 5 chapters" with the footnote); the chapter sheet (`FittedSheet`: "Chapter 3", the name field,
  "Skills, 4", the line, each skill a row with remove, `AddFieldRow` "Add a skill", Remove this chapter). Keep pops to
  the student's page, which reads its chapters again. A student without a class or school never reaches the route
  (decision 11).

- [ ] **Step 4: Run the Students tests** → pass. `bun check` green. **Step 5: Pictures** for `textbook-intro`,
  `-reading` (the fake's delay), `-chapters`, `-chapter-edit`. Commit "Students: a textbook's contents page read into
  chapters and skills, kept once per school, class and subject"; open PR 8, merge on green.

### Task 19: Students: the placement (PR 9)

**Files:**
- Create: `Features/Students/PlacementStore.swift`, `PlacementView.swift`
- Modify: `AppShell/TabsState.swift` (`Route.placement(UUID)`), `TabsView.swift`, `RootView+Students.swift`,
  `RootView+LaunchStates.swift`, `LaunchState.swift` (`placement`), `Fixtures.swift`, `StudentDetailView.swift` (Place
  <name> on the tracking card when `placeAction`), `StudentDetailStore.swift` (`placeAction` true when not known yet and
  the student has chapters)
- Test: `Tests/StudentsTests/PlacementStoreTests.swift`

**Interfaces:**
- Consumes: `AIRepository.makePlacement`, `TextbooksRepository.chapters/skills`, `RecordRepository.recordPlacement`,
  `SkillProgress.placementChanges`, `TrackingRules`, `CheckRow`.
- Produces: `PlacementStore(student: Student, register: any Register, ai: any AIRepository, textbooks: any
  TextbooksRepository, record: any RecordRepository, attendance: any AttendanceRepository, centre: UUID, now:, online:)`:
  `load() async` (the chapters and skills; one `makePlacement` per subject in parallel with the chapter names, a
  ladder subject's with its steps; a failed subject shows the in-place failure with Try again), `subjects:
  [PlacementSubject]` (`title`, `countLine` "2 of 3 right", `rows: [PlacementRow]` with `chapter`, `skill` (the chapter's
  first skill, or the step), `question`, `answer`, `tap: Bool?`), `footnote` (the 10.2 text), `doneFootnote`, `canFinish:
  Bool` (at least one tap), `finish() async -> Bool` (`PlacementRecord` of the tapped rows as placement checks, the
  `placementChanges`, the `Tracking` from `TrackingRules` with the new checks; `recordPlacement`; the register's student
  updated with the status), `message: String?`.
- Also used inside the close (Task 21) as `PlacementRows` for one student: the same store without `finish`, its rows
  folded into the close's checks and states.

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct PlacementStoreTests {
    func store(_ id: UUID = FakeStudentsRepository.riya, ai: FakeAIRepository = FakeAIRepository(), record: FakeRecordRepository = FakeRecordRepository(), textbooks: FakeTextbooksRepository = .seeded()) async -> PlacementStore {
        let register = await register()
        let store = PlacementStore(student: register.student(id)!, register: register, ai: ai, textbooks: textbooks, record: record, attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), centre: FakeSchoolsRepository.centre, now: { FakeClock.oct7at1635 }, online: { true })
        await store.load()
        return store
    }

    @Test func oneRowPerChapterInTheBooksOrderWithTheChaptersFirstSkill() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai, textbooks: .seededWithRiyasMaths())
        #expect(store.subjects.count == 1 && store.subjects[0].rows.count == 5)
        #expect(ai.placementCalls == [["The Fish Tale", "Shapes and Angles", "How Many Squares?", "Parts and Wholes", "Does it Look the Same?"]])
        #expect(store.subjects[0].rows[0].skill == "Compare lengths and weights" && store.subjects[0].countLine == "0 of 5 right")
        #expect(!store.canFinish)
    }

    @Test func doneKeepsTheTapsAndStartsTheChaptersFromTheFirstWrong() async {
        let record = FakeRecordRepository()
        let store = await store(record: record, textbooks: .seededWithRiyasMaths())
        store.subjects[0].rows[0].tap = true
        store.subjects[0].rows[1].tap = true
        store.subjects[0].rows[2].tap = false
        store.subjects[0].rows[4].tap = true     // after the first wrong: kept as a check, no state change
        #expect(store.subjects[0].countLine == "3 of 5 right" && store.canFinish)
        #expect(await store.finish())
        let placement = record.placements[0]
        #expect(placement.checks.count == 4 && placement.checks.allSatisfy(\.isPlacement))
        let secured = Set(placement.states.map(\.skillID))
        let skills = try! await FakeTextbooksRepository.seededWithRiyasMaths().skills(student: FakeStudentsRepository.riya)
        #expect(secured == Set(skills.filter { [1, 2].contains(chapterPosition($0, in: store)) }.map(\.id)))
        #expect(placement.track?.status == .onTrack)
    }

    @Test func aLadderStudentIsPlacedOnStepsAndChapters() async {
        let ai = FakeAIRepository()
        let store = await store(FakeStudentsRepository.sahil, ai: ai)
        #expect(store.subjects.map(\.title) == ["Reading", "Writing", "Numbers"])
        #expect(ai.placementCalls.contains(["Letters", "Words", "Sentences", "Paragraph", "Story"]))
        #expect(store.subjects[0].rows[2].skill == "Sentences")
    }

    @Test func aFailedSubjectSaysSoInPlaceAndTheOthersStand() async {
        let ai = FakeAIRepository()
        ai.scriptBySubject = ["Writing": .failure(.service)]
        let store = await store(FakeStudentsRepository.sahil, ai: ai)
        #expect(store.subjects[1].failure == "The AI service didn't answer. Try again." && store.subjects[0].rows.count == 5)
    }
}
```

(`chapterPosition(_:in:)` is a test helper reading the chapter of a skill from the store's loaded chapters;
`FakeAIRepository.scriptBySubject` scripts one subject's answer; `FakeTextbooksRepository.seededWithRiyasMaths()` is the
seed plus Riya's five-chapter maths book copied.)

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the store and the pushed screen to P10-Placement: `BackRow`,
  the title "Placement", the footnote, per subject a `Card` with the title and count, the `CheckRow`s, Done in the
  footer with its footnote; Done pops to the page, whose tracking card reads the new status.

- [ ] **Step 4: Run** → pass; `bun check` green. **Step 5: Pictures** for `placement` (Riya, the fake's answers). Commit
  "Students: the placement, a few questions per subject, tapped right or wrong"; open PR 9, merge on green.

### Task 20: DesignSystem and Today: the batch hero (PR 10)

**Files:**
- Create: `DesignSystem/Components/BatchHero.swift`
- Modify: `Features/Today/TodayStore.swift` (`Hero` gains `kind: Kind` (`.start`, `.laterToday`, `.tomorrow`, `.onDay`,
  `.closed(ClosedLines)`), the closed hero from the day's closed session), `TodaySections.swift` (`BatchHeroCard` takes
  the place of `HeroCard`), `TodayView.swift` (`startClass` and `openClass` actions), `TodayActions` (`openClose:
  (UUID) -> Void` replaces `openMarkAttendance`), `AppShell/RootView+Today.swift`
- Test: `Tests/TodayTests/TodayStoreTests.swift`

**Interfaces:**
- Produces: `BatchHero(eyebrow: String, accent: Bool, title: String, titleMark: Bool, line: String, action:
  BatchHero.Action?)` with `Action` `.primary("Start class", "play", run)` or `.secondary("Open the class", run)` (the
  10.3 "Batch hero": the Kit's next-class hero; closed, the title carries `checkmark.circle` in `ok`).
  `TodayStore.hero`: while the next batch is `.soon` or `.running` and today's session for it has no `closedAt`,
  eyebrow "Next batch · in 25 min" / "Now · until 18:30", title the batch, line "17:00–18:30 · 5 students", Start
  class; once today's session for the batch is closed, eyebrow "<batch> · closed at 18:32", title "4 of 5 came" with
  the mark, line "8 of 12 checks right · homework given to 4 · Nikhil absent" (checks and homework counts from the
  store's `CloseSummary` read with the session), Open the class; later today, tomorrow and on a day as V1 with "Next
  batch"; no batch today: "No batch today", "Next: Evening batch on Monday", the line of `components.md`.
  `AttendanceSession` gains `closedAt: Date?` (Data's `SessionRow` decodes `closed_at`; the fake's `close` sets it);
  `AttendanceRepository.sessions` selects it. The closed hero's counts come from `RecordRepository.checks(…, since:
  today)` and `homework(…)` for the session's students, read by `TodayStore.load()` when a closed session exists.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func theHeroSaysStartClassWhileTheBatchIsSoonOrRunning() async {
    let store = await today(clock: FakeClock.oct7at1635)       // Class 10 Maths at 17:00
    #expect(store.hero?.kind == .start && store.hero?.eyebrow == "Next batch · in 25 min" && store.hero?.title == "Class 10 Maths")
    #expect(store.hero?.line == "17:00–18:00 · 6 students")
}

@Test func afterTheCloseTheHeroReadsWhatHappened() async {
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithTodayClosed)
    let record = FakeRecordRepository(checks: FakeRecordRepository.todaysChecks, homework: FakeRecordRepository.todaysHomework)
    let store = await today(clock: FakeClock.oct7at1840, attendance: attendance, record: record)
    #expect(store.hero?.eyebrow == "Class 10 Maths · closed at 18:32" && store.hero?.title == "5 of 6 came")
    #expect(store.hero?.line == "8 of 12 checks right · homework given to 5 · Hemanth absent")
    #expect(store.hero?.kind == .closed)
}

@Test func aDayWithNoBatchNamesTheNextOne() async {
    let store = await today(clock: FakeClock.sat10at0930)
    #expect(store.hero?.eyebrow == "No batch today" && store.hero?.title == "Next: Class 10 Maths on Monday")
    #expect(store.hero?.line == "17:00–18:00 · 6 students · its plan is made when you open the app on Monday")
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the part and the store's lines; `RootView+Today` passes
  `openClose: { shell.tabs.push(.close($0)) }`.

- [ ] **Step 4: Run `TodayTests`** → pass. **Step 5: Commit** "Today: the batch hero with Start class, and what happened
  after the close".

### Task 21: Today: the close (PR 10)

**Files:**
- Create: `Features/Today/CloseStore.swift`, `CloseStore+Checks.swift`, `CloseView.swift`, `CloseSections.swift`
- Modify: `AppShell/TabsState.swift` (`Route.close(UUID)`), `TabsView.swift`, `RootView+Close.swift` (new: builds the
  store in `@State` with the register, textbooks, record, attendance, AI, the queue and `online`), `RootView+LaunchStates.swift`,
  `LaunchState.swift` (`close`, `closeScrolled`, `closePlacement`, `todayAfterClose`), `Fixtures.swift` and
  `Fixtures+Record.swift` (the Evening batch and its five students' records), `Data/Classes/FakeClassesRepository.swift`
  (`evening`)
- Test: `Tests/TodayTests/CloseStoreTests.swift`

**Interfaces:**
- Consumes: `Register`, `TextbooksRepository.chapters/skills`, `RecordRepository.checks/homework`,
  `AttendanceRepository.sessions/close`, `AIRepository.makeChecks/makePlacement`, `SpacedQueue`, `SkillProgress`,
  `TrackingRules`, `CheckRow`, `PlacementStore`'s rows (Task 19), `ChangeQueueing` (Task 22).
- Produces: `CloseStore(classID: UUID, workspace: Workspace, register: any Register, textbooks:, record:, attendance:,
  ai:, now:, calendar:)`: `title` "Close the class", `batchLine` ("Evening batch · Wed 7 Oct · 17:00–18:30 · 5
  students"), `footnote` (the 10.3 text), `students: [CloseStudent]` (per active member by name: `name`, `present:
  Bool` (true), `checks: Checks` (`.loading`, `.rows([CheckLine])` with `skill`, `skillID`, `question`, `answer`, `tap:
  Bool?`, `.placement(PlacementStore)`, `.none` (no chapters), `.failed(String)`), `homeworkGiven: Bool` (true),
  `catchUp: String?` ("Catch up · missed Mon and Fri" when absent at the last two sessions of the batch)),
  `load() async` (the month's sessions for the catch-up lines and a close already made today (reopening keeps its
  taps as Attendance's reopen does: `saved`), each student's skills and chapters, then the checks in parallel per
  student: `SpacedQueue.pick` → `makeChecks` with the skills' names; empty → the placement rows or `.none`),
  `retryChecks(for:)`, `toggle(_:)` (present), `setHomework(_:given:)`, `tap(_ student:, _ row:, right:)`,
  `summary` ("2 of 5 came, 4 checks right" for the Done footnote), `done() async -> Bool` (builds the `SessionClose`:
  the marks; the tapped checks (absent students' taps dropped); homework for the present students with the switch on;
  the states from `SkillProgress.after` with the previous check on the skill from the loaded checks; the `Tracking` per
  present student from `TrackingRules.evaluate` with the day's checks added and absences from the month's sessions; the
  absent students' tracking is worked out too (an absence counts); `attendance.close(…)`; the register's students
  updated with their status; pops), `message: String?`, `phase` (`.open`, `.closing`, `.closed(at:)`, `.savedHere(at:)`).

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct CloseStoreTests {
    func store(ai: FakeAIRepository = FakeAIRepository(), attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), record: FakeRecordRepository = FakeRecordRepository(), textbooks: FakeTextbooksRepository = .seeded()) async -> CloseStore {
        let register = await register(evening: true)
        let store = CloseStore(classID: FakeClassesRepository.evening.id, workspace: FakeCentreRepository.meeraWorkspace, register: register, textbooks: textbooks, record: record, attendance: attendance, ai: ai, now: { FakeClock.oct7at1705 }, calendar: DayHeading.india)
        await store.load()
        return store
    }

    @Test func everyoneStartsPresentWithHomeworkGivenAndThreeChecksFromTheQueue() async {
        let ai = FakeAIRepository()
        let store = await store(ai: ai)
        #expect(store.title == "Close the class" && store.batchLine == "Evening batch · Wed 7 Oct · 17:00–18:30 · 5 students")
        #expect(store.students.count == 5 && store.students.allSatisfy { $0.present && $0.homeworkGiven })
        let dev = store.students.first { $0.name == "Dev Kumar" }!
        guard case let .rows(rows) = dev.checks else { return Issue.record("no rows") }
        #expect(rows.count == 3 && ai.checkCalls.contains(rows.map(\.skill)))
    }

    @Test func aStudentWithNoChecksYetGetsThePlacementAndOneWithNoChaptersHasAttendanceAndHomeworkOnly() async {
        let store = await store()
        let riya = store.students.first { $0.name == "Riya Sharma" }!
        if case .placement = riya.checks {} else { Issue.record("Riya should be placed") }
        let noBook = store.students.first { $0.name == "Nikhil Das" }!     // class 8, no book in the fixtures
        #expect(noBook.checks == .none && noBook.homeworkGiven)
    }

    @Test func doneWithNothingTappedClosesWithAttendanceAlone() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await store(attendance: attendance)
        #expect(await store.done())
        let close = attendance.closes[0]
        #expect(close.checks.isEmpty && close.states.isEmpty && close.homework.count == 5 && close.marks.values.allSatisfy { $0 == .present })
        #expect(close.track.count == 5)   // every student's status worked out again
    }

    @Test func tapsBecomeChecksStatesAndStatusesAndAnAbsentStudentsTapsAreDropped() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
        let store = await store(attendance: attendance)
        let dev = store.students.firstIndex { $0.name == "Dev Kumar" }!
        store.tap(dev, 0, right: true); store.tap(dev, 1, right: false)
        let meher = store.students.firstIndex { $0.name == "Meher Shah" }!
        store.tap(meher, 0, right: true)
        store.toggle(meher)                                   // absent: her tap is dropped
        store.setHomework(dev, given: false)
        #expect(store.summary == "4 of 5 came, 1 check right")
        #expect(await store.done())
        let close = attendance.closes[0]
        #expect(close.checks.count == 2 && close.checks.allSatisfy { $0.studentID == store.students[dev].id })
        #expect(close.homework.count == 3)                    // four present, Dev's switch off
        #expect(close.states.contains { $0.state == .practising })   // Dev's taught skill, right once
        #expect(close.marks[store.students[meher].id] == .absent)
    }

    @Test func aFailedCheckCallShowsInPlaceAndDoneStillWorks() async {
        let ai = FakeAIRepository()
        ai.scriptBySubject = ["Science": .failure(.service)]
        let store = await store(ai: ai)
        let dev = store.students.first { $0.name == "Dev Kumar" }!
        #expect(dev.checks == .failed("The AI service didn't answer. Try again."))
        #expect(await store.done())
    }

    @Test func reopeningTodaysCloseShowsItsTaps() async {
        let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithTodayClosed)
        let record = FakeRecordRepository(checks: FakeRecordRepository.todaysChecks, homework: FakeRecordRepository.todaysHomework)
        let store = await store(attendance: attendance, record: record)
        #expect(store.phase == .closed(at: FakeClock.oct7at1832))
        let hemanth = store.students.first { $0.name == "Hemanth Reddy" }
        #expect(hemanth == nil)   // the Evening batch; the seed's close is Class 10 Maths: a separate test uses that batch
    }

    @Test func theCatchUpLineNamesTheMissedDays() async {
        let store = await store(attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithNikhilAbsentTwice))
        #expect(store.students.first { $0.name == "Nikhil Das" }?.catchUp == "Catch up · missed Mon and Fri")
    }
}
```

(The reopening test is written against `FakeClassesRepository.maths` with its closed seed instead, in the same file; the
line above is replaced by that test when executed: the plan keeps the intent, the executor the batch.)

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** the store and the screen to P10-Close, -Scrolled, -Placement
  and the 10.3 texts: `BackRow` with the quiet "Plan" leading back to Today, the title, the batch line, the footnote,
  "Students" with a "Close student card" per student (the head with the attendance pill, the eyebrow "Check · 3
  questions", three `CheckRow`s, the rule, the homework `Switch` row "Homework given"; absent folds to one line
  "Marked absent. The checks and homework wait; a catch-up line joins the next plan."; a placed student shows
  "Placement · a few questions per subject" and the placement's rows; `.none` shows the head and the homework row with
  the footnote "No book yet, so no checks. Add one from <name>'s page."; `.failed` shows the `ErrorRow` with Try
  again); Done in a `FooterBand` with the footnote; after Done, pops to Today, whose hero reads the close.

- [ ] **Step 4: Run `TodayTests`** → pass. **Step 5: Commit** "Today: the close, with attendance, three checks per
  student from the spaced queue or the placement, and homework, in one write".

### Task 22: The close offline, Pending changes, the status line (PR 10)

**Files:**
- Create: `Features/Today/CloseStore+Queue.swift`
- Modify: `CloseStore.swift` (`queue`, `online`), `CloseView.swift` (the footer's "Saved on this iPhone" mark in the
  `due` tone), `AppShell/RootView+Close.swift` (`queue = centreQueue()`, `online`), `RootView+Offline.swift`
  (`refreshScreens` reads Today again after a sent close; the Pending changes row for a close reads its title and
  line; the sign-out dialog's `shortName`), `Fixtures.swift` (`pending` with a close waiting)
- Test: `Tests/TodayTests/CloseQueueTests.swift`, `Tests/AppShellTests/ShellStateTests.swift`

**Interfaces:**
- Produces: `CloseStore.mustQueue() async -> Bool` (offline, or a close or attendance change of this batch and day
  waits); `keepHere(_ close: SessionClose)` adds `.close(close:className:present:total:)` to the queue, sets `phase =
  .savedHere(at:)`, updates the register's statuses optimistically and pops; a close kept here makes Today's hero read
  closed with "saved on this iPhone" in the eyebrow (`AttendanceSession.closedAt` set locally through the attendance
  store's month copy as `keepHere` does for a save). The checks made before the network went are kept in the close;
  opening the close offline shows `.failed(OfflineRefusal.words(for: .placement))`-style in-place lines for the checks
  ("You're offline. The checks need a connection; mark attendance and homework, and Done still closes.") and Done works.

- [ ] **Step 1: Write the failing tests**

```swift
@Test func offlineACloseIsKeptHereAndTheHeroReadsClosed() async {
    let queue = ChangeQueue(centre: FakeCentreRepository.meeraWorkspace.centre.id, directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
    let store = await store(attendance: attendance)
    store.queue = queue; store.online = { false }
    #expect(await store.done())
    #expect(attendance.closes.isEmpty && queue.pending.has(kind: .close))
    #expect(store.phase == .savedHere(at: FakeClock.oct7at1705))
    if case let .close(_, className, present, total) = queue.pending.changes[0].kind { #expect(className == "Evening batch" && present == 5 && total == 5) }
}

@Test func aSecondCloseOfTheSameBatchAndDayReplacesTheFirstInTheQueue() async {
    let queue = ChangeQueue(centre: UUID(), directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString))
    let store = await store()
    store.queue = queue; store.online = { false }
    _ = await store.done()
    let again = await self.store()
    again.queue = queue; again.online = { false }
    again.toggle(0)
    _ = await again.done()
    #expect(queue.pending.changes.count == 1)
    if case let .close(close, _, present, _) = queue.pending.changes[0].kind { #expect(present == 4 && close.marks.values.contains(.absent)) }
}

@Test func openingTheCloseOfflineGivesAttendanceAndHomeworkWithTheChecksTold() async {
    let ai = FakeAIRepository(); ai.script = .failure(.offline)
    let store = await store(ai: ai)
    #expect(store.students.allSatisfy { if case .failed = $0.checks { return true }; if case .none = $0.checks { return true }; return false })
    #expect(store.students[0].checks == .failed("You're offline. The checks need a connection; mark attendance and homework, and Done still closes."))
}

// ShellStateTests addition
@Test func aSentCloseReadsTodayAgain() async {
    // refreshScreens() after a run that sent a close: Today's store loads (its loadCount moves).
}
```

- [ ] **Step 2: Run to see them fail.** **Step 3: Build** as Attendance's queue path (`AttendanceStore+Queue.swift`):
  the same rules, the row in Pending changes (`QueuedChange.title/line` from Task 7), the `shortName` in the sign-out
  dialog ("the close of Evening batch").

- [ ] **Step 4: Run `TodayTests` and `AppShellTests`** → pass. `bun check` green. **Step 5: Pictures** for PR 10's
  states: `today` (both), `today-after-close`, `close` (both), `close-scrolled`, `close-placement`, `pending` (a close
  waiting). Commit "Today: the close waits on this iPhone when offline and is sent as one"; open PR 10, merge on green.

### Task 23: The deploy, the hand runs (D32), TestFlight (main)

- [ ] **Step 1 (after PR 2):** `gh workflow run deploy`; the summary shows 0017 pending, pushed, nothing after; the API
  smoke green (`/health` the commit; `/ai/generate` 401). Record the run id in `STATE.md`'s Production. By hand once:
  `curl -X POST "$API_ORIGIN/ai/make" -H "Authorization: Bearer <a live token>" -d '{"kind":"check","centreId":"…","classLevel":"8","subject":"Science","skills":["Name the reactants"]}'`
  answers 200 with one question (the allowance's first call of the month).
- [ ] **Step 2 (after PR 10):** the hand runs below, then `gh workflow run testflight`; the build number from the run;
  the owner installs it from the internal group and checks the V2 screens on his iPhone (the Apple way: cite the Apple
  app for any pattern he questions).

**The hand runs,** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed (decision 19),
signed in as Meera, each write confirmed in the database, each screenshot kept in `.shots/run/` and attached to the
phase's issue ("Phase 11 hand run"); the local API runs with `AI_FAKE=1` (no money):

| Run | Before merging | Through the screens | Confirm |
|---|---|---|---|
| 1 Five tabs and the links | PR 5 | Today → School (the Later card) → More → Attendance (pushed, the footer band) → Back; `xcrun simctl openurl booted "tutorcentral://attendance?date=2026-10-05&class=<maths id>"` → More's stack at Mon 5 Oct, Class 10 Maths; `tutorcentral://student/<Riya's id>` → her page | the screenshots; nothing written |
| 2 Add a student V2 | PR 6 | Students → "+" → Add student → Kavya Nair, Class 9 (the Board row appears), School → Add a school "DPS Bangalore" → Karnataka state, Batch Class 10 Maths, parent Anita Nair, 98765 43210 in two parts, language Kannada → Save | `select name, class_level, school_id, board, message_language from students where name = 'Kavya Nair'`; `select name, board from schools` (DPS with `karnataka`); `chapters` has no row for her yet (no book for class 9 at DPS) |
| 3 Edit a V1 student | PR 6 | Students → Bir Bikram Singh → Edit → the Class tile reads Choose → change the parent's name → Save (live without a class) | `select name, class_level, parent_name from students where name like 'Bir%'`: the name changed, `class_level` null |
| 4 Consent | PR 7 | Students → Riya Sharma → Consent "Not recorded yet" → Ask on WhatsApp → the sheet → Open WhatsApp (nothing opens; the sheet closes) → the section reads "Asked Neha Sharma on <today>" → Parent agreed → How On a call, the day, the number → Record it → "Neha Sharma agreed" → Change → Remove → waiting again | `select kind, opened_at from message_log where kind = 'consent'` one row; `select consent_at, consent_phone, consent_how from students where name = 'Riya Sharma'` set, then all null |
| 5 Keep a textbook | PR 8 | Riya's page → Add a textbook → Mathematics → Take a photo (the camera is unavailable in the simulator: Choose from Photos, a page added with `simctl addmedia`) → Reading → 5 chapters → open chapter 2 → remove a skill → Keep 5 chapters → the page's Record shows Mathematics, 5 chapters | `select title, class_level, subject, photo_path, jsonb_array_length(chapters) from textbooks` (one row, `photo_path` null); `select count(*) from chapters where textbook_id = …` is 5 for Riya only (the only class 5 student at Vidya Niketan) |
| 6 A second capture and a later student | PR 8 | Place Riya first (run 7) so a skill is secure; Riya's page → Mathematics → Add the book again → Keep → her states stand; then Students → "+" → "Late Joiner", Class 5, Vidya Niketan → Save → the page's Record shows the 5 chapters | `select state from skills where student_id = <Riya> and state = 'secure'` still there; `select count(*) from chapters where student_id = <Late Joiner>` is 5 |
| 7 The placement | PR 9 | Riya's page → Place Riya (the tracking card) → tap Right, Right, Wrong, skip, Right → Done → the card reads the status and "Next" | `select kind, correct, session_id from checks where student_id = <Riya>` four placement rows, `session_id` null; `select name, state from skills where student_id = <Riya> order by position` the first two chapters' skills secure; `select track_status, tracked_at from students where name = 'Riya Sharma'` |
| 8 The close online | PR 10 | Today (the clock within 90 minutes of a batch: edit Class 10 Maths's time first, or run at the right hour) → Start class → Hemanth's checks: Right, Wrong, Right → Akshita absent → Ananya's homework off → Done → Today's hero reads closed | `select closed_at from attendance_sessions where date = current_date`; `select count(*) from checks where session_id = …` 3; `select count(*) from homework where session_id = …` (present minus Ananya); `select name, state from skills where id in (…)` moved; `select name, track_status, track_reasons from students where class_id = <maths>` |
| 9 The close offline | PR 10 | Stop the gateway (`docker stop supabase_kong_tutor_central`) → Today → Start class → the checks say offline in place → Dev absent → Done → "Saved on this iPhone" → More → Settings → Pending changes: "Class closed · Class 8 Science" → `docker start` → the banner "Sending 1 saved change…" then sent | `attendance_sessions` for today and Class 8 Science with `closed_at`; `homework` rows; the queue file gone |
| 10 A V1 student in the close | PR 10 | Students → add Bir Bikram Singh to Class 8 Science (Add to batch) → Start class → his card has attendance and homework only ("No book yet…") → Done | his `homework` row; no `checks` row for him; `track_status` stays `not_known` |

### Task 24: The documents (main)

- [ ] **Step 1:** `docs/testing/device-tests.md` gains a Phase 11 section for the tester: T1 the contents page with a real
  book under the camera (the chapters read), T2 the consent ask reaching a real WhatsApp chat with the message whole,
  T3 the close on mobile data that drops mid-way (saved on this iPhone, then sent).
- [ ] **Step 2: Documents (D12), one commit to `main` when the phase ends:** `plan/phase-11-record-and-close.md` "As
  built" (with the hero decision as the owner ruled it, the trust page and export deferred, the states built);
  `plan/README.md` (Phase 11 done; a decision number only if the owner's hero ruling needs one); `plan/STATE.md`
  (production: 0017, the API commit, the build); `plan/ui-polish.md` (anything seen; a row for the no-book card's words
  and the Marks section's absence, to be boarded); `docs/design/components.md` and `information-architecture.md` where
  the build corrected a board's words or added a state (`later-school`); `ios/CLAUDE.md`, `api/CLAUDE.md`,
  `supabase/CLAUDE.md` for rules learned (the close's eighth argument; `common.ts` and `v2.ts`; the photo never kept);
  `plan/sessions/024/record.md`, `ledger.md` and `owner-messages.md`; then a reviewer pass over the ten merged pull
  requests with `superpowers:requesting-code-review` on Fable 5.1 (fresh context), its Important findings fixed with a
  test that failed first, before the TestFlight build of Task 23 step 2 (as Phases 6, 7 and 10 did).

---

## Self-review (done 2026-10-10)

**Spec coverage** (`phase-11-record-and-close.md`'s eight scope items): 1 five tabs and links → Task 11; 2 Add student V2,
edit, archive, V1 defaults → Tasks 4, 8, 12, 13; 3 consent (the message, the record, the page) → Tasks 7, 9, 16 (the
trust page and App Privacy deferred by the spec's own rule, decision 3); 4 textbook capture, once per school, class and
subject, copied, a later student → Tasks 1, 2, 10, 18, 13; 5 the ladder and the placement → Tasks 5, 15 (the ladder
rows), 19, with `/ai/make` placement in Task 3; 6 the close with `close_session`, offline by D39, V1's session → Tasks 1,
20, 21, 22; 7 the student's page → Tasks 14, 15 (Marks deferred, decision 16); 8 tracking status rules, stored at the
close and on a change (the placement), the list sorted, not known yet → Tasks 6, 1, 13, 15.

**Placeholder scan:** no "TBD", no "similar to Task N" without the code; the views are specified by their Kit parts and
the boards' texts, as this repository's plans do; one test (the reopening test in Task 21) names the batch it must use.

**Type consistency:** `SessionClose` (Domain from Task 5; Data's call sites in Tasks 9, 10, 21, 22 use `states`);
`PlacementRecord` (Task 5) consumed by Tasks 9, 19; `CheckRecord`, `HomeworkRecord`, `HomeworkStatus`, `SkillStateChange`,
`MessageEntry` (Task 5) in Tasks 6, 9, 15, 16, 20, 21; `ConsentRecord` (Task 4) in Tasks 8, 16; `TextbookReading`,
`CheckQuestion`, `PlacementQuestion` (Task 10) in Tasks 18, 19, 21; `StudentFormStore.init` (Task 13) in Task 11's
wiring; `Route.attendance/close/textbook/placement` (Tasks 11, 18, 19, 21); `FakeStudentsRepository.hemanth`, `.riya`,
`.sahil` are added in Task 8 beside `akshita` (the attendance fake's `hemanth` reads them); `FakeClock` (`oct7at1635`,
`oct7at1705`, `oct7at1832`, `oct7at1840`, `sat10at0930`) is one helper file in each test target that uses it, built from
`DayHeading.india`; `register(evening:textbooks:schools:)` is each Students and Today test file's helper.

**Review focus:** the seven lines each name their tests; the no-book card's words and the offline checks' line are new
sentences checked by `ErrorWordsTests` and listed for a board on `ui-polish.md` (Task 24).
