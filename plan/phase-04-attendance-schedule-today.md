# Phase 4: Attendance, schedule, tasks, Today live

**Status:** Done (session 9, 2026-10-08): PRs #36 to #42 and the review fixes #44; migrations 0004 and 0005 in production; build 0.1.0 (7) on TestFlight. **Depends on:** Phase 3 (done); Phase 0's Phase 4 boards (approved 2026-10-08). **Also closes:** `plan/ui-polish.md` U1 to U4 (the owner's call, 2026-10-08).

## Goal

The daily loop works: open the app, see the next class, mark who came in two taps, tell a parent about an
absence, add a task, see what is coming. Today stops being empty.

## Scope

1. **Attendance, mark.** Date (today by default, any past date), class or all students; the list starts all
   present; tap to mark absent; counts; save; a saved session reopens for correction; absence alert as a
   WhatsApp deep link per absent student from the saved session (D3), each logged.
2. **Attendance, history.** By date (sessions with counts, open one) and by student (monthly percentage,
   the list of absences); the student detail's attendance section reads from here.
3. **Schedule.** Month grid with marks on days that have classes or events; the day's classes from meeting
   days with their times; the day's events; add, edit and delete an event (title, date, start and end time,
   note).
4. **Tasks.** Inline add on Today; done with a swipe or a tap; optional due date; done tasks fall off after a
   day; a Tasks screen under More lists everything.
5. **Today live.** Greeting by time of day; stat tiles with real counts, each tappable into its list; next
   class with the time until it starts and "Mark attendance"; today's classes; upcoming events for the week;
   tasks; AI tools row.
6. **Domain rules, tested.** Next class from meeting days and the clock; occurrences of a class in a month;
   attendance percentage; "time until" wording; task ordering.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- Marking attendance for a class of ten takes two taps when everyone is present and three when one is absent.
- An absence alert opens WhatsApp with the right parent and message.
- Today shows the next class correctly across midnight and on days with no class.
- Domain tests cover every rule in item 6.

## As built

Session 9, Claude Opus 5.5, from `resume/008-phase-4-build.md`, executing `phase-04-plan.md` inline (a ledger of
rulings kept outside the repo; the rulings are in `plan/sessions/009/record.md`). Seven pull requests as planned, and an eighth for the final review's fixes:

| PR | Tasks | What |
|---|---|---|
| #36 | 1 to 4 | Domain: attendance status, session, draft and stats; the next class, "in 25 min", a class's days in a month; events and their draft; tasks and their ordering; the absence message and its `wa.me` link |
| #37 | 5 | Migration 0004 `save_attendance` with four RLS tests; deployed to production at once (run 37758056602, D26) |
| #38 | 6 to 8 | Data: attendance, message log, events and tasks repositories (PostgREST and fakes seeded by `seed.sql`'s rule), every answer decoded from the local stack's real text, every write run in Swift against it |
| #39 | 9 to 11 | The Phase 4 DesignSystem components; `AttendanceStore`; the Attendance tab to its seven boards; the Kit's one-pill rows |
| #40 | 12, 13 | History by date and by student, a student's month, the student detail's attendance section live |
| #41 | 14 to 16 | Schedule: the month, a day, events add, edit and delete; the event link; the event write path proven in Swift |
| #42 | 17 to 19 | Tasks (store, screen, inline add), Today live (U1 to U4), the More root; the hand-run fixes |
| #44 | review | The final review's Critical and four Important fixes, with migration 0005 `message_log.about_date` (deploy run 37773505389) |

**What exists.** `Domain` holds every rule of scope item 6, tested (the next class across the day and the week, the
relative words, a class's days in a month, attendance percentages and absences, task ordering and the 24-hour rule,
coming up, the absence message), plus `Register`, the protocol through which Attendance, Schedule and Today read the
one `RegisterStore` (Students) without importing it. `Data` has four repositories (attendance with its RPC, the
message log, events, tasks). `Features/Attendance` holds the mark screen with its one store per centre, the absence
alert, History and a student's month; `Features/Schedule` the month and the event form; `Features/Today` Today live,
the tasks store shared with the Tasks screen, and the inline add; the student detail reads this month's attendance.
AppShell has the More root, the routes (`history`, `historyStudent`, `schedule`, `event`, `tasks`), the links
`attendance?date=&class=` and `event/<id>`, the status-bar glass on the four tab roots (U1), and 26 Phase 4 launch
states (`today`, `today-evening`, `today-no-class`, `today-adding-task`, seven attendance, four history, five schedule,
two tasks, `more`, with `student` and `kit-surfaces` rephotographed).

**Acceptance, line by line.**
- Every screen matches its board: pictures in PRs #39 to #42, both appearances, each compared with its board before
  merging. Where a board's words or numbers could not come from the data, the build follows the data (below).
- Two taps when everyone came, three with one absent: the tab opens on today's first class with everyone present
  (or Mark attendance on Today opens it at the next class); Save sits in the footer above the tab bar and never needs
  a scroll (ten students in All students, seen in the hand run).
- An absence alert opens WhatsApp with the right parent and message: `AbsenceMessageTests`, `AttendanceStoreTests`;
  in the hand run the `wa.me` page showed Lakshmi Reddy's number and the message, and `message_log` held the row.
