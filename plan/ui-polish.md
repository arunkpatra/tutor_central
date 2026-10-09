# UI polish list

Things seen on screen that work but could look or read better: layout, spacing, copy, stale content, small visual
differences from a board. Not bugs (a bug is fixed in its own pull request at once) and not new features (those
belong to a phase). The owner decides when an item is taken: one at a time when a session is already in that
screen, several as a polish slice, or not at all.

## How it works

- **Adding:** anyone who sees something (the owner on a build, a session in the simulator or in a review) adds a row
  under "Open" in the same documents commit as the session's other notes: the next number, the date, the screen and
  state, what is seen, where it came from (the owner, a session record, a review). One thing per row, in words the
  owner would use. Don't fix it on the side.
- **Taking:** the owner picks items, or a session proposes one when its work already touches that screen and the
  owner agrees. An item that changes what is seen gets its board first (CLAUDE.md rule 1): a board on the canvas,
  approved, mirrored in `docs/design/`. A copy or stale-content fix that matches an approved board needs no new
  board. Each item, or a few on one screen, is its own pull request with screenshots of each changed state in both
  appearances (D7), and proven in the simulator by `docs/runbooks/simulator.md` where it touches a live screen.
- **Closing:** move the row to "Done" with the pull request. An item the owner drops moves to "Dropped" with the
  reason. Numbers are never reused.

## Open

| # | Seen | Screen | What is seen | Source |
|---|---|---|---|---|
| U5 | 2026-10-08 | More | The rows are 56 pt high (SettingRow's minimum); P4-More draws them at 50 | Session 9, comparing with the board (PR #42) |
| U8 | 2026-10-08 | Date pickers in a popover | Picking the day the calendar already shows leaves the popover open (tap outside to close); the system calendar starts the week on Sunday where the app's month starts on Monday | Session 9's hand run |
| U10 | 2026-10-08 | Attendance mark | A slow or failing read shows nothing for up to 20 s (no spinner by the date), and "Everyone starts present…" stays beside the error line | Session 9's follow-up hand run |
| U11 | 2026-10-08 | today-adding-task | The launch state cannot scroll Coming up to the top as P4-Today-AddingTask draws (the board's room is the keyboard's) | Session 9, comparing with the board |
| U13 | 2026-10-08 | Any sheet, then a link | A sheet open on one tab (Reports' Share as CSV) stays up over the tab a `tutorcentral://` link opens | Session 11's hand run (issue #50) |
| U14 | 2026-10-08 | Fees, an empty current month | Before the month is generated, the overdue banner for last month's unpaid fees is not shown (the board draws the empty month without it) | Session 11's final review |
| U15 | 2026-10-08 | Fees, Due or Paid with nothing in it | "Nothing due · Every fee for October is settled." and "Nothing paid yet" are the Kit's empty row in words no board drew | Session 11 (the plan's unboarded filler) |
| U17 | 2026-10-09 | The note's observations, the typed scheme | The counter reads "80 of 2,000" (the Kit's notes counter); P6-Form-ProgressNote draws "135 / 2000" | Session 13, comparing with the board |
| U18 | 2026-10-09 | Progress note, Send the note | The sheet opens lower than P6-ProgressNote-Send: its top sits under the student row, the board's under the nav row | Session 13, comparing with the board |
| U19 | 2026-10-09 | today-ai-tools (launch state) | Today is not scrolled to Create as P6-Today-AITools draws (like U11) | Session 13, comparing with the board |
| U20 | 2026-10-09 | Progress note, the consent sheet | Over the note form the sheet reads "Before the first photo" and speaks of photos; a note has none (the plan chose the same sheet) | Session 13's hand run (issue #61) |
| U21 | 2026-10-09 | Homework and worksheet forms, the failure row | "Couldn't create the homework." breaks after "create" (the board's "the paper." fits one line) | Session 13's hand run |
| U22 | 2026-10-09 | Check a paper, the scheme | Two papers on one topic look alike (title, kind, class, marks and day the same); nothing says which is newer | Session 13's hand run |
| U23 | 2026-10-09 | Check a paper, the pages | After removing every page the heading reads "0 pages" | Session 13's hand run |
| U25 | 2026-10-09 | Delete account | With the keyboard up, Delete my account sits under it until the field is put away | Session 15's hand run 5 |
| U26 | 2026-10-09 | Reports, offline | Reports has no copy on the iPhone: offline it shows the "nothing saved" card (the plan's decision; a cache would need a board) | Session 15 |
| U27 | 2026-10-09 | Attendance, offline at launch | The day's saved copy is used only after a read fails, so the first 20 s offline show nothing | Session 15's hand run 7 |
| U28 | 2026-10-09 | Fees, Mark paid offline | The receipt sheet is not offered after an offline Mark paid (no log can queue a receipt) | Session 14's plan, seen in session 15 |
| U29 | 2026-10-09 | Students, the "+" menu at the largest text sizes | The system menu cuts "Scan paper register" to "Scan paper regis…" | Session 15's Dynamic Type check |
| U30 | 2026-10-09 | The "Sign in again" status line | It has no way forward but Account → Sign out, which warns the saved changes are lost | The Phase 7 review (minor 7) |
| U32 | 2026-10-09 | Pushed screens other than the AI and scan screens (Attendance History, a student's month, Schedule, Tasks, Classes, a class, a student, a student's fees, Payments, Reports, Account, Delete account, Pending changes) | Content scrolls under the status bar with no glass; U24 put it on the AI and scan screens only, the others have no board for it | Session 17 (Task 11's source check) |
| U33 | 2026-10-09 | Toasts across the app | iOS has no toast: keep the bottom bar only where it carries Undo (as Mail's Undo Send); a confirmation shows in place, a failure that needs a decision is an alert, a list that could not load says so inline with Try Again, camera access and a gone item are alerts | The owner, 2026-10-09 ("remain as Apple native as possible"); boards first |

## Done

| # | Done | Pull request | What changed |
|---|---|---|---|
| U31 | 2026-10-09 | #85 | Home's phone is 240 × 520 at 360 px and below, inside the gutters |
| U7 | 2026-10-09 | #79 | Edit event keeps its fields and the note's well whole with the keyboard up; Delete event scrolls under the keyboard (P8-Event-Edit-Keyboard) |
| U16 | 2026-10-09 | #80 | A toast lifts above any footer on screen (D49); Suggested marks drops its AI line once saved, as P6-Check-Saved |
| U24 | 2026-10-09 | #80 | The pushed AI and scan screens draw the glass under the status bar once they scroll (P8-Scan-List-Scrolled, P8-Check-Marks-Scrolled) |
| U1 | 2026-10-08 | #42 | Today, Students, Attendance and More draw the system's glass under the status bar once their content scrolls (`statusBarGlass()`) |
| U6 | 2026-10-09 | #72 | Add on Today's Tasks scrolls the field and its chips above the keyboard (the owner, on build 10) |
| U9 | 2026-10-09 | #70 | Every sheet with a field puts the keyboard away before it writes, so a failure toast is seen (Phase 7 hardening) |
| U2 | 2026-10-08 | #42 | Today live: "Start here" shows only for an empty register |
| U3 | 2026-10-08 | #42 | Today's section lists the day's classes and events, so it agrees with the "Classes today" tile |
| U4 | 2026-10-08 | #42 | The three tiles share the row's height |
| U12 | 2026-10-08 | #47 | The Fees tab is live; the later card and its stale line are gone |

## Dropped

| # | Dropped | Why |
|---|---|---|
