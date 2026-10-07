# Phase 0 plan: Design

How `phase-00-design.md` is done. Written 2026-10-07 at the start of the phase. Ticked as it goes.

## Where boards live

One Artifacts **Design** canvas, "Tutor Central Design", holds every board as an artboard at iPhone size
(393 × 852 points). Boards are grouped by step below; each board is named `<step>/<screen>/<state>/<appearance>`.
Approved boards are mirrored into `docs/design/` (sources in `mockups/`, previews in `previews/`,
`canvas.json` with the board ids) in the same pull of documents that records the approval.

## Steps, in order

Each step ends with the owner's approval of its boards. A step is not started before the previous one is
approved, except step 2, which starts with step 1's choice.

- [x] **0.1 Directions.** (2026-10-07: A Ember, D20) Three visual directions, each as a board set: Today (dark and light), sign-in
  (dark), and a strip of core controls (primary and secondary button, stat tile, list row, segmented, switch,
  tab bar). Each direction has a name, a one-paragraph rationale, and a token sketch (surfaces, lines, text,
  accent, ok, note, type, radius). The owner chooses one, or a blend, and the brand name.
- [x] **0.2 Design system.** (approved 2026-10-07) The chosen direction worked out: tokens for both appearances (contrast checked:
  text 7:1 or better on its surface, secondary 4.5:1), the type scale on SF Pro with Dynamic Type sizes,
  spacing, radius, elevation (three depths), motion, haptics. A components board with every control in every
  state (default, pressed, disabled, focused, loading, error), the empty-state pattern, the status marks, the
  avatar, money and phone and date formats, the sheet and dialog, the toast. Written up as
  `design-tokens.md`, `components.md`, `guidelines.md`.
- [x] **0.3 Phase 2 boards.** (approved 2026-10-07) Sign-in (landing, email code request, code entry, error), onboarding, the shell
  (tab bar, both appearances), Today with every section empty, Settings minimal, the Kit.
  `information-architecture.md` written.
- [ ] **0.4 Phase 3 boards.** Students (empty, few, many, searching, filtered), "+" menu, new student (empty,
  filled, invalid), edit student, student detail, archive and delete confirmations, classes (empty, list),
  new and edit class, class detail.
- [ ] **0.5 Phase 4 boards.** Attendance mark (fresh, exceptions, saved, past date), absence alert, history
  by date and by student, schedule month and day, new and edit event, tasks on Today and under More, Today
  live (morning with a class soon, evening with nothing left, a day with no class).
- [ ] **0.6 Phase 5 boards.** Fees (before generation, all, due, paid, overdue), generate month, mark paid,
  remind and receipt (the message text), waive, UPI settings (empty, filled, QR added), payee confirmation,
  student detail fees, reports month, export.
- [ ] **0.7 Phase 6 boards.** AI Assistant home, each tool's form, generating, result, history; scan register
  intro, consent, review table, saved; check paper intro, capture, result, edited marks.
- [ ] **0.8 Phase 7 boards.** Settings full, account, delete account, notification permission, offline
  states (list from cache, write refused, queued), about, help, launch screen and app icon.

Steps 0.4 to 0.8 may be drawn just ahead of their build phase rather than all before Phase 2, so the first
screens are built sooner (D6's spirit); `STATE.md` says which are approved.

## How a board is made

- Built from the token values of the chosen direction, so a built screen's screenshot can sit beside it.
- Real content, never lorem: the seed's ten students, two classes, a month of fees and attendance.
- iOS 26 conventions: the floating glass tab bar, large titles that collapse, sheets with grabbers, 44-point
  targets, Dynamic Type at the default size, the system keyboard where a field is active.
- Both appearances for shell-level and key boards; dark for every state board.

## Checks before asking for approval

- Contrast of every text and icon colour on its surface.
- Every state in the phase file has a board.
- Copy in sentence case, no exclamation marks, no emoji, numbers formatted as the product will (₹1,200; +91
  98765 43210; 7 Oct 2026; 17:00).
- The board set is looked at as a flow, in order, before it is shown.

## Pull requests and commits

Documents only (D12): each approved step is one commit to `main` updating `docs/design/` and `STATE.md`.
