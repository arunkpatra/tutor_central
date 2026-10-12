# Phase 21: V3 AI quality, parents and exams

**Status:** Not started. **Depends on:** Phase 20.

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

## Acceptance

- A note day made by a job, checked, read on the phone in Kannada with English beside; a note that names a fact not in the
  record is refused by the check (a planted test).
- An exam's preparation runs as one job across its days; the mock's marks sum; the gap report adjusts the split.
- The cost report shows the month's spend per centre against D64's price; batched work costs half the live price in the report.
- Pictures, hand runs, a build on TestFlight: the external testing round's candidate (D81), unless Phase 22 ships first.
