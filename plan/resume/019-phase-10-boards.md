# Resume 019: Phase 10 (V2 design and foundation), Part A, the boards

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (D17: design and planning on Fable; Part B, the plumbing, goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors. V1 (Phases 0 to 9) is built and in user testing;
V2 starts with Phase 10. Read, in this order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D65; D56 to D65 are V2's), `plan/ui-polish.md`.
3. `docs/spec-v2.md` (the approved V2 spec; section 2 is the design method, sections 4 to 8 are what the boards show),
   `docs/v2/research.md` (the evidence behind it), `plan/phase-10-v2-design-and-foundation.md` (the scope),
   `plan/phase-10-plan.md` (Part A is yours: steps 10.1 to 10.7).
4. `docs/design/README.md` (the board process and the rule that a board's figures are illustrative), `design-tokens.md`,
   `components.md`, `guidelines.md`, `information-architecture.md`, `feedback.md`; the approved V1 boards in
   `docs/design/mockups/` (the V2 screens extend them: Today, Students, More, the Kit).
5. `plan/sessions/020/record.md` (this plan's session: the brainstorm, the owner's words on voice and names) and
   `plan/sessions/014/record.md` (how the Phase 7 boards were drawn by script, checked by headless Chrome and approved).

**What is already true:** V1 is on TestFlight (build 18, Beta App Review) with Phase 9 running alongside; the V2 spec is
approved; nothing of V2 is built or designed yet. The canvas is https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; rows 1
to 13 are V1's; Phase 10's boards go in rows 14 to 20 (y 37200 and every 1400 after), one row per step.

**The owner's rules for this work:** the word is "Students", not "Children"; the tab is "Today", not "Tonight"; copy and
documents in a plain voice (no slogans, no "every"); no technical words on screen (D41); plain labels on empty-state
buttons; the design method of spec section 2 (each feature works alone; the plan is a suggestion; no set-up gates
except consent). Decide small things yourself and say what you decided; ask one question at a time for the rest.

**Your work:** steps 10.1 to 10.7 of `plan/phase-10-plan.md`, one at a time, each approved by the owner before the
next: draw by script (copy the Phase 7 generator pattern into the scratchpad), render each board with headless Chrome in
both appearances, stitch contact sheets, look at them against the spec and D41, send them, and on approval publish the
row to the canvas, mirror into `docs/design/`, add the list, launch states and what the boards settle to
`information-architecture.md`, new parts to `components.md`, new values to `design-tokens.md`, and commit as documents
(D12). After 10.2 is approved, tell the owner Part B may start on Opus from `resume/020-phase-10-build.md` (write that
prompt then, from the plan's Part B). Update `plan/STATE.md` before you stop; write `plan/sessions/021/record.md` at
the end.