- Today shows the next class correctly across midnight and on a day with no class: `NextClassTests`
  (`sundayNightLooksToMonday`, the day's edges), `TodayStoreTests` (`aSaturdayWithNoClass`, the evening); the minute
  clock moved the countdown on screen in the hand run (13, 6, 3, 2 min).
- Domain tests cover every rule in item 6.
- D32: the hand run of every write path this phase adds, from a cold simulator against a fresh seed, each write
  confirmed with psql; the screenshots are on issue #43.

**Deviations and why** (rulings in the session record; one new decision, D33):
- **`Register` (D33).** The plan had Attendance, Schedule and Today take `RegisterStore`, which lives in the Students
  feature; that would make features import each other (rule 4). They take `any Register` from Domain; AppShell passes
  the one shared store.
- **Saved and the alert at 18:32.** P4-Attendance-Mark-Saved and P4-Absence-Alert read "Saved at 18:32"; those two
  launch states save on screen through the fake at a fixture clock of 18:32 rather than through a board hook.
  `attendance-past` opens Monday 5 October itself.
- **History's September.** P4-History-Student's Earlier row reads "8 of 11 present · 3 absences"; the seed's rule gives
  Hemanth 7 of 9 with 2 absences in September, which the screen shows. The plan's history test also expected
  Hemanth at 67% where the board and the fixture say 33%.
- **The schedule's Coming up looks 14 days ahead; Today's seven.** P4-Schedule-Month (Wed 7 Oct) lists Sat 10 and Sat
  17; the Today boards follow the seven-day rule. Both boards are built as drawn. Confirmed by the owner
  2026-10-08.
- **The schedule's dots** follow the meeting days (Monday to Friday in the seed); the boards dot Tuesday to Saturday.
  The event board's note counter reads 52 for a 50-character note; the screen counts 50.
- **Event sheets** open at the large detent and the delete confirmation shows over the schedule, as P4-Event-* draw
  them (the plan said the content's height and the dialog inside the sheet).
- **The task's date chip** names the chosen day and opens the date picker (P4-Today-AddingTask draws "Fri 9 Oct"
  chosen on a Wednesday; the plan offered only the next weekday). A tap turns it on with the next weekday.
- **Overdue on Today.** P4-Today-NoClass draws a task due Friday in `text3` on Saturday; it is overdue and reads in
  `overdue` (Review Focus 5).
- **Tiles** keep their words at the top and share the row's height (the plan pinned the label to the bottom; the
  boards do not). On the iPhone 17 "Classes today" fits on one line.
- **`today-adding-task`** scrolls toward Tasks, but the content ends before Coming up reaches the top as the board
  draws (the board's room is the keyboard's); the glass edge shows.
- **More's rows** keep the 56 pt minimum the Settings rows use; the board draws 50 (on the polish list).
- **Rows the boards do not draw**, built with the Kit's empty row and the plan's words: a class with no members on the
  mark screen; a month with no absences; Today with classes but nothing that day; Coming up empty on the schedule.
- **Each screen keeps its store in `@State`.** AppShell makes History's, the student month's, the schedule's and the
  student detail's store each time it builds the view; the first pictures showed empty screens until the screens held
  the first store.
- **The hand run** found four bugs, fixed in #42 with tests: the date popovers collapsed to a sliver
  (`calendarPopover`); the due chip could not pick its own suggested day; the attendance link raced the tab's first
  load; the event link pushed two schedules and kept a stale screen. The hand run marked Class 8 Science (the local
  seed is relative to the real day, a Thursday) and made the event 10:00 to 11:00.
- Smaller: SwiftLint shaped several plan interfaces (structs instead of tuples of three or more; `AbsenceMessage` a
  value with `text`; new rows in their own files; `RootView` split into extensions); `CalendarMonth` gains a
  date-components initialiser because DesignSystem cannot see `Day`; Schedule has its own time control for the same
  reason; `SheetToasts` moved to DesignSystem; `Banner` gains a tone and `EmptyState` a screen size; `LaterPlace`
  keeps only Fees and the two Students places.

**The final review** (a fresh reviewer on the whole range) found one Critical and four Important, all fixed in #44
with tests that failed first and re-checked in a follow-up hand run: a failed month read left Save enabled on an
"everyone present" draft (Save now needs the day read); a re-save dropped the marks of students who had left the class
(the saved marks are sent under the draft's); "Told" was matched by the day the link was opened, so telling a parent
the next morning failed and logged twice (migration 0005 carries the absence day); the schedule's failure messages were
never shown (now a toast with Retry); quick month moves could resolve out of order (a load generation). Eight minors
are deferred in the session record.

**Production.** Migrations 0004 and 0005 by `deploy.yml` (runs 37758056602 and 37773505389, nothing pending after);
build 0.1.0 (7) by `testflight.yml` (run 37773860384).

**What remains.** The owner's confirmation of the schedule's two-week Coming up; the board corrections listed above
(the canvas still draws the slips); the polish items found (U5 onwards); class and event reminders (Phase 7); the
attendance export (Phase 5); the AI tools row on Today (Phase 6's board).
