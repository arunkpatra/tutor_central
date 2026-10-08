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

## Toast

Bottom, above the tab bar, `surface1`, `lineStrong` border, radius `radiusTile`, `shadowFloat`, padding
12 16, text `subhead`, optional quiet action on the right (Undo, Retry). Stays `toastStay`. One at a time.

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
| The consent | "A photo of a register or an answer sheet carries children's names and details. It is sent to our AI service (Claude, by Anthropic) only to be read, and is not stored there or on our servers. Make sure the parents are fine with their details being kept in Tutor Central." |
| The notices | "The photo goes to our AI service to be read and is not kept, there or here." · "Nothing is saved until you have checked every row and tapped Add." |
| Send the note | The note as edited, a blank line, then the tutor's name and the centre's name (the absence alert's signature); the footnote "Opens WhatsApp with the note ready to send. We note the date on Hemanth's page. The text is copied too, in case WhatsApp can't open." |
| The note on a student | "7 Oct · Quadratic equations · 15 of 20 · " then the AI's summary line as edited, appended to the student's notes on its own line |
