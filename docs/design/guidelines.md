# UX and visual guidelines: Ember

## Principles

1. **Now first.** Every screen answers "what do I do now" before anything else: the next class on Today,
   the due rows on Fees, the unmarked class on Attendance. Everything else is one scroll down.
2. **One tap to the parent.** Wherever a need appears (a fee due, an absence, a finished paper) the WhatsApp
   action is right there, prefilled, and logged. The tutor never retypes a number or an amount.
3. **Warm, not loud.** One accent, used for the next action and for selection. Status colours mean what they
   say and nothing else. No red except overdue and destructive.
4. **Dense where the tutor works, generous where the tutor decides.** Lists are tight; a confirmation or a
   form has room.
5. **Honest states.** A cached value stays on screen while refreshing. Offline says offline. A failure says
   what failed and what to do. Never a blank screen, never a spinner over nothing.
6. **Native.** iOS 26 patterns: large titles that collapse, sheets with detents, the glass tab bar, swipe
   actions, Dynamic Type, VoiceOver. No custom navigation.

## Copy

- Sentence case. No exclamation marks. No emoji. No jargon ("invoice" is "fee"; "session" is "class").
- Second person, present tense: "Fees due this month", "Nothing on your list".
- Buttons are verbs with an object: "Mark attendance", "Email me a code", "Remind Dev's parent". "OK",
  "Submit" and "Yes" are never used.
- Numbers in copy are digits: "8 of 9 present", "4 parents".
- Empty states say what will appear here and how: "Classes you add appear here with their meeting days."
- Errors say what happened and what to do: "Couldn't save. Check your connection and try again."
- The parent-facing WhatsApp text is plain and polite, names the child, the month and the amount, and ends
  with the UPI id or link. Its templates live in `components.md` of Phase 5's boards.

## Layout

- Content width is the screen minus `pageSide` on both sides. Cards stretch to it; nothing is centred
  except the sign-in legal line and empty-state copy.
- Sections are a header plus one card, separated by `sectionGap`. A screen has at most five sections above
  the fold.
- Scroll content ends `contentBottom` above the screen so the last row clears the tab bar.
- A screen is laid out for the iPhone 17 Pro (393 pt) and checked on the smallest iOS 26 iPhone and the
  largest; nothing is scaled, text wraps.

## States every screen has

| State | Looks like |
|---|---|
| Loading, nothing cached | Skeleton of the real layout |
| Loading, cached | The cached screen, stale values at 0.55, spinner by the section title |
| Empty | The empty-state pattern inside the card |
| Error | The last good screen plus a footnote line and Try Again; nothing loaded, the unavailable view; an action that failed, the system alert (`feedback.md`) |
| Offline | A footnote bar under the navigation bar: "Offline. Showing what was last saved."; writes refused with the system alert |
| Destructive confirmation | The dialog pattern, warning haptic |

## Accessibility

- Dynamic Type at every size: layouts reflow; rows grow; nothing truncates at accessibility sizes except a
  trailing value that can wrap below its title.
- Contrast as in `design-tokens.md`. A status always has its word, never colour alone.
- Every control is a real control with a label; icon buttons have `accessibilityLabel`s; rows read as one
  element with their value.
- Touch targets 44 or larger. Swipe actions have a visible alternative (the row's menu).
- Reduced motion removes transitions; reduced transparency makes `chrome` opaque.
- VoiceOver order follows reading order; the tab bar announces its badge counts.

## Motion and feedback

- Presses scale to 0.97 in `press`; nothing bounces.
- Numbers roll; lists animate insertions with the system's default.
- Haptics as in `design-tokens.md`; off when the user says so.
- A successful save closes its sheet; a toast only when there is something to undo (`feedback.md`, U33)
  (a reminder opened, a month generated).

## Boards

- Every board at 393 × 852 unless it is a kit board, which is as tall as it needs.
- Dark for every state board; light for shell-level and key boards.
- Built from the tokens, with real seed content, so a built screen's screenshot can sit beside its board.
- No status bar drawn; the home indicator drawn at 50% as a reminder of the safe area.
