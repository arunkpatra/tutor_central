# Phase 20 plan: V3 AI quality, the material

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-13 (session 40, Fable 5.1) from `phase-20-ai-quality-material.md`, `docs/spec-v3.md` section 4 (the
agents, the models, the cost levers, the prompts, the evals, mathematics), Phase 18's and 19's "As built" and ledgers
(`plan/sessions/037/`, `039/`), the 15 boards of row 28 (`docs/design/mockups/P20-*`, "Phase 20 boards" in
`docs/design/information-architecture.md`), Phase 15's cost run (`phase-15-make-and-polish.md`, the figure this phase's
run is set against) and the code as it is. Approved by the owner 2026-10-13 ("Boards approved, go ahead with the plan"). The build runs on Opus 5.5 from
`resume/039-phase-20-build.md`, inline, task by task, with one ledger (`plan/sessions/041/ledger.md`) as sessions 22 to
39 kept.

**Goal:** the group material (the sheet, the worked example, the figure, the brief, the close's check, the placement, the
plan's naming) and the two readers (the textbook's contents page, the school's message) are made by agents: a draft, a
check by another model against the kind's rubric with the numeric keys verified by computation, one repair, then a refusal
in the tutor's words. Each prompt is a file with a version and a hash on every row. A golden set per kind runs in CI on the
kinds a pull request touches and gates the merge; the whole set runs each night through the Batches API and its result is
a job row the portal shows. Mathematics in the material is written in LaTeX and drawn properly on the iPhone (SwiftMath), in
the server's PDFs (Typst with mitex) and in the phone's own PDF. A kind can be switched off in the database and says so to
the tutor in plain words.

**Architecture:** one agent interface in the API (`src/agents/agent.ts`): a `Kind` spec (the draft request with a shared
cacheable prefix, a deterministic `verify`, the check rubric, the repair words) run by `runAgent` for a route and a job
alike, each Claude call a recorded row with its agent step. The model, effort, fallback and switch per kind and step live
in `ai_models` (migration 0052), seeded from `api/models.json` and read by the API every minute; an environment override
stays (D67). The prompts' versions are pinned by a generated table that `bun check` holds. The evals are promptfoo over a
custom provider that runs the agent (CI, the changed kinds) and our own runner over the Batches API (the nightly job,
kind `eval_run`). Mathematics: `MathText` in DesignSystem over SwiftMath; `mitex` vendored beside the Typst fonts.

**Tech stack:** as Phase 19 (Supabase CLI 2.120.0, Postgres 17, pg_cron; Bun 1.3.11; Hono 4.13.13, zod 4.6.5,
`@anthropic-ai/sdk` 0.132.1, `@myriaddreamin/typst-ts-node-compiler` 0.7.0) plus, each pinned with a decision (D14):
`promptfoo` 0.124.1 (a dev dependency of `api/`, D101); SwiftMath 1.7.3 (the second iOS dependency, D75, D102); `mitex`
0.2.7 vendored as files (Apache-2.0, D102); the font STIX Two Math (OFL) beside the Noto fonts in `api/fonts`. No new
Vercel or Supabase plan.

**Spec:** `docs/spec-v3.md` section 4 (D73, D74, D75), section 13 (cost); the scope `plan/phase-20-ai-quality-material.md`
(items 1 to 6, the acceptance); D35, D59, D62, D67, D68, D76, D83, D84, D86, D87, D89, D90, D93; the boards of row 28.

## Global constraints

- A screen changes only to an approved board (rule 1): the 15 boards of row 28 and what "Phase 20 boards" settles.
  Nothing else about the artefact screens changes; a state the boards do not draw keeps Phase 10's.
- No technical words on screen (D41): the switched-off words are the board's; every new string passes
  `ErrorWordsTests`; "LaTeX", "render", "model", "agent" and "eval" never reach a tutor.
- No AI key in the app or the repository (D11). The one new secret is `ANTHROPIC_API_KEY` as a GitHub repository secret
  for the evals workflow, set by the session from the key already in `api/.env.local`, piped, never printed (D87).
- No tutor's or student's data in a golden set (D74, D55): the seed's names (`supabase/seed.sql`), invented facts, no
  photo of a real page (the parsers' cases use pages drawn by a script).
- Every Claude call is a recorded row (D76): a check and a repair are rows of the same kind with `agent_step` set; the
  allowance counts drafts only; the cost counts every row.
- Migrations are additive (D26): build 29 keeps working (the `proof` field is ignored by its decoders; `ai_generations`
  gains columns with defaults; `start_ai_call`'s new parameter has a default).
- Bun only (D16); dependencies pinned exactly (D14); `bun check` green before every commit; a pull request merges on local
  green (D86); documents only go to `main` directly (D12); `bun evals` green before a prompt change merges (D74, D101).
- The order of truth for a model (D67, D73): the environment's `AI_MODEL_<WORK_TYPE>` over `ai_models` over
  `models.json`; a name not in `models.json`'s price table is refused at every level.

## Decisions this plan takes

The boards were shown to the owner with this plan (session 40) and approved with it; each is listed in "Phase 20 boards". Everything below was mine to decide and is stated so it can be pushed back on. D99 to D102 go into
`plan/README.md` with the plan's approval, as D94 to D96 did.

1. **The pipeline's shape (D99).** `runAgent` does, in order: the draft (the kind's model, structured output); the schema
   check (zod, free); `verify` (the kind's deterministic rules: the figure's refinements, a mock's marks, a sheet's numeric
   proofs by computation, the counts asked for; free); the model check (the kind's checker model, a `CheckVerdict`
   structured output against the kind's rubric, the draft given as JSON); one repair (the draft model again, the
   findings quoted, the same schema); the checks again; then a refusal in the kind's words (`errors.refused`). A draft that
   passes `verify` and the check is kept as it is. Three calls at most, usually two.
2. **The checker is the other tier (D99).** A kind drafted on Sonnet 5.5 is checked by Haiku 5.5; a kind drafted on Haiku
   5.5 is checked by Sonnet 5.5. The check reads a short JSON and answers a short verdict (about ₹0.05 on Haiku, ₹0.30 on
   Sonnet), so a sheet's cost rises by a tenth, not double; the numeric key is verified by computation, not by the checker,
   so the cheaper checker is not trusted with arithmetic. The table can move any checker to Opus without code (that is what
   `ai_models` is for); the nightly eval shows whether it should.
3. **Numeric keys by computation (D99).** The sheet's, worked example's and mock's outputs gain an optional `proof` per
   answer: `{ expression: string; equals: number }`, an arithmetic expression over numbers alone (`+ - * / ^`,
   parentheses, `sqrt`) that the server evaluates (`src/agents/arith.ts`, no `eval`) and compares to `equals` within
   1e-6 relative; the prompt asks for one wherever the answer is a number (the substituted check: for "solve 3x + 5 = 20"
   the proof is `3*5+5` equals `20`). A proof that does not add up is a finding; a repair that still fails is a refusal.
   The app ignores the field (its decoders skip unknown keys); the fake's samples carry it.
4. **A fallback model is a second try at the draft (D99).** When the draft's call fails with a 529, a 429 or a timeout, the
   kind's `fallback_model` (from `ai_models`) is asked once with the same request; the row records `fallback_model` (the
   column 0029 made). A refusal by content is never retried on another model (D35's reason holds: a refused topic is
   refused).
5. **Prompt caching on the shared prefix (D73).** `ClaudeRequest.system` becomes two blocks: `shared` (the voice, the
   kind's rules, the syllabus's chapter names for the class and subject from `supabase/syllabi` where the board has them,
   the output's limits from the generated contract) with `cache_control: { type: "ephemeral" }`, and `own` (the input's
   facts). The shared block is built once per kind and class level and never carries a date, an id or a name. The row
   records `tokens_cached` (new column) and the price counts a cached token at a tenth (`price.ts`). A prefix under the
   model's minimum simply does not cache; the cost run reads `cache_read_input_tokens` and says which kinds cache.
6. **`ai_models` (D100):** `kind` (the work type of `models.json`: `sheet_to_5`, `sheet_from_6`, …), `step` (`draft`,
   `check`, `repair`), `model`, `effort`, `fallback_model`, `enabled`, `since`, `set_by`, `note`, append-only: the current
   row of a kind and step is the newest `since`. Seeded by 0052 from `models.json`'s `work` table (a draft row per work
   type; a check row with the other tier; a repair row equal to the draft's), and a test holds the migration's rows equal
   to the file. Read by the platform alone (`using (false)` for members, as `admin_users`); Phase 22's portal writes it.
   `models.json` stays the seed, the price table and the tests' fixture (D67).
7. **The API reads the table once a minute.** `ModelTable.refresh()` through the platform client at start and every 60 s
   (a failed refresh keeps the last table; a start with no reachable table uses the file and logs it); `modelFor(kind,
   step, classLevel)` answers `{ model, effort, fallback, enabled }`. The worker's run and a route's request read the
   same table. `AI_MODEL_<WORK_TYPE>` overrides the draft row (D67 stands).
8. **The kill switch (D100):** `enabled` false on a kind's draft row. A route answers 503 `{ reason: "paused", error:
   <the board's words> }` before any call; the app's `APIClient` maps it to `.paused(words)` and the screen shows the
   system alert with OK (U33). A job's material step marks the request not made with `reason: "paused"` and pays nothing;
   Today reads it as not made (Phase 10's mark). The nightly eval skips a kind switched off and says so in its result.
9. **Prompts as files with a version (D74).** Each `src/prompts/<kind>.ts` exports `VERSION` (an integer string, "2" from
   this phase) and builds its request; `ClaudeRequest` gains `version`; the row's `prompt_version` is `<kind>@<version>`
   and `prompt_hash` the SHA-256 of the shared and own system words joined. `api/src/prompts/versions.json` holds each
   kind's version and hash, written by `bun prompts --write` and checked by `bun check`'s api step: a prompt whose words
   changed without its version is a red check. The check step's prompt is part of the kind's file and its version.
10. **Golden sets (D74):** `api/evals/<kind>/cases.json`, five cases per kind (the seed's names, a class level, a subject,
    the skills), each with its expected properties (counts, a numeric key where there is one, a word that must appear, a
    word that must not); `api/evals/<kind>/rubric.md`, the kind's rubric in words (facts only from the input, the level, the
    format and limits, the language, no textbook text), read by the agent's check step and by the graders alike.
11. **promptfoo (D101)** 0.124.1, a dev dependency of `api/`, run by `bun run evals` (never `npx`): `api/evals/promptfooconfig.yaml`
    with one provider, `file://./provider.ts` (our agent on the real client, `AI_FAKE=1` for a dry run), the cases as
    tests, two assertions per case: a `javascript` assertion that runs the kind's schema and `verify` (free) and an
    `llm-rubric` graded by `anthropic:messages:claude-opus-5-5` with the kind's rubric (a model other than the generator,
    Opus for every kind). The gate (`tools/evals-gate.ts` over promptfoo's JSON output): every case passes the schema and
    verify, and the rubric pass rate per kind is at least 85%. `bun evals [--kinds sheet,check]` runs it locally;
    `.github/workflows/evals.yml` runs it on a pull request that touches `api/src/prompts/**`, `api/src/agents/**`,
    `api/src/schemas.ts` or `api/evals/**`, for the kinds whose files changed (`tools/evals-changed.ts` names them from
    `git diff`), with the repository secret `ANTHROPIC_API_KEY`. A red evals run is not merged (D86's local green includes
    `bun evals` for those kinds).
12. **The nightly run is a job (D101):** kind `eval_run` (in `job_kind` since 0028), queued by pg_cron at 02:00 India time
    (`schedule_evals`, 0052), no centre. Its steps: `submit` (every case of every enabled kind as one Message Batches
    request: the draft calls), `wait` (the batch polled each tick), `check` (the deterministic checks, then a second
    batch of the check calls and the rubric graders), `wait`, `score` (the result on the job: per kind the cases, the
    schema and verify passes, the rubric pass rate, the cost in paise; the pass rate against the gate). The calls go
    through the Batches API at half price and are recorded as rows with a `job_id` and `agent_step` (`draft`, `check`,
    `grade`), under the Smoke centre (`SMOKE_CENTRE_ID`) so the gate and the allowance see them. The portal's Jobs page
    shows it as it shows any job (subject "nightly evals · 9 kinds", the open row's result: the pass rate per kind); no
    board, no new page (Phase 22's control page may chart it).
13. **Each kind moved** gets `src/agents/kinds/<kind>.ts`: the draft request (from the prompt file), `verify`, the rubric,
    the refusal words; `src/make.ts`'s `makeRequest` becomes `makeAgent`, and `run` (routes) and `recordedCall` (jobs)
    take a `Kind` and call `runAgent`. The kinds this phase: `sheet`, `worked_example`, `figure`, `brief`, `check`,
    `placement`, `plan` (the naming), `parse_textbook`, `parse_school`. The figure's refinements move from "unfit" to
    `verify` findings, so a wrong triangle is repaired once before it is refused. The mock, the parents' kinds, the gap
    report, read-marks and V1's kinds stay on `complete` as today (Phase 21).
14. **Mathematics on the phone (D102):** SwiftMath 1.7.3, exact, a dependency of `DesignSystem` only; `MathText` (a
    SwiftUI view) splits a string on `$…$` and `$$…$$`, renders each run with SwiftMath into a `UIImage` at the type
    style's point size and the foreground colour (`MathRenderer`, the one UIKit use, with its reason in the file), and
    concatenates `Text(Image(uiImage:))` with the words, so a formula flows inline with SF Pro and scales with Dynamic
    Type; a display run is its own centred line. The maths font is XITS Math (SwiftMath's bundled OFL font). A run that
    does not parse is shown as written in `text2`. VoiceOver reads `MathSpeech.words(latex)`. A `\text{…}` run holding a
    letter outside ASCII is cut out of the formula and drawn as words.
15. **Mathematics in the PDFs (D102):** mitex 0.2.7's files vendored at `api/typst/mitex/` (its `lib.typ`, `mitex.wasm`
    and licence), imported by path from the workspace (`workspace: api/`), never fetched from the package registry (a
    function has no network at render time and no package cache); STIX Two Math (`STIXTwoMath-Regular.otf`, OFL) in
    `api/fonts`, set for `math.equation`; the PDF sources split a text on `$…$` into `#"…"` strings and `#mi("…")`
    (`#mitex` for a display run). The export's PDF gets the same split. A `\text{…}` in Hindi or Kannada takes the Noto
    fonts as words do; a test renders one.
16. **The figure's PDF on the server (D90):** the `pdf` job gains the `figure` kind: the seven templates drawn in Typst
    from the spec (`src/pdf/figure.ts`: `line`, `circle`, `polygon`, `rect` and `place` from Typst's standard library,
    the same geometry as the app's `Figures/*`), one page, the caption under; Share on a figure takes the server's file
    as a sheet's does (D93's five-second rule).
17. **The phone's own PDF** (`PDFMaker`, the offline fallback of D93, and Print) draws its content with SwiftUI, so its
    lines take `MathText` and formulae print on the phone too.
18. **Launch states** for the boards' states (decision 14 of "Phase 20 boards"): `sheet-maths-to5`, `sheet-maths-from6`,
    `sheet-board-maths`, `worked-example-maths`, `mock-maths`, `kit-phase20`, `make-switched-off`, each with its fixture
    carrying the board's content; the existing states keep their chemistry content.
19. **The portal** gains the agent step on a call's page and in the calls list ("sheet · check"), and the eval job's
    subject; `admin_calls` and `admin_call` take the column (0052). No board: the chip's words are the trade's (D78).
20. **Branches and the ledger.** `phase-20/<slug>` in the main checkout, one per pull request; the build's ledger is
    `plan/sessions/041/ledger.md`, written by hand after each named test run, each ruling with its cost if wrong.
21. **Order of deploys.** Deploy A (`gh workflow run deploy`) after PR 4: 0052 and the API's table, agents and the kinds
    moved, so production's material goes through the check step before the mathematics changes the app. Deploy B after
    PR 10 (the PDFs with mitex and the figure). The app ships once, build 30, after PR 13 and the hand runs; the
    migrations are pending at no TestFlight run (D26).
22. **The cost run** (Task 17) repeats Phase 15's Task 15 on the real models: today's two plans with their material and
    Make's nine kinds, now with the check steps and caching, recorded against Phase 15's ₹7.31 and ₹15.23 in the ledger
    and the phase file; and one nightly eval's cost. The budget for the whole phase's real calls: about ₹120 (two cost
    runs, the hand runs, two eval runs, one nightly), said in the ledger as spent.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A right answer the checker calls wrong.** A checker that is too strict refuses good sheets and the tutor sees "Couldn't
   make this sheet" every morning. The repair is one try, the verdict's findings are logged on the row (`error_reason`
   `check:<finding>`), and the golden sets hold five known-good drafts that must pass the check unrepaired (Task 8's
   `a known-good draft passes the check without a repair`); the nightly's "repaired" count is in its result.
2. **A proof that is right while the answer text is wrong.** The model writes `answer: "x = 6"` with the proof `3*5+5 =
   20`: the arithmetic passes and the rubric check must catch the disagreement. Task 6's `the checker is given the proof
   beside the answer and must compare them` (the check prompt names it) and Task 8's planted case.
3. **A formula the phone cannot draw.** A sheet kept before this phase, or a model's slip (`$\frac{1}{2$`), must never
   crash a screen or hide a question: Task 11's `an unbalanced formula is shown as written` and `a sheet with no $ renders
   as plain text`.
4. **The table unreachable at a cold start.** The API starts while the database is down for a moment: it must serve from
   `models.json` and log, never refuse every call. Task 3's `a start with no table uses the file and the next refresh
   takes the table`.
5. **A switched-off kind inside the plan job.** The morning plan must go on without the kind and pay nothing: Task 12's
   `a paused kind is not made and not paid; the plan ends done with it counted not made`.
6. **The evals gate on a documents-only pull request.** A PR that changes a rubric's wording (`api/evals/**`) runs the
   evals; a PR touching nothing of the four paths runs none and the gate passes without a key. Task 9's
   `evals-changed names no kind for a web change`.
7. **A cache that never hits.** A date or an id in the shared block silently costs full price: Task 5's `the shared block
   of two requests of one kind and class is byte-equal`; the cost run reads `tokens_cached` per kind.
8. **Hindi inside a formula.** A prompt slip puts `\text{आधा}` in the maths: the phone draws it as words (Task 11's
   `a non-Latin \text is drawn as words`) and the PDF compiles (Task 10's `a Devanagari \text renders`).

## File structure

Created or changed, by part. A file has one job.

**Database (`supabase/`)**
- `migrations/20261126000052_v3_ai_models.sql`: `ai_models` with its seed; `ai_generations.agent_step`,
  `tokens_cached`; `start_ai_call`'s `p_agent_step` (the allowance counts drafts); `ai_models_current()`;
  `schedule_evals` and its cron; `admin_job_subject` for `eval_run`; `admin_calls` and `admin_call` with `agent_step`.
- `tests/ai-models.test.ts` (new), `tests/call-cost.test.ts` (cached tokens), `tests/rls.test.ts` (the catalogue),
  `tests/admin-reads.test.ts` (the step), `types.ts`.

**API (`api/`)**
- `src/models.ts` (the table: file, database, environment), `src/models-db.ts` (`ai_models_current` through the platform
  client; a fake), `models.json` (unchanged shape; the seed).
- `src/agents/agent.ts` (`runAgent`, `Kind`, `CheckVerdict`), `src/agents/arith.ts` (the evaluator), `src/agents/check.ts`
  (the check request builder), `src/agents/kinds/{sheet,worked-example,figure,brief,check,placement,plan,parse-textbook,parse-school}.ts`,
  `src/agents/kinds/index.ts` (`kindFor`).
- `src/claude.ts` (`system` as blocks with `cache_control`, `version`, cached tokens, the fallback try), `src/claude-fake.ts`
  (the steps' answers by `agent_step`), `src/price.ts` (cached tokens), `src/db.ts` (`agentStep`, `tokensCached`),
  `src/routes/common.ts` (`run` over `runAgent`), `src/jobs/call.ts` (`recordedCall` over `runAgent`), `src/make.ts`
  (`makeAgent`), `src/errors.ts` (`paused`), `src/schemas.ts` (`Proof`, `CheckVerdict`), `src/contract.ts`.
- `src/prompts/*.ts` (`VERSION`, the shared and own blocks, the rubric), `src/prompts/versions.json`, `tools/prompts.ts`.
- `src/pdf/typst.ts` (the maths split, the font), `src/pdf/sheet.ts`, `mock.ts`, `brief.ts`, `export.ts`, `src/pdf/figure.ts`
  (new), `src/jobs/kinds/pdf.ts` (figure), `api/typst/mitex/` (vendored), `api/fonts/STIXTwoMath-Regular.otf`,
  `vercel.json` (`includeFiles` gains `typst/**`).
- `src/evals/runner.ts` (the nightly over Batches), `src/evals/cases.ts` (the case files read), `src/jobs/kinds/eval-run.ts`,
  `src/jobs/kinds/index.ts`, `src/jobs/types.ts`.
- `evals/promptfooconfig.yaml`, `evals/provider.ts`, `evals/<kind>/cases.json`, `evals/<kind>/rubric.md`, `package.json`
  (promptfoo, the `evals` script).
- Tests: `test/models.test.ts`, `test/agent.test.ts`, `test/arith.test.ts`, `test/kinds.test.ts`, `test/prompts.test.ts`,
  `test/prompt-versions.test.ts`, `test/claude.test.ts`, `test/price.test.ts`, `test/pdf.test.ts`, `test/pdf-figure.test.ts`,
  `test/eval-run.test.ts`, `test/evals-cases.test.ts`, `test/platform-db.test.ts`, `test/v2.test.ts`, `test/plan-job.test.ts`.

**Tools and workflows**
- `tools/evals.ts` (+ test), `tools/evals-gate.ts` (+ test), `tools/evals-changed.ts` (+ test), `tools/prompts.ts` (+ test),
  `tools/check/steps.ts` (the api step's inputs gain `api/evals/**`, `api/typst/**`), `package.json` (`evals`, `prompts`),
  `.github/workflows/evals.yml`, `.github/workflows/deploy.yml` (the smoke renders a page with a formula).

**iOS (`ios/`)**
- `TutorCentralKit/Package.swift` (SwiftMath 1.7.3 exact on DesignSystem), `project.yml` (nothing: the package carries it),
  `Package.resolved`.
- `Sources/DesignSystem/Maths/MathText.swift`, `MathRenderer.swift`, `MathSpeech.swift`, `MathSplit.swift` (the parser of
  `$…$`), `Kit/KitPhase20.swift`, `Kit/KitView.swift` (the section).
- `Sources/DesignSystem/Components/BoardView.swift` (`MathText`), `PaperCard.swift` (`QuestionRow`), `PDF/PDFMaker.swift`;
  `Sources/Features/Artefacts/SheetSections.swift`, `WorkedExampleView.swift`, `MockView.swift`, `BriefView.swift`,
  `FigureScreen.swift` (the caption), `ArtefactScreen.swift` (the hero's title).
- `Sources/Data/AI/APIClient.swift` (`.paused`), `Sources/Domain/AIFailure.swift` (or where `APIFailure` lives: the case and
  its words), `Sources/Features/Make/*` (the alert), `Sources/AppShell/LaunchState.swift`, `RootView+LaunchStates.swift`,
  the fixtures.
- Tests: `DesignSystemTests/MathSplitTests`, `MathSpeechTests`, `MathRendererTests`; `DataTests/APIClientTests` (503 paused);
  `DomainTests/ErrorWordsTests` (the new words); `ArtefactsTests` (a sheet with maths decodes and renders).

**Admin (`admin/`)**: `lib/data/types.ts`, `app/calls/page.tsx`, `app/calls/[id]/page.tsx`, `content/words.ts`, `preview/calls.json`,
`preview/call.json`, `preview/jobs.json` (an `eval_run` row), `test/unit/calls.test.tsx`, `test/unit/jobs.test.tsx`.

**Documents:** `api/CLAUDE.md`, `ios/CLAUDE.md`, `supabase/CLAUDE.md`, `CLAUDE.md` (the commands `bun evals`, `bun prompts`),
`plan/README.md` (D99 to D102 with the plan's approval; the phase's status), `plan/phase-20-ai-quality-material.md`
("As built"), `plan/STATE.md`, `plan/sessions/041/`, `docs/design/information-architecture.md` (a state the build settles),
`docs/runbooks/simulator.md` (a sheet with maths, the switched-off run).

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 2 | `phase-20/db-ai-models` | Migration 0052: `ai_models` seeded from `models.json`, the agent step and cached tokens on a call, the evals' schedule | none |
| 2 | 3 | `phase-20/api-model-table` | The model table read from the database each minute, over the file, under the environment | none |
| 3 | 4, 5 | `phase-20/api-agent` | The agent interface: draft, verify, check, repair, refuse; cached prefixes; versions and hashes on the row | none |
| 4 | 6, 7 | `phase-20/api-kinds` | The nine kinds moved onto the agent with their rubrics; the kill switch's answer | none |
| 5 | 8 | `phase-20/evals-golden` | The golden sets, promptfoo over the agent, `bun evals` and its gate | none |
| 6 | 9 | `phase-20/evals-ci` | `evals.yml` on the kinds a pull request changes; `bun prompts` pins the versions | none |
| 7 | 10 | `phase-20/pdf-maths` | Typst with mitex and STIX Two Math: formulae in the sheet, mock, brief and export PDFs | the PDF page (P20-PDF-Sheet) |
| 8 | 10 | `phase-20/pdf-figure` | The figure's PDF drawn on the server from its spec | a figure's page |
| 9 | 12 | `phase-20/nightly-evals` | The `eval_run` job through the Batches API, its result on the portal's Jobs page | /jobs with the row (admin-shots) |
| 10 | 13 | `phase-20/admin-agent-step` | The portal shows a call's agent step | /calls, /calls/preview (admin-shots) |
| 11 | 11 | `phase-20/ios-mathtext` | SwiftMath and `MathText` in DesignSystem; the Kit's maths rows | kit-phase20, dark and light |
| 12 | 11 | `phase-20/ios-material-maths` | The sheet, board view, key, worked example, mock, brief and figure caption draw their maths; the phone's PDF too | the seven states, both appearances |
| 13 | 12 | `phase-20/ios-paused` | A kind switched off: the words and the alert | make-switched-off, both appearances |
| 14 | 15 | `phase-20/hand-runs` | What the hand runs find (D68) | the hand runs' pictures on the issue |

Every PR with pictures carries them by `bun pr-shots` (D7): `bun shots <state>` for the app, `bun admin-shots --pages …`
for the portal, and the PDF pages photographed from the rendered file (`sips -s format png` on page one).

## The order

Task 1 (the first material plan job read, when it has run) → 2 → 3 → 4 → 5 → 6 → 7 (Deploy A) → 8 → 9 → 10 (Deploy B) →
11 → 12 → 13 → 14 → 15 (the hand runs) → 16 (build 30) → 17 (the cost run) → 18 (the review, the documents). Tasks 8 and 9
need Task 6; Tasks 11 to 13 need nothing of the API but Task 7's words; build them after Deploy B anyway, so the hand runs
meet production's PDFs.

---

### Task 1: The first plan job with material (no code; the ledger)

The owner's centre has one live batch, which meets on Tuesdays; today's plan (13 October) was made by the 12 October
hand run with no material, and `schedule_plans` skips a day whose plan exists. So the first morning job with material
falls on Tuesday 20 October at 05:30, unless the owner asks for the plan again today.

- [ ] **Step 1: ask the owner, once, at the start:** on his iPhone, Today, the Class 8 batch, Change, then "Make the plan
  again": a `plan` job with `replace` runs Phase 18's material path in production now (about ₹4 on Sonnet). If he would
  rather wait, the read is the morning of 20 October.
- [ ] **Step 2: the read** (`supabase db query --linked`): the job's `created_at`, `started_at`, `finished_at`, `attempts`,
  `error`; its `job_steps` (step, attempt, state, cost); its `ai_generations` by `job_id` (kind, model, tokens, `cost_paise`);
  the plan's lines and the artefacts kept (`artefacts` by `plan_id`: kind, title); the total against Phase 15's ₹7.31 for
  two plans. One line each in the ledger; one line to the owner.
- [ ] **Step 3: a job that did not run, failed, made no material, or made a call with no cost is Phase 18's to fix (D68)**
  before Task 2 starts: its own `phase-20/fix-<what>` pull request with a test that fails first.

---

### Task 2: Migration 0052: `ai_models`, the agent step, cached tokens, the evals' schedule (PR 1)

**Files:**
- Create: `supabase/migrations/20261126000052_v3_ai_models.sql`, `supabase/tests/ai-models.test.ts`
- Modify: `supabase/tests/rls.test.ts` (the catalogue: `ai_models` among the platform tables, `memberReads: false`),
  `supabase/tests/call-cost.test.ts`, `supabase/tests/admin-reads.test.ts`, `supabase/types.ts`

**Interfaces:**
- Produces: table `public.ai_models(id uuid primary key default gen_random_uuid(), kind text not null, step text not null
  check (step in ('draft', 'check', 'repair')), model text not null, effort text not null check (effort in ('low', 'medium',
  'high')), fallback_model text, enabled boolean not null default true, since timestamptz not null default now(), set_by
  text not null default 'seed', note text, created_at, updated_at)`; RLS on, `using (false)` for members; no update or
  delete grant (append-only; a change is a new row).
- `ai_models_current() returns table (kind text, step text, model text, effort text, fallback_model text, enabled
  boolean, since timestamptz)`: the newest row per kind and step; `security invoker`, granted to `service_role` alone.
- `ai_generations` gains `agent_step text not null default 'draft' check (agent_step in ('draft', 'check', 'repair',
  'grade'))` and `tokens_cached integer`; the platform's update grant gains both.
- `start_ai_call` gains `p_agent_step text default 'draft'` (written to the row); the allowance's count (the `v_count`
  query) adds `and g.agent_step = 'draft'`; the cost sum stays over every row.
- `schedule_evals(p_now timestamptz default now()) returns integer`: inserts one `eval_run` job keyed `evals:<India's
  day>` with `input { "day": <day> }`, `run_at` 02:00 India time of that day, `on conflict do nothing`, `tc.jobs` set;
  `cron.schedule('schedule_evals', '35 20 * * *', $$select public.schedule_evals()$$)` (20:35 UTC is 02:05 IST; the
  function names the day by India's clock).
- `admin_job_subject` answers `'nightly evals'` for `eval_run`; `admin_calls` rows and `admin_call` gain `agent_step`.
- The seed: one `insert` per work type of `api/models.json`'s `work` (23 draft rows with effort `medium`, `high` for
  `scan_register`, `check_paper` and `mock` as the prompts ask today), one check row per work type (the other tier:
  Sonnet 5.5 ↔ Haiku 5.5; Opus 5.5's checker is Sonnet 5.5), one repair row equal to the draft's, every `fallback_model`
  the other tier, `set_by 'seed'`, `note '0052'`.

- [ ] **Step 1: the failing tests** (`supabase/tests/ai-models.test.ts`, the admin tests' frame: `local()`, a member `a`,
  the service client `svc`, `sql`):

```ts
import { SQL } from "bun";
import { beforeAll, expect, test } from "bun:test";
import table from "../../api/models.json" with { type: "json" };
import { local, type Local, serviceClient, userClient } from "./client";

let l: Local; let svc: ReturnType<typeof serviceClient>; let a: Awaited<ReturnType<typeof userClient>>; let sql: SQL; let centreA: string;
const stamp = Date.now();
const OTHER: Record<string, string> = { "claude-haiku-5-5": "claude-sonnet-5-5", "claude-sonnet-5-5": "claude-haiku-5-5", "claude-opus-5-5": "claude-sonnet-5-5" };

beforeAll(async () => {
  l = await local(); svc = serviceClient(l); sql = new SQL(l.db);
  a = await userClient(l, `models-a-${stamp}@example.com`);
  centreA = (await a.rpc("create_centre", { p_name: "Centre A", p_whatsapp: "+919999999999" })).data as string;
});

test("ai_models is seeded from models.json: a draft, a check on the other tier and a repair per work type", async () => {
  const rows = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; model: string; fallback_model: string; enabled: boolean }[];
  for (const [kind, model] of Object.entries(table.work)) {
    const draft = rows.find((r) => r.kind === kind && r.step === "draft");
    const check = rows.find((r) => r.kind === kind && r.step === "check");
    const repair = rows.find((r) => r.kind === kind && r.step === "repair");
    expect({ kind, draft: draft?.model, check: check?.model, repair: repair?.model, enabled: draft?.enabled }).toEqual({ kind, draft: model, check: OTHER[model], repair: model, enabled: true });
    expect(draft?.fallback_model).toBe(OTHER[model]);
  }
  expect(rows.length).toBe(Object.keys(table.work).length * 3);
});

test("the current row is the newest since; a member reads nothing and writes nothing", async () => {
  await sql`insert into public.ai_models (kind, step, model, effort, enabled, set_by, note) values ('sheet_to_5', 'draft', 'claude-sonnet-5-5', 'medium', false, 'test', 'switched off')`;
  const rows = (await svc.rpc("ai_models_current")).data as { kind: string; step: string; model: string; enabled: boolean }[];
  expect(rows.find((r) => r.kind === "sheet_to_5" && r.step === "draft")).toMatchObject({ model: "claude-sonnet-5-5", enabled: false });
  expect((await a.from("ai_models").select("kind")).data).toEqual([]);
  expect((await a.from("ai_models").insert({ kind: "x", step: "draft", model: "m", effort: "medium" })).error).not.toBeNull();
  expect((await a.rpc("ai_models_current")).error?.code).toBe("42501");
  await sql`delete from public.ai_models where set_by = 'test'`;
});

test("a check row counts against the cost and not the allowance", async () => {
  await sql`update public.centres set ai_allowance = 1 where id = ${centreA}`;
  const draft = await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "claude-haiku-5-5", p_key: `d-${stamp}`, p_agent_step: "draft" });
  expect(draft.error).toBeNull();
  const check = await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "claude-sonnet-5-5", p_key: `c-${stamp}`, p_agent_step: "check" });
  expect(check.error).toBeNull();
  const second = await a.rpc("start_ai_call", { p_centre: centreA, p_kind: "sheet", p_input: {}, p_model: "claude-haiku-5-5", p_key: `d2-${stamp}` });
  expect(second.error?.message).toContain("ai_limit_reached");
  const [row] = await sql`select agent_step from public.ai_generations where idempotency_key = ${`c-${stamp}`}`;
  expect(row.agent_step).toBe("check");
});

test("schedule_evals queues one eval_run for India's day, once", async () => {
  const now = "2026-10-20T10:00:00Z";
  expect((await svc.rpc("schedule_evals", { p_now: now })).data).toBe(1);
  expect((await svc.rpc("schedule_evals", { p_now: now })).data).toBe(0);
  const [job] = await sql`select kind, idempotency_key, input->>'day' as day, run_at from public.jobs where idempotency_key = 'evals:2026-10-20'`;
  expect(job).toMatchObject({ kind: "eval_run", day: "2026-10-20" });
  expect(new Date(job.run_at).toISOString()).toBe("2026-10-19T20:30:00.000Z");
  await sql`delete from public.jobs where idempotency_key = 'evals:2026-10-20'`;
});
```

  `call-cost.test.ts` gains `a cached token is priced at a tenth` (a row with `tokens_cached` priced by the test's copy of
  `costPaise`: 1,000 in, 1,000 cached, 100 out on Haiku 5.5 is 0.10 + 0.01 + 0.05 ÷ 1,000 dollars → 1 paisa). The
  catalogue's probe row for `ai_models` is `{ kind: "probe", step: "draft", model: "m", effort: "medium" }`.
- [ ] **Step 2: RED** (`cd supabase && bun test tests/ai-models.test.ts`): every test fails (no table). Ledger line.
- [ ] **Step 3: the migration.** The heart of it:

```sql
-- Phase 20 (D73, D99, D100): the model per kind and step in the database, seeded from api/models.json; a call's agent
-- step and cached tokens; the nightly evals' schedule. Read by the platform alone; Phase 22's portal writes it.
create table public.ai_models (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (char_length(kind) between 1 and 40),
  step text not null check (step in ('draft', 'check', 'repair')),
  model text not null check (char_length(model) between 1 and 60),
  effort text not null check (effort in ('low', 'medium', 'high')),
  fallback_model text check (fallback_model is null or char_length(fallback_model) between 1 and 60),
  enabled boolean not null default true,
  since timestamptz not null default now(),
  set_by text not null default 'seed' check (char_length(set_by) between 1 and 200),
  note text check (note is null or char_length(note) <= 400),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index ai_models_current_idx on public.ai_models (kind, step, since desc);
create trigger ai_models_updated before update on public.ai_models for each row execute function public.set_updated_at();
alter table public.ai_models enable row level security;
create policy ai_models_platform_only on public.ai_models for select to authenticated using (false);
revoke all on public.ai_models from anon, authenticated;

create function public.ai_models_current()
returns table (kind text, step text, model text, effort text, fallback_model text, enabled boolean, since timestamptz)
language sql stable security invoker set search_path = '' as $$
  select distinct on (m.kind, m.step) m.kind, m.step, m.model, m.effort, m.fallback_model, m.enabled, m.since
    from public.ai_models m order by m.kind, m.step, m.since desc
$$;
revoke all on function public.ai_models_current() from public, anon, authenticated;
grant execute on function public.ai_models_current() to service_role;

alter table public.ai_generations
  add column agent_step text not null default 'draft' check (agent_step in ('draft', 'check', 'repair', 'grade')),
  add column tokens_cached integer check (tokens_cached is null or tokens_cached >= 0);
grant update (agent_step, tokens_cached) on public.ai_generations to service_role;

-- The seed: the draft on the file's model, the check on the other tier, the repair on the draft's, as of 0052.
insert into public.ai_models (kind, step, model, effort, fallback_model, note) values
  ('paper', 'draft', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  ('paper', 'check', 'claude-haiku-5-5', 'medium', 'claude-sonnet-5-5', '0052'),
  ('paper', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052'),
  -- … one triple per work type of api/models.json, in the file's order (23 kinds, 69 rows); the test holds them equal.
  ('read_marks', 'repair', 'claude-sonnet-5-5', 'medium', 'claude-haiku-5-5', '0052');
```

  `start_ai_call` is re-created with the ninth parameter `p_agent_step text default 'draft'` (0035's body, the insert
  writing `agent_step`, the count filtered `and g.agent_step = 'draft'`), the old eight-parameter signature dropped
  (`drop function public.start_ai_call(uuid, public.ai_kind, jsonb, text, uuid, text, text, uuid, uuid)` first: PostgREST
  resolves by the argument names, and build 29 never calls it: the API does). `schedule_evals` follows `schedule_plans`'
  shape with `('2026-10-20'::date + time '02:00') at time zone 'Asia/Kolkata'` as `run_at`. `admin_job_subject` gains
  `when p_kind = 'eval_run' then 'nightly evals'`; `admin_calls`' row object and `admin_call`'s answer gain
  `'agent_step', g.agent_step` (re-create the two functions from 0050's text with the one key added).
- [ ] **Step 4: the catalogue and the types.** `rls.test.ts`: `"ai_models"` in `PLATFORM_TABLES` with its probe; the
  definers stay four. `supabase gen types typescript --local > types.ts`; `bun contract` (the API's database types).
- [ ] **Step 5: GREEN** (`bun check --only=db,tools,api`). Commit, PR 1, merge on local green (D86). Ledger line with the
  test counts.

---

### Task 3: The model table read from the database (PR 2)

**Files:**
- Create: `api/src/models-db.ts`, `api/test/models-db.test.ts`
- Modify: `api/src/models.ts`, `api/src/index.ts` (the refresh at start and each minute), `api/src/make-app.ts` (the table
  injected), `api/test/models.test.ts`, `api/src/jobs/types.ts` (`StepContext` carries nothing new: `modelFor` is a module
  function reading the table)

**Interfaces:**
- `models-db.ts`: `type ModelRow = { kind: string; step: "draft" | "check" | "repair"; model: string; effort: "low" |
  "medium" | "high"; fallbackModel: string | null; enabled: boolean }`; `type ModelSource = { current(): Promise<ModelRow[]>
  }`; `makeModelSource(url: string, serviceKey: string): ModelSource` (the platform client, `rpc("ai_models_current")`);
  `fakeModelSource(rows: ModelRow[]): ModelSource & { rows: ModelRow[] }`.
- `models.ts`: `type Step = "draft" | "check" | "repair"`; `type Chosen = { model: Model; effort: "low" | "medium" | "high";
  fallback: Model | null; enabled: boolean }`; `modelFor(kind: AIKind, step: Step, classLevel?: ClassLevel): Chosen`
  (the environment's override for a draft, else the table's row, else the file's model with effort `medium`, fallback
  null, enabled true); `installModelTable(source: ModelSource, clock = realClock): { refresh(): Promise<boolean>; stop():
  void }` (`refresh` reads `current()`, drops a row whose model is not in `KNOWN_MODELS` with a log line, keeps the last
  good table on a throw and answers false; the entry calls it at start and `setInterval` each 60 s); `applyModelOverrides`
  stays (D67). `workTypeOf` stays.

- [ ] **Step 1: the failing tests** (`api/test/models.test.ts` gains):

```ts
test("the table's row beats the file; the environment beats the table; a check step has its own row", async () => {
  const t = installModelTable(fakeModelSource([
    { kind: "sheet_from_6", step: "draft", model: "claude-haiku-5-5", effort: "low", fallbackModel: "claude-sonnet-5-5", enabled: true },
    { kind: "sheet_from_6", step: "check", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: true },
  ]));
  expect(await t.refresh()).toBe(true);
  expect(modelFor("sheet", "draft", "8")).toEqual({ model: "claude-haiku-5-5", effort: "low", fallback: "claude-sonnet-5-5", enabled: true });
  expect(modelFor("sheet", "check", "8").model).toBe("claude-sonnet-5-5");
  applyModelOverrides({ AI_MODEL_SHEET_FROM_6: "claude-opus-5-5" });
  expect(modelFor("sheet", "draft", "8").model).toBe("claude-opus-5-5");
  resetModelOverrides(); t.stop();
});

test("a start with no table uses the file and the next refresh takes the table", async () => {
  let fail = true;
  const source: ModelSource = { current: async () => { if (fail) throw new Error("down"); return [{ kind: "brief", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: true }]; } };
  const t = installModelTable(source);
  expect(await t.refresh()).toBe(false);
  expect(modelFor("brief", "draft").model).toBe("claude-sonnet-5-5");
  fail = false;
  expect(await t.refresh()).toBe(true);
  expect(modelFor("brief", "draft").model).toBe("claude-haiku-5-5");
  t.stop();
});

test("a row naming an unknown model is dropped and logged; a switched-off row answers enabled false", async () => {
  const t = installModelTable(fakeModelSource([
    { kind: "figure", step: "draft", model: "claude-nothing-9", effort: "medium", fallbackModel: null, enabled: true },
    { kind: "placement", step: "draft", model: "claude-haiku-5-5", effort: "medium", fallbackModel: null, enabled: false },
  ]));
  await t.refresh();
  expect(modelFor("figure", "draft").model).toBe("claude-sonnet-5-5");
  expect(modelFor("placement", "draft").enabled).toBe(false);
  t.stop();
});
```

  `models-db.test.ts`: `makeModelSource` maps `ai_models_current`'s rows (a fake Supabase client answering fixed rows,
  as `alerts/db.ts`'s test does) and throws on an error answer.
- [ ] **Step 2: RED**, then the code. `index.ts` installs the table with the platform's URL and key before the app is
  built (`await table.refresh()` once; a false at start is a log line, not a refusal: review focus 4); the worker's tick
  and the routes read the module. Every existing `modelFor(kind, classLevel)` call becomes `modelFor(kind, "draft",
  classLevel).model` in this PR (the prompts; `recordedCall` and `run` record `request.model`).
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`). Commit, PR 2, merge. Ledger line.

---

### Task 4: The agent interface: draft, verify, check, repair, refuse (PR 3, with Task 5)

**Files:**
- Create: `api/src/agents/agent.ts`, `api/src/agents/arith.ts`, `api/src/agents/check.ts`, `api/test/agent.test.ts`,
  `api/test/arith.test.ts`
- Modify: `api/src/claude.ts` (`system` blocks, `version`, the fallback try, cached tokens), `api/src/claude-fake.ts`,
  `api/src/schemas.ts` (`Proof`, `CheckVerdict`), `api/src/db.ts` (`agentStep`, `tokensCached` on `StartCall` and `Finish`),
  `api/src/price.ts`, `api/src/routes/common.ts`, `api/src/jobs/call.ts`, `api/test/claude.test.ts`, `api/test/price.test.ts`,
  `api/test/claude-fake.test.ts`

**Interfaces:**
- `schemas.ts`: `export const Proof = z.object({ expression: z.string().min(1).max(200), equals: z.number() })`;
  `SheetOutput.questions[].proof: Proof.nullable()`, `MockOutput.sections[].questions[].proof: Proof.nullable()`,
  `WorkedExampleOutput.proof: Proof.nullable()` (the problem's final answer); `export const CheckVerdict = z.object({ pass:
  z.boolean(), findings: z.array(z.object({ item: z.string().min(1).max(80), problem: z.string().min(1).max(300) })).max(12) })`.
- `claude.ts`: `type SystemBlocks = { shared: string; own: string }`; `ClaudeRequest<T>` gains `system: SystemBlocks`
  (replacing the string), `version: string`, `fallback?: Model`; `Answered` gains `tokensCached: number`, `model` the
  answering model, `fallbackUsed: boolean`; `complete` sends `system: [{ type: "text", text: shared, cache_control: {
  type: "ephemeral" } }, { type: "text", text: own }]`, reads `usage.cache_read_input_tokens`, and on a `failed` with
  reason `timeout`, `api 429` or `api 529` asks `request.fallback` once (the same deadline for both: a fallback runs only
  when the first failed quickly).
- `price.ts`: `costPaise(model, tokensIn, tokensOut, tokensCached = 0)`: cached tokens at a tenth of the input price;
  `promptHash(system: SystemBlocks)` hashes `shared + "\n" + own`.
- `db.ts`: `StartCall.agentStep?: "draft" | "check" | "repair" | "grade"` (sent as `p_agent_step`); `Finish.tokensCached:
  number | null`, `Finish.fallbackModel: string | null`.
- `arith.ts`: `evaluate(expression: string): number` (a recursive-descent parser: numbers with decimals, `+ - * /`, `^`
  right-associative, unary minus, parentheses, `sqrt(x)`; anything else throws `ArithError`); `proofHolds(p: { expression;
  equals }): boolean` (within `1e-6 * max(1, |equals|)`; false on a throw).
- `agent.ts`:

```ts
export type Kind<I, T> = {
  kind: AIKind;
  /** The draft request for an input: the kind's model and effort from the table are filled in by runAgent. */
  draft(input: I): Omit<ClaudeRequest<T>, "model" | "effort" | "fallback">;
  /** Deterministic findings over a parsed draft (free); none means it passes. */
  verify(input: I, draft: T): Finding[];
  /** The rubric the checker is held to, in words. */
  rubric: string;
  /** The repair's instruction built from the findings; the same schema. */
  classLevel?(input: I): ClassLevel | undefined;
  /** An answer that holds nothing (a page with no chapters), refused in words. */
  empty?(draft: T): boolean;
  student?(input: I): { id: string; name?: string } | undefined;
};
export type Finding = { item: string; problem: string };
export type AgentOutcome<T> =
  | { kind: "ok"; id: string; parsed: T; costPaise: number; repaired: boolean }
  | { kind: "pending" }
  | { kind: "paused" }
  | { kind: "failed"; id?: string; costPaise: number; reason: string };
export type AgentContext = { db: Db; claude: ClaudeClient; token: string; requestId: string; job?: string; step?: string; key?: string; centre: string };
export function runAgent<I, T>(ctx: AgentContext, spec: Kind<I, T>, input: I): Promise<AgentOutcome<T>>;
```

  `runAgent`: `modelFor(spec.kind, "draft", level)`; `enabled` false → `paused` with no row; the draft recorded with
  `agentStep: "draft"` and key `<key>` (a replay answers as today); `spec.verify` and the check (`check.ts`:
  `checkRequest(spec, input, draft, model)`: the system's shared block is the rubric and the verdict's rules, the own
  block the input and the draft as JSON, output `CheckVerdict`; recorded with `agentStep: "check"`, key `<key>:check`);
  a verdict with `pass` false or findings from `verify` → the repair (`spec.draft(input)` with the findings appended to
  the own block under "Fix these and change nothing else:", recorded `agentStep: "repair"`, key `<key>:repair`, the
  draft's model), then `verify` and the check once more; a draft that still fails is `failed` with reason
  `check:<first finding's item>` and the draft row's `error_reason` set so; the cost summed over every row. A check call
  that itself fails (a timeout) does not refuse the draft: it is logged and the draft is kept (a check is a guard, not
  a gate on availability; the nightly measures).
- `routes/common.ts`: `run(c, deps, centre, spec, input)` replaces `Call`; the paused outcome answers `errors.paused(kind)`
  (Task 7 adds the words; this task answers 503 `reason: "paused"` with the kind's refusal words until then).
  `jobs/call.ts`: `recordedCall(ctx, { centre, spec, input, job, step, key? })` over `runAgent`, answering
  `RecordedCall` plus `paused`.

- [ ] **Step 1: the failing tests.** `arith.test.ts`: `evaluate("3*5+5")` → 20; `evaluate("(20-5)/3")` → 5;
  `evaluate("2^3^2")` → 512; `evaluate("sqrt(16)+1")` → 5; `evaluate("-4+6")` → 2; `evaluate("x+1")` throws;
  `proofHolds({ expression: "3*5+5", equals: 20 })` true, `{ expression: "3*6+5", equals: 20 }` false,
  `{ expression: "1/3", equals: 0.3333333 }` true. `agent.test.ts` (a `Kind` for a tiny schema `{ answer: number; proof }`
  and the fake with a script by `agent_step`):

```ts
test("a draft that verifies and passes the check is kept with one draft row and one check row", async () => {
  const claude = fakeClaude((r) => r.system.shared.includes("You check") ? { answer: { pass: true, findings: [] } } : { answer: { answer: 20, proof: { expression: "3*5+5", equals: 20 } } });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "ok", repaired: false });
  expect(db.rows.map((r) => r.agentStep)).toEqual(["draft", "check"]);
  expect(db.rows.map((r) => r.key)).toEqual(["k", "k:check"]);
});

test("a planted wrong key is a finding; the repair is kept when it adds up", async () => {
  let drafts = 0;
  const claude = fakeClaude((r) => {
    if (r.system.shared.includes("You check")) return { answer: { pass: true, findings: [] } };
    drafts += 1;
    return { answer: drafts === 1 ? { answer: 20, proof: { expression: "3*6+5", equals: 20 } } : { answer: 20, proof: { expression: "3*5+5", equals: 20 } } };
  });
  const out = await runAgent(ctx(fakeDb(), claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "ok", repaired: true });
  expect(claude.requests.filter((r) => !r.system.shared.includes("You check")).length).toBe(2);
  expect(claude.requests[2]?.system.own).toContain("Fix these");
});

test("a draft the repair cannot fix is refused in words, with the finding on the row", async () => {
  const claude = fakeClaude((r) => r.system.shared.includes("You check") ? { answer: { pass: false, findings: [{ item: "answer", problem: "does not match the proof" }] } } : { answer: { answer: 21, proof: { expression: "3*5+5", equals: 20 } } });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kind, { x: 5 });
  expect(out).toMatchObject({ kind: "failed", reason: "check:answer" });
  expect(db.rows[0]?.finish?.errorReason).toBe("check:answer");
  expect(db.rows.length).toBe(4);
});

test("a kind switched off answers paused before any call or row", async () => {
  const t = installModelTable(fakeModelSource([{ kind: "sheet_from_6", step: "draft", model: "claude-sonnet-5-5", effort: "medium", fallbackModel: null, enabled: false }]));
  await t.refresh();
  const claude = fakeClaude({ answer: {} }); const db = fakeDb();
  expect(await runAgent(ctx(db, claude), sheetKindAtClass8, input)).toEqual({ kind: "paused" });
  expect(claude.requests.length).toBe(0); expect(db.rows.length).toBe(0);
  t.stop();
});

test("a failed draft call tries the fallback model once and records it", async () => {
  let n = 0;
  const claude = fakeClaude((r) => { n += 1; return n === 1 ? { fail: "api 529" } : r.system.shared.includes("You check") ? { answer: { pass: true, findings: [] } } : { answer: { answer: 20, proof: null } }; });
  const db = fakeDb();
  const out = await runAgent(ctx(db, claude), kindWithFallback, { x: 5 });
  expect(out.kind).toBe("ok");
  expect(db.rows[0]?.finish?.fallbackModel).toBe("claude-haiku-5-5");
});

test("a check that times out keeps the draft and logs", async () => {
  const claude = fakeClaude((r) => r.system.shared.includes("You check") ? { fail: "timeout" } : { answer: { answer: 20, proof: null } });
  expect((await runAgent(ctx(fakeDb(), claude), kind, { x: 5 })).kind).toBe("ok");
});
```

  `claude.test.ts` gains `the system is two blocks and the first carries cache_control` (the fake fetch reads the body)
  and `cache_read_input_tokens is answered as tokensCached`; `price.test.ts` gains the cached-token price. The fallback
  belongs to `runAgent`, not `complete` (one place that knows the table).
- [ ] **Step 2: RED** (`cd api && bun test test/agent.test.ts test/arith.test.ts`). Ledger line.
- [ ] **Step 3: the code.** `claude-fake.ts` answers by `agent_step` through its script function (the tests above); the
  `SAMPLE` answers gain a `proof` where there is a numeric key. `bun contract` rewrites the fake's samples for the app's
  ContractTests (the Swift decoders skip `proof`; ContractTests still decode).
- [ ] **Step 4: GREEN** (`bun check --only=api,tools,ios`: ContractTests with the new samples). Continue with Task 5 on the
  same branch.

---

### Task 5: Prompts as files with a version; the shared block cached (PR 3, with Task 4)

**Files:**
- Create: `api/src/prompts/versions.json`, `tools/prompts.ts`, `tools/prompts.test.ts`, `api/test/prompt-versions.test.ts`
- Modify: every `api/src/prompts/*.ts` (`VERSION`, `shared` and `own`), `api/src/prompts/shared.ts` (`VOICE`, `LIMITS` from
  the contract, `syllabusFacts(classLevel, subject)` from `supabase/syllabi`), `api/test/prompts.test.ts`, `package.json`
  (`prompts`), `tools/check/steps.ts` (the api step runs `bun tools/prompts.ts --check`)

**Interfaces:**
- Each prompt file: `export const VERSION = "2"`; `request(...)` answers `system: { shared, own }` and `version:
  VERSION`; the shared block is `[VOICE, the kind's rules, LIMITS[kind], syllabusFacts(level, subject)].join("\n\n")`
  and holds nothing of the input but the class level and subject; the own block holds the input's facts.
- `shared.ts`: `syllabusFacts(classLevel, subject): string` ("Chapters of class 8 Science in the CBSE syllabus: …" from
  `supabase/syllabi/*.json`, else ""); `LIMITS: Record<AIKind, string>` ("A question is at most 600 characters; …" built
  from the schemas' limits so the prompt states what the schema holds).
- `tools/prompts.ts`: `bun prompts --write` builds every kind's request from a fixed sample input (the fake's samples)
  and writes `{ "<kind>": { "version": "2", "hash": "<sha256 of shared>" } }` to `api/src/prompts/versions.json`;
  `--check` rebuilds and fails naming each kind whose hash changed under the same version, or whose version changed with
  the same hash. The row's `prompt_version` is `<kind>@<VERSION>`; `prompt_hash` is the hash of shared and own.

- [ ] **Step 1: the failing tests.** `prompt-versions.test.ts`: `every prompt file exports a VERSION that is an integer
  string`; `the shared block of two requests of one kind and class is byte-equal` (two sheets, different skills and
  reasons, class 8 Science: `request(a).system.shared === request(b).system.shared`); `the shared block carries no date,
  id or name` (a regex for a UUID, an ISO day, and the sample's student names); `the row's version is kind@VERSION`
  (`finishOf` with a request of version "2" → `promptVersion: "sheet@2"`). `tools/prompts.test.ts`: `--check` passes on
  a written table, fails when a hash moves (a temporary copy of the table with one hash changed).
- [ ] **Step 2: RED**, then the prompts rewritten one file at a time (the words unchanged where nothing asks for a change;
  each kind's limits stated; the proof asked for in the sheet, worked example and mock prompts: "Where an answer is a
  number, give a proof: an arithmetic expression over numbers only and the value it equals, so the answer can be
  checked by computation"), `versions.json` written, `finishOf` writing `promptVersion`.
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`). Commit, PR 3, merge. Ledger line.

---

### Task 6: The nine kinds moved onto the agent, with their rubrics (PR 4, with Task 7)

**Files:**
- Create: `api/src/agents/kinds/sheet.ts`, `worked-example.ts`, `figure.ts`, `brief.ts`, `check.ts`, `placement.ts`,
  `plan.ts`, `parse-textbook.ts`, `parse-school.ts`, `index.ts`; `api/test/kinds.test.ts`
- Modify: `api/src/make.ts` (`makeAgent(v: MakeInput): { spec: Kind; input }` for the nine; the rest stay `made(...)` on
  `complete` through a thin `legacyKind`), `api/src/routes/v2.ts`, `api/src/routes/ai.ts` (nothing: V1 stays), `api/src/jobs/kinds/plan.ts`
  (`recordedCall` with the spec), `api/test/v2.test.ts`, `api/test/plan-job.test.ts`, `api/test/make.test.ts`

**Interfaces:**
- `kinds/index.ts`: `kindFor(kind: AIKind): Kind<unknown, unknown> | null` (null for a kind not moved).
- Each kind's `verify`: `sheet` (exactly the questions asked, numbered from 1, every proof holds, every answer non-empty,
  a question under 600 characters); `worked_example` (two to six steps, the proof holds, the slip starts "A common slip
  here:"); `figure` (the template asked for; the refinements of `Figure` as findings: the landing on the line, shaded ≤
  parts, angles summing to 180, a plant first; a chapter's name among the labels for a cell); `brief` (three mistakes,
  three lines, the worked example's proof); `check` (exactly one question per skill, the skill repeated as given, the
  answer at most twelve words); `placement` (one per chapter, the chapter as given); `plan` (one topic per unnamed group
  number, each `groupNo` asked); `parse_textbook` (two to eight skills per chapter, chapters at most 40, no sentence over
  ten words as a skill); `parse_school` (dates ISO and not before today minus 400 days, a `classLevel` only from the
  given levels, a `school` only from the given schools, at most 12 items).
- Each kind's `rubric` (also written to `api/evals/<kind>/rubric.md` in Task 8, the one text): the facts are only those
  in the input (no invented student, school or page text); the level fits the class; the format and limits; the
  language (English in Indian idiom, the parsers' words as written); for the sheet and the worked example, "the answer
  and its proof agree" (review focus 2).
- `errors.refused(kind)` words stay; `errors.paused(kind)` comes in Task 7.

- [ ] **Step 1: the failing tests** (`kinds.test.ts`, each kind with the fake): `a sheet with a planted wrong proof is
  repaired, and refused when still wrong` (the fake's second draft fixes it; a third fake never fixes it); `a figure
  whose triangle sums to 190 is a finding, then unfit after the repair` (the route answers 422 in the figure's words);
  `a check with two skills and one question is a finding`; `a textbook page with no chapters is refused as empty without
  a check call` (empty before the check); `parse_school refuses a class not at the centre`; `the plan's naming asks one
  topic per unnamed group`. `v2.test.ts`: `/make` for a sheet records three rows at most and answers the repaired draft;
  `plan-job.test.ts`: `a make step whose draft is repaired keeps the repaired artefact and sums the cost of its rows`
  (the step's `costPaise` is the sum).
- [ ] **Step 2: RED**, then the kinds. `recordedCall`'s callers in `plan.ts` pass the spec from `makeAgent`; the step's
  `costPaise` is the outcome's sum; a `paused` outcome marks the request not made with `reason: "paused"` in the step
  (`notMade` counts it) and the ledger notes it (Task 7 tests it).
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`). Continue with Task 7 on the branch.

---

### Task 7: The kill switch's answer (PR 4, with Task 6)

**Files:**
- Modify: `api/src/errors.ts` (`paused`), `api/src/routes/common.ts`, `api/src/jobs/kinds/plan.ts`, `api/test/v2.test.ts`,
  `api/test/plan-job.test.ts`, `api/src/contract.ts` (the kinds' plain names for the app's words)

**Interfaces:**
- `errors.paused(kind: AIKind): ApiError` → `{ status: 503, body: { error: "<Kind plural> can't be made right now. Making
  <kind plural> is switched off for a short while so we can fix something. Everything else works as usual. Try again
  later.", reason: "paused" } }` with the plural from `KIND_WORDS: Record<AIKind, string>` ("sheets", "worked examples",
  "figures", "briefs", "checks", "placements", "topics", "chapter lists", "school messages", "mock tests", "notes", …);
  the app shows the title as the first sentence and the rest as the message (U33's rule), so the board's words come
  out as drawn (P20-Switched-Off).
- A paused route is not an `api_requests` error of the model's: `reason: "paused"` is listed in `admin/content/reasons.ts`
  as "paused · the kind is switched off" (Task 13).

- [ ] **Step 1: the failing tests.** `v2.test.ts`: `a switched-off kind answers 503 paused with the board's words and no
  row`; `plan-job.test.ts`: `a paused kind is not made and not paid; the plan ends done with it counted not made` (the
  table with the sheet off: the step `make:0` continues with `notMade` 1 and `reason: "paused"` on the step, no generation
  row, the job done with `not_made` 1).
- [ ] **Step 2: RED**, then the words and the branches.
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`). Commit, PR 4, merge. Then **Deploy A** (`gh workflow run deploy`):
  0052 and the API; the smoke's real `check` goes through the agent (a draft and a check row for the Smoke centre); the
  ledger line with the run number and the two rows read back with `--linked`.

---

### Task 8: The golden sets, promptfoo over the agent, `bun evals` and its gate (PR 5)

**Files:**
- Create: `api/evals/promptfooconfig.yaml`, `api/evals/provider.ts`, `api/evals/assert.ts` (the javascript assertion),
  `api/evals/<kind>/cases.json` and `rubric.md` for the nine kinds, `api/evals/README.md` (how a case is added),
  `tools/evals.ts`, `tools/evals.test.ts`, `tools/evals-gate.ts`, `tools/evals-gate.test.ts`, `api/test/evals-cases.test.ts`
- Modify: `api/package.json` (`promptfoo` 0.124.1 in devDependencies, the script `evals`), `bun.lock`, root `package.json`
  (`evals`), `tools/check/steps.ts` (the api step's inputs), `.gitignore` (`api/evals/.promptfoo`, `api/evals/output`)

**Interfaces:**
- A case: `{ "id": "sheet-8-linear-1", "input": { <the kind's input without centreId> }, "expect": { "count": 6,
  "proofs": true, "contains": ["x"], "never": ["Hemanth"] } }`; five per kind; the inputs name the seed's skills and
  classes (Class 8 Science chemical reactions, Class 4 Maths fractions, Class 10 Maths quadratic equations, Class 6
  English, LKG reading) so the two sheet bands and the languages are covered; the parsers' cases carry a PNG drawn by
  `api/evals/draw-page.ts` (a contents page and a school notice as text on a white image, no real page).
- `provider.ts` (promptfoo's `ApiProvider`): `id()` "tutor-central-agent"; `callApi(prompt, context)` reads
  `context.vars.kind` and `context.vars.input`, runs `runAgent` with the real client (`ANTHROPIC_API_KEY`) or the fake
  (`AI_FAKE=1`) over `fakeDb()` (no database: the evals never touch Supabase), answers `{ output: JSON.stringify(parsed),
  tokenUsage, cost: paise / 8500, metadata: { repaired, rows } }` or `{ error }` for a refusal.
- `assert.ts`: the javascript assertion: parses the output, runs the kind's schema and `verify`, then the case's `expect`
  (count, proofs, contains, never); answers `{ pass, score, reason }`.
- `promptfooconfig.yaml`: `providers: [file://./provider.ts]`; `tests:` generated from the case files by `tools/evals.ts`
  into `api/evals/output/tests.yaml` (one test per case: `vars: { kind, input }`, `assert: [{ type: javascript, value:
  file://./assert.ts }, { type: llm-rubric, value: file://./<kind>/rubric.md, provider: anthropic:messages:claude-opus-5-5 }]`).
- `bun evals [--kinds a,b] [--fake]`: writes the tests for the kinds asked (all nine by default), runs `bun run --cwd api
  promptfoo eval -c evals/promptfooconfig.yaml -o evals/output/results.json --no-cache`, then `tools/evals-gate.ts`
  reads the results: exit 1 naming each kind whose javascript assertion failed on any case or whose rubric pass rate is
  under 85%; prints a table (kind, cases, schema, rubric %, repaired, cost ₹).

- [ ] **Step 1: the failing tests.** `evals-cases.test.ts`: every case file parses, five cases per kind, every input
  satisfies the kind's zod input schema (with a probe `centreId`), no case holds a word of `BANNED_NAMES` (the real
  centres' tutor names are not in the repository; the list holds "+91" and an email pattern); `a known-good draft passes
  the check without a repair` (the fake's sample answers for the nine kinds run through `runAgent` with the fake checker
  answering `pass: true`: `verify` finds nothing). `evals-gate.test.ts`: a results JSON with one kind at 80% fails naming
  it; at 85% passes; a schema failure fails whatever the rubric. `evals.test.ts`: the tests YAML written for two kinds
  holds ten tests and the two assertions each.
- [ ] **Step 2: RED**, then the files; `bun add --exact --dev promptfoo@0.124.1` in `api/`.
- [ ] **Step 3: a fake run** (`bun evals --fake`): nine kinds, every javascript assertion green on the fake's answers,
  the rubric skipped under `--fake` (`llm-rubric` needs a key: the gate reads "skipped"). Then **a real run** on two kinds
  (`bun evals --kinds sheet,check`), the cost read with `bun cost` (the provider's rows go to no database: the cost is the
  provider's own sum, printed), the pass rates in the ledger; a kind under the gate on this first run is looked at case
  by case (the rubric's wording, the prompt's) and fixed before the PR, in this PR.
- [ ] **Step 4: GREEN** (`bun check --only=api,tools`). Commit, PR 5, merge. Ledger line with the two kinds' rates and ₹.

---

### Task 9: `evals.yml` on the kinds a pull request changes; the versions pinned in CI (PR 6)

**Files:**
- Create: `.github/workflows/evals.yml`, `tools/evals-changed.ts`, `tools/evals-changed.test.ts`
- Modify: `tools/check/steps.ts` (nothing more), `CLAUDE.md` (the commands), `api/CLAUDE.md`

**Interfaces:**
- `tools/evals-changed.ts <base>..<head>`: from `git diff --name-only`, the kinds to run: a change under
  `api/src/prompts/<kind>.ts` or `api/src/agents/kinds/<kind>.ts` or `api/evals/<kind>/` names that kind; a change to
  `api/src/prompts/shared.ts`, `api/src/agents/agent.ts`, `api/src/agents/check.ts`, `api/src/schemas.ts` or
  `api/evals/provider.ts` names every kind; anything else names none. Prints them comma-separated, or `none`.
- `evals.yml`: `on: pull_request` with `paths: [api/src/prompts/**, api/src/agents/**, api/src/schemas.ts, api/evals/**]`;
  one Ubuntu job: checkout with `fetch-depth: 0`, Bun, `bun install --frozen-lockfile`, `kinds=$(bun tools/evals-changed.ts
  origin/${{ github.base_ref }}..HEAD)`, `bun evals --kinds $kinds` when not `none`, with `ANTHROPIC_API_KEY: ${{
  secrets.ANTHROPIC_API_KEY }}`; the results table in the run's summary; `concurrency` per PR, cancel in progress.
- The secret: `gh secret set ANTHROPIC_API_KEY < <(grep '^ANTHROPIC_API_KEY=' api/.env.local | cut -d= -f2-)` by the
  session (D87), nothing printed; the ledger says the name.

- [ ] **Step 1: the failing test** (`evals-changed.test.ts`): `a prompt file names its kind`; `shared.ts names every
  kind`; `evals-changed names no kind for a web change`; `a rubric change names its kind`.
- [ ] **Step 2: RED**, then the tool and the workflow; the secret set.
- [ ] **Step 3: GREEN** (`bun check --only=tools`); commit, PR 6: the workflow runs on this very PR (it touches
  `api/evals/**`? no: it touches `tools/` and the workflow; so touch `api/evals/README.md` in it to prove the run), the run
  green with the kinds it names; merge. Ledger line with the run number.

---

### Task 10: Typst with mitex and STIX Two Math in the PDFs; the figure's PDF (PRs 7 and 8)

**Files:**
- Create: `api/typst/mitex/lib.typ`, `api/typst/mitex/mitex.wasm`, `api/typst/mitex/LICENSE` (Apache-2.0, from the
  package's 0.2.7 release, the files as published, with its `typst.toml` for the record), `api/fonts/STIXTwoMath-Regular.otf`
  (+ its OFL text in `api/fonts/OFL.txt`'s list), `api/src/pdf/maths.ts` (the split), `api/src/pdf/figure.ts`,
  `api/test/pdf-maths.test.ts`, `api/test/pdf-figure.test.ts`
- Modify: `api/src/pdf/typst.ts` (the preamble imports mitex by path and sets the maths font; `t()` and `numbered()` take
  the split), `api/src/pdf/sheet.ts`, `mock.ts`, `brief.ts`, `export.ts`, `api/src/pdf/render.ts` (`workspace`),
  `api/src/jobs/kinds/pdf.ts` (figure), `api/vercel.json` (`includeFiles: ["fonts/**", "typst/**"]`), `tools/deploy-check.ts`
  (or where the deploy checks the fonts: the `typst/` files too), `.github/workflows/deploy.yml` (the smoke's page carries
  a formula: `/jobs/health` renders `$\frac{1}{2}$`), `api/test/pdf.test.ts`, `api/test/pdf-job.test.ts`

**Interfaces:**
- `maths.ts`: `type Run = { kind: "text"; text: string } | { kind: "inline"; latex: string } | { kind: "display"; latex: string }`;
  `splitMaths(text: string): Run[]` (`$$…$$` first, then `$…$`; an unbalanced `$` leaves the text as text; a `\text{…}`
  whose letters are outside ASCII is lifted out of its run as text); `typstOf(text: string): string` (the runs as `#"…"`,
  `#mi("…")` and `#mitex("…")`, the LaTeX escaped as a Typst string).
- `typst.ts`: `preamble()` gains `#import "/typst/mitex/lib.typ": mi, mitex` and `#show math.equation: set text(font:
  ("STIX Two Math", "Noto Sans", "Noto Sans Devanagari", "Noto Sans Kannada"))`; `t(text)` becomes `typstOf(text)`.
- `render.ts`: `NodeCompiler.create({ workspace: apiRoot(), fontArgs: [{ fontPaths: [fontsDir()] }] })` where `apiRoot()` is
  the directory holding `fonts/` and `typst/` (the candidates of `fontsDir()` one level up); the source compiled is given
  as `mainFileContent` with the workspace's root as `/`.
- `figure.ts`: `figurePdf(spec: Figure, meta: { title: string; caption: string }): string`: the seven templates on an A4
  page, drawn in a 400 × 260 pt box centred, the caption under; number line (`line` with ticks and labels, the jumps as
  arcs by `path`), fraction bar (`rect` cells, the shaded in a grey), place value (a `table`), unit circle (`circle`, the
  radius, the point, the dashed drop), triangle (`polygon` from the angles by the law of sines on a 200 pt base, the right
  angle marked, the labels at the sides' midpoints), labelled cell (an `ellipse` with leader `line`s and labels), food
  chain (`rect` boxes joined by `line`s with arrowheads); every text through `t()`.
- `pdf.ts`: the `figure` kind renders `figurePdf` to `<centre>/<artefact>.pdf` (no key form).

- [ ] **Step 1: the failing tests.** `pdf-maths.test.ts`: `splitMaths("Solve $3x + 5 = 20$.")` → three runs;
  `splitMaths("$$x = 1$$")` → one display run; `an unbalanced $ is text`; `a non-Latin \text is lifted out as text`;
  `typstOf` escapes a quote inside maths. `pdf.test.ts`: `a sheet with a formula compiles to one page and the PDF's text
  holds the words around it` (the PDF's text read with the existing test's extractor); `a Devanagari \text renders`
  (compiles, no error); `the page's maths font is STIX Two Math` (the compiled PDF embeds a font named STIXTwoMath: the
  bytes contain `STIXTwoMath`). `pdf-figure.test.ts`: each of the seven templates compiles to one page; a triangle with
  the right angle marked holds "90°" in its text; `pdf-job.test.ts`: `a figure artefact's PDF is uploaded at its path`.
- [ ] **Step 2: RED**, then the vendoring (`api/typst/mitex/` from the 0.2.7 release archive: the session fetches it with
  `curl` from the Typst package registry's mirror on GitHub, `typst/packages` at tag `mitex-0.2.7`, verifies the licence
  file, and commits the three files; the wasm is about 1 MB), the font (STIX Two Math's OTF from the stixfonts release
  2.13, OFL), the split, the preamble, the figure.
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`); the rendered sheet's page one photographed (`sips -s format png`)
  and compared with P20-PDF-Sheet by eye: the title, the subtitle, the numbered rows with their formulae, the foot; then
  commit, PR 7 (the maths), merge; PR 8 (the figure) on its own branch after it, with a figure's page as its picture.
  Then **Deploy B** (`gh workflow run deploy`): the deploy's check that `typst/**` is in the function, the smoke's page with
  a formula; the ledger line.

---

### Task 11: Mathematics on the phone: SwiftMath, `MathText`, the material's screens, the Kit, the phone's PDF (PRs 11 and 12)

**Files:**
- Create: `ios/TutorCentralKit/Sources/DesignSystem/Maths/MathSplit.swift`, `MathRenderer.swift`, `MathText.swift`,
  `MathSpeech.swift`, `Kit/KitPhase20.swift`; `Tests/DesignSystemTests/MathSplitTests.swift`, `MathSpeechTests.swift`,
  `MathRendererTests.swift`
- Modify: `TutorCentralKit/Package.swift` (`.package(url: "https://github.com/mgriebling/SwiftMath.git", exact: "1.7.3")`,
  `DesignSystem` depends on `.product(name: "SwiftMath", package: "SwiftMath")`), `Package.resolved`,
  `Kit/KitView.swift` (the section `phase20`), `Components/BoardView.swift` (`MathText` for the question and the key),
  `Components/PaperCard.swift` (`QuestionRow`, `KeyRow`'s text), `Components/BoardView.swift`'s `StepRow` (the title and
  working), `PDF/PDFMaker.swift` (`PDFContent`'s lines through `MathText`), `Features/Artefacts/SheetSections.swift`,
  `WorkedExampleView.swift` (nothing: `StepRow` draws it), `MockView.swift`, `BriefView.swift`, `FigureScreen.swift`
  (the caption), `ArtefactScreen.swift` (`ResultHero`'s title through `MathText`), `AppShell/LaunchState.swift` (the
  seven states), `RootView+LaunchStates.swift`, the fixtures (`Fixtures/…`: the boards' content), `Tests/ArtefactsTests`
  (a sheet with maths), `docs/design/design-tokens.md` if a size is new (none expected: the formula takes the row's size)

**Interfaces:**
- `MathSplit`: `enum MathRun: Equatable { case text(String), inline(String), display(String) }`; `static func runs(_
  s: String) -> [MathRun]` (the same rules as the API's `splitMaths`, held equal by a shared case file
  `tools/contract/maths-cases.json` through `bun contract` as the plan cases are).
- `MathRenderer`: `nonisolated static func image(latex: String, pointSize: CGFloat, color: UIColor, display: Bool) ->
  UIImage?` (SwiftMath's `MTMathListBuilder` into a display list drawn by `MTMathUILabel`'s renderer into a
  `UIGraphicsImageRenderer` at the screen's scale; nil when the LaTeX does not parse; `XITS Math` as the font through
  `MTFontManager`); the file says why UIKit is used here (D8: SwiftMath draws with Core Text through a `UIView`).
- `MathText: View`: `init(_ text: String, style: TypeStyle = Tokens.body, color: Tokens.Color = Tokens.text)`;
  inline runs become `Text(Image(uiImage:))` with `.baselineOffset` so the formula's axis sits on the text's; a display
  run is its own `HStack` centred with `rowPaddingDense` above and below; a run that does not render is `Text(run)` in
  `text2`; the whole carries `accessibilityLabel(MathSpeech.words(text))`. Dynamic Type: the style's resolved point size
  at the environment's size (`typeStyle` reads it) is the renderer's.
- `MathSpeech`: `static func words(_ text: String) -> String` ("x over 4 minus 2 equals 1", "square root of 16", "x
  squared", "x to the 3", "alpha plus beta").
- `KitPhase20`: the board's five groups and the footnote; `KitView.Section.phase20`; the launch state `kit-phase20`.

- [ ] **Step 1: the failing tests** (Swift Testing):

```swift
@Test func splitsInlineAndDisplay() {
    #expect(MathSplit.runs("Solve $3x + 5 = 20$.") == [.text("Solve "), .inline("3x + 5 = 20"), .text(".")])
    #expect(MathSplit.runs("$$x = 1$$") == [.display("x = 1")])
}
@Test func anUnbalancedFormulaIsShownAsWritten() {
    #expect(MathSplit.runs("Solve $\\frac{x}{4 - 2 = 1") == [.text("Solve $\\frac{x}{4 - 2 = 1")])
}
@Test func aNonLatinTextIsDrawnAsWords() {
    #expect(MathSplit.runs("$\\text{आधा} = \\frac{1}{2}$") == [.text("आधा"), .inline(" = \\frac{1}{2}")])
}
@Test func speaksAFormula() {
    #expect(MathSpeech.words("$\\frac{x}{4} - 2 = 1$") == "x over 4 minus 2 equals 1")
    #expect(MathSpeech.words("$\\sqrt{16}$ and $x^{2}$") == "square root of 16 and x squared")
}
@Test @MainActor func rendersAFractionAndRefusesNonsense() {
    #expect(MathRenderer.image(latex: "\\frac{x}{4}", pointSize: 15, color: .white, display: false) != nil)
    #expect(MathRenderer.image(latex: "\\frac{x}{4", pointSize: 15, color: .white, display: false) == nil)
}
@Test func aSheetWithMathsDecodesAndKeepsItsText() throws {
    let sheet = try JSONDecoder().decode(SheetContent.self, from: Fixtures.sheetMathsFrom6)
    #expect(sheet.questions[1].text == "Solve $\\frac{x}{4} - 2 = 1$.")
}
```

  The maths cases file is read by `MathSplitTests` (`maths-cases.json` in the test's resources, copied by `bun
  contract`) and by `api/test/pdf-maths.test.ts`, so the phone and the PDF split alike.
- [ ] **Step 2: RED** (`bun check --only=ios` fails on the missing module). Then `bun add` nothing: `Package.swift`
  gains SwiftMath, `bun gen`, `xcodebuild -resolvePackageDependencies` once; `Package.resolved` committed. The
  renderer, the view, the speech, the Kit section; the screens take `MathText` where the structure says.
- [ ] **Step 3: GREEN** (`bun check`: format, lint, ios with the new tests; `TokenDocumentTests` unchanged). Pictures:
  `bun shots kit-phase20` (both appearances), compared with P20-Kit-Maths side by side (a contact sheet in the
  scratchpad); the maths face is XITS: a fraction's bar, an italic x, upright digits. Commit, PR 11, merge on local green.
- [ ] **Step 4: the material's screens** (PR 12, branch `phase-20/ios-material-maths`): the seven states' fixtures from
  the boards; `bun shots sheet-maths-to5`, `sheet-maths-from6`, `sheet-board-maths`, `worked-example-maths`,
  `mock-maths` (both appearances), each against its board; Dynamic Type checked at the largest accessibility size on
  `sheet-maths-from6` (`--dynamic-type` if `bun shots` has it, else the Settings path of the runbook): the formula grows
  with the row. Print on the phone: `PDFMaker.pdf(for:)` of the class 8 sheet opened in the simulator's Files app and
  photographed (the formula drawn). Commit, PR 12, merge. Ledger line.

---

### Task 12: A kind switched off on the phone (PR 13); the nightly evals job (PR 9)

**Files (PR 13, iOS):**
- Modify: `ios/TutorCentralKit/Sources/Data/AI/APIClient.swift` (`case 503 where body?.reason == "paused": .paused(body?.error ?? …)`),
  the `APIFailure` enum (`.paused(String)`, its alert title the first sentence, the message the rest; `Equatable`),
  `Features/Make/*` (the form's call maps `.paused` to `NoticeCenter.show` with OK only), `Features/Artefacts/SheetStore+Again.swift`
  (Make it again paused: the same alert, the old sheet kept), `Features/Students/*` (the placement's call), `Features/Today`
  (the close's checks: the line reads as not made), `AppShell/LaunchState.swift` (`make-switched-off`), the fixture,
  `Tests/DataTests/APIClientTests.swift`, `Tests/DomainTests/ErrorWordsTests.swift` (the words pass), `Tests/MakeTests`

**Files (PR 9, API):**
- Create: `api/src/evals/cases.ts`, `api/src/evals/runner.ts`, `api/src/jobs/kinds/eval-run.ts`, `api/test/eval-run.test.ts`
- Modify: `api/src/jobs/kinds/index.ts` (`eval_run` when `sources.evals` is given: the Batches client and the smoke centre),
  `api/src/index.ts` (`SMOKE_CENTRE_ID` read for the evals; absent locally: the seed's centre), `api/src/claude.ts`
  (`batch(requests): Promise<{ id }>`, `batchResults(id): Promise<Map<customId, ClaudeAnswer>> | "running"` on the
  client, through `client.messages.batches.create` and `.results`), `api/src/claude-fake.ts` (the batch answered at once),
  `api/src/jobs/types.ts` (`StepContext.claude` carries the batch methods), `admin/preview/jobs.json` (an `eval_run` row),
  `admin/test/unit/jobs.test.tsx` (the subject "nightly evals")

**Interfaces:**
- `evals/cases.ts`: `loadCases(): { kind: AIKind; id: string; input: unknown; expect: Expect }[]` (the nine case files);
  `evaluate(kind, parsed, expect): { schema: boolean; verify: boolean; expect: boolean }` (the same code as
  `api/evals/assert.ts`, which imports it).
- `evals/runner.ts`: `submitDrafts(ctx, cases)`: one batch request per case (the kind's draft request as a batch
  `params` with `custom_id` the case id; each case recorded through `start_ai_call` for the smoke centre with
  `agent_step: "draft"` and key `evals:<day>:<case>` before the batch is sent, finished when the results come);
  `submitChecks(ctx, drafts)`: the check requests (`agent_step: "check"`) and the graders (the rubric as the shared block,
  the draft as the own, `CheckVerdict` as the output, on Opus 5.5, `agent_step: "grade"`) in one batch; `score(results)`:
  per kind `{ cases, schema, verify, expect, check_pass, grade_pass, cost_paise, paused }` and the gate's verdict.
- `eval-run.ts`: the steps `submit` → `wait` (a `wait` outcome with `runAt` now + 60 s until the batch ends; `ended` →
  `check`) → `check` → `wait` → `score` (`done` with the result object); a batch that errors fails the job with a retry.
  The job's `costPaise` is the rows' sum.

- [ ] **Step 1: the failing tests (PR 13).** `APIClientTests`: `a 503 with reason paused is .paused with the words`;
  `a 503 without a reason stays .offline`; `MakeTests`: `a paused answer shows the alert with OK and keeps the form`;
  `ErrorWordsTests` reads the new strings (nothing banned). **(PR 9)** `eval-run.test.ts` with the fake: `a run submits
  one draft per enabled case and skips a paused kind`; `the job waits while the batch runs and scores when it ends`; `the
  result names each kind's pass rate and the gate's verdict`; `every row carries the job id and its agent step`
  (`fakeDb().rows`).
- [ ] **Step 2: RED**, then the code of each PR.
- [ ] **Step 3: GREEN.** PR 13: `bun check`; `bun shots make-switched-off` (both appearances) against P20-Switched-Off;
  commit, merge. PR 9: `bun check --only=api,admin,tools`; a local run of the job on the fake (`run-job`'s SQL with kind
  `eval_run`) seen done with its result in `jobs.result`; the portal's Jobs page (local, by the runbook) shows "nightly
  evals" with the result in the open row; `bun admin-shots --pages /jobs` with the preview row; commit, merge. Then the
  first production night: the job queued by pg_cron at 02:05 IST, read the next morning with `--linked`: its result,
  its cost (`bun cost` against production reads the smoke centre's rows: the ledger's figure). Ledger lines.

---

### Task 13: The portal shows a call's agent step (PR 10)

**Files:**
- Modify: `admin/lib/data/types.ts` (`agentStep` on a call row and the call), `admin/app/calls/page.tsx` (the kind cell's
  sub-line "sheet · check"), `admin/app/calls/[id]/page.tsx` (the facts row "Step: check"), `admin/content/words.ts`,
  `admin/content/reasons.ts` (`paused`), `admin/preview/calls.json`, `admin/preview/call.json`,
  `admin/test/unit/calls.test.tsx`, `admin/test/unit/reasons.test.ts`

- [ ] **Step 1: the failing tests:** the list from preview holds "sheet · check" for the fixture's check row and "sheet"
  alone for a draft; the call page holds "Step" and "check"; `reasonWords("paused")` → "paused · the kind is switched
  off".
- [ ] **Step 2: RED**, then the pages (no board: the words are the trade's, the cell's grammar P19's).
- [ ] **Step 3: GREEN** (`bun check --only=admin`); `bun admin-shots --pages /calls,/calls/preview`; commit, PR 10,
  merge. `gh workflow run deploy-admin` once with PR 9's row. Ledger line.

---

### Task 14: The figure on the server for Share (the app), and the brief's and mock's maths in the app (folded)

No separate PR: PR 12 carries the brief's and mock's `MathText`; Share on a figure takes the server's file through the
existing `ServerPDF` path once the `pdf` job makes it (D93's rule unchanged); the app's figure screen keeps drawing the
figure itself. A test in `ArtefactsTests` holds `a figure's Share takes the server's file when it is on the iPhone`.

- [ ] **Step 1:** the test, RED, the one-line change in `FigureStore` (`ServerPDF.file(for:)`), GREEN, in PR 12.

---

### Task 15: The hand runs (PR 14 for what they find)

Driven by `docs/runbooks/simulator.md` (D32) against the local stack with the local API on the real models (the key in
`api/.env.local`; `AI_FAKE` unset) and the worker; the pictures kept on one issue "Phase 20 hand run". Each finding is
fixed in its own `phase-20/fix-<what>` pull request with a test that fails first (D68).

- [ ] **Run 1, a sheet with maths from Make:** More → Make something → Sheet, For a class 8 group, Maths, "Linear
  equations": the sheet comes with formulae drawn; Board shows one at the display size with its key; Key shows the
  answers; the database holds a draft row and a check row (`agent_step`), the draft's `prompt_version` `sheet@2`, a
  `tokens_cached` on the second sheet of the run (the shared block cached).
- [ ] **Run 2, a planted wrong key:** `AI_FAKE=1` with the fake's planted sheet (a fake script by `TC_FAKE_SCRIPT=wrong-proof`,
  added in Task 6's fake): the API refuses in the sheet's words after a repair; the app shows the refusal; three rows.
- [ ] **Run 3, the plan's material by the job:** Make the plan again on Today for the seed's batch: the job runs the
  sheet, worked example, figure and brief through the agents; each artefact opens with its maths drawn; the job's steps
  carry the summed cost; `bun cost --since 30m` lists draft and check rows.
- [ ] **Run 4, Share as PDF:** Share on the sheet of run 3: the server's PDF (the `pdf` job's file) opened in Files: the
  formulae in STIX Two Math; the key form on its own page; Share on the figure: the server's page.
- [ ] **Run 5, offline Share and Print:** the gateway stopped (`docker stop supabase_kong_tutor_central`), Share on a sheet
  not yet downloaded: the phone's own PDF with its formulae drawn; Print's preview the same; the gateway started again.
- [ ] **Run 6, a kind switched off:** `insert into public.ai_models (kind, step, model, effort, enabled, set_by) values
  ('sheet_from_6', 'draft', 'claude-sonnet-5-5', 'medium', false, 'hand run')` with `supabase db query --local`; within a
  minute Make the sheet shows the alert (P20-Switched-Off's words); Make the plan again: the plan comes without the sheet,
  "not made"; the row removed; a minute later the sheet comes again.
- [ ] **Run 7, Dynamic Type:** Settings → Accessibility → Larger Text at the largest accessibility size: the class 8 sheet
  and the board view; the formula grows with the words; nothing clipped.
- [ ] **Run 8, VoiceOver:** the board view with VoiceOver on (the simulator's Accessibility Inspector): the question reads
  "x over 4 minus 2 equals 1".
- [ ] **Run 9, the evals locally:** `bun evals --kinds sheet,worked_example` on the real models: the table, the gate green;
  `bun evals-changed` on a branch that changes `api/src/prompts/sheet.ts` names `sheet`.
- [ ] **Run 10, the nightly locally:** the `eval_run` job queued by SQL on the real models for two kinds (`input { kinds:
  ["check", "placement"] }` honoured by the runner for a hand run): the batch submitted, the job waiting, done within the
  hour with its result; the portal's Jobs page shows it.

---

### Task 16: Build 30 and production

- [ ] **Deploy B's smoke** green before any TestFlight run (D26: 0052 is live after Deploy A; nothing pending).
- [ ] **`gh workflow run testflight`** on `main`'s head after PR 13 and the hand runs' fixes: 1.0.0 (30); the run's log
  shows the archive's `aps-environment` as before; the ledger line with the run number.
- [ ] **The owner's step** (one list): install build 30 from TestFlight; open a sheet made after Deploy A (or Make the plan
  again): the formulae drawn; Share as PDF: the server's file with its maths. His word in the ledger.

---

### Task 17: The cost run against Phase 15's

- [ ] **Step 1: today's two plans** on the local stack with the real models, by the runbook's run-job SQL for the seed's
  two batches (as Phase 15's Task 15): `bun cost --since 30m` by kind and model, the draft and check rows apart (`--kinds`
  per kind; the step read by SQL: `select agent_step, sum(cost_paise) …`), the cached tokens per kind
  (`sum(tokens_cached)`), the repaired count (`error_reason like 'check:%'` on draft rows that were followed by a repair:
  the repair rows' count). The figure against ₹7.31.
- [ ] **Step 2: Make's nine kinds**, one each, as Phase 15's: against ₹15.23 (the sheet's ₹0.90 and ₹0.05, the worked
  example's ₹0.59, the figure's ₹0.51, the brief's ₹1.06 now carry a check; the mock, note, paper and marking are
  unchanged kinds and should read as before).
- [ ] **Step 3: the first production night's eval** (Task 12): its cost from the job's row.
- [ ] **Step 4: the ledger and the phase file** ("The cost measured"): the table, the three totals, which kinds cached and
  how much it saved, the share of calls repaired, the share refused after a repair, and the phase's whole real-call spend.

---

### Task 18: The review, the rule files, the documents (`main`)

- [ ] **The review** on Fable 5.1, two fresh reviewers as Phase 19's: (a) the API and the database (0052, the agents, the
  kinds, the evals, the nightly job, the PDFs), (b) the app and the portal (SwiftMath, `MathText`, the screens, the
  paused words, the calls page); each given this plan, the boards and the diff from this phase's first commit; every
  finding fixed with a test that failed first (D68), each in its own `phase-20/fix-<what>` pull request; the deploys for
  what they touch.
- [ ] **The rule files** (D80): `api/CLAUDE.md` (the agent, the table, the prompts' versions, `bun evals`, the nightly,
  mitex and the fonts, `SMOKE_CENTRE_ID` for the evals); `ios/CLAUDE.md` (SwiftMath, `MathText`, the maths cases,
  `.paused`); `supabase/CLAUDE.md` (`ai_models`, `agent_step`, the allowance's count, `schedule_evals`); `CLAUDE.md` (the
  commands `bun evals`, `bun prompts`; rule 8's list).
- [ ] **The documents:** "As built" in `phase-20-ai-quality-material.md` with the cost measured; `plan/README.md` (Phase 20
  built; D99 to D102 were written with the plan's approval); `STATE.md` (production: 0052, the API's commit, the evals
  secret's name, build 30); `plan/sessions/041/{record,owner-messages,ledger}.md`;
  `docs/design/information-architecture.md` if the build settled a state the boards left open; `docs/runbooks/simulator.md`
  (the switched-off run, the planted key); the resume for Phase 21 if the owner asks.

## The cost

| What | A month | Once |
|---|---|---|
| The check step on the group material | about a tenth of the draft's cost (Haiku checks Sonnet; Sonnet checks Haiku): a morning's two plans from ₹7.31 to about ₹8.30 | |
| Prompt caching | a saving where the shared block clears the model's minimum: measured by the cost run, expected on the sheet from class 6 and the brief | |
| The nightly eval (45 cases: 45 drafts, 45 checks, 45 grades on Opus, at the Batches' half price) | about ₹12 a night, ₹360 a month; the kinds' case counts are the lever | |
| The CI evals (a pull request touching one kind: 5 drafts, 5 checks, 5 grades, live) | nothing most months; about ₹5 a run | |
| promptfoo, SwiftMath, mitex, STIX Two Math | nothing (MIT, MIT, Apache-2.0, OFL) | |
| The hand runs and the two cost runs on the real models | | about ₹60 |
| The two eval runs of Task 8 and run 9, the hand-run nightly | | about ₹30 |

The nightly's ₹360 a month is the one new standing cost; it is said here so it is the owner's to keep or cut (the case
counts, or every second night) when he reads the first results.

## Self-review (done 2026-10-13)

1. **Scope coverage** (`phase-20-ai-quality-material.md`): 1 the pipeline (Tasks 4, 6; caching Task 5; `ai_models` with
   the fallback recorded Tasks 2, 3, 4); 2 prompts as artefacts with the version and hash on the row and the limits
   stated from the generated types (Task 5); 3 evals: golden sets in `api/evals/`, promptfoo self-hosted in CI on the
   kinds changed, a schema check first, rubric graders on another model, the 85% gate, the nightly through the Batches
   API with its result a row the portal shows (Tasks 8, 9, 12); 4 mathematics: LaTeX in content, SwiftMath pinned,
   Typst with mitex, the Kit's preview, Hindi and Kannada inside a formula (Tasks 10, 11); 5 the kinds moved with their
   rubric, golden set and board (Tasks 6, 8, the boards of row 28); 6 the kill switch's column and words (Tasks 2, 7,
   12). Acceptance: a sheet's equations on the phone and in its PDF, the Kit in both appearances (Tasks 10, 11, runs 1
   and 4); a prompt change with a failing eval cannot merge (Task 9, D86); the nightly's result in the database (Task
   12); the check refuses a planted wrong key (Task 4's and 6's tests, run 2); the cost run against Phase 15's (Task 17);
   pictures, hand runs, TestFlight (Tasks 11 to 16).
2. **Placeholders:** the kinds' `verify` rules and rubrics are listed in Task 6 by kind; the seed's 69 rows are
   described by their rule and held by the test; the figure's Typst drawing is listed template by template.
3. **Names across tasks:** `ai_models_current`, `p_agent_step`, `agent_step`, `tokens_cached` (2) → `models-db.ts`,
   `db.ts`, `price.ts`, `admin` (3, 4, 13); `modelFor(kind, step, classLevel)` and `installModelTable` (3) → `runAgent`
   (4) and the tests (4, 7); `Kind`, `runAgent`, `AgentOutcome`, `Finding`, `CheckVerdict`, `Proof` (4) → the kinds (6),
   the routes and jobs (6, 7), the provider and the runner (8, 12); `SystemBlocks { shared, own }` and `version` (4, 5) →
   `promptHash`, `versions.json` (5); `splitMaths` and `typstOf` (10) ↔ `MathSplit.runs` (11) through
   `maths-cases.json`; `errors.paused` and `reason: "paused"` (7) → `.paused` (12) and `reasons.ts` (13); `eval_run`,
   `schedule_evals` (2) → `eval-run.ts` (12) and the portal's subject (2, 13).
4. **Review focus:** eight lines, each with its test in its owning task.
