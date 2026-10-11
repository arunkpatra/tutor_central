# Phase 14 plan: Parents

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-11 (session 29, Fable 5.1) from `phase-14-parents.md`, `docs/spec-v2.md` and the approved Phase 10 boards
(step 10.6, and 10.3's note day and To parents), with the owner's two rulings of the same day (D67, D68) as tasks, plus seven
Phase 14 boards drawn by this session for approval (row 24 of the canvas, `P14-*`). Ticked as it goes. The build runs on Opus
5.5 from `resume/028-phase-14-build.md`, inline, task by task, with one ledger as sessions 22, 24, 26 and 28 kept.

**Goal:** on the note day the tutor reads one note per student, in the parent's language with the English beside it, written
from the week's record (what was taught, what the student got right, what to practise, what is coming; for LKG to class 3,
what the student can now do from the ladder), and sends each with one tap; a parent gets at most three suggested messages a
week and the fourth waits, shown as held with its reason; a parent who has not agreed gets no note and the tutor sees why; a
student not on track shows the next step the plan will take unless the tutor changes it, and the parent can be told in their
language; marks are read from a photo of a report card or a marked test and saved after the tutor checks them; each message
ends with the tutor's name and "Made with Tutor Central". The model for each kind of AI work sits in one checked-in table an
environment variable overrides at deploy (D67). What Phase 13 left (U41 to U45, the review's five minors, the API's answer to
a lost database connection) is closed here, and nothing this phase finds is deferred (D68).

**Architecture:** the note is an artefact (`artefacts`, kinds `note` and `can_do`, a student and no plan), made on the phone
from the record as the user (D60): Domain's `NoteWeek` turns the week's checks, skill states, attendance, marks and school
items into facts; `/ai/make` kind `note` (or `can_do` for the ladder) writes the parent's words and the English from those
facts (the student's consent gates the call, D62); the app keeps the artefact, shows it on the note screen for reading and
editing, and logs a `message_log` row with the language and the body when WhatsApp opens. The cadence (`MessageCadence`,
Phase 13) decides send or held per parent across their students; a held note is a kept artefact with no log row that week,
shown as Held on Today and in the sent log. The note day lives on the batch (`classes.note_weekday`, `note_time`), Sunday
18:00 unless set. The next step lives on the student (`students.next_step`), null meaning the plan's own choice, and
`PlanRules` reads it for the teach line and the spaced queue. Marks from a photo go to a new route `/ai/read-marks` (a work
type apart from marking, D67) and come back as rows the tutor checks before `marks` rows are written. The model table is
`api/models.json`, read by the API at start (with `AI_MODEL_<WORK_TYPE>` overrides and a refusal to start on an unknown
name), by the test-side price sheet and by the cost tool. The note and can-now-do screens are `Artefacts`' (reached from
Today and Students through AppShell); the note day, the held sheet and the change wheel are Today's; the sent log, the
next-step sheet, the message to the parent and marks from a photo are Students'; the Phase 13 leftovers are School's.

**Tech stack:** as Phase 13 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI, Postgres, Bun tests; Hono, zod 4,
`@anthropic-ai/sdk`; XcodeGen). No new dependency.

