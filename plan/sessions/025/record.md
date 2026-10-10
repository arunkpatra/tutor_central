# Session 25 (2026-10-10): Phase 12's plan

Model: Claude Fable 5.1 (D17), from `resume/023-phase-12-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-12-plan.md` (25 tasks, nine pull requests, tests first, the launch states, the hand runs, the cost run, the
review focus, the 24 decisions it takes), the two Phase 12 boards on row 21 of the canvas (P12-Close-Cards dark and
light, P12-Pending-Close) mirrored into `docs/design/` and awaiting the owner's approval, `plan/resume/024-phase-12-build.md`
indexed, `STATE.md`, this record. Documents only, to `main` (D12). No code.

## What was done, in order

1. Read the rules, the state, the decisions (D1 to D66), the polish list, the V2 spec's sections 4 to 7 and 9, the
   Phase 12 scope, Phase 11's "As built", Phase 10's Part B "As built", the 10.3 and 10.4 notes in
   `information-architecture.md`, the parts and texts in `components.md`, the numbers in `design-tokens.md`,
   `feedback.md`, the records of sessions 23 and 24 with the ledger, migrations 0010, 0013 and 0017, the API's routes,
   schemas, models, fake and tests, Domain's record rules and figure specs, Today's store, hero and close, Data's AI
   client, repositories, cache and refresh, the shell's routes, fixtures and launch states, the reminders, the Phase 11
   plan for the house style, and the price sheet (the `claude-api` skill: Haiku 5.5 $0.10 and $0.50, Sonnet 5.5 $2 and
   $10, Opus 5.5 $4 and $20 per million tokens). Reality matched `STATE.md` (`main` at fc47196, nothing open).
2. Wrote the plan: the header, the global constraints, 24 decisions, eight review-focus lines each pinned to a test,
   the file structure by module, the launch states with their boards and pull requests, the nine pull requests, Tasks 1
   to 25 with the tests written out (the migration's SQL in full; the API's schemas, prompts, routes and fake; Domain's
   types, rules and budget with the price sheet; Data's repositories, cache, photos and client; the Today, Artefacts and
   close screens by their Kit parts and the boards' texts; the hand runs and the cost query; the documents), the
   self-review.
3. Drew the two boards the owner's polish rows need (U37, U38, U39): the close card's three states on the no-plan path
   and the waiting close's row, in the approved boards' style, checked with headless Chrome, published to row 21 of the
   canvas, mirrored into `docs/design/mockups/`, `directions/canvas.json`, `information-architecture.md` ("Phase 12
   boards"), `components.md` ("Phase 12 parts") and the README's status.
4. Wrote resume 024 and indexed it; updated `STATE.md`; this record and the owner's messages.

## Why things are as they are

- **The plan is made on the phone** (decision 1): spec section 6 puts the rules in Domain and D60 says the app makes
  the plan; nothing in a plan needs Claude but a first topic for a group whose record names no skill, so `/ai/plan`
  does that and nothing else. The spec's "reads the record as the user" is kept as the app's read: the API still reads no
  table but `ai_generations`, as each V2 route does.
- **Checks move to the plan per group** (decision 5): spec 6.5 makes the checks per group with personal ones only for a
  revisit, which is also what keeps a twelve-student batch at three groups' cost; the budget caps personal checks at four.
- **A new feature target for the artefact screens** (decision 11): a sheet is opened from Today's lines and from a
  student's homework rows; features never import each other, so neither may hold it.
- **Offline with no plan shows no plan section** (decision 14): a made-up offline plan would persist; Phase 11's Today
  has a board, the close works without a plan (D57), and the plan comes at the next online open.
- **The class reminder becomes the plan's** (decision 16): one reminder per batch, the scope's "an hour before" as the
  lead's default; a second reminder would double the notifications for the same batch.
- **The card states are boards, not closed rows** (decision 19): U38's wait stays on the no-plan path, so the owner's
  "close the row if no wait remains, else design it" lands on design.
- **The cost run spends real money** (decision 22): the fake's tokens are fixed, so only the real API measures; the
  owner is told before it runs.

## Tried and dropped

- Making the whole plan through `/ai/plan` on Sonnet: the rules are deterministic and Domain's, and a call per batch per
  day would be cost for nothing (D64 wants the margin).
- A second reminder for the plan beside the class reminder: two notifications for one batch.
- The card-states board with the batch head and intro: the third card fell under the footer; the board is a scrolled
  state, as P10-Close-Scrolled is.

## Machine

Reading only; `bun check` from its cache. No simulator run. Headless Chrome for the boards.

## Next

The owner approved the plan and the two boards the same day ("The plan is approved; the boards are approved too").
Phase 12's build on Opus 5.5 from `resume/024-phase-12-build.md`.
