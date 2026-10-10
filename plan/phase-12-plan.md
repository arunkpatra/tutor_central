# Phase 12 plan: the plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-10 (session 25, Fable 5.1), approved by the owner the same day with the two Phase 12 boards, from `phase-12-class-plan.md`, `docs/spec-v2.md` and the approved Phase 10
boards (steps 10.3 and 10.4), plus the two Phase 12 boards for U37 and U39 (row 21 of the canvas, `P12-*`). Ticked as it
goes. The build runs on Opus 5.5 from `resume/024-phase-12-build.md`, inline, task by task, with one ledger as sessions
22 and 24 kept.

**Goal:** when the tutor opens the app on a batch's day, Today shows that batch's plan: two or three level groups, one
line per student (teach, practise, check, homework), the material made ahead (the set, the sheet in three forms, the
checks, the worked example, a figure where the skill has one, the brief above class 7), the tutor can change any of it
where it appears, and the close follows the plan online and offline; the cost of a twelve-student batch is measured.

**Architecture:** the plan is made on the phone by Domain rules (`PlanRules`, `ArtefactBudget`) from the register and
the record, as the user (D60), and written in one call (`make_plan`, migration 0019); each artefact is one `/ai/make`
call (sheet, worked example, figure, brief on Sonnet or Haiku by class; checks on Haiku) kept with its generation by
`keep_artefact`; `/ai/plan` is called only for a group whose record names no skill (new students), to name a first
topic. Today's `PlanStore` makes the plan on open and in the background refresh and keeps a copy on the iPhone so a plan
already made opens offline. The artefact screens are a new feature target `Artefacts` that Today and Students reach
through AppShell's routes. The close reads the plan's checks and sheet from that copy; Done marks the plan's lines done
in the same `close_session` call.

**Tech stack:** as Phase 11 (Swift 6, SwiftUI, Observation, Swift Testing; Supabase CLI, Postgres, Bun tests; Hono, zod
4, `@anthropic-ai/sdk`; XcodeGen). No new dependency. Printing through `UIPrintInteractionController` behind one
DesignSystem wrapper (D8, the reason in the file).

**Spec:** `docs/spec-v2.md` sections 2, 6, 7, 9 and 10; scope `plan/phase-12-class-plan.md`; the boards and what they
settle in `docs/design/information-architecture.md` ("Phase 10 boards", 10.3 and 10.4, and "Phase 12 boards"), the parts
and texts in `components.md` ("Phase 10 parts" 10.3 and 10.4, "Phase 12 parts"), the numbers in `design-tokens.md`
("Numbers in code"); decisions D56 to D66; what Phase 11 built in `phase-11-record-and-close.md` "As built" and
`plan/sessions/024/ledger.md`; what Phase 10 settled in `phase-10-v2-design-and-foundation.md` "As built, Part B".

## Global constraints

- No board, no approval, no code for anything seen (rule 1). Each state a board draws gets a `LaunchState` and its
  pictures in the pull request, both appearances where the board has both (D7). What no board redraws stays as Phase 11
  built it.
- Nothing from V1 is renamed, dropped or narrowed in the model (D56, D26): the table is `classes`, the word on screen is
  "Batch". Migration 0019 is additive and never edits 0001 to 0018; `close_session` gains a ninth argument with a default
  so build 20's eight-argument call still resolves. `types.ts` regenerated and committed with it.
- A new function: `security invoker`, `set search_path = ''`, `revoke all … from public, anon`, `grant execute … to
  authenticated`; a test for each path it refuses. No `security definer` beyond `is_member` and `delete_account` (D37).
  No service-role key, no server job, no cron (D37, D60): the app makes the plan.
- The API runs each call as the user (D5); inputs are zod schemas; a route validates first (400 with the issues);
  `start_ai_generation` gates each call (the monthly allowance); one model per kind, no fallbacks (D35, D63). The API
  reads no table but `ai_generations`: the app passes what it read, as `/make` does today.
- No textbook text anywhere (D58): chapter names and skill names go to Claude; nothing from inside a book.
- Nothing about a student goes to the AI in this phase: each artefact is made from a skill at a level (spec section 8),
  so no call carries a student's name or id and none needs consent (D62). A test holds it on both sides.
- Figures are typed specs the app validates and draws with tokens (D59): the API's zod schema and Domain's `FigureSpec`
  share one wire format; a spec that fails `validate()` is refused by the API and never drawn by the app.
- Swift 6 strict concurrency, SwiftUI only, Observation (D8); features never import each other (rule 4: the artefact
  screens are their own feature, reached by AppShell's routes; the plan's rules are Domain's); tokens only (D10; a value
  a board uses that `design-tokens.md` does not name is added to the document and to `Tokens` in the same commit, D25);
  Swift Testing in the test targets, a new `ArtefactsTests` target in `Package.swift` and `project.yml`.
- No technical words on screen (D41): each new sentence passes `ErrorWordsTests`; each message is one of
  `docs/design/feedback.md`'s rows (a failed or refused write is the system alert; a list that could not load says so in
  its place; a success shows in place).
- Text limits count Unicode scalars (D48). Both appearances (D13). Dynamic Type through `AdaptiveRow` and
  `growsWithText()` where a row puts a value beside a title.
- Bun only (D16); dependencies pinned (D14); `bun check` green before each commit; code to `main` through pull requests
  with pictures; documents directly to `main` (D12), never mixed with code.
- Plain voice in documents and comments; the word is Students, not Children.

## Decisions this plan takes

Small decisions, written here so they are not re-decided. The one that is the owner's is marked.

1. **The plan is made on the phone.** `PlanRules` (Domain) makes the groups, the subject per student and the four lines
   from the register, each student's chapters and skills, the batch's last two sessions and the batch's kept pattern;
   `ArtefactBudget` says which artefacts to make and in what order. Nothing is computed on the server (spec section 6:
   "the rules choose the content"; D60). `/ai/plan` goes live with one job: for a group whose members have no skill in
   the group's subject (new students, no book yet), it names a first chapter and skill for that class, subject and month
   of the school year (Sonnet). A plan whose groups all have a skill makes no `/ai/plan` call. The spec's "reads the record
   as the user" is read as the app's read: the API still touches no table but `ai_generations`.
2. **Groups.** A student's level key is the class level's ordinal (LKG 0 to class 10 11), one less for a student not on
   track. Students sort by level key, then name; the group count is the batch's kept count, else the smaller of three and
   the number of distinct level keys; the cuts fall at the largest gaps in level key (ties: the later gap). Groups are
   numbered by size, largest first (ties: the higher level first), as P10-Today-Plan draws Group 1 as the big class 8
   group. A group of one is still a group. A batch with one student has one group.
3. **The subject.** Per student: the subject of the nearest school item within 14 days (Phase 13 supplies items; the rule
   takes an optional list and this phase passes none), else the subject least recently taught (the subject with no taught
   skill first, then the oldest latest `stateAt` among its skills beyond not started), ties by the batch's own subject then
   by name; the batch's kept pattern for the weekday overrides both. The group's subject is the most common among its
   members (ties: the batch's subject, then by name), and all the group's lines follow it, since the set, the sheet and
   the checks are the group's.
4. **The lines.** Teach: the student's first skill not secure in the group's subject ("Teach: <skill>"); "Teach again:
   <skill>, with the worked example" when the student is on watch or not on track; "Catch up: missed Mon and Fri · then
   <skill>" when absent at the batch's last two sessions; "Placement, her first checks" when the student has chapters in
   the subject and nothing taught yet. Practise: "Practise set 1" (the group's set). Check: "Check 3". Homework: "Homework
   sheet 1", "Homework sheet 1, light" up to class 5. A student with no chapters in the subject (a V1 student, a class with
   no book) follows the group: the group's skill (from `/ai/plan` when no member has one), the group's set, checks and
   sheet. The group's chapter is the teach skill's chapter ("Group 1 · Chemical reactions"); for a group named by
   `/ai/plan`, its chapter.
5. **The checks move to the plan.** The group's three questions are one `/ai/make` check call: the group's teach skill and
   two more from the members' spaced queues (`SpacedQueue.pick` per member, the most overdue two across the group, in the
   group's subject, distinct). A student with a Teach again, Catch up or Placement line gets their own checks (their
   spaced queue, or the placement), at most four such students per plan; the rest take the group's. The close reads them
   from the plan and makes none; without a plan it keeps Phase 11's path.
6. **The budget** (`ArtefactBudget`, Domain, tested against the price sheet): at most three groups; per group, in this
   order: the checks, the set (a sheet, `forHomework: false`, 10 questions), the homework sheet (`forHomework: true`, 10
   questions, 5 up to class 5), the worked example for the teach skill, a figure when the skill names a template (decision
   7), the brief when the group's class is above 7 or a brief for that chapter was made before; then the personal checks
   (at most four); at most 20 calls in all, the later ones dropped. The price sheet (`PriceSheet`, DomainTests): Haiku 5.5
   $0.10 in and $0.50 out, Sonnet 5.5 $2 and $10, Opus 5.5 $4 and $20 per million tokens, ₹85 to the dollar, with typical
   tokens per kind the cost run (Task 24) replaces; the test holds a twelve-student, three-group plan under ₹10 and equal
   in artefact count to three groups of one plus the personal checks. No prompt caching this phase: the prompts are under
   the cacheable minimum; the "chapter context cached for an hour" of spec section 9 waits for Phase 13's mocks, where the
   context is long enough.
7. **Which skill has a figure** is a word table in Domain (`FigureSpec.Kind.matching(skill:)`): number line ("number
   line", "jumps", "count on"), fraction bar ("fraction", "half", "quarter", "parts of a whole"), place value ("place
   value", "ones, tens", "large numbers"), unit circle ("sine", "cosine", "unit circle", "trigonometric ratios"), triangle
   ("triangle", "Pythagoras", "right angle"), labelled cell ("cell", "nucleus", "cytoplasm"), food chain ("food chain",
   "producer", "consumer"). A skill that matches none has no figure. The match is case-insensitive on the skill's name.
8. **The figure's wire format** (the Phase 10 contract): `{"kind": "number_line", …}` with the API's snake_case kinds and
   fields; `FigureSpec` gets a hand-written `Codable` for it. The number line follows the board (start, jumps, landing):
   `.numberLine(from:to:step:start:jumps:)` replaces Phase 10's `marks`; its validation adds the landing inside the range.
   The triangle marks a right angle when an angle is 90. The labelled cell has at most five labels (the board's five
   parts); the food chain two to six links, the first a plant (the prompt asks; the app checks the count).
9. **Artefact contents** are jsonb per kind with the API's output keys (snake_case): sheet `{title, instructions,
   questions: [{number, text, answer}], for_homework, light}`; worked example `{problem, steps: [{title, working}], slip}`;
   figure `{figure: {kind, …}, caption}`; brief `{about, mistakes: [{title, how_to_catch}], worked_example: {problem,
   steps, slip}, words: [three]}`; own `{text}` or none with a `photo_path`. Domain decodes each into its type
   (`ArtefactContent`); an unknown kind reads as `.other` and the row shows its title only.
10. **The sheet's PDF and print.** `PDFMaker` moves from AITools to DesignSystem as a renderer of a `PDFSheet` (title,
    instructions, numbered lines, an optional key); AITools adapts its `GenerationResult` to it (no change on screen).
    Print is `Printer.print(pdf:)`, DesignSystem's `UIPrintInteractionController` wrapper. The key is left out of a shared
    or printed sheet unless the Key form is showing (the board's rule).
11. **The artefact screens** are a feature target `Artefacts` (`Sources/Features/Artefacts`): `SheetView` (Paper, Board,
    Key; Make it again; Use my own), `WorkedExampleView`, `FigureView`, `BriefView`, each with a small store over
    `PlansRepository` and `AIRepository`. AppShell pushes them by `Route.artefact(UUID)` from Today's plan lines and from
    the student's page's homework rows (the sheet given). The brief opens from the brief row.
12. **Make it again** makes a new artefact with the reason in the prompt ("easier", "harder", "shorter", "more sums",
    "different numbers", or the tutor's words up to 200 characters), keeps the old one in the record
    (`artefacts.regenerated_from`) and relinks the plan's items to the new one in the same `keep_artefact` call. Offline it
    is refused in words (`OfflineRefusal.regenerate`). A failure keeps the old artefact on screen and says so in the system
    alert ("Couldn't make it again. The sheet you have is still here.").
13. **Use my own:** Take a photo or Choose from Photos reduces the photo (`PhotoReducer`), uploads it to
    `photos/<centre id>/own/<uuid>.jpg` (the first stored photo of V2; add-only), then keeps an artefact of source `own`
    with the photo's path, relinked like a regenerate; Type it keeps the typed text (up to 4000 characters) with no photo.
    Replace in the nav row repeats the menu; "Use the made sheet instead" relinks the made one. Account deletion now
    removes the centre's photos through Storage before `delete_account` (after Apple's revocation; a failure stops the
    deletion with the existing words), which settles Phase 10's open contract.
14. **When the plan is made.** Today's load makes the plan for each of today's batches that has no plan for today and is
    not closed, whatever the hour (a batch that ended without a close can still be closed today). The hero's Start class
    stays live while the plan is made; the planning card sits in the plan's place and the lines fill in as the groups and
    their artefacts land. A plan already made opens at once from its copy on the iPhone. Offline with no plan made, Today
    shows no "Today's plan" section (Phase 11's Today, which has its board) and the plan is made at the next online open
    or foreground; the close works without it (D57). Two batches on one day get two plans, in time order.
15. **The background refresh** (`BackgroundRefresh.register`'s handler, AppShell) runs the same maker for today's batches
    with the session that is signed in; the request is scheduled for 06:00 the next morning each time the app goes to the
    background; iOS decides whether it runs. Each artefact is kept as it lands, so an interrupted refresh leaves a plan the
    open completes.
16. **The reminder** is V1's class reminder reworded for the plan: title "<batch> at 17:00", body "In 1 hour · 5 students.
    Open for today's plan.", link `tutorcentral://today`. Its lead's default moves from 15 to 60 minutes
    (`ReminderSettings.classMinutesBefore`), the scope's "an hour before"; the wheel keeps 5 to 60. A tutor who set a lead
    keeps it. P7-Reminders' "15 min" is an illustrative figure (the owner, 2026-10-08).
17. **Changing the plan** writes plain updates as the user: a moved student (`plan_items.group_no`, `moved_from`), a
    skipped line (`plan_items.skipped_at`), a student left out (all their items skipped), each group's subject and the
    group count for today (`make_plan` again with the sheet's choices, the artefacts made again), "Keep this for
    Wednesdays" (`classes.plan_pattern[weekday]`). Offline each is refused in words (`OfflineRefusal.changePlan`). A
    student left out closes with attendance alone (no checks, homework off).
18. **The close from the plan:** a checklist card per group of the plan's lines (one row per kind: Teach, Practise, Check,
    Homework, with the catch-up and placement lines where they are), its taps written as `plan_items.done_at` by
    `close_session`'s ninth argument; each student's checks from the plan (the group's or their own), none made at the
    close; "Homework given · sheet 1" with the sheet's artefact id; the quiet "Plan" in the top row pops to Today; a
    student left out has attendance only. Offline, the plan's copy on the iPhone carries the questions, so the close is
    whole. Without a plan the close is Phase 11's.
19. **U37, U38, U39 (the owner, 2026-10-10)** are built to the two Phase 12 boards: P12-Close-Cards draws the close card's
    three states no earlier board drew (the checks being made, no book yet, offline without a plan) and P12-Pending-Close
    draws the waiting close's row with its own symbol (`checklist`). U38's wait remains only on the no-plan path (the
    plan makes the checks ahead), so it is designed, not closed. U35's "Today" on This week opens the Today tab scrolled
    to that batch's plan card.
20. **Launch states** follow the 10.3 and 10.4 lists; the figures are seven states on one `FigureView`, one per template
    (the Kit's Phase 10 board stays Phase 15's). `today-note-day` is Phase 14's (the notes); `today-after-close` shows
    the closed hero over the plan's cards with no "To parents" (Phase 14) and no note count.
21. **The seed** (`seed.sql`, local only) gains the Evening batch (Mon to Fri 17:00 to 18:30) with twelve students in
    three levels (four of class 8 with a Science book, four of class 5 with the Maths book, four of class 2 on the
    ladder), beside V1's ten, so the hand runs and the cost run meet the spec's batch; `copy_textbook_to_class` fills the
    books' chapters in the seed. The fixtures keep the boards' five-student Evening batch.
22. **The cost run** (Task 24) runs the twelve-student batch once against the local stack with the local API **without**
    `AI_FAKE` (the owner's key from `api/.env.local`; about ₹10 at the price sheet), reads `ai_generations` by kind and
    model, and writes the figure into the session record, `phase-12-class-plan.md` "As built" and `PriceSheet`'s typical
    tokens. The owner is told before it runs (it costs money).
23. **Branches** `phase-12/<slug>` in the main checkout, one pull request each, as sessions 22 and 24 worked.
24. **The owner's to confirm:** the two Phase 12 boards (P12-Close-Cards, P12-Pending-Close), drawn by session 25 on row 21
    of the canvas, approved on 2026-10-10 ("the boards are approved too"); and the cost run's spend before Task 24 runs it.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A batch with new students and no record** (class levels only, no book, no checks): the plan still comes, grouped by
   class, each group named a first chapter and skill by `/ai/plan`, the set and sheet made for it, the checks on that
   skill; a student with no class level follows the group. Tests: Task 6 (`PlanRulesTests.aBatchWithNoRecordIsPlannedByClass`,
   `aStudentWithNoClassFollowsTheGroup`), Task 3 (`plan names a first topic per group`), Task 14
   (`PlanStoreTests.aGroupWithoutASkillAsksForATopic`).
2. **A student without consent** gets the group's set, sheet and checks like anyone else and no artefact carries their
   name or id. Tests: Task 6 (`ArtefactBudgetTests.nothingPersonalIsEverMade`), Task 3 (`no make kind of this phase takes a
   student`), Task 10 (`APIBodiesV2Tests.noBodyCarriesAStudent`).
3. **A plan made offline, and a plan opened offline:** with no connection and no plan, Today shows no plan section and
   Start class works; a plan made earlier opens from its copy with its checks, and the close reads them without a call.
   Tests: Task 14 (`PlanStoreTests.offlineWithNoPlanShowsNothingAndStartClassStays`, `aPlanAlreadyMadeOpensOffline`),
   Task 20 (`CloseStoreTests.aCloseFromACachedPlanMakesNoCall`).
4. **A day with no batch, and a batch already closed:** no plan is made on a day with no batch (the no-batch hero stands);
   a batch closed today is not planned again; a second batch the same day gets its own plan. Tests: Task 14
   (`PlanStoreTests.noBatchTodayMakesNoPlan`, `aClosedBatchIsNotPlanned`, `twoBatchesGetTwoPlans`).
5. **A regenerate that fails** (the AI service down, the allowance spent, offline): the old sheet stays on screen and in
   the plan, the alert says so, Make it again is live again. Tests: Task 17 (`SheetStoreTests.aFailedRegenerateKeepsTheOld`,
   `regenerateOfflineIsRefusedInWords`), Task 1 (`keep_artefact relinks only when the new row is written`).
6. **A sheet with a figure, and a figure that does not add up:** a group whose skill is "Compare simple fractions" gets a
   fraction bar made and printed with the sheet; a spec whose parts do not sum, or a food chain of one link, is refused by
   the API (422 in words) and the plan goes on without the figure. Tests: Task 3 (`a figure that fails its rule is refused
   in words`), Task 7 (`FigureSpecTests.theWireFormatRoundTrips`, `aLandingOutsideTheLineIsRefused`), Task 14
   (`PlanStoreTests.aFailedFigureLeavesTheRestOfThePlan`).
7. **A V1 student in a V2 batch, and a batch of one:** a student with no class level is listed in the plan under a group
   with the group's lines and closes with the group's checks; a batch of one student has one group with everything made
   for it. Tests: Task 6 (`PlanRulesTests.aBatchOfOneHasOneGroup`), Task 20
   (`CloseStoreTests.aV1StudentTakesTheGroupsChecks`).
8. **Changing the plan after some material is made:** Move to Group n while the group's sheet is still on its way keeps
   the student's sheet the new group's once it lands; Make the plan again while artefacts are landing drops the late
   answers. Tests: Task 14 (`PlanStoreTests.aMoveBeforeTheSheetLandsFollowsTheNewGroup`,
   `makingAgainDropsLateAnswers`).

## File structure

Created or changed, by module. A file has one job; the stores are small and named for what they do.

| Module | File | Job |
|---|---|---|
| supabase | `migrations/20261024000019_v2_plan_write_and_pattern.sql` | `classes.plan_groups`, `classes.plan_pattern`; `plan_items.skipped_at`, `moved_from`; `make_plan`; `keep_artefact`; `close_session` with `p_done` |
| supabase | `tests/v2.test.ts` (extended), `seed.sql` (the Evening batch of twelve), `types.ts` | The function tests; the local data; the generated types |
| api | `src/schemas.ts` (`PlanInput` extended, `PlanOutput`, `SheetOutput`, `WorkedExampleOutput`, `FigureOutput`, `BriefOutput`, the regenerate `reason`), `src/prompts/plan.ts`, `sheet.ts`, `worked-example.ts`, `figure.ts`, `brief.ts`, `src/routes/v2.ts` (`/plan`, `/make` for the four kinds), `src/claude-fake.ts` (five samples, `kindOf`), `src/errors.ts` (the figure's refusal words), `test/v2.test.ts`, `test/prompts.test.ts`, `test/schemas.test.ts` | The routes live |
| Domain | `Record/FigureSpec.swift` (the wire format, the number line's jumps, `Kind.matching(skill:)`), `Plan/PlanTypes.swift` (`PlanGroup`, `PlanLine`, `PlanLineKind`, `PlanDraft`, `PlanRecord`, `PlanItem`), `Plan/PlanRules.swift`, `Plan/ArtefactBudget.swift`, `Plan/Artefact.swift` (`Artefact`, `ArtefactKind`, `ArtefactContent`, `SheetContent`, `WorkedExample`, `FigureContent`, `Brief`, `OwnContent`), `Plan/RegenerateReason.swift`, `Plan/PlanPattern.swift`, `Queue/OfflineRefusal.swift` (`.regenerate`, `.changePlan`, `.ownSheet`), `Reminders/ReminderPlanner.swift` (the plan's words and link), `Reminders/ReminderSettings.swift` (lead 60) | The rules and the shapes |
| Data | `Plans/PlansRepository.swift`, `SupabasePlansRepository.swift`, `PlanRows.swift`, `FakePlansRepository.swift`, `Plans/PlanCache.swift`, `Photos/PhotoStore.swift` (`SupabasePhotoStore`, `FakePhotoStore`), `AI/AIRepository.swift` (five calls, DTOs), `AI/APIClient+Plan.swift`, `AI/APIBodies.swift`, `AI/FakeAIRepository.swift`, `AI/AISamples+Plan.swift`, `Attendance/SupabaseAttendanceRepository.swift` (`p_done`), `Account/*` (photos removed before deletion), `Classes/*` (`plan_groups`, `plan_pattern` read and written) | The reads and writes behind the screens |
| DesignSystem | `Components/GroupCard.swift` (the group head, ready marks), `PlanLineRow.swift`, `LineChecklist.swift`, `LineMenu` (the context menu's rows), `FigureViews.swift` (seven figures), `FigureCard.swift`, `StepRow.swift`, `BoardView.swift`, `KeyRow.swift`, `PhotoCard.swift`, `ThreeFormControl` (the segmented control's use), `PDF/PDFMaker.swift` (moved), `PDF/Printer.swift`, `Tokens/Tokens.swift` and `docs/design/design-tokens.md` where a board's value is new | The Phase 10 and 12 parts this phase uses |
| Features/Today | `PlanStore.swift`, `PlanStore+Make.swift`, `PlanStore+Change.swift`, `PlanMaker.swift`, `PlanSections.swift` (the section, the group cards, the brief row, the planning card), `PlanChangeSheet.swift`, `TodayStore.swift` (the plans per batch, `focusBatch`), `TodayView.swift`, `CloseStore.swift`, `CloseStore+Checks.swift` (from the plan), `CloseStore+Done.swift` (`done` items), `CloseSections.swift` (the checklist, the card states, the Plan link) | The plan and the close |
| Features/Artefacts (new) | `ArtefactsActions.swift`, `SheetStore.swift`, `SheetStore+Again.swift`, `SheetStore+Own.swift`, `SheetView.swift`, `SheetSections.swift`, `OwnSheetMenu.swift`, `TypeItSheet.swift`, `ReasonSheet.swift`, `WorkedExampleStore.swift`, `WorkedExampleView.swift`, `FigureStore.swift`, `FigureView.swift`, `BriefStore.swift`, `BriefView.swift`, `ArtefactWords.swift` | The artefact screens |
| Features/AITools | `PDFMaker` use (`ResultFooter.swift`) | Unchanged on screen |
| Features/Students | `StudentsActions.swift` (`openToday`), `RecordSections.swift` (This week's "Today"; a homework row opens its sheet) | U35; the sheet from the page |
| Features/Settings | `Pending/PendingChangesView.swift` (the close's symbol), `Account/DeleteAccountStore.swift` (photos removed) | U39; the photos |
| AppShell | `TabsState.swift` (`Route.artefact(UUID)`), `TabsView.swift`, `RootView+Artefacts.swift`, `RootView+Today.swift`, `RootView+Close.swift`, `RootView+Students.swift`, `RootView+LaunchStates.swift`, `LaunchState.swift`, `Fixtures+Plan.swift`, `Dependencies.swift` (`plans`, `photos`), `AppDelegate.swift` and `RootView.swift` (the refresh's handler and schedule), `Package.swift`, `project.yml` | The shell |
| Tests | `supabase/tests/v2.test.ts`; `api/test/v2.test.ts`, `schemas.test.ts`, `prompts.test.ts`; `DomainTests/{FigureSpecTests, PlanRulesTests, ArtefactBudgetTests, PriceSheet (helper), ArtefactContentTests, PlanPatternTests, OfflineRefusalTests, ReminderPlannerTests}`; `DataTests/{PlanRowTests, FakePlansRepositoryTests, PlanCacheTests, APIBodiesV2Tests, APIClientTests, FakePhotoStoreTests}`; `TodayTests/{PlanStoreTests, PlanMakerTests, PlanChangeTests, CloseStoreTests, CloseQueueTests, TodayStoreTests}`; `ArtefactsTests/{SheetStoreTests, SheetOwnTests, WorkedExampleStoreTests, FigureStoreTests, BriefStoreTests}`; `DesignSystemTests/{FigureViewTests, PDFMakerTests (moved), TokenDocumentTests}`; `StudentsTests/StudentDetailStoreTests`; `SettingsTests/{PendingChangesStoreTests, DeleteAccountStoreTests}`; `AppShellTests/{LaunchStateTests, TabsStateTests, RefreshHandlerTests}` | |

## Launch states

Each state the 10.3 and 10.4 boards name, and the two Phase 12 boards', with the fixtures' data (the clock Wednesday 7
October 2026, 16:35, India, unless the state says another). Light twins from `--appearance light` where the board has
both. The fixtures' Evening batch (Dev, Meher, Nikhil in class 8; Riya in class 5; Sahil in class 2) has its plan made:
three groups, Group 1's balancing equations sheet and checks, the brief for Chemical reactions, Sahil's ladder group.

| State | Shows | Board | PR |
|---|---|---|---|
| `today` | Today with the batch hero (Start class) over the plan's cards | P10-Today-Plan (both) | 5 |
| `today-scrolled` | Scrolled to the smaller groups, the brief row, V1's sections | P10-Today-Plan-Scrolled | 5 |
| `today-planning` | The planning card in the plan's place, the hero's button live | P10-Today-Planning | 5 |
| `today-line-menu` | Dev's line pressed: the context menu | P10-Today-Plan-StudentMenu | 5 |
| `today-plan-changed` | Riya moved to Group 1, Nikhil's homework skipped | P10-Today-Plan-Changed | 5 |
| `today-plan-change` | The Change sheet | P10-Today-Plan-Change | 5 |
| `today-after-close` | 18:40: the closed hero over the plan's cards, lines done | P10-Today-AfterClose (without To parents) | 5 |
| `today-no-batch` | Saturday 10 October 09:30: no batch, the next on Monday (supersedes `today-no-class`) | P10-Today-NoBatch | 5 |
| `sheet`, `sheet-key`, `sheet-board` | Group 1's sheet: Paper (both), Key, Board at question 3 | P10-Sheet (both), -Key, -Board | 6 |
| `sheet-regenerate`, `sheet-regenerating` | The reasons menu; "Making it easier" | P10-Sheet-Regenerate, -Regenerating | 6 |
| `sheet-own-menu`, `sheet-own` | Use my own: the three ways; the tutor's photo in place | P10-Sheet-OwnMenu, -Own | 6 |
| `worked-example` | Balancing equations, two of four steps shown | P10-WorkedExample | 7 |
| `figure-number-line`, `-fraction-bar`, `-place-value`, `-unit-circle`, `-triangle`, `-cell`, `-food-chain` | One figure each, the board's spec | P10-Figure-* | 7 |
| `brief` | The brief for Chemical reactions | P10-Brief | 7 |
| `close`, `close-scrolled`, `close-placement` | The close from the plan: the group checklists, the checks from the plan; two students tapped and one absent; Sahil's placement | P10-Close (both), -Scrolled, -Placement | 8 |
| `close-cards` | 17:05, no plan: the three card states (the wait, no book, offline) | P12-Close-Cards (both) | 8 |
| `pending` | Pending changes with a waiting close and its symbol | P12-Pending-Close | 8 |
| `student-record` | Hemanth's page: This week with the quiet Today | P10-Student (unchanged) | 9 |

`today-evening` and `today-no-class` (Phase 4's) are retired: their content is `today-after-close` and `today-no-batch`.

## Pull requests

| PR | Tasks | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-12/db` | Database: the plan's write and pattern, the artefact's keep, the close's done lines; the seed's Evening batch | none |
| 2 | 2, 3 | `phase-12/api` | The API: `/ai/plan`; `/ai/make` sheet, worked example, figure and brief; the regenerate reason | none |
| main | | | `gh workflow run deploy` after PR 2: 0019 up, the API at `main`'s head (Task 24) | |
| 3 | 4, 5, 6, 7 | `phase-12/domain` | Domain: the plan's types and rules, the budget and the price sheet, the artefacts, the figure's wire format, the reminder's words, the refusals | none |
| 4 | 8, 9, 10 | `phase-12/data` | Data: plans and artefacts, the plan's copy on the iPhone, photos, the API client's five calls, the close's done lines; the write proofs | none |
| 5 | 11, 12, 13, 14 | `phase-12/today-plan` | Today: the plan made on open and in the background, the group cards and lines, the planning card, the line menu, Change the plan, the reminder | `today`, `today-scrolled`, `today-planning`, `today-line-menu`, `today-plan-changed`, `today-plan-change`, `today-after-close`, `today-no-batch`; both for `today` |
| 6 | 15, 16, 17 | `phase-12/sheet` | Artefacts: the sheet in three forms, Share as PDF and Print, Make it again, Use my own | `sheet`, `sheet-key`, `sheet-board`, `sheet-regenerate`, `sheet-regenerating`, `sheet-own-menu`, `sheet-own`; both for `sheet` |
| 7 | 18, 19 | `phase-12/artefacts` | Artefacts: the worked example, the seven figures, the brief | `worked-example`, the seven `figure-*`, `brief` |
| 8 | 20, 21, 22 | `phase-12/close-plan` | The close from the plan: the checklist, the checks and sheet from the plan, the Plan link, offline from the copy; the card states (U37, U38); the pending symbol (U39) | `close`, `close-scrolled`, `close-placement`, `close-cards`, `pending`; both for `close` and `close-cards` |
| 9 | 23 | `phase-12/student-today` | U35: This week's Today opens the plan at the student's batch; a homework row opens its sheet | `student-record` |
| main | 24, 25 | | The deploy, the hand runs, the cost run, TestFlight, the documents (D12) | |

Each pull request: `bun check` green, one change, described by what it does and how it was checked, the pictures by
`bun shots <state>` and `bun pr-shots` (rule 2). The two Phase 12 boards PR 8 builds are approved (decision 24).

---

### Task 1: Migration 0019: the plan's write and pattern, the artefact's keep, the close's done lines; the seed (PR 1)

**Files:**
- Create: `supabase/migrations/20261024000019_v2_plan_write_and_pattern.sql`
- Modify: `supabase/tests/v2.test.ts` (a "plans" block), `supabase/seed.sql` (the Evening batch of twelve),
  `supabase/types.ts` (regenerated)

**Interfaces:**
- Consumes: migrations 0010 (`plans`, `plan_items`, `artefacts`), 0017 (`close_session` with eight arguments), 0013
  (`start_ai_generation`).
- Produces: `classes.plan_groups integer` (1 to 3, null: the rule decides), `classes.plan_pattern jsonb` (`{"3":
  {"groups": 2, "subjects": ["Science", "Mathematics"]}}` keyed by ISO weekday 1 to 7); `plan_items.skipped_at
  timestamptz`, `plan_items.moved_from integer`; `make_plan(p_centre, p_class, p_date, p_groups, p_subjects, p_items)
  returns jsonb` (`{"plan_id": …, "items": [{"id", "student_id", "group_no", "kind"}]}`); `keep_artefact(p_centre,
  p_artefact, p_plan, p_group_no, p_student, p_item_kind) returns uuid`; `close_session(…, p_states, p_done uuid[]
  default '{}')`.

- [ ] **Step 1: Write the failing tests** (append to `supabase/tests/v2.test.ts`; `a` and `centre` are the file's)

```ts
// ---- Phase 12: the plan's write, the artefact's keep, the close's done lines ----
async function batchWithTwo() {
  const cls = (await a.from("classes").insert({ centre_id: centre, name: `Batch ${stamp}`, meeting_days: [1, 2, 3, 4, 5], start_time: "17:00", end_time: "18:30" }).select("id").single()).data!;
  const s1 = (await a.from("students").insert({ centre_id: centre, class_id: cls.id, name: "Plan One", class_level: "8" }).select("id").single()).data!;
  const s2 = (await a.from("students").insert({ centre_id: centre, class_id: cls.id, name: "Plan Two", class_level: "5" }).select("id").single()).data!;
  return { cls, s1, s2 };
}
const items = (s1: string, s2: string) => [
  { student_id: s1, group_no: 1, kind: "teach", words: "Teach: Balancing equations" },
  { student_id: s1, group_no: 1, kind: "practise", words: "Practise set 1" },
  { student_id: s1, group_no: 1, kind: "check", words: "Check 3" },
  { student_id: s1, group_no: 1, kind: "homework", words: "Homework sheet 1" },
  { student_id: s2, group_no: 2, kind: "teach", words: "Teach: Compare simple fractions" },
  { student_id: s2, group_no: 2, kind: "homework", words: "Homework sheet 1, light" },
  { student_id: null, group_no: 1, kind: "brief", words: "Your brief · Chemical reactions" },
];

test("make_plan writes the day's plan with its groups and items in one call, and a second call replaces it", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const groups = [{ group_no: 1, subject: "Science", chapter: "Chemical reactions", skill: "Balancing equations" }, { group_no: 2, subject: "Mathematics", chapter: "Parts and Wholes", skill: "Compare simple fractions" }];
  const first = await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: groups, p_subjects: { "1": "Science", "2": "Mathematics" }, p_items: items(s1.id, s2.id) });
  expect(first.error).toBeNull();
  const made = first.data as { plan_id: string; items: { id: string; student_id: string | null; group_no: number; kind: string }[] };
  expect(made.items).toHaveLength(7);
  expect(made.items.filter((i) => i.kind === "brief")[0]?.student_id).toBeNull();
  const again = await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [groups[0]], p_subjects: { "1": "Science" }, p_items: items(s1.id, s2.id).slice(0, 4) });
  expect((again.data as { plan_id: string }).plan_id).toBe(made.plan_id);
  const rows = await a.from("plan_items").select("id").eq("plan_id", made.plan_id);
  expect(rows.data).toHaveLength(4);
  const plan = await a.from("plans").select("groups, subjects, made_at").eq("id", made.plan_id).single();
  expect((plan.data!.groups as unknown[]).length).toBe(1);
});

test("make_plan refuses a non-member, a plan for another centre's batch, and a bad item kind", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const b = await userClient(l, `v2-plan-b-${stamp}@example.com`);
  const other = (await b.rpc("create_centre", { p_name: "Other", p_whatsapp: "+919999999902" })).data as string;
  expect((await b.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [] })).error?.code).toBe("42501");
  expect((await b.rpc("make_plan", { p_centre: other, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [] })).error).not.toBeNull();
  expect((await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-07", p_groups: [], p_subjects: {}, p_items: [{ student_id: s1.id, group_no: 1, kind: "revise" }] })).error).not.toBeNull();
  void s2;
});

test("keep_artefact writes the artefact and links the group's items of its kind; a personal keep links one student; a regenerate relinks and keeps the old", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-08", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string };
  const sheet = { kind: "sheet", source: "made", title: "Balancing equations · sheet 1", content: { title: "Balancing equations", questions: [{ number: 1, text: "Balance H2 + O2", answer: "2H2 + O2 → 2H2O" }], for_homework: true, light: false } };
  const kept = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: sheet, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  expect(kept.error).toBeNull();
  const linked = await a.from("plan_items").select("student_id, artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework");
  expect(linked.data!.find((r) => r.student_id === s1.id)?.artefact_id).toBe(kept.data as string);
  expect(linked.data!.find((r) => r.student_id === s2.id)?.artefact_id).toBeNull();
  const own = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "check", source: "made", title: "Plan One's checks", content: { questions: [] } }, p_plan: plan.plan_id, p_group_no: 1, p_student: s1.id, p_item_kind: "check" });
  expect(own.error).toBeNull();
  const again = await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { ...sheet, regenerated_from: kept.data }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" });
  expect(again.error).toBeNull();
  const relinked = await a.from("plan_items").select("artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework").eq("student_id", s1.id).single();
  expect(relinked.data!.artefact_id).toBe(again.data as string);
  const old = await a.from("artefacts").select("id, plan_id").eq("id", kept.data as string).single();
  expect(old.data!.plan_id).toBe(plan.plan_id);
});

