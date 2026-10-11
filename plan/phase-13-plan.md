# Phase 13 plan: School

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-11 (session 27, Fable 5.1) from `phase-13-school.md`, `docs/spec-v2.md` and the approved Phase 10 boards
(step 10.5, with the mock and the gap report of 10.4 and the student page's Marks of 10.2), plus the three Phase 13 boards
drawn by this session for approval (row 23 of the canvas, `P13-*`). Ticked as it goes. The build runs on Opus 5.5 from
`resume/026-phase-13-build.md`, inline, task by task, with one ledger as sessions 22, 24 and 26 kept.

**Goal:** what a school sends reaches the plan. A forwarded message or a photo becomes items the tutor checks and keeps
(exams, homework, notices, holidays, per student or per class of a school); the School tab lists them by date and on a
calendar; an exam within fourteen days turns its students' lines on Today into revision, with a daily set, a mock two days
before in the school's pattern, marking from a photo, and a gap report that sets the last two days; a holiday takes its
students out of the day's plan; Ask parents to forward starts the flow; Test tomorrow goes to the parent in their language
the evening before; marks from mocks and checked papers show on the student's page; the cost of a mock, a marking and a
gap report is measured.

**Architecture:** the share extension already writes one text or image into the app group's inbox; the app reads it on
launch and on foreground and opens "Check what was read" on the School tab, where `/ai/parse-school` (Sonnet) turns the
text or photo into item drafts the tutor ticks and adds. Items live in `school_items` (migration 0011, extended by 0021).
Domain rules do the rest on the phone, as the user (D60): who an item is for, the exam window and the split of portions
across the batch's days, the mock day, the holiday rule, the message cadence, the English Test tomorrow template. The plan
maker (Phase 12) reads the items and hands `PlanRules` revision lines and holidays; exam students form a group of their own
whose set, sheet and checks come from the day's portion; on the mock day the group's set is the mock (`/ai/make` kind
`mock`, kept once per exam and shared by its students); marking goes through V1's Check a paper with the mock's key
(`/ai/check-paper`, Opus, the student's consent) and writes a `marks` row; the gap report (`/ai/make` kind `gap_report`,
Sonnet) is made from the marking and, when used, gives the last days their lines. A new feature target `School` holds the
tab, the reading, the items, Ask parents to forward and Test tomorrow; the mock and the gap report are artefact screens in
`Artefacts`; the Marks section is Students'; To parents after the close is Today's.

**Tech stack:** as Phase 12 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI, Postgres, Bun tests; Hono, zod
4, `@anthropic-ai/sdk`; XcodeGen). No new dependency.

**Spec:** `docs/spec-v2.md` sections 2, 3, 4 (the School tab), 5 (school items, marks), 6.3 and 6.6 (the subject, exam
mode), 7 (mock, test tomorrow, gap report), 8 (test tomorrow, Ask parents to forward, the cadence), 9; scope
`plan/phase-13-school.md`; the boards and what they settle in `docs/design/information-architecture.md` ("Phase 10 boards",
10.5; 10.4's mock and gap report; 10.2's Marks; 10.3's To parents; "Phase 13 boards"), the parts and texts in
`components.md` ("Phase 10 parts" 10.5, 10.4, 10.2; "Phase 13 parts"), the numbers in `design-tokens.md` ("Numbers in
code", step 10.5); decisions D56 to D66; what Phase 12 built in `phase-12-class-plan.md` "As built" and
`plan/sessions/026/ledger.md`; what Phase 10 settled in `phase-10-v2-design-and-foundation.md` "As built, Part B".

## Global constraints

- No board, no approval, no code for anything seen (rule 1). Each state a board draws gets a `LaunchState` and its
  pictures in the pull request, both appearances where the board has both (D7). What no board redraws stays as Phases 11
  and 12 built it. The three Phase 13 boards (decision 31) are built only once approved.
- Nothing from V1 is renamed, dropped or narrowed in the model (D56, D26). Migration 0021 is additive and never edits
  0001 to 0020: new columns have defaults or are nullable; `keep_artefact` and `start_ai_generation` are replaced with the
  same arguments plus one that defaults, so build 23's calls still resolve. `types.ts` regenerated and committed with it.
- A new or replaced function: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute
  … to authenticated`; a test for each path it refuses. No `security definer` beyond `is_member` and `delete_account`
  (D37). No service-role key, no server job, no cron (D37, D60): the app reads the inbox and makes the plan.
- The API runs each call as the user (D5); inputs are zod schemas; a route validates first (400 with the issues);
  `start_ai_generation` gates each call (the monthly allowance; a student's consent for a personal kind); one model per
  kind, no fallbacks (D35, D63). The API reads no table but `ai_generations`: the app passes what it read.
- Nothing about a student goes to the AI without consent (D62): `parse-school` carries the school's own words and no
  student id; the mock is made from portions at a level for no one student; marking a mock and Test tomorrow in a
  parent's language name the student and need the recorded consent, which the gate enforces and the app checks first;
  the English Test tomorrow is a template on the phone and needs no call. A test holds each side.
- No textbook text anywhere (D58): chapter and skill names and the school's own message go to Claude; nothing from
  inside a book.
- No photo is stored by the API; a confirmed item's photo is uploaded by the app to `photos/<centre>/item/<uuid>.jpg`
  after Add (the Phase 10 contract), and removed with its item.
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4: `School` is its
  own target reached by AppShell's routes; Today's To parents row opens School's sheet through AppShell; the mock and
  gap report screens are `Artefacts`'; the Marks section is `Students`'; the rules are Domain's); tokens only (D10; a
  value a board uses that `design-tokens.md` does not name is added to the document and to `Tokens` in the same commit,
  D25); Swift Testing in the test targets, a new `SchoolTests` target in `Package.swift` and `project.yml`.
- No technical words on screen (D41): each new sentence passes `ErrorWordsTests`; each message is one of
  `docs/design/feedback.md`'s rows (a failed or refused write is the system alert; a list that could not load says so in
  its place; a success shows in place; the toast is for Undo only).
- Text limits count Unicode scalars (D48). Both appearances (D13). Dynamic Type through `AdaptiveRow` and
  `growsWithText()` where a row puts a value beside a title.
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull requests
  with pictures; documents directly to `main` (D12), never mixed with code.
- Plain voice in documents and comments; the word is Students, not Children; "Batch" on screen for V1's class.

## Decisions this plan takes

Small decisions, written here so they are not re-decided. The owner's are marked.

1. **Items are kept only after the tutor's Add.** A share, a photo or a pasted message is read by `/ai/parse-school` into
   drafts shown on "Check what was read"; nothing is written before Add (`confirmed_at` set in the same insert). A draft
   with no date, or no one to be for, is shown unticked with the fact missing in `text3` ("Date · not given"; "For ·
   choose") and Add counts only complete ticked items. The inbox file is removed once its items are added or the screen
   is left with Cancel (the dialog "Leave without adding?" of Scan register's pattern); offline, the inbox is left in
   place and the alert says it will be read when the connection is back (`OfflineRefusal.readSchool`).
2. **Who an item is for** (`ItemAudience`): one student; a school's class (`school_id` and `class_level`, as 0011 made
   it); or a school, every class (`school_id` with `class_level` null: the Confirm board's "Vidya Niketan, every class",
   a holiday's usual shape). An item for a school's class reaches every active student of that school and class, now and
   later (a student added to the class next week sees it); an item for a class no student is in is kept and its line
   reads "No one in class 8 there yet". The parser names a class level, a school and a student when the message does;
   the app resolves them to the centre's schools and students by name (case-insensitive, whole words), and the For tile
   reads "Choose" when it cannot.
3. **What an item holds** beyond 0011 (migration 0021): `title` (120, from the parser or the tutor), `end_date` (a
   holiday's last day), `source` (shared text, shared photo, a photo from the app, pasted, typed) and `received_at`, so
   the page reads "Shared on Wed 7 Oct, 15:04" (the board's "from WhatsApp" is not knowable from the share: an
   extension sees no sender app, so the word is "Shared"). Portions are held to 500 characters by the app and the API
   (the board's counter); 0011's 2000 stays (no narrowing, D26).
4. **The list** shows items from today on, grouped This week (to Sunday), Next week, Later, each group by date then title;
   an exam's line carries the countdown ("in 9 days", "tomorrow", "today"); a holiday's "to Wed 21 Oct". Past items leave
   the list but stay in the calendar and on the student's page. The calendar is the Phase 4 month card with a dot per day
   in the kind's colour (exam `overdue`, homework `accentText`, holiday `ok`, notice `text3`) and the chosen day's items
   under it. The tab's copy on the iPhone (`cache-<centre>-school.json`, D39) shows offline with the status line; every
   write is refused offline in words (`OfflineRefusal.schoolItem`).
5. **The "+" menu:** From a photo (the camera or Photos, V1's `PhotoPicker`, reduced by `PhotoReducer`), Paste a message
   (the pasteboard's text; with none, the alert "Nothing to paste. Copy the school's message first."), Add by hand (the
   item's sheet, empty), Ask parents to forward (the pushed screen). Add from a photo on the empty card is From a photo.
6. **The item's sheet** (to check an item, Edit on the page, Add by hand): Kind chips, Title, For (a tile opening the For
   sheet: the centre's schools each with their classes and student counts, "every class" per school, or one student),
   Subject (typed, with `Subject.common` offered as the textbook sheet does), Date and, for a holiday, To (the Phase 3
   day tiles), Portions (500, the counter), Remove this item. Save needs a kind, a title, who it is for and a date; an
   exam needs a subject too.
7. **Deleting an item** asks with the dialog in the board's words; the item's photo is removed from Storage; artefacts
   that served it (the mock, a gap report) keep their rows with `school_item_id` set null (0011); marks stay ("What was
   already taught stays in the record"); today's plan for a batch the item's students are in is made again when it is
   not closed (decision 15), so the preparation lines leave the plan.
8. **The exam window** is 14 days (`ExamPreparation.windowDays`); "unless the tutor sets another" waits: no board draws a
   field for it on the item's sheet, so the setting needs a board first (left for later, below). Class 10's two dates
   need no rule of their own: the nearest exam of a subject within the window drives the lines, and when it passes the
   next one does; a test pins it with a pre-board and a board exam of one subject.
9. **The split of portions across days** (`ExamPreparation`, Domain, pure): the portions text is cut into parts at "·",
   ";", new lines and "Ch n" markers; each part is matched to the student's chapters by name (case-insensitive, either
   contains the other, after the "Ch n" prefix is dropped) to give the day its skills, else the part's own words stand
   as the skill. The days are the batch's meeting days from today to the day before the exam, less the days its students
   are on holiday. With three days or more, the last meeting day at or before two days before the exam is the mock day,
   the days after it to the exam are after-mock days (the gap report's lines), and the parts spread over the days before
   the mock day in order: a part over k days is cut into k runs of its skills ("first half" and "second half" for two,
   "part i of k" for more); with fewer days than parts, a day takes several parts joined by " · ". With one or two days,
   every day is revision and there is no mock. The exam day itself is "The test".
10. **Exam groups on Today.** Students of one exam item within the window form a group of their own, nearest exam first,
    at most two such groups when other students remain (so a level group is left for them), else up to three; the rest
    are cut by level as Phase 12 does into the groups left. An exam group's subject is the exam's, its chapter the exam's
    title, its skill the day's portion title (`PlanGroup.examItemID` set; the Today card's head reads "Group 1 · Science
    unit test 3 · Class 8 · 3 students", P13-Today-Revision). A student of a third exam item keeps their level group, and
    the subject rule already picks the exam's subject for them. Lines: Teach "Revise: <portion>" ("The mock · 25 marks ·
    40 minutes" on the mock day; the gap plan's line, else "Revise: what the mock showed", after it), Practise "Revision
    set n" (n counts the exam's revision days), Check "Check 3", Homework "Revision sheet n" (none on the mock day); no
    worked example, figure or brief lines for an exam group. A revision line's words are cut to 200 characters at a word
    (the Phase 12 minor on `plan_items.words`).
11. **The exam group's material** (`ArtefactBudget`): the checks on the day's skills (at most three, else the portion
    title), the set and the homework sheet from the day's skills (a sheet's `skills` takes the portion words when no
    chapter matched); on the mock day the mock in the set's place (`ArtefactRequest.mock`), made once per exam item
    (`mocksMade`: items whose mock exists; the plan links the existing one) and shared by its students, so a class of
    three costs one mock; after the mock the set comes from the group's weakest skills in the gap tallies (up to six),
    else the portions once more. Checks match the students' skills by name first, then by the answer's order (the Phase
    12 minor).
12. **The mock's pattern** (`MockPattern`): the board's blueprint (`syllabi.blueprint`, read for the student's board, class
    and subject) for class 10; else a default by class (LKG to 5: 20 marks, 30 minutes; 6 and 7: 25 marks, 40 minutes; 8
    and 9: 40 marks, 60 minutes; class 10 without a blueprint: 80 marks, 180 minutes), sections chosen by the model
    within the marks. "From the school's earlier papers" waits: nothing in the model holds a school's paper, and reading
    one needs a route and a board (left for later, below). The mock's title is the exam's; the API refuses an answer whose
    marks do not sum to the pattern's (an unfit answer, 422 in the figure's way) and the plan goes on without the mock.
13. **Marking a mock** goes through V1's Check a paper (D36 keeps it in AITools) with a preset: the student (one of the
    exam's) and the scheme `.mock(generationID, artefactID)`; the scheme step is skipped. The API's mock scheme names the
    mock's generation (`{ kind: "mock", generationId }`, as a paper's does: the key is in `ai_generations.output`, which
    is the one table the API reads; the skeleton's `artefactId` goes, since no build sent it) and the body carries
    `studentId`, so `start_ai_generation` asks the student's consent (migration 0021; the centre's consent stands for
    V1's calls without a student). Save writes a `marks` row (subject, test "<title> · mock", today, the score and the
    max, the per-question marks and skills, the mock and the exam) and V1's line on the notes as before; Undo removes
    both. A student without consent sees Mark from a photo disabled with the consent line under it ("Marking <name>'s
    paper waits for <parent>'s consent", the consent section's words).
14. **Checked papers become marks too:** Check a paper's Save with a paper created here (its subject known) writes a
    `marks` row (test: the paper's title; subject: the paper's); a typed scheme has no subject and writes none (Phase 14's
    marks from a photo asks for it). School test marks arrive in Phase 14 (marks from a photo), so this phase's Marks
    section shows mocks and checked papers.
15. **The gap report** is made from the exam page's Marked row (quiet "Gap report") the first time it is opened: Domain
    tallies the marking by skill (`GapTallies`, from the mock's questions' skills), and `/ai/make` kind `gap_report`
    (Sonnet, the student's consent) writes the summary and the last days' lines (one to three, by the days left); it is
    kept as an artefact (kind `gap_report`, the student and the exam) so a second open costs nothing. "Use this plan"
    marks it used (`content.used_at`); the plan maker reads a used report for the student's after-mock lines and the
    group's set; "Leave it" changes nothing. Use this plan on a day whose plan is already made and not closed makes it
    again (decision 15). The marking's "By skill" rows are the app's arithmetic, not the model's.
16. **A plan already made follows the items:** an item added, changed or deleted today for students of a batch whose plan
    today is made and not closed makes that plan again (the Phase 12 "Make the plan again" path, its material made
    again), through an AppShell closure `schoolItemsChanged(students:)` that Today's plan stores answer; a closed plan
    is never touched; a plan not yet made needs nothing. The cost is the batch's material once more, on the day a message
    arrives; the material of a closed day is never remade.
17. **A holiday removes its students from the day's plan:** a student whose school (or class, or they themselves) is on
    holiday on the day is left out (`PlanDraft.leftOut`, as Leave out today does); when every member is on holiday no
    plan is made and Today shows the batch hero with no plan section (Phase 11's Today, which has its board) and the
    hero's line "Holiday at <school>" is not drawn (no board; the School tab says it). A holiday on a closed day changes
    nothing. The holiday's page lists the batch days it covers ("Mon 19, Tue 20 and Wed 21 Oct · Evening batch").
18. **Ask parents to forward** is a pushed screen from the "+" menu and the empty card: the message once (the board's
    words with the tutor's first name and the centre, editable, 600 characters), then one row per parent with a WhatsApp
    number (one row per number, the students' names joined when a parent has two), Send opening WhatsApp with the message
    and logging a `message_log` row of the new kind `forward_ask` (0021) per student of that parent, Sent in `ok` for a
    parent asked before, "2 of 7 sent" beside the title. Offline, Send is refused in words (no queue: D39's three kinds
    stand). The message is a hand send: it never counts in the cadence.
19. **Test tomorrow** is the two-language message sheet (P10-TestTomorrow) from the exam's page ("Test tomorrow" on the
    Preparation section's last row from the day before the exam) and from Today's To parents after the close. In English
    the message is Domain's template (no call, no consent: nothing leaves the phone; `TestTomorrowMessage`): "Hello
    <parent first name>, <child>'s <title, first letter lowered> is tomorrow (<weekday d Month>), from <portions>. This
    evening, let <him/her/them> go over <skill> once. Thank you." then the signature; without portions the second
    sentence is "This evening, a short revision will help."; the skill is the student's weakest among the portions'
    skills (revisit, then practising, then taught), else the sentence is left out. In Hinglish, Hindi or Kannada the
    message comes from `/ai/make` kind `test_tomorrow` (Haiku, the student's consent) with the English beside it; without
    consent the sheet shows the English message alone with the line "<parent>'s language needs consent; this is in
    English." Open WhatsApp logs `test_tomorrow` with the language and the body, then opens the link. The signature is the
    tutor's name and the centre, as the board draws; "Made with Tutor Central" on every message is Phase 14's (its scope
    item 6).
20. **The cadence** (`MessageCadence`, Domain, tested): at most three suggested messages a week per parent (Monday to
    Sunday, the centre's calendar), counting `note`, `can_do` and `test_tomorrow` rows across the parent's students (by
    number); the tutor's own sends never count. Where it holds this phase: a Test tomorrow row is not suggested on To
    parents when the parent's three are spent; the exam page's Test tomorrow is a hand send and always offered. Phase 14
    draws the held row (P10-Held).
21. **To parents after the close** (P10-Today-AfterClose, the 10.3 note): one row per message that goes now, the kind as
    the title (Test tomorrow, Absent today), the parent, the language and the detail, Send (primary on the first);
    Test tomorrow rows for the batch's students whose exam is tomorrow (consent or English), Absent today rows for the
    students marked absent who have a number (V1's absence alert sheet, logged as it is today). The weekly notes line is
    Phase 14's and is not drawn. Send opens School's Test tomorrow sheet through AppShell (`ShellState.testTomorrow`); the
    row reads Sent in `ok` once logged.
22. **The exam's page** (P10-School-Item): the hero (school, class and subject; the kind chip; the title; the date with the
    countdown; the portions), Who (the exam's students with the status word and their next step from `TrackingRules`),
    Preparation (one `PreparationRow` per day from today to the exam: the day column, the portion, what is made or done,
    a tick in `ok` for a day whose plan closed, Today as a chip, the Mock chip, the gap report's day; Change opens Today
    at the batch's plan, where lines are changed), What the school sent (the source well or the photo, and when it came),
    Delete this item. From the day before the exam the Preparation section ends with "Test tomorrow goes to parents on
    <weekday> evening" and the quiet Test tomorrow. Two days before the exam the page leads with the last days (P10-
    School-Exam-LastDays): Today (the mock, Ready or being made, Mark from a photo), Marked (each student: "14 of 25 ·
    <weakest skill> 3 of 10" and the quiet Gap report, or "Not marked yet"), The last two days. A homework's or notice's
    page has no Preparation; a holiday's says the batch days it covers.
23. **The mock's screen** (P10-Mock, `Artefacts`): the hero, the sections as V1's paper rows with the marks per question,
    the key behind the quiet Key, the footer: Make it again (one tap, the pattern once more), Share as PDF (the mock
    without its key unless the Key form shows, V1's `PDFMaker`), Mark from a photo (the primary; a student picker when the
    exam has several students, the Phase 6 picker limited to them). The gap report's screen (P10-GapReport): the score
    hero, By skill rows, The last two days, Use this plan with its footnote.
24. **The Marks section** (U36, P10-Student-Record and P13-Student-Marks): one row per mark, newest first, the test and
    subject, the school and date, the score "14 of 25" in `numberRow`, the compact chip "Below usual" (`due`) when the
    percentage is more than ten points under the mean of the student's earlier marks in that subject (two or more
    earlier); with none, the Kit's empty row "No marks yet" with the line "Marks from mocks and checked papers appear
    here." Add from a photo is Phase 14's and is not drawn until then (the new board draws the section without it). The
    page's School section lists the student's next five items by date with See all opening the School tab.
25. **The share hand-off:** `SharedInbox` is read when the app finishes launching signed in and on each return to the
    foreground (`refreshScreens`); an item found opens the School tab on "Check what was read" (a second item waits
    until the first is added or left); signed out, the inbox waits for sign-in; a file that is not an item is passed
    over (Phase 10). An image is read by content (`UIImage(data:)` takes HEIC) and reduced by `PhotoReducer` before
    it is sent. The deep link `tutorcentral://school/<item>` opens the item's page on the School tab.
26. **The API's new kinds,** one model each (D63; `api/src/models.ts` already names them): `parse_school` Sonnet, `mock`
    Sonnet, `gap_report` Sonnet, `test_tomorrow` Haiku; marking stays check-paper's Opus. No prompt caching this phase:
    the mock's prompt is under the cacheable minimum, so spec section 9's "cached for an hour" waits for a prompt long
    enough to pay for it.
27. **The parser's input** carries the message or the photo, today's date (so "Friday 16th Oct" becomes a day), the
    centre's school names and class levels (so "Class VIII B" and a named school resolve), and nothing about a student;
    its output is drafts with a kind, a title, a subject, a date (nullable), an end date, a class level, a school name and
    a student name as read from the message, and portions (500). An answer with no items is refused in words ("Couldn't
    find a test, homework, notice or holiday in this. Add it by hand.").
28. **The seed** (`seed.sql`, local only) gains Vidya Niketan's class 8 exam nine days out ("Science unit test 3", the
    seed's Science chapters 3 and 4 as portions), a class 8 homework due in five days, a Dasara holiday for the school in
    twelve days, a PTM notice for class 10, and two marks for Hemanth (the board's unit tests), so the hand runs meet the
    list, the exam page, the preparation and the Marks section. The fixtures hold the boards' items for the Evening batch.
29. **The cost run** (Task 27) spends real money once with the owner's yes: one mock (Sonnet), one marking of a two-page
    photo (Opus) and one gap report (Sonnet) for the seed's class 8 exam, read from `ai_generations` and written into the
    session record, "As built" and `PriceSheet.typical` (about ₹8 at the price sheet).
30. **Two Phase 12 items the owner ruled into this phase** (2026-10-11, "Agreed. proceed"): a new batch's first checks (the
    topic `/ai/plan` names is written as each member's chapter and skill, as the tutor's own chapter, so the first close
    has checks; the Phase 10 recapture rule keeps an own chapter behind a book captured later), and a group `/ai/plan`
    failed to name at the make is named by `complete()` on the next open or refresh through a small function that updates
    the plan's group and its teach lines without touching the artefact links. Both in one pull request after the School
    work (PR 10), so nothing waits on them. The other eight deferred minors stay deferred.
31. **The owner's to confirm:** the three Phase 13 boards drawn by session 27 on row 23 of the canvas (P13-School-Reading,
    the reading state no 10.5 board drew; P13-Today-Revision, Today's plan with an exam group, the one plan state no 10.3
    board drew; P13-Student-Marks, the Marks section as this phase builds it, without Phase 14's Add from a photo and with
    its empty row); and the cost run's spend before Task 27 runs it.
32. **Branches** `phase-13/<slug>` in the main checkout, one pull request each, as sessions 22, 24 and 26 worked.

### Left for later, with the reason

- A per-exam preparation window: the spec's "unless the tutor sets another" has no field on the approved item sheet; the
  14 days stand until a board draws one (a row for `plan/ui-polish.md`, added by Task 28).
- The mock "from the school's earlier papers": nothing in the model holds a school's paper; reading one needs a photo
  route and a board. Phase 15's Make something is where a photo of a past paper fits.
- School test marks from a report card: Phase 14's scope (marks from a photo).
- A held Test tomorrow shown as held, and "Made with Tutor Central" on every message: Phase 14's boards and scope.
- The School tab's list filtered to one student (the 10.2 note's "See all opens the list filtered"): no board draws a
  filter on the tab; See all opens the tab (a polish row, Task 28).

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A forwarded message with no date** ("Unit test next week, portions chapters 1 and 2"): the draft shows "Date · not
   given", unticked; the tutor sets the day on the item's sheet; Add counts it only then. Tests: Task 4
   (`SchoolItemRulesTests.aDraftWithoutADateIsNotComplete`), Task 13 (`ReadStoreTests.aDraftWithoutADateStaysUnticked`,
   `settingTheDateOnTheSheetTicksTheDraft`), Task 2 (`parse-school answers a null date when the message gives none`).
2. **An item for a class of a school no student is in** ("Class 9 at Vidya Niketan" with no class 9 student): kept, listed
   with "No one in class 9 there yet", no lines anywhere; a class 9 student added next week sees it on their page and in
   their plan. Tests: Task 4 (`SchoolItemRulesTests.anItemForAnEmptyClassReachesNoOneYet`,
   `aStudentAddedLaterIsReached`), Task 13 (`ReadStoreTests.anItemForAnEmptyClassIsKeptAndSaysSo`).
3. **Two schools in one batch** with exams the same week: two exam groups and one level group; each exam group's set is
   its own exam's; the third group's students follow the level rule. Tests: Task 6
   (`PlanRulesTests.twoExamsInOneBatchMakeTwoExamGroupsAndOneLevelGroup`,
   `aThirdExamKeepsItsStudentsInTheirLevelGroup`).
4. **Class 10's two dates** (a pre-board in the window and the board exam after it): the nearer drives the lines; after it
   passes, the next does. Tests: Task 4 (`SchoolItemRulesTests.theNearestExamOfASubjectDrivesThenTheNext`), Task 5
   (`ExamPreparationTests.aSecondExamAfterTheFirstIsNotSplitYet`).
5. **A holiday on a closed day,** and a holiday arriving today for a plan already made: a closed plan does not change; a
   plan made and not closed is made again without the students on holiday; a batch wholly on holiday shows no plan.
   Tests: Task 17 (`PlanStoreTests.aHolidayOnAClosedDayChangesNothing`, `aHolidayTodayRemakesAnOpenPlanWithoutThem`,
   `aBatchWhollyOnHolidayHasNoPlan`), Task 4 (`SchoolItemRulesTests.aHolidayCoversItsDays`).
6. **The share extension used signed out** (or before any account exists): the inbox keeps the item; after sign-in the
   School tab opens on "Check what was read"; a second share while one waits is read after the first. Tests: Task 14
   (`InboxHandoffTests.anInboxItemWaitsForSignIn`, `twoItemsAreReadOneAfterTheOther`), Task 8
   (`SharedInboxTests.removingAnItemLeavesTheOthers`).
7. **A mock marked for a student without consent,** and the gap report for one: Mark from a photo is disabled with the
   reason; the API refuses the call (403 consent) if one is made; the gap report is not offered. Tests: Task 1
   (`start_ai_generation asks the student's consent for a marking that names them`), Task 3 (`check-paper with a mock's
   key needs the student's consent`), Task 21 (`LastDaysTests.aStudentWithoutConsentCannotBeMarkedOrReported`).
8. **The exam in three days or fewer** (no room for a mock), and **the exam tomorrow**: every day is revision, no mock
   line, no Mock chip; the day before, Test tomorrow is offered. Tests: Task 5
   (`ExamPreparationTests.twoDaysLeaveNoRoomForAMock`, `theDayBeforeTheExamIsTheLastRevisionDay`), Task 16
   (`ToParentsTests.testTomorrowIsSuggestedTheEveningBefore`).

## File structure

Created or changed, by module. A file has one job; the stores are small and named for what they do.

| Module | File | Job |
|---|---|---|
| supabase | `migrations/20261026000021_v2_school_items_marks_mock.sql` | `school_items.title`, `end_date`, `source`, `received_at`; `marks.school_item_id`, `artefact_id`, `questions`; `message_kind` `forward_ask`; `keep_artefact` with `p_school_item`; `start_ai_generation` asking a student's consent for a marking that names them; `name_plan_group` |
| supabase | `tests/v2.test.ts` (a "school" block), `tests/rls.test.ts` (unchanged lists: no new table), `seed.sql` (the items and marks), `types.ts` | The function tests; the local data; the generated types |
| api | `src/schemas.ts` (`ParseSchoolInput` with `today`, `schools`, `classLevels`; `ParsedItem`, `ParseSchoolOutput`; the mock's `title`, `MockOutput`; `gap_report` input and `GapReportOutput`; `test_tomorrow` input and `TestTomorrowOutput`; `Scheme` mock by `generationId`; `CheckPaperInput.studentId`), `src/prompts/parse-school.ts`, `mock.ts`, `gap-report.ts`, `test-tomorrow.ts`, `check-paper.ts` (`schemeText` for a mock), `src/routes/ai.ts` (`/parse-school` live, check-paper's mock scheme and student), `src/routes/v2.ts` (`/make` mock, gap_report, test_tomorrow), `src/routes/common.ts` (`Call.student`), `src/db.ts` and `db-fake.ts` (`start` takes `student`), `src/claude-fake.ts` (four samples, `kindOf`), `src/errors.ts` (the parser's and the mock's refusal words), `test/v2.test.ts`, `test/ai.test.ts`, `test/schemas.test.ts`, `test/prompts.test.ts`, `test/claude-fake.test.ts` | The routes live |
| Domain | `School/SchoolItem.swift` (`SchoolItemKind`, `SchoolItemSource`, `ItemAudience`, `SchoolItem`, `SchoolItemDraft`), `School/SchoolItemRules.swift`, `School/ExamPreparation.swift` (`PreparationDay`, the split), `School/MockPattern.swift`, `School/MessageCadence.swift`, `School/TestTomorrowMessage.swift`, `School/ForwardAskMessage.swift`, `School/HolidayRules.swift`, `Record/Mark.swift` (`MarkRecord`, `NewMark`, `MarkRules`), `Plan/Artefact.swift` (`MockContent`, `GapReportContent`, `.mock`, `.gapReport`), `Plan/GapTallies.swift`, `Plan/PlanTypes.swift` (`PlanGroup.examItemID`, `PlanInput.revisions`, `holidays`, `RevisionLine`), `Plan/PlanRules.swift` (exam groups, revision lines, left out on holiday, the 200-character cut), `Plan/ArtefactBudget.swift` (`.mock`, the exam group's requests), `Queue/OfflineRefusal.swift` (`.schoolItem`, `.readSchool`, `.forwardAsk`, `.mark`, `.gapReport`), `CheckResult.swift` (`SchemeSource.mock`) | The rules and the shapes |
| Data | `School/SchoolItemsRepository.swift`, `SupabaseSchoolItemsRepository.swift`, `SchoolItemRow.swift`, `FakeSchoolItemsRepository.swift`, `School/SchoolCache.swift`, `Record/RecordRepository.swift` (marks), `SupabaseRecordRepository.swift`, `FakeRecordRepository.swift`, `Messages/*` (`logTestTomorrow`, `logForwardAsk`, `forwardAsked`, `entries(since:)`), `Photos/PhotoStore.swift` (`remove`), `Plans/PlansRepository.swift` (`ArtefactLink.schoolItem`, `mock(for:)`, `gapReport(for:student:)`, `setContent`, `nameGroup`), `SupabasePlansRepository.swift`, `FakePlansRepository.swift`, `AI/AIRepository.swift` (`parseSchool`, `makeMock`, `makeGapReport`, `makeTestTomorrow`, `checkPaper` with the student), `AI/APIClient+School.swift`, `AI/APIBodies.swift`, `AI/FakeAIRepository.swift`, `AI/AISamples+School.swift`, `Textbooks/TextbooksRepository.swift` (`addNamedChapter`) | The reads and writes behind the screens |
| DesignSystem | `Components/KindChip.swift`, `SchoolRow.swift`, `ItemCard.swift` (with `FactLine`), `SourceWell.swift`, `PreparationRow.swift`, `ParentSendRow.swift`, `TwoLanguageMessageSheet.swift`, `ScoreHero.swift`, `SkillBarRow.swift`, `CalendarMonth.swift` (dots by kind), `Tokens/Tokens.swift` and `docs/design/design-tokens.md` where a board's value is new | The 10.5 and 10.4 parts this phase uses |
| Features/School (new) | `SchoolActions.swift`, `SchoolStore.swift`, `SchoolView.swift`, `SchoolSections.swift`, `SchoolCalendarSection.swift`, `ReadStore.swift`, `ReadStore+Resolve.swift`, `ReadView.swift`, `ItemFormStore.swift`, `ItemFormSheet.swift`, `ForSheet.swift`, `ItemStore.swift`, `ItemView.swift`, `ItemSections.swift`, `PreparationSection.swift`, `LastDaysSections.swift`, `AskStore.swift`, `AskView.swift`, `TestTomorrowStore.swift`, `TestTomorrowSheet.swift`, `SchoolWords.swift` | The School tab and its screens |
| Features/Artefacts | `MockStore.swift`, `MockView.swift`, `GapReportStore.swift`, `GapReportView.swift`, `ArtefactScreen.swift` (two kinds more), `ArtefactRead.swift` | The mock and the gap report |
| Features/Today | `PlanMaker.swift` (items, revisions, holidays, the mock made once, the named topic written), `PlanMaker+Calls.swift` (`.mock`), `PlanMaker+Exam.swift`, `PlanStore.swift` (`.holiday`, remake on items changed, `complete` names groups), `TodayStore.swift` and `TodayStore+Parents.swift` (To parents rows, the cadence), `TodaySections.swift` (To parents) | The plan in exam mode; To parents |
| Features/Students | `RecordSections.swift` (`MarksSection`, the School section's rows), `StudentDetailStore+Record.swift` (marks, items), `StudentDetailView.swift` | U36; the page's School section |
| Features/AITools | `CheckStore.swift` (`CheckPreset`), `CheckStore+Marks.swift` (the marks row), `CheckIntroView.swift` (the picker limited), `CheckPagesView.swift` (Check goes straight to checking with a preset) | Marking a mock |
| AppShell | `TabsState.swift` (`Route.schoolRead`, `.schoolItem(UUID)`, `.schoolAsk`), `TabsView.swift`, `RootView+School.swift`, `RootView+Today.swift`, `RootView+Artefacts.swift`, `RootView+AITools.swift` (the preset), `RootView+LaunchStates.swift`, `LaunchState.swift`, `Fixtures+School.swift`, `ShellState.swift` (`inboxHandoff`, `testTomorrow`, `schoolItemsChanged`), `DeepLink.swift` (`.school(UUID)`), `Dependencies.swift` (`schoolItems`), `SharedInbox.swift` (`remove`, `image`), `Package.swift`, `project.yml` | The shell |
| Tests | `supabase/tests/v2.test.ts`; `api/test/{v2,ai,schemas,prompts,claude-fake}.test.ts`; `DomainTests/{SchoolItemRulesTests, ExamPreparationTests, MockPatternTests, MessageCadenceTests, TestTomorrowMessageTests, ForwardAskMessageTests, HolidayRulesTests, MarkRulesTests, GapTalliesTests, PlanRulesExamTests, ArtefactBudgetExamTests, ArtefactContentTests (mock, gap report), OfflineRefusalTests}`; `DataTests/{SchoolItemRowTests, FakeSchoolItemsRepositoryTests, SchoolCacheTests, MarkRowTests, APIBodiesSchoolTests, FakeAIRepositorySchoolTests, SharedInboxTests}`; `SchoolTests/{SchoolStoreTests, ReadStoreTests, ItemFormStoreTests, ItemStoreTests, PreparationTests, LastDaysTests, AskStoreTests, TestTomorrowStoreTests}`; `TodayTests/{PlanMakerExamTests, PlanStoreTests (holiday, remake, named), ToParentsTests, FirstChecksTests}`; `ArtefactsTests/{MockStoreTests, GapReportStoreTests}`; `StudentsTests/{MarksSectionTests}`; `AIToolsTests/{CheckPresetTests}`; `AppShellTests/{InboxHandoffTests, DeepLinkTests, LaunchStateTests}`; `DesignSystemTests/{CalendarDotsTests, TokenDocumentTests}` | |

## Launch states

Each state the 10.5 boards name, the mock and gap report of 10.4, the Marks of 10.2, To parents of 10.3, and the three
Phase 13 boards', with the fixtures' data (the clock Wednesday 7 October 2026, 16:35, India, unless the state says
another). Light twins from `--appearance light` where the board has both. The fixtures' Evening batch (Dev, Meher, Nikhil
in class 8 at Vidya Niketan; Riya in class 5; Sahil in class 2) has the boards' items: "Science unit test 3" for class 8
at Vidya Niketan on Friday 16 October (portions the fixtures' Chemical reactions and Acids, bases and salts), "Maths Ex
3.2, Q1 to 10" homework due Monday 12 October, "Dasara holidays" for Vidya Niketan Monday 19 to Wednesday 21 October, a
PTM notice for class 10 on Friday 9 October, and Dev's own "Science unit test" on Thursday 8 October (for Test tomorrow).

| State | Shows | Board | PR |
|---|---|---|---|
| `school-empty` | The School tab with nothing yet (supersedes `later-school`) | P10-School-Empty (both) | 5 |
| `school` | The list: This week, Next week, Later | P10-School-List (both) | 5 |
| `school-calendar` | The calendar with Friday 16 October chosen | P10-School-Calendar | 5 |
| `school-add-menu` | The "+" menu | P10-School-AddMenu | 5 |
| `school-reading` | What the school sent being read: the source well, the creating card | P13-School-Reading | 5 |
| `school-confirm` | The three items read from the board's message | P10-School-Confirm | 5 |
| `school-confirm-edit` | The exam's sheet over the list to check | P10-School-Confirm-Edit | 5 |
| `school-item-homework` | The homework's page (no Preparation) | P10-School-Item without its Preparation (the 10.5 note) | 5 |
| `school-item-holiday` | The holiday's page with the batch days it covers | P10-School-Item, the 10.5 note | 5 |
| `student-end` | Hemanth's page scrolled to School with his items | P10-Student-End | 5 |
| `school-ask` | Ask parents to forward, two sent | P10-School-Ask | 6 |
| `school-test-tomorrow` | The Test tomorrow sheet over Dev's exam (Hindi, English beside) | P10-TestTomorrow | 6 |
| `today-after-close` | 18:40: the closed hero, To parents (Dev's Test tomorrow, Nikhil absent), no notes line | P10-Today-AfterClose (the 10.3 note) | 6 |
| `school-item` | The exam's page with Who and Preparation | P10-School-Item | 7 |
| `school-item-edit` | The item's sheet over the page | P10-School-Item-Edit | 7 |
| `school-item-delete` | The delete dialog | P10-School-Item-Delete | 7 |
| `today-revision` | Today's plan with Group 1 as the exam group and its revision lines | P13-Today-Revision (both) | 7 |
| `mock` | The mock with its sections | P10-Mock | 8 |
| `gap-report` | Dev's gap report after the mock | P10-GapReport | 8 |
| `school-last-days` | Wednesday 14 October 16:35: the exam in two days, the mock ready, Dev and Meher marked | P10-School-Exam-LastDays | 8 |
| `student-marks` | Hemanth's page scrolled to Marks: two rows, one below usual (both); and the empty section for Riya | P13-Student-Marks (both), P10-Student-Record | 9 |

`later-school` is retired: its content is `school-empty`.

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-13/db` | Database: what an item holds, marks from a mock, the forward ask's kind, the mock's and gap report's keep, a marking's consent; the seed's items and marks | none |
| 2 | 2, 3 | `phase-13/api` | The API: `/ai/parse-school`; `/ai/make` mock, gap report and test tomorrow; check-paper with a mock's key and the student's consent | none |
| main | | | `gh workflow run deploy` after PR 2: 0021 up, the API at `main`'s head (Task 27) | |
| 3 | 4, 5, 6, 7 | `phase-13/domain` | Domain: items and who they reach, the exam window and split, the mock's pattern, exam groups and revision lines, the holiday rule, the cadence, the messages, marks, the mock and gap report contents | none |
| 4 | 8, 9, 10 | `phase-13/data` | Data: items and their copy, marks, the message log's kinds, photos removed, the mock and gap report kept, the API client's five calls; the write proofs | none |
| 5 | 11, 12, 13, 14 | `phase-13/school-tab` | School: the tab (empty, list, calendar, the menu), Check what was read from a share, a photo, the pasteboard or by hand, the item's sheet, an item's page, delete; the hand-off; the student page's School section | `school-empty` (both), `school` (both), `school-calendar`, `school-add-menu`, `school-reading`, `school-confirm`, `school-confirm-edit`, `school-item-homework`, `school-item-holiday`, `student-end` |
| 6 | 15, 16 | `phase-13/parents` | Ask parents to forward; Test tomorrow in two languages; To parents after the close | `school-ask`, `school-test-tomorrow`, `today-after-close` |
| 7 | 17, 18 | `phase-13/exam-preparation` | Exam preparation: the plan in exam mode (exam groups, revision lines, the daily set, holidays, a plan remade when an item changes), the exam's page with Preparation | `school-item`, `school-item-edit`, `school-item-delete`, `today-revision` (both) |
| 8 | 19, 20, 21 | `phase-13/mock-and-gap` | The mock two days before, marking from a photo, marks; the gap report and the last days | `mock`, `gap-report`, `school-last-days` |
| 9 | 22 | `phase-13/student-marks` | U36: the Marks section on the student's page | `student-marks` (both) |
| 10 | 23, 24 | `phase-13/first-checks` | A new batch's first checks: the named topic as each member's chapter and skill; an unnamed group named at the next open (the owner, 2026-10-11) | none (what is seen is Phase 12's) |
| main | 25, 26, 27, 28 | | The runbook's share path, the device tests, the deploy, the hand runs, the cost run, the review, TestFlight, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked, the pictures by
`bun shots <state>` and `bun pr-shots` (rule 2). PRs 5, 7 and 9 build to the three Phase 13 boards, which are approved
before they start (decision 31).

---

### Task 1: Migration 0021: what an item holds, marks from a mock, the forward ask's kind, the keeps, a marking's consent, a group's name; the seed (PR 1)

**Files:**
- Create: `supabase/migrations/20261026000021_v2_school_items_marks_mock.sql`
- Modify: `supabase/tests/v2.test.ts` (a "school" block at the end), `supabase/seed.sql` (the items and marks),
  `supabase/types.ts` (regenerated)

**Interfaces:**
- Consumes: migrations 0011 (`school_items`, `marks`, `message_kind`), 0013 (`start_ai_generation`), 0019
  (`keep_artefact`, `make_plan`).
- Produces: `school_items.title text` (120, default ''), `end_date date` (not before `date`), `source text`
  (`shared_text`, `shared_photo`, `photo`, `pasted`, `typed`; default `typed`), `received_at timestamptz` (default now);
  `marks.school_item_id uuid`, `marks.artefact_id uuid`, `marks.questions jsonb` (an array); `message_kind` value
  `forward_ask`; `keep_artefact(p_centre, p_artefact, p_plan, p_group_no, p_student, p_item_kind, p_school_item uuid
  default null) returns uuid` (a null `p_plan` links no line); `start_ai_generation(p_centre, p_kind, p_input, p_model,
  p_student default null)` refusing `check_paper` for a student without consent; `name_plan_group(p_centre, p_plan,
  p_group_no, p_chapter, p_skill) returns void`.

- [ ] **Step 1: Write the failing tests** (append to `supabase/tests/v2.test.ts`; `a`, `centre` and `stamp` are the file's)

```ts
// ---- Phase 13: what an item holds, marks from a mock, the keeps, a marking's consent, a group's name ----
test("an item holds its title, a holiday's last day, how it came and when; the checks hold", async () => {
  const school = (await a.from("schools").insert({ centre_id: centre, name: `Item School ${stamp}` }).select("id").single()).data!;
  const ok = await a
    .from("school_items")
    .insert({ centre_id: centre, school_id: school.id, kind: "holiday", title: "Dasara holidays", date: "2026-10-19", end_date: "2026-10-21", source: "shared_text", source_text: "School will remain closed 19th to 21st Oct for Dasara." })
    .select("title, end_date, source, received_at, class_level")
    .single();
  expect(ok.error).toBeNull();
  expect(ok.data).toMatchObject({ title: "Dasara holidays", end_date: "2026-10-21", source: "shared_text", class_level: null });
  expect(ok.data!.received_at).toBeTruthy();
  const old = await a.from("school_items").insert({ centre_id: centre, kind: "notice", date: "2026-10-20" }).select("title, source").single();
  expect(old.data).toEqual({ title: "", source: "typed" });
  expect((await a.from("school_items").insert({ centre_id: centre, kind: "holiday", title: "X", date: "2026-10-21", end_date: "2026-10-19" })).error).not.toBeNull();
  expect((await a.from("school_items").insert({ centre_id: centre, kind: "notice", title: "X", date: "2026-10-20", source: "fax" })).error).not.toBeNull();
  expect((await a.from("school_items").insert({ centre_id: centre, kind: "notice", title: "x".repeat(121), date: "2026-10-20" })).error).not.toBeNull();
});

test("a mark from a mock names the exam, the mock and its questions; deleting the exam keeps the mark", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Mocked", class_level: "8" }).select("id").single()).data!;
  const exam = (await a.from("school_items").insert({ centre_id: centre, student_id: st.id, kind: "exam", title: "Science unit test 3", subject: "Science", date: "2026-10-16" }).select("id").single()).data!;
  const mock = (await a.from("artefacts").insert({ centre_id: centre, kind: "mock", title: "Science unit test 3", school_item_id: exam.id }).select("id").single()).data!;
  const questions = [{ number: 1, marks: 1, of: 1, skill: "Spot a chemical change" }, { number: 2, marks: 0, of: 3, skill: "Balance a chemical equation" }];
  const mark = await a
    .from("marks")
    .insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "Science unit test 3 · mock", date: "2026-10-14", score: 14, max: 25, school_item_id: exam.id, artefact_id: mock.id, questions })
    .select("id, questions")
    .single();
  expect(mark.error).toBeNull();
  expect(mark.data!.questions).toEqual(questions);
  expect((await a.from("marks").insert({ centre_id: centre, student_id: st.id, subject: "Science", test: "x", date: "2026-10-14", score: 1, max: 2, questions: { a: 1 } })).error).not.toBeNull();
  expect((await a.from("school_items").delete().eq("id", exam.id)).error).toBeNull();
  const kept = await a.from("marks").select("school_item_id, score").eq("id", mark.data!.id).single();
  expect(kept.data).toEqual({ school_item_id: null, score: 14 });
});

test("message_log takes forward_ask", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Asked" }).select("id").single()).data!;
  expect((await a.from("message_log").insert({ centre_id: centre, student_id: st.id, kind: "forward_ask", channel: "whatsapp_link" })).error).toBeNull();
});

