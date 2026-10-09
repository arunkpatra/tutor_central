# Phase 9 plan: user testing

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to run this plan task-by-task (one
> session per reading or per fix; the tasks are small and the owner is in the loop at every step, so a fresh subagent
> per task buys nothing). Steps use checkbox (`- [ ]`) syntax for tracking.

Written 2026-10-09 (session 18, Fable 5.1) from `phase-09-user-testing.md` and the owner's two answers. Ticked as it goes.

**Goal:** six tutors run their centres on Tutor Central for three weeks on their own iPhones through TestFlight's external
group; everything they and the tester find is logged, triaged and fixed or placed; the release checklist is complete for
the final build; the owner submits that build to App Review.

**Architecture:** no new software. The phase runs on what exists: TestFlight's external group "Tutors" with named email
invitations, Beta App Review on the first build, TestFlight's screenshot feedback and crash reports (D18: no crash service),
the Help email, and the owner's WhatsApp. Findings land in one file under `plan/`, read twice a week; each becomes a bug
fixed in its own pull request (a test first, a board first when what is seen changes, pictures by D7, the hand run by D32),
a polish row, a later-phase item, or no change with its reason. A build goes to the group on Thursdays when fixes have
merged, with release notes in `docs/release.md` that are also the build's "What to Test".

