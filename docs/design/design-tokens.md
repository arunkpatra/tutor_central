# Design tokens: Ember

The values every screen is built from (D10, D20). The `DesignSystem` module holds the same tokens in Swift;
a test fails when the two differ. Both appearances are listed; dark is the hero (D13). Every colour pair below
has been checked for contrast on the surface it is meant for: body text 7:1 or better, secondary text 4.5:1 or
better, large numbers 3:1 or better.

Naming: `token` in this document is `Tokens.token` (Swift) and `--token` on a board.

## Colour

### Surfaces, from back to front

| Token | Dark | Light | Use |
|---|---|---|---|
| `ground` | #131110 | #F8F4EE | The screen behind everything |
| `surface1` | #1C1917 | #FFFFFF | Cards, rows, sheets, secondary buttons on ground |
| `surface2` | #272220 | #F1EBE2 | Tiles inside a card, selected row, pressed row, the active segment |
| `well` | #0E0C0B | #F3EEE6 | Recessed fields, the segmented track |
| `chrome` | rgba(28,25,23,.74) | rgba(255,255,255,.74) | The glass of the tab bar and of a bar over content; always with `blurChrome` |
| `dim` | rgba(8,6,5,.6) | rgba(40,30,20,.35) | Behind sheets and dialogs |

### Lines

| Token | Dark | Light | Use |
|---|---|---|---|
| `line` | #302A27 | #E8E0D5 | Card borders, dividers inside a card |
| `lineStrong` | #3D3632 | #D5CBBE | Secondary button and avatar borders, the off switch, unchecked circles |
| `lineGlass` | rgba(255,255,255,.08) | rgba(0,0,0,.06) | The edge of glass |

### Text

| Token | Dark | Light | Contrast on `surface1` | Use |
|---|---|---|---|---|
| `text` | #F6F1EA | #1F1B17 | 16:1 / 15:1 | Titles, body, values |
| `text2` | #B9AFA5 | #625A52 | 8.6:1 / 6.3:1 | Secondary lines, labels, inactive tabs |
| `text3` | #958B80 | #766D66 | 5.1:1 / 4.9:1 | Eyebrows, captions, placeholders, chevrons |
| `textOnAccent` | #221400 | #231500 | 11:1 on `accent` | Text and icons on the marigold fill |

### Accent, one only

| Token | Dark | Light | Use |
|---|---|---|---|
| `accent` | #FFAB38 | #FFAB38 | The primary button fill, the on switch, the selected day, the focus ring |
| `accentPressed` | #E6952A | #E6952A | The primary button while pressed |
| `accentText` | #FFAB38 | #A35F00 | Accent as text or icon on a surface (links, the active tab, eyebrows of the next action); 8.9:1 dark, 4.6:1 light |
| `accentTint` | rgba(255,171,56,.14) | rgba(224,138,0,.14) | The active tab pill, avatar fill, selected card wash |

### Status

Paid, due and overdue are the states of money; present and absent reuse `ok` and `overdue`. Each has a text
colour and a tint for a chip behind it. Never red for anything that is not overdue or destructive.

| Token | Dark | Light | Use |
|---|---|---|---|
| `ok` | #56D9A6 | #0F7F59 | Paid, present, saved, done |
| `okTint` | rgba(86,217,166,.14) | rgba(15,127,89,.12) | |
| `due` | #FFB84D | #A85F00 | Due this month, a pending thing |
| `dueTint` | rgba(255,184,77,.14) | rgba(168,95,0,.12) | |
| `overdue` | #FF6F61 | #D13B2C | Overdue, absent, destructive actions and their confirmations |
| `overdueTint` | rgba(255,111,97,.14) | rgba(209,59,44,.12) | |
| `neutral` | `text2` | `text2` | A chip that only names something (a class, a count) on `surface2` |

### Special

| Token | Dark | Light | Use |
|---|---|---|---|
| `appleButton` | #FFFFFF on #111111 text | #000000 on #FFFFFF text | Sign in with Apple, per Apple's guidelines; the only button not in the accent |
| `homeIndicator` | `text` at 50% | `text` at 50% | Boards only; the device draws the real one |
| `glowHero` | rgba(255,171,56,.18) | rgba(255,171,56,.18) | The radial glow behind sign-in and the email sheet: 460 × 380 at 90% −8%, fading to nothing at 70% |
| `glowHeroSoft` | rgba(255,171,56,.14) | rgba(255,171,56,.14) | The same glow, softer, behind onboarding |
| `buttonFill` | #272220 | #FFFFFF | Secondary and icon buttons, the active segment: `surface2` in dark, `surface1` in light |
| `okInk` | #0B2A1D | #0B2A1D | Text on an `ok` fill (Present when on) |
| `overdueInk` | #2B0906 | #2B0906 | Text on an `overdue` fill (Absent when on, the Delete that confirms) |
| `onStatus` | #FFFFFF | #FFFFFF | The tick on a checked checkbox |

