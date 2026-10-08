# Session 8 (2026-10-08): the Phase 4 boards and the Phase 4 plan

Model: Claude Fable 5.1 (D17), from `resume/007-phase-4-boards-and-plan.md`. Outcome: Phase 0 step 0.5 done (27 boards in
row 7 of the canvas, approved, with U1 added and two numbers corrected), mirrored into `docs/design/`;
`plan/phase-04-plan.md` written with `superpowers:writing-plans` and approved; `resume/008-phase-4-build.md` for the
Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, state, decisions, the Phase 4 scope, the Phase 0 plan, Phase 3's "As built", the design documents,
   the inventory, the spec, the records of sessions 5 to 7, the seed and migration 0001, the Today, Students and
   Data code, the Kit's attendance, calendar, checkbox and progress components. Reality matched `STATE.md`; `bun check`
   green; the local stack up.
2. Drew the 27 boards with one Python generator (shared pieces for the shell, rows, cards, the calendar, sheets and
   dialogs; light twins and the Kit's rows by substitution) and looked at every one rendered by headless Chrome
   before publishing: Today live (a class soon dark and light, the evening, a day with no class, adding a task),
   attendance (fresh dark and light, the class menu, one absent, saved, the absence alert, a past date, empty),
   history (by date, by student, one student, empty, the student detail's section live), More (dark and light),
   schedule (the month, a day, new event, edit event, delete confirmation), tasks (list, empty). Published to the
   canvas as row 7 (y 9000, a title note at 8700).
3. Two fixes before showing: the attendance row's two 96 pt toggles made half the seed's names wrap, so the row became
   one state pill with the whole row toggling (the Kit's two surfaces boards redrawn to match); the Save footer sat
   over rows, so it sits on a ground band the list scrolls under.
4. The owner approved the set and took U1 into the phase; the scrolled Today board gained the status bar on the
   system's glass. Mirrored the sources, the index and the Kit boards into `docs/design/`, extended `components.md`
   (the attendance pill, the history, percentage, absent-student, event and later rows, the counts beside a title,
   the footer button on a root, the status bar on a scrolled root, the month header's buttons, the percentage hero,
   the message sheet, the inline add, the relative words) and `information-architecture.md` (the 24 launch states,
   the board table, what the boards settle), ticked 0.5, committed to `main` (D12).
5. The owner reported from build 6 that the "Classes today" tile is taller than the other two: U4 on
   `plan/ui-polish.md`, taken into Phase 4 with U1 to U3.
6. Wrote `plan/phase-04-plan.md`: 20 tasks, 7 pull requests, tests first against the fakes, migration 0004
   `save_attendance` with four RLS tests, every read decoded against the local stack's real answer and every write
   proven in Swift before its PR merges (session 6's lesson), a Review Focus of five, a decisions table, the hand runs
   as a table in Task 20, a self-review. While writing it, the history boards' numbers turned out inconsistent with
   the fixture (Hemanth absent on the 5th and the 7th is 1 of 3, not 2 of 3): corrected both boards and the plan's
   test, committed as documents. The owner approved the plan.
7. Wrote `resume/008-phase-4-build.md`, indexed 007 and 008, updated `STATE.md`, `README.md`, the phase file, this
   record and the owner's messages; committed to `main`.

## Why things are as they are

- **One pill per attendance row, the whole row the toggle:** the Kit's two toggles left 109 pt for a name at 393 pt
  wide and "Bir Bikram Singh", "Hemanth Reddy" and "Lakshmi Menon" wrapped. One 96 pt pill leaves 205 pt; the row's
  tap target is the whole row; the acceptance (two taps all present, three with one absent) holds. The Kit's boards
  were redrawn with the set so the Kit screen keeps matching its board.
- **Save in a footer above the tab bar:** the acceptance's two taps need Save without a scroll on a class of sixty.
  Saved, the footer becomes a mark in `okTint`; a change turns it back into "Save changes".
- **The "class soon" board is an afternoon board at 16:35:** the seed's classes meet at 16:30 and 17:00, and real
  content rules (phase-00-plan.md); the morning board is the Saturday with no class. "Good afternoon, Meera" wraps at
  32 pt, as it will in the app.
- **The More root drawn now:** Schedule and Tasks live under More, which was Phase 2's placeholder; a shell-level
  board (dark and light) with the later rows at the Later opacity and their phase named, as P2-Settings did.
- **"Coming up" is the next seven days, not the calendar week:** on a Saturday the calendar week has nothing left.
- **Events: a 500-character note and a 120-character title; delete without typing:** the column has no note limit, the
  form does; an event carries no history, so the dialog's solid Delete is enough.
- **Tasks fall off Today after 24 hours, stay under More until cleared:** the phase file's "fall off after a day",
  and a list that only ever grows needs Clear.
- **The AI tools row waits for Phase 6's board:** Phase 2's ruling, kept.
- **U1 as one modifier on the four tab roots:** the fix is the shell's, not Today's; the scrolled Today board draws it.
- **U4 as tiles sharing a height:** the boards draw the three tiles at one height; the app's `HStack` let one grow.
- **History numbers follow the fixture:** the saved-7th fixture (needed for the saved and alert boards) makes Hemanth
  1 of 3 in October; the by-student and student-month boards were corrected rather than the plan carrying a note.
- **`save_attendance` as one function:** a save touches two tables; the function upserts the session on the
  nulls-not-distinct unique index, deletes marks not in the list, upserts the rest, `security invoker`.
- **Reads by month:** one read serves history, the student's month, the student detail and Today's ticks; the
  register is shared from `ShellState`, never read twice.

## Tried and dropped

- Viewing the gallery in the built-in browser pane (the pane resized itself mid-check); headless Chrome screenshots of
  each board instead, stitched into one contact sheet for the owner.
- Two 84 pt toggles (a long name still wrapped); first names only (two students may share one).
- A "morning with a class soon" board (no seed class meets before 16:30).

## Machine

As session 7. The generator, the gallery and the renders live in the session's scratchpad; the canvas and
`docs/design/mockups/` hold the real copies.

## Next

The build in a fresh Opus 5.5 session from `resume/008-phase-4-build.md`. Then Phase 0 step 0.6 (the Phase 5 boards)
on Fable.