test("keep_artefact refuses a non-member and a kind outside the enum, and links nothing when the row is not written", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-09", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string };
  const b = await userClient(l, `v2-keep-b-${stamp}@example.com`);
  expect((await b.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "sheet", title: "x", content: {} }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" })).error?.code).toBe("42501");
  expect((await a.rpc("keep_artefact", { p_centre: centre, p_artefact: { kind: "poster", title: "x", content: {} }, p_plan: plan.plan_id, p_group_no: 1, p_student: null, p_item_kind: "homework" })).error).not.toBeNull();
  const linked = await a.from("plan_items").select("artefact_id").eq("plan_id", plan.plan_id).eq("kind", "homework");
  expect(linked.data!.every((r) => r.artefact_id === null)).toBe(true);
});

test("close_session marks the plan's done lines and links the plan; the eight-argument call still works", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string; items: { id: string; kind: string }[] };
  const done = plan.items.filter((i) => i.kind === "teach").map((i) => i.id);
  const sid = (await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_marks: { [s1.id]: "present", [s2.id]: "present" }, p_checks: [], p_homework: [], p_track: {}, p_states: [], p_done: done })).data as string;
  const items2 = await a.from("plan_items").select("kind, done_at").eq("plan_id", plan.plan_id);
  expect(items2.data!.filter((i) => i.kind === "teach").every((i) => i.done_at !== null)).toBe(true);
  expect(items2.data!.filter((i) => i.kind !== "teach").every((i) => i.done_at === null)).toBe(true);
  expect((await a.from("plans").select("session_id").eq("id", plan.plan_id).single()).data!.session_id).toBe(sid);
  const eight = await a.rpc("close_session", { p_centre: centre, p_class: cls.id, p_date: "2026-10-12", p_marks: { [s1.id]: "present" }, p_checks: [], p_homework: [], p_track: {}, p_states: [] });
  expect(eight.error).toBeNull();
});

test("a batch keeps its group count and weekday pattern; the count is 1 to 3", async () => {
  const { cls } = await batchWithTwo();
  expect((await a.from("classes").update({ plan_groups: 2, plan_pattern: { "3": { groups: 2, subjects: ["Science", "Mathematics"] } } }).eq("id", cls.id)).error).toBeNull();
  expect((await a.from("classes").update({ plan_groups: 4 }).eq("id", cls.id)).error).not.toBeNull();
  const read = await a.from("classes").select("plan_groups, plan_pattern").eq("id", cls.id).single();
  expect(read.data).toEqual({ plan_groups: 2, plan_pattern: { "3": { groups: 2, subjects: ["Science", "Mathematics"] } } });
});

test("a skipped or moved line keeps its marks", async () => {
  const { cls, s1, s2 } = await batchWithTwo();
  const plan = (await a.rpc("make_plan", { p_centre: centre, p_class: cls.id, p_date: "2026-10-13", p_groups: [], p_subjects: {}, p_items: items(s1.id, s2.id) })).data as { plan_id: string; items: { id: string; kind: string; student_id: string | null }[] };
  const homework = plan.items.find((i) => i.kind === "homework" && i.student_id === s1.id)!;
  expect((await a.from("plan_items").update({ skipped_at: new Date().toISOString() }).eq("id", homework.id)).error).toBeNull();
  expect((await a.from("plan_items").update({ group_no: 2, moved_from: 1 }).eq("plan_id", plan.plan_id).eq("student_id", s1.id)).error).toBeNull();
  const moved = await a.from("plan_items").select("group_no, moved_from").eq("plan_id", plan.plan_id).eq("student_id", s1.id);
  expect(moved.data!.every((r) => r.group_no === 2 && r.moved_from === 1)).toBe(true);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd supabase && supabase db reset >/dev/null && bun test tests/v2.test.ts`
Expected: the seven new tests FAIL (`make_plan` and `keep_artefact` unknown, `plan_groups` unknown, `p_done` unknown).

- [ ] **Step 3: Write the migration**

```sql
-- Phase 12 (docs/spec-v2.md section 6; plan/phase-12-plan.md Task 1). Additive (D26): two columns on classes, two on
-- plan_items, two new functions, close_session replaced with a ninth argument that defaults, so build 20's
-- eight-argument call still resolves. Nothing from 0001 to 0018 is edited.

-- 1. The batch's kept choices (P10-Today-Plan-Change): how many groups, and the subjects per weekday ("Keep this for
--    Wednesdays"). plan_pattern: {"<iso weekday 1..7>": {"groups": n, "subjects": ["Science", "Mathematics"]}}.
alter table public.classes
  add column plan_groups integer check (plan_groups is null or plan_groups between 1 and 3),
  add column plan_pattern jsonb not null default '{}'::jsonb check (jsonb_typeof(plan_pattern) = 'object');

-- 2. A line skipped today, a student moved from another group (both for today only).
alter table public.plan_items
  add column skipped_at timestamptz,
  add column moved_from integer check (moved_from is null or moved_from between 1 and 9),
  add column words text not null default '' check (char_length(words) <= 200);

-- 3. The day's plan for a batch in one write: the plan row made or replaced (plans_one_per_day), its items replaced.
--    p_groups  [{"group_no", "subject", "chapter", "skill"}] (kept as made, for the cards)
--    p_subjects {"<group_no>": "<subject>"}
--    p_items   [{"student_id"?, "group_no", "kind", "skill_id"?, "words"}]
--    Answers {"plan_id", "items": [{"id", "student_id", "group_no", "kind"}]} so the app links artefacts by item.
create function public.make_plan(p_centre uuid, p_class uuid, p_date date, p_groups jsonb, p_subjects jsonb, p_items jsonb)
returns jsonb
language plpgsql security invoker set search_path = '' as $$
declare v_plan uuid; v_items jsonb;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_groups) <> 'array' or jsonb_typeof(p_subjects) <> 'object' or jsonb_typeof(p_items) <> 'array' then
    raise exception 'groups and items must be arrays, subjects an object' using errcode = '22023';
  end if;
  insert into public.plans (centre_id, class_id, date, made_at, groups, subjects)
  values (p_centre, p_class, p_date, now(), p_groups, p_subjects)
  on conflict (centre_id, class_id, date) do update
    set made_at = now(), groups = excluded.groups, subjects = excluded.subjects
  returning id into v_plan;
  delete from public.plan_items i where i.centre_id = p_centre and i.plan_id = v_plan;
  with written as (
    insert into public.plan_items (centre_id, plan_id, student_id, group_no, kind, skill_id, words)
    select p_centre, v_plan, (i->>'student_id')::uuid, (i->>'group_no')::integer, (i->>'kind')::public.plan_item_kind,
           (i->>'skill_id')::uuid, coalesce(i->>'words', '')
    from jsonb_array_elements(p_items) i
    returning id, student_id, group_no, kind
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', w.id, 'student_id', w.student_id, 'group_no', w.group_no, 'kind', w.kind)), '[]'::jsonb)
    into v_items from written w;
  return jsonb_build_object('plan_id', v_plan, 'items', v_items);
end $$;

revoke all on function public.make_plan(uuid, uuid, date, jsonb, jsonb, jsonb) from public, anon;
grant execute on function public.make_plan(uuid, uuid, date, jsonb, jsonb, jsonb) to authenticated;

-- 4. An artefact kept with the plan and linked to the lines it serves, in one write: the group's items of the kind
--    (p_student null) or one student's item (p_student set). A regenerate names regenerated_from; the old row stays.
--    p_artefact {"kind", "source"?, "title", "content", "photo_path"?, "generation_id"?, "regenerated_from"?}
create function public.keep_artefact(p_centre uuid, p_artefact jsonb, p_plan uuid, p_group_no integer, p_student uuid,
                                     p_item_kind public.plan_item_kind) returns uuid
language plpgsql security invoker set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_member(p_centre) then raise exception 'not a member' using errcode = '42501'; end if;
  if jsonb_typeof(p_artefact) <> 'object' then raise exception 'artefact must be an object' using errcode = '22023'; end if;
  insert into public.artefacts (centre_id, kind, source, student_id, plan_id, title, content, photo_path, generation_id, regenerated_from)
  values (p_centre, (p_artefact->>'kind')::public.artefact_kind, coalesce(p_artefact->>'source', 'made')::public.artefact_source,
          p_student, p_plan, p_artefact->>'title', coalesce(p_artefact->'content', '{}'::jsonb), p_artefact->>'photo_path',
          (p_artefact->>'generation_id')::uuid, (p_artefact->>'regenerated_from')::uuid)
  returning id into v_id;
  update public.plan_items i set artefact_id = v_id
   where i.centre_id = p_centre and i.plan_id = p_plan and i.kind = p_item_kind
     and ((p_student is null and i.group_no = p_group_no) or (p_student is not null and i.student_id = p_student));
  return v_id;
end $$;

revoke all on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind) from public, anon;
grant execute on function public.keep_artefact(uuid, jsonb, uuid, integer, uuid, public.plan_item_kind) to authenticated;

-- 5. The close also marks the plan's lines the tutor ticked (P10-Close's checklist): p_done, the item ids. The
--    eight-argument call of build 20 still resolves through the default.
drop function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb);

create function public.close_session(p_centre uuid, p_class uuid, p_date date, p_marks jsonb, p_checks jsonb,
                                     p_homework jsonb, p_track jsonb, p_states jsonb default '[]'::jsonb,
                                     p_done uuid[] default '{}') returns uuid
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
  update public.plan_items i set done_at = now()
   where i.centre_id = p_centre and i.plan_id = v_plan and i.id = any (p_done) and i.done_at is null;
  update public.attendance_sessions a set closed_at = now(), plan_id = v_plan where a.id = sid and a.centre_id = p_centre;
  return sid;
end $$;

revoke all on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb, uuid[]) from public, anon;
grant execute on function public.close_session(uuid, uuid, date, jsonb, jsonb, jsonb, jsonb, jsonb, uuid[]) to authenticated;
```

`plan_items.words` is the line as the plan made it ("Teach: Balancing equations"), so a plan read back offline or after a
skill was renamed shows what the tutor saw; the Phase 10 table had no column for the words.

- [ ] **Step 4: The seed's Evening batch** (append to `supabase/seed.sql`, after the Phase 11 block)

```sql
-- Phase 12: the Evening batch of twelve across three levels (docs/spec-v2.md section 6: "a batch of twelve costs about
-- what three groups cost"), for the hand runs and the cost run. Four of class 8 (Science from a captured book), four of
-- class 5 (the Maths book), four of class 2 (the ladder). V1's ten and their two batches stay as they were.
insert into public.classes (id, centre_id, name, subject, monthly_fee, meeting_days, start_time, end_time) values
  ('33333333-3333-3333-3333-333333333333', '22222222-2222-2222-2222-222222222222',
   'Evening batch', 'Science', 1200, '{1,2,3,4,5}', '17:00', '18:30');
insert into public.students (centre_id, class_id, name, parent_name, parent_phone, class_level, school_id, message_language) values
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Aarav Mehta', 'Rohit Mehta', '+919876500001', '8', '44444444-4444-4444-4444-444444444441', 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Diya Pillai', 'Anita Pillai', '+919876500002', '8', '44444444-4444-4444-4444-444444444441', 'hi'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Ishaan Bose', 'Rina Bose', '+919876500003', '8', '44444444-4444-4444-4444-444444444441', 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Kavya Nair', 'Suma Nair', '+919876500004', '8', '44444444-4444-4444-4444-444444444441', 'kn'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Rohan Gupta', 'Vijay Gupta', '+919876500005', '5', '44444444-4444-4444-4444-444444444441', 'hinglish'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Sneha Joshi', 'Meena Joshi', '+919876500006', '5', '44444444-4444-4444-4444-444444444441', 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Tanvi Kulkarni', 'Prasad Kulkarni', '+919876500007', '5', '44444444-4444-4444-4444-444444444441', 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Vihaan Rao', 'Priya Rao', '+919876500008', '5', '44444444-4444-4444-4444-444444444441', 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Anvi Shetty', 'Deepa Shetty', '+919876500009', '2', null, 'kn'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Dhruv Patel', 'Hema Patel', '+919876500010', '2', null, 'hi'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Myra Singh', 'Gurpreet Singh', '+919876500011', '2', null, 'en'),
  ('22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333', 'Zoya Khan', 'Farah Khan', '+919876500012', '2', null, 'en');
-- Two books at Vidya Niketan, copied to their classes (the class 5 book reaches Riya too).
insert into public.textbooks (id, centre_id, school_id, class_level, subject, title, chapters) values
  ('55555555-5555-5555-5555-555555555551', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', '8', 'Science', 'Science 8',
   '[{"position": 1, "name": "Crop production and management", "skills": ["Name the steps of crop production", "Tell kharif from rabi crops", "Explain why soil is loosened"]},
     {"position": 2, "name": "Microorganisms", "skills": ["Name the groups of microorganisms", "Give uses of microorganisms", "Explain how food is preserved"]},
     {"position": 3, "name": "Chemical reactions", "skills": ["Tell a physical from a chemical change", "Name the reactants", "Balance a chemical equation", "Name the types of reactions"]},
     {"position": 4, "name": "Force and pressure", "skills": ["Define force as a push or pull", "Tell contact from non-contact forces", "Explain pressure with examples"]}]'),
  ('55555555-5555-5555-5555-555555555552', '22222222-2222-2222-2222-222222222222', '44444444-4444-4444-4444-444444444441', '5', 'Mathematics', 'Math-Magic 5',
   '[{"position": 1, "name": "The Fish Tale", "skills": ["Compare lengths and weights", "Read large numbers", "Use units of measure"]},
     {"position": 2, "name": "Shapes and Angles", "skills": ["Name angles in shapes", "Tell right, acute and obtuse angles", "Measure turns"]},
     {"position": 3, "name": "How Many Squares?", "skills": ["Count squares in a shape", "Find the area on squared paper", "Draw shapes of equal area"]},
     {"position": 4, "name": "Parts and Wholes", "skills": ["Name a fraction of a whole", "Find equivalent fractions", "Compare simple fractions"]}]');
select public.copy_textbook_to_class('22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555551');
select public.copy_textbook_to_class('22222222-2222-2222-2222-222222222222', '55555555-5555-5555-5555-555555555552');
-- The class 8 four have the first two chapters taught; the class 5 four the first chapter; so the plan has a skill to
-- teach and the spaced queue something to check.
update public.skills k set state = 'practising', state_at = now() - interval '5 days'
  from public.chapters c
 where k.chapter_id = c.id and c.centre_id = '22222222-2222-2222-2222-222222222222' and c.textbook_id = '55555555-5555-5555-5555-555555555551' and c.position <= 2;
update public.skills k set state = 'secure', state_at = now() - interval '12 days'
  from public.chapters c
 where k.chapter_id = c.id and c.centre_id = '22222222-2222-2222-2222-222222222222' and c.textbook_id = '55555555-5555-5555-5555-555555555552' and c.position = 1;
-- The ladder for the class 2 four: three areas, five steps each (Domain's Ladder.Area.steps), the first two steps secure.
insert into public.chapters (centre_id, student_id, subject, position, name, ladder)
select s.centre_id, s.id, a.title, a.position, a.title, a.ladder
  from public.students s
  cross join (values ('Reading', 1, 'reading'), ('Writing', 2, 'writing'), ('Numbers', 3, 'numbers')) as a(title, position, ladder)
 where s.centre_id = '22222222-2222-2222-2222-222222222222' and s.class_id = '33333333-3333-3333-3333-333333333333' and s.class_level = '2';
insert into public.skills (centre_id, chapter_id, student_id, position, name, state, state_at)
select c.centre_id, c.id, c.student_id, st.position, st.name, case when st.position <= 2 then 'secure' else 'not_started' end, now() - interval '20 days'
  from public.chapters c
  cross join lateral (
    select * from unnest(case c.ladder
      when 'reading' then array['Letters', 'Words', 'Sentences', 'Paragraph', 'Story']
      when 'writing' then array['Traces', 'Letters', 'Words', 'Sentences', 'Short text']
      else array['To 9', 'To 99', 'Add', 'Subtract', 'Multiply'] end) with ordinality as st(name, position)) st
 where c.centre_id = '22222222-2222-2222-2222-222222222222' and c.ladder is not null
   and c.student_id in (select id from public.students where class_id = '33333333-3333-3333-3333-333333333333');
```

The Evening batch's students get this month's fees as the seed's fee block runs after them (move the Phase 12 block
above the fee block when appending, or the twelve have no fee row; the hand run does not need one either way).

- [ ] **Step 5: Regenerate the types and run the tests**

Run: `cd supabase && supabase db reset && supabase gen types typescript --local > types.ts && bun test tests`
Expected: PASS, the catalogue test included (no new table; two new functions granted to `authenticated` only).

- [ ] **Step 6: `bun check --only=db`, then commit**

```bash
git checkout -b phase-12/db
git add supabase/migrations/20261024000019_v2_plan_write_and_pattern.sql supabase/tests/v2.test.ts supabase/seed.sql supabase/types.ts
git commit -m "Database: make_plan, keep_artefact, the close's done lines, the batch's pattern; the seed's Evening batch"
```

Open PR 1; merge when green. Nothing on screen.

### Task 2: The API: the schemas and prompts of the plan's five kinds (PR 2)

**Files:**
- Modify: `api/src/schemas.ts` (`PlanInput` extended, `PlanOutput`, `SheetOutput`, `WorkedExampleOutput`,
  `FigureOutput`, `BriefOutput`; the sheet's `reason`), `api/src/errors.ts` (the figure's refusal words)
- Create: `api/src/prompts/plan.ts`, `sheet.ts`, `worked-example.ts`, `figure.ts`, `brief.ts`
- Test: `api/test/schemas.test.ts`, `api/test/prompts.test.ts`

**Interfaces:**
- Consumes: `ClaudeRequest<T>`, `modelFor(kind, classLevel)` (`models.ts`), `VOICE`, `QuestionSetOutput`.
- Produces: `PlanInput = { centreId, classId: guid | null, date, month: 1..12, groups: [{ groupNo: 1..3, classLevel,
  subject }] (1..3) }`; `PlanOutput = { groups: [{ groupNo, chapter, skill }] }`; `MakeInput` sheet gains `reason?:
  string (1..200)`; `SheetOutput = QuestionSetOutput`; `WorkedExampleOutput = { problem, steps: [{ title, working }]
  (2..6), slip }`; `FigureOutput = { figure: Figure, caption }` where `Figure` is a discriminated union on `kind` with
  the app's fields and rules; `BriefOutput = { about, mistakes: [{ title, howToCatch }] (3), workedExample: {
  problem, steps, slip }, words: [string] (3) }`; `request(...)` per prompt file as below.

- [ ] **Step 1: Write the failing schema tests** (append to `api/test/schemas.test.ts`; import the new names)

```ts
test("PlanInput names the month and up to three groups by class and subject, no student", () => {
  const ok = PlanInput.safeParse({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] });
  expect(ok.success).toBe(true);
  expect(PlanInput.safeParse({ centreId, classId: null, date: "2026-10-07", month: 13, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }).success).toBe(false);
  expect(PlanInput.safeParse({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [] }).success).toBe(false);
  expect(PlanInput.safeParse({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science", studentId: "x" }] }).success).toBe(false);
});

test("a sheet takes a reason to make it again, up to 200 characters", () => {
  expect(MakeInput.safeParse({ kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], reason: "easier" }).success).toBe(true);
  expect(MakeInput.safeParse({ kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], reason: "x".repeat(201) }).success).toBe(false);
});

test("the figure's spec is one of seven kinds and each kind's rule holds", () => {
  const ok = (figure: unknown) => FigureOutput.safeParse({ figure, caption: "Drawn from the skill." }).success;
  expect(ok({ kind: "number_line", from: 0, to: 20, step: 2, start: 4, jumps: [6, 6] })).toBe(true);
  expect(ok({ kind: "number_line", from: 0, to: 10, step: 1, start: 8, jumps: [5] })).toBe(false); // lands past the end
  expect(ok({ kind: "fraction_bar", parts: 4, shaded: 3, label: "3/4" })).toBe(true);
  expect(ok({ kind: "fraction_bar", parts: 4, shaded: 5, label: "5/4" })).toBe(false);
  expect(ok({ kind: "place_value", number: 4507 })).toBe(true);
  expect(ok({ kind: "place_value", number: 10_000_000 })).toBe(false);
  expect(ok({ kind: "unit_circle", angleDegrees: 30 })).toBe(true);
  expect(ok({ kind: "unit_circle", angleDegrees: 400 })).toBe(false);
  expect(ok({ kind: "triangle", angles: [90, 60, 30], labels: ["AB", "BC", "CA"] })).toBe(true);
  expect(ok({ kind: "triangle", angles: [90, 60, 40], labels: ["AB", "BC", "CA"] })).toBe(false);
  expect(ok({ kind: "labelled_cell", cell: "plant", labels: ["Cell wall", "Nucleus", "Chloroplast", "Vacuole", "Cytoplasm"] })).toBe(true);
  expect(ok({ kind: "labelled_cell", cell: "plant", labels: ["a", "b", "c", "d", "e", "f"] })).toBe(false);
  expect(ok({ kind: "food_chain", links: ["Grass", "Grasshopper", "Frog", "Snake"] })).toBe(true);
  expect(ok({ kind: "food_chain", links: ["Grass"] })).toBe(false);
  expect(ok({ kind: "pie_chart", slices: [1, 2] })).toBe(false);
});

test("the worked example has two to six steps and a slip; the brief has three mistakes and three lines to say", () => {
  const steps = [{ title: "Count the atoms", working: "H: 2 left, 2 right" }, { title: "Balance O", working: "Put 2 before H2O" }];
  expect(WorkedExampleOutput.safeParse({ problem: "Balance H2 + O2 → H2O", steps, slip: "Changing the small numbers." }).success).toBe(true);
  expect(WorkedExampleOutput.safeParse({ problem: "x", steps: steps.slice(0, 1), slip: "y" }).success).toBe(false);
  const brief = { about: "What happens in a reaction.", mistakes: [{ title: "Changing subscripts", howToCatch: "Ask what H2O becomes." }, { title: "Reactants and products swapped", howToCatch: "Point at the arrow." }, { title: "Ice melting called chemical", howToCatch: "Ask what new substance formed." }], workedExample: { problem: "Balance H2 + O2 → H2O", steps, slip: "Changing the small numbers." }, words: ["Only the numbers in front change.", "Count each atom on both sides.", "A new substance means a chemical change."] };
  expect(BriefOutput.safeParse(brief).success).toBe(true);
  expect(BriefOutput.safeParse({ ...brief, mistakes: brief.mistakes.slice(0, 2) }).success).toBe(false);
  expect(BriefOutput.safeParse({ ...brief, words: brief.words.slice(0, 2) }).success).toBe(false);
});

test("PlanOutput names a chapter and a skill per group", () => {
  expect(PlanOutput.safeParse({ groups: [{ groupNo: 1, chapter: "Chemical reactions", skill: "Balance a chemical equation" }] }).success).toBe(true);
  expect(PlanOutput.safeParse({ groups: [{ groupNo: 1, chapter: "" }] }).success).toBe(false);
});
```

- [ ] **Step 2: Write the failing prompt tests** (append to `api/test/prompts.test.ts`)

```ts
import { request as brief } from "../src/prompts/brief.js";
import { request as figure } from "../src/prompts/figure.js";
import { request as plan } from "../src/prompts/plan.js";
import { request as sheet } from "../src/prompts/sheet.js";
import { request as workedExample } from "../src/prompts/worked-example.js";

test("a sheet asks Haiku up to class 5 and Sonnet from class 6, names the skills and the count, and carries a reason when given", () => {
  const young = sheet({ kind: "sheet", centreId, classLevel: "5", subject: "Mathematics", skills: ["Compare simple fractions"], questions: 5, forHomework: true });
  expect(young.model).toBe("claude-haiku-5-5");
  expect(young.text).toContain("Exactly 5 questions");
  expect(young.text).toContain("homework");
  const older = sheet({ kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants"], questions: 10, forHomework: false, reason: "easier" });
  expect(older.model).toBe("claude-sonnet-5-5");
  expect(older.text).toContain('"Balance a chemical equation"');
  expect(older.text).toContain("Make it easier");
  expect(older.system).not.toContain("student's name");
});

test("a worked example asks Sonnet for steps the tutor says aloud and the common slip", () => {
  const r = workedExample("8", "Science", "Balance a chemical equation");
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.system).toContain("one step at a time");
  expect(r.text).toContain("Balance a chemical equation");
});

test("a figure asks Sonnet for one named template and says the rule the app checks", () => {
  const r = figure("fraction_bar", "5", "Mathematics", "Compare simple fractions");
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.text).toContain("fraction_bar");
  expect(r.system).toContain("parts");
  const chain = figure("food_chain", "7", "Science", "Explain a food chain");
  expect(chain.system).toContain("plant");
});

test("a brief asks Sonnet to write as a colleague, five minutes, for the chapter", () => {
  const r = brief("8", "Science", "Chemical reactions");
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.system).toContain("colleague");
  expect(r.text).toContain("Chemical reactions");
});

test("the plan's topics ask Sonnet for a first chapter and skill per group for the month of the school year", () => {
  const r = plan({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }, { groupNo: 2, classLevel: "2", subject: "Mathematics" }] });
  expect(r.model).toBe("claude-sonnet-5-5");
  expect(r.text).toContain("October");
  expect(r.text).toContain("Group 1: class 8 Science");
  expect(r.system).toContain("textbook");
});
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `cd api && bun test test/schemas.test.ts test/prompts.test.ts`
Expected: FAIL (the names are not exported; the prompt files do not exist).

