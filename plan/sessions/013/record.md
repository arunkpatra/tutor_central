# Session 13 (2026-10-09): the Phase 6 build

Model: Claude Opus 5.5 (D17), from `resume/012-phase-6-build.md`, executing `plan/phase-06-plan.md` with
`superpowers:executing-plans` (inline, one ledger, one fresh reviewer at the end). Outcome: Phase 6 built in PRs #53 to
#59, with #60 (the hand run's fixes) and #62 (the final review's fixes); the D32 hand run on issue #61; migrations 0006
and 0007 in production; the API at `6eea8b8`; build 0.1.0 (9) on TestFlight. The owner's camera scan on the iPhone:
"Installed the build on phone. Works". The other device checks went to a tester: `docs/testing/device-tests.md`.

## What was done, in order

1. Read the rules, the state, the plan, the boards and the runbook; rendered the 44 P6 boards with headless Chrome into
   the scratchpad to read every value. Loaded the `claude-api` skill before writing any call to Claude.
2. PR 1 (#53), the database: `pending` on `ai_status` (0006); `start_ai_generation` (0007), the member check, the
   consent for a child's data, the day's limit, the record; RLS tests. A security review found the limit could be
   dodged by deleting rows or marking them failed: a hard cap, DELETE revoked, UPDATE limited to five columns, a test.
3. PR 2 (#54), the API: Claude through `@anthropic-ai/sdk` (D35), the prompts, the image checks, the routes, the fake
   (`AI_FAKE=1`); bun tests against a fake Claude and a fake database. The deploy failed Vercel's type check on the
   SDK's default import; #55 used the named export and the deploy went green. Real calls with the owner's key worked
   (the papers were left in `/tmp/tutor-central/` for the owner); one paper's marks added to 17 of 20, so the API now
   plans the sections.
4. PR 3 (#56), Domain and Data: generations, results, the scan review, marks, the note line; the API client, history,
   consent, bulk students, notes, the progress log. Every read decoded; every write proven in Swift against the local
   stack in a throwaway test (deleted).
5. PR 4 (#57), AI Assistant, More's row and Today's Create row; PR 5 (#58), Scan register in Students (D36); PR 6
   (#59), Check a paper. Every state photographed in both appearances beside its board. The PR 5 hand run found Fix
   this row losing typed digits (the form store remade on re-render), fixed before merging.
6. The D32 hand run (issue #61), from a cold simulator and a reset seed: against the fake API (consent, a note sent, a
   failure and Retry, a scan with nothing found and one failing, a typed-scheme check with Save and Undo, Today and
   More), then against Claude (a paper, Create again, Copy, a PDF to Files, the sample register read 8 of 8 right and
   Add, a two-page and a six-page check). Two dead taps found and fixed in #60.
7. The final review: a fresh Opus reviewer on 76ed710..33e6fe6. No Critical; six Important, all kept after re-grading
   and fixed, each with a test that failed first (one on #60, five in #62), each run again in the simulator.
8. Deploy (run 37869867840), TestFlight (run 37870068225, build 9), the owner's camera check; the owner chose a tester
   for the rest, so the device tests became a living document on `main`.

## Why things are as they are

Every ruling was taken during the build and written in the ledger with what it costs if wrong. The ones that shape
the code are in the phase file's "As built"; the rest:

- **Branches in the main checkout** (`phase-6/…`), not a worktree: `bun shots` and the simulator tie to this checkout.
  Cost if wrong: none.
- **Tests placed and shaped for what runs:** the new RLS tests go before the delete-centre test (it deletes centre A);
  `StubProtocol` keeps its recorder in a `Mutex` and `APIClientTests` runs serialized; the entry test spawns with
  `--no-env-file`. Cost if wrong: none.
- **The review ran before the TestFlight build**, not after the documents, so its fixes are in the build the owner
  checked. Cost if wrong: some time.
- **A failed Undo after Scan's Add** answers its words to the caller (`undoAdd` returns them) rather than setting them on
  a store whose screen has gone. Cost if wrong: none.
- **No `maxDuration` pinned on Vercel:** the Hono preset runs on Fluid compute (300 s), well over the API's 110 s
  deadline. Cost if wrong: a long check cut by the platform reads as a failure.
- **Minor 7 fixed, not deferred:** `AIStore.noteStudent` was dead code, which the project's rules do not allow.
- **Declined to judge, ruled to stand:** a scan does not look for the same child twice within one page (the tutor
  reviews every row); Save writes the whole notes text from the cached register (one member per centre today); a
  non-owner member cannot record consent (no invites yet).

## What was tried and dropped

- A tap gesture on the multiline field itself: it could compete with the field's own gestures; the tap now sits on a
  layer behind the field.
- Re-reading the polish notes lost to a context summary: the transcript held only the summary's list. The send sheet's
  height and the Today scroll were found again by comparing with the boards (U18, U19); "RefreshSpinner tint" could
  not be traced and was not written down.

## The final review's minors (deferred)

1. (Done in Phase 8, PR #81.) Retain cycles: `aiStore(for:)`'s `onResult` captures its store; `scanView`'s `onAdded` captures its store, and
   `scanView` builds a `ScanStore` per body evaluation (`@State` keeps the first).
2. `start_ai_generation`'s limit can be passed by two concurrent calls at 39 (the hard cap bounds it);
   `pg_advisory_xact_lock` would close it.
3. The centre-delete cascade test runs with no `ai_generations` rows since the revoke.
4. `sectionPlan` with more questions than marks drops the 0-mark section (fewer questions than asked).
5. Homework and worksheet schemes carry no marks; Claude invents each question's maximum in a check.
6. (Done in Phase 8, PR #81.) `normalisePhone` reads an 11-digit number with a trunk 0 (`09876543210`) as no number.
7. (Done in Phase 8, PR #81, D48.) The notes and draft limits count graphemes; Postgres counts code points (Indic text near 2000).
8. One scan image: the app allows 4.2 M base64 characters, the API's schema 4.0 M.
9. The "paper is no longer here" 400 goes through `errors.badImage`; `AI_FAKE=1` is not refused on Vercel.
10. A parse failure is told by the SDK's error message text (brittle across SDK upgrades; the SDK is pinned).

## Seen in the real calls

A paper in 8 to 9 s on Sonnet 5.5 (about 1,000 tokens in, 1,200 out); the sample register in 5 s on Opus 5.5, every
name, phone and fee right; a two-page check in 21 s (6,859 in, 1,997 out); a six-page one in 16 s (16,871 in). The
sample answer sheets answer an earlier paper, so against a new one they scored 1 of 20, with reasons that were right.
