# Session 45: Phase 22, the build (Opus 5.5, 2026-10-15 and 16)

From `plan/resume/043-phase-22-build.md`. The owner's messages word for word are `owner-messages.md`; each task, RED and GREEN,
ruling, deploy run and cost is `ledger.md`.

## What was done

- Phase 22 built task by task from `plan/phase-22-plan.md`: PRs #350 to #362. Migrations 0066 (the alert lines, the controls'
  writers, the models' reads, `centres.internal`), 0067 (the figures, the eval runs and the run a person starts, the syllabi,
  the `weekly_report` job), 0068 (retention after 90 days, the split per batch, a refused push tried again). The API reads the
  lines each run and keeps a kind's last priced model row; the weekly report job; the sweep reduces old inputs; the push retry.
  The portal's eleven pages: Models and a kind's page with Switch off, the allowance dialog, the lines form, Figures with Send
  now, Golden sets with the run card, Syllabi, the call's Feedback row. The trust page's retention words.
- Deploy A (0066, the API at `cea9afb0`) and Deploy B (0067, 0068, the API at `ff534ffd`); deploy-admin twice; deploy-web once.
  Production's steps by the session (D87): the Smoke centre `internal`; one `weekly_report` job by SQL, delivered.
- The hand runs (#359): eleven runs on the local stack; F1 and F2 fixed (#360).
- The review on Fable 5.1, two reviewers (database and API; portal and web): thirteen findings, every one fixed (#361, #362).
- The owner's steps in production: the Models page, the brief switched off and refused on his iPhone, switched on and made
  with both audit rows, Send now's email. All four passed.
- His step 3 found the brief's worked example drawn as LaTeX on build 31. `RowTitles` drew every row title as plain text; a
  read-only sweep found eight more rows drawing AI text without `MathText`. All fixed in #363 (tests first; a `brief-maths`
  launch state for the pictures), merged on local green.
- The owner chose no TestFlight build until the brand mark is in (D121) and added the approved brand kit
  (`../tutor_central_logo` v1.1.0). `plan/phase-23-brand-mark.md` written from the kit's integration runbook; D120 and D121
  in `plan/README.md`; resume 044 for Phase 23.

## Decisions by the owner

- The four production steps passed ("models fine", "off fine", "on fine", "report fine").
- The brand mark is the kit's v1.1.0 (his approval of the logo, written as D120).
- No TestFlight build until the logo changes (D121).

## What was decided here (each in the ledger with its cost if wrong)

- D119 (the app keeps its own split; no app change in Phase 22).
- The rulings of each task (the ledger), and of #363: no new board (P10-Brief's row, P20-Kit-Maths' rule); the triangle's
  Canvas labels and the name-like texts left as text.
- Phase 23 in one session on Opus: its board and a short plan approved, then the build (the kit's runbook is most of the
  plan).

## Costs

No AI call on the real models: every run on the fake; `bun evals-changed` named no kind at any pull request. The owner's
step 3 made one brief in production (his own centre's allowance).

## Observations, not tasks

- The deploy gate refuses while `main`'s check is still running; the owner saw it as "Jobs failed". A deploy is started only
  after the check of its commit is green.
- `bunx biome check --write` in `api/` (which has no Biome config) reformats the whole package: never run it there (now in
  `api/CLAUDE.md`).
