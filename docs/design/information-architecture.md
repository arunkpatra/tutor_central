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
| Students | Students list | Student detail, a student's fees, Class detail, Classes list | New student, Edit student, New class, Edit class, Scan register, archive and delete confirmations |
| Fees | Fees (month) | Parent payments (via Payments), Student detail (via a row) | Generate month, Mark paid, Waive, Remind, Receipt |
| Attendance (V1; under More from Phase 11, D65) | Attendance (Mark) | History (by date, by student, one student's month); a saved class reopens on the Mark root by date and class | Absence alert |
| More | More | Schedule, Tasks, Classes, Settings, Reports, AI Assistant (its four forms, a result, History), Check a paper (pages, the scheme, the marks), Scan register (the list to check); Account (its password sheet, sign out, Delete account), Help; Settings pushes Parent payments, Teacher reminders, Account, Help and Pending changes (also reached from the failed-send banner on any tab root). From Phase 11 (P10-More): Organise holds Schedule, Attendance (the Mark root pushed, with History), Tasks, Batches (V1's Classes list), Reports; Make holds Make something (AI Assistant's successor, Phase 15), Check a paper, Scan register; App holds Settings, Account, Help | New event, Edit event (with Delete event), Share as CSV, the student picker, the consent, Send the note, Fix this row, the camera |
| School (V2, from Phase 11; its content Phase 13) | School: items by date, or the empty card | An item, the exam calendar, exam preparation (Phase 10 boards, step 10.5) | Items for confirmation, Ask parents to forward, the "+" menu |

Each tab keeps its own navigation stack. Tapping the active tab pops to its root. A student detail reached
from Today or Fees is pushed on that tab's stack, not a jump to the Students tab.

## Deep links (`tutorcentral://`)

| Link | Opens |
|---|---|
| `today` | The Today tab root |
| `student/<id>` | Student detail on the Students tab |
| `fees?month=YYYY-MM` | The Fees tab at that month |
| `attendance?date=YYYY-MM-DD&class=<id>` | Attendance mark for that day and class (from Phase 11, pushed on the More tab) |
| `school/<item>` | A school item on the School tab (V2, Phase 13) |
| `event/<id>` | The event in Schedule on the More tab |

Notifications (Phase 7) carry these links: a class reminder opens `attendance?date=&class=`, an event reminder `event/<id>`, the
unpaid-fee reminder `fees?month=`.


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

Phase 5's states (`plan/phase-05-plan.md` builds them; light twins from `--appearance light`; the clock is Wednesday 7
October 2026 at 18:30; the fees are the seed's October, six paid on 4 October by UPI, plus what each state names):

| State | Shows |
|---|---|
| `fees-empty` | Fees, a fresh centre: October with no fees generated and no UPI id (the Add card, the empty card with Generate October's fees) |
| `fees` | Fees, October, All: the hero, the overdue banner (Nikhil's September fee still due), due rows then paid, Dev reminded on 6 Oct |
| `fees-due` | Fees, Due: the four due rows with Remind and Mark paid |
| `fees-paid` | Fees, Paid: the six paid rows |
| `fees-overdue` | Fees, September 2026: Nikhil's fee overdue and reminded, nine paid on 3 Sep |
| `fees-payee` | Fees, All, with the payee card (the UPI id not yet confirmed) |
| `fees-generate` | The Generate sheet over `fees-empty`: 10 fees, by class, ₹11,300 |
| `fees-generate-nothing` | The Generate sheet over `fees`: everyone has a fee, Nothing to create |
| `fees-mark-paid` | The Mark paid sheet for Dev Kumar over `fees-due` |
| `fees-marked-paid` | Fees, All, after Dev was marked paid: the hero rolled, his row paid today, the toast with Undo |
| `fees-receipt` | The receipt sheet for Dev over `fees-marked-paid` |
| `fees-remind` | The reminder sheet for Hemanth over `fees-due` |
| `fees-waive` | The Waive sheet for Sahil, the reason typed, over `fees-due` |
| `payments-empty` | Parent payments, nothing set, the UPI id field focused |
| `payments` | Parent payments, the UPI id set and saved |
| `payments-qr` | Parent payments, a QR kept and the id read from it |
| `student-fees-due` | Student detail, Hemanth Reddy: the fees section live with Remind and Mark paid (P5-StudentDetail-Fees; `student` keeps Akshita, paid) |
| `student-fees` | Hemanth's fees: October due and reminded, September and August paid, July waived |
| `reports` | Reports, October, Fees |
| `reports-attendance` | Reports, October, Attendance |
| `reports-export` | The Share as CSV sheet over `reports`, Fees chosen |
| `reports-empty` | Reports, November 2026, nothing yet |
| `more` | The More root with Reports live (P5-More supersedes P4-More) |
| `settings` | Settings with the Parent payments row live (P5-Settings supersedes P2-Settings' later card) |

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
  in the header closes it). The AI tools row is Phase 6's "Create with AI" row at the end of Today (P6-Today-AITools). Scrolled, a tab root's
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

What the build corrected (session 9; the screens follow the data or the rule; the boards' figures are illustrative, so
the canvas is not redrawn, the owner, 2026-10-08):

- **P4-History-Student**, Earlier: the seed's rule gives Hemanth "September · 7 of 9 present · 2 absences", not 8 of 11
  with 3 absences.
- **P4-Schedule-Month and -Day**: the dots follow the classes' meeting days (Monday to Friday in the seed); the boards
  dot Tuesday to Saturday.
- **P4-Schedule-Month**: Coming up on the schedule looks two weeks ahead (it lists Sat 10 and Sat 17 on Wed 7); Today's
  Coming up stays the next seven days. Confirmed by the owner 2026-10-08; `design-tokens.md` says so.
- **P4-Event-New and -Edit**: the note "Class 10 parents. Bring the September test papers." counts 50 of 500, not 52.
- **P4-Today-NoClass**: a task due Friday reads in `overdue` on Saturday (an overdue task always does); the board draws it
  in `text3`.
- **P4-Today-AddingTask**: the date chip names the chosen day ("Fri 9 Oct") and opens the system's date picker; a tap
  turns it on with the next weekday ("Tomorrow"); No date clears it.
- **The tutorcentral://event/<id> link** opens one screen, the schedule with the event's Edit sheet, on the More tab
  (not the schedule pushed twice); a link to a gone event says "That event is no longer here."
- **"Told"** is matched by the day of the absence (`message_log.about_date`, migration 0005), and its words name the day
  the parent was told: a parent told on Thursday about Wednesday reads "Parent told on Thu 8 Oct" on Wednesday's row.

## Phase 5 boards (step 0.6, approved 2026-10-08)

Row 8 of the canvas; sources `mockups/P5-*.dc.html`. Dark for every state; light for Fees and Reports. Content is the
seed's October 2026 on Wednesday 7 October at 18:30 (six fees paid on 4 October by UPI, ₹4,000 due from four parents,
₹7,300 collected), plus Nikhil's September fee still due and Hemanth's earlier months for the states that need a past.

| Board | Source |
|---|---|
| Fees: before generation, the month (dark and light), due, paid, a past month with an overdue fee, the payee confirmation | `P5-Fees-Empty`, `P5-Fees-All`, `-All-Light`, `P5-Fees-Due`, `P5-Fees-Paid`, `P5-Fees-Overdue`, `P5-Fees-Payee` |
| Generate: what will be created; nothing to create | `P5-Generate`, `P5-Generate-Nothing` |
| Mark paid; after mark paid with the undo toast; the receipt; the reminder; waive | `P5-MarkPaid`, `P5-Fees-MarkedPaid`, `P5-Receipt`, `P5-Remind`, `P5-Waive` |
| Parent payments: empty, filled, a QR added | `P5-Payments-Empty`, `P5-Payments-Filled`, `P5-Payments-QR` |
| Student detail with the fees section live; a student's fees | `P5-StudentDetail-Fees`, `P5-StudentFees` |
| Reports: fees (dark and light), attendance, share as CSV, a month with nothing | `P5-Reports-Fees`, `-Fees-Light`, `P5-Reports-Attendance`, `P5-Reports-Export`, `P5-Reports-Empty` |
| More with Reports live (dark and light); Settings with Parent payments live | `P5-More`, `P5-More-Light`, `P5-Settings` |

What the boards settle (the parts are in `components.md`, "Phase 5 parts"):

- **Fees** is the tab's root: the large title with a quiet Payments action (opens Parent payments), the month header
  with chevrons (the current month first; any month can be opened), the money pair, the payee card until the UPI id is
  confirmed once, the overdue banner when an earlier month still has a due fee, All | Due | Paid, and the ledger card
  with Generate as its section action. The fee row is not a link, its name included (as the boards draw it); Remind
  and Mark paid are its buttons; the student detail is reached through the Students tab.
- **Overdue** is a fee of a month before the current one that is still due. Its own month's view marks it Overdue; the
  current month's view shows the banner and moves to that month on tap. The Due filter shows the shown month's fees
  only. Outstanding on the hero is the shown month's.
- **Generate** opens from the empty card's primary button and from the ledger's Generate action: a sheet that counts
  what `generate_fees` will make (active students without a fee for the month, by class, from the class fee or the
  student's own) and says so before it runs; the second time it says everyone has one and the button is disabled. The
  count is made on the device from the register and the month's fees.
- **Mark paid** is a sheet with the method (UPI, Cash, Other), the day (today, or any earlier day through the system
  date picker in a popover) and "Waive this fee instead". The write goes to the server at once; the row moves, the
  hero rolls and a toast offers Undo for 8 s, which writes the reverse. When receipts are on, the receipt sheet opens
  after the toast appears; Cancel skips it.
- **Remind and Receipt** are the Phase 4 message sheet with the texts in `components.md`. Open WhatsApp logs a
  `message_log` row (`reminder` or `receipt`, pointing at the invoice) before the link opens; the fee row then reads
  "Reminded Tue 6 Oct". The reminder text is copied to the clipboard as well, for a phone without WhatsApp.
- **Waive** asks for a reason (200 characters) and sets the fee waived; a waived fee counts as settled, not collected,
  and can still be marked paid later from the student's fees.
- **Parent payments** is one pushed screen, from Settings' row and from Fees' Payments: the UPI id (saved as you go,
  with the Saved mark; editing it clears the confirmation), Scan a QR (the camera) and From Photos (the photo picker),
  both decoded on the device (`upi://pay?pa=…`; the camera, in a sheet a swipe closes, is asked for the first time) to fill the id and keep the QR image on this iPhone (shown as a
  thumbnail with Remove; not synced), the optional payment link, the receipts switch (`send_receipts`).
- **The student detail's Fees section** reads this month's fee with Remind and Mark paid when due; See all pushes the
  student's fees: the money pair over the months with a fee and one row per month; a waived month there offers Mark paid
  alone (D34). Today's Due tile opens Fees at this month's Due.
- **Reports** is pushed from More: the month header, Fees | Attendance, the hero and per-student rows; Share opens the
  CSV sheet that names the file and its columns, then the system share sheet. The fees CSV: student, class, amount,
  status, paid on, paid by, reminded on. The attendance CSV: student, class, present, absent, percentage.
- **More** gains Reports as a live row; **Settings** gains Parent payments in place of its "Phase 5" later row.
- `tutorcentral://fees?month=YYYY-MM` opens the Fees tab at that month.

Phase 6's states (`plan/phase-06-plan.md` builds them; light twins from `--appearance light`; the clock is Wednesday 7
October 2026 at 18:32; the fixtures hold six results in History and, for the scan states, the eight rows the board
draws). The three system surfaces (the camera permission alert, the document camera, the photo picker) are the system's:
they have boards but no launch state, and are proven on the owner's iPhone.

| State | Shows |
|---|---|
| `ai-assistant` | AI Assistant: the four tools and three recent results (P6-Assistant; light twin) |
| `ai-assistant-empty` | AI Assistant with nothing created yet |
| `ai-paper` | The question paper form, Class 10 Maths, topic focused (P6-Form-Paper) |
| `ai-homework` | The homework form, Class 8 Science |
| `ai-worksheet` | The worksheet form with the answer-key switch |
| `ai-note` | The progress note form, Hemanth Reddy chosen, observations typed |
| `ai-note-student` | The student picker sheet over the note form |
| `ai-generating` | The paper form held at 0.45, the creating card, the button loading |
| `ai-generate-failed` | The paper form with the error row and Retry |
| `ai-result-paper` | The paper result: hero, sections, questions, the footer (light twin) |
| `ai-result-regenerating` | The result at 0.55 while a new paper is on its way |
| `ai-result-note` | The progress note result, editable, Send on WhatsApp |
| `ai-note-send` | The Send the note sheet over the note result |
| `ai-history` | History: October and September |
| `ai-history-empty` | History with nothing created yet |
| `scan-intro` | Scan register: the intro with the notices |
| `scan-consent` | The consent sheet over the intro |
| `scan-camera-refused` | The intro with the refused-camera toast and Open Settings |
| `scan-reading` | Reading the photo (the fixture's drawn page) |
| `scan-review` | The list to check: 8 found, Dev Kumar already here and unticked, Kavya Nair without a number |
| `scan-review-edit` | Fix this row (Kavya Nair) over the list |
| `scan-review-removed` | 7 found after Kavya Nair was removed, the toast with Undo |
| `scan-review-leave` | The Leave without adding? confirmation |
| `scan-nothing` | No names found |
| `scan-failed` | The call failed: the error row with Retry, Take another photo |
| `scan-saved` | The Students list with the seven added and the toast with Undo |
| `check-intro` | Check a paper: the intro, Hemanth Reddy chosen |
| `check-pages` | Two pages and the Add a page tile |
| `check-scheme` | The marking scheme from a created paper, Quadratic equations chosen |
| `check-scheme-typed` | The marking scheme typed |
| `check-checking` | Checking 2 pages |
| `check-result` | The suggested marks, 14 of 20 |
| `check-mark-picker` | The popover of marks for question 4 |
| `check-result-edited` | Question 6 changed to 2 of 2, the total 15 |
| `check-saved` | Saved to Hemanth's notes, the Saved footer and the toast with Undo |
| `check-failed` | The check failed: the error row with Retry, Back to the pages |
| `today-ai` | Today scrolled to the end: Coming up, Tasks and the Create with AI row (P6-Today-AITools) |
| `more` | The More root with the three AI rows live (P6-More supersedes P5-More; light twin) |

## Phase 6 boards (step 0.7, approved 2026-10-08)

Row 9 of the canvas; sources `mockups/P6-*.dc.html`. Dark for every state; light for the AI Assistant home, the paper
result and More. Content is the seed's (Class 10 Maths, Class 8 Science, Hemanth Reddy and Lakshmi Reddy) on
Wednesday 7 October 2026; the paper, the note, the eight names read from the register and the marks are illustrative
(the owner's rule: the screens follow the data).

| Board | Source |
|---|---|
| AI Assistant: the home (dark and light), nothing created yet | `P6-Assistant`, `-Light`, `-Empty` |
| The four forms; the student picker; creating; the failure | `P6-Form-Paper`, `-Homework`, `-Worksheet`, `-ProgressNote`, `P6-ProgressNote-StudentPicker`, `P6-Generating`, `P6-Generate-Failed` |
| Results: the paper (dark and light), creating again, the note, Send the note | `P6-Result-Paper`, `-Light`, `P6-Result-Regenerating`, `P6-Result-ProgressNote`, `P6-ProgressNote-Send` |
| History, empty | `P6-History`, `P6-History-Empty` |
| Scan register: intro, consent, the camera ask, refused, the camera, Photos, reading, the list, fixing a row, a row removed, leaving, nothing found, failed, added | `P6-Scan-Intro`, `-Consent`, `-CameraAsk`, `-CameraRefused`, `-Camera`, `-Photos`, `-Reading`, `-Review`, `-Review-Edit`, `-Review-RowRemoved`, `-Review-Leave`, `-Nothing`, `-Failed`, `-Saved` |
| Check a paper: intro, pages, the scheme (from a paper, typed), checking, the marks, changing one, edited, saved, failed | `P6-Check-Intro`, `-Pages`, `-Scheme`, `-Scheme-Typed`, `-Checking`, `-Result`, `-MarkPicker`, `-Result-Edited`, `-Saved`, `-Failed` |
| More with the three rows live (dark and light); Today's Create row | `P6-More`, `P6-More-Light`, `P6-Today-AITools` |

What the boards settle (the parts are in `components.md`, "Phase 6 parts"):

- **AI Assistant** is pushed from More's row and from the "Create with AI" row at the end of Today (on the Today tab's
  stack). Its nav row carries History; the home lists the four tools and the three most recent results (See all opens
  History), under the "AI can make mistakes" line.
- **The forms** are pushed one-task screens, the primary in a footer that never needs a scroll. Paper: class (a tile
  picker over the centre's active classes), subject (prefilled from the class, editable), topic (required), level (Easy,
  Medium, Hard), questions, marks. Homework: class, subject, topic, level, questions. Worksheet: the paper's fields but
  marks, plus "Answer key at the end". Progress note: the student (a floating sheet with search, one choice), a banner
  with the month's attendance and fee state (sent with the note), observations (2000), tone (Warm, Plain). Create is
  disabled until the topic (or the observations) is typed.
- **Creating** holds the form at the disabled opacity under a card that names what is being written, with Cancel and
  "you can wait here or come back from History": the call runs in the centre's AI store, not the screen, so leaving
  does not lose it. The result is pushed when it arrives. A failure replaces the card with the error row (Retry) and
  the footer is live again; the limit failure says how many are left tomorrow.
- **A result** is pushed with the hero (class and subject, the title, the counts and when it was created), the
  formatted text in a card (sections, numbered questions with marks on the right, the answer key last), and a footer:
  the AI line, "Create again" (quiet), Copy and Share as PDF. Create again keeps the old result at 0.55 with a spinner
  by the section title until the new one lands; the buttons are disabled meanwhile. Every result is in History.
- **A progress note's result** shows the student and parent, the note in an editable well, and a footer with Copy,
  Write again and Send on WhatsApp, which opens the Phase 4 message sheet (the note plus the signature) and logs a
  `progress` row in `message_log` with the student when Open WhatsApp is tapped. The text is copied too.
- **History** lists every generation (paper, homework, worksheet, note) by month, newest first; a row reopens its
  result. Scans and checked papers are recorded in `ai_generations` but not listed: what they produced is on the
  register and the student's page.
- **Scan register** is pushed from More's row, the Students "+" menu and the empty register's button. The intro names
  what happens (the photo goes to the AI service to be read and is not kept; nothing is saved before Add). The first
  photo asks the consent sheet once per centre (`ai_consent_at`), then the camera: the system's alert the first time
  (`AVCaptureDevice.requestAccess`), a refused camera says where to allow it with Open Settings, the camera is the
  system's document camera (VisionKit, one page, Cancel is the way out), Photos is the other way in. Reading shows the
  photo and a skeleton with Cancel. The list to check: "Add to" (a class or No class), N found, one row per name read
  with a checkbox (ticked unless it matches a student already in the register, then "Already here" and the match), the
  number and fee read ("No number read" in `due` when none), a chevron to Fix this row (the student form with "Remove
  this row"); a removed row offers Undo; Back asks "Leave without adding?"; Add N students creates the ticked rows in
  one write and pops to the Students list with a toast and Undo (which deletes those rows; a failed Undo says
  "Couldn't undo. Check your connection and try again." there). Nothing found and a failure (Retry sends the same
  photo again) have their screens.
- **Check a paper** is pushed from More's row: the intro with the student (a tile picker) and the notice, then the
  pages (tiles with Remove, Add a page through the document camera, From Photos; up to six, reduced on the iPhone),
  the marking scheme (a paper created here, its answer key and marks; or typed, 4000), checking, then the marks: the
  hero with the total and a bar, one row per question with the AI's note and a mark tile that opens a popover of
  chips 0 to the question's marks; a changed mark says "Changed from N" and the total rolls; Share is in the nav row;
  Save to the student's notes appends one line ("7 Oct · Quadratic equations · 15 of 20 · the notes") and offers
  Undo. Nothing is written before Save. One check runs at a time; Cancel or Back while checking abandons it. If the
  server says the centre has not agreed (the session thought it had), the consent sheet opens over the failure and
  the check runs on agreeing.
- **Every AI call** waits up to 125 s; the API gives Claude 110 s. A timeout says "That took too long to come back.
  Try again in a minute." (not the offline words, which promise nothing was used). A worksheet whose answer key is
  off shows the key on screen "(for you)" and leaves it out of Copy and the PDF.
- **More** gains the three rows live; **Today** gains the Create row at its end. The camera usage text covers the
  register, answer sheets and the UPI QR.

## Phase 7 boards (step 0.8, approved 2026-10-09)

Row 10 of the canvas; sources `mockups/P7-*.dc.html`. Dark for every state; light for Settings, Account and More. Content
is the seed's on Wednesday 7 October 2026 (Meera Nair, Bright Minds Tuition, meera.nair@gmail.com, Class 10 Maths at
17:00); the version "1.0 (14)", the reminder counts, the cache's time and the pending changes are illustrative (the owner's
rule: the screens follow the data).

| Board | Source |
|---|---|
| Settings in full (dark and light), scrolled to the end, a save failed | `P7-Settings`, `-Light`, `-End`, `-SaveFailed` |
| Account (dark and light); Set a password (empty, failed), after it was set; Sign out, Sign out with changes pending | `P7-Account`, `-Light`, `P7-Account-Password`, `-Failed`, `-Saved`, `P7-Account-SignOut`, `-Pending` |
| Delete account: the screen, typed, deleting, failed, done (the sign-in landing) | `P7-Delete`, `-Typed`, `-Deleting`, `-Failed`, `-Done` |
| Teacher reminders: not asked, the system's ask, on, all off, refused, the day picker | `P7-Reminders-NotAsked`, `-Ask`, `-On`, `-AllOff`, `-Refused`, `-DayPicker` |
| Help, an answer open | `P7-Help`, `P7-Help-Answer` |
| More with Account and Help live (dark and light) | `P7-More`, `P7-More-Light` |
| Offline: Today, Students, Fees from the cache; nothing saved yet; a write refused; attendance saved here; a fee marked paid here | `P7-Offline-Today`, `-Students`, `-Fees`, `-NoCache`, `-WriteRefused`, `-AttendanceSaved`, `-FeeMarked` |
| Back online: sending, sent, a change that failed; Pending changes, discarding one | `P7-Sync-Sending`, `-Sent`, `-Failed`, `P7-Pending`, `P7-Pending-Discard` |
| The three notifications on the lock screen; the launch screen; the icon in place | `P7-Notifications`, `P7-Launch`, `P7-AppIcon-Home` |

Phase 7's launch states (`plan/phase-07-plan.md` builds them; light twins from `--appearance light`; the clock is Wednesday 7
October 2026, 16:35; the system surfaces, the lock screen, the launch screen and the home screen have none):

| State | Shows |
|---|---|
| `settings` | Settings in full (supersedes P5-Settings): the profile with its Saved mark, Parents, This iPhone, Account, About |
| `settings-end` | Settings scrolled to the end: This iPhone, Account, About, with the glass under the status bar |
| `settings-save-failed` | Settings after a failed save: no mark, the typed value kept, the toast naming the field |
| `account` | Account: the tutor, the sign-in methods (Apple connected, the code on, no password), Sign out, Delete |
| `account-password` | The Set a password sheet, the field focused, the button disabled |
| `account-password-failed` | The sheet after a failed write: the error under the field, the button live |
| `account-password-saved` | Account with Password "Set" and the toast |
| `account-sign-out` | The sign-out confirmation over Account |
| `account-sign-out-pending` | The same with two changes waiting: they would be lost |
| `delete-account` | Delete account: what goes, the empty confirmation field, the button disabled |
| `delete-account-typed` | The centre's name typed, the button live |
| `delete-account-deleting` | The button loading, the field dimmed, the line "Removing everything" |
| `delete-account-failed` | The error row above the field, Retry, nothing removed |
| `signin-deleted` | The sign-in landing with the "deleted" banner under the lead (after a deletion) |
| `reminders-not-asked` | Teacher reminders before the permission: the intro, Turn on reminders, the switches dimmed |
| `reminders` | Reminders on: the next one, the three cards, 14 set, Refresh |
| `reminders-all-off` | Allowed, every switch off, nothing set |
| `reminders-refused` | Notifications off in iOS: the banner with Open Settings, the cards dimmed |
| `reminders-day-picker` | The day-of-the-month wheel in a popover |
| `help` | Help: Email us, the four questions closed |
| `help-answer` | Help with the first question open |
| `more` | The More root with Account and Help live (supersedes P6-More) |
| `offline-today` | Today offline, from the cache, the bar with its time |
| `offline-students` | Students offline, from the cache |
| `offline-fees` | Fees offline: Mark paid live, Remind and Generate disabled |
| `offline-no-cache` | Fees offline with nothing cached: the empty card with Try again |
| `offline-write-refused` | The New student sheet filled, the keyboard away, the refused toast |
| `offline-attendance-saved` | Attendance saved on the iPhone: the banner, the footer "Saved on this iPhone", Tell parent live |
| `offline-fee-marked` | Fees after Mark paid offline: the row moved with its "kept here" line, the toast with Undo |
| `sync-sending` | Today, back online, the banner with the spinner |
| `sync-sent` | Today with the "3 saved changes sent." toast |
| `sync-failed` | Today with the failure banner that opens Pending changes |
| `pending` | Pending changes: two waiting, one failed with its reason, Send again |
| `pending-discard` | The discard confirmation over Pending changes |

From build 10 (step 0.8b, approved 2026-10-09, row 10b of the canvas at y 14600): the owner's findings on the phone.

| Board | Source |
|---|---|
| New student: the class menu ends with New class… after a section break; no classes yet; the New class sheet on top; back with the class chosen (dark and light) | `P7-NewStudent-ClassMenu`, `-ClassMenu-NoClasses`, `-NewClass`, `-ClassMade`, each with `-Light` |
| Today: the account picture at the top right, level with the date (every Today state follows it) | `P7-Today-Header`, `-Light` |
| Opening: the launch screen's book fading into Today over `opening` (500 ms), once the app is ready | `P7-Launch-Fade`, `-Light` |
| Sign-in: Continue with Google as Google's guidelines draw it (its fill, outline, label and G), the three buttons pills of one size (supersedes A-SignIn's and P2-SignIn-Light's buttons) | `P7-SignIn-Google`, `-Light` |

| State | Shows |
|---|---|
| `student-new-new-class` | New class… chosen from the student form: the New class sheet (filled) on top |
| `student-new-class-made` | Back on New student with Class 12 Physics chosen and its fee in use |
| `kit-phase7` | The Kit's Phase 7 parts: the status lines, the account rows, a pending change, the picker row and its wheel |

The class menu is the system's (`Menu` with toggles, so each class keeps its count line); the opening has no launch state
(a recording of the launch proves it).

What the boards settle (the parts are in `components.md`, "Phase 7 parts"):

- **Settings** is pushed from Today's account button and More's row. Sections: Teaching profile (saved as you go, the
  Saved mark; a failed save keeps the typed value, drops the mark and toasts the field's name); Parents (Parent payments;
  Parent messages, WhatsApp, not tappable, D3); This iPhone (Teacher reminders with its state as the value, Haptic
  feedback, Appearance as a three-segment control Dark, Light, Match iPhone (D23), Pending changes with None or the
  count); Account (the email as the value); About (Version "1.0 (14)", Help, Privacy policy and Terms of use, which open
  the Phase 8 pages in Safari). Sign out moves to Account.
- **Account** is pushed from Settings and from More: the tutor's initials, name and email; Sign-in methods lists only the
  methods the account has (Apple or Google "Connected", Email code "On") plus Password always ("Not set" opens Set a
  password; "Set" opens Change password, the same sheet retitled; nothing connects a new provider in this build); Sign
  out (the dialog, which also says what is cached on the iPhone is removed; with queued changes it says they would be
  lost and the action reads "Sign out anyway"); Delete account permanently (a pushed screen).
- **Set a password** is a floating sheet (D28, content height): one secure field, the helper, the primary disabled until
  8 characters; a failed write shows the error under the field and the button tries again; success closes the sheet,
  the row reads Set and a toast says so. `profiles.has_password` is set with it.
- **Delete account** (the owner, 2026-10-09: option A): the intro names what goes, the notices card lists it (the count
  of students and classes from the register; the Apple row only for an Apple account), the centre's name is typed, the
  solid destructive button runs: Apple users confirm with Apple first (a fresh authorization, its code sent to the API,
  which revokes the token), then `delete_account()` in Postgres deletes the auth user and the cascades take the centre,
  its rows, the membership and the profile; the app then wipes its caches and the queue and shows the sign-in landing
  with the "deleted" banner. A failure says nothing was removed (Retry); the field keeps the name. A second sign-in
  starts at onboarding.
- **Teacher reminders** is pushed from Settings. Before the permission: the intro and Turn on reminders (the system's
  alert follows), the switches shown dimmed. Allowed: the banner names the next reminder; three cards: Classes (a
  switch, "How long before" 5, 10, 15, 30 or 60 min), Events (a switch, "How long before" 15 min, 30 min, 1 hour, the
  day before at 18:00), Fees (a switch, "Day of the month" 1st to 28th in a wheel; at 09:00); "On this iPhone" counts
  what is scheduled through its last day, with Refresh. Refused: the banner with Open Settings, the cards dimmed, the
  choices kept. All off: the banner says so and nothing is set. Reminders are local notifications scheduled two weeks
  ahead on foreground and after any edit of a class, an event or a fee; each carries its deep link.
- **Help** is pushed from Settings and More: Email hello@tutorcentral.in (opens Mail with the version in the subject),
  four questions as disclosure rows (one open at a time), the version line.
- **Offline** (the honest states of guidelines.md): every tab root and list reads from its cache first and shows the
  bar "Offline. Showing what was saved at 14:10." (today's time; "yesterday at 18:30"; "on Mon 5 Oct") between the
  title and the content; a screen never loaded online shows the bar "Offline. Nothing saved on this iPhone yet." and
  the empty card with Try again. Three writes work offline and queue: an attendance save (the footer reads "Saved on
  this iPhone" in the due tone, the banner says it reaches the server later; Tell parent still opens WhatsApp and its
  log is queued), Mark paid (the row moves, its line says it is kept here, the toast offers Undo, which removes it from
  the queue), and the absence alert's log. Every other write is refused on Save with a toast that names it ("You're
  offline. Adding a student needs a connection; nothing was saved.") and keeps the form; Remind, Generate and the AI
  tools are disabled offline.
- **Back online**: the bar becomes "Back online. Sending N saved changes…" on the open screen, then a toast "N saved
  changes sent."; a change that fails leaves the banner "N saved change(s) couldn't be sent." on every tab root until
  it is dealt with. Changes replay in the order they were made, each on its own; last write wins per row (the server's
  row is overwritten by the phone's); a replay that the server refuses (the student or class is gone, the session is
  out) is a failed change. **Pending changes** (from the banner and Settings) lists each change with its state and
  time; a failed one carries its reason in overdue and a quiet Discard (confirmed by a dialog: the server's state
  stands); Send again retries every failed change. Sign-out with changes pending warns.
- **The notifications**: "Class 10 Maths at 17:00 · In 15 minutes · 6 students. Tap to mark attendance." opens
  attendance for that day and class; "Parents' meeting in 1 hour · Sat 10 Oct, 11:00–12:00 · Class 10 parents." opens the
  event; "4 fees still due for October · ₹4,000 to collect. Tap to remind parents." opens the month on Fees. In the
  foreground the system's banner shows and the tap does the same.
- **The launch screen** is the ground colour with the book in marigold, always dark (the app opens dark, D23;
  `UILaunchScreen` with a colour and an image). **The icon** is D29's, drawn in place; the other icons on the board are
  stand-ins.

## Phase 8 boards (step 0.9, approved 2026-10-09)

Row 11 of the canvas (y 16000 on; the title note at y 15700); sources `mockups/P8-*.dc.html`. The website, tutorcentral.in
(D42), is drawn as pages, not phone frames: one HTML per page and appearance, laid out by container queries, rendered at
1280 (desktop) and 390 (phone) as the built site will be; each frame is fluid (`expand: fill`) and as tall as the page at
its width. Dark and light for every page (D13). The hero's phone is the seed's Today board (P4-Today-Soon), dark on both
pages because the app opens dark (D23). Facts only the owner knows are `[OWNER: …]` on the pages until he fills them. As built (session 17): GoodGround LLP, Bangalore; 30 days' notice; and D50, the site names no vendor or internal technology, so the built `/privacy` and Home reword the boards' hosting sentences (the board settles the layout, the page's words are the owner's).

| Board | Source |
|---|---|
| Home before the App Store link (the promise, the phone, what it does, how it works, what it does not do, who makes it) | `P8-Home`, `-Light`, `-Phone`, `-Phone-Light` |
| Home once the app is on the App Store: Apple's badge in the hero (a stand-in; Apple's own badge artwork replaces it) | `P8-Home-Badge`, `-Light`, `-Phone`, `-Phone-Light` |
| `/privacy`: who is responsible, what the app keeps, where, who can see it, children's details, nothing watches you, removing everything, your choices, changes | `P8-Privacy`, `-Light`, `-Phone`, `-Phone-Light` |
| `/terms`: the short agreement in plain words | `P8-Terms`, `-Light`, `-Phone`, `-Phone-Light` |
| `/support`: the email, Help's four questions and two more, the links | `P8-Support`, `-Light`, `-Phone`, `-Phone-Light` |
| Not found: the line, Home and Support | `P8-NotFound`, `-Light`, `-Phone`, `-Phone-Light` |
| U7: Edit event with the keyboard up, the note's well whole and focused, Delete event under the keyboard | `P8-Event-Edit-Keyboard` |
| U24: Scan register's list and Suggested marks scrolled, the glass under the status bar (every pushed AI screen) | `P8-Scan-List-Scrolled`, `P8-Check-Marks-Scrolled` |

The website has no launch states: its pages are proven by `bun web-shots` (each page at both widths and both appearances,
`plan/phase-08-plan.md`). The polish boards' states:

| State | Shows |
|---|---|
| `event-edit-keyboard` | Edit event with the note focused: the keyboard up, the well whole above it, Delete event below (reached by a scroll or when the keyboard goes) |
| `scan-review-scrolled` | Scan register's list scrolled under the status bar with the glass |
| `check-result-scrolled` | Suggested marks scrolled under the status bar with the glass |

What the boards settle:

- **The site's frame.** A header with the book mark and the wordmark on the left and three links (Support, Privacy, Terms)
  on the right, which drop under the brand at phone width; a footer with the brand, "Made in India for tutors who run their
  own centre.", the copyright line, the three links and the email. Content sits in one column of at most 1120 px with 24 px
  gutters; text runs at most 680 px. Appearance follows the device's setting; there is no toggle on the site.
- **Type.** The system stack (`-apple-system, BlinkMacSystemFont, 'SF Pro Text', 'SF Pro Display', system-ui, 'Segoe UI',
  Roboto, 'Helvetica Neue', Arial, sans-serif`): SF Pro on Apple devices, the platform's own face elsewhere, no font file and
  no third-party request. The web's scale: display 60/64 (40/44 at phone width), page title 44/50 (34/40), h2 28/34 (24/30),
  h3 20/27, lead 21/32 (19/28), body 17/27, row title 18/24, row line 16/24, small 15/22, caption 13/18; weights 400, 600, 700;
  tracking as the app's tokens. Colours are the app's tokens, dark and light.
- **Home.** The hero: "More time to teach." over the lead, with the app's `glowHero` behind and the Today board in an iPhone
  shape on the right (under the text at phone width). Before the app is on the App Store the call to action is a secondary
  button "Email hello@tutorcentral.in" with "Coming to the App Store. Write to us and we will tell you when it is there."; after,
  Apple's badge with "Free on the App Store. Needs an iPhone with iOS 26 or later." Then "What it does" as one list card of
  seven rows (students and parents, attendance, fees by UPI, classes and the schedule, papers, checking and progress notes, the
  paper register), "Made for how a tutor works" (six short entries in three columns), "What it does not do" (no ads or tracking,
  records in India, nothing sent on its own, no lock-in, a link to the privacy page), "Who makes it".
- **The legal pages** read in plain words (D41 holds on the site: no "server", "sync", "cache", "API"); every sentence states
  something the app does today, from the code and the decisions (the table below). `/privacy` and `/terms` never move (the app
  links them since Phase 2).
- **Support** is Help's content on the web: the primary Email button, the six questions (Help's four word for word, plus which
  phones and what it costs), the two links.