**Spec:** `docs/spec-v2.md` sections 2, 3, 5 (tracking status and the next step; marks), 7 (note, can-now-do), 8 (consent,
the note, the cadence, the signature), 9 (models by kind, `message_log`); scope `plan/phase-14-parents.md` (items 1 to 8);
the boards and what they settle in `docs/design/information-architecture.md` ("Phase 10 boards", 10.6; 10.3's note day and
To parents; 10.2's Marks; 10.5's item sheet and page; "Phase 14 boards"), the parts and texts in `components.md` ("Phase 10
parts" 10.6; "Phase 14 parts"), the numbers in `design-tokens.md` ("Numbers in code", steps 10.3 and 10.6); decisions D56 to
D68; what Phase 13 built in `phase-13-school.md` "As built" and `plan/sessions/028/ledger.md`; what Phase 11 built in
`phase-11-record-and-close.md` "As built".

## Global constraints

- No board, no approval, no code for anything seen (rule 1). Each state a board draws gets a `LaunchState` and its
  pictures in the pull request, both appearances where the board has both (D7). What no board redraws stays as Phases 11
  to 13 built it. The seven Phase 14 boards (decision 30) are built only once approved.
- Nothing from V1 is renamed, dropped or narrowed in the model (D56, D26). Migrations 0023 and 0024 are additive and never
  edit 0001 to 0022: new columns are nullable or have defaults; new enum values are added in 0023 and used in 0024 (a value
  cannot be used in the transaction that adds it, which is why 0012 and 0013 were two files); `start_ai_generation` keeps
  its signature. `types.ts` regenerated and committed with them.
- A replaced function: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute … to
  authenticated`; a test for each path it refuses. No `security definer` beyond `is_member` and `delete_account` (D37). No
  service-role key, no server job, no cron (D37, D60): the app makes the notes and reads the record.
- The API runs each call as the user (D5); inputs are zod schemas; a route validates first (400 with the issues);
  `start_ai_generation` gates each call (the monthly allowance; a student's consent for a personal kind); one model per
  work type from the table, no fallbacks (D35, D63, D67). The API reads no table but `ai_generations`.
- Nothing about a student goes to the AI without consent (D62): the note, can-now-do, the not-on-track message in a
  parent's language and reading a report card name the student and need the recorded consent, which the gate enforces
  and the app checks first; the English not-on-track message is a template on the phone (as Test tomorrow's is) and
  needs no call. A test holds each side.
- No textbook text anywhere (D58): skill and chapter names, the week's counts and the school's own item titles go to
  Claude; nothing from inside a book.
- No photo is stored by the API; a report card's photo is read and dropped (`marks.photo_path` stays null, as the
  textbook's does).
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4: the note screen is
  `Artefacts`', reached by AppShell routes from Today and Students; the held sheet and the change wheel are Today's; the
  sent log, the next step and marks from a photo are Students'; the rules are Domain's); tokens only (D10; a value a board
  uses that `design-tokens.md` does not name is added to the document and to `Tokens` in the same commit, D25); Swift
  Testing in the existing test targets.
- No technical words on screen (D41): each new sentence passes `ErrorWordsTests`; each message is one of
  `docs/design/feedback.md`'s rows (a failed or refused write is the system alert; a list that could not load says so in
  its place; a success shows in place; the toast is for Undo only).
- Text limits count Unicode scalars (D48): the note's 600 on the phone, the API's 600 as code points. Both appearances
  (D13). Dynamic Type through `AdaptiveRow` and `growsWithText()` where a row puts a value beside a title.
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull requests
  with pictures; documents directly to `main` (D12), never mixed with code.
- Plain voice in documents and comments; the word is Students, not Children; "Batch" on screen for V1's class.
- D68: a hand-run fault, a review finding of any grade, or a polish item this phase's work brings is fixed in this phase,
  each with a test that failed first; the review's minors are fixed in the fix pass too. The phase closes with no open
  finding of its own.

## Decisions this plan takes

Small decisions, written here so they are not re-decided. The owner's are marked.

1. **The note is a kept artefact.** When the tutor opens a note (Read on the note day) the app makes it once through
   `/ai/make` (`note`, or `can_do` for a student on the ladder) and keeps it with `keep_artefact` (kind `note` or `can_do`,
   the student, no plan, `school_item_id` null; `content` holds the message, the English, the language, the facts, the
   week's Monday and the generation id). Opening it again that week shows the kept one; Write again makes a new one with
   `regenerated_from` set; a Sunday note read on Monday is the same note. The log row (`message_log`, kind `note` or
   `can_do`, the language, the body as sent) is written when WhatsApp opens, as Test tomorrow's is; Copy writes a row with
   `channel = 'copied'`. The sent log reads "opened <day>" from a WhatsApp row, "copied <day>" from a copied row, and "not
   opened yet" for a note kept this week with no row.
2. **The note's week and its facts** (`NoteWeek`, Domain, pure): Monday to the note day, in the centre's calendar. Taught:
   skills of the student whose state moved from not started in the week (by chapter order, six at most), for a note
   with none "Nothing new this week". Got right: the week's checks right of asked ("8 of 12 checks"; the placement's left
   out), with a mark of the week after it ("14 of 25 on Unit test 2"); with no checks and no mark the fact reads "No checks
   yet" and the prompt leaves the sentence out. To practise: skills in practising or revisit among the week's chapters,
   else the skills of the week's wrong checks (three at most). Coming: the next not-started skill after the current one,
   and the nearest exam within the window ("the unit test on Fri 16 Oct"). Attendance: absences of sessions this week for
   the student's batches ("absent 2 of 3 classes"; "absent all week (3 classes)"), left out when none. The note says what
   the facts say and nothing else (the prompt's rule). A student absent all week still gets a note: the attendance fact and
   what the group did, with "Taught" reading the group's skills that week only when the student was present for any of it,
   else "Nothing new this week: absent all week".
3. **Can-now-do** (`CanDoWeek`): for a student on the ladder (LKG, UKG, and classes 1 to 3 for reading, writing and
   numbers), the facts are the steps that became secure this week ("Moved up": area and step), what the student can now do
   (the current secure step per area, "Read short sentences · count to 99"), what to do at home (a fixed line per area
   and step from Domain's table, no AI: reading "One page a day from the picture book", writing "Five words a day in the
   notebook", numbers "Count things at home to 99"), and what is next (the next step per area). A class 1 to 3 student
   with books as well gets the can-now-do (the ladder leads); from class 4 the note.
4. **The note day** is `NoteDay(weekday: .sunday, time: 18:00)` unless the batch sets another (`classes.note_weekday`,
   `note_time`, migration 0023; `Classroom.noteDay`). The wheel's choices are the board's five (Friday 18:00, Saturday 18:00,
   Sunday 18:00, Sunday 20:00, Monday 08:00). Today shows the note day's hero and the Notes card from the note time on the
   note weekday to the end of the next day, for the students of the batches whose note day that is; a tutor with one
   evening batch moves it once. Change day on the hero sets the day on each batch whose note day is the one shown. A
   student in two batches with two note days gets one note a week, on the earlier day. A student whose parent has no
   number is not listed (nothing to send to) and not counted.
5. **The Notes card's row:** the language, the week's lead topic (the first taught skill's chapter; "Can now …" for the
   ladder) and the lead fact ("2 absences", "all right", "absent Wed", "not on track"), as P10-Today-NoteDay reads; Read
   (primary 36) opens the note, Sent in `ok` once logged this week, Held in `text3` with the reason on the row ("held:
   three messages this week"; "waits for Neha's consent"). The count "k of n sent" counts rows sent this week over rows
   listed.
6. **The cadence and a held note** (`MessageCadence.decision`): the parent's suggested messages this week (note, can_do,
   test_tomorrow, not_on_track) across their students by number, Monday to Sunday; three or more → `.held(.threeThisWeek)`;
   no consent → `.held(.consent)`; else `.send`. A held row on Today opens the held sheet (P10-Held): the parent's messages
   this week with their kinds and days, the board's footnote, Send it now (opens the note as Read does; the send counts as
   a fourth, by the tutor's hand) and Keep it for next week (closes; nothing is written: the note shows again on the next
   note day, made afresh from the new week). A held note sits in the sent log's Held section with Send now until the next
   note day's note replaces it; from Monday the count is the new week's, so Send now sends it without the sheet. A hand
   send (a reminder, a receipt, the absence alert, consent, the forward ask, Call) never counts (Phase 13's rule stands).
7. **The sent log** (See all on the page's Messages, P10-Student-Messages): rows by month, newest first, each the kind's
   title, the day, the language and "opened <day>", "copied <day>" or nothing for a V1 kind without a language; a Held
   section between the months for the held note (title, "Held since <day> · <reason>", Send now). `MessageEntry` gains
   `channel` and `body`; the page's own Messages section keeps its five rows and gains See all.
8. **The homework share is not a message the app can log.** A homework sheet shared as a PDF goes through the system's
   share sheet (Phase 12), which tells the app nothing of who received it, so no `homework` row is written and nothing is
   counted; the kind's row words exist in the sent log for a later phase that addresses a sheet to the parent. The board's
   held "Homework sheet shared" row is illustrative of a held kind. Spec 8's "homework shared as a PDF when the tutor
   chooses" is met by Phase 12's Share as PDF.
9. **Not on track and the next step** (`NextStep`, Domain): five steps (tell the parent then teach again; teach again with
   the worked example; step back to what comes before; add it to the checks; leave it for now). The plan's own choice from
   the status: not on track → tell the parent; watch → teach again; else leave. The tutor's choice is kept on the student
   (`students.next_step`, null for the plan's own) and holds until the status changes (the close clears it when the
   stored status moves). `PlanRules` reads the effective step for the teach line: tell the parent and teach again →
   "Teach again: <skill>, with the worked example" (as today); step back → "Step back: <the skill before>, then <skill>"
   with the earlier skill's id; add to the checks → "Teach: <skill>" and the skill at the head of the spaced queue (a
   personal check); leave → "Teach: <skill>". The tracking card's Next reads the effective step's sentence; Change opens the
   next-step sheet (P10-NextStep) with the plan's choice ticked and Use this writes the step and remakes today's open plan.
10. **The message to the parent** (P10-NotOnTrack-Message): offered on the page under the tracking card while the student
    is not on track, the effective step is tell the parent, and no `not_on_track` row was logged since `track_since`; Call
    (tel:) and Tell the parent (the two-language sheet "Dev needs a hand this month": what is hard, what we are doing, what
    helps at home, a five-minute talk). In English it is a template on the phone (`NotOnTrackMessage.text`, no consent, no
    call); in Hindi, Hinglish or Kannada it is `/ai/make` kind `not_on_track` with the student's consent, the English
    beside it. Open WhatsApp logs kind `not_on_track` (a new `message_kind` value, 0023; the IA's "a note row of kind not
    on track" needs a kind of its own to read as "Not on track" in the sent log) with the language and body. On Today the
    student's line carries the caption "Since <day> · tell <parent's first name> after the class" (`overdue`) under the
    same conditions; tapping it opens the student's page. The not-on-track message counts in the cadence.
11. **Marks from a photo** (Add from a photo on the page's Marks, P10-Student-Record; the states on the Phase 14 boards): a
    report card or a marked test, one or two photos (the camera or Photos, reduced by `PhotoReducer`), to `POST
    /ai/read-marks` (a work type of its own, `read_marks`, D67; the student named, their consent gated; without consent the
    action is disabled with the reason line "Marks from a photo wait for <parent>'s consent"). The rows come back as
    subject, test, date, score and max; a row with no date reads "Date · not given" and stays unticked until the tutor sets
    one on its sheet; Save writes a `marks` row per ticked row (`photo_path` null, no exam, no artefact) and pops to the
    page, whose Marks lists them; the toast "3 marks saved to Hemanth's page" with Undo removes them. A subject the student
    has no book for is kept as written (`marks.subject` is text; Below usual compares by subject). Nothing is kept until
    Save.
12. **The signature** (`MessageSignature`, Domain): each message the app writes ends with a blank line, the tutor's name,
    the centre's name and "Made with Tutor Central": the note, can-now-do, Test tomorrow, the not-on-track message, Ask
    parents to forward, the consent ask, the absence alert, the fee reminder, the receipt and V1's progress note. The
    models no longer sign (Test tomorrow's prompt stops asking for it); the app appends the signature once, so the counter
    counts the body and the signature is outside the 600. The changed sheets are photographed again (D7).
13. **D67, the model table** (the owner, 2026-10-11): `api/models.json` holds the models with their prices (USD per million
    tokens in and out) and one row per work type: the V1 kinds (`paper`, `homework`, `worksheet`, `progress_note` on Sonnet;
    `scan_register`, `check_paper` on Opus), `plan`, `sheet_to_5` (Haiku), `sheet_from_6` (Sonnet), `worked_example`,
    `figure`, `brief`, `mock`, `gap_report`, `parse_school`, `parse_textbook` (Sonnet), `check`, `placement`, `note`,
    `can_do`, `test_tomorrow`, `not_on_track` (Haiku), `read_marks` (Sonnet until the cost run sets it, decision 27).
    `src/models.ts` imports it, applies `AI_MODEL_<WORK_TYPE>` from the environment (`AI_MODEL_CHECK_PAPER`,
    `AI_MODEL_SHEET_FROM_6`, …) and refuses to start on a name that is not one of the table's models, naming the variable
    and the known names; `modelFor(work, classLevel?)` is the one place a prompt asks; `MARKING_MODEL` and the old `MODELS`
    table go. The call records the model it used (`ai_generations.model`, as today), so an override shows in the log. The
    price sheet (`DomainTests/PriceSheet.swift`) reads the same file for prices and models; `bun cost` (a new tool) reads it
    to price the local `ai_generations` rows by kind and model. The work types are the `ai_kind` values plus the sheet's
    two bands; a test holds the table to the kinds.
14. **The API's answer to a lost database connection** (D68): the verifier tells an invalid token from an unreachable
    Supabase (a fetch failure or a 5xx from `auth.getUser`): the first is 401 "sign in again" as today; the second is 503
    `{ error: "Couldn't reach the service. Try again.", reason: "unreachable" }`, and the app reads a 503 as its
    connection words ("Couldn't reach the AI service. Check your connection and try again."). A status the app does not
    know (a 501 from a stale API, a 500) reads as "The AI service didn't answer. Try again.", never the body's words
    (`APIFailure.server` keeps only the tutor-facing 400 and 422 bodies).
15. **The review's five minors** (D68): a failed item insert removes the photo it uploaded (`ReadStore.add`); a student's
    missing consent answers 403 `reason: "student_consent"` with "<name>'s parent hasn't agreed yet." and the app shows it
    as the alert "The parent hasn't agreed yet. Record their consent on the student's page first." (never the centre's
    "Agree to the notice" words); `OfflineRefusal` has three reading refusals (a share waits here; a pasted message and a
    photo say to try again when back online); `SupabaseSchoolItemsRepository.update` filters by centre and id;
    `ExamPreparation.isWithinWindow` counts days with its calendar.
16. **U41** (a board first, P14-School-Paste): Paste a message opens "Check what was read" with the source well holding
    the system's `PasteButton` and the line "Copy the school's message in WhatsApp, then tap Paste. Nothing is read until
    you do."; iOS asks nothing, the text is read on the tap. **U42** (P14-School-Student): the student page's See all opens
    the School tab filtered to that student (a chip row under the title, "Dev's items" and Show all). **U43**
    (P14-School-Item-Window): the item's sheet gains "Preparation · 14 days before" for an exam, a setting row whose value
    opens the system wheel (7, 10, 14, 21 days), kept in `school_items.window_days` (0023) and read by the split, the plan
    and the page; 14 when null. **U44**: Who's rows carry chevrons and open the student's page (P10-School-Item). **U45**: the
    mock's prompt asks for two to six skills across the paper, each a portion's skill, each question naming one of them, so
    By skill groups (a test counts distinct skills in the fake and the prompt's words).
17. **The API's note kinds** replace the Phase 10 skeleton shapes nobody sent: `note` takes the student, the parent's name,
    the centre, the class, the language and `week` (taught, right, practise, coming, attendance, marks as decision 2's
    strings); `can_do` takes `ladder` (movedUp, canDo, atHome, next); `not_on_track` takes `hard`, `reasons`, `doing`,
    `atHome`. Each answers `MessageOutput { message, english }` (600, the prompt asks for 500 and no signature); for
    English the English repeats the message and the app shows one block. The fake answers the boards' Hindi note, the
    Kannada can-now-do and the Hindi not-on-track message by kind. `/ai/read-marks` takes one or two photos, the student
    and the student's subjects (so "Maths" reads as "Mathematics") and answers `ReadMarksOutput { marks: [{ subject, test,
    date | null, score, max }] }` (twelve at most); none read is refused in words ("Couldn't read any marks from this photo.
    Try a flatter, brighter one.").
18. **The note's screen** (P10-Note, -Light, -Send; P10-CanNowDo): pushed from Read; the hero (avatar, the student, "<parent>
    · <language> · the week of <Monday's date>"); the editable well "The note · Hindi" with the counter "212 of 600" (over
    600 the counter in `overdue` and Send disabled); "In English, for you" on `surface2` (none for English); "What it says"
    (Taught, Got right, To practise, Coming; Can now do, At home, Next); the footer: the AI line ("…the facts are from Dev's
    record." / "…from Sahil's ladder."), Write again, Copy, Send on WhatsApp. Can now do adds "Moved up" (the ladder's area
    with its five steps, the new step marked) above the well. Send opens the two-language sheet "Dev's week, for Ramesh"
    with the board's note; Open WhatsApp logs and opens. While the note is made, the well's place holds the Phase 6
    creating card ("Writing Dev's note", "Usually under a minute. From this week's record.") and the footer waits. A note
    the API refuses or the connection fails shows the alert with Try Again and the facts stay.
19. **Where the note is opened from:** the note day's Read, a held row's Send it now, the sent log's Send now, and the
    after-close "Weekly notes" row (which opens Today's Notes card when the note day is on; before it, the row only reads
    the count). The IA's "Write a note" on the student's page has no board on P10-Student-Record and is not built; a
    polish row names it.
20. **To parents after the close** (P10-Today-AfterClose) gains its last row, "Weekly notes · <weekday>": "N notes wait for
    the note day. <names>'s waits for consent." counting the closed batches' students with a parent's number, naming those
    without consent (one name, or "two wait for consent" from two).
21. **Offline:** the week's kept notes are copied to the iPhone (`cache-<centre>-notes.json`, wiped with the centre's
    files) so a made note opens offline; Read on a note not yet made is refused in words (`OfflineRefusal.note`: "You're
    offline. The note is written from this week's record and needs a connection."); Send on WhatsApp offline logs nothing
    and shows the refusal (as Test tomorrow does); Change day, Use this and Save marks are refused offline in words.
22. **Fixtures for the states:** the clock Sunday 11 October 2026 18:30 for the note day's states (`today-note-day`,
    `today-note-held`, `today-note-day-change`, `note`, `note-send`, `note-can-do`, `student-messages`); Friday 9 October
    16:35 for the not-on-track states (Dev not on track since that day with the board's reasons; the plan's groups as
    P10-Today-NotOnTrack); Wednesday 7 October 16:35 for the marks and School states. Dev's parent Ramesh Kumar writes in
    Hindi and agreed; Sahil's parent Deepak Verma in Kannada and agreed, Sahil on the ladder at Sentences; Riya's parent
    Neha has not agreed; for `today-note-held` Dev's parent has a reminder, Test tomorrow and a not-on-track message this
    week. Figures follow the data where the fixtures' record gives other numbers (the owner, 2026-10-08).
23. **Branches** `phase-14/<slug>` in the main checkout, one pull request each, as sessions 22 to 28 worked.
24. **Hand runs** against a freshly reset seed with the local API on the fake except the cost run; the seed gains recorded
    consent for Kavya Nair (Kannada), Rohan Gupta (Hinglish) and Diya Pillai (Hindi) so the note runs need no psql; a run
    on a day that is not the note day moves the Evening batch's note day to the real weekday and time by the Change day
    wheel (the write under test) and puts it back after.
25. **The cost of a week's notes** (D64) is measured on the real models after the hand runs, with the owner's standing
    approval for real calls in testing: the twelve students' notes (Haiku), a can-now-do, a not-on-track message, and
    reading one report card photo on Sonnet and on Opus (`AI_MODEL_READ_MARKS` set on the local API between the two runs).
    The record writes calls, tokens and rupees per kind, a week of notes for twelve students, and a month at four weeks.
26. **The read-marks default** is set from the cost run: the cheaper of Sonnet and Opus that reads the report card's rows
    right (each subject's test, date, score and max as printed); a wrong row on the cheaper one sends the default to the
    dearer. Written into `api/models.json` in a pull request of its own (PR 13) with the figures in its description.
27. **Two migrations, 0023 and 0024:** 0023 adds the columns and the enum values; 0024 replaces `start_ai_generation` with
    `read_marks` and `not_on_track` among the personal kinds (an enum value cannot be used in the transaction that adds
    it). The seed's consents ride with 0023's pull request.
28. **The tests' helpers:** `ParentFixtures` in `DomainTests` (Dev's week: three sessions, 12 checks with 8 right, two
    skills moved to taught, one practising; Sahil's ladder with Sentences made secure this week; Riya with no checks) and
    `FakeClock.oct11at1830`, `.oct9at1635` in the feature test targets, as Phase 13's `SchoolFixtures` were.
29. **The deploy** after PR 4 (0023, 0024 and the API's new kinds), a second after PR 13 (the read-marks default); nothing
    ships to TestFlight before the hand runs, the cost run and the review.
30. **The owner's to confirm:** the seven Phase 14 boards drawn by session 29 on row 24 of the canvas (P14-Marks-Reading,
    P14-Marks-Confirm and its light twin, P14-Marks-Edit for marks from a photo; P14-School-Paste for U41;
    P14-School-Student for U42; P14-School-Item-Window for U43) before PRs 11 and 12 build them. The plan itself before any
    build starts.

### Left for later, with the reason

Nothing this phase finds is left (D68). Two things the spec names are not this phase's and are written here so they are
not lost:

- **The trust page and the App Privacy answers** (spec 9, Privacy): "updated in the phase that first sends a student's data
  to testers", which is Phase 15's tutor round. Phase 11 moved them here; the spec's own rule moves them on. The owner may
  rule otherwise.
- **Export per student** (D62): not in `phase-14-parents.md`'s scope and no board draws it; Phase 15 (Reports extended)
  is where a per-student export fits.
- **"Write a note" from the student's page** (the IA's parenthesis): no board draws it on P10-Student-Record; a polish row.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A student absent all week:** the note still comes, with the attendance fact and no invented teaching; Taught reads
   "Nothing new this week: absent all week". Tests: Task 6 (`NoteWeekTests.aStudentAbsentAllWeekGetsTheAttendanceFactAndNoTaught`),
   Task 4 (`a note with no taught skills leaves that sentence out and keeps the attendance line`), Task 14
   (`NoteStoreTests.anAbsentStudentsNoteIsStillMade`).
2. **A student with no checks yet** (joined this week, or never closed): Got right reads "No checks yet" on the facts card
   and the note has no sentence about it; a student with no skills at all gets the facts from attendance alone. Tests: Task 6
   (`NoteWeekTests.aStudentWithNoChecksHasNoGotRightSentence`, `aStudentWithNoSkillsStillHasFacts`), Task 3 (`the prompt
   says to leave out an empty fact`).
3. **A parent of two students** (one number): two notes a week count two of the three; the third suggestion of the week
   goes and the fourth is held for both students; the held sheet lists both notes. Tests: Task 7
   (`MessageCadenceTests.twoStudentsOfOneParentShareTheThree`), Task 12 (`NoteDayStoreTests.aParentOfTwoSeesBothNotesAndTheFourthHeld`).
4. **A note edited past 600 characters** (or in a script where a glyph is several scalars): the counter turns `overdue`,
   Send and Copy are disabled, nothing is logged; cutting it back enables them. Tests: Task 14
   (`NoteStoreTests.aNoteOverSixHundredScalarsCannotBeSentAndTheCounterSaysSo`, `aKannadaNoteCountsScalarsNotBytes`).
5. **The note day changed after notes were sent:** the notes sent this week stay Sent and are not offered again; the next
   note day is the new weekday; a change to a day earlier in the same week shows the unsent notes that day. Tests: Task 12
   (`NoteDayStoreTests.changingTheNoteDayKeepsThisWeeksSentRowsAndMovesTheNextDay`), Task 6
   (`NoteDayTests.theWeekEndsOnTheNoteDayWhateverTheWeekday`).
6. **A held suggestion that frees up mid-week:** a note held on Sunday is free on Monday (the count is the new week's); the
   sent log's Send now sends it without the held sheet; on the next note day a fresh note replaces it. Tests: Task 7
   (`MessageCadenceTests.aNoteHeldOnSundayIsFreeOnMonday`), Task 15 (`MessagesStoreTests.aHeldNoteOffersSendNowOnceTheWeekRolls`,
   `theNextNoteDaysNoteReplacesAHeldOne`).
7. **A report card with subjects the student has no book for** (Hindi, Social science): the rows are kept as written and
   saved; the page lists them; Below usual compares within that subject. Tests: Task 17
   (`ReadMarksStoreTests.aSubjectWithNoBookIsKeptAsWrittenAndSaved`), Task 6 (`MarkRulesTests.belowUsualComparesWithinTheSubjectAsWritten`).
8. **The lost connection in the API** while a tutor's token is good: the app says to check the connection, never to sign
   in again; a stale API's 501 reads as the service words. Tests: Task 3 (`an unreachable Supabase answers 503, not 401`),
   Task 9 (`APIClientTests.a503ReadsAsTheConnectionWords`, `a501NeverShowsTheAPIsWords`).
9. **A model override set to a name that is not a model:** the API refuses to start and says which variable; the deploy's
   smoke fails; a good override reaches the next call and its log. Tests: Task 2 (`an unknown AI_MODEL value stops the
   entry`, `AI_MODEL_NOTE reaches the next note call and its record`).

## File structure

Created or changed, by module. A file has one job; the stores are small and named for what they do.

| Module | File | Job |
|---|---|---|
| supabase | `migrations/20261028000023_v2_parents_columns_kinds.sql`, `migrations/20261029000024_v2_ai_personal_kinds.sql` | The note day on the batch, the next step on the student, the exam's window, the new kinds and channel; `start_ai_generation` with `read_marks` and `not_on_track` personal |
| supabase | `tests/v2.test.ts` (a "parents" block), `seed.sql` (consents), `types.ts` | The function tests; the local data; the generated types |
| api | `models.json`, `src/models.ts` (the table read, the overrides, the refusal), `src/index.ts` (apply at start), `.env.example`, `src/prompts/*.ts` (`modelFor` only), `test/models.test.ts`, `test/entry.test.ts` | D67 |
| api | `src/auth.ts` (`Verify` answers `unreachable`), `src/index.ts` (the verifier tells the two apart), `src/errors.ts` (`unreachable`, `studentConsent`), `src/routes/common.ts`, `src/prompts/mock.ts` (U45), `test/auth.test.ts`, `test/ai.test.ts`, `test/prompts.test.ts` | The API's answers (D68) |
| api | `src/schemas.ts` (`note`, `can_do`, `not_on_track` inputs, `MessageOutput`, `ReadMarksInput`, `ReadMarksOutput`), `src/prompts/note.ts`, `can-do.ts`, `not-on-track.ts`, `read-marks.ts`, `test-tomorrow.ts` (no signature), `src/routes/v2.ts` (the three kinds, `/read-marks`), `src/db.ts` (`V2Kind` adds `not_on_track`, `read_marks`), `src/claude-fake.ts` (four samples, `kindOf`), `src/errors.ts` (the reader's refusal words), `test/v2.test.ts`, `test/schemas.test.ts`, `test/prompts.test.ts`, `test/claude-fake.test.ts` | The parents' kinds and the reader |
| tools | `cost.ts`, `cost.test.ts`, `package.json` (`cost`), `CLAUDE.md` (Commands) | `bun cost` |
| Domain | `Parents/NoteDay.swift`, `Parents/NoteFacts.swift` (`NoteFacts`, `NoteWeek`), `Parents/CanDoFacts.swift` (`CanDoFacts`, `CanDoWeek`), `Parents/NextStep.swift`, `Parents/NotOnTrackMessage.swift`, `Parents/MessageSignature.swift`, `Parents/NoteContent.swift` (the artefact's content), `School/MessageCadence.swift` (`Decision`, `HeldReason`), `School/SchoolItem.swift` (`windowDays`), `School/ExamPreparation.swift` (the window per exam, the calendar), `Record/Mark.swift` (`ReadMark`), `Record/RecordTypes.swift` (`MessageEntry.channel`, `body`; `MessageChannel`; `MessageKind.notOnTrack`), `Student.swift` (`nextStep`), `Classroom.swift` (`noteDay`), `Plan/PlanRules.swift` (the step's teach line and personal check), `Plan/Artefact.swift` (`NoteContent` in `ArtefactContent`), `Queue/OfflineRefusal.swift`, `FeeMessage.swift`, `AbsenceMessage.swift`, `Record/ConsentMessage.swift`, `School/ForwardAskMessage.swift`, `School/TestTomorrowMessage.swift` (the signature) | The rules and the shapes |
| Data | `Messages/*` (`logMessage`, `messages` with channel and body, `heldRows`), `Plans/PlansRepository.swift` (`keepNote`, `notes(for:since:)`), `SupabasePlansRepository.swift`, `FakePlansRepository.swift`, `Classes/*` (`setNoteDay`, the two columns), `Students/*` (`setNextStep`, `next_step`), `School/*` (`window_days`; `update` by centre), `AI/AIRepository+Parents.swift` (`NoteRequest`, `CanDoRequest`, `NotOnTrackRequest`, `ReadMarksRequest`, `ReadMarksAnswer`), `AI/APIClient+Parents.swift`, `AI/APIBodies+Parents.swift`, `AI/FakeAIRepository.swift`, `AI/AISamples+Parents.swift`, `AI/APIClient.swift` (503, student consent, unknown statuses), `AI/APIFailure.swift` (`studentConsent`), `Cache/NotesCache.swift` | The reads and writes behind the screens |
| DesignSystem | `Components/FactsCard.swift`, `MessageLogRow.swift`, `LadderStrip.swift` (Moved up), `NoteWell.swift` (the counter and helper), `HeldSheet.swift`, `ChoiceRowsSheet.swift` (the next step's five rows), `MarkReadRow.swift`, `PasteWell.swift`, `FilterChipRow.swift`, `Tokens/Tokens.swift` and `docs/design/design-tokens.md` where a board's value is new | The 10.6 and Phase 14 parts |
| Features/Artefacts | `NoteStore.swift`, `NoteStore+Facts.swift`, `NoteView.swift`, `NoteSections.swift`, `ArtefactScreen.swift` (`.note`), `ArtefactsActions.swift` (`openStudent`) | The note and can-now-do |
| Features/Today | `NoteDayStore.swift`, `NoteDaySections.swift` (the hero, the Notes card), `NoteDayChangeSheet.swift`, `TodayStore.swift` (the note day read with the counts), `TodayStore+Parents.swift` (the Weekly notes row; `told`), `PlanStore+Cards.swift` (`caption`), `PlanSections.swift` (the caption), `TodayView.swift` | The note day; Today's line |
| Features/Students | `MessagesScreen.swift`, `MessagesStore.swift`, `NextStepSheet.swift`, `NotOnTrackStore.swift`, `TellParentCard.swift`, `ReadMarksStore.swift`, `ReadMarksView.swift`, `ReadMarkEditSheet.swift`, `RecordSections.swift` (Marks' action, Messages' See all, the Held row), `StudentDetailStore+Record.swift` (the effective step), `StudentDetailView.swift`, `StudentsActions.swift` | The sent log, the next step, the message, marks from a photo |
| Features/School | `ReadStore.swift` (PasteButton's stage, the photo removed on failure), `ReadView.swift`, `SchoolStore.swift` (`filter`), `SchoolView.swift` (the chip row), `ItemFormStore.swift` and `ItemFormSheet.swift` (the window row), `ItemSections.swift` (Who's chevrons), `ItemStore+Preparation.swift` (the window) | U41 to U44 |
| AppShell | `TabsState.swift` (`Route.note(UUID, Day)`, `.studentMessages(UUID)`, `.readMarks(UUID)`), `RootView+Today.swift`, `RootView+Students.swift`, `RootView+Artefacts.swift`, `RootView+School.swift`, `RootView+LaunchStates.swift`, `LaunchState.swift`, `Fixtures+Parents.swift`, `ShellState.swift` (`heldNote`, `noteDayChange`, `nextStep`, `tellParent`), `Dependencies.swift` | The shell |
| Tests | `supabase/tests/v2.test.ts`; `api/test/{models,entry,auth,ai,v2,schemas,prompts,claude-fake}.test.ts`; `tools/cost.test.ts`; `DomainTests/{NoteDayTests, NoteWeekTests, CanDoWeekTests, MessageCadenceTests, NextStepTests, NotOnTrackMessageTests, MessageSignatureTests, PlanRulesStepTests, MarkRulesTests, ExamWindowTests, OfflineRefusalTests, PriceSheet (reads models.json), ArtefactContentTests (note)}`; `DataTests/{MessageEntryRowTests, NotesCacheTests, APIBodiesParentsTests, FakeAIRepositoryParentsTests, APIClientTests (503, 501, student consent)}`; `ArtefactsTests/NoteStoreTests`; `TodayTests/{NoteDayStoreTests, ToParentsTests (the Weekly notes row), PlanCaptionTests}`; `StudentsTests/{MessagesStoreTests, NotOnTrackStoreTests, NextStepTests, ReadMarksStoreTests}`; `SchoolTests/{ReadStoreTests (paste, the photo removed), SchoolStoreTests (filter), ItemFormStoreTests (window)}`; `AppShellTests/{LaunchStateTests, RoutesTests}`; `DesignSystemTests/TokenDocumentTests` | |

## Launch states

Each state the 10.6 boards name, 10.3's note day and To parents, and the seven Phase 14 boards', with the fixtures' data
(decision 22). Light twins from `--appearance light` where the board has both.

| State | Shows | Board | PR |
|---|---|---|---|
| `attendance-alert`, `fees-remind`, `fees-receipt`, `student-consent-ask`, `school-ask`, `school-test-tomorrow` | The message sheets with the signature's last line (what changed; the boards stand) | P4-Attendance-Alert, P5-Fees-Remind, P5-Fees-Receipt, P10-Consent-Ask, P10-School-Ask, P10-TestTomorrow | 5 |
| `today-note-day` | Sunday 11 October 18:30: the note day's hero, the Notes card (2 of 7 sent; Dev and Meher Sent; Nikhil, Sahil, Hemanth, Akshita Read; Riya Held for consent) | P10-Today-NoteDay | 7 |
| `today-note-held` | The held sheet over the note day for Dev (a reminder, Test tomorrow, Not on track this week) | P10-Held | 7 |
| `today-note-day-change` | The note day's wheel | P10-NoteDay-Change | 7 |
| `today-after-close` | 18:40: To parents with the Weekly notes row ("4 notes wait for the note day. Riya's waits for consent.") | P10-Today-AfterClose (the 10.3 note) | 7 |
| `note` | Dev's weekly note in Hindi with the English beside (both) | P10-Note, -Light | 8 |
| `note-send` | The two-language sheet over it | P10-Note-Send | 8 |
| `note-can-do` | Sahil's can-now-do in Kannada with Moved up | P10-CanNowDo | 8 |
| `note-writing` | The note being written (the creating card in the well's place) | the Phase 6 creating card, as P13-School-Reading placed it | 8 |
| `student-messages` | Dev's sent log by month with the Held section | P10-Student-Messages | 9 |
| `student-not-on-track` | Dev's page: the tracking card in `overdue` with Next and Change, the tell-the-parent card | P10-Student-NotOnTrack | 10 |
| `student-next-step` | The next-step sheet, the plan's choice ticked | P10-NextStep | 10 |
| `student-tell-parent` | The message to the parent in Hindi with the English beside | P10-NotOnTrack-Message | 10 |
| `today-not-on-track` | Friday 9 October 16:35: Today's plan with Dev's caption | P10-Today-NotOnTrack | 10 |
| `marks-reading` | Hemanth's report card being read | P14-Marks-Reading | 11 |
| `marks-confirm` | The rows read, one without a date unticked (both) | P14-Marks-Confirm, -Light | 11 |
| `marks-edit` | A row's sheet over them | P14-Marks-Edit | 11 |
| `student-marks` | Hemanth's Marks with Add from a photo (the 10.2 action now built) | P10-Student-Record, P13-Student-Marks | 11 |
| `school-paste` | Check what was read waiting for Paste | P14-School-Paste | 12 |
| `school-student` | The School tab filtered to Dev | P14-School-Student | 12 |
| `school-item-window` | The exam's sheet with the Preparation row | P14-School-Item-Window | 12 |
| `school-item` | The exam's page with Who's chevrons (U44) | P10-School-Item | 12 |

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-14/db` | Database: the note day on the batch, the next step, the exam's window, the new kinds; `start_ai_generation` with `read_marks` and `not_on_track`; the seed's consents | none |
| 2 | 2 | `phase-14/models` | D67: the model for each kind of AI work in `api/models.json`, overridden by `AI_MODEL_<WORK_TYPE>`, an unknown name stopping the API; the price sheet and `bun cost` read it | none |
| 3 | 3 | `phase-14/api-answers` | The API's answers (D68): a lost database connection is not "sign in again"; a student's missing consent in its own words; the mock's skills grouped (U45) | none |
| 4 | 4 | `phase-14/api-parents` | The API: `/ai/make` note, can_do and not_on_track; `/ai/read-marks`; the models stop signing | none |
| main | | | `gh workflow run deploy` after PR 4: 0023 and 0024 up, the API at `main`'s head (Task 22) | |
| 5 | 5, 6, 7 | `phase-14/domain` | Domain: the note day, the week's facts, can-now-do, the cadence's decision, the next step in the plan, the signature on each message, the exam's window, the shapes | the six message sheets (the signature) |
| 6 | 8, 9 | `phase-14/data` | Data: notes kept and read, the log's kinds, channel and body, the note day and next step written, the window, the four API calls and the fake, the API client's answers; the write proofs | none |
| 7 | 10, 11, 12 | `phase-14/note-day` | Today: the note day's hero and Notes card, a held note's sheet, the note day's wheel, the Weekly notes row after the close | `today-note-day`, `today-note-held`, `today-note-day-change`, `today-after-close` |
| 8 | 13, 14 | `phase-14/note` | Artefacts: the weekly note and can-now-do, read, edited, written again, copied, sent in two languages, logged | `note` (both), `note-send`, `note-can-do`, `note-writing` |
| 9 | 15 | `phase-14/messages` | Students: the sent log with Held and Send now | `student-messages` |
| 10 | 16 | `phase-14/not-on-track` | Not on track: the next step chosen by the plan unless changed, the message to the parent, Today's caption | `student-not-on-track`, `student-next-step`, `student-tell-parent`, `today-not-on-track` |
| 11 | 17 | `phase-14/marks-photo` | Marks from a photo: a report card or a marked test read, the rows checked, saved, undone | `marks-reading`, `marks-confirm` (both), `marks-edit`, `student-marks` |
| 12 | 18 | `phase-14/school-leftovers` | U41 to U44 and two review minors: Paste without the prompt, the tab filtered to a student, the exam's window, Who's chevrons, the photo removed on a failed add, the reading refusals | `school-paste`, `school-student`, `school-item-window`, `school-item` |
| 13 | 23 | `phase-14/read-marks-model` | The read-marks default from the cost run | none |
| main | 19, 20, 21, 22, 23, 24 | | The boards' approval, the device tests, the hand runs, the deploy, the cost run, the review, TestFlight, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked, the pictures by
`bun shots <state>` and `bun pr-shots` (rule 2). PRs 11 and 12 build to the Phase 14 boards, which are approved before they
start (decision 30).

---

### Task 1: Migrations 0023 and 0024: the note day, the next step, the exam's window, the new kinds; the personal kinds' consent; the seed (PR 1)

**Files:**
- Create: `supabase/migrations/20261028000023_v2_parents_columns_kinds.sql`, `supabase/migrations/20261029000024_v2_ai_personal_kinds.sql`
- Modify: `supabase/tests/v2.test.ts` (a "parents" block), `supabase/seed.sql` (consents), `supabase/types.ts` (regenerated)

**Interfaces:**
- Produces: `classes.note_weekday smallint`, `classes.note_time time`; `students.next_step text`; `school_items.window_days
  integer`; `message_kind` value `not_on_track`; `message_channel` value `copied`; `ai_kind` values `not_on_track`,
  `read_marks`; `start_ai_generation(p_centre, p_kind, p_input, p_model, p_student default null)` unchanged in signature,
  with `read_marks` and `not_on_track` asking the student's consent.

- [ ] **Step 1: Write the failing tests** (`supabase/tests/v2.test.ts`, after the "school" block; the helpers `asMeera`,
  `rpc`, `otherCentre` are the file's):

```ts
describe("parents (0023, 0024)", () => {
  test("a batch keeps its note day; the default is none (the app reads Sunday 18:00)", async () => {
    const { data: before } = await asMeera.from("classes").select("note_weekday, note_time").eq("id", EVENING).single();
    expect(before).toEqual({ note_weekday: null, note_time: null });
    const { error } = await asMeera.from("classes").update({ note_weekday: 6, note_time: "18:00" }).eq("id", EVENING);
    expect(error).toBeNull();
    const { error: bad } = await asMeera.from("classes").update({ note_weekday: 8 }).eq("id", EVENING);
    expect(bad?.message).toContain("check");
  });

  test("a student's next step is one of five, or null for the plan's own", async () => {
    for (const step of ["tell_parent", "teach_again", "step_back", "add_to_checks", "leave", null]) {
      const { error } = await asMeera.from("students").update({ next_step: step }).eq("id", DEV);
      expect({ step, error }).toEqual({ step, error: null });
    }
    const { error } = await asMeera.from("students").update({ next_step: "shout" }).eq("id", DEV);
    expect(error?.message).toContain("check");
  });

  test("an exam's window is 3 to 60 days, or null for 14", async () => {
    const { error } = await asMeera.from("school_items").update({ window_days: 7 }).eq("id", SCIENCE_EXAM);
    expect(error).toBeNull();
    const { error: bad } = await asMeera.from("school_items").update({ window_days: 2 }).eq("id", SCIENCE_EXAM);
    expect(bad?.message).toContain("check");
  });

  test("a not-on-track message and a copied note are logged with their kind and channel", async () => {
    const { data, error } = await asMeera
      .from("message_log")
      .insert({ centre_id: CENTRE, student_id: DEV, kind: "not_on_track", language: "hi", body: "…" })
      .select("kind, channel")
      .single();
    expect(error).toBeNull();
    expect(data).toEqual({ kind: "not_on_track", channel: "whatsapp_link" });
    const copied = await asMeera
      .from("message_log")
      .insert({ centre_id: CENTRE, student_id: DEV, kind: "note", channel: "copied", language: "kn", body: "…" })
      .select("channel")
      .single();
    expect(copied.data).toEqual({ channel: "copied" });
  });

  test("start_ai_generation asks the student's consent for read_marks and not_on_track, as for a note", async () => {
    // Riya's parent has not agreed (the seed); Diya's has.
    for (const kind of ["read_marks", "not_on_track", "note", "can_do"]) {
      const refused = await rpc(asMeera, "start_ai_generation", { p_centre: CENTRE, p_kind: kind, p_input: {}, p_model: "m", p_student: RIYA });
      expect({ kind, error: refused.error?.message }).toEqual({ kind, error: expect.stringContaining("ai_consent_missing") });
      const allowed = await rpc(asMeera, "start_ai_generation", { p_centre: CENTRE, p_kind: kind, p_input: {}, p_model: "m", p_student: DIYA });
      expect({ kind, error: allowed.error }).toEqual({ kind, error: null });
    }
    const noStudent = await rpc(asMeera, "start_ai_generation", { p_centre: CENTRE, p_kind: "read_marks", p_input: {}, p_model: "m" });
    expect(noStudent.error?.message).toContain("ai_consent_missing");
  });

  test("read_marks and not_on_track count in the month's allowance, as the other V2 kinds do", async () => {
    const { data } = await asMeera.from("ai_generations").select("kind").in("kind", ["read_marks", "not_on_track"]);
    expect((data ?? []).length).toBeGreaterThan(0);
  });

  test("the seed records consent for Diya, Kavya and Rohan", async () => {
    const { data } = await asMeera.from("students").select("name, consent_at, consent_phone, consent_how, message_language").not("consent_at", "is", null).order("name");
    expect(data?.map((s) => [s.name, s.message_language, s.consent_how])).toEqual([
      ["Diya Pillai", "hi", "whatsapp"],
      ["Kavya Nair", "kn", "in_person"],
      ["Rohan Gupta", "hinglish", "call"],
    ]);
  });
});
```

- [ ] **Step 2: Run them to see them fail:** `cd supabase && bun test tests/v2.test.ts` → the seven fail (no column, no
  value, no consent in the seed).

- [ ] **Step 3: Write 0023**

```sql
-- Phase 14 (docs/spec-v2.md sections 5, 6 and 8; plan/phase-14-plan.md Task 1). Additive (D26): nullable columns, enum
-- values. Nothing from 0001 to 0022 is edited. The values added here are used by 0024 (a value cannot be used in the
-- transaction that adds it: 0012 and 0013 were two files for the same reason).

-- 1. The note day on the batch (P10-NoteDay-Change): the ISO weekday (1 Monday to 7 Sunday) and the time; null reads as
--    Sunday 18:00 in the app (Domain's NoteDay.default).
alter table public.classes
  add column note_weekday smallint check (note_weekday is null or note_weekday between 1 and 7),
  add column note_time time;

-- 2. The next step the tutor chose for a student not on track (P10-NextStep); null is the plan's own choice. The close
--    clears it when the stored status changes (the app's write).
alter table public.students
  add column next_step text check (next_step is null or next_step in ('tell_parent', 'teach_again', 'step_back', 'add_to_checks', 'leave'));

-- 3. A per-exam preparation window (U43; spec 6.6 "14 days unless the tutor sets another"); null reads as 14.
alter table public.school_items
  add column window_days integer check (window_days is null or window_days between 3 and 60);

-- 4. The message to the parent of a student not on track is its own kind (the sent log reads "Not on track"); a note
--    copied rather than opened in WhatsApp is its own channel.
alter type public.message_kind add value 'not_on_track';
alter type public.message_channel add value 'copied';

-- 5. Two kinds of AI work (D67): the parent's message when not on track, and reading a printed report card (apart from
--    marking a handwritten paper, check_paper).
alter type public.ai_kind add value 'not_on_track';
alter type public.ai_kind add value 'read_marks';
```

- [ ] **Step 4: Write 0024**

```sql
-- Phase 14 (plan/phase-14-plan.md Task 1). start_ai_generation replaced with the same signature: read_marks and
-- not_on_track name a student and need the parent's recorded consent (D62), and count in the month's allowance with the
-- other V2 kinds. 0021's body otherwise unchanged.
create or replace function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                                      p_student uuid default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report', 'not_on_track', 'read_marks']::public.ai_kind[];
  v_group public.ai_kind[];
  v_limit integer;
  v_count integer;
  v_started integer;
  v_since timestamptz;
  v_id uuid;
begin
  if not public.is_member(p_centre) then
    raise exception 'ai_not_a_member';
  end if;
  if p_kind = any (v_v1) then
    if p_kind in ('scan_register', 'check_paper', 'progress_note')
       and (select c.ai_consent_at from public.centres c where c.id = p_centre) is null then
      raise exception 'ai_consent_missing';
    end if;
    if p_kind = 'check_paper' and p_student is not null and (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null then
      raise exception 'ai_consent_missing';
    end if;
    if p_kind in ('paper', 'homework', 'worksheet', 'progress_note') then
      v_group := array['paper', 'homework', 'worksheet', 'progress_note']::public.ai_kind[];
      v_limit := 40;
    else
      v_group := array[p_kind];
      v_limit := 20;
    end if;
    v_since := now() - interval '24 hours';
  else
    if p_kind = any (v_personal) and (p_student is null or (
         select s.consent_at from public.students s where s.id = p_student and s.centre_id = p_centre) is null) then
      raise exception 'ai_consent_missing';
    end if;
    v_group := array['plan', 'sheet', 'worked_example', 'figure', 'brief', 'check', 'placement', 'mock', 'note', 'can_do',
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook', 'not_on_track', 'read_marks']::public.ai_kind[];
    v_limit := 600;
    v_since := date_trunc('month', now() at time zone 'Asia/Kolkata') at time zone 'Asia/Kolkata';
  end if;
  select count(*) filter (where g.status <> 'failed'), count(*) into v_count, v_started
    from public.ai_generations g
   where g.centre_id = p_centre and g.kind = any (v_group) and g.created_at >= v_since;
  if v_count >= v_limit or v_started >= v_limit + v_limit / 2 then
    raise exception 'ai_limit_reached' using detail = v_limit::text;
  end if;
  insert into public.ai_generations (centre_id, kind, input, model, status)
  values (p_centre, p_kind, p_input, p_model, 'pending')
  returning id into v_id;
  return v_id;
end $$;

revoke all on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) from public, anon;
grant execute on function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid) to authenticated;
```

  (The body's tail after `returning id` is 0021's: copy it from 0021 so nothing but the two arrays changes.)

- [ ] **Step 5: The seed:** after the students' insert, record consent for three parents so the hand runs need no psql:

```sql
-- Phase 14: three parents agreed (the note runs in Hindi, Kannada and Hinglish; Riya's and Dev's have not).
update public.students set consent_at = now() - interval '20 days', consent_phone = parent_phone, consent_how = 'whatsapp'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Diya Pillai';
update public.students set consent_at = now() - interval '18 days', consent_phone = parent_phone, consent_how = 'in_person'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Kavya Nair';
update public.students set consent_at = now() - interval '15 days', consent_phone = parent_phone, consent_how = 'call'
 where centre_id = '22222222-2222-2222-2222-222222222222' and name = 'Rohan Gupta';
```

  The allowance test needs a `read_marks` and a `not_on_track` row in the seed's `ai_generations`: add one of each (status
  ok, model `claude-sonnet-5-5` and `claude-haiku-5-5`, input `{}`), as the seed's other kinds are given.

- [ ] **Step 6: Run** `supabase db reset`, `supabase gen types typescript --local > types.ts`, `cd supabase && bun test tests`
  (the parents block green, the catalogue test green: no new table), `bun check --only=db`; commit.

```bash
git add supabase
git commit -m "0023 and 0024: the note day, the next step, the exam's window, the parents' kinds; read_marks and not_on_track ask consent; the seed's consents"
```

- [ ] **Step 7:** Open PR 1 (`phase-14/db`); merge when green.

### Task 2: D67: the model for each kind of AI work in one place (PR 2)

**Files:**
- Create: `api/models.json`, `tools/cost.ts`, `tools/cost.test.ts`
- Modify: `api/src/models.ts`, `api/src/index.ts`, `api/.env.example`, `api/tsconfig.json` (`resolveJsonModule` if not set),
  `api/src/prompts/check-paper.ts`, `scan-register.ts`, `paper.ts`, `homework.ts`, `worksheet.ts`, `progress-note.ts` (each
  asks `modelFor`), `api/src/routes/ai.ts` (check-paper's model from `modelFor("check_paper")`), `api/test/models.test.ts`,
  `api/test/entry.test.ts`, `api/test/ai.test.ts`, `ios/TutorCentralKit/Tests/DomainTests/PriceSheet.swift`,
  `package.json` (`cost`), `CLAUDE.md` (Commands), `api/CLAUDE.md`

**Interfaces:**

```ts
// api/models.json
{
  "rupeesPerDollar": 85,
  "models": {
    "claude-haiku-5-5": { "inputUsdPerMillion": 0.10, "outputUsdPerMillion": 0.50 },
    "claude-sonnet-5-5": { "inputUsdPerMillion": 2, "outputUsdPerMillion": 10 },
    "claude-opus-5-5": { "inputUsdPerMillion": 4, "outputUsdPerMillion": 20 }
  },
  "work": {
    "paper": "claude-sonnet-5-5", "homework": "claude-sonnet-5-5", "worksheet": "claude-sonnet-5-5", "progress_note": "claude-sonnet-5-5",
    "scan_register": "claude-opus-5-5", "check_paper": "claude-opus-5-5",
    "plan": "claude-sonnet-5-5", "sheet_to_5": "claude-haiku-5-5", "sheet_from_6": "claude-sonnet-5-5",
    "worked_example": "claude-sonnet-5-5", "figure": "claude-sonnet-5-5", "brief": "claude-sonnet-5-5", "mock": "claude-sonnet-5-5",
    "gap_report": "claude-sonnet-5-5", "parse_school": "claude-sonnet-5-5", "parse_textbook": "claude-sonnet-5-5",
    "check": "claude-haiku-5-5", "placement": "claude-haiku-5-5", "note": "claude-haiku-5-5", "can_do": "claude-haiku-5-5",
    "test_tomorrow": "claude-haiku-5-5", "not_on_track": "claude-haiku-5-5",
    "read_marks": "claude-sonnet-5-5"
  }
}
// api/src/models.ts
export type Model = keyof typeof table.models;                       // the three names
export type WorkType = keyof typeof table.work;                       // the ai kinds, with sheet_to_5 and sheet_from_6 for sheet
export const KNOWN_MODELS: readonly Model[];
/** The table with the environment's overrides applied; throws naming the variable on an unknown model. Called once at start. */
export function applyModelOverrides(env: Record<string, string | undefined>): void;
/** The model for a kind of work; a sheet needs the class (to class 5 one band, from class 6 the other). */
export function modelFor(work: Exclude<WorkType, "sheet_to_5" | "sheet_from_6"> | "sheet", classLevel?: ClassLevel): Model;
/** The work type a kind and class name (what the price sheet and bun cost key on). */
export function workTypeOf(kind: AIKind, classLevel?: ClassLevel): WorkType;
export function resetModelOverrides(): void;                           // tests only
// tools/cost.ts: bun cost [--since 30m|2h|1d|7d] [--kinds a,b]; prints kind, model, calls, tokens in, tokens out, ₹ from the local
// ai_generations (status ok) priced by api/models.json; costTable(rows, table) is the pure function cost.test.ts tests.
```

- [ ] **Step 1: Write the failing tests**

```ts
// api/test/models.test.ts (replaces the file)
import { afterEach, expect, test } from "bun:test";
import table from "../models.json" with { type: "json" };
import { applyModelOverrides, KNOWN_MODELS, modelFor, resetModelOverrides, workTypeOf } from "../src/models.js";
import type { AIKind } from "../src/db.js";

afterEach(() => resetModelOverrides());

const KINDS: AIKind[] = ["paper", "homework", "worksheet", "progress_note", "scan_register", "check_paper", "plan", "sheet", "worked_example", "figure", "brief", "check", "placement", "mock", "note", "can_do", "test_tomorrow", "gap_report", "parse_school", "parse_textbook", "not_on_track", "read_marks"];

test("the table names a model for each kind of work, the sheet in two bands (D67)", () => {
  for (const kind of KINDS) {
    const levels = kind === "sheet" ? (["5", "6"] as const) : ([undefined] as const);
    for (const level of levels) expect({ kind, level, model: KNOWN_MODELS.includes(modelFor(kind, level)) }).toEqual({ kind, level, model: true });
  }
  expect(workTypeOf("sheet", "lkg")).toBe("sheet_to_5");
  expect(workTypeOf("sheet", "6")).toBe("sheet_from_6");
  expect(workTypeOf("check_paper")).toBe("check_paper");
  expect(Object.keys(table.work).sort()).toEqual([...KINDS.filter((k) => k !== "sheet"), "sheet_from_6", "sheet_to_5"].sort());
});

test("the defaults are the spec's (D63) with marking apart from reading a report card (D67)", () => {
  expect(modelFor("check_paper")).toBe("claude-opus-5-5");
  expect(modelFor("read_marks")).toBe("claude-sonnet-5-5");
  expect(modelFor("note")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "5")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "6")).toBe("claude-sonnet-5-5");
});

