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
| Attendance | Name | | Two toggles 96 × 40, radius 13, Present (`ok` fill, `okInk` when on) and Absent (`overdue` fill, `overdueInk` when on); off is a `lineStrong` outline in `text2` |
| Task | Circle checkbox 24 (`lineStrong` ring; `ok` fill with a tick when done) | Title (struck through when done) | Due day `footnote` `text3` |
| Setting | Symbol 20 `text2` | Label `body` | Value `body` `text2` and chevron, or a switch |
| Form field | | Label `footnote` `text2` above; value `body` in a well | |
| Member (class detail) | Avatar 40 | Name; parent phone | "Class fee" `footnote` `text2`, or the student's own fee in `footnoteStrong` `text`; chevron |
| Meeting (class detail) | Day `time` `text2`, width 46 | Date `rowTitle` ("Today, 7 October") | Time range `footnote` `text2`. Today's row sits on `surface2` with its day in `accentText` 700 |
| Checklist (add students) | Avatar 40 | Name; class line | Checkbox 24; the whole row toggles it. The card sits on `surface2` when it is inside a sheet |

A student row's second line is the class ("No class yet" when none); the parent's phone takes its place only
while no class exists yet, or when a search matched the number. The fee status under the amount reads this
month's invoice ("Paid 4 Oct" in `ok`, "Due" in `due`) and is absent when the month has no invoice yet.

A section whose feature arrives in a later build (the student detail's attendance until Phase 4) shows the
empty-row pattern at the Later opacity 0.6, with words that say what will appear and when.

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

The "+" button's menu is the system pull-down menu from the icon button; the board draws it as `chrome` glass
with `lineGlass` border, `shadowFloat`, radius `radiusTile`, 260 wide; rows 46 with the label `body` on the left
and its symbol 20 on the right: Add a student (`person.badge.plus`), Scan paper register (`doc.viewfinder`),
Create a class (`book.closed`). On iOS the system draws it.

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

## Calendar month

Weekday initials `caption` `text3`; day numbers `subhead` 600; today in an `accent` disc with
`textOnAccent`; selected (not today) in a `surface2` disc; a day with classes or events carries a 4 pt dot
under the number in `accentText`; other months' days hidden. Month title `headline` with chevron buttons.

## Progress bar (attendance, usage)

4 high, `lineStrong` track, `ok` fill (or `accent` when it is not a status), radius 2, with the value as
text beside it.

## Money, phone, date and time

- Money: `₹1,200`, `₹14,700`; never decimals in INR; `₹4.8k` is not used in the app (the board for
  direction B used it; Ember writes the full number).
- Phone: `+91 98765 43210` for display; stored E.164.
- Date: `Wed 7 Oct` in rows, `Wednesday 7 October` on Today, `7 Oct 2026` with the year when the month is
  not the current one.
- Time: 24-hour, `17:00`; a range `17:00–18:00` with an en dash.
- Relative: `in 25 min`, `in 2 h`, `starts now`, `ended 40 min ago`.
