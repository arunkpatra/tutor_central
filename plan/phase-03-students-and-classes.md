# Phase 3: Students and classes

**Status:** Done (session 6, 2026-10-08): PRs #24 to #31, the final review's fixes in #33; migration 0003 in
production; build 0.1.0 (6) on TestFlight. **Depends on:** Phase 2 (done); Phase 0's Phase 3 boards (approved 2026-10-08, `docs/design/mockups/P3-*`).

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

Session 6, Claude Opus 5.5, from `resume/005-phase-3-build.md`, executing `phase-03-plan.md` inline. Eight pull
requests as planned:

| PR | Tasks | What |
|---|---|---|
| #24 | 1 to 3 | Domain: weekday, time of day, calendar day, gender, initials, `Classroom` and its draft, `Student`, `MonthFee`, its draft, the register's query |
| #26 | 4, 5 | Data: students and classes repositories (PostgREST and fakes seeded as `seed.sql`), the JSON cache |
| #25 | 6 | Migration 0003 `archive_class`; the delete cascade proven; deployed to production the same hour (D26) |
| #27 | 7 to 9 | The Phase 3 DesignSystem components; `RegisterStore`; the Students root to its six boards |
| #28 | 10, 11 | The student form store; New student to its three boards |
| #29 | 12, 13 | Student detail, archive, restore, typed delete, edit; the student deep link |
| #30 | 14 to 17 | Classes list, class form with Archive class, class detail, add students |
| #31 | 18 | The Phase 2 minors in these files: ASCII digits, shadows parsed once, success and error haptics |

**What exists.** `Domain` holds the register's types and every rule of scope item 6, tested (Review Focus 2 and
3 included). `Data` reads students with this month's invoice embedded (`fee_invoices.period` filter, checked
against the local stack) and classes; writes are column maps, so an edit clears what the tutor cleared;
`archive_class` is the one RPC. `Features/Students` has one `RegisterStore` for the tab (kept by `ShellState`
across tab switches; cache first, then the network; optimistic writes with rollback, a toast naming the student
and Retry; delete waits for the server), the form stores, and the screens: the Students root, New and Edit
student, the student detail, Classes, the class form, the class detail and the add-students sheet. AppShell has
the routes (`student`, `classes`, `classroom`), `tutorcentral://student/<id>`, and 21 Phase 3 launch states.

**Acceptance, line by line.**
- Every screen matches its board; screenshots in PRs #27 to #30, both appearances, for all 21 states.
- Add, edit, move between classes, archive, restore and delete a student, and a class likewise, with the list
  following without a reload: `RegisterStoreTests` against the fakes. After the final review, every Swift read and
  write the app makes was run against the local stack as the seed's tutor (a throwaway test). Not done: the screens
  driven in the simulator against the local stack (typing into the simulator was unreliable in this session); the
  owner's install of build 6 is the first hand run.
- The seed's ten students and two classes: the PostgREST read of `seed.sql`'s rows was run against the local stack
  (curl); the fakes carry the same rows with fixed ids.
- Domain tests cover every rule in item 6 (45 Domain tests).

**Deviations and why** (each a ruling in `plan/sessions/006/record.md`; none changes a numbered rule):
- The type is `Classroom` (the plan's decision). The "+" menu is a popover with the board's rows; the system does
  not dim the screen behind it as the board does. Removal from a class is the row's context menu; there is no
  swipe (the members are a card).
- Searching "sh" finds four students, not the board's three: "Lakshmi" contains "sh" too, and the rule is any part
  of the name (Review Focus 2). The layout is as drawn.
- The date of birth and the class times are the boards' accent values that open the system's pickers in a popover
  (graphical for the date, a 24-hour wheel for times, with Clear); the system's compact pickers draw a capsule the
  boards do not. The plan's "Clear times" button under the tiles is not on a board, so it is not there.
- Edit class and its archive confirmation open over the Classes list, as P3-EditClass draws them; Edit in the class
  detail opens the same sheet. The class form sizes to its content; the add-students sheet opens at the board's
  59% and drags to large.
- A member's own fee is `footnoteStrong` (13/600, a new token, D25) as P3-ClassDetail draws it; `components.md`
  said `numberRow`. `Card` gains `.onSheet`; the checklist's tick is `okInk` as drawn. `EmptyState` takes two
  actions side by side (P3-Students-Empty).
- A link to a missing student takes the route off the stack from AppShell (`TabsState.remove`) and shows the
  toast: a `dismiss()` during the push was lost and left an empty screen (found with `simctl openurl`).
- The detail and the classes screens wait for the register (`loadIfNeeded`) before deciding anything is missing:
  a pushed launch state first saw an empty register.
- Archived classes are not listed (no board draws them); a waived month reads "Waived" in `text2`.
- Three plan tests were wrong and were corrected: the search fixture gave both students the same number; the retry
  test expected the failed attempt to reach the fake; the class order expected the database's text order, which
  the fake and the store now keep. One plan rule was wrong: a typed "+91 98111" did not match; it does now.

**Final review:** one Critical (student saves did not decode their answer; Retry duplicated) and six Important,
fixed in PR #33 and proven against the local stack in Swift; build 0.1.0 (5) carried the Critical, build 6 replaces
it. The deferred minors are in `plan/sessions/006/record.md`.

**Remains, for later phases or polish:** the detail's Attendance section, Fees "See all", Mark attendance and Scan
register open the later board until Phases 4, 5 and 6; a class restore if ever wanted; the owner's UI polish pass.