test("AI_MODEL_<WORK_TYPE> overrides one work type and leaves the rest", () => {
  applyModelOverrides({ AI_MODEL_CHECK_PAPER: "claude-sonnet-5-5", AI_MODEL_SHEET_FROM_6: "claude-haiku-5-5" });
  expect(modelFor("check_paper")).toBe("claude-sonnet-5-5");
  expect(modelFor("sheet", "8")).toBe("claude-haiku-5-5");
  expect(modelFor("sheet", "3")).toBe("claude-haiku-5-5");
  expect(modelFor("mock")).toBe("claude-sonnet-5-5");
});

test("an unknown model name is refused at start, naming the variable and the known names", () => {
  expect(() => applyModelOverrides({ AI_MODEL_NOTE: "claude-5" })).toThrow(/AI_MODEL_NOTE names an unknown model: claude-5\. Known: claude-haiku-5-5, claude-sonnet-5-5, claude-opus-5-5/);
  expect(() => applyModelOverrides({ AI_MODEL_SOMETHING: "claude-opus-5-5" })).toThrow(/AI_MODEL_SOMETHING names no kind of work/);
  expect(modelFor("note")).toBe("claude-haiku-5-5");
});

test("the prices are the three models' and the rupee is 85", () => {
  expect(table.rupeesPerDollar).toBe(85);
  expect(Object.keys(table.models)).toEqual(["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]);
});
```

```ts
// api/test/ai.test.ts, added
test("AI_MODEL_NOTE reaches the next note call and its record (D67)", async () => {
  applyModelOverrides({ AI_MODEL_TEST_TOMORROW: "claude-opus-5-5" });
  try {
    const claude = fakeClaude({ answer: SAMPLE.test_tomorrow });
    const db = fakeDb();
    const r = await post(app(claude, db), "/ai/make", testTomorrowBody);
    expect(r.status).toBe(200);
    expect(claude.requests[0]?.model).toBe("claude-opus-5-5");
    expect(db.started[0]).toMatchObject({ kind: "test_tomorrow", model: "claude-opus-5-5" });
    expect(db.finished[0]).toMatchObject({ model: "claude-opus-5-5" });
  } finally {
    resetModelOverrides();
  }
});

test("check-paper's model comes from the table, not a constant", async () => {
  applyModelOverrides({ AI_MODEL_CHECK_PAPER: "claude-sonnet-5-5" });
  try {
    const claude = fakeClaude({ answer: SAMPLE.check_paper });
    const r = await post(app(claude, fakeDb()), "/ai/check-paper", { centreId, pages: [image], scheme: { kind: "typed", text: "Q1 2 marks" }, studentName: "Dev" });
    expect(r.status).toBe(200);
    expect(claude.requests[0]?.model).toBe("claude-sonnet-5-5");
  } finally {
    resetModelOverrides();
  }
});
```

```ts
// api/test/entry.test.ts, added to the "refuses to start" test's neighbourhood
test("an unknown AI_MODEL value stops the entry, so the deploy's smoke fails and no tutor's call does", async () => {
  const env = { PATH: process.env.PATH ?? "", ...SETTINGS, AI_MODEL_NOTE: "claude-5" };
  const run = Bun.spawnSync(["bun", "--no-env-file", "-e", "await import('./src/index.ts')"], { cwd: root, env, stderr: "pipe" });
  expect(run.exitCode).not.toBe(0);
  expect(new TextDecoder().decode(run.stderr)).toContain("AI_MODEL_NOTE names an unknown model: claude-5");
  const good = Bun.spawnSync(["bun", "--no-env-file", "-e", "await import('./src/index.ts')"], { cwd: root, env: { ...env, AI_MODEL_NOTE: "claude-sonnet-5-5" }, stderr: "pipe" });
  expect(good.exitCode).toBe(0);
});
```

```ts
// tools/cost.test.ts
import { expect, test } from "bun:test";
import { costTable } from "./cost";
import table from "../api/models.json" with { type: "json" };

test("rows are priced by kind and model from api/models.json, in rupees to the paisa", () => {
  const rows = [
    { kind: "check_paper", model: "claude-opus-5-5", tokens_in: 10_623, tokens_out: 2_690 },
    { kind: "mock", model: "claude-sonnet-5-5", tokens_in: 1_166, tokens_out: 4_399 },
    { kind: "note", model: "claude-haiku-5-5", tokens_in: 900, tokens_out: 300 },
    { kind: "note", model: "claude-haiku-5-5", tokens_in: 800, tokens_out: 250 },
  ];
  expect(costTable(rows, table)).toEqual([
    { kind: "check_paper", model: "claude-opus-5-5", calls: 1, tokensIn: 10_623, tokensOut: 2_690, rupees: 8.18 },
    { kind: "mock", model: "claude-sonnet-5-5", calls: 1, tokensIn: 1_166, tokensOut: 4_399, rupees: 3.94 },
    { kind: "note", model: "claude-haiku-5-5", calls: 2, tokensIn: 1_700, tokensOut: 550, rupees: 0.04 },
  ]);
});

test("a row whose model the table does not price is listed with no rupees, never priced wrong", () => {
  const [row] = costTable([{ kind: "note", model: "claude-5", tokens_in: 1, tokens_out: 1 }], table);
  expect(row).toMatchObject({ kind: "note", model: "claude-5", rupees: null });
});
```

```swift
// DomainTests/PriceSheet.swift: the sheet reads api/models.json (the file is found from the test bundle's source root, as
// TokenDocumentTests finds docs/design/design-tokens.md) for prices and models; a test holds it to the file.
@Test func thePriceSheetReadsTheModelTable() throws {
    let sheet = try PriceSheet.load()
    #expect(sheet.rupeesPerDollar == 85)
    #expect(sheet.model(for: .mock) == "claude-sonnet-5-5")
    #expect(sheet.model(for: .sheet(/* class 8 */)) == "claude-sonnet-5-5" && sheet.model(for: .sheet(/* class 2 */)) == "claude-haiku-5-5")
    #expect(sheet.price("claude-haiku-5-5")?.input == 0.10)
}
```

- [ ] **Step 2: Run them to see them fail:** `cd api && bun test models entry ai` (no `applyModelOverrides`, no JSON); `bun
  test tools/cost.test.ts` (no module); the Swift test (no `PriceSheet.load`).

- [ ] **Step 3: Implement.** `models.json` as the interface shows; `models.ts` imports it (`import table from
  "../models.json" with { type: "json" }`; `tsconfig` has `resolveJsonModule` and `module: NodeNext` accepts the
  attribute; if Vercel's build refuses the attribute, the fallback is a `models.ts` that embeds the same object with a
  test holding it equal to the file, and the ledger says so), keeps a module-level copy of `work`, and
  `applyModelOverrides(env)` walks `AI_MODEL_*` keys: the suffix lower-cased must be a key of `work` (else "names no kind
  of work") and the value one of `models`' keys (else "names an unknown model: <value>. Known: <list>"). `index.ts` calls
  `applyModelOverrides(process.env)` before building the app, beside `env(...)`. Each prompt asks `modelFor(<work>)`;
  `check-paper.ts`'s `request` takes no model and asks `modelFor("check_paper")`; `MARKING_MODEL` and the old `MODELS`
  table go. `.env.example` gains a comment block: "AI_MODEL_<WORK_TYPE> overrides the model for one kind of work at deploy
  (D67): the work types are api/models.json's keys upper-cased (AI_MODEL_CHECK_PAPER, AI_MODEL_SHEET_FROM_6). A value that
  is not one of its models stops the API at start." `tools/cost.ts`: reads `--since` (default `30m`), runs `psql
  "$DATABASE_URL"` (default `postgresql://postgres:postgres@127.0.0.1:54322/postgres`) for `select kind, model, tokens_in,
  tokens_out from public.ai_generations where status = 'ok' and created_at > now() - interval '<since>'`, prices through
  `costTable`, prints a table and the total; `package.json` gains `"cost": "bun tools/cost.ts"`; `CLAUDE.md` Commands gains
  the row. `PriceSheet.swift` loads the JSON (`PriceSheet.load()` with `rupeesPerDollar`, `model(for:)`, `price(_:)`);
  `rupees(_:)` uses them; the typical tokens stay the measured ones.

- [ ] **Step 4: Run the tests; `bun check --only=tools,api,ios`; commit.**

```bash
git add api tools package.json CLAUDE.md ios/TutorCentralKit/Tests/DomainTests/PriceSheet.swift
git commit -m "D67: the model for each kind of AI work in api/models.json, overridden by AI_MODEL_<WORK_TYPE>, an unknown name stopping the API; the price sheet and bun cost read it"
```

- [ ] **Step 5:** Open PR 2 (`phase-14/models`); merge when green. The ledger notes the owner's words ("env vars etc.").

### Task 3: The API's answers (D68): a lost database connection, a student's missing consent, the mock's skills (PR 3)

**Files:**
- Modify: `api/src/auth.ts`, `api/src/index.ts`, `api/src/errors.ts`, `api/src/routes/common.ts`, `api/src/db.ts`
  (`DbFailure.reason` adds `student_consent`), `api/src/db-fake.ts`, `api/src/prompts/mock.ts`, `api/src/claude-fake.ts`
  (the mock's skills), `api/test/auth.test.ts`, `api/test/ai.test.ts`, `api/test/v2.test.ts`, `api/test/prompts.test.ts`,
  `api/CLAUDE.md`

**Interfaces:**

```ts
// auth.ts
export type Verify = (token: string) => Promise<{ id: string } | null | "unreachable">;
// requireUser: null → 401 { error: "sign in again" }; "unreachable" (or a thrown verifier) → 503 { error: "Couldn't reach the service. Try again.", reason: "unreachable" }.
// index.ts: verify answers "unreachable" when getUser throws (a fetch failure) or its error has status >= 500 or none; null for a 4xx (an expired or malformed token).
// errors.ts: consent(studentName?: string): a name → { status: 403, body: { error: `${first(studentName)}'s parent hasn't agreed yet.`, reason: "student_consent" } }; none → the centre's words as today.
// db.ts: start throws DbFailure("student_consent") when the message includes ai_consent_missing and a student was named; "consent" otherwise. Call gains studentName?: string so run can word it.
// prompts/mock.ts: "Choose two to six skills across the paper, each one of the portions' skills (a chapter's main ideas, not one per question); each question names one of them in its skill field, so several questions share a skill."
```

- [ ] **Step 1: Write the failing tests**

```ts
// api/test/auth.test.ts, added
test("an unreachable Supabase answers 503 in connection words, not 401 'sign in again'", async () => {
  const app = new Hono<Vars>();
  app.use("/ai/*", makeRequireUser(async () => "unreachable"));
  app.get("/ai/x", (c) => c.json({ ok: true }));
  const r = await app.request("/ai/x", { headers: { authorization: "Bearer good" } });
  expect(r.status).toBe(503);
  expect(await r.json()).toEqual({ error: "Couldn't reach the service. Try again.", reason: "unreachable" });
  const thrown = new Hono<Vars>();
  thrown.use("/ai/*", makeRequireUser(async () => { throw new Error("fetch failed"); }));
  thrown.get("/ai/x", (c) => c.json({ ok: true }));
  expect((await thrown.request("/ai/x", { headers: { authorization: "Bearer good" } })).status).toBe(503);
});

test("an expired or malformed token is still 401", async () => {
  const app = new Hono<Vars>();
  app.use("/ai/*", makeRequireUser(async () => null));
  app.get("/ai/x", (c) => c.json({ ok: true }));
  expect((await app.request("/ai/x", { headers: { authorization: "Bearer old" } })).status).toBe(401);
});

// api/test/ai.test.ts, added (index.ts's verifier is tested through a fake supabase client factory it takes as an option: makeVerify(createClient))
test("the verifier tells a 4xx (sign in again) from a network failure or a 5xx (unreachable)", async () => {
  const expired = makeVerify(() => ({ auth: { getUser: async () => ({ data: { user: null }, error: { status: 401, message: "expired" } }) } }));
  expect(await expired("t")).toBeNull();
  const down = makeVerify(() => ({ auth: { getUser: async () => ({ data: { user: null }, error: { status: 502, message: "bad gateway" } }) } }));
  expect(await down("t")).toBe("unreachable");
  const failed = makeVerify(() => ({ auth: { getUser: async () => { throw new TypeError("fetch failed"); } } }));
  expect(await failed("t")).toBe("unreachable");
  const good = makeVerify(() => ({ auth: { getUser: async () => ({ data: { user: { id: "u1" } }, error: null }) } }));
  expect(await good("t")).toEqual({ id: "u1" });
});

test("a named student's missing consent answers in the student's words, the centre's missing consent in the centre's", async () => {
  const mockBody = { centreId, pages: [image], scheme: { kind: "mock", generationId: MOCK_ID }, studentName: "Diya Pillai", studentId: "77777777-7777-7777-7777-777777777777" };
  const r = await post(app(undefined, fakeDb({ studentConsent: false, generations: { [MOCK_ID]: { kind: "mock", output: JSON.stringify(SAMPLE.mock) } } })), "/ai/check-paper", mockBody);
  expect(r.status).toBe(403);
  expect(await r.json()).toEqual({ error: "Diya's parent hasn't agreed yet.", reason: "student_consent" });
  const centre = await post(app(undefined, fakeDb({ consent: false })), "/ai/scan-register", { centreId, ...image });
  expect(await centre.json()).toEqual({ error: "Agree to the notice before the first photo.", reason: "consent" });
});

// api/test/prompts.test.ts, added (U45)
test("the mock asks for two to six skills across the paper so By skill groups", () => {
  const r = mockRequest({ kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions", "Acids, bases and salts"], pattern: { marks: 25, durationMinutes: 40 } });
  expect(r.system).toContain("two to six skills across the paper");
  expect(r.system).toContain("several questions share a skill");
  const skills = new Set(SAMPLE.mock.sections.flatMap((s) => s.questions.map((q) => q.skill)));
  expect(skills.size).toBeGreaterThanOrEqual(2);
  expect(skills.size).toBeLessThanOrEqual(6);
});
```

- [ ] **Step 2: Run them to see them fail** (`cd api && bun test auth ai prompts`).

- [ ] **Step 3: Implement** as the interfaces say. `index.ts` exports `makeVerify(createClient)` (the entry test still finds
  `src/index.ts` as the one file importing "hono"; `makeVerify` lives in a new `src/verify.ts` so the entry stays small and
  testable). `run` passes `studentName` from the body for the personal kinds and check-paper's mock, and `errors.consent`
  words it. The fake's mock sample already names four skills over twelve questions; the prompt's words change.

- [ ] **Step 4: Run the tests; `bun run check`; `bun check --only=api`; commit.**

```bash
git add api
git commit -m "The API's answers: a lost database connection is 503 in connection words; a student's missing consent in the student's words; the mock's skills grouped (U45)"
```

- [ ] **Step 5:** Open PR 3 (`phase-14/api-answers`); merge when green.

### Task 4: The API: `/ai/make` note, can_do and not_on_track; `/ai/read-marks`; the models stop signing (PR 4)

**Files:**
- Create: `api/src/prompts/note.ts`, `can-do.ts`, `not-on-track.ts`, `read-marks.ts`
- Modify: `api/src/schemas.ts`, `api/src/routes/v2.ts`, `api/src/db.ts` (`V2Kind`), `api/src/claude-fake.ts`,
  `api/src/errors.ts`, `api/src/prompts/test-tomorrow.ts`, `api/test/v2.test.ts`, `api/test/schemas.test.ts`,
  `api/test/prompts.test.ts`, `api/test/claude-fake.test.ts`, `api/test/app.test.ts` (the 501 skeleton test for `can_do`
  becomes a 200), `api/CLAUDE.md`

**Interfaces:**

```ts
// schemas.ts
const Parent = { parentName: z.string().max(80).optional(), centreName: z.string().max(120), language: Language, classLevel: ClassLevel };
// MakeInput gains, in place of the Phase 10 skeleton shapes:
z.object({ ...V2, kind: z.literal("note"), ...Student, ...Parent,
  week: z.object({
    monday: Day,
    taught: Skills.max(6),                       // [] when nothing new
    right: z.string().max(120).optional(),       // "8 of 12 checks", "8 of 12 checks · 14 of 25 on Unit test 2"
    practise: Skills.max(3),
    coming: z.array(z.string().max(200)).max(3),
    attendance: z.string().max(80).optional(),   // "absent 2 of 3 classes", "absent all week (3 classes)"
  }) }),
z.object({ ...V2, kind: z.literal("can_do"), ...Student, ...Parent,
  ladder: z.object({
    movedUp: z.array(z.object({ area: z.enum(["reading", "writing", "numbers"]), step: z.string().max(40) })).max(3),
    canDo: z.array(z.string().max(80)).min(1).max(4),
    atHome: z.string().max(160),
    next: z.array(z.string().max(80)).max(3),
  }) }),
z.object({ ...V2, kind: z.literal("not_on_track"), ...Student, ...Parent,
  hard: z.array(Name).min(1).max(3), reasons: z.array(z.string().max(200)).max(4), doing: z.string().max(200), atHome: z.string().max(200).optional() }),
export const MessageOutput = z.object({ message: z.string().min(1).max(600), english: z.string().min(1).max(600) });
export const TestTomorrowOutput = MessageOutput;
export const ReadMarksInput = z.object({ ...V2, studentId: z.guid(), studentName: z.string().min(1).max(80), pages: z.array(Image).min(1).max(2), subjects: z.array(Subject).max(12).optional() })
  .refine((v) => v.pages.reduce((n, p) => n + p.imageBase64.length, 0) <= 4_200_000, { message: "pages: too many characters in one request" });
export const ReadMarksOutput = z.object({ marks: z.array(z.object({ subject: Subject, test: z.string().min(1).max(120), date: Day.nullable(), score: z.number().min(0), max: z.number().min(1) })).max(12) });
// db.ts: V2Kind gains "not_on_track" | "read_marks".
// routes/v2.ts: /make note → run(kind "note", student v.studentId); can_do → "can_do"; not_on_track → "not_on_track"; POST /read-marks:
//   pages decoded (decodeImage each), input { kind: "read_marks", pages, bytes, studentName }, request readMarksRequest(pages, studentName, subjects),
//   student v.studentId, empty: (read) => read.marks.length === 0.
// errors.ts REFUSED gains read_marks: "Couldn't read any marks from this photo. Try a flatter, brighter one."
// claude-fake.ts: SAMPLE.note (the board's Hindi note and English), SAMPLE.can_do (the board's Kannada can-now-do), SAMPLE.not_on_track
//   (the board's Hindi message), SAMPLE.read_marks ({ marks: [Mathematics Unit test 2 2026-09-28 14/25, Science Unit test 2 2026-09-29 18/25, Hindi Unit test 2 null 11/25] });
//   kindOf: "report card" in the system → read_marks (before the images branch's check_paper); "weekly note" → note; "can now do" → can_do; "finding" → not_on_track.
```

- [ ] **Step 1: Write the failing tests**

```ts
// api/test/v2.test.ts, added
const student = { studentId: "77777777-7777-7777-7777-777777777777", studentName: "Dev Kumar", tutorName: "Meera Nair", parentName: "Ramesh Kumar", centreName: "Bright Minds Tuition", classLevel: "8" };
const week = { monday: "2026-10-05", taught: ["Balancing equations", "Types of reactions"], right: "8 of 12 checks · all of Section A on the mock", practise: ["The numbers in front of a formula"], coming: ["Acids, bases and salts", "the unit test on Fri 16 Oct"], attendance: "absent 2 of 3 classes" };

test("make note writes the week's note in the parent's language with the English beside it, on Haiku, with the student's consent", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { message: string; english: string } };
  expect(body.result.message).toMatch(/^नमस्ते/);
  expect(body.result.english).toContain("Dev learnt to balance chemical equations");
  expect(db.started[0]).toMatchObject({ kind: "note", model: "claude-haiku-5-5", student: student.studentId });
  expect(claude.requests[0]?.text).toContain("Taught: Balancing equations, Types of reactions.");
  expect(claude.requests[0]?.text).toContain("Attendance: absent 2 of 3 classes.");
  expect(claude.requests[0]?.system).not.toContain("signed");
});

test("a note for a student whose parent has not agreed is refused before any call, in the student's words", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  const r = await post(app(claude, fakeDb({ studentConsent: false })), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(r.status).toBe(403);
  expect(await r.json()).toEqual({ error: "Dev's parent hasn't agreed yet.", reason: "student_consent" });
  expect(claude.requests).toHaveLength(0);
});

test("a note with no taught skills leaves that sentence out and keeps the attendance line", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  await post(app(claude, fakeDb()), "/ai/make", { kind: "note", centreId, ...student, language: "en", week: { ...week, taught: [], right: undefined, attendance: "absent all week (3 classes)" } });
  const text = claude.requests[0]?.text ?? "";
  expect(text).not.toContain("Taught:");
  expect(text).not.toContain("Got right:");
  expect(text).toContain("Attendance: absent all week (3 classes).");
  expect(claude.requests[0]?.system).toContain("leave out");
});

test("make can_do writes from the ladder, naming what moved up, what the student can do, what to do at home and what is next", async () => {
  const claude = fakeClaude({ answer: SAMPLE.can_do });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", { kind: "can_do", centreId, ...student, studentName: "Sahil Verma", parentName: "Deepak Verma", classLevel: "2", language: "kn",
    ladder: { movedUp: [{ area: "reading", step: "Sentences" }], canDo: ["Read short sentences", "Count to 99"], atHome: "One page a day from the picture book", next: ["Writing words", "Adding to 20"] } });
  expect(r.status).toBe(200);
  expect(((await r.json()) as { result: { message: string } }).result.message).toMatch(/^ನಮಸ್ಕಾರ/);
  expect(db.started[0]).toMatchObject({ kind: "can_do", model: "claude-haiku-5-5" });
  expect(claude.requests[0]?.text).toContain("Moved up this week: reading to Sentences.");
});

test("make not_on_track writes what is hard, what we are doing and what helps at home, and asks for a talk", async () => {
  const claude = fakeClaude({ answer: SAMPLE.not_on_track });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", { kind: "not_on_track", centreId, ...student, language: "hi",
    hard: ["Balancing equations"], reasons: ["3 of 10 on the mock", "absent twice in four weeks"], doing: "the worked example in the next class", atHome: "ten minutes of practice each evening" });
  expect(r.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "not_on_track", model: "claude-haiku-5-5", student: student.studentId });
  expect(claude.requests[0]?.system).toContain("five minutes");
});

