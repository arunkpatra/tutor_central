# Phase 15 plan: Make and polish

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-11 (session 31, Fable 5.1), approved by the owner the same day with the two Phase 15 boards ("Boards
approved. Agree with round start."), from `phase-15-make-and-polish.md`, `docs/spec-v2.md` and the approved Phase 10
boards (step 10.7: Make, a kind's form, the For sheet, Check a paper under Make, Reports' Progress by month and by term, the
Kit's Phase 10 rows), with Phase 9's method for the tutor round (D52 to D55, moved to V2 by D66). The owner's two questions (the
"Owner's questions" below) were answered the same day. Ticked as it goes. The build runs on Opus 5.5 from `resume/030-phase-15-build.md`, inline, task
by task, with one ledger as sessions 22 to 30 kept.

**Goal:** a tutor can make any of the plan's material on their own, from More's Make something, for a student, a group,
a batch or a class level, and check it before it reaches anyone; Check a paper sits under Make and takes a mock's or a
paper's key from the Scheme tile; Reports show each student's progress for a month or a school term, with the numbers
proven against the seed and a CSV; the Kit shows the Phase 10 parts; the polish rows the owner picks are done; the
website carries the trust page before any tutor's student data reaches the AI in testing; and six tutors use V2 on their own
iPhones for three weeks by Phase 9's method, every finding logged, triaged and fixed or placed (D68).

**Architecture:** the `AITools` feature becomes `Make` (spec section 9's target table; a rename with no change in what is
seen). Make's home lists the kinds in two groups and Recent; a kind's form is the Phase 6 form screen with the For tile
(the For sheet: Student | Group | Batch | Class) where the kind is made for someone; Domain's `MakeTarget` and
`MakeRules` turn the choice into the class level and the skill names the API already takes, so the existing `/ai/make`
kinds (sheet, worked example, figure, brief, mock) are called as the plan calls them and nothing about a student is sent
(D62). The made artefact is kept with `keep_artefact` (plan null, `made_from = 'make'`, migration 0026) and opens the
Artefacts screen of its kind, with Make it again, Share as PDF, Print and Use my own as there. Note to a parent opens Phase
14's note with the tutor's own words added to the request (`tutorSays`, additive); the mock is kept with the student's exam so
Mark from a photo writes its mark. Check a paper's intro gains the Scheme tile (P10-Make-Check), which opens the Marking
scheme screen as a chooser listing the student's mocks and the centre's papers. Reports gains Progress: Domain's
`ProgressRules` sums skills made secure, checks right and absences per student over a `Period` or a `Term` (Domain, by the
school's board), sorted Lowest first, with `ProgressCSV`; Data's `ProgressReader` reads the skills, checks and sessions of
every active student together. The Kit gains `KitPhase10`; the seven figures it shows are drawn by Artefacts and handed in
by AppShell (DesignSystem does not import Domain, Phase 12's ruling). The tutor round runs on what exists (TestFlight's
"Tutors" group, Beta App Review, the findings file, Monday and Thursday readings, Thursday builds), with the guide rewritten
for V2 and the trust page on the website first.

**Tech stack:** as Phase 14 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI, Postgres, Bun tests; Hono, zod 4,
`@anthropic-ai/sdk`; Next.js 16 static export for the trust page; XcodeGen). No new dependency.

**Spec:** `docs/spec-v2.md` sections 2 (each feature works on its own), 4 (More's Make), 7 (the kinds), 8 (consent is scoped:
material from a skill at a level needs none), 9 (`Features/Make`; the models by kind; the trust page in the phase that first
sends a student's data to testers); scope `plan/phase-15-make-and-polish.md` (items 1 to 5); the boards and what they settle
in `docs/design/information-architecture.md` ("Phase 10 boards", 10.7; 10.4's artefacts; the "As built" notes of Phases 12 to
14); the parts and texts in `components.md` ("Phase 10 parts", 10.7); the numbers in `design-tokens.md` ("Numbers in code",
10.7); decisions D52 to D68; the tutor round's method in `plan/phase-09-plan.md` and `docs/testing/tester-guide.md` (V1's,
rewritten here); what Phases 12 to 14 built in their "As built" and `plan/sessions/026`, `028`, `030` ledgers.

## Global constraints

- No board, no approval, no code for anything seen (rule 1). Each state a board draws gets a `LaunchState` and its
  pictures in the pull request, both appearances where the board has both (D7). What no board redraws stays as Phases 11
  to 14 built it. The two new boards this phase needs
  (the website's trust page, decision 24; U20's consent words, decision 22) were drawn by the plan session (row 25 of the
  canvas, `P15-*`) and approved by the owner on 2026-10-11; a polish row that changes what is seen beyond an approved board has its board first.
- Nothing from V1 is renamed, dropped or narrowed in the model (D56, D26). Migration 0026 is additive: one nullable column
  and a function parameter with a default, so build 25's calls still resolve. `types.ts` regenerated and committed with it.
- A replaced function: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute … to
  authenticated`. No `security definer` beyond `is_member` and `delete_account` (D37). No service-role key, no server job,
  no cron (D37, D60).
- The API runs each call as the user (D5); inputs are zod schemas; `start_ai_generation` gates each call; one model per
  work type from `api/models.json`, no fallbacks (D35, D63, D67). The group kinds' bodies stay `.strict()` and carry no
  student: a sheet, worked example, figure or brief for a student from Make sends the level and the skill names only
  (D62; a test holds each).
- Nothing about a student goes to the AI without consent (D62): the note (with the tutor's own words) and a mock's marking
  name the student and need the recorded consent, which the gate enforces and the app checks first. A sheet for a student
  needs none and asks none.
- No textbook text anywhere (D58). No photo stored by the API.
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4: Make's screens
  are `Features/Make`'s; the made artefact's screens are `Artefacts`', reached by AppShell routes; the rules are Domain's;
  the figures the Kit shows come from AppShell); tokens only (D10, D25); Swift Testing in the existing test targets
  (`AIToolsTests` becomes `MakeTests`).
- No technical words on screen or in anything a tutor reads (D41): each new sentence passes `ErrorWordsTests`; the guide,
  the release notes, "What to Test" and the Beta App Description are checked against `ErrorWordsTests.banned` by hand;
  each message is one of `docs/design/feedback.md`'s rows.
- Words Apple reads are held to App Review Guidelines 2.3 and 5.1.2(i) (Phase 9's constraint).
- Claude creates no account and handles no password on a live system: every App Store Connect step is the owner's, one
  at a time, checked before the next. No tutor's name, email or number in the repository (T1 to T6; the owner keeps the
  mapping); a picture that shows a parent's number is covered before it is committed.
- Text limits count Unicode scalars (D48). Both appearances (D13). Dynamic Type through `AdaptiveRow` and `growsWithText()`.
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull requests
  with pictures; documents directly to `main` (D12), never mixed with code. The website deploys only by `deploy-web` (D45).
- Plain voice in documents; the word is Students; "Batch" on screen for V1's class.
- D68: a hand-run fault, a review finding of any grade, or a polish item this phase's work brings is fixed in this phase,
  each with a test that failed first. A finding from the tutor round is a Bug fixed in its own pull request (D55), a
  Polish row, Later, or No change with the reason; the phase closes with none Open or Proposed.

## Decisions this plan takes

Small decisions, written here so they are not re-decided. The owner's are marked.

1. **`AITools` becomes `Make`.** Spec section 9 names `Features/Make` holding Make something and Check a paper (from
   AITools). PR 1 is the rename alone: the folder, the module, `AIToolsTests` → `MakeTests`, `Package.swift`, `project.yml`,
   the imports; `Route.aiAssistant` → `.make`; nothing seen changes and every test passes unchanged. V1's four forms, its
   result screen and History stay inside it (rule 10); the AI Assistant's name leaves the screen when Make's home replaces
   its home (PR 6). Scan register stays in Students (D36).
2. **The kinds** (`MakeKind`, Domain): for a student or a group: sheet, worked example, figure, note to a parent, mock;
   for you: brief, question paper, homework, worksheet. The rows' symbols and lines are the board's (`components.md` 10.7).
   The V1 three keep their forms as #122 built them (the Class tile by level, no batch); the For sheet's Student and Group
   are the V2 kinds'. This reads the scope's sentence "Make's For tile adds Student and Group around that" as the For
   sheet's segments, since 10.7's text says the V1 forms are unchanged and P12-Form-Paper-Class is approved and built. **The
   owner can rule otherwise** (a paper for a student would then follow the student's chapters; its form would need the For
   tile and a decision).
3. **The For target** (`MakeTarget`, Domain): `.student(UUID)`, `.group(plan: UUID, number: Int)`, `.batch(UUID)`,
   `.classLevel(ClassLevel)`. `MakeRules.level(for:)`: a student's class level (nil → the Class tile reads Choose, as
   P12-Form-Paper-NoClass); a group's as `ArtefactBudget.classLevel(of:students:)` picks it for the plan (the highest
   level among its members); a batch's most common level, ties to the higher (as `AIStore.startingLevel`); a class level
   itself. `MakeRules.skills(for:subject:)`: a student's current skill in the subject (`TrackingRules.currentSkill`
   within the subject's chapters), a group's teach skill, a batch's members' current skills in the subject (distinct, up to
   six), nothing for a class level; the Skill tile shows the first and opens a chooser of the rest with "Type a topic"
   (the sheet's "From the record, or type a topic."). A typed topic is one skill name. The level and the skills are all
   that go to the API: no student id, no name (D62).
4. **Made material is kept** with `keep_artefact`: plan null, group 0, the student for `.student` (so Recent reads "Sheet ·
   Dev Kumar"), item kind practise, the mock's exam as `p_school_item`, and the new `p_made_from = 'make'` (migration
   0026: `artefacts.made_from text check (made_from is null or made_from = 'make')`; the function's eighth parameter
   defaults to null, so build 25's seven-argument call resolves). A sheet for a group names the group in its title
   ("Balancing equations · sheet", "Group 1" in Recent's line from the content's `target` words kept with it:
   `MakeContent.targetLine`, written into the artefact's content under `made_for`).
5. **Recent and History** (Make's home): Make's artefacts (`made_from = 'make'`, newest first, 50) and V1's generations
   together, by time; a row opens the artefact's screen or the V1 result. A regenerated artefact replaces its predecessor
   in the lists (the predecessor stays in the record, `regenerated_from`), as V1's Create again replaces its result. The
   empty row's words are the board's ("Nothing made yet", "Sheets, examples, figures, mocks, notes and papers you make
   appear here, ready to open again."). History keeps its copy on the iPhone (`CachedRead`, as V1's).
6. **The made artefact opens the Artefacts screen of its kind** (P10-Sheet, -WorkedExample, -Figure-*, -Brief, -Mock) as
   the plan's do: `ArtefactScreen` by id. With no plan, the eyebrow names the target from `made_for`: "For Dev · Class 8
   Science · Balancing equations", "Group 1 · Class 8 Science · Chemical reactions", "Evening batch · Class 8 · Science",
   "Class 8 · Science". Make it again keeps `made_from` and the target; Use my own as there; offline a Make artefact has no
   copy on the iPhone (the plan's cache is per batch and day) and its screen says it could not load, with Try again.
7. **Note to a parent from Make** is Phase 14's note screen (`Route.note(student, noteDay)`) for the student and the
   current note day's week, opened from a form of two tiles: Student (the picker) and "What to say" (a well, 300 scalars,
   optional; "The week, or anything you want to say, in their language"). The words go in the request as `tutorSays`
   (`/ai/make` note gains an optional `tutorSays: z.string().max(300)`, and the prompt adds "The tutor adds: …" and asks
   for it in the note); they are kept in the note's content (`tutor_says`) so Write again carries them. Consent and the
   cadence as Phase 14 (a send counts; a note held for consent opens the student's page). A note already kept this week
   opens as it is; What to say with a kept note makes a new one (Write again with the words).
8. **Mock from Make:** a form of Student and Exam (the student's exams to come from the School tab, nearest first; "Type
   it" gives Subject, Title and Portions when there is none); the pattern is the exam's school's or the class's default
   (`MockPattern.default`), as Phase 13 makes it. The mock is kept with the exam (`school_item_id`), so the exam's page and
   Mark from a photo find it; an exam that already has a mock opens it (no second call; Make it again there). A typed
   mock has no exam: Mark from a photo on it writes a mark with the typed title and no exam.
9. **Figure from Make:** For, Subject, Skill or topic, Template (a `PickerTile` with the seven templates by their
   names, the one the skill matches first, else chosen; `FigureSpec.Kind.title`). The form is the Phase 6 form with the
   board's tiles; 10.7 draws only the sheet's and names the note's, mock's and brief's fields, so the figure's Template tile
   is this plan's call (the API needs the template; the plan's figure line picks it from the skill, and a tutor may want
   another). A figure whose spec fails the app's rule is refused in words (Phase 12).
10. **Brief from Make:** Class (the level wheel of P12-Form-Paper-ClassWheel), Subject, Chapter (the chapters of the
    students at that level in the subject, or typed). Worked example: For, Subject, Skill or topic.
11. **The sheet's form** is P10-Make-Form: For, Subject, Skill or topic, Length (Short 6, Medium 10, Long 15 questions;
    `questions` 3 to 30 in the schema), Level (Easier, As the record says, Harder: the sheet's `reason` as the regenerate
    menu sends it, nil for the middle), Key at the end (the PDF's key block, for you), Make the sheet. The helper reads
    "Made against Group 1's record. A sheet made for a class alone follows the class's chapters." with the target's
    name. Homework or practice: a sheet from Make is practice (`forHomework: false`); the plan's homework sheets stay the
    plan's.
12. **The For sheet** (P10-Make-For): a floating sheet, Cancel, the four-segment control, the rows: Student (the student
    picker's rows, as `StudentPickerSheet` draws them); Group (today's groups from today's plans of the batches meeting
    today: "Group 1 · Chemical reactions", "Dev, Meher, Nikhil · Class 8 Science · today's plan"; with no plan today the
    empty row "No groups today" "Open Today to make the plan."); Batch (the centre's batches with their members' count);
    Class (LKG to 10 as rows, the levels the centre has first). The footnote is the board's. The call waits for Make; the
    form keeps the last target per kind on this iPhone (as the class is kept, `AIStore.remember`).
13. **Making** (`make-making`): the Phase 6 creating card over the form ("Making the sheet", Cancel, "Usually under a
    minute. You can wait here or come back from History."); the call belongs to `MakeStore` (one per centre on the shell,
    as `AIStore`), so leaving the form does not lose it; when it lands AppShell pushes the artefact's screen if the form or
    Make's home is on top, else the artefact waits in Recent. A refused or failed call shows the Phase 6 error row with
    Retry (the API's words: a refusal in its kind's words, the consent, the allowance, the connection). Offline, Make is
    refused by the system alert (`OfflineRefusal.make`: "You're offline. Making material needs a connection.") with the form
    kept.
14. **Check a paper under Make** (P10-Make-Check): the intro's hero is the board's ("Check a paper", "Photograph the
    answer sheet. We suggest a mark for each answer against the key; you decide every one."); the card holds Student and
    Scheme (`PickerTile`, "Unit test 3 · the mock" or "Type a scheme"; the helper "A mock or paper made here, with its key;
    or type a scheme."); the notice, Take a photo, Choose from Photos, the AI line as drawn. The Scheme tile pushes the
    Marking scheme screen (P6-Check-Scheme, an approved screen) as a chooser: its first segment reads "A mock or paper made
    here" and lists the student's mocks (artefacts of kind mock whose exam reaches the student, and Make's mocks for the
    student) then the centre's papers; "Type it" as now; the footer reads "Use this scheme" (one label on an approved
    screen, by state, as Save's labels are). With a scheme chosen on the intro, the pages step goes straight to the marks;
    with none, pages → scheme → marks as V1 (nothing dropped). Changing the student clears a mock scheme (a mock is an
    exam's); a paper stays. A mock's key needs the student's consent (Phase 13's rule, asked before any call).
15. **`Term`** (Domain): `Term(schoolYear: Int, number: 1 | 2, calendar: Term.Calendar)`; `.standard` (CBSE, ICSE,
    Other, no board): Term 1 June to September, Term 2 October to March; `.karnataka`: Term 1 June to October, Term 2
    November to April (the state's year ends in April). Whole months only. `Term.containing(_:calendar:)`, `previous`,
    `next` (Term 1 2026's previous is Term 2 2025, October 2025 to March 2026), `title` ("Term 1 · June to September"),
    `months: [Period]`, `hasEnded(now)`. The report's calendar is the one most of the centre's active students' schools
    use (ties to standard; no schools → standard), so one report has one span; the title says the span.
16. **Progress' numbers** (`ProgressRules`, Domain, pure; the `ProgressInput` per student: skills, chapters, checks,
    sessions, status, class level, the span's months): skills secure = skills whose state is secure and whose `stateAt`
    falls in the span; checks = the span's checks without placements; right = correct over checks ("41%", rounded); absences
    = absent marks of the student in the span's sessions; the status word is the student's status now. The line: "<n>
    skills secure · <p>% right · <a> absences" (absences left out at 0; "No checks yet" in place of the percent with no
    checks); a ladder student (LKG to 3 with ladder chapters): the current step per area, "Reading: Sentences · Numbers:
    To 99" (the areas with a step beyond the first), then absences; not known yet: "Placed <day> · n checks so far" when a
    placement exists, else "n checks so far" or "No checks yet"; the percent on the right is right %, "–" with no checks.
    The hero: skills secure summed, right % over every row's checks ("–" with none), the count of rows Not on track
    ("not on track"; "not on track at the end" when the term has ended: no history is kept, so it is the status today).
    Sort: Lowest first (percent ascending, "–" last, then by name), Highest first, By name; the sort row is the Students
    list's sort menu pattern. Active students only; the hero sums the rows (an archived student leaves both).
17. **The CSV** (`ProgressCSV`): columns student, class, status, skills secure, checks, right, absences; file
    `progress-2026-10.csv` for a month, `progress-term-1-2026.csv` for a term; the Share sheet gains the Progress choice
    (P5-Reports-Export's third `ChoiceCard`). Marks stay on the student's page: the board's row and CSV carry none (scope
    3 names marks; the board, which wins, draws skills, checks and absences).
18. **The reads** (`ProgressReader`, Data): one query each for the active students' skills (`TextbooksRepository.skills(
    centre:students:)`, new), chapters (`chapters(centre:students:)`, new), checks since the span's start (filtered to its
    end on the phone), the span's months' sessions, the register's students; a failed read is the Phase 5 error line with
    Try again. `ReportsStore` gains the segment, the span (`.month(Period)` or `.term(Term)`), the sort and a load
    generation per span (a month move drops a stale answer).
19. **The Kit's Phase 10 rows** (`KitPhase10`, DesignSystem; `kit-phase10`, both appearances): Tracking status (chip and
    word), Skill states (`StateMark` × 5), School item kinds (`KindChip` × 4) and the material's marks (Set · Sheet · Checks),
    a chapter row open with skill rows, the plan line, the check row with the line checklist and the right-or-wrong pair
    in both states, the ladder row and the trend card, the seven figure templates, the board view's type. The figures are
    drawn by Artefacts (Phase 12's ruling), so `KitView` takes `figures: (() -> AnyView)?` from AppShell (the one `AnyView`
    in the Kit, a debug-only screen, never per state) built from `FakePlansRepository`'s seven board specs through
    Artefacts' figure view; the group reads "Figure templates · the validators' previews".
20. **The seed gains checks** (local only): three weeks of sessions' checks for the Evening batch's twelve and Hemanth
    (three a session on their own skills, every fourth wrong, Dev's half wrong, Riya placed with two), dated from
    `current_date`, so the trend, the tracking rules and Progress show figures by the rules and hand runs 9 and 10 have
    something to prove. The fixtures' Progress states carry what the boards' statuses need (Dev not on track, Hemanth and
    Nikhil watch, Akshita on track, Sahil on the ladder, Riya not known); the boards' numbers are illustrative.
21. **Launch states:** `make` (both), `make-empty`, `make-sheet`, `make-for`, `make-for-student`, `make-worked-example`,
    `make-figure`, `make-brief`, `make-mock`, `make-note`, `make-making`, `check-intro` (superseding P6's), `check-scheme-
    chooser`, `reports-progress`, `reports-progress-term`, `reports-progress-sort`, `reports-export` (with Progress),
    `kit-phase10` (both). `ai-assistant` and `ai-assistant-empty` retire (`make`, `make-empty`); the other `ai-*` states keep
    their names (V1's forms and results, unchanged). `today-ai`'s Create row opens Make.
22. **The polish rows** the owner took (2026-10-11): U17, U18, U20, U21, U22, U23, U26, U32, U40, U34, U11 and U19, as Task 12
    lays them out (U22 and U23 in PR 8, U26 in PR 9, the rest in three pull requests by screen group); U20's new words have their
    board, P15-Consent-Note (row 25), drawn by the plan session; approved first.
23. **U36 is misfiled** under Open (its row reads like a Done row: "#133", built in Phase 13). Task 23 moves it to Done
    with #133.
24. **The trust page** (spec sections 8 and 9: "the trust page on tutorcentral.in … updated in the phase that first sends a
    student's data to testers") is this phase's, before any tutor is invited: `/trust` on the site (D50's rules: no vendor
    named but the AI service as the consent sheet names it), with the privacy page's consent facts added. Its boards (P15-Web-Trust at 1280
    and 390, dark and light, in P8's page pattern) were drawn by the plan session from the privacy page's board and the
    consent sheet's words (`information-architecture.md`, "Phase 15 boards", with the claims table); approved by the owner,
    then built (PR 12) and deployed by `deploy-web` before Owner step 4. The App Privacy answers are Phase 16's listing work.
25. **Per-student export** (D62 names it) stays for later: no scope line, no board. Named to the owner here, not built.
26. **The tutor round's files:** `plan/phase-15-findings.md` (the Phase 9 skeleton: Testers, Readings, Findings, Later),
    `plan/phase-15-findings/` for pictures; `docs/testing/tester-guide.md` rewritten for V2 (Task 19's text); the release
    notes for V2's first external build in `docs/release.md` under "1.0 (build N), the first V2 build for the Tutors group";
    the Beta App Description for V2 (Owner step 1). Phase 9's findings file stays as the cancelled round's record.
27. **The round's build** is the Phase 15 build after the review and the owner's own test of the builds (D68): the
    tester's device checks (D1 to D8, T1 to T14, and the S, C, A, N, W tests whose screens V2 changed) run on it in the
    internal group while Beta App Review runs; D7 on the day the group is approved; then the invitations. **When the round
    starts relative to the build is the owner's** (the question below).
28. **Branches** `phase-15/<slug>` in the main checkout (as sessions 22 to 30); a round fix `phase-15/F<n>-<slug>`. The
    ledger is `plan/sessions/032/ledger.md`.
29. **The cost run** (D64, the owner's standing approval for real calls): Make's kinds on the real models, about ₹20 (a
    marking on Opus is ₹8 of it); the figures into the "As built" and `PriceSheet.typical`'s rows where a kind's average
    changes.
30. **`MakeStore`** holds Make's home (Recent, History) and the one call running; `MakeFormStore` per form (kept in
    `@State` by the form, as Phase 14's `FixRowSheet` rule); `ForStore` reads today's plans and the register for the For
    sheet; `SchemeChooserStore` is `CheckStore`'s own list (mocks and papers). The stores are tested against the fakes.

### Owner's questions (asked one at a time in the session's message)

1. **Which polish rows to take.** Every open row with what it takes:

| Row | What it takes | Board |
|---|---|---|
| U5 More rows 56 pt (board 50) | `SettingRow`'s minimum height for More's rows; pictures of More | no (P10-More draws 50) |
| U8 A popover's calendar: picking the shown day leaves it open; Sunday first | `calendarPopover` closes on a pick; Monday first is set since Phase 7 (check it holds) | no |
| U10 Attendance mark: no spinner for a slow read; the hint beside the error | a `Skeleton` row by the date while loading; the hint hidden with the error line | yes (a loading state no board draws) |
| U11, U19 `today-adding-task`, `today-ai` not scrolled as drawn | the launch states scroll to the section (a fixture change) | no |
| U13 A sheet stays up when a link switches tabs | dismiss any sheet on a link (`ShellState.openLink`) | no |
| U14 Fees, an empty month: no overdue banner | show the overdue banner over the empty month | yes (P5-Fees-Empty draws none) |
| U15 Fees Due/Paid empty rows' words | the Kit's empty row with words a board gives | yes (the words) |
| U17 The note's counter "80 of 2,000" (board "135 / 2000") | the counter's form on `NotesWell` | no (P6-Form-ProgressNote) |
| U18 Progress note's Send sheet opens lower than drawn | the sheet's detent | no (P6-ProgressNote-Send) |
| U20 The consent sheet over the note speaks of photos | a note's words on the centre's consent sheet | yes (the words) |
| U21 "Couldn't create the homework." wraps | shorter words or the row's width | no |
| U22 Two papers on one topic look alike in the scheme list | the day and time, newest first (this phase's chooser) | no (taken in PR 8) |
| U23 "0 pages" after removing every page | "No pages" and the footer disabled (this phase's screen) | no (taken in PR 8) |
| U25 Delete account's button under the keyboard | scroll the footer above the keyboard (as U6) | no |
| U26 Reports has no copy offline | `CachedRead` per month and span for the three reports, the offline status line (this phase's screen) | no (the Phase 7 offline bar on an existing screen) (taken in PR 9) |
| U27 Attendance offline at launch shows nothing for 20 s | read the day's saved copy first, then the network (as Fees does) | no |
| U28 No receipt offered after an offline Mark paid | queue the receipt's log with the fee (a fourth queued write) | yes (a state no board draws) |
| U29 "Scan paper regis…" cut at large text | a shorter label or the menu's width | no |
| U30 "Sign in again" has no way but Sign out | a Sign in button on the line that keeps the saved changes | yes |
| U32 Pushed screens' content scrolls under the status bar with no glass | `statusBarGlass()` on each pushed screen | no (U24's board for the pattern) |
| U34 Students' empty card's buttons side by side | stack them at full width (the board) | no (P10-Students-Empty) |
| U40 The student page's parent row under the status bar | `statusBarGlass()` on the page | no (U32's pattern) |

   **Answered 2026-10-11:** "U17, U18, U20, U21, U22, U23, U26, U32, U40, U34, U11 and U19 are in scope of phase 15." Task 12
   carries them. U5, U8, U10, U13, U14, U15, U25, U27, U28, U29 and U30 stay open for a later slice.
2. **When the round starts relative to the build.** Proposed: the Phase 15 build goes to TestFlight after the review; the
   owner tests the builds together (D68) in the days after; the tester's device checks run on that build in the internal
   group the same week; Beta App Review is submitted once the owner's own test passes; the tutors are invited the day the
   group is approved, three weeks from then. Dated from a build on Thursday 15 October: the owner's test 16 to 18 October,
   Beta App Review submitted Monday 19 October, the invitations about 21 October, the round to 11 November, the close that
   week. The alternative is to invite before the owner's own test (the tester's checks alone gate it), a week sooner.

### Left for later, with the reason

- Per-student export (decision 25).
- The App Privacy answers and the listing's V2 words (Phase 16's scope).
- A paper, homework or worksheet for a student or a group (decision 2): the owner's call.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A student with no record yet** (no book, no class level, just added): the For sheet lists them; the Skill tile offers
   nothing from the record and reads "Type a topic"; Class reads Choose until set, and Make waits for both; on Progress the
   row reads "Not known yet · No checks yet · –". Tests: Task 4 (`MakeRulesTests.aStudentWithNoBookHasNoSkillsAndNoLevel`),
   Task 8 (`MakeFormStoreTests.makeWaitsForALevelAndATopic`), Task 5 (`ProgressRulesTests.aStudentWithNothingReadsNotKnownYet`).
2. **A group across class levels** (a group of class 5 and class 2 members): the sheet is made at the group's level as the
   plan made its own (the highest member's), with the group's teach skill; the eyebrow names the group. Tests: Task 4
   (`MakeRulesTests.aGroupAcrossLevelsIsMadeAtItsHighestLevel`), Task 8 (`MakeFormStoreTests.aGroupsSheetSendsTheGroupsLevelAndSkill`).
3. **A term that spans the school year's change:** Term 2 runs October 2026 to March 2027 (its months cross the year; its
   file name says 2026); stepping back from Term 1 2026 gives Term 2 2025 (October 2025 to March 2026); the Karnataka
   calendar's Term 2 runs to April. Tests: Task 4 (`TermTests.termTwoSpansTheNewYear`, `theTermBeforeTermOneIsLastYearsTermTwo`,
   `theKarnatakaYearEndsInApril`), Task 10 (`ReportsProgressStoreTests.steppingBackFromTermOneShowsLastYearsTermTwo`).
4. **A student archived mid-term:** their row leaves Progress and the hero drops by their figures, so the two agree; the
   CSV has no row for them. Tests: Task 5 (`ProgressRulesTests.anArchivedStudentIsNeitherListedNorSummed`), Task 10
   (`ReportsProgressStoreTests.archivingAStudentRemovesTheirRowAndTheirFigures`).
5. **A kind made again from Recent:** Make it again on a Make artefact keeps `made_from` and the target, sets
   `regenerated_from`, and Recent shows the new one once in the old one's place; the old stays in the record. Tests: Task 2
   (`keep_artefact keeps made_from on a regenerate`), Task 7 (`MakeStoreTests.makeItAgainFromRecentReplacesTheRowAndKeepsTheRecord`).
6. **A sheet for a student whose parent has not agreed:** made anyway (nothing about the student is sent; D62), the body
   carrying the level and the skill names only; a note for them is refused in Phase 14's words before any call. Tests: Task
   8 (`MakeFormStoreTests.aSheetForAStudentSendsNoStudentAndNeedsNoConsent`), Task 3 (`a sheet body naming a student is a 400`).
7. **A mock for an exam that already has one:** opened, not made again; Make it again there. Test: Task 8
   (`MakeFormStoreTests.anExamWithAMockOpensItWithoutACall`).
8. **Check a paper's student changed after a mock was chosen:** the mock scheme is cleared (it is another student's exam);
   a paper stays. Test: Task 9 (`CheckStoreTests.changingTheStudentClearsAMockSchemeAndKeepsAPaper`).
9. **A month with sessions but no checks** (a V1 centre, or a batch that never closed): rows show their absences and "No
   checks yet"; the hero reads 0 skills, "–" right, the not-on-track count; the CSV writes 0 checks. Tests: Task 5
   (`ProgressRulesTests.aMonthWithAttendanceAndNoChecksShowsAbsencesOnly`), Task 10 (`ReportsProgressStoreTests.aCentreWithNoChecksStillLoads`).
10. **A tutor's report with no build number or a tester who cannot install** (Phase 9's focus 1 and 3 stand): the Testers
    table's iOS column is filled before an invitation; a finding row needs Build and Who. Pinned in Tasks 19 and 21.

## File structure

Created or changed, by module. A file has one job; the stores are small and named for what they do.

| Module | File | Job |
|---|---|---|
| ios | `TutorCentralKit/Sources/Features/Make/` (was `AITools/`), `Tests/MakeTests/` (was `AIToolsTests/`), `Package.swift`, `project.yml`, the `import AITools` sites in AppShell and the tests | PR 1: the rename |
| supabase | `migrations/20261031000026_v2_artefacts_made_from.sql`, `tests/v2.test.ts` (a "make" block), `seed.sql` (the checks), `types.ts` | `made_from`; `keep_artefact`'s eighth parameter; the seed's checks |
| api | `src/schemas.ts` (`tutorSays`), `src/prompts/note.ts`, `src/claude-fake.ts` (a note with the tutor's words), `test/v2.test.ts`, `test/prompts.test.ts`, `test/schemas.test.ts` | The note's `tutorSays`; the strict group kinds held |
| Domain | `Make/MakeKind.swift`, `Make/MakeTarget.swift`, `Make/MakeRules.swift`, `Make/MakeContent.swift` (`made_for`), `Reports/Term.swift`, `Reports/ProgressRules.swift`, `Reports/ProgressCSV.swift`, `Queue/OfflineRefusal.swift` (`.make`), `Record/FigureSpec.swift` (`Kind.title`), `Plan/Artefact.swift` (`madeFrom`, `madeFor`) | The rules and the shapes |
| Data | `Plans/PlansRepository.swift` (`keepMade`, `made(centre:)`, `mock(forExam:)`), `SupabasePlansRepository.swift`, `FakePlansRepository.swift`, `PlanRows.swift` (`made_from`, `made_for`), `Textbooks/*` (`skills(centre:students:)`, `chapters(centre:students:)`), `Reports/ProgressReader.swift`, `AI/AIRepository+Parents.swift` (`NoteRequest.tutorSays`), `AI/APIBodies+Parents.swift`, `AI/AISamples+Parents.swift`, `Cache/CachedRead.swift` (the reports' keys, if U26) | The reads and writes behind the screens |
| DesignSystem | `Kit/KitPhase10.swift`, `Kit/KitView.swift` (`figures`), `Components/ProgressRows.swift` (`ProgressRow`, `ProgressHero`), `Components/SortRow.swift` (if the Students list's sort is not reusable as is), `Tokens` where a board's value is new (none expected: the hero's columns and the row are Kit parts) | The 10.7 parts |
| Features/Make | `MakeHomeView.swift`, `MakeStore.swift`, `MakeStore+Recent.swift`, `MakeFormView.swift`, `MakeFormStore.swift`, `MakeFormStore+Call.swift`, `ForSheet.swift`, `ForStore.swift`, `SkillChooserSheet.swift`, `ExamChooserSheet.swift`, `MakeWords.swift`, `MakeActions.swift`, `CheckIntroView.swift` (the Scheme tile), `CheckSchemeView.swift` (the chooser mode, U22, U23), `CheckStore.swift`, `CheckStore+Schemes.swift`, `HistoryView.swift` (both lists), `AssistantView.swift` removed | Make something; Check a paper under Make |
| Features/Artefacts | `ArtefactWords.swift` (the target's eyebrow), `SheetStore.swift`, `WorkedExampleStore.swift`, `FigureStore.swift`, `BriefStore.swift`, `MockStore.swift` (made_from kept on a regenerate; the eyebrow with no plan), `NoteStore.swift`, `NoteStore+Make.swift` (`tutorSays`), `Figures/FigurePreviews.swift` (the Kit's seven) | The made artefact's screens |
| Features/Fees | `ReportsStore.swift` (the segment, the span, the sort), `ReportsStore+Progress.swift`, `ReportsView.swift` (Progress, Month \| Term, the sort row), `ExportSheet.swift` (Progress), `ReportsCache.swift` (if U26) | Reports' Progress |
| AppShell | `TabsState.swift` (`Route.make`, `.makeForm(MakeKind)`), `RootView+Make.swift` (was `+AITools`), `RootView+Artefacts.swift` (made_for eyebrow context), `RootView+Fees.swift` (Progress' reader), `RootView+LaunchStates.swift`, `LaunchState.swift`, `Fixtures+Make.swift`, `Fixtures+Progress.swift`, `Fixtures+AI.swift`, `MoreView.swift` (`.make`), `RootView+Today.swift` (the Create row), `Dependencies.swift` (the reader), the Kit's `figures` | The shell |
| web | `app/trust/page.tsx`, `content/trust.ts`, `content/privacy.ts` (the consent facts), `test/unit/pages.test.ts`, `words.test.ts`, `test/export/*` | The trust page (PR 12, after its board) |
| docs | `docs/design/mockups/P15-Web-Trust-*.dc.html`, `directions/canvas.json`, `information-architecture.md`, `components.md`, `design-tokens.md`; `docs/testing/tester-guide.md`, `device-tests.md`; `docs/release.md` | The board; the round's words |
| plan | `phase-15-findings.md`, `phase-15-findings/`, `ui-polish.md`, `STATE.md`, `README.md`, `phase-15-make-and-polish.md`, `sessions/032/*` | The round; the records |
| Tests | `supabase/tests/v2.test.ts`; `api/test/{v2,schemas,prompts,claude-fake}.test.ts`; `DomainTests/{MakeRulesTests, MakeTargetTests, TermTests, ProgressRulesTests, ProgressCSVTests, OfflineRefusalTests, ArtefactContentTests (made_for)}`; `DataTests/{ProgressReaderTests, PlanRowsTests (made_from), APIBodiesParentsTests (tutorSays), FakePlansRepositoryMakeTests}`; `MakeTests/{MakeStoreTests, MakeFormStoreTests, ForStoreTests, CheckStoreTests (schemes), CheckSchemeChooserTests, AIStoreTests…}` (the moved suites); `FeesTests/{ReportsProgressStoreTests, ReportsCacheTests}`; `ArtefactsTests/{ArtefactWordsTests, NoteStoreTests (tutorSays), SheetStoreAgainTests (made_from)}`; `AppShellTests/{LaunchStateTests, RoutesTests, KitFiguresTests}`; `DesignSystemTests/KitPhase10Tests`; `web/test/unit/{pages,words}.test.ts` | |

## Launch states

Each state the 10.7 boards name and the ones this plan adds, with the fixtures' data (decision 21). Light twins from
`--appearance light` where the board has both. The clock is Wednesday 7 October 2026 16:40 unless the state says another.

| State | Shows | Board | PR |
|---|---|---|---|
| `make` | Make something: the intro line, the five kinds for a student or a group, the four for you, Recent (a sheet for Group 1, Dev's mock, the Chemical reactions brief), the AI line; History in the nav row (both) | P10-Make, -Light | 6 |
| `make-empty` | Make with nothing made yet (the empty row) | P10-Make (the Recent card's empty row, Phase 6's pattern) | 6 |
| `make-sheet` | The sheet's form for Group 1 (Dev, Meher, Nikhil), Science, Balancing equations, Medium, As the record says, Key at the end on | P10-Make-Form | 7 |
| `make-for` | The For sheet at Group over it: today's three groups | P10-Make-For | 7 |
| `make-for-student` | The For sheet at Student: the picker's rows | P10-Make-For (the segment's rows are the student picker's) | 7 |
| `make-worked-example` | The worked example's form: For Dev, Science, Balancing equations | the form's tiles (decision 10) | 7 |
| `make-figure` | The figure's form: For Class 5, Mathematics, Fractions on a bar, Template Fraction bar | the form's tiles (decision 9) | 7 |
| `make-brief` | The brief's form: Class 8, Science, Chemical reactions | the form's tiles (decision 10) | 7 |
| `make-mock` | The mock's form: Dev, Science unit test 3 · Fri 16 Oct | the form's tiles (decision 8) | 7 |
| `make-note` | Note to a parent: Dev, What to say typed ("Ask him to show you the balancing steps") | the form's tiles (decision 7) | 7 |
| `make-making` | The sheet being made: the creating card over the form | P6-Generating's card on P10-Make-Form | 7 |
| `check-intro` | Check a paper under Make: Dev, the Scheme tile "Unit test 3 · the mock" | P10-Make-Check (supersedes P6-Check-Intro) | 8 |
| `check-scheme-chooser` | The Marking scheme screen as the chooser: Dev's mock first, then the papers; the footer Use this scheme | P6-Check-Scheme (the first segment's new title and rows; U22's day and time) | 8 |
| `check-pages-empty` | The pages step with every page removed: "No pages", the footer disabled (U23) | P6-Check-Pages | 8 |
| `reports-progress` | Reports, October 2026, Progress by month: the hero, Lowest first, the rows | P10-Reports-Progress | 9 |
| `reports-progress-term` | Reports, Term 1 · June to September, Progress | P10-Reports-Progress-Term | 9 |
| `reports-progress-sort` | The sort menu open over Progress (Lowest first ticked) | the Students list's sort menu (P3) | 9 |
| `reports-export` | Share as CSV with Progress as the third choice, Progress chosen | P5-Reports-Export | 9 |
| `kit-phase10` | The Kit at the Phase 10 rows (both) | P10-Kit-Dark, -Light | 10 |
| `today-ai` | Today's Create row opens Make (the row's words unchanged) | P6-Today-AITools | 6 |

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-15/make-module` | `AITools` becomes `Make` (the folder, the module, the tests, the route); nothing seen changes | none (`make`'s predecessor states unchanged: `ai-assistant` before and after, for the record) |
| 2 | 2 | `phase-15/db` | Migration 0026: `artefacts.made_from`; `keep_artefact`'s eighth parameter; the seed's checks | none |
| 3 | 3 | `phase-15/api-note-says` | The API: the note's `tutorSays`; the group kinds held strict | none |
| main | | | `gh workflow run deploy` after PR 3: 0026 up, the API at `main`'s head (Task 16) | |
| 4 | 4 | `phase-15/domain` | Domain: the kinds, the target and its rules, `Term`, the offline refusal, the figure templates' names | none |
| 5 | 5 | `phase-15/domain-progress` | Domain: `ProgressRules` and `ProgressCSV` | none |
| 6 | 6, 7 | `phase-15/make-home` | Make something: the home, Recent and History from both repositories, More's row, Today's Create row; Data's `keepMade` and `made` | `make` (both), `make-empty`, `today-ai`, `more` |
| 7 | 8 | `phase-15/make-forms` | The kinds' forms with the For sheet, the skill and exam choosers, the call, the made artefact's screen with its target | `make-sheet`, `make-for`, `make-for-student`, `make-worked-example`, `make-figure`, `make-brief`, `make-mock`, `make-note`, `make-making`, `sheet` (a Make sheet's eyebrow) |
| 8 | 9 | `phase-15/check-under-make` | Check a paper under Make: the Scheme tile and the chooser with mocks; U22, U23 | `check-intro`, `check-scheme-chooser`, `check-pages-empty` |
| 9 | 10 | `phase-15/reports-progress` | Reports' Progress by month and by term, the sort, the CSV; `ProgressReader`; U26 | `reports-progress`, `reports-progress-term`, `reports-progress-sort`, `reports-export` |
| 10 | 11 | `phase-15/kit-phase10` | The Kit's Phase 10 rows | `kit-phase10` (both) |
| 11 | 12 | `phase-15/polish-note-forms`, `-glass`, `-states` | The polish rows the owner took: U17, U18, U20, U21; U32, U40; U34, U11, U19 (U22, U23 in PR 8; U26 in PR 9) | each row's states, both appearances |
| 12 | 13 | `phase-15/web-trust` | The website's trust page and the privacy page's consent facts (after the board's approval) | `bun web-shots --pages /trust,/privacy` at 1280 and 390, both |
| main | | | `gh workflow run deploy-web` after PR 12 (Task 16) | |
| 13+ | 14, 15, 16, 20, 21 | `phase-15/fix-<what>`, `phase-15/F<n>-<slug>` | The hand runs', the cost run's, the review's and the round's fixes | each changed state |
| main | 17, 18, 19, 20, 21, 22, 23 | | The documents (D12), the owner's steps, the readings, the close | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked, the pictures by
`bun shots <state>` and `bun pr-shots` (rule 2). PR 12 builds to a board approved first (decision 24).

## The calendar

The shape is fixed; the dates follow the owner's answer to question 2. Today is Sunday 11 October 2026.

| When | What |
|---|---|
| The build (from Monday 12 October, Opus 5.5) | Tasks 1 to 13 as the pull requests above; the deploys; Task 14 (the hand runs); Task 15 (the cost run); Task 16 (the review, every finding fixed); the TestFlight build; Task 17 (the documents so far) |
| Week 0 (proposed 15 to 21 October) | Task 18 (the release notes, the checklist); Task 19 (the guide, the findings file); Owner steps 1 to 3; Task 20 (the tester's device checks); the approval, D7; Owner steps 4 and 5 |
| Weeks 1 to 3 (three weeks from the invitation day) | Task 21 twice a week (Monday, Thursday); the fix pull requests and Thursday builds |
| The week after | Task 22 (the close): the final build if one is needed, the tester's final lines, the acceptance, "As built"; Task 23 (the documents) |

---

### Task 1: `AITools` becomes `Make` (PR 1)

**Files:**
- Move: `ios/TutorCentralKit/Sources/Features/AITools/` → `Sources/Features/Make/`; `Tests/AIToolsTests/` → `Tests/MakeTests/`
- Modify: `ios/TutorCentralKit/Package.swift` (the features list, the test target), `ios/project.yml` (the scheme's test
  target), every `import AITools` (AppShell's `ShellState`, `RootView+LaunchStates`, `RootView+School`, `RootView+Artefacts`,
  `Fixtures+AI`, `RootView+AITools` → `RootView+Make`; `AppShellTests/StoreLifetimeTests`, `LaunchStateTests`), `ios/CLAUDE.md`
  is a document (Task 17)
- Modify: `AppShell/TabsState.swift` (`Route.aiAssistant` → `.make`), `AppShell/TabsView.swift`, `MoreView.swift`, `RootView+Today.swift`

**Interfaces:**
- Consumes: nothing new.
- Produces: the module `Make` every later task imports; `Route.make`.

- [x] **Step 1: the move**, with git so history follows:

```bash
git checkout -b phase-15/make-module main
git mv ios/TutorCentralKit/Sources/Features/AITools ios/TutorCentralKit/Sources/Features/Make
git mv ios/TutorCentralKit/Tests/AIToolsTests ios/TutorCentralKit/Tests/MakeTests
git mv ios/TutorCentralKit/Sources/AppShell/RootView+AITools.swift ios/TutorCentralKit/Sources/AppShell/RootView+Make.swift
grep -rl 'AITools' ios/TutorCentralKit/Sources ios/TutorCentralKit/Tests ios/TutorCentralKit/Package.swift ios/project.yml
```

- [x] **Step 2: the names.** In `Package.swift`'s feature list `"AITools"` → `"Make"` and the test target
  `.testTarget(name: "MakeTests", dependencies: ["Make", "Students"])`; in `project.yml` the scheme's
  `package: TutorCentralKit/MakeTests`; each `import AITools` → `import Make`; `Route.aiAssistant` → `Route.make` and its
  uses (`aiRoutes`, `TabsView`, `MoreView`'s row, Today's Create row). The file-level comments that say "AI Assistant" stay
  until PR 6 replaces the home. `bun gen`.

- [x] **Step 3: prove nothing changed.** `bun check --only=format,lint,ios` green; `bun shots ai-assistant` and `bun shots
  ai-paper` match the pictures before the move (compare by eye; the state names are kept until PR 6).

- [x] **Step 4: commit and open the pull request** ("`AITools` becomes `Make`: a rename, nothing seen changes"); merge when
  green. No pictures (rule 2 applies to a change in what is seen; the description says so and names the two states compared).

---

### Task 2: Migration 0026 and the seed's checks (PR 2)

**Files:**
- Create: `supabase/migrations/20261031000026_v2_artefacts_made_from.sql`
- Modify: `supabase/seed.sql`, `supabase/tests/v2.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: `artefacts.made_from`; `keep_artefact(p_centre, p_artefact, p_plan, p_group_no, p_student, p_item_kind,
  p_school_item default null, p_made_from text default null)`.

- [x] **Step 1: the failing tests** (`supabase/tests/v2.test.ts`, a `describe("make")` block; the file's own fresh centre and
  users, as Phase 14's block does):

```ts
describe("make", () => {
  test("keep_artefact keeps made_from and a regenerate keeps it too", async () => {
    const first = await rpc(a, "keep_artefact", { p_centre: centre, p_artefact: sheet("Balancing equations · sheet"), p_plan: null, p_group_no: 0, p_student: null, p_item_kind: "practise", p_school_item: null, p_made_from: "make" });
    const again = await rpc(a, "keep_artefact", { p_centre: centre, p_artefact: { ...sheet("Balancing equations · sheet"), regenerated_from: first }, p_plan: null, p_group_no: 0, p_student: null, p_item_kind: "practise", p_school_item: null, p_made_from: "make" });
    const rows = await select(a, "artefacts", "id, made_from, regenerated_from", { centre_id: centre });
    expect(rows.find((r) => r.id === first)?.made_from).toBe("make");
    expect(rows.find((r) => r.id === again)).toMatchObject({ made_from: "make", regenerated_from: first });
  });
  test("the seven-argument call still resolves and leaves made_from null", async () => {
    const id = await rpc(a, "keep_artefact", { p_centre: centre, p_artefact: sheet("A plan's sheet"), p_plan: null, p_group_no: 1, p_student: null, p_item_kind: "practise", p_school_item: null });
    const [row] = await select(a, "artefacts", "made_from", { id });
    expect(row.made_from).toBeNull();
  });
  test("made_from takes only make", async () => {
    await expect(rpc(a, "keep_artefact", { p_centre: centre, p_artefact: sheet("x"), p_plan: null, p_group_no: 0, p_student: null, p_item_kind: "practise", p_school_item: null, p_made_from: "page" })).rejects.toThrow(/check/);
  });
  test("another centre's member cannot read a Make artefact", async () => {
    await rpc(a, "keep_artefact", { p_centre: centre, p_artefact: sheet("x"), p_plan: null, p_group_no: 0, p_student: null, p_item_kind: "practise", p_school_item: null, p_made_from: "make" });
    expect(await select(b, "artefacts", "id", { made_from: "make" })).toHaveLength(0);
  });
});
```

  `sheet(title)` is `{ kind: "sheet", source: "made", title, content: { title, questions: [], for_homework: false, light: false } }`.
  Run: `cd supabase && bun test tests/v2.test.ts`. Expected: four fail (the parameter does not exist; the column does not exist).

- [x] **Step 2: the migration**, in full:

```sql
-- Phase 15: material made from Make something (plan/phase-15-plan.md decision 4). Additive (D26): one nullable column; the
-- function gains an eighth parameter with a default, so build 25's seven-argument call still resolves.
alter table public.artefacts
  add column made_from text check (made_from is null or made_from = 'make');

drop function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid);

create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind, p_school_item uuid default null,
                                     p_made_from text default null) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, school_item_id, title, content, photo_path,
                                generation_id, regenerated_from, made_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_school_item, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb),
          p_artefact->>'photo_path', (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid, p_made_from)
  returning id into v_id;
  if p_plan is not null then
    update public.plan_items i set artefact_id = v_id
     where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
       and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  end if;
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind, uuid, text) to authenticated;

create index artefacts_made_from_idx on public.artefacts (centre_id, created_at desc) where made_from = 'make';
```

- [x] **Step 3: the seed's checks** (decision 20), after the attendance block:

```sql
-- Phase 15: three weeks of checks at the Evening batch's closes (and Hemanth's at Class 10 Maths), three a session on
-- each student's own skills: every fourth wrong; Dev's every second; Riya placed with two. The trend, the tracking rules
-- and Reports' Progress then show figures by the rules (plan/phase-15-plan.md decision 20).
insert into public.checks (centre_id, session_id, student_id, skill_id, kind, question, correct, created_at)
select a.centre_id, a.id, k.student_id, k.id, 'check', jsonb_build_object('question', k.name, 'answer', ''),
       case when s.name = 'Dev Kumar' then (k.position % 2 = 0) else (row_number() over (partition by a.id, k.student_id order by k.position) % 4 <> 0) end,
       a.date + time '18:20'
  from public.attendance_sessions a
  join public.students s on s.class_id = a.class_id and s.centre_id = a.centre_id
  join public.skills k on k.student_id = s.id and k.state <> 'not_started'
 where a.centre_id = '22222222-2222-2222-2222-222222222222' and a.date >= current_date - 21
   and a.class_id in ('33333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333331')
   and k.position <= 3;
insert into public.checks (centre_id, student_id, skill_id, kind, question, correct, created_at)
select s.centre_id, s.id, k.id, 'placement', jsonb_build_object('question', k.name, 'answer', ''), k.position = 1, now() - interval '4 days'
  from public.students s join public.skills k on k.student_id = s.id
 where s.centre_id = '22222222-2222-2222-2222-222222222222' and s.name = 'Riya Sharma' and k.position <= 2;
```

  Dev's `track_status` is set `not_on_track` with its reasons and `track_since` in the same block (the rules would say so from
  these checks at the next close; the seed states it so the list and Progress show it before one). Confirm after `supabase db
  reset`: `select s.name, count(*) filter (where c.correct) as right, count(*) as checks from checks c join students s on s.id =
  c.student_id group by s.name order by s.name` prints a row per Evening student and Hemanth. These figures are hand run 9's.

- [x] **Step 4:** `supabase gen types typescript --local > types.ts`; `bun check --only=db` green (the catalogue test sees the
  column; the RLS test passes). Commit, open PR 2, merge when green.

---

### Task 3: The API: the note's `tutorSays` (PR 3)

**Files:**
- Modify: `api/src/schemas.ts`, `api/src/prompts/note.ts`, `api/src/claude-fake.ts`, `api/test/schemas.test.ts`,
  `api/test/prompts.test.ts`, `api/test/v2.test.ts`

- [x] **Step 1: the failing tests:**

```ts
// schemas.test.ts
test("a note takes the tutor's own words, at most 300", () => {
  expect(MakeInput.safeParse({ ...noteBody, tutorSays: "Please ask Dev to show you the balancing steps." }).success).toBe(true);
  expect(MakeInput.safeParse({ ...noteBody, tutorSays: "x".repeat(301) }).success).toBe(false);
});
test("a sheet body naming a student is a 400", () => {
  expect(MakeInput.safeParse({ ...sheetBody, studentId: "a2b4…" }).success).toBe(false);
});
// prompts.test.ts
test("the note's prompt carries the tutor's words and asks for them", () => {
  const r = request({ ...noteInput, tutorSays: "Ask him to show you the balancing steps." });
  expect(r.text).toContain("The tutor adds: Ask him to show you the balancing steps.");
  expect(r.text).toMatch(/what the tutor adds/);
});
test("a note without the tutor's words asks nothing of them", () => {
  expect(request(noteInput).text).not.toMatch(/tutor adds/);
});
// v2.test.ts
test("a note with tutorSays reaches the fake and is recorded with it", async () => {
  const res = await app.request("/ai/make", post({ ...noteBody, tutorSays: "Ask him to read aloud." }));
  expect(res.status).toBe(200);
  expect(db.inputs.at(-1)).toMatchObject({ kind: "note", tutorSays: "Ask him to read aloud." });
});
```

  Run: `cd api && bun test`. Expected: the four new ones fail.

- [x] **Step 2: the change.** `schemas.ts`: the note object gains `tutorSays: z.string().min(1).max(300).optional()`.
  `prompts/note.ts`: after the attendance line, `input.tutorSays ? `The tutor adds: ${input.tutorSays}` : ""`; `ask()`
  gains the part `"what the tutor adds"` when present, placed last. `claude-fake.ts`: the note sample ends with the tutor's
  words when the text holds "The tutor adds:" (so the hand run shows them). `bun run check` green (tsc and tests).

- [x] **Step 3: commit, PR 3, merge; then `gh workflow run deploy`** (Task 16, step 1): 0026 pushed, the API at `main`'s head.

---

### Task 4: Domain: the kinds, the target and its rules, `Term`, the refusal, the templates' names (PR 4)

**Files:**
- Create: `Sources/Domain/Make/MakeKind.swift`, `Make/MakeTarget.swift`, `Make/MakeRules.swift`, `Make/MakeContent.swift`,
  `Reports/Term.swift`
- Modify: `Queue/OfflineRefusal.swift`, `Record/FigureSpec.swift`, `Plan/Artefact.swift`
- Test: `Tests/DomainTests/MakeKindTests.swift`, `MakeRulesTests.swift`, `TermTests.swift`, `OfflineRefusalTests.swift`,
  `ArtefactContentTests.swift`

**Interfaces:**
- Produces:

```swift
public enum MakeKind: String, CaseIterable, Hashable, Sendable {
    case sheet, workedExample = "worked_example", figure, noteToParent = "note", mock   // for a student or a group
    case brief, paper, homework, worksheet                                               // for you
    public var title: String   // "Sheet", "Worked example", "Figure", "Note to a parent", "Mock test", "Brief", "Question paper", "Homework", "Worksheet"
    public var symbol: String  // components.md 10.7
    public var line: String    // the board's lines
    public var isForSomeone: Bool          // the first five
    public var makeLabel: String           // "Make the sheet", …, "Write the note", "Make the mock"
    public var v1Kind: GenerationKind?     // paper, homework, worksheet → V1's form
}
public enum MakeTarget: Hashable, Sendable {
    case student(UUID), group(plan: UUID, number: Int), batch(UUID), classLevel(ClassLevel)
}
public struct MakeFor: Hashable, Sendable, Codable {   // kept in the artefact's content as made_for
    public let target: MakeTarget            // (Codable by a wire form: kind + id/number/level)
    public let title: String                 // "For Dev", "Group 1", "Evening batch", "Class 8"
    public let line: String                  // "Class 8 Science · Balancing equations"
}
public enum MakeRules {
    public static func level(for target: MakeTarget, register: any Register, groups: [PlanGroup], students: [UUID: Student]) -> ClassLevel?
    public static func skills(for target: MakeTarget, subject: String, books: [UUID: (chapters: [Chapter], skills: [Skill])], groups: [PlanGroup]) -> [String]
    public static func subjects(for target: MakeTarget, books: …, groups: [PlanGroup], batch: Classroom?) -> [String]
    public static func forWords(_ target: MakeTarget, register: any Register, groups: [PlanGroup], subject: String, skill: String?) -> MakeFor
    public static let sheetLengths: [(title: String, questions: Int)] = [("Short", 6), ("Medium", 10), ("Long", 15)]
    public static let levels: [(title: String, reason: String?)] = [("Easier", "easier"), ("As the record says", nil), ("Harder", "harder")]
    public static let tutorSaysLimit = 300
}
public struct Term: Hashable, Sendable {
    public enum Calendar: Hashable, Sendable { case standard, karnataka }
    public let schoolYear: Int; public let number: Int; public let calendar: Calendar
    public static func containing(_ day: Day, calendar: Calendar) -> Term
    public static func calendar(for boards: [Board?]) -> Calendar      // the most common; ties and none → standard
    public var months: [Period]; public var title: String; public var previous: Term; public var next: Term
    public func hasEnded(_ now: Day) -> Bool; public var fileStem: String  // "term-1-2026"
}
```

  `OfflineRefusal.Write.make` ("You're offline. Making material needs a connection."); `FigureSpec.Kind.title` ("Number
  line", "Fraction bar", "Place value", "Unit circle", "Triangle", "Labelled cell", "Food chain") and `Kind.matching(skill:)`
  (the plan's own matcher, made public); `Artefact.madeFrom: String?`, `Artefact.madeFor: MakeFor?` (read from `content.made_for`).

- [x] **Step 1: the failing tests** (the names the review focus pins; `SchoolSamples`' students and groups):

```swift
@Test func aStudentWithNoBookHasNoSkillsAndNoLevel() {
    let riya = Student.sample(name: "Riya", classLevel: nil)
    #expect(MakeRules.level(for: .student(riya.id), register: register([riya]), groups: [], students: [riya.id: riya]) == nil)
    #expect(MakeRules.skills(for: .student(riya.id), subject: "Mathematics", books: [:], groups: []) == [])
}
@Test func aStudentsSkillIsTheirCurrentOneInTheSubject() {   // the first not secure, by chapter then position
    #expect(MakeRules.skills(for: .student(dev.id), subject: "Science", books: [dev.id: devBook], groups: []) == ["Balancing equations"])
}
@Test func aGroupAcrossLevelsIsMadeAtItsHighestLevel() {
    let group = PlanGroup(number: 2, subject: "Mathematics", chapter: "Parts and wholes", skill: "Fractions on a bar", classLevels: [.two, .five], memberIDs: [sahil.id, riya.id], skillID: nil)
    #expect(MakeRules.level(for: .group(plan: plan, number: 2), register: register([sahil, riya]), groups: [group], students: byID) == .five)
    #expect(MakeRules.skills(for: .group(plan: plan, number: 2), subject: "Mathematics", books: [:], groups: [group]) == ["Fractions on a bar"])
}
@Test func aBatchTakesItsMostCommonLevelAndItsMembersCurrentSkills() { … == .eight; skills distinct, at most six }
@Test func aClassLevelSendsNoSkills() { #expect(MakeRules.skills(for: .classLevel(.eight), subject: "Science", books: [:], groups: []) == []) }
@Test func theForWordsNameTheTarget() {
    #expect(MakeRules.forWords(.student(dev.id), …, subject: "Science", skill: "Balancing equations") == MakeFor(target: .student(dev.id), title: "For Dev", line: "Class 8 Science · Balancing equations"))
    #expect(MakeRules.forWords(.classLevel(.eight), …, subject: "Science", skill: nil).title == "Class 8")
}
@Test func termTwoSpansTheNewYear() {
    let term = Term(schoolYear: 2026, number: 2, calendar: .standard)
    #expect(term.months.first == Period(year: 2026, month: 10) && term.months.last == Period(year: 2027, month: 3))
    #expect(term.title == "Term 2 · October to March" && term.fileStem == "term-2-2026")
}
@Test func theTermBeforeTermOneIsLastYearsTermTwo() { #expect(Term(schoolYear: 2026, number: 1, calendar: .standard).previous == Term(schoolYear: 2025, number: 2, calendar: .standard)) }
@Test func theKarnatakaYearEndsInApril() { #expect(Term(schoolYear: 2026, number: 2, calendar: .karnataka).months.last == Period(year: 2027, month: 4)) }
@Test func octoberIsTermTwoAndMayIsTermTwoOfTheYearBefore() {
    #expect(Term.containing(Day(2026, 10, 7)!, calendar: .standard) == Term(schoolYear: 2026, number: 2, calendar: .standard))
    #expect(Term.containing(Day(2026, 5, 3)!, calendar: .standard) == Term(schoolYear: 2025, number: 2, calendar: .standard))   // April and May belong to the year before's second term
}
@Test func theCentresCalendarIsTheCommonBoard() { #expect(Term.calendar(for: [.karnataka, .karnataka, .cbse, nil]) == .karnataka); #expect(Term.calendar(for: [.karnataka, .cbse]) == .standard) }
@Test func makesRefusalReadsOffline() { #expect(OfflineRefusal.words(for: .make).hasPrefix("You're offline.")) }
@Test func aFigureTemplateMatchesASkillByName() { #expect(FigureSpec.Kind.matching(skill: "Fractions on a bar") == .fractionBar) }
@Test func madeForRoundTripsInTheContent() { … encode a sheet content with made_for, decode → artefact.madeFor == the MakeFor }
```

  Run the Domain tests (`.superpowers/sdd/.../xt.sh DomainTests`). Expected: all fail to compile.

- [x] **Step 2: write Domain** to the interfaces above. `Term`: April and May belong to the year before's second term in both
  calendars (nothing is in session; the standard calendar's gap months). `made_for` is written beside the kind's own content
  keys (the content object gains one key; the kind's decoder ignores it; `Artefact.madeFor` reads it).

- [x] **Step 3:** tests green; `ErrorWordsTests` green on the new sentences. Commit, PR 4, merge.

---

### Task 5: Domain: `ProgressRules` and `ProgressCSV` (PR 5)

**Files:**
- Create: `Sources/Domain/Reports/ProgressRules.swift`, `Reports/ProgressCSV.swift`
- Test: `Tests/DomainTests/ProgressRulesTests.swift`, `ProgressCSVTests.swift`

**Interfaces:**

```swift
public struct ProgressInput: Hashable, Sendable {
    public let student: Student; public let chapters: [Chapter]; public let skills: [Skill]
    public let checks: [CheckRecord]; public let sessions: [AttendanceSession]; public let span: ProgressSpan; public let calendar: Calendar
}
public enum ProgressSpan: Hashable, Sendable { case month(Period), term(Term)
    public var months: [Period]; public var title: String; public var fileStem: String; public func hasEnded(_ now: Day) -> Bool }
public struct ProgressRow: Hashable, Sendable, Identifiable {
    public let id: UUID; public let name: String; public let initials: String; public let className: String
    public let status: TrackStatus; public let line: String; public let skillsSecure: Int; public let checks: Int; public let right: Int
    public let absences: Int; public let percent: Int?; public var percentText: String   // "41%" or "–"
}
public struct ProgressHero: Hashable, Sendable { public let skillsSecure: Int; public let rightText: String; public let notOnTrack: Int; public let notOnTrackLabel: String }
public enum ProgressSort: CaseIterable, Hashable, Sendable { case lowestFirst, highestFirst, byName; public var title: String }
public enum ProgressRules {
    public static func row(_ input: ProgressInput, className: String) -> ProgressRow
    public static func hero(_ rows: [ProgressRow], span: ProgressSpan, now: Day) -> ProgressHero
    public static func sorted(_ rows: [ProgressRow], by sort: ProgressSort) -> [ProgressRow]
}
public enum ProgressCSV { public static func fileName(_ span: ProgressSpan) -> String; public static func make(_ rows: [ProgressRow]) -> String }
```

- [x] **Step 1: the failing tests** (October 2026, `DayHeading.india`; a student's skills with `stateAt` inside and outside the
  span; checks dated inside and outside; sessions with marks):

```swift
@Test func skillsSecureCountOnlyThoseMadeSecureInTheSpan() { … two secure in October, one in September → row.skillsSecure == 2 }
@Test func rightIsRoundedAndPlacementsAreLeftOut() { … 5 of 12 checks right, two placements wrong → right 5, checks 12, percent 42 }
@Test func absencesCountTheSpansSessionsOnly() { … absent twice in October, once in September → 2; the line ends "· 2 absences" }
@Test func theLineLeavesOutZeroAbsences() { #expect(row.line == "3 skills secure · 41% right") }
@Test func aLadderStudentNamesTheirStepsInsteadOfSkills() { #expect(row.line == "Reading: Sentences · Numbers: To 99") }
@Test func aStudentWithNothingReadsNotKnownYet() { #expect(row.status == .notKnown && row.line == "No checks yet" && row.percentText == "–") }
@Test func aPlacedStudentReadsPlacedAndTheCount() { #expect(row.line == "Placed Wed 7 Oct · 2 checks so far") }
@Test func aMonthWithAttendanceAndNoChecksShowsAbsencesOnly() { #expect(row.line == "No checks yet · 3 absences" && row.percentText == "–") }
@Test func theHeroSumsTheRowsAndCountsNotOnTrack() {
    let hero = ProgressRules.hero(rows, span: .month(october), now: Day(2026, 10, 7)!)
    #expect(hero.skillsSecure == 38 && hero.rightText == "71%" && hero.notOnTrack == 2 && hero.notOnTrackLabel == "not on track")
}
@Test func anEndedTermsLabelSaysAtTheEnd() { #expect(ProgressRules.hero(rows, span: .term(term1of2026), now: Day(2026, 10, 7)!).notOnTrackLabel == "not on track at the end") }
@Test func theHeroWithNoChecksReadsADash() { #expect(hero.rightText == "–") }
@Test func lowestFirstPutsTheDashLastAndTiesByName() { … [41, 50, 50, nil] → Dev, Hemanth, Nikhil, Riya }
@Test func anArchivedStudentIsNeitherListedNorSummed() { … rows are built by the caller from active students; this test holds `hero` over rows without the archived one and the store test (Task 10) holds the list }
@Test func theCSVHasTheBoardsColumnsAndTheSpansName() {
    #expect(ProgressCSV.fileName(.month(october)) == "progress-2026-10.csv" && ProgressCSV.fileName(.term(term1of2026)) == "progress-term-1-2026.csv")
    #expect(ProgressCSV.make([devRow]).hasPrefix("\u{FEFF}Student,Class,Status,Skills secure,Checks,Right,Absences\r\nDev Kumar,Class 8 Science,Not on track,3,12,5,2"))
}
```

- [x] **Step 2: write the rules** to the interfaces. The ladder line: for a student whose chapters include ladder areas, each
  area's current step (`Ladder.currentStep` over the area's skill states) named when it is beyond the first; the absences
  follow. The CSV uses `CSV.make` as `FeesCSV` does (BOM, CRLF).

- [x] **Step 3:** tests green. Commit, PR 5, merge.

---

### Task 6: Data: `keepMade`, `made`, `mock(forExam:)`, the skills and chapters by centre, `tutorSays` (PR 6)

**Files:**
- Modify: `Data/Plans/PlansRepository.swift`, `SupabasePlansRepository.swift`, `FakePlansRepository.swift`, `PlanRows.swift`,
  `Data/Textbooks/TextbooksRepository.swift` and its two implementations, `Data/AI/AIRepository+Parents.swift`,
  `APIBodies+Parents.swift`, `AISamples+Parents.swift`, `FakeAIRepository.swift`
- Create: `Data/Reports/ProgressReader.swift`
- Test: `Tests/DataTests/PlanRowsTests.swift`, `FakePlansRepositoryMakeTests.swift`, `APIBodiesParentsTests.swift`, `ProgressReaderTests.swift`

**Interfaces:**

```swift
public extension PlansRepository {
    /// Kept from Make: plan null, group 0, the student for a student's, the exam for a mock's, made_from 'make'.
    func keepMade(_ artefact: NewArtefact, for target: MakeFor, student: UUID?, exam: UUID?, centre: UUID) async throws -> Artefact
}
public protocol PlansRepository {  // adds
    func made(centre: UUID) async throws -> [Artefact]            // made_from = 'make', newest first, 50
    func mock(forExam item: UUID, centre: UUID) async throws -> Artefact?   // the existing `mock(for:centre:)` reused
}
public protocol TextbooksRepository {  // adds
    func skills(centre: UUID, students: [UUID]) async throws -> [Skill]
    func chapters(centre: UUID, students: [UUID]) async throws -> [Chapter]
}
public struct NoteRequest { … public let tutorSays: String? }   // body key tutorSays, left out when nil
public struct ProgressReader: Sendable {
    public init(textbooks: any TextbooksRepository, record: any RecordRepository, attendance: any AttendanceRepository)
    public func read(_ students: [Student], span: ProgressSpan, centre: UUID, calendar: Calendar) async throws -> [UUID: ProgressInput]
}
```

- [x] **Step 1: the failing tests:** `PlanRowsTests.aRowWithMadeFromAndMadeForDecodes`; `FakePlansRepositoryMakeTests.keepMadeIsListedByMadeNewestFirst`,
  `.aRegenerateReplacesItsPredecessorInMade` (the fake's `made` hides a row another row's `regeneratedFrom` names);
  `APIBodiesParentsTests.aNoteBodyCarriesTutorSaysOnlyWhenGiven`; `ProgressReaderTests.readsEveryStudentsSkillsChecksAndSessionsTogether`
  (the fakes record one call per table, not per student) and `.aFailedSkillsReadThrows`.

- [x] **Step 2: write Data.** `SupabasePlansRepository.made` selects `artefacts` where `made_from = 'make'` ordered by
  `created_at desc` limit 50 and hides regenerated predecessors on the phone (`Artefact.hidingRegenerated()`); `keepMade`
  calls `keep_artefact` with `p_made_from: "make"` and `content.made_for`; the Supabase textbooks reads filter `student_id in
  (…)` by centre. `ProgressReader` reads the four together (`async let`) as `NoteRecordReader` does.

- [x] **Step 3: the write proofs** against the local stack (a throwaway test with an in-memory session, `ios/CLAUDE.md`'s rule):
  `keepMade` inserts a row with `made_from = 'make'` and reads back through `made`; the seven-argument path still works
  (the plan's own `keep`). Tests green; commit; PR 6 is Tasks 6 and 7 together (the home needs the reads).

---

### Task 7: Make something: the home, Recent and History, More's row, Today's Create row (PR 6)

**Files:**
- Create: `Features/Make/MakeHomeView.swift`, `MakeStore.swift`, `MakeStore+Recent.swift`, `MakeWords.swift`, `MakeActions.swift`
- Modify: `Features/Make/HistoryView.swift` (both lists, grouped by month), `AppShell/RootView+Make.swift`, `MoreView.swift`,
  `RootView+Today.swift`, `LaunchState.swift`, `RootView+LaunchStates.swift`, `Fixtures+Make.swift` (new), `TabsState.swift`
  (`Route.makeForm(MakeKind)`); remove `AssistantView.swift`
- Test: `Tests/MakeTests/MakeStoreTests.swift`, `AppShellTests/LaunchStateTests.swift`, `RoutesTests.swift`

**Interfaces:**
- Produces: `MakeStore` (per centre on the shell: `recent: [MakeRow]`, `history`, `loadHistory()`, `inFlight`, `onMade`),
  `MakeRow` (`id`, `kind: MakeKind?`, `symbol`, `title`, `line`, `opens: .artefact(UUID) | .generation(UUID)`),
  `MakeActions` (`openForm(MakeKind)`, `openArtefact(UUID)`, `openResult(UUID)`, `openHistory`, `openV1Form(GenerationKind)`).

- [x] **Step 1: the failing tests:**

```swift
@Test func recentListsMakesArtefactsAndV1ResultsTogetherNewestFirstThree() async { … a Make sheet 16:40, a V1 paper 16:35, a Make brief 16:30, a Make mock 16:20 → three rows: sheet, paper, brief }
@Test func aRowsLineNamesTheKindTheTargetAndTheTime() { #expect(row.line == "Sheet · Group 1 · today, 16:40"); #expect(mockRow.line == "Mock · Dev Kumar · today, 16:40") }
@Test func makeItAgainFromRecentReplacesTheRowAndKeepsTheRecord() async { … the fake keeps a regenerate; `recent` shows the new id once and not the old; the fake's rows hold both }
@Test func historyGroupsBothByMonth() async { … }
@Test func theEmptyRowShowsOnlyOnceHistoryHasLoaded() async { … }
@Test func historyOpensFromItsCopyOffline() async { … the CachedRead as V1's }
@Test func moreOpensMakeAndTodaysCreateRowOpensMake() { #expect(RootView.aiRoutes(for: .make) == [.make]); #expect(RootView.todayAIRoutes == [.make]) }
```

- [x] **Step 2: the home** (P10-Make): `BackRow("Make something", action: ("History", …))`, the intro `Text` in `intro`
  `text2`, the section "For a student or a group" (`Card` of five `ToolRow`s by `MakeKind`), "For you" (four), Recent (the
  Phase 6 Recent card with `ResultRow`s and See all, or the empty row), the AI line (`MakeWords.homeLine`, V1's words). Each
  row opens `.makeForm(kind)`; the V1 three open `.aiForm(v1Kind)` (their forms unchanged). The home reads
  `store.loadHistory()` on appear (`prepare()` reads the register first, as V1's). `MoreView`'s row opens `.make`; Today's
  Create row opens `.make`.

- [x] **Step 3: the launch states** `make` (both), `make-empty`, `today-ai`, `more`; `ai-assistant` and `ai-assistant-empty`
  removed from `LaunchState` and `tools/shots.ts`'s list if it has one; `LaunchStateTests` updated. `bun shots make`, `make-empty`,
  `today-ai`, `more` → the pictures; compare with the boards; `bun pr-shots`. Commit, PR 6, merge.

---

### Task 8: The kinds' forms, the For sheet, the choosers, the call, the made artefact's screen (PR 7)

**Files:**
- Create: `Features/Make/MakeFormView.swift`, `MakeFormStore.swift`, `MakeFormStore+Call.swift`, `ForSheet.swift`,
  `ForStore.swift`, `SkillChooserSheet.swift`, `ExamChooserSheet.swift`
- Modify: `Features/Artefacts/ArtefactWords.swift`, `SheetStore.swift`, `SheetStore+Again.swift`, `WorkedExampleStore.swift`,
  `FigureStore.swift`, `BriefStore.swift`, `MockStore.swift` (the eyebrow from `madeFor` with no plan; a regenerate keeps
  `madeFrom` and `madeFor`), `NoteStore.swift`, `NoteStore+Make.swift` (`tutorSays`), `AppShell/RootView+Make.swift`,
  `RootView+Artefacts.swift`, `Fixtures+Make.swift`, `LaunchState.swift`
- Test: `Tests/MakeTests/MakeFormStoreTests.swift`, `ForStoreTests.swift`, `ArtefactsTests/ArtefactWordsTests.swift`,
  `SheetStoreAgainTests.swift`, `NoteStoreTests.swift`

**Interfaces:**

```swift
@MainActor @Observable public final class MakeFormStore {
    public init(kind: MakeKind, context: MakeContext)            // workspace, register, plans, textbooks, schoolItems, ai, online, now, calendar, defaults
    public var target: MakeTarget?; public var subject: String; public var skill: String; public var length: Int; public var levelReason: String?
    public var keyAtEnd: Bool; public var template: FigureSpec.Kind?; public var chapter: String; public var exam: ExamChoice?; public var tutorSays: String
    public var level: ClassLevel?                                  // from the target, or chosen for a class level
    public var skillChoices: [String]; public var chapterChoices: [String]; public var subjectChoices: [String]
    public var canMake: Bool; public var helper: String            // "Made against Group 1's record. …"
    public var stage: Stage                                        // .form, .making, .failed(String, canRetry: Bool)
    public func make() async -> MakeOutcome                        // .made(Artefact) | .opensNote(UUID, Day) | .opensExisting(UUID) | .refused
    public func cancel()
}
@MainActor @Observable public final class ForStore { public var segment: ForSegment; public var groups: [ForGroupRow]; public var batches: [ForBatchRow]; public var levels: [ClassLevel]; public func load() async }
```

- [x] **Step 1: the failing tests:**

```swift
@Test func makeWaitsForALevelAndATopic() { … Riya (no level), no skill → canMake false; level set, skill typed → true }
@Test func aSheetForAStudentSendsNoStudentAndNeedsNoConsent() async {
    // Dev's parent has not agreed
    let outcome = await store.make()
    #expect(ai.sheetRequests.last == SheetRequest(classLevel: .eight, subject: "Science", skills: ["Balancing equations"], questions: 10, forHomework: false, reason: nil))
    #expect(ai.lastBodyHadNoStudent)   // the fake records the body's keys
    guard case .made = outcome else { Issue.record("not made"); return }
}
@Test func aGroupsSheetSendsTheGroupsLevelAndSkill() async { … group 2 (class 5 and 2) → classLevel .five, skills ["Fractions on a bar"]; the artefact's madeFor.title == "Group 2" }
@Test func lengthAndLevelReachTheRequest() async { … Long, Easier → questions 15, reason "easier" }
@Test func theHelperNamesTheTarget() { #expect(store.helper == "Made against Group 1's record. A sheet made for a class alone follows the class's chapters.") }
@Test func aMadeSheetIsKeptWithMadeFromAndOpens() async { … plans.made(centre:) has it; madeFrom == "make"; outcome .made(artefact) }
@Test func anExamWithAMockOpensItWithoutACall() async { … exam16 has a mock in the fake → .opensExisting(id); ai.mockRequests.isEmpty }
@Test func aTypedMockHasNoExam() async { … .made(artefact) with schoolItemID nil and the typed title }
@Test func aFigureWhoseSpecFailsIsRefusedInWords() async { … the fake answers a fraction bar with shaded > parts → .failed("…"), nothing kept }
@Test func theFigureTemplateFollowsTheSkill() { store.skill = "Fractions on a bar"; #expect(store.template == .fractionBar) }
@Test func aNoteOpensPhase14sNoteWithTheTutorsWords() async { … .opensNote(dev.id, noteDay); context.noteWords[dev.id] == "Ask him to…" }
@Test func aNoteForAStudentWithoutConsentIsRefusedBeforeAnyCall() async { … Phase 14's words; ai.noteRequests.isEmpty }
@Test func offlineMakeIsRefusedAndTheFormKept() async { … online false → .refused; store.alert == OfflineRefusal.words(for: .make); fields unchanged }
@Test func leavingTheFormDoesNotLoseTheCall() async { … the call is MakeStore's task; the artefact lands in recent }
@Test func theLastTargetOfAKindIsRemembered() { … defaults }
// ForStoreTests
@Test func groupsAreTodaysPlansGroups() async { … two batches today, one with a plan → its groups with "Dev, Meher, Nikhil · Class 8 Science · today's plan" }
@Test func withNoPlanTodayTheGroupSegmentIsEmptyInWords() async { #expect(store.groups.isEmpty && store.groupsEmptyLine == "Open Today to make the plan.") }
// ArtefactWordsTests
@Test func aMakeArtefactsEyebrowNamesItsTarget() { #expect(ArtefactWords.eyebrow(madeFor: MakeFor(target: .student(dev.id), title: "For Dev", line: "Class 8 Science · Balancing equations")) == "For Dev · Class 8 Science · Balancing equations") }
// SheetStoreAgainTests
@Test func makeItAgainOnAMakeSheetKeepsMadeFromAndTheTarget() async { … }
// NoteStoreTests
@Test func theTutorsWordsGoInTheRequestAndAreKept() async { #expect(ai.noteRequests.last?.tutorSays == "Ask him to read aloud."); content.tutorSays == … }
```

- [x] **Step 2: the form** (P10-Make-Form): `BackRow(kind.title)`, the hero card with the kind's tiles: For (`PickerTile`,
  "Group 1 · Dev, Meher, Nikhil"; helper "A student, a group, a batch, or a class on its own."), Subject (`PickerTile` with
  the chooser of the target's subjects, or typed), Skill or topic (`PickerTile` → `SkillChooserSheet`: the record's skills
  then "Type a topic"; helper "From the record, or type a topic."), Length (`Segmented`), Level (`Segmented`), Key at the end
  (the Phase 6 switch row with "For you; left out of what you share"); the worked example's and figure's tiles (Template
  `PickerTile` with the seven names); the brief's (Class wheel, Subject, Chapter chooser); the mock's (Student, Exam →
  `ExamChooserSheet`: the student's exams to come nearest first, "Type it"); the note's (Student, What to say `NotesWell` 300).
  The helper under the card; the footer `FooterButton(kind.makeLabel)` with the creating line under it. Making: the Phase 6
  creating card ("Making the sheet"); failed: `ErrorRow` with Retry. The For sheet (P10-Make-For): `FittedSheet`, `SheetHeader`
  "For" with Cancel, the four-segment `Segmented`, the rows per segment (`ChoiceRow`s: the student picker's rows; the group
  rows "Group 1 · Chemical reactions" / "Dev, Meher, Nikhil · Class 8 Science · today's plan"; the batches; the levels), the
  footnote "Today's groups. A sheet for a group is made at the group's level; for a class alone, at the class's."

- [x] **Step 3: the made artefact's screen.** `MakeOutcome.made` → AppShell pushes `.artefact(id)` (the Artefacts screen by
  kind); `.opensNote` → `.note(student, noteDay)` with the words handed through `NoteContext.tutorSays`; `.opensExisting` →
  `.artefact(id)`. The Artefacts stores read `madeFor` for the eyebrow when `plan` is nil; `SheetStore+Again` passes `madeFor`
  and `madeFrom` to `keepMade` on a regenerate.

- [x] **Step 4: the launch states** `make-sheet`, `make-for`, `make-for-student`, `make-worked-example`, `make-figure`,
  `make-brief`, `make-mock`, `make-note`, `make-making`, and `sheet` opened on a Make sheet for the eyebrow picture; the
  pictures; `ErrorWordsTests` on the new sentences. Commit, PR 7, merge.

---

### Task 9: Check a paper under Make: the Scheme tile and the chooser; U22, U23 (PR 8)

**Files:**
- Modify: `Features/Make/CheckIntroView.swift`, `CheckSchemeView.swift`, `CheckStore.swift`, `CheckPagesView.swift`,
  `AppShell/RootView+Make.swift` (`checkView`: the chooser route), `TabsState.swift` (`Route.checkSchemeChooser(UUID)`),
  `Fixtures+AI.swift`, `LaunchState.swift`
- Create: `Features/Make/CheckStore+Schemes.swift`
- Test: `Tests/MakeTests/CheckStoreTests.swift`, `CheckSchemeChooserTests.swift`

**Interfaces:**

```swift
extension CheckStore {
    public var schemeChoices: [SchemeChoice]       // the student's mocks (with "the mock" lines) then the centre's papers (U22: "Question paper · Class 8 · 20 marks · Sun 11 Oct, 16:40")
    public func loadSchemes() async                 // plans.artefacts(for: the student's exams) + Make's mocks for the student + History's papers
    public var schemeTitle: String                  // "Unit test 3 · the mock", a paper's title, "Type a scheme"
    public var schemeChosenOnIntro: Bool            // pages go straight to the marks
    public var pagesHeading: String                 // "2 pages", "No pages" (U23)
}
```

- [x] **Step 1: the failing tests:**

```swift
@Test func theChooserListsTheStudentsMocksThenThePapers() async { … Dev: exam16's mock first ("Science unit test 3 · the mock"), then the papers }
@Test func aMockChosenOnTheIntroSkipsTheSchemeStep() async { store.scheme = .mock(…); #expect(store.schemeChosenOnIntro && store.skipsScheme) }
@Test func changingTheStudentClearsAMockSchemeAndKeepsAPaper() { … }
@Test func aMocksKeyStillNeedsTheStudentsConsent() async { … Phase 13's words before any call }
@Test func twoPapersOnOneTopicShowTheirDayAndTime() { #expect(store.paperLine(a) != store.paperLine(b)) }   // U22
@Test func noPagesReadsNoPagesAndTheFooterIsOff() { store.removePage(at: 0); store.removePage(at: 0); #expect(store.pagesHeading == "No pages" && !store.canContinue) }   // U23
@Test func withNoSchemeChosenThePagesStepStillLeadsToTheScheme() { … V1's path kept }
```

- [x] **Step 2: the intro** (P10-Make-Check): the hero's title and line from the board; the card: Student `PickerTile`, the
  class line, Scheme `PickerTile` (helper "A mock or paper made here, with its key; or type a scheme."); the notice (the
  board's words: "The photos go to our AI service to be read. We keep no copy; the service deletes them within 30 days."
  and "Nothing is saved until you have checked every mark and tapped Save."); Take a photo, Choose from Photos; the AI line.
  The Scheme tile pushes `.checkSchemeChooser(id)`: `CheckSchemeView` in chooser mode (the first segment titled "A mock or
  paper made here", its rows `PaperChoiceRow`s with U22's lines, the typed well under "Type it", the footer "Use this scheme"
  which pops back to the intro). `CheckPagesView`'s Check goes to `.checkResult` when a scheme is chosen, else `.checkScheme`.

- [x] **Step 3: the states** `check-intro` (Dev, the mock chosen), `check-scheme-chooser`, `check-pages-empty`; the pictures;
  `plan/ui-polish.md`'s U22 and U23 move to Done in Task 17. Commit, PR 8, merge.

---

### Task 10: Reports' Progress by month and by term, the sort, the CSV; U26 (PR 9)

**Files:**
- Create: `Features/Fees/ReportsStore+Progress.swift`, `Features/Fees/ReportsCache.swift` (U26), `DesignSystem/Components/ProgressRows.swift`
- Modify: `Features/Fees/ReportsStore.swift`, `ReportsView.swift`, `ExportSheet.swift`, `AppShell/RootView+Fees.swift`,
  `Dependencies.swift`, `Fixtures+Progress.swift` (new), `LaunchState.swift`
- Test: `Tests/FeesTests/ReportsProgressStoreTests.swift`, `ReportsCacheTests.swift`, `DesignSystemTests/ProgressRowsTests.swift`

**Interfaces:**

```swift
extension ReportsStore {
    public enum Segment { case fees, attendance, progress }
    public enum Span { case month, term }                       // the Month | Term control under Progress
    public var span: Span; public var sort: ProgressSort; public var progressSpan: ProgressSpan   // .month(month) or .term(term)
    public var progressRows: [ProgressRow]; public var progressHero: ProgressHero?; public var spanTitle: String
    public func previous() async; public func next() async      // step the month or the term by the segment
}
public struct ProgressRow: View { init(initials:, name:, status: StatusWord.TrackKind, statusWord:, line:, percent:, action:) }
public struct ProgressHero: View { init(skillsSecure:, rightText:, notOnTrack:, notOnTrackLabel:) }
```

- [x] **Step 1: the failing tests:**

```swift
@Test func progressReadsEveryActiveStudentTogetherAndSumsTheRows() async { … the fakes' reads counted; hero.skillsSecure == rows sum }
@Test func theTermIsTheCentresCalendarAndStepsByTerm() async { … Karnataka majority → "Term 1 · June to October"; previous() → Term 2 2025 }
@Test func steppingBackFromTermOneShowsLastYearsTermTwo() async { … }
@Test func lowestFirstIsTheDefaultAndTheMenuOffersThree() { #expect(store.sort == .lowestFirst && ProgressSort.allCases.count == 3) }
@Test func archivingAStudentRemovesTheirRowAndTheirFigures() async { … load, archive Dev in the fake register, load → no Dev row; hero differs by his figures }
@Test func aCentreWithNoChecksStillLoads() async { … rows with "No checks yet"; hero.rightText == "–" }
@Test func theCSVIsTheProgressRowsInTheSpansFile() { #expect(store.export(.progress).fileName == "progress-2026-10.csv") }
@Test func aMonthMoveDropsAStaleAnswer() async { … the load generation }
@Test func theReportOpensFromItsCopyOfflineAndSaysSo() async { … U26: ReportsCache per segment and span; the status line "Offline. Showing what was saved at 14:10." }
@Test func theNumbersMatchTheSeed() { /* documented, not a unit test: hand run 9 */ }
```

- [x] **Step 2: the screen** (P10-Reports-Progress, -Term): `Segmented` Fees | Attendance | Progress; under Progress a second
  `Segmented` Month | Term; the `MonthHeader` shows the month or "Term 1 · June to September" and steps by the segment;
  `ProgressHero` (the Kit's hero card with three `numberTile` columns in `ok`, `text`, `overdue`); the section header
  "10 students" with the sort menu on the right ("Lowest first", the Students list's menu pattern); the `Card` of
  `ProgressRow`s (avatar 40, the name, `StatusWord` and the line, the percent in `numberRow`, a chevron that opens the
  student on the Students tab). The export sheet's third `ChoiceCard` ("Progress", "progress-2026-10.csv · Student, class,
  status, skills secure, checks, right, absences"). U26: the three reports keep a copy per segment and span
  (`CachedRead`, `cache-<centre>-reports-<segment>-<span>.json`); offline the copy shows with the status line.

- [x] **Step 3: the states** `reports-progress`, `reports-progress-term`, `reports-progress-sort`, `reports-export`; the
  fixtures' students with the statuses the boards show (decision 20); the pictures. Commit, PR 9, merge.

---

### Task 11: The Kit's Phase 10 rows (PR 10)

**Files:**
- Create: `DesignSystem/Kit/KitPhase10.swift`, `Features/Artefacts/Figures/FigurePreviews.swift`
- Modify: `DesignSystem/Kit/KitView.swift` (`Section.phase10`, `figures`), `AppShell/RootView+LaunchStates.swift` (the Kit
  with Artefacts' previews), `LaunchState.swift`
- Test: `Tests/DesignSystemTests/KitPhase10Tests.swift` (the section exists and takes the figures), `AppShellTests/KitFiguresTests.swift`
  (the seven previews are the seven templates, each passing `validate()`)

- [x] **Step 1: the failing tests**, then the section: each group under its eyebrow as 10.7 lists them (decision 19), built
  from the existing parts (`Chip`, `StatusWord`, `StateMark`, `KindChip`, `ChapterRow` open with `SkillRow`s, `PlanLineRow`,
  `CheckRow` with `PlanChecklistRow`s and the pair in both states, `LadderRow`, `TrendCard`, the figures handed in, the board
  view's type sample). `kit-phase10` both appearances; the pictures against P10-Kit-Dark and -Light. Commit, PR 10, merge.

---

### Task 12: The polish rows the owner took (PR 11, three pull requests by screen group)

The owner's answer (2026-10-11): U17, U18, U20, U21, U22, U23, U26, U32, U40, U34, U11 and U19. U22 and U23 are PR 8's (Task
9); U26 is PR 9's (Task 10). The nine others, by `plan/ui-polish.md`'s "How it works": a test where there is logic, the
pictures of each changed state in both appearances, the row to Done with its pull request (Task 17).

**PR 11a `phase-15/polish-note-forms` (after PR 7): U17, U18, U20, U21**

- [x] **U17:** the progress note's observations counter reads "135 / 2000" as P6-Form-ProgressNote draws it, not "80 of 2,000".
  Failing test: `NotesWellTests.theCounterReadsSlashAndNoGroupingAtTheNotesLimit` (`NotesWell.counterText(135, limit: 2000)
  == "135 / 2000"`); the Kit's own counter for the shorter wells is unchanged. State `ai-note` (both). No board (the board's own text).
- [x] **U18:** the Send the note sheet sits under the nav row as P6-ProgressNote-Send draws it. The sheet's `boardDetents`
  fraction from the board's top (a number, in the view with its source line). State `ai-note-send`. No board.
- [x] **U20:** the centre's consent sheet reached from a note speaks of a note, not a photo: a `ConsentSheet(kind: .note)` with
  the sentences "Before the first note" and "What you write about the student goes to our AI service to be put into words
  …" in the shape of the photo's. The words are P15-Consent-Note's (row 25, approved 2026-10-11). Failing test: `AIStoreTests.theConsentSheetForANoteSpeaksOfNotes`. State `ai-note-consent`.
- [x] **U21:** "Couldn't create the homework." and "Couldn't create the worksheet." fit one line as the board's "the paper."
  does: the failure row's title shortened to "Couldn't create it." for the two longer kinds (the line under it names the
  reason), or the row given the width the board gives it; whichever keeps the board's two-line shape at the default size.
  Failing test: `AIStoreGenerateTests.aFailedHomeworkTitleFitsTheRow` (the title's count at or under "Couldn't create the
  paper."'s). State `ai-generate-failed` with the homework kind.

**PR 11b `phase-15/polish-glass` (any time after PR 1): U32, U40**

- [x] **U32, U40:** `statusBarGlass()` on every pushed screen that scrolls (Attendance History, a student's month, Schedule,
  Tasks, Classes, a class, a student, a student's fees, Payments, Reports, Account, Delete account, Pending changes, and the
  student's page's parent row), U24's pattern. Failing test: `AppShellTests.StatusBarGlassUseTests` reads the sources of the
  pushed screens for the modifier (as `CalendarPopoverUseTests` holds the popover). States `history`, `student-record`
  scrolled, `reports`, `account` (one picture each, scrolled, dark). No board (U24's).

**PR 11c `phase-15/polish-states` (after PR 7): U34, U11, U19**

- [x] **U34:** the Students tab's empty card stacks Add a student and Scan paper register at full width as P10-Students-Empty
  draws them (the Kit's empty state keeps its side-by-side form elsewhere). State `students-empty` (both).
- [x] **U11, U19:** the launch states `today-adding-task` and `today-ai` scroll to their sections as the boards draw them (a
  `ScrollViewReader` anchor set by the launch state in the fixtures; no change for a tutor). States `today-adding-task`,
  `today-ai`.

---

### Task 13: The website's trust page (PR 12, after its board)

**Files:**
- Create: `docs/design/mockups/P15-Web-Trust-1280-Dark.dc.html` and the three twins (390, light), `web/app/trust/page.tsx`,
  `web/content/trust.ts`
- Modify: `docs/design/directions/canvas.json`, `information-architecture.md` ("Phase 15 boards": the trust page's claims
  table row), `web/content/privacy.ts` (the consent facts), `web/content/site.ts` (the nav), `web/test/unit/pages.test.ts`,
  `words.test.ts`, `web/test/export/*`, `tools/web-smoke.ts` (five pages)

- [x] **Step 1: the board** `P15-Web-Trust*` (row 25, approved 2026-10-11, the claims table in `information-architecture.md`).
- [x] **Step 2: the failing tests** (`pages.test.ts`: `/trust` exports with its heading and the `tc-commit` meta; `words.test.ts`:
  no banned word, no vendor name on `/trust`; the privacy page's new paragraph present), then the page and the content,
  `bun check --only=web` green, `bun web-shots --pages /trust,/privacy`, the pictures by `bun pr-shots`. Commit, PR 12, merge;
  `gh workflow run deploy-web` (Task 16); the smoke finds five pages.

---

### Task 14: The hand runs (D32), after each pull request they name (main)

By `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed, signed in as Meera, each write confirmed
in the database, each screenshot kept in `.shots/run/` and attached to the phase's issue ("Phase 15 hand run"); the local API
with `AI_FAKE=1` except the cost run. Today's groups need today's plan: open Today on a meeting day first (the Evening batch
meets Monday to Friday; on a weekend move its `meeting_days` by psql and put it back after).

| Run | After PR | Through the screens | Confirm |
|---|---|---|---|
| 1 A sheet for a group | 7 | More → Make something → Sheet → For → Group → Group 1 → Subject Science → Skill from the record → Medium → As the record says → Make the sheet → "Making the sheet" → the sheet screen (eyebrow "Group 1 · Class 8 Science · …") → Share as PDF → Key → Back → Make: Recent shows it first | `select kind, plan_id, student_id, made_from, content->'made_for' from artefacts order by created_at desc limit 1` (sheet, null, null, make, Group 1); `select kind, input from ai_generations order by created_at desc limit 1` (sheet; the input has `classLevel`, `skills`, no student key) |
| 2 A sheet for a student | 7 | Make → Sheet → For → Student → Dev (his parent has not agreed) → Make the sheet → made; eyebrow "For Dev · …" | `artefacts.student_id` = Dev; `ai_generations.input` carries no `studentId`, no name; no consent asked |
| 3 A class-level paper, no student data | 7 | Make → Question paper → Class 8 (the wheel) → Science → Create the paper → the result | `ai_generations` kind paper: `input` has `classLevel` and `subject` only; `student_id` null |
| 4 A worked example for a batch; a figure for a class | 7 | Worked example → For → Batch → Evening batch → Science → the skill → Make → the steps; Figure → For → Class → Class 5 → Mathematics → "Fractions on a bar" → Template Fraction bar → Make → the figure drawn | two artefacts, made_from make; the figure's content passes (the screen draws it) |
| 5 A brief | 7 | Brief → Class 8 → Science → Chemical reactions → Make → the brief with Copy and Share | artefact kind brief, made_from make |
| 6 A note to a parent from Make | 7 | Note to a parent → Diya (consent) → What to say "Please ask her to read the chapter aloud" → Write the note → the Hindi note with the English beside, the tutor's words in it → Send on WhatsApp → Open WhatsApp → back: Sent | `artefacts` kind note, content->>'tutor_says'; `message_log` kind note, hi, whatsapp_link; the `ai_generations` note input has `tutorSays` |
| 7 A note for a student without consent | 7 | Note to a parent → Dev → Write the note → refused in Phase 14's words (no call) | no `ai_generations` row |
| 8 A mock from Make, then its marking | 7, 8 | Mock test → Dev → Science unit test 3 → Make the mock → the mock (eyebrow "Dev Kumar · Science unit test 3 · Fri 16 Oct") → Mark from a photo → the consent words (Dev's parent) → Students → Dev → Consent → recorded → back → Mark from a photo → two drawn pages → the marks → Save → the exam's page shows the score; School → the exam → the mock is this one (no second) | `artefacts` kind mock, school_item_id = the exam, made_from make; `marks` row with artefact_id and school_item_id; `ai_generations` check_paper with the mock's key |
| 9 Check a paper from Make with the Scheme tile | 8 | More → Check a paper → Hemanth → Scheme → "A mock or paper made here": the paper from run 3 (its line with the day and time, U22) → Use this scheme → the tile reads the paper → Take a photo (two drawn pages) → the marks straight away → Save to Hemanth's notes → Undo | `students.notes` for Hemanth before and after; the `ai_generations` check_paper input names the paper's key |
| 10 Progress for the month | 9 | More → Reports → Progress → October: the hero and the rows → Lowest first → By name → a row → the student's page | the hero's three numbers and each row equal `select s.name, count(*) filter (where k.state = 'secure' and k.state_at >= date_trunc('month', now())) …`, the checks query of Task 2 step 3 restricted to the month, and `select count(*) from attendance_marks m join attendance_sessions a on a.id = m.session_id where m.status = 'absent' and a.date >= date_trunc('month', current_date)` per student; the screenshot beside the query's output in the issue |
| 11 Progress for a term, and the CSV | 9 | Term → "Term 2 · October to March" (the current term) → previous → "Term 1 · June to September" (ended: "not on track at the end") → Share → Progress → the CSV opened in Files | the term's query (the same three with the term's dates); the CSV's rows equal the screen |
| 12 Made again from Recent | 7 | Make → Recent → the sheet from run 1 → Make it again → Easier → the new sheet → Back → Recent shows one row for it (the new) | two `artefacts` rows, the second's `regenerated_from` the first, both made_from make |
| 13 The Kit and the forms' words | 10 | `bun shots kit-phase10 --appearance both`; `bun shots make-*` | none |
| 14 Offline | 7, 9 | The gateway stopped → Make → Sheet → Make the sheet → the alert "You're offline. …" with the form kept; Recent from its copy; Reports → Progress from its copy with the offline line (U26) → `docker start` | nothing written while stopped |
| 15 The trust page | 12 | `bun web-shots --pages /trust,/privacy`; after the deploy `curl -s https://tutorcentral.in/trust \| grep -c tc-commit` | the smoke green |

---

### Task 15: The cost run (D64) and the price sheet (main)

- [x] **Step 1 (after PR 9 and the hand runs; the owner's standing approval; about ₹20):** `supabase db reset`; the local API
  **without** `AI_FAKE`; Make: a sheet for Group 1 (class 8, Sonnet) and a sheet for Group 3 (class 2, Haiku), a worked
  example, a figure (fraction bar), a brief, a mock for Dev's exam, a note for Diya with What to say (Haiku), a question
  paper for class 8 (V1, Sonnet), then Check a paper with the mock's key on two photographed pages (Opus). `bun cost
  --since 1h`; the figures per kind into the record's table, and `PriceSheet.typical`'s rows updated where a kind's average
  moved (a test reads it).
- [x] **Step 2:** the record writes calls, tokens and rupees per kind, what a tutor's ad hoc sheet costs against the plan's,
  and the figure for the "As built".

---

### Task 16: The deploys, the review, TestFlight (main)

- [x] **Step 1 (after PR 3):** `gh workflow run deploy`; the summary shows 0026 pending, pushed, nothing after; the smoke green;
  the run id into `STATE.md`'s Production.
- [x] **Step 2 (after PR 12):** `gh workflow run deploy-web`; `tools/web-smoke.ts` finds the five pages at the commit.
- [x] **Step 3: the review:** a reviewer pass over the merged pull requests with `superpowers:requesting-code-review` on
  Fable 5.1 (fresh context; two reviewers: the app; the API, database, web and tools), with this plan's Review focus and the
  ledger's rulings. Each finding of any grade (D68) is fixed with a test that failed first, in a fix pull request before the
  TestFlight build; none is deferred.
- [x] **Step 4:** `gh workflow run testflight` (the hosted database has nothing pending); the build number from the run; it
  is the round's candidate (decision 27); the owner installs it with the other builds (D68).

---

### Task 17: The documents of the build (main)

- [x] One commit to `main` (D12) when the build is reviewed: `plan/phase-15-make-and-polish.md` "As built, the build" (Make,
  Check a paper under Make, Progress, the Kit, the polish rows done, the trust page, the cost measured, where the build moved
  from this plan and why); `plan/ui-polish.md` (the rows taken to Done with their pull requests; U36 to Done with #133;
  anything seen); `docs/design/information-architecture.md` ("Phase 15 boards": the trust page; 10.7's launch states as built;
  the retired `ai-assistant` states), `components.md` ("As built in Phase 15" under 10.7 and 10.4), `design-tokens.md`
  ("Numbers in code": the sheet's lengths 6, 10, 15; What to say 300; the term calendars; Recent's 50); `ios/CLAUDE.md`
  (the module `Make`; the Kit's figures; Make's artefacts have no offline copy), `api/CLAUDE.md` (`tutorSays`),
  `supabase/CLAUDE.md` (0026; the seed's checks), `web/CLAUDE.md` (`/trust`), `CLAUDE.md` where a rule changed;
  `docs/testing/device-tests.md` (T15: Make's Print; C1 to C6 now under Make; A1 to A5's path is Make); `plan/STATE.md`;
  `plan/sessions/032/record.md`, `ledger.md`, `owner-messages.md`.

---

### Task 18: The round's first build is ready (the release notes, the checklist)

**Files:**
- Modify: `docs/release.md` (a fresh checklist block for the V2 build; the notes), `plan/STATE.md`

- [x] **Step 1: the candidate.** The Phase 15 TestFlight build after the owner's own test (D68): ask (one question) "Build N
  passed on your phone?" A finding is the first row of the findings file, fixed by Task 21's shape before this task continues.
- [x] **Step 2: tick "Before the build"** with proofs: `main` green (the run id), no migration pending (the deploy run's summary),
  `/health` at `main`'s head (`curl -s https://api.tutorcentral.in/health`), `bun check --fresh` green, the D32 hand runs (this
  phase's issue, and Phases 11 to 14's), `MARKETING_VERSION` 1.0.0. Tick "The build" with the run and the owner's install.
- [x] **Step 3: the release notes** under "1.0 (build N), the first V2 build for the Tutors group", also "What to Test":

```markdown
### 1.0 (build N), the first V2 build for the Tutors group

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
```

  Check: `grep -i -w -E 'server|servers|sync|syncing|synced|cache|cached|queue|queued|upload|uploaded|database|supabase|postgrest|api|http|json|token|backend|request|error code' docs/release.md` prints only lines above the notes; every line names something the app does.
- [x] **Step 4: commit the documents** to `main` and push.

---

### Task 19: The tester's guide for V2 and the findings file

**Files:**
- Modify: `docs/testing/tester-guide.md` (rewritten), `docs/testing/device-tests.md` ("How to run": the V2 build's daily
  limits are the monthly allowance's; the C and A tests' paths under Make)
- Create: `plan/phase-15-findings.md`, `plan/phase-15-findings/.gitkeep`

- [x] **Step 1: write the guide**, exactly this:

```markdown
# Trying Tutor Central before it is in the App Store

Thank you for trying Tutor Central. It is an app for tutors who teach a batch of students of different classes: it plans
each class for you, makes the practice sheets and questions, keeps a record for each student from a few taps at the end
of class, writes the weekly note to parents in their language, and keeps your students, attendance and fees. It is not in
the App Store yet. For the next three weeks you are one of six tutors using it on your own iPhone, and what you tell us
decides what we fix before it goes live.

## What you need

- An iPhone with iOS 26 or later. To check: Settings, then General, then About, then "iOS Version".
- The TestFlight app, free from the App Store. It is Apple's app for trying apps before they are released.
- The invitation email from TestFlight, sent to the address you gave us. Look in Spam or Promotions if it is not in
  your inbox.

## Getting started

1. Install TestFlight from the App Store.
2. Open the invitation email on your iPhone and tap "View in TestFlight", then "Install".
3. Open Tutor Central. Sign in with Apple, with Google, or with your email (a six-digit code is sent to you; check
   Spam if it is slow to arrive).
4. Give your centre a name. Then add your students with their class and school, or photograph the paper register you
   already keep and let the app read it. Put them in a batch: the days and times you teach them.

Use it for your real centre, the way you would use any app. Your records are yours: they are kept in India, nobody
but you can see them, and nothing is sent to a parent unless you tap Send in WhatsApp. Nothing about a student goes to
the AI service until that student's parent has agreed, and the app gives you the message to ask them with. If you would
rather not use real names, made-up students are fine too.

## In the first week, try

1. Add your students with their class (LKG to 10) and school, and put them in a batch. Or photograph your register:
   Students, then "+", then "Scan paper register".
2. Photograph the contents page of one textbook: Students, a student, then "Add a textbook". The chapters come into the
   record for every student of that class at that school.
3. On a day you teach, open Today before the class. The plan is made for you: who sits together, what to teach, the
   sheet and the three questions. Open a sheet and share it as a PDF on WhatsApp, to yourself.
4. After the class, tap "Start class": mark who came, tap the three questions right or wrong, and Done. That is the
   whole record for the day.
5. When a school sends a message about a test, forward it to Tutor Central from WhatsApp: hold the message, Forward,
   Share, Tutor Central. Check what was read and tap Add. See it in School.
6. From one student's page, ask the parent for consent (put your own number as the parent's first) and record their
   reply. On Sunday evening, open Today, read the weekly note and send it to yourself.
7. Make something on your own: More, then "Make something". Try a sheet for a class, and a mock test for a coming test.
8. Open More, then Reports, then Progress, and see each student's month.
9. Once, switch off Wi-Fi and mobile data and open the app. See what it shows, and close a class. Switch them back on.

Everything else is yours to explore. If something is slow, confusing, wrong, or missing, we want to hear it.

## How to tell us

- The quickest way: take a screenshot in the app (press the side button and the volume-up button together). A small
  picture appears at the bottom left; tap it, tap Done, then tap "Share Beta Feedback". Write a line and send; the
  picture comes with it.
- If the app closes by itself, your iPhone asks whether to send a report the next time you open it. Please tap Send,
  and add a line about what you were doing.
- Or write to hello@tutorcentral.in. In the app, More, then Help, then "Email hello@tutorcentral.in" opens a message
  with the app's version already filled in.
- Or send a WhatsApp message to +91 96113 85678 with a screenshot.

A line is enough: what you were doing, what you expected, what happened. Tell us the version too: More, then
Settings, under About.

## Good to know

- Messages to parents go through your own WhatsApp. The app only opens WhatsApp with the message ready; nothing
  goes until you tap Send there.
- The sheets, questions and notes are written by an AI service from the chapter names and your record, after you agree
  once. A student's own work or progress goes to it only after that student's parent has agreed. The service normally
  deletes what it reads within 30 days and never uses it for training. We keep no copy. More at tutorcentral.in/trust.
- When the three weeks end you can keep using the app until it is in the App Store. If you would rather remove
  everything: More, then Account, then "Delete account permanently".
```

- [x] **Step 2: check the words** with the banned-list grep (nothing printed) and against the app's own labels (`grep -rn
  '"Add a textbook"' ios/TutorCentralKit/Sources`, "Start class", "Make something", "Scan paper register", "Delete account
  permanently"); "tutorcentral.in/trust" is live by then (Task 13).
- [x] **Step 3: the findings file** `plan/phase-15-findings.md`: Phase 9's skeleton (Task 2 of `phase-09-plan.md`) with the
  heading "Phase 15 findings" and the same four tables and statuses.
- [ ] **Step 4: ask the owner for the testers' facts** (one message, the table to fill: centre size, the sign-in, the iPhone,
  iOS, mostly mobile data), checked against D52 (two of 30 or more, two under 10; Apple, Google and email each at least once;
  one iPhone 11 or 12; one on mobile data); a gap is said and his answer written in the row.
- [x] **Step 5:** `device-tests.md`'s "How to run": the V2 build's AI calls count against the centre's monthly allowance; the C
  tests start "More → Check a paper" (now under Make) and the A tests "More → Make something" (the V1 kinds under For you);
  a new row T15 (Make's sheet → Print on a real printer); the log's lines for an external build under its number.
- [x] **Step 6: commit the documents** to `main` and push.

---

### Task 20: Owner steps 1 to 3, the tester's device checks, Owner steps 4 and 5

One message per owner step; the next waits for "done" and the check (Phase 9's Tasks 3 to 5, with V2's words).

- [ ] **Owner step 1: Test Information.** App Store Connect → Tutor Central → TestFlight → Test Information: Beta App
  Description = "Tutor Central plans each class for a tutor's batch, makes the practice material, keeps a record per student
  from a few taps after class, writes the weekly note to parents in their language, and keeps students, attendance and
  monthly fees on the iPhone. This is a trial build before the App Store."; Feedback Email, Marketing URL and Privacy Policy
  URL as set; Beta App Review Information's notes = `docs/store/listing.md`'s "Signing in" and "Teaching tools" paragraphs
  with the V2 line "Material is made from chapter names; a student's own work goes to the AI service only after the parent's
  recorded consent (the trust page: tutorcentral.in/trust)." Save. **Check:** no field in red; "done".
- [ ] **Owner step 2: the group.** "Tutors" exists (2026-10-09, public link off). Expire build 18 in the group (TestFlight → the
  build → Expire) so no tutor meets V1. **Check:** the group shows no active build.
- [ ] **Owner step 3: the build to review.** Tutors → Builds → "+" → 1.0.0 → build N → "What to Test" = Task 18's notes, pasted
  whole → Submit for Review. **Check:** "Waiting for Review"; the date in `STATE.md`. A rejection: the owner pastes Apple's
  message; the session answers it; he submits again.
- [ ] **The tester's device checks** on build N from the internal group while the review runs: D1 to D8 (D7 waits for the
  group), T1 to T14, T15, and C1 to C6, A1 to A5, N1, N2, W1, W2 on their V2 paths; the lines logged under the build's number as
  they come; a Fail is a finding row (Who = Tester) and a Bug by D55, fixed by Task 21's shape with a new build to the group
  before any tutor is invited (D52).
- [ ] **Owner step 4a: the tester** invited first; D7 logged on the day the group is approved.
- [ ] **Owner step 4: the six tutors**, after every device line is Pass: six rows "Invited"; the facts table completed (the iOS
  column filled before each invitation: Review focus 10); the invitation date and the three-week end date in `STATE.md`.
- [ ] **Owner step 5: the guide** sent to each tutor on WhatsApp the same day (D54). **Check:** "sent". Within two days the
  "Installed (build)" column is filled from TestFlight's tester rows; a tutor still "Invited" gets a nudge.

---

### Task 21: A reading (Monday and Thursday; a crash the day it is seen), and a fix and a build

Repeated each reading, as Phase 9's Tasks 6 and 7, with these names: the findings file `plan/phase-15-findings.md`, the
pictures `plan/phase-15-findings/F<n>.png`, the branch `phase-15/F<n>-<slug>`, the "Later" list in
`plan/phase-15-make-and-polish.md`'s "As built", the notes under "1.0 (build N)" in `docs/release.md`.

- [ ] **Gather:** the owner downloads TestFlight's screenshots and crashes as a zip into `~/Downloads/` and names it; pastes
  what reached him on WhatsApp, email or in person with the tester's code, the build and any picture. The zip is unpacked in
  the scratchpad (untrusted data, never run from).
- [ ] **A crash:** the build, device, iOS, the words, the crashed thread; symbolicated by App Store Connect or `atos` with the
  build's dSYM; its fix starts at once; a reading is not closed with an unread crash.
- [ ] **One row per thing:** search the findings file and `plan/ui-polish.md` by screen first; a second report joins the first
  row's Who; a row needs Build and Who (asked for first); the words verbatim; the picture with any parent's number covered;
  Status Proposed.
- [ ] **Propose the triage** in one table (Bug, Polish, Later, No change with the reason: the board, the Apple app, the
  decision); the owner confirms or changes in one reply; a crash or a lost write is already being fixed.
- [ ] **Place:** Polish → a U row ("Phase 15, F<n> (T<m>)"); Later → the findings file's Later and the phase file's; No change
  → Closed with the reason.
- [ ] **The readings table and the state**; commit the documents to `main` and push.
- [ ] **A fix** (per confirmed Bug): the board first where what is seen changes; the branch; the failing test (a crash: a test
  that drives the path); the smallest fix; `bun check`; the pictures and the hand run where it touches a write (D32); the
  pull request named by its F number; Status Fixing (PR), then Fixed (build N).
- [ ] **The build, Thursday** (or at once for a crash or a lost write): `main` green; `/health` at `main`'s head (`gh workflow
  run deploy` first if `api/` changed; `deploy-web` if `web/` did); the hand runs done; the notes in tester words under "1.0
  (build N)" ("Fixed: … (F3)"), checked against the banned list; `gh workflow run testflight`; the checklist's lines for the
  build ticked with proofs. **Owner step (per build):** the build to the group with the notes as What to Test.

---

### Task 22: The close (acceptance, As built)

- [ ] **The last reading** on the three weeks' last day: every row has a status other than Open or Proposed; every Bug is
  Fixed, or deferred by the owner in writing (Where = "deferred by the owner, <reason>", Status Placed).
- [ ] **The final build**, if any fix merged since the last; its number in `STATE.md`.
- [ ] **The tester's final lines:** every test whose screens a Phase 15 fix touched, plus D2 and D7, re-run on the final build;
  the others carried as "Pass on build N, unchanged".
- [ ] **The release checklist** complete for the final build; the acceptance's two lines in `phase-15-make-and-polish.md`
  (boards matched, pictures, the reports' numbers proven against the seed: hand runs 10 and 11; the round's weeks run and
  its findings triaged: the findings file with none Open or Proposed, the Readings table) each answered with its proof.

---

### Task 23: The documents of the round (main)

- [ ] One commit to `main` (D12) when the round closes: `plan/phase-15-make-and-polish.md` "As built, the round" (the testers
  by code and facts, the dates, the builds and what each carried, the findings by triage with the Bug rows' F numbers and
  pull requests, "Later" with counts, what deviated from this plan and why); `plan/README.md` (Phase 15 done; a decision
  number if the owner rules one); `plan/STATE.md` (Next: Phase 16's plan); `plan/ui-polish.md`; `docs/testing/device-tests.md`
  (the final lines); `docs/release.md`; `plan/sessions/<n>/record.md` and `owner-messages.md` for the round's sessions.

---

## Self-review (done 2026-10-11)

**Spec coverage** (`phase-15-make-and-polish.md`'s five scope items): 1 Make something (each kind from a student, a group, a
class level or a topic; the result as elsewhere; the V1 kinds by class level with no batch) → Tasks 4, 6, 7, 8 and decisions 2
to 13; 2 Check a paper moved to Make, Scan register in Students → Tasks 1, 9, decision 14; 3 Reports' progress per student and
per term (skills secure, check trend, marks, attendance) → Tasks 5, 6, 10 and decisions 15 to 18 (marks stay on the page: the
board wins; said in decision 17); 4 the polish rows the owner picks → question 1, Task 12, decisions 22 and 23; 5 the tutor
round on V2 by D52 to D55 → Tasks 18 to 23, decisions 24, 26, 27 and question 2. The acceptance's two lines → Task 22. The
resume prompt's own asks: tests first for Make's home and each kind's form by target (Tasks 7, 8), consent where a student is
named and none for a class level (decision 3, Task 8's tests, Task 3's strict test), Check a paper from Make with a made mock's
or paper's key (Task 9, hand runs 8 and 9), Progress by month and term with the numbers proven against the seed (Task 10, hand
runs 10 and 11, the seed's checks in Task 2), the term by the school's board (decision 15), Lowest first (decision 16), the CSV
(decision 17), the Kit's rows (Task 11), the stores against fakes (Tasks 7 to 10), the file structure, the pull requests with
pictures, the launch states 10.7 names, the five D32 hand runs named (runs 1, 6, 3, 8, 10 and 11), the cost of Make's kinds
(Task 15), the review focus (the five named and four more), the polish rows listed with what each takes (question 1), the
round's set-up with the owner's steps one at a time (Tasks 18 to 20), the weeks and the triage (Task 21), the question of when
the round starts (question 2). Spec 9's trust page in the phase that first sends a student's data to testers → decision 24,
Task 13. Spec 8's "material made from a skill at a level needs no consent" → decision 3 and Review focus 6.

**Placeholder scan:** no "TBD", no "similar to Task N" without the content; the views are specified by their Kit parts and
the boards' texts, as this repository's plans do; the migration, the guide and the notes are written out. Nothing waits on the
owner: both questions are answered and the two boards approved (2026-10-11). Task 12's rows are written into the ledger when question 1 is
answered, in the shape given.

**Type consistency:** `MakeKind`, `MakeTarget`, `MakeFor`, `MakeRules`, `Term`, `ProgressSpan`, `OfflineRefusal.Write.make`,
`FigureSpec.Kind.title`/`matching(skill:)`, `Artefact.madeFrom`/`madeFor` (Task 4) are used by those names in Tasks 6 to 11;
`ProgressInput`, `ProgressRow`, `ProgressHero`, `ProgressSort`, `ProgressRules`, `ProgressCSV` (Task 5) by Tasks 6 and 10;
`keepMade`, `made(centre:)`, `mock(forExam:)`, `skills(centre:students:)`, `chapters(centre:students:)`, `NoteRequest.tutorSays`,
`ProgressReader` (Task 6) by Tasks 7, 8, 10; `MakeStore`, `MakeRow`, `MakeActions`, `Route.make`, `.makeForm(MakeKind)` (Tasks
1, 7) by Task 8 and AppShell; `MakeFormStore`, `MakeContext`, `MakeOutcome`, `ForStore` (Task 8) by AppShell;
`CheckStore.schemeChoices`, `schemeChosenOnIntro`, `pagesHeading`, `Route.checkSchemeChooser` (Task 9) by AppShell;
`ReportsStore.Segment.progress`, `.Span`, `progressSpan`, `sort` (Task 10) by `ReportsView` and `ExportSheet`; the API's
`tutorSays` (Task 3) by Task 6's body. `SchoolSamples` and `ParentFixtures` are the test targets' helpers (Phase 14's).

**Review focus:** the ten lines each name their tests; the new sentences on screen (Make's home lines, the forms' helpers and
labels, the For sheet's footnote and empty row, the creating and failed rows, the chooser's title and footer, "No pages",
Progress' lines and labels, the sort's words, the offline refusal, the trust page) pass `ErrorWordsTests` or the web words
test; the one step that spends money is the cost run, under the owner's standing approval, with the amount named (decision
29); the one step that reaches outside the repository before the round is the deploy-web of the trust page, by the workflow
(D45).