## Type

SF Pro through Dynamic Type text styles. Sizes below are at the default (Large) content size; every style
scales. Weights 400, 600, 700 only. Numbers always `monospacedDigit`. No other typeface (D20).

| Token | Text style | Size / line | Weight | Tracking | Use |
|---|---|---|---|---|---|
| `display` | largeTitle | 34 / 41 | 700 | -0.02em | Large titles on tab roots and onboarding; the headline of sign-in at 44 / 48, 800, -0.03em (`displayHero`) |
| `displayCompact` | largeTitle | 32 / 36 | 700 | -0.02em | The greeting on Today; the two values of a money pair in a hero card |
| `title1` | title | 28 / 34 | 700 | -0.02em | Screen titles when not large |
| `title2` | title2 | 22 / 28 | 700 | -0.015em | Card titles (the next class), sheet titles |
| `title3` | title3 | 20 / 25 | 600 | -0.01em | Section titles in a long form |
| `headline` | headline | 17 / 22 | 700 | 0 | Section headers on Today, row titles that lead a card |
| `wordmark` | headline | 17 / 22 | 700 | -0.01em | "Tutor Central" beside the logo on sign-in |
| `lead` | body | 18 / 26 | 400 | 0 | The lead paragraph under the sign-in headline |
| `intro` | callout | 16 / 22 | 400 | 0 | The line under a one-task screen's title (onboarding) |
| `emptyTitle` | title3 | 20 / 25 | 700 | 0 | The title of a card that fills a screen while its feature is on the way (P2-Later) |
| `body` | body | 17 / 22 | 400 | 0 | Body copy, form values |
| `bodyStrong` | body | 17 / 22 | 600 | 0 | Numbers and phone digits in a field, a picker's value |
| `rowTitle` | callout | 16 / 20 | 600 | 0 | The first line of a list row |
| `subhead` | subheadline | 15 / 20 | 400 | 0 | Second lines, button labels of secondary actions (600) |
| `footnote` | footnote | 13 / 18 | 400 | 0 | Captions under rows, tile labels, helper text |
| `footnoteStrong` | footnote | 13 / 18 | 600 | 0 | A student's own fee on a member row (P3-ClassDetail) |
| `caption` | caption | 12 / 16 | 400 | 0 | Legal lines, timestamps |
| `captionStrong` | caption | 12 / 16 | 600 | 0 | A status under a row's amount (Paid 3 Oct) |
| `eyebrow` | caption | 12 / 16 | 600 | +0.08em, uppercase | The date over the greeting, "Next class", section eyebrows |
| `eyebrowAccent` | caption | 12 / 16 | 700 | +0.08em, uppercase | The eyebrow of the next action, in `accentText` ("Start here") |
| `rowHeading` | callout | 16 / 20 | 700 | 0 | The title of an empty row inside a card (Today's "No classes yet") |
| `rowLine` | subheadline | 14 / 18 | 400 | 0 | The line under it |
| `tabLabel` | caption2 | 10 / 12 | 600 (700 active) | +0.01em | Tab bar labels |
| `numberTile` | title | 26 / 30 | 700 | -0.02em | The value in a stat tile |
| `numberHero` | largeTitle | 40 / 44 | 700 | -0.02em | Outstanding and collected on Fees, the total on a report |
| `numberRow` | callout | 16 / 20 | 700 | 0 | Money in a list row |
| `time` | subheadline | 14 / 18 | 600 | 0 | Times in a row's leading column |
| `button` | callout | 16 / 20 | 700 | 0 | Primary button label; 15 / 20, 600 for secondary and quiet |
| `buttonStrong` | subheadline | 15 / 20 | 700 | 0 | A primary 44 high in a row; a quiet action that commits (Save, Undo); the Delete that confirms |
| `segment` | subheadline | 14 / 18 | 600 | 0 | A segment, an attendance toggle when off |
| `segmentActive` | subheadline | 14 / 18 | 700 | 0 | The active segment, an attendance toggle when on |
| `chipLabel` | footnote | 13 / 18 | 700 | 0 | A status chip |
| `chipCompactLabel` | caption | 12 / 16 | 700 | 0 | The status chip inside a fee row (24 high) |
| `chipNeutralLabel` | footnote | 13 / 18 | 600 | 0 | A neutral chip |
| `day` | subheadline | 15 / 20 | 600 | 0 | A day number in a calendar |
| `dayToday` | subheadline | 15 / 20 | 700 | 0 | Today's number, on the accent disc |
| `avatar` | subheadline | 14 / 18 | 700 | 0 | Initials in a 40 pt avatar |
| `avatarSmall` | footnote | 13 / 18 | 700 | 0 | Initials in a 36 pt avatar |
| `avatarLarge` | title3 | 20 / 25 | 700 | 0 | Initials in a 56 pt avatar |

Rules: numbers and their unit are one run (`₹1,200`, `8 of 9`); a unit that follows a number is `footnote` in
`text2`. Sentence case everywhere. No exclamation marks. No emoji.

## Spacing

Base 4, with half steps where a control needs them. Steps in use: 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24,
28, 32, 40, 48, 62.

| Token | Value | Use |
|---|---|---|
| `inline` | 8 | Icon to label |
| `fieldGap` | 6 | Label to its field |
| `rowGapInner` | 2 | Title to subtitle inside a row |
| `tileGap` | 10 | Between stat tiles, between buttons in a row |
| `sectionGap` | 18 | Between sections on a screen |
| `sectionHeaderGap` | 10 | Section header to its card |
| `cardPadding` | 18 | Inside a hero card; 14 inside a compact card or tile |
| `rowPadding` | 14 × 16 | Vertical × horizontal inside a list row |
| `pageSide` | 20 | Screen edge to content |
| `pageTop` | 62 | Top of screen to the first content line (under the status bar) |
| `tabBarInset` | 16 × 34 | Tab bar sides × bottom |
| `contentBottom` | 120 | Scroll content's bottom inset so the last row clears the tab bar |
| `heroInset` | 24 | Screen edge to content on the sign-in landing |
| `heroTop` | 80 | Top of screen to the logo on the landing and to the eyebrow on onboarding |
| `heroLead` | 72 | The logo row to the headline on the landing |
| `groupGap` | 24 | Between the groups of a one-task screen: code entry, onboarding |
| `emptyPadding` | 40 | Top and bottom inside a card that fills a screen while its feature is on the way |
| `measureLead` | 320 | The widest a lead paragraph runs (sign-in's promise) |
| `measureLine` | 280 | The widest a centred line runs (an empty state, a card for a place on its way) |
| `rowPaddingDense` | 12 | Vertical padding of a list row of people or classes (the Kit board); horizontal stays 16 |
| `hairline` | 1 | Every border and divider |
| `iconTab` | 22 | A tab bar symbol |
| `iconButton` | 20 | A symbol in a button, a setting row, an icon tile |
| `iconSmall` | 18 | A symbol in a 46 button on a card (Today's "Add a student") |
| `iconInline` | 16 | A symbol inline with text: chevrons, a field's error mark, the offline bar |

## Radius

Radius grows with size. Nothing between 15 and 18 except where listed.

| Token | Value | Use |
|---|---|---|
| `radiusChip` | 14 | Chips, pills (height 28) |
| `radiusSegment` | 10 | A segment inside a track of 13 |
| `radiusControl` | 15 | Buttons and fields 46–52 high |
| `radiusTile` | 16 | Stat tiles, compact rows |
| `radiusCard` | 18 | List cards (rows inside) |
| `radiusHero` | 20 | The hero card |
| `radiusSheet` | 22 | Sheets (top corners) and dialogs |
| `radiusBar` | 33 | The tab bar pill; its active item 28 |
| `radiusAvatar` | half the size | Avatars, icon buttons |
| `radiusFull` | 9999 | Switches |

## Elevation

Three depths: **flat** (tiles, segments, chips), **raised** (cards, secondary buttons), **floating** (tab
bar, toasts, sheets, dialogs). Light comes from above: raised things carry a 1 px top highlight; fields are
recessed. One glow, under the primary button.

| Token | Dark | Light |
|---|---|---|
| `shadowRaised` | inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35), 0 12px 32px rgba(0,0,0,.28) | 0 1px 2px rgba(40,30,20,.05), 0 10px 28px rgba(40,30,20,.07) |
| `shadowButton` (secondary) | inset 0 1px 0 rgba(255,255,255,.06), 0 1px 2px rgba(0,0,0,.4) | 0 1px 2px rgba(40,30,20,.08) |
| `shadowPrimary` | inset 0 1px 0 rgba(255,255,255,.35), 0 8px 22px rgba(255,171,56,.28) | inset 0 1px 0 rgba(255,255,255,.4), 0 8px 22px rgba(224,138,0,.26) |
| `shadowPrimaryPressed` | inset 0 2px 4px rgba(0,0,0,.25) | inset 0 2px 4px rgba(0,0,0,.15) |
| `shadowWell` | inset 0 1px 3px rgba(0,0,0,.6) | none; `line` border only |
| `shadowSegment` (active) | inset 0 1px 0 rgba(255,255,255,.1), 0 1px 3px rgba(0,0,0,.55) | 0 1px 3px rgba(40,30,20,.14) |
| `shadowFloat` | 0 10px 30px rgba(0,0,0,.35), inset 0 1px 0 rgba(255,255,255,.06) | 0 10px 30px rgba(40,30,20,.14), inset 0 1px 0 rgba(255,255,255,.6) |
| `shadowDialog` | 0 24px 64px rgba(0,0,0,.55) | 0 24px 64px rgba(40,30,20,.2) |
| `haloFocus` | 0 0 0 3px rgba(255,171,56,.18) | 0 0 0 3px rgba(224,138,0,.16) |
| `shadowLogo` | 0 10px 26px rgba(255,171,56,.3), inset 0 1px 0 rgba(255,255,255,.4) | 0 10px 26px rgba(255,171,56,.3), inset 0 1px 0 rgba(255,255,255,.4) |
| `shadowButtonLanding` | inset 0 1px 0 rgba(255,255,255,.05), 0 1px 2px rgba(0,0,0,.35) | 0 1px 2px rgba(40,30,20,.08) |
| `blurChrome` | blur 22, saturate 1.3 | blur 22, saturate 1.3 |

Disabled: opacity 0.45 and no shadow. Stale (a value being refreshed): opacity 0.55 with a spinner beside it.
Later (a row for a feature in a later build, P2-Settings): opacity 0.6, not tappable.

## Motion

Easing `easeOut` = cubic-bezier(.2, .8, .2, 1) for every transition the system does not own. Spring for
sheets and the tab pill (iOS defaults).

| Token | Duration | Use |
|---|---|---|
| `press` | 160 ms | Press: scale 0.97 and the pressed fill; release back |
| `panel` | 240 ms | Toasts in and out, fades |
| `number` | 500 ms | A number rolling to a new value (`contentTransition(.numericText())`) |
| `breathe` | 1600 ms | Skeleton opacity 1 to 0.55, ease-in-out, repeating |
| `toastStay` | 5 s | A toast stays; 8 s when it carries an undo |

Reduced motion: every transition is removed; numbers change at once.

## Haptics

| Event | Haptic |
|---|---|
| Segment or filter changed | selection |
| Attendance mark toggled | selection |
| Saved, paid, sent | notification success |
| Destructive confirmation shown | notification warning |
| Error toast | notification error |
| Pull to refresh completes | impact light |

Off when the user turns haptics off in Settings.

## Icons

SF Symbols only, weight regular at 22 pt in the tab bar and 20 pt in buttons, medium at 16 pt inline.
Multicolour off; tinted with the text colour of their context. The boards draw stroke stand-ins; the app uses
the symbol named in `components.md`.

## Numbers in code

Values the code needs that are not visual tokens: the "in N min" threshold for "next class" is 90 min before start to
the end of the class; a task falls off Today one day after it is done; a toast with undo stays 8 s, and Undo on a
fee written to the server reverses it with a second write (Phase 5: money is written at once, never held back);
the month of fees opens on the current month; an event's note is at most 500 characters and its title 120; Today's
"Coming up" is the next seven days' events and the schedule's the next fourteen (confirmed by the owner, 2026-10-08);
a done task stays on the Tasks screen until cleared; a waive reason is at most 200 characters; a fee of a month before
the current one that is still due is overdue; the payee confirmation on Fees shows until the UPI id is confirmed once
and again whenever the id changes.Phase 6 (the AI tools): a tutor's observations for a progress note are at most 2000 characters and a typed marking
scheme 4000; an answer sheet is at most 6 pages; a photo is reduced on the iPhone to 2000 px on its long edge as a JPEG
at quality 0.7 before it is sent, so six pages stay under the API's 4.5 MB request body; a call to the AI service waits
up to 120 s before it is a failure; each centre may make 40 generations, 20 register scans and 20 paper checks a day
(the limit is in Postgres and the failure names it); a checked paper's note on a student is appended to `students.notes`
(2000 characters: when it would not fit, the save says so and offers Share instead); Undo after "Add N students" deletes
those rows and nothing else, Undo after "Saved to the student's notes" puts back the notes exactly as they were; the
consent is asked once per centre (`centres.ai_consent_at`) before the first photo, for the register and the paper alike.