test("the three message kinds hold the model to 500 characters and the schema to 600, with no signature", async () => {
  const claude = fakeClaude({ answer: SAMPLE.note });
  await post(app(claude, fakeDb()), "/ai/make", { kind: "note", centreId, ...student, language: "hi", week });
  expect(claude.requests[0]?.system).toContain("at most 500 characters");
  expect(claude.requests[0]?.system).toContain("no signature");
  expect(MessageOutput.safeParse({ message: "x".repeat(601), english: "y" }).success).toBe(false);
});

test("read-marks reads a report card into rows the tutor checks, records the pages and never the image, with the student's consent", async () => {
  const claude = fakeClaude({ answer: SAMPLE.read_marks });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth Reddy", pages: [image], subjects: ["Mathematics", "Science"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { marks: { subject: string; test: string; date: string | null; score: number; max: number }[] } };
  expect(body.result.marks[0]).toEqual({ subject: "Mathematics", test: "Unit test 2", date: "2026-09-28", score: 14, max: 25 });
  expect(body.result.marks[2]?.date).toBeNull();
  expect(db.started[0]).toMatchObject({ kind: "read_marks", model: "claude-sonnet-5-5", student: student.studentId, input: { pages: 1, bytes: 8 } });
  expect(JSON.stringify(db.started[0])).not.toContain(jpeg);
  expect(claude.requests[0]?.system).toContain("report card");
  expect(claude.requests[0]?.text).toContain("Subjects the student takes here: Mathematics, Science.");
});

test("read-marks refuses a photo with no marks in words, and a student without consent before any call", async () => {
  const none = await post(app(fakeClaude({ answer: { marks: [] } }), fakeDb()), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image] });
  expect(none.status).toBe(422);
  expect(await none.json()).toEqual({ error: "Couldn't read any marks from this photo. Try a flatter, brighter one." });
  const claude = fakeClaude({ answer: SAMPLE.read_marks });
  const refused = await post(app(claude, fakeDb({ studentConsent: false })), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image] });
  expect(refused.status).toBe(403);
  expect(claude.requests).toHaveLength(0);
  const three = await post(app(undefined, fakeDb()), "/ai/read-marks", { centreId, studentId: student.studentId, studentName: "Hemanth", pages: [image, image, image] });
  expect(three.status).toBe(400);
});

test("test tomorrow no longer asks the model to sign (the app signs each message once)", async () => {
  const claude = fakeClaude({ answer: SAMPLE.test_tomorrow });
  await post(app(claude, fakeDb()), "/ai/make", testTomorrowBody);
  expect(claude.requests[0]?.system).toContain("no signature");
  expect(claude.requests[0]?.text).not.toContain("Signed:");
});
```

```ts
// api/test/claude-fake.test.ts, added
test("the fake tells the four parents' kinds apart by their words", () => {
  expect(kindOf(noteRequest({ ...noteInput }))).toBe("note");
  expect(kindOf(canDoRequest({ ...canDoInput }))).toBe("can_do");
  expect(kindOf(notOnTrackRequest({ ...notOnTrackInput }))).toBe("not_on_track");
  expect(kindOf(readMarksRequest([page], "Hemanth", []))).toBe("read_marks");
  expect(kindOf(checkRequest([page], "scheme", "Dev"))).toBe("check_paper");
});
```

- [ ] **Step 2: Run them to see them fail** (`cd api && bun test v2 claude-fake schemas prompts app`): no `note.ts`, the
  skeleton shapes refuse the bodies, `can_do` answers 501.

- [ ] **Step 3: Implement.** The three prompts share `VOICE` and a system block: "You write a short WhatsApp message from a
  tutor to a parent, in the language asked (Hindi in Devanagari, Kannada in Kannada script, Hinglish in Latin letters,
  English in English). Use only the facts given; leave out any fact that is missing or empty, never invent one. Polite,
  warm, at most 500 characters, sentence case, no exclamation marks. Also give the same message in English for the tutor to
  read (for English, repeat it). End with the last sentence: no signature, no name, no sign-off (the app adds the
  signature)." The note's text lines: `Language:`, `Student:` (first name), `Parent:` (first name, when given), `Class:`,
  `Week of <spoken Monday>`, `Taught: a, b.` (left out when empty), `Got right: …` (left out when missing), `To practise:
  …` (left out when empty), `Coming: …` (left out when empty), `Attendance: …` (left out when missing), then "Write the
  week's note: what was taught, what the student got right, what to practise at home and what is coming." Can-now-do's
  lines: `Moved up this week: reading to Sentences.` (left out when none), `Can now do: …`, `At home: …`, `Next: …`, then
  "Write the note: what the student can now do, one thing to do at home, what comes next." Not on track's system adds "Say
  what is hard, what we are doing in class, what helps at home, and ask for a five-minute talk this week; kind and plain,
  never blaming the student." with lines `Finding hard: …`, `Why: …`, `What we are doing: …`, `At home: …`. The reader's
  system: "You read a printed school report card or a marked test paper photographed by a tutor. Give one row per
  subject's test you can read: the subject as printed (matched to the tutor's subject names when one fits), the test's
  name, the date when printed (ISO), the score and the maximum. Leave out a row you cannot read; give none when the photo
  holds no marks." with the text `Student: <name>.`, `Subjects the student takes here: a, b.` (when given), "Read the
  marks on these pages."; `effort: "medium"`, `modelFor("read_marks")`. Test tomorrow's prompt drops its signature
  sentence and the `Signed:` line; its fake sample drops the two signature lines (the app signs).

- [ ] **Step 4: Run the tests; `bun run check`; `bun check --only=api`; commit.**

```bash
git add api
git commit -m "The API: /ai/make note, can_do and not_on_track; /ai/read-marks; the models stop signing"
```

- [ ] **Step 5:** Open PR 4 (`phase-14/api-parents`) after PR 3 merges; merge when green. Then Task 22's first deploy.

### Task 5: Domain: the note day, the next step, the signature on each message, the shapes (PR 5)

**Files:**
- Create: `Sources/Domain/Parents/NoteDay.swift`, `Parents/NextStep.swift`, `Parents/MessageSignature.swift`,
  `Parents/NoteContent.swift`
- Modify: `Sources/Domain/Classroom.swift` (`noteDay: NoteDay?`, decoded as nil from an older cache), `Student.swift`
  (`nextStep: NextStep?`), `Record/RecordTypes.swift` (`MessageKind.notOnTrack = "not_on_track"` with the title "Not on
  track"; `MessageChannel`; `MessageEntry.channel`, `body`), `Record/Mark.swift` (`ReadMark`), `School/SchoolItem.swift`
  (`windowDays: Int?`), `School/ExamPreparation.swift` (`window(_ exam:)`, `isWithinWindow` by its calendar),
  `Plan/Artefact.swift` (`.note(NoteContent)` in `ArtefactContent`), `Queue/OfflineRefusal.swift`, `FeeMessage.swift`,
  `AbsenceMessage.swift`, `Record/ConsentMessage.swift`, `School/ForwardAskMessage.swift`, `School/TestTomorrowMessage.swift`
- Test: `DomainTests/NoteDayTests.swift`, `NextStepTests.swift`, `MessageSignatureTests.swift`, `ExamWindowTests.swift`,
  `OfflineRefusalTests.swift`, `ArtefactContentTests.swift`

**Interfaces:**

```swift
public struct NoteDay: Hashable, Sendable, Codable {
    public let weekday: Weekday            // ISO, Monday 1 to Sunday 7 (classes.note_weekday)
    public let time: TimeOfDay             // classes.note_time
    public static let `default` = NoteDay(weekday: .sunday, time: TimeOfDay(hour: 18, minute: 0))
    public static let choices: [NoteDay]   // Friday 18:00, Saturday 18:00, Sunday 18:00, Sunday 20:00, Monday 08:00 (P10-NoteDay-Change)
    public var title: String               // "Sunday 18:00"
    /// True from the note time on the note weekday to the end of the following day (a tutor who misses the evening sees the notes next day).
    public func isOn(at now: Date, calendar: Calendar) -> Bool
    /// The note day this note belongs to: today when on, else the latest note day at or before `now`.
    public func noteDay(for now: Date, calendar: Calendar) -> Day
    /// The week a note covers: the Monday on or before the note day, to the note day.
    public static func week(ending noteDay: Day, calendar: Calendar) -> ClosedRange<Day>
}
public enum NextStep: String, CaseIterable, Hashable, Sendable, Codable {
    case tellParent = "tell_parent", teachAgain = "teach_again", stepBack = "step_back", addToChecks = "add_to_checks", leave
    public var title: String               // "Tell the parent, then teach again", "Teach again with the worked example", "Step back to what comes before", "Add it to the checks", "Leave it for now"
    /// The row's second line (P10-NextStep): the language, the skill and the skill before it fill the blanks.
    public func meaning(language: MessageLanguage, skill: String?, before: String?) -> String
    /// The plan's own choice from the stored status (the ticked row when the tutor has chosen none).
    public static func planned(_ status: TrackStatus) -> NextStep   // notOnTrack → tellParent, watch → teachAgain, else leave
    /// The tracking card's Next sentence for the effective step and the current skill.
    public func nextLine(skill: String?, before: String?) -> String
}
public extension Student { var effectiveStep: NextStep { nextStep ?? NextStep.planned(trackStatus) } }
public enum MessageSignature {
    public static let madeWith = "Made with Tutor Central"
    /// "\n\n<tutor>\n<centre>\nMade with Tutor Central" (the tutor's line left out when there is no name).
    public static func text(tutorName: String?, centreName: String) -> String
    public static func signed(_ body: String, tutorName: String?, centreName: String) -> String
}
public enum MessageChannel: String, Hashable, Sendable, Codable { case whatsAppLink = "whatsapp_link", copied }
public struct MessageEntry { … public let channel: MessageChannel; public let body: String? }   // channel defaults .whatsAppLink, body nil, in init and decoding
public struct NoteContent: Hashable, Sendable, Codable {
    public let message: String; public let english: String?; public let language: MessageLanguage
    public let weekMonday: Day; public let facts: [FactRow]; public let generationID: UUID?
    public struct FactRow: Hashable, Sendable, Codable { public let label: String; public let fact: String; public let symbol: String }
}
public struct ReadMark: Hashable, Sendable, Codable { public var subject: String; public var test: String; public var date: Day?; public var score: Int; public var max: Int }
// ExamPreparation
public static func window(_ exam: SchoolItem) -> Int              // exam.windowDays ?? windowDays (14)
public static func isWithinWindow(_ exam: SchoolItem, today: Day, calendar: Calendar) -> Bool   // today.days(to: exam.date, calendar:) in 0...window(exam)
// OfflineRefusal: .readShared ("You're offline. What was shared waits here until you're back online."), .readPasted ("You're offline. Reading what you pasted needs a connection. Try again when you're back online."), .readPhoto (the same for a photo), .note, .readMarks ("You're offline. Reading the marks needs a connection."), .notOnTrack ("You're offline. Sending needs a connection to note it on the student's page."), .noteDay ("You're offline. Changing the note day needs a connection."), .nextStep ("You're offline. Changing the next step needs a connection."), .saveMarks ("You're offline. Saving the marks needs a connection. They're still here.")
```

- [ ] **Step 1: Write the failing tests**

```swift
struct NoteDayTests {
    let calendar = DayHeading.india

    @Test func theDefaultIsSundayAtSix() {
        #expect(NoteDay.default.title == "Sunday 18:00")
        #expect(NoteDay.choices.map(\.title) == ["Friday 18:00", "Saturday 18:00", "Sunday 18:00", "Sunday 20:00", "Monday 08:00"])
    }

    @Test func theNoteDayIsOnFromItsTimeToTheEndOfTheNextDay() {
        let day = NoteDay.default
        #expect(!day.isOn(at: india(2026, 10, 11, 17, 59), calendar: calendar))
        #expect(day.isOn(at: india(2026, 10, 11, 18, 0), calendar: calendar))
        #expect(day.isOn(at: india(2026, 10, 12, 23, 59), calendar: calendar))
        #expect(!day.isOn(at: india(2026, 10, 13, 0, 1), calendar: calendar))
    }

    @Test func theWeekEndsOnTheNoteDayWhateverTheWeekday() {
        let saturday = NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0))
        let week = NoteDay.week(ending: saturday.noteDay(for: india(2026, 10, 10, 19, 0), calendar: calendar), calendar: calendar)
        #expect(week == Day(year: 2026, month: 10, day: 5) ... Day(year: 2026, month: 10, day: 10))
        let monday = NoteDay(weekday: .monday, time: TimeOfDay(hour: 8, minute: 0))
        let mondayWeek = NoteDay.week(ending: monday.noteDay(for: india(2026, 10, 12, 9, 0), calendar: calendar), calendar: calendar)
        #expect(mondayWeek == Day(year: 2026, month: 10, day: 6) ... Day(year: 2026, month: 10, day: 12))
    }

    @Test func beforeTheNoteTimeTheNoteDayIsLastWeeks() {
        let day = NoteDay.default.noteDay(for: india(2026, 10, 11, 12, 0), calendar: calendar)
        #expect(day == Day(year: 2026, month: 10, day: 4))
    }
}

struct NextStepTests {
    @Test func thePlanChoosesByStatus() {
        #expect(NextStep.planned(.notOnTrack) == .tellParent)
        #expect(NextStep.planned(.watch) == .teachAgain)
        #expect(NextStep.planned(.onTrack) == .leave && NextStep.planned(.notKnown) == .leave)
    }

    @Test func theTutorsChoiceHoldsOverThePlans() {
        var dev = ParentFixtures.dev
        dev.trackStatus = .notOnTrack
        #expect(dev.effectiveStep == .tellParent)
        dev.nextStep = .stepBack
        #expect(dev.effectiveStep == .stepBack)
    }

    @Test func theRowsReadAsTheBoard() {
        #expect(NextStep.tellParent.meaning(language: .hindi, skill: "Balancing equations", before: "Counting atoms in a formula") == "A message in Hindi; the worked example in the next class")
        #expect(NextStep.teachAgain.meaning(language: .hindi, skill: "Balancing equations", before: nil) == "Balancing equations in the next class, a set after")
        #expect(NextStep.stepBack.meaning(language: .hindi, skill: "Balancing equations", before: "Counting atoms in a formula") == "Counting atoms in a formula, then balancing equations")
        #expect(NextStep.addToChecks.meaning(language: .hindi, skill: nil, before: nil) == "Three questions on it, spaced over the next weeks")
        #expect(NextStep.leave.meaning(language: .hindi, skill: nil, before: nil) == "The plan carries on; the status stays")
        #expect(NextStep.tellParent.nextLine(skill: "Balancing equations", before: nil) == "Tell the parent, then teach again with the worked example.")
        #expect(NextStep.stepBack.nextLine(skill: "Balancing equations", before: "Counting atoms in a formula") == "Step back to Counting atoms in a formula, then Balancing equations.")
    }
}

struct MessageSignatureTests {
    @Test func theSignatureIsTheTutorTheCentreAndMadeWith() {
        #expect(MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition") == "\n\nMeera Nair\nBright Minds Tuition\nMade with Tutor Central")
        #expect(MessageSignature.text(tutorName: nil, centreName: "Bright Minds Tuition") == "\n\nBright Minds Tuition\nMade with Tutor Central")
    }

    @Test func eachMessageTheAppWritesEndsWithIt() {
        let signature = MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        let messages = [
            FeeMessage.reminder(ParentFixtures.feeContext).text,
            FeeMessage.receipt(ParentFixtures.feeContext).text,
            AbsenceMessage(studentName: "Nikhil Das", parentName: "Asha Das", day: Day(year: 2026, month: 10, day: 7), tutorName: "Meera Nair", centreName: "Bright Minds Tuition").text,
            ConsentMessage.text(studentName: "Dev Kumar", parentName: "Ramesh Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition"),
            ForwardAskMessage.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition"),
            ParentFixtures.testTomorrow.text,
        ]
        for message in messages {
            #expect(message.hasSuffix(signature), "\(message.suffix(60))")
            #expect(message.components(separatedBy: MessageSignature.madeWith).count == 2)
        }
    }
}

struct ExamWindowTests {
    @Test func anExamsOwnWindowReplacesTheFourteen() {
        var exam = ParentFixtures.scienceExam          // Fri 16 Oct
        #expect(ExamPreparation.window(exam) == 14)
        exam.windowDays = 7
        #expect(ExamPreparation.window(exam) == 7)
        let today = Day(year: 2026, month: 10, day: 7)
        #expect(!ExamPreparation.isWithinWindow(exam, today: today, calendar: DayHeading.india))
        #expect(ExamPreparation.isWithinWindow(exam, today: Day(year: 2026, month: 10, day: 9), calendar: DayHeading.india))
    }

    @Test func theWindowCountsDaysInTheCalendarItIsGiven() {
        // A calendar whose day starts at 06:00 would count Fri 16 Oct from Wed 7 Oct as nine days, as India's does.
        let exam = ParentFixtures.scienceExam
        #expect(ExamPreparation.isWithinWindow(exam, today: Day(year: 2026, month: 10, day: 2), calendar: DayHeading.india))
        #expect(!ExamPreparation.isWithinWindow(exam, today: Day(year: 2026, month: 10, day: 1), calendar: DayHeading.india))
    }
}

struct OfflineRefusalTests {   // added cases
    @Test func theThreeReadingRefusalsSayWhatWaits() {
        #expect(OfflineRefusal.words(for: .readShared).contains("waits here"))
        #expect(!OfflineRefusal.words(for: .readPasted).contains("waits here") && OfflineRefusal.words(for: .readPasted).contains("Try again"))
        #expect(!OfflineRefusal.words(for: .readPhoto).contains("waits here"))
        for kind in [OfflineRefusal.Kind.note, .readMarks, .notOnTrack, .noteDay, .nextStep, .saveMarks] {
            #expect(OfflineRefusal.words(for: kind).hasPrefix("You're offline."))
        }
    }
}

struct ArtefactContentTests {   // added
    @Test func aNoteRoundTripsWithItsFactsAndWeek() throws {
        let content = ArtefactContent.note(NoteContent(message: "नमस्ते…", english: "Hello Ramesh…", language: .hindi, weekMonday: Day(year: 2026, month: 10, day: 5), facts: [.init(label: "Taught", fact: "Chemical reactions: balancing equations", symbol: "book.closed")], generationID: UUID()))
        let data = try JSONEncoder().encode(content)
        #expect(try JSONDecoder().decode(ArtefactContent.self, from: data) == content)
        #expect(String(decoding: data, as: UTF8.self).contains("\"week_monday\":\"2026-10-05\""))
    }
}
```

- [ ] **Step 2: Run them to see them fail** (`xt.sh DomainTests`: no `NoteDay`, `NextStep`, `MessageSignature`; the
  signature test fails on each message).

- [ ] **Step 3: Implement.** The messages: `FeeMessage`, `AbsenceMessage`, `ConsentMessage`, `ForwardAskMessage` and
  `TestTomorrowMessage` end with `MessageSignature.text(...)` in place of their own two-line sign-off (one place for the
  signature; `TestTomorrowMessage.text` drops its `signature` local). `MessageEntry`'s decoding reads `channel` with a
  default of `.whatsAppLink` so a cached entry still decodes. `Classroom`'s custom `init(from:)` reads `noteDay` with
  `decodeIfPresent`. `OfflineRefusal.readSchool` is removed with its one caller moving to the three new cases (Task 18).

- [ ] **Step 4: Run the tests; `bun check --only=format,lint,ios`.** The signature changes the words on six sheets: the
  pictures `attendance-alert`, `fees-remind`, `fees-receipt`, `student-consent-ask`, `school-ask`, `school-test-tomorrow`
  are taken for PR 5 (rule 2; the boards stand, the last line is new).

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the note day, the next step, the signature on each message, the exam's window, the shapes"
```

### Task 6: Domain: the week's facts for the note; can-now-do from the ladder (PR 5)

**Files:**
- Create: `Sources/Domain/Parents/NoteFacts.swift` (`NoteFacts`, `NoteWeek`), `Parents/CanDoFacts.swift` (`CanDoFacts`,
  `CanDoWeek`)
- Test: `DomainTests/NoteWeekTests.swift`, `CanDoWeekTests.swift`, `MarkRulesTests.swift` (one case added),
  `DomainTests/ParentFixtures.swift`

**Interfaces:**

```swift
public struct NoteFacts: Hashable, Sendable {
    public let taught: [String]        // skill names, chapter order, six at most
    public let taughtLine: String      // "Chemical reactions: balancing equations, types of reactions"; "Nothing new this week"; "Nothing new this week: absent all week"
    public let right: String?          // "8 of 12 checks"; "8 of 12 checks · 14 of 25 on Unit test 2"; nil with neither
    public let rightLine: String       // right ?? "No checks yet"
    public let practise: [String]      // three at most
    public let practiseLine: String    // "The numbers in front of a formula · 5 a day"-style joins: names joined by " · "; "Nothing to add" when empty
    public let coming: [String]        // the next skill; "the unit test on Fri 16 Oct"
    public let comingLine: String      // joined by " · "; "Nothing set" when empty
    public let attendance: String?     // "absent 2 of 3 classes"; "absent all week (3 classes)"; nil with none absent or no sessions
    public let absentAllWeek: Bool
    public var rows: [NoteContent.FactRow]   // Taught book.closed, Got right checkmark.circle, To practise pencil.line, Coming calendar
    /// The row's lead for the Notes card: "2 absences", "all right", "absent Wed", "not on track", else the first practise skill.
    public func lead(status: TrackStatus, absentDays: [Day]) -> String
}
public enum NoteWeek {
    public static func facts(
        student: Student, chapters: [Chapter], skills: [Skill], checks: [CheckRecord], sessions: [AttendanceSession],
        marks: [MarkRecord], items: [SchoolItem], week: ClosedRange<Day>, calendar: Calendar
    ) -> NoteFacts
    /// The week's lead topic for the Notes card: the first taught skill's chapter, else the current chapter.
    public static func topic(_ facts: NoteFacts, chapters: [Chapter], skills: [Skill]) -> String?
}
public struct CanDoFacts: Hashable, Sendable {
    public struct MovedUp: Hashable, Sendable { public let area: Ladder.Area; public let step: String }
    public let movedUp: [MovedUp]; public let canDo: [String]; public let atHome: String; public let next: [String]
    public var rows: [NoteContent.FactRow]   // Can now do, At home, Next
    public var movedUpLine: String           // "Sentences · moved up this week"; "No change this week"
}
public enum CanDoWeek {
    public static func facts(chapters: [Chapter], skills: [Skill], week: ClosedRange<Day>, calendar: Calendar) -> CanDoFacts
    public static func atHome(area: Ladder.Area, step: Int) -> String   // the fixed lines per area and step
    /// Whether a student's note is can-now-do: LKG, UKG, or classes 1 to 3 with a ladder chapter.
    public static func isLadderNote(_ student: Student, chapters: [Chapter]) -> Bool
}
```

- [ ] **Step 1: Write the failing tests**

```swift
struct NoteWeekTests {
    let week = Day(year: 2026, month: 10, day: 5) ... Day(year: 2026, month: 10, day: 11)
    let calendar = DayHeading.india

    @Test func theFactsComeFromTheWeeksRecord() {
        let facts = NoteWeek.facts(student: ParentFixtures.dev, chapters: ParentFixtures.devChapters, skills: ParentFixtures.devSkills, checks: ParentFixtures.devChecks, sessions: ParentFixtures.weekSessions, marks: ParentFixtures.devMarks, items: [ParentFixtures.scienceExam], week: week, calendar: calendar)
        #expect(facts.taught == ["Balancing equations", "Types of reactions"])
        #expect(facts.taughtLine == "Chemical reactions: balancing equations, types of reactions")
        #expect(facts.right == "8 of 12 checks · 14 of 25 on Unit test 2")
        #expect(facts.practise == ["The numbers in front of a formula"])
        #expect(facts.coming == ["Acids, bases and salts", "the unit test on Fri 16 Oct"])
        #expect(facts.attendance == "absent 2 of 3 classes" && !facts.absentAllWeek)
        #expect(facts.rows.map(\.label) == ["Taught", "Got right", "To practise", "Coming"])
    }

    @Test func checksAndMarksOutsideTheWeekDoNotCount() {
        let old = ParentFixtures.devChecks.map { ParentFixtures.moved($0, to: Day(year: 2026, month: 9, day: 28)) }
        let facts = NoteWeek.facts(student: ParentFixtures.dev, chapters: ParentFixtures.devChapters, skills: ParentFixtures.devSkills, checks: old, sessions: [], marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.right == nil && facts.rightLine == "No checks yet")
    }

    @Test func aStudentAbsentAllWeekGetsTheAttendanceFactAndNoTaught() {
        let facts = NoteWeek.facts(student: ParentFixtures.dev, chapters: ParentFixtures.devChapters, skills: ParentFixtures.devSkillsUnchanged, checks: [], sessions: ParentFixtures.weekSessions(devAbsent: true), marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.absentAllWeek && facts.attendance == "absent all week (3 classes)")
        #expect(facts.taught.isEmpty && facts.taughtLine == "Nothing new this week: absent all week")
        #expect(facts.lead(status: .watch, absentDays: [Day(year: 2026, month: 10, day: 5), Day(year: 2026, month: 10, day: 7), Day(year: 2026, month: 10, day: 9)]) == "3 absences")
    }

    @Test func aStudentWithNoChecksHasNoGotRightSentence() {
        let facts = NoteWeek.facts(student: ParentFixtures.riya, chapters: ParentFixtures.riyaChapters, skills: ParentFixtures.riyaSkills, checks: [], sessions: ParentFixtures.weekSessions, marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.right == nil && facts.rightLine == "No checks yet")
        #expect(facts.practise.isEmpty && facts.practiseLine == "Nothing to add")
    }

    @Test func aStudentWithNoSkillsStillHasFacts() {
        let facts = NoteWeek.facts(student: ParentFixtures.newStudent, chapters: [], skills: [], checks: [], sessions: ParentFixtures.weekSessions, marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.taughtLine == "Nothing new this week" && facts.comingLine == "Nothing set" && facts.attendance == nil)
    }

    @Test func thePlacementsChecksAreLeftOut() {
        let placement = ParentFixtures.devChecks.map { ParentFixtures.asPlacement($0) }
        let facts = NoteWeek.facts(student: ParentFixtures.dev, chapters: ParentFixtures.devChapters, skills: ParentFixtures.devSkills, checks: placement, sessions: [], marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.right == nil)
    }

    @Test func theLeadReadsTheWeeksOneFact() {
        let facts = NoteWeek.facts(student: ParentFixtures.meher, chapters: ParentFixtures.devChapters, skills: ParentFixtures.meherSkills, checks: ParentFixtures.meherChecksAllRight, sessions: ParentFixtures.weekSessions, marks: [], items: [], week: week, calendar: calendar)
        #expect(facts.lead(status: .onTrack, absentDays: []) == "all right")
        #expect(facts.lead(status: .onTrack, absentDays: [Day(year: 2026, month: 10, day: 7)]) == "absent Wed")
        #expect(facts.lead(status: .notOnTrack, absentDays: []) == "not on track")
        #expect(NoteWeek.topic(facts, chapters: ParentFixtures.devChapters, skills: ParentFixtures.meherSkills) == "Types of reactions")
    }
}

struct CanDoWeekTests {
    let week = Day(year: 2026, month: 10, day: 5) ... Day(year: 2026, month: 10, day: 11)

    @Test func theLadderGivesWhatMovedUpWhatTheStudentCanDoAndWhatIsNext() {
        let facts = CanDoWeek.facts(chapters: ParentFixtures.sahilLadder, skills: ParentFixtures.sahilSkills, week: week, calendar: DayHeading.india)
        #expect(facts.movedUp == [.init(area: .reading, step: "Sentences")])
        #expect(facts.canDo == ["Read short sentences", "Count to 99"])
        #expect(facts.atHome == "One page a day from the picture book")
        #expect(facts.next == ["Writing words", "Adding to 20"])
        #expect(facts.movedUpLine == "Sentences · moved up this week")
        #expect(facts.rows.map(\.label) == ["Can now do", "At home", "Next"])
    }

    @Test func aWeekWithNoStepMovedStillSaysWhatTheStudentCanDo() {
        let facts = CanDoWeek.facts(chapters: ParentFixtures.sahilLadder, skills: ParentFixtures.sahilSkillsUnchanged, week: week, calendar: DayHeading.india)
        #expect(facts.movedUp.isEmpty && facts.movedUpLine == "No change this week" && !facts.canDo.isEmpty)
    }

    @Test func theAtHomeLineFollowsTheAreaMovedUpElseReading() {
        #expect(CanDoWeek.atHome(area: .numbers, step: 1) == "Count things at home to 99")
        #expect(CanDoWeek.atHome(area: .writing, step: 2) == "Five words a day in the notebook")
    }

    @Test func ladderStudentsGetCanNowDoAndOthersTheNote() {
        #expect(CanDoWeek.isLadderNote(ParentFixtures.sahil, chapters: ParentFixtures.sahilLadder))
        #expect(!CanDoWeek.isLadderNote(ParentFixtures.dev, chapters: ParentFixtures.devChapters))
        var fourth = ParentFixtures.sahil
        fourth.classLevel = .four
        #expect(!CanDoWeek.isLadderNote(fourth, chapters: ParentFixtures.sahilLadder))
    }
}

// MarkRulesTests, added
@Test func belowUsualComparesWithinTheSubjectAsWritten() {
    let hindi = ParentFixtures.mark(subject: "Hindi", test: "Unit test 2", day: 28, score: 11, max: 25)
    let earlier = [ParentFixtures.mark(subject: "Hindi", test: "Unit test 1", day: 1, score: 20, max: 25), ParentFixtures.mark(subject: "Hindi", test: "Class test", day: 10, score: 19, max: 25), ParentFixtures.mark(subject: "Mathematics", test: "Unit test 1", day: 1, score: 5, max: 25)]
    #expect(MarkRules.belowUsual(hindi, earlier: earlier))
    let social = ParentFixtures.mark(subject: "Social science", test: "Unit test 2", day: 28, score: 11, max: 25)
    #expect(!MarkRules.belowUsual(social, earlier: earlier))
}
```

