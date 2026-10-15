# Session 44: Phase 22's reads, boards and plan (Fable 5.1, 2026-10-15)

From `plan/resume/042-phase-22-boards-and-plan.md`. The owner's messages word for word are `owner-messages.md`; each read,
ruling and cost is `ledger.md`.

## What was done

- Reality matched `STATE.md` (`main` e2b9dd55, clean, no open pull request). `bun check` green; one flaky database test
  (`jobs.test.ts` hands the Mac's clock to `wait_job`) seen once and green on the re-run: the build's Task 1.
- Production read (`supabase db query --linked`): the first batched morning (15 October: four of five requests in batches,
  27 minutes, ₹3.26, no refusal, no deadline fallback; the live placement ₹1.84 of it); no exam job and no exam in its window;
  no feedback row (`bun feedback-cases --since 7d`: 0 candidates); no alert since 14 October and no false alarm.
- The boards: 41 (`P22-*`), generated in the Phase 19 grammar from a script in the session's scratchpad, rendered by headless
  Chrome and looked at, shown as three groups of contact sheets. The owner approved all three and the run card.
- Canvas 2: canvas 1 held 508 of its 512 files; the owner chose a second Design artifact
  (https://claude.ai/artifact/JV9q2AGk1fmMDVjsGgpAqw). Row 30 at y 0 holds the 41 boards; the mirror is
  `docs/design/mockups/P22-*` with `docs/design/directions/canvas-2.json`; `docs/design/README.md`,
  `information-architecture.md` ("Phase 22 boards", the trust claims) and `components.md` ("Phase 22 parts") updated.
- `plan/phase-22-plan.md`: fifteen tasks, twelve pull requests, three migrations (0066 to 0068), D113 to D118 proposed, no
  real-call budget. Phase 21's leftovers ruled: R-api-4 in (the split per batch), the Feedback row in, the Smoke centre in
  (`centres.internal`), the alert push retry in (every push, three tries), U53 the owner's.
- `plan/resume/043-phase-22-build.md` for Opus 5.5.

## Decisions by the owner

- A second canvas rather than retiring a row ("1").
- All three board groups approved; the golden sets' run card kept ("keep the card").
- The plan approved as written ("plan approved"): D113 to D118 in `plan/README.md`.

## What was decided here (each in the ledger with its cost if wrong)

- The nav grows to eleven pages at 14 px; the syllabus view opens in place; the weekly email is one light board at 680; the
  evals page is spec section 10's and in scope; the tap call's button is "Open the centre"; the allowance-reached words on the
  phone need no board (shipped since build 27).
- The plan's D113 to D118 (the controls write rows; the figures are one function with internal centres left out; the weekly
  report is a job; the golden sets' page and the run a person starts; retention by the sweep with the trust page's words; the
  split per batch) and the push retry.

## Observations, not tasks

- A `not_known` student in a batch never closed gets a fresh placement each morning (₹1.76 a day on Sonnet): Phase 12's open
  ruling on a new batch's first checks, now seen in money. In STATE's open items.

## Next

Resume 043 on Opus 5.5 builds Phase 22.
