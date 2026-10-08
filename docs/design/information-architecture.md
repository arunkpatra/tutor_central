# Information architecture

What lives where, how the tutor moves between places, and which launch states exist for screenshots. The
spec (`docs/spec.md` section 2) is the source; this is the map a builder works from.

## Entry

```
Launch
 ├─ no session ──────────────► Sign in (landing)
 │                                ├─ Continue with Apple ── native sheet ─┐
 │                                ├─ Continue with Google ─ web session ──┼─► session
 │                                └─ Continue with email ─ request code ─ enter code ─┘
 ├─ session, no centre ──────► Onboarding (name, centre, WhatsApp) ─► Tabs
 └─ session, centre ─────────► Tabs
```

The session gate lives in `AppShell` and is the only thing that decides which of the three roots shows.

## Tabs

| Tab | Root | Pushed screens | Sheets |
|---|---|---|---|
| Today | Today | Schedule, Attendance mark (via Mark attendance), class (via a row), student (via a fee row) | A task is added inline, not on a sheet |
| Students | Students list | Student detail, Class detail, Classes list | New student, Edit student, New class, Edit class, Scan register, archive and delete confirmations |
| Fees | Fees (month) | Student detail | Generate month, Mark paid, Waive, UPI settings |
| Attendance | Attendance (Mark) | History (by date, by student, one student's month); a saved class reopens on the Mark root by date and class | Absence alert |
| More | More | Schedule, Tasks, Classes, Settings now; Reports, AI Assistant, Check a paper, Scan register, Account, Help named with their phase until it ships | New event, Edit event (with Delete event), Generation forms |

Each tab keeps its own navigation stack. Tapping the active tab pops to its root. A student detail reached
from Today or Fees is pushed on that tab's stack, not a jump to the Students tab.

## Deep links (`tutorcentral://`)

| Link | Opens |
|---|---|
| `today` | The Today tab root |
| `student/<id>` | Student detail on the Students tab |
| `fees?month=YYYY-MM` | The Fees tab at that month |
| `attendance?date=YYYY-MM-DD&class=<id>` | Attendance mark for that day and class |
| `event/<id>` | The event in Schedule on the More tab |

Notifications (Phase 7) carry these links.

## Launch states (`bun shots <state>`)

The screenshot tool launches the app at a named state with a fake session and fixed data, so a board and
its built screen can be compared. Phase 2's states:

| State | Shows |
|---|---|
| `signin` | Sign in landing |
| `signin-email` | Email sheet, request a code |
| `signin-code` | Code entry |
| `signin-code-wrong` | Code entry with the error |
| `signin-password` | Password entry (the sheet after "Use my password instead") |
| `onboarding` | Onboarding, fields prefilled |
| `today-empty` | Tabs, Today with every section empty |
| `later-fees` | The Fees tab's placeholder (and `later-students`, `later-attendance`, `later-more`) |
| `settings` | Settings minimal |
| `kit` | The Kit (debug builds), at buttons |
| `kit-fields` | The Kit at fields, chips, progress and calendar |
| `kit-surfaces` | The Kit at navigation and rows |
| `kit-patterns` | The Kit at the hero card, empty, loading, stale, error, toast, offline |
| `kit-dialog` | The Kit at the dialog |

Phase 3's states (`plan/phase-03-plan.md` builds them; the light twins come from `--appearance light`):

| State | Shows |
|---|---|
| `students-empty` | Students, nothing yet, both empty cards |
| `students-few` | Students, the first three, no classes yet |
| `students` | Students, the seed's ten with filters, the Classes row and the sort menu |
| `students-searching` | Students, searching "sh", three matches |
| `students-filtered` | Students filtered to Class 8 Science |
| `students-add-menu` | Students with the "+" menu open |
| `student-new` | New student, empty, Save disabled |
| `student-new-filled` | New student, Riya Sharma filled in, Save enabled |
| `student-new-invalid` | New student with a nine-digit number and its error |
| `student-edit` | Edit student, Akshita Rao, nothing changed, Save disabled |
| `student` | Student detail, Akshita Rao |
| `student-archived` | Student detail, archived, with Restore |
| `student-archive-confirm` | The archive confirmation over the detail |
| `student-delete-confirm` | The typed delete confirmation over the detail |
| `classes-empty` | Classes, nothing yet |
| `classes` | Classes, the seed's two and the "Not in a class" row |
| `class-new` | New class, Class 12 Physics filled in |
| `class-edit` | Edit class, Class 10 Maths, nothing changed, with Archive class (over the Classes list, as the board draws it) |
| `class-archive-confirm` | The class archive confirmation over Edit class: the dialog pattern with the class's words |
| `class` | Class detail, Class 10 Maths: this week and six students |
| `class-add-members` | Class detail with the add-students sheet |

Later phases add theirs in their plan files.

Phase 4's states (`plan/phase-04-plan.md` builds them; light twins from `--appearance light`; the clock is given per
state):