- [ ] **Step 2: Run them to see them fail; implement.** Taught: skills with `stateAt` in the week and state not
  `notStarted`, ordered by chapter position then skill position, lower-cased after the first in the line ("Chemical
  reactions: balancing equations, types of reactions" when they share a chapter; "Chemical reactions: balancing equations ·
  Acids: naming acids" across chapters). Got right: checks in the week, not placement, by `at`; the mark of the week with
  the latest date. To practise: skills in `.practising` or `.revisit` whose chapter is one of the week's taught chapters,
  else the skills of the week's wrong checks (distinct, in order), three at most. Coming: `TrackingRules.currentSkill`'s
  next not-started skill by position, then the nearest exam within `ExamPreparation.window` after the week's end ("the
  <lower-cased title> on <shortWeekdayText>"). Attendance: the sessions in the week whose marks name the student. The
  ladder: `CanDoWeek` reads the ladder chapters (`chapter.ladder != nil`): movedUp = steps made `.secure` in the week;
  canDo = the highest secure step per area in the board's words (reading "Read short sentences" for Sentences, numbers
  "Count to 99" for To 99: a small table per area and step, the ladder's own step names otherwise); next = the step after
  per area; atHome from the area moved up (else reading).

- [ ] **Step 3: Run the tests; `swiftformat --lint`, `swiftlint --strict`; commit.**

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the week's facts for the note; can-now-do from the ladder"
```

### Task 7: Domain: the cadence's decision and a held note; the next step in the plan; the message to the parent (PR 5)

**Files:**
- Create: `Sources/Domain/Parents/NotOnTrackMessage.swift`
- Modify: `Sources/Domain/School/MessageCadence.swift`, `Sources/Domain/Plan/PlanRules.swift`, `Plan/PlanTypes.swift`
  (`PlanInput.told: Set<UUID>`; `PlanLine.caption`), `Plan/ArtefactBudget.swift` (the added personal check)
- Test: `DomainTests/MessageCadenceTests.swift`, `PlanRulesStepTests.swift`, `NotOnTrackMessageTests.swift`

**Interfaces:**

```swift
public enum HeldReason: Hashable, Sendable { case consent(parentFirstName: String?), threeThisWeek }
public extension MessageCadence {
    static let suggestedKinds: Set<MessageKind> = [.note, .canDo, .testTomorrow, .notOnTrack]
    enum Decision: Hashable, Sendable { case send, held(HeldReason), noNumber }
    /// For one student: no number → .noNumber; no consent → .held(.consent); the parent's three suggested this week spent → .held(.threeThisWeek); else .send.
    static func decision(for student: Student, parentEntries: [MessageEntry], now: Date, calendar: Calendar) -> Decision
    /// The row's words: "held: three messages this week"; "waits for Neha's consent".
    static func heldWords(_ reason: HeldReason) -> String
    /// The held sheet's footnote, with the next note day's date: "Three messages this week already. The app suggests at most three a week per parent, so this weekly note waits for Sunday the 18th unless you send it now. Messages you send yourself are never held."
    static func heldFootnote(nextNoteDay: Day) -> String
}
// PlanRules.studentLines reads student.effectiveStep (decision 9); PlanLine gains caption: String? (the Today line's caption,
// "Since Fri 9 Oct · tell Ramesh after the class" when the step is tellParent, the status not on track and the student is not in input.told).
public enum NotOnTrackMessage {
    public struct Facts: Hashable, Sendable { public let hard: [String]; public let reasons: [String]; public let doing: String; public let atHome: String? }
    public static func facts(student: Student, reasons: [String], skill: Skill?, before: Skill?, step: NextStep) -> Facts
    /// The English template on the phone (no call, no consent): "Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month. We will teach it again with a worked example in the next class. Ten minutes of practice each evening at home will make a big difference. Could we talk for five minutes this week? Thank you." then the signature.
    public static func text(studentName: String, parentName: String?, gender: Gender?, facts: Facts, tutorName: String?, centreName: String) -> String
    public static let title = "Tell the parent"
    public static func heading(studentFirstName: String) -> String   // "Dev needs a hand this month"
}
```

- [ ] **Step 1: Write the failing tests**

```swift
struct MessageCadenceTests {   // added cases
    let now = india(2026, 10, 11, 18, 30), calendar = DayHeading.india

    @Test func aParentWithThreeSuggestedThisWeekHasTheFourthHeld() {
        let three = [MessageKind.testTomorrow, .notOnTrack, .note].map { ParentFixtures.entry($0, day: 7) }
        #expect(MessageCadence.decision(for: ParentFixtures.devAgreed, parentEntries: three, now: now, calendar: calendar) == .held(.threeThisWeek))
        #expect(MessageCadence.decision(for: ParentFixtures.devAgreed, parentEntries: Array(three.prefix(2)), now: now, calendar: calendar) == .send)
    }

    @Test func handSendsNeverCount() {
        let hand = [MessageKind.reminder, .receipt, .absence, .consent, .forwardAsk, .progress].map { ParentFixtures.entry($0, day: 7) }
        #expect(MessageCadence.decision(for: ParentFixtures.devAgreed, parentEntries: hand, now: now, calendar: calendar) == .send)
    }

    @Test func noConsentHoldsWithTheParentsName() {
        #expect(MessageCadence.decision(for: ParentFixtures.riya, parentEntries: [], now: now, calendar: calendar) == .held(.consent(parentFirstName: "Neha")))
        #expect(MessageCadence.heldWords(.consent(parentFirstName: "Neha")) == "waits for Neha's consent")
        #expect(MessageCadence.heldWords(.threeThisWeek) == "held: three messages this week")
    }

    @Test func noNumberMeansNothingToSendTo() {
        var dev = ParentFixtures.devAgreed
        dev.parentPhone = nil
        #expect(MessageCadence.decision(for: dev, parentEntries: [], now: now, calendar: calendar) == .noNumber)
    }

    @Test func twoStudentsOfOneParentShareTheThree() {
        // The caller passes the parent's entries across their students (TodayStore's sameParent); two notes and a test tomorrow fill it.
        let entries = [ParentFixtures.entry(.note, day: 5), ParentFixtures.entry(.note, day: 5), ParentFixtures.entry(.testTomorrow, day: 7)]
        #expect(MessageCadence.decision(for: ParentFixtures.devAgreed, parentEntries: entries, now: now, calendar: calendar) == .held(.threeThisWeek))
    }

    @Test func aNoteHeldOnSundayIsFreeOnMonday() {
        let three = [MessageKind.testTomorrow, .notOnTrack, .note].map { ParentFixtures.entry($0, day: 7) }
        #expect(MessageCadence.decision(for: ParentFixtures.devAgreed, parentEntries: three, now: india(2026, 10, 12, 9, 0), calendar: calendar) == .send)
    }

    @Test func theHeldFootnoteNamesTheNextNoteDay() {
        #expect(MessageCadence.heldFootnote(nextNoteDay: Day(year: 2026, month: 10, day: 18)).contains("waits for Sunday the 18th unless you send it now"))
    }
}

struct PlanRulesStepTests {
    @Test func theStepsChangeTheTeachLine() {
        let base = ParentFixtures.planInput(dev: .notOnTrack, step: nil)
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: base) == "Teach again: Balancing equations, with the worked example")
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: ParentFixtures.planInput(dev: .notOnTrack, step: .teachAgain)) == "Teach again: Balancing equations, with the worked example")
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: ParentFixtures.planInput(dev: .notOnTrack, step: .stepBack)) == "Step back: Counting atoms in a formula, then Balancing equations")
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: ParentFixtures.planInput(dev: .notOnTrack, step: .leave)) == "Teach: Balancing equations")
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: ParentFixtures.planInput(dev: .notOnTrack, step: .addToChecks)) == "Teach: Balancing equations")
    }

    @Test func stepBackTeachesTheSkillBeforeAndLinksIt() {
        let plan = PlanRules.plan(ParentFixtures.planInput(dev: .notOnTrack, step: .stepBack))
        let teach = plan.lines.first { $0.studentID == ParentFixtures.dev.id && $0.kind == .teach }
        #expect(teach?.skillID == ParentFixtures.countingAtoms.id)
    }

    @Test func addToTheChecksPutsTheSkillAtTheHeadOfTheStudentsChecks() {
        let plan = PlanRules.plan(ParentFixtures.planInput(dev: .notOnTrack, step: .addToChecks))
        let check = plan.lines.first { $0.studentID == ParentFixtures.dev.id && $0.kind == .check }
        #expect(check?.personalChecks == true)
        #expect(plan.personalCheckSkills[ParentFixtures.dev.id]?.first?.name == "Balancing equations")
    }

    @Test func theCaptionShowsUntilTheParentIsTold() {
        let untold = PlanRules.plan(ParentFixtures.planInput(dev: .notOnTrack, step: nil, since: Day(year: 2026, month: 10, day: 9)))
        #expect(untold.lines.first { $0.studentID == ParentFixtures.dev.id && $0.kind == .teach }?.caption == "Since Fri 9 Oct · tell Ramesh after the class")
        let told = PlanRules.plan(ParentFixtures.planInput(dev: .notOnTrack, step: nil, since: Day(year: 2026, month: 10, day: 9), told: [ParentFixtures.dev.id]))
        #expect(told.lines.first { $0.studentID == ParentFixtures.dev.id && $0.kind == .teach }?.caption == nil)
        let leave = PlanRules.plan(ParentFixtures.planInput(dev: .notOnTrack, step: .leave, since: Day(year: 2026, month: 10, day: 9)))
        #expect(leave.lines.first { $0.studentID == ParentFixtures.dev.id && $0.kind == .teach }?.caption == nil)
    }

    @Test func aWatchStudentKeepsPhase12sTeachAgain() {
        #expect(PlanRules.teachWords(for: ParentFixtures.dev, in: ParentFixtures.planInput(dev: .watch, step: nil)) == "Teach again: Balancing equations, with the worked example")
    }
}

struct NotOnTrackMessageTests {
    @Test func theEnglishTemplateReadsAsTheBoard() {
        let facts = NotOnTrackMessage.Facts(hard: ["balancing equations"], reasons: ["absent twice this month"], doing: "teach it again with a worked example in the next class", atHome: "Ten minutes of practice each evening at home will make a big difference.")
        let text = NotOnTrackMessage.text(studentName: "Dev Kumar", parentName: "Ramesh Kumar", gender: .male, facts: facts, tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        #expect(text.hasPrefix("Hello Ramesh, Dev is finding balancing equations hard and was absent twice this month. We will teach it again with a worked example in the next class. Ten minutes of practice each evening at home will make a big difference. Could we talk for five minutes this week? Thank you."))
        #expect(text.hasSuffix(MessageSignature.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")))
        #expect(NotOnTrackMessage.heading(studentFirstName: "Dev") == "Dev needs a hand this month")
    }

    @Test func theFactsComeFromTheReasonsTheSkillAndTheStep() {
        let facts = NotOnTrackMessage.facts(student: ParentFixtures.dev, reasons: ["3 of 10 on the mock", "Absent twice in four weeks", "Homework not done three times running"], skill: ParentFixtures.balancing, before: ParentFixtures.countingAtoms, step: .stepBack)
        #expect(facts.hard == ["balancing equations"])
        #expect(facts.reasons.count == 3)
        #expect(facts.doing == "step back to counting atoms in a formula, then balancing equations")
        let noSkill = NotOnTrackMessage.facts(student: ParentFixtures.dev, reasons: ["Absent 4 times in four weeks"], skill: nil, before: nil, step: .tellParent)
        #expect(noSkill.hard == ["keeping up this month"] && noSkill.doing == "go over the last chapter again in the next class")
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** `PlanRules.studentLines` reads `student.effectiveStep` in place of
  the `again` test alone: `.tellParent` and `.teachAgain` → the Phase 12 "Teach again" line (watch students keep it);
  `.stepBack` → the skill before the current one in the same chapter (else the last skill of the chapter before) with
  its id; `.addToChecks` → the plain teach line and the current skill at the head of the student's personal checks
  (`PlanInput`'s spaced queue gains it first; `personalChecks` true); `.leave` → the plain line. `PlanRules.teachWords`
  is the small pure function the first test names. The caption: `PlanLine.caption` set on the teach line when the status
  is not on track, the effective step `.tellParent`, and the student is not in `input.told` (the ids whose parent has a
  `not_on_track` row since `trackSince`): "Since <trackSince's shortWeekdayText> · tell <parent's first name> after the
  class" ("tell the parent" without a name).

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the six pictures of Task 5; `bun pr-shots`; commit; open
  PR 5 (`phase-14/domain`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Domain: the cadence's decision and a held note; the next step in the plan; the message to the parent"
```

### Task 8: Data: notes kept and read; the log's kinds, channel and body; the note day and the next step written; the window (PR 6)

**Files:**
- Create: `Sources/Data/Cache/NotesCache.swift`
- Modify: `Sources/Data/Messages/MessageLogRepository.swift`, `SupabaseMessageLogRepository.swift`,
  `FakeMessageLogRepository.swift`; `Sources/Data/Plans/PlansRepository.swift`, `SupabasePlansRepository.swift`,
  `FakePlansRepository.swift`; `Sources/Data/Classes/*` (the two columns, `setNoteDay`); `Sources/Data/Students/*`
  (`next_step`, `setNextStep`); `Sources/Data/School/SchoolItemRow.swift`, `SchoolItemWrite`, `SupabaseSchoolItemsRepository.swift`
  (`window_days`; `update` by centre and id), `FakeSchoolItemsRepository.swift`
- Test: `DataTests/MessageEntryRowTests.swift`, `NotesCacheTests.swift`, `FakeRepositoriesParentsTests.swift`,
  `SchoolItemRowTests.swift` (the window)

**Interfaces:**

```swift
// MessageLogRepository
/// A note, can-now-do or not-on-track message as sent (or copied): kind, language, body (cut to 4000), channel; when it was logged.
func logMessage(centre: UUID, studentID: UUID, kind: MessageKind, language: MessageLanguage, body: String, channel: MessageChannel) async throws -> Date
// messages(centre:student:) and entries(centre:since:) read channel and body too.
// PlansRepository
public struct NewNote: Hashable, Sendable { public let studentID: UUID; public let kind: ArtefactKind /* .note | .canDo */; public let title: String; public let content: NoteContent; public let regeneratedFrom: UUID? }
func keepNote(_ note: NewNote, centre: UUID) async throws -> Artefact            // keep_artefact, no plan, no item
func notes(centre: UUID, students: [UUID], since: Date) async throws -> [Artefact]   // kinds note and can_do, newest first
// ClassesRepository: func setNoteDay(id: UUID, _ noteDay: NoteDay?, centre: UUID) async throws -> Classroom; the row reads note_weekday and note_time.
// StudentsRepository: func setNextStep(id: UUID, _ step: NextStep?) async throws -> Student; the row reads next_step.
// SchoolItemRow / SchoolItemWrite: window_days ↔ SchoolItem.windowDays.
// NotesCache: the week's kept notes per centre (cache-<centre>-notes.json): keep(_ notes: [Artefact]), read() -> [Artefact]; wiped with the centre's files (Wipe).
```

- [ ] **Step 1: Write the failing tests**

```swift
struct MessageEntryRowTests {
    @Test func aRowReadsItsChannelAndBodyAndAnOlderRowDefaultsToWhatsApp() throws {
        let copied = """
        {"id":"\(UUID())","kind":"note","opened_at":"2026-10-11T13:00:00Z","language":"kn","channel":"copied","body":"ನಮಸ್ಕಾರ"}
        """
        let entry = try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(copied.utf8)).entry
        #expect(entry?.channel == .copied && entry?.body == "ನಮಸ್ಕಾರ" && entry?.kind == .note)
        let old = """
        {"id":"\(UUID())","kind":"reminder","opened_at":"2026-10-06T04:45:00Z","language":null}
        """
        let older = try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(old.utf8)).entry
        #expect(older?.channel == .whatsAppLink && older?.body == nil)
    }

    @Test func aNotOnTrackRowReadsAsItsKind() throws {
        let row = """
        {"id":"\(UUID())","kind":"not_on_track","opened_at":"2026-10-09T13:00:00Z","language":"hi","channel":"whatsapp_link","body":"…"}
        """
        #expect(try SupabaseMessageLogRepository.decoder.decode(MessageEntryRow.self, from: Data(row.utf8)).entry?.kind == .notOnTrack)
    }
}

@MainActor struct FakeRepositoriesParentsTests {
    @Test func theFakeLogKeepsAMessageWithItsKindLanguageBodyAndChannel() async throws {
        let log = FakeMessageLogRepository()
        _ = try await log.logMessage(centre: UUID(), studentID: FakeStudentsRepository.dev, kind: .note, language: .hindi, body: "नमस्ते", channel: .whatsAppLink)
        _ = try await log.logMessage(centre: UUID(), studentID: FakeStudentsRepository.dev, kind: .note, language: .hindi, body: "नमस्ते", channel: .copied)
        let entries = try await log.messages(centre: UUID(), student: FakeStudentsRepository.dev)
        #expect(entries.map(\.channel) == [.copied, .whatsAppLink] && entries.first?.body == "नमस्ते")
        #expect(log.messageLogs.count == 2)
    }

    @Test func theFakePlansKeepAndFindTheWeeksNotes() async throws {
        let plans = FakePlansRepository()
        let kept = try await plans.keepNote(NewNote(studentID: FakeStudentsRepository.dev, kind: .note, title: "Dev's week", content: ParentFixtures.noteContent, regeneratedFrom: nil), centre: UUID())
        let found = try await plans.notes(centre: UUID(), students: [FakeStudentsRepository.dev], since: ParentFixtures.monday.date(in: DayHeading.india))
        #expect(found.map(\.id) == [kept.id] && found.first?.content == .note(ParentFixtures.noteContent))
        let again = try await plans.keepNote(NewNote(studentID: FakeStudentsRepository.dev, kind: .note, title: "Dev's week", content: ParentFixtures.noteContent, regeneratedFrom: kept.id), centre: UUID())
        #expect(again.regeneratedFrom == kept.id)
    }

    @Test func theFakeClassesKeepTheNoteDayAndStudentsTheNextStep() async throws {
        let classes = FakeClassesRepository()
        let saturday = NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0))
        let changed = try await classes.setNoteDay(id: FakeClassesRepository.evening, saturday, centre: UUID())
        #expect(changed.noteDay == saturday)
        let students = FakeStudentsRepository()
        #expect(try await students.setNextStep(id: FakeStudentsRepository.dev, .stepBack).nextStep == .stepBack)
        #expect(try await students.setNextStep(id: FakeStudentsRepository.dev, nil).nextStep == nil)
    }
}

