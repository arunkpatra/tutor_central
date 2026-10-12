# Session 36: Phase 18's boards and plan (Fable 5.1, 2026-10-12)

From `plan/resume/034-phase-18-boards-and-plan.md`. The owner's messages word for word are `owner-messages.md`; each ruling
with its cost if wrong is `ledger.md`.

## Setup

- Reality matched `STATE.md`: `main` clean at `c92393d`, no open pull request; `bun check` green (cached). Documents only;
  nothing built.
- Read in the resume's order. Three readers surveyed the code: the API's jobs and migrations 0028 to 0035; the phone's
  platform work (the plan maker, the note day, reminders, the background refresh, PDFs, every AI call by when it starts);
  the student's page, consent, the polish rows and the canvas's grammar.

## The boards (row 26, y 56600)

Drawn by a script in the scratchpad from the existing boards' parts (inline styles, the Ember tokens, light twins by the token
block), each rendered with headless Chrome and looked at before publishing. Fourteen boards in three sets:

1. **Consent withdrawn** (approved): Change on an agreed consent with Parent withdrew in place of Remove; the Parent withdrew
   sheet (how, the day, "From now, at once"); the page after a withdrawal (consent back under the parent, its history, Ask
   on WhatsApp and Parent agreed), dark and light.
2. **The export** (approved, with every later board pre-approved): the Export section at the page's foot (the ask, being
   made, ready to share dark and light, not made) and page 1 of the PDF.
3. **Plan ready** (pre-approved): the notifications (plan ready per batch, the note day's notes ready), Today while the
   material is still being made (dark and light), and the Reminders screen without "On this iPhone".

Mirrored into `docs/design/` with "Phase 18 boards" (`information-architecture.md`) and "Phase 18 parts" (`components.md`);
committed as `d6c8b66`.

## Found while reading

- The phone has no note-day reminder, and the reminder settings live only in the iPhone's defaults; the Reminders screen's
  "On this iPhone · Refresh · set two weeks ahead" stops being true with push. Set 3 redrew the screen; the settings move to
  the account (plan decision 6).
- The record sheet's Remove already writes a `withdrawn` event through 0032's trigger, without how or the day; nothing reads
  `consent_events` yet.
- `SpacedQueue` was never ported in Phase 17 (its plan named `spaced.ts`; no such file); Phase 18 ports it with the budget.
- The message log keeps a message's day and kind, not its words: the export lists messages by day and kind and gives the
  words of what the AI service wrote.
- `recordedCall` passes no student, so a personal kind made by a job would be refused: Task 8 adds it.

## The plan

`plan/phase-18-plan.md` with `superpowers:writing-plans`, in Phase 17's form: 25 tasks, 22 pull requests, 28 decisions, eight
review-focus lines with their tests, the file structure, the order, the cost and the self-review. Its shape: five migrations
(the withdrawal, three member requests limited to their kind, the notifications outbox and settings, the schedules by
pg_cron with change triggers, the buckets and Storage's deletions); three case files written from Domain's rules before they
are retired; the budget, the reminder rules and the note week ported and held equal; APNs with an outbox the minute tick
sends; the `plan` job's material, exam weeks and holidays; the note day; Typst for the sheets', mocks', briefs' and the
export's PDFs; the sweep's Storage; then the app to its boards and one data layer.

## Decided, and why

- **D88, `@parse/node-apn` 8.1.0:** the spec's choice, maintained, carries the HTTP/2 connection and Apple's answers; our own
  client over `http2` was weighed.
- **D89, Typst now:** the export must shape Hindi and Kannada; D75 already chose Typst for the server; Phase 20 adds the
  maths to the same compiler.
- **D90, what the server's PDF covers:** sheets, mocks and briefs; figures wait for Phase 20, V1's results for Phase 21; an
  offline Share without the file draws on the phone as today, so no tutor loses what they have.
- **D91, automatic work only for a centre in use:** the server would otherwise pay each morning for a tutor who stopped.
- **D92, the export a PDF kept seven days.**
- Smaller rulings are the plan's decisions 6 to 28 (the settings on the account, the outbox, the run times, the requests,
  the material's steps and keys, exam weeks on the server, what stays a call from the phone, withdrawal, push in the app,
  PlanStore's reads, `CopyFirst`, the buckets, the ports' cases, the retirements, the deploys, the smoke's new checks, the
  retention, the trust page).

## No question for the owner

Every choice was small, medium or settled by a decision; the plan states each. The owner's one step is Task 1 (the APNs
key and the App ID's push), asked by the build session.

## What is next

Session 37: Phase 18's build on Opus 5.5 from `plan/resume/035-phase-18-build.md`, after the owner's review of the plan.
