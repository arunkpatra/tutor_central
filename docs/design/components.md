# Components: Ember

Each control and pattern the app uses: anatomy, sizes, states, rules. Every one appears on the Kit boards
(`Kit-Controls-*`, `Kit-Surfaces-*` on the canvas) in both appearances. A new pattern is added here, with its
states, before it is used twice. Token names are from `design-tokens.md`.

## Buttons

| Variant | Fill | Text | Border | Shadow | Use |
|---|---|---|---|---|---|
| Primary | `accent` | `textOnAccent`, `button` 700 | none | `shadowPrimary` | The one main action of a view; never two on screen |
| Secondary | `surface2` (dark) / `surface1` (light) | `text`, 15 600 | `lineStrong` | `shadowButton` | Everything else that is a button |
| Quiet | none | `accentText`, 15 600 | none | none | Inline actions in headers and rows (Add, Schedule, Change) |
| Destructive | `overdueTint` | `overdue`, 15 600 | none | none | Delete, remove; always followed by a confirmation |
| Apple | `appleButton` | | none | 0 1px 2px rgba(0,0,0,.4) | Sign in with Apple only |

Sizes: 46 (in a row of buttons, forms), 50 (the primary on a card), 52 (sign-in and sheet footers). Radius
`radiusControl`. Side padding 16. An icon leads at 20 pt with `inline` gap.

States: default; pressed (scale 0.97, primary fill `accentPressed`, secondary fill `surface2` darkened by the
pressed shadow); disabled (opacity 0.45, no shadow); loading (label replaced by a 20 pt spinner in the label
colour, width kept). SF Symbols on buttons: `checkmark.circle` (mark attendance, mark paid), `bell`
(remind), `paperplane` (send), `camera`, `photo.on.rectangle`, `plus`.

**Icon button**: 40 × 40, round, `surface2` fill, `lineStrong` border, icon 20 in `text`. The account button
shows initials in `accentText`.

## Stat tile

`surface1`, `line` border, `radiusTile`, padding 14, `shadowRaised`. Value in `numberTile`, label in
`footnote` `text2`. A tile is a link: the whole tile presses. The value takes a status colour when it is a
status (`due` for money owed). Three in a row with `tileGap`.

## Cards

| Card | Fill | Radius | Padding | Use |
|---|---|---|---|---|
| Hero | `surface1`, `line`, `shadowRaised` | `radiusHero` | 18 | The next class, the outstanding/collected pair, the UPI payee |
| List | `surface1`, `line`, `shadowRaised` | `radiusCard` | 0; rows inside carry their own | A group of rows |
| Compact | `surface1`, `line`, `shadowRaised` | `radiusTile` | 14 | A single row with its own border (a student in a list) |
| Selected | `surface1`, `accent` border, `haloFocus` | as above | | A chosen option |
| On sheet | `surface2`, `line`, no shadow | `radiusCard` | 0 | A list inside a sheet (the add-students checklist) |

Rows inside a list card are divided by `line`; the last has no divider.

In code the inset top highlight of a raised surface is a 1 pt stroke along the inside of the top edge, fading
out down the corners; SwiftUI has no inset shadow (D25). An inset with a blur (a well, a pressed button) is an
inner shadow inside the shape.

## Rows

Row padding `rowPadding` (`rowPaddingDense` 12 × 16 in lists of people and classes); height at least 56; the whole row presses; chevron `chevron.right` 20 in `text3`
when the row opens something.

| Row | Leading | Middle | Trailing |
|---|---|---|---|
| Student | Avatar 40 | Name `rowTitle`; class and phone `footnote` `text2` | Fee `numberRow`; status `caption` in its colour |
| Class | Icon tile 40 (`surface2`, symbol) | Name; meeting summary | Member count; chevron |
| Schedule | Time `time` in `text2`, width 46 | Name; subtitle (`ok` when attendance is taken) | Check in `ok` or chevron |
| Fee | Name; phone | | Amount; compact status chip (24 high, 12 700); on a due row a second line of two buttons 44 high, radius 14 (Remind, Mark paid) |
| Attendance | Name `rowTitle` | | One state pill 96 × 40, radius 13: Present (`ok` fill, `okInk`, `segmentActive`) or Absent (`overdue` fill, `overdueInk`). The whole row is the toggle; selection haptic. (Phase 4 replaced the two toggles of step 0.2: half the names wrapped beside them) |
| Task | Circle checkbox 24 (`lineStrong` ring; `ok` fill with a tick when done) | Title `subhead` (struck through in `text2` when done) | Due day, or the done day, `footnote` `text3` |
| Setting | Symbol 20 `text2` | Label `body` | Value `body` `text2` and chevron, or a switch |
| Form field | | Label `footnote` `text2` above; value `body` in a well | |
| Member (class detail) | Avatar 40 | Name; parent phone | "Class fee" `footnote` `text2`, or the student's own fee in `footnoteStrong` `text`; chevron |
| Meeting (class detail) | Day `time` `text2`, width 46 | Date `rowTitle` ("Today, 7 October") | Time range `footnote` `text2`. Today's row sits on `surface2` with its day in `accentText` 700 |
| History (attendance) | Day over date, `time` `text2` / `caption` `text3`, width 46 | Class `rowTitle`; "5 of 6 present" `footnote` `text2` (or "Parent told on Mon 5 Oct" in `ok`) | "1 absent" `footnote` 600 `overdue`; chevron |
| Student percentage (history by student) | Avatar 40 | Name; a progress bar under it | Percentage `numberRow`; "9 of 12" `caption` `text2`; chevron |
| Absent student (saved attendance) | Avatar 40 | Name; parent and number `footnote` `text2` | Tell parent: a secondary button 36 high, radius 13, `whatsapp` glyph; or "Told Mon 5 Oct" in `ok` with a tick |
| Event (schedule) | Start over end, `time` `text2` / `caption` `text3` | Title; note or time range `footnote` `text2` | Chevron (opens Edit event) |
| Setting, later | As Setting at opacity 0.6 | | The phase name `caption` 600 `text3` instead of a chevron; not tappable (P4-More) |
| Checklist (add students) | Avatar 40 | Name; class line | Checkbox 24; the whole row toggles it. The card sits on `surface2` when it is inside a sheet |

A student row's second line is the class ("No class yet" when none); the parent's phone takes its place only
while no class exists yet, or when a search matched the number. The fee status under the amount reads this
month's invoice ("Paid 4 Oct" in `ok`, "Due" in `due`) and is absent when the month has no invoice yet.

