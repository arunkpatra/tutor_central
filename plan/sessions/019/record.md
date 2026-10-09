# Session 19 (2026-10-09): Phase 9's run begins

Model: Claude Opus 5.5, from `resume/018-phase-9-run.md`, with `superpowers:executing-plans` (inline). Outcome: Tasks 1 to 3
of `plan/phase-09-plan.md` done; build 18 in Beta App Review; Task 4 handed to the tester. No code, no pull request.

## What was done, in order

1. Read the rules, the state, the plan, the phase file, the release checklist, the device tests, session 18's record. Reality
   matched `STATE.md`: `main` at `999e881`, nothing open, `check` run 37956293284 green, `/health` at `2448295`.
2. **Task 1.** `gh workflow run deploy` (run 37965871936): the database job green (nothing pending), the API and its smoke
   green; `/health` reports `999e881`. `bun check --fresh` green (93.4 s, all seven steps). The checklist's "Before the
   build" and "The build" ticked with proofs; build 18's notes written (the Phase 7 list became one "Earlier" line). The
   owner: build 18 passed on his phone, so it is the review build.
3. **Task 2.** The guide and the findings file written from the plan; words checked against the banned list (nothing) and
   against the app's strings; D7 names the Tutors group; "How to run" carries "Pass on build N, unchanged".
4. **Owner steps 1 to 3**, one at a time, each "done": Test Information (the description, the Marketing URL, the review
   contact, sign-in with the demo account typed by the owner, the notes' "Signing in" and "Teaching tools" paragraphs), the
   "Tutors" group (public link off), build 18 with its notes as What to Test → Submit for Review: **Waiting for Review**,
   2026-10-09.
5. **Task 4, step 1:** the message for the tester (D1 to D6 and D8 on the internal install; D2 re-checks #84, D5 on a
   throwaway Apple ID, D7 after approval) given to the owner to send.

## Rulings

- The guide and the notes say "More, then Settings", "More, then Help", "More, then Account" and "Save attendance": the app
  has no Settings tab (Settings, Account, Help are rows under More) and the attendance button reads "Save attendance". The
  plan's text was inexact; recorded in its small decisions.
- The checklist's D32 line for build 18 rests on the full hand run on build 14's code (session 17) and #85's Scan hand run;
  #83 to #87 changed no write itself (#86 changed only how a refused write is told, covered by `NoticeCenterTests` and its
  launch states).
- What to Test was given to the owner with the hard-wrapped lines joined (the same words as `docs/release.md`).
- The testers' facts (Task 2, step 4) wait for Owner step 4: the owner does not know the tutors yet. The D52 mix is checked
  then, before any invitation.

## The owner's questions answered

- What Beta App Review is: Apple's App Review staff, not the public; a lighter review than the App Store's; approval makes
  the build available to the group, and only those invited by email can install it.
- Whether it is mandatory: yes for external testers (the first build of a version); internal testers skip it but must be
  App Store Connect team users, which the tutors should not be.

## Next

New sessions from `resume/018-phase-9-run.md`, each with what the owner brings: Apple's answer on build 18; the tester's
lines (Task 4, step 2); on approval, Owner step 4a (the tester, D7), then the testers' facts and Owner steps 4 and 5.
