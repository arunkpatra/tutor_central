# Phase 0: Design

**Status:** Every step approved: 0.1 to 0.8 (0.8 and 0.8b on 2026-10-09) and 0.9, the website (2026-10-09, 27 boards in row 11);
the Kit and the mirror are kept current as phases build. **Plan:** `phase-00-plan.md`. **Runs beside:** Phase 1 (D6).

## Goal

Every screen and every state the product has, drawn at iPhone size on one Artifacts canvas, approved by the
owner, and mirrored into `docs/design/` so a session can build any screen from the repo alone. No screen is
built without its approved board (`CLAUDE.md`, rule 2).

## Scope

1. **Identity and direction.** Two or three visual directions for the shell and the Today screen, in both
   appearances: colour world, type, depth, the one accent, the tab bar on iOS 26 glass. The owner chooses one.
   The brand name and icon are proposed here (D19).
2. **Design system.** Tokens (colour for both appearances, type scale on SF Pro with Dynamic Type, spacing,
   radius, elevation, motion), components (buttons, fields, rows, cards, stat tiles, segmented, switch, sheets,
   dialogs, toasts, empty states, status marks, avatar, money and phone formats), guidelines (principles, copy
   rules, states, accessibility, haptics).
3. **Boards, in the order the phases need them:**
   - Phase 2: sign-in, email code entry, onboarding, the shell with tabs, Today with empty states, the Kit.
   - Phase 3: students list (empty, few, many, search, filter), "+" menu, new and edit student, student detail,
     classes list, new and edit class, class detail, archive and delete confirmations.
   - Phase 4: attendance mark (all present, exceptions, saved), history by date and by student, schedule month
     and day, new event, tasks inline, Today live.
   - Phase 5: fees month view (all, due, paid, overdue), generate month, mark paid, remind and receipt flows
     (what the WhatsApp message says), UPI settings and QR, payee confirmation, reports month, export.
   - Phase 6: AI assistant home, each tool's form, generating state, result, history, scan register (intro,
     consent, camera, review table, saved), check paper (intro, capture, result, review marks).
   - Phase 7: settings, account, delete account, notification permission, offline states, about and help.
4. **States.** For each screen: empty, loading from cache, error, offline, and the destructive confirmation
   where there is one.
5. **Mirror into the repo.** `docs/design/README.md` (index, order of authority, rules), `design-tokens.md`,
   `components.md`, `guidelines.md`, `information-architecture.md`, `mockups/` (sources), `previews/` (PNGs),
   `canvas.json` (board ids on the canvas).

## How boards are made

- One artifact (HTML canvas) holds every board; each board is an iPhone frame at 393 × 852 points, one per
  state, grouped by phase. Both appearances for shell-level boards; dark for every state board, light for the
  key screens of each phase.
- Boards use the same token values the app will use, so a screenshot of the built screen can sit beside its
  board in a pull request.
- The owner approves a board set by phase. Approval is recorded in `docs/design/README.md` (date) and in
  `STATE.md`.

## Acceptance

- The owner has chosen a direction and the brand name.
- Every screen in `docs/spec.md` section 2 and every capability marked Keep or Better in
  `docs/reference/functional-inventory.md` has a board with its states, approved.
- `docs/design/` is complete and a test, once Phase 1 exists, fails when `design-tokens.md` and the token
  source in `DesignSystem` differ.

## Out of scope

iPad boards (D1). Plans and paywalls (D4). Marketing and App Store assets.

## As built

(Written when the phase ends: what exists, what deviated and why, what remains to draw.)
