# Session 22 (2026-10-10): Phase 10 Part B, the plumbing

Model: Claude Opus 5.5 (D17), from `resume/020-phase-10-build.md`, with `superpowers:executing-plans` (inline, one ledger:
`ledger.md` beside this record) and `superpowers:test-driven-development`. Outcome: Part B of `plan/phase-10-plan.md` done,
PRs #90 to #96, two production deploys, a fresh final review, a TestFlight build; Phase 10 done. The owner cancelled Phase
9's tester run and made V2 the product (D66).

## What was done, in order

1. Read the rules, the state, the decisions, the V2 spec, the Phase 10 scope and plan, the 10.2 and 10.3 notes in
   `information-architecture.md`, the records of sessions 20 and 21, the migrations and tests. Reality matched `STATE.md`;
   `bun check` green. The pre-flight scan of the plan's interfaces went into the ledger (Task 8's `textbooks.chapters` and
   `copy_textbook_chapters` moved into Task 1's migration; `chapters.syllabus_id` referenced in 0011).
2. Task 1 and 2 (PR #90): migrations 0009 and 0010, tests first in `supabase/tests/v2.test.ts` and the catalogue and
   isolation rows in `rls.test.ts`. Merged.
3. Task 3 and 4 (PR #91): 0011, 0012 (the enum values) and 0013 (the allowance). CI failed on the photos test: its local
   Supabase was started without Storage; `check.yml` now starts it. Merged; deploy run 38042680418 applied 0009 to 0013.
4. Task 6 (PR #92): the API skeletons, merged, deployed with the same run.
5. Task 5: the generator `tools/syllabi.ts` and its tests; the 24 chapter lists given to two research agents (CBSE,
   Karnataka) reading the publishers' 2026-27 PDFs; meanwhile Tasks 7 and 8 (PR #93: Domain types, the repositories, the
   close; the write paths proven against the local stack with a throwaway Swift test) and Task 9 (PR #94).
6. Task 9's question to the owner: the share extension puts a "Tutor Central" entry in the share sheet that does nothing
   until Phase 13, which Phase 9's testers would see. The owner chose to keep it out; then cancelled Phase 9's tester run
   and said V2 is the product; asked again, the owner chose to embed it now. The owner registered the app group, the
   extension's App ID and the group on the app's App ID, one step at a time.
7. The agents' 24 files reviewed (schema, blueprint sums, spot checks, no book text) and committed with migrations 0014 and
   0015 (PR #95). #93, #94, #95 merged; `main` green.
8. The final review of the whole range on Fable 5.1 (fresh context): no Critical, three Important (a second capture of a
   book wiped the students' progress; the mock's blueprint names did not fit the API's schema; photo paths with the centre's
   id in capitals were refused), eight minors. One fix pass, each fix test first (PR #96, migration 0016). Deploy run
   38046925061 applied 0014 to 0016; the API at `d98e8e5`.
9. TestFlight run 38047105651 (build 19), the first with the share extension. Archived with the extension embedded and cloud-signed under the new App ID and app group, exported, uploaded.
10. Task 10: "As built, Part B", the README (rows 9 and 10, D66), `STATE.md`, `phase-09-user-testing.md` and
    `phase-15-make-and-polish.md` (D66), resume 021 and its index, this record, the ledger and the owner's messages.

11. The owner installed build 19 on his iPhone: the V1 screens fine. He withdrew build 18's Beta App Review for the
    "Tutors" group.

## Why things are as they are

- **The tables carry what the approved boards show,** beyond the spec's list: how the parent agreed (`consent_how`), since
  when a status holds (`track_since`), the ladder as one chapter per area with the five steps as skills (so checks and
  states work unchanged for LKG to 3), the placement's answers as checks without a session (`checks.kind`), homework with
  no sheet (the close runs without a plan in Phase 11), the close linking the day's plan.
- **The ladder's steps are the boards',** not the plan's lists: the boards are binding (rule 1).
- **Migration numbers are digits only** (0012 and 0013 for the plan's 0012 and 0012b), so the syllabi are 0014 and 0015 and
  the review's fix is 0016.
- **Photos are add-only:** no update policy on `storage.objects`; a new photo takes a new path.
- **A second capture of a book keeps progress:** chapters match by position in the book, skills by position in the chapter.
- **The share extension is embedded now** (the owner): cloud signing of its App ID and the app group is proven with build 19
  rather than in Phase 13.
- **The syllabus data was transcribed by agents and checked here,** never taken on the agents' word; its soft spots are in
  the phase file and `STATE.md`.
- **V2 is the product (D66):** Phase 9's tester run is cancelled; the first tutor round is Phase 15's, by Phase 9's method.

## Tried and dropped

- Keeping the share extension out of archives until Phase 13 (a scheme entry for run and test only): built, then undone when
  the owner chose to embed it.
- A temporary table inside `copy_textbook_chapters`: replaced by the same subquery in three statements (a member may not be
  allowed temporary tables).
- The plan's hand-escaped JSON in the share extension: replaced by an encoder (a tab or other control character broke it).

## Machine

The local stack in Docker; the iPhone 17 simulator; a scratch `xt.sh` (build for testing, then only the named tests);
`.superpowers/sdd/phase-10-plan/` held the ledger and the review package (git-ignored, removed at the end).

## Next

Phase 11's plan on Fable from `resume/021-phase-11-boards-and-plan.md`; then its build on Opus.
