# Resume 045: the external testing round on build 32

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1.
V1 and V2 are the product and V3 the platform under them; Phase 23 put the brand mark in (D120, D122). Production holds
migrations 0001 to 0068, the API at `ff534ffd`, the website and the portal at `5675c376`; **1.0.0 (32)** is on TestFlight
(run 38870869498) and on the owner's iPhone ("icon fine", "maths fine"). The round runs on build 32 (D121) by Phase 15's
Tasks 20 to 23 and Phase 9's method (D52 to D55); Phase 16 (D81) follows it.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. This session starts
the external testing round: the tester's device checks, then six tutors for three weeks, on build 32. Read, in this order,
before doing anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `docs/working/testing.md`, `docs/runbooks/simulator.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D122; in particular D52 to D55, D66, D68, D69, D81, D85,
   D107, D112, D121).
3. `plan/phase-15-plan.md`: Tasks 18 to 23 whole (the notes, the guide, the owner steps, the readings, the close, the
   documents), and `plan/phase-15-make-and-polish.md`'s "As built, the build" and the round's documents it names.
4. `plan/phase-09-plan.md` (the method the round follows: D52 six tutors three weeks, D53 device checks first, D54 the guide on
   WhatsApp, D55 the findings and no tutor's name in the repository).
5. `docs/release.md` (build 32 is the round's build; the unticked lines are the round's), `docs/testing/device-tests.md`
   (D1 to D8, T1 to T22, C, A, N and W; the log), `docs/store/listing.md`.
6. `plan/sessions/046/record.md` and `ledger.md` (Phase 23, build 32), and STATE's open items (Supabase Pro is bought before
   the round, as a step of its checklist, D85).

**What is already true:**
- Build 32 carries everything since build 31: the brand mark and #363 (formulae drawn in rows). Its release notes are in
  `docs/release.md` under "1.0 (build 32)".
- The owner's own test of build 32 passed in session 46 (the icon in light and dark, a brief's maths). T22's other parts (clear
  and tinted, Spotlight, Settings, a notification) wait for the tester.
- No automation spends on AI calls (D112). The tutors' calls in production are the product's, not testing.

**Your work:**
1. Check reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green. Open
   `plan/sessions/047/ledger.md`.
2. The round's checklist before any invitation: Supabase Pro (D85) as an owner step; `docs/release.md`'s App Store Connect
   lines for build 32 (Phase 15's Task 20, Owner steps 1 to 3), one at a time, each a numbered list of exact actions with what
   success shows.
3. The tester's device checks on build 32 (Task 20): D1 to D8, T1 to T22, C, A, N and W on their V2 paths, logged under build 32;
   a Fail is a finding (D55) fixed by Task 21's shape with a new build before any tutor is invited.
4. Owner steps 4a, 4 and 5: the tester, the six tutors, the guide on WhatsApp (D54).
5. The readings (Task 21) as they come; the close (Task 22) and the documents (Task 23) when the three weeks end. This session
   ends at a clean boundary (the invitations sent, or a reading done) with `STATE.md` updated and the next resume written.

**The owner's rules:**
- Be brief. One question at a time, only for decisions that are his, with a recommendation and its reasons; decide the rest
  and say so, with its cost if wrong, in the ledger. Keep costs in the ledger, not in front of him.
- Any step he takes is a numbered list of exact actions: the site, each menu item by its label, what to copy, what a prompt
  asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41).
- No tutor's name, email or number in the repository (D55); no secret (D11).
- A phase fixes what it finds (D68); decisions are never reopened, a change gets a new number.
- Nothing on screen without its board (rule 1).