A section whose feature arrives in a later build (the student detail's attendance until Phase 4) shows the
empty-row pattern at the Later opacity 0.6, with words that say what will appear and when.

**Counts beside a section title** (the attendance mark): "6 present · 0 absent" in `footnote` 600, present in `ok`,
absent in `overdue` when more than none, else `text2`.

## Section header

Title in `headline`; optional quiet action on the right (Add, Schedule, See all). 2 pt side inset so text
aligns with card content. `sectionHeaderGap` to the card below.

## Segmented control

Track `well` with `line` border, `shadowWell` (dark), radius 13, padding 3. Items 36 high, radius
`radiusSegment`, label 14 600 `text2`; the active item `surface2` (dark) / `surface1` (light) with
`shadowSegment` and `text` 700. Whole width of the content. Selection haptic.

## Switch

The system switch, tinted `accent`. 51 × 31. Off track `lineStrong`.

## Checkbox (tasks, review tables)

24 round, `lineStrong` ring 1.5; checked: `ok` fill, white tick 2.6 stroke. Selection haptic.

## Fields

Label `footnote` `text2` above (`fieldGap`). The well: 46 high, `well` fill, `line` border, `shadowWell`
(dark), `radiusControl`, padding 0 14. Value `body` 600 for numbers (`monospacedDigit`), 400 for text.
Prefix (₹) and suffix (per month) in `text2` / `text3`. Placeholder `text3`.

States: focus (`accent` border and `haloFocus`); error (`overdue` border, message `footnote` `overdue` under
the field, never only a colour); disabled (opacity 0.45). Phone fields format as typed (+91 98765 43210).
Multiline (notes): min 96 high, counter `caption` `text3` bottom right.

**Picker row**: label left `body`, value right in `accentText` with `chevron.up.chevron.down`; opens a menu
or a sheet.

On a sheet (`surface1`) a picker row is a tile: `surface2` fill, `line` border, no shadow, 46 high (the class
picker, the date of birth, the start and end time). The date-of-birth row carries its switch on the right; once
on, the date sits beside the switch in `accentText` with `chevron.up.chevron.down` and opens the system date
picker. A fee field left empty on a student means "the class fee": the placeholder shows that fee and the helper
line under the field says which one applies.

**Search field**: the system search field, drawn as a well 44 high: `magnifyingglass` 18 in `text3`, placeholder
`text3` ("Search by name or phone"). Focused it takes the field's focus ring, a clear mark and a quiet Cancel to
its right; the large title collapses. Results replace the list under a count line ("3 of 10 match"); the letters
that matched are in `accentText`.

## Chips and status marks

Height 28, radius `radiusChip`, padding 0 10, label 13 700. Status chips: tint fill and status text with a
leading symbol (`checkmark` paid, `clock` due, `exclamationmark.circle` overdue). Neutral chips: `surface2`
fill, `text2` 600, no symbol. A status never relies on colour alone: the word is always there.

**Filter chip** (selectable): off it is a neutral chip; on, `accentTint` fill and `accentText` 700, padding 0 12.
A row of filter chips (All, each class, No class, Archived) runs past `pageSide` to the screen edge and scrolls
sideways. The same chip is a toggle inside a form (gender: Girl, Boy, Other; "Every day" beside the meeting days).

**Banner**: one line of state under a header (a student's "Archived: off the list and today's counts…"):
`surface2`, radius 12, padding 8 14, `footnote` `text2` with a symbol 14, the offline bar's pattern.

## Avatar

Initials on `accentTint` in `accentText`, `avatar` type. 40 in rows, 36 in dense lists, 56 on a detail
header. Up to two letters from the first two words of the name.

**Icon tile** (a class): `surface2` fill, `book.closed` in `text2`; 40 with radius 12 in rows, 56 with
`radiusTile` on the class detail header.

## Day picker

Seven round toggles 40 (M T W T F S S) spread across the content width. Off: `surface2` fill, `lineStrong`
border, `text2` 600. On: `accent` fill, `textOnAccent` 700. "Every day" is a filter chip beside the label and
turns all seven on. The summary the Domain makes ("Tue, Thu, Sat · 18:00–19:30") reads back as a `footnote`
under the time rows. Selection haptic.

## Menu

The "+" button's menu is a popover from the icon button holding the board's rows (a popover rather than the system
pull-down, so its state can be photographed); the board draws it as `chrome` glass with `lineGlass` border,
`shadowFloat`, radius `radiusTile`, 260 wide; rows 46 with the label `body` on the left and its symbol 20 on the
right, divided by `lineGlass`: Add a student (`person.badge.plus`), Scan paper register (`doc.viewfinder`), Create
a class (`book.closed`). On iOS the popover's glass and shadow are the system's.

## Tab bar

Floating pill: `chrome` with `blurChrome`, `lineGlass` border, `shadowFloat`, height 66, radius `radiusBar`,
inset `tabBarInset`, padding 5. Five items; the active item sits on an `accentTint` pill (56 high, radius
28) in `accentText` 700; others `text2` 600. Symbols: `sun.max` Today, `person.2` Students, `indianrupeesign`
Fees, `checkmark.circle` Attendance, `ellipsis` More. On iOS 26 this is the system tab bar styled with these
tokens; the pill and glass come from the system.

## Navigation bar

Large title on tab roots (`display`), collapsing to `headline` on scroll with the system's glass bar.
Pushed screens: back chevron, title `headline`, one trailing action (quiet text or an icon button). Sheets:
Cancel left (quiet), title centre, Save right (quiet, 700; disabled until valid).

## Sheets

In the app a partial-height sheet is iOS 26's floating system sheet, inset with every corner rounded (D28); what
follows is its content.


`surface1`, top radius `radiusSheet`, grabber 36 × 5 `lineStrong`. Detents: medium and large for forms;
large only for long forms. The footer carries the primary button at 52 with 16 side padding and the safe
area below. A form sheet asks before discarding typed changes.

**Event sheets** (P4-Event-New, -Edit) open at the large detent. Delete event at the foot of Edit event closes the
sheet and the schedule asks over itself, on the event's day (P4-Event-Delete-Confirm).

**A calendar in a popover** (the attendance date, an event's day, a task's due day) is the system's graphical date
picker at 320 wide (`calendarPopover`); without a width the popover collapses it.

## Dialog (confirmation)

`surface1`, `lineStrong` border, `radiusSheet`, `shadowDialog`, padding 22. Title `title2`, body `subhead`
`text2`, two buttons 46 side by side: secondary Cancel, then the action (primary, or destructive for delete).
A destructive dialog that removes history asks the user to type the name. Warning haptic on appearance.
A reversible action (archive) is confirmed with a primary button; a deletion with the solid destructive one, which
stays disabled until the typed name matches. The copy names the student rather than a pronoun.

## Toast (Undo only)

Bottom, above the tab bar and above a footer (D49), `surface1`, `lineStrong` border, radius `radiusTile`, `shadowFloat`,
padding 12 16, text `subhead`, the quiet Undo on the right. Stays `toastStayUndo`. One at a time. Since U33 the toast carries
Undo and nothing else: every other message is in place, under its field, in its list, or the system alert
(`feedback.md`).

## Empty state

Inside the card or screen it belongs to: symbol 28 in `text3`, title `headline`, one line `subhead` `text2`,
and when there is an action, a secondary button (or primary when it is the only thing to do on the screen).
Copy says what will appear here and how.

## Loading and stale

First load with nothing cached: skeleton rows in `surface2` breathing (`breathe`), the real layout's
shape. A refresh with a cached value: the value stays at opacity 0.55 with a 16 pt spinner beside the section
title; never a blank screen. An error replaces the spinner with a `footnote` line and Retry.

## Footer button on a root

A primary button 50 that must never need a scroll (Save attendance) sits in a footer above the tab bar: 12 of
ground above it, `pageSide` beside, `tabBarInset` plus the bar below; the list scrolls under the footer's ground.
After a save it becomes a Saved mark (`okTint` fill, `ok` text with a tick, same size, not a button); a new change
turns it back into the primary ("Save changes"). Disabled when nothing changed.

## Status bar on a scrolled root (U1)

A tab root with a hidden navigation bar (Today, Students, Attendance, More) draws the system's glass edge under the
status bar once its content scrolls: `chrome` with `blurChrome`, a `lineGlass` hairline below, the safe-area height.
At rest nothing shows (P4-Today-AddingTask draws the scrolled state).

## Calendar month

Weekday initials `caption` `text3`; day numbers `subhead` 600; today in an `accent` disc with
`textOnAccent`; selected (not today) in a `surface2` disc; a day with classes or events carries a 4 pt dot
under the number in `accentText`; other months' days hidden. Month title `headline` with two chevron buttons (`chevron.left`, `chevron.right`, 18 in
`accentText`, 32 round targets), inside the calendar card on Schedule and above a list on History; the card's
padding is 12 14 10.

## Progress bar (attendance, usage)

4 high, `lineStrong` track, `ok` fill (or `accent` when it is not a status), radius 2, with the value as
text beside it.

## Percentage hero (a student's month)

A hero card: eyebrow with the month, the percentage in `numberHero` with "present" in `subhead` `text2` beside it,
the progress bar, then "2 of 3 classes · 1 absence" in `footnote` `text2`.

## Message sheet (the absence alert)

A floating sheet (D28) with Cancel and no Save: the student's avatar 56 beside "Hemanth was absent today" in
`title3` and the parent's name and number in `subhead` `text2`; a "Message" label over the text in a well (padding
14, `body`); a `footnote` `text3` line saying what happens; the primary Open WhatsApp 52 with the `whatsapp` glyph in
the footer.

