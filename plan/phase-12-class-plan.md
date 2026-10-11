# Phase 12: The plan

**Status:** Done (session 26, 2026-10-11): migrations 0019 and 0020, PRs #110 to #119, hand runs #120. **Depends on:**
Phase 11; boards 10.3 and 10.4.

## Goal

Today shows a plan per batch with the material made, and the close follows from it.

## Scope

1. **The plan.** `/ai/plan` from the record: groups by level across classes, the subject per student (nearest school
   item, else least recently taught, else the batch's weekly pattern), four lines per student, catch-up lines; the
   tutor moves a student, drops the groups, skips a line; a plan with no record (new students) still makes one from
   class levels.
2. **The material.** `/ai/make` per group: the set, the sheet (PDF, board view, key), the checks; the worked example;
   figures from their specs (number line, fraction bar, place value, unit circle, triangle, labelled cell, food chain);
   the brief when the chapter is above class 7 or the tutor has asked about it; regenerate with a reason; "Own"
   (the tutor's photo) in a line.
3. **When it is made.** On open, with "Planning today's class"; in a background refresh when iOS grants one; the local
   reminder at the tutor's time (default an hour before the batch). The artefact budget per session (a Domain rule).
4. **The close from the plan.** The lines as the checklist; checks from the plan; homework from the plan; offline.
5. **Cost measured.** Tokens per kind per group from `ai_generations`, reported in the session record for D64.
6. **Polish taken with the phase** (`plan/ui-polish.md`, the owner, 2026-10-10): U35, the student page's This week
   "Today" link, opening Today at the student's batch and plan; U37, the close card's no-book and offline sentences,
   designed with the close's checklist; U38, the close card's wait for checks, which ends when the plan makes the checks
   ahead (close the row if no wait remains, else design it); U39, a symbol of its own for a waiting close in Pending
   changes. U37 and U39 need their boards approved before they are built (rule 1).

## Acceptance

- Boards matched; pictures; hand run of the close from a plan and of a regenerate.
- The cost of a twelve-student batch across three groups is measured and written down.
- A student without consent gets group material and checks (no personal data), and no personal artefact.
- U35, U37, U38 and U39 move to Done on `plan/ui-polish.md` with the pull requests that close them.

## As built (session 26, 2026-10-11)

Built from `plan/phase-12-plan.md` in nine pull requests (#110 to #119, with #111 to #114 for the database, the API, Domain
and Data), the D32 hand runs on issue #120, a fresh review on Fable 5.1 whose Critical and Important findings were fixed in
#119, and two deploys (0019, then 0020 and the API). The ledger with every ruling is `plan/sessions/026/ledger.md`.

**The plan.** Made on the phone by Domain's `PlanRules` from the record, as the user (D60): the batch's students sorted by
class level (one lower for a student not on track) and cut at the largest gaps into at most three groups, the largest first;
a student with no class takes the batch's most common level. Each group gets a subject and a skill to teach from its
members' books; `/ai/plan` is called only to name a first chapter and skill for a group whose members have no record. Each
student gets teach, practise, check and homework lines, a catch-up line after two absences running, and the group a worked
example line, a figure line when the skill names a template, and a brief line above class 7. `make_plan` writes the plan
and its lines in one call; `keep_artefact` keeps each piece of material and links it to the lines it serves. The tutor
changes the plan where it shows: move a student (their set, checks and sheet follow the new group's), skip a check or
homework, leave a student out, change the group count and subjects, keep a weekday's pattern (the subjects the sheet shows),
make it again. A plan whose batch has closed does not change.

**The material.** `ArtefactBudget` asks for it in order (the checks, the placement, the sets and sheets, the worked
examples, the figures, the brief), at most four personal checks and twenty calls a plan; a student without consent gets
the group's material and nothing personal. The new `Artefacts` feature shows the sheet as Paper, Board and Key with Share
as PDF and Print, Make it again with a reason (the old sheet stays in the record), Use my own (a photo or typed words in
the made sheet's place, the made one brought back with one tap); the worked example a step at a time; the brief with Copy,
Share as PDF and Make it again; the seven figures, drawn by the app from their checked specs, with Show large, Share and
Print. Offline the material opens from the plan's copy on this iPhone.

**When it is made.** On open, with "Planning today's class" and the cards filling as the material lands; a second open
while a run is going leaves that run alone; in a background refresh when iOS grants one; the reminder an hour before the
batch ("In 1 hour · N students. Open for today's plan."). Today shows the plan's copy at once offline.

**The close from the plan.** The lines are a checklist per group; the checks come from the plan with no call and record
on each student's own skill (by id, else by name); a row a student cannot keep (no book) is not offered; the homework sheet
given is written with the homework; a homework skipped today or a student left out closes with none given; the ticked lines
of students who came are written as done. Offline the close reads the plan's copy and a copy of each student's book kept
when the plan or the last close read it, and waits in the queue with its lines.

**The cost measured** (run 8, the twelve-student Evening batch of the seed in three groups, the real API; D64):

| Kind | Model | Calls | Tokens in | Tokens out | ₹ |
|---|---|---|---|---|---|
| Sheet | Sonnet 5.5 | 2 | 1,421 | 1,624 | 1.62 |
| Worked example | Sonnet 5.5 | 3 | 2,268 | 1,199 | 1.40 |
| Brief | Sonnet 5.5 | 1 | 1,205 | 1,231 | 1.25 |
| Sheet | Haiku 5.5 | 4 | 2,836 | 3,629 | 0.18 |
| Checks | Haiku 5.5 | 3 | 2,287 | 2,239 | 0.11 |
| **The batch** | | **13** | **10,017** | **9,922** | **4.57** |

About ₹91 a month at twenty sessions for that batch. No figure or placement was asked (the seed's skills match no figure
template and its students are placed); the price sheet's test figures now use these averages.

**Where the build moved from the plan, and why** (each a ruling in the ledger):

- The figures are drawn in the Artefacts feature, not DesignSystem: DesignSystem does not import Domain's `FigureSpec`.
- A triangle's labels name the sides opposite its angles (the API's prompt says so; the samples follow).
- The brief keeps the board's Make it again; the figure screen follows its boards (the template's name, the model's
  caption, the app's check as the figure's VoiceOver label).
- `today-evening` stays a launch state for the Store-1 board until Phase 16 redoes the store boards.
- A student left out or whose check is skipped today has no check section on the close card (`CloseChecks.skipped`).
- A copy of each student's book is kept on this iPhone (the hand runs found the offline close dropping every check).
- The hand runs and the review found eleven faults, each fixed with a test that failed first: a line's order after a
  reload, replacing your own sheet, a moved student's material, a kept pattern's subjects, an absent student's lines,
  Today's plan offline, the offline close's checks, a second run on reopen, a skipped homework, checks a student cannot
  keep, a closed plan's changes; and the material offline.

**Left open:** a group `/ai/plan` fails to name at the make stays without material that day (Make the plan again names it);
a new batch with no record has no checks at its first close (writing the named topic as each member's chapter and skill
is the owner's call for Phase 13); the review's ten minors (the ledger's `Final: minor (deferred)` lines); a student link
while another student's page is open shows the first student (a separate task).

