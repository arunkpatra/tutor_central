# Phase 22: V3 the admin portal, control and analytics

**Status:** Planned (session 44, 2026-10-15): the 41 boards of row 30 (canvas 2) and `phase-22-plan.md` approved by the owner; the build from `plan/resume/043-phase-22-build.md`. **Depends on:** Phases 19 and 21.

## Goal

The owner controls the platform from the portal and reads its product metrics; the DPDP retention rule is in force.

## Scope

1. **Controls** (D73, D76, D78): the model, effort and fallback per kind and step with their history; the allowance per centre
   (calls and paise); feature flags and kill switches per kind; the alert thresholds; a view of the syllabus data (edits by
   migration still).
2. **Support within consent** (D78): an audited open of a centre's records with a reason; a student's record and the outputs
   made about them; never a parent's number, a photo, or an input for a student without consent.
3. **Analytics** (D82): tutors active a week, closes, plans made and followed, notes sent, artefacts made and regenerated with
   reasons, Make's use, consent given, cost per active tutor; the owner's weekly report as a page and an email.
4. **Retention** (D79): a personal kind's input reduced to a reference after 90 days by the `sweep` job; the trust page's words
   changed in the same phase (`web/`, with its smoke).
5. **The round's documents** read once more against V3 (`docs/release.md`, `docs/testing/tester-guide.md`,
   `docs/testing/device-tests.md`): a push, a plan that arrives, and an export are new device tests.

## Acceptance

- A kind switched off in the portal refuses in the tutor's words within a minute, and switched on works again; the audit
  shows both.
- A centre's allowance changed in the portal is the limit the next call meets.
- The weekly report arrives by email with the week's figures; an admin open without a reason is refused.
- An input older than 90 days is a reference; the trust page says so; its smoke is green.
- Pictures of each page and state; the external testing round starts on this build or Phase 21's (D81).

## As built (session 45, 2026-10-15, Opus 5.5)

PRs #350 to #362; hand runs on issue #359; migrations 0066 (Deploy A, run 38694563888), 0067 and 0068 (Deploy B, run
38700765521); the portal by deploy-admin 38694571631 and 38700774225; the website by deploy-web 38700782694. The ledger is
`plan/sessions/045/ledger.md`.

- **Controls (D113).** `/models` and `/models/<kind>` (Current, Change a step, History; Switch off asks a reason and quotes the
  tutor's words, carried from `api/src/errors.ts` by `bun contract`); the centre's allowance dialog (calls 1 or more, the cap
  in rupees); the alert lines as a form; each write a named function with its audit row. The API reads the lines each run
  and keeps a kind's last good model row when a new one is unpriced. Proven: a switched-off brief refused in the tutor's
  words with nothing paid, made again 37 s after Switch on.
- **Figures and the weekly report (D114, D115).** `/figures` from `admin_figures` and `admin_reasons_week` (a typed reason
  counted, never shown); the `weekly_report` job Monday 08:00 IST and Send now, the board's words to `ALERT_EMAIL`. The
  Smoke centre is `internal` in production (left out of the figures, the active counts and the day's cost line).
- **Golden sets (D116).** `/evals` from `admin_eval_runs`; the run card queues an `eval_run` only on a person's press; a run
  started there names its day by the minute so its calls never replay another's.
- **Syllabus data.** `/syllabi`, one opened in place; read only.
- **Support within consent.** The call page's Feedback row (never the revised text; a typed reason reads "typed by the
  tutor") and the reduced line.
- **Retention (D117).** The sweep reduces a student's input to a reference after 90 days (`reduce_old_inputs`); `/trust`
  says so, and that staff never see what was sent about a student whose parent has not agreed (live 15 October).
- **The split per batch (D118, D119).** The exam job writes each batch's split to `preparations`. The app was found to work
  out its own split (the page per exam, the plans per batch), so it is unchanged: the round runs on build 31.
- **The push retry.** A push Apple refused for a while is due again a minute later, three times at most.
- **Deviations:** no app change and no build 32 (D119); the nav grew with its pages rather than at once; the hand runs read
  the API's answers by curl, not on the simulator (the app unchanged); the run card's kinds are links in the address.
- **Found and fixed (D68):** the hand runs' F1 (one call's plural) and F2 (the Golden sets page with no run done), #360; the
  review on Fable 5.1, thirteen findings, every one fixed (#361, #362), none ruled away.
- **Left for the owner:** U54 (the header's Sign out between 760 and 1100 px), U55 (the gate's third check has no column).