test("keep_artefact links an artefact to an exam with no plan, and the six-argument call still works", async () => {
  const st = (await a.from("students").insert({ centre_id: centre, name: "Kept", class_level: "8" }).select("id").single()).data!;
  const exam = (await a.from("school_items").insert({ centre_id: centre, student_id: st.id, kind: "exam", title: "Unit test", subject: "Science", date: "2026-10-16" }).select("id").single()).data!;
  const mock = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "mock", title: "Unit test", content: { title: "Unit test" } }, p_plan: null, p_group_no: null, p_student: null, p_item_kind: "practise", p_school_item: exam.id });
  expect(mock.error).toBeNull();
  const row = await a.from("artefacts").select("school_item_id, plan_id, student_id").eq("id", mock.data as string).single();
  expect(row.data).toEqual({ school_item_id: exam.id, plan_id: null, student_id: null });
  const report = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "gap_report", title: "After the mock", content: { summary: "x" } }, p_plan: null, p_group_no: null, p_student: st.id, p_item_kind: "practise", p_school_item: exam.id });
  expect(report.error).toBeNull();
  expect((await a.from("artefacts").select("student_id").eq("id", report.data as string).single()).data).toEqual({ student_id: st.id });
  const six = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "sheet", title: "Sheet", content: {} }, p_plan: null, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  expect(six.error).toBeNull();
  expect((await a.from("artefacts").select("school_item_id").eq("id", six.data as string).single()).data).toEqual({ school_item_id: null });
});

test("start_ai_generation asks the student's consent for a marking that names them, and the centre's for one that does not", async () => {
  const without = (await a.from("students").insert({ centre_id: centre, name: "No consent" }).select("id").single()).data!;
  const withIt = (await a.from("students").insert({ centre_id: centre, name: "Consent", consent_at: new Date().toISOString(), consent_phone: "+919876543210", consent_how: "in_person" }).select("id").single()).data!;
  await a.from("centres").update({ ai_consent_at: new Date().toISOString() }).eq("id", centre);
  const refused = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "check_paper", p_input: { pages: 1 }, p_model: "claude-opus-5-5", p_student: without.id });
  expect(refused.error?.message).toContain("ai_consent_missing");
  const allowed = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "check_paper", p_input: { pages: 1 }, p_model: "claude-opus-5-5", p_student: withIt.id });
  expect(allowed.error).toBeNull();
  const v1 = await a.rpc("start_ai_generation", { p_centre: centre, p_kind: "check_paper", p_input: { pages: 1 }, p_model: "claude-opus-5-5" });
  expect(v1.error).toBeNull();
});

test("name_plan_group names a plan's group and its teach lines, leaves the artefact links, and refuses a non-member", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const made = await a.rpc("make_plan", {
    p_centre: centre, p_class: cls.id, p_date: "2026-10-20",
    p_groups: [{ group_no: 1, subject: "Science", chapter: "", skill: "" }],
    p_subjects: { "1": "Science" },
    p_items: [
      { student_id: s1.id, group_no: 1, kind: "teach", words: "Teach: with the group" },
      { student_id: s2.id, group_no: 1, kind: "teach", words: "Teach: with the group" },
      { student_id: s1.id, group_no: 1, kind: "homework", words: "Homework sheet 1" },
    ],
  });
  const plan = (made.data as { plan_id: string }).plan_id;
  const sheet = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "sheet", title: "Sheet", content: {} }, p_plan: plan, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  const named = await a.rpc("name_plan_group", { p_centre: centre, p_plan: plan, p_group_no: 1, p_chapter: "Chemical reactions", p_skill: "Balance a chemical equation" });
  expect(named.error).toBeNull();
  const groups = (await a.from("plans").select("groups").eq("id", plan).single()).data!.groups as { chapter: string; skill: string }[];
  expect(groups[0]).toMatchObject({ chapter: "Chemical reactions", skill: "Balance a chemical equation" });
  const items = (await a.from("plan_items").select("kind, words, artefact_id").eq("plan_id", plan).order("kind")).data!;
  expect(items.find((i) => i.kind === "homework")).toMatchObject({ artefact_id: sheet.data, words: "Homework sheet 1" });
  expect(items.filter((i) => i.kind === "teach").map((i) => i.words)).toEqual(["Teach: Balance a chemical equation", "Teach: Balance a chemical equation"]);
  const b = await userClient(l, `v2-b13-${stamp}@example.com`);
  const other = await b.rpc("name_plan_group", { p_centre: centre, p_plan: plan, p_group_no: 1, p_chapter: "x", p_skill: "y" });
  expect(other.error).not.toBeNull();
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd supabase && supabase db reset >/dev/null && bun test tests/v2.test.ts`
Expected: the six new tests FAIL (`title` is not a column; `p_school_item` is not an argument; `name_plan_group` does not
exist; the marking with a student is allowed).

- [ ] **Step 3: Write the migration**

```sql
-- Phase 13 (docs/spec-v2.md sections 5, 6 and 8; plan/phase-13-plan.md Task 1). Additive (D26): columns with defaults or
-- nullable, one enum value, two functions replaced with one more argument that defaults (build 23's calls resolve), one
-- new function. Nothing from 0001 to 0020 is edited.

-- 1. What the boards show on an item that 0011 did not hold: the title, a holiday's last day, how it reached the app and
--    when (an extension cannot name the sender app, so the words are "Shared", not "from WhatsApp").
alter table public.school_items
  add column title text not null default '' check (char_length(title) <= 120),
  add column end_date date check (end_date is null or end_date >= date),
  add column source text not null default 'typed'
    check (source in ('shared_text', 'shared_photo', 'photo', 'pasted', 'typed')),
  add column received_at timestamptz not null default now();

-- 2. A mark from a marked mock: the exam, the mock and the marks per question (the gap report's input). The exam and the
--    mock may go; the mark stays ("what was already taught stays in the record").
alter table public.marks
  add column school_item_id uuid,
  add column artefact_id uuid,
  add column questions jsonb check (questions is null or jsonb_typeof(questions) = 'array'),
  add foreign key (centre_id, school_item_id) references public.school_items(centre_id, id) on delete set null (school_item_id),
  add foreign key (centre_id, artefact_id) references public.artefacts(centre_id, id) on delete set null (artefact_id);

-- 3. Ask parents to forward is logged once per parent (P10-School-Ask's Sent marks).
alter type public.message_kind add value 'forward_ask';

-- 4. keep_artefact links the mock and the gap report to the exam they serve; with no plan it links no line. The
--    six-argument call of build 23 resolves through the default.
drop function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind);

create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, school_item_id, title, content, photo_path,
                                generation_id, regenerated_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_school_item, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb),
          p_artefact->>'photo_path', (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid)
  returning id into v_id;
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid) to authenticated;