| State | Shows |
|---|---|
| `today` | Today live, Wed 7 Oct 16:35: the next class in 25 min with Mark attendance, today's class, coming up, tasks (replaces `today-empty`'s content; `today-empty` stays for a centre with nothing yet) |
| `today-evening` | Today live at 19:30: tomorrow's class in the hero, today's class marked |
| `today-no-class` | Today live on Saturday 10 October 09:30: no classes, the next class on Monday, the day's event |
| `today-adding-task` | Today scrolled to Tasks, the add field focused with a due date chosen; the status bar on the glass edge (U1) |
| `attendance` | Attendance, Class 10 Maths today, everyone present, Save attendance |
| `attendance-class-menu` | The class menu open (All students, each class, with counts) |
| `attendance-exceptions` | One student marked absent |
| `attendance-saved` | Just saved: the banner, the absent student with Tell parent, the footer reads Saved |
| `attendance-alert` | The absence alert sheet over the saved screen: the message and Open WhatsApp |
| `attendance-past` | Mon 5 Oct reopened: the marked banner, the absent student already told, Save changes disabled |
| `attendance-empty` | Attendance with no students yet |
| `history` | History by date, October 2026: the month's summary and its classes |
| `history-by-student` | History by student, October 2026: each student's percentage bar |
| `history-student` | Hemanth Reddy's October: the percentage hero, the absence, earlier months |
| `history-empty` | History with nothing marked yet |
| `student` | The student detail now shows this month's attendance live (P4-StudentDetail-Attendance supersedes the P3 boards' later section; the rest unchanged) |
| `more` | The More root |
| `schedule` | Schedule, October 2026 with today chosen: today's class and the coming events |
| `schedule-day` | Schedule with Saturday 10 October chosen: its event, no class |
| `event-new` | New event, filled in, over the schedule |
| `event-edit` | Edit event, nothing changed, with Delete event |
| `event-delete-confirm` | The delete confirmation over the schedule |
| `tasks` | Tasks under More: to do and done |
| `tasks-empty` | Tasks with nothing on the list |

## Phase 2 boards (step 0.3)

