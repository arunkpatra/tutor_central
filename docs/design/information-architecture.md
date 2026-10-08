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
| Today | Today | Schedule, class (via a row), student (via a fee row) | New task |
| Students | Students list | Student detail, Class detail, Classes list | New student, Edit student, New class, Edit class, Scan register, archive and delete confirmations |
| Fees | Fees (month) | Student detail | Generate month, Mark paid, Waive, UPI settings |
| Attendance | Attendance (Mark) | History by date, History by student, Session | Absence alert |
| More | More | Schedule, Classes, Reports, AI Assistant, Check a paper, Scan register, Tasks, Settings, Account, Help | Event, Generation forms |

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
| `class-edit` | Edit class, Class 10 Maths, nothing changed, with Archive class |
| `class` | Class detail, Class 10 Maths: this week and six students |
| `class-add-members` | Class detail with the add-students sheet |

Later phases add theirs in their plan files.

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
  says), Create a class (sheet).
- Forms are floating sheets (D28): the student form at the large detent, the class form at its content height.
  Save is disabled until the form is valid and, when editing, until something changed. Cancel asks before
  discarding typed changes (components.md, Sheets).
- A student's fee left empty means the class fee; the helper line says so. A student is archived from the
  detail (primary confirmation, reversible, restored from the same screen or the Archived filter) and deleted
  with the typed confirmation. A class is archived from the bottom of its edit sheet; its students stay, with no
  class.
- Class detail: the week's meetings from the meeting days (today's row marked), the members with "Add" (a
  checklist sheet of students not in the class; a student moved keeps a fee of their own), removal by the
  system's swipe action with the row's context menu as the visible alternative (not drawn: the system draws it).
  "Mark attendance" and the detail's Fees "See all" open the later board until Phases 4 and 5.
- Searching matches names and phone numbers across every class and the archive; the matched letters are in
  `accentText`; the matching phone takes the row's second line.
