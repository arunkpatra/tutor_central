# Design

Phase 0 (`plan/phase-00-design.md`, how: `plan/phase-00-plan.md`) fills this folder. Until a direction is
chosen and its boards approved, **no screen is built**. The website's pages (Phase 8) are boards too: fluid frames at
1280 and 390, rendered from one source per page and appearance.

## Where the design lives

| What | Where | Use it for |
|---|---|---|
| The design canvas (live, zoomable) | https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (private to the owner until shared) | Looking at the boards as designed; approving them |
| Direction boards, sources | `directions/*.dc.html`, index `directions/canvas.json` | Exact values: every colour, size, radius and shadow is an inline style or a variable on the board's root |
| Tokens, components, guidelines | `design-tokens.md`, `components.md`, `guidelines.md` | Exact values, each control's anatomy and states, the rules. Approved 2026-10-07 (step 0.2) |
| Information architecture | `information-architecture.md` | Entry flow, tabs and stacks, deep links, launch states, the Phase 2 board list |
| Kit boards (step 0.2) and approved screen boards | `mockups/` (sources), `previews/` (PNGs, from step 0.3) | `Kit-Controls-*`, `Kit-Surfaces-*` in both appearances; `P2-*` (Phase 2), `P3-*` (Phase 3), `P4-*` (Phase 4), `P5-*` (Phase 5), `P6-*` (Phase 6), `P7-*` (Phase 7), `P8-*` (Phase 8, the website's pages as fluid frames) |

## Status

| Step | Status |
|---|---|
| 0.1 Directions | Done 2026-10-07: A Ember chosen (D20). The B and C boards stay on the canvas as a record |
| 0.2 Design system | Approved by the owner 2026-10-07: four Kit boards on the canvas, `design-tokens.md`, `components.md`, `guidelines.md` |
| 0.3 Phase 2 boards | Approved by the owner 2026-10-07: nine boards in row 5 of the canvas plus sign-in dark from row 1; `information-architecture.md` |
| 0.4 Phase 3 boards | Approved by the owner 2026-10-08: 22 boards in row 6 of the canvas (`mockups/P3-*.dc.html`); the list and the launch states in `information-architecture.md` |
| 0.5 Phase 4 boards | Approved by the owner 2026-10-08: 27 boards in row 7 of the canvas (`mockups/P4-*.dc.html`) and the Kit's attendance row redrawn; the list, the launch states and what the boards settle in `information-architecture.md` |
| 0.6 Phase 5 boards | Approved by the owner 2026-10-08: 27 boards in row 8 of the canvas (`mockups/P5-*.dc.html`); the list, the launch states and what the boards settle in `information-architecture.md`; the new parts in `components.md` |
| 0.7 Phase 6 boards | Approved by the owner 2026-10-08: 44 boards in row 9 of the canvas (`mockups/P6-*.dc.html`); the list, the launch states and what the boards settle in `information-architecture.md`; the new parts and the texts in `components.md` |
| 0.8 Phase 7 boards | Approved by the owner 2026-10-09: 41 boards in row 10 of the canvas (`mockups/P7-*.dc.html`); the list, the launch states and what the boards settle in `information-architecture.md`; the new parts and the texts in `components.md`; the numbers in `design-tokens.md` |
| 0.9 Phase 8 boards, the website | Approved by the owner 2026-10-09: 27 boards in row 11 of the canvas (`mockups/P8-*.dc.html`): the five pages at 1280 and 390, dark and light, plus U7 and U24; the list, the web's type scale, what the boards settle and the claims table in `information-architecture.md`; the web parts in `components.md` |

## The three directions (step 0.1, decided: A)

| | A · Ember | B · Indigo | C · Ink |
|---|---|---|---|
| World | Warm charcoal ground, marigold accent | Deep night blue with a soft indigo and lime atmosphere, lime accent | Neutral graphite, cobalt accent |
| Type | SF Pro only, tight tracking; native Dynamic Type everywhere | Sora for titles and labels, SF Pro body, SF Mono for times and money | Instrument Serif for titles and lead numbers, SF Pro body |
| Depth | Raised cards with a top highlight, one marigold glow under the primary action | Glass cards over the atmosphere, blur everywhere, larger radii | Hairline rules instead of cards where a list is a list; one card for the next class |
| Radius | 15 controls, 18 rows, 20 cards | 18 controls, 22 rows, 26 cards | 12 controls, 16 cards |
| Status colours | Paid mint, due amber, overdue coral (same in all three, with light-mode variants) | | |

Order of authority once approved: the owner's decisions in `plan/README.md`, then the boards, then these
documents. If a document and a board disagree, the board wins and the document is fixed in the same commit.
A board's numbers, names, counts and dates are illustrative: the board settles the design, not the data. Where the
data or a rule gives another figure, the screen follows the data and the board is not redrawn (the owner, 2026-10-08).
