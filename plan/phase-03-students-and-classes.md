# Phase 3: Students and classes

**Status:** Not started. **Depends on:** Phase 2; Phase 0's Phase 3 boards approved.

## Goal

The tutor's register lives in the app: every student with their parent's contact and fee, grouped into classes
that know when they meet. The student detail hub is the place to go for anything about one child.

## Scope

1. **Students list.** Search by name or phone; filter by class and status (active, archived); sort by name or
   fee; empty, few and many states; pull to refresh; counts.
2. **"+" menu.** Add one student; scan paper register (navigates to Phase 6's entry, which shows its "coming
   later" board state until then); create a class.
3. **New and edit student.** Name (required), class (picker, Unassigned), monthly fee (prefilled from the
   class), parent name, parent WhatsApp number (E.164 with +91 default, validated, formatted as typed), date of
   birth (optional, with the switch), gender (optional), notes (2,000 characters). Save disabled until valid.
4. **Student detail.** Header with avatar and class; parent actions (call, WhatsApp chat) as one row; sections
   for fees (this month's status now; the ledger in Phase 5), attendance (this month's percentage in Phase 4),
   notes; edit; archive and restore; delete with a typed confirmation.
5. **Classes.** List with member counts and meeting summary; new and edit class (name, subject, monthly fee,
   meeting days with "every day", start and end time, both optional); class detail with members (add and
   remove), the week's meetings, and a "mark attendance" shortcut (Phase 4); archive.
6. **Domain rules, tested.** Phone normalisation and formatting; fee prefill; meeting-day summary ("Mon, Wed,
   Fri · 17:00–18:00"); initials for avatars; sort and filter.
7. **Data.** Repositories for students and classes with cache; optimistic create and update; archive as soft
   delete.

## Acceptance

- Every screen matches its board; screenshots in the PRs.
- A student can be added, edited, moved between classes, archived and restored, deleted; a class likewise;
  the list reflects each change without a reload.
- The seed's ten students and two classes appear on a fresh sign-in to the local stack.
- Domain tests cover every rule in item 6.

## As built

(Written when the phase ends.)
