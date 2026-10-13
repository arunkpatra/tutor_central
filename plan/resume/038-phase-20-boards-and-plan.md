# Resume 038: Phase 20 (V3 AI quality, the material), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: plans on Fable, builds on Opus). Phase 19 is built and deployed: the admin portal at admin.tutorcentral.in, the alerts
job live, migrations 0001 to 0050 in production. Phase 20 changes what the tutor sees: mathematics on the sheet, the worked
example, the mock, the board view and the Kit. So its boards come first (rule 1; boards before the plan, the owner's 2026-10-11
rule). This session draws those boards on the design canvas, gets them approved, mirrors them into `docs/design/`, then
writes `plan/phase-20-plan.md` and the build's resume prompt, and stops for the owner's review.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D98). Phase 17 laid the foundation (jobs, the
recorded call, request ids, observability, the gated deploy). Phase 18 moved the platform work onto the server and reaches the
iPhone through APNs. Phase 19 gave the owner the portal and the alerts. Phase 20 makes the material good: an agent per kind
with a checking step, prompts versioned, evals gated in CI, and mathematics shown properly. Read, in this order, before doing
anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `admin/CLAUDE.md`, `docs/design/README.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D98; D35 the SDK, D62 group kinds, D67 `models.json`, D73 an
   agent per kind, D74 prompts and evals, D75 mathematics, D76 the recorded call, D83 the platform's identity, D86 merge on
   local green, D87 production through the signed-in CLIs, D89 Typst, D90 the server's PDFs, D97 the portal's loading states,
   D98 Vercel Pro).
3. `plan/phase-20-ai-quality-material.md` (the scope and acceptance), `docs/spec-v3.md`'s sections on the agents, the evals and
   mathematics, `plan/phase-19-admin-portal-reading.md`'s "As built", `plan/phase-18-server-work-and-push.md`'s "As built".
4. `plan/sessions/039/record.md` and `ledger.md` (Phase 19's build: what was found and how it was fixed),
   `plan/phase-19-plan.md` (the plan's form to follow).
5. What Phase 20 moves: `api/src/routes/v2.ts` and `routes/common.ts` (the material kinds), `api/src/claude.ts`,
   `api/models.json`, `api/src/price.ts`, `api/src/jobs/kinds/plan.ts` and `pdf.ts` (Typst), the app's renderers for the sheet,
   the worked example, the figure, the mock and the board view (`ios/`), the Kit's boards on the canvas, and Phase 15's cost
   run (`plan/phase-15-make-and-polish.md`), which is the figure Phase 20's cost run is set against.

**First, before the boards:** read the first morning's `alerts` rows in production (14 October, the jobs at 05:30 India time
and after) with `supabase db query --linked`: what was raised, emailed and pushed, and whether any is a false alarm. Put it in
the ledger and in one line to the owner. A wrong line is Phase 19's to fix (D68) before Phase 20 starts.

**What is already true:** production holds 0001 to 0050. The API and the portal are at `main`'s head of 13 October, both in
`bom1` beside the database in Mumbai. The portal moves with Next's `Link`, a loading state per page and pending buttons (D97,
#289). Vercel is on Pro (D98); Supabase is on Free until the external testing round (D85). Git deploys are off on all three
Vercel projects: deploys only through `deploy.yml`, `deploy-web.yml` and `deploy-admin.yml`. The Supabase, Vercel and GitHub
CLIs are signed in on the owner's Mac: do production's setup yourself (D87). Real Claude calls for testing are allowed without
asking; be judicious. The cost of a call is in `bun cost` and on the portal's Cost page.

**Your work:**

1. Reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`); `bun check` green; open `plan/sessions/040/ledger.md`;
   the morning alerts above.
2. Phase 20's boards, on the design canvas (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D, a new row below row 27's
   loading boards at y 77000): the sheet (both bands), the worked example, the mock and the board view with equations in
   both appearances, the Kit's maths preview, a sheet's PDF page with an equation, and the words a kind switched off says to
   the tutor (D73's kill switch). The tutor's words only, no technical words (D41). Show them to the owner in groups, get
   each group approved, mirror each approved board into `docs/design/` (the canvas memory's steps).
3. `plan/phase-20-plan.md` with `superpowers:writing-plans`, in Phase 19's form:
   - The pipeline: one agent interface (draft, check by a different model, repair once, refuse in words), prompt caching on
     the shared prefixes, `ai_models` in the database seeded from `models.json` with the fallback recorded on the row.
   - Prompts as files with a version and hash on each row.
   - Golden sets in `api/evals/` (the seed's names, no real data), and promptfoo in CI with its pass-rate gate. promptfoo is a
     new dependency, so it needs a decision; pin it.
   - The first nightly run through the Batches API, its result a row the portal shows.
   - Mathematics: SwiftMath pinned, Typst's `mitex`, Hindi and Kannada inside a formula.
   - Each kind moved, with its rubric, golden set and board.
   - The kill switch's column and words.
   - For every task: test first, the review focus, the hand runs (D32), the pictures (D7: `tools/shots.ts` for the app,
     `bun admin-shots` for the portal), and a cost run against Phase 15's.

   Decide what is yours to decide and say so; ask the owner only what is his.
4. Write `plan/resume/039-phase-20-build.md` (Opus 5.5) and index it in `plan/resume/README.md`. Write the session's record and
   owner messages, update `STATE.md`, and commit to `main` (D12). Stop for the owner's review of the plan.

**The owner's rules:**
- Be brief.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy,
  what a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41).
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55).
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68).
- Polish goes on `plan/ui-polish.md`.
