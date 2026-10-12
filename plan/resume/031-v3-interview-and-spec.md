# Resume 031: V3, the interview and the spec

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude Fable 5.1
(D17: planning and scoping on Fable). V3 is the platform under the product: AI excellence, engineering robustness, the work
best done on the server, process, observability, and an admin web app for internal users. It gets its own spec,
`docs/spec-v3.md`, written only after an interview of the owner. This session runs the interview, one question at a time, and
writes the spec when the owner says there is enough. It writes no code. Paste this prompt again for each session until the
spec is approved.

---

You are continuing Tutor Central, a native iPhone app for tutors who run a small tuition centre in India. V1 (Phases 1 to 8)
and V2 (Phases 10 to 15) were the product: the use cases, the screens and what a tutor does. Phase 15 is built and on
TestFlight as 1.0.0 (26). The tutor round (Phase 15's Tasks 20 to 23) waits by D69: the owner tests build 26 on his own iPhone
and reviews the engineering decisions himself first. V3 comes next and is about what is under the hood. Read, in this order,
before you ask anything:

1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`, `web/CLAUDE.md`. Each rule there was learned the
   hard way; V3 may change a rule, but only by a numbered decision.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md`, all of decisions D1 to D69. Note the ones V3 is most likely to
   revisit, and say so when a question touches one: D11 (no secret in the app), D14 (dependencies pinned), D16 (Bun only),
   D17, D18 (no third-party analytics; crash reporting undecided), D21 to D26 (deploys, CI, migrations), D35 to D37, D39 and
   D40 (offline), D45, D60, D62 (consent), D64 (money last), D67 (the model table), D68.
3. `docs/spec.md` and `docs/spec-v2.md` in full: what the product promises, so V3 serves it and changes nothing a tutor sees
   without a board (rule 1).
4. The platform as built. Skim it and take notes; do not review it line by line.
   - The app: `ios/TutorCentralKit/Sources` (modules, the stores, `Data/` and its repositories, `CachedRead`, `ChangeQueue`,
     `QueueRunner`, the plan maker that calls `/ai/make` from the phone).
   - The API: `api/src` (routes, `common.ts`'s `run`, prompts, `schemas.ts`, `models.ts` and `models.json`, `claude.ts`,
     the fake).
   - The database: `supabase/migrations` (0001 to 0027, RLS, `start_ai_generation`, `keep_artefact`, the limits),
     `supabase/tests`.
   - The website: `web/`.
   - The workflows: `.github/workflows` (check, deploy, deploy-web, testflight) and `tools/` (check, shots, cost).
5. What the phases learned: the "As built" sections of `plan/phase-11-*` to `plan/phase-15-*`, and the review ledgers
   `plan/sessions/026/`, `028/`, `030/` and `032/` (the cost runs, the reviews' findings, the faults the hand runs found: each
   points at a weakness V3 may remove). `plan/ui-polish.md`'s open rows are not V3's.

**What is already true:**
- Production holds migrations 0001 to 0027, the API at `54adb24` on Vercel (Hono, Bun, `bom1`), and Supabase in Mumbai.
- The website is tutorcentral.in, with `/trust`.
- AI calls go from the phone through the API to Claude. The model per work type is in `api/models.json` (D67); every call is
  recorded in `ai_generations`, with tokens and cost read by `bun cost`.
- Much of the work runs on the phone: the plan is made there, call by call; the offline queue, the reminders and the PDFs
  are the phone's.
- There is no staging environment, no admin surface, no crash reporting and no metrics beyond the database's tables.
- The owner approved real AI calls in testing without asking each time; this session needs none.

**Your work, in order:**

1. The session's setup as `plan/SESSIONS.md` says. This is session 033 (then 034 and on). Open `plan/sessions/033/record.md`
   and keep `docs/v3/interview.md`. That file is the interview's record: each question, the options and your recommendation,
   the owner's answer word for word, and what it settles. It is written as you go, so nothing depends on memory.
2. **The interview.** Use `superpowers:brainstorming`.
   - Ask one question at a time, and wait for the answer.
   - Choose each next question from the last answer: follow a thread until it is settled, then move to the next area.
   - When the answer is a choice, use AskUserQuestion with two to four options. Put your recommendation first, marked
     "(Recommended)", with its reasons: what the state of the art does, what it costs, and what it means for a one-person
     team on Supabase and Vercel. Never offer a bare menu.
   - When the question is open, ask it plainly.
   - Research before recommending where the field moves fast (AI evaluation, model routing, prompt management, agent
     tooling, observability): use WebSearch and say what you found and from where.
   - Push back, with a concrete reason, when an answer would hurt the product or the platform (`docs/working/pushback.md`).
   - The areas to cover. They are a map, not a script: take them in the order the owner's answers lead, skip what he rules
     out, and add what he raises.
     a. **Why V3, and its bounds.** What "state of the art" means here, and what success looks like in six months. What V3
        must not change for a tutor. Where V3 sits against Phase 16 (Release, D64) and the paused round (D69). The team:
        the owner alone, or with others.
     b. **The owner's own review.** He is analysing the engineering and technical decisions himself. Ask what he found
        before proposing anything: his findings come first and shape the rest.
     c. **AI excellence.**
        - Quality: evals with golden sets per work type, graders, regression gates in CI, and the cost runs as a standing
          practice.
        - Prompts as versioned artefacts: who edits them, from where, and with what review.
        - Model routing and fallbacks; prompt caching and batching; structured outputs and their failures.
        - Latency and streaming; guardrails (the facts-only rule, consent); the tutor's edits as feedback; the cost per
          centre and its controls.
        - Agents, or durable workflows, for multi-step work such as the plan and exam preparation.
     d. **Server-side delegation.**
        - Which work leaves the phone: plan making, the note day's notes, reminders and push notifications, PDFs,
          scheduled jobs.
        - Durable jobs: queues, retries, idempotency.
        - What the phone keeps: offline, the queue, the copies.
        - The choice of runtime (Vercel Functions or Queues, Supabase Edge Functions, cron, others), weighed against what
          is in production today.
     e. **Robustness.**
        - Error handling end to end; idempotent writes.
        - The offline model and conflict handling; data integrity.
        - Migrations and rollbacks; backups and restore drills.
        - Security: auth, row-level security, secrets, abuse and rate limits; India's DPDP Act and the consent records.
        - Load assumptions and limits.
     f. **Engineering process.**
        - Environments (staging, preview), feature flags, CI's speed and flakiness, release trains.
        - Test strategy: unit, contract tests between the app and the API, end-to-end, the hand runs.
        - Code review with models; dependency upkeep; the decision log; the house rules for sessions.
     g. **Observability.**
        - Structured logs, traces across the app, the API and the database; metrics and SLOs.
        - Alerting and who receives it; crash reporting (D18).
        - The AI calls' traces: the prompt, the model, tokens, latency, outcome.
        - Privacy: what may be logged about a student.
     h. **The admin web app** for internal users.
        - Who uses it and how they sign in (roles, two-factor authentication, an audit log).
        - What it shows: centres, usage, the AI calls and their cost, errors, the jobs.
        - What it controls: the model table, prompts, limits and allowances, feature flags, kill switches, the syllabus
          data.
        - Support tools within consent and privacy (D55, D62): what an admin may see of a centre's records, and never see.
        - Where it lives and its stack (next to `web/` on Vercel, or elsewhere). Its own design boards (rule 1 applies to
          it too).
     i. **Data and analytics.**
        - Product metrics without third-party trackers (D18): what is measured, and where it is kept.
        - Reporting for the owner.
     j. **Cost and money.** The platform's monthly budget; AI spend per centre against D64's price; the alarms.
     k. **Phasing.** How V3 is cut into phases with something to show at each end; what comes first; what is left out.
3. **When there is enough.** Say so, list what is settled and what is still open, and ask the owner whether to write the
   spec. Do not write it before he agrees.
4. **The spec.** Write `docs/spec-v3.md` in the house's plain voice (`plan/SESSIONS.md`; the voice of `docs/spec-v2.md`).
   - It gives the goals and the bounds, then a section per area: what is required, what is chosen and why (each choice
     traceable to `docs/v3/interview.md`), and what is left out.
   - It names the decisions it needs: new numbers from D70, each superseding an older one where it does.
   - It ends with the phases V3 is cut into: their order, what each shows, and their dependencies.
   - Show it whole and wait for the owner's approval. A change he asks for is made and shown again.
5. **When the spec is approved:**
   - Record the decisions in `plan/README.md`.
   - Add V3's phases to the phase table, with one scope file each (`plan/phase-NN-*.md`, the shape of the V2 ones).
   - Update `STATE.md`.
   - Write the resume prompt for the first V3 phase's plan (Fable 5.1) and index it in `plan/resume/README.md`.
   - Commit the documents to `main` (D12).
6. If the owner brings findings from his own test of build 26, record each as a row of `plan/phase-15-findings.md` (Who =
   Owner) and say which phase will fix it. Fixing is a build session's work, not this one's.
7. `plan/STATE.md` before you stop, every session; `plan/sessions/033/record.md` (and each later session's own) with the
   questions asked and what they settled.

**The owner's rules:**
- Be brief. Ask one question at a time, with a recommendation and its reasons.
- Decide small things yourself and say what you decided.
- Check each answer against the spec, the decisions and the code, and push back when it is wrong.
- Use plain voice in documents.
- No technical words in anything a tutor reads (D41). The admin app is for internal users and may use the trade's words.
- Nothing a tutor sees changes without a board (rule 1).
- No secret in the repository (D11), and no tutor's name, email or number in it (D55).
- Decisions are never reopened; a change gets a new number.