| Board | Canvas | Source |
|---|---|---|
| Sign in, dark | row 1, board 3 (`A-SignIn`) | `directions/A-SignIn.dc.html` |
| Sign in, light | row 5 | `mockups/P2-SignIn-Light.dc.html` |
| Email, request a code | row 5 | `mockups/P2-Email-Request.dc.html` |
| Email, enter the code, with the wrong-code state | row 5 | `mockups/P2-Email-Code.dc.html` |
| Email, sign in with a password, with the wrong-password state | row 5 | `mockups/P2-Email-Password.dc.html` |
| Onboarding, dark and light | row 5 | `mockups/P2-Onboarding-*.dc.html` |
| Today empty, dark and light | row 5 | `mockups/P2-Today-Empty-*.dc.html` |
| Settings minimal | row 5 | `mockups/P2-Settings.dc.html` |
| A tab that comes later | row 5 | `mockups/P2-Later.dc.html` |
| The Kit | row 4 | `mockups/Kit-*.dc.html` |
| The app icon (C3 approved: Ember glow, Lucide's open book in marigold; source `mockups/AppIcon.svg`) | row 5 | `mockups/P2-AppIcon.dc.html` |

Sign in with Apple and Google show the system's own sheets; they are not drawn.

## Phase 3 boards (step 0.4, approved 2026-10-08)

Row 6 of the canvas; sources `mockups/P3-*.dc.html`. Dark for every state; light for the Students list and the
student detail. Content is the seed's (`supabase/seed.sql`) on Wednesday 7 October 2026 at 18:30.

| Board | Source |
|---|---|
| Students: empty, the first three, the whole register (dark and light), searching, filtered, the "+" menu | `P3-Students-Empty`, `-Few`, `-Many`, `-Many-Light`, `-Searching`, `-Filtered`, `-AddMenu` |
| New student: empty, filled, a number that is not complete; edit student | `P3-NewStudent-Empty`, `-Filled`, `-Invalid`, `P3-EditStudent` |
| Student detail (dark and light), archived with Restore; the archive and the typed delete confirmations | `P3-StudentDetail`, `-Light`, `-Archived`, `P3-Archive-Confirm`, `P3-Delete-Confirm` |
| Classes: empty, list; new class; edit class with Archive class; class detail; add students | `P3-Classes-Empty`, `P3-Classes-List`, `P3-NewClass`, `P3-EditClass`, `P3-ClassDetail`, `P3-ClassDetail-AddMembers` |

What the boards settle for the Students tab:

- The Students root: large title with the "+" icon button, the search field, the filter chips (shown once a class
  or an archived student exists), one compact Classes row that opens the Classes list, then the count line with
  the sort menu (Name, Fee) and the list card. Pushed screens on this tab (student detail, classes, class detail)
  hide the tab bar; the roots keep it.
- The "+" menu: Add a student (sheet), Scan paper register (Phase 6; until then the later board, as the inventory
  says), Create a class (sheet). In the app it is a popover holding the board's three rows on the system's own glass
  (so its state can be photographed); the system does not dim the screen behind it as the board does.
- Forms are floating sheets (D28): the student form at the large detent, the class form at its content height.
  Save is disabled until the form is valid and, when editing, until something changed. Cancel asks before
  discarding typed changes (components.md, Sheets).
- A student's fee left empty means the class fee; the helper line says so. A student is archived from the
  detail (primary confirmation, reversible, restored from the same screen or the Archived filter) and deleted
  with the typed confirmation. A class is archived from the bottom of its edit sheet; its students stay, with no
  class.
- Class detail: the week's meetings from the meeting days (today's row marked), the members with "Add" (a
  checklist sheet of students not in the class; a student moved keeps a fee of their own), removal through the row's
  context menu ("Remove from class", not drawn: the system draws it) or the student's own Edit; the members are a
  card, not a list, so there is no swipe action.
  "Mark attendance" and the detail's Fees "See all" open the later board until Phases 4 and 5.
- Searching matches names and phone numbers across every class and the archive; the matched letters are in
  `accentText`; the matching phone takes the row's second line.

## Phase 4 boards (step 0.5, approved 2026-10-08)

