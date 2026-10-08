# Session 12 (2026-10-08 to 09): the Phase 6 boards and the Phase 6 plan

Model: Claude Fable 5.1 (D17), from `resume/011-phase-6-boards-and-plan.md`. Outcome: Phase 0 step 0.7 done (44 boards in
row 9 of the canvas, approved), mirrored into `docs/design/`; `plan/phase-06-plan.md` written with
`superpowers:writing-plans` and approved; `resume/012-phase-6-build.md` for the Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, state, decisions, the Phase 6 scope, the Phase 0 plan, Phase 5's "As built", the design documents,
   the inventory's AI rows, the spec's section 6, the records of sessions 10 and 11, the seed and migration 0001, the
   API's routes and schemas, the shell's wiring and the Phase 5 code the plan would reuse (the stores, the fakes, the
   DesignSystem surface, the camera). Loaded the `claude-api` skill before any model choice. Reality matched `STATE.md`;
   the local stack up.
2. Drew the 44 boards with one Python generator (a parts library of the Ember tokens: the shell, nav rows, cards, rows,
   fields, tile pickers, segmented controls, sheets, dialogs, the system alert, toasts, skeletons, drawn pages; light
   twins by token-block substitution) and looked at every one rendered by headless Chrome before publishing: the
   Assistant (dark, light, empty), the four forms, the student picker, creating, a failure, the paper result (dark,
   light), creating again, the note result, Send the note, History (full, empty), Scan register (intro, consent, the
   camera ask, refused, the document camera, Photos, reading, the list, Fix this row, a row removed, leaving, nothing
   found, failed, added), Check a paper (intro, pages, the scheme from a paper and typed, checking, the marks, the mark
   picker, edited, saved, failed), More (dark, light), Today's Create row. Seven fixes before showing (a counter over
   its text, a wrapping WhatsApp button, the camera's outline, a toast over a footer, a popover on a hidden row, Share
   into the nav row, Today's scroll offset). Checked every style attribute for a missing semicolon (Phase 5's money
   pair) and counted the exact token colours in the renders. Published as row 9 (y 11800, a title note at 11500).
3. The owner approved the set. Mirrored the sources and the index into `docs/design/`, extended `components.md` ("Phase
   6 parts" and the texts: the AI lines, the consent, the notices, the note's message, the note on a student),
   `information-architecture.md` (the More tab's row, the 38 launch states, the board table, what the boards settle),
   `design-tokens.md` ("Numbers in code": the limits, the downscale, the daily limits, the notes append, the undos),
   ticked 0.7, committed to `main` (D12).
4. Took the local stack's real answers for every Phase 6 read and write with curl as the seed's tutor (an
   `ai_generations` insert and a failed one, the history read, the consent update and read, a bulk insert of two
   students and their delete, a notes update and its undo, a `progress` log), then cleaned the rows, so the plan's
   decoding fixtures are real. Checked the SDK's version (0.132.1, zod 4 accepted), the vision limits (10 MB an image,
   2576 px on the long edge) and Vercel's function duration (Hobby: 300 s).
5. Wrote `plan/phase-06-plan.md`: 20 tasks, 6 pull requests, two migrations with RLS tests, the API with a fake Claude
   and a fake database client, Domain and Data tests first with the pasted answers and the Swift write proofs, the
   DesignSystem parts, the stores with their tests (the timing rules of session 11 written in), the screens as pieces,
   the launch states, the two simulator write proofs, the hand runs as a table that says which runs cost money, the
   owner's steps in order, a Review Focus of five, a decisions table (D35, D36), a self-review (three fixes: a
   force-unwrap in a test, the consent sheet shared through DesignSystem, the blank sample for the nothing-found run).
   The owner approved the plan.
6. Wrote `resume/012-phase-6-build.md`, indexed it, updated `STATE.md`, `README.md`, the phase file, this record and
   the owner's messages; committed to `main`.

## Why things are as they are

