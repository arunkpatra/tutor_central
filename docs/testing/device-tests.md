# Device tests

What a person must test on a real iPhone, because the simulator cannot:
- a real camera and real paper;
- WhatsApp, Files, Print and the share sheet with real apps;
- a phone network that drops;
- the production AI answering real handwriting.

Everything else is proven in the simulator against the local stack (`docs/runbooks/simulator.md`) and is not listed here.

This is a living document. A session adds a test when its work needs one, and removes a test the simulator can now cover.
The tester writes results in the log at the end.

## How to run

- Install the newest TestFlight build of Tutor Central and sign in with a test centre, not a real one. The AI tools run
  against production and every call counts against the centre's daily limit (40 creations, 20 scans, 20 checks).
- Use made-up students. If you photograph a real register or answer sheet, use one you may share: it is sent to the AI
  service to be read and is not kept.
- For each test, write a line in the log: the date, the build number, the test id, Pass or Fail, and what you saw. A
  Fail needs a screenshot (side button and volume up together) and a word on what you expected instead.

## Tests

### Scan register (Students → + → Scan paper register)

| Id | Do | Expect |
|---|---|---|
| S1 | First use on this phone: Take a photo. When iOS asks for the camera, tap Allow. Photograph a page of 8 to 10 names with parents' phones and fees, flat, in good light. | The consent sheet ("Before the first photo") once per centre, then the scanner. It finds the page and "Check the list" shows every row. Names, phones and fees match the page. A child already in the app is unticked with "Already here". |
| S2 | Same as S1, with the page at an angle, in dim light, or handwritten in a hurry. | Most rows read right. A phone it could not read says "No number read", never a wrong number. Note every misread in the log. |
| S3 | Phones written as 98765 43210, +91 98765 43210, 098765 43210 and 98765-43210 on one page. | The first, second and fourth read as +91 98765 43210. The one with a leading 0 is a known gap (it reads "No number read"); log what you see. |
| S4 | On the list: tap a row, fix the name or number, Save. Untick one row. Add. Then tap Undo on the Students list straight away (within 8 s). | Add creates only the ticked rows, in the chosen class, with their fees. Undo removes exactly those rows. |
| S5 | Choose from Photos, a photo of a register taken with the iPhone Camera app (full size). | It reads as S1, within about 10 s on Wi-Fi. |
| S6 | Turn the camera off: Settings → Privacy & Security → Camera → Tutor Central off. Back in the app: Take a photo. | A message saying the camera is off, with Open Settings, which opens Tutor Central's settings. Turning it back on and returning works. |

### Check a paper (More → Check a paper)

| Id | Do | Expect |
|---|---|---|
| C1 | Choose a student, Take photos: photograph two pages of a real or hand-written answer sheet. Type it: a short scheme ("Q1 2 marks: x = 3 or 4. Q2 1 mark: roots equal."). Check 2 pages. | Suggested marks within about 30 s, each with a short reason that matches the sheet. The total is the sum of the rows. |
| C2 | Use A paper I created as the scheme: create a question paper in AI Assistant first, write answers to it on paper, photograph them, check against that paper. | Marks out of the paper's total; reasons refer to its questions. |
| C3 | Six pages (the most). Check on mobile data, not Wi-Fi. | It sends and answers, maybe slower. No "too many pages" message for six ordinary photos. |
| C4 | Change two marks (tap a mark, pick another), Save to the student's notes. Open the student's page. Then go back and tap Undo on the toast. | The notes end with one line: date, scheme, total (with the changed marks). Undo takes the line away and leaves the notes exactly as they were. |
| C5 | Start a check, tap Cancel while it says Checking. Start it again. | Cancel goes back to the scheme with nothing shown; the second check answers normally. |
| C6 | Start a check and lock the phone or switch to another app for a minute, then come back. | The marks are there, or a clear failure with Retry. Never a spinner that does not end. |

### AI Assistant (Today → Create with AI, or More → AI Assistant)

