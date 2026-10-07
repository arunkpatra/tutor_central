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
| `onboarding` | Onboarding, fields prefilled |
| `today-empty` | Tabs, Today with every section empty |
| `later-fees` | The Fees tab's placeholder (and `later-students`, `later-attendance`, `later-more`) |
| `settings` | Settings minimal |
| `kit` | The Kit (debug builds) |

Later phases add theirs in their plan files.

## Phase 2 boards (step 0.3)

| Board | Canvas | Source |
|---|---|---|
| Sign in, dark | row 1, board 3 (`A-SignIn`) | `directions/A-SignIn.dc.html` |
| Sign in, light | row 5 | `mockups/P2-SignIn-Light.dc.html` |
| Email, request a code | row 5 | `mockups/P2-Email-Request.dc.html` |
| Email, enter the code, with the wrong-code state | row 5 | `mockups/P2-Email-Code.dc.html` |
| Onboarding, dark and light | row 5 | `mockups/P2-Onboarding-*.dc.html` |
| Today empty, dark and light | row 5 | `mockups/P2-Today-Empty-*.dc.html` |
| Settings minimal | row 5 | `mockups/P2-Settings.dc.html` |
| A tab that comes later | row 5 | `mockups/P2-Later.dc.html` |
| The Kit | row 4 | `mockups/Kit-*.dc.html` |

Sign in with Apple and Google show the system's own sheets; they are not drawn.
