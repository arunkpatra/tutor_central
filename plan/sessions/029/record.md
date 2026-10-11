# Session 29 (2026-10-11): Phase 14's plan

Model: Claude Fable 5.1 (D17), from `resume/027-phase-14-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-14-plan.md` (24 tasks, thirteen pull requests, tests first, the launch states, the hand runs, the cost run, the
review focus, 30 decisions, D67 and D68 as tasks), seven Phase 14 boards drawn on row 24 of the canvas and mirrored into
`docs/design/` awaiting the owner's approval, `plan/resume/028-phase-14-build.md` indexed, `STATE.md`, this record.
Documents only, to `main` (D12). No code.

## What was done, in order

1. Read the rules, the state, the decisions (D1 to D68), the polish list, the pushback rule, the V2 spec, the Phase 14
   scope, Phase 13's and Phase 11's "As built", the 10.6 and 10.3 notes in `information-architecture.md`, the parts and texts
   in `components.md`, the numbers in `design-tokens.md`, `feedback.md`, the boards' own words (extracted from the
   mockups), the records and ledger of sessions 27 and 28, and the code the phase builds on: the cadence, the messages, the
   message log, To parents, the tracking rules, the student page, Check a paper's preset and marks, the API's routes,
   schemas, prompts, fake, models, auth, entry and tests, the price sheet, the migrations' enums and functions, the plan's
   rules and cards, the fixtures and launch states, Phase 13's plan for the house style. Reality matched `STATE.md` (`main`
   at 2da76bb, nothing open).
2. Wrote the plan: the header, the global constraints, 30 decisions with three things named as not this phase's, nine
   review-focus lines each pinned to a test, the file structure by module, the launch states with their boards and pull
   requests, the thirteen pull requests, Tasks 1 to 24 with the tests written out (the two migrations' SQL in full; the
   model table and its overrides; the API's schemas, prompts, routes and fake; Domain's note day, facts, cadence decision,
   next step, signature and message; Data's repositories, cache and client; the Today, Artefacts, Students and School
   screens by their Kit parts and the boards' texts; the hand runs and the cost run; the documents), the self-review.
3. Drew the seven boards no earlier step drew (marks from a photo: the reading, the marks to check in both appearances, a
   mark's sheet; U41's paste well; U42's filtered tab; U43's window row) from the approved boards' own markup, checked with
   headless Chrome, published to row 24 of the canvas (note `p14_1`), mirrored into `docs/design/mockups/`,
   `directions/canvas.json`, `information-architecture.md` ("Phase 14 boards"), `components.md` ("Phase 14 parts") and the
   README's status.
4. Wrote resume 028 and indexed it; updated `STATE.md`, `plan/README.md`'s Phase 14 row and the scope file's status; this
   record and the owner's messages.

## Why things are as they are

- **The note is a kept artefact** (decision 1): a note made once per week survives a relaunch and a re-read costs nothing;
  Write again keeps its predecessor as a regenerate does; the sent log can read "not opened yet" for a note kept with no
  log row, which a log-on-open design could not show.
- **The note day and the next step live on the batch and the student** (decisions 4 and 9): two nullable columns and one,
  additive (D26); null reads as the default so nothing is configured (D57).
- **Two migrations** (decision 27): an enum value cannot be used in the transaction that adds it; 0012 and 0013 were split
  for the same reason.
- **A `not_on_track` message kind of its own** (decision 10): the sent log's board titles it "Not on track", which a `note`
  row with a flag could not do without a column; an enum value is additive.
- **The homework share is not logged** (decision 8): the system share sheet tells the app nothing of who received the PDF;
  logging it as a message to the parent would be a false claim. Spec 8's share is met by Phase 12's Share as PDF.
- **"Write a note" on the page is not built** (decision 19): no board draws it on P10-Student-Record; a polish row.
- **D67 as one JSON file** (decision 13): the API, the Swift price sheet and the cost tool read the same bytes; the TS module
  imports it with an import attribute, with a named fallback if Vercel's build refuses it.
- **A 503 for a lost connection** (decision 14): the app already has connection words for `.offline`; a 503 maps to them,
  and a status the app does not know maps to the service words, so a stale API's 501 never reaches the screen.
- **The trust page and per-student export are not this phase's** (left for later): the spec puts the trust page in the
  phase that first sends a student's data to testers (Phase 15); export has no scope line and no board. Named for the
  owner to rule otherwise.
- **The read-marks model is set by the cost run** (decision 26): the owner asked for the measurement; Sonnet stands until
  it, and the figures go into PR 13's description.

## Tried and dropped

- A `held_messages` table for a held note: a kept artefact with no log row that week says the same, with no new table,
  policy or test.
- `message_log.opened_at` made nullable for an unsent note: it breaks the V1 column's meaning; the artefact carries the
  made-but-unsent state.
- A homework share logged from the sheet's Share as PDF: the recipient is unknown (decision 8).
- Holding the model table in TypeScript alone: the price sheet (Swift) and the cost tool would each carry a copy.

## Machine

Reading only; headless Chrome for the boards; no `bun check` run (no code changed); no simulator run.

## Next

The owner's word on the plan and the seven boards; the build on Opus 5.5 from `resume/028-phase-14-build.md`.