**Tech stack:** App Store Connect and TestFlight (Apple's), `gh workflow run testflight` (D24) and `deploy` (D21, D26),
`bun shots`, `bun pr-shots`, the simulator runbook; Swift 6 / SwiftUI and the API for fixes.

**Spec:** `plan/phase-09-user-testing.md` (scope 1 to 6, the acceptance); `docs/release.md` (the checklist);
`docs/testing/device-tests.md` (the tester's tests, D1 to D8); `docs/store/listing.md` (the words Apple has);
`docs/design/feedback.md` (how the app speaks, for triage); `plan/ui-polish.md` ("How it works", for polish rows).

## Global constraints

- No code is written in this phase except a fix for a finding, each in its own pull request; `bun check` green before
  every commit; code reaches `main` only through a pull request with a green check.
- A fix that changes what is seen has a board first, approved by the owner on the canvas and mirrored in `docs/design/`
  (rule 1); pictures of every changed state, both appearances, in the pull request by `bun shots` and `bun pr-shots`
  (D7); a fix that touches a write is hand-run by `docs/runbooks/simulator.md` before the build that carries it (D32).
- A fix has a test that fails first where there is logic (Domain, Data, API, RLS); a crash fix has a test that reproduces
  the thread or the state (as #84 did).
- No technical words in anything a tutor or Apple reads (D41): the tester's guide, the release notes, "What to Test",
  the Beta App Description, any new string in the app. The banned list is `ErrorWordsTests.banned` in
  `ios/TutorCentralKit/Tests/DomainTests/ErrorWordsTests.swift`.
- Words Apple reads are held to App Review Guidelines 2.3 (accurate, nothing the app does not do, no other company's
  name as a keyword, Apple's names as Apple writes them) and 5.1.2(i) (the AI service named and what is sent to it said
  plainly): the Beta App Description, "What to Test", the Beta App Review notes.
- Claude creates no account and handles no password on a live system: every App Store Connect step is the owner's, given
  one at a time and checked before the next; the review account's password is typed by the owner only.
- No tutor's name, email or phone number in the repository: testers are T1 to T6 in the findings file; the owner keeps
  the mapping. A tester's picture that shows a parent's phone number is covered before it is committed.
- Documents only go to `main` directly (D12), never mixed with code: the findings file, the guide, the release notes, the
  state are documents commits.
- Deploys and builds run only from the workflows started by hand (D21, D24, D26); the API's `/health` must report `main`'s
  head before every TestFlight build (a fix in `api/` is deployed first).
- Nothing a tester asks for is silently dropped (rule 10): a feature the app lacks is written under "Later" in the phase
  file's As built, with how many asked.

## Decisions this plan takes

Numbered in `plan/README.md` in the documents commit that records the plan's approval; a change gets a new number.

| # | Decision |
|---|---|
| D52 | **Who tests, and for how long.** Six tutors the owner knows, three calendar weeks from the day the first tutor is invited: two centres of 30 or more students, two of under 10, two in between; across the six at least one each of Sign in with Apple, Google and the email code; at least one iPhone 11 or 12 (the oldest that runs iOS 26); at least one mostly on mobile data. Three weeks cover one month-end, so Fees rolls a month under real use. The tester's device checks (`docs/testing/device-tests.md` D1 to D8) run on the Beta App Review build before any tutor is invited; a Fail is fixed and a new build goes to review first, so no tutor meets a known crash. The owner's choices, 2026-10-09. |
| D53 | **The external group.** One group, "Tutors", with named email invitations; the public link stays off (six chosen people, and the link's "anyone with it" is not that). The tester is invited first, and D7 (installing from the group's email) is their first check. Each build's "What to Test" is its release notes from `docs/release.md`, word for word, held to App Review Guidelines 2.3. A build goes to the group on a Thursday when at least one fix has merged since the last build, at most one a week, except a crash or a lost write, which ships the day its fix merges. Before every build: `main` green, no migration pending (the TestFlight lane refuses one), the API's `/health` at `main`'s head, the D32 hand run of every write the build's fixes touch. |
| D54 | **The tester's guide** is `docs/testing/tester-guide.md`, plain words (D41, checked against `ErrorWordsTests.banned` by hand), sent by the owner to each tutor on WhatsApp the day the invitation goes out, as the message it is written to be; its short form is the first build's "What to Test". Not a page on the site: the site is what Apple reads, a page for six people would need a board, a pull request and a deploy, and a tutor reads WhatsApp before a web page. |
| D55 | **Findings and triage.** `plan/phase-09-findings.md` holds one row per thing seen (F1, F2, …): the date, the build, who (T1 to T6, the tester, the owner), how it came (TestFlight screenshot, TestFlight crash, email, WhatsApp, in person), the screen, the tester's words verbatim, the picture (`plan/phase-09-findings/F<n>.png`), the triage, where it went, the status. A second report of the same thing joins the first row's "who"; a thing already on `plan/ui-polish.md` points at its U row. Readings on Monday and Thursday: the owner downloads TestFlight's feedback (screenshots and crashes) and hands over what reached him on WhatsApp, email or in person; a crash is read the day it is seen. Triage is one of **Bug** (the app does other than its board, the spec or Apple's way says, crashes, or loses what the tutor typed or marked: its own pull request by the global constraints), **Polish** (it works but could look or read better: a row on `plan/ui-polish.md`, the owner's to take), **Later** (a feature the app does not have: the phase file's "Later" list), **No change** (with the reason: the approved board, Apple's way naming the Apple app that does it, or a decision's number). Claude proposes the triage of every new finding at the reading, in one table; the owner confirms or changes it in one reply; a crash's fix starts at once and is reported. |

Small decisions, written here so they are not re-decided:

- Session 19: the guide and the notes say "More, then Settings" and "More, then Help" (Settings, Account and Help are under
  the More tab, not tabs of their own), and "Save attendance" (the button's words); otherwise as written above.

- The first Beta App Review build is the newest build on the internal group that the owner has passed on his phone: build
  1.0.0 (18) today, or the build that carries a fix for what he finds on it.
- The tester is in the internal group already (build 13's crash came from there); the device checks D1 to D6 and D8 run from
  that install while Beta App Review runs; D7 runs the day the group is approved, before the tutors are invited.
- Each reading is a session, or the start of one; a fix is its own pull request in that session or the next; `STATE.md`'s
  "In flight" says which reading is next and which build is out.
- A finding from the owner's own phone is logged like any other, "who" = the owner.
- The phase's three weeks run from the first tutor's invitation day (Owner step 4) to the same weekday three weeks later; the
  final build, if one is needed, goes out that week; the close follows.
- A device test passes on the final build when its code and screens did not change since the build it passed on; the log
  line says so with that build's number. The tester re-runs every test a Phase 9 fix touched, plus D2 and D7, on the final
  build.
- The pictures of the TestFlight feedback are kept in the scratchpad while they are read; only the one a row needs is copied
  to `plan/phase-09-findings/`.
- The branch for a fix is `phase-9/F<n>-<slug>`; several findings on one screen may share a pull request when they share a
  board.
- The two remote branches of merged pull requests (`tools/review-seed`, `tools/store-shots`) are the owner's to delete, as
  session 17's were.

## Review focus

Five things a person will meet that no task's happy path exercises; each is pinned in the task that owns it.

1. **A phone that cannot run the build** (iOS below 26, an iPad, an Android phone): TestFlight says the build is not
   compatible, or the invitation leads nowhere, and a tutor is lost on day one. Pinned: Task 2's tester table has an iOS
   column the owner fills before Owner step 4 invites anyone, and the guide's first lines say how to read the version.
2. **The production API behind the app:** a build whose fix touched `api/` goes out while `/health` still reports an older
   commit, so a tester sees the old behaviour and the finding reads "not fixed" (true today: #81's phone reading is on
   `main`, not deployed). Pinned: Task 1 deploys now; Task 7's build step curls `/health` and compares it with `main`'s
   head before `gh workflow run testflight`.
3. **A finding with no build number or no tester** (a WhatsApp forward of a screenshot): it cannot be told from one already
   fixed. Pinned: Task 6 refuses a row with a blank Build or Who and asks the owner for them first; the guide asks for the
   version (Settings, then About), and TestFlight's feedback carries the build itself.
4. **A crash report with addresses instead of names:** the reading ends with "unreadable". Pinned: Task 6's crash step says
   where the build's dSYM is in App Store Connect and the `atos` command, and a reading is not closed with an unread crash.
5. **The same thing from two tutors, or a thing already on the polish list:** two rows, and the end-of-phase counts lie.
   Pinned: Task 6 searches the findings file and `plan/ui-polish.md` by screen before a row is written; a second report
   joins the first row's Who column.

## File structure

| File | Responsibility | Task |
|---|---|---|
| `docs/release.md` | The checklist ticked with proofs for each external build; the release notes per build (also "What to Test") | 1, 7, 8 |
| `docs/testing/tester-guide.md` | The tester's guide, the message the owner sends (D54) | 2 |
| `docs/testing/device-tests.md` | D7's wording for the group; the tester's log lines per build | 2, 4, 8 |
| `plan/phase-09-findings.md` | The testers table (T1 to T6), the readings table, the findings table (D55) | 2, 6 |
| `plan/phase-09-findings/` | The pictures the findings rows point at | 6 |
| `plan/ui-polish.md` | Rows for Polish findings | 6 |
| `plan/phase-09-user-testing.md` | "Later", then "As built" | 6, 8 |
| `plan/STATE.md` | The build out, the next reading, the open bugs | every task |
| `plan/README.md` | D52 to D55 (this session's documents commit); Phase 9's status | 8 |

Code changes only in fix pull requests (Task 7), named by their findings.

## The calendar

Dates follow the owner's steps; the shape is fixed. Today is Friday 9 October 2026.

| When | What |
|---|---|
| Week 0 (12 to 16 October) | Task 1 (the API deploy, the checklist, the release notes), Task 2 (the guide, the findings file), Owner steps 1 to 3 (Test Information, the group, the build to Beta App Review), Task 4 (the tester's D1 to D6 and D8 on the internal install), the approval, D7, Owner steps 4 and 5 (the invitations, the guide sent) |
| Weeks 1 to 3 (from the invitation day, three weeks) | Task 6 twice a week (Monday, Thursday); Task 7 as findings need (fix pull requests, a Thursday build with its notes) |
| The week after | Task 8: the final build if one is needed, the tester's final lines, the acceptance, As built, then Owner step 6 (App Store submission) |

---

### Task 1: the first external build is ready (the API deploy, the checklist, the release notes)

**Files:**
- Modify: `docs/release.md` (the checklist's proofs; "Release notes")
- Modify: `plan/STATE.md` (Production: the API's commit and run)

**Interfaces:**
- Consumes: `main`'s head; the API's `/health`; TestFlight run 37950611572 (build 18).
- Produces: the release-notes text under "1.0 (build 18)" that Owner step 3 pastes as "What to Test" and Task 2's guide
  shortens; the ticked "Before the build" and "The build" lines.

- [x] **Step 1: confirm the candidate build with the owner.** Ask (one question): "Build 18 passed on your phone (U33's alerts,
  the long class name on Add to class)?" A finding here is the first row of Task 2's findings file, fixed by Task 7 before this
  task continues; the candidate becomes the build that carries the fix.

- [x] **Step 2: deploy the API** so production carries #81's phone reading and D48's limits:

```bash
gh workflow run deploy && sleep 20 && gh run list --workflow deploy --limit 1
```

  Watch it with `gh run watch <id>`. Expected: the migrate job's summary says nothing is pending; the smoke is green;
  `curl -s https://api.tutorcentral.in/health` prints `main`'s head (`git rev-parse HEAD`). Record the run id and the commit
  in `STATE.md`'s Production.

- [x] **Step 3: tick "Before the build"** in `docs/release.md`, each with its proof in the line:
  `main` green (the `check` run id of the head commit, `gh run list --workflow check --limit 1`); no migration pending
  (the deploy run's summary, and the TestFlight lane of build 18 passed its migration gate); `/health` at the head (the
  curl's commit); `bun check --fresh` green locally (the summary's last line, with the date); the D32 hand runs (the pull
  requests that carried build 18's write changes: #84, #86, #87, each with its hand run in its description);
  `MARKETING_VERSION` 1.0.0 (`ios/project.yml` line 15).

- [x] **Step 4: tick "The build"**: run 37950611572, build 1.0.0 (18); the internal group installed it (the owner's phone, step
  1). The tester's line waits for Task 4.

- [x] **Step 5: write the release notes** under "Release notes", replacing the template "1.0 (build N)" with this text (the
  Phase 7 list moves under it as history: "Earlier: build 10 to 18 brought …", one line). This is also "What to Test" for
  the build, pasted whole by Owner step 3:

```markdown
### 1.0 (build 18), the first build for the Tutors group

Tutor Central keeps your tuition centre on your iPhone: students and parents, who came to class, who has paid this
month, your classes and events, and tools that prepare papers and check answers. This is the app as it will go to
the App Store; you are among the first tutors to use it.

In the first week, try:
- Add your students and their classes, with each parent's WhatsApp number and the monthly fee. Or photograph the
  register you already keep: Students, then "+", then "Scan paper register".
- Mark attendance on each day you teach, and try "Tell parent" for an absent student.
- Open Fees for this month: send a reminder, mark a fee paid, share the receipt.
- Turn on reminders in Settings, and see one arrive before your next class.
- Make a question paper or a worksheet in AI Assistant, and share it as a PDF.
- Check a photographed answer sheet against your marking scheme, and write a progress note.
- Once, switch off Wi-Fi and mobile data, open the app and mark attendance; then switch them back on.

If something is slow, confusing, wrong or missing: take a screenshot, tap it, tap Done, then "Share Beta Feedback".
Or write to hello@tutorcentral.in from Settings, then Help.
```

  Check the words: no entry of the banned list appears (`grep -i -w -E 'server|servers|sync|syncing|synced|cache|cached|queue|queued|upload|uploaded|database|supabase|postgrest|api|http|json|token|backend|request' docs/release.md` prints only lines above the notes); nothing claims what the app does not do (compare each line with `docs/store/listing.md`'s description).

- [ ] **Step 6: commit the documents** to `main` (D12) and push:

```bash
git add docs/release.md plan/STATE.md && git commit -m "Release checklist and notes for build 18, the first external build; the API deployed to main's head" && git push
```

---

### Task 2: the tester's guide and the findings file

**Files:**
- Create: `docs/testing/tester-guide.md`, `plan/phase-09-findings.md`, `plan/phase-09-findings/.gitkeep`
- Modify: `docs/testing/device-tests.md` (D7's row names the Tutors group; "How to run" gains one line: the tester's lines for
  the external build go under the build number)

**Interfaces:**
- Consumes: Task 1's release notes (the guide's "In the first week" is the same list, with the same words).
- Produces: the guide the owner sends (Owner step 5); the findings file's three tables that Task 6 fills; the tester
  codes T1 to T6 every later task uses.

- [x] **Step 1: write the guide**, exactly this (the owner's WhatsApp number is already in the repository, in the review seed):

```markdown
# Trying Tutor Central before it is in the App Store

Thank you for trying Tutor Central. It is an app for tutors who run their own tuition centre: your students and
their parents, who came to class, who has paid this month, your classes, and tools that help you prepare papers and
check answers. It is not in the App Store yet. For the next three weeks you are one of six tutors using it on your
own iPhone, and what you tell us decides what we fix before it goes live.

## What you need

- An iPhone with iOS 26 or later. To check: Settings, then General, then About, then "iOS Version".
- The TestFlight app, free from the App Store. It is Apple's app for trying apps before they are released.
- The invitation email from TestFlight, sent to the address you gave us. Look in Spam or Promotions if it is not in
  your inbox.

## Getting started

1. Install TestFlight from the App Store.
2. Open the invitation email on your iPhone and tap "View in TestFlight", then "Install".
3. Open Tutor Central. Sign in with Apple, with Google, or with your email (a six-digit code is sent to you; check
   Spam if it is slow to arrive).
4. Give your centre a name. Then add your students, or photograph the paper register you already keep and let the
   app read it.

Use it for your real centre, the way you would use any app. Your records are yours: they are kept in India, nobody
but you can see them, and nothing is sent to a parent unless you tap Send in WhatsApp. If you would rather not use
real names, made-up students are fine too.

## In the first week, try

1. Add your students and their classes, with each parent's WhatsApp number and the monthly fee. Or photograph your
   register: Students, then "+", then "Scan paper register".
2. Mark attendance on each day you teach: tap the students who did not come, then Save. Try "Tell parent" for an
   absent student. (Put your own number as a parent's first, to see what arrives.)
3. Open Fees for this month. Send a fee reminder to yourself. Mark one fee paid and share the receipt.
4. Turn on reminders: Settings, then Teacher reminders. See whether a reminder arrives before your next class, and
   tap it.
5. Make a question paper or a worksheet: More, then AI Assistant. Share it as a PDF on WhatsApp.
6. Photograph a checked answer sheet with your marking scheme: More, then Check a paper.
7. Write a progress note for one student and send it to yourself.
8. Once, switch off Wi-Fi and mobile data and open the app. See what it shows, and mark attendance. Switch them
   back on.

Everything else is yours to explore. If something is slow, confusing, wrong, or missing, we want to hear it.

## How to tell us

- The quickest way: take a screenshot in the app (press the side button and the volume-up button together). A small
  picture appears at the bottom left; tap it, tap Done, then tap "Share Beta Feedback". Write a line and send; the
  picture comes with it.
- If the app closes by itself, your iPhone asks whether to send a report the next time you open it. Please tap Send,
  and add a line about what you were doing.
- Or write to hello@tutorcentral.in. In the app, Settings, then Help, then "Email hello@tutorcentral.in" opens a message with the app's
  version already filled in.
- Or send a WhatsApp message to +91 96113 85678 with a screenshot.

A line is enough: what you were doing, what you expected, what happened. Tell us the version too: Settings, then
About.

## Good to know

- Reminders and receipts go through your own WhatsApp. The app only opens WhatsApp with the message ready; nothing
  goes until you tap Send there.
- The teaching tools send what you type, and the photos you take, to an AI service to be read, after you agree once.
  The service normally deletes them within 30 days and never uses them for training. We keep no copy.
- When the three weeks end you can keep using the app until it is in the App Store, where it will be free. If you
  would rather remove everything: Settings, then Account, then "Delete account permanently".
```

- [x] **Step 2: check the guide's words.**

```bash
grep -n -i -w -E 'server|servers|sync|syncing|synced|cache|cached|queue|queued|upload|uploaded|database|supabase|postgrest|api|http|json|token|backend|request|error code' docs/testing/tester-guide.md
```

  Expected: nothing printed. Then read it once as a tutor would: every step names what is tapped, in the app's own words
  (compare "Scan paper register", "Tell parent", "Teacher reminders", "Check a paper", "Delete account permanently" with the
  strings in `ios/TutorCentralKit/Sources`: `grep -rn '"Scan paper register"' ios/TutorCentralKit/Sources` finds each).

- [x] **Step 3: write the findings file**, exactly this skeleton:

```markdown
# Phase 9 findings

One row per thing seen by a tutor, the tester or the owner (D55). Read on Monday and Thursday; a crash the day it is seen.
No tutor's name, email or number here: the owner keeps who T1 to T6 are. A picture that shows a parent's number is
covered before it is committed.

## Testers

| Code | Centre (students) | Sign-in | iPhone | iOS | Network | Invited | Installed (build) |
|---|---|---|---|---|---|---|---|
| T1 | | | | | | | |
| T2 | | | | | | | |
| T3 | | | | | | | |
| T4 | | | | | | | |
| T5 | | | | | | | |
| T6 | | | | | | | |
| Tester | (the device tests) | | | | | | |
| Owner | | | | | | | |

## Readings

| # | Date | Builds in use | New findings | Open bugs after | Build out |
|---|---|---|---|---|---|

## Findings

Triage: **Bug** (its own pull request), **Polish** (a row on `plan/ui-polish.md`), **Later** (the phase file's "Later"),
**No change** (with the reason). Status: Open, Proposed, Confirmed, Fixing (PR), Fixed (build N), Placed (U<n> or Later),
Closed (No change).

| # | Date | Build | Who | How | Screen | The words | Picture | Triage | Where | Status |
|---|---|---|---|---|---|---|---|---|---|---|

## Later

Things tutors asked for that the app does not have, for the owner to place in a phase (rule 10): the thing, who asked,
how many.

| What | Who | Count |
|---|---|---|
```

- [ ] **Step 4: ask the owner for the testers' facts**, one message, a table to fill: for each of T1 to T6 the centre's size,
  the sign-in he expects them to use, the iPhone model, iOS version, and whether they are mostly on mobile data. He fills
  what he knows now; the rest at Owner step 4. Put the answers in the Testers table. Check against D52: two of 30 or more,
  two under 10; Apple, Google and email each at least once; one iPhone 11 or 12; one on mobile data. A gap is said to the
  owner (he may swap a tutor or accept the gap, written in the table's row as "accepted").

- [x] **Step 5: `docs/testing/device-tests.md`**: D7's "Do" becomes "Install the build from the Tutors group's invitation email
  (not the internal group)". Under "How to run", add: "For an external build, write the lines under that build's number; a
  test whose screens did not change since it passed may be carried as 'Pass on build N, unchanged'."

- [ ] **Step 6: commit the documents** to `main` and push:

```bash
git add docs/testing/tester-guide.md docs/testing/device-tests.md plan/phase-09-findings.md plan/phase-09-findings/.gitkeep && git commit -m "Phase 9: the tester's guide (D54) and the findings file (D55)" && git push
```

---

### Task 3: Owner steps 1 to 3 (App Store Connect: Test Information, the group, the build to Beta App Review)

One message per step; the next waits for "done" and the check.

- [x] **Owner step 1: Test Information.** App Store Connect → Tutor Central → TestFlight → Test Information. Check and fill:
  Beta App Description = "Tutor Central helps tutors who run their own tuition centre keep students and parents, attendance,
  monthly fees, classes and teaching tools on their iPhone. This is a trial build before the App Store." Feedback Email
  `hello@tutorcentral.in` (set). Marketing URL `https://tutorcentral.in`. Privacy Policy URL `https://tutorcentral.in/privacy`
  (set). Beta App Review Information: contact first and last name, phone, email (the owner's); "Sign-in required" on, with
  `review@tutorcentral.in` and its password (typed by the owner; never in chat); Notes = the "Signing in" and "Teaching tools"
  paragraphs of `docs/store/listing.md`'s App Review notes. Save. **Check:** the page saves with no field in red; the owner
  says "done".
- [x] **Owner step 2: the group.** TestFlight → External Testing → "+" beside "External Groups" → name "Tutors" → Create. Leave
  "Enable Public Link" off (D53). **Check:** "Tutors" appears with 0 testers and no build.
- [x] **Owner step 3: the build to review.** Tutors → Builds → "+" → version 1.0.0 → build 18 (or Task 1's candidate) → Next;
  "What to Test" = the text under "1.0 (build 18)" in `docs/release.md`, pasted whole; Next → Submit for Review. **Check:** the
  build's status in the group reads "Waiting for Review"; the owner says so. Beta App Review usually answers within a day or
  two. If it comes back rejected, the owner pastes Apple's message; the session answers it (a fix by Task 7, or the words
  changed in Test Information) and the owner submits again. Write the submission date in `STATE.md`'s In flight.

---

### Task 4: the tester's device checks on the review build

**Files:**
- Modify: `docs/testing/device-tests.md` (the log lines)

- [ ] **Step 1: hand the tester the list.** The owner sends the tester the build number and the tests D1 to D6 and D8 (the
  internal install; D7 waits for the group). Session 17's note: D2 re-checks build 13's crash fix (#84); D3 is the queue; D5
  deletes a test Apple ID's account, so a throwaway Apple ID.
- [ ] **Step 2: log the lines** as they come back, one per test, in the log table: date, build, test, Pass or Fail, what was
  seen (the tester's words). A Fail is also a finding row (Task 6's format, Who = Tester) and a Bug by D55.
- [ ] **Step 3: on approval, D7.** When Beta App Review says "Approved", Owner step 4a invites the tester's email first; the
  tester installs from that email and logs D7 (the version on Settings reads 1.0 with the build number from the email).
- [ ] **Step 4: the gate.** With D1 to D8 all Pass on this build, Owner step 4 goes ahead. With a Fail: Task 7 fixes it, a new
  build goes to the group (the same version: Apple may approve it without a full review, or review it again), the tester
  re-runs the failed test and D7 on the new build, then Owner step 4.
- [ ] **Step 5: commit** the log lines to `main` as documents:

```bash
git add docs/testing/device-tests.md plan/phase-09-findings.md && git commit -m "Device tests D1 to D8 on build 18 (the tester)" && git push
```

---

### Task 5: Owner steps 4 and 5 (the invitations and the guide)

- [ ] **Owner step 4a: the tester.** Tutors → Testers → "+" → "Add New Testers" → the tester's email, first and last name →
  Add. **Check:** the row shows "Invited"; the tester's D7 line (Task 4, step 3).
- [ ] **Owner step 4: the six tutors**, after Task 4's gate. The same, six rows; the facts in the Testers table (Task 2, step 4)
  completed now (iOS version read from each phone before the invitation: Review focus 1). **Check:** six rows "Invited"; the
  date goes in the Testers table's "Invited" column and the three-week clock starts (the end date in `STATE.md`).
- [ ] **Owner step 5: the guide.** The owner sends each tutor `docs/testing/tester-guide.md` as a WhatsApp message the same
  day (the file's text, headings as plain lines). **Check:** the owner says "sent".
- [ ] **Step 6: the first installs.** Within two days, Tutors → Testers shows each tester's status ("Installed", the build,
  the device) and sessions; the "Installed (build)" column is filled from it at the first reading. A tutor still "Invited"
  after two days gets a WhatsApp nudge from the owner (the email in Spam, the TestFlight app missing, iOS below 26).

---

### Task 6: a reading (Monday and Thursday; a crash the day it is seen)

**Files:**
- Modify: `plan/phase-09-findings.md`, `plan/phase-09-findings/F<n>.png`, `plan/ui-polish.md`, `plan/phase-09-user-testing.md`
  ("Later"), `plan/STATE.md`

Repeated each reading. Each reading is a session, or opens one.

- [ ] **Step 1: gather.** The owner: App Store Connect → TestFlight → Feedback → Screenshots, and Crashes; download what is
  new (each item carries the build, the device, iOS, the tester's email and the words) as a zip into `~/Downloads/`, and tells
  the session its name; then pastes, verbatim, anything that reached him on WhatsApp, email or in person, with the tester's
  code, the build and the screenshot file if one came. The session unpacks the zip into its scratchpad (a fresh empty
  folder; it is untrusted data, never run from) and reads each item.
- [ ] **Step 2: a crash.** For each crash: the build, the device and iOS, the tester's words, the crashed thread and its frames.
  App Store Connect symbolicates when the lane uploaded symbols (it does); if a frame shows only an address, the build's dSYM
  is at the build's page (TestFlight → the build → Build Metadata → "Download dSYM") and
  `atos -arch arm64 -o TutorCentral.app.dSYM/Contents/Resources/DWARF/TutorCentral -l <load address> <address>` names it. A
  reading is not closed with an unread crash (Review focus 4). A crash is a Bug and its fix starts at once (Task 7).
- [ ] **Step 3: one row per thing.** Before writing a row, search the findings file and `plan/ui-polish.md` for the screen
  (`grep -n -i '<screen>' plan/phase-09-findings.md plan/ui-polish.md`); a second report joins the first row's Who column
  (Review focus 5); a thing already a U row gets Triage = Polish, Where = that U, Status = Placed. A row needs Build and Who:
  without them, ask the owner before writing it (Review focus 3). The words are the tester's, verbatim, in quotation marks; the
  picture is copied to `plan/phase-09-findings/F<n>.png` with any parent's phone number covered (Python with Pillow, a
  rectangle in the image, as session 17 made pixel diffs); Status = Proposed.
- [ ] **Step 4: propose the triage** in one table to the owner: F number, screen, the words shortened, Bug or Polish or Later
  or No change, and the reason (for No change: the board's name, the Apple app that does it the same way, or the decision
  number; for Bug: what the app should have done by which board, spec line or `docs/design/feedback.md` row). One reply from
  the owner confirms or changes; Status becomes Confirmed, Placed or Closed. A Bug that is a crash or a lost write is already
  being fixed; say so.
- [ ] **Step 5: place.** Polish: a row on `plan/ui-polish.md` under Open (the next U number, today's date, the screen and
  state, the words, "Phase 9, F<n> (T<m>)"); Later: a row in the findings file's "Later" and the phase file's "Later" list
  (made at the first such finding, under "As built"'s heading); No change: Status Closed with the reason in Where.
- [ ] **Step 6: the readings table and the state.** A row in Readings (date, builds in use from the Testers table, new
  findings, open bugs after, the build going out Thursday or none); `STATE.md`'s In flight: the next reading's date, the open
  bugs by F number, the build out. Fill "Installed (build)" from TestFlight's tester rows.
- [ ] **Step 7: commit** the documents to `main` and push:

```bash
git add plan/phase-09-findings.md plan/phase-09-findings plan/ui-polish.md plan/phase-09-user-testing.md plan/STATE.md && git commit -m "Reading <n> (<date>): F<a> to F<b> logged and triaged" && git push
```

---

### Task 7: a fix and a build

**Files:** named by the finding; the pull request's description names the F number.

Repeated per confirmed Bug; the build on Thursday (D53).

- [ ] **Step 1: the board, when what is seen changes.** A new state or a changed screen gets its board on the canvas first
  (`docs/design/README.md`; the memory's canvas method), approved by the owner, mirrored in `docs/design/mockups/` and its
  row in `information-architecture.md` (a documents commit). A fix that restores what an approved board already draws needs
  no new board; say which board.
- [ ] **Step 2: the branch and the failing test.** `git checkout -b phase-9/F<n>-<slug> main`. Write the test that shows the
  bug (Swift Testing in the owning test target; `bun test` in `api/` or `supabase/tests`): run it, see it fail for the bug's
  reason, not a typo. A crash: a test that drives the same path (as `NotificationClientTests.aTappedReminderFinishesOnTheMainThreadWhereverItArrives` did for #84).
- [ ] **Step 3: the fix**, smallest that makes the test pass; `bun check` green; no raw style (D10), no technical words (D41:
  `ErrorWordsTests` runs in the check), nothing from the inventory dropped.
- [ ] **Step 4: the pictures and the hand run.** `bun shots <state>` for every changed state, both appearances; `bun pr-shots
  phase-9/F<n> <files>`; the table in the description (D7). A fix that touches a write: the hand run by
  `docs/runbooks/simulator.md` against the local stack, every write confirmed in the database, its screenshots in the
  description (D32).
- [ ] **Step 5: the pull request.** `gh pr create` with: the F number and the tester's words, what changed, how it was checked
  (the test's name, the pictures, the hand run), the board if one; the attribution line. Merge when CI is green and the pictures
  show (rule 2). The findings row: Status = Fixing (PR #n), then Fixed (build N) once the build is out.
- [ ] **Step 6: the build, Thursday** (or at once for a crash or a lost write). Before it: `main` green; `curl -s
  https://api.tutorcentral.in/health` prints `main`'s head, else `gh workflow run deploy` first and wait for it (Review focus
  2); the hand runs of the build's writes done; the release notes for the build written in `docs/release.md` under
  "1.0 (build N)" in tester words ("Fixed: tapping a class reminder closed the app." one line per fix, the F numbers in
  parentheses), checked against the banned list as Task 1 step 5 does. Then:

```bash
gh workflow run testflight && sleep 20 && gh run list --workflow testflight --limit 1
```

  `gh run watch <id>`; the build number is the run number. The checklist's lines for this build ticked with the proofs
  (the "Before the build" and "The build" lists are per build: copy them under the build's notes, ticked).
- [ ] **Owner step (per build): the build to the group.** Tutors → Builds → "+" → 1.0.0 → the new build → "What to Test" = the
  new notes, pasted whole → Submit. **Check:** the build shows in the group ("Approved", or "Waiting for Review" when Apple
  reviews it again) and the testers get TestFlight's update notice. The Testers table's "Installed (build)" follows at the
  next reading.
- [ ] **Step 8: commit** `docs/release.md`, `plan/phase-09-findings.md` (Fixed (build N)), `plan/STATE.md` to `main` and push.

---

### Task 8: the close (acceptance, As built, submission)

**Files:**
- Modify: `plan/phase-09-user-testing.md` ("As built", "Later"), `plan/README.md` (Phase 9's status), `plan/STATE.md`,
  `docs/release.md`, `docs/testing/device-tests.md`, `plan/phase-09-findings.md`

- [ ] **Step 1: the last reading** on the three weeks' last day (Task 6). Every row has a status other than Open or Proposed;
  every Bug is Fixed or deferred by the owner in writing (Where = "deferred by the owner, <reason>", Status = Placed).
- [ ] **Step 2: the final build**, if any fix merged since the last (Task 7, step 6); otherwise the last build out is the
  final build. Its number goes in `STATE.md`.
- [ ] **Step 3: the tester's final lines.** On the final build, the tester re-runs every test whose screens a Phase 9 fix
  touched, plus D2 and D7 (and S1 to S6, C1 to C6, A1 to A5, N1, N2, W1, W2 if a fix touched them); every other test carries
  "Pass on build N, unchanged" with that build's number. The log shows a line per test for the final build.
- [ ] **Step 4: the release checklist** in `docs/release.md` complete for the final build: "Before the build" and "The build"
  (Task 7's proofs), App Store Connect's four lines (the group, the review's approval date), "After" (the notes written;
  `STATE.md` updated). The acceptance's four lines in `phase-09-user-testing.md` each answered with its proof: the six tutors'
  "Installed (build)" and sessions through the three weeks (from TestFlight's tester rows, counts only); the findings table
  with no Open or Proposed; the device log; the checklist.
- [ ] **Step 5: As built** in `phase-09-user-testing.md`: the testers (codes and facts), the dates, the builds (numbers and
  what each carried), the findings by triage (counts, the Bug rows by F number and PR), "Later" (the list with counts), what
  deviated from this plan and why. `plan/README.md`: Phase 9 "Done (session N, PRs #a to #b)"; `STATE.md` rewritten (Next:
  App Review; after approval, `APP_STORE_URL` on Vercel's `tutor-central-web` and `gh workflow run deploy-web` for Home's
  badge (D47), a later slice).
- [ ] **Step 6: commit the documents** to `main` and push.
- [ ] **Owner step 6: App Store submission.** App Store Connect → the app → the 1.0 version page → Build → "+" → the final
  build → Done → Save; read the page once more (the screenshots, the description, the review account under App Review
  Information: `docs/store/listing.md`); "Add for Review" → "Submit to App Review". **Check:** the version's status reads
  "Waiting for Review"; the date in `STATE.md`. Apple's answer (an approval, or a message to answer) is the next slice, not
  this phase.

---

## Self-review

- **Spec coverage.** Scope 1 (who, how long): D52, asked and answered 2026-10-09. Scope 2 (the group, the test information,
  Beta App Review, the invitations, one at a time): Task 3's Owner steps 1 to 3, Task 5's 4 and 5, Task 7's per-build step.
  Scope 3 (the guide; the device checks): Task 2 (the guide, D54), Task 4 (D1 to D8 before the tutors, D52). Scope 4 (feedback
  and crashes read each week, each finding with build, words, picture): Task 6, twice a week (D55). Scope 5 (triage into bug,
  polish, later, no change; a build when fixes land with notes): D55, Tasks 6 and 7. Scope 6 (plan first; D7; D32; STATE):
  this file; Task 7's steps 1, 4, 5; every task's commit step. Acceptance's four lines: Task 8 steps 1 to 4. The resume
  prompt's own asks: the owner's steps checked one at a time (Tasks 3, 5, 7, 8); the guide's place (D54); the findings file,
  its cadence and triage (D55); the cadence of builds and notes (D53, Task 7); what ends the phase and the submission as the
  owner's step (Task 8). Carry forward: the open polish rows and the minors stay the owner's (none taken; Task 6 only adds
  rows); D2 re-checks #84 (Task 4, step 1).
- **Placeholders.** The guide, the notes, the findings skeleton, the Test Information words and every command are written
  out. The one open input is the owner's: the testers' facts (Task 2, step 4), said as such. The owner's WhatsApp number in the
  guide is the one already in the repository (the review seed).
- **Consistency.** The tester codes T1 to T6, Tester, Owner (Task 2) are what Tasks 4 to 8 use; the statuses Open, Proposed,
  Confirmed, Fixing, Fixed, Placed, Closed (Task 2's skeleton) are what Tasks 6 to 8 set; the branch name `phase-9/F<n>-<slug>`
  (small decisions, Task 7); "What to Test" = the notes under "1.0 (build N)" in `docs/release.md` (D53, Tasks 1, 3, 7);
  the picture path `plan/phase-09-findings/F<n>.png` (D55, Task 6).
- **Review focus.** 1 → Task 2 step 4 and Owner step 4 (the iOS column before an invitation), the guide's "What you need".
  2 → Task 1 step 2 (the deploy now), Task 7 step 6 (the curl before every build). 3 → Task 6 step 3 (no row without Build and
  Who). 4 → Task 6 step 2 (the dSYM and `atos`). 5 → Task 6 step 3 (the search before a row; a second report joins the first).
- **Apple's way.** The guide's feedback path is TestFlight's own (screenshot → Done → Share Beta Feedback; the crash prompt on
  the next launch); the notes and the description name only what the app does (2.3) and the AI service as the consent sheet
  does (5.1.2(i)); the group is Apple's external group with Beta App Review, not a sideload.
- **Seen while planning, for the owner:** the API in production is behind `main` by #81 (the phone trunk 0 and D48's limits);
  Task 1 deploys it before any tutor sees the app. Two remote branches of merged pull requests remain (`tools/review-seed`,
  `tools/store-shots`).
