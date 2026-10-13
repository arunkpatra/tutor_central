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

## As built (session 41, 2026-10-13)

Built from `plan/phase-20-plan.md` in pull requests #291 to #317; the hand runs are issue #313. Every ruling, hand run, fix
and review finding is in `plan/sessions/041/ledger.md`.

**The pull requests.** #291 to #293 migration 0052 (`ai_models`, the agent step, cached tokens, the step gate's grammar,
`schedule_evals`). #294 the model table read each minute. #295 the agent (draft, verify, check by the other tier, one
repair, refuse) and prompts as versioned files with a cached shared block. #296 the nine kinds on their agents with their
rubrics, and the kill switch's words. #297 the golden sets, promptfoo over the agent, `bun evals` and its gate. #298
`evals.yml`. #299 the PDFs with mitex and STIX Two Math. #300 the figure's PDF. #301 the database tests' timeout. #302 the
nightly `eval_run` through Message Batches. #303 the portal's agent step. #304 mitex carried to the function. #305 SwiftMath
and `MathText`, the Kit's maths rows. #306 the material's screens and the phone's PDF draw their maths; Share on a figure
takes the server's page. #307 a kind switched off on the phone; the alert's action in the accent. #308 the material's
prompts ask for LaTeX (version 3). #309 to #311 what the hand runs found (the planted key, bold digits, the nightly's batch
ids). #312 prompts version 4 (answers as formulae, money in rupees, own worked examples, D104's placement, a holiday's end)
with the API review's fixes and migration 0056. #314 D103 (a failed eval case retried once). #315 the app review's fixes.
#316 migration 0055 (a step taken again gets its check). #317 the brief's slip (no repair on every brief).

**Deviations from the plan, each a ruling in the ledger.**
- The LaTeX words waited for the app that draws them (version 3, then 4), so build 29 never showed raw formulae.
- `includeFiles` is ignored by Vercel's Hono builder: mitex reaches the function through a literal `new URL(…)`.
- The nightly's rows name their run by key (`evals:<day>:<case>`), not by job id (a platform job has no centre).
- The gate retries a failed case once (D103, the owner's); placements ask what a story's title promises and draft on Sonnet
  (D104, the owner's); the brief's prompt states the worked example's slip.
- The phone's spaces around a formula: edge spaces are word spaces, an operator written with a space keeps an operator's
  space (SwiftMath reads a leading `+` as a sign); a heavy formula's digits are `\mathbf` inside `\bm`.
- Run 8 (VoiceOver by the Accessibility Inspector) was not done: no Simulator.app to target, and access was declined; held by
  MathSpeech's tests and left for the device test.

**The cost measured** (local stack, real models). Two plans ₹11.24 against Phase 15's ₹7.31 (the checks and repairs). Make's
nine about ₹16.76 against ₹15.23: the class 4 sheet ₹0.84 (its Sonnet check four times the Haiku draft), the class 8 sheet
₹1.14 (₹0.74 cached), worked example ₹0.78, figure ₹0.60 (₹0.14 cached), brief about ₹1.47 after #317 (₹2.44 before, a
repair every time), mock ₹3.32, note, paper and marking unchanged. The nightly on two kinds ₹4.83 at half price; nine kinds
about ₹25 a night. The phase's real-call spend about ₹700 against the owner's approved ₹520: CI's five nine-kind eval runs ₹485 (about ₹95 each
with Opus grading), local evals ₹157 (the golden sets' build included), the agent's development ₹9, the hand runs, the
cost run and the nightly's tries about ₹45.

**Production.** Deploy A (run 38371143677, 739102d: 0052 and the agents), Deploy B (run 38382638833, c08d6d9: 0053, 0054, the
PDFs with mitex, the figure's PDF, the nightly), the portal (run 38386745738, dc0d49d) and Deploy C (run 38400290327, 29e79fb:
0055, 0056, the prompts at version 4, every review fix, the nightly's batch ids). `/health` answers 29e79fb. TestFlight
1.0.0 (30) from run 38400789743. The repository's secret `ANTHROPIC_API_KEY` (the evals in CI), Vercel's `SMOKE_CENTRE_ID`,
the Smoke centre's allowance 2,000. The first production nightly is 02:05 IST on 14 October.