- **Not found** is a page (Vercel's `404.html` from the static export), never a redirect.
- **U7.** With the keyboard up, Edit event's fields keep their size; the note's well is whole and focused; Delete event sits under
  the keyboard, reached by scrolling or when the keyboard goes (`scrollDismissesKeyboard(.interactively)` is on the root). Nothing
  rides on top of the keyboard.
- **U24.** The pushed AI screens (Scan register's list, Suggested marks, the pages, the result) draw `statusBarGlass()` once they
  scroll, as the roots and Help do.

Where each claim on `/privacy` and `/terms` comes from (the build keeps them true; a change to the app that breaks one changes
the page in the same phase):

| Claim | Source |
|---|---|
| Name and email from Apple, Google or the email code; a password stored scrambled; whether one is set | Supabase Auth (bcrypt); `profiles.has_password` (0001) |
| The centre's name, WhatsApp number, UPI id, payment link, send receipts, the consent day | `centres` columns (0001, 0007 `ai_consent_at`) |
| Students: name, class, fee, parent's name and phone, date of birth, gender, notes; attendance; fees with status, paid date and method; classes, events, tasks | `students`, `attendance_*`, `fee_invoices`, `classes`, `calendar_events`, `tasks` (0001) |
| A message log of student, kind and time, never the text | `message_log` (0001, 0005): `student_id`, `kind`, `channel`, `opened_at`, `about_date` |
| AI inputs and answers kept in history; photos not stored, only page count and size | `ai_generations.input` holds counts and bytes, never the image (`api/CLAUDE.md`, Phase 6) |
| Copies on the iPhone behind the lock, removed on sign-out and deletion | `CachedRead` with file protection, `Wipe.everything` (D39, D40) |
| Records kept in India by the companies that host the app; sign-in codes by an email service (no vendor named, D50) | `supabase/CLAUDE.md` (ap-south-1), D21 (`bom1`), D30 |
| Claude by Anthropic reads what is sent, outside India; never used to train; deleted within 30 days | D35; Anthropic's commercial terms (privacy center, 2026-10-09; the owner, Owner step 0) |
| One centre never reads another's | Row-level security on every table (rule 6) |
| No backup copies of deleted records (the sentence is not on the page; Supabase Free keeps none) | The owner, 2026-10-09; moving to a plan with backups means saying so on `/privacy` |
| No ads, analytics or tracking; no cookies on the site | D18; the site is static with no third-party script |
| Crash reports only through Apple's sharing setting | D18 (no crash SDK); Apple's own analytics sharing |
| Delete account removes everything at once; Apple is told to forget | `delete_account()` and the cascades (D37); the revoke route (D38) |
| Reports gives a month's fees as a file | Phase 5's CSV export |
| Nothing to pay today | D4 |
| Sign in with Apple, Google or an email code; a password optional | Phase 2, Phase 7 |
| iPhone with iOS 26 or later; no iPad, Android or web | D1 |

## U33 boards (approved 2026-10-09): telling the tutor what happened, the Apple way

Row 12 of the canvas (y 34400; the title note at 34100); sources `mockups/U33-*.dc.html`, dark and light, each derived from an
approved board by string edits. The rule they settle is `feedback.md`: the toast is for Undo only.

| Board | Source | Shows |
|---|---|---|
| Copied in place | `U33-Result-Copied`, `-Light` | Copy becomes "✓ Copied" in `ok` for two seconds; no toast |
| A field that did not save | `U33-Settings-NotSaved`, `-Light` | The centre name outlined in `overdue`, its line under it; no toast |
| A list that could not load | `U33-Fees-LoadFailed`, `-Light` | Nothing loaded: the symbol, "Couldn't load the fees", the line, Try Again |
| A failed save | `U33-Attendance-SaveFailed`, `-Light` | The system alert: "Attendance wasn't saved", OK and Try Again; the marks stay |
| The camera is off | `U33-Scan-CameraOff`, `-Light` | The system alert: Not Now and Open Settings |
| An item no longer here | `U33-Event-Gone`, `-Light` | The system alert with OK |

## Store boards (approved 2026-10-09): the App Store screenshots

Row 13 of the canvas (y 35800; the title note at 35500); sources `mockups/Store-*.dc.html`, 402 × 874, each the real
simulator screen (`mockups/store/<launch state>.jpg`, dark, 9:41) in the website's phone frame under an eyebrow, a caption
and a line. The boards are the template: `bun store-shots` renders them with fresh screens at 1206 × 2622 (D51). The order
is the store's; search shows the first three.

| Board | Launch state | Eyebrow | Caption | Line |
|---|---|---|---|---|
| `Store-1-Today` | `today-evening` | Today | Your day at a glance | Classes, fees due and tasks, on one screen. |
| `Store-2-Attendance` | `attendance-exceptions` | Attendance | Attendance in a few taps | Everyone starts present. Tap who is absent, then save. |
| `Store-3-Fees` | `fees-due` | Fees | Know who has paid | Remind a parent on WhatsApp. Mark a fee paid in one tap. |
| `Store-4-Scan` | `scan-review` | Scan a register | Photograph your register | Your students are read from the page, ready to add. |
| `Store-5-Check` | `check-result` | Check a paper | Check a paper in minutes | A suggested mark for every answer. You decide. |
| `Store-6-Paper` | `ai-result-paper` | Teaching tools | A question paper, ready to share | Pick a topic and a level. Copy it or share it as a PDF. |

## Phase 10 boards (V2, `docs/spec-v2.md`): step 10.1, the shell (approved 2026-10-10)

Row 14 of the canvas (y 37200; the title note at 36900); sources `mockups/P10-*.dc.html`. Dark for every state; light for the
three tab roots. Content is the seed's on Wednesday 7 October 2026 at 16:35, as the V1 boards draw it. The V2 boards extend the
approved V1 boards; what a V2 board does not redraw stays as V1 built it (D56).

| Board | Source |
|---|---|
| Today with the five tabs (dark and light): Today, Students, School, Fees, More; Today's content as V1 built it until step 10.3 | `P10-Shell-Today`, `-Light` |
| More (dark and light): Organise, Make, App | `P10-More`, `-Light` |
| The School tab with nothing yet (dark and light) | `P10-School-Empty`, `-Light` |
| Attendance reached from More | `P10-Attendance-Pushed` |

Phase 11 builds these states (the light twins from `--appearance light`):

| State | Shows |
|---|---|
| `today` | Today with the five-tab bar (every tab root follows: `students`, `fees`, `more`, `school-empty`) |
| `more` | The More root with Organise, Make and App (supersedes P7-More) |
| `school-empty` | The School tab with nothing from a school yet: the empty card and its two buttons |
| `attendance` | The Mark root pushed on the More tab, Save attendance in the footer (every attendance state follows: `attendance-exceptions`, `-saved`, `-alert`, `-past`, `-empty`, `-class-menu`) |

What the boards settle:

- **The tab bar** holds Today, Students, School, Fees, More (`sun.max`, `person.2`, `building.columns`, `indianrupeesign`, `ellipsis`).
  Attendance leaves the bar and keeps its two screens unchanged under More (D65): the Mark root is pushed with a Back row, its
  title and the quiet History, and its Save attendance button sits in a footer band above the safe area (12 of ground above,
  `pageSide` beside, 50 below) instead of above the tab bar. Today's Mark attendance, a class detail's Mark attendance and the
  `attendance?date=&class=` link open it the same way, each on its own tab's stack.
- **More** is three list cards: Organise (Schedule, Attendance, Tasks, Batches, Reports), Make (Make something, Check a paper, Scan
  register), App (Settings, Account, Help). Tasks and Batches stay: the Tasks screen with Clear and the batches list (V1's
  Classes) have no other way in from More, and nothing from V1 is dropped (D56). Until Phase 15 builds Make something, its row opens AI
  Assistant as V1's row did (the same screen under the new name is a Phase 15 decision, not a Phase 11 one).
- **V1's class is a "batch" on screen** (the owner, 2026-10-10, at step 10.2: "Batch everywhere"): the tile "Batches today", More's
  row "Batches", the attendance picker "Batch", the Students tab's Batches row and filter chips, the student form's Batch
  picker, "the batch fee". "Class" now means the student's class (LKG to 10), as the spec's section 4 and the tutors' own word.
  The table stays `classes` (D56 renames nothing in the model); only the words on screen change, and V1's screens take the new
  word as Phase 11 touches them (the Classes list, New class and Edit class become New batch and Edit batch, the class tile on
  the attendance picker reads Batch).
- **The School tab** is a tab root with the large title and a "+" icon button (its menu, From a photo and Paste a message, is
  step 10.5's). Empty, it shows one card: `building.columns`, "Nothing from a school yet", the line "Tests, homework, notices
  and holidays appear here, by student, once a school's message or a photo of it reaches Tutor Central.", the primary Ask parents
  to forward (the message that starts the flow, spec section 8) and the secondary Add from a photo, both plain labels; under
  the card the footnote "From WhatsApp, share the school's message to Tutor Central. From Photos, share a timetable or a
  circular. You check each item before it is kept." Until Phase 13 builds the tab's content, Phase 11 shows the Later card in
  its place (P2-Later's pattern, as V1 did for a tab that came later), so no button on screen does nothing.
- **Today** keeps V1's content (the greeting, the tiles, the next class, Today, Coming up, Tasks, the Create row) until step
  10.3 redraws it around the plan.

## Phase 10 boards: step 10.2, Students (approved 2026-10-10)

Row 15 of the canvas (y 38600; the title note at 38300); sources `mockups/P10-Students-*`, `P10-NewStudent-*`, `P10-Student-*`,
`P10-Consent-*`, `P10-Textbook-*`, `P10-Placement`. Dark for every state; light for the list and the student's page. Content is
the seed's ten students given illustrative class levels, schools and records (Hemanth Reddy, class 10, Vidya Niketan, CBSE,
on watch; Riya Sharma, class 5, new; Sahil Verma, class 2, on the ladder); the owner's rule holds: the screens follow the data.

| Board | Source |
|---|---|
| Students sorted by status (dark and light); the empty list | `P10-Students-List`, `-Light`, `P10-Students-Empty` |
| New student: empty, filled, at class 9 (the Board row), the class wheel, the school sheet, scrolled to the end | `P10-NewStudent`, `-Filled`, `-Class9`, `-ClassPicker`, `-School`, `-End` |
| The student's page: the top (dark and light), the record, the end; a new student (not known yet); a class 2 student (the ladder) | `P10-Student`, `-Light`, `-Record`, `-End`, `-NotKnown`, `-Ladder` |
| Consent: the ask, the record, waiting for the reply | `P10-Consent-Ask`, `P10-Consent-Record`, `P10-Student-Consent-Waiting` |
| The textbook's contents page: intro, reading, the chapters, a chapter opened | `P10-Textbook-Intro`, `-Reading`, `-Chapters`, `-Chapter-Edit` |
| The placement | `P10-Placement` |

Phase 11 builds these states (the light twins from `--appearance light`; the clock is Wednesday 7 October 2026, 16:35):

| State | Shows |
|---|---|
| `students` | Students sorted by status with the status word on each row (supersedes P3-Students-Many; `students-empty`, `-few`, `-searching`, `-filtered`, `-add-menu` follow with Batches for Classes) |
| `student-new` | New student empty, the name focused, Save disabled |
| `student-new-filled` | Riya Sharma filled in at class 5, Save live |
| `student-new-class9` | The form at class 9 with the Board row |
| `student-new-class-picker` | The class wheel open |
| `student-new-school` | The school sheet over the form |
| `student-new-end` | The form scrolled to its end |
| `student` | Hemanth Reddy's page: the top (supersedes P3-StudentDetail and P5-StudentDetail-Fees) |
| `student-record` | The page scrolled to the record |
| `student-end` | The page scrolled to homework, school, messages, consent, fees |
| `student-not-known` | Riya Sharma's page: not known yet, consent not asked, no book |
| `student-ladder` | Sahil Verma's page: the ladder |
| `student-consent-ask` | The consent message sheet over Riya's page |
| `student-consent-record` | The Parent agreed sheet |
| `student-consent-waiting` | Riya's page with the reply awaited |
| `textbook-intro` | Add a textbook |
| `textbook-reading` | Reading the contents page |
| `textbook-chapters` | The chapters read, Keep |
| `textbook-chapter-edit` | A chapter's sheet |
| `placement` | The placement for Riya |

What the boards settle:

- **The list** sorts by tracking status by default (not on track, watch, on track, not known yet; by name inside each), then
  Name and Fee as V1; each row's line starts with the status word in its colour (`ok`, `due`, `overdue`, `text3`) and goes on
  with the batch. The fee column stays. Filter chips name the batches; the compact row above the list is Batches.
- **New student (V2)**: Name; Class (a wheel of LKG, UKG, Class 1 to Class 10; required with the name); School (a floating sheet:
  the centre's schools with their student counts and board, one chosen, Add a school as the last row with a field; optional);
  Board (CBSE, ICSE, Karnataka state, Other), shown only from class 8; Batch (V1's class picker, optional); Monthly fee (V1);
  Parent's name and WhatsApp number (V1); Parent's message language (chips English, Hinglish, Hindi, Kannada; English unless the
  tutor's last choice was another); Date of birth, Gender, Notes (V1). Edit student is the same form. Save needs the name and
  the class; nothing else is required (spec section 2).
- **The student's page** is V1's page extended, in this order: the nav row (Back, the name, Edit); the header (avatar 56, the
  name, the class chip, the batch chip, the school and board line, the fee line); the tracking card (the status with its
  symbol, since when, the reasons in one or two sentences, "Next" with the step the plan will take and the quiet Change, which
  opens the four next steps: re-teach with a worked example, step back to the prerequisite, add to the spaced queue, tell the
  parent); the parent card (V1); This week (the sessions of the week: came, how many checks right, what was taught, homework
  given; today's row opens Today); Record (per subject a card: the subject's head with its chapter count and the quiet Add a
  chapter; chapter rows with their position, name and a count of skill states; an open chapter lists its skills with a state
  mark; a subject with no book shows the empty row with Add the book); Checks (the three-week trend: one bar per session,
  the bar's height the right answers of three, `ok` for 3, `due` for 2, `overdue` for fewer; the percentage; the counts);
  Marks (one row per test: the test and subject, the school and date, the score, a chip when it is below the student's
  usual; Add from a photo); Homework (one row per sheet given: Done, Partial, Not done chips); School (the student's items
  with their dates; See all opens the School tab's list filtered to the student); Messages (what was sent, when, the
  language, opened); Consent (three states below); Fees, Attendance, Notes, Archive and Delete as V1.
- **Not known yet** (a student without checks) says what will tell (the first week's checks, or a placement) and offers
  Place <name> on the card's Next line; the Record shows each subject waiting for its book.
- **The ladder** (LKG to 3) replaces chapters for Reading, Writing and Numbers: five steps each, the secure steps in `ok`,
  the current one in the accent with its name in 700, the rest in `lineStrong`; the line says the step and when it moved up.
  Other subjects (EVS, the school's books) keep chapters. The steps: Reading Letters, Words, Sentences, Paragraph, Story;
  Writing Traces, Letters, Words, Sentences, Short text; Numbers To 9, To 99, Add, Subtract, Multiply.
- **Consent (D62)** is a section on the page, never a gate on a screen, and the WhatsApp message is optional (the owner,
  2026-10-10). Not recorded: the line says the parent agrees once, in person, on a call or on WhatsApp; two buttons: Ask on
  WhatsApp (secondary; opens the message sheet, the text in `components.md`; Open WhatsApp logs a `consent` row and notes the
  day asked) and Parent agreed (primary; opens the record sheet straight away). Waiting (only after a WhatsApp ask): "Asked
  <parent> on <day>", what waits (the student's own notes and marking) and what does not (sheets and sets), Ask again and
  Parent agreed. The record sheet: How (In person, On a call, On WhatsApp), Agreed on (today or earlier), the parent's
  number, Record it. Agreed: "<parent> agreed" with the day, the number and how; the quiet Change reopens the sheet and can
  clear it. Export and delete per student live on Edit student (Phase 11 decides their form).
- **The textbook (D58)** is captured from the student's page (Add a textbook, Add the book) for one subject: the intro names
  the school and class and says the classmates get the same chapters; the photo goes through V1's camera or Photos; reading
  shows the creating card with the photo's thumbnail over the intro dimmed; the chapters read are a list in the book's order,
  each with the skills read under it, Add a chapter, and a chapter sheet (the name, the skills with remove and add, Remove
  this chapter); Keep writes the textbook once for the school, class and subject and the chapters and skills for each student
  of that school and class. Nothing is written before Keep.
- **The placement** is a pushed screen (from Place <name>, and the same form inside the close for a student with no checks): a
  footnote on how to use it, per subject a card of check rows (the skill as the eyebrow, the question, the expected answer,
  a Right | Wrong pair; untapped is skipped), the count beside the subject's title, Done in the footer. Done keeps the taps;
  each subject's chapters start from the first skill got wrong.
- **The check row** (`components.md`) is the one control for a right-or-wrong answer here and in the close (step 10.3).

## Phase 10 boards: step 10.3, Today (approved 2026-10-10)

Row 16 of the canvas (y 40000; the title note at 39700); sources `mockups/P10-Today-*`, `P10-Close*`. Dark for every state; light
for the plan and the close. Content is the seed's on Wednesday 7 October 2026 at 16:35 with an illustrative mixed batch (the
Evening batch, 17:00–18:30: Dev, Meher and Nikhil in class 8, Riya in class 5, Sahil in class 2, in three groups); the note day
is Sunday 11 October, the day with no batch Saturday 10 October. The figures are illustrative.

| Board | Source |
|---|---|
| Today with the plan (dark and light); scrolled to the smaller groups, the brief and V1's sections | `P10-Today-Plan`, `-Light`, `-Scrolled` |
| Planning today's class | `P10-Today-Planning` |
| A line's menu; the plan changed; the Change sheet | `P10-Today-Plan-StudentMenu`, `P10-Today-Plan-Changed`, `P10-Today-Plan-Change` |
| The close (dark and light); scrolled (checks tapped, a student absent); the placement inside it | `P10-Close`, `-Light`, `-Scrolled`, `-Placement` |
| After the close; the note day; a day with no batch | `P10-Today-AfterClose`, `P10-Today-NoteDay`, `P10-Today-NoBatch` |

Phase 12 builds the plan's states and Phase 11 the close's (the light twins from `--appearance light`):

| State | Shows |
|---|---|
| `today` | Today with the plan for the day's batch (supersedes P4-Today-Soon and P7-Today-Header's content; `today-evening` becomes `today-after-close`) |
| `today-scrolled` | Today scrolled to the smaller groups, the brief, V1's sections |
| `today-planning` | The plan being made |
| `today-line-menu` | A student's line pressed |
| `today-plan-changed` | A student moved, a homework skipped |
| `today-plan-change` | The Change sheet |
| `close` | The close for the day's batch, nothing tapped yet (Phase 11; it works without a plan: the lines card is absent and each student has the three checks from the spaced queue, or the placement) |
| `close-scrolled` | Two students' checks tapped, one absent |
| `close-placement` | A student with no checks yet |
| `today-after-close` | Today after the close |
| `today-note-day` | Sunday evening: the notes |
| `today-no-batch` | Saturday: no batch |

What the boards settle:

- **Today's order:** the header, the tiles (Students, Due, Batches today), the batch hero, "Today's plan", then V1's sections
  (Today, Coming up, Tasks) and the Make something row (Phase 15; the Create with AI row until then). The hero is the next batch
  with Start class while one is within 90 minutes or running (Start class replaces Mark attendance on Today: the close writes
  attendance; Mark attendance stays under More for any day and batch); after the last batch the hero reads what happened
  (closed at, N of M came, the checks right, the homework given, who was absent) with Open the class; on a day with no batch it
  names the next batch and says its plan is made when the app is opened that day.
- **The plan** is a card per level group under "Today's plan" with the quiet Change: the group's head (Group n · its chapter;
  the class and subject and the count; the material's marks: each artefact with a tick in `ok` when made, a spinner while it is
  on its way), then one line per student: avatar 36, the name, the status word, the teach line in `text` (Teach, Teach again with
  the worked example, Catch up for a student absent twice), then practise, check and homework in `text2`. The brief row (the
  Phase 6 tool row: Your brief · the chapter; five minutes, three common mistakes, the worked example) sits between the groups
  after the group whose chapter is above class 7 or one the tutor asked about. A group of one is still a group.
- **Planning** holds the hero's button disabled and the creating card in the plan's place; the lines fill in as they come and the
  class can start meanwhile. A plan already made opens at once (D60).
- **Changing** is where it appears (spec section 2): a long press on a line gives Move to Group n, Skip the check today, Skip
  homework today, Leave out today (the system's context menu; the board draws the Phase 3 menu); a moved student's line says
  "Moved here from Group n", a skipped line is struck through with "skipped today". Change on the section header opens a
  floating sheet: Groups (one to three; one puts everyone together), each group's subject today, "Keep this for <weekday>s" (the
  weekly pattern on the batch), Make the plan again, Use this plan. Nothing changed here is carried to another day unless kept.
- **The close** is pushed from Start class (and from a batch's row on Today once the batch has begun): the title "Close the
  class" with the quiet Plan (back to Today's plan); the batch, the day, the time and the count; a footnote on how it works; per
  group a checklist card of the plan's lines (24 pt checkboxes, a count beside the title); then "Students": a card per student
  with the name and the attendance pill (Present by default; the whole head toggles), the eyebrow "Check · 3 questions", three
  check rows (the skill, the question, the expected answer, Right | Wrong; untapped is skipped), and "Homework given · sheet n"
  with a switch on by default. A student marked absent folds to one line (the checks wait, a catch-up line joins the next plan).
  A student with no checks yet shows the placement's rows under "Placement · a few questions per subject". Done in the footer
  writes the attendance session, the checks and the homework in one call (`close_session`) and pops to Today; nothing is asked
  first; Done with attendance alone is a close. Offline the close queues as V1's attendance does (D39 extended): the footer
  becomes "Saved on this iPhone" in the due tone.
- **After the close**, "To parents" lists what goes now, one row each with its kind as the title (Test tomorrow, Absent today),
  the parent, the language and the detail, and Send (primary for the first); the last row counts the notes waiting for the note
  day and names any held for consent. Each Send opens the Phase 4 message sheet.
- **The note day** (Sunday evening by default; changed where it appears, on the batch) puts a hero on Today ("7 notes for
  parents") and a Notes card: one row per student with the language, the week's topic and the fact that leads the note; Read
  (primary, 36 high) opens the note (step 10.6); a sent row reads Sent in `ok`; a held row (no consent, or the parent's three
  messages this week are spent) reads Held in `text3`. The count sits beside the title.

## Phase 10 boards: step 10.4, the artefacts (approved 2026-10-10)

Row 17 of the canvas (y 41400; the title note at 41100); sources `mockups/P10-Sheet*`, `P10-WorkedExample`, `P10-Figure-*`,
`P10-Brief`, `P10-Mock`, `P10-GapReport`. Dark for every state; light for the sheet. Content is illustrative (Group 1's balancing
equations sheet, Dev's science mock). The check in the close and the placement are drawn in steps 10.3 and 10.2.

| Board | Source |
|---|---|
| The sheet: paper (dark and light), the key, the board view; make it again (the reasons, being made); use my own (the menu, the tutor's sheet in place) | `P10-Sheet`, `-Light`, `-Key`, `-Board`, `-Regenerate`, `-Regenerating`, `-OwnMenu`, `-Own` |
| The worked example | `P10-WorkedExample` |
| The figure templates: number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain | `P10-Figure-NumberLine`, `-FractionBar`, `-PlaceValue`, `-UnitCircle`, `-Triangle`, `-Cell`, `-FoodChain` |
| The brief; the mock; the gap report | `P10-Brief`, `P10-Mock`, `P10-GapReport` |

Phase 12 builds the sheet, the worked example, the figures and the brief; Phase 13 the mock and the gap report (the light twins
from `--appearance light`):

| State | Shows |
|---|---|
| `sheet` | A sheet from the plan, Paper |
| `sheet-key` | The key |
| `sheet-board` | The board view at question 3 |
| `sheet-regenerate` | The reasons menu |
| `sheet-regenerating` | Being made again |
| `sheet-own-menu` | Use my own: the three ways |
| `sheet-own` | The tutor's own sheet in place |
| `worked-example` | Two of four steps shown |
| `figure-number-line`, `-fraction-bar`, `-place-value`, `-unit-circle`, `-triangle`, `-cell`, `-food-chain` | One figure each (the Kit's figure previews cover the validators) |
| `brief` | The brief for a chapter |
| `mock` | The mock with its sections |
| `gap-report` | After a marked mock |

What the boards settle:

- **An artefact's screen** is pushed from its plan line, the student's page or Make: the nav row (Back, the kind, one quiet
  action), the result hero (the eyebrow names the group or student, the class, subject and chapter; the title; the line with the
  counts, who it is for and when it was made), the content, and the footer band: the AI line, a centred quiet Make it again, two
  buttons 46 (Share as PDF and Print for anything printable; Copy and Share as PDF for the brief; Share as PDF and Mark from a
  photo for the mock). PDFs are rendered on the phone when shared or printed (spec section 7).
- **The sheet** has three forms under a segmented control: Paper (the Phase 6 paper card: a section row with "1 mark each", numbered
  question rows), Board (full screen, one question at a time in `display` type, the count, Previous and Next, Done, and Key to show
  the answer under the question), Key (each answer under its question in `ok` 600, "for you"; left out of a shared or printed
  sheet unless chosen).
- **Make it again** is one tap and a reason: Easier, Harder, Shorter, More sums, Different numbers, or "Say what to change…" (a
  field in a sheet). The old artefact stays at 0.55 with a spinner and the reason by the section title ("Making it easier") until
  the new one lands; the buttons wait (Phase 6's pattern). The new one replaces the old in the plan; the old stays in the record
  (`artefacts.regenerated_from`).
- **Use my own** (spec section 2, hand-made material) is the nav row's action on any sheet: Take a photo, Choose from Photos, Type it.
  The tutor's own takes the made artefact's place in the plan and the record ("Used in place of sheet 1"), with Replace in the
  nav row and a quiet Use the made sheet instead; it can be shared and printed like any other.
- **The worked example** is one step at a time: the problem as the hero's title, a Steps card (shown steps with their number in
  the accent disc, the title and the working; steps to come dimmed with their title only), "2 of 4" beside the section title, Show
  the next step in the footer with the common slip under it, Show all in the nav row.
- **A figure** is drawn by the app from a typed spec with tokens (D59), never a picture from the model: the hero names the skill,
  the figure sits on `surface2` inside a card with a caption that says what the app checked, Show large opens it full screen,
  Print adds it to the sheet. The seven templates and their rules: number line (start, jumps, landing; the jumps in the accent),
  fraction bar (equal parts, the shaded ones in the accent; the parts must sum to the whole), place value (a column per place
  with the digit in `accentText` and its worth), unit circle (the angle, the point, the two ratios; the sine as a dashed `ok`
  drop), triangle (the right angle marked, the sides named, the rule), labelled cell (five parts with leader lines, the chapter's
  names only), food chain (boxes joined by accent arrows pointing at the eater; the first link a plant).
- **The brief** reads in five minutes: What the chapter is about (one paragraph), Three common mistakes (numbered, each with how
  to catch it), The worked example to use (a row that opens it), Words to say (three lines to use in class). Its AI line reads it as
  a colleague's note, not a textbook.
- **The mock** is in the school's pattern from its last papers (or the board's blueprint for class 10): sections with their marks
  each, the questions; Key in the nav row; Mark from a photo opens V1's Check a paper with this paper's key.
- **The gap report** follows a marked mock: the score with a bar and the days left; By skill, one row each with a bar in `ok`, `due`
  or `overdue` by its fraction and the line that says what went wrong; The last two days, a row per day with the lines the plan
  will take, Change; Use this plan replaces those days' lines; leaving it keeps the plan as it was.

## Phase 10 boards: step 10.5, School (approved 2026-10-10)

Row 18 of the canvas (y 42800; the title note at 42500); sources `mockups/P10-School-*`, `P10-TestTomorrow`. Dark for every
state; light for the list. Content is illustrative: a Class VIII B message from Vidya Niketan read into an exam, a homework and a
holiday; Dev's test on Thursday 8 October for Test tomorrow.

| Board | Source |
|---|---|
| The share hand-off (the system's sheet, for reference); the items read for checking; an item's sheet | `P10-School-Share`, `P10-School-Confirm`, `-Confirm-Edit` |
| The list (dark and light); the "+" menu; the calendar | `P10-School-List`, `-Light`, `P10-School-AddMenu`, `P10-School-Calendar` |
| An exam's page; edit; delete | `P10-School-Item`, `-Item-Edit`, `-Item-Delete` |
| Ask parents to forward; Test tomorrow; the last days before an exam | `P10-School-Ask`, `P10-TestTomorrow`, `P10-School-Exam-LastDays` |

Phase 13 builds these states (the light twins from `--appearance light`; the share sheet has none, it is the system's):

| State | Shows |
|---|---|
| `school` | The School tab's list (supersedes `school-empty` once an item exists) |
| `school-calendar` | The calendar with Friday 16 October chosen |
| `school-add-menu` | The "+" menu |
| `school-confirm` | The items read from a message |
| `school-confirm-edit` | An item's sheet over the list to check |
| `school-item` | An exam's page with its preparation |
| `school-item-edit` | The item's sheet over the page |
| `school-item-delete` | The delete dialog |
| `school-ask` | Ask parents to forward |
| `school-test-tomorrow` | The Test tomorrow sheet over the exam |
| `school-last-days` | The exam two days before |

What the boards settle:

- **The way in** is the share extension (a message from WhatsApp, a photo from Photos) and the "+" menu (From a photo, Paste a
  message, Add by hand, Ask parents to forward). A share opens the app on "Check what was read" with the source in a well
  (`school_items.source_text` or the photo) and one card per item read: a 24 pt checkbox, the title, the kind chip (Exam `overdue`,
  Homework `due`, Notice neutral, Holiday `ok`), and its facts in two columns (For, Subject, Date or Due, Portions). Add keeps the
  ticked items (`confirmed_at`); nothing is kept before. An item read for a class ("Class 8 at Vidya Niketan") is for every student
  of that school and class; a message about one student makes that student's item.
- **The item's sheet** (from the list to check, and Edit on the page) holds the kind as chips, the title, For (a tile: a school's
  class or one student), Subject, Date, Portions (500), Remove this item.
- **The School tab** is List | Calendar. The list groups by date (This week, Next week, Later): the day column, the title, the
  line (who, the school, the subject, the countdown for an exam), the kind chip, a chevron. The calendar is the Phase 4 month
  card with a dot per day in the kind's colour and the chosen day's items under it.
- **An exam's page**: the hero (the school, class and subject, the kind chip, the title, the date with the countdown, the portions);
  Who (the students with their status); Preparation (one row per day from today to the test: the portion and what is made for it,
  a tick when done, Today as a chip, the mock two days before, the last set from the gap report; Change opens the day's lines);
  What the school sent (the source and when it came); Delete this item. A homework's page has no Preparation; a holiday's page
  says the batch days it covers.
- **Preparation (spec section 6)** starts when an exam is within the window (14 days unless changed): the portions split across
  the days, a daily set, the mock two days before in the school's pattern (from its earlier papers, or the board's blueprint),
  marking from a photo (V1's Check a paper with the mock's key), and the gap report that sets the last days. Two days before,
  the page leads with Today (the mock ready, Mark from a photo), Marked (each student's score and the quiet Gap report) and The
  last two days.
- **Ask parents to forward** is a pushed screen: the message once (the tutor edits it), then one row per parent with Send
  (opens WhatsApp to that parent) and Sent marks; "2 of 7 sent" beside the title. Each Send logs a `message_log` row.
- **Test tomorrow** is the Phase 4 message sheet in two languages: the message in the parent's language with the signature, "In
  English, for you" under it on `surface2`, Edit in the header, Open WhatsApp (logs `test_tomorrow`). It is offered on Today's
  "To parents" the evening before and from the item.
- **Delete** asks with the dialog: the item leaves the tab and its preparation lines leave the plan; what was taught stays.

## Phase 10 boards: step 10.6, Parents (approved 2026-10-10)

Row 19 of the canvas (y 44200; the title note at 43900); sources `mockups/P10-Note*`, `P10-CanNowDo`, `P10-Student-Messages`,
`P10-Held`, `P10-Student-NotOnTrack`, `P10-NextStep`, `P10-NotOnTrack-Message`, `P10-Today-NotOnTrack`, `P10-NoteDay-Change`. Dark
for every state; light for the note. Content is illustrative: Dev's week for his father in Hindi, Sahil's ladder for his father in
Kannada. The note day's list is drawn in step 10.3 (P10-Today-NoteDay).

| Board | Source |
|---|---|
| The weekly note (dark and light); sending it | `P10-Note`, `-Light`, `-Send` |
| Can now do | `P10-CanNowDo` |
| The sent log; a held note | `P10-Student-Messages`, `P10-Held` |
| Not on track: the student's page, the next step, the message to the parent, Today's line | `P10-Student-NotOnTrack`, `P10-NextStep`, `P10-NotOnTrack-Message`, `P10-Today-NotOnTrack` |
| The note day's setting | `P10-NoteDay-Change` |

Phase 14 builds these states (the light twins from `--appearance light`):

| State | Shows |
|---|---|
| `note` | Dev's weekly note in Hindi with English beside |
| `note-send` | The two-language sheet over it |
| `note-can-do` | Sahil's can-now-do in Kannada |
| `student-messages` | Dev's sent log with a held row |
| `today-note-held` | A held note's sheet over the note day |
| `student-not-on-track` | Dev's page with the next step and Tell the parent |
| `student-next-step` | The next-step sheet |
| `student-tell-parent` | The message to the parent |
| `today-not-on-track` | Today's plan with Dev's line not on track |
| `today-note-day-change` | The note day's wheel |

What the boards settle:

- **The note** is pushed from the note day's Read (and from a student's page, Write a note): the hero (avatar, the student, the
  parent, the language, the week); the note in the parent's language in an editable well (600 characters, the counter), "In
  English, for you" on `surface2` under it (the tutor reads what the parent will get; the English is never sent); "What it
  says", four rows from the record (Taught, Got right, To practise, Coming; for LKG to 3: Can now do, At home, Next); the
  footer: the AI line, Write again, Copy and Send on WhatsApp (the two-language message sheet with the signature; Open WhatsApp
  logs a `note` row with the language). Can now do is the same screen with "Moved up" (the ladder) above the note.
- **The parent's language** is the student's (English, Hinglish, Hindi, Kannada); English is always beside it for the tutor; a
  note in English shows no second block.
- **The cadence (D61)**: at most three suggested messages a week per parent (the note, can-now-do, test tomorrow, not on track,
  a homework share); the fourth is held and shows on the note day and the sent log as Held with the reason; the held sheet
  lists the week's three and offers Send it now or Keep it for next week. The tutor's own sends (a reminder, a receipt, the
  absence alert, Call) are never held and do not count.
- **The sent log** (See all under Messages on the student's page) lists every message by month, newest first: the kind, the
  day, the language, "opened <day>" when WhatsApp was opened (`message_log.opened_at`), "not opened yet" otherwise; a Held
  section between the months with Send now.
- **Not on track** on the student's page: the tracking card in `overdue` with the reasons and "Next" ("Tell the parent, then
  teach again with the worked example"); a card under it says the parent has not been told, with Call and Tell the parent
  (the two-language message sheet: what is hard, what we are doing, what helps at home, a five-minute talk; logs a `note`
  row of kind not on track). Change on the card opens the next-step sheet: the five choices with the plan's choice ticked;
  Use this. On Today, the student's line carries a `caption` in `overdue` ("Since Fri 9 Oct · tell Ramesh after the class") and
  the teach line is already the step.
- **The note day** is Sunday 18:00 unless the batch says another: Change day on the note day's hero opens a wheel of weekday
  and time; the choice is kept on the batch (the weekly pattern's row), so a tutor with a Saturday batch moves it once.

## Phase 10 boards: step 10.7, Make and the Kit (approved 2026-10-10)

Row 20 of the canvas (y 45600; the title note at 45300); sources `mockups/P10-Make*`, `P10-Reports-Progress*`, `P10-Kit-Dark`,
`P10-Kit-Light` (the Kit boards are 393 × 2020). Dark for every state; light for Make and the Kit. With this row Part A of Phase 10
is complete: 96 boards in rows 14 to 20, every V2 screen and state of spec sections 4 to 8.

| Board | Source |
|---|---|
| Make something (dark and light); a kind's form; for whom | `P10-Make`, `-Light`, `P10-Make-Form`, `P10-Make-For` |
| Check a paper under Make | `P10-Make-Check` |
| Reports: Progress by month, by term | `P10-Reports-Progress`, `-Term` |
| The Kit's new rows (dark and light) | `P10-Kit-Dark`, `P10-Kit-Light` |

Phase 15 builds these states (the light twins from `--appearance light`):

| State | Shows |
|---|---|
| `make` | Make something (supersedes `ai-assistant`; `ai-assistant-empty` becomes `make-empty`) |
| `make-sheet` | The sheet's form for Group 1 |
| `make-for` | The For sheet at Group |
| `check-intro` | Check a paper under Make with the mock's key offered (supersedes P6-Check-Intro's way in) |
| `reports-progress` | Reports, October, Progress |
| `reports-progress-term` | Reports, Term 1, Progress |
| `kit-phase10` | The Kit's Phase 10 rows |

What the boards settle:

- **Make something** replaces AI Assistant's home under More's Make (Phase 15): an intro line, "For a student or a group" (Sheet,
  Worked example, Figure, Note to a parent, Mock test), "For you" (Brief, Question paper, Homework, Worksheet: V1's kinds, their
  forms unchanged), Recent (three, See all), the AI line; History in the nav row. Each row opens the kind's form.
- **A kind's form** is the Phase 6 form screen: For (a tile that opens the For sheet: Student | Group | Batch | Class, with choice
  rows; a sheet for a class level alone carries no student's data and needs no consent), Subject, Skill or topic (from the record,
  or typed), Length (Short, Medium, Long), Level (Easier, As the record says, Harder), Key at the end; Make in the footer. The
  note's form asks for the student and what to say; the mock's for the student and the exam; the brief's for the chapter.
- **Check a paper** keeps V1's screens under Make; its scheme tile offers a mock or paper made here (with its key) or a typed scheme.
- **Reports** gains Progress beside Fees and Attendance, with Month | Term under it (a term is the school's: Term 1 June to
  September, Term 2 October to March; the Karnataka state calendar's where the school is state board): the hero with skills made
  secure, checks right and the not-on-track count; one row per student with the status word, skills secure, checks right and
  absences, the percentage on the right, Lowest first as the sort; Share gives the CSV (student, class, status, skills secure,
  checks, right, absences). A LKG to 3 row names the ladder steps instead of skills.
- **The Kit** gains the Phase 10 parts in both appearances, as `kit-phase10` shows them: tracking status (chip and word), skill
  states, item kinds, the material's marks, a chapter row open with skill rows, the plan line, the check row with the line
  checklist and the right-or-wrong pair in both states, the ladder, the trend, the seven figure templates (the validators'
  previews), the board view type.