## Inline add (tasks)

A well 46 with `plus` in `text3` and "Add a task" as placeholder, at the top of the Tasks screen and, on Today, as
the first row of the Tasks card when Add is tapped. Focused it takes the focus ring; under it a row of chips (the
due date as a filter chip with `calendar`, "No date" neutral) and a quiet Add (700) on the right; the section's
action reads Cancel while adding. The date chip names the chosen day ("Tomorrow", "Fri 9 Oct") and opens the system's
graphical date picker in a popover; a tap turns it on with the next weekday; No date clears it.

## Money, phone, date and time

- Money: `₹1,200`, `₹14,700`; never decimals in INR; `₹4.8k` is not used in the app (the board for
  direction B used it; Ember writes the full number).
- Phone: `+91 98765 43210` for display; stored E.164.
- Date: `Wed 7 Oct` in rows, `Wednesday 7 October` on Today, `7 Oct 2026` with the year when the month is
  not the current one.
- Time: 24-hour, `17:00`; a range `17:00–18:00` with an en dash.
- Relative: `in 25 min`, `in 2 h`, `starts now`, `ended 40 min ago`; a next class on another day says the
  day (`tomorrow`, `on Monday`).
- A day column in a row: `Wed` over `7 Oct` (history), `Sat 10` alone when the row is an event (coming up).

## Phase 5 parts (step 0.6, approved 2026-10-08)

