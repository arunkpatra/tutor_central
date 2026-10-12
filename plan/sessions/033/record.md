# Session 33: V3, the interview (Fable 5.1, 2026-10-12)

From `plan/resume/031-v3-interview-and-spec.md`. The interview's record, question by question, is `docs/v3/interview.md`;
the owner's messages word for word are `owner-messages.md`.

## Setup

- Reality matched `STATE.md`: `main` clean at `17583e7`, no open pull request; the merged `phase-*` and `fix/*` branches
  still on the remote, the owner's to delete.
- Read in the order the resume prompt gives: the five `CLAUDE.md` files, `STATE.md`, `SESSIONS.md`, `README.md` (D1 to
  D69), `docs/spec.md`, `docs/spec-v2.md`; the platform skimmed by four agents with written briefs (the app's data layer
  and plan maker, the API and workflows, the database, the phases' lessons and the four review ledgers); their notes are
  summarised in `docs/v3/interview.md`'s "What the reading found".
- `bun check` run at the start (documents-only session; nothing built).

## Questions asked and what they settled

The full text, options and the owner's words are `docs/v3/interview.md`.

1. Q1, open: his own review. Settled V3's principle (the backend is the platform, the app a presentation layer), jobs with
   states, cost and activity tracked, limits managed, an admin portal, APNs decided by the backend, one environment, an
   agentic AI layer with proper mathematics.
2. Q2, a choice: offline. The app keeps a copy and the four-write queue (D39); nothing else.
3. Q3, a choice: order. V3 first, then the external testing round, then Phase 16.
4. Q4, open: the team. Him alone with Claude; he found the question needless.
5. Q5, open: budget. Paid plans fine, judicious.
6. Q6, a choice (dismissed once, asked again at his word): the admin portal signs in through the same Supabase Auth with TOTP;
   the service role on its server only; an audit. Between the two askings he ruled out Sentry and helpdesk tools: our own
   tables and the portal are the eyes.
7. Q7 was not asked: he wrote "don't ask me superfluous questions that you are capable of answering/deciding yourself". The
   runtime (a job table in Postgres, pg_cron, Hono workers on Vercel Pro) and the twelve remaining areas were decided in the
   interview file's "Decided without asking" and carried into the spec as D70 to D82 for his approval with it.

The research (`research.md`) was done by an agent with WebSearch before the technical questions: Vercel Workflows GA, Queues
beta, Functions 800 s on Pro; Supabase Queues alpha, Cron beta, Edge Functions 400 s; APNs token auth and libraries; Claude
caching and batch prices, Managed Agents beta, the Agent SDK's container need; Langfuse, Braintrust, promptfoo; SwiftMath,
Typst; the observability services' tiers.

## The spec and its approval

`docs/spec-v3.md` written after his "yes, write the spec", sent whole, approved with one change: the round is the external
testing round, not the tutor round. While reviewing he asked what product work is pending in V2; the answer given: Phase 16
(the subscription, the website's V2 words, the listing, submission); the external testing round (his test of build 26, the App
Store Connect steps, device tests T1 to T15 never run, invitations, readings); the items left for later (per-student export,
now Phase 18's; a per-exam preparation window field; a mock from a school's earlier paper; a paper or sheet for a student or
group in Make; his ruling on a school message that names a student; the syllabus data's soft spots); the open polish rows U5,
U8, U10, U13 to U15, U25, U27 to U30, U48; the deferred review minors of Phases 5 to 12; and what is out of scope by decision
(server-sent WhatsApp at a count, Android, iPad, multi-teacher, material in Kannada or Hindi, a student app).

## Written

- `docs/spec-v3.md`; `docs/v3/interview.md`; `plan/sessions/033/{record,owner-messages,research}.md`.
- `plan/README.md`: D70 to D82; Phases 17 to 22 in the phase table; the V3 row.
- `plan/phase-17-platform-foundation.md` to `plan/phase-22-admin-portal-control.md`.
- `plan/resume/032-phase-17-plan.md`, indexed.
- `plan/STATE.md`.

## What is next

Session 034: Phase 17's plan on Fable 5.1 from `plan/resume/032-phase-17-plan.md`. The owner's findings on build 26, if any,
go into `plan/phase-15-findings.md` (Who = Owner) with the phase that fixes each.
