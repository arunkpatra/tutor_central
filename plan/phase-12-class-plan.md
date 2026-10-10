# Phase 12: The plan

**Status:** Not started. **Depends on:** Phase 11; boards 10.3 and 10.4.

## Goal

Today shows a plan per batch with the material made, and the close follows from it.

## Scope

1. **The plan.** `/ai/plan` from the record: groups by level across classes, the subject per student (nearest school
   item, else least recently taught, else the batch's weekly pattern), four lines per student, catch-up lines; the
   tutor moves a student, drops the groups, skips a line; a plan with no record (new students) still makes one from
   class levels.
2. **The material.** `/ai/make` per group: the set, the sheet (PDF, board view, key), the checks; the worked example;
   figures from their specs (number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain);
   the brief when the chapter is above class 7 or the tutor has asked about it; regenerate with a reason; "Own"
   (the tutor's photo) in a line.
3. **When it is made.** On open, with "Planning today's class"; in a background refresh when iOS grants one; the local
   reminder at the tutor's time (default an hour before the batch). The artefact budget per session (a Domain rule).
4. **The close from the plan.** The lines as the checklist; checks from the plan; homework from the plan; offline.
5. **Cost measured.** Tokens per kind per group from `ai_generations`, reported in the session record for D64.

## Acceptance

- Boards matched; pictures; hand run of the close from a plan and of a regenerate.
- The cost of a twelve-student batch across three groups is measured and written down.
- A student without consent gets group material and checks (no personal data), and no personal artefact.
