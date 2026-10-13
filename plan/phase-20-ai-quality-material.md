# Phase 20: V3 AI quality, the material

**Status:** Planned (session 40, 2026-10-13): the 15 boards of row 28 drawn (`docs/design/mockups/P20-*`) and `phase-20-plan.md`
written, both approved by the owner the same day; the build on Opus 5.5 from `resume/039-phase-20-build.md`. **Depends on:** Phases
17 and 18 (the jobs run the agents); the boards for the sheet, worked example, mock and board view with mathematics, and the Kit's
maths preview, approved first.

## Goal

The material kinds are made by specialised agents with a checking step, evaluated against golden sets in CI, and show
mathematics properly.

## Scope

1. **The pipeline** (D73): one interface for an agent (draft with strict tools and structured output; check by a different
   model against the kind's rubric; repair once; refuse in words); prompt caching on the shared prefixes; `ai_models` in the
   database (kind, step, model, effort, fallback, since, by whom), seeded from `api/models.json`, read by the API and `bun
   cost`; a fallback used is recorded on the row.
2. **Prompts as artefacts** (D74): one file per kind and step with a version and hash recorded on each row; the schemas'
   limits stated in the prompt from the generated types.
3. **Evals** (D74): a golden set per kind in `api/evals/` (the seed's names, no real data); promptfoo self-hosted in CI, run on
   the kinds whose prompts or schemas changed, a schema check first, rubric graders by a model other than the generator, a
   pass-rate gate set in the plan; the first nightly run through the Batches API, its result a row the portal shows.
4. **Mathematics** (D75): LaTeX maths mode in content; SwiftMath added to the package, pinned (`project.yml`, `Package.swift`);
   Typst with `mitex` in the `pdf` job; the Kit's maths preview; fonts checked for Hindi and Kannada text inside a formula.
5. **The kinds moved:** sheet (both bands), worked example, figure (the spec's validation becomes the check step's rule),
   brief, check, placement, the plan's naming, parse-textbook, parse-school; each with its rubric, golden set and board.
6. **Kill switch** (D73): a kind switched off in `ai_models` refuses in the tutor's words (the portal's control comes in
   Phase 22; the column and the words come here).

## Acceptance

- A sheet from the plan carries equations rendered on the phone and in its PDF; the Kit shows them in both appearances.
- A prompt change with a failing eval cannot merge; the nightly run's result is in the database.
- The check step refuses a sheet whose numeric key is wrong (a test with a planted wrong answer).
- A cost run on the moved kinds, recorded, against Phase 15's figures.
- Pictures (D7), hand runs (D32), a build on TestFlight.