- [ ] **Step 4: The schemas** (in `api/src/schemas.ts`, replacing `PlanInput` and the sheet entry of `MakeInput`,
  adding the outputs)

```ts
/** POST /ai/plan: the groups whose record names no skill yet (new students, no book). The API names a first chapter and
 *  skill per group for the class, subject and month of the school year. No student. */
export const PlanInput = z.object({
  ...V2,
  classId: z.guid().nullable(),
  date: Day,
  month: z.number().int().min(1).max(12),
  groups: z.array(z.object({ groupNo: z.number().int().min(1).max(3), classLevel: ClassLevel, subject: Subject }).strict()).min(1).max(3),
});
export type PlanInput = z.infer<typeof PlanInput>;
export const PlanOutput = z.object({ groups: z.array(z.object({ groupNo: z.number().int().min(1).max(3), chapter: Name, skill: Name })).min(1) });
export type PlanOutput = z.infer<typeof PlanOutput>;

// In MakeInput's sheet entry, after groupNo:
//   /** Make it again: one of the menu's words or the tutor's own, in the prompt (P10-Sheet-Regenerate). */
//   reason: z.string().min(1).max(200).optional(),
export type SheetInput = Extract<MakeInput, { kind: "sheet" }>;

/** A sheet is a question set (V1's homework and worksheet shape): the app's `SheetContent` decodes it. */
export const SheetOutput = QuestionSetOutput;
export type SheetOutput = z.infer<typeof SheetOutput>;

export const WorkedExampleOutput = z.object({
  problem: z.string().min(1).max(300),
  steps: z.array(z.object({ title: z.string().min(1).max(80), working: z.string().min(1).max(400) })).min(2).max(6),
  slip: z.string().min(1).max(300),
});
export type WorkedExampleOutput = z.infer<typeof WorkedExampleOutput>;

/** The seven figure templates (D59), each with the rule the app checks again before drawing (Domain's FigureSpec). */
const Label = z.string().min(1).max(40);
export const Figure = z.discriminatedUnion("kind", [
  z
    .object({ kind: z.literal("number_line"), from: z.number().int(), to: z.number().int(), step: z.number().int().min(1), start: z.number().int(), jumps: z.array(z.number().int()).min(1).max(8) })
    .refine((f) => f.from < f.to && (f.to - f.from) / f.step <= 40, { message: "the line has 1 to 40 steps" })
    .refine((f) => f.start >= f.from && f.start <= f.to, { message: "start is on the line" })
    .refine((f) => f.jumps.every((j) => j !== 0) && f.start + f.jumps.reduce((a, b) => a + b, 0) >= f.from && f.start + f.jumps.reduce((a, b) => a + b, 0) <= f.to, { message: "the landing is on the line" }),
  z.object({ kind: z.literal("fraction_bar"), parts: z.number().int().min(1).max(24), shaded: z.number().int().min(0), label: Label }).refine((f) => f.shaded <= f.parts, { message: "shaded parts fit the whole" }),
  z.object({ kind: z.literal("place_value"), number: z.number().int().min(0).max(9_999_999) }),
  z.object({ kind: z.literal("unit_circle"), angleDegrees: z.number().int().min(0).max(360) }),
  z.object({ kind: z.literal("triangle"), angles: z.array(z.number().int().min(1).max(178)).length(3), labels: z.array(Label).length(3) }).refine((f) => f.angles.reduce((a, b) => a + b, 0) === 180, { message: "the angles sum to 180" }),
  z.object({ kind: z.literal("labelled_cell"), cell: z.enum(["plant", "animal"]), labels: z.array(Label).min(1).max(5) }),
  z.object({ kind: z.literal("food_chain"), links: z.array(Label).min(2).max(6) }),
]);
export type Figure = z.infer<typeof Figure>;
export const FigureOutput = z.object({ figure: Figure, caption: z.string().min(1).max(200) });
export type FigureOutput = z.infer<typeof FigureOutput>;

export const BriefOutput = z.object({
  about: z.string().min(1).max(1200),
  mistakes: z.array(z.object({ title: z.string().min(1).max(80), howToCatch: z.string().min(1).max(300) })).length(3),
  workedExample: WorkedExampleOutput,
  words: z.array(z.string().min(1).max(160)).length(3),
});
export type BriefOutput = z.infer<typeof BriefOutput>;
```

`FigureKind` (Phase 10) stays as the input's template name; `Figure` is the output. A refinement that fails makes the
answer "unfit" (`claude.ts` reports it as refused), so `errors.refused("figure")` gets its words in `errors.ts`:
`figure: "Couldn't draw a figure for this skill. The plan goes on without it."`.

- [ ] **Step 5: The prompts**

`api/src/prompts/sheet.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type SheetInput, SheetOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const REASONS: Record<string, string> = {
  easier: "Make it easier: recall and one-step questions only.",
  harder: "Make it harder: application and two-step questions.",
  shorter: "Make it shorter: fewer, quicker questions.",
  "more sums": "More sums: numerical questions, fewer words.",
  "different numbers": "Keep the questions' shape and change every number.",
};

/** A group's practice set or homework sheet (P10-Sheet): questions on the skills named, for the class, with the answers
 *  for the tutor. Skills and a class only; no student is named. A reason comes from Make it again. */
export function request(input: SheetInput): ClaudeRequest<SheetOutput> {
  const reason = input.reason ? (REASONS[input.reason.toLowerCase()] ?? `The tutor asks: ${input.reason}`) : null;
  return {
    model: modelFor("sheet", input.classLevel),
    effort: "medium",
    system: [
      VOICE,
      input.forHomework
        ? "You set homework: short practice questions a student finishes in one evening, lighter for the younger classes."
        : "You write a practice set for one class sitting: questions the students work through while the tutor moves between them.",
      "Spread the questions across the skills named, in their order, easiest first.",
      "Give every question its answer, for the tutor. Instructions are one line for the student, or null. Number from 1. The title is the first skill.",
    ].join(" "),
    text: [
      `Class ${input.classLevel} ${input.subject}, ${input.forHomework ? "homework" : "a practice set"} on: ${input.skills.map((s) => `"${s}"`).join(", ")}.`,
      `Exactly ${input.questions} questions.`,
      reason,
    ].filter(Boolean).join("\n"),
    schema: SheetOutput,
  };
}
```

`api/src/prompts/worked-example.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type ClassLevel, WorkedExampleOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

/** The worked example for a skill (P10-WorkedExample): one problem a student of that class meets, solved one step at a
 *  time as the tutor says it aloud, and the common slip. */
export function request(classLevel: ClassLevel, subject: string, skill: string): ClaudeRequest<WorkedExampleOutput> {
  return {
    model: modelFor("worked_example", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write one worked example a tutor shows a class one step at a time, saying each step aloud before the next.",
      "Each step has a short title and the working in one or two lines; two to six steps.",
      "The slip is the one mistake students of that class make most on this skill, in one sentence that starts 'A common slip here:'.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}. One worked example for the skill "${skill}", with numbers from the class's textbook level.`,
    schema: WorkedExampleOutput,
  };
}
```

`api/src/prompts/figure.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type ClassLevel, type FigureKind, FigureOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const RULES: Record<FigureKind, string> = {
  number_line: "number_line: from, to, step, start and jumps; start and the landing (start plus the jumps) lie on the line; at most 40 steps.",
  fraction_bar: "fraction_bar: parts (1 to 24), shaded (at most parts) and the label as a fraction.",
  place_value: "place_value: one whole number up to 9,999,999.",
  unit_circle: "unit_circle: one angle in degrees, 0 to 360.",
  triangle: "triangle: three angles that sum to 180 and three side labels; use 90 for a right angle.",
  labelled_cell: "labelled_cell: plant or animal, and one to five part names as the class's chapter names them.",
  food_chain: "food_chain: two to six links, the first a plant, each eaten by the next.",
};

