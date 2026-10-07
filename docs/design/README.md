# Design

Phase 0 (`plan/phase-00-design.md`, how: `plan/phase-00-plan.md`) fills this folder. Until a direction is
chosen and its boards approved, **no screen is built**.

## Where the design lives

| What | Where | Use it for |
|---|---|---|
| The design canvas (live, zoomable) | https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D (private to the owner until shared) | Looking at the boards as designed; approving them |
| Direction boards, sources | `directions/*.dc.html`, index `directions/canvas.json` | Exact values: every colour, size, radius and shadow is an inline style or a variable on the board's root |
| Tokens, components, guidelines | `design-tokens.md`, `components.md`, `guidelines.md` | Exact values, each control's anatomy and states, the rules. Approved 2026-10-07 (step 0.2) |
| Information architecture | `information-architecture.md` | Written in step 0.3 |
| Kit boards (step 0.2) and approved screen boards | `mockups/` (sources), `previews/` (PNGs, from step 0.3) | `Kit-Controls-*`, `Kit-Surfaces-*` in both appearances |

## Status

| Step | Status |
|---|---|
| 0.1 Directions | Done 2026-10-07: A Ember chosen (D20). The B and C boards stay on the canvas as a record |
| 0.2 Design system | Approved by the owner 2026-10-07: four Kit boards on the canvas, `design-tokens.md`, `components.md`, `guidelines.md` |
| 0.3 Phase 2 boards | In progress |
| 0.4 to 0.8 Boards by phase | Not started |

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
