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
| U6 | 2026-10-08 | Today, adding a task | With the keyboard up the add field sits just above it and its chips are hidden until the card is scrolled | Session 9's hand run (issue #43) |
| U7 | 2026-10-08 | Edit event | With the keyboard up, Delete event rides just above it and the note's well is clipped | Session 9's hand run |
| U8 | 2026-10-08 | Date pickers in a popover | Picking the day the calendar already shows leaves the popover open (tap outside to close); the system calendar starts the week on Sunday where the app's month starts on Monday | Session 9's hand run |
| U9 | 2026-10-08 | Sheets with a field | A failure toast draws at the sheet's bottom, behind the keyboard while it is up (Phase 3's sheets too) | Session 9's follow-up hand run |
| U10 | 2026-10-08 | Attendance mark | A slow or failing read shows nothing for up to 20 s (no spinner by the date), and "Everyone starts present…" stays beside the error line | Session 9's follow-up hand run |
| U11 | 2026-10-08 | today-adding-task | The launch state cannot scroll Coming up to the top as P4-Today-AddingTask draws (the board's room is the keyboard's) | Session 9, comparing with the board |
| U12 | 2026-10-08 | Fees tab | The later card still says "This build has sign-in, your profile, Today and the register." | Session 9 |

## Done

| # | Done | Pull request | What changed |
|---|---|---|---|
| U1 | 2026-10-08 | #42 | Today, Students, Attendance and More draw the system's glass under the status bar once their content scrolls (`statusBarGlass()`) |
| U2 | 2026-10-08 | #42 | Today live: "Start here" shows only for an empty register |
| U3 | 2026-10-08 | #42 | Today's section lists the day's classes and events, so it agrees with the "Classes today" tile |
| U4 | 2026-10-08 | #42 | The three tiles share the row's height |

## Dropped

| # | Dropped | Why |
|---|---|---|