**Money pair hero (Fees, Reports, a student's fees):** the Kit's hero card: Outstanding in `due` over its line ("4
parents"), Collected in `ok` over its line ("6 of 10 paid"), `displayCompact` numbers, a `line` rule between.

**Fee row** (the Kit's, settled): name `rowTitle`; a second line `footnote` `text2` that reads the parent's name and
number on a due row ("Ramesh Kumar · +91 98848 43831"), "Reminded Tue 6 Oct" in `ok` with a tick once a reminder was
opened, "Paid by UPI on 4 Oct" on a paid row, "Waived · <reason>" on a waived row; on the right the amount `numberRow`
over a compact chip (Paid `ok`, Due `due`, Overdue `overdue`, Waived neutral); a due or overdue row carries a second
line of two 44 pt buttons, radius 14: Remind (secondary, `bell`) and Mark paid (primary, `checkmark`). In All, due rows
come first, then paid, then waived, each group by name. The row does not press, its name included. The same row lists a student's months on their fees screen
(the month as the title) and this month on the student detail.

**As built (session 11):** the boards' money pair draws its numbers white through a CSS typo in their source; the
numbers are `due` and `ok` as written here. A past month's Outstanding line reads "1 parent, overdue". The on-sheet
row's label is 15 600 (700 for the total), as P5-Generate draws. On the fee sheets the toast sits above the footer
button.

**Overdue banner (Fees, the current month):** the Banner pattern in `overdue` with `exclamationmark.circle` and a
chevron: "₹1,000 overdue from September · 1 parent"; tapping moves the month to the latest month with an overdue fee.
Hidden when nothing earlier is due.

**Payee card (Fees):** a compact card: "Parents are told to pay <upi id>" `rowTitle`, "Reminders carry this UPI id.
Not right? Change it." `footnote` `text2`, then two 44 pt buttons: Change (secondary, opens Parent payments) and That's
right (primary, `checkmark`; sets the confirmation). With no UPI id at all the card is the empty-row pattern "No UPI id
yet" with a quiet Add. Shown until confirmed once; shown again when the id changes.

**Ledger section header (Fees):** "10 fees" / "4 due" / "6 paid" with the quiet action Generate on the right.

**Generate sheet (floating, D28, content height):** Cancel and the title "Generate fees"; an eyebrow with the month,
`title2` "10 fees will be created", a `subhead` `text2` line; an on-sheet card of rows (a class with its student count
and its total, "No class", then the total row in 700); a `footnote`; the primary "Create 10 fees" 52 in the footer.
When nothing is missing: "Everyone has a fee for October", the one total row, the primary disabled and reading
"Nothing to create".

**Mark paid sheet (floating, content height):** Cancel and "Mark paid"; the student line (avatar 40, name, "₹1,000 for
October"); "Paid by" over a three-segment control UPI | Cash | Other; "Paid on" over a tile picker ("Day · Today, 7
Oct") that opens the system date picker in a popover, today and earlier; a `footnote` about the receipt; above the
footer a quiet "Waive this fee instead"; the primary "Mark ₹1,000 paid" with `checkmark`.

**Waive sheet (floating, content height):** Cancel and "Waive this fee"; the student line; "Reason" over a multiline
well (200 characters, the counter); a `footnote` ("A waived fee counts as settled, not collected. You can still mark it
paid later."); the primary "Waive ₹800", disabled until a reason is typed.

**Message sheets (the reminder and the receipt):** the Phase 4 message sheet. Remind: "Remind the parent"; the avatar
56 beside "Hemanth's October fee is due" `title3` and "Lakshmi Reddy · +91 93802 60871"; "Message" over the text in a
well; the footnote "Opens WhatsApp with the message ready to send. We note the date on the fee. The text is copied too,
in case WhatsApp can't open."; Open WhatsApp. Receipt: "Send a receipt"; "Dev's fee is paid"; "Receipt" over the text;
"Opens WhatsApp with the receipt ready to send. We note it on the fee."

The parent-facing texts (plain, polite, the child, the month, the amount, the UPI id or link at the end; the tutor's
name and the centre as the signature):

| Message | Text |
|---|---|
| Reminder | "Hello Lakshmi, Hemanth's fee of ₹1,200 for October is due. You can pay by UPI to meera@okhdfcbank. Thank you." With a payment link as well: "… to meera@okhdfcbank or through this link: <link>." With no UPI id and no link the second sentence is left out. |
| Receipt | "Hello Ramesh, received ₹1,000 by UPI on 7 Oct for Dev's October fee. Thank you." ("by cash", or "on 7 Oct" alone for other.) |
| Signature | A blank line, then the tutor's name and the centre's name on their own lines (as the absence alert). |

**Toast after Mark paid:** "Dev's fee marked paid by UPI." with Undo (the Kit's toast); the row has already moved and
the hero rolled.

**Parent payments (pushed; from Settings and from Fees' Payments):** the nav row with Back; "UPI" with the Saved mark
on the right once saved; a card (padding 16): the UPI id field (`yourname@bank` placeholder, 600) with the helper
"Reminders tell parents to pay this id." ("Read from the QR. Edit it if it is not right." after a scan), the QR row when
one is kept (a 56 pt thumbnail, "QR from your UPI app", "Kept on this iPhone to show a parent.", a quiet Remove in
`overdue`), then two secondary buttons Scan a QR (`camera`) and From Photos (`photo.on.rectangle`); "Payment link" with
its optional field and the helper "Added to reminders when set, for parents who pay by a link."; "Receipts" with one
switch row "Offer a receipt after Mark paid" and its line. Saves as you go, as Settings does.

**Student detail, Fees:** this month's fee row with its buttons when due; See all opens the student's fees (pushed,
"Hemanth's fees"): the money pair for the months with a fee, then one row per month, newest first (a waived month
offers Mark paid alone across the row, D34), and a footnote
("Months before Hemanth joined have no fee. A month's fee is made when you generate that month.").

**Reports (pushed from More):** the nav row with Back and the quiet Share on the right; the month header; a
two-segment control Fees | Attendance. Fees: the money pair ("4 of 10 due" · "6 of 10 paid") and a card of report
rows (name over the class, the amount, the compact chip). Attendance: the percentage hero for the whole month
("79% present", the bar, "19 of 24 marks · 5 classes marked") and a card of rows: name over "3 present · 1 absent"
(present in `ok` 600, absent in `overdue` 600 when more than none), the percentage `numberRow` on the right; a student
with no class marked reads "No class, nothing marked" with an en dash. A month with nothing: the empty row ("Nothing
for November yet").

**Share as CSV (floating sheet, content height):** a `subhead` `text2` line, two choice cards on `surface2` (the
selected one with the `accent` border and `haloFocus` and a tick in `accentText`; the other a 24 pt ring), each with
the file name and its columns: fees-2026-10.csv (Student, class, amount, status, paid on, paid by, reminded on) and
attendance-2026-10.csv (Student, class, present, absent, percentage); the primary "Share fees-2026-10.csv" with
`square.and.arrow.up` opens the system share sheet (not drawn).

**More and Settings:** Reports is a live row on More (Organise); Settings' later card becomes "Payments and later
builds" with Parent payments live (value "UPI", chevron) over the Phase 7 row.

## Phase 6 parts (step 0.7, approved 2026-10-08)

**Tool row (AI Assistant):** the Class row's shape: an icon tile 40 (`doc.text` paper, `list.bullet` homework,
`pencil.line` worksheet, `text.bubble` note), the title `rowTitle`, one `footnote` `text2` line, a chevron.

**History row:** the same row for a result: the icon tile of its kind, the topic (or the student's name) as the title,
"Question paper · Class 10 Maths · Tue 6 Oct" as the line. On the home, three under "Recent" with See all; in History,
grouped under an eyebrow per month.

**Create row (Today):** a compact card: the `sparkles` tile, "Create with AI", "A paper, homework, a worksheet or a
progress note", a chevron; the last section of Today.

**Form screen (pushed):** the nav row with Back; one form card (padding 16, gap 14) of tile pickers (Class, Student,
Questions, Marks: label left, value in `accentText` with `chevron.up.chevron.down`; numbers open a wheel in a popover,
the class and the student a sheet), wells (Subject, Topic), a labelled segmented control (Level, Tone), a multiline well
with its counter (observations 2000), a switch row (Answer key at the end); a `footnote` under the card; the primary 50
with `sparkles` in the footer band (12 of ground above, 50 below), disabled until the form is valid.

**Student picker (a floating sheet, D28, large):** Cancel and "Student"; the search well; an on-sheet card of student
rows (avatar 40, name, class line) with the chosen one ticked in `accentText` and a 24 pt ring on the others; one choice
closes the sheet.

**Creating card:** a hero card (padding 16, radius 18): `rowHeading` "Writing 10 questions on Quadratic equations"
with a quiet Cancel on the right, three to four skeleton bars breathing, the `footnote` "Usually under a minute. You
can wait here or come back from History." Shown with the form at the disabled opacity and the footer button loading.
Scan and check use the same card with a thumbnail of the photo on the left: "Reading the register · Usually under a
minute.", "Checking 2 pages · Against Quadratic equations · 20 marks. Usually a minute or two."

**Error row:** a list card with one row: `exclamationmark.circle` 24 in `overdue`, a `rowHeading` ("Couldn't create the
paper."), a `rowLine` in `text2` ("Check your connection and try again. Nothing was used up."), a quiet Retry 700 on the
right. The limit failure reads "You've made today's 40. Try again tomorrow." without Retry.

**Result hero:** a hero card: the eyebrow ("Class 10 Maths · Mathematics"; "Hemanth Reddy · Quadratic equations"), the
title `title2`, a `footnote` `text2` line ("10 questions · 20 marks · Medium · created today, 18:32").

**Paper card:** a list card of section rows (`surface2`, the title 15 700 and "1 mark each" `footnote` `text2`) and
question rows (the number in a 24 pt column `text2` 600, the text `subhead`, the marks `footnote` `text3` on the right).
The answer key is the last section. Homework and worksheets use the same card without marks.

**Result footer:** the footer band holding the AI line (`footnote` `text3`), a centred quiet action (Create again;
Write again on a note), then two secondary 46 buttons: Copy (`doc.on.doc`) and Share as PDF (`square.and.arrow.up`). On
a note the row is Copy and Write again over the primary Send on WhatsApp (`whatsapp` glyph). Creating again: the content
at 0.55, a 16 pt spinner with "Creating again" by the section title, the buttons disabled, the quiet replaced by "A new
paper is on its way. This one stays until it arrives."

**Note well:** the Phase 3 multiline well, min 220 high, holding the note for editing; the helper "Edit anything before
it goes. Tap Write again for a fresh draft."

**Intro hero:** a hero card (padding 24) with the feature tile 56 (`doc.viewfinder`; `doc.text.magnifyingglass`), the
title `emptyTitle` centred, the line `subhead` `text2` centred (max 300).

**Notices card:** a list card of rows with a 18 pt symbol in `text2` (`lock`, `checkmark`) and `rowLine` text.

**Consent sheet (floating, content height):** Cancel and "Before the first photo"; the text in `subhead` `text2`; the
`footnote` "Asked once for Bright Minds Tuition, and recorded with the date."; the primary "I agree, continue" 52.

**Review row (the list to check):** a 24 pt checkbox (`ok` fill with the tick when ticked, a `lineStrong` ring when
not), the name `rowTitle`, the line "+91 98765 43210 · ₹1,200" `footnote` `text2`; a chevron opens Fix this row. A row
that matches a student already in the register carries the compact chip "Already here" (`due`, `exclamationmark.circle`)
beside the name, the line "Matches Dev Kumar in Class 8 Science", and starts unticked. A row with no number read has
"No number read" in `due` 600 in its line. The section title counts rows ("8 found") with the quiet action Add a row.

**Fix this row (floating, large):** the Phase 3 student form (Name, Class, Monthly fee with its helper, Parent's name,
Parent's WhatsApp number with a helper when nothing was read) with Save, and the destructive quiet "Remove this row" at
the bottom. Edits stay on the device until Add.

**Page tile (Check a paper):** a compact card (padding 10) holding the page's thumbnail, "Page 1" `footnote` `text2`,
and a 28 pt round remove mark (`xmark`) at its top right; two to a row. The Add a page tile is a dashed `lineStrong`
border, radius 16, `camera` 22 and "Add a page" in `accentText`. From Photos is the section's quiet action.

**Mark tile:** a 36 pt tile 64 wide, `surface2`, `line` border, radius 10, "2 / 4" in `accentText` 700 tabular; a tap
opens a popover (the menu's glass, 200 wide) with an eyebrow "Marks for question 4" and a row of chips 0 to the
question's marks, the current one on (`accentTint`). A changed mark adds "· Changed from 1" in `ok` 600 to the row's line
and rolls the hero total and bar.

**Mark row:** "4. Nature of the roots" `rowTitle`, the AI's note `footnote` `text2`, the mark tile on the right. The
hero: the eyebrow, the total in `numberHero` with "of 20" `subhead` `text2`, a 4 pt progress bar in `accentText`, "10
questions · 2 pages · checked today".

**Saved footer and toast (a check):** after Save the footer button becomes the Saved mark ("Saved to Hemanth's notes",
`okTint`, `ok`, the tick) and a toast "Saved to Hemanth's notes: 15 of 20 on Quadratic equations." offers Undo.

**Toasts:** "Kavya Nair removed." with Undo (the row comes back exactly, on the device); "7 students added from the
register." with Undo (deletes those rows); "Allow the camera for Tutor Central in Settings." with Open Settings.

**Dialog:** "Leave without adding?" · "The names read from the photo will be lost. Nothing has been saved." · Keep
checking (secondary), Leave (primary: reversible by scanning again, not destructive).

**System surfaces, not drawn by the app:** the camera alert ("“Tutor Central” Would Like to Access the Camera", the usage
text "To photograph your paper register and answer sheets so they can be read, and the QR of your UPI app."), the
document camera (VisionKit's `VNDocumentCameraViewController`, full screen, its own Cancel and Save; one page for the
register, up to six for a paper), the photo picker (`PhotosPicker`, one image for the register, several for a paper).

The texts:

| Text | Words |
|---|---|
| The AI line | "AI can make mistakes. Check everything before you share it." (the home); "… Check every question and answer before you share it." (a result); "… Read the note as the parent will." (a note); "… Check every name and number before you add them." (the register); "… Every mark is a suggestion until you save it." (a paper) |
| The consent | "A photo of a register or an answer sheet carries children's names and details. It is sent to our AI service (Claude, by Anthropic) only to be read. We keep no copy; the service deletes it within 30 days and never uses it for training. Make sure the parents are fine with their details being kept in Tutor Central." |
| The notices | "The photo goes to our AI service to be read. We keep no copy; the service deletes it within 30 days." (Check a paper: "The photos … deletes them within 30 days.") · "Nothing is saved until you have checked every row and tapped Add." |
| Send the note | The note as edited, a blank line, then the tutor's name and the centre's name (the absence alert's signature); the footnote "Opens WhatsApp with the note ready to send. We note the date on Hemanth's page. The text is copied too, in case WhatsApp can't open." |
| The note on a student | "7 Oct · Quadratic equations · 15 of 20 · " then the AI's summary line as edited, appended to the student's notes on its own line |

## Phase 7 parts (step 0.8, approved 2026-10-09)

**Setting row with a line:** the Setting row with a `footnote` `text2` line under the label (Parent messages); the value
stays on the right; no chevron when the row does nothing.

**Segmented row (Appearance):** the Setting row's label and symbol over a three-segment control inside the same row
(padding 14 16, 12 between); the segments never wrap (Match iPhone).

**Tile row:** a tile picker as a row of a list card: the label `body`, the value in `accentText` 600 with
`chevron.up.chevron.down`; minutes and hours open a wheel in a popover, the day of the month a wheel of 1st to 28th.

**Saved mark, saving:** the Saved mark reads "Saving" with a 14 pt spinner in `text3` while a write runs.

**Account hero:** avatar 56 beside the name `title3` and the email `subhead` `text2`.

**Method row:** the Setting row with the provider's symbol (`apple.logo`, `envelope`, `key`) and a value: "Connected"
in `ok`, "On" in `text2`, "Not set" or "Set" with a chevron.

**Destructive row:** a list-card row in `overdue` 600 with its symbol (`rectangle.portrait.and.arrow.right` for Sign
out, `trash` for Delete account permanently, the latter with a chevron).

**Delete screen:** the intro hero with its tile in `overdue`, the notices card, the typed field ("Type the centre's name
to confirm", the name as the placeholder), the solid destructive 50 (disabled until the typed name matches, loading
while it runs), a `footnote`. The error row sits above the field.

**Status banner:** the Banner with a tone: `ok` with `checkmark.circle` ("Reminders are on. Next: …"; "Saved at
17:05"), `due` with `clock` ("Saved on this iPhone at 17:05 …") or `bell.slash` ("Notifications are off …", with the
quiet Open Settings on the right), `overdue` with `exclamationmark.circle` and a chevron ("1 saved change couldn't be
sent."), `text2` with a 14 pt spinner ("Back online. Sending 3 saved changes…"). The offline bar is the `text2` one
with `wifi.slash` and the time.

**Saved here mark:** the footer's Saved mark in the `due` tone (`dueTint`, `due`, `clock`): "Saved on this iPhone".

**Dimmed cards:** a group waiting for a permission or a connection sits at opacity 0.45 (the Teacher reminders cards
before the permission and when refused).

**Wheel popover:** the Phase 6 popover (the menu's glass, 200 wide) with an eyebrow and a wheel of five visible rows 36
high, the chosen one on `surface2` in 700, the others `text3`.

**Disclosure row (Help):** `rowTitle` with `chevron.down` in `text3`; open, `chevron.up` and the answer in `rowLine`
`text2` under it. One open at a time.

**Pending row:** an icon tile 40 (`checkmark.circle` attendance, `indianrupeesign` a fee, `text.bubble` a message log),
the title `rowTitle` ("Fee · Dev Kumar"), the line with its state first in 600 ("Waiting" `text3`, "Failed" `overdue`)
then what and when; a failed row adds a second line in `overdue` with the reason and a quiet Discard in `overdue`.

**Notification (the system's, not drawn by the app):** the app icon, a title (the thing and its time) and one body line
that ends with what a tap does. The lock-screen board draws iOS's banner for reference only.

**Launch screen:** `ground` with the book from the icon (D29) at 88 pt in `accent`, centred; always dark.

The texts:

| Text | Words |
|---|---|
| A failed save on Settings | "Couldn't save the centre's name. Check your connection and try again." (your name; the WhatsApp number) |
| The methods' footnote | "Any of these signs you in to Bright Minds Tuition. The code always works; a password is optional." |
| Set a password | "At least 8 characters. You can still sign in with a code; the password is another way in." · failed: "Couldn't set the password. Check your connection and try again." · set: "Password set. Use it with your email next time you sign in." |
| Sign out | "Sign out?" · "You can sign back in with Apple, Google or your email. What Tutor Central saved on this iPhone for Bright Minds Tuition is removed." · pending: "2 saved changes haven't reached the server yet: attendance for Class 10 Maths and Dev's fee. Sign out now and they are lost. Connect first and they go on their own." with "Sign out anyway" |
| Delete account | "Delete your account permanently" · "Everything in Bright Minds Tuition goes, and your sign-in with it. There is no way back." · the notices: "10 students with their fees and attendance, 2 classes, your events, tasks, notes and everything created with AI." · "Your sign-in. Signing in again later starts a new, empty centre." · "Apple is asked to forget this app, so your Apple ID no longer lists it. You confirm with Apple first." · the footnote "Takes a moment. You are signed out when it is done." · deleting: "Removing everything. Keep the app open until it is done." · failed: "Couldn't delete your account." "Check your connection and try again. Nothing was removed; you are still signed in." · done: "Your account and Bright Minds Tuition's records were deleted." |
| Teacher reminders | "Reminders on this iPhone" · "A nudge before each class and event, and once a month about fees still due. Set on this iPhone only; parents get nothing from here." · "iOS asks once. You can change your mind any time in the iPhone's Settings." · on: "Reminders are on. Next: Class 10 Maths, today at 16:45." · all off: "Reminders are allowed, but every switch below is off." · refused: "Notifications are off for Tutor Central." with Open Settings and "Allow them under Settings → Tutor Central → Notifications, then come back here. Your switches are kept." · the rows: "Before each class" "Class 10 Maths and Class 8 Science on their days"; "Before each event" "Everything on your schedule"; "Fees still due" "Who hasn't paid this month, with the total, at 09:00" · "14 reminders set · through Fri 23 Oct" / "No reminders set" · "Reminders are set two weeks ahead and refreshed whenever you open the app or change a class, an event or a fee." |
| The notifications | "Class 10 Maths at 17:00" "In 15 minutes · 6 students. Tap to mark attendance." · "Parents' meeting in 1 hour" "Sat 10 Oct, 11:00–12:00 · Class 10 parents." · "4 fees still due for October" "₹4,000 to collect. Tap to remind parents." |
| Help | "How can we help?" · "Short answers below. For anything else, write to us; a reply usually comes within a day." · "Opens Mail with the app's version filled in, so we know what you're on." · the four questions and answers are on P7-Help-Answer and the board's source |
| Offline | "Offline. Showing what was saved at 14:10." (today) · "… saved yesterday at 18:30" · "… saved on Mon 5 Oct" · "Offline. Nothing saved on this iPhone yet." with "Nothing saved here yet" "October's fees appear once this screen has loaded with a connection." and Try again · refused: "You're offline. Adding a student needs a connection; nothing was saved." (editing a student; a class; an event; a task; a note; a fee month; a setting) · attendance: "Saved on this iPhone at 17:05. It reaches the server when you're back online." · a fee: "Paid by UPI on 7 Oct · Kept on this iPhone until you're online" and the toast "Dev's fee marked paid here. It's sent when you're back online." with Undo |
| Back online | "Back online. Sending 3 saved changes…" · "3 saved changes sent." · "1 saved change couldn't be sent." |
| Pending changes | "Saved on this iPhone while you were offline, in the order you made them." · a failure: "Dev Kumar is no longer in the register, so his fee can't be marked. Keep it here or discard it." · "Each change is sent on its own; one that fails doesn't hold up the rest. A failed change stays here until you discard it." · Discard: "Discard this change?" "Dev's October fee stays as the server has it: due. The mark you made here is lost." |

### Phase 7 as built (where the build moved from the boards, and why)

- **No technical words on screen (D41).** The approved texts that said "server" were reworded in the build: "It's sent
  when you're back online.", "haven't been sent yet", "stays as it was", "This change couldn't be saved. Keep it here or
  discard it.", and the consent "kept neither there nor by us" (since Phase 8, the owner: "We keep no copy; the service deletes it within 30 days and never uses it for training", as `/privacy` says). Pending changes' reason for a removed student uses "their",
  not "his". A failure the app cannot name reads "That didn't go through. Try again."; a backend's own message never shows.
- **Banner action.** Open Settings on the refused reminders banner is `bannerAction` (13/700, accentText), a new token.
- **Picker list row and wheel.** `PickerListRow` and `WheelPopover` (the day of the month, the leads) are DesignSystem's.
- **Dynamic Type layer.** At the five accessibility sizes rows stack (`AdaptiveRow`, `AdaptiveSpacer`, `TrailingColumn`),
  filled buttons wrap, fixed-height rows grow (`growsWithText`), drawn-height sheets open full and scroll (`boardDetents`),
  one-word titles, emails, phones and initials shrink (`singleLineTitle`); the boards' layout is kept at every other size
  (a pixel diff of 23 states). Record: `docs/design/accessibility-pass.md`.
- **Build 10 findings (the owner on the phone):** Start here's buttons are plain labels (P2-Today-Empty updated); every
  calendar is `calendarPopover` (its width, Monday first, the keyboard away as it opens); a picker tile keeps label and
  value on one line when both fit, else the value goes under the label; sheets sized to their content (New class, Sign in
  with email) keep the header pinned while the fields scroll (`FittedSheet`); a drag down puts the keyboard away
  everywhere (`scrollDismissesKeyboard(.interactively)` on the root); Add on Today's Tasks scrolls the field above the
  keyboard; New class… from the student form; Today's account picture at the top right; the opening fade.

## Phase 8 parts (step 0.9, approved 2026-10-09): the website

The site is built from the app's colour tokens and its own type scale (`information-architecture.md`, Phase 8 boards). Its parts:

**Site header:** the brand (a 28 px tile in `ground` with the book in `accent`, the wordmark 17/700) and a `nav` of three links
15/600 in `text2` (the current page in `text`), a `line` hairline under; the links drop under the brand at phone width.

**Site footer:** a `line` hairline above; the brand at 24 px, the one-line promise in `text2`, the copyright in `text3`; the three
links and the email (in `accentText`) on the right, under the brand at phone width.

**Page title:** an eyebrow 15/600 in `accentText` naming the page, the title (44/50; 34/40 at phone width), a lead 19/29 in `text2`,
at most 720 px wide.

**Prose:** h2 28/34, h3 20/27 600, body 17/27 in `text2` on `ground`, links in `accentText` underlined (offset 3, thickness 1), at most
680 px wide; sections 40 px apart.

**List card (web):** `surface1`, `line` border, radius 20, `shadowRaised`; rows 20 × 22 with a `line` divider: a feature row has a
44 px tile in `surface2` with the symbol in `accentText`, the title 18/24 600 and the line 16/24 `text2`; a question row the question
18/24 600 over the answer 16/24 `text2`.

**Plain row:** a title 18/24 600 over a line 16/24 `text2`, in two or three columns of the section (one at phone width).

**Buttons:** the primary 52 high, radius 15, `accent` fill, `accentInk` 16/700, `shadowPrimary`; the secondary 52 high, `buttonFill`
with a `lineStrong` border, 16/600, `shadowButton`; both carry a 20 px symbol on the left.

**Hero:** two columns (text, then the phone) 72 px apart, stacked at phone width; `glowHero` as a 920 × 620 radial behind, from the
top; the phone an iPhone shape (radius 48, a `surface1` and `lineStrong` rim, the Today board scaled to 0.78, 0.7 at phone width).

**App Store badge (a stand-in):** 52 high, black with a #A6A6A6 rim, Apple's mark and "Download on the App Store"; the real page uses
Apple's badge artwork from its marketing tools, never this drawing.

**Keyboard (boards only):** a stand-in for the system keyboard, 336 high, `well` with keys in `buttonFill`; drawn only where a
state is defined by the keyboard being up (P8-Event-Edit-Keyboard).

The texts are on the boards' sources; `/privacy` and `/terms` are the owner's once he fills the `[OWNER: …]` placeholders and
reviews the claims table in `information-architecture.md`.

## Phase 10 parts (step 10.1, approved 2026-10-10): the shell

**Tab bar, five tabs:** Today `sun.max`, Students `person.2`, School `building.columns`, Fees `indianrupeesign`, More `ellipsis`;
everything else as the Kit's tab bar. Attendance is no longer a tab (D65).

**More's rows:** the Setting row with its symbol: Schedule `calendar`, Attendance `checkmark.circle`, Tasks `checklist`, Classes
`book.closed`, Reports `chart.bar`; Make something `sparkles`, Check a paper `doc.text.magnifyingglass`, Scan register
`doc.viewfinder`; Settings `gearshape`, Account `person.crop.circle`, Help `questionmark.circle`.

**Empty card with two buttons (the School tab):** the empty-state pattern inside a list card (symbol 28 `text3`, `headline`,
`subhead` `text2` at most 280 wide), then the primary 50 and a secondary 46 at the card's full width minus its padding, 10 apart,
8 under the line; the card's padding 28 20 20. Buttons carry plain labels, no symbol (the owner, 2026-10-08).

**Footer band on a pushed screen (Attendance under More):** the Phase 6 form footer: a band of `ground` 130 high at the bottom,
the primary 50 at 50 above the bottom edge (the safe area), `pageSide` beside; the content scrolls under it. After a save the
button becomes the Saved mark as on the root.

## Phase 10 parts (step 10.2, approved 2026-10-10): Students

**Status word:** the tracking status as a word in its colour, `footnote` 600: On track `ok`, Watch `due`, Not on track `overdue`,
Not known yet `text3`. On a student row it leads the second line ("Watch · Class 10 Maths"); on the tracking card it is the
title with its symbol (`checkmark.circle`, `clock`, `exclamationmark.circle`, `circle`).

**Tracking card:** a compact hero (padding 16, radius 18): the status word 17/700 with its symbol 20 and "since <day>" `caption`
`text3` on the right; the reasons `rowLine` `text2`; a `line` rule; the eyebrow "Next" over the step in `rowLine` `text`, the quiet
Change (or Place <name>) on the right.

**Picker tile with a helper:** the Phase 3 tile picker (46 high, `surface2`) with a `footnote` `text3` line under it; a tile not
yet chosen shows its placeholder in `text3` ("Choose", "Choose or add", "No batch yet").

**Chip row in a form:** the Phase 3 gender chips, with a label above and an optional helper under, for the parent's message
language (English, Hinglish, Hindi, Kannada).

**Choice row on a sheet:** the student picker's row with a leading icon tile (`building.columns`) and a count line; the last row
holds a field (Add a school, Add a skill) with `plus` in `accentText`.

**Chapter row:** a 20 pt position column `time` `text2`, the chapter name `rowTitle`, a line of its skill states (`4 of 4 secure`),
`chevron.down` in `text3`; open, the row sits on `surface2` with `chevron.up` and its skills follow.

**Skill row:** indented under its chapter (padding 10 16 10 44): the skill `subhead`, an optional `caption` `text3` line (when it was
checked), the state mark on the right.

**State mark:** symbol 16 and the word in `caption` 600: Secure `ok` `checkmark.circle`, Practising `due` `clock`, Taught `text2`
`circle`, Revisit `overdue` `exclamationmark.circle`, Not started `text3` `circle`.

**Subject head:** the first row of a subject's card: the subject 15/700 over its line (`14 chapters from the book · 3 taught`),
a quiet action on the right (Add a chapter, Add the book).

**Trend card:** a compact card: the title and the percentage `numberRow`; twelve bars 36 high, radius 3, 4 apart, on `lineStrong`
tracks, each filled to its session's right answers of three (`ok` 3, `due` 2, `overdue` 1 or 0); a `footnote` `text2` line.

**Ladder:** a row per skill area (Reading, Writing, Numbers): the title `rowTitle` and the current step's line on the right; five
cells, each a 6 pt bar (radius 3) over its name in 11/14: secure steps `ok`, the current step `accent` with its name in
`accentText` 700, the rest `lineStrong` and `text3`.

**Mark row:** the test `rowTitle`, the school and date `footnote`, the score `numberRow`, a compact chip when below the usual
(`due`, `clock`).

**Check row:** an eyebrow with the skill `caption` `text2`, the question `subhead`, then the expected answer `footnote` `text3` on the
left and the Right | Wrong pair on the right: a `well` track 150 wide, radius 13, padding 3, two segments 34 high, radius 10;
Right on is `ok` fill with `okInk`, Wrong on is `overdue` fill with `overdueInk`, off segments `text2` 600. Untapped is neither.

**Consent section:** a list card with one row in three states (`information-architecture.md`); the agreed row carries
`checkmark.circle` 22 in `ok` and the quiet Change; the other two carry two buttons 44 high (the fee row's) under the line: Ask on
WhatsApp (secondary, a plain label) and Parent agreed (primary, `checkmark`).

**Creating card with a photo:** the Phase 6 creating card with a 56 × 72 thumbnail on the left.

The texts:

| Text | Words |
|---|---|
| The consent message | "Hello <parent first name>, I use Tutor Central to plan <child>'s classes and keep her progress. To prepare her practice sheets and your weekly note, her name, class, marks and work may be read by an AI service (Claude, by Anthropic). It keeps nothing for training and deletes what it reads within 30 days. Please reply YES if you agree. Thank you." then the tutor's name and the centre (the absence alert's signature); "his" for a boy, "their" when the gender is not set |
| The ask's footnote | "Opens WhatsApp with the message ready to send. We note the day you asked on <child>'s page; record the reply when it comes. The text is copied too, in case WhatsApp can't open." |
| Consent, not recorded | "Not recorded yet" · "Before <child>'s own work, marks or name go to the AI service, her parent agrees once: in person, on a call or on WhatsApp. Note it here." · Ask on WhatsApp · Parent agreed · the footnote "Asking on WhatsApp is optional: it sends a message you can read first. Either way, only the day, the number and how are kept." |
| Consent, waiting | "Asked <parent> on <day>" · "Waiting for her reply. <child>'s own notes and marking wait too; sheets and sets do not." · Ask again · Parent agreed |
| Consent, agreed | "<parent> agreed" · "<day> · <number> · in person" (or "on a call", "her reply on WhatsApp") · Change · the footnote "<child>'s name, marks and work go to the AI service only for his own material and notes. Export or delete everything about him from Edit." |
| Parent agreed (the sheet) | "<parent> agreed" · "<child>'s parent" · How (chips: In person, On a call, On WhatsApp) · Agreed on (a day tile, today or earlier) · Parent's number (editable) · "Kept with <child>'s record: the day, the number and how. From now her own notes, marking and messages can be made. You can change or remove this any time." · Record it |
| Not known yet | "<child> joined on <day>. Her first week's checks show where she stands; a placement shows it sooner." · Next: "Start with the class's first chapter until the checks say otherwise." · Place <child> |
| Add a textbook | "Photograph the contents page" · "Open <child>'s <subject> book at its contents page and take a photo. We read the chapter names into a list you check." · the subject tile's helper "<school>, class <n>. <child>'s classmates there get the same chapters." · the notices "The photo goes to our AI service to be read. We keep no copy; the service deletes it within 30 days." "Only the chapter names are kept, nothing from inside the book." "Nothing is saved until you have checked the list and tapped Keep." · "AI can make mistakes. Check every chapter before you keep them." |
| Reading | "Reading the contents page" · "Usually under a minute. <subject> · <school> · class <n>" |
| The chapters | "<n> chapters read" with Add a chapter · each row "<k> skills read" · "Keep <n> chapters" · "Open a chapter to change its name or skills, or remove it. Nothing is kept until you tap Keep." |
| A chapter | "Chapter <k>" · Chapter (the name) · "Skills, <n>" · "What the plan teaches and checks, one at a time, in this order." · Remove this chapter |
| The placement | "A few questions per subject, so the plan starts at the right place. Ask them in your words and tap what <child> answers. Skip any you don't ask." · "<n> of <m> right" beside each subject · Done · "Done keeps what you tapped. <child>'s chapters start from the first skill she got wrong in each subject." |
| The school sheet | "One textbook photo per school and class serves everyone there. From class 8 the board is asked on the form." |
| The form's helpers | Class: "LKG to class 10. The plan and the sheets follow it." · Board: "Shown from class 8. The chapters follow the board's list." · Fee: "Leave empty to use the batch fee once a batch is chosen." / "The batch fee is ₹1,200. This student pays this amount instead." · Language: "Notes to <parent> are written in this language, with English beside them for you." |
