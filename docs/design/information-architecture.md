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
| Attendance | Attendance (Mark) | History (by date, by student, one student's month); a saved class reopens on the Mark root by date and class | Absence alert |
| More | More | Schedule, Tasks, Classes, Settings, Reports, AI Assistant (its four forms, a result, History), Check a paper (pages, the scheme, the marks), Scan register (the list to check); Account and Help named with their phase until it ships; Settings pushes Parent payments | New event, Edit event (with Delete event), Share as CSV, the student picker, the consent, Send the note, Fix this row, the camera |

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
