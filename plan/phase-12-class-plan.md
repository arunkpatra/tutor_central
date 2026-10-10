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
6. **Polish taken with the phase** (`plan/ui-polish.md`, the owner, 2026-10-10): U35, the student page's This week
   "Today" link, opening Today at the student's batch and plan; U37, the close card's no-book and offline sentences,
   designed with the close's checklist; U38, the close card's wait for checks, which ends when the plan makes the checks
   ahead (close the row if no wait remains, else design it); U39, a symbol of its own for a waiting close in Pending
   changes. U37 and U39 need their boards approved before they are built (rule 1).

## Acceptance

- Boards matched; pictures; hand run of the close from a plan and of a regenerate.
- The cost of a twelve-student batch across three groups is measured and written down.
- A student without consent gets group material and checks (no personal data), and no personal artefact.
- U35, U37, U38 and U39 move to Done on `plan/ui-polish.md` with the pull requests that close them.