-- 5. Marking a paper that names a student needs the student's recorded consent (D62): check_paper with p_student set.
--    V1's call (no student) keeps the centre's consent and its daily rule; 0013's body otherwise unchanged.
drop function public.start_ai_generation(uuid, public.ai_kind, jsonb, text, uuid);

create function public.start_ai_generation(p_centre uuid, p_kind public.ai_kind, p_input jsonb, p_model text,
                                           p_student uuid default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare
  v_v1 public.ai_kind[] := array['paper', 'homework', 'worksheet', 'progress_note', 'scan_register', 'check_paper']::public.ai_kind[];
  v_personal public.ai_kind[] := array['note', 'can_do', 'test_tomorrow', 'gap_report']::public.ai_kind[];
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
                     'test_tomorrow', 'gap_report', 'parse_school', 'parse_textbook']::public.ai_kind[];
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

-- 6. A group /ai/plan could not name at the make is named later (plan decision 30): the group's chapter and skill in
--    plans.groups and the teach lines that still read "Teach: with the group"; the artefact links are not touched.
create function public.name_plan_group(p_centre uuid, p_plan uuid, p_group_no integer, p_chapter text, p_skill text)
returns void
language plpgsql security invoker set search_path = '' as $$
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if p_chapter is null or p_skill is null or char_length(p_skill) = 0 then
    raise exception 'a chapter and a skill are needed' using errcode = '22023';
  end if;
  update public.plans p
     set groups = (
       select coalesce(jsonb_agg(case when (g->>'group_no')::integer = p_group_no
                                      then g || jsonb_build_object('chapter', p_chapter, 'skill', p_skill) else g end), '[]'::jsonb)
         from jsonb_array_elements(p.groups) g)
   where p.centre_id = p_centre and p.id = p_plan;
  update public.plan_items i set words = left('Teach: ' || p_skill, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'teach'
     and i.words = 'Teach: with the group';
  update public.plan_items i set words = left(i.words || ' · then ' || p_skill, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'catch_up'
     and i.words not like '%· then %';
  update public.plan_items i set words = left('Your brief · ' || p_chapter, 200)
   where i.centre_id = p_centre and i.plan_id = p_plan and i.group_no = p_group_no and i.kind = 'brief'
     and i.words = 'Your brief';
end $$;

revoke all on function public.name_plan_group(uuid, uuid, integer, text, text) from public, anon;
grant execute on function public.name_plan_group(uuid, uuid, integer, text, text) to authenticated;
```

- [ ] **Step 4: The seed** (append to `supabase/seed.sql`, after the Evening batch; the dates are relative to the real day,
  as the seed's attendance is)

```sql
-- Phase 13: what Vidya Niketan sent, for the hand runs (the list, the exam's page, the preparation, the Marks section).
insert into public.school_items (id, centre_id, school_id, class_level, kind, title, subject, date, portions, source, source_text, received_at, confirmed_at) values
  ('66666666-6666-6666-6666-666666666661', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', '8',
   'exam', 'Science unit test 3', 'Science', current_date + 9, 'Ch 3 Chemical reactions · Ch 4 Force and pressure', 'shared_text',
   'Dear Parents, Science Unit Test 3 for Class 8 will be held on ' || to_char(current_date + 9, 'FMDay DDth Mon') || '. Portions: Ch 3 Chemical Reactions, Ch 4 Force and Pressure. Regards, Class Teacher, VIII B',
   now() - interval '1 hour', now() - interval '1 hour'),
  ('66666666-6666-6666-6666-666666666662', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', '8',
   'homework', 'Maths Ex 3.2, Q1 to 10', 'Mathematics', current_date + 5, null, 'shared_text', null, now() - interval '1 hour', now() - interval '1 hour'),
  ('66666666-6666-6666-6666-666666666663', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', null,
   'holiday', 'Dasara holidays', null, current_date + 12, null, 'shared_text', null, now() - interval '1 hour', now() - interval '1 hour'),
  ('66666666-6666-6666-6666-666666666664', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', '10',
   'notice', 'PTM, 10:00', null, current_date + 2, null, 'typed', null, now() - interval '1 hour', now() - interval '1 hour');
update public.school_items set end_date = current_date + 14 where id = '66666666-6666-6666-6666-666666666663';
-- Hemanth's marks (P10-Student-Record): unit test 2 below his usual.
insert into public.marks (centre_id, student_id, subject, test, date, score, max)
select s.centre_id, s.id, 'Mathematics', t.test, t.date, t.score, 25
  from public.students s, (values ('Unit test 1', current_date - 44, 19), ('Unit test 2', current_date - 9, 14)) as t(test, date, score)
 where s.centre_id = '22222222-2222-2222-2222-222222222222' and s.name = 'Hemanth Reddy';
```

- [ ] **Step 5: Regenerate the types and run the tests**

Run: `cd supabase && supabase db reset >/dev/null && supabase gen types typescript --local > types.ts && bun test tests`
Expected: PASS, the catalogue test included (no new table; the new function grants nothing to `anon`).

- [ ] **Step 6: `bun check --only=db`, then commit**

```bash
git add supabase/migrations/20261026000021_v2_school_items_marks_mock.sql supabase/tests/v2.test.ts supabase/seed.sql supabase/types.ts
git commit -m "Migration 0021: what an item holds, marks from a mock, forward_ask, the keeps for an exam, a marking's consent, name_plan_group; the seed's items"
```

### Task 2: The API: the schemas, prompts and fake answers of the school kinds (PR 2)

**Files:**
- Modify: `api/src/schemas.ts`, `api/src/claude-fake.ts`, `api/src/prompts/check-paper.ts` (`schemeText` for a mock),
  `api/src/errors.ts`
- Create: `api/src/prompts/parse-school.ts`, `mock.ts`, `gap-report.ts`, `test-tomorrow.ts`
- Test: `api/test/schemas.test.ts`, `api/test/prompts.test.ts`, `api/test/claude-fake.test.ts`

**Interfaces:**
- Consumes: `ClaudeRequest` (`claude.ts`), `modelFor` (`models.ts`), `VOICE` (`prompts/shared.ts`), `DecodedImage`.
- Produces: `ParseSchoolInput` (`{ centreId, text?, image?, today, schools?: string[], classLevels?: ClassLevel[] }`),
  `ParsedItem`, `ParseSchoolOutput`; `MakeInput`'s `mock` with `title`, `MockOutput`; `gap_report` with `classLevel`,
  `subject`, `daysLeft`, `bySkill`, `GapReportOutput`; `test_tomorrow` with `parentName`, `centreName`, `revise`,
  `TestTomorrowOutput`; `Scheme` `{ kind: "mock", generationId }`; `CheckPaperInput.studentId`; the four prompt
  `request` functions; `SAMPLE.parse_school`, `.mock`, `.gap_report`, `.test_tomorrow`; `kindOf` for each;
  `errors.refused` words for `parse_school` and `mock`.

- [ ] **Step 1: Write the failing schema tests** (append to `api/test/schemas.test.ts`)

```ts
test("ParseSchoolInput takes the message or a photo with today's date, the schools and the class levels, nothing else", () => {
  const ok = ParseSchoolInput.safeParse({ centreId, text: "Unit test on Friday", today: "2026-10-07", schools: ["Vidya Niketan"], classLevels: ["8", "10"] });
  expect(ok.success).toBe(true);
  expect(ParseSchoolInput.safeParse({ centreId, today: "2026-10-07" }).success).toBe(false);
  expect(ParseSchoolInput.safeParse({ centreId, text: "x", today: "7 Oct" }).success).toBe(false);
  expect(ParseSchoolInput.safeParse({ centreId, text: "x", today: "2026-10-07", studentId: centreId }).success).toBe(false);
});

test("ParsedItem allows a missing date, an end date, a class and a student as read, and holds portions to 500", () => {
  const item = { kind: "exam", title: "Science unit test 3", subject: "Science", date: null, endDate: null, classLevel: "8", school: "Vidya Niketan", studentName: null, portions: "Ch 1 · Ch 2" };
  expect(ParsedItem.safeParse(item).success).toBe(true);
  expect(ParsedItem.safeParse({ ...item, portions: "x".repeat(501) }).success).toBe(false);
  expect(ParsedItem.safeParse({ ...item, kind: "party" }).success).toBe(false);
  expect(ParseSchoolOutput.safeParse({ items: [] }).success).toBe(true);
});

test("a mock takes its title, portions and the pattern; the output's questions carry a skill and the total is checked by the route", () => {
  const input = { kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions", "Acids, bases and salts"], pattern: { marks: 25, durationMinutes: 40 } };
  expect(MakeInput.safeParse(input).success).toBe(true);
  expect(MakeInput.safeParse({ ...input, studentId: centreId }).success).toBe(false);
  const out = MockOutput.safeParse(SAMPLE.mock);
  expect(out.success).toBe(true);
  expect(SAMPLE.mock.sections.flatMap((s) => s.questions).every((q) => q.skill.length > 0)).toBe(true);
});

test("a gap report takes the tallies by skill and the days left; its output has one to three days", () => {
  const input = { kind: "gap_report", centreId, studentId: centreId, classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10, note: "Changed the formulas" }] };
  expect(MakeInput.safeParse(input).success).toBe(true);
  expect(MakeInput.safeParse({ ...input, daysLeft: 0 }).success).toBe(false);
  expect(GapReportOutput.safeParse(SAMPLE.gap_report).success).toBe(true);
  expect(GapReportOutput.safeParse({ summary: "x", days: [] }).success).toBe(false);
});

test("test tomorrow names the student, the parent, the language, the exam and what to revise", () => {
  const input = { kind: "test_tomorrow", centreId, studentId: centreId, studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2", revise: "balancing equations" };
  expect(MakeInput.safeParse(input).success).toBe(true);
  expect(MakeInput.safeParse({ ...input, language: "ta" }).success).toBe(false);
  expect(TestTomorrowOutput.safeParse(SAMPLE.test_tomorrow).success).toBe(true);
});

test("Scheme names a mock by its generation, and CheckPaperInput may name the student", () => {
  expect(Scheme.safeParse({ kind: "mock", generationId: centreId }).success).toBe(true);
  expect(Scheme.safeParse({ kind: "mock", artefactId: centreId }).success).toBe(false);
  expect(CheckPaperInput.safeParse({ pages: [image], scheme: { kind: "typed", text: "Q1" }, studentName: "Dev", studentId: centreId }).success).toBe(true);
});
```

- [ ] **Step 2: Write the failing prompt and fake tests** (append to `api/test/prompts.test.ts` and
  `api/test/claude-fake.test.ts`)

```ts
// prompts.test.ts
test("parse-school asks for items as the school wrote them, with today's date and the centre's schools and classes, on Sonnet", () => {
  const r = parseSchoolRequest({ text: "Dear Parents, Science Unit Test 3 for Class 8 will be held on Friday 16th Oct.", image: null, today: "2026-10-07", schools: ["Vidya Niketan"], classLevels: ["8", "10"] });
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.text).toContain("Today is 2026-10-07");
  expect(r.text).toContain("Vidya Niketan");
  expect(r.system).toContain("null");
  expect(r.images).toBeUndefined();
});

test("parse-school with a photo sends it and no text", () => {
  const r = parseSchoolRequest({ text: null, image: { mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, today: "2026-10-07", schools: [], classLevels: [] });
  expect(r.images).toHaveLength(1);
  expect(r.text).toContain("what the school sent");
});

test("the mock asks for the pattern's marks exactly, one skill per question, nothing from inside a book", () => {
  const r = mockRequest({ kind: "mock", centreId: "c", classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } });
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.text).toContain("25 marks");
  expect(r.text).toContain("40 minutes");
  expect(r.system).toContain("skill");
});

test("the gap report asks for one line per day left, from the tallies", () => {
  const r = gapReportRequest({ kind: "gap_report", centreId: "c", studentId: "s", classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10 }] });
  expect(r.text).toContain("2 days");
  expect(r.text).toContain("Balancing equations: 3 of 10");
  expect(r.model).toBe("claude-sonnet-5-5");
});

