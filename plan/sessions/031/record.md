# Session 31 (2026-10-11): Phase 15's plan

Model: Claude Fable 5.1 (D17), from `resume/029-phase-15-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-15-plan.md` (23 tasks, twelve pull requests plus fixes, tests first, 30 decisions, ten review-focus lines, the
file structure, the launch states, the fifteen hand runs, the cost run, the round's set-up, weeks and triage), `plan/resume/
030-phase-15-build.md` indexed, `STATE.md`, this record. Documents only, to `main` (D12). No code, no board drawn.

## What was done, in order

1. Read the rules (the four CLAUDE files), the state, the sessions' rules, the decisions D1 to D68, the polish list, the
   pushback rule, the V2 spec, the Phase 15 and 16 scope files, Phase 12's, 13's and 14's "As built", Phase 9's plan and the
   V1 guide, the device tests, the 10.7 boards' words (extracted from the mockups), the IA's 10.7 and As built notes, the
   components' 10.7 parts, the numbers in code, `feedback.md`, the release checklist, the Phase 9 findings skeleton, sessions
   29 and 30 (the record and the ledger's rulings), and the code the phase builds on: AITools (the store, the forms by class,
   Check a paper's store, intro and scheme screens, the preset), the Artefacts stores (sheet, note's make, mock), the plan's
   calls and budget (a group's level is its highest member's), More's rows, the launch states and fixtures, Reports, the
   repositories (AI, plans, record, textbooks, attendance, schools, history), the note reader, the tracking rules, the
   Domain shapes (artefact, skill, check, mark, school item, scheme source, figure spec, term-less `Period`), the API's V2
   routes, schemas, the note's prompt and `run`, `models.json`, `bun cost`, migrations 0009 to 0025 (`keep_artefact`'s
   signature), the seed, the Kit, the website's layout and rules. Reality matched `STATE.md` (`main` at b3347a2, nothing open).
2. Wrote the plan: the header, the global constraints, the 30 decisions with the two owner's questions carried as proposals,
   the review focus, the file structure by module, the launch states, the pull requests, the calendar, Tasks 1 to 23 (the
   rename; migration 0026 in full with the seed's checks; the API's `tutorSays`; Domain's kinds, target, rules and `Term`;
   `ProgressRules` and the CSV; Data's reads and writes; Make's home; the forms with the For sheet; Check a paper under Make
   with U22 and U23; Reports' Progress with U26; the Kit; the polish rows; the trust page after its board; the hand runs;
   the cost run; the deploys, review and TestFlight; the build's documents; the round's notes and checklist; the V2 guide
   written out and the findings file; the owner's App Store Connect steps and the tester's checks; the readings, fixes and
   builds; the close; the round's documents), the self-review.
3. Wrote resume 030 and indexed it; set Phase 15's status in the scope file, `plan/README.md` and `STATE.md`; this record and
   the owner's messages.

## Why things are as they are

- **`AITools` becomes `Make`** (decision 1): spec section 9's target table names `Features/Make` holding Make something and
  Check a paper; a rename alone, in its own pull request, so nothing seen changes and every later task imports one module.
- **The V1 forms keep their Class tile** (decision 2): 10.7's text says the V1 kinds' forms are unchanged and P12-Form-Paper-
  Class is approved and built; the scope's "adds Student and Group around that" is read as the For sheet's segments for the
  V2 kinds. Named to the owner as his to overrule.
- **A sheet for a student needs no consent** (decision 3): spec section 8 and D62 scope consent to a student's own data; the
  level and the skill names are not that; the group kinds' bodies stay strict and a test proves no student id travels.
- **`made_from` as a column** (decision 4): Recent must tell Make's material from the plan's; a plan-null test cannot (the
  notes are plan-null too); a nullable column and a defaulted parameter are additive (D26).
- **The note from Make is Phase 14's note with the tutor's words** (decision 7): one note screen, one cadence, one consent
  rule; `tutorSays` is one optional field on the request and in the prompt.
- **The Scheme tile pushes the approved Marking scheme screen as a chooser** (decision 14): a new sheet would need a board;
  the screen exists and its first segment takes mocks beside papers; one footer label changes by state.
- **One term span per report** (decision 15): the centre's most common board sets the calendar, so the hero sums one span;
  Karnataka's year ends in April, so its terms are June to October and November to April, whole months.
- **"Not on track at the end" is today's status** (decision 16): no history of `track_status` is kept; the label is the
  board's for an ended term, and the plan says what it means.
- **Marks stay off Progress' row and CSV** (decision 17): the board draws skills, checks and absences; the board wins over the
  scope's parenthesis.
- **The Kit's figures come from AppShell** (decision 19): Phase 12 ruled DesignSystem does not import Domain's `FigureSpec`;
  the Kit is debug-only and takes a view.
- **The seed gains checks** (decision 20): the seed had none, so Progress and the trend had nothing to prove against; hand
  runs 10 and 11 compare the screen with a query.
- **The trust page is this phase's** (decision 24): spec section 9 puts it in the phase that first sends a student's data to
  testers; the round is that; it needs a board first, so it is drawn in the build session and PR 12 waits on it alone.
- **The round's start is the owner's** (decision 27, question 2): D68 has him test the builds together; whether the tutors
  wait for that or only for the tester's checks changes the dates by a week.
- **U36 is misfiled**: its Open row reads as a Done row for #133; the build moves it.

## Tried and dropped

- A `Features/Make` module beside `AITools` (two modules for one screen family): the spec names one.
- Per-student term spans by each school's board: one report with mixed spans could not be summed honestly.
- A `made` flag inside the content JSON: a list query on a JSON key with no index, and the kind decoders would carry it.
- Drawing the trust page's board in this session: the brief scoped the session to the plan and the resume; the build session
  draws it first and nothing but PR 12 waits.

## Machine

Reading only; no `bun check` run (no code changed); no simulator run; no real AI call.

## Next

The owner's two answers (the polish rows; when the round starts), then Phase 15's build on Opus 5.5 from
`resume/030-phase-15-build.md`.
