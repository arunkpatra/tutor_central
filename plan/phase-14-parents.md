# Phase 14: Parents

**Status:** Done (session 30, 2026-10-11): built from `phase-14-plan.md` in #135 to #149; "As built" below. **Depends on:** Phase 12; Phase 13 for test tomorrow; boards 10.6, 10.3's note day and To parents, the P14 boards.

## Goal

The parent receives a weekly note about their student in their language, and the tutor sees who is not on track and
what to do next.

## Scope

1. **The note.** On the note day (default Sunday evening; changed where it appears), per student with consent, in the
   parent's language with English beside it, from the week's record; read, edit, send by the WhatsApp link; logged.
2. **Can-now-do** for LKG to 3 from the ladder; **homework** shared as a PDF.
3. **The cadence.** At most three suggested messages a week per parent; held suggestions shown as held; hand-sent
   messages not counted.
4. **Marks from a photo.** A report card or marked test to `/ai/check-paper`'s reader; the marks confirmed and saved.
5. **Not on track.** The next step on the student's page and on Today's line (re-teach, prerequisite, spaced queue,
   tell the parent), taken by the plan unless changed.
6. **Messages carry the tutor's name** and "Made with Tutor Central".
7. **The model for each kind of AI work in one place (D67).** One checked-in table of work type to model (with a class band
   where it matters; marking a handwritten paper and reading a printed report card as separate work types), overridable
   per work type by an environment variable at deploy (`AI_MODEL_<WORK_TYPE>`; an unknown model stops the API at start); `MARKING_MODEL` and the per-kind table in `api/src/models.ts` folded
   into it; the price sheet and the cost run read it; the model used stays logged per call.
8. **What Phase 13 left (D68).** U41 to U45 on `plan/ui-polish.md` (boards first where they change what is seen), the five
   `Final: minor (deferred)` lines of `plan/sessions/028/ledger.md`, and the API answering a lost database connection as
   "sign in again" (a 401 only when the token is refused; an outage answers as one).

## Acceptance

- Boards matched; pictures; hand run of a note in Kannada and Hinglish with English beside.
- A parent without consent gets no note and the tutor sees why on the student's page.
- The cadence holds a fourth suggestion and never a hand-sent reminder.
- A model changed for one work type by the table or its environment variable is the one the next call of that type uses
  and logs, with no code change.
- Phase 13's U41 to U45, five minors and the lost-connection answer are closed; nothing this phase finds is deferred (D68).

## As built (session 30, 2026-10-11)

Built from `plan/phase-14-plan.md` in fifteen pull requests: #135 (0023, 0024, the seed's consents), #136 (D67: the
model table, overrides, `bun cost`, the price sheet), #137 (the lost connection, the student's consent words, U45), #138
(the API's note, can-now-do, not-on-track and `/ai/read-marks`), #139 (Domain, with the signature), #140 (Data), #141 (the
note day on Today), #142 (the note and can-now-do), #143 (the sent log), #144 (not on track, 0025), #145 (marks from a
photo), #146 (School: U41 to U44, two review minors, and the hand runs' fixes), #147 (the cost run's two fixes), #148 and
#149 (every finding of the fresh review on Fable 5.1, D68). The ledger with each ruling, hand run and fix is
`plan/sessions/030/ledger.md`.

