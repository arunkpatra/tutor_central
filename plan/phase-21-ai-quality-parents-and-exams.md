# Phase 21: V3 AI quality, parents and exams

**Status:** Planned (session 42, 2026-10-14): the 18 boards of row 29 drawn (`docs/design/mockups/P21-*`; 13 on the canvas, the five light twins in the mirror) and `phase-21-plan.md` written, both approved by the owner the same day ("Boards approved, plan approved, ₹550 and decision 8 approved"); the build on Opus 5.5 from `resume/041-phase-21-build.md`. **Depends on:** Phase 20.

## Goal

The parent-facing kinds and the exam kinds are made by agents with language and fact checks, the exam is one orchestrated
job, and the cost of AI work is a standing report.

## Scope

1. **The parent kinds** (D73, D74): note, can-now-do, test tomorrow, not on track, read marks on the pipeline; rubrics for
   facts from the record only, the parent's language and script, length, the tutor's own words carried whole (Phase 15); the
   native-speaker anchor sets for Hindi and Kannada (the owner arranges the speaker; the sets hold no real student).
2. **The exam orchestrator** (D73): exam preparation as one job with sub-agents: the split, the daily sets, the mock in the
   school's pattern, marking from a photo (the photo from the phone at a tap), the gap report that adjusts the last days.
3. **Make's and V1's kinds** on the pipeline: paper, homework, worksheet, progress note, scan register, Check a paper.
4. **Feedback** (D74): `generation_feedback` keeps a tutor's edit to a note, a regeneration with its reason, a replacement
   by their own; read by the eval set's growth and the portal.
5. **Batches** (D73): the morning's plans and the nightly evals through the Message Batches API at half price, with the
   one-hour cache; a live call for the kinds made at a tap.
6. **The standing cost report** (D74): cost per kind, model, step and centre, by day and month, in the portal's data; Phases 12
   to 15's session cost runs retired as a practice.
7. **The nightly's findings first** (D105): each failed case of the nightlies since 14 October is fixed (a free `verify` rule
   where the fault can be computed, else the prompt with a version bump) or ruled a strict grade (the rubric or the case
   changed, the reason in the ledger), before the other kinds move.

## Acceptance

- The first nightly after D105's fix is deployed: no failure the fix computes (a brief's slip, a plan's chapter names), and no
  kind below 4 of 5.

- A note day made by a job, checked, read on the phone in Kannada with English beside; a note that names a fact not in the
  record is refused by the check (a planted test).
- An exam's preparation runs as one job across its days; the mock's marks sum; the gap report adjusts the split.
- The cost report shows the month's spend per centre against D64's price; batched work costs half the live price in the report.
- Pictures, hand runs, a build on TestFlight: the external testing round's candidate (D81), unless Phase 22 ships first.

## As built (session 43, 2026-10-14)

Built from `plan/phase-21-plan.md` in pull requests #318 to #349; the hand runs are issue #343. Every ruling, hand run, fix
and review finding, with its cost if wrong, is in `plan/sessions/043/ledger.md`.

**The pull requests.** #318 the first nightly's failures (D105). #319, #320 migration 0057 (the exam's job, a tutor's
feedback, a batched call) and its writer's own-item check. #321 the parents' four kinds on their agents with the message
rules, the golden sets and the language anchors. #322 the hour's requests test. #323 the reasons menus, the feedback writes
and the set-aside note. #324 the mock, the gap report, marking and read-marks on their agents. #325 the `exam_prep` job. #326
the exam's page reading the job. #327, #328 the morning's plans through Message Batches with the hour's cache, the repairs
batched too (D111). #329 three kinds the CI evals found short. #330 Make's V1 kinds on their agents and their PDFs on the
server. #331, #332 the standing cost report and the portal's Cost page. #333 the nightly's sets and `bun feedback-cases`.
#334 Share takes a V1 result's server PDF. #335 the nightly's parent's-message cases start with no student (0063). #336 D112:
no automation spends on AI calls (0064). #337 to #342 what the hand runs found. #344 to #349 the review's findings (0065).

**Deviations from the plan, each a ruling in the ledger.**
- D111 (the owner's): a batched plan's repairs and their checks go in batches too.
- D112 (the owner's): no pull request, push, schedule or deploy makes a paid AI call; the evals and the nightly run by hand;
  the deploy's smoke is free; the pre-PR proof (`docs/working/pre-pr-proof.md`) carries what CI did.
- Every check is told a finding is something the draft must change (#339); the full eval run that proved it fixed three
  kinds' words (progress note, register, mock).
- A material draft is keyed by its request and a replace is live (#344): a gap report no longer pays for the plan again.
- The plan and the page each compute an exam's split by the same rules; the item's `preparation` is the job's record
  (R-api-4's ruling). A function lost between sending a batch and recording it may send a second (R-api-5's ruling).
- The call page's Feedback row waits for its board (rule 1); `admin_call` returns the rows.

**The cost measured** (local stack, real models). Tomorrow's two plans by batch ₹6.34 (Class 8 Science ₹3.02, Evening
batch ₹3.32; 20 items) against Phase 20's ₹11.24 (15 items): about half, from the batch's half price and the hour's cache.
3 of 30 drafts repaired, none refused. Make's nine once each ₹17.82: sheet ₹1.60, worked example ₹0.85, figure ₹1.41
(repaired), brief ₹1.86, mock ₹5.61, note ₹0.37, paper ₹2.77, homework ₹1.15, worksheet ₹2.20. The Cost page's
`admin_cost_by_step` agrees with the rows' sums to the paisa (49 rows): the standing report replaces the session's cost run.
The phase's real-call spend about ₹1,770 of the owner's ₹3,000: most of it the evals (CI's runs before D112, the V1 kinds'
golden sets, the full run on the new check rule).

**Production.** Deploy A and B (migrations to 0058), Deploy C (e782718, to 0062), Deploy D (c00e494, 0063 and 0064, no
`schedule_evals` cron), Deploy E (527ae78, the hand runs' fixes), Deploy F (69d8389, 0065 and the review's fixes), the
portal (run 38563016478). TestFlight 1.0.0 (31) from run 38583690172 at 9a8f7ea9.