test("test tomorrow writes in the parent's language with the English beside, on Haiku, signed by the tutor", () => {
  const r = testTomorrowRequest({ kind: "test_tomorrow", centreId: "c", studentId: "s", studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2", revise: "balancing equations" });
  expect(r.model).toBe("claude-haiku-5-5");
  expect(r.text).toContain("Hindi");
  expect(r.text).toContain("Thursday 8 October");
  expect(r.system).toContain("English");
});

test("schemeText reads a mock's key with its sections", () => {
  const text = schemeText(SAMPLE.mock, "mock");
  expect(text).toContain("Section A");
  expect(text).toContain("Q1 (1 mark)");
});

// claude-fake.test.ts
test("kindOf tells the school kinds apart", () => {
  expect(kindOf(parseSchoolRequest({ text: "x", image: null, today: "2026-10-07", schools: [], classLevels: [] }))).toBe("parse_school");
  expect(kindOf(parseSchoolRequest({ text: null, image: { mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, today: "2026-10-07", schools: [], classLevels: [] }))).toBe("parse_school");
  expect(kindOf(mockRequest({ kind: "mock", centreId: "c", classLevel: "8", subject: "Science", title: "T", portions: ["x"], pattern: { marks: 25, durationMinutes: 40 } }))).toBe("mock");
  expect(kindOf(gapReportRequest({ kind: "gap_report", centreId: "c", studentId: "s", classLevel: "8", subject: "Science", daysLeft: 1, bySkill: [{ skill: "x", right: 1, of: 2 }] }))).toBe("gap_report");
  expect(kindOf(testTomorrowRequest({ kind: "test_tomorrow", centreId: "c", studentId: "s", studentName: "D", tutorName: "M", centreName: "B", language: "hi", subject: "Science", title: "T", date: "2026-10-08" }))).toBe("test_tomorrow");
});

test("the local script reads a photo as two exams and a message as the board's three items", () => {
  const photo = localScript(parseSchoolRequest({ text: null, image: { mediaType: "image/jpeg", base64: "AAAA", bytes: 3 }, today: "2026-10-07", schools: [], classLevels: [] }));
  expect((photo.answer as { items: { kind: string }[] }).items.map((i) => i.kind)).toEqual(["exam", "exam"]);
  const text = localScript(parseSchoolRequest({ text: "Dear Parents", image: null, today: "2026-10-07", schools: [], classLevels: [] }));
  expect((text.answer as { items: { kind: string }[] }).items.map((i) => i.kind)).toEqual(["exam", "homework", "holiday"]);
});

test("the local mock's marks sum to the pattern asked for", () => {
  const r = mockRequest({ kind: "mock", centreId: "c", classLevel: "8", subject: "Science", title: "T", portions: ["x"], pattern: { marks: 40, durationMinutes: 60 } });
  const made = localScript(r).answer as { sections: { questions: { marks: number }[] }[] };
  expect(made.sections.flatMap((s) => s.questions).reduce((n, q) => n + q.marks, 0)).toBe(40);
});
```

- [ ] **Step 3: Run them to see them fail**

Run: `cd api && bun test test/schemas.test.ts test/prompts.test.ts test/claude-fake.test.ts`
Expected: FAIL (`ParseSchoolInput` has no `today`; `MockOutput`, `GapReportOutput`, `TestTomorrowOutput` and the four
`request` functions are not exported; `SAMPLE.mock` is undefined).

- [ ] **Step 4: The schemas** (`api/src/schemas.ts`)

```ts
/** POST /ai/parse-school: what the school sent, as text or one photo, with the day it is read on (so "Friday 16th Oct"
 *  becomes a date), the centre's school names and class levels (so a named school and "Class VIII B" resolve), and
 *  nothing about a student (D62). */
export const ParseSchoolInput = z
  .object({
    ...V2,
    text: z.string().min(1).max(4000).optional(),
    image: Image.optional(),
    today: Day,
    schools: z.array(z.string().min(1).max(120)).max(20).optional(),
    classLevels: z.array(ClassLevel).max(12).optional(),
  })
  .strict()
  .refine((v) => v.text !== undefined || v.image !== undefined, { message: "text or image is needed" });
export type ParseSchoolInput = z.infer<typeof ParseSchoolInput>;

/** One item as read: the words the school used; a date the message does not give is null (the tutor sets it). */
export const ParsedItem = z.object({
  kind: z.enum(["exam", "homework", "notice", "holiday"]),
  title: z.string().min(1).max(120),
  subject: z.string().max(80).nullable(),
  date: Day.nullable(),
  endDate: Day.nullable(),
  classLevel: ClassLevel.nullable(),
  school: z.string().max(120).nullable(),
  studentName: z.string().max(80).nullable(),
  portions: z.string().max(500).nullable(),
});
export type ParsedItem = z.infer<typeof ParsedItem>;
export const ParseSchoolOutput = z.object({ items: z.array(ParsedItem).max(12) });
export type ParseSchoolOutput = z.infer<typeof ParseSchoolOutput>;
```

In `MakeInput`, replace the `mock`, `test_tomorrow` and `gap_report` members:

```ts
  z.object({
    ...V2,
    kind: z.literal("mock"),
    classLevel: ClassLevel,
    subject: Subject,
    title: z.string().min(1).max(120),
    portions: z.array(Name).min(1).max(30),
    pattern: MockPattern,
  }).strict(),
  z.object({
    ...V2,
    kind: z.literal("test_tomorrow"),
    ...Student,
    centreName: z.string().max(120),
    parentName: z.string().max(80).optional(),
    language: Language,
    subject: Subject,
    title: z.string().min(1).max(120),
    date: Day,
    portions: z.string().max(500).optional(),
    revise: z.string().max(200).optional(),
  }),
  z.object({
    ...V2,
    kind: z.literal("gap_report"),
    studentId: z.guid(),
    classLevel: ClassLevel,
    subject: Subject,
    daysLeft: z.number().int().min(1).max(3),
    bySkill: z.array(z.object({ skill: Name, right: z.number().int().min(0), of: z.number().int().min(1), note: z.string().max(300).optional() })).min(1).max(12),
  }),
```

with, above `MakeInput`:

```ts
/** The mock's pattern: the board's blueprint as the syllabus data writes it, or the app's default by class. */
export const MockPattern = z.object({
  marks: z.number().int().min(5).max(100),
  durationMinutes: z.number().int().min(10).max(240),
  sections: z.array(z.object({ name: z.string().max(40), questions: z.number().int().positive(), marksEach: z.number().positive() })).optional(),
});
export type MockPattern = z.infer<typeof MockPattern>;
```

and the outputs:

```ts
/** A mock (P10-Mock): V1's paper shape with the skill each question tests (the gap report's tallies) and the time. The
 *  route refuses an answer whose marks do not sum to the pattern's. */
export const MockOutput = z.object({
  title: z.string().min(1).max(120),
  durationMinutes: z.number().int().min(10).max(240),
  sections: z
    .array(
      z.object({
        name: z.string().min(1).max(40),
        marksEach: z.number().int().min(1),
        questions: z
          .array(z.object({ number: z.number().int().min(1), text: z.string().min(1).max(600), marks: z.number().int().min(1), answer: z.string().min(1).max(600), skill: Name }))
          .min(1),
      }),
    )
    .min(1)
    .max(5),
});
export type MockOutput = z.infer<typeof MockOutput>;
export const mockMarks = (mock: MockOutput) => mock.sections.flatMap((s) => s.questions).reduce((n, q) => n + q.marks, 0);

/** The gap report's words (P10-GapReport): a line on what the mock showed and one line per day left. The tallies by
 *  skill are the app's arithmetic. */
export const GapReportOutput = z.object({
  summary: z.string().min(1).max(200),
  days: z.array(z.object({ title: z.string().min(1).max(40), line: z.string().min(1).max(180) })).min(1).max(3),
});
export type GapReportOutput = z.infer<typeof GapReportOutput>;

/** Test tomorrow in the parent's language with the English beside it for the tutor (P10-TestTomorrow). */
export const TestTomorrowOutput = z.object({ message: z.string().min(1).max(600), english: z.string().min(1).max(600) });
export type TestTomorrowOutput = z.infer<typeof TestTomorrowOutput>;
```

`Scheme`'s mock member becomes `z.object({ kind: z.literal("mock"), generationId: z.guid() })` (the key is the mock's
generation output, the one table the API reads); `CheckPaperInput` gains `studentId: z.guid().optional()` (sent for a
mock, so the gate asks the student's consent).

- [ ] **Step 5: The prompts** (one file each; each exports `request`)

`prompts/parse-school.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import type { DecodedImage } from "../images.js";
import { modelFor } from "../models.js";
import { type ClassLevel, ParseSchoolOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

export type ParseSchoolSource = { text: string | null; image: DecodedImage | null; today: string; schools: string[]; classLevels: ClassLevel[] };

/** What the school sent read into items the tutor checks (plan decision 27): the kinds, the words as written, the dates
 *  resolved from today, a class and a school when named, a student only when the message is about one. */
export function request(source: ParseSchoolSource): ClaudeRequest<ParseSchoolOutput> {
  return {
    model: modelFor("parse_school", source.classLevels[0] ?? "8"),
    effort: "medium",
    system: [
      VOICE,
      "You read a message or a photo a school sent to parents and list what it announces: exams (kind exam), homework the school set (homework), notices such as a PTM or a fee circular (notice), and holidays (holiday).",
      "One item per announcement. The title is short, in the school's own words (\"Science unit test 3\"). The subject only when one is named. The portions as written, shortened to 500 characters.",
      "Dates are ISO (YYYY-MM-DD), resolved from today's date and the school year; a date the message does not give is null, never guessed. A holiday's endDate is its last day; otherwise endDate is null.",
      "classLevel is the class named (VIII, 8th, Class 8 all mean \"8\"; LKG and UKG as such), else null. school is the school's name when the message names one of the schools given, else null. studentName is a student's name only when the message is about one student, else null.",
      "No item for a greeting or a signature. An empty list when nothing is announced.",
    ].join(" "),
    text: [
      `Today is ${source.today}.`,
      source.schools.length ? `Schools: ${source.schools.join("; ")}.` : "",
      source.classLevels.length ? `Classes at the centre: ${source.classLevels.join(", ")}.` : "",
      source.image ? "Read what the school sent in the photo." : `What the school sent:\n${source.text}`,
    ].filter(Boolean).join("\n"),
    images: source.image ? [{ mediaType: source.image.mediaType, base64: source.image.base64 }] : undefined,
    schema: ParseSchoolOutput,
  };
}
```

`prompts/mock.ts` (`request(input: MockInput)`): Sonnet by `modelFor("mock", …)`, effort "high"; the system: the voice, "You
set a mock test in the pattern the school uses: exactly the marks given, sections as given (or sensible sections when
none), each question tests one skill from the portions and names it; a key with a short answer per question; no text
copied from a textbook; questions a student of that class can answer in the minutes given"; the text: `${title}, class
${classLevel} ${subject}. Portions: …. Pattern: ${marks} marks, ${durationMinutes} minutes` and the sections when given
("Section A: 5 questions of 1 mark"); `schema: MockOutput`.

`prompts/gap-report.ts` (`request(input: GapReportInput)`): Sonnet, effort "medium"; the system: "You write a tutor's
plan for the last days before a school test from a marked mock: one sentence on what it showed, then one line per day
left naming what to revise and how (a worked example, a short set, a sorting set, the key read together); the weakest
skills first; nothing a tutor cannot do in one class"; the text: `Class ${classLevel} ${subject}. ${daysLeft} days left.
By skill:` then `${skill}: ${right} of ${of}` (and the note) per row; `schema: GapReportOutput`.

`prompts/test-tomorrow.ts` (`request(input: TestTomorrowInput)`): Haiku, effort "medium"; the system: "You write a short
WhatsApp message from a tutor to a parent, in the language asked (Hindi in Devanagari, Kannada in Kannada script,
Hinglish in Latin letters), saying the student's test is tomorrow, the portions, and one thing to go over this evening;
polite, four sentences at most, signed with the tutor's name and the centre on two lines; and the same message in
English for the tutor to read"; the text: the language's name, the student's first name, the parent's first name, the
title, the weekday and date (`Thursday 8 October` from the ISO date), the portions and the skill; `schema:
TestTomorrowOutput`.

`check-paper.ts`'s `schemeText` gains:

```ts
  if (kind === "mock") {
    const mock = MockOutput.safeParse(output);
    if (!mock.success) return null;
    const lines = mock.data.sections.flatMap((s) => [
      `${s.name} (${s.marksEach} ${s.marksEach === 1 ? "mark" : "marks"} each)`,
      ...s.questions.map((q) => `Q${q.number} (${q.marks} ${q.marks === 1 ? "mark" : "marks"}) ${q.text} → ${q.answer}`),
    ]);
    return [mock.data.title, ...lines].join("\n");
  }
```

- [ ] **Step 6: The fake** (`claude-fake.ts`): `SAMPLE.parse_school` (the board's three items: the exam Friday 16 October
  class 8 Vidya Niketan with the portions, the homework Monday 12 October, the holiday 19 to 21 October), a second
  constant `PHOTO_ITEMS` (two exams on Friday 16 October: Science for class 8 with chapters 1 and 2, Mathematics for class
  10 with chapters 3 and 4), `SAMPLE.mock` (title "Science unit test 3", 40 minutes, Section A five one-mark questions,
  Section B five two-mark, Section C two five-mark, each with a skill from "Spot a chemical change", "Write a word
  equation", "Balance a chemical equation", "Name the types of reactions"; the total 25), `SAMPLE.gap_report` (the board's
  summary and two days), `SAMPLE.test_tomorrow` (the board's Hindi message and its English). `kindOf`: before the image
  branch's register test, `if (request.text.includes("what the school sent") || request.text.includes("Read what the
  school sent")) return "parse_school"`; `if (request.text.includes("Pattern:")) return "mock"`; `if
  (request.text.includes("By skill:")) return "gap_report"`; `if (request.system.includes("test is tomorrow")) return
  "test_tomorrow"`. `localScript`: `parse_school` answers `PHOTO_ITEMS` for a request with an image and `SAMPLE.parse_school`
  for text; `mock` answers `patterned(marks)`: the sample's sections scaled so the marks sum to the pattern's (a last
  question takes the remainder); the others the sample, each after 1.5 s.

- [ ] **Step 7: The refusal words** (`errors.ts` `REFUSED`): `parse_school: "Couldn't find a test, homework, notice or
  holiday in this. Add it by hand."`, `mock: "Couldn't set a mock for these portions. The plan goes on without it."`.

- [ ] **Step 8: Run the tests**

Run: `cd api && bun run check`
Expected: PASS (`tsc` and every test).

- [ ] **Step 9: Commit**

```bash
git add api/src/schemas.ts api/src/prompts api/src/claude-fake.ts api/src/errors.ts api/test
git commit -m "API: the school kinds' schemas, prompts and fake answers (parse-school, mock, gap report, test tomorrow, a mock's key)"
```

### Task 3: The API: `/ai/parse-school` live; `/ai/make` mock, gap report and test tomorrow; check-paper with a mock's key and the student's consent (PR 2)

**Files:**
- Modify: `api/src/routes/ai.ts` (`/parse-school` from skeleton to live; `/check-paper`'s mock scheme and `studentId`),
  `api/src/routes/v2.ts` (the three kinds), `api/src/routes/common.ts` (`Call.student`), `api/src/db.ts` (`start` takes
  `student`, passes `p_student`), `api/src/db-fake.ts` (refuses a call with a student when `studentConsent` is false)
- Test: `api/test/ai.test.ts`, `api/test/v2.test.ts`

**Interfaces:**
- Consumes: Task 2's schemas, prompts and samples; `run`, `parse`, `answer`, `decodeImage`.
- Produces: `POST /ai/parse-school` answering `{ id, result: { items } }`; `/ai/make` kinds `mock`, `gap_report`,
  `test_tomorrow`; `/ai/check-paper` with `{ kind: "mock", generationId }` and `studentId`; `Db.start(token, { centre,
  kind, input, model, student? })`.

- [ ] **Step 1: Write the failing route tests** (append to `api/test/v2.test.ts`; `app`, `post`, `image`, `centreId` are
  the file's; the `fakeDb` of Task 3 takes `studentConsent`)

```ts
const today = "2026-10-07";

test("parse-school reads a message into items on Sonnet, records no text of the message and no student, and never the image", async () => {
  const claude = fakeClaude({ answer: SAMPLE.parse_school });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/parse-school", { centreId, text: "Dear Parents, Science Unit Test 3 for Class 8 will be held on Friday 16th Oct.", today, schools: ["Vidya Niketan"], classLevels: ["8"] });
  expect(r.status).toBe(200);
  const body = (await r.json()) as { result: { items: { kind: string; date: string | null }[] } };
  expect(body.result.items.map((i) => i.kind)).toEqual(["exam", "homework", "holiday"]);
  expect(db.started[0]).toMatchObject({ kind: "parse_school", model: "claude-sonnet-5-5", input: { kind: "parse_school", source: "text", characters: 84, pages: 0 } });
  expect(JSON.stringify(db.started[0])).not.toContain("Dear Parents");
  const photo = await post(app(claude, db), "/ai/parse-school", { centreId, image, today });
  expect(photo.status).toBe(200);
  expect(db.started[1]).toMatchObject({ input: { source: "photo", pages: 1, bytes: 8 } });
  expect(JSON.stringify(db.started[1])).not.toContain(jpeg);
});

test("parse-school answers a null date when the message gives none, and refuses a message with nothing in it", async () => {
  const undated = await post(app(fakeClaude({ answer: { items: [{ kind: "exam", title: "Unit test", subject: "Science", date: null, endDate: null, classLevel: null, school: null, studentName: null, portions: null }] } })), "/ai/parse-school", { centreId, text: "Unit test next week", today });
  expect(((await undated.json()) as { result: { items: { date: null }[] } }).result.items[0]?.date).toBeNull();
  const db = fakeDb();
  const none = await post(app(fakeClaude({ answer: { items: [] } }), db), "/ai/parse-school", { centreId, text: "Good morning", today });
  expect(none.status).toBe(422);
  expect(await none.json()).toEqual({ error: "Couldn't find a test, homework, notice or holiday in this. Add it by hand." });
  expect(db.finished[0]).toMatchObject({ status: "failed" });
});

const mock = { kind: "mock", centreId, classLevel: "8", subject: "Science", title: "Science unit test 3", portions: ["Chemical reactions", "Acids, bases and salts"], pattern: { marks: 25, durationMinutes: 40 } };

test("make mock answers the paper on Sonnet with no student, and refuses one whose marks do not sum to the pattern", async () => {
  const db = fakeDb();
  const ok = await post(app(fakeClaude({ answer: SAMPLE.mock }), db), "/ai/make", mock);
  expect(ok.status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "mock", model: "claude-sonnet-5-5", input: { title: "Science unit test 3" } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
  const short = { ...SAMPLE.mock, sections: [SAMPLE.mock.sections[0]] };
  const unfit = await post(app(fakeClaude({ answer: short }), db), "/ai/make", mock);
  expect(unfit.status).toBe(422);
  expect(await unfit.json()).toEqual({ error: "Couldn't set a mock for these portions. The plan goes on without it." });
  expect(db.finished[1]).toMatchObject({ status: "failed" });
});

test("make gap_report and test_tomorrow are personal: the student's consent is asked and recorded, and a refusal is 403", async () => {
  const report = { kind: "gap_report", centreId, studentId: centreId, classLevel: "8", subject: "Science", daysLeft: 2, bySkill: [{ skill: "Balancing equations", right: 3, of: 10 }] };
  const db = fakeDb();
  expect((await post(app(fakeClaude({ answer: SAMPLE.gap_report }), db), "/ai/make", report)).status).toBe(200);
  expect(db.started[0]).toMatchObject({ kind: "gap_report", student: centreId, model: "claude-sonnet-5-5" });
  const refused = await post(app(undefined, fakeDb({ studentConsent: false })), "/ai/make", report);
  expect(refused.status).toBe(403);
  const message = { kind: "test_tomorrow", centreId, studentId: centreId, studentName: "Dev Kumar", tutorName: "Meera Nair", centreName: "Bright Minds Tuition", parentName: "Ramesh Kumar", language: "hi", subject: "Science", title: "Science unit test", date: "2026-10-08", portions: "chapters 1 and 2" };
  const sent = await post(app(fakeClaude({ answer: SAMPLE.test_tomorrow }), db), "/ai/make", message);
  expect(sent.status).toBe(200);
  expect(((await sent.json()) as { result: { english: string } }).result.english).toContain("Dev");
  expect(db.started[1]).toMatchObject({ kind: "test_tomorrow", student: centreId, model: "claude-haiku-5-5" });
});

test("the note and can_do still answer 501", async () => {
  const r = await post(app(), "/ai/make", { kind: "can_do", centreId, studentId: centreId, studentName: "D", tutorName: "M", language: "en", ladder: {} });
  expect(r.status).toBe(501);
});
```

and to `api/test/ai.test.ts`:

```ts
test("check-paper marks against a mock's key read from its generation, names the student for the gate, and needs their consent", async () => {
  const generations = { "11111111-1111-1111-1111-111111111111": { kind: "mock" as const, output: JSON.stringify(SAMPLE.mock) } };
  const db = fakeDb({ generations });
  const body = { centreId, pages: [image], scheme: { kind: "mock", generationId: "11111111-1111-1111-1111-111111111111" }, studentName: "Dev Kumar", studentId: centreId };
  const claude = fakeClaude({ answer: SAMPLE.check_paper });
  const r = await post(app(claude, db), "/ai/check-paper", body);
  expect(r.status).toBe(200);
  expect(claude.requests[0]?.text).toContain("Section A");
  expect(db.started[0]).toMatchObject({ kind: "check_paper", student: centreId, input: { scheme: { kind: "mock", generationId: "11111111-1111-1111-1111-111111111111" } } });
  const refused = await post(app(claude, fakeDb({ generations, studentConsent: false })), "/ai/check-paper", body);
  expect(refused.status).toBe(403);
  const gone = await post(app(claude, fakeDb()), "/ai/check-paper", body);
  expect(gone.status).toBe(400);
  expect(await gone.json()).toEqual({ error: "That mock is no longer here. Type the scheme instead." });
});
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd api && bun test test/v2.test.ts test/ai.test.ts`
Expected: FAIL (`/parse-school` answers 501; the three kinds answer 501; the mock scheme answers 501; `started[0].student`
is undefined).

- [ ] **Step 3: The routes**

`common.ts`: `Call<T>` gains `student?: string`; `run` passes it: `deps.db.start(token, { centre, kind, input, model,
student: call.student })`. `db.ts`: `start(token, { centre, kind, input, model, student })` sends `p_student: student ??
null`. `db-fake.ts`: `fakeDb({ studentConsent })`; `start` throws `DbFailure("consent")` when `args.student` is set and
`studentConsent === false`.

`ai.ts`: replace the skeleton with

```ts
  routes.post("/parse-school", async (c) => {
    const body = await parse(c, ParseSchoolInput);
    if (!isParsed(body)) return body;
    let image: DecodedImage | null = null;
    if (body.value.image) {
      const decoded = decodeImage(body.value.image);
      if (typeof decoded === "string") return answer(c, errors.badImage(decoded));
      image = decoded;
    }
    const { text, today, schools = [], classLevels = [] } = body.value;
    // The message's words are not recorded: the record holds how much came and how.
    const input = image
      ? { kind: "parse_school", source: "photo", pages: 1, bytes: image.bytes, characters: 0 }
      : { kind: "parse_school", source: "text", pages: 0, characters: [...(text ?? "")].length };
    const request = parseSchoolRequest({ text: text ?? null, image, today, schools, classLevels });
    return run(c, deps, body.centre, { kind: "parse_school", input, request, empty: (read) => read.items.length === 0 });
  });
```

In `/check-paper`: `if (scheme.kind === "mock") { const stored = await deps.db.generation(c.get("token"),
scheme.generationId); text = stored?.kind === "mock" && stored.output ? schemeText(safeJSON(stored.output), "mock") :
null; if (!text) return answer(c, errors.badImage("That mock is no longer here. Type the scheme instead.")); }`; the
record's `scheme` for a mock is `{ kind: "mock", generationId }`; the call carries `student: body.value.studentId`.

`v2.ts` `/make`: `case "mock": return run(c, deps, body.centre, { kind: "mock", input: v, request: mockRequest(v), empty:
(made) => mockMarks(made) !== v.pattern.marks });`, `case "gap_report": return run(…, { kind: "gap_report", input: v,
request: gapReportRequest(v), student: v.studentId });`, `case "test_tomorrow": return run(…, { kind: "test_tomorrow",
input: v, request: testTomorrowRequest(v), student: v.studentId });`; `note` and `can_do` keep `notYet`.

- [ ] **Step 4: Run the tests**

Run: `cd api && bun run check`
Expected: PASS.

- [ ] **Step 5: `bun check --only=api`, then commit**

```bash
git add api/src api/test
git commit -m "API: /ai/parse-school live; /ai/make mock, gap report and test tomorrow; check-paper with a mock's key and the student's consent"
```

### Task 4: Domain: items, who they reach, the list's shape, holidays, the nearest exam (PR 3)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/School/SchoolItem.swift`, `SchoolItemRules.swift`, `HolidayRules.swift`
- Modify: `Sources/Domain/Queue/OfflineRefusal.swift`
- Test: `Tests/DomainTests/SchoolItemRulesTests.swift`, `HolidayRulesTests.swift`, `OfflineRefusalTests.swift`

**Interfaces:**
- Consumes: `Student` (`classLevel`, `schoolID`, `archivedAt`, `parentPhone`), `School`, `ClassLevel`, `Day`, `Weekday`,
  `Classroom.meetingDays`, `SchoolItemHint` (Phase 12).
- Produces:

```swift
public enum SchoolItemKind: String, CaseIterable, Hashable, Sendable, Codable { case exam, homework, notice, holiday }
public enum SchoolItemSource: String, Hashable, Sendable, Codable {
    case sharedText = "shared_text", sharedPhoto = "shared_photo", photo, pasted, typed
}
/// Who an item is for (plan decision 2).
public enum ItemAudience: Hashable, Sendable, Codable {
    case student(UUID)
    case schoolClass(school: UUID, level: ClassLevel)
    case school(UUID)
}
public struct SchoolItem: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID; public var kind: SchoolItemKind; public var audience: ItemAudience; public var title: String
    public var subject: String?; public var date: Day; public var endDate: Day?; public var portions: String?
    public var sourceText: String?; public var photoPath: String?; public var source: SchoolItemSource
    public var receivedAt: Date; public var confirmedAt: Date?
}
/// An item before Add: what the parser read, or what the tutor typed; incomplete until it has a kind, a title, who it
/// is for and a date (an exam a subject too).
public struct SchoolItemDraft: Hashable, Sendable, Identifiable {
    public let id: UUID; public var kind: SchoolItemKind; public var audience: ItemAudience?; public var title: String
    public var subject: String?; public var date: Day?; public var endDate: Day?; public var portions: String?
    public var sourceText: String?; public var source: SchoolItemSource; public var ticked: Bool
    public var missing: [Missing]   // .date, .audience, .subject, .title
    public var isComplete: Bool
}
public enum SchoolItemRules {
    public static let portionsLimit = 500, titleLimit = 120, windowDays = 14
    public static func students(for item: SchoolItem, in students: [Student]) -> [Student]
    public static func audienceLine(_ item: SchoolItem, students: [Student], schools: [School]) -> String
    public static func countdown(from today: Day, to date: Day) -> String?   // "today", "tomorrow", "in 9 days"; nil past
    public static func buckets(_ items: [SchoolItem], today: Day, calendar: Calendar) -> [(title: String, items: [SchoolItem])]
    public static func line(_ item: SchoolItem, today: Day, students: [Student], schools: [School]) -> String
    public static func nearestExam(for student: Student, items: [SchoolItem], students: [Student], today: Day, calendar: Calendar) -> SchoolItem?
    public static func hints(_ items: [SchoolItem], students: [Student], today: Day, calendar: Calendar) -> [SchoolItemHint]
    public static func upcoming(for student: Student, items: [SchoolItem], students: [Student], today: Day) -> [SchoolItem]
}
public enum HolidayRules {
    public static func covers(_ item: SchoolItem, _ day: Day) -> Bool
    public static func onHoliday(_ student: Student, on day: Day, items: [SchoolItem], students: [Student]) -> Bool
    public static func batchDays(_ item: SchoolItem, batch: Classroom, calendar: Calendar) -> [Day]
    public static func coveredLine(_ item: SchoolItem, batches: [Classroom], calendar: Calendar) -> String
}
```

- [ ] **Step 1: Write the failing tests** (`DomainTests/SchoolItemRulesTests.swift`; the students and schools are small
  fixtures built in the file: Dev, Meher and Nikhil in class 8 at Vidya; Akshita in class 10 at Vidya; Riya class 5 at
  St Mary's; Bir with no class)

```swift
import Domain
import Foundation
import Testing

struct SchoolItemRulesTests {
    let today = Day(year: 2026, month: 10, day: 7)!
    let calendar = DayHeading.india

    @Test func anItemForASchoolsClassReachesItsActiveStudentsNowAndLater() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .eight))
        #expect(SchoolItemRules.students(for: item, in: people).map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        var late = student("Late Joiner", level: .eight, school: vidya.id)
        #expect(SchoolItemRules.students(for: item, in: people + [late]).count == 4)
        late.archivedAt = Date()
        #expect(SchoolItemRules.students(for: item, in: people + [late]).count == 3)
    }

    @Test func anItemForAWholeSchoolReachesEveryClassAndAStudentsItemOnlyThem() {
        let holiday = SchoolItem.fixture(kind: .holiday, audience: .school(vidya.id), date: today.adding(days: 12, calendar: calendar))
        #expect(SchoolItemRules.students(for: holiday, in: people).map(\.name) == ["Akshita Rao", "Dev Kumar", "Meher Shah", "Nikhil Das"])
        let own = exam(audience: .student(dev.id))
        #expect(SchoolItemRules.students(for: own, in: people).map(\.id) == [dev.id])
    }

    @Test func anItemForAnEmptyClassReachesNoOneYet() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .nine))
        #expect(SchoolItemRules.students(for: item, in: people).isEmpty)
        #expect(SchoolItemRules.audienceLine(item, students: people, schools: [vidya]) == "Class 9 at Vidya Niketan · no one in class 9 there yet")
    }

    @Test func aStudentAddedLaterIsReached() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .nine))
        let joiner = student("New Nine", level: .nine, school: vidya.id)
        #expect(SchoolItemRules.students(for: item, in: people + [joiner]).map(\.id) == [joiner.id])
    }

    @Test func theAudienceLineNamesTheClassTheSchoolAndTheStudents() {
        #expect(SchoolItemRules.audienceLine(exam(audience: .schoolClass(school: vidya.id, level: .eight)), students: people, schools: [vidya]) == "Class 8 at Vidya Niketan · Dev, Meher, Nikhil")
        #expect(SchoolItemRules.audienceLine(exam(audience: .school(vidya.id)), students: people, schools: [vidya]) == "Vidya Niketan, every class")
        #expect(SchoolItemRules.audienceLine(exam(audience: .student(riya.id)), students: people, schools: [vidya, stMarys]) == "Riya Sharma · St Mary's School")
    }

    @Test func theCountdownReadsTodayTomorrowAndDaysAndNothingForThePast() {
        #expect(SchoolItemRules.countdown(from: today, to: today) == "today")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: 1, calendar: calendar)) == "tomorrow")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: 9, calendar: calendar)) == "in 9 days")
        #expect(SchoolItemRules.countdown(from: today, to: today.adding(days: -1, calendar: calendar)) == nil)
    }

    @Test func theListGroupsThisWeekNextWeekAndLaterFromTodayOn() {
        // Wednesday 7 October: this week ends Sunday 11; next week Monday 12 to Sunday 18.
        let items = [
            exam(date: today.adding(days: 1, calendar: calendar)), exam(date: today.adding(days: 9, calendar: calendar)),
            exam(date: today.adding(days: 12, calendar: calendar)), exam(date: today.adding(days: -2, calendar: calendar)),
        ]
        let buckets = SchoolItemRules.buckets(items, today: today, calendar: calendar)
        #expect(buckets.map(\.title) == ["This week", "Next week", "Later"])
        #expect(buckets.map { $0.items.count } == [1, 1, 1])
    }

    @Test func theLineReadsWhoTheSubjectAndTheCountdownOrAHolidaysLastDay() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .eight), date: today.adding(days: 9, calendar: calendar), portions: "Ch 1 · Ch 2")
        #expect(SchoolItemRules.line(item, today: today, students: people, schools: [vidya]) == "Class 8 at Vidya Niketan · Dev, Meher, Nikhil · in 9 days")
        var holiday = SchoolItem.fixture(kind: .holiday, audience: .school(vidya.id), date: today.adding(days: 12, calendar: calendar))
        holiday.endDate = today.adding(days: 14, calendar: calendar)
        #expect(SchoolItemRules.line(holiday, today: today, students: people, schools: [vidya]) == "Vidya Niketan · to Wed 21 Oct")
    }

    @Test func theNearestExamOfASubjectDrivesThenTheNext() {
        let preBoard = exam(audience: .student(akshita.id), date: today.adding(days: 10, calendar: calendar), subject: "Mathematics", title: "Pre-board")
        let board = exam(audience: .student(akshita.id), date: today.adding(days: 40, calendar: calendar), subject: "Mathematics", title: "Board exam")
        #expect(SchoolItemRules.nearestExam(for: akshita, items: [board, preBoard], students: people, today: today, calendar: calendar)?.title == "Pre-board")
        let after = today.adding(days: 11, calendar: calendar)
        #expect(SchoolItemRules.nearestExam(for: akshita, items: [board, preBoard], students: people, today: after, calendar: calendar) == nil)
        let inWindow = today.adding(days: 27, calendar: calendar)
        #expect(SchoolItemRules.nearestExam(for: akshita, items: [board, preBoard], students: people, today: inWindow, calendar: calendar)?.title == "Board exam")
    }

    @Test func hintsCarryOneExamPerStudentWithinTheWindow() {
        let item = exam(audience: .schoolClass(school: vidya.id, level: .eight), date: today.adding(days: 9, calendar: calendar))
        let far = exam(audience: .schoolClass(school: vidya.id, level: .eight), date: today.adding(days: 20, calendar: calendar), subject: "Mathematics")
        let hints = SchoolItemRules.hints([item, far], students: people, today: today, calendar: calendar)
        #expect(hints.count == 3 && hints.allSatisfy { $0.subject == "Science" })
    }

    @Test func aDraftWithoutADateIsNotComplete() {
        var draft = SchoolItemDraft(kind: .exam, audience: .student(dev.id), title: "Unit test", subject: "Science", date: nil, source: .sharedText)
        #expect(!draft.isComplete && draft.missing == [.date])
        draft.date = today
        #expect(draft.isComplete)
        let noOne = SchoolItemDraft(kind: .holiday, audience: nil, title: "Dasara", subject: nil, date: today, source: .sharedText)
        #expect(noOne.missing == [.audience])
        let noSubject = SchoolItemDraft(kind: .exam, audience: .student(dev.id), title: "Test", subject: nil, date: today, source: .typed)
        #expect(noSubject.missing == [.subject])
    }

    @Test func portionsAndTheTitleCountScalarsAndAreHeldToTheirLimits() {
        var draft = SchoolItemDraft(kind: .exam, audience: .student(dev.id), title: String(repeating: "अ", count: 120), subject: "Hindi", date: today, source: .typed)
        #expect(draft.isComplete)
        draft.title += "अ"
        #expect(draft.missing == [.title])
        draft.title = "Test"
        draft.portions = String(repeating: "क", count: 501)
        #expect(!draft.isComplete)
    }
}
```

`HolidayRulesTests`: `aHolidayCoversItsDays` (from `date` to `endDate` inclusive; a holiday with no end covers one day),
`aStudentOfTheSchoolIsOnHolidayAndOthersAreNot` (Dev yes, Riya no), `aStudentsOwnHolidayCoversOnlyThem`,
`theBatchDaysCoveredNameTheBatchsMeetingDays` ("Mon 19, Tue 20 and Wed 21 Oct · Evening batch" for a Monday-to-Friday
batch; a Saturday-only batch yields no day and no line). `OfflineRefusalTests` gains the five new writes' words (each
passes `ErrorWordsTests.banned`): `.schoolItem` "You're offline. Keeping what the school sent needs a connection; nothing
was kept.", `.readSchool` "You're offline. Reading what the school sent needs a connection; it waits here until you're
back online.", `.forwardAsk` "You're offline. Sending needs a connection to note who was asked.", `.mark` "You're
offline. Marking needs a connection; the photos are still here.", `.gapReport` "You're offline. The gap report needs a
connection.".

- [ ] **Step 2: Run them to see them fail**

Run: `tools/xt.sh DomainTests` (the session's `xcodebuild test -only-testing` helper from session 26, or `bun check
--only=ios`)
Expected: FAIL to compile (no `SchoolItem`).

- [ ] **Step 3: Implement** `SchoolItem.swift`, `SchoolItemRules.swift`, `HolidayRules.swift` as the interfaces above.
  Details that are rules: `students(for:)` keeps `archivedAt == nil`; `.schoolClass` matches `schoolID` and `classLevel`;
  `.school` matches `schoolID`; the audience line's names are first names sorted, "no one in class n there yet" when
  none; `buckets` cuts at the Sunday of today's week and the Sunday after (`calendar.firstWeekday` is Monday in
  `DayHeading.india`); items before today are left out of `buckets` but not of `upcoming` for the calendar; `line`
  joins who, the subject (an exam's, when the title does not contain it), the countdown (an exam) or "to <end>" (a
  holiday) with " · "; `nearestExam` takes exams the student is reached by with `date` in `today ... today + windowDays`,
  the earliest first (ties by title); `hints` maps each student's nearest exam to a `SchoolItemHint`; the draft's
  `missing` is computed in order title, audience, date, subject (an exam only), portions over the limit counted as
  `.portions`.

- [ ] **Step 4: Run the tests to see them pass; commit**

```bash
git add ios/TutorCentralKit/Sources/Domain/School ios/TutorCentralKit/Sources/Domain/Queue/OfflineRefusal.swift ios/TutorCentralKit/Tests/DomainTests
git commit -m "Domain: school items, who they reach, the list's shape, holidays, the nearest exam, the offline words"
```

### Task 5: Domain: the exam window and the split of portions across days; the mock's pattern (PR 3)

**Files:**
- Create: `Sources/Domain/School/ExamPreparation.swift`, `Sources/Domain/School/MockPattern.swift`
- Test: `DomainTests/ExamPreparationTests.swift`, `MockPatternTests.swift`

**Interfaces:**
- Consumes: `SchoolItem`, `HolidayRules`, `Classroom.meetingDays`, `Chapter`, `Skill`, `Board`, `ClassLevel`.
- Produces:

```swift
public struct PreparationDay: Hashable, Sendable, Identifiable {
    public enum Kind: Hashable, Sendable { case revise(index: Int), mock, afterMock, exam }
    public var id: Day { day }
    public let day: Day; public let kind: Kind
    /// "Acids, bases and salts · first half", "The mock", "What the mock showed", "The test".
    public let title: String
    public let skills: [String]; public let skillIDs: [UUID]
}
public enum ExamPreparation {
    public static let windowDays = 14, mockDaysBefore = 2
    public static func portions(_ text: String) -> [String]
    public static func matching(_ portion: String, in chapters: [Chapter]) -> [Chapter]
    public static func days(exam: SchoolItem, batch: Classroom, today: Day, holidays: [SchoolItem], student: Student,
                            students: [Student], chapters: [Chapter], skills: [Skill], calendar: Calendar) -> [PreparationDay]
    public static func isWithinWindow(_ exam: SchoolItem, today: Day, calendar: Calendar) -> Bool
    public static func weakest(_ skills: [Skill], among names: [String]) -> Skill?
}
public struct MockPattern: Hashable, Sendable, Codable {
    public struct Section: Hashable, Sendable, Codable { public let name: String; public let questions: Int; public let marksEach: Int }
    public let marks: Int; public let durationMinutes: Int; public let sections: [Section]?
    public static func `default`(for level: ClassLevel?) -> MockPattern
    public static func blueprint(_ json: Data) -> MockPattern?
    public var line: String   // "25 marks · 40 minutes"
}
```

- [ ] **Step 1: Write the failing tests** (`DomainTests/ExamPreparationTests.swift`; the Evening batch meets Monday to
  Friday; Dev's Science chapters are the fixtures' Chemical reactions (four skills) and Acids, bases and salts (four))

```swift
struct ExamPreparationTests {
    let today = Day(year: 2026, month: 10, day: 7)!   // Wednesday
    let calendar = DayHeading.india

    @Test func portionsAreCutAtDotsSemicolonsLinesAndChapterMarkers() {
        #expect(ExamPreparation.portions("Ch 1 Chemical reactions · Ch 2 Acids, bases and salts") == ["Chemical reactions", "Acids, bases and salts"])
        #expect(ExamPreparation.portions("Chapters 3 and 4") == ["Chapters 3 and 4"])
        #expect(ExamPreparation.portions("Fractions; Decimals\nPercentages") == ["Fractions", "Decimals", "Percentages"])
    }

    @Test func aPortionMatchesAChapterByNameEitherWay() {
        #expect(ExamPreparation.matching("Ch 1 Chemical reactions", in: devChapters).map(\.name) == ["Chemical reactions"])
        #expect(ExamPreparation.matching("acids and bases", in: devChapters).isEmpty)
        #expect(ExamPreparation.matching("Acids, bases and salts · indicators", in: devChapters).map(\.name) == ["Acids, bases and salts"])
    }

    @Test func nineDaysOutSplitsTwoPortionsOverTheRevisionDaysWithTheMockTwoDaysBefore() {
        // Fri 16 Oct: meeting days Wed 7, Thu 8, Fri 9, Mon 12, Tue 13, Wed 14, Thu 15 (seven). Mock Wed 14; after-mock Thu 15.
        let days = ExamPreparation.days(exam: exam16, batch: evening, today: today, holidays: [], student: dev, students: [dev], chapters: devChapters, skills: devSkills, calendar: calendar)
        #expect(days.map(\.day.day) == [7, 8, 9, 12, 13, 14, 15, 16])
        #expect(days.map(\.kind) == [.revise(index: 1), .revise(index: 2), .revise(index: 3), .revise(index: 4), .revise(index: 5), .mock, .afterMock, .exam])
        #expect(days[0].title == "Chemical reactions · part 1 of 3" && days[0].skills.count == 2)
        #expect(days[3].title == "Acids, bases and salts · first half")
        #expect(days[5].title == "The mock" && days[6].title == "What the mock showed" && days[7].title == "The test")
    }

    @Test func aHolidayDropsItsDaysFromTheSplit() {
        var holiday = SchoolItem.fixture(kind: .holiday, audience: .school(vidya.id), date: Day(year: 2026, month: 10, day: 12)!)
        holiday.endDate = Day(year: 2026, month: 10, day: 13)!
        let days = ExamPreparation.days(exam: exam16, batch: evening, today: today, holidays: [holiday], student: dev, students: [dev], chapters: devChapters, skills: devSkills, calendar: calendar)
        #expect(!days.map(\.day.day).contains(12) && !days.map(\.day.day).contains(13))
    }

    @Test func fewerDaysThanPortionsPutSeveralOnOneDay() {
        let exam = SchoolItem.fixture(kind: .exam, audience: .student(dev.id), date: Day(year: 2026, month: 10, day: 12)!, portions: "Ch 1 · Ch 2 · Ch 3 · Ch 4")
        // Days before: Wed 7, Thu 8, Fri 9 → mock Fri 9, after-mock none, revision Wed and Thu for four portions.
        let days = ExamPreparation.days(exam: exam, batch: evening, today: today, holidays: [], student: dev, students: [dev], chapters: [], skills: [], calendar: calendar)
        #expect(days.map(\.kind) == [.revise(index: 1), .revise(index: 2), .mock, .exam])
        #expect(days[0].title == "Ch 1 · Ch 2" && days[0].skills == ["Ch 1", "Ch 2"])
    }

    @Test func twoDaysLeaveNoRoomForAMock() {
        let exam = SchoolItem.fixture(kind: .exam, audience: .student(dev.id), date: Day(year: 2026, month: 10, day: 9)!, portions: "Ch 1")
        let days = ExamPreparation.days(exam: exam, batch: evening, today: today, holidays: [], student: dev, students: [dev], chapters: devChapters, skills: devSkills, calendar: calendar)
        #expect(days.map(\.kind) == [.revise(index: 1), .revise(index: 2), .exam])
    }

    @Test func theDayBeforeTheExamIsTheLastRevisionDay() {
        let exam = SchoolItem.fixture(kind: .exam, audience: .student(dev.id), date: Day(year: 2026, month: 10, day: 8)!, portions: "Ch 1")
        let days = ExamPreparation.days(exam: exam, batch: evening, today: today, holidays: [], student: dev, students: [dev], chapters: devChapters, skills: devSkills, calendar: calendar)
        #expect(days.map(\.kind) == [.revise(index: 1), .exam])
    }

    @Test func aSecondExamAfterTheFirstIsNotSplitYet() {
        let board = SchoolItem.fixture(kind: .exam, audience: .student(dev.id), date: today.adding(days: 40, calendar: calendar), portions: "Everything")
        #expect(!ExamPreparation.isWithinWindow(board, today: today, calendar: calendar))
        #expect(ExamPreparation.isWithinWindow(exam16, today: today, calendar: calendar))
    }

    @Test func theWeakestSkillAmongThePortionsIsRevisitThenPractisingThenTaught() {
        let names = devSkills.map(\.name)
        #expect(ExamPreparation.weakest(devSkills, among: names)?.name == "Balance a chemical equation")   // the fixture's revisit
        #expect(ExamPreparation.weakest(devSkills.filter { $0.state == .secure }, among: names) == nil)
    }
}
```

`MockPatternTests`: `theDefaultFollowsTheClass` (LKG to 5: 20 and 30; 6 and 7: 25 and 40; 8 and 9: 40 and 60; 10 and
nil: 80 and 180), `aBlueprintReadsAsAPattern` (the CBSE class 10 English blueprint's JSON from Task 1's `types.ts` shape
reads 80 marks, 180 minutes, six sections), `theLineReadsMarksAndMinutes`.

- [ ] **Step 2: Run them to see them fail; implement; run them to see them pass.** The split: the meeting days between
  today and the day before the exam, less the days `HolidayRules.onHoliday` says for the student; `D = count`; with `D >=
  3`: the mock day is the last meeting day `<= exam - 2` that leaves at least one revision day before it (else the last
  meeting day before the exam with one revision day before it); after-mock days are the meeting days after the mock day;
  the parts over the revision days as decision 9 says; `skills` for a part are its matched chapters' skill names in
  position order (the run of the day when the part spans days), else `[part]`; `skillIDs` likewise (empty when none
  matched).

- [ ] **Step 3: Commit**

```bash
git add ios/TutorCentralKit/Sources/Domain/School ios/TutorCentralKit/Tests/DomainTests
git commit -m "Domain: the exam window and the split of portions across the batch's days; the mock's pattern"
```

### Task 6: Domain: exam groups and revision lines in the plan; holidays leave students out; the budget's mock and revision requests (PR 3)

**Files:**
- Modify: `Sources/Domain/Plan/PlanTypes.swift` (`PlanGroup.examItemID`, `PlanInput.revisions`, `PlanInput.holidays`,
  `RevisionLine`), `Sources/Domain/Plan/PlanRules.swift`, `Sources/Domain/Plan/ArtefactBudget.swift`
- Test: `DomainTests/PlanRulesExamTests.swift`, `DomainTests/ArtefactBudgetExamTests.swift`, `PlanRulesTests.swift` (the
  words' limit)

**Interfaces:**
- Consumes: Tasks 4 and 5; Phase 12's `PlanRules`, `PlanDraft`, `PlanLine`, `ArtefactRequest`, `ArtefactBudget`.
- Produces:

```swift
/// A student's exam line for the day (plan decision 10), from ExamPreparation.
public struct RevisionLine: Hashable, Sendable {
    public let itemID: UUID; public let title: String; public let subject: String; public let examDate: Day
    public let day: PreparationDay
    /// The gap report's line for this day, when one was used.
    public let gapLine: String?
    public let gapSkills: [String]
}
// PlanInput gains: revisions: [UUID: RevisionLine] (by student), holidays: Set<UUID> (students on holiday today);
// both default to empty in a new init so Phase 12's callers and tests compile unchanged.
// PlanGroup gains: examItemID: UUID? (nil for a level group), decoded as nil from Phase 12's copies.
public extension PlanRules {
    static let revisionPrefix = "Revise: "
    static let wordsLimit = 200
    static func cut(_ words: String) -> String   // at most 200 scalars, at a word, no trailing " ·"
}
// ArtefactRequest gains:
//   case mock(group: Int, itemID: UUID, title: String, portions: [String], pattern: MockPattern, classLevel: ClassLevel, subject: String)
// ArtefactBudget.requests gains `mocksMade: Set<UUID>` (items whose mock exists) and `gapSkills: [UUID: [String]]`.
```

- [ ] **Step 1: Write the failing tests** (`DomainTests/PlanRulesExamTests.swift`)

```swift
struct PlanRulesExamTests {
    // Dev, Meher, Nikhil (class 8, Vidya), Riya (5), Sahil (2) in the Evening batch; the exam16 revision for the three.
    @Test func studentsOfOneExamFormTheirOwnGroupWithRevisionLines() {
        let draft = PlanRules.plan(input(revisions: revisions(for: [dev, meher, nikhil], day: day7)))
        let examGroup = draft.groups.first { $0.examItemID == exam16.id }
        #expect(examGroup?.number == 1 && examGroup?.subject == "Science" && examGroup?.chapter == "Science unit test 3")
        #expect(examGroup?.skill == "Chemical reactions · part 1 of 3")
        let dev = draft.lines.filter { $0.studentID == dev.id }
        #expect(dev.map(\.kind) == [.teach, .practise, .check, .homework])
        #expect(dev.map(\.words) == ["Revise: Chemical reactions · part 1 of 3", "Revision set 1", "Check 3", "Revision sheet 1"])
        #expect(!draft.lines.contains { $0.groupNo == 1 && [.workedExample, .figure, .brief].contains($0.kind) })
        #expect(draft.groups.count == 3)   // the exam group, then Riya and Sahil by level
    }

    @Test func twoExamsInOneBatchMakeTwoExamGroupsAndOneLevelGroup() {
        var revs = revisions(for: [dev, meher], day: day7)
        revs.merge(revisions(for: [riya], day: day7, exam: riyaExam)) { a, _ in a }
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 2)
        #expect(draft.groups.last?.memberIDs.sorted() == [nikhil.id, sahil.id].sorted())
    }

    @Test func aThirdExamKeepsItsStudentsInTheirLevelGroup() {
        var revs = revisions(for: [dev], day: day7)
        revs.merge(revisions(for: [riya], day: day7, exam: riyaExam)) { a, _ in a }
        revs.merge(revisions(for: [sahil], day: day7, exam: sahilExam)) { a, _ in a }
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 2)
        let sahilLines = draft.lines.filter { $0.studentID == sahil.id }
        #expect(sahilLines.first?.words.hasPrefix("Revise: ") == true)   // his own words, the group's material
    }

    @Test func aBatchOfExamStudentsOnlyMayHaveThreeExamGroups() {
        var revs = revisions(for: [dev], day: day7)
        revs.merge(revisions(for: [meher], day: day7, exam: meherExam)) { a, _ in a }
        revs.merge(revisions(for: [nikhil], day: day7, exam: nikhilExam)) { a, _ in a }
        let draft = PlanRules.plan(input(students: [dev, meher, nikhil], revisions: revs))
        #expect(draft.groups.compactMap(\.examItemID).count == 3)
    }

    @Test func theMockDayHasTheMockForPractiseAndNoHomework() {
        let draft = PlanRules.plan(input(revisions: revisions(for: [dev, meher, nikhil], day: day14)))
        let dev = draft.lines.filter { $0.studentID == dev.id }
        #expect(dev.map(\.kind) == [.teach, .practise, .check])
        #expect(dev[0].words == "The mock · 25 marks · 40 minutes" && dev[1].words == "The mock")
    }

    @Test func theDayAfterTheMockTakesTheGapReportsLineWhenOneWasUsed() {
        var revs = revisions(for: [dev, meher, nikhil], day: day15)
        revs[dev.id] = RevisionLine(itemID: exam16.id, title: "Science unit test 3", subject: "Science", examDate: exam16.date, day: day15, gapLine: "Balancing equations: the worked example, then a set of 6", gapSkills: ["Balance a chemical equation"])
        let draft = PlanRules.plan(input(revisions: revs))
        #expect(draft.lines.first { $0.studentID == dev.id && $0.kind == .teach }?.words == "Balancing equations: the worked example, then a set of 6")
        #expect(draft.lines.first { $0.studentID == meher.id && $0.kind == .teach }?.words == "Revise: what the mock showed")
    }

    @Test func aStudentOnHolidayIsLeftOut() {
        let draft = PlanRules.plan(input(holidays: [riya.id]))
        #expect(draft.leftOut == [riya.id] && !draft.lines.contains { $0.studentID == riya.id })
    }

    @Test func aLinesWordsAreCutAtAWordAtTwoHundred() {
        let long = "Revise: " + String(repeating: "Acids ", count: 50)
        let cut = PlanRules.cut(long)
        #expect(cut.storedCount <= 200 && !cut.hasSuffix(" ") && !cut.hasSuffix("·"))
    }
}
```

`ArtefactBudgetExamTests`: `anExamGroupAsksChecksASetAndASheetFromTheDaysSkillsAndNothingElse` (no worked example, figure
or brief; the sheet's `skills` are the day's), `theMockDayAsksTheMockInTheSetsPlaceOnceOnly` (`.mock` present when
`mocksMade` lacks the item, absent when it has it; no homework sheet), `theAfterMockSetComesFromTheWeakestSkills`
(`gapSkills` for the members, up to six, else the portions), `theBudgetStillHoldsTwentyCalls` (a twelve-student batch
with one exam group and two level groups stays within 20 and under ₹10 on the price sheet with the mock at Sonnet
2,000 in and 2,500 out).

- [ ] **Step 2: Run them to see them fail; implement.** `groups(_:count:)` is wrapped: `examGroups(input)` takes the
  students with a `RevisionLine`, grouped by `itemID`, ordered by `examDate` then title, capped at `maxGroups - 1` when
  any student is left without a revision line (else `maxGroups`); the rest go through Phase 12's level cut with `count
  = min(count ?? …, maxGroups - examGroups.count)` (at least 1 when any remain). Exam groups are numbered first (the
  board's Group 1), then the level groups by size. `studentLines` for a member of an exam group reads the day: teach
  `revisionPrefix + day.title` (`.mock`: "The mock · " + pattern line; `.afterMock`: `gapLine ?? "Revise: what the mock
  showed"`), practise "Revision set n" / "The mock", check "Check 3", homework "Revision sheet n" (none on `.mock`);
  every `words` through `cut`. `leftOut` adds `holidays`. The budget: an exam group's requests as decision 11.

- [ ] **Step 3: Run the tests (the whole `DomainTests`: Phase 12's `PlanRulesTests` must still pass with the new
  defaults); commit**

```bash
git add ios/TutorCentralKit/Sources/Domain/Plan ios/TutorCentralKit/Tests/DomainTests
git commit -m "Domain: exam groups and revision lines in the plan, holidays leave students out, the budget's mock and revision requests"
```

### Task 7: Domain: the cadence, the messages, marks, the mock and gap report contents (PR 3)

**Files:**
- Create: `Sources/Domain/School/MessageCadence.swift`, `TestTomorrowMessage.swift`, `ForwardAskMessage.swift`,
  `Sources/Domain/Record/Mark.swift`, `Sources/Domain/Plan/GapTallies.swift`
- Modify: `Sources/Domain/Plan/Artefact.swift` (`MockContent`, `GapReportContent`, `.mock`, `.gapReport`),
  `Sources/Domain/CheckResult.swift` (`SchemeSource.mock(generationID:artefactID:)`)
- Test: `DomainTests/MessageCadenceTests.swift`, `TestTomorrowMessageTests.swift`, `ForwardAskMessageTests.swift`,
  `MarkRulesTests.swift`, `GapTalliesTests.swift`, `ArtefactContentTests.swift`

**Interfaces:**

```swift
public enum MessageCadence {
    public static let perWeek = 3
    public static let suggestedKinds: Set<MessageKind> = [.note, .canDo, .testTomorrow]
    /// The parent's suggested messages in the week of `now` (Monday to Sunday), across their students.
    public static func suggestedCount(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Int
    public static func canSuggest(_ entries: [MessageEntry], now: Date, calendar: Calendar) -> Bool
}
public struct TestTomorrowMessage: Hashable, Sendable {
    public let parentName: String?; public let studentName: String; public let gender: Gender?; public let title: String
    public let date: Day; public let portions: String?; public let revise: String?; public let tutorName: String?; public let centreName: String
    public var text: String
}
public enum ForwardAskMessage {
    public static let limit = 600
    public static func text(tutorName: String?, centreName: String) -> String
}
public struct MarkRecord: Identifiable, Hashable, Sendable, Codable {
    public let id: UUID; public let studentID: UUID; public let subject: String; public let test: String; public let date: Day
    public let score: Int; public let max: Int; public let photoPath: String?; public let schoolItemID: UUID?; public let artefactID: UUID?
    public let questions: [CheckResult.QuestionMark]?
    public var line: String   // "14 of 25"
}
public struct NewMark: Hashable, Sendable { … the same fields but id … }
public enum MarkRules {
    public static func belowUsual(_ mark: MarkRecord, earlier: [MarkRecord]) -> Bool
}
public struct MockContent: Hashable, Sendable, Codable {
    public struct Question: Hashable, Sendable, Codable, Identifiable { number, text, marks, answer, skill }
    public struct Section: Hashable, Sendable, Codable, Identifiable { name, marksEach, questions }
    public let title: String; public let durationMinutes: Int; public let sections: [Section]; public let pattern: MockPattern
    public let portions: [String]; public let schoolItemID: UUID?
    public var marks: Int; public var line: String   // "25 marks · 40 minutes · chapters 1 and 2"
}
public struct GapReportContent: Hashable, Sendable, Codable {
    public struct Tally: Hashable, Sendable, Codable, Identifiable { skill, right, of, note: String? }
    public struct DayPlan: Hashable, Sendable, Codable { title, line }
    public let summary: String; public let bySkill: [Tally]; public let days: [DayPlan]; public var usedAt: Date?
    public let score: Int; public let max: Int; public let schoolItemID: UUID
}
public enum GapTallies {
    public static func bySkill(_ marking: CheckResult, mock: MockContent) -> [GapReportContent.Tally]
    public static func weakest(_ tallies: [GapReportContent.Tally], count: Int) -> [String]
}
```

- [ ] **Step 1: Write the failing tests**

```swift
struct MessageCadenceTests {
    let calendar = DayHeading.india
    let wed = FakeClock.oct7at1640
    func entry(_ kind: MessageKind, daysAgo: Int) -> MessageEntry { … }

    @Test func threeSuggestedThisWeekSpendTheWeek() {
        let entries = [entry(.note, daysAgo: 2), entry(.testTomorrow, daysAgo: 1), entry(.canDo, daysAgo: 0)]
        #expect(MessageCadence.suggestedCount(entries, now: wed, calendar: calendar) == 3)
        #expect(!MessageCadence.canSuggest(entries, now: wed, calendar: calendar))
    }

    @Test func lastWeeksAndHandSendsDoNotCount() {
        let entries = [entry(.note, daysAgo: 4), entry(.reminder, daysAgo: 1), entry(.absence, daysAgo: 0), entry(.consent, daysAgo: 0)]
        #expect(MessageCadence.suggestedCount(entries, now: wed, calendar: calendar) == 0)   // Monday 5 October starts the week
    }
}

struct TestTomorrowMessageTests {
    @Test func theEnglishMessageReadsAsTheBoardWrote() {
        let message = TestTomorrowMessage(parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test", date: Day(year: 2026, month: 10, day: 8)!, portions: "chapters 1 and 2", revise: "balancing equations", tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        #expect(message.text == "Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2. This evening, let him go over balancing equations once. Thank you.\n\nMeera Nair\nBright Minds Tuition")
    }

    @Test func withoutPortionsOrASkillTheSentencesAdapt() {
        let message = TestTomorrowMessage(parentName: nil, studentName: "Riya Sharma", gender: nil, title: "FA2", date: Day(year: 2026, month: 10, day: 8)!, portions: nil, revise: nil, tutorName: nil, centreName: "Bright Minds Tuition")
        #expect(message.text == "Hello, Riya's FA2 is tomorrow (Thursday 8 October). This evening, a short revision will help. Thank you.\n\nBright Minds Tuition")
    }

    @Test func portionsWithChapterMarkersReadAsAList() {
        let message = TestTomorrowMessage(parentName: "Ramesh Kumar", studentName: "Dev Kumar", gender: .male, title: "Science unit test 3", date: Day(year: 2026, month: 10, day: 16)!, portions: "Ch 1 Chemical reactions · Ch 2 Acids, bases and salts", revise: nil, tutorName: "Meera Nair", centreName: "B")
        #expect(message.text.contains("from Chemical reactions and Acids, bases and salts."))
    }
}

struct ForwardAskMessageTests {
    @Test func theMessageNamesTheTutorAndTheCentre() {
        let text = ForwardAskMessage.text(tutorName: "Meera Nair", centreName: "Bright Minds Tuition")
        #expect(text.hasPrefix("Hello, this is Meera from Bright Minds Tuition. Please forward me whatever the school sends about tests, portions, homework and holidays, as soon as it comes."))
        #expect(text.hasSuffix("Thank you.\n\nMeera Nair\nBright Minds Tuition") && text.storedCount <= ForwardAskMessage.limit)
    }
}

struct MarkRulesTests {
    @Test func belowUsualNeedsTwoEarlierMarksInTheSubjectAndTenPointsUnderTheirMean() {
        let earlier = [mark("Unit test 1", 19, 25, daysAgo: 44), mark("FA1", 18, 25, daysAgo: 80)]   // mean 74%
        #expect(MarkRules.belowUsual(mark("Unit test 2", 14, 25, daysAgo: 9), earlier: earlier))       // 56%
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 17, 25, daysAgo: 9), earlier: earlier))      // 68%
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 10, 25, daysAgo: 9), earlier: [earlier[0]]))
        #expect(!MarkRules.belowUsual(mark("Unit test 2", 10, 25, daysAgo: 9, subject: "Science"), earlier: earlier))
    }
}

struct GapTalliesTests {
    @Test func talliesGroupTheMarkingBySkillInTheMocksOrder() {
        let tallies = GapTallies.bySkill(marking, mock: mock)   // the fake's mock and a marking with Q4 and Q6 wrong
        #expect(tallies.map(\.skill) == ["Spot a chemical change", "Write a word equation", "Balance a chemical equation", "Name the types of reactions"])
        #expect(tallies.first { $0.skill == "Balance a chemical equation" }.map { ($0.right, $0.of) } == (3, 10))
        #expect(GapTallies.weakest(tallies, count: 2) == ["Balance a chemical equation", "Name the types of reactions"])
    }
}

// ArtefactContentTests gains:
@Test func aMockAndAGapReportRoundTripThroughTheKeepsKeys() throws {
    let mock = MockContent.fixture
    let data = try ArtefactContent.mock(mock).encoded()
    #expect(String(decoding: data, as: UTF8.self).contains("\"duration_minutes\""))
    #expect(try ArtefactContent.decode(kind: .mock, json: data) == .mock(mock))
    let report = GapReportContent.fixture
    #expect(try ArtefactContent.decode(kind: .gapReport, json: try ArtefactContent.gapReport(report).encoded()) == .gapReport(report))
}
```

- [ ] **Step 2: Run them to see them fail; implement; run them to see them pass.** `TestTomorrowMessage.text`: the
  greeting as `AbsenceMessage` does; the child's first name; the title with its first letter lowered unless its second
  character is upper case; "from " + the portions as `ExamPreparation.portions` joins them ("a and b", "a, b and c") or
  the raw portions when they do not split; the pronoun from `PlanRules.pronoun`'s rule ("him", "her", "them"); the
  signature as `AbsenceMessage`. `MarkRules.belowUsual`: earlier marks in the same subject with `date` before the mark's,
  at least two, the mark's percentage more than ten points under their mean percentage. `GapTallies.bySkill`: each mock
  question's skill, the marking's marks by question number (a missing number counts 0 of the question's marks), in the
  order the skills first appear in the mock. `SchemeSource.mock(generationID:artefactID:)` is valid.

- [ ] **Step 3: Commit**

```bash
git add ios/TutorCentralKit/Sources/Domain ios/TutorCentralKit/Tests/DomainTests
git commit -m "Domain: the message cadence, Test tomorrow and the forward ask, marks and below usual, the mock and gap report contents"
```

### Task 8: Data: the items repository, its rows and fake; the tab's copy on the iPhone; the inbox read and removed (PR 4)

**Files:**
- Create: `Sources/Data/School/SchoolItemsRepository.swift`, `SupabaseSchoolItemsRepository.swift`, `SchoolItemRow.swift`,
  `FakeSchoolItemsRepository.swift`, `SchoolCache.swift`
- Modify: `Sources/AppShell/SharedInbox.swift` (`remove(_:)`, `image(of:)`)
- Test: `DataTests/SchoolItemRowTests.swift`, `FakeSchoolItemsRepositoryTests.swift`, `SchoolCacheTests.swift`,
  `AppShellTests/SharedInboxTests.swift`

**Interfaces:**

```swift
public protocol SchoolItemsRepository: Sendable {
    /// Every confirmed item of the centre, by date then title.
    func items(centre: UUID) async throws -> [SchoolItem]
    func item(id: UUID, centre: UUID) async throws -> SchoolItem?
    /// Add on "Check what was read": the complete, ticked drafts in one insert with `confirmed_at` set; the items back.
    func add(_ drafts: [SchoolItemDraft], photoPath: String?, centre: UUID) async throws -> [SchoolItem]
    func update(_ item: SchoolItem) async throws -> SchoolItem
    func delete(id: UUID, centre: UUID) async throws
}
/// The tab's copy (D39): `cache-<centre>-school.json`.
public struct SchoolCache: Sendable { init(centre:directory:); func load() -> CachedValue<[SchoolItem]>?; func keep(_ items: [SchoolItem], at: Date) }
// SharedInbox gains:
//   public func remove(_ item: Item) throws        // the item's file and its image
//   public func image(of item: Item) -> Data?      // the bytes beside it, whatever their format
```

- [ ] **Step 1: Write the failing tests.** `SchoolItemRowTests.aRowReadsIntoAnItemWithItsAudience` (three rows: a student's,
  a school's class, a whole school; `end_date`, `source`, `received_at`, `confirmed_at` read; a row with an unknown
  `source` word reads as `.typed`); `FakeSchoolItemsRepositoryTests` (`addKeepsOnlyCompleteTickedDraftsAndConfirmsThem`,
  `updateReplacesTheItem`, `deleteRemovesIt`, `aScriptedFailureThrows`); `SchoolCacheTests.keepsAndLoadsTheItems`;
  `SharedInboxTests.removingAnItemLeavesTheOthers` and `anImageIsReadBesideItsItem`.

- [ ] **Step 2: Run them to see them fail; implement.** The Supabase repository selects `id, kind, school_id, student_id,
  class_level, title, subject, date, end_date, portions, source_text, photo_path, source, received_at, confirmed_at`
  ordered by `date, title`; `add` inserts the rows with `confirmed_at: now` and `photo_path` and returns them; `update`
  patches the row by id. `SharedInbox.remove` deletes `<id>.json` and the file it names.

- [ ] **Step 3: Run the tests; commit**

```bash
git add ios/TutorCentralKit/Sources/Data/School ios/TutorCentralKit/Sources/AppShell/SharedInbox.swift ios/TutorCentralKit/Tests/DataTests ios/TutorCentralKit/Tests/AppShellTests/SharedInboxTests.swift
git commit -m "Data: school items, their copy on the iPhone, the inbox read and removed"
```

### Task 9: Data: marks, the message log's kinds, photos removed, the mock and gap report kept, a group named (PR 4)

**Files:**
- Modify: `Sources/Data/Record/RecordRepository.swift`, `SupabaseRecordRepository.swift`, `FakeRecordRepository.swift`,
  `RecordRows.swift` (`MarkRow`), `Sources/Data/Messages/*`, `Sources/Data/Photos/PhotoStore.swift`,
  `Sources/Data/Plans/PlansRepository.swift`, `SupabasePlansRepository.swift`, `FakePlansRepository.swift`,
  `Sources/Data/Textbooks/TextbooksRepository.swift` (+ Supabase and Fake)
- Test: `DataTests/MarkRowTests.swift`, `FakeRecordRepositoryTests.swift`, `FakeMessageLogRepositoryTests.swift`,
  `FakePhotoStoreTests.swift`, `FakePlansRepositoryTests.swift`

**Interfaces:**

```swift
// RecordRepository gains:
func marks(centre: UUID, students: [UUID]) async throws -> [MarkRecord]          // newest first
func addMark(_ mark: NewMark, centre: UUID) async throws -> MarkRecord
func deleteMark(id: UUID, centre: UUID) async throws                              // Undo after a mock's Save
// MessageLogRepository gains:
func logTestTomorrow(centre: UUID, studentID: UUID, language: MessageLanguage, body: String) async throws -> Date
func logForwardAsk(centre: UUID, studentID: UUID) async throws -> Date
func forwardAsked(centre: UUID) async throws -> [UUID: Date]                      // by student, the latest
func entries(centre: UUID, since: Date) async throws -> [(studentID: UUID, entry: MessageEntry)]   // the cadence
// PhotoStore gains:
func remove(path: String) async throws
// PlansRepository gains (ArtefactLink gains `schoolItem: UUID?`, nil by default; `plan` becomes optional):
func mock(for item: UUID, centre: UUID) async throws -> Artefact?
func gapReport(for item: UUID, student: UUID, centre: UUID) async throws -> Artefact?
func artefacts(for item: UUID, centre: UUID) async throws -> [Artefact]
func setContent(_ content: ArtefactContent, artefact: UUID, centre: UUID) async throws
func nameGroup(plan: UUID, group: Int, chapter: String, skill: String, centre: UUID) async throws
// TextbooksRepository gains (Task 23's write):
func addNamedChapter(student: UUID, subject: String, name: String, skill: String, centre: UUID) async throws -> Chapter
```

- [ ] **Step 1: Write the failing tests**, one per new call on each fake, and `MarkRowTests.aRowReadsItsQuestionsAndLinks`
  (a `marks` row with `questions` as the API's `CheckOutput` question shape reads into `QuestionMark`s; a row without
  reads nil). `FakePlansRepositoryTests.keepWithAnItemAndNoPlanLinksNoLine` and `nameGroupRenamesTheGroupAndItsTeachLines`
  (the fake mirrors `name_plan_group`: `plans.groups` and the "Teach: with the group" lines; links untouched).

- [ ] **Step 2: Run them to see them fail; implement.** `SupabasePlansRepository.keep` passes `p_school_item` and a null
  `p_plan` when the link has none; `nameGroup` calls `name_plan_group`; `setContent` patches `artefacts.content` by id.
  `SupabasePhotoStore.remove` is `files.remove(paths: [path])`. `addNamedChapter` inserts the chapter after the subject's
  last position with no source and one skill `not_started` (the textbooks repository already inserts a tutor's own
  chapter; this reuses that path with a skill).

- [ ] **Step 3: Run the tests; commit**

```bash
git add ios/TutorCentralKit/Sources/Data ios/TutorCentralKit/Tests/DataTests
git commit -m "Data: marks, the message log's new kinds, photos removed, the mock and gap report kept for an exam, a group named, a named chapter"
```

### Task 10: Data: the API client's five calls, the fake's answers; the write proofs (PR 4)

**Files:**
- Modify: `Sources/Data/AI/AIRepository.swift`, `APIBodies.swift`, `FakeAIRepository.swift`, `AISamples+School.swift`
  (new), `APIClient.swift` (`checkPaper` with the student)
- Create: `Sources/Data/AI/APIClient+School.swift`
- Test: `DataTests/APIBodiesSchoolTests.swift`, `FakeAIRepositorySchoolTests.swift`, and the throwaway write proof of
  `ios/CLAUDE.md` (a test against the local stack with an in-memory session, run once, not committed)

**Interfaces:**

```swift
public enum SchoolSource: Hashable, Sendable { case text(String), image(ImageUpload) }
public struct ParsedItem: Hashable, Sendable, Decodable { kind, title, subject?, date: Day?, endDate: Day?, classLevel: ClassLevel?, school: String?, studentName: String?, portions: String? }
public struct SchoolReading: Hashable, Sendable { public let id: UUID; public let items: [ParsedItem] }
public struct MockRequest: Hashable, Sendable { classLevel, subject, title, portions: [String], pattern: MockPattern }
public struct MadeMock: Hashable, Sendable { generationID, content: MockContent }
public struct GapRequest: Hashable, Sendable { studentID, classLevel, subject, daysLeft: Int, bySkill: [GapReportContent.Tally] }
public struct MadeGapReport: Hashable, Sendable { generationID, summary: String, days: [GapReportContent.DayPlan] }
public struct TestTomorrowRequest: Hashable, Sendable { studentID, studentName, parentName?, tutorName, centreName, language, subject, title, date: Day, portions?, revise? }
public struct MadeMessage: Hashable, Sendable { generationID, message: String, english: String }
// AIRepository gains:
func parseSchool(_ source: SchoolSource, today: Day, schools: [String], classLevels: [ClassLevel], centre: UUID) async throws(APIFailure) -> SchoolReading
func makeMock(_ request: MockRequest, centre: UUID) async throws(APIFailure) -> MadeMock
func makeGapReport(_ request: GapRequest, centre: UUID) async throws(APIFailure) -> MadeGapReport
func makeTestTomorrow(_ request: TestTomorrowRequest, centre: UUID) async throws(APIFailure) -> MadeMessage
func checkPaper(pages: [ImageUpload], scheme: SchemeSource, studentName: String, studentID: UUID?, centre: UUID) async throws(APIFailure) -> CheckAnswer
```

- [ ] **Step 1: Write the failing tests.** `APIBodiesSchoolTests`: `theParseBodyCarriesTodayTheSchoolsAndNoStudent` (the
  encoded JSON has `today`, `schools`, `classLevels`, no `studentId`, the image when given), `theMockBodyIsStrictAndNamesNoStudent`,
  `theGapAndTestTomorrowBodiesNameTheStudent`, `aMockSchemeSendsItsGenerationAndTheStudent` (`{"scheme":{"kind":"mock",
  "generationId":…},"studentId":…}`), `aParsedItemReadsANullDate`. `FakeAIRepositorySchoolTests`: the fake answers the
  samples (the photo's two exams, the text's three items; the mock summing to the pattern; the gap report; the message
  with its English) and records each call (`parseCalls`, `mockCalls`, `gapCalls`, `messageCalls`); a scripted
  `APIFailure` throws.

- [ ] **Step 2: Run them to see them fail; implement; run them to see them pass.**

- [ ] **Step 3: The write proofs** (`ios/CLAUDE.md`'s rule, against the local stack with the local API on `AI_FAKE=1`, a
  throwaway test): `add` three drafts and read them back; `update` a title; `delete` one; `addMark` and `deleteMark`;
  `logForwardAsk` and `forwardAsked`; `keep` a mock with an item and no plan, `mock(for:)`; `nameGroup` on a plan from
  `make`; `parseSchool` with text; `makeMock`; `checkPaper` with a mock scheme and the student (the API must take it:
  a student without consent answers `.consent`). Each decodes. Not committed.

- [ ] **Step 4: Commit**

```bash
git add ios/TutorCentralKit/Sources/Data/AI ios/TutorCentralKit/Tests/DataTests
git commit -m "Data: the API client's school calls (parse-school, mock, gap report, test tomorrow, a mock's marking) and the fake's answers"
```

### Task 11: DesignSystem: the School parts (PR 5)

**Files:**
- Create: `Sources/DesignSystem/Components/KindChip.swift`, `SchoolRow.swift`, `ItemCard.swift`, `SourceWell.swift`,
  `PreparationRow.swift`, `ParentSendRow.swift`, `TwoLanguageMessageSheet.swift`, `ScoreHero.swift`, `SkillBarRow.swift`
- Modify: `Sources/DesignSystem/Components/CalendarMonth.swift` (dots by kind), `Tokens/Tokens.swift` and
  `docs/design/design-tokens.md` only where a board's value is new (none expected: the parts reuse `time`, `caption`,
  `rowTitle`, `footnote`, `numberRow`, `numberHero`, the chip tones; the fact label's 64 pt is `Tokens.factLabelWidth`
  if `components.md` 10.5 names a value no token has)
- Test: `DesignSystemTests/CalendarDotsTests.swift`, `TokenDocumentTests` (unchanged, must stay green)

**Interfaces** (each as `components.md` "Phase 10 parts" 10.5 and 10.4 describe):

```swift
public struct KindChip: View { public init(_ kind: KindChipKind) }   // exam overdue exclamationmark.circle, homework due doc.text, notice neutral flag, holiday ok calendar
public enum KindChipKind: Sendable { case exam, homework, notice, holiday; var title: String }
public struct SchoolRow: View { public init(day: String, date: String, title: String, line: String, kind: KindChipKind, action: @escaping () -> Void) }
public struct ItemCard<Facts: View>: View { public init(ticked: Binding<Bool>, title: String, kind: KindChipKind, open: @escaping () -> Void, @ViewBuilder facts: () -> Facts) }
public struct FactLine: View { public init(label: String, value: String, missing: Bool = false) }   // missing: value in text3
public struct SourceWell: View { public init(label: String, text: String?, image: UIImage?, collapsedHeight: CGFloat = 96) }
public struct PreparationRow: View { public enum Mark { case done, today, mock, none }; public init(day: String, date: String, title: String, line: String, mark: Mark, action: (() -> Void)?) }
public struct ParentSendRow: View { public enum State { case send, sent, noNumber }; public init(initials: String, name: String, line: String, state: State, send: @escaping () async -> Void) }
public struct TwoLanguageMessageSheet: View { public init(title: String, name: String, parentLine: String, languageTitle: String, message: Binding<String>, english: String?, note: String, canOpen: Bool, open: @escaping () async -> Void, close: @escaping () -> Void) }   // english nil: one block (an English parent)
public struct ScoreHero: View { public init(eyebrow: String, score: Int, of: Int, line: String) }
public struct SkillBarRow: View { public init(skill: String, line: String, right: Int, of: Int) }   // ok at 3 or 4 of 4, due between, overdue under half
public enum CalendarDot: Hashable, Sendable { case exam, homework, holiday, notice }
// CalendarMonth gains init(month:today:selected:dots: [Date: [CalendarDot]], calendar:) drawing one 4 pt dot per kind in its colour (at most three dots a day, exam first).
```

- [ ] **Step 1: Write the failing test** (`CalendarDotsTests.aDayDrawsOneDotPerKindExamFirstAtMostThree`: the pure
  `CalendarMonth.dots(for:)` helper orders and caps) and the Kit's Phase 10 board section is not changed (it is Phase
  15's); the parts are previewed in each file's `#Preview`.
- [ ] **Step 2: Implement the parts with tokens only; `bun check --only=format,lint,ios`; commit**

```bash
git add ios/TutorCentralKit/Sources/DesignSystem ios/TutorCentralKit/Tests/DesignSystemTests
git commit -m "DesignSystem: the School parts (kind chip, school row, item card, source well, preparation row, parent send row, the two-language sheet, the score hero, skill bars, calendar dots)"
```

### Task 12: School: the tab (empty, the list, the calendar, the menu), its copy offline (PR 5)

**Files:**
- Create: `Sources/Features/School/SchoolActions.swift`, `SchoolStore.swift`, `SchoolView.swift`, `SchoolSections.swift`,
  `SchoolCalendarSection.swift`, `SchoolWords.swift`; `Tests/SchoolTests/SchoolStoreTests.swift`; the `School` target and
  `SchoolTests` in `Package.swift` (`features` gains "School"; the test target depends on `School` and `Students`) and
  `project.yml` (the scheme's test list)

**Interfaces:**

```swift
public struct SchoolActions: Sendable {
    public let openItem: (UUID) -> Void
    public let read: (ReadSource) -> Void          // the "+" menu's From a photo, Paste a message, Add by hand, a share
    public let askParents: () -> Void
}
public enum ReadSource: Hashable, Sendable { case photo(ImageUpload), pasted(String), typed, shared(SharedItemID) }
@MainActor @Observable public final class SchoolStore {
    public enum State: Hashable, Sendable { case loading, empty, items, offline, failed }
    public enum Segment: Hashable, Sendable, CaseIterable { case list, calendar }
    public private(set) var state: State
    public var segment: Segment
    public private(set) var buckets: [(title: String, rows: [SchoolRowModel])]
    public var selectedDay: Day?                          // the calendar's chosen day (today at first)
    public private(set) var dots: [Day: [CalendarDot]]
    public var dayRows: [SchoolRowModel]                  // the chosen day's items
    public func load() async; public func refresh() async
    public init(workspace:, items: any SchoolItemsRepository, register: any Register, schools: any SchoolsRepository, cache: SchoolCache?, now:, calendar:)
}
public struct SchoolRowModel: Identifiable, Hashable, Sendable { id, day, date, title, line, kind: KindChipKind }
```

- [ ] **Step 1: Write the failing tests** (`SchoolTests/SchoolStoreTests.swift`, against `FakeSchoolItemsRepository`, the
  fixtures' register and schools)

```swift
@MainActor struct SchoolStoreTests {
    @Test func withNoItemsTheTabIsEmptyAndWithItemsItBuckets() async {
        let store = makeStore(items: [])
        await store.load()
        #expect(store.state == .empty)
        let filled = makeStore(items: SchoolFixtures.boardItems)
        await filled.load()
        #expect(filled.state == .items && filled.buckets.map(\.title) == ["This week", "Next week", "Later"])
        #expect(filled.buckets[1].rows.map(\.title) == ["Maths Ex 3.2, Q1 to 10", "Science unit test 3"])
        #expect(filled.buckets[1].rows[1].line == "Class 8 at Vidya Niketan · Dev, Meher, Nikhil · in 9 days")
    }

    @Test func theCalendarDotsEachDayByKindAndListsTheChosenDay() async {
        let store = makeStore(items: SchoolFixtures.boardItems)
        await store.load()
        store.segment = .calendar
        store.selectedDay = Day(year: 2026, month: 10, day: 16)
        #expect(store.dots[Day(year: 2026, month: 10, day: 16)!] == [.exam])
        #expect(store.dots[Day(year: 2026, month: 10, day: 20)!] == [.holiday])   // a holiday covers its days
        #expect(store.dayRows.map(\.title) == ["Science unit test 3"])
    }

    @Test func offlineTheTabShowsItsCopyAndAFailedReadWithNoCopySaysSo() async {
        let cache = SchoolCache(centre: centre, directory: tmp)
        cache.keep(SchoolFixtures.boardItems, at: .now)
        let offline = makeStore(items: SchoolFixtures.boardItems, failure: URLError(.notConnectedToInternet), cache: cache)
        await offline.load()
        #expect(offline.state == .offline && !offline.buckets.isEmpty)
        let bare = makeStore(items: [], failure: URLError(.notConnectedToInternet), cache: nil)
        await bare.load()
        #expect(bare.state == .failed)
    }
}
```

- [ ] **Step 2: Run them to see them fail (the target does not exist); add the target; implement.** The view: the tab
  root with the large title "School" and the "+" `IconButton` (its menu: From a photo, Paste a message, Add by hand, Ask
  parents to forward, each a `Label` with its symbol), the `Segmented` List | Calendar under the title, the list as
  `SectionHeader`s and `Card`s of `SchoolRow`s, the calendar as `CalendarMonth` with dots and the day's rows under it,
  the empty state as P10-School-Empty (the Kit's empty card with the two plain-label buttons and the footnote), offline
  the status line (`RootStatus`) over the copy, a failed load `LoadFailedView`. From a photo uses V1's `PhotoPicker`
  (camera or Photos, `PhotoReducer`); Paste a message reads `UIPasteboard.general.string` and, with none, shows the
  alert "Nothing to paste. Copy the school's message first." (`NoticeCenter`).

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; commit**

```bash
git add ios/TutorCentralKit/Package.swift ios/project.yml ios/TutorCentralKit/Sources/Features/School ios/TutorCentralKit/Tests/SchoolTests
git commit -m "School: the tab, empty, the list by week, the calendar with dots, the menu, the copy offline"
```

### Task 13: School: Check what was read, from a share, a photo, the pasteboard or by hand; the item's sheet (PR 5)

**Files:**
- Create: `Sources/Features/School/ReadStore.swift`, `ReadStore+Resolve.swift`, `ReadView.swift`, `ItemFormStore.swift`,
  `ItemFormSheet.swift`, `ForSheet.swift`
- Test: `SchoolTests/ReadStoreTests.swift`, `ItemFormStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class ReadStore {
    public enum Stage: Hashable, Sendable { case reading, read, adding, added([SchoolItem]), failed(String) }
    public private(set) var stage: Stage
    public private(set) var source: ReadSource
    public private(set) var sourceText: String?; public private(set) var sourceImage: UIImage?
    public private(set) var drafts: [SchoolItemDraft]
    public var message: String?
    public var countLine: String             // "3 items read"
    public var addLabel: String              // "Add 3 items", "Add an item", disabled at none
    public var canAdd: Bool
    public func read() async                 // /ai/parse-school, then resolve
    public func toggle(_ id: UUID); public func addDraft(); public func replace(_ draft: SchoolItemDraft); public func remove(_ id: UUID)
    public func add() async -> Bool          // the ticked complete drafts in one insert, the photo uploaded first
    public func leave()                      // the inbox item removed
    public init(source: ReadSource, workspace:, items:, ai:, register:, schools:, photos:, inbox: SharedInbox?, now:, calendar:, online:)
}
/// Resolves what the parser read to the centre: a named school to a School, a class to the school's class, a named student
/// to one student (first name and surname, case-insensitive, one match), else the audience stays nil ("Choose").
enum DraftResolver { static func resolve(_ parsed: ParsedItem, source: ReadSource, schools: [School], students: [Student], today: Day) -> SchoolItemDraft }
@MainActor @Observable public final class ItemFormStore { … kind, title, audience, subject, date, endDate, portions, counter "54 of 500", problems, canSave, func draft() -> SchoolItemDraft; func item(from existing: SchoolItem) -> SchoolItem }
```

- [ ] **Step 1: Write the failing tests** (`ReadStoreTests`, against `FakeAIRepository` with the photo and text samples and
  the fixtures' register and schools)

```swift
@MainActor struct ReadStoreTests {
    @Test func aMessageReadsIntoThreeDraftsForTheRightPeople() async {
        let store = makeStore(.pasted(SchoolFixtures.boardMessage))
        await store.read()
        #expect(store.stage == .read && store.drafts.count == 3 && store.countLine == "3 items read")
        #expect(store.drafts[0].audience == .schoolClass(school: FakeSchoolsRepository.vidya.id, level: .eight))
        #expect(store.drafts[2].kind == .holiday && store.drafts[2].audience == .school(FakeSchoolsRepository.vidya.id) && store.drafts[2].endDate != nil)
        #expect(store.drafts.allSatisfy(\.ticked) && store.addLabel == "Add 3 items")
    }

    @Test func aTimetablePhotoReadsIntoTwoExamsWithTheirDates() async {
        let store = makeStore(.photo(SchoolFixtures.timetable))
        await store.read()
        #expect(store.drafts.map(\.kind) == [.exam, .exam] && store.drafts.map(\.date?.day) == [16, 16])
    }

    @Test func aDraftWithoutADateStaysUnticked() async {
        let store = makeStore(.pasted("Unit test next week"), ai: FakeAIRepository(parse: [.undated]))
        await store.read()
        #expect(store.drafts[0].ticked == false && store.drafts[0].missing == [.date] && !store.canAdd)
    }

    @Test func settingTheDateOnTheSheetTicksTheDraft() async {
        let store = makeStore(.pasted("Unit test next week"), ai: FakeAIRepository(parse: [.undated]))
        await store.read()
        var draft = store.drafts[0]
        draft.date = Day(year: 2026, month: 10, day: 14)
        store.replace(draft)
        #expect(store.drafts[0].ticked && store.canAdd)
    }

    @Test func anItemForAnEmptyClassIsKeptAndSaysSo() async {
        let store = makeStore(.pasted("Class 9 unit test"), ai: FakeAIRepository(parse: [.classNine]))
        await store.read()
        #expect(store.drafts[0].audience == .schoolClass(school: FakeSchoolsRepository.vidya.id, level: .nine) && store.drafts[0].ticked)
        #expect(await store.add())
    }

    @Test func aStudentNamedInTheMessageIsTheItemsAudienceAndAnUnknownNameLeavesItToChoose() async {
        let dev = makeStore(.pasted("Dev Kumar has not submitted his science homework, due Monday 12 Oct."), ai: FakeAIRepository(parse: [.aboutDev]))
        await dev.read()
        #expect(dev.drafts[0].audience == .student(FakeStudentsRepository.dev))
        let unknown = makeStore(.pasted("Rahul has …"), ai: FakeAIRepository(parse: [.aboutRahul]))
        await unknown.read()
        #expect(unknown.drafts[0].audience == nil && unknown.drafts[0].missing == [.audience] && !unknown.drafts[0].ticked)
    }

    @Test func addWritesTheTickedCompleteDraftsUploadsThePhotoAndRemovesTheInboxItem() async throws {
        let inbox = try SharedInbox.temporary(with: .image(SchoolFixtures.timetable))
        let items = FakeSchoolItemsRepository()
        let photos = FakePhotoStore()
        let store = makeStore(.shared(inbox.items()[0].id), items: items, photos: photos, inbox: inbox)
        await store.read()
        store.toggle(store.drafts[1].id)
        #expect(await store.add())
        #expect(items.items.count == 1 && items.items[0].photoPath?.contains("/item/") == true && photos.paths.count == 1)
        #expect(try inbox.items().isEmpty)
    }

    @Test func nothingReadIsSaidInWordsAndOfflineTheInboxWaits() async {
        let none = makeStore(.pasted("Good morning"), ai: FakeAIRepository(parseFailure: .refused("Couldn't find a test, homework, notice or holiday in this. Add it by hand.")))
        await none.read()
        #expect(none.stage == .failed("Couldn't find a test, homework, notice or holiday in this. Add it by hand."))
        let offline = makeStore(.pasted("x"), online: false)
        await offline.read()
        #expect(offline.message == OfflineRefusal.words(for: .readSchool))
    }

    @Test func addOfflineIsRefusedAndKeepsTheDrafts() async {
        let store = makeStore(.pasted(SchoolFixtures.boardMessage))
        await store.read()
        store.online = { false }
        #expect(await store.add() == false && store.message == OfflineRefusal.words(for: .schoolItem) && store.drafts.count == 3)
    }
}
```

`ItemFormStoreTests`: `saveNeedsAKindATitleWhoAndADateAndAnExamASubject`, `theCounterCountsScalarsOf500`,
`aHolidayTakesAnEndDateNotBeforeItsDate`, `theForSheetListsEachSchoolsClassesWithCountsEveryClassAndTheStudents`.

- [ ] **Step 2: Run them to see them fail; implement.** The view (P10-School-Confirm): the pushed screen "Check what was
  read" with `BackRow`; the `SourceWell` labelled "What the school sent" (the text, or the photo); the `SectionHeader`
  with `countLine` and the quiet Add an item; one `ItemCard` per draft with its `FactLine`s (For, Subject, Date or Due or
  Dates, Portions; a missing fact in `text3`); the footer `FooterButton` with `addLabel`; the footnote "Open an item to
  change who it is for, the date or the portions. Nothing is kept until you tap Add."; while reading, the `CreatingCard`
  "Reading what the school sent" with the line "Usually under a minute." over the dimmed empty list (P13-School-Reading);
  a failure in the system alert with Try again. The item's sheet (P10-School-Confirm-Edit) is a `FittedSheet` with
  Cancel, "Item", Save: Kind chips (`ChipRow`), Title, For (`PickerTileHelper` opening the `ForSheet`: `ChoiceRow`s per
  school's class with the students' names as the line, "every class" per school, then the students), Subject (the
  textbook sheet's subject rows), Date (and To for a holiday; the Phase 3 day tile), Portions (`NotesWell` with the 500
  counter), Remove this item in `overdue`. Leaving with Back while drafts stand asks "Leave without adding?" (the Scan
  register dialog's words adapted: "Nothing read here is kept.").

- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; commit**

```bash
git add ios/TutorCentralKit/Sources/Features/School ios/TutorCentralKit/Tests/SchoolTests
git commit -m "School: Check what was read from a share, a photo, the pasteboard or by hand; the item's sheet and the For sheet"
```

### Task 14: School: an item's page, Edit and Delete; AppShell: the feature wired, the hand-off, the routes, the launch states; the student page's School section (PR 5)

**Files:**
- Create: `Sources/Features/School/ItemStore.swift`, `ItemView.swift`, `ItemSections.swift`; `Sources/AppShell/RootView+School.swift`,
  `Fixtures+School.swift`
- Modify: `Sources/AppShell/TabsState.swift` (`Route.schoolRead(ReadSource)`, `.schoolItem(UUID)`, `.schoolAsk`),
  `TabsView.swift`, `RootView.swift` (the School tab's root; the inbox read on launch and on foreground), `ShellState.swift`
  (`inboxHandoff()`, `schoolItemsChanged`), `DeepLink.swift` (`.school(UUID)`), `Dependencies.swift` (`schoolItems`),
  `LaunchState.swift`, `RootView+LaunchStates.swift`, `Fixtures.swift`; `SchoolLaterView.swift` removed;
  `Sources/Features/Students/RecordSections.swift` (`SchoolSection` rows), `StudentDetailStore+Record.swift`,
  `StudentDetailView.swift`
- Test: `SchoolTests/ItemStoreTests.swift`, `AppShellTests/InboxHandoffTests.swift`, `DeepLinkTests.swift`,
  `LaunchStateTests.swift`, `StudentsTests/StudentDetailStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class ItemStore {
    public enum State: Hashable, Sendable { case loading, shown, gone, failed }
    public private(set) var item: SchoolItem?
    public var hero: ItemHeroModel          // "Vidya Niketan · Class 8 · Science", the chip, the title, "Friday 16 October · in 9 days", "Portions: …"
    public var who: [WhoRow]               // the students with the status word and their next step
    public var coveredLine: String?        // a holiday: the batch days it covers
    public var sourceLine: String          // "Shared on Wed 7 Oct, 15:04"
    public func load() async; public func save(_ edited: SchoolItem) async -> Bool; public func delete() async -> Bool
    public var onChanged: ((Set<UUID>) -> Void)?   // the students reached, for the plan (decision 16)
}
// DeepLink gains .school(UUID) ("tutorcentral://school/<id>", tab .school).
// ShellState gains func inboxHandoff() (reads SharedInbox.live(); the first item opens .schoolRead(.shared(id)) on the School tab when signed in; nothing when a read screen is already up) and schoolItemsChanged: (Set<UUID>) -> Void (Task 17 fills it).
```

- [ ] **Step 1: Write the failing tests.** `ItemStoreTests`: `anExamsHeroWhoAndSourceLineReadFromTheItem`,
  `aHolidaysPageSaysTheBatchDaysItCovers`, `deleteRemovesTheItemAndItsPhotoAndTellsThePlan` (the fake photo store's
  path gone, `onChanged` called with Dev, Meher and Nikhil), `anItemGoneReadsGone`, `saveOfflineIsRefused`.
  `InboxHandoffTests`: `anInboxItemWaitsForSignIn` (signed out: nothing pushed; after the session becomes ready the
  School tab is selected with `.schoolRead(.shared(…))`), `twoItemsAreReadOneAfterTheOther` (the second is pushed only
  after the first screen leaves), `aHandoffDoesNotStackASecondReadScreen`. `DeepLinkTests.schoolOpensTheItem`.
  `LaunchStateTests` (the new states parse and `later-school` is gone). `StudentDetailStoreTests.theSchoolSectionListsTheStudentsNextFiveItems`.

- [ ] **Step 2: Run them to see them fail; implement.** The page (P10-School-Item without Preparation this task; Task 18
  adds it): `BackRow` with the kind's word as the title and the quiet Edit; the hero card; Who (a `Card` of rows: avatar
  36, the name, the status word and next step); for a holiday the covered line in Who's place; What the school sent (the
  `SourceWell` expanded, or the photo loaded from `PhotoStore.url`, the source line under); Delete this item in
  `overdue` opening the `Dialog` with the board's words. `RootView+School` builds the stores; the School tab's root is
  `SchoolView`; `inboxHandoff` runs after the session is ready on launch and in `refreshScreens`; the fixtures
  (`Fixtures+School`) hold the boards' items, the reading state's drafts (`school-reading` opens the read screen with the
  fake answering after a long delay), and the pages' items.

- [ ] **Step 3: Run the tests; `bun check`; the pictures** (`school-empty` both, `school` both, `school-calendar`,
  `school-add-menu`, `school-reading`, `school-confirm`, `school-confirm-edit`, `school-item-homework`,
  `school-item-holiday`, `student-end`), compared with the boards; `bun pr-shots`; commit; open PR 5; merge when green.

```bash
git add ios/TutorCentralKit ios/project.yml
git commit -m "School: an item's page, Edit and Delete; the share hand-off, the routes, the launch states; the student page's School section"
```

### Task 15: School: Ask parents to forward (PR 6)

**Files:**
- Create: `Sources/Features/School/AskStore.swift`, `AskView.swift`
- Test: `SchoolTests/AskStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class AskStore {
    public struct ParentRow: Identifiable, Hashable, Sendable { public let id: String /* the number */; initials, name, line /* "Dev's father", "Dev and Riya's parent" */, phone: PhoneNumber, studentIDs: [UUID], sent: Bool }
    public var message: String                     // ForwardAskMessage.text, editable, 600
    public private(set) var rows: [ParentRow]      // one per number, by the first student's name
    public var countLine: String                   // "2 of 7 sent"
    public var notice: String?                     // the alert's words
    public func load() async
    public func send(_ row: ParentRow) async       // logs forward_ask per student, then opens WhatsApp
    public init(workspace:, register: any Register, messages: any MessageLogRepository, open: @escaping (URL) -> Void, now:, online:)
}
```

- [ ] **Step 1: Write the failing tests** (`AskStoreTests`): `oneRowPerParentNumberWithTheirStudentsNamed` (two students
  with one number make one row "Dev and Riya's parent"; a student without a number makes no row), `sendLogsEachStudentAndOpensWhatsAppWithTheMessage`
  (the fake log has two `forwardAsk` rows; the URL's text is the message; the row reads sent; "3 of 7 sent"),
  `aParentAskedBeforeReadsSentOnLoad`, `sendOfflineIsRefusedInWords` (`OfflineRefusal.words(for: .forwardAsk)`, no log, WhatsApp not
  opened), `theMessageIsHeldTo600Scalars`.
- [ ] **Step 2: Run them to see them fail; implement** the pushed screen (P10-School-Ask): `BackRow` "Ask parents to
  forward"; the footnote "One message, sent once to each parent on WhatsApp. Edit it first if you like; what they forward
  lands on this tab."; the Message `NotesWell` (600) with the signature lines under it; the Parents `SectionHeader` with
  `countLine`; a `Card` of `ParentSendRow`s. The route `.schoolAsk` from the "+" menu and the empty card's primary.
- [ ] **Step 3: Run the tests; `bun check --only=format,lint,ios`; commit**

```bash
git add ios/TutorCentralKit/Sources/Features/School ios/TutorCentralKit/Sources/AppShell ios/TutorCentralKit/Tests/SchoolTests
git commit -m "School: Ask parents to forward, one message, one chat at a time, logged once per parent"
```

### Task 16: School and Today: Test tomorrow in two languages; To parents after the close; the cadence (PR 6)

**Files:**
- Create: `Sources/Features/School/TestTomorrowStore.swift`, `TestTomorrowSheet.swift`; `Sources/Features/Today/TodayStore+Parents.swift`
- Modify: `Sources/Features/Today/TodayStore.swift` (the items and the log read with the counts), `TodaySections.swift`
  (To parents), `TodayView.swift`; `Sources/AppShell/ShellState.swift` (`testTomorrow: TestTomorrowAsk?` presented by
  AppShell over any tab), `RootView+Today.swift`, `RootView+School.swift`
- Test: `SchoolTests/TestTomorrowStoreTests.swift`, `TodayTests/ToParentsTests.swift`

**Interfaces:**

```swift
public struct TestTomorrowAsk: Hashable, Sendable { public let item: SchoolItem; public let student: Student }
@MainActor @Observable public final class TestTomorrowStore {
    public enum Stage: Hashable, Sendable { case making, ready, failed(String) }
    public private(set) var stage: Stage
    public var message: String                 // the parent's language (editable, Edit in the header)
    public private(set) var english: String?   // nil for an English parent
    public var languageTitle: String           // "Message · Hindi"
    public var parentLine: String              // "Ramesh Kumar · +91 98848 43831 · Hindi"
    public var note: String                    // "Opens WhatsApp with the Hindi message ready to send. We note it on Dev's page. The text is copied too, in case WhatsApp can't open."
    public var consentLine: String?            // "<parent>'s language needs consent; this is in English." when the parent's language is not English and consent is missing
    public func make() async                   // the template, or /ai/make test_tomorrow
    public func open() async                   // logs test_tomorrow (the language, the body), copies, opens WhatsApp
    public init(ask: TestTomorrowAsk, workspace:, ai:, messages:, textbooks:, open:, now:, calendar:, online:)
}
// TodayStore gains, after a close today: toParents: [ParentRowModel] (kind title, parent, language, detail, state send | sent)
// built by TodayStore+Parents from the day's closed sessions, the items (SchoolItemsRepository), the register and the log; the cadence applied to Test tomorrow rows.
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct TestTomorrowStoreTests {
    @Test func anEnglishParentGetsTheTemplateWithNoCallAndNoSecondBlock() async {
        let ai = FakeAIRepository()
        let store = makeStore(parentLanguage: .english, consent: nil, ai: ai)
        await store.make()
        #expect(store.stage == .ready && store.english == nil && ai.messageCalls.isEmpty)
        #expect(store.message.hasPrefix("Hello Ramesh, Dev's science unit test is tomorrow (Thursday 8 October), from chapters 1 and 2."))
    }

    @Test func aHindiParentWithConsentGetsTheMadeMessageWithTheEnglishBeside() async {
        let ai = FakeAIRepository()
        let store = makeStore(parentLanguage: .hindi, consent: .agreed, ai: ai)
        await store.make()
        #expect(store.english?.contains("Dev's science unit test is tomorrow") == true && store.languageTitle == "Message · Hindi")
        #expect(ai.messageCalls.first?.language == .hindi && ai.messageCalls.first?.revise == "balancing equations")
    }

    @Test func aHindiParentWithoutConsentGetsTheEnglishTemplateAndTheReason() async {
        let ai = FakeAIRepository()
        let store = makeStore(parentLanguage: .hindi, consent: nil, ai: ai)
        await store.make()
        #expect(ai.messageCalls.isEmpty && store.english == nil && store.consentLine == "Ramesh's language needs consent; this is in English.")
    }

    @Test func openLogsTheLanguageAndTheBodyCopiesAndOpensWhatsApp() async {
        let log = FakeMessageLogRepository()
        var opened: URL?
        let store = makeStore(parentLanguage: .english, consent: nil, messages: log) { opened = $0 }
        await store.make()
        await store.open()
        #expect(log.testTomorrowLogs.first.map { ($0.language, $0.body) } == (.english, store.message) && opened?.host() == "wa.me")
    }

    @Test func aFailedCallKeepsTheSheetWithTryAgainInWords() async {
        let store = makeStore(parentLanguage: .hindi, consent: .agreed, ai: FakeAIRepository(messageFailure: .service))
        await store.make()
        #expect(store.stage == .failed("The AI service didn't answer. Try again."))
    }
}

@MainActor struct ToParentsTests {
    @Test func testTomorrowIsSuggestedTheEveningBefore() async {
        // Wed 7 Oct 18:40, the Evening batch closed; Dev's exam is Thu 8 Oct.
        let store = makeTodayStore(items: [SchoolFixtures.devExamTomorrow], closed: true)
        await store.load()
        #expect(store.toParents.map(\.title) == ["Test tomorrow"] && store.toParents[0].detail == "Dev's father · Hindi · Science unit test on Thu 8 Oct, chapters 1 and 2")
    }

    @Test func anAbsentStudentWithANumberMakesAnAbsentTodayRow() async {
        let store = makeTodayStore(items: [], closed: true, absent: [FakeStudentsRepository.nikhil])
        await store.load()
        #expect(store.toParents.map(\.title) == ["Absent today"])
    }

    @Test func noRowsBeforeTheCloseAndNoneForAnExamInTwoDays() async {
        let open = makeTodayStore(items: [SchoolFixtures.devExamTomorrow], closed: false)
        await open.load()
        #expect(open.toParents.isEmpty)
        let later = makeTodayStore(items: [SchoolFixtures.exam16], closed: true)
        await later.load()
        #expect(later.toParents.isEmpty)
    }

    @Test func theCadenceHoldsAFourthSuggestionAndNeverAHandSend() async {
        let log = FakeMessageLogRepository(entriesThisWeek: [.note, .canDo, .testTomorrow], for: FakeStudentsRepository.dev)
        let store = makeTodayStore(items: [SchoolFixtures.devExamTomorrow], closed: true, messages: log)
        await store.load()
        #expect(store.toParents.isEmpty)
        let hand = FakeMessageLogRepository(entriesThisWeek: [.reminder, .receipt, .absence, .consent], for: FakeStudentsRepository.dev)
        let open = makeTodayStore(items: [SchoolFixtures.devExamTomorrow], closed: true, messages: hand)
        await open.load()
        #expect(open.toParents.count == 1)
    }

    @Test func aSentRowReadsSent() async {
        let log = FakeMessageLogRepository(entriesToday: [.testTomorrow], for: FakeStudentsRepository.dev)
        let store = makeTodayStore(items: [SchoolFixtures.devExamTomorrow], closed: true, messages: log)
        await store.load()
        #expect(store.toParents[0].state == .sent)
    }
}
```

- [ ] **Step 2: Run them to see them fail; implement.** The sheet is `TwoLanguageMessageSheet` in a `FittedSheet`
  (P10-TestTomorrow): Cancel, "Test tomorrow", Edit; the avatar and "Dev's test is tomorrow"; the parent line; the
  message well with the language's title and the signature; "In English, for you" on `surface2` when there is a second
  block; the note; Open WhatsApp. To parents on Today (P10-Today-AfterClose): a `SectionHeader` "To parents", a `Card` of
  rows (the kind as `rowTitle`, the detail `footnote`, Send as the primary 36 on the first row and secondary on the
  rest; Sent in `ok`); Send on a Test tomorrow row sets `shell.testTomorrow`; on an Absent today row it opens V1's
  absence alert sheet for that student. The exam page's Preparation (Task 18) also offers Test tomorrow from the day
  before. The revision skill for the message is `ExamPreparation.weakest` over the student's skills in the portions.

- [ ] **Step 3: Run the tests; `bun check`; the pictures** (`school-ask`, `school-test-tomorrow`, `today-after-close`);
  `bun pr-shots`; commit; open PR 6; merge when green.

```bash
git add ios/TutorCentralKit
git commit -m "Test tomorrow in the parent's language with the English beside; To parents after the close; the cadence"
```

### Task 17: Today: the plan in exam mode; holidays; a plan remade when an item changes; the first-checks hook (PR 7)

**Files:**
- Create: `Sources/Features/Today/PlanMaker+Exam.swift`
- Modify: `Sources/Features/Today/PlanMaker.swift` (reads the items; `revisions` and `holidays` into `PlanInput`; the mock
  made once; `mocksMade`; `gapSkills`), `PlanMaker+Calls.swift` (`.mock`, the checks matched by name first),
  `PlanStore.swift` (`.holiday`; `remake(for students:)`), `TodayStore.swift` (the hero on a holiday), `Sources/AppShell/ShellState.swift`
  (`schoolItemsChanged` → the day's plan stores), `RefreshHandler.swift` (the maker takes the items)
- Test: `TodayTests/PlanMakerExamTests.swift`, `PlanStoreTests.swift` (holiday, remake)

**Interfaces:**

```swift
// PlanMaker.init gains `schoolItems: any SchoolItemsRepository`, `register` for the schools' students, and reads the centre's items
// with the record (one read, the items filtered to the batch's members). PlanMaker+Exam:
extension PlanMaker {
    /// Each member's revision line for the day (the nearest exam within the window, its PreparationDay for `date`), and
    /// the members on holiday.
    func exams(for batch: PlanBatch, record: Record, items: [SchoolItem], gapReports: [UUID: GapReportContent]) -> (revisions: [UUID: RevisionLine], holidays: Set<UUID>)
    /// The mock request's artefact: an existing mock for the item is linked, a new one made and kept with the item.
    func mock(_ request: ArtefactRequest, work: PlanWork) async -> (NewArtefact, LinePlace)?
}
// PlanStore gains State.holiday (no card; Today draws the batch hero alone) and
public func remake(for students: Set<UUID>) async   // today's plan made again when not closed and a member is among `students`
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct PlanMakerExamTests {
    @Test func anExamInTheWindowTurnsItsStudentsLinesToRevision() async {
        let maker = makeMaker(items: [SchoolFixtures.exam16])
        let draft = try! await maker.draft(eveningBatch, choices: nil)
        #expect(draft.groups[0].examItemID == SchoolFixtures.exam16.id)
        #expect(draft.lines.first { $0.studentID == FakeStudentsRepository.dev && $0.kind == .teach }?.words.hasPrefix("Revise: ") == true)
    }

    @Test func anExamOutsideTheWindowChangesNothing() async {
        let maker = makeMaker(items: [SchoolFixtures.examIn20Days])
        let draft = try! await maker.draft(eveningBatch, choices: nil)
        #expect(draft.groups.allSatisfy { $0.examItemID == nil })
    }

    @Test func theMockIsMadeOnceForTheExamAndLinkedAgainTheNextTime() async {
        let ai = FakeAIRepository(); let plans = FakePlansRepository()
        let maker = makeMaker(items: [SchoolFixtures.exam16], ai: ai, plans: plans, clock: FakeClock.oct14at1635)
        await maker.make(eveningBatch(on: .oct14), choices: nil) { _ in }
        #expect(ai.mockCalls.count == 1 && plans.artefacts.filter { $0.kind == .mock }.count == 1)
        await maker.make(eveningBatch(on: .oct14), choices: nil) { _ in }   // Make the plan again
        #expect(ai.mockCalls.count == 1)   // the existing mock is linked, not made again
        #expect(plans.plans.first!.artefact(group: 1, kind: .mock) != nil)
    }

    @Test func aStudentOnHolidayIsLeftOutAndAWholeBatchOnHolidayMakesNoPlan() async {
        let holiday = SchoolFixtures.holiday(for: .school(FakeSchoolsRepository.vidya.id), on: .oct7)
        let maker = makeMaker(items: [holiday])
        let draft = try! await maker.draft(eveningBatch, choices: nil)
        #expect(Set(draft.leftOut) == [FakeStudentsRepository.dev, FakeStudentsRepository.meher, FakeStudentsRepository.nikhil])
        let all = makeMaker(items: [SchoolFixtures.holiday(for: .school(FakeSchoolsRepository.vidya.id), on: .oct7), SchoolFixtures.holiday(for: .student(FakeStudentsRepository.riya), on: .oct7), SchoolFixtures.holiday(for: .student(FakeStudentsRepository.sahil), on: .oct7)])
        #expect(await all.wholeBatchOnHoliday(eveningBatch))
    }

    @Test func aUsedGapReportGivesTheDayAfterTheMockItsLines() async {
        let plans = FakePlansRepository(artefacts: [SchoolFixtures.devGapReportUsed])
        let maker = makeMaker(items: [SchoolFixtures.exam16], plans: plans, clock: FakeClock.oct15at1635)
        let draft = try! await maker.draft(eveningBatch(on: .oct15), choices: nil)
        #expect(draft.lines.first { $0.studentID == FakeStudentsRepository.dev && $0.kind == .teach }?.words == "Balancing equations: the worked example, then a set of 6")
    }

    @Test func aChecksSkillIsMatchedByNameBeforeTheAnswersOrder() {
        let questions = [CheckQuestion(skill: "B", question: "q", answer: "a"), CheckQuestion(skill: "A", question: "q", answer: "a")]
        let content = PlanMaker.checks(questions, skills: [("A", idA), ("B", idB)], placement: false)
        if case let .check(checks) = content { #expect(checks.questions.map(\.skillID) == [idB, idA]) }
    }
}

// PlanStoreTests gains:
@Test func aHolidayOnAClosedDayChangesNothing() async { … the plan closed (sessionID set); remake(for:) does nothing; no make call }
@Test func aHolidayTodayRemakesAnOpenPlanWithoutThem() async { … a plan made; the holiday item added; remake(for: [dev, meher, nikhil]); the new plan's leftOut has the three }
@Test func aBatchWhollyOnHolidayHasNoPlan() async { … state == .holiday, no make call }
@Test func anExamAddedTodayRemakesTheOpenPlanWithRevisionLines() async { … }
```

- [ ] **Step 2: Run them to see them fail; implement.** `PlanMaker.read` also reads the items (`schoolItems.items`) and the
  used gap reports for the batch's exams (`plans.artefacts(for:)` per exam item within the window, kind `gapReport` with
  `usedAt`); `input(_:_:_:)` passes `schoolItems: SchoolItemRules.hints(…)`, `revisions`, `holidays`; the mock request's
  artefact comes from `plans.mock(for:)` when one exists (linked with `plans.link`), else `ai.makeMock` kept with
  `ArtefactLink(plan:, group:, student: nil, itemKind: .practise, schoolItem: item)`; `mocksMade` is the set of items with
  a mock. `PlanStore.load` sets `.holiday` when `maker.wholeBatchOnHoliday`; `remake(for:)` runs the "Make the plan again"
  path when the plan is not closed and a member is in the set. `ShellState.schoolItemsChanged` calls `remake` on each of
  today's plan stores. `RefreshHandler` passes the items repository to the maker.

- [ ] **Step 3: Run the tests (all `TodayTests`); commit**

```bash
git add ios/TutorCentralKit/Sources/Features/Today ios/TutorCentralKit/Sources/AppShell ios/TutorCentralKit/Tests/TodayTests
git commit -m "Today: the plan in exam mode (exam groups, revision lines, the mock made once), holidays, a plan remade when an item changes"
```

### Task 18: School: the exam's page with Preparation (PR 7)

**Files:**
- Create: `Sources/Features/School/PreparationSection.swift`
- Modify: `Sources/Features/School/ItemStore.swift` (`preparation: [PreparationRowModel]`, `testTomorrowOffered`), `ItemView.swift`,
  `Sources/AppShell/Fixtures+School.swift`, `LaunchState.swift` (`school-item`, `school-item-edit`, `school-item-delete`, `today-revision`)
- Test: `SchoolTests/PreparationTests.swift`

**Interfaces:**

```swift
public struct PreparationRowModel: Identifiable, Hashable, Sendable {
    public let id: Day; public let day: String; public let date: String; public let title: String
    public let line: String        // "A set of 6 each · done in today's class", "The worked example · a set of 8", "In the school's pattern · 25 marks · mark it from a photo", "The last set from the gap report"
    public let mark: PreparationRow.Mark
    public let opens: UUID?        // the day's plan (Today) when it is today's, the mock when made
}
// ItemStore gains: preparation (built by ExamPreparation.days for the exam's first student in the batch, the lines from the
// day's plan when one exists: its artefacts' count lines; a day whose session closed is .done; today is .today; the mock
// day .mock), changeOpensToday: UUID? (the batch), testTomorrowOffered: Bool (today is the day before the exam).
```

- [ ] **Step 1: Write the failing tests** (`PreparationTests`): `nineDaysOutShowsOneRowPerBatchDayToTheTest` (the eight rows
  of Task 5's split in the board's shape: "Wed 7 Oct · Chemical reactions · part 1 of 3"; today's row `.today`; "Wed 14
  Oct · The mock · In the school's pattern · 25 marks · mark it from a photo" `.mock`; "Fri 16 Oct · The test"),
  `aDayWhosePlanClosedIsDoneWithWhatWasMade` ("A set of 6 · done in Wednesday's class"), `theDayBeforeOffersTestTomorrow`,
  `aHomeworkHasNoPreparation`, `anExamOutsideTheWindowShowsNoPreparationButTheDaysToGo`.
- [ ] **Step 2: Run them to see them fail; implement** the Preparation `SectionHeader` with the quiet Change (opens Today at
  the batch's plan, `actions.openToday(batch)`, U35's path) and a `Card` of `PreparationRow`s; the last row from the day
  before: "Test tomorrow goes to parents on <weekday> evening" with the quiet Test tomorrow (`shell.testTomorrow`); the
  `today-revision` fixture: the Evening batch's plan with Group 1 as the exam group ("Group 1 · Science unit test 3 · Class
  8 · 3 students", the three with "Revise: Chemical reactions · part 1 of 3", "Revision set 1 · Check 3 · Revision sheet
  1"), Groups 2 and 3 as `today`'s.
- [ ] **Step 3: Run the tests; `bun check`; the pictures** (`school-item`, `school-item-edit`, `school-item-delete`,
  `today-revision` both), compared with P10-School-Item, -Edit, -Delete and P13-Today-Revision; `bun pr-shots`; commit;
  open PR 7; merge when green.

```bash
git add ios/TutorCentralKit
git commit -m "School: the exam's page with Who and Preparation, Change to Today, Test tomorrow from the day before; the plan's exam group on Today"
```

### Task 19: Artefacts: the mock (PR 8)

**Files:**
- Create: `Sources/Features/Artefacts/MockStore.swift`, `MockView.swift`
- Modify: `Sources/Features/Artefacts/ArtefactScreen.swift` (kind `.mock`), `ArtefactRead.swift`, `ArtefactWords.swift`,
  `Sources/AppShell/RootView+Artefacts.swift` (Mark from a photo → the Check a paper preset), `Fixtures+School.swift`
- Test: `ArtefactsTests/MockStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class MockStore {
    public enum Form: Hashable, Sendable { case paper, key }
    public var form: Form
    public private(set) var mock: MockContent?; public private(set) var artefact: Artefact?
    public var hero: (eyebrow: String, title: String, line: String)   // "Science unit test 3 · Fri 16 Oct", "Mock in the school's pattern", "25 marks · 40 minutes · chapters 1 and 2 · made today, 16:40"
    public var patternLine: String                                     // "as Vidya Niketan sets them" when the exam's school is known, else "in the pattern for class 8"
    public private(set) var students: [Student]                        // the exam's students, for Mark from a photo
    public func load() async; public func again() async -> Bool; public func pdf(withKey: Bool) -> URL?
    public var onMark: ((Student, SchemeSource) -> Void)?
}
```

- [ ] **Step 1: Write the failing tests** (`MockStoreTests`): `theMockOpensFromThePlanAndOffline` (from `PlanCache.artefact`
  when the read fails), `theHeroAndPatternLineReadFromTheMockAndItsExam`, `againMakesANewMockAndRelinksTheExam` (the old
  stays with `regeneratedFrom`; the plan's practise lines point at the new one; `mock(for:)` answers the new),
  `thePDFLeavesTheKeyOutUnlessAsked`, `markOffersEachOfTheExamsStudentsWithTheMocksScheme`.
- [ ] **Step 2: Run them to see them fail; implement** (P10-Mock): `BackRow` "Mock test" with the quiet Key toggling the
  form; the hero card; "Paper" with the pattern line, the sections (V1's paper rows: the section head "Section A · 1 mark
  each", each question with its marks tile) or the key rows; the footnote "AI can make mistakes. Check every question
  before you give it. Marking from a photo uses this paper's key."; the result footer: quiet Make it again, Share as PDF
  (secondary), Mark from a photo (primary; a student picker sheet when the exam has several students). `again` makes the
  mock once more and keeps it with the item (`regeneratedFrom`), relinking today's plan lines; offline it is refused in
  words (`OfflineRefusal.regenerate`).
- [ ] **Step 3: Run the tests; commit**

```bash
git add ios/TutorCentralKit/Sources/Features/Artefacts ios/TutorCentralKit/Sources/AppShell ios/TutorCentralKit/Tests/ArtefactsTests
git commit -m "Artefacts: the mock in the school's pattern, its key, Make it again, Share as PDF, Mark from a photo"
```

### Task 20: AITools: marking a mock from a photo; marks written (PR 8)

**Files:**
- Modify: `Sources/Features/AITools/CheckStore.swift` (`CheckPreset`), `CheckStore+Marks.swift` (the marks row; Undo),
  `CheckIntroView.swift`, `CheckPagesView.swift` (Check goes to checking with a preset), `Sources/AppShell/RootView+AITools.swift`
  (`ShellState.checkPresets[id]`), `Sources/Data/AI/APIClient.swift` (the student sent)
- Test: `AIToolsTests/CheckPresetTests.swift`

**Interfaces:**

```swift
public struct CheckPreset: Hashable, Sendable { public let studentID: UUID; public let scheme: SchemeSource; public let mark: MarkTarget }
public struct MarkTarget: Hashable, Sendable { public let subject: String; public let test: String; public let schoolItemID: UUID?; public let artefactID: UUID?; public let skills: [Int: String] /* by question number */ }
// CheckStore.init gains preset: CheckPreset? ; with one: studentID set, scheme set, the scheme step skipped (pages → check),
// Save writes NewMark (score = result.total, max = result.outOf, questions = result.questions with the skills) through RecordRepository
// and V1's notes line; Undo deletes the mark and puts the notes back. For a scheme .paper(generationID) with the paper's subject
// known (its Generation's context), Save also writes a mark (test: the paper's title). For a typed scheme, none.
```

- [ ] **Step 1: Write the failing tests** (`CheckPresetTests`): `aPresetSkipsTheSchemeAndSendsTheStudent`
  (`ai.checkCalls.first?.studentID == dev`, the scheme `.mock`), `saveWritesTheMarkWithItsQuestionsAndTheNotesLine`
  (`record.marks` has one row: 14 of 25, the questions' skills, the exam and the mock; the notes line as before),
  `undoRemovesTheMarkAndTheNotesLine`, `aPaperSchemeWritesAMarkWithThePapersSubjectAndATypedSchemeDoesNot`,
  `aStudentWithoutConsentIsRefusedInWordsBeforeAnyCall` ("Marking Dev's paper waits for Ramesh's consent."; the
  consent line's words as the student's page has them), `offlineMarkingIsRefusedAndKeepsThePages`.
- [ ] **Step 2: Run them to see them fail; implement; run the whole `AIToolsTests` (V1's paths unchanged); commit**

```bash
git add ios/TutorCentralKit/Sources/Features/AITools ios/TutorCentralKit/Sources/AppShell ios/TutorCentralKit/Sources/Data/AI ios/TutorCentralKit/Tests/AIToolsTests
git commit -m "Check a paper: a mock's preset (the student, the key), the scheme step skipped, Save writes the mark; a paper's check writes one too"
```

### Task 21: Artefacts and School: the gap report; the last days (PR 8)

**Files:**
- Create: `Sources/Features/Artefacts/GapReportStore.swift`, `GapReportView.swift`, `Sources/Features/School/LastDaysSections.swift`
- Modify: `Sources/Features/School/ItemStore.swift` (`lastDays: LastDaysModel?`), `ItemView.swift`, `Sources/Features/Artefacts/ArtefactScreen.swift`
  (kind `.gapReport`), `Sources/AppShell/RootView+Artefacts.swift`, `Fixtures+School.swift`, `LaunchState.swift` (`mock`,
  `gap-report`, `school-last-days`)
- Test: `ArtefactsTests/GapReportStoreTests.swift`, `SchoolTests/LastDaysTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class GapReportStore {
    public enum Stage: Hashable, Sendable { case making, ready, failed(String) }
    public private(set) var stage: Stage
    public private(set) var report: GapReportContent?
    public var hero: (eyebrow: String, score: Int, of: Int, line: String)   // "Dev Kumar · Science mock · marked Wed 14 Oct", 14, 25, "The test is on Friday. Two days left."
    public var days: [(day: String, date: String, title: String, line: String)]
    public var used: Bool
    public func load() async      // an existing report, else made from the mark's questions and the mock, kept
    public func use() async -> Bool   // usedAt set; today's plan remade when it is one of the days and not closed
    public init(student: Student, mark: MarkRecord, mock: Artefact, exam: SchoolItem, …)
}
public struct LastDaysModel: Hashable, Sendable {
    public let todayTitle: String                  // "Today, Wednesday"
    public let mock: (title: String, line: String, state: MockState)   // "The mock, for Dev, Meher and Nikhil", "In the school's pattern · 25 marks · 40 minutes", .ready | .making | .none
    public let marked: [MarkedRow]                 // name, "14 of 25 · Balancing equations 3 of 10" | "Not marked yet", gapReport: UUID?, canMark: Bool, consentLine: String?
    public let lastDays: [(day: String, date: String, title: String, line: String)]
}
```

- [ ] **Step 1: Write the failing tests.** `GapReportStoreTests`: `theReportIsMadeOnceFromTheMarkingAndKept` (one
  `gapCalls`; the tallies in the mock's order; a second `load` makes none), `theHeroCountsTheDaysLeft`,
  `useSetsUsedAtAndTellsThePlan`, `withoutConsentNothingIsMade`, `offlineTheKeptReportOpensAndANewOneIsRefused`.
  `LastDaysTests`: `twoDaysBeforeThePageLeadsWithTheMockAndTheMarkedRows` (Wed 14 Oct: the mock ready; Dev 14 of 25 with
  the weakest skill; Meher 21 of 25 "all skills secure"; Nikhil not marked), `aStudentWithoutConsentCannotBeMarkedOrReported`
  (`canMark == false`, the consent line), `theLastTwoDaysReadTheUsedReportsLinesPerStudent` ("Dev: balancing equations, the
  worked example and a set · Meher: a short revision set"), `beforeTheMockIsMadeTheRowSaysSo` ("The mock is made with
  Wednesday's plan" when the mock day's plan is not yet made; the Phase 12 planning card's path).
- [ ] **Step 2: Run them to see them fail; implement** (P10-GapReport: `ScoreHero`, By skill `SkillBarRow`s, The last two
  days with the quiet Change opening Today, Use this plan primary with the footnote "Replaces the two days' lines in the
  plan. Leave it and the plan carries on as it was."; P10-School-Exam-LastDays: the Today card with the mock row and Mark
  from a photo (primary) with its line, Marked rows, The last two days).
- [ ] **Step 3: Run the tests; `bun check`; the pictures** (`mock`, `gap-report`, `school-last-days`), compared with the
  boards; `bun pr-shots`; commit; open PR 8; merge when green.

```bash
git add ios/TutorCentralKit
git commit -m "The gap report after a marked mock, Use this plan; the exam's last days"
```

### Task 22: Students: the Marks section (U36) (PR 9)

**Files:**
- Modify: `Sources/Features/Students/RecordSections.swift` (`MarksSection`), `StudentDetailStore+Record.swift` (`marks`,
  `markRows`), `StudentDetailView.swift` (after Checks, before Homework, as P10-Student-Record orders it),
  `Sources/AppShell/Fixtures+School.swift`, `LaunchState.swift` (`student-marks`)
- Test: `StudentsTests/MarksSectionTests.swift`

- [ ] **Step 1: Write the failing tests** (`MarksSectionTests`): `theMarksListNewestFirstWithTheSchoolAndTheScore`
  (Hemanth's two: "Unit test 2 · Mathematics", "Vidya Niketan · 28 Sep", "14 of 25"; then unit test 1), `aMarkBelowUsualWearsTheChip`
  (unit test 2 with two earlier at 19 and 18 of 25: `due` "Below usual"; unit test 1 none), `aStudentWithNoMarksSeesTheEmptyRow`
  ("No marks yet" · "Marks from mocks and checked papers appear here."), `aMockMarkNamesTheMock` ("Science unit test 3 ·
  mock · Science"), `noAddFromAPhotoYet` (the section's header has no action).
- [ ] **Step 2: Run them to see them fail; implement** `MarksSection` (a `SectionHeader` "Marks" with no action; a `Card` of
  rows: the test `rowTitle`, the school and date `footnote`, the score `numberRow`, the compact `Chip(.status(.due, "Below
  usual", symbol: "clock"))` when `MarkRules.belowUsual`; or the Kit's `EmptyRow`), the store's read of `record.marks`
  with the record's other reads, the `student-marks` fixtures (Hemanth's two marks; Riya with none for the empty row's
  light twin).
- [ ] **Step 3: Run the tests; `bun check`; the pictures** (`student-marks` both), compared with P13-Student-Marks and
  P10-Student-Record; `bun pr-shots`; commit; open PR 9; merge when green; move U36 to Done on `plan/ui-polish.md`
  (Task 28).

```bash
git add ios/TutorCentralKit
git commit -m "Students: the Marks section (U36): mocks and checked papers, below usual, the empty row"
```

### Task 23: Today: a new batch's first checks (the owner, 2026-10-11) (PR 10)

**Files:**
- Modify: `Sources/Features/Today/PlanMaker.swift` (`named` writes each member's chapter and skill when the group's members
  have no skill in the subject), `Sources/Domain/Plan/PlanTypes.swift` (`PlanDraft.naming` sets the group's `skillID`
  per member: the lines take their own new skill ids)
- Test: `TodayTests/FirstChecksTests.swift`

- [ ] **Step 1: Write the failing tests** (`FirstChecksTests`): `aGroupNamedByThePlanWritesEachMembersChapterAndSkill`
  (two new students, no book; `/ai/plan` names "Chemical reactions" and "Balance a chemical equation"; after `make`, the
  fake textbooks repository has one chapter and one skill per member, source none, position after the subject's last;
  the teach lines carry each member's own skill id), `theFirstCloseThenHasChecksOnTheirOwnSkills` (the close store from
  that plan offers three check rows per member, written on their own skill ids), `aMemberWhoAlreadyHasTheChapterGetsNoSecond`
  (a member with a chapter of that name in the subject keeps it; the skill is added to it when missing),
  `aFailedWriteLeavesTheGroupNamedWithNoOwnSkill` (the plan stands as Phase 12 made it: checks by name).
- [ ] **Step 2: Run them to see them fail; implement** with `TextbooksRepository.addNamedChapter` (Task 9); the chapter's
  position after the subject's last (the Phase 10 recapture rule moves own chapters behind a book captured later).
- [ ] **Step 3: Run the tests; commit**

```bash
git add ios/TutorCentralKit
git commit -m "Today: a group /ai/plan names writes each member's chapter and skill, so a new batch's first close has checks"
```

### Task 24: Today: an unnamed group named at the next open (the owner, 2026-10-11) (PR 10)

**Files:**
- Modify: `Sources/Features/Today/PlanMaker.swift` (`complete` names groups whose `skill` is empty through `/ai/plan` and
  `plans.nameGroup`, then makes their material), `Sources/Features/Today/PlanStore.swift`
- Test: `TodayTests/PlanStoreTests.swift`, `PlanMakerTests.swift`

- [ ] **Step 1: Write the failing tests**: `PlanMakerTests.completeNamesAnUnnamedGroupAndMakesItsMaterial` (a plan whose
  Group 2 has `skill == ""`, `/ai/plan` answering now: `nameGroup` called with the chapter and skill; the group's teach
  lines read "Teach: <skill>"; the set, sheet and checks made and linked; the other groups' artefacts untouched),
  `completeLeavesANamedGroupAlone`, `aSecondFailureLeavesTheGroupUnnamedWithoutAWrite`, and
  `PlanStoreTests.reopeningNamesTheGroupTheMakeCouldNot` (the store's `load` on a plan with an unnamed group runs
  `complete`, and the card's head reads the chapter).
- [ ] **Step 2: Run them to see them fail; implement; run the whole `TodayTests`; `bun check`; commit; open PR 10
  (no picture: what is seen is Phase 12's card with a name); merge when green**

```bash
git add ios/TutorCentralKit
git commit -m "Today: a group the make could not name is named on the next open and its material made"
```

### Task 25: The runbook's share path and the device tests (main, documents)

- [ ] **Step 1:** `docs/runbooks/simulator.md` gains section 11, "Share to Tutor Central": the extension in the simulator
  is driven from Photos (a picture added with `xcrun simctl addmedia booted <file.png>`; Photos → the picture → Share →
  Tutor Central in the sheet, the row found with a settled screenshot) and from a text (`printf 'Dear Parents…' | xcrun
  simctl pbcopy booted`, then Notes → a new note → Paste → select all → Share → Tutor Central), each followed by `xcrun
  simctl launch booted in.tutorcentral.app` (the extension writes and closes; the app reads the inbox on the next
  foreground), the wait of 2 s before looking, and the proof in the app group's folder: `find ~/Library/Developer/
  CoreSimulator/Devices/<udid>/data/Containers/Shared/AppGroup -path '*group.in.tutorcentral/inbox/*' -mmin -5`. Measured
  waits are written down as section 5's were. The section also names the confirm screen's taps (the checkbox at the
  card's left edge, Add at the footer) and the query that proves an item: `select title, kind, date, class_level,
  student_id, source, confirmed_at from school_items order by created_at desc limit 5`.
- [ ] **Step 2:** `docs/testing/device-tests.md` gains a Phase 13 section for the tester: T8 share a real school WhatsApp
  message to Tutor Central from WhatsApp itself (the app opens on "Check what was read" with the items), T9 share a
  photo of a printed timetable from Photos (two or more exams read with their dates), T10 Test tomorrow in Hindi or
  Kannada opens WhatsApp with the message in that script, T11 Mark from a photo on a real mock paper photographed with the
  camera (the marks come back; Save shows the mark on the student's page and the exam's Marked row), T12 the share
  extension used while signed out (the item waits; after sign-in the School tab opens on it).
- [ ] **Step 3:** Commit both with the documents of Task 28 (D12), or on their own to `main` when the hand runs need them
  first.

### Task 26: The hand runs (D32), after each pull request they name (main)

By `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed (decision 28), signed in as Meera,
each write confirmed in the database, each screenshot kept in `.shots/run/` and attached to the phase's issue ("Phase 13
hand run"); the local API with `AI_FAKE=1` except the cost run. The Evening batch meets Monday to Friday 17:00 to 18:30;
a run on another hour or day moves the batch's time or the item's date by psql first and puts it back after (session
26's practice). The seed's exam is nine days out; a run that needs two days out sets `date = current_date + 2` on the
item.

| Run | After PR | Through the screens | Confirm |
|---|---|---|---|
| 1 A forwarded timetable photo | 5 | Photos (a timetable picture added) → Share → Tutor Central → the app → "Check what was read" with the photo in the well → two exam items (Science and Mathematics on the fake's dates) → open the Mathematics item → For: Class 10 at Vidya Niketan → Save → Add 2 items → the list shows both under their week | `select title, kind, subject, date, class_level, source, photo_path, confirmed_at from school_items order by created_at desc limit 2` (both rows, `source = 'shared_photo'`, one `photo_path` under `<centre>/item/`); Studio's Storage shows the object; the inbox folder is empty |
| 2 A pasted message with a holiday | 5 | The pasteboard holds the board's message → School → "+" → Paste a message → three items read → untick the homework → Add 2 items → the calendar shows the exam's dot and the holiday's three days → the holiday's page lists the batch days | the two rows; `end_date` on the holiday; `select count(*) from school_items where kind = 'homework' and title like 'Maths Ex%'` unchanged |
| 3 Edit and delete | 5 | The exam's page → Edit → the date moved a day → Save → the list's countdown changes → Delete this item → the dialog → Delete → the tab without it | the row's `date`, then gone; the photo gone from Storage when it had one |
| 4 Ask parents to forward | 6 | School → "+" → Ask parents to forward → Send on two parents (WhatsApp's page opens in Safari with the message; back) → "2 of N sent" → Back → again: the two read Sent | `select student_id, kind, opened_at from message_log where kind = 'forward_ask'` (one row per student of those parents) |
| 5 Test tomorrow | 6 | The seed's exam moved to tomorrow (`update school_items set date = current_date + 1 where id = '…661'`) → Today → Start class → Done (a close) → To parents: Test tomorrow for the class 8 students → Send on Diya (Hindi) → the sheet in Hindi with the English beside → Open WhatsApp → back: Sent; Send on Aarav (English): the template alone | `select kind, language, body from message_log where kind = 'test_tomorrow' order by opened_at desc limit 2` (Hindi body, English body) |
| 6 An exam in the window turns lines to revision | 7 | The exam back to nine days → Today → Make the plan again → Group 1 is "Science unit test 3" with "Revise: Chemical reactions …", "Revision set 1", "Check 3", "Revision sheet 1" for the four class 8 students; the revision set opens; the exam's page shows Preparation with today's row | `select groups from plans where date = <IST today>` (`exam_item_id` on Group 1); `select kind, words from plan_items where plan_id = … and student_id = <Aarav>`; `select kind, title from artefacts where plan_id = …` (the set and sheet named for the portion) |
| 7 A holiday takes students out | 7 | A holiday for Vidya Niketan today (Add by hand) → Today's plan is made again without the Vidya students; the class 2 four remain → delete the holiday → the plan returns | `plan_items` rows for a Vidya student: none while the holiday stands; `skipped_at` not used (left out) |
| 8 The mock two days before | 8 | The exam to `current_date + 2` → Today → Make the plan again → Group 1's Practise is "The mock" → the mock opens (sections, the key behind Key) → Share as PDF (the share sheet) → the exam's page leads with Today: the mock Ready | `select kind, school_item_id, plan_id, generation_id from artefacts where kind = 'mock'` (one row, the exam's id, the plan's id); `ai_generations` has one `mock` |
| 9 Marking from a photo | 8 | The mock → Mark from a photo → Diya (consent recorded first on her page) → two pages from Photos → the marks → change one → Save → the exam's page: Diya "x of 25 · <skill> n of m" → Students → Diya → Marks: the mock's row | `select score, max, test, school_item_id, artefact_id, jsonb_array_length(questions) from marks order by created_at desc limit 1`; her notes' last line; `ai_generations` has one `check_paper` with the mock's scheme and no image |
| 10 The gap report | 8 | Diya's Marked row → Gap report → the score hero, By skill, The last two days → Use this plan → the exam's page: The last two days read the report's lines → Today (the day after the mock, moved by psql) → her teach line is the report's | `select kind, student_id, school_item_id, content->>'used_at' from artefacts where kind = 'gap_report'`; `plan_items.words` for Diya's teach line |
| 11 Marks on the page | 9 | Students → Hemanth → Marks: the seed's two, unit test 2 "Below usual"; Riya → Marks: "No marks yet" | nothing written |
| 12 A new batch's first checks | 10 | Students → Add Zara (class 6, Vidya, no book) and Yash (class 6) into a new batch meeting now → Today → the plan: one group named by `/ai/plan` → Start class → each has three check rows → Done | `select name, subject, position from chapters where student_id in (…)` (one own chapter each); `select count(*) from checks where session_id = …` (6) |
| 13 An unnamed group named later | 10 | The local API stopped → Today for a new batch → the plan's group reads "Teach: with the group" → the API back → Today again → the group is named and its material lands | `select groups from plans where …` before and after; `plan_items.words` for the teach lines |
| 14 The share signed out | 5 | Sign out → Photos → Share → Tutor Central → the app opens on sign-in → sign in → the School tab opens on "Check what was read" | the inbox file present before sign-in, gone after Add or Leave |
| 15 Offline | 5, 6 | `docker stop supabase_kong_tutor_central` → School shows its copy with the status line → "+" → Paste a message: the alert (the inbox path: a share waits) → Ask parents → Send: refused in words → `docker start` | nothing written while stopped |

### Task 27: The deploy, the cost run, the review, TestFlight (main)

- [ ] **Step 1 (after PR 2):** `gh workflow run deploy`; the summary shows 0021 pending, pushed, nothing after; the API
  smoke green; the run id into `STATE.md`'s Production.
- [ ] **Step 2 (after PR 10 and the hand runs): the cost run** (decision 29; the owner's yes in chat first; about ₹8):
  `supabase db reset`; the local API **without** `AI_FAKE`; the seed's exam at `current_date + 2`; Today → the plan (the
  mock on Sonnet); Diya's consent recorded; Mark from a photo with two photographed pages of a filled mock (a sheet of the
  fake's questions answered by hand and photographed with the Mac's camera into Photos; Opus); Gap report (Sonnet). Then:

```sql
select kind, model, count(*) as calls, sum(tokens_in) as tokens_in, sum(tokens_out) as tokens_out,
       round(sum(case model when 'claude-haiku-5-5' then tokens_in * 0.10 + tokens_out * 0.50
                            when 'claude-sonnet-5-5' then tokens_in * 2 + tokens_out * 10
                            else tokens_in * 4 + tokens_out * 20 end) / 1e6 * 85, 2) as rupees
  from public.ai_generations
 where created_at > now() - interval '30 minutes' and status = 'ok' and kind in ('mock', 'check_paper', 'gap_report', 'parse_school', 'test_tomorrow')
 group by 1, 2 order by rupees desc;
```

  The record writes calls, tokens and rupees per kind, the cost of one exam's preparation for a class of three (one
  mock, three markings, three gap reports, the daily sets already in Phase 12's figure) and the monthly figure at two
  exams a month; `PriceSheet.typical` takes the measured averages for `mock`, `check_paper` (the mock's) and `gap_report`.
- [ ] **Step 3: The review:** a reviewer pass over the merged pull requests with `superpowers:requesting-code-review` on
  Fable 5.1 (fresh context), its Critical and Important findings fixed with a test that failed first, each ruling in the
  ledger, before the TestFlight build (as Phases 6, 7, 10, 11 and 12 did).
- [ ] **Step 4:** `gh workflow run testflight`; the build number from the run; the owner installs it from the internal
  group and tries the share from WhatsApp on his iPhone (T8).

### Task 28: The documents (main)

- [ ] **Documents (D12), one commit to `main` when the phase ends:** `plan/phase-13-school.md` "As built" (what items,
  the exam window, the mock, the marking, the gap report and the messages settled; the cost measured; where the build
  moved from this plan and why; what was left open); `plan/README.md` (Phase 13 done; a decision number if the owner
  rules one); `plan/STATE.md` (production: 0021, the API commit, the build); `plan/ui-polish.md` (U36 to Done with PR 9;
  new rows: a per-exam window needs a field on the item's sheet; the student page's See all opens the School tab
  unfiltered; anything seen); `docs/design/information-architecture.md` ("Phase 13 boards": the three boards and their
  states; the launch states list; `later-school` retired), `components.md` ("Phase 13 parts": the reading card's words,
  the revision line's words, the Marks empty row; "As built in Phase 13" under 10.5, 10.4, 10.2 and 10.3), `design-tokens.md`
  ("Numbers in code": the window 14 days, the mock two days before with three days or more, at most two exam groups
  when others remain, three suggested messages a week, the forward ask's 600, a mark below usual by ten points over two
  earlier marks); `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` for rules learned; `plan/sessions/028/record.md`,
  `ledger.md` and `owner-messages.md`.

---

## Self-review (done 2026-10-11)

**Spec coverage** (`phase-13-school.md`'s six scope items): 1 the share extension (text or image through the app group to
the School tab, `/ai/parse-school`, items for confirmation with kind, who, subject, date and portions, the photo kept in
Storage) → Tasks 2, 3, 8, 13, 14, 25; 2 items and the calendar (per student and per class of a school, by date, edit,
delete, a holiday removing the batch's plan for the day) → Tasks 4, 12, 13, 14, 17; 3 Ask parents to forward (sent once,
logged) → Task 15; 4 Test tomorrow (the evening before, held by the cadence) → Tasks 7, 16; 5 exam preparation (the window,
the split, a daily set, the mock two days before in the school's pattern or the board's blueprint, marking from a photo,
the gap report adjusting the last days, class 10's two dates) → Tasks 5, 6, 17, 18, 19, 20, 21, with the two dates in
Task 4's and 5's tests; 6 Marks on the student's page (U36) → Task 22 to the Phase 13 board. The acceptance's three lines
→ hand runs 1 and 6, and Task 22. Spec section 7's "Test tomorrow", "Mock" and "Gap report" rows and section 8's forward
ask and cadence → Tasks 7, 15, 16, 19, 21. The two Phase 12 items the owner ruled in → Tasks 23 and 24.

**Placeholder scan:** no "TBD", no "similar to Task N" without the code; the views are specified by their Kit parts and
the boards' texts, as this repository's plans do; the prompts' system words are given in full for the parser and in their
sentences for the other three. Two things wait on the owner and are marked (decision 31): the three boards' approval and
the cost run's spend.

**Type consistency:** `SchoolItem`, `SchoolItemDraft`, `ItemAudience`, `SchoolItemKind`, `SchoolItemSource` (Task 4) are
used by those names in Tasks 8, 12, 13, 14, 16, 17, 18; `PreparationDay`, `ExamPreparation`, `MockPattern` (Task 5) by
Tasks 6, 16, 17, 18, 19; `RevisionLine`, `PlanGroup.examItemID`, `ArtefactRequest.mock`, `PlanRules.cut` (Task 6) by Tasks
17 and 18; `MessageCadence`, `TestTomorrowMessage`, `ForwardAskMessage`, `MarkRecord`, `NewMark`, `MarkRules`, `MockContent`,
`GapReportContent`, `GapTallies`, `SchemeSource.mock` (Task 7) by Tasks 9, 15, 16, 19, 20, 21, 22; `SchoolItemsRepository`,
`SchoolCache` (Task 8) by Tasks 12, 13, 14, 16, 17; `ArtefactLink.schoolItem`, `mock(for:)`, `gapReport(for:student:)`,
`setContent`, `nameGroup`, `addNamedChapter` (Task 9) by Tasks 17, 19, 21, 23, 24; `SchoolSource`, `ParsedItem`,
`SchoolReading`, `MockRequest`, `MadeMock`, `GapRequest`, `MadeGapReport`, `TestTomorrowRequest`, `MadeMessage` (Task 10)
by Tasks 13, 16, 17, 19, 21; `KindChip`, `SchoolRow`, `ItemCard`, `FactLine`, `SourceWell`, `PreparationRow`,
`ParentSendRow`, `TwoLanguageMessageSheet`, `ScoreHero`, `SkillBarRow`, `CalendarDot` (Task 11) by Tasks 12 to 22;
`ReadSource`, `SchoolActions` (Task 12) by Tasks 13 and 14; `TestTomorrowAsk` (Task 16) by Tasks 18 and 21; `CheckPreset`,
`MarkTarget` (Task 20) by Tasks 19 and 21; the API's `ParseSchoolInput`, `MockOutput`, `GapReportOutput`,
`TestTomorrowOutput`, `Scheme` mock by `generationId` (Task 2) by Tasks 3 and 10. `SchoolFixtures` and `FakeClock.oct14at1635`,
`.oct15at1635` are the test targets' helpers, as Phase 12's were.

**Review focus:** the eight lines each name their tests; the new sentences on screen (the reading card, the missing facts,
"No one in class n there yet", the paste alert, the consent lines, the revision words, the Marks empty row, the five
offline refusals) pass `ErrorWordsTests`; the cost run is the one step that spends money and the owner is told first
(decision 29).