**The note.** On the note day (a batch's own, else Sunday 18:00; on from its time to the end of the next day) Today's
hero reads "N notes for parents" and the Notes card lists each student with a parent's number: Read, Sent, or Held with its
reason. Read opens the week's note, made once from the week's record (`/ai/make` note on Haiku, the parent's language with
the English beside, kept as an artefact with no plan, copied to the iPhone so it opens offline); a student on the ladder
(LKG to 3) gets Can now do with "Moved up". The note is edited (600 counted on the body, the signature outside it),
written again, copied (logged as copied; a copy never counts as a send) and sent on WhatsApp from the two-language sheet
(logged with its kind, language and the signed words). Taught means first taught that week. Offline the register's rows
show and a kept note opens; an unmade one, a send and Change day are refused in words.

**The cadence.** At most three suggested messages a week per parent across their students (the note, can-now-do, test
tomorrow, not on track); the fourth note is held with the held sheet (Send it now, Keep it for next week); a note waiting
for consent opens the student's page instead. A hand send never counts; a copy never counts. The sent log (See all on the
page's Messages) lists every message by month with "opened <day>", "copied <day>" or "not opened yet", and a Held section
with Send now.

**Not on track.** The tracking card shows the step the plan takes (`NextStep`, the plan's own stored as null) with Change
(What next, five steps); a changed status clears the tutor's step (0025's trigger, mirrored by the register), and a step
waits while a close that tracks the student is still queued. While the parent has not been told, a card offers Call and
Tell the parent (the two-language message: the English template with no call, or `/ai/make` not_on_track with consent);
Today's line carries "Since <day> · tell <parent> after the class" until it is sent.

**Marks from a photo.** Marks' Add from a photo (disabled with the reason until the parent agrees) reads one or two pages
on Sonnet (`/ai/read-marks`), the rows ticked, opened, dated; Save writes a mark per ticked row, no photo kept; Undo takes
them back (a failure said, the rest left for another Undo).

**The signature.** Each message the app writes ends with the tutor's name, the centre and "Made with Tutor Central"
(`MessageSignature`); the models never sign.

**D67 and D68.** `api/models.json` is the one model table (a class band for the sheet, marking apart from reading a
report card); `AI_MODEL_<WORK_TYPE>` overrides one at deploy and an unknown name stops the API at start; the app's price
sheet and `bun cost` read the same file. A lost connection is 503 "Couldn't reach the service" (as are a rate limit, a
timeout and a proxy's page), never "sign in again"; a missing student consent is 403 in the student's words; a body the
schema refuses is a 400 marked invalid and never shown. U41 to U45 and the five Phase 13 minors closed.

**The cost measured** (the real models, session 30; the seed's twelve Evening students):

| Kind | Model | Calls | Tokens in | Tokens out | ₹ |
|---|---|---|---|---|---|
| Weekly note | Haiku 5.5 | 8 | 5,944 | 8,995 | 0.43 |
| Can now do | Haiku 5.5 | 4 | 2,832 | 3,627 | 0.18 |
| Not on track | Haiku 5.5 | 1 | 753 | 1,458 | 0.07 |
| Marks from a photo | Sonnet 5.5 | 1 | 2,690 | 124 | 0.56 |
| Marks from a photo (compared) | Opus 5.5 | 1 | 2,690 | 217 | 1.28 |

A week of notes for twelve students ₹0.61, a month ₹2.44; a Kannada note's output is about three times an English
one's. Both models read the report card right; reading stays on Sonnet (decision 26).

**Where the build moved from the plan, and why.** Today's caption is computed from the log, not carried on the plan's
line (a send changes it without making the material again). A changed status clears the step by a trigger (0025), not a
second write. The photo travels with its route; the photo well is the board's, not Phase 13's source well. Change day writes
only the batches whose day is shown. The English beside a message may run to 1,000 characters (the cost run's Hindi note);
an unfit message is refused in its own words. The read-marks pull request was not needed (Sonnet read right). Fixes found
by the hand runs (Step back's words on a first skill, the consent hold, a copy counted, the paste footer, the note day
offline), the cost run (the English's limit, the refusal's words) and the review (eighteen findings) each came with a test
that failed first. Two review findings were ruled, not changed: the not-on-track message is not held by the cadence (the
tutor's deliberate send, counted), and a copy made offline is not logged.

**Left open.** Nothing of the phase's own. The polish rows U46 and U47 (Moved up's heading on an unchanged week; the
note's 20 s "Writing" while a kept note is looked for offline); the device tests T11 to T14 wait for the tester.
