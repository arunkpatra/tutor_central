# Phase 13: School

**Status:** Not started. **Depends on:** Phase 12; boards 10.5.

## Goal

What a school sends reaches the plan: exams, portions, homework and notices become items, and exam preparation runs
from the school's own dates.

## Scope

1. **The share extension.** "Share to Tutor Central" from WhatsApp and Photos; text or image through the app group
   to the School tab; `/ai/parse-school`; items shown for confirmation (kind, student or class of a school, subject,
   date, portions); a photo kept in Storage under the centre.
2. **Items and the calendar.** Per student and per class of a school; the calendar by date; edit and delete; a
   holiday removes the batch's plan for the day.
3. **"Ask parents to forward."** The message, sent once, logged.
4. **Test tomorrow.** The parent message from an exam item, suggested the evening before; held by the cadence rule.
5. **Exam preparation.** The window (14 days default); the split of portions across days; a daily set; the mock in the
   school's pattern or the board's blueprint two days before; marking from a photo (`/ai/check-paper`); the gap report
   that adjusts the last days; class 10's two dates.
6. **Marks on the student's page** (`plan/ui-polish.md` U36, moved here by the owner, 2026-10-10): a Marks section in the
   record from school tests and checked papers; its board approved before it is built (rule 1).

## Acceptance

- Boards matched; pictures; the share path in the simulator runbook and hand-run.
- A forwarded timetable photo of two subjects produces two exam items with the right dates after confirmation.
- A school exam within the window changes the student's lines to revision on Today.
- U36 moves to Done on `plan/ui-polish.md` with the pull request that builds it.
