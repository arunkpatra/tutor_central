# Resume 043: Phase 22 (V3 the admin portal, control and analytics), the build

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Opus 5.5
(D17: plans on Fable, builds on Opus). Phase 22 is planned: the 41 boards of row 30 on canvas 2
(`docs/design/mockups/P22-*`, https://claude.ai/artifact/JV9q2AGk1fmMDVjsGgpAqw) and `plan/phase-22-plan.md`, both
approved by the owner 2026-10-15 ("plan approved"; D113 to D118 are in `plan/README.md`).
Production holds migrations 0001 to 0065, the API at 69d8389 and the portal at its Phase 21 deploy, both in `bom1`;
1.0.0 (31) is on the owner's iPhone ("build 31 fine"). This session builds the phase task by task, inline, with one ledger,
deploys twice plus the portal and the website, ships build 32, runs the hand runs and the review, reads the round's documents
against V3, and writes the documents.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 and V2 are the
product (on TestFlight). V3 is the platform under them (`docs/spec-v3.md`, D70 to D118). Phase 22 is V3's last phase: the
owner controls the platform from the portal and reads its product figures; the DPDP retention rule comes into force. After it
come the external testing round, then Phase 16 (D81). Read, in this order, before doing anything:

1. `CLAUDE.md`, then `admin/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`, `ios/CLAUDE.md`,
   `docs/design/README.md`, `docs/working/pre-pr-proof.md`, `docs/working/testing.md`, `docs/runbooks/admin.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (D1 to D112; in particular D68 a phase fixes what it finds, D76,
   D78, D79, D82, D83, D84, D86, D87, D94 to D97, D100, D107, D109, D112).
3. `plan/phase-22-plan.md` whole: the global constraints (Phase 21's lessons are binding), the decisions D113 to D118 (in
   `plan/README.md`), the review focus, the file structure, the pull
   requests, the order, the fifteen tasks, the cost.
4. `plan/phase-22-admin-portal-control.md` (the scope and acceptance), "Phase 22 boards" and "Phase 22 parts" in
   `docs/design/information-architecture.md` and `docs/design/components.md`, the boards themselves (`docs/design/mockups/P22-*`,
   or canvas 2 at y 0).
5. `plan/sessions/044/record.md` and `ledger.md` (the reads of production, the boards, the rulings), `plan/sessions/043/ledger.md`
   (Phase 21's build: what was found and what went wrong), `plan/phase-21-plan.md` (the form this plan follows).
6. The code the plan changes, surveyed by hand before Task 1: `admin/` whole (`lib/data/`, `content/`, `app/`, `preview/`,
   `test/`), `supabase/migrations/2026112*` and `2026120*` (0046 to 0065; every migration that defines a function you replace),
   `api/src/alerts/`, `api/src/jobs/kinds/{alerts,sweep,exam-prep,eval-run}.ts`, `api/src/jobs/{sweep-db,exam-source,runner}.ts`,
   `api/src/push/`, `api/src/models.ts`, `api/src/models-db.ts`, `api/src/contract.ts`, `tools/admin-shots.ts`,
   `tools/contract.ts`, `web/content/trust.ts`, `ios/TutorCentralKit/Sources/Domain/School/`,
   `ios/TutorCentralKit/Sources/Features/School/ItemStore+Preparation.swift`.

**What is already true:**
- The kill switch exists (D100): a disabled `ai_models` draft row refuses with the kind's words; the API reads
  `ai_models_current()` once a minute. The portal only reads the table today.
- The allowance lives on `centres.ai_allowance` and `ai_allowance_paise`; members cannot update them.
- The alert lines are four constants in `api/src/alerts/lines.ts`; the alerts job runs each ten minutes.
- No automation spends on AI calls (D112). This phase asks for no real-call budget: `bun evals-changed` is expected to name
  nothing. If it names a kind, stop and ask the owner once, with a recommendation.
- `bun check` was green at the plan's close, with one flaky database test (`supabase/tests/jobs.test.ts`'s clock): Task 1.
- Session 44's reads (`plan/sessions/044/ledger.md`): one centre runs plans; the first batched morning cost ₹3.26; no exam
  job, no feedback row, no alert yet. The placement made each morning for a never-closed student is Phase 12's open ruling, not
  this phase's.
- The Supabase, Vercel and GitHub CLIs are signed in on the owner's Mac: production's steps are yours (D87): the Smoke centre's
  `internal` flag, the switch's proof, one `weekly_report` job by SQL.

**Your work:**
1. Check reality against `STATE.md` (`git fetch`, `git status`, `gh pr list`). `bun check` green. Open
   `plan/sessions/045/ledger.md`.
2. Execute `plan/phase-22-plan.md` task by task in its order: Task 1 (the flaky test), 2 (0066), 3 (the API's lines and the
   model refresh), 4 and 5 (the portal's controls; Deploy A and the portal), 6 (0067), 7 (the weekly report job), 8 (the
   figures, evals and syllabi pages, the Feedback row), 9 (0068: retention, the split, the push retry), 10 (the app's split by
   batch; Deploy B, the portal), 11 (the trust page; deploy-web), 12 (the hand runs; what they find fixed, D68), 13 (build 32,
   production's steps, the owner's five steps one at a time), 14 (the round's documents), 15 (the review on Fable 5.1 with
   every finding fixed or ruled, the rule files, the documents).
3. Every pull request: tests first (RED and GREEN in the ledger), `bun check`, `bun evals-changed`, the pictures
   (`bun admin-shots --pages …`, `bun web-shots --pages /trust`; `bun pr-shots` for the table), the pre-PR proof in the body;
   merge on local green (D86). Documents never ride in a code commit; push documents after a deploy has its check.
4. Close: "As built" in `plan/phase-22-admin-portal-control.md`, the rule files, `plan/README.md` (the phase's status),
   `plan/STATE.md`, `plan/sessions/045/record.md` and `owner-messages.md`, `plan/ui-polish.md`; one documents commit to `main`.
   Then the next resume: the external testing round (Phase 15's Tasks 20 to 23 by D52 to D55, on build 32 or its successor), on
   Fable 5.1 (D81).

**The owner's rules:**
- Be brief. No chatter. Show each finished part: what was built, what was decided, what needs approval.
- One question at a time, and only for decisions that are his, with a recommendation and its reasons. Decide the rest and
  say so, with its cost if wrong, in the ledger.
- Keep count of costs in the ledger. Don't trouble the owner with cost details.
- Any step the owner must take is a numbered list of exact actions: the site, each menu item by its label, what to copy,
  what a prompt asks, what success shows.
- Plain voice in documents; no technical words in anything a tutor reads (D41); the trade's words on the portal (D78).
- No secret in the repository (D11). A secret is piped straight to its store, never printed (D87).
- No tutor's name, email or number in the repository (D55).
- No automation spends on AI calls (D112).
- Decisions are never reopened; a change gets a new number.
- A phase fixes what it finds (D68). Polish goes on `plan/ui-polish.md`.
- Nothing on screen without its board (rule 1).
- Never a database test while local jobs run; read every migration that defines a function before replacing it; `git add`
  only the files a commit is for; file lists through `xargs`.
