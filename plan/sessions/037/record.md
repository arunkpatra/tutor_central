# Session 37: Phase 18's build (Opus 5.5, 2026-10-12 and 13)

From `plan/resume/035-phase-18-build.md`. The owner's messages word for word are `owner-messages.md`; every ruling, task line,
hand run and review finding is `ledger.md`.

## What was built

Phase 18 from `plan/phase-18-plan.md`, all twenty-five tasks, in #215 to #261; "As built" in
`plan/phase-18-server-work-and-push.md`. The server now makes each batch's plan and its material, the note day's notes, the
PDFs and a student's export, and reaches the iPhone through APNs: reminders, Plan ready with a background fetch, Notes ready.
Consent can be withdrawn with its history; the app shows its copies first offline.

## Checked

- `bun check` green before every merge (#250 merged with a lint failure in its test; #251 fixed main within minutes, and the
  merge step now runs only on a green check).
- Hand runs 1 to 11 against the local stack, each write confirmed in the database; issue #260 with the pictures. Run 11 was the
  pre-TestFlight hand run of the writes the review's fixes touched (D32).
- A plan job and a note day on the real models: ₹2.84 and ₹0.21.
- Two fresh reviews on Fable 5.1 (app and tooling; database and API): sixteen findings; fifteen fixed in #244 to #259, one ruled
  transitional (build 27 filling an unlinked line while the job makes the material; closed by build 28).
- Deploy 1 (run 38282034144, 0036 to 0041) and Deploy 2 (run 38311560782, 0042 to 0045 at `6d973b9`), smokes green.
- 1.0.0 (28) by run 38312753433; 1.0.0 (29) by run 38314213195 with #261, whose log shows the archive's push entitlement
  (`aps-environment`; the App Store export re-signs it for production).

## Faults found and fixed during the build

- The note day's step name was over job_steps' 40 characters (#239); APNs' sandbox dropped a stream before answering (#241);
  the job wrote the note's week in a form the app does not read, so Read asked again and a phone-made note would have been paid
  twice (#242); offline, Today, its plans, the note day and the material waited for reads that take 20 s to fail (#243, from
  build 27's time too).
- Docker Desktop died three times: stopping the local API with `kill $(lsof -ti :3000)` also killed Docker's own connection to
  that port. Only the listener is stopped now (`-sTCP:LISTEN`); runbook section 13. The local stack runs only what CI runs
  (#240).

## Decisions

- D93: Share draws on the phone also when the server's PDF is slow (five seconds); supersedes D90 for that case.

## For the owner

- Build 29 carries push (28 does too; 29 only adds the run's check). Install it from TestFlight and allow notifications (More → Settings → Teacher reminders → Turn on
  reminders): from then on reminders, Plan ready and Notes ready come from the server. Device tests T16 and T17
  (`docs/testing/device-tests.md`) are for the end-of-V3 test (D68).
- Your centre's first morning plan job on the server runs at 05:30 on 13 October; the next session reads it (steps, made and not made, cost).

## Next

Phase 19 (the admin portal, reading): its boards and plan on Fable, from a resume the owner asks for.
