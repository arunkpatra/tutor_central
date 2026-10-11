# Phase 13: School

**Status:** Done (2026-10-11): plan (session 27), build (session 28): migrations 0021 and 0022, PRs #123 to #126 and #128 to #134; the cost measured; 1.0.0 (24) on TestFlight. **Depends on:** Phase 12; boards 10.5, 10.4's mock and gap report, 10.2's Marks, 10.3's To parents, the Phase 13 boards.

## Goal

What a school sends reaches the plan: exams, portions, homework and notices become items, and exam preparation runs
from the school's own dates.

## Scope

1. **The share extension.** "Share to Tutor Central" from WhatsApp and Photos; text or image through the app group
   to the School tab; `/ai/parse-school`; items shown for confirmation (kind, student or class of a school, subject,
   date, portions); a photo kept in Storage under the centre.
2. **Items and the calendar.** Per student and per class of a school; the calendar by date; edit and delete; a
   holiday removes the batch's plan for the day.
3. **"Ask parents to forward."** The message, sent once, logged.
4. **Test tomorrow.** The parent message from an exam item, suggested the evening before; held by the cadence rule.
5. **Exam preparation.** The window (14 days default); the split of portions across days; a daily set; the mock in the
   school's pattern or the board's blueprint two days before; marking from a photo (`/ai/check-paper`); the gap report
   that adjusts the last days; class 10's two dates.
6. **Marks on the student's page** (`plan/ui-polish.md` U36, moved here by the owner, 2026-10-10): a Marks section in the
   record from school tests and checked papers; its board approved before it is built (rule 1).

## Acceptance

- Boards matched; pictures; the share path in the simulator runbook and hand-run.
- A forwarded timetable photo of two subjects produces two exam items with the right dates after confirmation.
- A school exam within the window changes the student's lines to revision on Today.
- U36 moves to Done on `plan/ui-polish.md` with the pull request that builds it.

## As built (session 28, 2026-10-11)

Built from `plan/phase-13-plan.md` in ten pull requests (#123 to #126 and #128 to #134; #127 cleared the compiler's
warnings), the D32 hand runs 1 to 15 against the local stack, the cost run on the real models, a fresh review on Fable 5.1
whose four Important findings were fixed in #134, two deploys (0021 with the API after #124; 0022 and the API after #134)
and TestFlight. The ledger with every ruling is `plan/sessions/028/ledger.md`.

**Items.** A school's message or photo reaches the School tab from WhatsApp or Photos through the share extension (the app
group's inbox, handed to the tab on open, signed in or after sign-in), from Paste a message, from a photo, or by hand.
`/ai/parse-school` (Haiku) reads it into items for "Check what was read": kind (exam, homework, holiday, notice), who (a
student, a class of a school, a whole school), subject, date, an end date for a holiday, portions; nothing is kept until
Add, and a draft missing a date or who it is for stays unticked. A photo is kept in Storage under the centre and goes with
the last item that uses it; the time an item came is the share's, not Add's. The tab lists items by week and draws a month
with a dot per kind; an item's page has Edit and Delete, Who with the record's reason, and what the school sent. A holiday
takes its students out of the day's plan; a batch wholly on holiday has no plan, and a plan made before the holiday is not
shown again. An item added, changed or deleted makes today's open plan of the batches it reaches again.

