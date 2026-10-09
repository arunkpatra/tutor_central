# Session 18 (2026-10-09): the Phase 9 plan

Model: Claude Fable 5.1, from `resume/017-phase-9-plan.md`, with `superpowers:writing-plans`. Outcome: `plan/phase-09-plan.md`
approved by the owner; decisions D52 to D55 in `plan/README.md`; `resume/018-phase-9-run.md` for the Opus 5.5 run. No code.

## What was done, in order

1. Read the rules, the state, the decisions, the polish list, the phase file, the release checklist, the device tests, the
   listing, the feedback guide, session 17's record, ledger and messages. Reality matched `STATE.md` (`main` at `1bcd810`,
   nothing open, `bun check` green from cache), except two remote branches of merged pull requests still there
   (`tools/review-seed`, `tools/store-shots`).
2. Checked two facts before planning: the API in production (`/health` → `2448295`) is behind `main` by #81 (the phone trunk 0
   that device test S3 expects, and D48's limits); `ITSAppUsesNonExemptEncryption` is false in `Info.plist`, so builds do not
   wait on a compliance question.
3. Asked the owner's two questions, one at a time: who tests and for how long ("6 tutors, 3 weeks", the recommended mix);
   the device checks before or beside the tutors ("Before the tutors are invited").
4. Wrote the plan: D52 to D55, a calendar, Review focus (a phone below iOS 26; the API behind the app; a finding without a
   build or a tester; an unsymbolicated crash; a duplicate or an existing polish row), eight tasks with the owner's seven
   App Store Connect steps one at a time, the tester's guide and the findings file written in full, the self-review. The
   guide's words were checked against `ErrorWordsTests.banned` (nothing found) and its labels against the app's strings
   (Help's row is "Email hello@tutorcentral.in", corrected).
5. The owner approved as written. Recorded D52 to D55, the phase's status, resume 018 and its index row, `STATE.md`, this
   record and the owner's messages; pushed to `main` as documents (D12).

## Why things are as they are

- **Named invitations, no public link (D53):** six chosen tutors; the link's "anyone with it" is a different test. The tester
  is invited first so D7 (the invitation path) is proven before a tutor meets it.
- **The guide on WhatsApp, not the site (D54):** the site is what Apple reads; a page would need a board, a pull request and a
  deploy; the tutors are on WhatsApp (D3). Its short form is "What to Test", so the words live once in `docs/release.md`.
- **Readings twice a week, builds on Thursday (D53, D55):** weekly is too slow for a crash in a three-week phase; a build a day
  would make the testers' builds a moving target. A crash or a lost write ships the day its fix merges.
- **No names in the repository (D55):** the tutors are T1 to T6; the owner keeps the mapping; a picture showing a parent's
  number is covered before it is committed.
- **A device test on the final build may be carried as "Pass on build N, unchanged"** when nothing it touches changed: the
  acceptance allows "or a reason", and re-running thirty tests on a real phone for a build that changed one screen is not a
  better proof.
- **The API deploy is Task 1, not an owner step:** sessions run `deploy.yml` (session 15 did); the owner's steps are only
  App Store Connect and the messages to the tutors.

## Tried and dropped

- A three-question split (how many, which, how long): the owner's brief says one question at a time, so one question with a
  recommended mix and "Other" for a split.
- A page `/beta` on the site for the guide (D54 says why not).

## Machine

Nothing run but `bun check` (green from cache) and `curl` on the production API.

## Next

Phase 9's run from `resume/018-phase-9-run.md` on Opus 5.5: Task 1 (confirm build 18, deploy the API, the checklist and
notes), Task 2, Owner step 1.
