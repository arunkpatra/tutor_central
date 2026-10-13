# The golden sets (D74, D101)

One folder per kind on its agent: `cases.json` (five cases), `rubric.md` (written by `bun contract` from the agent's
rubric in `api/src/agents/kinds/`; never edited here), and for the textbook reader `pages/` (contents pages drawn by
`bun evals/draw-page.ts` from `pages.json`, no photo of a real book).

A case is `{ "id", "input", "expect" }`: the input is the route's body without `centreId` (the case test checks it
against the route's schema); `expect` may hold `count` (the questions, mistakes, chapters, items or groups), `proofs`
(every numeric answer carries a proof that adds up), `contains` and `never` (words in or out of the answer), `figure` (the
template) and `refused` (the case expects a refusal: no rubric is graded). Names are the seed's; no phone number, email
or real page.

Run: `bun evals --fake` (free: the schema, verify and expectations on the fake's answers), `bun evals --kinds sheet,check`
(the real models, graded by Opus 5.5; about ₹5 a kind). The gate: every case's free checks, and the rubric at 85% or
more per kind. CI runs the kinds a pull request touches (`.github/workflows/evals.yml`).