| Id | Do | Expect |
|---|---|---|
| A1 | Question paper for a class: Create, then leave the screen and open something else while it writes. Come back through Recent. | The paper is in Recent and History. Sections add up to the marks asked for. |
| A2 | On a paper: Share as PDF → WhatsApp (to yourself), → Print (or Save to Files), → Mail. | A clean A4 PDF named after the topic, every page readable, the answer key at the end. |
| A3 | A worksheet with Answer key at the end turned off: Copy, paste into Notes; Share as PDF. | Neither the pasted text nor the PDF has the answers. The screen still shows them, marked "(for you)". |
| A4 | Progress note: choose a student whose parent has a WhatsApp number, write what you've seen, Write the note, edit a word, Send on WhatsApp → Open WhatsApp. | WhatsApp opens a chat with that parent's number, the note and your sign-off typed in. The student's page notes that a progress note was sent today. |
| A5 | The same with WhatsApp not installed (or on a phone without it). | The wa.me page opens in Safari instead; the note is on the clipboard (the sheet says it is copied too). Nothing breaks. |

### A bad network (any AI tool)

| Id | Do | Expect |
|---|---|---|
| N1 | Airplane mode on, then Create (or Check, or Scan). | "Couldn't create/check/read …" with Retry, in plain words. Airplane mode off, Retry works. |
| N2 | On a weak signal (a lift, a basement), Check six pages. | Either the marks, or after a while "That took too long to come back. Try again in a minute." Never stuck. |

### WhatsApp from Fees (from Phase 5; no WhatsApp in the simulator)

| Id | Do | Expect |
|---|---|---|
| W1 | Fees → a due fee → Remind → Open WhatsApp. | WhatsApp opens the parent's chat with the reminder and the UPI id typed in. |
| W2 | Mark a fee paid with receipts on → the receipt → Open WhatsApp. | The receipt message in the parent's chat. |

### Phase 7: the account, reminders, offline, the release candidate

| Id | Do | Expect |
|---|---|---|
| D1 | Settings → Accessibility → VoiceOver on. Swipe through Today, Students, one student, Fees, Attendance (mark one absent and save), Settings and Account. VoiceOver off. | Every control is read with a name that says what it does ("Mark attendance, button"); a row is read as one item with its value ("Dev Kumar, Class 8 Science, ₹1,000, Due"); the attendance pill says "Present, button" and what a tap does; nothing is read as "button" alone or skipped. |
| D2 | Settings → Teacher reminders → Turn on reminders → Allow. Add a class (Students → Classes) that meets today, starting 16 minutes from now. Lock the phone and wait. | A banner on the lock screen within a minute: "<class> at <time> · In 15 minutes · N students. Tap to mark attendance." Tapping it unlocks into Attendance for that class and day. |
| D3 | Airplane mode on. Open Today, Students and Fees (seen before). Mark attendance for a class with one absent, Save, Tell parent → Open WhatsApp. Mark one fee paid. Add a student. Airplane mode off; wait on the Today tab. | Each screen shows its last content with the bar "Offline. Showing what was saved at …". Attendance reads "Saved on this iPhone"; WhatsApp opens with the alert (it queues it); the fee row says it is kept here; the student is refused in words and the form kept. Back online: "Back online. Sending 3 saved changes…", then "3 saved changes sent."; the attendance, the fee and the alert's note are on their screens. |
| D4 | On the oldest iPhone that runs iOS 26 you can borrow (an iPhone 11 or 12): cold-launch the app five times; scroll the Students list of 30 or more students and the Fees month quickly. | Today appears within about two seconds of the icon tap each time; scrolling never stutters. Note the phone model and anything slower. |
| D5 | Sign in with Apple on a test Apple ID. Settings → Account → Delete account permanently → type the centre's name → Delete my account → confirm with Apple. Then on the phone: Settings → your name → Sign-In & Security → Sign in with Apple. | The Apple sheet appears before deletion; the sign-in landing says the account was deleted; Tutor Central is no longer in the phone's Sign in with Apple list; signing in with Apple again starts at onboarding with an empty centre. |
| D6 | Account → Password → set one. Sign out. Continue with email → Use my password instead → the password. | Signs in without a code. |
| D7 | Install the build from the external TestFlight group's invitation email (not the internal group). | It installs and signs in; the version on Settings reads 1.0 with the build number from the email. |

## Log

| Date | Build | Test | Result | What was seen |
|---|---|---|---|---|
| 2026-10-09 | 0.1.0 (9) | S1 | Pass | The owner: "Installed the build on phone. Works" (Scan register with the real camera). |
