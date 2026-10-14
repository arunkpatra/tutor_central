# Phase 21 plan: V3 AI quality, parents and exams

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or
> superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-14 (session 42, Fable 5.1) from `phase-21-ai-quality-parents-and-exams.md`, `docs/spec-v3.md` section 4 (the
agents, the orchestrator, the cost levers, feedback, the anchor sets), Phase 20's "As built" and ledger (`plan/sessions/041/`),
the 18 boards of row 29 (`docs/design/mockups/P21-*`, "Phase 21 boards" in `docs/design/information-architecture.md`), the
first production nightly (job `a01907fc…`, D105) and the code as it is. Approved by the owner 2026-10-14 ("Boards approved, plan approved, ₹550 and decision 8 approved") with
the boards, the build's budget of about ₹550 and the nightly's cadence of decision 8. The
build runs on Opus 5.5 from `resume/041-phase-21-build.md`, inline, task by task, with one ledger
(`plan/sessions/043/ledger.md`) as sessions 22 to 41 kept.

**Goal:** every kind of AI work runs on its agent with a rubric and a golden set (the parent kinds with language and fact
checks, the exam kinds, Make's and V1's); the first nightly's nine failures are fixed or ruled; exam preparation is one job
across its days; a tutor's edits, reasons and replacements are kept as feedback; the morning's plans go through the Batches
API with the one-hour cache; the cost is a standing report in the portal; V1's results get the server's PDFs.

**Architecture:** the agent interface of Phase 20 (`src/agents/agent.ts`) unchanged; each kind moved gets
`src/agents/kinds/<kind>.ts` with a free `verify`, a rubric and a golden set, and `kindFor` answers it so routes and jobs
take it without a change of their own. A new job kind `exam_prep` owns an exam's days (the split, the mock, the gap
reports) and leans on the `plan` job for the lines. The `plan` job's material phase submits its drafts and checks as Message
Batches (`src/jobs/batch.ts`, the nightly's runner generalised) with a live fallback at a deadline. `generation_feedback`
(0057) keeps edits, reasons and replacements. The portal's Cost page reads two new functions (0058). The `pdf` job gains a
generation source for V1's results.

**Tech stack:** as Phase 20 (Supabase CLI 2.120.0, Postgres 17, pg_cron; Bun 1.3.11; Hono 4.13.13, zod 4.6.5,
`@anthropic-ai/sdk` 0.132.1, promptfoo 0.124.1, Typst 0.7.0 with mitex 0.2.7; SwiftMath 1.7.3). No new dependency, no new
plan.

**Spec:** `docs/spec-v3.md` section 4 (D73, D74), section 5 (the exam as one job), section 13 (cost); the scope
`plan/phase-21-ai-quality-parents-and-exams.md` (items 1 to 7, the acceptance); D35, D41, D55, D58, D61, D62, D64, D67, D68,
D73, D74, D76, D79, D81, D83, D84, D86, D87, D90, D93, D99 to D105; the boards of row 29.

## Global constraints

- A screen changes only to an approved board (rule 1): the 18 boards of row 29 (13 on the canvas, the five light twins in
  the mirror) and what "Phase 21 boards" settles. The sheet's Make it again, Use my own, Check a paper's screens and the
  portal's other pages are as they are.
- No technical words on screen (D41): every new string passes `ErrorWordsTests`; "check", "model", "agent", "eval",
  "batch", "refused" and "LaTeX" never reach a tutor. The portal may use the trade's words (D78).
- No AI key in the app or the repository (D11); no new secret this phase. Production is set through the signed-in CLIs
  (D87); a value is piped, never printed.
- No tutor's or student's data in a golden or anchor set (D74, D55): the seed's names (`supabase/seed.sql`), invented facts,
  pages drawn by `api/evals/draw-page.ts`, no real page or paper. `bun feedback-cases` prints candidates with the names
  replaced; a case is added by hand.
- Every Claude call is a recorded row (D76) with its `agent_step`; a batch row is priced at half (`batched` true); the
  allowance counts drafts only.
- Migrations are additive (D26): build 30 keeps working (new tables, new columns with defaults, new job kinds, new
  functions; nothing removed). The TestFlight lane refuses a build while a migration is pending: every deploy comes before
  its build.
- Bun only (D16); dependencies pinned exactly (D14); documents only go to `main` directly (D12); a pull request merges on
  local green (D86), and local green for a kind's change includes `bun evals --kinds <kind>` (D101, D103).
- Phase 20's lessons, binding: the full `bun check` before every push (partial checks let two type errors reach CI);
  never the API's database tests (`bun test` in `api/`, `bun check --only=api,db`) during a hand run (they clear the local
  jobs table: three nightly tries were lost); restart the local API after a branch switch (`--hot` served an old module
  for an hour); deploy before TestFlight while migrations are pending (D26); a CI evals run cancelled when the same kinds
  passed locally on the same words (D86) is a ruling in the ledger, never silent.
- The real-call budget is the owner's (asked once, below); the ledger sums the spend after every run that costs money,
  from the runs' own tables, never from memory (Phase 20's underestimate).

## Decisions this plan takes

The boards were shown to the owner with this plan (session 42) and approved with it; the budget and decision 8 too. Everything below was mine to decide and is stated so it can
be pushed back on. D106 to D110 go into `plan/README.md` with the plan's approval, as D99 to D102 did.

1. **The nightly's nine failures, each (D105).** A fault fixed by a free `verify` rule where it can be computed, else in the
   prompt with a version bump, else ruled a strict grade:
   - `brief-9-matter` (the slip's wrong answer miscalculated): the worked example's output gains `slipProof: Proof | null`
     (the slip's wrong working as an expression and the wrong value it gives); `verify` holds it as it holds `proof`
     (`proofHolds`) and refuses a slip whose value equals the right answer; asked in `PROOF`'s words (worked_example 5,
     brief 6).
   - `figure-3-number-line` (the caption against the drawing): `verify` for a number line: the caption carries the landing
     (`start + Σ jumps`) as digits, and a count of jumps it names ("5 jumps", "five jumps") equals `jumps.length`; the
     prompt (figure 3) says the caption names how many jumps and where they land, as drawn.
   - `figure-7-triangle` (angles labelled with side names): a strict grade. The template's rule is that `labels[i]` names
     the side opposite `angles[i]` (the app draws labels on the sides); the rubric gains the line "A triangle's labels
     name its sides, never its angles; the app draws them on the sides." The case stays.
   - `placement-4-english` (the plot asked, against D104) and `placement-7-science` (two questions in one): `verify`
     refuses a question holding more than one question mark; the prompt (placement 5) says one question, in one sentence,
     and for a story or poem only "Who is it about?" or "What is it about?" in the title's words. The Celsius doubt is a
     strict grade: the rubric gains "An answer is right by what the class's textbook teaches, not by everyday practice."
   - `plan-oct-8-science` (a chapter months early) and `plan-jan-three-groups` (a chapter not in the request's list):
     `verify`, where the syllabus data lists the class's chapters (`SYLLABI`, classes 8 to 10): the chapter must be one
     listed (either board, case-insensitive, a prefix of the printed name allowed), and its position must lie within a
     quarter of the list's length of the month's share of the school year (June is the first of ten months); the prompt
     (plan 4) says both in words.
   - `textbook-8-science` (a skill adds words the page does not say): the prompt (parse_textbook 4): "a skill repeats the
     heading's own words turned into what a student does, adding nothing"; not computable without the page's text.
   - `school-ptm` (portions holding a day and time): `verify`: a notice's or holiday's `portions` is null (portions belong
     to an exam or homework); the prompt (parse_school 4) says so.
   All in one pull request (they share `schemas.ts` through `slipProof`), so CI runs the nine kinds once; each kind's
   evals green locally first (D103).
2. **The exam as one job (D106).** A job kind `exam_prep`, one per exam item, keyed `exam:<item>`, queued by a trigger when
   an exam item is confirmed and by `schedule_exam_preps` (00:10 IST daily) for every exam in its window with no live job.
   Its steps: `split` (the days from `src/plan/exam-prep.ts` for the item's students, written to `school_items.preparation`
   so the page and the plan read one split), `wait` until the mock day's 05:00 IST, `mock` (the mock's agent keyed
   `mock:<item>`, kept and linked by the day's plan as today), then `marks` each fifteen minutes to the exam day: for each
   student with a mark on the item and no gap report, the gap report's agent keyed `gap:<item>:<student>` (the tallies by
   skill computed on the server from the mark's questions and the mock's skills: `src/plan/gap.ts`, the port of Domain's
   `GapTallies`, held equal by `tools/contract/gap-cases.json`), kept with `used_at` set, then `request_plan` with
   `replace` for the batch's open days (today's plan if not closed), so the last days change by the plan's own rules;
   `done` on the exam day. Marking stays Check a paper at a tap (the photo is the phone's; the tutor decides the marks) on
   the `check_paper` agent; the Save of marks calls `request_exam_prep`, which wakes the waiting job at once. The page reads
   the job's state for its rows (jobs are a member's to read): Being made, Not made with Try again (`request_exam_prep`),
   Working, Changed. The gap report screen's Use this plan becomes the done row once `used_at` is set.
3. **Feedback (D107).** `generation_feedback` (0057): `id`, `centre_id`, `generation_id` (composite to `ai_generations`),
   `student_id` (composite, cascade, for a personal kind), `kind` (`edit`, `again`, `replace`), `reason` (200), `revised`
   (jsonb: the sent text or the replacement's shape; never a photo), `created_at`, `updated_at`; RLS through `is_member`;
   written only through `record_feedback(p_centre, p_generation, p_kind, p_reason, p_revised)`. Written at: a note's Send
   when the text differs from the draft (`edit`, the sent text); every Make it again and Write again with its reason
   (`again`, on the old generation); Use my own (`replace`, the typed text or `{"photo": true}`). The brief, the mock and
   the note get a reasons menu (the boards); the sheet keeps its own. Read by the portal (the call page's Feedback row) and
   by `bun feedback-cases` (the eval set's growth: candidates printed with the seed's names).
4. **Batches for the morning's plans (D108).** The `plan` job's material phase: `make:submit` sends every request's draft
   as one Message Batch (each a started row keyed `<job>:make:<n>`, `batched` true), `make:wait` polls each minute,
   `make:check` runs `verify` and sends the checks as a second batch, `make:repair` makes the few repairs live and keeps
   each artefact as today. The shared block carries `cache_control: { type: "ephemeral", ttl: "1h" }` for a job's calls
   (the morning's plans across centres fall within the hour) and stays five minutes for a tap. A batch not ended by the
   deadline (`run_at` + 4 h, and never past 90 minutes before the batch's start) is left and the rest made live by the
   path of today. `schedule_plans` queues the job at 00:05 IST (was 05:30) so the batch has the night. The note day stays
   live (the tutor opens it at the hour it is made) and so does every tap.
5. **The standing cost report (D109).** `ai_generations.batched boolean not null default false` (0057), set by the batch
   finish; `models.json` gains `cachedUsdPerMillion` per model (Opus 5.5 0.20, Sonnet 5.5 0.20, Haiku 5.5 0.01, checked
   against the pricing page by the build) and `price.ts` reads it; 0058's `admin_cost_by_step(month, centre)` (kind, step,
   model, batched, calls, paise) and `admin_cost_by_month(centre)` (six months: calls, paise, batched paise, active centres,
   per active centre); the Cost page per the boards. The session cost runs of Phases 12 to 20 are retired as a practice:
   one last run against Phase 20's figures proves the report, and from then the report is the figure.
6. **The anchor sets (D110).** `api/evals/anchors/hi/cases.json` and `kn/cases.json`: eight notes each (four weekly notes,
   two can-now-do, one test tomorrow, one not on track) with the seed's names and invented weeks; a `verify` rule every
   message kind shares: at least 85% of the message's letters are in the language's script (Devanagari for Hindi, Kannada
   for Kannada, Latin for Hinglish and English) and the English is Latin; the native speaker's labels (script fidelity 0 to
   2, code-mixing 0 to 2, meaning kept, natural 1 to 5, a corrected version) are the owner's to arrange by
   `docs/testing/anchor-labelling.md`; until they come the anchors run under the free checks alone, and the labels become
   each case's `contains` words and the rubric's examples.
7. **The kinds moved and their rubrics.** The parents' (`note`, `can_do`, `test_tomorrow`, `not_on_track`): facts only from
   the request (a number in the message is one the facts hold), the parent's language and script, the length, the tutor's
   own words carried whole, no sign-off, no blame. The exam's (`mock`: marks sum to the pattern, questions numbered 1 to n
   across sections, two to six skills, proofs hold, maths; `gap_report`: one line per day left, titles short; `check_paper`:
   every scheme question once, marks within its own, the summary; `read_marks`: score within max, ISO dates). Make's and
   V1's (`paper`: the sections as `sectionPlan` gives them, numbered through; `homework`, `worksheet`: exactly the questions
   asked; `progress_note`: four to six sentences, first names, no sign-off; `scan_register`: names capitalised, phones
   normalised or null). The planted test for the parents: a note naming a test the facts do not hold is refused.