- **Downscale on the device, no Storage.** The API accepts 10 MB an image but Vercel's body is 4.5 MB; a photo
  reduced to 2000 px on its long edge as a JPEG at 0.7 is 350 to 900 KB, so six pages fit, and the high-resolution tier
  (2576 px) reads it whole. Storage would add a bucket, policies, a cleanup job and a round trip for a photo nobody wants
  kept; children's data is never stored.
- **The consent gates a child's data, not a paper.** Scan register, Check a paper and the progress note send a child's
  name and details; a paper, homework or worksheet sends a topic. `start_ai_generation` is the gate the app cannot skip;
  the sheet is the same one over the note form, the scan intro and the check intro (DesignSystem's `ConsentSheet`, since
  Students and AITools cannot share a view otherwise).
- **One function for membership, consent, the limit and the record.** `ai_generations` from 0001 holds every call; a
  `pending` status (its own migration, since a new enum value cannot be used in the transaction that adds it) marks a
  call that started; the limits are abuse limits in the function (40 generations, 20 scans, 20 checks a day; failures do
  not count), not a plan (D4).
- **The API as the user.** Every database call carries the tutor's JWT, so RLS decides; the API never holds the
  service-role key (rule 5). The API's deploy needs the key at boot like the Supabase variables, so a deployment
  without it fails its smoke loudly; `AI_FAKE=1` answers from the fake locally.
- **Sonnet 5.5 for generation, Opus 5.5 for reading photos** (the scope's choice), adaptive thinking with the effort
  set, structured outputs by zod; no `fallbacks` (these prompts do not touch the categories that refuse; a refusal is a
  422 in words).
- **The call outlives the screen.** A tutor who taps Create and goes to the next class should find the paper in
  History; `AIStore` is one per centre on `ShellState`, the result lands in Recent and History, and the result route is
  pushed only when the form is still on top. One call at a time keeps the cost and the state simple.
- **Scan register lives in Students (D36).** It creates students, its entry is the Students "+" menu, and Fix this
  row is the student form, which only Students holds (rule 4). Check a paper and the Assistant are AITools.
- **Every Undo restores exactly:** Add N students deletes those ids; a saved check writes the previous notes back
  (nil stays nil); a removed row returns to its place. Session 11's waived-fee lesson.
- **The forms are pushed screens, not sheets.** A generation's result is pushed on top; a sheet would have to close
  and push; the footer button never needs a scroll.
- **The camera pieces shared in DesignSystem.** `CameraAccess` (from Fees) and the document camera serve Fees' QR,
  Scan register and Check a paper; a third copy would have followed the Phase 4 and 5 message sheets (which now have a
  DesignSystem `MessageSheet` for the note; adopting it in Attendance and Fees is a deferred minor).
- **The paper's answer key is the check's scheme.** The generation carries answers; "A paper I created" sends the id
  and the API builds the scheme text from the stored output as the user.
- **The hand runs say what costs money.** Five real calls (about $0.60); everything else on the local fake with the
  consent, limit and record paths real.
- **Boards by generator, checked by headless Chrome, as sessions 8 and 10**; the money-pair lesson became a style
  audit (no declaration with two `name:` parts) and an exact-colour count on the renders.

## Tried and dropped

- Supabase Storage for the pages (a bucket, policies, cleanup; the downscale fits).
- A `ConsentSheet` in AITools (Students cannot import it); a `CameraAccess` with the AVFoundation status mapped in
  each feature (three mappings; the enum moved whole with its import and the reason in the file).
- Forms as floating sheets (the result would have to close the sheet first).
- Scan register in AITools (no student form there).
- A migration adding a `pending` value and the function in one file (the enum value cannot be used in its own
  transaction).

## Machine

As sessions 8 and 10: Xcode 27, the iPhone 17 simulator, bun, Docker with the local stack, Google Chrome 155 headless
for the renders, Python 3.11 with Pillow for the contact sheets. The generator (`gen/lib.py`, `gen/boards.py`), the
renders and the contact sheets live in the session's scratchpad; the canvas and `docs/design/mockups/` hold the real
copies.

## Next

The build in a fresh Opus 5.5 session from `resume/012-phase-6-build.md`. Then Phase 0 step 0.8 (the Phase 7 boards)
on Fable.
