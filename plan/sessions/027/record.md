# Session 27 (2026-10-11): Phase 13's plan

Model: Claude Fable 5.1 (D17), from `resume/025-phase-13-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-13-plan.md` (28 tasks, ten pull requests, tests first, the launch states, the hand runs, the cost run, the
review focus, the 32 decisions it takes and what it leaves for later), the three Phase 13 boards drawn on row 23 of the
canvas (six files with their light twins) and mirrored into `docs/design/` awaiting the owner's approval,
`plan/resume/026-phase-13-build.md` indexed, `STATE.md`, this record. Documents only, to `main` (D12). No code.

## What was done, in order

1. Read the rules, the state, the decisions (D1 to D66), the polish list, the pushback rule, the V2 spec in full, the
   Phase 13 scope, Phase 12's "As built", Phase 10's Part B "As built", the 10.5, 10.4, 10.2 and 10.3 notes in
   `information-architecture.md`, the parts and texts in `components.md`, the numbers in `design-tokens.md`,
   `feedback.md`, the records of sessions 25 and 26 with the ledger, migrations 0009 to 0013 and 0019, the API's routes,
   schemas, models, fake, db and tests, Domain's plan rules, budget and artefacts, Today's maker and store, Data's AI
   client and repositories, the share extension and the inbox, the shell's routes, fixtures and launch states, the
   boards' own words (extracted from the mockups), the Phase 12 plan for the house style. Reality matched `STATE.md`
   (`main` at 69b5955, nothing open); `bun check` green from its cache.
2. Answered the owner's question on the four items Phase 12 left open: the unnamed group and the first checks in (one
   pull request after the School work), two of the ten minors folded into the tasks that touch their files (a check's
   skill matched by name first; the 200-character line cut), the rest deferred; the student link already fixed in #121.
   The owner: "Agreed. proceed".
3. Wrote the plan: the header, the global constraints, 32 decisions with five things left for later and their reasons,
   eight review-focus lines each pinned to a test, the file structure by module, the launch states with their boards and
   pull requests, the ten pull requests, Tasks 1 to 28 with the tests written out (the migration's SQL in full; the API's
   schemas, prompts, routes and fake; Domain's items, the split, the pattern, the exam groups and revision lines, the
   cadence and messages, marks and the contents; Data's repositories, cache, inbox and client; the School, Today,
   Artefacts, AITools and Students screens by their Kit parts and the boards' texts; the hand runs and the cost query;
   the documents), the self-review.
4. Drew the three boards no earlier step drew, from the approved boards' own markup (the confirm screen with the
   textbook's creating card; Today's plan with Group 1 as the exam group; the student page scrolled to Marks without
   Add from a photo, and the empty row), checked with headless Chrome, published to row 23 of the canvas (note
   `p13_1`), mirrored into `docs/design/mockups/`, `directions/canvas.json`, `information-architecture.md` ("Phase 13
   boards"), `components.md` ("Phase 13 parts") and the README's status; U36's row says which board it needs now.
5. Wrote resume 026 and indexed it; updated `STATE.md`; this record and the owner's messages.

## Why things are as they are

- **Items are kept only after Add, and a draft with no date or no one to be for stays unticked** (decisions 1, 2): the
  boards' "Nothing is kept until you tap Add", and `school_items.date` is not null; the parser answers a null date rather
  than a guess, so the tutor sets it on the sheet.
- **Who an item is for has three shapes** (decision 2): the Confirm board's "Vidya Niketan, every class" is a school with
  no class, which 0011 already allows (`class_level` nullable); a class no student is in keeps its item for a student who
  joins later.
- **The source is "Shared", not "from WhatsApp"** (decision 3): a share extension sees no sender app; the board's words are
  illustrative and a false claim would be a bug.
- **Exam students form their own group** (decision 10): spec 6.6 turns "that subject's lines" to revision and the group's
  set, sheet and checks are made per group, so a mixed group would give revision students a level set; the cap of two
  exam groups keeps a level group for the rest.
- **The mock is made once per exam and shared** (decision 11): it carries no student's data (D62) and a class of three
  costs one Sonnet call; marking and the gap report are per student and need consent.
- **The mock's key reaches check-paper through the generation's output** (decision 13): `ai_generations` is the one table
  the API reads (Phase 12's rule); the skeleton's `artefactId` was never sent by any build.
- **The English Test tomorrow is a template on the phone** (decision 19): no student data leaves the phone, so no consent
  gate and no call; the other languages need the model and the gate.
- **The window stays 14 days and the school's earlier papers wait** (decisions 8, 12): neither has a field or a store on
  an approved board; each is written down as left for later rather than built without one.
- **U36's board**: P10-Student-Record already draws Marks (approved at 10.2) with Phase 14's Add from a photo, so the new
  board draws only what this phase builds differently (no action, the mock's row, the empty row), not a second design.
- **Two more boards than the resume named**: the reading state and Today's exam group are states no 10.5 or 10.3 board
  drew, and rule 1 wants them approved before PRs 5 and 7 build them.

## Tried and dropped

- A `revise` and a `mock` kind in `plan_item_kind`: the close's checklist, the artefact links and the copies all key on
  the four line kinds; the revision lines keep the kinds and change the words.
- Reading the inbox in the extension's own UI: the extension draws nothing (Phase 10), and the app's "Check what was
  read" is the approved screen.
- A `plans` column for a stale plan when an item changes: the AppShell closure that remakes an open plan is one call
  and keeps the maker the one writer.

## Machine

Reading only; `bun check` green from its cache (web ran, 3.6 s). No simulator run. Headless Chrome for the boards.

## Next

The owner approved the plan and the three boards the same day ("The plan is approved; the boards are approved too").
Phase 13's build on Opus 5.5 from `resume/026-phase-13-build.md`.
