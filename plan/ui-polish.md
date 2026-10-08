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
| U1 | 2026-10-08 | Today | The content scrolls under the status bar | The owner, after installing a build (session 6) |
| U2 | 2026-10-08 | Today | The "Start here: Add your first students" card still shows with 10 students in the register; it is Phase 2's fixed content (`phase-02-plan.md`, Today); Phase 4 makes Today live and may settle it | Session 7's hand run (`plan/sessions/007/record.md`) |
| U3 | 2026-10-08 | Today | The Today section says "No classes yet" while the tile beside it says "1 Classes today"; also Phase 2's fixed content; Phase 4 may settle it | Session 7's hand run |

## Done

| # | Done | Pull request | What changed |
|---|---|---|---|

## Dropped

| # | Dropped | Why |
|---|---|---|