struct NotesCacheTests {
    @Test func theWeeksNotesRoundTripUnderTheCentre() throws {
        let cache = NotesCache(centre: UUID(), directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
        try cache.keep([ParentFixtures.noteArtefact])
        #expect(try cache.read() == [ParentFixtures.noteArtefact])
        #expect(cache.url.lastPathComponent.hasPrefix("cache-") && cache.url.lastPathComponent.hasSuffix("-notes.json"))
    }
}

// SchoolItemRowTests, added
@Test func theWindowReadsAndWritesAndNilMeansFourteen() throws {
    let row = try SupabaseSchoolItemsRepository.decoder.decode(SchoolItemRow.self, from: ParentFixtures.examRowJSON(windowDays: 7))
    #expect(row.item?.windowDays == 7)
    var exam = ParentFixtures.scienceExam
    exam.windowDays = 21
    let write = try JSONEncoder().encode(SchoolItemWrite(item: exam))
    #expect(String(decoding: write, as: UTF8.self).contains("\"window_days\":21"))
    #expect(try SupabaseSchoolItemsRepository.decoder.decode(SchoolItemRow.self, from: ParentFixtures.examRowJSON(windowDays: nil)).item?.windowDays == nil)
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The Supabase log's `logMessage` inserts kind, language, body
  (`prefix(4000)`) and channel and selects `opened_at`; `messages` selects `id, kind, opened_at, language, channel, body`
  (an older row's null channel reads as WhatsApp). `keepNote` calls `keep_artefact` with `p_plan` null, `p_group_no` 0,
  `p_student`, `p_item_kind` `practise` (links no line, as the gap report's keep does) and the content encoded with
  `week_monday`; `notes(for:since:)` selects artefacts of kinds `note` and `can_do` for the students with `created_at >=
  since`. The classes row reads `note_weekday` and `note_time` ("18:00:00" → `TimeOfDay`); `setNoteDay` writes both (null
  for the default). `SupabaseSchoolItemsRepository.update` adds `.eq("centre_id", value: item.centreID)`.

- [ ] **Step 3: Run the tests; `swiftformat --lint`, `swiftlint --strict`; commit.**

```bash
git add ios/TutorCentralKit
git commit -m "Data: notes kept and read, the log's kinds, channel and body, the note day and the next step written, the exam's window"
```

### Task 9: Data: the four API calls and the fake; the API client's answers; the write proofs (PR 6)

**Files:**
- Create: `Sources/Data/AI/AIRepository+Parents.swift`, `APIClient+Parents.swift`, `APIBodies+Parents.swift`,
  `AISamples+Parents.swift`
- Modify: `Sources/Data/AI/AIRepository.swift`, `FakeAIRepository.swift`, `APIClient.swift`, `APIFailure.swift`
- Test: `DataTests/APIBodiesParentsTests.swift`, `FakeAIRepositoryParentsTests.swift`, `APIClientTests.swift` (three
  cases added)

**Interfaces:**

```swift
public struct NoteRequest: Hashable, Sendable { studentID, studentName, parentName: String?, tutorName, centreName, classLevel: ClassLevel, language: MessageLanguage, weekMonday: Day, facts: NoteFacts }
public struct CanDoRequest: Hashable, Sendable { studentID, studentName, parentName, tutorName, centreName, classLevel, language, facts: CanDoFacts }
public struct NotOnTrackRequest: Hashable, Sendable { studentID, studentName, parentName, tutorName, centreName, classLevel, language, facts: NotOnTrackMessage.Facts }
public struct ReadMarksRequest: Hashable, Sendable { studentID, studentName, pages: [ImageUpload], subjects: [String] }
public struct ReadMarksAnswer: Hashable, Sendable { generationID: UUID; marks: [ReadMark] }
public protocol AIRepository {   // added
    func makeNote(_ request: NoteRequest, centre: UUID) async throws(APIFailure) -> MadeMessage
    func makeCanDo(_ request: CanDoRequest, centre: UUID) async throws(APIFailure) -> MadeMessage
    func makeNotOnTrack(_ request: NotOnTrackRequest, centre: UUID) async throws(APIFailure) -> MadeMessage
    func readMarks(_ request: ReadMarksRequest, centre: UUID) async throws(APIFailure) -> ReadMarksAnswer
}
// FakeAIRepository: noteCalls: [NoteRequest], canDoCalls, notOnTrackCalls, readMarksCalls; readMarksRows (the sample's three); Call gains .note, .canDo, .notOnTrack, .readMarks for scriptByKind.
// APIFailure gains .studentConsent(String) (the API's words); message: the words. APIClient: 403 reason "student_consent" → .studentConsent(body.error); 503 → .offline; a status not in [400, 401, 403, 422, 429, 503] → .service (a 501 included).
// The bodies keep within the API's limits on the app side (ios/CLAUDE.md): taught six, practise three, coming three, right 120, attendance 80; canDo four, next three, atHome 160; hard three, reasons four, doing 200, atHome 200; subjects twelve; pages two.
```

- [ ] **Step 1: Write the failing tests**

```swift
struct APIBodiesParentsTests {
    @Test func theNoteBodyCarriesTheFactsWithinTheAPIsLimits() throws {
        let body = MakeNoteBody(ParentFixtures.noteRequest(taught: Array(repeating: "A long skill name", count: 9)), centre: UUID())
        #expect(body.week.taught.count == 6 && body.week.monday == "2026-10-05" && body.language == "hi" && body.kind == "note")
        let data = try JSONEncoder().encode(body)
        let json = String(decoding: data, as: UTF8.self)
        #expect(json.contains("\"attendance\":\"absent 2 of 3 classes\"") && json.contains("\"studentId\""))
    }

    @Test func aMissingFactIsLeftOutOfTheBodyNotSentEmpty() throws {
        let body = MakeNoteBody(ParentFixtures.noteRequest(right: nil, attendance: nil), centre: UUID())
        let json = String(decoding: try JSONEncoder().encode(body), as: UTF8.self)
        #expect(!json.contains("\"right\"") && !json.contains("\"attendance\""))
    }

    @Test func theReadMarksBodyCarriesTwoPagesAtMostAndTheSubjects() {
        let body = ReadMarksBody(ParentFixtures.readMarksRequest(pages: 3, subjects: ["Mathematics", "Science"]), centre: UUID())
        #expect(body.pages.count == 2 && body.subjects == ["Mathematics", "Science"])
    }

    @Test func theCanDoAndNotOnTrackBodiesReadAsTheSchemas() throws {
        let canDo = String(decoding: try JSONEncoder().encode(MakeCanDoBody(ParentFixtures.canDoRequest, centre: UUID())), as: UTF8.self)
        #expect(canDo.contains("\"movedUp\":[{\"area\":\"reading\",\"step\":\"Sentences\"}]") && canDo.contains("\"kind\":\"can_do\""))
        let not = String(decoding: try JSONEncoder().encode(MakeNotOnTrackBody(ParentFixtures.notOnTrackRequest, centre: UUID())), as: UTF8.self)
        #expect(not.contains("\"hard\":[\"balancing equations\"]") && not.contains("\"kind\":\"not_on_track\""))
    }
}

@MainActor struct FakeAIRepositoryParentsTests {
    @Test func theFakeAnswersTheBoardsNotesAndRecordsTheCalls() async throws {
        let ai = FakeAIRepository()
        let note = try await ai.makeNote(ParentFixtures.noteRequest(), centre: UUID())
        #expect(note.message.hasPrefix("नमस्ते") && note.english.contains("Dev learnt to balance chemical equations"))
        #expect(ai.noteCalls.count == 1 && ai.noteCalls.first?.language == .hindi)
        let canDo = try await ai.makeCanDo(ParentFixtures.canDoRequest, centre: UUID())
        #expect(canDo.message.hasPrefix("ನಮಸ್ಕಾರ"))
        let marks = try await ai.readMarks(ParentFixtures.readMarksRequest(pages: 1, subjects: []), centre: UUID())
        #expect(marks.marks.count == 3 && marks.marks[2].date == nil)
    }

    @Test func aScriptedFailureOnOneKindLeavesTheOthers() async {
        let ai = FakeAIRepository()
        ai.scriptByKind[.note] = .failure(.service)
        await #expect(throws: APIFailure.service) { try await ai.makeNote(ParentFixtures.noteRequest(), centre: UUID()) }
        #expect((try? await ai.makeCanDo(ParentFixtures.canDoRequest, centre: UUID())) != nil)
    }
}

// APIClientTests, added
@Test func a503ReadsAsTheConnectionWords() async {
    let client = APIClient(origin: URL(string: "https://api.test")!, session: FakeURLSession(status: 503, body: #"{"error":"Couldn't reach the service. Try again.","reason":"unreachable"}"#), token: { "t" })
    await #expect(throws: APIFailure.offline) { try await client.makeTestTomorrow(ParentFixtures.testTomorrowRequest, centre: UUID()) }
}

@Test func a501NeverShowsTheAPIsWords() async {
    let client = APIClient(origin: URL(string: "https://api.test")!, session: FakeURLSession(status: 501, body: #"{"error":"not yet","route":"/ai/make"}"#), token: { "t" })
    await #expect(throws: APIFailure.service) { try await client.makeTestTomorrow(ParentFixtures.testTomorrowRequest, centre: UUID()) }
}

@Test func aStudentsMissingConsentReadsInTheAPIsStudentWords() async {
    let client = APIClient(origin: URL(string: "https://api.test")!, session: FakeURLSession(status: 403, body: #"{"error":"Dev's parent hasn't agreed yet.","reason":"student_consent"}"#), token: { "t" })
    await #expect(throws: APIFailure.studentConsent("Dev's parent hasn't agreed yet.")) { try await client.makeNote(ParentFixtures.noteRequest(), centre: UUID()) }
    #expect(APIFailure.studentConsent("Dev's parent hasn't agreed yet.").message == "Dev's parent hasn't agreed yet.")
}
```

- [ ] **Step 2: Run them to see them fail; implement.** `APIClient+Parents` posts `/ai/make` for the three kinds and
  `/ai/read-marks` with the pages reduced by the caller; `MadeMessage` decodes `{ id, result: { message, english } }`;
  `ReadMarksAnswer` decodes the rows (a null date as nil; a fractional score rounded, as the marks row reads). The fake's
  samples are the boards' (`AISamples+Parents`: the Hindi note and its English, the Kannada can-now-do, the Hindi
  not-on-track message, three mark rows). A store that meets `.studentConsent` shows the alert "The parent hasn't agreed
  yet. Record their consent on the student's page first." (Tasks 14, 16, 17 use the one `ConsentWords.studentAlert`).

- [ ] **Step 3: The write proofs** (the local stack, Meera, the API on `AI_FAKE=1`, a throwaway Swift test with an
  in-memory session, deleted after): `logMessage` note/hi/body/whatsapp and note/kn/copied (rows read back with channel
  and body); `keepNote` for Diya (an artefact row with student, no plan, kind note, the content read back equal; a second
  with `regenerated_from`); `notes(for:since:)` finds both; `setNoteDay` on the Evening batch (Saturday 18:00; `note_weekday
  6`, `note_time 18:00:00`) and back to nil; `setNextStep` on Dev (`step_back`, then null); `update` of an item with
  `window_days 7` (the row filtered by centre); `makeNote`, `makeCanDo`, `makeNotOnTrack` for Diya (consent) → 200 and
  the fake's words; for Riya (no consent) → `.studentConsent` with Riya's words; `readMarks` for Diya with one page →
  three rows. The ledger records each.

- [ ] **Step 4: Run the tests; `bun check --only=format,lint,ios`; commit; open PR 6 (`phase-14/data`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Data: the note, can-now-do, not-on-track and read-marks calls and the fake; the API client's 503, 501 and student-consent answers; the write proofs"
```

### Task 10: Today: the note day's hero and the Notes card (PR 7)

**Files:**
- Create: `Sources/Features/Today/NoteDayStore.swift`, `NoteDaySections.swift`
- Modify: `Sources/Features/Today/TodayStore.swift` (the note day read beside the counts: `noteDay: NoteDayStore?`),
  `TodayView.swift` (the hero and the card between the batch hero and the plan when on), `TodayActions.swift`
  (`openNote(UUID, Day)`, `openHeld(HeldNote)`)
- Test: `TodayTests/NoteDayStoreTests.swift`

**Interfaces:**

```swift
public struct NoteRowModel: Identifiable, Hashable, Sendable {
    public enum State: Hashable, Sendable { case read, sent, held(HeldReason) }
    public let id: UUID            // the student
    public let name: String, initials: String
    public let line: String        // "Hindi · Chemical reactions · 2 absences"; "Kannada · Can now read short sentences"; "Hindi · waits for Neha's consent"; "Hindi · held: three messages this week"
    public let state: State
    public let noteDay: Day
}
@MainActor @Observable public final class NoteDayStore {
    public private(set) var isOn: Bool               // any batch's note day is on now
    public private(set) var title: String            // "Note day · Sunday 18:00" (the first batch's); "Note day" when batches differ
    public private(set) var heroLine: String         // "7 notes for parents" / "1 note for parents" / "No notes this week" (no student with a number)
    public private(set) var heroNote: String         // "Each one is about the week: what was taught, what went right, what to practise. Read it as the parent will, then send."
    public private(set) var rows: [NoteRowModel]
    public private(set) var countLine: String        // "2 of 7 sent"
    public private(set) var loadFailed: Bool         // the card's LoadFailedView (feedback.md row 13)
    public func load() async                         // the register, the record (chapters, skills, checks, marks, sessions, items), the week's log entries, the kept notes
    public func held(for student: UUID) -> HeldNote? // the held sheet's model: the parent's messages this week (kind title, day), the footnote, the student
    public init(register: any Register, record: any RecordRepository, attendance: any AttendanceRepository, messages: any MessageLogRepository, plans: any PlansRepository, schoolItems: (any SchoolItemsRepository)?, notesCache: NotesCache?, workspace: Workspace, now: @escaping () -> Date, calendar: Calendar)
}
public struct HeldNote: Hashable, Sendable { public let studentID: UUID; public let studentFirstName: String; public let parentLine: String /* "Ramesh Kumar · Dev's parent" */; public let thisWeek: [(kind: String, day: String)]; public let footnote: String; public let noteDay: Day }
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct NoteDayStoreTests {
    // Sunday 11 October 18:30 unless a test says another; the fixtures' Evening batch (Dev hi agreed, Meher en, Nikhil kn agreed, Riya hi not agreed, Sahil kn agreed on the ladder) and Class 10 Maths (Hemanth hi agreed, Akshita en).
    @Test func onTheNoteDayTheHeroCountsTheNotesAndTheRowsReadTheWeek() async {
        let store = makeNoteDayStore(now: FakeClock.oct11at1830, sent: [.dev, .meher])
        await store.load()
        #expect(store.isOn && store.title == "Note day · Sunday 18:00" && store.heroLine == "7 notes for parents")
        #expect(store.rows.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das", "Sahil Verma", "Hemanth Reddy", "Akshita Rao", "Riya Sharma"])
        #expect(store.rows[0].line == "Hindi · Chemical reactions · 2 absences" && store.rows[0].state == .sent)
        #expect(store.rows[3].line == "Kannada · Can now read short sentences" && store.rows[3].state == .read)
        #expect(store.rows[6].line == "Hindi · waits for Neha's consent" && store.rows[6].state == .held(.consent(parentFirstName: "Neha")))
        #expect(store.countLine == "2 of 7 sent")
    }

    @Test func beforeTheNoteTimeAndTwoDaysAfterNothingShows() async {
        let before = makeNoteDayStore(now: india(2026, 10, 11, 17, 0))
        await before.load()
        #expect(!before.isOn)
        let monday = makeNoteDayStore(now: india(2026, 10, 12, 20, 0))
        await monday.load()
        #expect(monday.isOn)
        let tuesday = makeNoteDayStore(now: india(2026, 10, 13, 9, 0))
        await tuesday.load()
        #expect(!tuesday.isOn)
    }

    @Test func aParentWithThreeThisWeekIsHeldAndTheSheetListsThem() async {
        let store = makeNoteDayStore(now: FakeClock.oct11at1830, devThisWeek: [.reminder, .testTomorrow, .notOnTrack])
        await store.load()
        #expect(store.rows[0].state == .held(.threeThisWeek) && store.rows[0].line == "Hindi · held: three messages this week")
        let held = store.held(for: .dev)
        #expect(held?.parentLine == "Ramesh Kumar · Dev's parent")
        #expect(held?.thisWeek.map(\.kind) == ["Fee reminder", "Test tomorrow", "Not on track"])
        #expect(held?.footnote.contains("waits for Sunday the 18th") == true)
    }

    @Test func aParentOfTwoSeesBothNotesAndTheFourthHeld() async {
        // Nikhil and Riya share a number here; Riya agreed for this test; two notes sent plus a Test tomorrow this week.
        let store = makeNoteDayStore(now: FakeClock.oct11at1830, sameParent: [.nikhil, .riya], riyaAgreed: true, parentThisWeek: [.note, .note, .testTomorrow])
        await store.load()
        #expect(store.rows.first { $0.id == .nikhil }?.state == .sent && store.rows.first { $0.id == .riya }?.state == .sent)
        let fourth = makeNoteDayStore(now: FakeClock.oct11at1830, sameParent: [.nikhil, .riya], riyaAgreed: true, parentThisWeek: [.note, .testTomorrow, .testTomorrow])
        await fourth.load()
        #expect(fourth.rows.first { $0.id == .riya }?.state == .held(.threeThisWeek))
    }

    @Test func aStudentWithoutANumberIsNotListed() async {
        let store = makeNoteDayStore(now: FakeClock.oct11at1830, noNumber: [.meher])
        await store.load()
        #expect(!store.rows.contains { $0.id == .meher } && store.heroLine == "6 notes for parents")
    }

    @Test func aBatchWithItsOwnNoteDayShowsOnThatDay() async {
        // The Evening batch on Saturday 18:00, Class 10 Maths on the default: Saturday evening lists the Evening batch's five only.
        let store = makeNoteDayStore(now: india(2026, 10, 10, 18, 30), eveningNoteDay: NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0)))
        await store.load()
        #expect(store.isOn && store.rows.count == 5 && !store.rows.contains { $0.id == .hemanth })
    }

    @Test func aStudentInTwoBatchesGetsOneNoteOnTheEarlierDay() async {
        let store = makeNoteDayStore(now: india(2026, 10, 10, 18, 30), eveningNoteDay: NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0)), hemanthInBoth: true)
        await store.load()
        #expect(store.rows.filter { $0.id == .hemanth }.count == 1)
        let sunday = makeNoteDayStore(now: FakeClock.oct11at1830, eveningNoteDay: NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0)), hemanthInBoth: true, sent: [.hemanth])
        await sunday.load()
        #expect(sunday.rows.first { $0.id == .hemanth }?.state == .sent)
    }

    @Test func changingTheNoteDayKeepsThisWeeksSentRowsAndMovesTheNextDay() async {
        let store = makeNoteDayStore(now: india(2026, 10, 10, 18, 30), sent: [.dev])
        store.setNoteDay(NoteDay(weekday: .saturday, time: TimeOfDay(hour: 18, minute: 0)))
        await store.load()
        #expect(store.rows.first { $0.id == .dev }?.state == .sent)
        #expect(store.nextNoteDay == Day(year: 2026, month: 10, day: 17))
    }

    @Test func aFailedReadSaysSoInPlace() async {
        let store = makeNoteDayStore(now: FakeClock.oct11at1830, recordFails: true)
        await store.load()
        #expect(store.loadFailed && store.rows.isEmpty)
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The store reads the register's active students and batches, works
  out each batch's `noteDay ?? .default` and which are on; for the students of the on batches (one row per student, the
  earlier note day for a student in two) with a parent's number, reads the record for the week (`NoteDay.week(ending:)`),
  the log since the week's Monday, and the kept notes since Monday; a row is `.sent` when a `note` or `can_do` WhatsApp
  row exists this week, else `MessageCadence.decision` over the parent's entries (`sameParent` as `TodayStore+Parents`
  has it: lift that helper to a `Register` extension in Domain so both use it). The line: the language's title, then
  the topic (`NoteWeek.topic`, or `"Can now \(canDo.first.lowercased)"` for the ladder), then the lead
  (`facts.lead(status:absentDays:)`); for a held row the language and the held words. `TodayStore` builds it beside the
  counts' read so the hero shows at once and the rows fill. The view (P10-Today-NoteDay): a hero card with the eyebrow
  "Note day" (and the setting title with Change day as a quiet action, Task 11), the count as the title, the note as
  the line; a `SectionHeader("Notes")` with the count line beside it; a `Card` of rows (avatar 36, the name, the line,
  Read primary 36 / Sent in `ok` / Held in `text3`); `LoadFailedView` in the card's place on a failed read.

- [ ] **Step 3: Run the tests; `swiftformat --lint`, `swiftlint --strict`; commit.**

```bash
git add ios/TutorCentralKit
git commit -m "Today: the note day's hero and the Notes card"
```

### Task 11: Today: a held note's sheet; the note day's wheel (PR 7)

**Files:**
- Create: `Sources/Features/Today/NoteDayChangeSheet.swift`; `Sources/DesignSystem/Components/HeldSheet.swift`
- Modify: `Sources/Features/Today/NoteDayStore.swift` (`setNoteDay`, `nextNoteDay`), `TodayView.swift`,
  `Sources/AppShell/ShellState.swift` (`heldNote: HeldNote?`, `noteDayChange: Bool`), `RootView+Today.swift`
- Test: `TodayTests/NoteDayStoreTests.swift` (two cases added), `DesignSystemTests/HeldSheetTests.swift` (the words)

- [ ] **Step 1: Write the failing tests**

```swift
// NoteDayStoreTests, added
@Test func changeDayWritesTheBatchesWhoseNoteDayIsShownAndRefusesOffline() async {
    let classes = FakeClassesRepository()
    let store = makeNoteDayStore(now: FakeClock.oct11at1830, classes: classes)
    await store.load()
    #expect(store.choices.map(\.title) == ["Friday 18:00", "Saturday 18:00", "Sunday 18:00", "Sunday 20:00", "Monday 08:00"] && store.chosen == .default)
    let ok = await store.changeDay(to: NoteDay.choices[1])
    #expect(ok && classes.noteDays[FakeClassesRepository.evening] == NoteDay.choices[1] && classes.noteDays[FakeClassesRepository.class10] == NoteDay.choices[1])
    let offline = makeNoteDayStore(now: FakeClock.oct11at1830, online: false)
    await offline.load()
    #expect(await offline.changeDay(to: NoteDay.choices[0]) == false && offline.message == OfflineRefusal.words(for: .noteDay))
}

@Test func keepItForNextWeekWritesNothingAndSendItNowOpensTheNote() async {
    let store = makeNoteDayStore(now: FakeClock.oct11at1830, devThisWeek: [.reminder, .testTomorrow, .notOnTrack])
    await store.load()
    var opened: (UUID, Day)?
    store.onOpenNote = { opened = ($0, $1) }
    store.sendNow(store.held(for: .dev)!)
    #expect(opened?.0 == .dev && opened?.1 == Day(year: 2026, month: 10, day: 11))
    #expect(store.rows[0].state == .held(.threeThisWeek))   // keep writes nothing; the row changes only once a log row lands
}

// HeldSheetTests
@Test func theHeldSheetReadsAsTheBoard() {
    let sheet = HeldSheet.Words(parentLine: "Ramesh Kumar · Dev's parent", footnote: MessageCadence.heldFootnote(nextNoteDay: Day(year: 2026, month: 10, day: 18)))
    #expect(HeldSheet.title == "Held for this week" && HeldSheet.sendNow == "Send it now" && HeldSheet.keep == "Keep it for next week")
    #expect(sheet.footnote.hasPrefix("Three messages this week already."))
}
```

- [ ] **Step 2: Run them to see them fail; implement.** `HeldSheet` (DesignSystem, P10-Held): the message sheet's head
  ("Held for this week", Cancel), the avatar and the parent line, an on-sheet card of the week's messages (an icon tile by
  kind, the kind, the day), the footnote, two 52 buttons: Send it now (secondary) and Keep it for next week (primary);
  presented by AppShell over Today (`shell.heldNote`). `NoteDayChangeSheet` (P10-NoteDay-Change): a `FittedSheet` "Note day"
  with the system wheel over `NoteDay.choices` and Save; Change day on the hero opens it; Save calls `changeDay`, which
  writes each on batch through the classes repository and reloads; the hero's title reads the new day. Offline both are
  refused in words (the alert).

- [ ] **Step 3: Run the tests; `swiftformat --lint`, `swiftlint --strict`; commit.**

```bash
git add ios/TutorCentralKit
git commit -m "Today: a held note's sheet; the note day's wheel"
```

### Task 12: Today: the Weekly notes row after the close; the launch states (PR 7)

**Files:**
- Modify: `Sources/Features/Today/TodayStore+Parents.swift` (`notesWaiting: String?`), `TodaySections.swift` (the last row
  of To parents), `Sources/AppShell/LaunchState.swift`, `RootView+LaunchStates.swift`, `Fixtures+Parents.swift` (new),
  `Dependencies.swift`
- Test: `TodayTests/ToParentsTests.swift` (two cases), `AppShellTests/LaunchStateTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// ToParentsTests, added
@Test func afterTheCloseTheLastRowCountsTheNotesWaitingAndNamesWhoWaitsForConsent() async {
    // Wed 7 Oct 18:40, the Evening batch closed: Dev, Meher, Nikhil, Sahil with numbers and consent or English; Riya without consent.
    let store = makeTodayStore(items: [], closed: true)
    await store.load()
    #expect(store.notesWaiting == "4 notes wait for the note day. Riya's waits for consent.")
    #expect(store.notesWaitingTitle == "Weekly notes · Sunday")
}

@Test func theRowReadsOneNoteAndTwoWaitingForConsent() async {
    let store = makeTodayStore(items: [], closed: true, noConsent: [.riya, .nikhil], noNumber: [.meher, .sahil])
    await store.load()
    #expect(store.notesWaiting == "1 note waits for the note day. Two wait for consent.")
}

// LaunchStateTests, added
@Test func phase14sStatesParse() {
    for name in ["today-note-day", "today-note-held", "today-note-day-change", "note", "note-send", "note-can-do", "note-writing", "student-messages", "student-not-on-track", "student-next-step", "student-tell-parent", "today-not-on-track", "marks-reading", "marks-confirm", "marks-edit", "school-paste", "school-student", "school-item-window"] {
        #expect(LaunchState(rawValue: name) != nil, name)
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The row (P10-Today-AfterClose): title "Weekly notes · <the batch's
  note weekday>", the line as the tests read it, no Send; tapping it opens Today's Notes card when the note day is on
  (`scrollTo(Anchor.notes)`), otherwise nothing. The fixtures (decision 22): `today-note-day`, `today-note-held`,
  `today-note-day-change` at Sunday 11 October 18:30 with the seven rows the board lists (two sent, four to read, one held
  for consent; `today-note-held` with Dev's three messages this week and the held sheet up; `today-note-day-change` with
  the wheel up); `today-after-close` gains the row. The other Phase 14 states are registered now (each a `LaunchState`
  case; their screens come with their pull requests, as Phase 13's Task 14 did for `school-ask`).

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the pictures `today-note-day`, `today-note-held`,
  `today-note-day-change`, `today-after-close`; `bun pr-shots`; commit; open PR 7 (`phase-14/note-day`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Today: the Weekly notes row after the close; Phase 14's launch states"
```

### Task 13: DesignSystem: the note's parts (PR 8)

**Files:**
- Create: `Sources/DesignSystem/Components/FactsCard.swift`, `NoteWell.swift`, `LadderStrip.swift`, `MessageLogRow.swift`,
  `ChoiceRowsSheet.swift`, `MarkReadRow.swift`, `PasteWell.swift`, `FilterChipRow.swift`
