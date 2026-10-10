# Session 21 (2026-10-10): the Phase 10 boards (Part A)

Model: Claude Fable 5.1 (D17), from `resume/019-phase-10-boards.md`. Outcome: Part A of Phase 10 done: the seven steps of
`plan/phase-10-plan.md` drawn, each approved by the owner and mirrored; 96 boards in rows 14 to 20 of the canvas;
`docs/design/` extended for every step; `resume/020-phase-10-build.md` for Part B on Opus. Documents only, to `main`.

## What was done, in order

1. Read the rules, the state, the decisions (D1 to D65), the polish list, the V2 spec, the research note, the Phase 10 scope and
   plan, the design documents, the records of sessions 20 and 14, the V1 boards the V2 screens extend. Reality matched `STATE.md`
   (`main` clean, nothing open); `bun check` green from its cache.
2. Copied the Phase 7 generator (session 14's `gen14/`) from an old scratchpad into this session's, and extended it: a Phase 10
   parts file over the Phase 7 library (new icons, the five-tab bar, the glass edge, the footer band, the empty card with
   buttons), a second parts file (tracking status, the student row, forms in a sheet, tiles and chip rows, the wheel popover,
   choice rows, the student page's header and cards, skill rows and state marks, chapter rows, the trend bars, the ladder, the
   check row with Right | Wrong, the message sheet, the creating card), one `stepN.py` per step, a renderer that takes a step
   module and a per-board size, a contact-sheet script, and an audit (every tag closed, no broken declaration, no raw colour
   outside the token block, no exclamation mark or emoji, no "children", no technical word, the ground pixel under no overlay).
   Every board was rendered by headless Chrome in both appearances where the board has both and looked at before it was sent.
3. Step by step, one message per step with its sheets and the decisions taken, each answered by the owner before the next:
   10.1 the shell (7), 10.2 Students (23), 10.3 Today (14), 10.4 the artefacts (19), 10.5 School (13), 10.6 Parents (11),
   10.7 Make and the Kit (9). On each approval: `Artifact read` of the canvas, the row published (the index with its `boards`,
   `order` and a `title1` note 300 above; the sources), the sources and the index mirrored into `docs/design/mockups/` and
   `directions/canvas.json`, the step's list, launch states and what the boards settle appended to
   `information-architecture.md`, its parts and texts to `components.md`, its numbers to `design-tokens.md`, the step ticked in
   the plan and the README's status table, `STATE.md` updated, committed to `main` (D12) and pushed.
4. After 10.2 the owner was told Part B may start on Opus; `resume/020-phase-10-build.md` was written from the plan's Part B and
   indexed (with 019, which had not been indexed).
5. The owner's two rulings mid-way: "Batch everywhere" for V1's class on screen (at 10.2; the three 10.1 boards redrawn and the
   10.1 text corrected) and the WhatsApp consent ask made optional (after 10.3's sheets; three 10.2 boards redrawn, the texts
   updated, committed on its own).
6. The phase file's "As built, Part A", the README's phase row, `STATE.md`, this record and the owner's messages; committed.

## The owner's words, kept

- "Approved" (10.1); "Approved, Batch everywhere" (10.2); "approved" (10.3); "Approved" (10.4); "Approved." (10.5); "Approved"
  (10.6); "Approved" (10.7).
- "I see some screens where whatsapp message is being sent to parent for censent about Ai usage - make taht optional. possible?"

## Why things are as they are

- **Batch, not class, for V1's group on screen.** The student form's "Class" is the student's class (LKG to 10), the tutors' own
  word; the spec already called V1's class a batch; two things called Class on one form would confuse. The table is not renamed
  (D56). The 10.1 boards had kept "Classes" and were redrawn once the owner ruled.
- **The WhatsApp consent ask is optional.** D62 asks for recorded consent (the day, the number); it does not say how the parent
  agreed. Many parents agree in person or on a call; the record now keeps how. The message stays as one way to ask.
- **Consent is a section, never a gate** (spec section 2): only the student's own notes, marking and messages wait for it;
  sheets, sets and checks never do.
- **The plan lives on Today under the batch hero**, not on a pushed screen, so V1's sections stay around it and the close is one
  tap from the hero (Start class replaces Mark attendance; the close writes attendance).
- **Changing the plan is where it appears:** a long press on a line for the common cases; a sheet only for the group count, the
  subjects and the weekly pattern. Nothing changed holds past the day unless kept.
- **The check row** (the question, the expected answer, Right | Wrong) is one control for the close, the placement and the Kit.
- **Figures are drawn with tokens from typed specs** (D59): the seven templates were drawn as inline SVG with token colours so the
  Kit can hold the validators' previews; the caption on each says what the app checked.
- **Make it again is a reason, not a prompt:** easier, harder, shorter, more sums, different numbers, or a sentence; the old
  artefact stays until the new one lands (Phase 6's pattern).
- **Own material takes the made one's place** in the plan and the record (spec section 2, hand-made treated the same); the made one
  stays behind a quiet action.
- **School items are for a school's class** when the message names one, so one forward serves every student there; a photo is
  read the same way; nothing is kept before Add.
- **Ask parents to forward is one chat at a time** because a WhatsApp link opens one chat; the screen keeps Sent marks.
- **A held message is explained where it is seen** with the week's three listed and Send it now; the tutor's own sends never count
  (D61).
- **Not on track's next step is the plan's unless changed;** "tell the parent" is a choice the tutor makes, never sent on its own.
- **Make something keeps V1's four kinds** under "For you"; Progress joins Reports as a third segment with Month | Term, the term
  being the school's.
- **Each step's documents were written on approval, not at the end,** so a Part B session starting mid-way reads a complete
  `information-architecture.md` for the steps approved so far.

## Tried and dropped

- A status chip on the student row (it crowded the fee column): the status word leads the row's line instead.
- "Not on track" twice on Today's line (the note and the status word): the note reads "Since Fri 9 Oct · tell Ramesh after the
  class".
- The Kit board at 1780 high (it cut the board view type): 2020.
- A `Use my own` label in the 40-wide nav column (clipped): a nav row with a wide trailing action (`nav_row_wide`).
- The number line's last label and the food chain's longest name off their frames; the cell's rightmost label cut: the figures
  were shifted and the long name set smaller.

## Machine

As session 14: Google Chrome at `/Applications/Google Chrome.app/Contents/MacOS/Google Chrome` headless at 393 × 852 (the Kit at
393 × 2020) and 2×, Python 3.11 with Pillow for the sheets. The generator (`gen/lib.py`, `lib10.py`, `parts2.py`, `step1.py` to
`step7.py`, `render.py`, `audit.py`, `sheets.py`), the renders and the sheets live in the session's scratchpad; the canvas and
`docs/design/mockups/` hold the real copies.

## Next

Part B on Opus 5.5 from `resume/020-phase-10-build.md` (it may be running); its Task 10 writes `resume/021-phase-11-boards-and-plan.md`.
Phase 9 carries on alongside from `resume/018-phase-9-run.md`.