**Exam preparation.** The window is 14 days. The split of portions runs from the day the item came (or the window's first
day), not from today, so the mock day holds as the days pass: the batch's meeting days to the exam less the student's
holidays, the mock on the last meeting day two days or more before the exam when there are three days or more, the days
after it the gap report's, the rest revision with the portions spread in order. On Today, students of one exam form a group
of their own ("Group 1 · Science unit test 3 · … · the test in 9 days"), at most two such groups when others remain, with
revision lines ("Revise: Chemical reactions · part 1 of 3", Revision set, Check 3, Revision sheet) and Set · Sheet · Checks;
on the mock day the set is the mock, made once per exam on Sonnet in the school's pattern (class 10's board blueprint, else a
default by class), kept with the exam and shared by every batch's plan; on the test day the students are back in their level
group. The exam's page shows Preparation (a row per day from today: Today, a tick and what was made for a closed day, the
Mock, the gap report's day; Change opens Today at the plan) and from the mock day leads with the last days: the mock and
Mark from a photo, Marked (each student's score and weakest skill, Gap report, who waits for consent), The last two days.

**Marking and the gap report.** Mark from a photo opens Check a paper with the student and the mock's key set and the
scheme step skipped; the student's parent's consent is asked before any call (Opus); Save writes a mark (score, out of,
the questions, the exam and the mock) with V1's notes line, Undo takes both back, and Back returns to the exam's page,
which reads the new mark. A check against a paper made here writes a mark too. The gap report (Sonnet, the student's
consent) takes the app's tallies by skill (the twelve weakest sent), the model's sentence and a line per day left, and is
kept with the exam and the student; Use this plan marks it used and the days after the mock take its lines.

**Messages to parents.** Ask parents to forward: one editable message, one row per parent number, Send logs `forward_ask`
for each of their students and opens WhatsApp (a hand send, outside the cadence); when who was asked cannot be read, no
count is claimed. Test tomorrow: in English from the app's template; in Hindi, Hinglish or Kannada from `/ai/make` (Haiku,
the student's consent) with the English beside it; logged before WhatsApp opens. After the close, To parents lists Test
tomorrow for students present whose exam is tomorrow (three suggested messages a parent a week) and Absent today.

**The student page.** School (the student's items to come, See all) and Marks (U36): mocks and checked papers newest
first with the school and the day, Below usual when a mark is more than ten points under the mean of two or more earlier
ones in the subject, "No marks yet" otherwise; no add from a photo yet (Phase 14).

**A new batch's first checks** (the owner, 2026-10-11). A group `/ai/plan` names writes each member's chapter and skill,
so the first close records checks on their own skills; a group's checks are three questions (the day's skill fills the
places the spaced queue leaves); a group the make could not name is named at the next open and its material made.

**The cost measured** (the real models, session 28; the seed's Evening batch, Diya's mock marked from two photographed
pages):

| Kind | Model | Calls | Tokens in | Tokens out | ₹ |
|---|---|---|---|---|---|
| Marking (check_paper, the mock's key) | Opus 5.5 | 1 | 10,623 | 2,690 | 8.18 |
| Mock | Sonnet 5.5 | 1 | 1,166 | 4,399 | 3.94 |
| Gap report | Sonnet 5.5 | 1 | 1,307 | 250 | 0.43 |

One exam for a class of three (one mock, three markings, three reports): about ₹29.77; two exams a month about ₹59.5 a
class of three, the marking most of it. The plan's estimate was ₹8 for the three calls; it was ₹12.55.

**Where the build moved from the plan, and why.** The split starts when the item came, not today (decision 9 read daily
moves the mock day away). An existing mock is linked, not made again, and plan reads take artefacts their lines link from
another plan. Test tomorrow and Ask parents in the boards' words with no relation in the model ("Dev's parent"). The seed
gained a class test so Below usual shows by the rule. Fixes found by the hand runs (a photo two items share, the source
time, the calendar's frame, Back after saving marks, the page reading a new mark, the day picker opening on today, Ask
parents offline) and by the cost run (the gap report within the API's limits and the model within the output's) each came
with a test that failed first. The ledger has every ruling with its cost if wrong.

**Left open.** A per-exam window (a field on the item's sheet, a board first); the student page's See all opens the School
tab unfiltered; Paste a message raises iOS's paste prompt each time (PasteButton would not; a board first); the mock names a
skill per question, so By skill runs long; the review's five minors (in the ledger); the API answers a lost Supabase
connection as "sign in again" (V1's verifier rule); the real-device checks of the share from WhatsApp (T8).