Row 7 of the canvas; sources `mockups/P4-*.dc.html`. Dark for every state; light for Today live, the attendance
mark and More. Content is the seed's on Wednesday 7 October 2026, at the clock each board names; attendance follows
`seed.sql`'s rule (every fifth mark absent, ordered by date and name) over the four weeks before, plus the session
saved on the day; two events (Parents' meeting Sat 10 Oct 11:00–12:00; Mock test, Class 10, Sat 17 Oct 10:00–12:00)
and two done tasks join the seed's two open ones.

| Board | Source |
|---|---|
| Today live: a class soon (dark and light), the evening, a day with no class, adding a task (scrolled, U1) | `P4-Today-Soon`, `-Soon-Light`, `-Evening`, `-NoClass`, `-AddingTask` |
| Attendance: mark fresh (dark and light), the class menu, one absent, saved, the absence alert, a past date, no students | `P4-Attendance-Mark-Fresh`, `-Fresh-Light`, `P4-Attendance-ClassMenu`, `P4-Attendance-Mark-Exceptions`, `-Saved`, `P4-Absence-Alert`, `P4-Attendance-Mark-PastDate`, `P4-Attendance-Empty` |
| History: by date, by student, one student, empty; the student detail's attendance section live | `P4-History-ByDate`, `-ByStudent`, `-Student`, `-Empty`, `P4-StudentDetail-Attendance` |
| More (dark and light) | `P4-More`, `P4-More-Light` |
| Schedule: the month, a chosen day; new event, edit event, delete confirmation | `P4-Schedule-Month`, `P4-Schedule-Day`, `P4-Event-New`, `P4-Event-Edit`, `P4-Event-Delete-Confirm` |
| Tasks: the list, empty | `P4-Tasks`, `P4-Tasks-Empty` |
| The Kit's attendance rows redrawn (dark and light) | `Kit-Surfaces-Dark`, `Kit-Surfaces-Light` |

What the boards settle:

- **Today live** replaces Phase 2's fixed content (U2, U3). The hero card is the next class with the time until it
  starts and Mark attendance (accent eyebrow) while one is within 90 min or running; after the last class it names
  tomorrow's first (plain eyebrow, no button); on a day with no class it names the next class day. "Today" lists
  the day's classes, each marked with a tick and "5 of 6 present" in `ok` once attendance is saved, and the day's
  events; "Coming up" lists the events of the next seven days; "Tasks" lists open tasks and tasks done within a day,
  with Add opening the inline field in the card (a due-date chip: the next weekday, or No date; Add commits; Cancel
  in the header closes it). The AI tools row waits for Phase 6's board, as Phase 2 ruled. Scrolled, a tab root's
  status bar sits on the system's glass edge (`chrome`, `blurChrome`, `lineGlass`), never on bare content (U1); the
  header at rest is unchanged.
- **Attendance mark** is the tab's root: the date (Today, or any past day through the system date picker) and the
  class (a popover menu: All students, each active class, with counts) in one card; everyone starts present; the
  whole row toggles and its pill says Present or Absent; the counts sit beside the section title; Save attendance is
  a primary button in a footer above the tab bar, so saving never needs a scroll. Saved, the footer reads Saved in
  `okTint`, a banner says when, and an "N absent" card lists each absent student with Tell parent; a changed mark
  turns the footer back into Save changes. A past day that was marked reopens the same screen with its marks, a
  banner ("Marked on Mon 5 Oct at 18:04. Saving again replaces it.") and Told under a parent already told. With no
  students the root is one empty card with Go to Students. Mark attendance on Today, on a class detail and the
  `attendance?date=&class=` link all open this root with the date and class set.
- **The absence alert** is a floating sheet (D28): the student and parent, the message in a well, Open WhatsApp.
  The message: "Hello <parent first name>, <child first name> was absent from <class> today, <weekday d month>.
  Please let me know if everything is all right." then the tutor's name and the centre. Opening it logs an
  `absence` row in `message_log` (D3); the saved screen and the student's month then show "Told <day>".
- **History** is pushed from the root's quiet History action: a segmented By date | By student, a month header with
  chevrons, and for the month either the summary card and the classes marked (each opening its reopened session)
  or every student with a percentage bar and "9 of 12" (Lowest first sorts by percentage). A student's month shows
  the percentage hero, the absences (each with Tell parent or Told), and earlier months. The student detail's
  Attendance section reads the same numbers, with See all into the student's month.
- **More** is a tab root with three list cards: Organise (Schedule, Tasks, Classes; Reports at the Later opacity
  with "Phase 5"), Create (the three AI tools, "Phase 6"), App (Settings; Account and Help, "Phase 7"). A later row
  is not tappable.
- **Schedule** is pushed from More and from Today's Schedule action: a calendar card (month header with chevrons
  inside the card, today on the accent disc, the chosen day on a `surface2` disc, a dot under days with a class or
  an event), then the chosen day's classes (time column, name, "5 of 6 present" and a tick once marked, else the
  meeting summary) and events (start time over end time, title, note), then Coming up when today is chosen. A day
  without classes says so in a footnote. The "+" icon button and the day's Add event open New event.
- **Events** are floating sheets (D28): Title (required, 120), Day (the system date picker from a tile), Starts and
  Ends (optional, end after start), Note (optional, 500 characters with the counter). Save is disabled until valid
  and, when editing, until something changed; Delete event at the bottom of Edit event asks with the dialog pattern
  (solid destructive Delete; nothing to type, an event has no history). `event/<id>` opens Edit event over the
  schedule on the More tab.
- **Tasks** under More lists everything: the add field at the top, "N to do" (open, by due date then creation),
  "Done" with the tick, the title struck through and the done day; Clear removes the done ones. Swipe completes a
  row; so does the circle. A task falls off Today one day after it is done but stays here until cleared.
