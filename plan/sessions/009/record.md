# Session 9 (2026-10-08): Phase 4 built

Model: Claude Opus 5.5 (D17), from `resume/008-phase-4-build.md`, executing `plan/phase-04-plan.md` inline with
`superpowers:executing-plans` (a ledger of rulings kept outside the repo; the rulings are below). Outcome: PRs #36 to
#42 merged, as the plan's seven, and the review fixes in #44; migration 0004 `save_attendance` in production (deploy
run 37758056602, then 0005 `message_log.about_date` with the review fixes (deploy run 37773505389), nothing pending
after); the hand run of every Phase 4 write path by the runbook (issue #43); build 0.1.0 (7) (run 37773860384) on
TestFlight. A fresh reviewer (Fable) found 1 Critical and 4 Important; all five fixed in #44, eight minors deferred.

## What was done, in order

1. Read the rules, state, decisions, the scope, the plan, the design documents, the runbook, the polish list and the
   records of sessions 6 to 8. Reality matched `STATE.md`; `bun check` green; the local stack up. Rendered the 27 P4
   boards with headless Chrome so each screen could sit beside its board (a pair image per state).
2. PR #36 Domain (Tasks 1 to 4), tests first. PR #37 migration 0004 with four RLS tests, merged and deployed at once
   (D26). PR #38 Data (Tasks 6 to 8): every decoding fixture is the local stack's real answer (curl as the seed's
   tutor), and every write path was run in Swift against the local stack (a throwaway test, deleted).
3. PR #39 the Attendance tab (Tasks 9 to 11): the components, `AttendanceStore`, seven states. PR #40 History and the
   student's month (Tasks 12, 13). PR #41 Schedule (Tasks 14 to 16, the event writes proven in Swift through the store).
   PR #42 Tasks, Today live and More (Tasks 17 to 19, the task writes proven in Swift through the store).