/** A figure's spec (D59): the app draws it; the model only fills the template's numbers and labels. */
export function request(kind: FigureKind, classLevel: ClassLevel, subject: string, skill: string): ClaudeRequest<FigureOutput> {
  return {
    model: modelFor("figure", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You fill one figure template with the numbers and labels that illustrate a skill; the app draws it.",
      RULES[kind],
      "The caption is one sentence the tutor can say while pointing at the figure.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}, the skill "${skill}". Fill the template ${kind}.`,
    schema: FigureOutput,
  };
}
```

`api/src/prompts/brief.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { BriefOutput, type ClassLevel } from "../schemas.js";
import { VOICE } from "./shared.js";

/** The tutor's brief for a chapter (P10-Brief): five minutes of reading before the class, as a colleague's note. */
export function request(classLevel: ClassLevel, subject: string, chapter: string): ClaudeRequest<BriefOutput> {
  return {
    model: modelFor("brief", classLevel),
    effort: "medium",
    system: [
      VOICE,
      "You write a colleague's note to a tutor about a chapter they teach this week: what it is about in one paragraph a tutor reads in a minute, the three mistakes students of that class make most with how to catch each in class, one worked example to use, and three lines to say in class.",
      "Plain, direct, no headings inside the fields, nothing copied from a textbook.",
    ].join(" "),
    text: `Class ${classLevel} ${subject}, the chapter "${chapter}".`,
    schema: BriefOutput,
  };
}
```

`api/src/prompts/plan.ts`:

```ts
import type { ClaudeRequest } from "../claude.js";
import { modelFor } from "../models.js";
import { type PlanInput, PlanOutput } from "../schemas.js";
import { VOICE } from "./shared.js";

const MONTHS = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

/** A first topic for a group whose record names none yet (plan decision 1): the chapter a class is usually at in that
 *  month of the Indian school year, and its first skill, as a skill name the app can teach and check. */
export function request(input: PlanInput): ClaudeRequest<PlanOutput> {
  return {
    model: modelFor("plan", input.groups[0]?.classLevel ?? "8"),
    effort: "medium",
    system: [
      VOICE,
      "For each group, name the chapter a class of that level is usually at in the given month of the school year (June to March) and one skill from it, as a short skill name a tutor can teach in one class and check with one question.",
      "Chapter names as the common textbook for that board and class prints them; no text from inside a book.",
    ].join(" "),
    text: [`${MONTHS[input.month - 1]}.`, ...input.groups.map((g) => `Group ${g.groupNo}: class ${g.classLevel} ${g.subject}.`)].join("\n"),
    schema: PlanOutput,
  };
}
```

- [ ] **Step 6: Run the tests to verify they pass**

Run: `cd api && bun run check`
Expected: PASS (`tsc` clean; the schema and prompt tests green).

- [ ] **Step 7: Commit**

```bash
git checkout -b phase-12/api
git add api/src/schemas.ts api/src/errors.ts api/src/prompts/plan.ts api/src/prompts/sheet.ts api/src/prompts/worked-example.ts api/src/prompts/figure.ts api/src/prompts/brief.ts api/test/schemas.test.ts api/test/prompts.test.ts
git commit -m "API: the plan's and the four artefacts' schemas and prompts"
```

### Task 3: The API: `/ai/plan` and `/ai/make` for sheet, worked example, figure and brief, with the fake (PR 2)

**Files:**
- Modify: `api/src/routes/v2.ts`, `api/src/claude-fake.ts` (five samples, `kindOf`, `localScript`), `api/CLAUDE.md`
- Test: `api/test/v2.test.ts`, `api/test/claude-fake.test.ts`

**Interfaces:**
- Consumes: Task 2's schemas and prompts; `run`, `parse`, `answer`, `notYet` (`routes/common.ts`); `fakeDb`.
- Produces: `POST /ai/plan` → `{ id, result: PlanOutput }`; `POST /ai/make` kinds `sheet`, `worked_example`, `figure`,
  `brief` → `{ id, result: <kind's output> }`; `mock` and the personal kinds still 501; `SAMPLE.plan`, `SAMPLE.sheet`,
  `SAMPLE.worked_example`, `SAMPLE.figure`, `SAMPLE.brief` (the boards' content: Group 1's balancing equations sheet of
  eight, the four-step worked example with the board's slip, the fraction bar 3 of 4, the Chemical reactions brief);
  `kindOf` tells the five apart by the prompt's words ("fill the template", "worked example", "colleague's note", "Group
  1:", "a practice set" or "homework" with the skills' quotes).

- [ ] **Step 1: Write the failing route tests** (append to `api/test/v2.test.ts`)

```ts
const sheet = { kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation", "Name the reactants"], questions: 8 };

test("make sheet answers a question set on Sonnet for class 8 and Haiku for class 5, recording the skills and no student", async () => {
  const claude = fakeClaude({ answer: SAMPLE.sheet });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/make", sheet);
  expect(r.status).toBe(200);
  const body = (await r.json()) as { id: string; result: { title: string; questions: { number: number; text: string; answer: string }[] } };
  expect(body.result.questions).toHaveLength(8);
  expect(db.started[0]).toMatchObject({ kind: "sheet", model: "claude-sonnet-5-5", input: { skills: sheet.skills, forHomework: false } });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
  const young = await post(app(fakeClaude({ answer: SAMPLE.sheet }), db), "/ai/make", { ...sheet, classLevel: "5", forHomework: true, questions: 5 });
  expect(young.status).toBe(200);
  expect(db.started[1]).toMatchObject({ model: "claude-haiku-5-5" });
});

test("make sheet with a reason passes it to the prompt and records it", async () => {
  const claude = fakeClaude({ answer: SAMPLE.sheet });
  const db = fakeDb();
  await post(app(claude, db), "/ai/make", { ...sheet, reason: "easier" });
  expect(claude.requests[0]?.text).toContain("Make it easier");
  expect(db.started[0]).toMatchObject({ input: { reason: "easier" } });
});

test("make worked_example, figure and brief answer their shapes on Sonnet", async () => {
  const db = fakeDb();
  const example = await post(app(fakeClaude({ answer: SAMPLE.worked_example }), db), "/ai/make", { kind: "worked_example", centreId, classLevel: "8", subject: "Science", skill: "Balance a chemical equation" });
  expect(example.status).toBe(200);
  expect(((await example.json()) as { result: { steps: unknown[] } }).result.steps).toHaveLength(4);
  const figure = await post(app(fakeClaude({ answer: SAMPLE.figure }), db), "/ai/make", { kind: "figure", centreId, figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" });
  expect(figure.status).toBe(200);
  expect(((await figure.json()) as { result: { figure: { kind: string } } }).result.figure.kind).toBe("fraction_bar");
  const brief = await post(app(fakeClaude({ answer: SAMPLE.brief }), db), "/ai/make", { kind: "brief", centreId, classLevel: "8", subject: "Science", chapter: "Chemical reactions" });
  expect(brief.status).toBe(200);
  expect(((await brief.json()) as { result: { mistakes: unknown[] } }).result.mistakes).toHaveLength(3);
  expect(db.started.map((s) => (s as { model: string }).model)).toEqual(["claude-sonnet-5-5", "claude-sonnet-5-5", "claude-sonnet-5-5"]);
});

test("a figure that fails its rule is refused in words and recorded as failed", async () => {
  const db = fakeDb();
  const r = await post(app(fakeClaude({ answer: { figure: { kind: "fraction_bar", parts: 4, shaded: 5, label: "5/4" }, caption: "x" } }), db), "/ai/make", { kind: "figure", centreId, figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "Compare simple fractions" });
  expect(r.status).toBe(422);
  expect(await r.json()).toEqual({ error: "Couldn't draw a figure for this skill. The plan goes on without it." });
  expect(db.finished[0]).toMatchObject({ status: "failed" });
});

test("plan names a first topic per group on Sonnet, with no student in the record", async () => {
  const claude = fakeClaude({ answer: SAMPLE.plan });
  const db = fakeDb();
  const r = await post(app(claude, db), "/ai/plan", { centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] });
  expect(r.status).toBe(200);
  expect(((await r.json()) as { result: { groups: { groupNo: number; chapter: string; skill: string }[] } }).result.groups[0]?.groupNo).toBe(1);
  expect(db.started[0]).toMatchObject({ kind: "plan", model: "claude-sonnet-5-5" });
  expect(JSON.stringify(db.started[0])).not.toContain("studentId");
});

test("no make kind of this phase takes a student; the mock and the personal kinds still answer 501", async () => {
  const db = fakeDb({ consent: false });
  expect((await post(app(undefined, db), "/ai/make", sheet)).status).toBe(200);
  expect((await post(app(undefined, db), "/ai/make", { ...sheet, studentId: "11111111-1111-1111-1111-111111111111" })).status).toBe(400);
  expect((await post(app(undefined, db), "/ai/make", { kind: "mock", centreId, classLevel: "8", subject: "Science", portions: ["Chemical reactions"], pattern: { marks: 25, durationMinutes: 40 } })).status).toBe(501);
  expect((await post(app(undefined, db), "/ai/make", { kind: "note", centreId, studentId: "11111111-1111-1111-1111-111111111111", studentName: "Dev", tutorName: "Meera", language: "en", week: { taught: [], right: [], practise: [], coming: [] } })).status).toBe(501);
});
```

And in `api/test/claude-fake.test.ts`:

```ts
test("kindOf tells the plan's five kinds apart and localScript answers each", () => {
  const sheetReq = sheetRequest({ kind: "sheet", centreId, classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8, forHomework: false });
  expect(kindOf(sheetReq)).toBe("sheet");
  expect(kindOf(workedExampleRequest("8", "Science", "Balance a chemical equation"))).toBe("worked_example");
  expect(kindOf(figureRequest("fraction_bar", "5", "Mathematics", "Compare simple fractions"))).toBe("figure");
  expect(kindOf(briefRequest("8", "Science", "Chemical reactions"))).toBe("brief");
  expect(kindOf(planRequest({ centreId, classId: null, date: "2026-10-07", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }))).toBe("plan");
  const figure = localScript(figureRequest("number_line", "3", "Mathematics", "Count on a number line"));
  expect((figure.answer as { figure: { kind: string } }).figure.kind).toBe("number_line");
});
```

`MakeInput`'s objects are `.strict()` for the five kinds of this phase so `studentId` is a 400 (the test above). The
sheet's `questions` answers follow the request's count in `localScript` (the sample's eight cut or repeated), so a
homework of five reads as five on screen.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `cd api && bun test test/v2.test.ts test/claude-fake.test.ts`
Expected: FAIL (501 for the four kinds and the plan; `SAMPLE.sheet` undefined).

- [ ] **Step 3: The route** (`api/src/routes/v2.ts`, the `/make` switch and a new `/plan`)

```ts
routes.post("/plan", async (c) => {
  const body = await parse(c, PlanInput);
  if (!isParsed(body)) return body;
  return run(c, deps, body.centre, { kind: "plan", input: body.value, request: planRequest(body.value) });
});
// In /make's switch:
case "sheet":
  return run(c, deps, body.centre, { kind: "sheet", input: v, request: sheetRequest(v) });
case "worked_example":
  return run(c, deps, body.centre, { kind: "worked_example", input: v, request: workedExampleRequest(v.classLevel, v.subject, v.skill) });
case "figure":
  return run(c, deps, body.centre, {
    kind: "figure", input: v, request: figureRequest(v.figure, v.classLevel, v.subject, v.skill),
    // The template asked for is the template answered; another is an unfit answer.
    empty: (made) => made.figure.kind !== v.figure,
  });
case "brief":
  return run(c, deps, body.centre, { kind: "brief", input: v, request: briefRequest(v.classLevel, v.subject, v.chapter) });
```

`run`'s `empty` path records failed and answers `errors.refused(kind)`, as the textbook's "no chapters" does. The fake:
`SAMPLE` gains the five samples (the boards' words); `kindOf` reads "Fill the template" → figure, "worked example" →
worked_example, "colleague's note" → brief, "Group 1:" → plan, "a practice set" or `homework on:` → sheet, before the V1
checks; `localScript` answers a figure with the template the prompt names (one fixed spec per kind) and a sheet with the
asked count.

- [ ] **Step 4: Run the tests, `bun check --only=api`, update `api/CLAUDE.md`'s V2 line (the five kinds live; `mock` and
  the personal kinds 501), commit**

```bash
git add api/src/routes/v2.ts api/src/claude-fake.ts api/test/v2.test.ts api/test/claude-fake.test.ts api/CLAUDE.md
git commit -m "API: /ai/plan live; /ai/make sheet, worked example, figure and brief with the fake"
```

Open PR 2; merge when green. Then Task 24 step 1 (the deploy).

### Task 4: Domain: the plan's types and the artefacts' contents (PR 3)

**Files:**
- Create: `Sources/Domain/Plan/PlanTypes.swift`, `Plan/Artefact.swift`, `Plan/PlanPattern.swift`,
  `Plan/RegenerateReason.swift`
- Test: `Tests/DomainTests/ArtefactContentTests.swift`, `PlanPatternTests.swift`, `PlanTypesTests.swift`

**Interfaces:**
- Consumes: `Skill`, `Chapter`, `ClassLevel`, `TrackStatus`, `Weekday`, `Day`, `FigureSpec` (Task 7).
- Produces:

```swift
/// One of the plan's level groups, as `plans.groups` keeps it.
public struct PlanGroup: Hashable, Sendable, Codable, Identifiable {
    public var id: Int { number }
    public let number: Int            // 1 to 3; Group 1 is the largest
    public let subject: String
    public let chapter: String        // the teach skill's chapter ("Chemical reactions")
    public let skill: String          // the group's teach skill
    public let classLevels: [ClassLevel]   // distinct, ascending, for the head ("Class 8 · 3 students")
    public let memberIDs: [UUID]      // the group's students, by name
    public let skillID: UUID?         // the skill row of the first member who has it; nil for a group named by /ai/plan
}
public enum PlanLineKind: String, Hashable, Sendable, Codable, CaseIterable { case teach, practise, check, homework, brief, catchUp = "catch_up" }
/// One line as the rules made it, before it is written.
public struct PlanLine: Hashable, Sendable, Codable {
    public let studentID: UUID?       // nil: the group's brief
    public let groupNo: Int
    public let kind: PlanLineKind
    public let skillID: UUID?
    public let words: String          // "Teach: Balancing equations"
    public let personalChecks: Bool   // a check line whose questions are the student's own (decision 5)
}
public struct PlanDraft: Hashable, Sendable {
    public let classID: UUID
    public let date: Day
    public let groups: [PlanGroup]
    public let lines: [PlanLine]
    public let leftOut: [UUID]        // students with no lines (left out today)
}
/// A line as read back (`plan_items`).
public struct PlanItem: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let studentID: UUID?
    public var groupNo: Int
    public let kind: PlanLineKind
    public let skillID: UUID?
    public let words: String
    public var artefactID: UUID?
    public var doneAt: Date?
    public var skippedAt: Date?
    public var movedFrom: Int?
}
/// The day's plan for a batch as read back, with its artefacts.
public struct PlanRecord: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID
    public let classID: UUID
    public let date: Day
    public let madeAt: Date
    public var groups: [PlanGroup]
    public var items: [PlanItem]
    public var artefacts: [Artefact]
    public var sessionID: UUID?
    public func items(of studentID: UUID) -> [PlanItem]
    public func artefact(_ id: UUID?) -> Artefact?
    /// The group's artefact of a kind (the sheet with `forHomework`, the checks, the worked example, the figure, the brief).
    public func artefact(group: Int, kind: ArtefactKind, homework: Bool? = nil) -> Artefact?
    public func checks(for studentID: UUID) -> Artefact?   // the student's own, else the group's
}
public enum ArtefactKind: String, Hashable, Sendable, Codable, CaseIterable {
    case sheet, workedExample = "worked_example", figure, brief, check, placement, mock, note, canDo = "can_do", testTomorrow = "test_tomorrow", gapReport = "gap_report"
}
public enum ArtefactSource: String, Hashable, Sendable, Codable { case made, own }
public struct SheetQuestion: Hashable, Sendable, Codable, Identifiable { public var id: Int { number }; public let number: Int; public let text: String; public let answer: String }
public struct SheetContent: Hashable, Sendable, Codable { public let title: String; public let instructions: String?; public let questions: [SheetQuestion]; public let forHomework: Bool; public let light: Bool }
public struct WorkedExample: Hashable, Sendable, Codable { public struct Step: Hashable, Sendable, Codable, Identifiable { public var id: String { title }; public let title: String; public let working: String }; public let problem: String; public let steps: [Step]; public let slip: String }
public struct FigureContent: Hashable, Sendable, Codable { public let figure: FigureSpec; public let caption: String }
public struct Brief: Hashable, Sendable, Codable { public struct Mistake: Hashable, Sendable, Codable, Identifiable { public var id: String { title }; public let title: String; public let howToCatch: String }; public let about: String; public let mistakes: [Mistake]; public let workedExample: WorkedExample; public let words: [String] }
public struct CheckContent: Hashable, Sendable, Codable { public struct Question: Hashable, Sendable, Codable { public let skillID: UUID; public let skill: String; public let question: String; public let answer: String }; public let questions: [Question]; public let placement: Bool }
public struct OwnContent: Hashable, Sendable, Codable { public let text: String?; public let inPlaceOf: String }   // "sheet 1"
public enum ArtefactContent: Hashable, Sendable {
    case sheet(SheetContent), workedExample(WorkedExample), figure(FigureContent), brief(Brief), check(CheckContent), own(OwnContent), other
}
public struct Artefact: Hashable, Sendable, Codable, Identifiable {
    public let id: UUID; public let kind: ArtefactKind; public let source: ArtefactSource; public let title: String
    public let content: ArtefactContent; public let photoPath: String?; public let studentID: UUID?; public let planID: UUID?
    public let regeneratedFrom: UUID?; public let madeAt: Date
    /// "8 questions · for Dev, Meher and Nikhil · made today, 16:40" needs the names: the screen adds them.
    public var countLine: String?   // "8 questions", "4 steps", nil
}
/// The batch's kept pattern for a weekday (`classes.plan_pattern`): the group count and each group's subject.
public struct PlanPattern: Hashable, Sendable, Codable { public let groups: Int; public let subjects: [String] }
public enum RegenerateReason: Hashable, Sendable { case easier, harder, shorter, moreSums, differentNumbers, own(String)
    public var words: String   // "easier", … or the tutor's text (trimmed, at most 200 scalars)
    public var title: String   // "Making it easier", "Making it with more sums", "Making it as you asked"
}
```

`ArtefactContent` decodes from the jsonb by the artefact's kind with `JSONDecoder.keyDecodingStrategy =
.convertFromSnakeCase` (`for_homework`, `how_to_catch`, `worked_example`, `in_place_of`); a kind this build does not know,
or content that does not fit, is `.other` (the row shows its title, nothing fails). Encoding goes the other way
(`.convertToSnakeCase`) for `keep_artefact`'s `content`. `FigureSpec` has its own coding (Task 7), nested under
`figure`.

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
@testable import Domain

struct ArtefactContentTests {
    static let decoder: JSONDecoder = { let d = JSONDecoder(); d.dateDecodingStrategy = .iso8601; return d }()

    @Test func aSheetDecodesFromTheApisKeys() throws {
        let json = #"{"title":"Balancing equations","instructions":null,"questions":[{"number":1,"text":"Balance H2 + O2 → H2O","answer":"2H2 + O2 → 2H2O"}],"for_homework":true,"light":false}"#
        let content = try ArtefactContent.decode(kind: .sheet, json: Data(json.utf8))
        guard case let .sheet(sheet) = content else { Issue.record("not a sheet"); return }
        #expect(sheet.forHomework)
        #expect(sheet.questions.count == 1)
        #expect(sheet.instructions == nil)
    }

    @Test func aBriefCarriesItsWorkedExampleAndThreeLines() throws {
        let json = #"{"about":"A","mistakes":[{"title":"T","how_to_catch":"H"},{"title":"T2","how_to_catch":"H"},{"title":"T3","how_to_catch":"H"}],"worked_example":{"problem":"P","steps":[{"title":"S","working":"W"},{"title":"S2","working":"W"}],"slip":"A common slip here: x"},"words":["a","b","c"]}"#
        guard case let .brief(brief) = try ArtefactContent.decode(kind: .brief, json: Data(json.utf8)) else { Issue.record("not a brief"); return }
        #expect(brief.mistakes[0].howToCatch == "H")
        #expect(brief.workedExample.steps.count == 2)
        #expect(brief.words.count == 3)
    }

    @Test func aFigureDecodesByItsKind() throws {
        let json = #"{"figure":{"kind":"fraction_bar","parts":4,"shaded":3,"label":"3/4"},"caption":"Three of four equal parts."}"#
        guard case let .figure(figure) = try ArtefactContent.decode(kind: .figure, json: Data(json.utf8)) else { Issue.record("not a figure"); return }
        #expect(figure.figure == .fractionBar(parts: 4, shaded: 3, label: "3/4"))
    }

    @Test func anUnknownKindOrAnUnfitContentReadsAsOther() throws {
        #expect(try ArtefactContent.decode(kind: .mock, json: Data("{}".utf8)) == .other)
        #expect(try ArtefactContent.decode(kind: .sheet, json: Data(#"{"title":1}"#.utf8)) == .other)
    }

    @Test func aContentEncodesWithSnakeCaseKeys() throws {
        let sheet = SheetContent(title: "T", instructions: nil, questions: [], forHomework: true, light: true)
        let data = try ArtefactContent.sheet(sheet).encoded()
        let text = String(decoding: data, as: UTF8.self)
        #expect(text.contains("\"for_homework\":true"))
        #expect(!text.contains("forHomework"))
    }

    @Test func theCountLineNamesQuestionsAndSteps() {
        #expect(Artefact.countLine(for: .sheet(SheetContent(title: "T", instructions: nil, questions: Array(repeating: SheetQuestion(number: 1, text: "q", answer: "a"), count: 8), forHomework: false, light: false))) == "8 questions")
        #expect(Artefact.countLine(for: .workedExample(WorkedExample(problem: "p", steps: [.init(title: "a", working: "w"), .init(title: "b", working: "w")], slip: "s"))) == "2 steps")
        #expect(Artefact.countLine(for: .other) == nil)
    }
}

struct PlanTypesTests {
    @Test func aRecordFindsAStudentsItemsAndTheGroupsArtefacts() {
        let dev = UUID(), riya = UUID(), sheetID = UUID(), checksID = UUID(), ownChecks = UUID()
        let sheet = Artefact(id: sheetID, kind: .sheet, source: .made, title: "s", content: .sheet(SheetContent(title: "s", instructions: nil, questions: [], forHomework: true, light: false)), photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: FakeClock.oct7at1635)
        let groupChecks = Artefact(id: checksID, kind: .check, source: .made, title: "c", content: .check(CheckContent(questions: [], placement: false)), photoPath: nil, studentID: nil, planID: nil, regeneratedFrom: nil, madeAt: FakeClock.oct7at1635)
        let riyasChecks = Artefact(id: ownChecks, kind: .check, source: .made, title: "c", content: .check(CheckContent(questions: [], placement: true)), photoPath: nil, studentID: riya, planID: nil, regeneratedFrom: nil, madeAt: FakeClock.oct7at1635)
        let record = PlanRecord(id: UUID(), classID: UUID(), date: Day(iso: "2026-10-07")!, madeAt: FakeClock.oct7at1635, groups: [], items: [
            PlanItem(id: UUID(), studentID: dev, groupNo: 1, kind: .homework, skillID: nil, words: "Homework sheet 1", artefactID: sheetID, doneAt: nil, skippedAt: nil, movedFrom: nil),
            PlanItem(id: UUID(), studentID: dev, groupNo: 1, kind: .check, skillID: nil, words: "Check 3", artefactID: checksID, doneAt: nil, skippedAt: nil, movedFrom: nil),
            PlanItem(id: UUID(), studentID: riya, groupNo: 1, kind: .check, skillID: nil, words: "Placement, her first checks", artefactID: ownChecks, doneAt: nil, skippedAt: nil, movedFrom: nil),
        ], artefacts: [sheet, groupChecks, riyasChecks], sessionID: nil)
        #expect(record.items(of: dev).count == 2)
        #expect(record.artefact(group: 1, kind: .sheet, homework: true)?.id == sheetID)
        #expect(record.checks(for: dev)?.id == checksID)
        #expect(record.checks(for: riya)?.id == ownChecks)
    }
}

struct PlanPatternTests {
    @Test func aPatternRoundTripsByWeekdayKey() throws {
        let kept: [Weekday: PlanPattern] = [.wednesday: PlanPattern(groups: 2, subjects: ["Science", "Mathematics"])]
        let data = try PlanPattern.encode(kept)
        #expect(String(decoding: data, as: UTF8.self).contains("\"3\":"))
        #expect(try PlanPattern.decode(data) == kept)
    }

    @Test func aReasonHasItsWordsAndTitle() {
        #expect(RegenerateReason.moreSums.words == "more sums")
        #expect(RegenerateReason.moreSums.title == "Making it with more sums")
        #expect(RegenerateReason.easier.title == "Making it easier")
        #expect(RegenerateReason.own("  Use fractions only  ").words == "Use fractions only")
        #expect(RegenerateReason.own(String(repeating: "x", count: 300)).words.storedCount == 200)
        #expect(RegenerateReason.own("y").title == "Making it as you asked")
    }
}
```

- [ ] **Step 2: Run to verify they fail** (`bun check --only=ios` fails to build: the types do not exist).
- [ ] **Step 3: Write the types** as the interface above, with `ArtefactContent.decode(kind:json:) throws`,
  `encoded() throws -> Data`, `Artefact.countLine(for:)` ("n questions", "n steps", nil), `PlanPattern.encode/decode`
  keyed by the weekday's raw value as a string, `RegenerateReason.words` trimmed and cut to 200 scalars
  (`String.storedCount`, D48).
- [ ] **Step 4: Run the tests** (`bun check --only=format,lint,ios`): PASS.
- [ ] **Step 5: Commit** on `phase-12/domain`: `git commit -m "Domain: the plan's types and the artefacts' contents"`.

### Task 5: Domain: the plan's rules (PR 3)

**Files:**
- Create: `Sources/Domain/Plan/PlanRules.swift`
- Test: `Tests/DomainTests/PlanRulesTests.swift`

**Interfaces:**
- Consumes: `Student` (`classLevel`, `trackStatus`, `name`, `gender`), `Classroom` (`subject`, `plan_groups` as
  `planGroups: Int?`, `planPattern: [Weekday: PlanPattern]`, both added to `Classroom` here with defaults nil and `[:]`
  so V1 rows decode), `Chapter`, `Skill`, `AttendanceSession`, `TrackingRules.currentSkill`, `SpacedQueue.pick`,
  `Placement.groups`.
- Produces:

```swift
/// What the rules read for one batch.
public struct PlanInput: Sendable {
    public let classroom: Classroom
    public let date: Day
    public let students: [Student]                    // the batch's active members
    public let chapters: [UUID: [Chapter]]            // by student
    public let skills: [UUID: [Skill]]
    public let sessions: [AttendanceSession]          // the batch's, any month, for the catch-up line
    public let schoolItems: [SchoolItemHint]          // Phase 13 fills it; [] now
    public let now: Date
    public let calendar: Calendar
    /// Today's choices from the Change sheet (nil: the batch's kept pattern, else the rules).
    public let groupCount: Int?
    public let subjects: [Int: String]                // by group number
}
public struct SchoolItemHint: Hashable, Sendable { public let studentID: UUID; public let subject: String; public let date: Day }
public enum PlanRules {
    public static let maxGroups = 3, catchUpAfterAbsences = 2, schoolItemWindowDays = 14
    /// The draft: groups (largest first), one teach, practise, check and homework line per student (a catch-up line
    /// before the teach line when the student missed the last two), a brief line per qualifying group. A group whose
    /// members have no skill in its subject has `skill == ""` and `chapter == ""`: the maker asks /ai/plan for them.
    public static func plan(_ input: PlanInput) -> PlanDraft
    static func levelKey(_ student: Student) -> Int
    static func groups(_ students: [Student], count: Int?) -> [[Student]]
    static func subject(for student: Student, input: PlanInput) -> String
    static func groupSubject(_ members: [Student], input: PlanInput, override: String?) -> String
    static func teachSkill(for student: Student, subject: String, input: PlanInput) -> Skill?
    static func catchUp(for student: Student, input: PlanInput) -> String?   // "Catch up: missed Mon and Fri"
    public static func homeworkWords(_ level: ClassLevel?) -> String        // "Homework sheet 1" / "Homework sheet 1, light"
    public static func pronoun(_ student: Student) -> String                 // "her", "his", "their" (the placement line)
}
```

- [ ] **Step 1: Write the failing tests** (the helpers `student(_:class:status:)`, `batch(…)` build a `PlanInput`
  from names, class levels and a book per student; the file's own, built on `RecordFixtures`)

```swift
import Foundation
import Testing
@testable import Domain

struct PlanRulesTests {
    let calendar = DayHeading.india
    let evening = Classroom(id: UUID(), name: "Evening batch", subject: "Science", monthlyFee: nil, meetingDays: [.monday, .tuesday, .wednesday, .thursday, .friday], startTime: TimeOfDay(hour: 17, minute: 0), endTime: TimeOfDay(hour: 18, minute: 30), archivedAt: nil)

    func student(_ name: String, class level: ClassLevel?, status: TrackStatus = .onTrack, gender: Gender? = nil) -> Student {
        Student(id: UUID(), name: name, classID: evening.id, monthlyFee: nil, parentName: nil, parentPhone: nil, dateOfBirth: nil, gender: gender, notes: nil, archivedAt: nil, thisMonth: nil, classLevel: level, trackStatus: status)
    }

    /// A Science book of three chapters, the first `taught` chapters practising, for a student.
    func science(_ s: Student, taught: Int) -> (chapters: [Chapter], skills: [Skill]) {
        let chapters = (1 ... 3).map { chapter($0, subject: "Science") }
        let skills = chapters.flatMap { c in (1 ... 2).map { skill(c, $0, state: c.position <= taught ? .practising : .notStarted, stateAt: FakeClock.at(2026, 10, 7 - c.position, 17, 0), name: "Science \(c.position).\($0)") } }
        return (chapters, skills)
    }

    func input(_ students: [Student], books: [UUID: (chapters: [Chapter], skills: [Skill])], sessions: [AttendanceSession] = [], groupCount: Int? = nil, subjects: [Int: String] = [:], classroom: Classroom? = nil) -> PlanInput {
        PlanInput(classroom: classroom ?? evening, date: Day(iso: "2026-10-07")!, students: students, chapters: books.mapValues(\.chapters), skills: books.mapValues(\.skills), sessions: sessions, schoolItems: [], now: FakeClock.oct7at1635, calendar: calendar, groupCount: groupCount, subjects: subjects)
    }

    @Test func threeLevelsMakeThreeGroupsLargestFirst() {
        let dev = student("Dev", class: .eight), meher = student("Meher", class: .eight), nikhil = student("Nikhil", class: .eight)
        let riya = student("Riya", class: .five), sahil = student("Sahil", class: .two)
        let books = Dictionary(uniqueKeysWithValues: [dev, meher, nikhil].map { ($0.id, science($0, taught: 2)) })
        let draft = PlanRules.plan(input([riya, sahil, dev, meher, nikhil], books: books))
        #expect(draft.groups.map(\.number) == [1, 2, 3])
        #expect(draft.groups[0].memberIDs == [dev.id, meher.id, nikhil.id])
        #expect(draft.groups[0].classLevels == [.eight])
        #expect(draft.groups[1].memberIDs == [riya.id])
        #expect(draft.groups[2].memberIDs == [sahil.id])
    }

    @Test func aKeptGroupCountCutsAtTheLargestGaps() {
        let students = [student("A", class: .eight), student("B", class: .seven), student("C", class: .three), student("D", class: .two)]
        let two = PlanRules.plan(input(students, books: [:], groupCount: 2))
        #expect(two.groups.count == 2)
        #expect(Set(two.groups[0].memberIDs) == Set(students.prefix(2).map(\.id)))
        let one = PlanRules.plan(input(students, books: [:], groupCount: 1))
        #expect(one.groups.count == 1)
        #expect(one.groups[0].memberIDs.count == 4)
    }

    @Test func aStudentNotOnTrackSitsOneLevelDown() {
        let a = student("A", class: .eight), b = student("B", class: .eight, status: .notOnTrack), c = student("C", class: .seven)
        let draft = PlanRules.plan(input([a, b, c], books: [:], groupCount: 2))
        let withB = draft.groups.first { $0.memberIDs.contains(b.id) }!
        #expect(withB.memberIDs.contains(c.id))
        #expect(!withB.memberIDs.contains(a.id))
    }

    @Test func aBatchOfOneHasOneGroup() {
        let dev = student("Dev", class: .eight)
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.groups.count == 1)
        #expect(draft.lines.filter { $0.studentID == dev.id }.map(\.kind) == [.teach, .practise, .check, .homework])
    }

    @Test func theTeachLineIsTheFirstSkillNotSecureAndTheGroupTakesItsChapter() {
        let dev = student("Dev", class: .eight)
        let book = science(dev, taught: 2)
        let draft = PlanRules.plan(input([dev], books: [dev.id: book]))
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach: Science 1.1")
        #expect(draft.groups[0].chapter == "Chapter 1")
        #expect(draft.groups[0].skill == "Science 1.1")
        #expect(draft.groups[0].skillID == book.skills[0].id)
    }

    @Test func watchAndNotOnTrackTeachAgainWithTheWorkedExample() {
        let dev = student("Dev", class: .eight, status: .watch)
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach again: Science 1.1, with the worked example")
        #expect(draft.lines.first { $0.kind == .check }?.personalChecks == true)
    }

    @Test func twoAbsencesRunningAddACatchUpLineBeforeTheTeachLine() {
        let dev = student("Dev", class: .eight)
        let mon = AttendanceSession(id: UUID(), classID: evening.id, date: Day(iso: "2026-10-05")!, savedAt: FakeClock.oct7at1635, marks: [dev.id: .absent])
        let tue = AttendanceSession(id: UUID(), classID: evening.id, date: Day(iso: "2026-10-06")!, savedAt: FakeClock.oct7at1635, marks: [dev.id: .absent])
        let draft = PlanRules.plan(input([dev], books: [dev.id: science(dev, taught: 1)], sessions: [mon, tue]))
        let devs = draft.lines.filter { $0.studentID == dev.id }
        #expect(devs.map(\.kind) == [.catchUp, .teach, .practise, .check, .homework])
        #expect(devs[0].words == "Catch up: missed Mon and Tue · then Science 1.1")
        #expect(devs[3].personalChecks)
    }

    @Test func nothingTaughtYetMakesAPlacementLineWithThePronoun() {
        let riya = student("Riya", class: .five, gender: .female)
        let book = science(riya, taught: 0)
        let draft = PlanRules.plan(input([riya], books: [riya.id: book]))
        #expect(draft.lines.first { $0.kind == .check }?.words == "Placement, her first checks")
        #expect(draft.lines.first { $0.kind == .check }?.personalChecks == true)
        #expect(draft.lines.first { $0.kind == .teach }?.words == "Teach: Science 1.1")
    }

    @Test func theSubjectIsTheLeastRecentlyTaughtUnlessTheWeekdayPatternSaysAnother() {
        let dev = student("Dev", class: .eight)
        let science = self.science(dev, taught: 2)
        let mathsChapter = chapter(1, subject: "Mathematics")
        let maths = (chapters: [mathsChapter], skills: [skill(mathsChapter, 1, state: .practising, stateAt: FakeClock.at(2026, 9, 20, 17, 0), name: "Maths 1.1")])
        let book = (chapters: science.chapters + maths.chapters, skills: science.skills + maths.skills)
        let draft = PlanRules.plan(input([dev], books: [dev.id: book]))
        #expect(draft.groups[0].subject == "Mathematics")
        var patterned = evening
        patterned.planPattern = [.wednesday: PlanPattern(groups: 1, subjects: ["Science"])]
        let kept = PlanRules.plan(input([dev], books: [dev.id: book], classroom: patterned))
        #expect(kept.groups[0].subject == "Science")
        let chosen = PlanRules.plan(input([dev], books: [dev.id: book], subjects: [1: "Science"]))
        #expect(chosen.groups[0].subject == "Science")
    }

    @Test func aSubjectNeverTaughtComesBeforeOneTaughtLongAgo() {
        let dev = student("Dev", class: .eight)
        let science = self.science(dev, taught: 1)
        let english = chapter(1, subject: "English")
        let book = (chapters: science.chapters + [english], skills: science.skills + [skill(english, 1, name: "English 1.1")])
        #expect(PlanRules.plan(input([dev], books: [dev.id: book])).groups[0].subject == "English")
    }

    @Test func theGroupsSubjectIsTheMostCommonAndEveryLineFollowsIt() {
        let a = student("A", class: .eight), b = student("B", class: .eight), c = student("C", class: .eight)
        let maths = chapter(1, subject: "Mathematics")
        let scienceBook = { (s: Student) in self.science(s, taught: 1) }
        let mathsBook = (chapters: [maths], skills: [skill(maths, 1, name: "Maths 1.1")])
        let draft = PlanRules.plan(input([a, b, c], books: [a.id: scienceBook(a), b.id: scienceBook(b), c.id: mathsBook]))
        #expect(draft.groups[0].subject == "Science")
        #expect(draft.lines.first { $0.studentID == c.id && $0.kind == .teach }?.words == "Teach: Science 1.1")
    }

    @Test func aBatchWithNoRecordIsPlannedByClass() {
        let a = student("A", class: .eight), b = student("B", class: .five)
        let draft = PlanRules.plan(input([a, b], books: [:]))
        #expect(draft.groups.count == 2)
        #expect(draft.groups.allSatisfy { $0.skill.isEmpty && $0.chapter.isEmpty && $0.skillID == nil })
        #expect(draft.groups[0].subject == "Science")
        #expect(draft.lines.filter { $0.kind == .teach }.allSatisfy { $0.words == "Teach: with the group" })
    }

    @Test func aStudentWithNoClassFollowsTheGroup() {
        let dev = student("Dev", class: .eight), bir = student("Bir", class: nil)
        let draft = PlanRules.plan(input([dev, bir], books: [dev.id: science(dev, taught: 1)]))
        #expect(draft.groups.count == 1)
        #expect(draft.lines.first { $0.studentID == bir.id && $0.kind == .teach }?.words == "Teach: Science 1.1")
        #expect(draft.lines.first { $0.studentID == bir.id && $0.kind == .check }?.personalChecks == false)
    }

    @Test func homeworkIsLightUpToClassFive() {
        #expect(PlanRules.homeworkWords(.five) == "Homework sheet 1, light")
        #expect(PlanRules.homeworkWords(.six) == "Homework sheet 1")
        #expect(PlanRules.homeworkWords(nil) == "Homework sheet 1")
    }

    @Test func aBriefLineComesForAGroupAboveClassSeven() {
        let dev = student("Dev", class: .eight), riya = student("Riya", class: .five)
        let draft = PlanRules.plan(input([dev, riya], books: [dev.id: science(dev, taught: 1), riya.id: science(riya, taught: 1)]))
        let briefs = draft.lines.filter { $0.kind == .brief }
        #expect(briefs.count == 1)
        #expect(briefs[0].groupNo == draft.groups.first { $0.memberIDs == [dev.id] }?.number)
        #expect(briefs[0].words == "Your brief · Chapter 1")
    }

    @Test func aStudentIsNeverInTwoGroupsAndEveryoneIsPlaced() {
        let students = (1 ... 12).map { student("S\($0)", class: ClassLevel.allCases[$0 % 12]) }
        let draft = PlanRules.plan(input(students, books: [:]))
        let placed = draft.groups.flatMap(\.memberIDs)
        #expect(Set(placed).count == 12)
        #expect(placed.count == 12)
        #expect(draft.groups.count == 3)
    }
}
```

- [ ] **Step 2: Run to verify they fail**, then **Step 3: write `PlanRules`** to the interface: the level key
  (`ClassLevel.allCases.firstIndex` or `-1` for none, minus one for `notOnTrack`), the cut at the largest gaps (sort the
  gaps between neighbours in the sorted list, take the `count - 1` largest, later gap first on ties), the numbering by
  size then level, the subject rules, `teachSkill` as `TrackingRules.currentSkill` over the subject's chapters, the
  words exactly as the tests read them, `pronoun` from `gender` (female "her", male "his", else "their"). A student with
  no class level takes the level key of the batch's most common level so they join the largest group.
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** `git commit -m "Domain: the plan's rules"`.

### Task 6: Domain: the artefact budget and the price sheet (PR 3)

**Files:**
- Create: `Sources/Domain/Plan/ArtefactBudget.swift`
- Test: `Tests/DomainTests/ArtefactBudgetTests.swift`, `Tests/DomainTests/PriceSheet.swift` (a test helper)

**Interfaces:**
- Consumes: `PlanDraft`, `PlanGroup`, `PlanLine`, `FigureSpec.Kind.matching(skill:)` (Task 7), `ClassLevel`.
- Produces:

```swift
/// One call the plan will make, in the order to make it.
public enum ArtefactRequest: Hashable, Sendable {
    case checks(group: Int, skills: [String], skillIDs: [UUID], classLevel: ClassLevel, subject: String)
    case personalChecks(studentID: UUID, skills: [String], skillIDs: [UUID], classLevel: ClassLevel, subject: String)
    case placement(studentID: UUID, classLevel: ClassLevel)       // the maker builds the subjects from Placement.groups
    case sheet(group: Int, skills: [String], classLevel: ClassLevel, subject: String, questions: Int, forHomework: Bool)
    case workedExample(group: Int, skill: String, classLevel: ClassLevel, subject: String)
    case figure(group: Int, kind: FigureSpec.Kind, skill: String, classLevel: ClassLevel, subject: String)
    case brief(group: Int, chapter: String, classLevel: ClassLevel, subject: String)
    public var groupNo: Int?
}
public enum ArtefactBudget {
    public static let maxPersonalChecks = 4, maxCalls = 20, setQuestions = 10, homeworkQuestions = 10, lightHomeworkQuestions = 5
    /// `briefsMade`: chapter names a brief exists for (the tutor asked before). `spacedSkills`: per student, the
    /// spaced queue's pick (names and ids), for the group's two spaced questions and the personal checks.
    public static func requests(for draft: PlanDraft, students: [UUID: Student], spacedSkills: [UUID: [Skill]], briefsMade: Set<String>) -> [ArtefactRequest]
    /// The group's class for the model's sake: the highest level among its members (a group spans a class at most two apart).
    static func classLevel(of group: PlanGroup, students: [UUID: Student]) -> ClassLevel
}
```

- [ ] **Step 1: Write the failing tests**

```swift
import Foundation
import Testing
@testable import Domain

/// The price sheet the budget is tested against (plan decision 6): USD per million tokens, the rupee at 85, and the
/// typical tokens per kind (the cost run of Task 24 replaces these with the measured figures).
enum PriceSheet {
    static let rupeesPerDollar = 85.0
    struct Model { let input: Double; let output: Double }
    static let haiku = Model(input: 0.10, output: 0.50), sonnet = Model(input: 2, output: 10), opus = Model(input: 4, output: 20)
    struct Typical { let tokensIn: Int; let tokensOut: Int }
    static func typical(_ request: ArtefactRequest) -> Typical {
        switch request {
        case .checks, .personalChecks, .placement: Typical(tokensIn: 700, tokensOut: 250)
        case .sheet: Typical(tokensIn: 900, tokensOut: 1400)
        case .workedExample: Typical(tokensIn: 700, tokensOut: 700)
        case .figure: Typical(tokensIn: 700, tokensOut: 200)
        case .brief: Typical(tokensIn: 800, tokensOut: 1300)
        }
    }
    static func model(_ request: ArtefactRequest) -> Model {
        switch request {
        case .checks, .personalChecks, .placement: haiku
        case let .sheet(_, _, level, _, _, _): level <= .five ? haiku : sonnet
        case .workedExample, .figure, .brief: sonnet
        }
    }
    static func rupees(_ requests: [ArtefactRequest]) -> Double {
        requests.reduce(0) { sum, r in
            let t = typical(r), m = model(r)
            return sum + (Double(t.tokensIn) * m.input + Double(t.tokensOut) * m.output) / 1_000_000 * rupeesPerDollar
        }
    }
}

struct ArtefactBudgetTests {
    // Builds a draft of n students in groups by class, with a Science book each, the first chapter taught (PlanRules).
    func draft(_ levels: [ClassLevel], statuses: [TrackStatus] = []) -> (draft: PlanDraft, students: [UUID: Student], spaced: [UUID: [Skill]]) { /* the file's helper on PlanRulesTests' builders */ }

    @Test func threeGroupsOfOneGetTheGroupsSixKindsAtMost() {
        let (d, students, spaced) = draft([.eight, .five, .two])
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        let group1 = requests.filter { $0.groupNo == 1 }
        #expect(group1.map(\.kindName) == ["checks", "sheet", "sheet", "workedExample", "brief"])   // no figure: the skill names none
        #expect(requests.filter { $0.groupNo == 3 }.map(\.kindName) == ["checks", "sheet", "sheet", "workedExample"])
    }

    @Test func aTwelveStudentBatchCostsWhatThreeGroupsCostPlusPersonalChecks() {
        let twelve = draft(Array(repeating: .eight, count: 4) + Array(repeating: .five, count: 4) + Array(repeating: .two, count: 4), statuses: [.watch, .notOnTrack])
        let three = draft([.eight, .five, .two])
        let big = ArtefactBudget.requests(for: twelve.draft, students: twelve.students, spacedSkills: twelve.spaced, briefsMade: [])
        let small = ArtefactBudget.requests(for: three.draft, students: three.students, spacedSkills: three.spaced, briefsMade: [])
        let personal = big.filter { if case .personalChecks = $0 { true } else { false } }
        #expect(big.count - personal.count == small.count)
        #expect(personal.count == 2)
        #expect(PriceSheet.rupees(big) < 10)
    }

    @Test func personalChecksAreCappedAtFourAndTheRestTakeTheGroups() {
        let (d, students, spaced) = draft(Array(repeating: .eight, count: 8), statuses: Array(repeating: .watch, count: 8))
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.filter { if case .personalChecks = $0 { true } else { false } }.count == 4)
    }

    @Test func theOrderIsChecksFirstThenTheSetTheSheetTheExampleTheFigureTheBrief() {
        let (d, students, spaced) = draft([.eight])
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: ["Chapter 1"])
        #expect(requests.map(\.kindName) == ["checks", "sheet", "sheet", "workedExample", "brief"])
        if case let .sheet(_, _, _, _, questions, forHomework) = requests[1] { #expect(questions == 10); #expect(!forHomework) }
        if case let .sheet(_, _, _, _, questions, forHomework) = requests[2] { #expect(questions == 10); #expect(forHomework) }
    }

    @Test func homeworkIsFiveQuestionsUpToClassFive() {
        let (d, students, spaced) = draft([.five])
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        if case let .sheet(_, _, _, _, questions, true) = requests[2] { #expect(questions == 5) } else { Issue.record("no homework sheet") }
    }

    @Test func aFigureComesWhenTheSkillNamesATemplate() {
        let (d, students, spaced) = draft([.five], skillName: "Compare simple fractions")
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.contains { if case .figure(_, .fractionBar, _, _, _) = $0 { true } else { false } })
    }

    @Test func theBriefComesAboveClassSevenOrWhenAskedBefore() {
        let young = draft([.five])
        #expect(!ArtefactBudget.requests(for: young.draft, students: young.students, spacedSkills: young.spaced, briefsMade: []).contains { if case .brief = $0 { true } else { false } })
        #expect(ArtefactBudget.requests(for: young.draft, students: young.students, spacedSkills: young.spaced, briefsMade: ["Chapter 1"]).contains { if case .brief = $0 { true } else { false } })
    }

    @Test func theGroupsChecksAreTodaysSkillAndTwoSpacedOnes() {
        let (d, students, spaced) = draft([.eight, .eight, .eight])
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        guard case let .checks(_, skills, ids, _, _) = requests[0] else { Issue.record("no group checks"); return }
        #expect(skills.count == 3)
        #expect(skills[0] == d.groups[0].skill)
        #expect(Set(skills).count == 3)
        #expect(ids.count == 3)
    }

    @Test func aGroupWithoutASkillGetsNoChecksUntilItIsNamed() {
        let (d, students, spaced) = draft([.eight], books: false)
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.isEmpty)   // the maker names the skill through /ai/plan, then asks again with the named draft
    }

    @Test func nothingPersonalIsEverMade() {
        let (d, students, spaced) = draft(Array(repeating: .eight, count: 12), statuses: Array(repeating: .notOnTrack, count: 12))
        let requests = ArtefactBudget.requests(for: d, students: students, spacedSkills: spaced, briefsMade: [])
        #expect(requests.count <= ArtefactBudget.maxCalls)
        for request in requests {
            switch request {
            case .personalChecks, .placement: break   // named by id for the link, never sent: the maker sends skills only
            case .checks, .sheet, .workedExample, .figure, .brief: #expect(request.studentID == nil)
            }
        }
    }
}
```

(`kindName` and `studentID` are test-only computed properties in the file.)

- [ ] **Step 2: Run to verify they fail**, then **Step 3: write `ArtefactBudget`**: per group in order (checks when
  the group has a skill: the teach skill plus the two most overdue distinct spaced skills in the subject across the
  members, by `skills[*].lastCheckedAt ?? stateAt`, oldest first; the set; the homework sheet (5 questions when the
  group's class is five or under); the worked example; the figure when `FigureSpec.Kind.matching(skill:)` answers; the
  brief when the class is above seven or the chapter is in `briefsMade`), then the personal checks (lines with
  `personalChecks`, by the student's name, at most four: the placement request when the student has chapters in the
  subject and nothing taught, else the student's spaced pick), then `prefix(maxCalls)`.
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** `git commit -m "Domain: the artefact budget, tested against the price sheet"`.

### Task 7: Domain: the figure's wire format and word table; the reminder's words; the refusals (PR 3)

**Files:**
- Modify: `Sources/Domain/Record/FigureSpec.swift`, `Reminders/ReminderPlanner.swift`, `Reminders/ReminderSettings.swift`,
  `Queue/OfflineRefusal.swift`, `Classroom.swift` (`planGroups`, `planPattern`), `ClassroomDraft.swift` (untouched on
  screen: the batch form does not edit them)
- Test: `Tests/DomainTests/FigureSpecTests.swift`, `ReminderPlannerTests.swift`, `OfflineRefusalTests.swift`,
  `ClassroomTests.swift`

**Interfaces:**
- Produces: `FigureSpec.numberLine(from: Int, to: Int, step: Int, start: Int, jumps: [Int])` (replaces `marks`);
  `FigureSpec` `Codable` as `{"kind": "number_line", "from": 0, …}`; `FigureSpec.Kind.matching(skill: String) ->
  Kind?` (decision 7); `Problem` gains `.landingOffTheLine`, `.tooManyLabels`, `.tooManyLinks`; `Reminder.Kind.classMeeting`'s
  words: title "<batch> at 17:00", body "In 1 hour · 5 students. Open for today's plan.", link `tutorcentral://today`;
  `ReminderSettings.classMinutesBefore` default 60; `OfflineRefusal.Write.regenerate`, `.changePlan`, `.ownSheet`
  with the words "You're offline. Making it again needs a connection; the sheet you have is still here.", "You're
  offline. Changing the plan needs a connection; nothing was changed.", "You're offline. Using your own sheet needs a
  connection; nothing was changed."; `Classroom.planGroups: Int?`, `planPattern: [Weekday: PlanPattern]` (decoded with
  defaults when the keys are missing: a batch cached by build 20 has none).

- [ ] **Step 1: Write the failing tests** (`FigureSpecTests` extended; the others' new cases)

```swift
@Test func theWireFormatRoundTrips() throws {
    let line = FigureSpec.numberLine(from: 0, to: 20, step: 2, start: 4, jumps: [6, 6])
    let data = try JSONEncoder().encode(line)
    #expect(String(decoding: data, as: UTF8.self).contains("\"kind\":\"number_line\""))
    #expect(try JSONDecoder().decode(FigureSpec.self, from: data) == line)
    let cell = try JSONDecoder().decode(FigureSpec.self, from: Data(#"{"kind":"labelled_cell","cell":"plant","labels":["Cell wall","Nucleus"]}"#.utf8))
    #expect(cell == .labelledCell(kind: .plant, labels: ["Cell wall", "Nucleus"]))
    #expect(throws: (any Error).self) { try JSONDecoder().decode(FigureSpec.self, from: Data(#"{"kind":"pie_chart"}"#.utf8)) }
}

@Test func aLandingOutsideTheLineIsRefused() {
    #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 8, jumps: [5]).validate() == .landingOffTheLine)
    #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 2, jumps: [3, 3]).validate() == nil)
    #expect(FigureSpec.numberLine(from: 0, to: 10, step: 1, start: 2, jumps: [0]).validate() == .badStep)
}

@Test func aCellHasAtMostFiveLabelsAndAChainTwoToSixLinks() {
    #expect(FigureSpec.labelledCell(kind: .animal, labels: ["a", "b", "c", "d", "e", "f"]).validate() == .tooManyLabels)
    #expect(FigureSpec.foodChain(links: ["Grass"]).validate() == .tooFewLinks)
    #expect(FigureSpec.foodChain(links: Array(repeating: "x", count: 7)).validate() == .tooManyLinks)
}

@Test func aSkillNamesItsTemplateOrNone() {
    #expect(FigureSpec.Kind.matching(skill: "Compare simple fractions") == .fractionBar)
    #expect(FigureSpec.Kind.matching(skill: "Count on a number line") == .numberLine)
    #expect(FigureSpec.Kind.matching(skill: "Read large numbers") == .placeValue)
    #expect(FigureSpec.Kind.matching(skill: "Find the sine of an angle") == .unitCircle)
    #expect(FigureSpec.Kind.matching(skill: "Use Pythagoras' theorem") == .triangle)
    #expect(FigureSpec.Kind.matching(skill: "Label the parts of a plant cell") == .labelledCell)
    #expect(FigureSpec.Kind.matching(skill: "Explain a food chain") == .foodChain)
    #expect(FigureSpec.Kind.matching(skill: "Balance a chemical equation") == nil)
}

// ReminderPlannerTests
@Test func aClassReminderSaysOpenForTodaysPlanAnHourBefore() {
    let plan = ReminderPlanner.plan(input(classes: [maths], settings: ReminderSettings()), now: FakeClock.oct7at1635, calendar: DayHeading.india)
    let first = plan.first { $0.kind == .classMeeting }!
    #expect(first.title == "Class 10 Maths at 17:00")
    #expect(first.body == "In 1 hour · 6 students. Open for today's plan.")
    #expect(first.link == "tutorcentral://today")
    #expect(first.fireAt == FakeClock.at(2026, 10, 7, 16, 0) || first.fireAt > FakeClock.oct7at1635)
}

@Test func theDefaultClassLeadIsAnHour() {
    #expect(ReminderSettings().classMinutesBefore == 60)
    #expect(ReminderSettings.classLeads.contains(60))
}

// OfflineRefusalTests
@Test func thePlansRefusalsNameWhatWasNotChanged() {
    #expect(OfflineRefusal.words(for: .regenerate) == "You're offline. Making it again needs a connection; the sheet you have is still here.")
    #expect(OfflineRefusal.words(for: .changePlan) == "You're offline. Changing the plan needs a connection; nothing was changed.")
    #expect(OfflineRefusal.words(for: .ownSheet) == "You're offline. Using your own sheet needs a connection; nothing was changed.")
}

// ClassroomTests
@Test func aBatchCachedBeforeThePlanReadsWithNoPatternAndNoCount() throws {
    let json = #"{"id":"6D8E1C0A-0000-0000-0000-000000000001","name":"Evening batch","meetingDays":[1],"subject":null,"monthlyFee":null,"startTime":null,"endTime":null,"archivedAt":null}"#
    let room = try JSONDecoder().decode(Classroom.self, from: Data(json.utf8))
    #expect(room.planGroups == nil)
    #expect(room.planPattern.isEmpty)
}
```

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the code** (the `FigureSpec` `Codable` by a `kind` key and
  per-case keys; the word table in lower case; `ReminderPlanner.meeting` words; `OfflineRefusal`'s three cases;
  `Classroom`'s two fields with a hand-written `init(from:)` giving defaults). The reminder's words pass
  `ErrorWordsTests` as each sentence does.
- [ ] **Step 4: `bun check --only=format,lint,ios`**: PASS. **Step 5: Commit** `git commit -m "Domain: the figure's wire format and templates, the plan's reminder words, the plan's refusals, the batch's pattern"`.

Open PR 3 (Tasks 4 to 7); merge when green. Nothing on screen.

### Task 8: Data: the plans and artefacts repository, its rows and fake; the plan's copy on the iPhone (PR 4)

**Files:**
- Create: `Sources/Data/Plans/PlansRepository.swift`, `SupabasePlansRepository.swift`, `PlanRows.swift`,
  `FakePlansRepository.swift`, `PlanCache.swift`
- Modify: `Data/Classes/ClassroomRow.swift` (`plan_groups`, `plan_pattern`), `SupabaseClassesRepository.swift`
  (`setPlanGroups`, `setPlanPattern`), `ClassesRepository.swift`, `FakeClassesRepository.swift`
- Test: `Tests/DataTests/PlanRowTests.swift`, `FakePlansRepositoryTests.swift`, `PlanCacheTests.swift`,
  `ClassroomRowTests.swift`

**Interfaces:**
- Consumes: `PlanDraft`, `PlanRecord`, `PlanItem`, `PlanGroup`, `Artefact`, `ArtefactContent` (Task 4);
  `make_plan`, `keep_artefact` (Task 1); `PostgRESTDecoder`.
- Produces:

```swift
public protocol PlansRepository: Sendable {
    /// The day's plan for a batch with its items and artefacts; nil when none was made.
    func plan(centre: UUID, classID: UUID, date: Day) async throws -> PlanRecord?
    /// `make_plan`: the draft written (a second call replaces the day's plan); the record with its item ids, no artefacts.
    func make(_ draft: PlanDraft, centre: UUID) async throws -> PlanRecord
    /// `keep_artefact`: the artefact written and linked to the group's items of the kind (student nil) or one student's.
    func keep(_ artefact: NewArtefact, plan: UUID, group: Int, student: UUID?, itemKind: PlanLineKind, centre: UUID) async throws -> Artefact
    func artefact(id: UUID, centre: UUID) async throws -> Artefact?
    /// The chapters a brief was made for (the budget's "asked before").
    func briefChapters(centre: UUID) async throws -> Set<String>
    func skip(item: UUID, centre: UUID) async throws
    func move(items: [UUID], to group: Int, from: Int, centre: UUID) async throws
    func leaveOut(student: UUID, plan: UUID, centre: UUID) async throws
}
/// An artefact as the app writes it (the API's result and its generation id).
public struct NewArtefact: Hashable, Sendable {
    public let kind: ArtefactKind; public let source: ArtefactSource; public let title: String
    public let content: ArtefactContent; public let photoPath: String?; public let generationID: UUID?; public let regeneratedFrom: UUID?
}
public extension ClassesRepository {
    func setPlanGroups(_ count: Int?, classID: UUID) async throws
    func setPlanPattern(_ pattern: PlanPattern?, weekday: Weekday, classID: UUID) async throws
}
/// The plan's copy on this iPhone (D39): one file per batch and day, `plan-<class>-<date>`, kept whenever the plan or
/// an artefact lands, read when the network is away. Yesterday's copies are removed on the next keep.
public struct PlanCache: Sendable {
    public init(centre: UUID, directory: URL?)
    public func load(classID: UUID, date: Day) -> CachedValue<PlanRecord>?
    public func keep(_ plan: PlanRecord, at: Date)
    public func removeAll(before day: Day)
}
```

- [ ] **Step 1: Write the failing tests**

```swift
struct PlanRowTests {
    @Test func aPlanRowReadsItsGroupsItemsAndArtefacts() throws {
        let json = #"""
        {"id":"7a1f0000-0000-0000-0000-000000000001","class_id":"7a1f0000-0000-0000-0000-000000000002","date":"2026-10-07","made_at":"2026-10-07T11:05:00+00:00","session_id":null,
         "groups":[{"number":1,"subject":"Science","chapter":"Chemical reactions","skill":"Balancing equations","classLevels":["8"],"memberIDs":["7a1f0000-0000-0000-0000-000000000004"],"skillID":null}],
         "subjects":{"1":"Science"},
         "plan_items":[{"id":"7a1f0000-0000-0000-0000-000000000003","student_id":"7a1f0000-0000-0000-0000-000000000004","group_no":1,"kind":"teach","skill_id":null,"words":"Teach: Balancing equations","artefact_id":null,"done_at":null,"skipped_at":null,"moved_from":null}],
         "artefacts":[{"id":"7a1f0000-0000-0000-0000-000000000005","kind":"sheet","source":"made","title":"Balancing equations · sheet 1","content":{"title":"B","instructions":null,"questions":[],"for_homework":false,"light":false},"photo_path":null,"student_id":null,"plan_id":"7a1f0000-0000-0000-0000-000000000001","regenerated_from":null,"created_at":"2026-10-07T11:06:00+00:00"}]}
        """#
        let record = try PostgRESTDecoder.make().decode(PlanRow.self, from: Data(json.utf8)).record
        #expect(record.groups[0].skill == "Balancing equations")
        #expect(record.items[0].words == "Teach: Balancing equations")
        if case .sheet = record.artefacts[0].content {} else { Issue.record("not a sheet") }
    }

    @Test func makeParamsCarryTheDraftAsTheFunctionTakesIt() {
        let params = SupabasePlansRepository.makeParams(PlanRulesTests.sampleDraft, centre: UUID())
        #expect(params["p_groups"] != nil)
        #expect(params["p_subjects"] != nil)
        guard case let .array(items)? = params["p_items"], case let .object(first)? = items.first else { Issue.record("no items"); return }
        #expect(first["kind"] == .string("teach"))
        #expect(first["words"] != nil)
    }

    @Test func keepParamsEncodeTheContentWithSnakeCaseAndNoStudentForAGroup() throws {
        let artefact = NewArtefact(kind: .sheet, source: .made, title: "t", content: .sheet(SheetContent(title: "t", instructions: nil, questions: [], forHomework: true, light: false)), photoPath: nil, generationID: UUID(), regeneratedFrom: nil)
        let params = try SupabasePlansRepository.keepParams(artefact, plan: UUID(), group: 1, student: nil, itemKind: .homework, centre: UUID())
        guard case let .object(a)? = params["p_artefact"], case let .object(content)? = a["content"] else { Issue.record("no artefact"); return }
        #expect(content["for_homework"] == .bool(true))
        #expect(params["p_student"] == .null)
        #expect(params["p_item_kind"] == .string("homework"))
    }
}

@MainActor struct FakePlansRepositoryTests {
    @Test func makeThenKeepLinksTheGroupsItems() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanRulesTests.sampleDraft, centre: centre)
        #expect(made.items.count == PlanRulesTests.sampleDraft.lines.count)
        let sheet = try await repo.keep(NewArtefact(kind: .sheet, source: .made, title: "s", content: .sheet(SheetContent(title: "s", instructions: nil, questions: [], forHomework: true, light: false)), photoPath: nil, generationID: nil, regeneratedFrom: nil), plan: made.id, group: 1, student: nil, itemKind: .homework, centre: centre)
        let read = try await repo.plan(centre: centre, classID: made.classID, date: made.date)!
        #expect(read.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy { $0.artefactID == sheet.id })
        #expect(read.artefacts.map(\.id) == [sheet.id])
    }

    @Test func aSecondMakeReplacesTheDaysPlanAndUnlinksItsArtefacts() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let first = try await repo.make(PlanRulesTests.sampleDraft, centre: centre)
        let second = try await repo.make(PlanRulesTests.sampleDraft, centre: centre)
        #expect(first.id == second.id)
        #expect(try await repo.plan(centre: centre, classID: second.classID, date: second.date)?.artefacts.isEmpty == true)
    }

    @Test func skipMoveAndLeaveOutMarkTheItems() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanRulesTests.sampleDraft, centre: centre)
        let dev = made.items[0].studentID!
        try await repo.skip(item: made.items(of: dev).first { $0.kind == .homework }!.id, centre: centre)
        try await repo.move(items: made.items(of: dev).map(\.id), to: 2, from: 1, centre: centre)
        var read = try await repo.plan(centre: centre, classID: made.classID, date: made.date)!
        #expect(read.items(of: dev).allSatisfy { $0.groupNo == 2 && $0.movedFrom == 1 })
        #expect(read.items(of: dev).first { $0.kind == .homework }?.skippedAt != nil)
        try await repo.leaveOut(student: dev, plan: made.id, centre: centre)
        read = try await repo.plan(centre: centre, classID: made.classID, date: made.date)!
        #expect(read.items(of: dev).allSatisfy { $0.skippedAt != nil })
    }

    @Test func briefChaptersNameTheChaptersBriefsWereMadeFor() async throws {
        let repo = FakePlansRepository()
        let centre = UUID()
        let made = try await repo.make(PlanRulesTests.sampleDraft, centre: centre)
        _ = try await repo.keep(NewArtefact(kind: .brief, source: .made, title: "Your brief · Chemical reactions", content: .other, photoPath: nil, generationID: nil, regeneratedFrom: nil), plan: made.id, group: 1, student: nil, itemKind: .brief, centre: centre)
        #expect(try await repo.briefChapters(centre: centre) == ["Chemical reactions"])
    }
}

struct PlanCacheTests {
    @Test func aPlanIsKeptPerBatchAndDayAndOldDaysAreRemoved() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: UUID(), directory: directory)
        let plan = PlanRulesTests.sampleRecord(date: Day(iso: "2026-10-07")!)
        cache.keep(plan, at: FakeClock.oct7at1635)
        #expect(cache.load(classID: plan.classID, date: plan.date)?.value.id == plan.id)
        cache.removeAll(before: Day(iso: "2026-10-08")!)
        #expect(cache.load(classID: plan.classID, date: plan.date) == nil)
    }
}

// ClassroomRowTests
@Test func aBatchRowReadsItsPlanChoices() throws {
    let json = #"{"id":"7a1f0000-0000-0000-0000-000000000009","name":"Evening batch","subject":"Science","monthly_fee":null,"meeting_days":[1,2],"start_time":"17:00","end_time":"18:30","archived_at":null,"plan_groups":2,"plan_pattern":{"3":{"groups":2,"subjects":["Science","Mathematics"]}}}"#
    let room = try PostgRESTDecoder.make().decode(ClassroomRow.self, from: Data(json.utf8)).classroom
    #expect(room.planGroups == 2)
    #expect(room.planPattern[.wednesday]?.subjects == ["Science", "Mathematics"])
}
```

`PlanRulesTests.sampleDraft` and `sampleRecord(date:)` are `static` helpers added to DomainTests and reached from
DataTests through a small `PlanSamples` file in `Tests/DataTests` that rebuilds them (DataTests cannot see DomainTests);
the plan names them once here and the build keeps one copy per test target that needs them.

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the repository**: `plan` selects `plans` with
  `plan_items(*)` and `artefacts(*)` embedded (PostgREST's composite keys on `plan_id`) for the batch and day;
  `make` calls `make_plan` and reads the answer's `plan_id` and `items` into a `PlanRecord` with the draft's groups and
  no artefacts; `keep` calls `keep_artefact` then selects the row by id; `skip`, `move` (one update with `in`), `leaveOut`
  (one update filtered by `plan_id` and `student_id`); `briefChapters` selects `title` of kind brief and strips "Your
  brief · ". The fake keeps everything in memory with the same rules (`make` replaces by class and date). `PlanCache`
  is a `JSONCache` per file with the key `plan-<class>-<date>` under the centre.
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** on `phase-12/data`: `git commit -m "Data: plans and artefacts, the plan's copy on the iPhone, the batch's plan choices"`.

### Task 9: Data: photos in Storage; the close's done lines; deletion removes the centre's photos (PR 4)

**Files:**
- Create: `Sources/Data/Photos/PhotoStore.swift` (`PhotoStore` protocol, `SupabasePhotoStore`, `FakePhotoStore`)
- Modify: `Domain/Record/SessionClose.swift` (`done: [UUID]`), `Data/Attendance/SupabaseAttendanceRepository.swift`
  (`p_done`), `FakeAttendanceRepository.swift`, `Settings/Account/DeleteAccountStore.swift` (photos removed between
  Apple's revocation and `delete_account`), `AppShell/SessionStore.swift` where deletion is wired
- Test: `Tests/DataTests/FakePhotoStoreTests.swift`, `SessionCloseParamsTests.swift`, `DomainTests/SessionCloseTests.swift`,
  `SettingsTests/DeleteAccountStoreTests.swift`

**Interfaces:**
- Produces:

```swift
/// The `photos` bucket (migration 0011): a JPEG under the centre, add-only; the first stored photo of V2 is a tutor's own
/// sheet (plan decision 13).
public protocol PhotoStore: Sendable {
    /// Uploads `data` to `photos/<centre>/<kind>/<uuid>.jpg`; the path.
    func add(_ data: Data, centre: UUID, kind: String) async throws -> String
    /// A short-lived URL the screen loads the photo from (ten minutes).
    func url(for path: String) async throws -> URL
    /// All the centre's photos removed (account deletion, D40).
    func removeAll(centre: UUID) async throws
}
// SessionClose gains `public let done: [UUID]` (default []), carried in the queue; closeParams adds "p_done".
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct FakePhotoStoreTests {
    @Test func addKeepsThePathUnderTheCentreAndRemoveAllClearsIt() async throws {
        let store = FakePhotoStore()
        let centre = UUID()
        let path = try await store.add(Data([0xFF, 0xD8]), centre: centre, kind: "own")
        #expect(path.hasPrefix("\(centre.uuidString.lowercased())/own/"))
        #expect(path.hasSuffix(".jpg"))
        #expect(store.paths == [path])
        try await store.removeAll(centre: centre)
        #expect(store.paths.isEmpty)
    }
}

// SessionCloseParamsTests
@Test func theDoneLinesGoAsAnArrayOfIds() {
    let item = UUID()
    let close = SessionClose(classID: UUID(), date: Day(iso: "2026-10-07")!, marks: [:], checks: [], homework: [], track: [:], states: [], done: [item])
    let params = SupabaseAttendanceRepository.closeParams(close, centre: UUID())
    #expect(params["p_done"] == .array([.string(item.uuidString.lowercased())]))
}

// SessionCloseTests (Domain)
@Test func aCloseWithoutDoneLinesDecodesFromACloseKeptByBuild20() throws {
    let json = #"{"classID":null,"date":{"year":2026,"month":10,"day":7},"marks":{},"checks":[],"homework":[],"track":{},"states":[]}"#
    #expect(try JSONDecoder().decode(SessionClose.self, from: Data(json.utf8)).done.isEmpty)
}

// DeleteAccountStoreTests
@Test func deletionRemovesTheCentresPhotosAfterAppleAndBeforeTheAccount() async {
    let photos = FakePhotoStore()
    _ = try? await photos.add(Data([1]), centre: workspace.centre.id, kind: "own")
    let store = DeleteAccountStore(…, photos: photos, …)
    await store.confirm("DELETE")
    #expect(photos.paths.isEmpty)
    #expect(auth.deleted)
}

@Test func aPhotoRemovalThatFailsLeavesTheAccountWhole() async {
    let photos = FakePhotoStore(); photos.failure = .service
    let store = DeleteAccountStore(…, photos: photos, …)
    await store.confirm("DELETE")
    #expect(!auth.deleted)
    #expect(store.message == "The account wasn't deleted. Check your connection and try again. Nothing was removed.")
}
```

(The deletion's existing words are reused; see `DeleteAccountStore` for the exact sentence it shows today and keep it.)

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the code**: `SupabasePhotoStore` over
  `client.storage.from("photos")` (`upload`, `createSignedURL(path:expiresIn: 600)`, `list` then `remove`, folder by
  folder: `own`, `textbook`, `item`, `mark`); `SessionClose.done` with a decoder that defaults it; `closeParams`'s
  `p_done`; `DeleteAccountStore` takes `photos` and calls `removeAll` after the revocation and before `deleteAccount`.
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** `git commit -m "Data: photos in Storage, the close's done lines, deletion removes the centre's photos"`.

### Task 10: Data: the API client's five calls, the fake's answers; the write proofs (PR 4)

**Files:**
- Create: `Sources/Data/AI/APIClient+Plan.swift`, `AI/AISamples+Plan.swift`
- Modify: `AI/AIRepository.swift`, `AI/APIBodies.swift`, `AI/FakeAIRepository.swift`, `AppShell/Dependencies.swift`
  (`plans`, `photos`), `Fixtures.swift` (the fakes)
- Test: `Tests/DataTests/APIBodiesV2Tests.swift`, `APIClientTests.swift`, `FakeAIRepositoryTests.swift`

**Interfaces:**
- Produces (on `AIRepository`, `APIClient`, `FakeAIRepository`):

```swift
public struct MadeSheet: Hashable, Sendable { public let generationID: UUID; public let content: SheetContent }
public struct MadeWorkedExample: Hashable, Sendable { public let generationID: UUID; public let example: WorkedExample }
public struct MadeFigure: Hashable, Sendable { public let generationID: UUID; public let figure: FigureContent }
public struct MadeBrief: Hashable, Sendable { public let generationID: UUID; public let brief: Brief }
public struct PlanTopic: Hashable, Sendable, Codable { public let groupNo: Int; public let chapter: String; public let skill: String }
public struct MadeChecks: Hashable, Sendable { public let generationID: UUID; public let questions: [CheckQuestion] }

func makeSheet(classLevel: ClassLevel, subject: String, skills: [String], questions: Int, forHomework: Bool, reason: String?, centre: UUID) async throws(APIFailure) -> MadeSheet
func makeWorkedExample(classLevel: ClassLevel, subject: String, skill: String, centre: UUID) async throws(APIFailure) -> MadeWorkedExample
func makeFigure(_ kind: FigureSpec.Kind, classLevel: ClassLevel, subject: String, skill: String, centre: UUID) async throws(APIFailure) -> MadeFigure
func makeBrief(classLevel: ClassLevel, subject: String, chapter: String, centre: UUID) async throws(APIFailure) -> MadeBrief
func planTopics(classID: UUID?, date: Day, month: Int, groups: [(groupNo: Int, classLevel: ClassLevel, subject: String)], centre: UUID) async throws(APIFailure) -> [PlanTopic]
/// Phase 11's makeChecks now also answers the generation's id, so the plan can keep the checks with it.
func makeChecksWithID(classLevel: ClassLevel, subject: String, skills: [String], centre: UUID) async throws(APIFailure) -> MadeChecks
```

The fake answers the boards' content: `AISamples.sheet` (Group 1's eight balancing-equations questions, cut or
repeated to the asked count; "light" five for a young class), `AISamples.workedExample` (the board's four steps and its
slip), `AISamples.figure(kind)` (one fixed spec per template: the boards' seven), `AISamples.brief` (the Chemical
reactions brief), `AISamples.topics(groups)` (class 8 Science "Chemical reactions · Balance a chemical equation", class
5 Mathematics "Parts and Wholes · Name a fraction of a whole", class 2 "Numbers · To 99", else "<subject> chapter 1 ·
The first idea"). It records each call (`sheets`, `examples`, `figures`, `briefs`, `topics`) and takes a scripted
failure per call kind (`scriptByKind`) and a delay.

- [ ] **Step 1: Write the failing tests**

```swift
struct APIBodiesV2Tests {
    @Test func aSheetBodyNamesTheSkillsCountAndReason() throws {
        let body = MakeSheetBody(centreId: "c", classLevel: "8", subject: "Science", skills: ["Balance a chemical equation"], questions: 8, forHomework: false, reason: "easier")
        let json = String(decoding: try JSONEncoder().encode(body), as: UTF8.self)
        #expect(json.contains("\"kind\":\"sheet\""))
        #expect(json.contains("\"forHomework\":false"))
        #expect(json.contains("\"reason\":\"easier\""))
    }

    @Test func noBodyCarriesAStudent() throws {
        let bodies: [any Encodable] = [
            MakeSheetBody(centreId: "c", classLevel: "8", subject: "Science", skills: ["x"], questions: 10, forHomework: true, reason: nil),
            MakeWorkedExampleBody(centreId: "c", classLevel: "8", subject: "Science", skill: "x"),
            MakeFigureBody(centreId: "c", figure: "fraction_bar", classLevel: "5", subject: "Mathematics", skill: "x"),
            MakeBriefBody(centreId: "c", classLevel: "8", subject: "Science", chapter: "x"),
            PlanBody(centreId: "c", classId: nil, date: "2026-10-07", month: 10, groups: [.init(groupNo: 1, classLevel: "8", subject: "Science")]),
        ]
        for body in bodies {
            let json = String(decoding: try JSONEncoder().encode(body), as: UTF8.self)
            #expect(!json.lowercased().contains("student"))
        }
    }
}

// APIClientTests (the stubbed transport the file already uses)
@Test func makeFigureDecodesTheSpecByKindAndRefusesInWords() async throws {
    let client = stubbed(status: 200, body: #"{"id":"7a1f0000-0000-0000-0000-000000000010","result":{"figure":{"kind":"fraction_bar","parts":4,"shaded":3,"label":"3/4"},"caption":"Three of four."}}"#)
    let made = try await client.makeFigure(.fractionBar, classLevel: .five, subject: "Mathematics", skill: "Compare simple fractions", centre: UUID())
    #expect(made.figure.figure == .fractionBar(parts: 4, shaded: 3, label: "3/4"))
    let refused = stubbed(status: 422, body: #"{"error":"Couldn't draw a figure for this skill. The plan goes on without it."}"#)
    await #expect(throws: APIFailure.refused("Couldn't draw a figure for this skill. The plan goes on without it.")) {
        try await refused.makeFigure(.fractionBar, classLevel: .five, subject: "Mathematics", skill: "x", centre: UUID())
    }
}

@Test func planTopicsDecodeTheGroups() async throws {
    let client = stubbed(status: 200, body: #"{"id":"7a1f0000-0000-0000-0000-000000000011","result":{"groups":[{"groupNo":1,"chapter":"Chemical reactions","skill":"Balance a chemical equation"}]}}"#)
    let topics = try await client.planTopics(classID: nil, date: Day(iso: "2026-10-07")!, month: 10, groups: [(1, .eight, "Science")], centre: UUID())
    #expect(topics == [PlanTopic(groupNo: 1, chapter: "Chemical reactions", skill: "Balance a chemical equation")])
}

// FakeAIRepositoryTests
@MainActor @Test func theFakeAnswersEachKindAndCountsItsCalls() async throws {
    let fake = FakeAIRepository()
    let sheet = try await fake.makeSheet(classLevel: .five, subject: "Mathematics", skills: ["Compare simple fractions"], questions: 5, forHomework: true, reason: nil, centre: UUID())
    #expect(sheet.content.questions.count == 5)
    #expect(sheet.content.light)
    let figure = try await fake.makeFigure(.foodChain, classLevel: .seven, subject: "Science", skill: "x", centre: UUID())
    #expect(figure.figure.figure.kind == .foodChain)
    fake.scriptByKind[.brief] = .failure(.service)
    await #expect(throws: APIFailure.service) { try await fake.makeBrief(classLevel: .eight, subject: "Science", chapter: "x", centre: UUID()) }
    #expect(fake.sheets.count == 1 && fake.figures.count == 1 && fake.briefs.count == 1)
}
```

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the code**, **Step 4: run the tests**: PASS.
- [ ] **Step 5: The write proofs** (ios/CLAUDE.md's rule: a write path is proven in Swift against the local stack
  before a build ships): a throwaway test with an in-memory session against local Supabase, run once by hand and not
  committed, for `make`, `keep` (a group's sheet, a student's checks, a regenerate), `skip`, `move`, `leaveOut`,
  `setPlanPattern`, `PhotoStore.add` then `url` then `removeAll`, and `close` with `done`; each confirmed in Studio or
  psql. Write what was run in the ledger.
- [ ] **Step 6: Commit** `git commit -m "Data: the API client's plan and artefact calls, the fake's answers"`; open
  PR 4 (Tasks 8 to 10); merge when green. Nothing on screen.

### Task 11: DesignSystem: the plan's parts (PR 5)

**Files:**
- Create: `Sources/DesignSystem/Components/GroupCard.swift` (`GroupHead`, `ReadyMarks`), `PlanLineRow.swift`,
  `LineChecklist.swift` (`ChecklistRow`), `LineMenu.swift` (the context menu's rows as a `ViewBuilder` helper)
- Modify: `Tokens/Tokens.swift` and `docs/design/design-tokens.md` only where a board's value is not a token yet
  (the boards use `rowTitle`, `footnote`, `caption`, `text`, `text2`, `text3`, `accentText`, `ok`, `lineStrong`, the
  avatar 36, the checkbox 24: the parts' fixed sizes are static metrics as the record's parts are)
- Test: `Tests/DesignSystemTests/PlanPartsTests.swift` (the parts' words and metrics; a view's `static` text helpers)

**Interfaces** (from `components.md` "Phase 10 parts", 10.3):
- `GroupHead(title: "Group 1 · Chemical reactions", line: "Class 8 Science · 3 students", marks: [ReadyMark])` where
  `ReadyMark(name: "Set 1", state: .made | .onItsWay | .notMade)`: the name `caption` 600; made `ok` with a 12 pt tick,
  on its way `text3` with a 12 pt spinner, not made `text3` alone.
- `PlanLineRow(initials:, name:, note: PlanLineNote?, teachLine: String, restLine: [LineBit], onPress:)` with
  `PlanLineNote.movedFrom(Int)` (caption 600 `accentText` "Moved here from Group n") and `.skipped("Homework skipped
  today")` (`text3`); `LineBit(text:, struck: Bool)` for "Practise set 1 · Check 3 · Homework sheet 1" with a skipped
  item struck through in `text3`; the avatar 36, the name `rowTitle`, the teach line `footnote` `text`, the rest
  `footnote` `text2`, `chevron.right` 18. The whole row presses; the long press is the caller's `contextMenu`.
- `ChecklistRow(isOn: Binding<Bool>, text:)`: a 24 pt checkbox (`ok` fill with the tick when done; `lineStrong` ring
  when not), the text `subhead` (`text2` once done); `LineChecklist.count(done:total:)` → "2 of 5".
- `LineMenu.rows(groups: [Int], current: Int, move:, skipCheck:, skipHomework:, leaveOut:)`: Move to Group n
  (`arrow.right`, one per other group), Skip the check today (`minus`), Skip homework today (`minus`), Leave out today
  (`xmark`), for a `contextMenu`.
- The planning card is `CreatingCard(title: "Planning today's class", line:, cancel: nil)` with the 10.3 words; no new
  part.

- [ ] **Step 1: Write the failing tests** (words and metrics only; the views are proven by the pictures)

```swift
struct PlanPartsTests {
    @Test func theChecklistCountReads() {
        #expect(LineChecklist.count(done: 2, total: 5) == "2 of 5")
        #expect(LineChecklist.count(done: 5, total: 5) == "5 of 5")
    }

    @Test func aReadyMarkNamesItsState() {
        #expect(ReadyMark(name: "Set 1", state: .made).accessibilityWords == "Set 1, made")
        #expect(ReadyMark(name: "Sheet 1", state: .onItsWay).accessibilityWords == "Sheet 1, on its way")
        #expect(ReadyMark(name: "Checks", state: .notMade).accessibilityWords == "Checks, not made")
    }

    @Test func theRestLineJoinsItsBitsWithTheMiddleDot() {
        #expect(PlanLineRow.restText([LineBit(text: "Practise set 1", struck: false), LineBit(text: "Check 3", struck: true)]) == "Practise set 1 · Check 3")
    }

    @Test func theMenuOffersEveryOtherGroup() {
        #expect(LineMenu.moveTargets(groups: [1, 2, 3], current: 2) == [1, 3])
        #expect(LineMenu.moveTargets(groups: [1], current: 1).isEmpty)
    }
}
```

- [ ] **Step 2 to 4:** fail, write the parts to the metrics above, pass.
- [ ] **Step 5: Commit** on `phase-12/today-plan`: `git commit -m "DesignSystem: the group card, the plan line, the line checklist, the line menu"`.

### Task 12: Today: the plan maker and the plan store (PR 5)

**Files:**
- Create: `Sources/Features/Today/PlanMaker.swift`, `PlanStore.swift`, `PlanStore+Make.swift`
- Test: `Tests/TodayTests/PlanMakerTests.swift`, `PlanStoreTests.swift`

**Interfaces:**
- Consumes: `PlanRules`, `ArtefactBudget`, `ArtefactRequest`, `PlansRepository`, `PlanCache`, `TextbooksRepository`
  (`chapters`, `skills`), `AttendanceRepository.sessions`, `AIRepository` (the six calls), `Register`, `SpacedQueue`,
  `Placement`, `FigureSpec.validate`.
- Produces:

```swift
/// Makes the day's plan for one batch and its material, as the user (D60): the rules, the write, then the artefacts
/// in the budget's order, each kept as it lands. Shared by Today's open and the background refresh.
public final class PlanMaker: Sendable {
    public init(plans: any PlansRepository, textbooks: any TextbooksRepository, attendance: any AttendanceRepository, ai: any AIRepository, cache: PlanCache?, now: @escaping @Sendable () -> Date, calendar: Calendar)
    /// What the maker reports as it goes: the plan written (its lines show), then each artefact kept.
    public enum Progress: Sendable { case written(PlanRecord), kept(Artefact, PlanRecord), finished(PlanRecord), failed(String) }
    /// Makes the plan for the batch on `date`; the choices come from the Change sheet or the batch's pattern.
    public func make(classroom: Classroom, members: [Student], date: Day, centre: UUID, choices: PlanChoices?, progress: @escaping @Sendable (Progress) async -> Void) async
    /// The rules alone (no write): what the Change sheet previews, and the tests read.
    public func draft(classroom:, members:, date:, centre:, choices:) async throws -> PlanDraft
}
public struct PlanChoices: Hashable, Sendable { public var groups: Int?; public var subjects: [Int: String] }

/// One batch's plan on Today (P10-Today-Plan and its states): nothing yet, being made (the lines fill in as they come),
/// made, or none because the network is away and no copy exists.
@MainActor @Observable public final class PlanStore {
    public enum State: Hashable, Sendable { case none, planning(PlanRecord?), made(PlanRecord), offline, failed(String) }
    public private(set) var state: State = .none
    public let classID: UUID
    /// The cards: one per group with its head, marks and lines in the plan's order.
    public var groups: [GroupCardModel]
    public var briefRow: BriefRowModel?            // after the qualifying group
    public var changedNote: Bool                    // any moved or skipped line today (the section's quiet Change stays)
    public func load() async                        // the copy, then the server's plan, then make when none
    public func makeAgain(choices: PlanChoices?) async
    public func open(line: PlanItem) -> PlanOpen?   // .artefact(id) for practise, check, homework, brief lines; nil for teach
    // Task 13 adds move, skipCheck, skipHomework, leaveOut, keep(pattern:)
}
public struct GroupCardModel: Identifiable, Hashable, Sendable { public let id: Int; public let title: String; public let line: String; public let marks: [ReadyMark]; public let lines: [PlanLineModel] }
public struct PlanLineModel: Identifiable, Hashable, Sendable { public let id: UUID (the student); public let initials: String; public let name: String; public let status: String; public let note: PlanLineNote?; public let teach: String; public let rest: [LineBit]; public let items: [PlanItem] }
public struct BriefRowModel: Hashable, Sendable { public let title: String; public let line: String; public let artefactID: UUID?; public let afterGroup: Int }
```

The maker, in order: reads chapters and skills per member together (a `TaskGroup`, as the close does) and the batch's
last sessions; `PlanRules.plan` with the choices (else the batch's pattern for the weekday, else nil); for groups with no
skill, `/ai/plan` with the month of the school year (the calendar month) and the topics fill `chapter` and `skill` (a
failure leaves those groups with "Teach: with the group" and no checks, set or sheet: they are made the next open);
`plans.make`; `.written`; then `ArtefactBudget.requests` in order, each call → `plans.keep` → `.kept`; a figure whose
spec fails `validate()` is dropped (the API refuses it first); a call that fails is skipped with the reason in the
ledger's words and the rest goes on; `.finished`. Each `.written`, `.kept` and `.finished` is kept in the cache.
Personal checks are `NewArtefact(kind: .check, content: .check(CheckContent(questions: [...skillID...], placement:
false)))` kept with `student`; the placement is kept as kind `.placement`, content `.check(…, placement: true)` with the
subjects' questions in `Placement.groups` order.

- [ ] **Step 1: Write the failing tests** (`PlanMakerTests`; the helpers build the fixtures' Evening batch from
  `FakeStudentsRepository.eveningSeed`, `FakeTextbooksRepository.evening()` and `FakeAttendanceRepository.seed`)

```swift
@MainActor struct PlanMakerTests {
    func maker(ai: FakeAIRepository = FakeAIRepository(), plans: FakePlansRepository = FakePlansRepository()) -> (PlanMaker, FakePlansRepository, FakeAIRepository) {
        (PlanMaker(plans: plans, textbooks: FakeTextbooksRepository.evening(), attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), ai: ai, cache: nil, now: { FakeClock.oct7at1635 }, calendar: DayHeading.india), plans, ai)
    }
    let evening = FakeClassesRepository.evening
    let members = FakeStudentsRepository.eveningSeed.filter { $0.classID == FakeClassesRepository.evening.id }

    @Test func theEveningBatchMakesThreeGroupsWithTheirMaterialInOrder() async throws {
        let (maker, plans, ai) = maker()
        var seen: [String] = []
        await maker.make(classroom: evening, members: members, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { progress in
            await MainActor.run { seen.append(progress.name) }
        }
        #expect(seen.first == "written")
        #expect(seen.last == "finished")
        let plan = try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: evening.id, date: Day(iso: "2026-10-07")!)!
        #expect(plan.groups.map(\.number) == [1, 2, 3])
        #expect(plan.artefact(group: 1, kind: .check) != nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: false) != nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
        #expect(plan.artefact(group: 1, kind: .workedExample) != nil)
        #expect(plan.artefact(group: 1, kind: .brief) != nil)      // class 8 is above 7
        #expect(plan.artefact(group: 3, kind: .brief) == nil)      // Sahil's class 2 group
        #expect(ai.sheets.count == 6)
        #expect(ai.topics.isEmpty)                                  // each group had a skill
    }

    @Test func aGroupWithoutASkillAsksForATopic() async throws {
        let (maker, plans, ai) = maker()
        let newcomers = [student("Kavya", class: .nine), student("Arjun", class: .nine)]
        await maker.make(classroom: evening, members: newcomers, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { _ in }
        #expect(ai.topics.count == 1)
        let plan = try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: evening.id, date: Day(iso: "2026-10-07")!)!
        #expect(!plan.groups[0].skill.isEmpty)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
    }

    @Test func aFailedFigureLeavesTheRestOfThePlan() async throws {
        let ai = FakeAIRepository()
        ai.scriptByKind[.figure] = .failure(.refused("Couldn't draw a figure for this skill. The plan goes on without it."))
        let (maker, plans, _) = maker(ai: ai)
        let riya = members.first { $0.id == FakeStudentsRepository.riya }!   // her teach skill names a fraction bar
        await maker.make(classroom: evening, members: [riya], date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { _ in }
        let plan = try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: evening.id, date: Day(iso: "2026-10-07")!)!
        #expect(plan.artefact(group: 1, kind: .figure) == nil)
        #expect(plan.artefact(group: 1, kind: .sheet, homework: true) != nil)
        #expect(plan.artefact(group: 1, kind: .workedExample) != nil)
    }

    @Test func aSpecTheApiLetThroughButTheAppRefusesIsNotKept() async throws {
        let ai = FakeAIRepository()
        ai.figureOverride = FigureContent(figure: .foodChain(links: ["Grass"]), caption: "x")
        let (maker, plans, _) = maker(ai: ai)
        let riya = members.first { $0.id == FakeStudentsRepository.riya }!
        await maker.make(classroom: evening, members: [riya], date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { _ in }
        #expect(try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: evening.id, date: Day(iso: "2026-10-07")!)?.artefact(group: 1, kind: .figure) == nil)
    }

    @Test func personalChecksAreKeptWithTheStudentAndThePlacementAsItsKind() async throws {
        let (maker, plans, _) = maker()
        await maker.make(classroom: evening, members: members, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { _ in }
        let plan = try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: evening.id, date: Day(iso: "2026-10-07")!)!
        let riyas = plan.checks(for: FakeStudentsRepository.riya)!
        #expect(riyas.kind == .placement)
        #expect(riyas.studentID == FakeStudentsRepository.riya)
        #expect(plan.checks(for: FakeStudentsRepository.dev)?.studentID == nil)
    }

    @Test func theChoicesOverrideTheRulesAndThePatternOverridesNothingChosen() async throws {
        let (maker, _, _) = maker()
        let two = try await maker.draft(classroom: evening, members: members, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: PlanChoices(groups: 2, subjects: [1: "Mathematics"]))
        #expect(two.groups.count == 2)
        #expect(two.groups[0].subject == "Mathematics")
        var patterned = evening
        patterned.planPattern = [.wednesday: PlanPattern(groups: 1, subjects: ["Science"])]
        let kept = try await maker.draft(classroom: patterned, members: members, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil)
        #expect(kept.groups.count == 1)
    }

    @Test func nothingPersonalIsSentToTheApi() async throws {
        let (maker, _, ai) = maker()
        await maker.make(classroom: evening, members: members, date: Day(iso: "2026-10-07")!, centre: FakeCentreRepository.meeraCentre.id, choices: nil) { _ in }
        for call in ai.sheets + ai.examples + ai.figures + ai.briefs {
            #expect(!call.lowercased().contains("riya") && !call.lowercased().contains("dev"))
        }
    }
}

@MainActor struct PlanStoreTests {
    func store(plans: FakePlansRepository = FakePlansRepository(), ai: FakeAIRepository = FakeAIRepository(), online: Bool = true, cache: PlanCache? = nil, now: Date = FakeClock.oct7at1635, attendance: FakeAttendanceRepository = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)) async -> (PlanStore, FakePlansRepository) {
        let register = await register(evening: true)
        let maker = PlanMaker(plans: plans, textbooks: FakeTextbooksRepository.evening(), attendance: attendance, ai: ai, cache: cache, now: { now }, calendar: DayHeading.india)
        let store = PlanStore(classID: FakeClassesRepository.evening.id, workspace: FakeCentreRepository.meeraWorkspace, register: register, plans: plans, maker: maker, cache: cache, now: { now }, calendar: DayHeading.india)
        store.online = { online }
        await store.load()
        return (store, plans)
    }

    @Test func openingMakesThePlanAndShowsTheGroupsAsTheyLand() async {
        let (store, _) = await store()
        guard case .made = store.state else { Issue.record("not made: \(store.state)"); return }
        #expect(store.groups.count == 3)
        #expect(store.groups[0].title == "Group 1 · Chemical reactions")
        #expect(store.groups[0].line == "Class 8 Science · 3 students")
        #expect(store.groups[0].marks.map(\.name) == ["Checks", "Set 1", "Sheet 1", "Example", "Brief"])
        #expect(store.groups[0].marks.allSatisfy { $0.state == .made })
        #expect(store.groups[0].lines.map(\.name) == ["Dev Kumar", "Meher Shah", "Nikhil Das"])
        #expect(store.groups[0].lines[0].teach == "Teach: Balancing equations")
        #expect(store.groups[0].lines[0].rest.map(\.text) == ["Practise set 1", "Check 3", "Homework sheet 1"])
        #expect(store.briefRow?.afterGroup == 1)
        #expect(store.briefRow?.line == "Five minutes · three common mistakes · the worked example to use")
    }

    @Test func aPlanAlreadyMadeOpensAtOnceWithoutMakingAgain() async {
        let plans = FakePlansRepository()
        let ai = FakeAIRepository()
        _ = await store(plans: plans, ai: ai)
        let calls = ai.sheets.count
        let (store, _) = await store(plans: plans, ai: ai)
        guard case .made = store.state else { Issue.record("not made"); return }
        #expect(ai.sheets.count == calls)
    }

    @Test func offlineWithNoPlanShowsNothingAndStartClassStays() async {
        let (store, _) = await store(online: false)
        #expect(store.state == .offline)
        #expect(store.groups.isEmpty)
    }

    @Test func aPlanAlreadyMadeOpensOffline() async {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let cache = PlanCache(centre: FakeCentreRepository.meeraCentre.id, directory: directory)
        _ = await store(cache: cache)
        let (store, _) = await store(plans: FakePlansRepository(), online: false, cache: cache)
        guard case let .made(plan) = store.state else { Issue.record("not made from the copy"); return }
        #expect(plan.artefact(group: 1, kind: .check) != nil)
    }

    @Test func aClosedBatchIsNotPlanned() async {
        let ai = FakeAIRepository()
        let (store, _) = await store(ai: ai, now: FakeClock.oct7at1840, attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seedWithTodayClosed))
        #expect(store.state == .none)
        #expect(ai.sheets.isEmpty)
    }

    @Test func noBatchTodayMakesNoPlan() async {
        let ai = FakeAIRepository()
        let (store, _) = await store(ai: ai, now: FakeClock.sat10at0930)
        #expect(store.state == .none)
        #expect(ai.sheets.isEmpty)
    }

    @Test func planningShowsTheLinesBeforeTheMaterial() async {
        let ai = FakeAIRepository()
        ai.delay = .seconds(5)
        let plans = FakePlansRepository()
        let store = PlanStore(classID: FakeClassesRepository.evening.id, workspace: FakeCentreRepository.meeraWorkspace, register: await register(evening: true), plans: plans, maker: PlanMaker(plans: plans, textbooks: FakeTextbooksRepository.evening(), attendance: FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed), ai: ai, cache: nil, now: { FakeClock.oct7at1635 }, calendar: DayHeading.india), cache: nil, now: { FakeClock.oct7at1635 }, calendar: DayHeading.india)
        let load = Task { await store.load() }
        try? await Task.sleep(for: .milliseconds(300))
        guard case .planning(let plan?) = store.state else { Issue.record("not planning with lines"); load.cancel(); return }
        #expect(plan.items.count > 0)
        #expect(store.groups[0].marks.allSatisfy { $0.state == .onItsWay })
        load.cancel()
    }

    @Test func aLineOpensItsArtefact() async {
        let (store, _) = await store()
        guard case let .made(plan) = store.state else { Issue.record("not made"); return }
        let homework = plan.items(of: FakeStudentsRepository.dev).first { $0.kind == .homework }!
        #expect(store.open(line: homework) == .artefact(homework.artefactID!))
        #expect(store.open(line: plan.items(of: FakeStudentsRepository.dev).first { $0.kind == .teach }!) == nil)
    }
}
```

- [ ] **Step 2: Run to verify they fail**, **Step 3: write `PlanMaker` and `PlanStore`** (the store: the copy first
  (`cache.load`), then `plans.plan`, then `maker.make` when online and the batch meets today and has no closed session
  today; `.offline` when not online and no copy; the card models from the record, the status word from the register's
  student, the marks from the artefacts present (`onItsWay` while `.planning`); the brief row after the group whose
  brief exists or is coming).
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** `git commit -m "Today: the plan maker and the plan store"`.

### Task 13: Today: the plan on screen, the line menu, Change the plan (PR 5)

**Files:**
- Create: `Sources/Features/Today/PlanSections.swift`, `PlanChangeSheet.swift`, `PlanStore+Change.swift`
- Modify: `TodayStore.swift` (`plans: [UUID: PlanStore]` for today's batches, `focusBatch: UUID?`), `TodayView.swift`
  (the section after the hero; `boardState` cases `.lineMenu`, `.planChanged`, `.changeSheet`, `.scrolledToPlan`),
  `TodayStore+Hero.swift` (the no-batch line stays), `TodayActions` (`openArtefact: (UUID) -> Void`)
- Test: `Tests/TodayTests/PlanChangeTests.swift`, `TodayStoreTests.swift`

**Interfaces:**
- `PlanStore` gains: `move(student: UUID, to group: Int) async`, `skipCheck(student:) async`, `skipHomework(student:)
  async`, `leaveOut(student:) async`, `keep(choices: PlanChoices, for weekday: Weekday) async`, `useToday(choices:)
  async` (make again with the choices), `message: String?` (the alert's words), `changeChoices: PlanChoices` (the
  sheet's current values from the record's groups), `subjectsOffered(group:) -> [String]` (the members' subjects).
- The section (from 10.3): "Today's plan" header with the quiet Change; one `GroupCard` per group; the brief row (the
  Phase 6 tool row) after `briefRow.afterGroup`; the `CreatingCard` while `.planning` with no lines; nothing while
  `.none` or `.offline`; `.failed` shows `LoadFailedView`'s footnote row with Try Again.
- The sheet (P10-Today-Plan-Change): a `FittedSheet` titled "Change the plan"; Groups (a segmented 1 | 2 | 3 with the
  line "One to three, by level. One group puts everyone together."); a row per group "Group n · Class k" with a menu of
  the subjects; a switch "Keep this for Wednesdays" with the line "The same subjects next Wednesday; the groups still
  follow the record"; the quiet "Make the plan again"; the primary "Use this plan".

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct PlanChangeTests {
    @Test func moveMarksTheStudentsLinesAndTheCardSaysSo() async {
        let (store, plans) = await PlanStoreTests().store()
        await store.move(student: FakeStudentsRepository.riya, to: 1)
        let plan = try? await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!)
        #expect(plan?.items(of: FakeStudentsRepository.riya).allSatisfy { $0.groupNo == 1 && $0.movedFrom == 2 } == true)
        #expect(store.groups[0].lines.first { $0.id == FakeStudentsRepository.riya }?.note == .movedFrom(2))
        #expect(store.changedNote)
    }

    @Test func skipHomeworkStrikesTheBitAndSaysSkippedToday() async {
        let (store, _) = await PlanStoreTests().store()
        await store.skipHomework(student: FakeStudentsRepository.nikhil)
        let line = store.groups[0].lines.first { $0.id == FakeStudentsRepository.nikhil }!
        #expect(line.note == .skipped("Homework skipped today"))
        #expect(line.rest.first { $0.text == "Homework sheet 1" }?.struck == true)
    }

    @Test func leaveOutRemovesTheStudentsLineFromTheCard() async {
        let (store, _) = await PlanStoreTests().store()
        await store.leaveOut(student: FakeStudentsRepository.meher)
        #expect(!store.groups.flatMap(\.lines).contains { $0.id == FakeStudentsRepository.meher })
    }

    @Test func aChangeOfflineIsRefusedInWordsAndChangesNothing() async {
        let (store, _) = await PlanStoreTests().store()
        store.online = { false }
        await store.skipCheck(student: FakeStudentsRepository.dev)
        #expect(store.message == OfflineRefusal.words(for: .changePlan))
        #expect(store.groups[0].lines[0].note == nil)
    }

    @Test func useTodayMakesThePlanAgainWithTheChoices() async {
        let (store, _) = await PlanStoreTests().store()
        await store.useToday(choices: PlanChoices(groups: 2, subjects: [1: "Mathematics"]))
        #expect(store.groups.count == 2)
        #expect(store.groups[0].line.contains("Mathematics"))
    }

    @Test func keepWritesTheWeekdaysPatternOnTheBatch() async {
        let (store, _) = await PlanStoreTests().store()
        await store.keep(choices: PlanChoices(groups: 2, subjects: [1: "Science", 2: "Mathematics"]), for: .wednesday)
        let classes = FakeClassesRepository.shared   // the fixture the register was built on
        #expect(classes.patterns[FakeClassesRepository.evening.id]?[.wednesday] == PlanPattern(groups: 2, subjects: ["Science", "Mathematics"]))
    }

    @Test func aMoveBeforeTheSheetLandsFollowsTheNewGroup() async {
        let ai = FakeAIRepository(); ai.delay = .milliseconds(400)
        let plans = FakePlansRepository()
        let (store, _) = await PlanStoreTests().store(plans: plans, ai: ai)   // returns once written; the material lands behind
        await store.move(student: FakeStudentsRepository.riya, to: 1)
        try? await Task.sleep(for: .seconds(3))
        let plan = try? await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!)
        let homework = plan?.items(of: FakeStudentsRepository.riya).first { $0.kind == .homework }
        #expect(homework?.artefactID == plan?.artefact(group: 1, kind: .sheet, homework: true)?.id)
    }

    @Test func makingAgainDropsLateAnswers() async {
        let ai = FakeAIRepository(); ai.delay = .milliseconds(400)
        let (store, plans) = await PlanStoreTests().store(ai: ai)
        await store.useToday(choices: PlanChoices(groups: 1, subjects: [:]))
        try? await Task.sleep(for: .seconds(3))
        let plan = try? await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!)
        #expect(plan?.groups.count == 1)
        #expect(plan?.artefacts.allSatisfy { $0.planID == plan?.id } == true)
        #expect(plan?.items.allSatisfy { $0.artefactID == nil || plan?.artefact($0.artefactID) != nil } == true)
    }
}

// TodayStoreTests (added)
@Test func todayHoldsAPlanStorePerBatchMeetingToday() async {
    let store = await todayStore(at: FakeClock.oct7at1635, evening: true)
    await store.load()
    #expect(Set(store.plans.keys) == Set([FakeClassesRepository.maths.id, FakeClassesRepository.evening.id]))
}

@Test func twoBatchesGetTwoPlans() async {
    let plans = FakePlansRepository()
    let store = await todayStore(at: FakeClock.oct7at1635, evening: true, plans: plans)
    await store.load()
    #expect(try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.maths.id, date: Day(iso: "2026-10-07")!) != nil)
    #expect(try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!) != nil)
}
```

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the code** (a move relinks the student's practise, check and
  homework items to the new group's artefacts when they exist, and the maker's late `.kept` for a group relinks all
  members of that group as of then; `useToday` cancels the running maker's task before it makes again, so a late answer
  from the old run is dropped by its generation).
- [ ] **Step 4: Run the tests**: PASS. **Step 5: Commit** `git commit -m "Today: the plan's cards and lines, the line menu, Change the plan"`.

### Task 14: AppShell: the plan's routes, the launch states, the background refresh, the reminder (PR 5)

**Files:**
- Create: `Sources/AppShell/Fixtures+Plan.swift` (the Evening batch's plan: the boards' groups, lines and artefacts;
  `FakePlansRepository` seeded per state), `AppShell/RootView+Artefacts.swift` (`Route.artefact` → the Artefacts
  feature, Task 16; a stub view until then is not built: the route is added in PR 6)
- Modify: `AppShell/RootView+Today.swift` (`PlanMaker` and `PlanCache` into `TodayStore`; `openArtefact` pushes
  `.artefact(id)` from PR 6 on), `RootView.swift` and `AppDelegate.swift` (the refresh's handler: the signed-in
  session's workspace → `PlanMaker.make` for today's batches not closed; `BackgroundRefresh.schedule(earliest:)` at
  06:00 tomorrow), `Data/Refresh/BackgroundRefresh.swift` (`schedule(at: Date)`), `LaunchState.swift`,
  `RootView+LaunchStates.swift`, `Fixtures.swift` (states, clocks, counts; `todayEvening` and `todayNoClass` retired),
  `Dependencies.swift` (`plans`, `photos`, wired live and fake), `ReminderScheduler.swift` (no change: the words are
  the planner's)
- Test: `Tests/AppShellTests/LaunchStateTests.swift`, `RefreshHandlerTests.swift`, `DependenciesVersionTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// LaunchStateTests
@Test func thePlansStatesAreNamedAsTheBoardsNameThem() {
    for name in ["today-scrolled", "today-planning", "today-line-menu", "today-plan-changed", "today-plan-change", "today-no-batch"] {
        #expect(LaunchState(rawValue: name) != nil, "\(name)")
    }
    #expect(LaunchState(rawValue: "today-evening") == nil)
    #expect(LaunchState(rawValue: "today-no-class") == nil)
}

// RefreshHandlerTests
@MainActor struct RefreshHandlerTests {
    @Test func theRefreshMakesTodaysPlansForTheSignedInCentre() async {
        let plans = FakePlansRepository()
        let handler = RefreshHandler(session: readySession(evening: true), plans: plans, maker: fakeMaker(plans: plans), now: { FakeClock.oct7at1635 })
        await handler.run()
        #expect(try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!) != nil)
    }

    @Test func theRefreshDoesNothingSignedOutOrOnADayWithNoBatch() async {
        let plans = FakePlansRepository()
        await RefreshHandler(session: signedOutSession(), plans: plans, maker: fakeMaker(plans: plans), now: { FakeClock.oct7at1635 }).run()
        await RefreshHandler(session: readySession(evening: true), plans: plans, maker: fakeMaker(plans: plans), now: { FakeClock.sat10at0930 }).run()
        #expect(plans.made.isEmpty)
    }

    @Test func theNextRefreshIsAskedForSixTomorrow() {
        #expect(BackgroundRefresh.nextMorning(after: FakeClock.oct7at1635, calendar: DayHeading.india) == FakeClock.at(2026, 10, 8, 6, 0))
    }
}
```

- [ ] **Step 2: Run to verify they fail**, **Step 3: write the code**: the fixtures' plan for `today*` states (the
  boards' content: Group 1 · Chemical reactions for Dev, Meher, Nikhil; Group 2 · Parts and Wholes for Riya; Group 3 ·
  Numbers for Sahil; the marks made; `today-planning` with the plan written and no artefacts and `FakeAIRepository.delay`
  long; `today-plan-changed` with Riya moved and Nikhil's homework skipped; `today-after-close` at 18:40 with the lines
  done); `today-no-batch` on Saturday 10 October (Phase 4's `today-no-class` content: the no-batch hero and the day's
  event); the refresh handler in AppShell built from `Dependencies` and the session store; `Dependencies.live()` with
  `SupabasePlansRepository` and `SupabasePhotoStore`.
- [ ] **Step 4: `bun check`**: PASS. **Step 5: Pictures**: `bun shots today` (both), `today-scrolled`, `today-planning`,
  `today-line-menu`, `today-plan-changed`, `today-plan-change`, `today-after-close`, `today-no-batch`; compare each to
  its board; `bun pr-shots phase-12-today-plan <files>`.
- [ ] **Step 6: Commit and open PR 5** (Tasks 11 to 14) with the table; merge when green and the pictures match.

### Task 15: DesignSystem: the artefacts' parts; the PDF renderer moved; Print (PR 6)

**Files:**
- Create: `Sources/DesignSystem/Components/BoardView.swift`, `KeyRow.swift`, `StepRow.swift`, `PhotoCard.swift`,
  `FigureCard.swift`, `PDF/PDFMaker.swift` (moved from AITools, over a `PDFSheet`), `PDF/Printer.swift`
- Modify: `Features/AITools/ResultFooter.swift` (adapts `GenerationResult` to `PDFSheet`), `Features/AITools/PDFMaker.swift`
  (deleted), `Tests/AIToolsTests/PDFMakerTests.swift` (moved to `DesignSystemTests`)
- Test: `Tests/DesignSystemTests/PDFMakerTests.swift`, `ArtefactPartsTests.swift`

**Interfaces** (from `components.md` 10.4):
- `PDFSheet(title:, instructions: String?, blocks: [PDFBlock])` with `PDFBlock.section(title:, lines: [(number, text,
  marks: String?)])`, `.key([(number, answer)])`, `.text(String)`; `PDFMaker.pdf(for: PDFSheet) throws -> URL`
  (A4, 40 pt margins, light, as today).
- `Printer.print(_ url: URL)`: `UIPrintInteractionController.shared` with the PDF as `printingItem`, presented from
  the key window (the UIKit reason in the file: SwiftUI has no print sheet).
- `BoardView(question: String, number: Int, count: Int, answer: String?, showsKey: Bool, previous:, next:, done:,
  toggleKey:)`: `ground` full screen, the top row (quiet Done, "3 of 8" `footnote` `text2`, quiet Key), the eyebrow,
  the question at `displayHero`'s 44/52 700, "Question n" `title2` `text2`, the answer under it in `ok` 600 when
  shown, the bottom row Previous (secondary 52, `chevron.left`) and Next (primary 52, `arrow.right`), equal widths.
- `KeyRow(number:, question:, answer:)`: the question row with its answer under it in `rowLine` `ok` 600.
- `StepRow(number:, title:, working: String?, shown: Bool)`: a 28 pt disc (`accentTint` and `accentText` when shown;
  `surface2` and `text2` when to come, the row at 0.45 with its title only), the title `rowTitle`, the working
  `subhead` `text2`.
- `PhotoCard(image: UIImage)`: `surface2`, the raised shadow, radius 18, as tall as the photo's aspect allows.
- `FigureCard(caption:) { figure }`: a list card (padding 16) holding the figure on `surface2` (radius 12, padding 12,
  centred) and the `footnote` `text2` caption centred.

- [ ] **Step 1: Write the failing tests**

```swift
struct PDFMakerTests {   // moved; the existing cases now build a PDFSheet
    @MainActor @Test func aSheetWithAKeyPrintsTheKeyLast() throws {
        let sheet = PDFSheet(title: "Balancing equations · sheet 1", instructions: "Show your working.", blocks: [.section(title: nil, lines: [(1, "Balance H₂ + O₂ → H₂O", nil)]), .key([(1, "2H₂ + O₂ → 2H₂O")])])
        let url = try PDFMaker.pdf(for: sheet)
        let text = try pdfText(url)
        #expect(text.contains("Answer key"))
        #expect(text.range(of: "Balance")!.lowerBound < text.range(of: "Answer key")!.lowerBound)
    }

    @MainActor @Test func aSheetWithoutAKeyHasNone() throws {
        let sheet = PDFSheet(title: "T", instructions: nil, blocks: [.section(title: nil, lines: [(1, "q", nil)])])
        #expect(!(try pdfText(try PDFMaker.pdf(for: sheet))).contains("Answer key"))
    }

    @Test func theFileNameDropsSlashesAndColons() {
        #expect(PDFMaker.fileName("Group 1: Science/Chemistry") == "Group 1- Science-Chemistry")
    }
}

struct ArtefactPartsTests {
    @Test func theBoardCountReads() {
        #expect(BoardView.countText(number: 3, of: 8) == "3 of 8")
    }

    @Test func aStepToComeShowsItsTitleOnly() {
        #expect(StepRow.showsWorking(shown: false, working: "w") == false)
        #expect(StepRow.showsWorking(shown: true, working: "w") == true)
    }
}
```

- [ ] **Step 2 to 4:** fail, write the parts, pass (`bun check --only=format,lint,ios`; the AITools result still shares
  its PDF: `aiResultPaper`'s picture unchanged).
- [ ] **Step 5: Commit** on `phase-12/sheet`: `git commit -m "DesignSystem: the board view, the key row, the step row, the photo and figure cards; the PDF renderer moved; Print"`.

### Task 16: Artefacts: the sheet in three forms, Share as PDF and Print (PR 6)

**Files:**
- Create: `Sources/Features/Artefacts/ArtefactsActions.swift`, `SheetStore.swift`, `SheetView.swift`,
  `SheetSections.swift`, `ArtefactWords.swift`; `Tests/ArtefactsTests/SheetStoreTests.swift`
- Modify: `Package.swift` (the `Artefacts` feature and `ArtefactsTests`), `ios/project.yml` (the test target in the
  scheme), `AppShell/TabsState.swift` (`Route.artefact(UUID)`), `TabsView.swift`, `RootView+Artefacts.swift`,
  `RootView+Today.swift` (`openArtefact`), `LaunchState.swift` (`sheet`, `sheetKey`, `sheetBoard`), `Fixtures+Plan.swift`

**Interfaces:**

```swift
/// A sheet's screen (P10-Sheet, -Key, -Board): the artefact read by id from the plans repository, the names of who it
/// is for from the register, the form chosen, the PDF made when the screen shows.
@MainActor @Observable public final class SheetStore {
    public enum Form: Hashable, Sendable { case paper, board, key }
    public init(artefactID: UUID, workspace: Workspace, register: any Register, plans: any PlansRepository, ai: any AIRepository, photos: any PhotoStore, now:, calendar:)
    public private(set) var artefact: Artefact?
    public private(set) var sheet: SheetContent?
    public private(set) var plan: PlanRecord?
    public var form: Form = .paper
    public var boardIndex = 0
    public var boardShowsKey = false
    public private(set) var loadFailed: String?
    public var eyebrow: String      // "Group 1 · Class 8 Science · Chemical reactions"
    public var title: String        // "Balancing equations · sheet 1"
    public var line: String         // "8 questions · for Dev, Meher and Nikhil · made today, 16:40"
    public var pdfSheet: PDFSheet   // with the key only when form == .key
    public func load() async
}
public struct ArtefactsActions { let pop: () -> Void; let openArtefact: (UUID) -> Void }
```

The screen: `BackRow` with the kind ("Sheet") and the quiet "Use my own" (Task 17); `ResultHero`; `Segmented` Paper |
Board | Key; Paper: the `PaperCard` section row ("1 mark each") and `QuestionRow`s; Key: `KeyRow`s under "Answers · for
you"; Board: a full-screen cover with `BoardView`; the footer band: the AI line, the quiet Make it again (Task 17),
Share as PDF (`ShareLink` on `PDFMaker.pdf(for:)`) and Print (`Printer.print`). The names line: "for Dev, Meher and
Nikhil" from the plan's group members (the first three by name, then "and n more"), "for Riya" for one.

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct SheetStoreTests {
    func store(plans: FakePlansRepository = seededPlans(), artefact: UUID? = nil) async -> SheetStore {
        let register = await register(evening: true)
        let id = artefact ?? plans.sample.artefact(group: 1, kind: .sheet, homework: true)!.id
        let store = SheetStore(artefactID: id, workspace: FakeCentreRepository.meeraWorkspace, register: register, plans: plans, ai: FakeAIRepository(), photos: FakePhotoStore(), now: { FakeClock.oct7at1640 }, calendar: DayHeading.india)
        await store.load()
        return store
    }

    @Test func theHeroNamesTheGroupTheClassAndWhoItIsFor() async {
        let store = await store()
        #expect(store.eyebrow == "Group 1 · Class 8 Science · Chemical reactions")
        #expect(store.title == "Balancing equations · sheet 1")
        #expect(store.line == "8 questions · for Dev, Meher and Nikhil · made today, 16:40")
    }

    @Test func theKeyIsLeftOutOfThePdfUnlessTheKeyFormShows() async {
        let store = await store()
        #expect(!store.pdfSheet.blocks.contains { if case .key = $0 { true } else { false } })
        store.form = .key
        #expect(store.pdfSheet.blocks.contains { if case .key = $0 { true } else { false } })
    }

    @Test func theBoardWalksTheQuestions() async {
        let store = await store()
        store.form = .board
        store.boardIndex = 2
        #expect(store.boardQuestion?.number == 3)
        #expect(store.boardCount == "3 of 8")
        store.boardShowsKey = true
        #expect(store.boardAnswer == store.sheet?.questions[2].answer)
    }

    @Test func anArtefactThatIsGoneSaysSoInItsPlace() async {
        let store = await store(artefact: UUID())
        #expect(store.loadFailed == "This sheet isn't here any more.")
    }

    @Test func aStudentsOwnSheetNamesTheStudent() async {
        let plans = seededPlans()
        let riyas = try! await plans.keep(NewArtefact(kind: .sheet, source: .made, title: "Fractions · sheet 1", content: .sheet(SheetContent(title: "Fractions", instructions: nil, questions: [], forHomework: true, light: true)), photoPath: nil, generationID: nil, regeneratedFrom: nil), plan: plans.sample.id, group: 2, student: FakeStudentsRepository.riya, itemKind: .homework, centre: FakeCentreRepository.meeraCentre.id)
        let store = await store(plans: plans, artefact: riyas.id)
        #expect(store.line.contains("for Riya"))
    }
}
```

- [ ] **Step 2 to 4:** fail, write the store and the screen, pass.
- [ ] **Step 5: Pictures** `bun shots sheet` (both), `sheet-key`, `sheet-board`; compare to the boards. **Step 6: Commit**
  `git commit -m "Artefacts: the sheet in three forms, Share as PDF and Print"`.

### Task 17: Artefacts: Make it again; Use my own (PR 6)

**Files:**
- Create: `Sources/Features/Artefacts/SheetStore+Again.swift`, `SheetStore+Own.swift`, `ReasonSheet.swift`,
  `OwnSheetMenu.swift`, `TypeItSheet.swift`; `Tests/ArtefactsTests/SheetAgainTests.swift`, `SheetOwnTests.swift`
- Modify: `SheetView.swift`, `LaunchState.swift` (`sheetRegenerate`, `sheetRegenerating`, `sheetOwnMenu`,
  `sheetOwn`), `Fixtures+Plan.swift`

**Interfaces:**

```swift
extension SheetStore {
    public enum Again: Hashable, Sendable { case idle, making(RegenerateReason), failed(String) }
    public var again: Again
    public var message: String?
    public var online: @Sendable () async -> Bool
    /// Make it again with a reason: the new sheet replaces this one on screen and in the plan; the old stays in the record.
    public func makeAgain(_ reason: RegenerateReason) async
    public var regeneratingLine: String   // "An easier sheet is on its way. This one stays until it arrives."
    // Own
    public enum Own: Hashable, Sendable { case none, photo(path: String), text(String) }
    public var own: Own
    public func useOwn(photo: Data) async   // reduce, upload, keep, relink
    public func useOwn(text: String) async
    public func useMadeInstead() async      // relinks the made sheet
}
```

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct SheetAgainTests {
    @Test func makeAgainReplacesTheSheetInThePlanAndKeepsTheOld() async throws {
        let plans = seededPlans(), ai = FakeAIRepository()
        let store = await SheetStoreTests().store(plans: plans)
        let old = store.artefact!.id
        await store.makeAgain(.easier)
        #expect(ai.sheets.last?.contains("easier") == true)
        #expect(store.artefact?.id != old)
        #expect(store.artefact?.regeneratedFrom == old)
        let plan = try await plans.plan(centre: FakeCentreRepository.meeraCentre.id, classID: FakeClassesRepository.evening.id, date: Day(iso: "2026-10-07")!)!
        #expect(plan.items.filter { $0.groupNo == 1 && $0.kind == .homework }.allSatisfy { $0.artefactID == store.artefact?.id })
        #expect(try await plans.artefact(id: old, centre: FakeCentreRepository.meeraCentre.id) != nil)
    }

    @Test func whileMakingTheOldStaysAndTheLineSaysWhat() async {
        let ai = FakeAIRepository(); ai.delay = .seconds(2)
        let store = await SheetStoreTests().store()
        let task = Task { await store.makeAgain(.shorter) }
        try? await Task.sleep(for: .milliseconds(200))
        #expect(store.again == .making(.shorter))
        #expect(store.regeneratingLine == "A shorter sheet is on its way. This one stays until it arrives.")
        #expect(store.sheet != nil)
        task.cancel()
    }

    @Test func aFailedRegenerateKeepsTheOld() async {
        let ai = FakeAIRepository(); ai.scriptByKind[.sheet] = .failure(.service)
        let store = await SheetStoreTests().store()
        let old = store.artefact!.id
        await store.makeAgain(.harder)
        #expect(store.artefact?.id == old)
        #expect(store.message == "Couldn't make it again. The sheet you have is still here.")
        #expect(store.again == .idle)
    }

    @Test func regenerateOfflineIsRefusedInWords() async {
        let store = await SheetStoreTests().store()
        store.online = { false }
        await store.makeAgain(.moreSums)
        #expect(store.message == OfflineRefusal.words(for: .regenerate))
    }

    @Test func theTutorsOwnWordsGoInTheReason() async {
        let ai = FakeAIRepository()
        let store = await SheetStoreTests().store()
        await store.makeAgain(.own("Only equations with oxygen"))
        #expect(ai.sheets.last?.contains("Only equations with oxygen") == true)
    }
}

@MainActor struct SheetOwnTests {
    @Test func aPhotoIsReducedUploadedKeptAndLinkedInPlaceOfTheSheet() async throws {
        let plans = seededPlans(), photos = FakePhotoStore()
        let store = await SheetStoreTests().store(plans: plans)   // with photos
        let made = store.artefact!.id
        await store.useOwn(photo: TestImages.jpeg(width: 3000))
        #expect(photos.paths.count == 1)
        #expect(photos.paths[0].contains("/own/"))
        #expect(photos.lastBytes < 1_500_000)
        #expect(store.artefact?.source == .own)
        #expect(store.artefact?.photoPath == photos.paths[0])
        #expect(store.title == "Your sheet · balancing equations")
        #expect(store.line.hasPrefix("A photo · added today, 16:40 · for Dev, Meher and Nikhil"))
        #expect(store.inPlaceLine == "Used in place of sheet 1. The plan and the record treat it as sheet 1: homework given, done, not done.")
        await store.useMadeInstead()
        #expect(store.artefact?.id == made)
    }

    @Test func typedWordsBecomeAnOwnSheetWithNoPhoto() async {
        let store = await SheetStoreTests().store()
        await store.useOwn(text: "1. Balance Fe + O2\n2. Balance Mg + O2")
        #expect(store.artefact?.source == .own)
        #expect(store.artefact?.photoPath == nil)
        if case let .own(own) = store.artefact!.content { #expect(own.text?.hasPrefix("1. Balance") == true) } else { Issue.record("not own") }
    }

    @Test func ownOfflineIsRefusedAndNothingUploads() async {
        let photos = FakePhotoStore()
        let store = await SheetStoreTests().store()
        store.online = { false }
        await store.useOwn(photo: TestImages.jpeg(width: 800))
        #expect(photos.paths.isEmpty)
        #expect(store.message == OfflineRefusal.words(for: .ownSheet))
    }
}
```

- [ ] **Step 2 to 4:** fail, write (the reasons menu as the system `Menu` with the six rows, "Say what to change…"
  opening `ReasonSheet` (a `FittedSheet` with a field of 200); `OwnSheetMenu` with Take a photo (`DocumentCameraView`,
  one page, after `CameraAccess`), Choose from Photos (`PhotosPicker`), Type it (`TypeItSheet`, a `NotesWell` of 4000);
  the own sheet's screen: the `PhotoCard` or the typed text, Replace in the nav row, the quiet "Use the made sheet
  instead", the in-place footnote), pass.
- [ ] **Step 5: Pictures** `sheet-regenerate`, `sheet-regenerating`, `sheet-own-menu`, `sheet-own`. **Step 6:
  Commit**, open PR 6 (Tasks 15 to 17); merge when green and the pictures match.

### Task 18: Artefacts: the worked example and the brief (PR 7)

**Files:**
- Create: `Sources/Features/Artefacts/WorkedExampleStore.swift`, `WorkedExampleView.swift`, `BriefStore.swift`,
  `BriefView.swift`; `Tests/ArtefactsTests/WorkedExampleStoreTests.swift`, `BriefStoreTests.swift`
- Modify: `LaunchState.swift` (`workedExample`, `brief`), `Fixtures+Plan.swift`, `RootView+Artefacts.swift` (the
  route opens the view by the artefact's kind)

**Interfaces:**

```swift
@MainActor @Observable public final class WorkedExampleStore {
    public init(artefactID:, workspace:, plans:, now:, calendar:)
    public private(set) var example: WorkedExample?
    public private(set) var shown = 1            // steps shown; "2 of 4"
    public func showNext(); public func showAll()
    public var countText: String                 // "2 of 4"
    public var canShowNext: Bool
    public var slip: String                      // under the footer's button
    public var intro: String                     // "One step at a time. Say each step aloud before you show the next."
}
@MainActor @Observable public final class BriefStore {
    public init(artefactID:, workspace:, plans:, now:, calendar:)
    public private(set) var brief: Brief?
    public var eyebrow: String                   // "Group 1 · Class 8 Science · Chemical reactions"
    public var title: String                     // "Your brief"
    public var line: String                      // "Five minutes to read before the class · made today, 16:40"
    public var copyText: String                  // the brief as plain text for Copy
}
```

The worked example's screen (P10-WorkedExample): the hero with the problem as the title and the intro line; a Steps
card of `StepRow`s with "2 of 4" beside the section title; Show all in the nav row; the footer: Show the next step
(primary) with the slip under it. The brief (P10-Brief): the hero; What the chapter is about; Three common mistakes
(`StepRow`s numbered, each with how to catch it); The worked example to use (a `ToolRow` that opens the example's
steps in place, as a sheet); Words to say (three lines); the footer: the AI line "AI can make mistakes. Read it as a
colleague's note, not a textbook.", Copy and Share as PDF (`PDFSheet` with `.text` blocks).

- [ ] **Step 1: Write the failing tests**

```swift
@MainActor struct WorkedExampleStoreTests {
    @Test func stepsShowOneAtATimeThenAll() async {
        let store = await exampleStore()   // the fixtures' four-step example
        #expect(store.countText == "1 of 4")
        store.showNext(); store.showNext()
        #expect(store.countText == "3 of 4")
        #expect(store.canShowNext)
        store.showAll()
        #expect(store.countText == "4 of 4")
        #expect(!store.canShowNext)
    }

    @Test func theSlipAndTheIntroAreTheBoards() async {
        let store = await exampleStore()
        #expect(store.intro == "One step at a time. Say each step aloud before you show the next.")
        #expect(store.slip.hasPrefix("A common slip here:"))
    }
}

@MainActor struct BriefStoreTests {
    @Test func theBriefReadsItsFourPartsAndCopiesAsText() async {
        let store = await briefStore()
        #expect(store.title == "Your brief")
        #expect(store.line == "Five minutes to read before the class · made today, 16:40")
        #expect(store.brief?.mistakes.count == 3)
        #expect(store.brief?.words.count == 3)
        #expect(store.copyText.contains("Three common mistakes"))
        #expect(store.copyText.contains("Words to say"))
    }
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Pictures** `worked-example`, `brief`. **Step 6: Commit** on
  `phase-12/artefacts`: `git commit -m "Artefacts: the worked example and the brief"`.

### Task 19: DesignSystem and Artefacts: the seven figures (PR 7)

**Files:**
- Create: `Sources/DesignSystem/Components/Figures/FigureView.swift` (the switch), `NumberLineFigure.swift`,
  `FractionBarFigure.swift`, `PlaceValueFigure.swift`, `UnitCircleFigure.swift`, `TriangleFigure.swift`,
  `LabelledCellFigure.swift`, `FoodChainFigure.swift`, `Sources/Features/Artefacts/FigureStore.swift`,
  `FigureScreen.swift`; `Tests/DesignSystemTests/FigureViewTests.swift`, `Tests/ArtefactsTests/FigureStoreTests.swift`
- Modify: `LaunchState.swift` (the seven `figure-*`), `Fixtures+Plan.swift`, `RootView+Artefacts.swift`

**Interfaces:**
- `FigureView(spec: FigureSpec)`: draws the validated spec with `Canvas` and `Path` in tokens (strokes `text2`, axes
  `lineStrong`, the thing to see `accent`, a second thing `ok`, the triangle's fill `accentTint`, labels `caption`
  `text2`, values 600 `text` or `accentText`), each at a fixed aspect inside the card's width; `FigureView.caption(for:
  spec)` is "what the app checked": "The jumps land on 16, inside the line." / "4 equal parts, 3 shaded: 3/4." / "4,507
  read by place." / "30° on the unit circle: sine 0.5, cosine 0.87." / "Angles 90°, 60°, 30° add to 180°." / "5 parts
  named as the chapter names them." / "4 links, grass first."
- `FigureStore(artefactID:, …)`: `figure: FigureContent?`, `eyebrow` (the skill), `caption` (the model's), `checked`
  (the app's), `large: Bool` (Show large: a full-screen cover), the footer's AI line "Figures are drawn by the app, never
  pictures made up by the AI, so every label is right.", Show large, Print (the figure rendered to a PDF page with
  `ImageRenderer` through `PDFMaker.pdf(for: PDFSheet(.figure))`: a `.image(UIImage)` block is added to `PDFBlock`).

- [ ] **Step 1: Write the failing tests**

```swift
struct FigureViewTests {
    @Test func theCheckedCaptionsSayWhatTheAppChecked() {
        #expect(FigureView.checkedCaption(.numberLine(from: 0, to: 20, step: 2, start: 4, jumps: [6, 6])) == "The jumps land on 16, inside the line.")
        #expect(FigureView.checkedCaption(.fractionBar(parts: 4, shaded: 3, label: "3/4")) == "4 equal parts, 3 shaded: 3/4.")
        #expect(FigureView.checkedCaption(.placeValue(number: 4507)) == "4,507 read by place.")
        #expect(FigureView.checkedCaption(.unitCircle(angleDegrees: 30)) == "30° on the unit circle: sine 0.5, cosine 0.87.")
        #expect(FigureView.checkedCaption(.triangle(angles: [90, 60, 30], labels: ["AB", "BC", "CA"])) == "Angles 90°, 60°, 30° add to 180°.")
        #expect(FigureView.checkedCaption(.labelledCell(kind: .plant, labels: ["a", "b", "c", "d", "e"])) == "5 parts named as the chapter names them.")
        #expect(FigureView.checkedCaption(.foodChain(links: ["Grass", "Grasshopper", "Frog", "Snake"])) == "4 links, grass first.")
    }

    @Test func thePlaceValueColumnsReadTheDigitsAndTheirWorth() {
        #expect(PlaceValueFigure.columns(4507).map(\.place) == ["Thousands", "Hundreds", "Tens", "Ones"])
        #expect(PlaceValueFigure.columns(4507).map(\.digit) == [4, 5, 0, 7])
        #expect(PlaceValueFigure.columns(4507).map(\.worth) == ["4,000", "500", "0", "7"])
    }

    @Test func theUnitCircleRatiosRoundToTwoPlaces() {
        #expect(UnitCircleFigure.ratios(30) == (sine: "0.5", cosine: "0.87"))
        #expect(UnitCircleFigure.ratios(90) == (sine: "1", cosine: "0"))
    }

    @Test func aTriangleMarksTheRightAngleOnlyWhenOneIsNinety() {
        #expect(TriangleFigure.rightAngleIndex([90, 60, 30]) == 0)
        #expect(TriangleFigure.rightAngleIndex([60, 60, 60]) == nil)
    }
}

@MainActor struct FigureStoreTests {
    @Test func theFigureScreenReadsTheSkillTheCaptionsAndTheAiLine() async {
        let store = await figureStore(.fractionBar(parts: 4, shaded: 3, label: "3/4"))
        #expect(store.eyebrow.contains("Compare simple fractions"))
        #expect(store.checked == "4 equal parts, 3 shaded: 3/4.")
        #expect(store.aiLine == "Figures are drawn by the app, never pictures made up by the AI, so every label is right.")
    }

    @Test func aSpecThatFailsIsNotDrawnAndSaysSo() async {
        let store = await figureStore(.foodChain(links: ["Grass"]), validated: false)
        #expect(store.figure == nil)
        #expect(store.loadFailed == "This figure can't be drawn.")
    }
}
```

- [ ] **Step 2 to 4:** fail, write the seven figures and the screen, pass.
- [ ] **Step 5: Pictures** the seven `figure-*` states (the fixtures' specs are the boards'). **Step 6: Commit**, open
  PR 7 (Tasks 18, 19); merge when green and the pictures match.

### Task 20: Today: the close from the plan (PR 8)

**Files:**
- Modify: `Sources/Features/Today/CloseStore.swift` (`plan: PlanRecord?`, the checklist, `planLink`),
  `CloseStore+Checks.swift` (from the plan first), `CloseStore+Done.swift` (`done` items, the sheet's artefact id),
  `CloseStore+Queue.swift` (unchanged: the close carries `done`), `CloseSections.swift` (the checklist cards, the
  Plan link, "Homework given · sheet 1"), `CloseView.swift`, `AppShell/RootView+Close.swift` (`plans`, `PlanCache`)
- Test: `Tests/TodayTests/CloseStoreTests.swift`, `CloseQueueTests.swift`

**Interfaces:**

```swift
extension CloseStore {
    public struct ChecklistCard: Identifiable, Hashable, Sendable { public let id: Int; public let title: String; public let rows: [ChecklistLine] }
    public struct ChecklistLine: Identifiable, Hashable, Sendable { public let id: UUID (the first item of the kind in the group); public let text: String; public var done: Bool; let itemIDs: [UUID] }
    public private(set) var checklist: [ChecklistCard]     // one per group: Teach, Practise, Check, Homework (+ Catch up, Placement lines as the plan has them)
    public func toggle(line: UUID, in group: Int)
    public var countText(for group: Int) -> String           // "2 of 5"
    public var hasPlan: Bool                                 // the quiet Plan shows
    func homeworkLabel(_ student: CloseStudent) -> String    // "Homework given · sheet 1" / "Homework given"
}
```

The checks: `load()` reads the plan (`plans.plan` online, else `PlanCache.load`), and for each present student takes
`plan.checks(for:)` → `.rows` from its `CheckContent` (placement content → `.placement`), with no call; a student the
plan left out (all items skipped) has `.none` with attendance only and homework off; only a student with no plan
checks (joined after the plan, or no plan at all) goes Phase 11's way. `done()` adds `done: [UUID]` (the ticked lines'
item ids) and the student's homework item's `artefactID` to `SessionClose.Homework`. The intro and footnote are the
boards'; the top row gains the quiet "Plan" (pops to Today) when `hasPlan`.

- [ ] **Step 1: Write the failing tests**

```swift
// CloseStoreTests (added; the helper gains `plans: FakePlansRepository = seededPlans()`)
@Test func aCloseFromThePlanTakesItsChecksAndMakesNoCall() async {
    let ai = FakeAIRepository()
    let store = await store(ai: ai)
    #expect(ai.checkCalls.isEmpty && ai.placementCalls.isEmpty)
    guard case let .rows(rows)? = store.students.first { $0.id == FakeStudentsRepository.dev }?.checks else { Issue.record("no rows"); return }
    #expect(rows.count == 3)
    #expect(rows[0].skill == "Balancing equations")
    guard case .placement? = store.students.first { $0.id == FakeStudentsRepository.riya }?.checks else { Issue.record("no placement"); return }
}

@Test func theChecklistHasACardPerGroupWithItsLines() async {
    let store = await store()
    #expect(store.checklist.map(\.title) == ["Group 1 · Chemical reactions", "Group 2 · Parts and Wholes", "Group 3 · Numbers"])
    #expect(store.checklist[0].rows.map(\.text) == ["Teach: Balancing equations", "Practise set 1", "Check 3", "Homework sheet 1"])
    store.toggle(line: store.checklist[0].rows[0].id, in: 1)
    #expect(store.countText(for: 1) == "1 of 4")
}

@Test func doneWritesTheTickedLinesAndTheSheetGiven() async throws {
    let attendance = FakeAttendanceRepository(sessions: FakeAttendanceRepository.seed)
    let store = await store(attendance: attendance)
    store.toggle(line: store.checklist[0].rows[0].id, in: 1)
    #expect(await store.done())
    let close = attendance.closes.last!
    #expect(close.done.count == 3)   // Dev, Meher and Nikhil's teach items
    #expect(close.homework.first { $0.studentID == FakeStudentsRepository.dev }?.artefactID == seededPlans().sample.artefact(group: 1, kind: .sheet, homework: true)?.id)
    #expect(store.homeworkLabel(store.students[0]) == "Homework given · sheet 1")
}

@Test func aStudentLeftOutClosesWithAttendanceAlone() async {
    let plans = seededPlans()
    try? await plans.leaveOut(student: FakeStudentsRepository.meher, plan: plans.sample.id, centre: FakeCentreRepository.meeraCentre.id)
    let store = await store(plans: plans)
    let meher = store.students.first { $0.id == FakeStudentsRepository.meher }!
    #expect(meher.checks == .none)
    #expect(!meher.homeworkGiven)
}

@Test func aCloseFromACachedPlanMakesNoCall() async {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let cache = PlanCache(centre: FakeCentreRepository.meeraCentre.id, directory: directory)
    cache.keep(seededPlans().sample, at: FakeClock.oct7at1640)
    let ai = FakeAIRepository()
    let textbooks = FakeTextbooksRepository.evening(); textbooks.failure = TransportError.offline
    let store = await store(ai: ai, textbooks: textbooks, plans: FakePlansRepository(failure: TransportError.offline), cache: cache)
    guard case .rows? = store.students.first { $0.id == FakeStudentsRepository.dev }?.checks else { Issue.record("no rows from the copy"); return }
    #expect(ai.checkCalls.isEmpty)
}

@Test func aV1StudentTakesTheGroupsChecks() async {
    let plans = seededPlans(withBir: true)   // Bir, no class level, in Group 1 by the rules
    let store = await store(plans: plans)
    guard case let .rows(rows)? = store.students.first { $0.name.hasPrefix("Bir") }?.checks else { Issue.record("no rows"); return }
    #expect(rows.map(\.skill) == ["Balancing equations", "Types of reactions", "Chemical change"])
}

@Test func withoutAPlanTheCloseIsPhaseElevens() async {
    let ai = FakeAIRepository()
    let store = await store(ai: ai, plans: FakePlansRepository())
    #expect(store.checklist.isEmpty)
    #expect(!store.hasPlan)
    #expect(!ai.checkCalls.isEmpty)
    #expect(store.homeworkLabel(store.students[0]) == "Homework given")
}

// CloseQueueTests (added)
@Test func aQueuedCloseCarriesItsDoneLines() async {
    let store = await store(online: false)
    store.toggle(line: store.checklist[0].rows[0].id, in: 1)
    _ = await store.done()
    guard case let .close(close, _, _, _)? = queue.pending.changes.last?.kind else { Issue.record("not queued"); return }
    #expect(!close.done.isEmpty)
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Commit** on `phase-12/close-plan`: `git commit -m "Today: the close from the plan"`.

### Task 21: Today: the close card's three states (U37, U38) and the pending close's symbol (U39) (PR 8)

The boards P12-Close-Cards and P12-Pending-Close are approved (decision 24).

**Files:**
- Modify: `Features/Today/CloseSections.swift` (the card states to the board), `CloseStore+Checks.swift` (the words),
  `Features/Settings/Pending/PendingChangesView.swift` (`symbol(.close)` → the board's), `LaunchState.swift`
  (`closeCards`), `Fixtures+Record.swift` (the state's three students: one with the checks being made, one with no
  book, one offline), `docs/design/*` mirrors (Task 25)
- Test: `Tests/TodayTests/CloseStoreTests.swift` (the words), `Tests/SettingsTests/PendingChangesStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
@Test func theCardStatesWordsAreTheBoards() async {
    #expect(CloseStore.offlineWords == P12Words.closeOffline)      // the board's sentence, set at approval
    #expect(CloseStore.noBookWords(firstName: "Bir") == P12Words.closeNoBook("Bir"))
    #expect(CloseStore.makingWords == P12Words.closeMaking)
}

// PendingChangesStoreTests
@Test func aWaitingCloseWearsItsOwnSymbol() {
    #expect(PendingChangesView.symbol(.close(close: sampleClose, className: "Evening batch", present: 4, total: 5)) == "checklist")
    #expect(PendingChangesView.symbol(.attendance(classID: nil, className: "x", date: Day(iso: "2026-10-07")!, marks: [:], present: 0, total: 0)) == "checkmark.circle")
}
```

`P12Words` is the test's copy of the approved board's sentences (`components.md` "Phase 12 parts"); the plan fills
them in when the boards are approved, so the build reads the words from the mirror, not from this plan.

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Pictures** `close` (both), `close-scrolled`, `close-placement`,
  `close-cards` (both), `pending`. **Step 6: Commit** `git commit -m "The close card's three states (U37, U38); the waiting close's symbol (U39)"`.

### Task 22: Today: the close offline from the plan's copy; Today's hero after a close from a plan (PR 8)

**Files:**
- Modify: `CloseStore.swift` (the copy when the reads fail), `TodayStore+Hero.swift` (the closed hero's line reads the
  plan's counts from the close kept here, as Phase 11), `RootView+Close.swift`
- Test: `Tests/TodayTests/CloseQueueTests.swift`, `TodayStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
@Test func offlineTheCloseListsTheStudentsAndTheChecksFromTheCopyAtOnce() async {
    // the gateway down: each read fails after its timeout; the copy answers first
    let store = await store(online: false, plansFailing: true, cache: cacheWithSamplePlan())
    #expect(store.loaded)
    #expect(store.students.allSatisfy { if case .rows = $0.checks { true } else if case .placement = $0.checks { true } else { false } })
    #expect(store.canFinish)
}

@Test func afterACloseFromAPlanTodaysHeroCountsItsChecks() async {
    let store = await todayStore(at: FakeClock.oct7at1840, evening: true, closedToday: true)
    await store.load()
    #expect(store.hero?.kind == .closed)
    #expect(store.hero?.line.contains("checks right") == true)
    #expect(store.plans[FakeClassesRepository.evening.id]?.groups.allSatisfy { $0.lines.allSatisfy { $0.done } } == true)
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Hand run 4** (Task 24). **Step 6: Commit**, open PR 8 (Tasks 20
  to 22) with the pictures; merge when green and the pictures match.

### Task 23: Students: This week's "Today" (U35); a homework row opens its sheet (PR 9)

**Files:**
- Modify: `Sources/Features/Students/StudentsActions.swift` (`openToday: (UUID) -> Void`, `openArtefact: (UUID) ->
  Void`), `RecordSections.swift` (the quiet "Today" on This week's header when the student's batch meets today; a
  homework row with an artefact opens it), `StudentDetailStore+Record.swift` (`todaysBatch: UUID?`; `HomeworkRecord`
  gains `artefactID: UUID?` in Domain and the row), `Domain/Record/RecordTypes.swift`, `Data/Record/RecordRows.swift`,
  `AppShell/RootView+Students.swift` (`openToday` selects the Today tab and sets `today.focusBatch`), `TodayView.swift`
  (scrolls to the batch's plan card when `focusBatch` is set, then clears it)
- Test: `Tests/StudentsTests/StudentDetailStoreTests.swift`, `Tests/AppShellTests/TabsStateTests.swift`,
  `Tests/TodayTests/TodayStoreTests.swift`

- [ ] **Step 1: Write the failing tests**

```swift
// StudentDetailStoreTests
@Test func thisWeekOffersTodayWhenTheBatchMeetsToday() async {
    let store = await detailStore(for: FakeStudentsRepository.dev, at: FakeClock.oct7at1635, evening: true)
    #expect(store.todaysBatch == FakeClassesRepository.evening.id)
    let saturday = await detailStore(for: FakeStudentsRepository.dev, at: FakeClock.sat10at0930, evening: true)
    #expect(saturday.todaysBatch == nil)
}

@Test func aHomeworkRowKnowsItsSheet() async {
    let store = await detailStore(for: FakeStudentsRepository.dev, at: FakeClock.oct7at1840, evening: true, homeworkWithSheet: true)
    #expect(store.homeworkRows.first?.artefactID != nil)
}

// TabsStateTests
@Test func openTodaySelectsTheTabAndFocusesTheBatch() {
    let shell = ShellState()
    shell.tabs.select(.students)
    shell.openToday(batch: FakeClassesRepository.evening.id)
    #expect(shell.tabs.selected == .today)
    #expect(shell.today?.focusBatch == FakeClassesRepository.evening.id)
}
```

- [ ] **Step 2 to 4:** fail, write, pass. **Step 5: Picture** `student-record` (This week with the quiet Today).
  **Step 6: Commit** on `phase-12/student-today`, open PR 9; merge when green. Move U35 to Done on `ui-polish.md` in
  Task 25.

### Task 24: The deploy, the hand runs (D32), the cost run, TestFlight (main)

- [ ] **Step 1 (after PR 2):** `gh workflow run deploy`; the summary shows 0019 pending, pushed, nothing after; the
  API smoke green. Record the run id in `STATE.md`'s Production.
- [ ] **Step 2 (after PR 9):** the hand runs below, then the cost run, then `gh workflow run testflight`; the build
  number from the run; the owner installs it from the internal group and checks the plan on his iPhone.

**The hand runs,** by `docs/runbooks/simulator.md` from a cold simulator against a freshly reset seed (decision 21),
signed in as Meera, each write confirmed in the database, each screenshot kept in `.shots/run/` and attached to the
phase's issue ("Phase 12 hand run"); the local API with `AI_FAKE=1` except run 8. The Evening batch meets Monday to
Friday 17:00 to 18:30; a run on another hour moves the batch's time by psql first and puts it back after (session
24's practice).

| Run | Before merging | Through the screens | Confirm |
|---|---|---|---|
| 1 The plan made on open | PR 5 | Today (within 90 minutes of the Evening batch) → "Planning today's class" → the three group cards fill in: the marks tick, the brief row after Group 1; Today again → the plan opens at once | `select id, groups, subjects from plans where date = current_date`; `select kind, group_no, count(*) from plan_items where plan_id = … group by 1, 2`; `select kind, source, title, student_id from artefacts where plan_id = …` (the checks, two sheets, the example per group; a figure for Group 2's fractions; the brief for Group 1; Riya's placement); `select kind, model, tokens_in, tokens_out from ai_generations where created_at > now() - interval '10 minutes'` |
| 2 A regenerate | PR 6 | A line's "Homework sheet 1" → the sheet → Paper, Key, Board (Next, Key) → Make it again → Easier → "Making it easier" → the new sheet → Share as PDF (the share sheet) → Print (the print sheet, cancelled) | `select id, regenerated_from from artefacts where kind = 'sheet' order by created_at desc limit 2`; the plan's homework items point at the new id; `ai_generations` has the sheet with `reason` in its input |
| 3 Use my own | PR 6 | The sheet → Use my own → Choose from Photos (a page added with `simctl addmedia`) → "Your sheet" in place, the in-place footnote → Replace → Type it → two lines → the typed sheet → Use the made sheet instead | `select source, photo_path, content from artefacts where source = 'own'` (one with a path under `<centre>/own/`, one with text); Studio's Storage shows the object; the items point at the made sheet again |
| 4 The close from the plan, online | PR 8 | Today → Start class → the checklist cards (tick Teach and Practise of Group 1) → Dev's checks Right, Wrong, Right (the plan's questions, no wait) → Riya's placement rows → Sahil absent → Done → Today's hero reads closed; the plan's lines show done | `select done_at from plan_items where plan_id = …` (the ticked lines); `select artefact_id from homework where session_id = …` (the sheets); `select count(*) from checks where session_id = …`; `select session_id from plans where id = …` |
| 5 The close offline | PR 8 | `docker stop supabase_kong_tutor_central` → Today (the plan from its copy) → Start class → the checks are there, no wait → Dev absent → Done → "saved on this iPhone" → Pending changes: the close with its own symbol → `docker start` → sent | `attendance_sessions` closed with `plan_id`; `plan_items.done_at`; the queue file gone |
| 6 Change the plan | PR 5 | Today → long-press Riya → Move to Group 1 → "Moved here from Group 1"; long-press Nikhil → Skip homework today → struck; Change → Groups 2 → Keep this for <today>s on → Use this plan → two groups | `select group_no, moved_from, skipped_at from plan_items where student_id in (…)`; `select plan_groups, plan_pattern from classes where name = 'Evening batch'` |
| 7 U35 | PR 9 | Students → Dev Kumar → This week → Today → the Today tab scrolled to the Evening batch's plan | the screenshot; nothing written |
| 8 The cost run | PR 9 | `supabase db reset`; the local API **without** `AI_FAKE` (the owner told first: about ₹10); Today → the plan for the twelve-student Evening batch → wait for all the marks to tick | the query below; the figure into the session record, "As built" and `PriceSheet.typical` |
| 9 A V1 student in the plan | PR 8 | Students → Bir Bikram Singh → Edit → Batch: Evening batch → Save → Today → Make the plan again (Change) → Bir's line in the largest group ("Teach: with the group" is not shown: the group has a skill) → Start class → his card has the group's three checks | `plan_items` rows for Bir with `group_no` of the largest group; `checks` rows for him after Done |

**The cost query** (run 8), the numbers by the price sheet (decision 6):

```sql
select kind, model, count(*) as calls, sum(tokens_in) as tokens_in, sum(tokens_out) as tokens_out,
       round(sum(case model when 'claude-haiku-5-5' then tokens_in * 0.10 + tokens_out * 0.50
                            when 'claude-sonnet-5-5' then tokens_in * 2 + tokens_out * 10
                            else tokens_in * 4 + tokens_out * 20 end) / 1e6 * 85, 2) as rupees
  from public.ai_generations
 where created_at > now() - interval '30 minutes' and status = 'ok'
 group by 1, 2 order by rupees desc;
```

The record writes: calls, tokens and rupees per kind and model, the total for the batch, and the monthly figure at
twenty sessions; `PriceSheet.typical` takes the measured averages (a documents-only change if it moves no test; else
with PR 9's follow-up).

### Task 25: The documents (main)

- [ ] **Step 1:** `docs/testing/device-tests.md` gains a Phase 12 section for the tester: T4 the plan made in the
  background overnight on a real iPhone (open the app the next morning: the plan is there without the planning card),
  T5 the reminder an hour before the batch, its tap opening Today, T6 Print from the sheet to a real printer, T7 Use my
  own with the camera on a real sheet.
- [ ] **Step 2: Documents (D12), one commit to `main` when the phase ends:** `plan/phase-12-class-plan.md` "As built"
  (what the plan, the budget, the artefacts and the close settled; the cost measured; where the build moved from this
  plan and why); `plan/README.md` (Phase 12 done; a decision number if the owner rules one); `plan/STATE.md`
  (production: 0019, the API commit, the build); `plan/ui-polish.md` (U35, U37, U38, U39 to Done with their pull
  requests; anything seen); `docs/design/information-architecture.md` ("Phase 12 boards": the two boards, their
  states; the launch states list), `components.md` ("Phase 12 parts": the card states' words, the pending symbol; "As
  built in Phase 12" under 10.3 and 10.4), `design-tokens.md` ("Numbers in code": three groups at most, four personal
  checks, twenty calls, the class reminder's default an hour, the plan's copy per batch and day, the own photo's
  path); `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md` for rules learned; `plan/sessions/026/record.md`,
  `ledger.md` and `owner-messages.md`; then a reviewer pass over the merged pull requests with
  `superpowers:requesting-code-review` on Fable 5.1 (fresh context), its Important findings fixed with a test that
  failed first, before the TestFlight build of Task 24 step 2 (as Phases 6, 7, 10 and 11 did).

---

## Self-review (done 2026-10-10)

**Spec coverage** (`phase-12-class-plan.md`'s six scope items): 1 the plan (groups, the subject, four lines, catch-up
lines, move, drop the groups, skip, a plan with no record) → Tasks 5, 12, 13, 2 and 3 (`/ai/plan`); 2 the material (the
set, the sheet in three forms, the checks, the worked example, the seven figures, the brief above class 7 or asked,
regenerate with a reason, Own) → Tasks 2, 3, 6, 15 to 19; 3 when it is made (on open with the planning card, the
background refresh, the reminder at the tutor's time, the budget) → Tasks 12, 14, 7, 6; 4 the close from the plan
(the checklist, the checks and homework from the plan, offline) → Tasks 1, 9, 20, 22; 5 the cost measured → Task 24
run 8 and decision 22; 6 U35, U37, U38, U39 → Tasks 23, 21, with the boards of decision 24. The acceptance's "a student
without consent gets group material and checks and no personal artefact" → review focus 2 (Tasks 3, 6, 10).

**Placeholder scan:** no "TBD", no "similar to Task N" without the code; the views are specified by their Kit parts and
the boards' texts, as this repository's plans do. Two sentences wait on the owner: the card states' words (Task 21,
`P12Words`) are read from the approved board's mirror, not invented here.

**Type consistency:** `PlanDraft`, `PlanGroup`, `PlanLine`, `PlanLineKind`, `PlanItem`, `PlanRecord`, `Artefact`,
`ArtefactKind`, `ArtefactContent`, `NewArtefact`, `PlanPattern`, `PlanChoices`, `RegenerateReason` (Tasks 4, 8, 12) are
used by those names in Tasks 5, 6, 8, 12, 13, 16, 17, 20; `ArtefactRequest` (Task 6) by Task 12; `FigureSpec.numberLine
(from:to:step:start:jumps:)` (Task 7) by Tasks 2, 10, 19; `MadeSheet`, `MadeWorkedExample`, `MadeFigure`, `MadeBrief`,
`MadeChecks`, `PlanTopic` (Task 10) by Task 12; `PlanCache` (Task 8) by Tasks 12, 20, 22; `PhotoStore` (Task 9) by Tasks
16, 17; `SessionClose.done` (Task 9) by Tasks 20, 22; `Route.artefact` (Task 16) by Tasks 14, 23; `GroupCardModel`,
`PlanLineModel`, `BriefRowModel`, `ReadyMark`, `PlanLineNote`, `LineBit` (Tasks 11, 12) by Task 13; `seededPlans()` and
`register(evening:)` are each test target's helpers (TodayTests, ArtefactsTests), as Phase 11's were; `FakeClock.oct7at1640`
is added beside the others.

**Review focus:** the eight lines each name their tests; the two new board sentences and the three refusals pass
`ErrorWordsTests`; the cost run is the one step that spends money and the owner is told first (decision 22).