- Modify: `Sources/DesignSystem/Tokens/Tokens.swift` and `docs/design/design-tokens.md` only where a board's value is new
- Test: `DesignSystemTests/NoteWellTests.swift` (the counter's words and tone), `TokenDocumentTests` (unchanged, holds)

**Interfaces:**

```swift
/// The Phase 6 note well (min 200 high, body 16/24) with "The note · Hindi" over it, the counter "212 of 600" on the right
/// (overdue when over), and the helper under it (components.md 10.6).
public struct NoteWell: View { init(title: String, text: Binding<String>, limit: Int, helper: String, showsFocus: Bool = false) }
public extension NoteWell { static func counter(_ count: Int, limit: Int) -> (text: String, over: Bool) }   // ("212 of 600", false); scalars
/// "What it says": rows with an icon tile and a label over the fact in footnote text2.
public struct FactsCard: View { init(title: String, rows: [(label: String, fact: String, symbol: String)]) }
/// "Moved up": one area's five steps, the current step filled, the new step marked (P10-CanNowDo).
public struct LadderStrip: View { init(area: String, steps: [String], current: Int, line: String) }
/// A sent-log row: an icon tile by kind, the kind, the line, a chevron; a held row has the quiet Send now instead.
public struct MessageLogRow: View { init(symbol: String, title: String, line: String, held: (() -> Void)? = nil, dim: Bool = false) }
/// The student picker's sheet shape with choice rows (an icon tile, the title, what it means), one ticked, the footer's Use this.
public struct ChoiceRowsSheet: View { init(title: String, line: String, rows: [(symbol: String, title: String, meaning: String)], chosen: Int, choose: (Int) -> Void, use: () -> Void, cancel: () -> Void) }
/// A mark read from a photo: a 24 pt checkbox, "Mathematics · Unit test 2", "28 Sep" (or "Date · not given" in text3), "14 of 25" (P14-Marks-Confirm).
public struct MarkReadRow: View { init(ticked: Binding<Bool>, title: String, line: String, lineTone: Tone, score: String, open: () -> Void) }
/// The source well holding the system PasteButton and a line (P14-School-Paste).
public struct PasteWell: View { init(line: String, paste: (String) -> Void) }
/// A chip row under a title: one accent chip and a quiet action (P14-School-Student).
public struct FilterChipRow: View { init(chip: String, action: (String, () -> Void)) }
```

- [ ] **Step 1: Write the failing test**

```swift
struct NoteWellTests {
    @Test func theCounterCountsScalarsAndTurnsOverPastTheLimit() {
        #expect(NoteWell.counter(212, limit: 600) == ("212 of 600", false))
        #expect(NoteWell.counter(601, limit: 600) == ("601 of 600", true))
        #expect("ನಮಸ್ಕಾರ".storedCount == 7)
    }
}
```

- [ ] **Step 2: Run it to see it fail; implement the parts by the 10.6 and Phase 14 parts in `components.md`** (the
  tokens are the Kit's: `well`, `line`, `surface2`, `radiusControl`, `footnote`, `rowLine`; a 36 ladder step uses the
  check row's track height). A new value (none expected) goes to `design-tokens.md` and `Tokens` together (D25).

- [ ] **Step 3: Run the tests; `swiftformat --lint`, `swiftlint --strict`; commit.**

```bash
git add ios/TutorCentralKit
git commit -m "DesignSystem: the note's parts (the well and counter, the facts card, the ladder strip, the log row, the choice rows, the mark row, the paste well, the chip row)"
```

### Task 14: Artefacts: the weekly note and can-now-do (PR 8)

**Files:**
- Create: `Sources/Features/Artefacts/NoteStore.swift`, `NoteStore+Facts.swift`, `NoteView.swift`, `NoteSections.swift`
- Modify: `Sources/Features/Artefacts/ArtefactScreen.swift` (`.note(student: UUID, noteDay: Day)`), `ArtefactsActions.swift`,
  `Sources/AppShell/TabsState.swift` (`Route.note`), `RootView+Artefacts.swift`, `RootView+Today.swift` (Read opens it),
  `RootView+LaunchStates.swift`, `Fixtures+Parents.swift`
- Test: `ArtefactsTests/NoteStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class NoteStore {
    public enum Stage: Hashable, Sendable { case loading, writing, ready, failed(String) }
    public private(set) var stage: Stage
    public private(set) var isLadder: Bool                   // can-now-do
    public var message: String                               // the parent's language, editable
    public private(set) var english: String?                 // nil for English
    public private(set) var hero: (name: String, line: String)   // "Dev Kumar", "Ramesh Kumar · Hindi · the week of 5 October"
    public private(set) var wellTitle: String                // "The note · Hindi"
    public var counter: (text: String, over: Bool)           // NoteWell.counter(message.storedCount, limit: 600)
    public private(set) var facts: [NoteContent.FactRow]     // What it says
    public private(set) var ladder: (area: String, steps: [String], current: Int, line: String)?   // Moved up
    public private(set) var aiLine: String                   // "AI can make mistakes. Read the note as the parent will; the facts are from Dev's record." / "…from Sahil's ladder."
    public var canSend: Bool                                 // ready, not over, not empty
    public private(set) var sent: Bool                       // a log row this visit
    public var message_: String?                             // the alert's words (named `alert` in code)
    public func load() async                                 // the kept note this week, else make()
    public func make() async                                 // the facts → the API → keepNote
    public func writeAgain() async                           // a fresh draft, regeneratedFrom the shown one
    public func copy() async                                 // the pasteboard (with the signature); logs channel copied
    public func send() async -> Bool                         // the two-language sheet's Open WhatsApp: logs the kind, language and body (with the signature), opens wa.me
    public var sendSheet: (title: String, heading: String, parentLine: String, note: String)   // "Weekly note" / "Dev's week, for Ramesh" / "Ramesh Kumar · +91 … · Hindi" / "Opens WhatsApp with the note ready to send. We note the day and the language on Dev's page. The text is copied too, in case WhatsApp can't open."
    public init(student: UUID, noteDay: Day, context: ArtefactsContext /* register, record, attendance, messages, plans, schoolItems, ai, notesCache, workspace, open, now, calendar, online */)
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct NoteStoreTests {
    @Test func aNoteIsMadeFromTheWeeksFactsKeptAndShownWithTheEnglishBeside() async {
        let ai = FakeAIRepository(), plans = FakePlansRepository()
        let store = makeNoteStore(student: .dev, ai: ai, plans: plans)
        await store.load()
        #expect(store.stage == .ready && !store.isLadder)
        #expect(ai.noteCalls.first?.facts.taught == ["Balancing equations", "Types of reactions"] && ai.noteCalls.first?.language == .hindi)
        #expect(store.message.hasPrefix("नमस्ते") && store.english?.contains("Dev learnt") == true)
        #expect(store.hero == ("Dev Kumar", "Ramesh Kumar · Hindi · the week of 5 October") && store.wellTitle == "The note · Hindi")
        #expect(store.facts.map(\.label) == ["Taught", "Got right", "To practise", "Coming"])
        #expect(plans.kept.first?.kind == .note && plans.kept.first?.studentID == .dev && plans.kept.first?.planID == nil)
    }

    @Test func aNoteAlreadyKeptThisWeekOpensWithoutACall() async {
        let ai = FakeAIRepository(), plans = FakePlansRepository(notes: [ParentFixtures.noteArtefact])
        let store = makeNoteStore(student: .dev, ai: ai, plans: plans)
        await store.load()
        #expect(ai.noteCalls.isEmpty && store.message == ParentFixtures.noteContent.message)
    }

    @Test func writeAgainMakesAFreshDraftAndKeepsTheOldOne() async {
        let plans = FakePlansRepository()
        let store = makeNoteStore(student: .dev, plans: plans)
        await store.load()
        let first = plans.kept.first?.id
        await store.writeAgain()
        #expect(plans.kept.count == 2 && plans.kept.last?.regeneratedFrom == first)
    }

    @Test func aLadderStudentGetsCanNowDoWithMovedUp() async {
        let ai = FakeAIRepository()
        let store = makeNoteStore(student: .sahil, ai: ai)
        await store.load()
        #expect(store.isLadder && ai.canDoCalls.count == 1 && ai.noteCalls.isEmpty)
        #expect(store.ladder?.area == "Reading" && store.ladder?.current == 2 && store.ladder?.line == "Sentences · moved up this week")
        #expect(store.facts.map(\.label) == ["Can now do", "At home", "Next"] && store.aiLine.hasSuffix("from Sahil's ladder."))
        #expect(store.hero.line == "Deepak Verma · Kannada · the week of 5 October")
    }

    @Test func anEnglishParentSeesOneBlock() async {
        let store = makeNoteStore(student: .meher)
        await store.load()
        #expect(store.english == nil && store.wellTitle == "The note · English")
    }

    @Test func anAbsentStudentsNoteIsStillMade() async {
        let ai = FakeAIRepository()
        let store = makeNoteStore(student: .dev, devAbsentAllWeek: true, ai: ai)
        await store.load()
        #expect(store.stage == .ready && ai.noteCalls.first?.facts.absentAllWeek == true && ai.noteCalls.first?.facts.taught.isEmpty == true)
    }

    @Test func aNoteOverSixHundredScalarsCannotBeSentAndTheCounterSaysSo() async {
        let log = FakeMessageLogRepository()
        let store = makeNoteStore(student: .dev, messages: log)
        await store.load()
        store.message = String(repeating: "क", count: 601)
        #expect(!store.canSend && store.counter == ("601 of 600", true))
        #expect(await store.send() == false && log.messageLogs.isEmpty)
        store.message = String(repeating: "क", count: 600)
        #expect(store.canSend && store.counter == ("600 of 600", false))
    }

    @Test func aKannadaNoteCountsScalarsNotBytes() async {
        let store = makeNoteStore(student: .sahil)
        await store.load()
        store.message = String(repeating: "ನ", count: 600)
        #expect(store.canSend)
    }

    @Test func sendLogsTheKindLanguageAndSignedBodyThenOpensWhatsApp() async {
        let log = FakeMessageLogRepository()
        var opened: URL?
        let store = makeNoteStore(student: .dev, messages: log) { opened = $0 }
        await store.load()
        #expect(await store.send())
        let logged = log.messageLogs.first
        #expect(logged?.kind == .note && logged?.language == .hindi && logged?.channel == .whatsAppLink)
        #expect(logged?.body.hasSuffix("Made with Tutor Central") == true && logged?.body.hasPrefix(store.message) == true)
        #expect(opened?.host() == "wa.me" && store.sent)
        #expect(store.sendSheet.heading == "Dev's week, for Ramesh")
    }

    @Test func copyLogsAsCopiedAndSendsNothing() async {
        let log = FakeMessageLogRepository()
        let store = makeNoteStore(student: .dev, messages: log)
        await store.load()
        await store.copy()
        #expect(log.messageLogs.first?.channel == .copied && !store.sent)
    }

    @Test func aParentWithoutConsentIsRefusedBeforeAnyCallInTheStudentsWords() async {
        let ai = FakeAIRepository()
        let store = makeNoteStore(student: .riya, ai: ai)
        await store.load()
        #expect(ai.noteCalls.isEmpty && store.stage == .failed("Riya's note waits for Neha's consent. Record it on Riya's page first."))
    }

    @Test func aFailedCallKeepsTheFactsAndOffersTryAgain() async {
        let ai = FakeAIRepository()
        ai.scriptByKind[.note] = .failure(.service)
        let store = makeNoteStore(student: .dev, ai: ai)
        await store.load()
        #expect(store.stage == .failed("The AI service didn't answer. Try again.") && store.facts.count == 4)
    }

    @Test func offlineAKeptNoteOpensFromItsCopyAndAnUnmadeOneIsRefused() async {
        let cache = NotesCache.inMemory([ParentFixtures.noteArtefact])
        let kept = makeNoteStore(student: .dev, online: false, notesCache: cache, plansFail: true)
        await kept.load()
        #expect(kept.stage == .ready && kept.message == ParentFixtures.noteContent.message)
        let unmade = makeNoteStore(student: .meher, online: false, notesCache: cache, plansFail: true)
        await unmade.load()
        #expect(unmade.stage == .failed(OfflineRefusal.words(for: .note)))
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** `load()` reads the register's student and the record for the week
  (`NoteDay.week(ending: noteDay)`), finds a kept note of this week in `plans.notes` (else the cache offline), else
  `make()`: consent first (the student's words above, feedback.md's alert row through `stage.failed`), online, the facts
  (`NoteWeek.facts` or `CanDoWeek.facts`), the call, `keepNote`, the cache. The view (P10-Note, -Light, -Send, P10-CanNowDo):
  `BackRow` "Weekly note" / "Can now do"; the hero; `LadderStrip` for the ladder; `NoteWell` with the counter and helper
  ("Edit anything before it goes. Tap Write again for a fresh draft."); the English block; `FactsCard("What it says")`;
  the footer: the AI line, Write again, Copy (the `CopyButton` done state "✓ Copied"), Send on WhatsApp (primary) opening
  `TwoLanguageMessageSheet` as `sendSheet` words it, whose Open WhatsApp calls `send()`. While writing, the Phase 6 creating
  card ("Writing Dev's note", "Usually under a minute. From this week's record.") stands in the well's place and the footer
  is disabled (`note-writing`). The route `Route.note(student, noteDay)` is pushed by Today's Read, a held sheet's Send it
  now, the sent log's Send now; Back returns.

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the pictures `note` (both), `note-send`, `note-can-do`,
  `note-writing`; `bun pr-shots`; commit; open PR 8 (`phase-14/note`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Artefacts: the weekly note and can-now-do, read, edited, written again, copied, sent in two languages, logged"
```

### Task 15: Students: the sent log with Held and Send now (PR 9)

**Files:**
- Create: `Sources/Features/Students/MessagesScreen.swift`, `MessagesStore.swift`
- Modify: `Sources/Features/Students/RecordSections.swift` (`MessagesSection` gains See all and a Held row),
  `StudentDetailStore.swift` (`heldNote`), `StudentDetailView.swift`, `StudentsActions.swift` (`openMessages`,
  `openNote`), `Sources/AppShell/TabsState.swift` (`Route.studentMessages(UUID)`), `RootView+Students.swift`,
  `RootView+LaunchStates.swift`, `Fixtures+Parents.swift`
- Test: `StudentsTests/MessagesStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class MessagesStore {
    public struct Row: Identifiable, Hashable, Sendable { public let id: UUID; public let symbol: String; public let title: String; public let line: String }
    public struct Month: Identifiable, Hashable, Sendable { public let id: String; public let title: String; public let rows: [Row] }
    public struct Held: Hashable, Sendable { public let title: String; public let line: String /* "Held since Thu 8 Oct · Ramesh had three messages that week" */; public let noteDay: Day }
    public private(set) var title: String          // "Messages · Dev"
    public private(set) var line: String           // "What went to Ramesh Kumar from here, newest first. Opened means WhatsApp was opened with it; what he read is his."
    public private(set) var months: [Month]
    public private(set) var held: Held?            // placed before the month the held note belongs to
    public private(set) var loadFailed: Bool
    public func load() async
    public func sendNow() -> (UUID, Day)?          // the held note's student and note day for the route
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct MessagesStoreTests {
    @Test func theLogListsByMonthNewestFirstWithKindDayLanguageAndOpened() async {
        let store = makeMessagesStore(student: .dev, entries: ParentFixtures.devLogOctoberAndSeptember)
        await store.load()
        #expect(store.title == "Messages · Dev" && store.months.map(\.title) == ["October", "September"])
        #expect(store.months[0].rows.map(\.title) == ["Weekly note", "Not on track", "Test tomorrow", "Fee reminder", "Weekly note"])
        #expect(store.months[0].rows[1].line == "Fri 9 Oct · Hindi · opened Fri" && store.months[0].rows[3].line == "Tue 6 Oct · English")
        #expect(store.months[0].rows[0].symbol == "text.bubble" && store.months[0].rows[1].symbol == "exclamationmark.circle")
    }

    @Test func aNoteKeptThisWeekWithNoRowReadsNotOpenedYetAndACopiedOneCopied() async {
        let store = makeMessagesStore(student: .dev, entries: [], notes: [ParentFixtures.noteArtefact])
        await store.load()
        #expect(store.months[0].rows[0].line == "Sun 11 Oct · Hindi · not opened yet")
        let copied = makeMessagesStore(student: .dev, entries: [ParentFixtures.entry(.note, day: 11, channel: .copied)])
        await copied.load()
        #expect(copied.months[0].rows[0].line == "Sun 11 Oct · Hindi · copied Sun")
    }

    @Test func aHeldNoteSitsBetweenTheMonthsWithSendNow() async {
        let store = makeMessagesStore(student: .dev, entries: ParentFixtures.devThreeThisWeek, notes: [ParentFixtures.noteArtefact], now: FakeClock.oct11at1830)
        await store.load()
        #expect(store.held?.title == "Weekly note" && store.held?.line == "Held since Sun 11 Oct · Ramesh had three messages that week")
        #expect(store.sendNow() == (.dev, Day(year: 2026, month: 10, day: 11)))
    }

    @Test func aHeldNoteOffersSendNowOnceTheWeekRolls() async {
        let store = makeMessagesStore(student: .dev, entries: ParentFixtures.devThreeThisWeek, notes: [ParentFixtures.noteArtefact], now: india(2026, 10, 13, 9, 0))
        await store.load()
        #expect(store.held != nil && store.sendNow() != nil)
    }

    @Test func theNextNoteDaysNoteReplacesAHeldOne() async {
        let store = makeMessagesStore(student: .dev, entries: [], notes: [ParentFixtures.noteArtefact, ParentFixtures.noteArtefact(week: Day(year: 2026, month: 10, day: 12))], now: india(2026, 10, 18, 19, 0))
        await store.load()
        #expect(store.held == nil && store.months[0].rows.filter { $0.title == "Weekly note" }.count == 2)
    }

    @Test func aHeldForConsentNoteNamesTheReason() async {
        let store = makeMessagesStore(student: .riya, entries: [], now: FakeClock.oct11at1830)
        await store.load()
        #expect(store.held?.line == "Held since Sun 11 Oct · waits for Neha's consent")
    }

    @Test func aFailedReadSaysSoInPlace() async {
        let store = makeMessagesStore(student: .dev, fails: true)
        await store.load()
        #expect(store.loadFailed && store.months.isEmpty)
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The screen (P10-Student-Messages): `BackRow` "Messages · Dev", the
  line, per month a `SectionHeader` and a `Card` of `MessageLogRow`s, the Held section (header "Held", one row with the
  quiet Send now → `Route.note`); `LoadFailedView` on a failed read. The page's `MessagesSection` gains See all → the
  screen, and shows the held row first when there is one. The symbols: `text.bubble` note, `exclamationmark.circle` not on
  track, `doc.text` test tomorrow, `bell` reminder, `checkmark.circle` receipt, `person.crop.circle.badge.exclamationmark`
  absence, `hand.raised` consent, `arrowshape.turn.up.forward` forward ask, `clock` in `text3` held.

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the picture `student-messages`; `bun pr-shots`; commit;
  open PR 9 (`phase-14/messages`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Students: the sent log by month with Held and Send now"
```

### Task 16: Not on track: the next step chosen by the plan unless changed; the message to the parent; Today's caption (PR 10)

**Files:**
- Create: `Sources/Features/Students/NextStepSheet.swift`, `NotOnTrackStore.swift`, `TellParentCard.swift`
- Modify: `Sources/Features/Students/StudentDetailStore+Record.swift` (`TrackingLines.next` from the effective step;
  `tellParent: TellParentModel?`), `StudentDetailStore.swift` (`setNextStep`, the `told` read), `StudentDetailView.swift`,
  `RecordSections.swift` (`TrackingSection` gains Change), `Sources/Features/Today/PlanStore+Cards.swift`
  (`PlanLineModel.caption`), `PlanSections.swift`, `PlanMaker.swift` (`told` into the input; the plan remade on a step
  change through `ShellState.recordChanged`), `TodayStore+Parents.swift`, `Sources/Features/Today/CloseStore+Done.swift`
  (a changed status clears the step), `Sources/AppShell/ShellState.swift` (`nextStep: UUID?`, `tellParent: UUID?`),
  `RootView+Students.swift`, `RootView+Today.swift`, `Fixtures+Parents.swift`
- Test: `StudentsTests/NotOnTrackStoreTests.swift`, `NextStepTests.swift`, `TodayTests/PlanCaptionTests.swift`,
  `TodayTests/CloseStoreTests.swift` (one case)

**Interfaces:**

```swift
public struct TellParentModel: Hashable, Sendable { public let title: String /* "Ramesh Kumar has not been told yet" */; public let line: String /* "A message in Hindi that says what is hard, what we are doing and what helps at home. You read it first." */; public let callURL: URL? }
@MainActor @Observable public final class NotOnTrackStore {   // the message sheet's store (the two-language sheet)
    public enum Stage: Hashable, Sendable { case making, ready, failed(String) }
    public private(set) var stage: Stage; public var message: String; public private(set) var english: String?
    public let heading: String /* "Dev needs a hand this month" */; public let parentLine: String; public let languageTitle: String; public let note: String
    public func make() async        // the English template, or /ai/make not_on_track with consent
    public func open() async -> Bool // logs not_on_track (language, signed body), opens WhatsApp
}
// StudentDetailStore: func chooseStep(_ step: NextStep) async -> Bool   // writes students.next_step (nil when the plan's own is chosen), bumps recordChanged
// TrackingLines.next reads student.effectiveStep.nextLine(skill:before:); TrackingLines.canChange: status is watch or notOnTrack
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct NextStepTests {
    @Test func theCardsNextReadsTheEffectiveStepAndChangeWritesTheChoice() async {
        let students = FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)))
        let store = makeDetailStore(student: .dev, students: students)
        await store.load()
        #expect(store.tracking?.next == "Tell the parent, then teach again with the worked example." && store.tracking?.canChange == true)
        #expect(store.nextStepRows.map(\.title) == ["Tell the parent, then teach again", "Teach again with the worked example", "Step back to what comes before", "Add it to the checks", "Leave it for now"] && store.chosenStep == 0)
        #expect(store.nextStepRows[2].meaning == "Counting atoms in a formula, then balancing equations")
        #expect(await store.chooseStep(.stepBack))
        #expect(students.nextSteps[.dev] == .stepBack && store.tracking?.next == "Step back to Counting atoms in a formula, then Balancing equations.")
        #expect(await store.chooseStep(.tellParent) && students.nextSteps[.dev] == nil)   // the plan's own choice is kept as null
    }

    @Test func theTellParentCardShowsUntilTheParentIsToldOrTheStepChanges() async {
        let store = makeDetailStore(student: .dev, students: FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9))))
        await store.load()
        #expect(store.tellParent?.title == "Ramesh Kumar has not been told yet" && store.tellParent?.line.hasPrefix("A message in Hindi") == true)
        let told = makeDetailStore(student: .dev, students: FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9))), entries: [ParentFixtures.entry(.notOnTrack, day: 9)])
        await told.load()
        #expect(told.tellParent == nil)
        _ = await store.chooseStep(.leave)
        #expect(store.tellParent == nil)
    }

    @Test func offlineTheChangeIsRefusedInWords() async {
        let store = makeDetailStore(student: .dev, students: FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9))), online: false)
        await store.load()
        #expect(await store.chooseStep(.stepBack) == false && store.message == OfflineRefusal.words(for: .nextStep))
    }
}

@MainActor struct NotOnTrackStoreTests {
    @Test func anEnglishParentGetsTheTemplateWithNoCall() async {
        let ai = FakeAIRepository()
        let store = makeNotOnTrackStore(student: .meher, ai: ai)
        await store.make()
        #expect(store.stage == .ready && store.english == nil && ai.notOnTrackCalls.isEmpty)
        #expect(store.message.hasPrefix("Hello Priya, Meher is finding") && store.message.hasSuffix("Made with Tutor Central"))
    }

    @Test func aHindiParentWithConsentGetsTheMadeMessageWithTheEnglishBeside() async {
        let ai = FakeAIRepository()
        let store = makeNotOnTrackStore(student: .dev, ai: ai)
        await store.make()
        #expect(store.english?.contains("Dev is finding") == true && store.heading == "Dev needs a hand this month" && store.languageTitle == "Message · Hindi")
        #expect(ai.notOnTrackCalls.first?.facts.hard == ["balancing equations"])
    }

    @Test func aParentWithoutConsentGetsTheEnglishTemplateAndTheReason() async {
        let ai = FakeAIRepository()
        let store = makeNotOnTrackStore(student: .riya, ai: ai)
        await store.make()
        #expect(ai.notOnTrackCalls.isEmpty && store.english == nil && store.consentLine == "Neha's language needs consent; this is in English.")
    }

    @Test func openLogsNotOnTrackWithTheLanguageAndSignedBody() async {
        let log = FakeMessageLogRepository()
        let store = makeNotOnTrackStore(student: .dev, messages: log)
        await store.make()
        #expect(await store.open())
        #expect(log.messageLogs.first?.kind == .notOnTrack && log.messageLogs.first?.language == .hindi && log.messageLogs.first?.body.hasSuffix("Made with Tutor Central") == true)
    }
}

@MainActor struct PlanCaptionTests {
    @Test func aNotOnTrackLineCarriesTheCaptionUntilTheParentIsTold() async {
        let store = makePlanStore(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)), now: FakeClock.oct9at1635)
        await store.load()
        #expect(store.cards[0].lines.first { $0.id == .dev }?.caption == "Since Fri 9 Oct · tell Ramesh after the class")
        let told = makePlanStore(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)), now: FakeClock.oct9at1635, entries: [ParentFixtures.entry(.notOnTrack, day: 9)])
        await told.load()
        #expect(told.cards[0].lines.first { $0.id == .dev }?.caption == nil)
    }

    @Test func aChangedStepRemakesTodaysOpenPlan() async {
        let store = makePlanStore(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)), now: FakeClock.oct9at1635)
        await store.load()
        store.students.setStep(.dev, .stepBack)
        await store.recordChanged()
        #expect(store.cards[0].lines.first { $0.id == .dev }?.teach == "Step back: Counting atoms in a formula, then Balancing equations")
    }
}

// CloseStoreTests, added
@Test func aChangedStatusClearsTheTutorsStep() async {
    let students = FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)), devStep: .stepBack)
    let store = makeCloseStore(students: students, devChecksAllRight: true)   // the close moves Dev to watch
    await store.done()
    #expect(students.nextSteps[.dev] == nil)
    let same = FakeStudentsRepository(dev: .notOnTrack(since: Day(year: 2026, month: 10, day: 9)), devStep: .stepBack)
    let unchanged = makeCloseStore(students: same, devChecksAllRight: false)
    await unchanged.done()
    #expect(same.nextSteps[.dev] == .stepBack)
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The page (P10-Student-NotOnTrack): the tracking card gains the quiet
  Change when the status is watch or not on track; `TellParentCard` under it (a list card: one row, Call secondary 44
  with `phone`, Tell the parent primary 44 with `message`); Tell the parent presents `TwoLanguageMessageSheet` from
  `NotOnTrackStore` (the facts from the stored reasons, the current skill, the one before, the effective step); Change
  presents `ChoiceRowsSheet` ("What next for Dev", "The plan takes the first line unless you choose another. Nothing is
  sent until you send it.", the five rows with their meanings, the effective step ticked, Use this → `chooseStep`; choosing
  the plan's own writes null). The close's `done` writes `next_step` null for a student whose stored status changed
  (`SessionClose.Track` carries the previous status; the students repository's `setNextStep` after `close_session`, one
  call per changed student; offline it rides the queue's close as a second change). Today: `PlanLineModel.caption` from
  `PlanLine.caption`, drawn in `caption` `overdue` between the name and the status word, tappable → the student's page
  through `TodayActions.openStudent`; `PlanMaker` passes `told` (the `not_on_track` rows since each student's `trackSince`)
  in `PlanInput`.

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the pictures `student-not-on-track`,
  `student-next-step`, `student-tell-parent`, `today-not-on-track`; `bun pr-shots`; commit; open PR 10
  (`phase-14/not-on-track`); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Not on track: the next step chosen by the plan unless changed, the message to the parent in two languages, Today's caption"
```

### Task 17: Marks from a photo: a report card or a marked test read, the rows checked, saved, undone (PR 11)

**Files:**
- Create: `Sources/Features/Students/ReadMarksStore.swift`, `ReadMarksView.swift`, `ReadMarkEditSheet.swift`
- Modify: `Sources/Features/Students/RecordSections.swift` (`MarksSection` gains Add from a photo, disabled with the reason
  without consent), `StudentDetailStore+Marks.swift` (`canAddMarks`, `marksConsentLine`), `StudentDetailView.swift`,
  `StudentsActions.swift`, `Sources/AppShell/TabsState.swift` (`Route.readMarks(UUID)`), `RootView+Students.swift`,
  `RootView+LaunchStates.swift`, `Fixtures+Parents.swift`
- Test: `StudentsTests/ReadMarksStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class ReadMarksStore {
    public enum Stage: Hashable, Sendable { case choosing, reading, read, saving, failed(String) }
    public struct Row: Identifiable, Hashable, Sendable { public let id: UUID; public var mark: ReadMark; public var ticked: Bool; public var title: String /* "Mathematics · Unit test 2" */; public var line: String /* "28 Sep"; "Date · not given" */; public var lineIsMissing: Bool; public var score: String /* "14 of 25" */ }
    public private(set) var stage: Stage
    public private(set) var hero: (name: String, line: String)   // "Hemanth Reddy", "From a photo · a report card or a marked test"
    public private(set) var pages: [ImageUpload]                 // one or two, reduced
    public var rows: [Row]
    public var canSave: Bool                                     // read, a ticked row, each ticked row dated
    public var saveLabel: String                                 // "Save 3 marks" / "Save 1 mark"
    public let aiLine = "AI can make mistakes. Check each mark against the paper."
    public let footnote = "Each mark read appears here for you to check. Nothing is kept until you tap Save."
    public func add(_ page: ImageUpload)                         // the camera or Photos; a second page allowed, a third refused in words
    public func read() async                                     // /ai/read-marks with the student's subjects
    public func edit(_ id: UUID, _ mark: ReadMark)               // the row's sheet; a date set ticks it
    public func save() async -> Bool                             // addMark per ticked row (date ?? today); the toast with Undo
    public func undo() async -> Bool                             // deleteMark each
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct ReadMarksStoreTests {
    @Test func aReportCardReadsIntoRowsWithTheUndatedOneUnticked() async {
        let ai = FakeAIRepository()
        let store = makeReadMarksStore(student: .hemanth, ai: ai)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(store.stage == .read && store.rows.count == 3)
        #expect(store.rows[0].title == "Mathematics · Unit test 2" && store.rows[0].line == "28 Sep" && store.rows[0].score == "14 of 25" && store.rows[0].ticked)
        #expect(store.rows[2].title == "Hindi · Unit test 2" && store.rows[2].line == "Date · not given" && store.rows[2].lineIsMissing && !store.rows[2].ticked)
        #expect(store.saveLabel == "Save 2 marks" && store.canSave)
        #expect(ai.readMarksCalls.first?.subjects == ["Mathematics", "Science"] && ai.readMarksCalls.first?.pages.count == 1)
    }

    @Test func settingTheDateOnTheSheetTicksTheRow() async {
        let store = makeReadMarksStore(student: .hemanth)
        store.add(ParentFixtures.page)
        await store.read()
        var mark = store.rows[2].mark
        mark.date = Day(year: 2026, month: 9, day: 29)
        store.edit(store.rows[2].id, mark)
        #expect(store.rows[2].ticked && store.rows[2].line == "29 Sep" && store.saveLabel == "Save 3 marks")
    }

    @Test func saveWritesATickedRowEachAndTheToastUndoesThem() async {
        let record = FakeRecordRepository()
        let store = makeReadMarksStore(student: .hemanth, record: record)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(await store.save())
        #expect(record.addedMarks.count == 2 && record.addedMarks.allSatisfy { $0.photoPath == nil && $0.schoolItemID == nil && $0.artefactID == nil })
        #expect(record.addedMarks[0].subject == "Mathematics" && record.addedMarks[0].test == "Unit test 2" && record.addedMarks[0].score == 14 && record.addedMarks[0].max == 25)
        #expect(store.toast == "2 marks saved to Hemanth's page")
        #expect(await store.undo() && record.marks(for: .hemanth).count == ParentFixtures.hemanthMarks.count)
    }

    @Test func aSubjectWithNoBookIsKeptAsWrittenAndSaved() async {
        let record = FakeRecordRepository()
        let ai = FakeAIRepository()
        ai.readMarksRows = [ReadMark(subject: "Social science", test: "Unit test 2", date: Day(year: 2026, month: 9, day: 30), score: 17, max: 25)]
        let store = makeReadMarksStore(student: .hemanth, ai: ai, record: record)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(await store.save() && record.addedMarks.first?.subject == "Social science")
    }

    @Test func aThirdPageIsRefusedAndTwoAreSent() async {
        let ai = FakeAIRepository()
        let store = makeReadMarksStore(student: .hemanth, ai: ai)
        store.add(ParentFixtures.page); store.add(ParentFixtures.page); store.add(ParentFixtures.page)
        #expect(store.pages.count == 2 && store.message == "Two pages at most. A report card is one; a marked test front and back is two.")
        await store.read()
        #expect(ai.readMarksCalls.first?.pages.count == 2)
    }

    @Test func noMarksReadIsSaidInWordsAndTheRowsStayEmpty() async {
        let ai = FakeAIRepository()
        ai.scriptByKind[.readMarks] = .failure(.refused("Couldn't read any marks from this photo. Try a flatter, brighter one."))
        let store = makeReadMarksStore(student: .hemanth, ai: ai)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(store.stage == .failed("Couldn't read any marks from this photo. Try a flatter, brighter one.") && store.rows.isEmpty)
    }

    @Test func withoutConsentTheActionIsDisabledWithTheReasonAndNoCallIsMade() async {
        let detail = makeDetailStore(student: .riya)
        await detail.load()
        #expect(!detail.canAddMarks && detail.marksConsentLine == "Marks from a photo wait for Neha's consent.")
        let ai = FakeAIRepository()
        let store = makeReadMarksStore(student: .riya, ai: ai)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(ai.readMarksCalls.isEmpty && store.stage == .failed("Marks from a photo wait for Neha's consent."))
    }

    @Test func offlineReadingAndSavingAreRefusedInWordsAndTheRowsStay() async {
        let store = makeReadMarksStore(student: .hemanth, online: false)
        store.add(ParentFixtures.page)
        await store.read()
        #expect(store.stage == .failed(OfflineRefusal.words(for: .readMarks)))
        let saved = makeReadMarksStore(student: .hemanth, onlineAfterRead: false)
        saved.add(ParentFixtures.page)
        await saved.read()
        #expect(await saved.save() == false && saved.message == OfflineRefusal.words(for: .saveMarks) && saved.rows.count == 3)
    }

    @Test func aSavedMarkShowsOnThePageAndBelowUsualFollowsIt() async {
        let record = FakeRecordRepository()
        let store = makeReadMarksStore(student: .hemanth, record: record)
        store.add(ParentFixtures.page)
        await store.read()
        _ = await store.save()
        let detail = makeDetailStore(student: .hemanth, record: record)
        await detail.load()
        #expect(detail.markRows.first?.title == "Science · Unit test 2" || detail.markRows.first?.title == "Unit test 2 · Mathematics")
        #expect(detail.markRows.count == ParentFixtures.hemanthMarks.count + 2)
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement to the Phase 14 boards.** `ReadMarksView` (P14-Marks-Reading,
  P14-Marks-Confirm, -Light): `BackRow` "Marks from a photo"; the hero; the photo well with the thumbnail (the Phase 13
  `SourceWell`) and "Add a page" while under two; the creating card while reading ("Reading the marks", "Usually under a
  minute. Each subject's test, date and score are picked out for you to check."); the rows as `MarkReadRow`s (tapping a
  row opens `ReadMarkEditSheet`, P14-Marks-Edit: Subject with `Subject.common` chips, Test, Date (the Phase 3 day tile with
  `calendarPopover`), Score, Out of, Remove this mark, Save); the footer: the AI line and Save N marks (disabled until a
  ticked row, each dated). Save pops to the page (`recordChanged` bumps the page's Marks) and shows the toast with Undo
  (`ToastCenter.show` with `("Undo", …)`). The page's Marks header gains the quiet "Add from a photo" (P10-Student-Record),
  disabled with `marksConsentLine` under the header when the parent has not agreed. The way in to a photo is the Phase 13
  pattern (the system's Take a photo / Choose from Photos dialog, then the document camera or the photos picker).

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the pictures `marks-reading`, `marks-confirm` (both),
  `marks-edit`, `student-marks`; `bun pr-shots`; commit; open PR 11 (`phase-14/marks-photo`), once the boards are approved
  (decision 30); merge when green.**

```bash
git add ios/TutorCentralKit
git commit -m "Marks from a photo: a report card or a marked test read, the rows checked and dated, saved with Undo"
```

### Task 18: School: U41 to U44 and two review minors (PR 12)

**Files:**
- Modify: `Sources/Features/School/ReadStore.swift` (`.pasteWaiting` stage; `paste(_ text:)`; the photo removed on a
  failed add; the three offline refusals), `ReadView.swift` (`PasteWell`), `SchoolStore.swift` (`filter: UUID?`,
  `filterChip`), `SchoolView.swift` (`FilterChipRow`), `SchoolActions.swift`, `ItemFormStore.swift` (`windowDays`,
  `windowChoices`), `ItemFormSheet.swift` (the Preparation row and wheel), `ItemSections.swift` (Who's rows with chevrons
  and `openStudent`), `ItemStore+Preparation.swift` (`ExamPreparation.window`), `Sources/Features/Students/StudentsActions.swift`
  (`openSchool(student:)`), `Sources/AppShell/RootView+School.swift`, `RootView+Students.swift`, `TabsState.swift`
  (`Route.school(filter: UUID?)` or the tab's store told), `RootView+LaunchStates.swift`, `Fixtures+School.swift`
- Test: `SchoolTests/ReadStoreTests.swift`, `SchoolStoreTests.swift`, `ItemFormStoreTests.swift`, `ItemStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// ReadStoreTests, added
@Test func pasteAMessageWaitsForThePasteButtonAndReadsOnIt() async {
    let ai = FakeAIRepository()
    let store = makeReadStore(source: .pasteWaiting, ai: ai)
    #expect(store.stage == .pasteWaiting && store.pasteLine == "Copy the school's message in WhatsApp, then tap Paste. Nothing is read until you do." && ai.parseSchoolCalls.isEmpty)
    await store.paste(SchoolFixtures.boardMessage)
    #expect(ai.parseSchoolCalls.count == 1 && store.drafts.count == 3)
}

@Test func aFailedAddRemovesTheUploadedPhoto() async {
    let photos = FakePhotoStore(), items = FakeSchoolItemsRepository(addFails: true)
    let store = makeReadStore(source: .photo(SchoolFixtures.timetable), photos: photos, items: items)
    await store.read()
    #expect(await store.add() == false)
    #expect(photos.added.count == 1 && photos.removed == photos.added)
}

@Test func theOfflineRefusalNamesWhatWaitsAndWhatDoesNot() async {
    let shared = makeReadStore(source: .shared(SchoolFixtures.sharedText), online: false)
    await shared.read()
    #expect(shared.message == OfflineRefusal.words(for: .readShared))
    let pasted = makeReadStore(source: .pasted(SchoolFixtures.boardMessage), online: false)
    await pasted.read()
    #expect(pasted.message == OfflineRefusal.words(for: .readPasted))
}

// SchoolStoreTests, added
@Test func theTabFilteredToAStudentListsTheirItemsWithTheChipAndShowAllClearsIt() async {
    let store = makeSchoolStore()
    await store.load(filter: FakeStudentsRepository.dev)
    #expect(store.filterChip == "Dev's items" && store.sections.flatMap(\.rows).allSatisfy { $0.reaches(FakeStudentsRepository.dev) })
    store.showAll()
    #expect(store.filterChip == nil && store.sections.flatMap(\.rows).count > store.devCount)
}

// ItemFormStoreTests, added
@Test func anExamsPreparationWindowIsFourteenUnlessChosenAndWrites() async {
    let items = FakeSchoolItemsRepository()
    let store = makeItemFormStore(item: SchoolFixtures.exam16, items: items)
    #expect(store.windowTitle == "14 days before" && store.windowChoices == [7, 10, 14, 21])
    store.windowDays = 7
    #expect(store.windowTitle == "7 days before")
    #expect(await store.save())
    #expect(items.items.first { $0.id == SchoolFixtures.exam16.id }?.windowDays == 7)
    let homework = makeItemFormStore(item: SchoolFixtures.homework12, items: items)
    #expect(homework.showsWindow == false)
}

// ItemStoreTests, added
@Test func theWindowChangesWhenPreparationStartsAndWhoOpensTheStudent() async {
    var exam = SchoolFixtures.exam16
    exam.windowDays = 7
    let store = makeItemStore(item: exam, now: FakeClock.oct7at1635)
    await store.load()
    #expect(store.preparation.isEmpty && store.hero.line.contains("in 9 days"))
    let near = makeItemStore(item: exam, now: india(2026, 10, 9, 16, 35))
    await near.load()
    #expect(!near.preparation.isEmpty)
    #expect(store.who.first?.opens == FakeStudentsRepository.dev)
}
```

- [ ] **Step 2: Run them to see them fail; implement to the Phase 14 boards.** The "+" menu's Paste a message pushes
  `Route.schoolRead` with `ReadSource.pasteWaiting`; `ReadView` shows `PasteWell` ("Paste" is the system `PasteButton`
  with `payloadType: String.self`; its tap hands the text to `store.paste`, which reads as a pasted source); the footer's
  Add is disabled with the usual line (P14-School-Paste). The tab's filter: `StudentsActions.openSchool(student:)` sets the
  tab's filter through AppShell (`ShellState.schoolFilter`), the tab shows `FilterChipRow("Dev's items", ("Show all",
  showAll))` under the title and lists the items that reach the student (P14-School-Student); a link or the tab bar clears
  it. The item sheet: for an exam, a `SettingRow` "Preparation" with the accent value "14 days before" opening the system
  wheel of 7, 10, 14, 21 in a popover (P14-School-Item-Window); `ItemFormStore.save` writes `windowDays` (nil for 14). Who's
  rows take a chevron and open the student's page (P10-School-Item). `ExamPreparation.window(exam)` replaces the constant
  in `ItemStore+Preparation`, `PlanMaker+Exam` and `SchoolItemRules.nearestExam`. `ReadStore.add` removes the photo when
  the insert throws (`photos.remove(path)`), and its offline refusal picks the source's case.

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; the pictures `school-paste`, `school-student`,
  `school-item-window`, `school-item`; `bun pr-shots`; commit; open PR 12 (`phase-14/school-leftovers`), once the boards are
  approved; merge when green. `plan/ui-polish.md`: U41 to U45 to Done with PRs 12 and 3 (Task 24).**

```bash
git add ios/TutorCentralKit
git commit -m "School: Paste without the prompt (U41), the tab filtered to a student (U42), the exam's window (U43), Who's chevrons (U44); the photo removed on a failed add; the reading refusals by source"
```

### Task 19: The boards' approval and the device tests (main, documents)

- [ ] **Step 1 (session 29, done with this plan):** the seven Phase 14 boards on row 24 of the canvas (`P14-Marks-Reading`,
  `P14-Marks-Confirm`, `-Light`, `P14-Marks-Edit`, `P14-School-Paste`, `P14-School-Student`, `P14-School-Item-Window`),
  mirrored into `docs/design/mockups/`, `directions/canvas.json`, `information-architecture.md` ("Phase 14 boards") and
  `components.md` ("Phase 14 parts"), awaiting the owner's word. PRs 11 and 12 start only after it (decision 30).
- [ ] **Step 2:** `docs/testing/device-tests.md` gains a Phase 14 section for the tester: T11 a real report card photographed
  with the camera (the rows match the card; Save shows them on the page); T12 a note in Kannada or Hindi (Send on WhatsApp
  opens the chat with the note in that script, signed, ending "Made with Tutor Central"); T13 a parent of two students on the
  note day (both notes, each counted; a Test tomorrow the same week held as the fourth); T14 the not-on-track message in
  Hinglish arrives readable.
- [ ] **Step 3:** Commit with the documents of Task 24 (D12), or on their own to `main` when the hand runs need them first.

### Task 20: The hand runs (D32), after each pull request they name (main)

By `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed, signed in as Meera, each write
confirmed in the database, each screenshot kept in `.shots/run/` and attached to the phase's issue ("Phase 14 hand run");
the local API with `AI_FAKE=1` except the cost run. The seed's Evening batch meets Monday to Friday 17:00 to 18:30; a run
needing the note day sets it by the wheel (the write under test: the real weekday and the next choice at or before the
real time, or the batch's `note_weekday` and `note_time` by psql when no choice fits) and puts it back after. A run on a day
that is not a meeting day moves the batch's time by psql, as session 28 did.

| Run | After PR | Through the screens | Confirm |
|---|---|---|---|
| 1 The signature | 5 | Fees → Remind on a due fee → the sheet's message ends with Meera's name, the centre and "Made with Tutor Central" → Open WhatsApp; Attendance → an absent student → Tell parent: the same ending | `select kind, opened_at from message_log order by opened_at desc limit 2`; the WhatsApp page's text ends with the line |
| 2 A note in Kannada | 8 | The note day on (Change day) → Today → the hero "N notes for parents" → Read on Kavya → "Writing Kavya's note" → the Kannada note with "In English, for you" and What it says from her week → edit a word → Send on WhatsApp → the two-language sheet → Open WhatsApp → WhatsApp's page shows the Kannada text with the signature → back: Kavya's row reads Sent | `select kind, language, channel, left(body, 40), opened_at from message_log where kind = 'note' order by opened_at desc limit 1` (kn, whatsapp_link, the edited word); `select kind, student_id, plan_id, content->>'language' from artefacts where kind = 'note'` (one row, plan null) |
| 3 A note in Hinglish | 8 | Read on Rohan → the Hinglish note (Latin letters) with the English beside → Copy → "✓ Copied" → Back → Rohan's row still Read (a copy is not a send) → Read again: the same note, no new call | `message_log` row kind note, language hinglish, channel copied; `ai_generations` has one `note` for Rohan |
| 4 No consent, and the reason | 8, 9 | Riya's row reads Held "waits for Neha's consent" → tap: the held sheet's reason → Students → Riya → Messages: the Held row "Held since … · waits for Neha's consent" → See all: the Held section → Consent → Parent agreed → back on Today: Riya's row reads Read | nothing written until consent; after it `students.consent_at` set and `ai_generations` gains Riya's note on Read |
| 5 The cadence holds a fourth | 7, 8, 9 | Diya's parent given three suggested rows this week by psql (`insert into message_log … kind in ('test_tomorrow','not_on_track','note')`, opened this week) → Today: Diya's row Held "held: three messages this week" → tap: the held sheet lists the three with their days and the footnote → Keep it for next week → nothing changes → Students → Diya → Messages: Held with Send now → Send now → the note → Send on WhatsApp → the row reads Sent | the three rows then a fourth `note` row for Diya; `select count(*) from message_log where student_id = <Diya> and kind in ('note','can_do','test_tomorrow','not_on_track') and opened_at >= date_trunc('week', now() at time zone 'Asia/Kolkata')` = 4 |
| 6 A hand send never counts | 7 | Diya's three rows replaced by a reminder, a receipt and the absence alert this week → Today: Diya's row reads Read | the rows' kinds; no Held |
| 7 Can now do | 8 | Anvi (class 2, Kannada, consent recorded on her page) with a ladder step made secure this week (a close with her checks right, or `update skills set state='secure', state_at=now()` on one step) → Read → "Can now do" with Moved up and the Kannada note → Send | `artefacts` kind can_do for Anvi; `message_log` kind can_do, kn |
| 8 The note day changed | 7 | Change day → Saturday 18:00 → the hero reads "Note day · Saturday 18:00" → the real weekday's next run | `select note_weekday, note_time from classes where id = <Evening>` (6, 18:00:00); back to null after |
| 9 Not on track and the next step | 10 | Dev made not on track by psql (`update students set track_status='not_on_track', track_reasons='["Balancing equations: 1 of 6 checks right over three weeks","Absent twice in four weeks"]', track_since=now() - interval '2 days'`) → Today's plan made again: Dev's line carries "Since <day> · tell Ramesh after the class" → tap it → Dev's page: the card in overdue, Next "Tell the parent, then teach again with the worked example.", the tell-the-parent card → Tell the parent → the Hindi message with the English beside → Open WhatsApp → back: the card gone; Today: the caption gone → Change → Step back → Use this → Next reads "Step back to …" → Today's plan made again: "Step back: …" | `message_log` kind not_on_track, hi; `students.next_step = 'step_back'`; `plan_items.words` for Dev's teach line |
| 10 Marks from a report card | 11 | A report card picture (a made PNG of three subjects' marks, one undated; `xcrun simctl addmedia`) → Students → Diya (consent) → Marks → Add from a photo → Choose from Photos → "Reading the marks" → three rows, the undated one unticked → tap it → the sheet → set the date → Save 3 marks → the page's Marks lists them → the toast with Undo (left) | `select subject, test, date, score, max, photo_path from marks where student_id = <Diya> order by created_at desc limit 3` (photo_path null); `ai_generations` has one `read_marks` with pages 1 and no image |
| 11 Marks from a marked test, and Undo | 11 | A marked test page (a score and a title written on it) → Add from a photo → one row → Save 1 mark → Undo → the row gone from the page | the marks row then none |
| 12 D67 on the local API | 2 | The local API started with `AI_MODEL_NOTE=claude-sonnet-5-5` → Read on a note → the record's model; restarted with `AI_MODEL_NOTE=claude-5` → the process stops with "AI_MODEL_NOTE names an unknown model" | `select kind, model from ai_generations where kind = 'note' order by created_at desc limit 1` (sonnet); the terminal's message |
| 13 The lost connection | 3 | `docker stop supabase_kong_tutor_central`, the API up → School → "+" → Paste a message → Paste → "Couldn't reach the AI service. Check your connection and try again." (not "Your sign-in has ended") → `docker start` | nothing written |
| 14 U41 to U44 | 12 | School → "+" → Paste a message → the Paste well → Paste (no iOS prompt) → three items read; Students → Dev → School → See all → the tab shows "Dev's items" with his items only → Show all; the exam → Edit → Preparation → 7 days before → Save → Today (the exam nine days out): the lines are level lines, not revision; the exam's page → Who → a row opens the student | `school_items.window_days = 7`; `plans.groups` with no exam group; `window_days` back to null after |
| 15 Offline | 7, 8, 11 | The gateway stopped → Today: the note day's card shows (the register's copy) → Read on a note made in run 2: it opens from its copy → Read on an unmade one: the alert "You're offline. The note…" → Change day: refused in words → Marks → Add from a photo → the alert → `docker start` | nothing written while stopped |

### Task 21: The cost run (D64) and the read-marks default (main)

- [ ] **Step 1 (after PR 12 and the hand runs; the owner's standing approval for real calls in testing; about ₹3):**
  `supabase db reset`; the local API **without** `AI_FAKE`; consent recorded for the twelve Evening students (psql); the note
  day set to now by the wheel; Today → Read and Send on each of the twelve (eleven notes and Anvi's can-now-do, Haiku);
  Dev's not-on-track message (Haiku); Diya's report card read twice: once with the API on `AI_MODEL_READ_MARKS=claude-sonnet-5-5`
  (the default), once on `claude-opus-5-5`, the rows compared against the card (subject, test, date, score, max) and the
  second set discarded without Save. Then `bun cost --since 1h` and the Phase 13 query for the record. `PriceSheet.typical`
  takes the measured note tokens (a `note` request is not a plan request: its figure is the record's).
- [ ] **Step 2:** the record writes calls, tokens and rupees per kind; a week of notes for twelve students; a month at four
  weeks; which model read the card right and at what cost; and the decision for `read_marks` (decision 26).
- [ ] **Step 3 (PR 13, `phase-14/read-marks-model`):** `api/models.json`'s `read_marks` set to the chosen model if it is not
  Sonnet; the test in `models.test.ts` updated to the choice; the description carries the two readings' rows and cost.
  Merge when green; `gh workflow run deploy` (Task 22).

### Task 22: The deploys, the review, TestFlight (main)

- [ ] **Step 1 (after PR 4):** `gh workflow run deploy`; the summary shows 0023 and 0024 pending, pushed, nothing after; the
  API smoke green (`/health` at the commit, `/ai/generate` 401); the run id into `STATE.md`'s Production. Set no
  `AI_MODEL_*` on Vercel (the table's defaults stand); `.env.example` says how.
- [ ] **Step 2 (after PR 13, when it changed the table):** `gh workflow run deploy` again.
- [ ] **Step 3: The review:** a reviewer pass over the merged pull requests with `superpowers:requesting-code-review` on
  Fable 5.1 (fresh context), with this plan's Review focus and the ledger's rulings. Each finding of any grade (D68:
  Critical, Important and Minor alike) is fixed with a test that failed first, in a fix pull request before the TestFlight
  build; the ledger records each; none is deferred.
- [ ] **Step 4:** `gh workflow run testflight`; the build number from the run; the owner installs it with the other builds
  after the last phase (D68); the device tests T11 to T14 wait for the tester.

### Task 23: Nothing deferred: the close of the phase's own findings (main)

- [ ] Before the documents: the ledger is read end to end; each hand-run fault, review finding and polish item that this
  phase's work brought has a fix commit and a test that failed first, or a ruling the owner gave in chat. A finding without
  one stops the phase here, not in the documents. Items the phase found on screens it did not touch, and that are not of
  this phase's making, go to `plan/ui-polish.md` with their source (those are not this phase's).

### Task 24: The documents (main)

- [ ] **Documents (D12), one commit to `main` when the phase ends:** `plan/phase-14-parents.md` "As built" (the note and its
  facts, the cadence as built, the note day, the next step, marks from a photo, the signature, D67's table and overrides,
  the lost connection, U41 to U45 and the five minors; the cost measured; where the build moved from this plan and why;
  what was left open: nothing of the phase's own); `plan/README.md` (Phase 14 done; a decision number if the owner rules
  one); `plan/STATE.md` (production: 0023, 0024, the API commit, the build; the open items' Phase 13 lines removed);
  `plan/ui-polish.md` (U41 to U45 to Done with their pull requests; a row for "Write a note" from the page; anything seen);
  `docs/design/information-architecture.md` ("Phase 14 boards": the seven boards and their states; the 10.6 launch states
  as built; the 10.3 note day), `components.md` ("Phase 14 parts": the texts; "As built in Phase 14" under 10.6, 10.3,
  10.2 and 10.5), `design-tokens.md` ("Numbers in code": the note's 600 counted on the body alone, the signature outside
  it; the note day Sunday 18:00 and its five choices, on from its time to the end of the next day; three suggested a week
  across a parent's students, the fourth held, a hand send never counted; the next step kept until the status changes; a
  report card's two pages and twelve rows; the exam's window 3 to 60 days); `ios/CLAUDE.md`, `api/CLAUDE.md`,
  `supabase/CLAUDE.md`, `CLAUDE.md` (Commands: `bun cost`) for rules learned; `docs/testing/device-tests.md` (T11 to T14);
  `plan/sessions/030/record.md`, `ledger.md` and `owner-messages.md`.

---

## Self-review (done 2026-10-11)

**Spec coverage** (`phase-14-parents.md`'s eight scope items): 1 the note (the note day, per student with consent, the
parent's language with English beside, from the week's record, read, edit, send, logged) → Tasks 4, 6, 8, 10, 12, 14; 2
can-now-do (LKG to 3 from the ladder) → Tasks 4, 6, 14, with the homework share settled by decision 8; 3 the cadence (three a
week, held shown as held, hand sends not counted) → Tasks 7, 10, 11, 15; 4 marks from a photo (a report card or a marked
test, confirmed and saved) → Tasks 4, 9, 17 and the P14 boards; 5 not on track (the next step on the page and on Today's
line, taken by the plan unless changed) → Tasks 5, 7, 16; 6 the tutor's name and "Made with Tutor Central" on each message
→ Task 5 (and the models stop signing, Task 4); 7 D67 (one table, a class band, marking apart from reading, the
environment override, the refusal at start, `MARKING_MODEL` folded, the price sheet and the cost run reading it, the model
logged) → Tasks 2, 21; 8 D68 (U41 to U45, the five minors, the lost connection; nothing of the phase's deferred) → Tasks 3,
5, 18, 22, 23. The acceptance's five lines → hand runs 2 and 3 (Kannada and Hinglish), 4 (no consent and the reason), 5 and 6
(the fourth held, a hand send not), 12 (the override reaches the call and the log), and Tasks 18, 22, 23 (the leftovers
closed, nothing deferred). Spec 8's "Each message carries the tutor's name and ends with 'Made with Tutor Central'" → Task 5's
`eachMessageTheAppWritesEndsWithIt`. Spec 5's tracking "next step the plan will take unless the tutor changes it" → Task 7's
`PlanRulesStepTests`. Spec 7's Note and Can-now-do rows → Tasks 4 and 14. Spec 9's `message_log` kinds and `language`,
`body` → Tasks 1 and 8.

**Placeholder scan:** no "TBD", no "similar to Task N" without the code; the views are specified by their Kit parts and the
boards' texts, as this repository's plans do; the prompts' system words are given in their sentences; the migrations in
full. Two things wait on the owner and are marked (decision 30): the seven boards' approval and the plan itself.

**Type consistency:** `NoteDay`, `NextStep`, `MessageSignature`, `MessageChannel`, `MessageEntry.channel`/`body`,
`NoteContent`, `ReadMark`, `SchoolItem.windowDays`, `ExamPreparation.window` (Task 5) are used by those names in Tasks 6 to
18; `NoteFacts`, `NoteWeek`, `CanDoFacts`, `CanDoWeek` (Task 6) by Tasks 9, 10, 14; `MessageCadence.decision`, `HeldReason`,
`heldWords`, `heldFootnote`, `PlanLine.caption`, `PlanInput.told`, `NotOnTrackMessage` (Task 7) by Tasks 10, 11, 15, 16;
`logMessage`, `NewNote`, `keepNote`, `notes(for:since:)`, `setNoteDay`, `setNextStep`, `NotesCache` (Task 8) by Tasks 10,
11, 14, 15, 16; `NoteRequest`, `CanDoRequest`, `NotOnTrackRequest`, `ReadMarksRequest`, `ReadMarksAnswer`, `MadeMessage`,
`APIFailure.studentConsent` (Task 9) by Tasks 14, 16, 17; `NoteRowModel`, `HeldNote`, `NoteDayStore` (Task 10) by Tasks 11,
12; `NoteWell`, `FactsCard`, `LadderStrip`, `MessageLogRow`, `ChoiceRowsSheet`, `MarkReadRow`, `PasteWell`, `FilterChipRow`,
`HeldSheet` (Tasks 11, 13) by Tasks 14 to 18; `Route.note`, `.studentMessages`, `.readMarks` (Tasks 14, 15, 17) by AppShell;
the API's `MessageOutput`, `ReadMarksInput`, `ReadMarksOutput`, `Verify`'s `"unreachable"`, `errors.consent(studentName)`
(Tasks 3, 4) by Tasks 9 and 22; `applyModelOverrides`, `modelFor`, `workTypeOf`, `costTable` (Task 2) by Tasks 4, 21.
`ParentFixtures`, `FakeClock.oct11at1830` and `.oct9at1635` are the test targets' helpers (decision 28).

**Review focus:** the nine lines each name their tests; the new sentences on screen (the Notes card's lines, the held words
and footnote, the note's helper and AI lines, the sent log's lines, the tell-the-parent card, the next-step rows, the
marks rows and their refusals, the paste line, the window row, the consent reasons, the nine offline refusals) pass
`ErrorWordsTests`; the one step that spends money is the cost run, under the owner's standing approval, with the amount
named (decision 25).