4. Every state photographed in both appearances and compared with its board before its PR merged.
5. The hand run (D32) from a cold simulator against a fresh seed, through the screens, every write confirmed with
   psql (issue #43). It found four bugs, fixed in #42 with tests.
6. The reviewer pass on the range; its five findings fixed in #44 with migration 0005, deployed (run 37773505389), the
   follow-up hand run of the fixed paths; TestFlight build 7; the documents.

## Why things are as they are

- **`Register` in Domain (D33):** `RegisterStore` is the Students feature's; Attendance, Schedule and Today read it
  through a Domain protocol AppShell passes, so features never import each other and the register is read once.
- **Each screen keeps its store in `@State`:** AppShell builds History's, the schedule's, the student month's and the
  student detail's store each time it builds the view; the view must keep the first one or a loaded store is swapped
  for an empty one (seen as blank pictures).
- **One attendance store and one tasks store per centre** on `ShellState` (the plan's decision): a tab switch keeps
  the toggles; Today and the Tasks screen share the add field. The attendance store's first load stands aside once a
  link or Mark attendance asked for a class and day (found in the hand run).
- **Saves that wait, edits that roll back:** attendance saves, event adds and deletes wait for the server; task writes
  and event edits are optimistic and roll back with a toast and Retry (the plan's decision).
- **The boards win, the data wins over a board's numbers:** where a board's layout or interaction differed from the
  plan (event sheets at the large detent, the delete confirmation over the schedule, the date chip that opens a
  picker), the board was built; where a board's figures could not come from the seed (September's line, the schedule's
  dots, a note's count, an overdue colour), the screen shows the data and the board's words are listed for correction.

## Rulings (from the ledger, in order)

- Setup: work in the main checkout on one phase-4/* branch per PR, no worktree; ignored Local.xcconfig, .shots and
  DerivedData live here; the owner named per-PR branches; cost if wrong: none (branches isolate)
- Task 3: SwiftFormat strips force-unwraps in tests, so the plan's optional-tuple comparisons in dueWordsAndOverdue
  cannot compile; a test helper renders (text, overdue) as one string; same assertions; cost if wrong: none
- Task 4: SwiftLint refuses AbsenceMessage.text's 7 parameters (function_parameter_count; inits are exempt);
  AbsenceMessage is a Hashable struct: init(parentName:studentName:className:day:today:tutorName:centreName:) and
  .text; whatsAppURL stays static; later tasks call AbsenceMessage(...).text; cost if wrong: one call shape
- Task 5: Postgres orders an enum as declared (present before absent), so the first test's order("status") expectation
  was reversed; expectation corrected; cost if wrong: none
- Task 5: bun's toEqual takes one argument; the message became a comment (tsc refused); cost if wrong: none
- Task 6: the plan's SessionRowTests fixture was invented; replaced by the local stack's real answers (curl as meera,
  2026-10-08): marks embedded with a space after each colon, an all-students session, a single row, the bare-uuid RPC
  answer, the log insert and a log read with a null student; cost if wrong: none
- Task 6: FakeAttendanceRepository.saves is [Save] (a struct), not a 3-tuple; SwiftLint large_tuple; cost if wrong:
  one property shape
- Task 6: LogRow.log is AbsenceLog? and both reads compactMap it (the plan's own instruction under the code; its
  UUID_NULL fallback dropped); logAbsence throws cannotParseResponse if the insert answer has no student; cost if
  wrong: none
- Task 7: EventRowTests' fixture replaced by the stack's real read/update answers (curl as meera); the fake sorts as
  the read does (date, then start time with a timeless event first, nullsFirst) rather than the plan's midnight
  stand-in; cost if wrong: none
- Task 8: TaskRowTests' fixtures replaced by the stack's real read/insert/done/clear answers; IDRow internal (the
  clear's answer is tested); cost if wrong: none
- Task 8: SessionStoreTests builds Dependencies itself, so it gained the four fakes (the plan said only live and
  Fixtures call the init); cost if wrong: none
- Task 9: the new rows live in AttendanceRows.swift, ScheduleRows.swift and TaskRow.swift, not Rows.swift; Rows.swift
  would pass SwiftLint's 400-line file_length; shared DayColumn (46) and RowLines are internal helpers; cost if wrong:
  file layout only
- Task 9: InlineAdd takes showsFocus/autofocus (TextWell's pattern, so real focus shows the chips) and a DueChip
  struct instead of the plan's 3-tuple (large_tuple) and canAdd/add instead of the add tuple; cost if wrong: one call
  shape
- Task 9: TaskRow's swipe is a horizontal DragGesture across the row (≥60 pt) that completes an open task; the rows
  sit in cards in a ScrollView, where .swipeActions does not exist; the circle is the visible alternative; cost if
  wrong: swipe feel
- Task 9: the coming-up event row (P4-Today-*, P4-Schedule-Month) reads 'time · the note's first sentence' while a
  day's event row reads the full note (P4-Schedule-Day); the Domain gains that line in Task 15/18; the boards decide;
  cost if wrong: one line of copy
- Task 10: RegisterStore is in Features/Students, so AttendanceStore cannot take it without Attendance importing
  Students (rule 4). Domain gains @MainActor protocol Register (activeStudents, activeClasses, members(of:), student,
  classroom, loadIfNeeded); RegisterStore conforms in Students; AppShell will pass the shared store as any Register;
  AttendanceTests depends on Students only to build a real register; rule 4 kept, one register per centre; cost if
  wrong: one protocol
- Task 10: classOptions/banner/absentRows are structs (ClassOption, MarkBanner, AbsentRow) not 3-tuples (large_tuple);
  'All students' members sorted by StudentQuery's name sort; cost if wrong: none
- Task 10: a failed log on Tell parent says 'Couldn't open WhatsApp. Check your connection and try again.' (the
  tutor's view: the link did not open); cost if wrong: one string
- Task 11: attendance-saved and attendance-alert save on screen through the fake at a fixture clock of 18:32
  (Fixtures.clock(for:)), as P4-Attendance-Mark-Saved and P4-Absence-Alert read 'Saved at 18:32'; no markSavedForBoard
  hook; LaunchStateTests checks the clock instead of a pre-saved 7th; the board's time decides; cost if wrong: none
- Task 11: attendance-past needs its own board state (.past) opening Class 10 Maths on Mon 5 Oct (the plan's fixture
  alone opened today); Fixtures.attendance(for:) is seed for every attendance state; cost if wrong: none
- Task 11: AttendanceStore.load() runs once (opened flag) so returning to the tab keeps the toggles; AbsenceAlert
  carries its headline ('Hemanth was absent today' / 'on Fri 2 Oct'); tests added RED→GREEN; cost if wrong: none
- Task 11: SheetToasts moved from Students to DesignSystem (public) for the alert sheet; Banner gains tone (the saved
  banner is ok, P4-Attendance-Mark-Saved); EmptyState gains size .screen (padding 40×24, button 220:
  P4-Attendance-Empty); cost if wrong: none
- Task 11: RootView's attendance wiring lives in RootView+Attendance.swift (type_body_length); session, toasts, shell,
  deps, launch and register(for:) became internal for it; cost if wrong: access level only
- Task 11: a class with no members shows the Kit's EmptyRow ('No students in this class', the plan's copy); no board
  draws that state; flagged to the owner; cost if wrong: one empty row
- Task 11: the absence alert sheet sits at the board's 65% detent (and large); the class menu is the system popover
  with its arrow (Phase 3's AddMenu ruling); cost if wrong: none
- Task 12: the plan's HistoryStoreTests expected Hemanth 67% (2 of 3); P4-History-ByStudent, the student-month test
  and session 8's correction say 33% (1 of 3: absent 5th and 7th); test follows the board; cost if wrong: none
- Task 12: P4-History-Student's Earlier row reads 'September · 8 of 11 present · 3 absences'; the seed's rule gives
  Hemanth 7 of 9 present, 2 absences (9 maths days from 10 Sep); the build follows the fixture, the board's words to
  be corrected in docs (a fixture number, not layout; the prompt names this case); cost if wrong: one line on one
  board
- Task 12: the stores' tuples are structs (Summary, DateRow, StudentLine, Hero, AbsenceLine, EarlierLine) and take any
  Register; cost if wrong: none
- Task 13: AppShell makes a screen's store each time it builds the view; HistoryView, StudentMonthView and
  StudentDetailView now keep theirs in @State (the first shots showed empty screens: the loaded store was replaced by
  a fresh one); cost if wrong: none
- Task 13: StudentDetailStore takes attendance: any AttendanceRepository (required; tests pass the fake); 'no
  absences' lower case after the middle dot on the detail and the student's month (P4-StudentDetail-Attendance); cost
  if wrong: one word
- Task 13: RootView's Students actions and navigation moved to RootView+Students.swift (type_body_length); cost if
  wrong: none
- Task 13: a month with no absences shows EmptyRow 'No absences this month' (the plan's words; no board draws it);
  flagged with the other unboarded rows; cost if wrong: one row
- Task 14: P4-Schedule-Month (Wed 7 Oct) draws Coming up with Sat 10 and Sat 17, while the Today boards and
  design-tokens say seven days (Today-Soon on the same day shows Sat 10 only); the schedule's Coming up looks 14 days
  ahead (ScheduleStore.comingUpDays), Today's stays seven; both boards built as drawn; design-tokens' number to be
  corrected; owner to confirm; cost if wrong: one constant
- Task 14: the coming-up line ('11:00–12:00 · Class 10 parents': time, then the note's first sentence) is
  CalendarEvent.comingUpLine in Domain with its test, for Today and the schedule; cost if wrong: none
- Task 14: EventFormStore's times: an end chosen first takes a start an hour before; clearing the start clears the
  end; choosing a start does not invent an end (Ends is optional on the board); the plan's test, not the class form's
  rule; cost if wrong: none
- Task 14: the plan's FakeEventsRepositorySeed typo replaced by FakeEventsRepository (the brief says so);
  ScheduleTests depends on Students for a real register; cost if wrong: none
- Task 15: the event sheets are the large detent (P4-Event-New/-Edit draw them near full height), not the content's
  height the plan named; the delete confirmation is drawn over the schedule on the event's day
  (P4-Event-Delete-Confirm, information-architecture 'over the schedule'), so Delete event closes the sheet and the
  schedule asks; boards win; cost if wrong: none
- Task 15: CalendarMonth's new initialiser takes year, month and DateComponents (DesignSystem cannot see Domain's
  Day/Period) and draws without its own card so MonthHeader sits inside the schedule's; monthDays and monday are
  nonisolated (the test trapped otherwise, ios/CLAUDE.md); cost if wrong: none
- Task 15: P4-Schedule-Month/-Day dot Tue–Sat (a day off the seed's Mon–Fri classes: 3, 24, 31 dotted, Mondays bare)
  and the note counter reads '52 of 500' for a 50-character note; the build follows the rule and the real count; board
  words to correct in docs; cost if wrong: none
- Task 15: Schedule has its own EventTimeControl (the class form's TimeControl is in Students and DesignSystem cannot
  see TimeOfDay); default start 10:00, Ends 'Not set' becomes start + 1 h; cost if wrong: a duplicate to fold later
  (minor)
- Task 15: Day.fullText 'Sat 10 Oct 2026' (the event form's day tile), NotesWell gains optional:, TodayActions gains
  openSchedule (LaterTarget.schedule gone), Coming up's empty row says 'the next two weeks' (unboarded, the plan's
  pattern); cost if wrong: none
- Task 17: P4-Today-AddingTask draws the date chip as 'Fri 9 Oct' chosen on Wed 7 (the plan's chip only offered the
  next weekday, Thursday); the calendar chip shows the chosen day, else the next weekday ('Tomorrow'), and opens the
  system's date picker; No date clears; the board decides; the plan's chips test kept, aChosenDayNamesTheDateChip
  added; cost if wrong: one popover
- Task 17: the plan's addingIsOptimisticAndRollsBack expected the new task last; it is due Fri 9 Oct so it sorts
  before the undated task (TaskOrdering); the test checks the whole order; cost if wrong: none
- Task 17: TasksStore.loadIfNeeded (Today and the Tasks screen share one read); Today's Add pushes the Tasks screen
  until Task 18 makes it inline; LaterPlace.tasks removed; cost if wrong: none
- Task 18: TodayStore takes any Register (Today cannot import Students, rule 4); Register gains showsEmptyRegister for
  Start here (U2); TodayTests depends on Students for a real register; ShellStateTests builds the new store; cost if
  wrong: none
- Task 18: the tiles keep their words at the top and share the row's height (the boards draw no Spacer pinning the
  label to the bottom as the plan wrote); cost if wrong: none
- Task 18: the minute clock is a .task loop calling tick(Date()) every 60 s while Today is on screen, off when
  Dependencies.fixedClock (the fixtures); the plan's TimelineView did the same job with more machinery; cost if wrong:
  none
- Task 18: an empty Today section says P2's 'No classes yet' while the register has no classes (P2-Today-Empty,
  today-empty unchanged) and 'Nothing today' when classes exist but none meet and no event (unboarded, the plan's
  words); cost if wrong: one row
- Task 18: P4-Today-NoClass draws 'Fri 9 Oct' in text3 on Saturday 10; it is overdue and Review Focus 5 says overdue
  reads in overdue; the rule stands; board words to correct; cost if wrong: one colour
- Task 18: today-adding-task scrolls to Coming up but the content ends before Coming up reaches the top as
  P4-Today-AddingTask draws (the board's room is the keyboard's, which the board leaves out); the glass edge shows;
  cost if wrong: the photo's scroll offset
- Task 18: Fixtures.counts(for:) gives the Today states the boards' tiles (10, ₹4,000, 1 or 0); today-empty has an
  empty register, no events, no tasks; the hero spacing follows the board (12 between parts, 4 in the title block);
  cost if wrong: none
- Task 19: LaterPlace.tab(AppTab) became .feesTab (the only tab still on the way; the others' cases were dead once
  Attendance and More have roots); LaterRow added to Rows.swift; MoreView's SettingRows pass action: by name (a
  trailing closure is the trailing view); cost if wrong: none
- Task 19: P4-More's rows are 50 high (padding 14 16), SettingRow keeps components.md's 56 minimum as the built
  Settings screen does; polish row added, component unchanged; cost if wrong: 6 pt per row
- Task 20: the hand run marked Class 8 Science (the local seed is relative to the real date, Thu 8 Oct; the plan's
  table assumed Wed 7 and Class 10 Maths) and made the event 10:00–11:00 (Ends first gives Starts an hour before; the
  wheel is slow to drive); every write path in the table was still run and confirmed in psql; cost if wrong: none

## Not done, and why

- The canvas still draws the board figures listed in "As built". The owner ruled them illustrative (the boards are
  design, not data), so none is redrawn.

## Tried and dropped

- The plan's `markSavedForBoard` hook for the saved state: the board's 18:32 comes for free by saving at a fixture
  clock.
- A `TimelineView` for Today's minute clock: a `.task` loop calling `tick` does the same with less.
- A generation counter for overlapping attendance opens: the test for a link arriving mid-load passed without it.

## Final review

Fresh reviewer (Fable) on `699e76f..63c5fd8`: 1 Critical, 4 Important, 8 Minor. Re-graded and kept: the Critical
(a failed read let Save overwrite the day's marks) and the four Important (a re-save dropped departed students' marks;
the schedule's toasts never showed; Told matched by the day the parent was told, not the absence day; month loads
resolving out of order). One fix pass, each test watched fail first, in #44:

- Fixed review 5 (in AttendanceStore) and CI's flaky aLinkOpenedBeforeTheTabLoadsWins (load ran first on the slower
  runner); an open generation: the newest open lands, load stands aside if any open began;
  aLaterOpenWinsOverASlowerEarlierOne RED→GREEN (a month-delay test double), AttendanceTests 19/19 three runs
- Fixed review 1 (Critical); canSave needs the day's sessions read (error nil, loadedMonth == the draft's month);
  aFailedReadBlocksSaving RED→GREEN
- Fixed review 2; a save sends the saved marks merged under the draft's, so a student who left keeps their mark;
  aStudentWhoLeftTheClassKeepsTheirMarkOnResave RED→GREEN (RED re-checked with the fix reverted)
- Fixed review 5 (History, StudentMonth, Schedule); a load generation; aQuickSecondMonthMoveWins ×3 RED→GREEN;
  AttendanceTests 23/23, ScheduleTests 8/8
- Fixed review 4; migration 0005 message_log.about_date (additive, D26); logAbsence carries the absence day; absences
  read by about_date month (old rows by the opened day); Told matched by the absence day, its words name the day told;
  an absence log carries the day (rls) RED→GREEN, tellingAboutAPastDayShowsToldAndLogsOnce,
  aParentToldTheNextDayStillReadsAsTold RED→GREEN, aLogCarriesTheDayItIsAbout (fixtures from the stack); write and
  read proven in Swift against the local stack
- Fixed review 3; ScheduleView shows store.message as a toast with Retry (view wiring; checked in the simulator in the
  follow-up hand run)

Deferred minors (ledgered, not fixed; the owner chooses):

- AttendanceStore.open replaces unsaved toggles silently when the date or class changes
- the tasks toast is wired on Today and on the Tasks screen; one failure plays two error haptics
- an event link while the read fails says the event is no longer here
- attendance?date= accepts a future day the picker forbids
- Today's minute loop is not aligned to the minute boundary (up to 59 s late)
- a task's done_at is the device clock
- an event end of 00:xx chosen first makes an immediate end-before-start
- the task swipe has no visual feedback; confirm a diagonal scroll never completes a task

## Machine

As session 8, with the iOS Simulator tool driving the iPhone 17 (the runbook's waits held; one tap landed on a list
because the pushed screen had hidden the tab bar: look first, rule 4).

## After the record

The owner confirmed the schedule's 14-day Coming up, ruled the boards' numbers illustrative (design, not data: no
board is redrawn for a figure; `docs/design/README.md`), and tested build 7 on the iPhone: all good.

## Next

Phase 0 step 0.6 (the Phase 5 boards) on Fable.
