# Accessibility pass (Phase 7, Task 18)

The record of the pass: every screen at `accessibility-extra-large`, what reflowed, what was fixed, and the controls
VoiceOver now reads differently. The pictures are in the hardening pull request.

## How it was run

`xcrun simctl ui booted content_size accessibility-extra-large`, then `bun shots <state> --appearance dark` for today,
students, student, student-new-filled, fees, fees-mark-paid, attendance, attendance-saved, history, schedule, event-new,
tasks, more, settings, account, delete-account, reminders, help, pending, ai-assistant, ai-paper, ai-result-paper,
check-result, scan-review, signin, signin-email and onboarding. Afterwards the size was set back to `large`.

The default size was proven unchanged by shooting 23 states from the code before the pass and after it, then comparing
the pixels below the status bar and above the tab bar. No layout moved. The only differences are sub-pixel
anti-aliasing on some button labels, where the label's line limit is now read from the text size.

## The rule

Nothing truncates and no word breaks in the middle. At the five accessibility sizes (`TypeSizeLayout.stacks`):

- A row stacks: its trailing value goes under its title, left-aligned (`AdaptiveRow`, `AdaptiveSpacer`,
  `TrailingColumn`).
- A pair of buttons stacks, one over the other.
- A fixed-height row grows (`growsWithText`).
- A filled button wraps its label and grows.
- A sheet opens full and scrolls (`boardDetents`).
- A one-word root title, an email address or a phone number stays on one line and shrinks (`singleLineTitle`).

At every other size, the boards' layout is kept exactly.

## What was found and fixed

| Where | Found at accessibility-extra-large | Fix |
|---|---|---|
| Every row with a trailing value (Settings, Account's methods, reminders, students, fees, history, a student's contact and month fee, the absent rows) | Titles broke mid-word ("Passwor d", "Stude nts"); values truncated ("Class 1…") | `AdaptiveRow`: the value goes under the title |
| Picker tiles and lines (a paper's class, Attendance's date and class, Mark paid's day, an event's day and times) | Values truncated ("Today, 7 O…", "St… 11…") | `TileRow`, `PickerLine`, `PickerListRow`, the form picker: stack and grow |
| Back rows with an action (AI Assistant, Suggested marks, a student) and sheet headers (New event, New student, Sign in with email) | The title ran under the action ("AI AssistanHistory", "CanceNew event") | `BackRow`, `SheetHeader`: the title goes on its own lines under the buttons. A student's detail now uses `BackRow`, not its own copy |
| Section headers with an action ("Questions · Tap a mark to change it") | Broke and overlapped | `SectionHeader` stacks |
| Root titles (Attendance, Students, Fees, More) | "Attendanc / e" | `singleLineTitle()` |
| Today's three tiles | "Stude / nts", "Classe / s today" | They stack, full width |
| The money pair (Fees, a student's fees) | "OUTSTAN / DING" | One half over the other |
| Attendance's count line | "6 / students", "presen / t" | Counts stay whole; the row stacks |
| The attendance pill | "Pres…" | At least 96 × 40; wider and taller with its word |
| Filled and landing buttons ("Save to Hemanth's notes", "Continue with Google", "WhatsApp") | Truncated | The label wraps and the button grows |
| Fee buttons, Call and WhatsApp, Copy and Share | Squeezed to "Whats…" | They stack |
| Avatars | Initials became "…" | The initials shrink inside the circle |
| Segmented controls ("Medium") | "Mediu / m" | One line, shrinking |
| The calendar month | "1 / 0" | Day numbers stay on one line |
| Account's email, Help's email button, a parent's phone | "gmail.c / om", "tutorcentral.i / n" | One line, shrinking |
| A student's fee line in the header's chip row | Ran off the right edge | `FlowLayout` gives a too-wide child the row's width |
| Sheets with a drawn height (Mark paid, Waive, Remind, Generate, Export, Absence alert, Add members, Password) | Fields were squeezed; the receipt note was cut off | `boardDetents`: full height and scrolling at these sizes only (the choice follows the text size, never the keyboard) |
| The sign-in landing | "Teach more…." and the promise were cut off | The same page scrolls when it is taller than the screen |

Left as they are: a text field shows the end of a long value (Settings' "Bright Minds Tuiti…"), as fields do.
Onboarding's "Signed in as …" line keeps its middle ellipsis. Both are one line by design.

## VoiceOver

Every `Image(systemName:)` in the features and DesignSystem was checked. Each one now does one of three things:

- It sits in a labelled control: the icon buttons, Back, the month arrows, Clear, Remove page, Sort, Add.
- It is the label's icon in a `Label`.
- It is hidden.

Changed:

| Control | Before | Now |
|---|---|---|
| The tick on a chosen row (Attendance's class menu, the marking scheme, a student picker, on-sheet choices) | Read "Checkmark" inside the row | Hidden; the row says "Selected" (the trait, already there) |
| A setting row's symbol, a chip's symbol, the field error's mark, the picker chevrons, the empty state's symbol, Add a page's camera, Tell parent's glyph, the Saved tick, the toast's offline mark, the footer's tick and clock, the add-menu row symbols | Read their symbol names inside combined rows | Hidden (the words beside them say it) |
| The attendance pill | "Akshita Rao, Present, toggle" | "Akshita Rao, Present, toggle, Marks absent" |

The report rows now also stack at the accessibility sizes, as the other list rows do.

The simulator cannot speak. A tester's run with VoiceOver on a real iPhone is device test D1.
