# Resume 001: Phase 1, Foundation

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Opus 5.5 (decision D17).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything: `CLAUDE.md`, `plan/STATE.md`, `plan/SESSIONS.md`, `plan/phase-01-foundation.md`,
`plan/phase-01-plan.md`. The spec is `docs/spec.md`; decisions D1 to D20 are in `plan/README.md`.

**Your work:** execute `plan/phase-01-plan.md` natively, yourself, task by task, with the
`superpowers:executing-plans` skill. Nine tasks, four pull requests, tests first. It builds no screen; Phase 0's
design continues separately and nothing user-facing is built in this phase (D6).

**What is already true:** the repo holds documents only. Xcode 27.0 with Swift 6.4 and the iOS 26.4 simulator
runtime are installed; bun 1.3.11, node 22, vercel CLI, gh (logged in as arunkpatra) and Homebrew exist.
xcodegen, swiftformat, swiftlint, xcbeautify and the Supabase CLI are not installed yet: Task 1 installs them.
Docker may not be installed; if `supabase start` cannot find it, stop and ask the owner to install Docker
Desktop or OrbStack (owner step).

**How to work:** one branch per pull request as the plan names them; `bun check` before every commit once it
exists; a pull request is opened with `gh` and merged when the check is green (CI from Task 7 on). Documents
only (`plan/`, `docs/`, `CLAUDE.md` files, `README.md`) go to `main` directly, never mixed with code. Decide
small and medium things yourself and write them down; ask the owner only for decisions that are his, one at a
time. Give him his steps (Supabase project at Task 4, Vercel project at Task 6, Docker if missing) one at a time
and check each result before the next.

**When a plan step does not match reality** (a runner label, a Vercel preset, an XcodeGen key), fix it, record
the deviation in `plan/phase-01-foundation.md` under "As built", and add a numbered decision in
`plan/README.md` if it changes a rule.

**End of the session:** Task 9 updates the rules files, the commands table, "As built", `plan/README.md` and
`plan/STATE.md`; write `plan/sessions/002/record.md` and `owner-messages.md`; commit to `main`; then ask for a
reviewer pass on the four merged pull requests with the `superpowers:requesting-code-review` skill.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
