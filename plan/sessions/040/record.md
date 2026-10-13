# Session 40: Phase 20's boards and plan (Fable 5.1, 2026-10-13)

From `plan/resume/038-phase-20-boards-and-plan.md`. The owner's messages word for word are `owner-messages.md`; each ruling
with its cost if wrong is `ledger.md`.

## Setup

- Reality matched `STATE.md`: `main` clean at `dd5a403`, no open pull request; `bun check` green (cached). Documents only;
  nothing built.
- Read in the resume's order; the code the plan changes surveyed by hand (the Claude client, the model table, the recorded
  call, the prompts, the plan and PDF jobs, the schemas, the board view and the sheet's sections, the Kit, the launch states,
  the admin reads, the check steps and CI).

## The two production reads

- **The first morning plan job:** none yet. The session ran at 12:14 IST on the 13th; the owner's one live batch meets on
  Tuesdays, today's plan exists from the 12 October hand run (no material), and 14 October is a Wednesday, so nothing is queued
  that morning. The first scheduled run with material is Tuesday 20 October at 05:30. Not a Phase 18 defect. Offered to the
  owner: "Make the plan again" on Today runs the material path in production now; the read is the build's Task 1.
- **The alerts rows:** sixteen alerts jobs in the morning, all done; one alert in all, the Smoke centre's proof from Phase 19,
  acknowledged. No false alarm; nothing of Phase 19's to fix.

## The boards (row 28, y 82000)

Fifteen boards drawn by a generator in the scratchpad in the Phase 10 artefact boards' grammar, every formula drawn as the
renderers will draw it (a serif maths face beside SF Pro, letters italic, numbers upright, fractions stacked): the sheet for
the younger band (class 4 fractions) and the older band (class 8 linear equations), the board view with the key shown, the
worked example, the mock with a centred display formula, each dark and light; the Kit's mathematics rows (inline, display,
the board type, Hindi and Kannada beside a formula, maths that could not be read); a sheet's PDF page as Typst renders it; a
kind switched off (U33's alert over the Make form) dark and light. Looked at on contact sheets before publishing; two things
fixed first. Published as row 28 and mirrored into `docs/design/` as drawn ("Phase 20 boards", "Phase 20 parts"), awaiting
the owner's approval, as sessions 31 and 36 did.

## Decided, and why

- **The agent's shape (D99):** draft, schema, deterministic `verify`, a check by the other tier, one repair, refusal; the
  numeric key by computation through a `proof` the model writes and the server evaluates, because a cheap checker cannot be
  trusted with arithmetic and an expensive one would double the cost; a fallback model only for a failed call, never a
  refused topic.
- **`ai_models` and the kill switch (D100):** append-only, seeded from the file, refreshed each minute, the file as the
  fallback when the table is unreachable; `enabled` false pauses a kind with the board's words.
- **promptfoo and the two runners (D101):** promptfoo in CI over a provider that runs our agent; the nightly as an
  `eval_run` job over the Batches API (a function cannot run promptfoo); one case file and one rubric text for both; the
  gate 85% on the rubric, 100% on the schema and verify.
- **Mathematics (D102):** SwiftMath 1.7.3 with XITS Math on the phone, mitex 0.2.7 vendored by path with STIX Two Math
  in the PDF (one family), words in Hindi or Kannada outside a formula, the figure's PDF on the server in Typst.
- The smaller rulings (the allowance counting drafts only, the checker's words logged on the row, the nightly under the
  Smoke centre, the evals secret, the standing cost said rather than asked) are the ledger's.

## The plan

`plan/phase-20-plan.md` with `superpowers:writing-plans`, in Phase 19's form: 18 tasks, 14 pull requests, 22 decisions, D99 to
D102 in the README, eight review-focus lines with their tests, the file structure, the order, the cost (one new standing
cost, the nightly's ₹360 a month, said for the owner to keep or cut) and the self-review. Resume 039 written and indexed.

## The owner's answer

"Boards approved, go ahead with the plan": the 15 boards and the plan approved together on 2026-10-13. Offered, not asked: "Make the plan again" on
his iPhone today, so the material path is proved in production before the 20th.

## What is next

Session 41: Phase 20's build on Opus 5.5 from `plan/resume/039-phase-20-build.md`.
