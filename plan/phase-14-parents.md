# Phase 14: Parents

**Status:** Planned (session 29, 2026-10-11): `phase-14-plan.md` (24 tasks, thirteen pull requests) and the seven Phase 14 boards on row 24 of the canvas await the owner's approval; the build runs from `resume/028-phase-14-build.md`. **Depends on:** Phase 12; Phase 13 for test tomorrow; boards 10.6, 10.3's note day and To parents, the P14 boards.

## Goal

The parent receives a weekly note about their student in their language, and the tutor sees who is not on track and
what to do next.

## Scope

1. **The note.** On the note day (default Sunday evening; changed where it appears), per student with consent, in the
   parent's language with English beside it, from the week's record; read, edit, send by the WhatsApp link; logged.
2. **Can-now-do** for LKG to 3 from the ladder; **homework** shared as a PDF.
3. **The cadence.** At most three suggested messages a week per parent; held suggestions shown as held; hand-sent
   messages not counted.
4. **Marks from a photo.** A report card or marked test to `/ai/check-paper`'s reader; the marks confirmed and saved.
5. **Not on track.** The next step on the student's page and on Today's line (re-teach, prerequisite, spaced queue,
   tell the parent), taken by the plan unless changed.
6. **Messages carry the tutor's name** and "Made with Tutor Central".
7. **The model for each kind of AI work in one place (D67).** One checked-in table of work type to model (with a class band
   where it matters; marking a handwritten paper and reading a printed report card as separate work types), overridable
   per work type by an environment variable at deploy (`AI_MODEL_<WORK_TYPE>`; an unknown model stops the API at start); `MARKING_MODEL` and the per-kind table in `api/src/models.ts` folded
   into it; the price sheet and the cost run read it; the model used stays logged per call.
8. **What Phase 13 left (D68).** U41 to U45 on `plan/ui-polish.md` (boards first where they change what is seen), the five
   `Final: minor (deferred)` lines of `plan/sessions/028/ledger.md`, and the API answering a lost database connection as
   "sign in again" (a 401 only when the token is refused; an outage answers as one).

## Acceptance

- Boards matched; pictures; hand run of a note in Kannada and Hinglish with English beside.
- A parent without consent gets no note and the tutor sees why on the student's page.
- The cadence holds a fourth suggestion and never a hand-sent reminder.
- A model changed for one work type by the table or its environment variable is the one the next call of that type uses
  and logs, with no code change.
- Phase 13's U41 to U45, five minors and the lost-connection answer are closed; nothing this phase finds is deferred (D68).