8. **The nightly grows with the kinds** (the owner's question below): the nine kinds and the job kinds nightly
   (`eval_run` input `kinds` by `schedule_evals`), the tap kinds on Sundays, unless the owner keeps every kind nightly.
9. **V1's results on the server's PDFs** (D90's last half, no new decision): the `pdf` job gains input `generation_id`
   (a `paper`, `homework` or `worksheet` row), rendered by `src/pdf/paper.ts` (the sections with their marks each, the key
   on its own last page) to `<centre>/gen-<id>.pdf`, queued by the API as the platform when such a row finishes ok;
   Share on a V1 result takes `ServerPDF` by generation id (D93's rule), else draws on the phone.
10. **The check step's price.** A Haiku draft's Sonnet check costs three to ten times the draft (the reads). No change
    here: `ai_models` can move a check to Haiku without code, and the report shows the step's cost; Phase 22's control
    page is where the owner changes it.
11. **Launch states** (decision 14 of "Phase 20 boards"' kind): `brief-again`, `mock-again`, `note-again`, `note-set-aside`,
    `today-note-day-set-aside`, `school-last-days-mock-making`, `school-last-days-mock-failed`,
    `school-last-days-gap-working`, `school-last-days-changed`, `gap-report-used`, each with its fixture carrying the
    board's content.
12. **The portal** gains the Feedback row on a call's page and the Cost page's parts; the Jobs page shows `exam_prep` as
    any job (subject: the exam's title). No board for the Feedback row: the facts row's grammar is P19-Call's and the words
    the trade's (D78), as Phase 20's agent step was.
13. **Branches and the ledger.** `phase-21/<slug>` in the main checkout, one per pull request; the ledger
    `plan/sessions/043/ledger.md`, written after each named test run, each ruling with its cost if wrong, the spend summed
    from the tables after every paid run.
14. **Order of deploys.** Deploy A after PR 2 (0057, the nightly's fixes, the parent kinds): production's notes go through
    the check. Deploy B after PR 7 (the exam job, the exam kinds). Deploy C after PR 10 (batches, 0058, the cost report,
    V1's PDFs). The app ships once, build 31, after PR 13 and the hand runs. The portal deploys after PR 11.

## Review focus

What a person meets that no happy path exercises, most likely to bite first. Each line names its test in the task that
owns the code.

1. **A note refused twice for a true fact.** The record says "8 of 12" and the model writes "eight of twelve": the number
   rule must read words as numbers, or every Hindi note is set aside. Task 3's `a number written in words counts as the
   facts' number` and `a number the facts do not hold is a finding`.
2. **A batch that never ends.** Anthropic's batch runs past the morning: the plan must still be there at 06:00 by the live
   path, and nothing paid twice. Task 8's `a batch not ended by the deadline is left and the rest is made live, each row
   once`.
3. **Marks saved before the mock day's job woke.** A tutor marks a paper at 20:00; the job is waiting until its next
   quarter hour: `request_exam_prep` must wake it and the gap report must land within a minute, not fifteen. Task 6's
   `a saved mark wakes the waiting job at once`.
4. **A second exam job for the same item.** The trigger and the schedule both queue: one job, keyed `exam:<item>`, and a
   finished job is not queued again for a past exam. Task 5's `the trigger and the schedule queue one job`.
5. **A regeneration's reason reaching the parent.** "Less about marks" is an instruction to the model, never a sentence in
   the note: Task 3's rubric line and Task 4's `the reason is not in the message` test.
6. **A feedback row for a note the tutor did not change.** Send with the draft unchanged writes nothing; a one-character
   edit writes one row: Task 4's `an unchanged send writes no feedback`.
7. **The cost report on a month with no batched row.** "Batched ₹0 · 0%", never a division by zero or a missing row: Task
   10's `a month with no batched row shows zero`.
8. **A V1 result whose PDF job has not run.** Share on a paper made a second ago draws on the phone (D93) and shares the
   server's file next time: Task 12's `Share takes the server's file once it is on the iPhone`.

## File structure

Created or changed, by part. A file has one job.

**Database (`supabase/`)**
- `migrations/20261130000057_v3_exam_job_feedback.sql`: `job_kind` gains `exam_prep`; `school_items.preparation jsonb`;
  `request_exam_prep`, `schedule_exam_preps` and its cron, the trigger `school_items_exam_prep`; `generation_feedback` with
  `record_feedback`; `ai_generations.batched`; `admin_job_subject` for `exam_prep`; `pdf` job input by generation.
- `migrations/20261201000058_v3_cost_report.sql`: `admin_cost_by_step`, `admin_cost_by_month`; `admin_call` with its
  `feedback`.
- `tests/exam-job.test.ts`, `tests/feedback.test.ts`, `tests/cost-report.test.ts` (new); `tests/rls.test.ts` (the
  catalogue), `tests/admin-reads.test.ts`, `tests/schedules.test.ts`, `types.ts`, `seed.sql` (a marked mock for the exam's
  hand run).

**API (`api/`)**
- `src/agents/kinds/{note,can-do,test-tomorrow,not-on-track,progress-note,mock,gap-report,check-paper,read-marks,paper,homework,worksheet,scan-register}.ts`,
  `src/agents/kinds/message.ts` (the shared message rules: the script, the numbers, the sign-off), `src/agents/kinds/index.ts`.
- `src/agents/kinds/{brief,figure,placement,plan,parse-textbook,parse-school,worked-example}.ts` (Task 1's rules),
  `src/prompts/{worked-example,brief,figure,placement,plan,parse-textbook,parse-school}.ts` (the bumps), `src/prompts/shared.ts`
  (`PROOF` with the slip), `src/schemas.ts` (`slipProof`), `src/prompts/versions.json`.
- `src/jobs/kinds/exam-prep.ts` (new), `src/jobs/kinds/index.ts`, `src/jobs/record.ts` (the exam's read), `src/jobs/db.ts`
  (`markedStudents`, `keepGapReport`, `writePreparation`, `wakeJob`), `src/plan/gap.ts` (new, `tools/contract/gap-cases.json`).
- `src/jobs/batch.ts` (new: the batch runner over a list of `Kind` requests, shared by the nightly and the plan),
  `src/jobs/kinds/plan.ts` (the `make:*` steps), `src/jobs/kinds/eval-run.ts` (over `batch.ts`), `src/claude.ts` (the shared
  block's `ttl`), `src/db.ts` (`batched`), `src/price.ts` (`cachedUsdPerMillion`), `models.json`.
- `src/routes/ai.ts`, `src/routes/v2.ts` (`kindFor` for every kind; the V1 finish queues the PDF), `src/make.ts` (`makeAgent`
  answers every kind; `fromRequest` retired), `src/pdf/paper.ts` (new), `src/jobs/kinds/pdf.ts` (the generation source).
- `src/evals/cases.ts` (`EVAL_KINDS` grows; the anchors), `evals/<kind>/cases.json` and `rubric.md` for thirteen kinds,
  `evals/anchors/{hi,kn}/cases.json`, `evals/draw-page.ts` (a marked answer sheet, a report card, a register page).
- Tests: `test/kinds-parents.test.ts`, `test/kinds-exam.test.ts`, `test/kinds-v1.test.ts`, `test/kinds.test.ts` (Task 1),
  `test/exam-prep-job.test.ts`, `test/gap.test.ts`, `test/batch.test.ts`, `test/plan-job.test.ts`, `test/price.test.ts`,
  `test/pdf-paper.test.ts`, `test/evals-cases.test.ts`, `test/prompt-versions.test.ts`.

**Tools and workflows**
- `tools/feedback-cases.ts` (+ test), `tools/contract.ts` (the gap cases, the rubrics), `tools/evals-changed.ts` (the new
  kinds' files), `tools/check/steps.ts`, `package.json` (`feedback-cases`), `.github/workflows/evals.yml` (unchanged paths).

**iOS (`ios/`)**
- `Sources/Data/Feedback/FeedbackRepository.swift` (`record_feedback`), `Sources/Domain/Feedback/Feedback.swift`,
  `Sources/Features/Artefacts/{BriefStore,BriefView,MockStore,MockView,NoteStore,NoteView,NoteStore+Make,SheetStore+Again,SheetStore+Own}.swift`
  (the reasons menus, the feedback writes, the set-aside card), `Sources/Features/Make/{NoteResultView,AIStore+Generate,GenerationResult+PDF}.swift`,
  `Sources/Features/Today/{NoteDayStore,NoteDaySections}.swift` (the set-aside row), `Sources/Features/School/{ItemStore+LastDays,LastDaysSections,ItemStore+Preparation}.swift`
  (the job's states, Try again), `Sources/Features/Artefacts/{GapReportStore,GapReportView}.swift` (the done row),
  `Sources/Data/Jobs/JobsRepository.swift` (`request_exam_prep`, the exam job's read), `Sources/AppShell/LaunchState.swift`,
  `RootView+LaunchStates.swift`, the fixtures.
- Tests: `DomainTests/FeedbackTests`, `DataTests/FeedbackRepositoryTests`, `ArtefactsTests` (the menus, the set-aside,
  the done row), `SchoolTests` (the rows' states), `TodayTests` (the set-aside row), `ErrorWordsTests`.

**Admin (`admin/`)**: `app/cost/page.tsx`, `content/cost.ts`, `lib/data/{types,real,preview}.ts`, `preview/cost.json`,
`app/calls/[id]/page.tsx` (the Feedback row), `preview/call.json`, `preview/jobs.json` (an `exam_prep` row),
`test/unit/cost.test.tsx`, `test/unit/calls.test.tsx`.

**Documents:** `api/CLAUDE.md`, `ios/CLAUDE.md`, `supabase/CLAUDE.md`, `admin/CLAUDE.md`, `CLAUDE.md` (the command
`bun feedback-cases`; the cost runs retired), `plan/README.md` (D106 to D110 with the plan's approval; the phase's status),
`plan/phase-21-ai-quality-parents-and-exams.md` ("As built"), `plan/STATE.md`, `plan/sessions/043/`,
`docs/design/information-architecture.md` (a state the build settles), `docs/runbooks/simulator.md` (the exam's hand run,
the set-aside note), `docs/testing/anchor-labelling.md` (new), `docs/testing/device-tests.md` (a note in Kannada read on a
real iPhone).

## Pull requests

| PR | Task | Branch | Title | Pictures |
|---|---|---|---|---|
| 1 | 1 | `phase-21/nightly-findings` | The first nightly's nine failures: the slip's proof, the caption's landing, one question, a chapter from the list in its month, a notice without portions; the rubric lines ruled | none |
| 2 | 2, 3 | `phase-21/db-feedback-exam` and `phase-21/api-parents` | Migration 0057; the parents' kinds on their agents with the message rules, the planted test, the golden sets | none |
| 3 | 3 | `phase-21/anchors` | The Hindi and Kannada anchor sets and the labelling guide | none |
| 4 | 4 | `phase-21/ios-feedback` | The reasons menus on the brief, the mock and the note; feedback written at an edit, a reason and a replacement; the set-aside note and row | brief-again, mock-again, note-again (both), note-set-aside (both), today-note-day-set-aside |
| 5 | 5 | `phase-21/api-exam-kinds` | The mock, the gap report, marking and read-marks on their agents, with their golden sets | none |
| 6 | 6 | `phase-21/api-exam-job` | The `exam_prep` job: the split, the mock on its morning, the gap reports as marks come, the plan changed | none |
| 7 | 7 | `phase-21/ios-exam-job` | The exam page reads the job: Being made, Not made with Try again, Working, Changed; the gap report's done row; Save wakes the job | school-last-days-mock-making, -mock-failed, -gap-working, -changed (both), gap-report-used |
| 8 | 8 | `phase-21/api-batches` | The plan's material through the Batches API with the one-hour cache and the live fallback; the nightly over the same runner | none |
| 9 | 9 | `phase-21/api-v1-kinds` | Make's and V1's kinds on their agents with their golden sets; V1's PDFs on the server | a paper's page (P21-PDF-Paper) |
| 10 | 10 | `phase-21/db-cost-report` and `phase-21/admin-cost` | Migration 0058; the Cost page by kind, model and step, by month, batched at half; the call page's Feedback row | /cost and /calls/preview (admin-shots, 1280 and 390, both) |
| 11 | 11 | `phase-21/evals-schedule` | `schedule_evals` names the nightly's kinds; `bun feedback-cases` | none |
| 12 | 12 | `phase-21/ios-v1-pdf` | Share on a V1 result takes the server's file | none (the file is the picture of PR 9) |
| 13 | 14 | `phase-21/hand-runs` | What the hand runs find (D68) | the hand runs' pictures on the issue |

Every PR with pictures carries them by `bun pr-shots` (D7): `bun shots <state>` for the app, `bun admin-shots --pages …`
for the portal, a rendered PDF's page one by `sips -s format png`.

## The order

Task 1 → 2 → 3 (Deploy A) → 4 → 5 → 6 → 7 (Deploy B) → 8 → 9 → 10 → 11 (Deploy C, the portal) → 12 → 13 (the hand runs) →
14 (build 31) → 15 (the cost proof) → 16 (the review, the documents). Task 4 needs 2's table; Task 7 needs 6's job; Task 12
needs 9's file. The owner's question (the budget) is asked at the start and answered before Task 1's real runs.

---

### Task 1: The first nightly's nine failures (PR 1, D105)

**Files:**
- Modify: `api/src/schemas.ts` (`WorkedExampleOutput.slipProof`), `api/src/prompts/shared.ts` (`PROOF`),
  `api/src/prompts/worked-example.ts` (VERSION "5"), `brief.ts` ("6"), `figure.ts` ("3"), `placement.ts` ("5"), `plan.ts`
  ("4"), `parse-textbook.ts` ("4"), `parse-school.ts` ("4"), `api/src/agents/kinds/{worked-example,figure,placement,plan,parse-school}.ts`
  (the rules), `api/src/agents/kinds/{figure,placement}.ts` (the rubric lines), `api/src/prompts/versions.json` (`bun prompts
  --write`), `api/evals/{figure,placement}/rubric.md` (`bun contract`), `api/src/claude-fake.ts` (the samples' `slipProof`)
- Test: `api/test/kinds.test.ts`, `api/test/prompts.test.ts`

**Interfaces:**
- Produces: `WorkedExampleOutput.slipProof?: Proof | null`; `workedExampleFindings(example, at)` holds both proofs;
  `numberLineCaptionFindings(figure, caption): Finding[]`; `oneQuestionFindings(questions): Finding[]`;
  `chapterInSyllabus(classLevel, subject, chapter): { listed: boolean; share?: number; count?: number }` in
  `src/agents/kinds/plan.ts`; `parse_school`'s `verify` with the portions rule.

- [ ] **Step 1: the failing tests** (`api/test/kinds.test.ts` gains):

```ts
test("a slip whose wrong answer does not follow from its working is a finding; a slip equal to the right answer too", () => {
  const example = { problem: "p", steps: [{ title: "a", working: "b" }, { title: "c", working: "d" }], slip: "A common slip here: 27 − 273 = 246.", proof: { expression: "27+273", equals: 300 }, slipProof: { expression: "27-273", equals: 246 } };
  expect(workedExampleFindings(example).map((f) => f.item)).toEqual(["slip"]);
  expect(workedExampleFindings({ ...example, slipProof: { expression: "27-273", equals: -246 } })).toEqual([]);
  expect(workedExampleFindings({ ...example, slipProof: { expression: "27+273", equals: 300 } }).map((f) => f.problem)).toContain("the slip's value equals the right answer");
});

test("a number line's caption names the landing and the jumps as drawn", () => {
  const figure = { kind: "number_line", from: 0, to: 20, step: 1, start: 3, jumps: [5] } as const;
  expect(numberLineCaptionFindings(figure, "Start at 3 and take 5 jumps to land on 8.").map((f) => f.problem)).toEqual(["the caption says 5 jumps; the figure draws 1"]);
  expect(numberLineCaptionFindings(figure, "Start at 3 and jump 5 to land on 8.")).toEqual([]);
  expect(numberLineCaptionFindings(figure, "Start at 3 and jump 5 to land on 9.").map((f) => f.problem)).toEqual(["the caption does not name the landing, 8"]);
});

test("a placement question asks one thing", () => {
  expect(oneQuestionFindings([{ chapter: "Heat", question: "What measures temperature? And in what unit?", answer: "A thermometer, in degree Celsius" }]).map((f) => f.item)).toEqual(["Heat"]);
  expect(oneQuestionFindings([{ chapter: "Heat", question: "What do we measure temperature with?", answer: "A thermometer" }])).toEqual([]);
});

test("the plan's chapter is one the syllabus lists, at the month's place in the year", () => {
  expect(chapterInSyllabus("8", "English", "Reported speech")).toEqual({ listed: false, count: expect.any(Number) });
  const light = chapterInSyllabus("8", "Science", "Light: Mirrors and Lenses");
  expect(light.listed).toBe(true);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }, { groups: [{ groupNo: 1, chapter: "Light: Mirrors and Lenses", skill: "s" }] }).map((f) => f.item)).toEqual(["group 1"]);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-10-13", month: 10, groups: [{ groupNo: 1, classLevel: "8", subject: "Science" }] }, { groups: [{ groupNo: 1, chapter: "Exploring Forces", skill: "s" }] })).toEqual([]);
  expect(plan.verify?.({ centreId: "x", classId: null, date: "2026-06-16", month: 6, groups: [{ groupNo: 1, classLevel: "5", subject: "EVS" }] }, { groups: [{ groupNo: 1, chapter: "Super Senses", skill: "s" }] })).toEqual([]);
});

test("a notice or a holiday carries no portions", () => {
  const input = { text: "PTM on Saturday 17 October, 9 am to 12 noon.", image: null, today: "2026-10-13", schools: [], classLevels: ["8"] };
  const item = { kind: "notice", title: "PTM", subject: null, date: "2026-10-17", endDate: null, classLevel: null, school: null, studentName: null, portions: "Saturday 9 am to 12 noon" } as const;
  expect(parseSchool.verify?.(input, { items: [item] }).map((f) => f.problem)).toEqual(["a notice has no portions"]);
  expect(parseSchool.verify?.(input, { items: [{ ...item, portions: null }] })).toEqual([]);
});
```

  `prompts.test.ts`: `PROOF asks for the slip's proof` (the words "the slip's wrong value" in the worked example's and
  the brief's shared block); `the figure prompt asks the caption for the jumps and the landing`; `the placement prompt
  asks one question in one sentence`; `the plan prompt asks a listed chapter at the month's place`; `the textbook prompt
  asks a skill to add nothing`; `the school prompt gives a notice no portions`.
- [ ] **Step 2: RED** (`cd api && bun test test/kinds.test.ts test/prompts.test.ts`). Ledger line.
- [ ] **Step 3: the rules and the words.** `schemas.ts`: `slipProof: Proof.nullish()` on `WorkedExampleOutput`; `shared.ts`'s
  `PROOF` gains "Give the slip's wrong working the same way, as slipProof: the expression a student who makes the slip
  would write and the wrong value it gives; it must differ from the right answer." The month's share:
  `share = (month + 6) % 12` for June as 0 to March as 9; the chapter's index `i` of `count` is in place when
  `|i / count − share / 10| ≤ 0.25`; a class with no syllabus list (below 8, ICSE) has no finding. The caption rule reads
  digits and the number words one to twelve. The one-question rule counts `?` after trimming a trailing one.
- [ ] **Step 4: `bun prompts --write`, `bun contract`** (the rubrics with their new lines; the fake's samples with a
  `slipProof`); `bun check --only=format,api,tools,ios` (ContractTests decode the samples).
- [ ] **Step 5: the kinds' evals locally** (`bun evals --kinds worked_example,brief,figure,placement,plan,parse_textbook,parse_school`,
  about ₹70): each kind green (D103); a case still failing is looked at case by case and the rule or the words fixed in
  this PR; the ledger line with each kind's rate and ₹.
- [ ] **Step 6: GREEN** (`bun check`). Commit, PR 1; CI runs the nine kinds once (shared files changed, about ₹95); merge on
  local green (D86) and say so if CI's run is cancelled. Ledger line.

---

### Task 2: Migration 0057: the exam job's kind and request, `generation_feedback`, a call's `batched`, the PDF by generation (PR 2a)

**Files:**
- Create: `supabase/migrations/20261130000057_v3_exam_job_feedback.sql`, `supabase/tests/exam-job.test.ts`,
  `supabase/tests/feedback.test.ts`
- Modify: `supabase/tests/rls.test.ts` (`generation_feedback` among the centre tables with its probe), `tests/schedules.test.ts`
  (the fifth schedule), `tests/admin-reads.test.ts` (the subject), `supabase/types.ts`, `supabase/seed.sql` (a marked mock on
  the Evening batch's exam: Dev's `marks` row with `questions`), `api/src/generated/*` (`bun contract`)

**Interfaces:**
- Produces: `alter type public.job_kind add value 'exam_prep'`; `school_items.preparation jsonb` (the split:
  `[{ "day", "kind", "index", "title", "skills", "skill_ids" }]`, null until the job writes it);
  `request_exam_prep(p_centre uuid, p_item uuid) returns uuid` (security invoker, `tc.jobs` set: one live job keyed
  `exam:<item>`; a waiting one is woken: `run_at = now()`; an exam item only, in its window, else `not_found`);
  `schedule_exam_preps(p_now timestamptz default now()) returns integer` (every exam in its window with no live job, as
  the platform; cron `schedule_exam_preps` at `40 18 * * *`, 00:10 IST); the trigger `school_items_exam_prep` after insert
  or update of `date`, `portions`, `window_days` on an exam with `confirmed_at` set, calling `request_exam_prep` (the
  member's own transaction; `tc.jobs` set inside); `generation_feedback` as decision 3 with `record_feedback(p_centre
  uuid, p_generation uuid, p_kind text, p_reason text, p_revised jsonb) returns uuid` (a member of the generation's
  centre; `again` needs a reason, `edit` and `replace` a `revised`); `ai_generations.batched boolean not null default
  false` with the platform's update grant; `admin_job_subject` answers the exam's title for `exam_prep`; `jobs.input`
  for `pdf` may name `generation_id` (no schema change: jsonb).

- [ ] **Step 1: the failing tests** (`supabase/tests/exam-job.test.ts`, the admin tests' frame):

```ts
test("a confirmed exam in its window queues one exam_prep job; the schedule queues no second", async () => {
  const item = await a.rpc("add_school_item", { ...examNineDaysOut(centreA, schoolA) });
  const [job] = await sql`select id, kind, state from public.jobs where centre_id = ${centreA} and idempotency_key = ${`exam:${item.data}`}`;
  expect(job).toMatchObject({ kind: "exam_prep", state: "queued" });
  expect((await svc.rpc("schedule_exam_preps")).data).toBe(0);
  await sql`update public.jobs set state = 'done', finished_at = now() where id = ${job.id}`;
  expect((await svc.rpc("schedule_exam_preps")).data).toBe(1);
});

test("request_exam_prep wakes a waiting job at once and refuses an item of another centre", async () => {
  const [job] = await sql`select id from public.jobs where idempotency_key = ${`exam:${itemA}`} and state <> 'done' limit 1`;
  await sql`update public.jobs set state = 'waiting', run_at = now() + interval '15 minutes' where id = ${job.id}`;
  await a.rpc("request_exam_prep", { p_centre: centreA, p_item: itemA });
  const [woken] = await sql`select run_at <= now() as due from public.jobs where id = ${job.id}`;
  expect(woken.due).toBe(true);
  expect((await b.rpc("request_exam_prep", { p_centre: centreA, p_item: itemA })).error?.message).toContain("not_a_member");
});

test("the platform writes the split and a member reads it", async () => {
  await svc.from("school_items").update({ preparation: [{ day: "2026-10-09", kind: "revise", index: 1, title: "Balancing equations", skills: ["Balance a chemical equation"], skill_ids: [] }] }).eq("id", itemA);
  const { data } = await a.from("school_items").select("preparation").eq("id", itemA).single();
  expect(data?.preparation).toHaveLength(1);
});
```

  `feedback.test.ts`: `a member records an edit, a reason and a replacement on their own generation`; `again without a
  reason is refused; edit without revised is refused`; `a member of another centre records nothing and reads nothing`;
  `a feedback row goes with the student` (the cascade); `the platform updates batched`. The catalogue's probe row:
  `{ generation_id: <a probe row's>, kind: "again", reason: "shorter" }`.
- [ ] **Step 2: RED** (`cd supabase && bun test tests/exam-job.test.ts tests/feedback.test.ts --timeout 20000`). Ledger line.
- [ ] **Step 3: the migration**, in 0046's style for the enum and 0037's for the request:

```sql
-- Phase 21 (D106, D107): exam preparation as one job, a tutor's feedback kept, a batched call marked, the subject of the job.
alter type public.job_kind add value 'exam_prep';
alter table public.school_items add column preparation jsonb check (preparation is null or jsonb_typeof(preparation) = 'array');

create table public.generation_feedback (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  generation_id uuid not null,
  student_id uuid,
  kind text not null check (kind in ('edit', 'again', 'replace')),
  reason text check (reason is null or char_length(reason) between 1 and 200),
  revised jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  foreign key (centre_id, generation_id) references public.ai_generations(centre_id, id) on delete cascade,
  foreign key (centre_id, student_id) references public.students(centre_id, id) on delete cascade,
  check ((kind = 'again' and reason is not null) or (kind <> 'again' and revised is not null))
);
-- … index on (centre_id, generation_id), set_updated_at, RLS select through is_member, no insert for members (the function), grants.
```

  `record_feedback` (security invoker, `set search_path = ''`): checks `is_member`, reads the generation's `student_id`
  for the row, inserts, answers the id. `ai_generations.batched` with `grant update (batched)` to `service_role`.
  `request_exam_prep` as `request_plan`'s shape over `request_job` with `'exam_prep'`, `jsonb_build_object('item_id',
  p_item)`, and before it `update public.jobs set run_at = now() where … state = 'waiting'`. `schedule_exam_preps`:
  exams with `confirmed_at` set, `date` within `window_days` (null as 14) of India's day and not past, no job of the key
  queued, waiting or running; one insert each with `tc.jobs` set, `on conflict do nothing`.
- [ ] **Step 4: the catalogue, the types, the seed.** `rls.test.ts`: `generation_feedback` in `CENTRE_TABLES` with its probe;
  the definers stay four. `supabase gen types typescript --local > types.ts`; `bun contract`. The seed: Dev's `marks` row
  on the Evening batch's exam with `questions` (eight rows, a weak skill), so the hand run has a marked mock.
- [ ] **Step 5: GREEN** (`bun check --only=db,tools,api`). Commit, PR 2a, merge on local green. Ledger line.

---

### Task 3: The parents' kinds on their agents; the planted test; the anchor sets (PRs 2b and 3)

**Files:**
- Create: `api/src/agents/kinds/message.ts`, `api/src/agents/kinds/{note,can-do,test-tomorrow,not-on-track}.ts`,
  `api/evals/{note,can_do,test_tomorrow,not_on_track}/cases.json`, `api/evals/anchors/{hi,kn}/cases.json`,
  `docs/testing/anchor-labelling.md`, `api/test/kinds-parents.test.ts`
- Modify: `api/src/agents/kinds/index.ts`, `api/src/make.ts` (`makeAgent` answers these through `kindFor`),
  `api/src/claude-fake.ts` (the planted script `TC_FAKE_SCRIPT=invented-fact`), `api/src/evals/cases.ts` (`EVAL_KINDS`, the
  anchors loaded under `anchor_hi`, `anchor_kn`), `api/src/prompts/{note,can-do,test-tomorrow,not-on-track}.ts` (VERSION
  "3": the reason's words, the number rule said), `api/src/prompts/versions.json`, `tools/evals-changed.ts` (the anchors'
  folder names their kind), `api/test/evals-cases.test.ts`

**Interfaces:**
- Produces: `messageFindings(input: { language: Language; studentName: string; parentName?: string; facts: string[]; tutorSays?: string }, draft: MessageOutput): Finding[]`
  (the script share by `scriptShare(text, language)`, the numbers by `numbersOf(text)` with the words one to twelve and
  Hindi and Kannada numerals read as digits, the sign-off words, the tutor's own words in the English or the message); the
  four kinds, each `rubric([...])` with `MESSAGE_RUBRIC` lines; `Kind.student` kept; `WeeklyNoteInput` gains `reason?: string`
  (200) as `SheetInput` has, so Write again's reason reaches the prompt (`schemas.ts`: a small change, the shared-file run
  of CI is this PR's, batched with Task 1's merge order: this PR follows PR 1).

- [ ] **Step 1: the failing tests** (`api/test/kinds-parents.test.ts`):

```ts
const facts = ["Taught: balancing equations, types of reactions", "Got right: 8 of 12 checks", "To practise: the numbers in front of a formula"];
const who = { language: "hi" as const, studentName: "Dev Kumar", parentName: "Ramesh Kumar", facts };

test("a number the facts do not hold is a finding; a number written in words counts as the facts' number", () => {
  expect(messageFindings(who, { message: "देव ने 12 में से 8 सवाल सही किए।", english: "Dev got 8 of 12 right." })).toEqual([]);
  expect(messageFindings(who, { message: "देव ने 12 में से 9 सवाल सही किए।", english: "Dev got 9 of 12 right." }).map((f) => f.problem)).toEqual(["9 is not in the facts"]);
  expect(messageFindings({ ...who, language: "en" }, { message: "Dev got eight of twelve right.", english: "Dev got eight of twelve right." })).toEqual([]);
});

test("the message is in the parent's script; the English is English", () => {
  expect(messageFindings(who, { message: "Dev did well this week.", english: "Dev did well this week." }).map((f) => f.item)).toEqual(["script"]);
  expect(messageFindings({ ...who, language: "kn" }, { message: "ದೇವ್ ಈ ವಾರ ಚೆನ್ನಾಗಿ ಮಾಡಿದ್ದಾನೆ.", english: "Dev did well this week." })).toEqual([]);
  expect(messageFindings({ ...who, language: "hinglish" }, { message: "Dev ne is hafte accha kiya.", english: "Dev did well this week." })).toEqual([]);
});

test("a sign-off is a finding; the tutor's own words are carried whole", () => {
  expect(messageFindings({ ...who, language: "en" }, { message: "Dev did well. Regards, Meera", english: "Dev did well. Regards, Meera" }).map((f) => f.item)).toEqual(["sign-off"]);
  const says = "Please send the fee by Friday";
  expect(messageFindings({ ...who, language: "en", tutorSays: says }, { message: `Dev did well. ${says}.`, english: `Dev did well. ${says}.` })).toEqual([]);
  expect(messageFindings({ ...who, language: "en", tutorSays: says }, { message: "Dev did well. Send the fee.", english: "Dev did well. Send the fee." }).map((f) => f.item)).toEqual(["the tutor's words"]);
});

test("a note naming a fact not in the record is refused after a repair (the planted test)", async () => {
  process.env.TC_FAKE_SCRIPT = "invented-fact";
  const out = await runAgent(ctx(fakeDb(), fakeClaude()), note, noteInput({ language: "en" }));
  expect(out).toMatchObject({ kind: "failed", words: "refused" });
  expect(out.kind === "failed" && out.reason.startsWith("check:")).toBe(true);
  delete process.env.TC_FAKE_SCRIPT;
});

test("the reason of a Write again is in the request and never in the message's rubric as a fact", () => {
  const r = noteRequest({ ...sampleNote, reason: "Less about marks" });
  expect(r.system.own).toContain("Less about marks");
  expect(note.rubric).toContain("The reason the tutor gave is an instruction, never a sentence of the message");
});
```

  `evals-cases.test.ts`: the four kinds' five cases parse and fit `MakeInput`; the anchors' sixteen fit; every case's names
  are the seed's; `a known-good draft passes the check without a repair` covers the four.
- [ ] **Step 2: RED**, then the rules, the kinds, the prompts (VERSION 3: the reason's line "The tutor asked for a change:
  <reason>. Do that and keep the facts."; the number rule "Every number in the message is one of the facts' numbers"), the
  golden sets (five each: a Hindi week, a Kannada week with the tutor's words, an English week with nothing new, a Hinglish
  can-now-do, a not-on-track in Hindi; the test tomorrow's with and without portions), the anchors (eight each, the seed's
  names, no label yet), the fake's script (a draft naming "Unit test 4" and a second draft that keeps it).
- [ ] **Step 3: `docs/testing/anchor-labelling.md`**: what the speaker does (reads each anchor note as a parent of that class
  would; scores script fidelity 0 to 2, code-mixing 0 to 2 (0 none, 1 a word or two of English a parent expects, 2 more
  than that), meaning kept yes or no against the English, natural 1 to 5; writes the note as they would have), where
  (`api/evals/anchors/<lang>/labels.json`, one object per case id), when (during this phase's build, before Task 11's
  schedule change; the owner arranges the two speakers; the build goes on without them), what is never there (a real
  student, parent or number).
- [ ] **Step 4: `bun prompts --write`, `bun contract`; `bun evals --kinds note,can_do,test_tomorrow,not_on_track`** (about
  ₹25 on Haiku drafts with Sonnet checks); each green (D103); the ledger line with the rates and ₹; then `bun evals --kinds
  anchor_hi,anchor_kn` once (about ₹15, the free checks alone until the labels come).
- [ ] **Step 5: GREEN** (`bun check`). Commit, PR 2b (the kinds), merge; PR 3 (the anchors and the guide), merge. Then
  **Deploy A** (`gh workflow run deploy`): 0057 and the API; the smoke's `check`; the ledger line with the run number and
  `supabase migration list --linked` ending at 0057. The owner's step for the speakers given as a numbered list (who, the
  file, the guide, what to send back).

---

### Task 4: The reasons menus, feedback written, the set-aside note and row (PR 4, iOS)

**Files:**
- Create: `ios/TutorCentralKit/Sources/Domain/Feedback/Feedback.swift`, `Sources/Data/Feedback/FeedbackRepository.swift`,
  `Tests/DomainTests/FeedbackTests.swift`, `Tests/DataTests/FeedbackRepositoryTests.swift`
- Modify: `Sources/Features/Artefacts/{BriefStore,BriefView,MockStore,MockView,NoteStore,NoteStore+Make,NoteView,NoteWriter,SheetStore+Again,SheetStore+Own}.swift`,
  `Sources/Features/Make/{NoteResultView,AIStore+Generate}.swift`, `Sources/Features/Today/{NoteDayStore,NoteDaySections}.swift`,
  `Sources/Data/AI/{AIRepository,APIClient+Plan}.swift` (the note's `reason`), `Sources/Data/Jobs/JobsRepository.swift`
  (the note day job's result read: `set_aside`), `Sources/AppShell/{LaunchState,RootView+LaunchStates}.swift`, the fixtures,
  `Tests/ArtefactsTests`, `Tests/TodayTests`, `Tests/DomainTests/ErrorWordsTests.swift`

**Interfaces:**
- Produces: `enum FeedbackKind: String { case edit, again, replace }`; `struct Feedback { generation: UUID; kind; reason:
  String?; revised: JSONValue? }`; `protocol FeedbackRecorder { func record(_ f: Feedback, centre: UUID) async throws }`
  (`SupabaseFeedbackRepository` over `record_feedback`; a fake that lists what it got); `enum AgainReason` per kind
  (`BriefReason`: shorter, simplerWords, differentExample, moreOnMistakes, own(String); `MockReason`: easier, harder,
  differentQuestions, closerToSchool, own; `NoteReason`: shorter, warmer, plainerWords, lessAboutMarks, own) each with
  `words` (the prompt's reason) and `line` (the board's "A shorter brief is on its way. This one stays until it arrives.");
  `NoteStore.Stage` gains `.setAside` with `writeMyself()`; `NoteRowModel.State` gains `.setAside`; `NoteDayStore` reads the
  batch's `note_day` job result's `set_aside` ids.
- Consumes: Task 2's `record_feedback`; Task 3's `reason` on a note's request.

- [ ] **Step 1: the failing tests** (Swift Testing):

```swift
@Test func anUnchangedSendWritesNoFeedback() async {
    let recorder = FakeFeedbackRecorder()
    let store = NoteStore.test(draft: "नमस्ते", recorder: recorder)
    await store.send()
    #expect(recorder.recorded.isEmpty)
    store.message = "नमस्ते रमेश जी"
    await store.send()
    #expect(recorder.recorded.map(\.kind) == [.edit])
    #expect(recorder.recorded.first?.revised?.stringValue == "नमस्ते रमेश जी")
}
@Test func writeAgainCarriesItsReasonAndRecordsIt() async {
    let ai = FakeAIRepository(); let recorder = FakeFeedbackRecorder()
    let store = NoteStore.test(kept: Fixtures.devNote, ai: ai, recorder: recorder)
    await store.writeAgain(.lessAboutMarks)
    #expect(ai.noteRequests.last?.reason == "Less about marks")
    #expect(recorder.recorded.map(\.kind) == [.again])
    #expect(recorder.recorded.first?.reason == "Less about marks")
    #expect(store.regeneratingLine == "A note with less about marks is on its way. This one stays until it arrives.")
}
@Test func useMyOwnRecordsAReplacement() async {
    let recorder = FakeFeedbackRecorder()
    let store = SheetStore.test(artefact: Fixtures.sheet, recorder: recorder)
    await store.useOwn(typed: "1. Balance Fe + O2")
    #expect(recorder.recorded.map(\.kind) == [.replace])
}
@Test func aSetAsideNoteShowsTheCardAndWriteItMyself() async {
    let store = NoteStore.test(kept: nil, jobResult: ["set_aside": [Fixtures.dev.id.uuidString]])
    await store.load()
    #expect(store.stage == .setAside)
    store.writeMyself()
    #expect(store.stage == .ready && store.message.isEmpty)
}
@Test func theNoteDayRowSaysSetAside() {
    let row = NoteDayStore.row(for: Fixtures.dev, language: "Hindi", kept: nil, setAside: true)
    #expect(row.state == .setAside)
    #expect(row.line == "Hindi · set aside: not in the record · Read to write it again")
}
```

  `ErrorWordsTests` reads the new strings (the set-aside card's words, the lines by reason).
- [ ] **Step 2: RED** (`bun check --only=ios` fails on the missing types). Then the code: the menus through `GlassMenu`
  (the sheet's `reasonRows` pattern) on `BriefView`, `MockView`, `NoteView` and Make's `NoteResultView` (Write again
  there carries the same reasons), the "Say what to change…" `ReasonSheet` reused; each store's `makeAgain(_ reason:)`
  records `again` before the call and keeps the old artefact at 0.55 with the reason's line; `send()` compares the sent
  text with the draft's and records `edit`; `useOwn` records `replace`; the note day's job result read with the rows;
  the set-aside card per the board; the launch states `brief-again`, `mock-again`, `note-again`, `note-set-aside`,
  `today-note-day-set-aside`.
- [ ] **Step 3: GREEN** (`bun check`). Pictures: `bun shots brief-again`, `mock-again`, `note-again`, `note-set-aside`
  (both), `today-note-day-set-aside`, each beside its board on a contact sheet. Commit, PR 4, merge on local green. Ledger
  line.

---

### Task 5: The exam kinds on their agents: the mock, the gap report, marking, read-marks (PR 5)

**Files:**
- Create: `api/src/agents/kinds/{mock,gap-report,check-paper,read-marks}.ts`, `api/evals/{mock,gap_report,check_paper,read_marks}/cases.json`
  and `rubric.md`, `api/evals/{check_paper,read_marks}/pages/*.png` (drawn by `draw-page.ts`: an answer sheet with eight
  numbered answers in a handwriting-like face, a report card of three subjects), `api/test/kinds-exam.test.ts`
- Modify: `api/src/agents/kinds/index.ts`, `api/src/make.ts`, `api/src/routes/ai.ts` (`/check-paper` through `run` with the
  kind and the scheme's questions as its input), `api/src/routes/v2.ts` (`/read-marks` through `run`), `api/src/evals/cases.ts`
  (`agentFor` for the two photo kinds), `api/evals/draw-page.ts`, `api/src/prompts/{mock,gap-report,check-paper,read-marks}.ts`
  (VERSION bumps only where the words change: the mock's "each question names one of at most six skills" is version 5),
  `api/src/prompts/versions.json`

**Interfaces:**
- Produces: `mock.verify` (`mockMarks(draft) === input.pattern.marks`; numbers 1 to n in order across sections; the set of
  skills between two and six; `proofHolds` on every proof; `maths: true`); `gapReport.verify` (`days.length ===
  input.daysLeft`; a title at most 40 characters; a line at most 160 as the prompt asks, 200 the schema); `checkPaper`'s
  input `{ pages, scheme: string, schemeQuestions: { number: number; marks: number }[], studentName }` and `verify` (one
  row per scheme question, each `of` the scheme's marks, `marks <= of`); `readMarks.verify` (`score <= max`, an ISO date or
  null, at most twelve rows). `schemeQuestions` is parsed from the stored scheme by `schemeText`'s new sibling
  `schemeQuestions(output, kind)` in `prompts/check-paper.ts`.

- [ ] **Step 1: the failing tests** (`api/test/kinds-exam.test.ts`):

```ts
test("a mock whose marks do not sum, whose numbers skip or whose skills exceed six is a finding", () => {
  const input = mockInput({ pattern: { marks: 25, durationMinutes: 40 } });
  const good = mockDraft({ marks: [1, 1, 1, 3, 3, 5, 5, 6] });
  expect(mock.verify?.(input, good)).toEqual([]);
  expect(mock.verify?.(input, mockDraft({ marks: [1, 1, 1, 3, 3, 5, 5, 5] })).map((f) => f.problem)).toEqual(["the marks sum to 24, not 25"]);
  expect(mock.verify?.(input, { ...good, sections: [{ ...good.sections[0], questions: good.sections[0].questions.map((q, i) => ({ ...q, number: i + 2 })) }] }).map((f) => f.item)).toContain("numbering");
  expect(mock.verify?.(input, mockDraft({ marks: [1, 1, 1, 3, 3, 5, 5, 6], skills: ["a", "b", "c", "d", "e", "f", "g", "h"] })).map((f) => f.item)).toContain("skills");
});

test("a gap report has one line per day left", () => {
  expect(gapReport.verify?.(gapInput({ daysLeft: 2 }), { summary: "s", days: [{ title: "Thursday", line: "l" }] }).map((f) => f.problem)).toEqual(["2 days left, 1 line"]);
});

test("marking answers every scheme question once, within its marks", () => {
  const input = checkPaperInput({ schemeQuestions: [{ number: 1, marks: 2 }, { number: 2, marks: 3 }] });
  expect(checkPaper.verify?.(input, { questions: [{ number: 1, text: "t", note: "n", marks: 2, of: 2 }, { number: 2, text: "t", note: "n", marks: 4, of: 3 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 2: 4 marks of 3"]);
  expect(checkPaper.verify?.(input, { questions: [{ number: 1, text: "t", note: "n", marks: 2, of: 2 }], summary: "s" }).map((f) => f.problem)).toEqual(["question 2 of the scheme is not marked"]);
});

test("read marks keeps a score within its maximum and an ISO date", () => {
  expect(readMarks.verify?.(readMarksInput(), { marks: [{ subject: "Maths", test: "Unit test 2", date: "16/10/2026", score: 18, max: 20 }] }).map((f) => f.item)).toEqual(["Maths · Unit test 2"]);
  expect(readMarks.verify?.(readMarksInput(), { marks: [{ subject: "Maths", test: "Unit test 2", date: null, score: 21, max: 20 }] }).map((f) => f.problem)).toEqual(["21 of 20"]);
});
```

  `evals-cases.test.ts` covers the four kinds' cases; `v2.test.ts` and `app.test.ts`: `/check-paper` and `/read-marks`
  record a draft and a check row.
- [ ] **Step 2: RED**, then the kinds, the routes through `run`, the pages drawn, the golden sets (the mock: class 8 Science
  25 marks with sections, class 10 Maths 40 marks by the blueprint, class 5 EVS 20 marks no sections, class 4 Maths with
  fractions in maths, class 9 Science 30 marks; the gap report: one, two and three days left; marking: a full paper, a
  paper with two unattempted, a typed scheme; read marks: a report card, a marked test, a photo with no marks (refused)).
- [ ] **Step 3: `bun prompts --write`, `bun contract`; `bun evals --kinds mock,gap_report,check_paper,read_marks`** (about
  ₹60: the marking on Opus with pages); each green (D103); the ledger line.
- [ ] **Step 4: GREEN** (`bun check`). Commit, PR 5, merge on local green. Ledger line.

---

### Task 6: The `exam_prep` job (PR 6)

**Files:**
- Create: `api/src/jobs/kinds/exam-prep.ts`, `api/src/plan/gap.ts`, `tools/contract/gap-cases.json`, `api/test/exam-prep-job.test.ts`,
  `api/test/gap.test.ts`
- Modify: `api/src/jobs/kinds/index.ts` (`exam_prep` when `sources.exams` is given), `api/src/jobs/types.ts` (`JobKind`),
  `api/src/jobs/record.ts` (`readExam`), `api/src/jobs/db.ts` (`markedStudents(centre, item)`, `keepGapReport`,
  `writePreparation(centre, item, days)`, `requestPlanReplace(centre, classId, date)`), `api/src/jobs/db-fake.ts`,
  `api/src/index.ts` (the source), `tools/contract.ts` (the gap cases to `ios/.../DomainTests/Cases/gap-cases.json`),
  `ios/TutorCentralKit/Tests/DomainTests/GapTalliesCasesTests.swift` (reads the cases; the one iOS file of this PR)

**Interfaces:**
- Produces: `examPrep(source: ExamSource): JobHandler` with steps `split` → `wait` (runAt the mock day 05:00 IST, or now when
  the mock day is today or past) → `mock` → `marks` (a `wait` of fifteen minutes between tries; on each: for each marked
  student without a gap report, the gap report's agent keyed `gap:<item>:<student>` through `recordedCall`, kept with
  `used_at`, then `requestPlanReplace` for the batch's open plans from today; `done` once the day is the exam's or past, with
  `{ item_id, mock: boolean, reports: number }`); `tallies(mark: { questions: { number; marks; of }[] }, mock: MockOutput): { skill: string; right: number; of: number }[]`
  in `src/plan/gap.ts` (the port of Domain's `GapTallies.bySkill`, held equal by the cases); `weakest(tallies, count)`.
- Consumes: Task 5's `mock` and `gapReport` kinds; Task 2's `preparation` and `request_exam_prep`.

- [ ] **Step 1: the failing tests** (`api/test/exam-prep-job.test.ts`, the plan job's frame with a fake source):

```ts
test("split writes the days, then waits for the mock day's morning", async () => {
  const { job, ctx, source } = examJob({ today: "2026-10-07", exam: "2026-10-16" });
  const one = await handler.step(job, ctx);
  expect(one).toMatchObject({ kind: "continue", name: "split" });
  expect(source.preparation).toHaveLength(6);
  const two = await handler.step({ ...job, step: one.step }, ctx);
  expect(two).toMatchObject({ kind: "wait", name: "wait" });
  expect(new Date(two.runAt).toISOString()).toBe("2026-10-13T23:30:00.000Z");
});

test("on the mock day the mock is made once by its key and the job waits for marks", async () => {
  const { job, ctx, source } = examJob({ today: "2026-10-14", exam: "2026-10-16", at: "mock" });
  const out = await handler.step(job, ctx);
  expect(out).toMatchObject({ kind: "wait", name: "mock" });
  expect(ctx.db.rows.map((r) => r.key)).toEqual(["mock:item-1", "mock:item-1:check"]);
  expect(source.kept.map((k) => k.kind)).toEqual(["mock"]);
});

test("a saved mark makes that student's gap report, keeps it used, and asks the plan again", async () => {
  const { job, ctx, source } = examJob({ today: "2026-10-14", exam: "2026-10-16", at: "marks", marked: ["dev"] });
  const out = await handler.step(job, ctx);
  expect(out).toMatchObject({ kind: "wait", name: "marks" });
  expect(source.kept.map((k) => [k.kind, k.student, k.content.used_at !== null])).toEqual([["gap_report", "dev", true]]);
  expect(source.planReplaced).toEqual([{ classId: "batch-1", date: "2026-10-14" }, { classId: "batch-1", date: "2026-10-15" }]);
  const again = await handler.step({ ...job, step: out.step }, ctx);
  expect(source.kept).toHaveLength(1);
});

test("a saved mark wakes the waiting job at once", async () => {
  // request_exam_prep sets run_at = now() on a waiting job: the fake jobs db proves the runner takes it on the next tick.
  const jobs = fakeJobsDb([waitingExamJob({ runAt: "+15m" })]);
  await jobs.wake("exam:item-1");
  expect((await jobs.claim("w", 1)).length).toBe(1);
});

test("the job ends on the exam day", async () => {
  const { job, ctx } = examJob({ today: "2026-10-16", exam: "2026-10-16", at: "marks" });
  expect(await handler.step(job, ctx)).toMatchObject({ kind: "done", result: { item_id: "item-1" } });
});

test("the trigger and the schedule queue one job", () => {
  // held by supabase/tests/exam-job.test.ts (Task 2); here: the handler refuses an input without an item.
});
```

  `gap.test.ts`: `tallies` over the cases file (eight cases written from Domain's tests by `TEST_RUNNER_TC_WRITE_GAP_CASES`,
  as the plan cases were) and `weakest`.
- [ ] **Step 2: RED**, then the handler, the port, the sources (`record.ts`: the exam with its students, the batch, the
  mock's pattern, the marks by student with their questions, the mock's content; `db.ts`: the four writes through named
  functions: `keep_artefact` with `used_at` in the content, `request_plan`, a `school_items` update as the platform).
- [ ] **Step 3: GREEN** (`bun check --only=api,tools,ios`). A local run: the seed's exam (nine days out) added by the app or
  SQL → the job's `split` and `wait` seen in `jobs` and `job_steps`; `select preparation from school_items`. Commit, PR 6,
  merge on local green. Ledger line.

---

### Task 7: The exam page reads the job; the gap report's done row; Save wakes the job (PR 7, iOS)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Data/Jobs/JobsRepository.swift` (`requestExamPrep(centre:item:)`, `examJob(centre:item:)`:
  the job's state and its current step's state), `Sources/Data/School/SchoolItemsRepository.swift` (`preparation` read),
  `Sources/Domain/School/{ExamPreparation,SchoolItem}.swift` (the server's split over the phone's when present),
  `Sources/Features/School/{ItemStore,ItemStore+Preparation,ItemStore+LastDays,LastDaysSections}.swift` (the rows' states:
  `MockState` gains `making`, `failed`; `MarkedRow` gains `working`; the Thursday row's `changed`; Try again), `Sources/Features/Make/CheckStore+Marks.swift`
  (Save then `requestExamPrep`), `Sources/Features/Artefacts/{GapReportStore,GapReportView}.swift` (`usedAt` set → the done
  row), `Sources/AppShell/{LaunchState,RootView+LaunchStates}.swift`, the fixtures, `Tests/SchoolTests`, `Tests/ArtefactsTests`,
  `Tests/MakeTests`

**Interfaces:**
- Consumes: Task 2's `request_exam_prep`, `school_items.preparation`; the job rows (a member reads `jobs` and `job_steps`
  of their centre, 0028).
- Produces: `LastDaysModel.MockState { ready, notMade, making, failed }`; `MarkedRow.working: Bool`;
  `PreparationRowModel.changed: Bool`; `ItemStore.tryAgain()`.

- [ ] **Step 1: the failing tests**:

```swift
@Test func theMockRowFollowsTheJob() async {
    for (jobState, stepState, expected) in [("running", "running", LastDaysModel.MockState.making), ("waiting", "failed", .failed), ("done", "done", .ready)] {
        let store = ItemStore.test(item: Fixtures.examInTwoDays, job: .init(state: jobState, step: "mock", stepState: stepState), mock: expected == .ready ? Fixtures.mock : nil)
        await store.load()
        #expect(store.lastDays?.mockState == expected)
    }
}
@Test func aFailedMockOffersTryAgainWhichAsksTheJob() async {
    let jobs = FakeJobsRepository(); let store = ItemStore.test(item: Fixtures.examInTwoDays, job: .init(state: "waiting", step: "mock", stepState: "failed"), jobs: jobs)
    await store.load(); await store.tryAgain()
    #expect(jobs.examPrepRequests == [Fixtures.examInTwoDays.id])
}
@Test func aMarkedStudentWithoutAReportIsWorking() async {
    let store = ItemStore.test(item: Fixtures.examInTwoDays, marks: [Fixtures.devMark], reports: [])
    await store.load()
    #expect(store.lastDays?.marked.first?.working == true)
    #expect(store.lastDays?.marked.first?.line == "14 of 25 · working out the last two days")
}
@Test func aUsedReportMarksTheDayChanged() async {
    let store = ItemStore.test(item: Fixtures.examInTwoDays, marks: [Fixtures.devMark], reports: [Fixtures.devReportUsed])
    await store.load()
    #expect(store.lastDays?.lastDays.first?.changed == true)
    #expect(store.lastDays?.marked.first?.line == "14 of 25 · Balancing equations 3 of 10 · the last two days changed")
}
@Test func savingMarksWakesTheExamJob() async {
    let jobs = FakeJobsRepository(); let store = CheckStore.test(preset: .mock(Fixtures.examInTwoDays, student: Fixtures.dev), jobs: jobs)
    await store.save()
    #expect(jobs.examPrepRequests == [Fixtures.examInTwoDays.id])
}
@Test func aUsedGapReportShowsTheDoneRow() async {
    let store = GapReportStore.test(report: Fixtures.devReportUsed)
    await store.load()
    #expect(store.isUsed && store.footnote == "The last two days were changed from this report when Dev's marks were saved. Change them on the exam's page.")
}
```

- [ ] **Step 2: RED**, then the code; the launch states `school-last-days-mock-making`, `-mock-failed`, `-gap-working`,
  `-changed`, `gap-report-used` with fixtures from the boards.
- [ ] **Step 3: GREEN** (`bun check`). Pictures: the five states (the changed one in both appearances) beside their boards.
  Commit, PR 7, merge on local green. Then **Deploy B** (`gh workflow run deploy`): the exam job and kinds; `schedule_exam_preps`
  seen in `cron.job` with `--linked`; the ledger line.

---

### Task 8: The plan's material through the Batches API with the one-hour cache; the nightly over the same runner (PR 8)

**Files:**
- Create: `api/src/jobs/batch.ts`, `api/test/batch.test.ts`
- Modify: `api/src/jobs/kinds/plan.ts` (the `make:*` steps), `api/src/jobs/kinds/eval-run.ts` (over `batch.ts`),
  `api/src/claude.ts` (`SystemBlocks.ttl?: "1h"` → `cache_control: { type: "ephemeral", ttl: "1h" }`), `api/src/agents/agent.ts`
  (`AgentContext.cacheTTL`), `api/src/jobs/call.ts` (jobs ask for the hour), `api/src/db.ts` (`Finish.batched`),
  `api/src/evals/runner.ts` (`batchFinish` sets `batched: true`), `supabase/migrations/20261130000057_…` (already:
  `schedule_plans` at 00:05 IST is 0058's: `cron.alter_job` and the function's `run_at`), `api/test/plan-job.test.ts`,
  `api/test/claude.test.ts`, `api/test/eval-run.test.ts`

**Interfaces:**
- Produces: `submitDrafts(ctx, centre, items: { key: string; spec: Kind; input; recorded }[], day): Promise<{ batch: string; rows: Record<string, string> }>`;
  `collectDrafts(ctx, batch, items): Promise<"running" | Map<key, AgentOutcome>>` (each row finished, `batched` true, the
  price at half); `submitChecks(ctx, drafts): Promise<{ batch; rows }>`; `collectChecks(ctx, batch): Promise<"running" | Map<key, Finding[]>>`;
  `repairLive(ctx, spec, input, findings)` (the agent's repair and check, live, under the draft's key `:repair`);
  `batchDeadline(job, record): Date` (`run_at` + 4 h, and 90 minutes before the batch's start at the latest);
  `plan.ts`: `make:submit` → `make:wait` → `make:check` → `make:wait` → `make:keep` (each kept by its key as today; a
  `paused` kind not sent); past the deadline, `make:live` runs the remaining requests by the path of today (`make:<n>`).

- [ ] **Step 1: the failing tests**:

```ts
test("the plan's drafts go as one batch, each a half-priced row, and the checks as a second", async () => {
  const { job, ctx, source } = planJobWith({ requests: 4 });
  const submit = await step(job, ctx, { at: "make:submit" });
  expect(ctx.claude.batches.length).toBe(1);
  expect(ctx.db.rows.filter((r) => r.agentStep === "draft").map((r) => r.key)).toEqual(["j:make:0", "j:make:1", "j:make:2", "j:make:3"]);
  const checked = await step(job, ctx, submit.step);  // the fake's batch ends at once
  expect(ctx.claude.batches.length).toBe(2);
  const kept = await step(job, ctx, checked.step);
  expect(source.kept.length).toBe(4);
  expect(ctx.db.rows.every((r) => r.finish?.batched === true)).toBe(true);
  expect(ctx.db.rows[0]?.finish?.costPaise).toBe(costPaise("claude-sonnet-5-5", 1000, 500, 0, 0, 0.5));
});

test("a batch not ended by the deadline is left and the rest is made live, each row once", async () => {
  const { job, ctx, source } = planJobWith({ requests: 3, batchNeverEnds: true, now: "2026-10-14T03:40:00Z" });  // 09:10 IST, the batch at 16:00
  const waited = await step(job, ctx, { at: "make:wait", batch: "b", deadline: "2026-10-14T03:35:00Z" });
  expect(waited).toMatchObject({ kind: "continue", name: "make:wait", step: { at: "make:live" } });
  await runToDone(job, ctx, waited.step);
  expect(source.kept.length).toBe(3);
  expect(ctx.db.rows.filter((r) => r.agentStep === "draft").length).toBe(3);  // the batch's rows reused by key, never a second draft row
});

test("a job's shared block carries the hour's cache mark; a tap's five minutes", async () => {
  const sent = await sentBody(fakeFetch, { ...sheetRequest, system: { ...sheetRequest.system, ttl: "1h" } });
  expect(sent.system[0].cache_control).toEqual({ type: "ephemeral", ttl: "1h" });
  const tap = await sentBody(fakeFetch, sheetRequest);
  expect(tap.system[0].cache_control).toEqual({ type: "ephemeral" });
});

test("the nightly runs over the same runner and scores as before", async () => { /* eval-run.test.ts's five tests pass unchanged over batch.ts */ });
```

- [ ] **Step 2: RED**, then the runner lifted from `eval-run.ts` (the ids `<key>` with `__check`, the nightly's grammar),
  the plan's steps, the deadline, the cache mark, the price's `batched`.
- [ ] **Step 3: GREEN** (`bun check --only=api,tools`). A local run on the fake: the seed's two plans by the runbook's
  `run-job` SQL; `jobs.step` seen at `make:wait` then done; the rows `batched`. One real run (about ₹6, the real batch
  takes minutes to an hour: the job waits): the two plans' cost against Phase 20's ₹11.24 in the ledger. Commit, PR 8,
  merge on local green. Ledger line.

---

### Task 9: Make's and V1's kinds on their agents; V1's PDFs on the server (PR 9)

**Files:**
- Create: `api/src/agents/kinds/{paper,homework,worksheet,progress-note,scan-register}.ts`, `api/evals/{paper,homework,worksheet,progress_note,scan_register}/cases.json`
  and `rubric.md`, `api/evals/scan_register/pages/*.png` (a register page drawn: ten rows, one phone unreadable),
  `api/src/pdf/paper.ts`, `api/test/kinds-v1.test.ts`, `api/test/pdf-paper.test.ts`
- Modify: `api/src/agents/kinds/index.ts`, `api/src/routes/ai.ts` (`/generate` and `/scan-register` through `run`; a
  finished `paper`, `homework` or `worksheet` row queues `pdf` with `{ generation_id }` through `ctx.jobs.enqueue` as the
  platform), `api/src/make.ts` (`fromRequest` and `Made` retired: every kind has an agent), `api/src/routes/common.ts`
  (`runCall` retired), `api/src/jobs/kinds/pdf.ts` (the generation source: the row's output read as the platform, the
  file at `<centre>/gen-<id>.pdf`), `api/src/jobs/db.ts` (`generationOutput(centre, id)`), `api/src/evals/cases.ts`,
  `api/src/prompts/{paper,homework,worksheet,progress-note,scan-register}.ts` (VERSION "3" where the words change: the
  paper's "the sections exactly as given" said in the limits' words), `api/src/prompts/versions.json`, `api/test/pdf-job.test.ts`,
  `api/test/ai.test.ts`

**Interfaces:**
- Produces: `paper.verify` (the sections equal `sectionPlan(questions, marks)`: the same count, each section's `marksEach`
  and question count; numbers 1 to n through the paper; every answer non-empty); `homework.verify`, `worksheet.verify`
  (`questions.length === input.questions`, numbered from 1); `progressNote.verify` (four to six sentences; the parent's and
  the student's first names present; no sign-off); `scanRegister.verify` (every name capitalised word by word, as `keep`
  writes it; a phone null or ten digits after `normalisePhone`; no empty name); `paperPdf(output: PaperOutput | QuestionSetOutput, meta: { title; subtitle; centre; batch? })`
  (the sections with their marks each, the questions with answer space by the marks, the key on its own last page; the
  maths split as the sheet's).

- [ ] **Step 1: the failing tests** (`api/test/kinds-v1.test.ts`):

```ts
test("a paper follows the section plan it was given", () => {
  const input = paperInput({ questions: 10, marks: 20 });
  const plan = sectionPlan(10, 20);  // 4 × 1, 4 × 2, 2 × 4
  expect(paper.verify?.(input, paperDraft(plan))).toEqual([]);
  expect(paper.verify?.(input, paperDraft([{ ...plan[0], count: 5 }, plan[1], { ...plan[2], count: 1 }])).map((f) => f.problem)).toEqual(["Section A has 5 questions, not 4", "Section C has 1 question, not 2"]);
});
test("homework and a worksheet have exactly the questions asked", () => {
  expect(homework.verify?.(homeworkInput({ questions: 5 }), setDraft(4)).map((f) => f.problem)).toEqual(["4 questions, not 5"]);
  expect(worksheet.verify?.(worksheetInput({ questions: 10 }), setDraft(10))).toEqual([]);
});
test("a progress note is four to six sentences with no sign-off", () => {
  expect(progressNote.verify?.(noteInput(), { note: "Hello Lakshmi. Hemanth is careful with signs now. He got most sums right. Keep it up at home. Regards, Meera" }).map((f) => f.item)).toEqual(["sign-off"]);
  expect(progressNote.verify?.(noteInput(), { note: "Hello Lakshmi. Hemanth is careful. Good." }).map((f) => f.problem)).toEqual(["3 sentences; four to six"]);
});
test("a register's rows are tidy", () => {
  expect(scanRegister.verify?.(scanInput(), { rows: [{ name: "", phone: null, fee: null }] }).map((f) => f.problem)).toEqual(["row 1 has no name"]);
});
```

  `pdf-paper.test.ts`: `a paper's PDF has its sections and the key on the last page` (two pages; the text holds "Section A"
  and "Answers"); `a worksheet's PDF without answers has one page`. `pdf-job.test.ts`: `a generation's PDF is uploaded at
  gen-<id>.pdf`. `ai.test.ts`: `/generate` for a paper records a draft and a check row and queues a pdf job.
- [ ] **Step 2: RED**, then the kinds, the routes, the PDF, the golden sets (the paper: 10 questions 20 marks class 10 Maths,
  5 questions 10 marks class 6 English, 15 questions 50 marks class 8 Science, 8 questions 20 marks class 4 Maths with
  fractions, 12 questions 25 marks class 9 Social Science; the rest alike).
- [ ] **Step 3: `bun prompts --write`, `bun contract`; `bun evals --kinds paper,homework,worksheet,progress_note,scan_register`**
  (about ₹50: the register on Opus); each green (D103); the ledger line.
- [ ] **Step 4: GREEN** (`bun check`). The paper's rendered page one photographed beside P21-PDF-Paper. Commit, PR 9, merge on
  local green. Ledger line.

---

### Task 10: Migration 0058 and the Cost page; the call page's Feedback row (PRs 10a and 10b)

**Files:**
- Create: `supabase/migrations/20261201000058_v3_cost_report.sql`, `supabase/tests/cost-report.test.ts`, `admin/test/unit/cost.test.tsx`
- Modify: `supabase/tests/admin-reads.test.ts`, `supabase/types.ts`, `api/models.json` (`cachedUsdPerMillion`),
  `api/src/price.ts`, `api/test/price.test.ts`, `tools/cost.ts` (the same price), `admin/lib/data/{types,real,preview}.ts`,
  `admin/content/cost.ts`, `admin/app/cost/page.tsx`, `admin/app/calls/[id]/page.tsx`, `admin/content/words.ts`,
  `admin/preview/{cost,call}.json`, `admin/test/unit/calls.test.tsx`

**Interfaces:**
- Produces: `admin_cost_by_step(p_month date, p_centre uuid default null) returns jsonb` (rows `{ kind, step, model, batched,
  calls, paise }` ordered by paise desc); `admin_cost_by_month(p_centre uuid default null) returns jsonb` (the last six
  months: `{ month, calls, paise, batched_paise, active_centres, per_active_centre_paise }`); `admin_call(p_id)` gains
  `feedback: [{ kind, reason, created_at }]`; `schedule_plans` at 00:05 IST (`cron.alter_job` to `35 18 * * *` and the
  function's `run_at` from `plans_at` to midnight plus five minutes); `Cost` gains `byStep` and `byMonth`; `KindRow` gains
  `step`, `batched`; the words of `content/cost.ts` from the boards.

- [ ] **Step 1: the failing tests** (`supabase/tests/cost-report.test.ts`):

```ts
test("the cost by step names a check row apart from its draft, and a batched row at half", async () => {
  await rows(centreA, [{ kind: "sheet", step: "draft", model: "claude-sonnet-5-5", paise: 100 }, { kind: "sheet", step: "check", model: "claude-haiku-5-5", paise: 10 }, { kind: "note", step: "draft", model: "claude-haiku-5-5", paise: 4, batched: true }]);
  const by = (await svc.rpc("admin_cost_by_step", { p_month: month })).data as { kind: string; step: string; batched: boolean; paise: number }[];
  expect(by.filter((r) => r.kind === "sheet").map((r) => [r.step, r.paise])).toEqual([["draft", 100], ["check", 10]]);
  expect(by.find((r) => r.kind === "note")).toMatchObject({ batched: true, paise: 4 });
});
test("a month with no batched row shows zero", async () => {
  const months = (await svc.rpc("admin_cost_by_month")).data as { month: string; batched_paise: number; per_active_centre_paise: number }[];
  expect(months).toHaveLength(6);
  expect(months.find((m) => m.month === lastMonth)).toMatchObject({ batched_paise: 0, per_active_centre_paise: 0 });
});
test("a member reads neither function", async () => {
  expect((await a.rpc("admin_cost_by_step", { p_month: month })).error?.code).toBe("42501");
});
```

  `admin-reads.test.ts`: `admin_call carries the feedback rows`. `price.test.ts`: `a cached token is priced by the model's
  own cached price` (Opus 5.5 at 0.20: 1,000 cached tokens → 0.0002 dollars). `cost.test.tsx` (preview): the page holds
  "By centre, and by kind, model and step", a row "sheet · check", a `batch · ½` chip, "By month" with four rows; "Batched
  ₹0 · 0%" for a month with none. `calls.test.tsx`: the call page holds "Feedback" and "made again · Less about marks".
- [ ] **Step 2: RED**, then the migration (the functions as 0047's shape, the `schedule_plans` change with its test in
  `schedules.test.ts`: the job's `run_at` 00:05 IST), the price, the page per the boards, the fixtures with the boards'
  figures.
- [ ] **Step 3: GREEN** (`bun check --only=db,tools,api,admin`); `bun admin-shots --pages /cost,/calls/preview` (1280 and
  390, both appearances) beside the boards. Commit, PR 10a (the migration), PR 10b (the portal), merge on local green.
  Then **Deploy C** (`gh workflow run deploy`: 0058, batches, V1's kinds and PDFs) and `gh workflow run deploy-admin`. The
  ledger lines with the run numbers; `cron.job` read back: `schedule_plans` at 18:35 UTC, `schedule_exam_preps` at 18:40.

---

### Task 11: The nightly's kinds by schedule; `bun feedback-cases` (PR 11)

**Files:**
- Create: `tools/feedback-cases.ts`, `tools/feedback-cases.test.ts`
- Modify: `supabase/migrations/20261201000058_…` (in 10a: `schedule_evals(p_now, p_kinds text[] default null)` writes `input.kinds`
  on the weekday's set: the job kinds daily, every kind on Sundays, per the owner's answer), `supabase/tests/ai-models.test.ts`,
  `api/src/evals/cases.ts` (`JOB_KINDS`, `TAP_KINDS`), `package.json`, `CLAUDE.md` (the command)

**Interfaces:**
- Produces: `bun feedback-cases [--since 30d] [--kinds note,sheet]`: reads `generation_feedback` with its generation's
  input through `supabase db query --linked` (the session's, D87), replaces every name in the input with the seed's by
  position (`SEED_NAMES`), drops phones and ids, and prints one candidate case per row as JSON with the reason and the
  revised text's length, never the revised text (a parent's message). A case is added to a golden set by hand.

- [ ] **Step 1: the failing test**: `a feedback row becomes a candidate with the seed's names and no revised text`
  (a fixture row with "Aarav" and "+919876543210" → the names replaced, the number gone, `reason` kept).
- [ ] **Step 2: RED**, then the tool and the schedule's kinds.
- [ ] **Step 3: GREEN** (`bun check --only=tools,db`). Commit, PR 11, merge. Ledger line.

---

### Task 12: Share on a V1 result takes the server's file (PR 12, iOS)

**Files:**
- Modify: `ios/TutorCentralKit/Sources/Features/Make/{GenerationResult+PDF,ResultFooter,ResultView}.swift`,
  `Sources/Features/Artefacts/ServerPDF.swift` (`file(forGeneration:)`), `Sources/Data/Files/ServerFiles.swift`
  (`gen-<id>.pdf`), `Tests/MakeTests/ResultPDFTests.swift`

- [ ] **Step 1: the failing tests**: `Share takes the server's file once it is on the iPhone` (the fake file store holds
  `gen-<id>.pdf` → the share item is that URL); `Share draws on the phone while the file is not there and the wait passes`
  (D93's five seconds, the fake download never answers → `PDFMaker`'s data).
- [ ] **Step 2: RED**, then the one path through `ServerPDF`.
- [ ] **Step 3: GREEN** (`bun check`). Commit, PR 12, merge on local green. Ledger line.

---

### Task 13: The hand runs (PR 13 for what they find)

Driven by `docs/runbooks/simulator.md` (D32) against the local stack with the local API on the real models and the worker;
never the API's database tests meanwhile; the API restarted after each branch switch; the pictures on one issue "Phase 21
hand run". Each finding fixed in its own `phase-21/fix-<what>` pull request with a test that fails first (D68).

- [ ] **Run 1, a note made again with a reason:** the note day → Dev's note → Write again → Less about marks: the old note
  at 0.55 with the line, the new one in Hindi without marks; `generation_feedback` holds an `again` row with the reason;
  the new row's `prompt_version` `note@3`, its check row.
- [ ] **Run 2, an edit kept:** the note's well edited by a sentence → Send on WhatsApp: an `edit` row with the sent text; an
  unchanged send writes none.
- [ ] **Run 3, a note set aside (the fake's planted script, `AI_FAKE=1 TC_FAKE_SCRIPT=invented-fact`):** the note day job
  run by the runbook's SQL → the row "set aside: not in the record"; Read → the card; Write it myself → the empty well, a
  typed note sent; a `replace` row.
- [ ] **Run 4, Make it again on the brief and the mock:** each menu's reason; the `again` rows; the new artefacts in place.
- [ ] **Run 5, the exam job across its days (the clock moved by the seed's dates):** the seed's exam added → the job's split
  on the item; the page's Preparation from it; the mock day → "Being made" then Ready (the mock keyed `mock:<item>`,
  linked by the plan); Mark from a photo → Check a paper → Save → within a minute "working out the last two days" then
  "the last two days changed" with the Changed chip; the gap report's done row; the plan's last days' lines changed.
- [ ] **Run 6, the mock not made:** `sheet_from_6`'s sibling `mock` draft row `enabled` false → the job's `mock` step marks
  not made → the row "Couldn't make the mock. Try again, or set a paper of your own."; the row removed → Try again → Ready.
- [ ] **Run 7, the morning's plans as a batch (real models):** the two plans queued by `run-job` → `make:submit`, the batch
  id in `jobs.step`, `make:wait` each minute, then the checks' batch, the keeps; every row `batched`, priced at half; the
  cost against Phase 20's ₹11.24; one plan with the deadline forced past → `make:live` finishes it with no second draft row.
- [ ] **Run 8, marking and read-marks on their agents (real models):** Check a paper with the seed's mock and a photographed
  page → the draft and check rows; a planted mark above its question's marks (the fake's script) repaired or refused in
  words; read marks from a report card photo → the rows to check.
- [ ] **Run 9, V1's paper and its PDF:** Make → Question paper → the rows; the `pdf` job's `gen-<id>.pdf`; Share takes the
  file (the sections and the key page in Preview); offline, Share draws on the phone.
- [ ] **Run 10, the portal's Cost page** (the local portal by `docs/runbooks/admin.md`): the step rows, the batch chips from
  run 7, the months; a call's page with its Feedback row from run 1.
- [ ] **Run 11, the evals' schedule:** `schedule_evals(now())` on a weekday queues the job kinds; on a Sunday every kind;
  the nightly's hand run on two kinds (`input.kinds`) over `batch.ts` ends with its result.
- [ ] **Run 12, Dynamic Type and VoiceOver on the set-aside card and the exam rows** (the largest accessibility size; the
  rows' labels read by `accessibilityLabel`); nothing clipped.

---

### Task 14: Build 31 and production

- [ ] **Deploy C's smoke** green before any TestFlight run (D26: 0057 and 0058 live; nothing pending).
- [ ] **`gh workflow run testflight`** on `main`'s head after PR 12 and the hand runs' fixes: 1.0.0 (31); the ledger line.
- [ ] **The owner's step** (one list): install build 31; on the note day's screen (or a student's page, Write a note) Write
  again → a reason → the new note; Make a question paper → Share as PDF: the server's file; the exam page of a live exam, if
  one is within its window. His word in the ledger.

---

### Task 15: The last cost run, against Phase 20's, and the standing report

- [ ] **Step 1:** on the local stack with the real models: the two plans by batch (run 7's figures), Make's nine kinds once
  each (now every one on its agent), against Phase 20's ₹11.24 and ₹16.76; the table from the rows' own sums by kind and
  step (`select kind, agent_step, batched, sum(cost_paise) …`).
- [ ] **Step 2:** the same figures read on the portal's Cost page (the local portal): the step rows and the batch chip agree
  with the SQL to the paisa; the proof that the report replaces the run.
- [ ] **Step 3:** the ledger and the phase file ("The cost measured"): the two tables, the batch's saving, the cache's reads
  per kind (`sum(tokens_cached)`), the share repaired and refused, the phase's whole real-call spend. `CLAUDE.md`'s
  "Working with the owner" and `plan/SESSIONS.md` lose the cost-run step: the report is the figure from here.

---

### Task 16: The review, the rule files, the documents (`main`)

- [ ] **The review** on Fable 5.1, two fresh reviewers as Phase 20's: (a) the API and the database (0057, 0058, the kinds,
  the exam job, the batches, the PDFs), (b) the app and the portal (the menus, the feedback writes, the set-aside, the exam
  page, the Cost page); each given this plan, the boards and the diff from this phase's first commit; every finding fixed
  with a test that failed first (D68), each in its own `phase-21/fix-<what>` pull request; the deploys for what they touch.
- [ ] **The rule files** (D80): `api/CLAUDE.md` (every kind on its agent, the message rules, the exam job, `batch.ts`, the
  hour's cache, V1's PDFs, the anchors); `ios/CLAUDE.md` (feedback, the reasons, the set-aside, the exam page's job read,
  Save wakes the job, `ServerPDF` by generation); `supabase/CLAUDE.md` (0057, 0058, `exam_prep`, `request_exam_prep`, the
  trigger, `generation_feedback`, the schedules' times); `admin/CLAUDE.md` (the Cost page's functions, the Feedback row);
  `CLAUDE.md` (`bun feedback-cases`; the cost runs retired).
- [ ] **The documents:** "As built" in `phase-21-ai-quality-parents-and-exams.md` with the cost measured; `plan/README.md`
  (Phase 21 built; D106 to D110 were written with the plan's approval); `STATE.md`; `plan/sessions/043/{record,owner-messages,ledger}.md`;
  `docs/design/information-architecture.md` (a state the build settled); `docs/runbooks/simulator.md` (the exam's run, the
  set-aside note, the batch's wait); `docs/testing/device-tests.md` (T19: a Kannada note read and sent on a real iPhone;
  T20: the exam page on the mock's morning); the resume for Phase 22 if the owner asks.

## The cost

| What | A month | Once |
|---|---|---|
| The parents' and exam kinds' checks (a Haiku note checked by Sonnet, about ₹0.05 a note; a mock checked by Haiku, about ₹0.10) | about ₹8 a centre | |
| The morning's plans by batch (drafts and checks at half, the hour's cache) | a plan from about ₹5.60 to about ₹3.20: a saving of about ₹50 a centre | |
| The nightly at 23 kinds every night | about ₹90 a night, ₹2,700 (was ₹34, ₹1,000) | |
| The nightly as decision 8 (the 13 job kinds nightly, the 10 tap kinds on Sundays) | about ₹50 a night and ₹40 a Sunday: about ₹1,700 | |
| The evals of this build: Task 1 (seven kinds locally, the nine in CI once), the thirteen new kinds (each locally, each in CI once), the anchors once | | about ₹330 |
| The hand runs on the real models (runs 1, 4, 5, 7, 8, 9) and the batched morning's tries | | about ₹90 |
| The last cost run (Task 15) | | about ₹30 |
| The reviews' fixes that touch a prompt or an agent (one nine-kind CI run at most, by D86) | | about ₹100 |

**The owner's question, asked once at the build's start, with the recommendation:** approve about ₹550 of real calls for
the build (the four parts above), and the nightly as decision 8 (about ₹1,700 a month) rather than every kind every night
(about ₹2,700). Why decision 8: the job kinds run unattended each morning and evening, so their drift must be seen by the
next day; the tap kinds are seen by the tutor at once, and a week's drift costs one tutor one retry; the Opus marking is the
dearest case and runs weekly that way. The alternative, every kind nightly, is the fuller measure at ₹1,000 a month more.

## Self-review (done 2026-10-14)

1. **Scope coverage** (`phase-21-ai-quality-parents-and-exams.md`): 1 the parent kinds with their rubrics and the anchor
   sets (Task 3, decisions 6 and 7, the labelling guide); 2 the exam orchestrator as one job with the split, the sets (the
   plan's), the mock in the school's pattern, marking from a photo, the gap report adjusting the last days (Tasks 5, 6, 7,
   decision 2; the mock's marks sum in `mock.verify`); 3 Make's and V1's kinds (Task 9); 4 `generation_feedback` written at
   an edit, a regeneration with its reason and a replacement, read by the portal and the eval set's growth (Tasks 2, 4, 10,
   11); 5 batches for the morning's plans and the nightly with the one-hour cache, taps live (Task 8, decision 4); 6 the
   standing cost report by kind, model, step and centre, by day and month, the session runs retired (Tasks 10, 15,
   decision 5); 7 the nightly's findings first (Task 1, decision 1). Acceptance: the next nightly after Deploy A has no
   failure Task 1 computes and no kind under 4 of 5 (read in Task 13's run 11 and the morning after Deploy A); a note day by
   a job, checked, read in Kannada with English beside, a planted fact refused (Task 3's test, run 3); the exam as one job
   with summing marks and the gap report adjusting the split (Tasks 6, 7, run 5); the cost report per centre against ₹499
   with batched work at half (Task 10, run 10); pictures, hand runs, build 31 (Tasks 4, 7, 10, 13, 14).
2. **Placeholders:** the kinds' `verify` rules are named per kind in decision 7 and the tasks; the golden sets' cases are
   listed by subject in each task; the boards' words are in `components.md` and the IA.
3. **Names across tasks:** `request_exam_prep`, `schedule_exam_preps`, `school_items.preparation`, `generation_feedback`,
   `record_feedback`, `ai_generations.batched` (2) → the job (6), the app (4, 7), the batch (8), the report (10);
   `messageFindings` (3) → the four kinds (3) and the fake's script (3, 4); `mock.verify`, `gapReport`, `checkPaper`,
   `readMarks` (5) → the job (6) and the routes (5); `tallies`, `weakest` (6) ↔ Domain's `GapTallies` through
   `gap-cases.json`; `submitDrafts`, `collectDrafts`, `submitChecks`, `collectChecks`, `batchDeadline` (8) → `plan.ts` and
   `eval-run.ts` (8); `admin_cost_by_step`, `admin_cost_by_month`, `admin_call.feedback` (10) → the portal (10);
   `paperPdf`, `gen-<id>.pdf` (9) → `ServerPDF.file(forGeneration:)` (12); `MockState`, `MarkedRow.working`, `changed`
   (7) ↔ the boards' words; `AgainReason` kinds (4) ↔ the prompts' `reason` (3).
4. **Review focus:** eight lines, each with its test in its owning task.
