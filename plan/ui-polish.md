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
| U13 | 2026-10-08 | Any sheet, then a link | A sheet open on one tab (Reports' Share as CSV) stays up over the tab a `tutorcentral://` link opens | Session 11's hand run (issue #50) |
| U14 | 2026-10-08 | Fees, an empty current month | Before the month is generated, the overdue banner for last month's unpaid fees is not shown (the board draws the empty month without it) | Session 11's final review |
| U15 | 2026-10-08 | Fees, Due or Paid with nothing in it | "Nothing due · Every fee for October is settled." and "Nothing paid yet" are the Kit's empty row in words no board drew | Session 11 (the plan's unboarded filler) |
| U25 | 2026-10-09 | Delete account | With the keyboard up, Delete my account sits under it until the field is put away | Session 15's hand run 5 |
| U27 | 2026-10-09 | Attendance, offline at launch | The day's saved copy is used only after a read fails, so the first 20 s offline show nothing | Session 15's hand run 7 |
| U28 | 2026-10-09 | Fees, Mark paid offline | The receipt sheet is not offered after an offline Mark paid (no log can queue a receipt) | Session 14's plan, seen in session 15 |
| U29 | 2026-10-09 | Students, the "+" menu at the largest text sizes | The system menu cuts "Scan paper register" to "Scan paper regis…" | Session 15's Dynamic Type check |
| U30 | 2026-10-09 | The "Sign in again" status line | It has no way forward but Account → Sign out, which warns the saved changes are lost | The Phase 7 review (minor 7) |
| U48 | 2026-10-12 | Students, the empty card (P10-Students-Empty) | "Create a batch" is the width of its text; the board draws it at full width like the two ways above it | Session 32, U34's pictures |

## Done

| # | Done | Pull request | What changed |
|---|---|---|---|
| U11 | 2026-10-12 | #164 | today-adding-task scrolls Coming up to the top with room below Today's end, as P4-Today-AddingTask draws |
| U17 | 2026-10-12 | #162 | The note's and the typed scheme's counter reads as the boards draw it ("135 / 2000") |
| U18 | 2026-10-12 | #162 | The Send sheet opens under the nav row, as P6-ProgressNote-Send draws |
| U19 | 2026-10-12 | #164 | today-ai scrolls to Create as P6-Today-AITools draws |
| U20 | 2026-10-12 | #162 | Over a note the centre's consent sheet speaks of a note, not a photo (P15-Consent-Note, without "our servers": D41) |
| U21 | 2026-10-12 | #162 | The homework and worksheet failure row reads "Couldn't create it." on one line |
| U22 | 2026-10-12 | #159 | Check a paper's papers carry their time beside the day, so two of one topic are told apart |
| U23 | 2026-10-12 | #159 | With every page removed the heading reads "No pages" and Check is off |
| U26 | 2026-10-12 | #160, #169, #170 | Reports keeps a copy on this iPhone: offline it shows the copy at once with the offline line and its time |
| U32 | 2026-10-12 | #163 | The status bar glass on every pushed screen that scrolls |
| U34 | 2026-10-12 | #164 | The Students empty card stacks Add a student and Scan paper register at full width (P10-Students-Empty) |
| U40 | 2026-10-12 | #163 | The student's page draws the status bar glass when scrolled |
| U36 | 2026-10-11 | #133 | The student's page has Marks after Checks: mocks and checked papers, Below usual, "No marks yet" (P13-Student-Marks, -Empty) |
| U46 | 2026-10-11 | #151 | Can now do in a week no step moved is headed "On the ladder" with "No change this week" (P14-CanNowDo-NoChange) |
| U47 | 2026-10-11 | #150 | The note opens from the copy on this iPhone at once, then the server's; no 20 s of "Writing" on a connection that hangs |
| U41 | 2026-10-11 | #146 | Paste a message waits for the system's Paste button: iOS asks nothing (P14-School-Paste) |
| U42 | 2026-10-11 | #146 | The student page's School See all opens the School tab filtered to the student, with Show all (P14-School-Student) |
| U43 | 2026-10-11 | #146 | A kept exam's sheet has Preparation, 7, 10, 14 or 21 days before (P14-School-Item-Window) |
| U44 | 2026-10-11 | #146 | Who's rows on an item's page carry a chevron and open the student (P10-School-Item) |
| U45 | 2026-10-11 | #137 | The mock names two to six skills across the paper, so By skill groups |
| U35 | 2026-10-11 | #119 | This week's quiet Today, when the student's batch meets today, opens the Today tab at the batch's plan |
| U37 | 2026-10-11 | #118 | The close card's no-book and offline states in the board's words and type (P12-Close-Cards) |
| U38 | 2026-10-11 | #118 | The close card's wait: the eyebrow over a 16 pt ring and "Making the three questions. A second or two." (P12-Close-Cards); the close from a plan never waits |
| U39 | 2026-10-11 | #118 | A waiting close wears the checklist symbol in Pending changes (P12-Pending-Close) |
| U33 | 2026-10-09 | #86 | The toast is for Undo only; a success shows in place, a failed or refused write is the system alert, a field's failure is under it, a list with nothing loaded says so in its place (`docs/design/feedback.md`) |
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
