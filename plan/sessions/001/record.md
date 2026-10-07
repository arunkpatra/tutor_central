# Session 1 (2026-10-07): scoping, specification, design through step 0.3, Phase 1 plan

Model: Claude Fable 5.1 (D17). Outcome: the project is scoped, specified and planned; Phase 0 is through step
0.3 with every step approved; Phase 1 has an implementation plan and a resume prompt. Nothing built.

## What was done, in order

1. Read all 45 reference screenshots; identified the reference app (TuitionPilot, a tuition-centre manager for
   solo tutors in India, on iOS 26 with Supabase behind it). Renamed them by function into
   `docs/reference/tuitionpilot/` with an inventory; wrote the feature contract
   `docs/reference/functional-inventory.md`.
2. Extracted the rooftop app's design discipline and session process through an agent (tokens only, three
   depths, one accent, screenshots in every PR, state and session files), not its look.
3. Two rounds of questions became D1 to D6; the design was presented in seven sections and approved whole.
   Wrote `docs/spec.md`, `plan/` (README with D1 to D19, STATE, SESSIONS, eight phase scope files), root
   `CLAUDE.md`, `README.md`, `.gitignore`.
4. Phase 0 plan (`phase-00-plan.md`). Step 0.1: three directions on the canvas
   (https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D), A Ember chosen, name kept (D20). Step 0.2: tokens,
   components, guidelines, four Kit boards; approved. Step 0.3: nine Phase 2 boards and
   `information-architecture.md`; approved.
5. Phase 1 implementation plan (`phase-01-plan.md`, writing-plans skill): nine tasks, four PRs, tests first.
   The owner chose native execution in a fresh Opus 5.5 session; resume prompt `resume/001`.

## Why things are as they are

- **Supabase-direct (D5)** over a backend-for-frontend: one native client, RLS as the security floor, the
  least code between a tap and the database. The Hono API exists only where a secret or heavy logic is needed.
- **iOS 26 minimum (D1):** the reference already runs on iOS 26; Liquid Glass and the newest SwiftUI are the
  straightest path to a native gold-class feel; TestFlight-only distribution makes reach a non-issue.
- **WhatsApp deep links (D3):** zero cost, no Meta approval, day one. Server-sent messages later.
- **Subscriptions deferred (D4):** the owner's call. No limits in the model; a plans phase can be added later.
- **Foundation beside design (D6):** speed; plumbing shows nothing on screen.
- **Ember (D20):** the owner's pick among three honest options. SF Pro only means Dynamic Type for free; the
  marigold is in the same family as the rooftop app's amber, which the owner accepted knowingly.
- **No UI test suites (D15):** the owner's explicit wish; screens are proven by screenshots in PRs.
- **XcodeGen (D9)** over Tuist: lighter, one YAML, enough for one app and one package.
- **Today, not Home; a student detail hub:** two deliberate departures from the reference's IA, in the spec.
- **Three A-board colours lifted** (captions and two status colours in light) to clear 4.5:1 contrast after the
  direction was chosen; the tokens document carries the corrected values.

## Tried and dropped

- Asking questions strictly one at a time: batched into two rounds because the owner asked for speed and had
  supplied most constraints.
- Direction C with a coral accent: coral collided with the overdue colour; C went to cobalt.
- Writing light boards by hand: derived from the dark markup by variable substitution instead, so both
  appearances share one structure.

## Machine

Xcode 27.0 (27A266a), Swift 6.4, iOS 26.4 and 18.6 simulator runtimes, iPhone 17 Pro booted and attached to
the session; bun 1.3.11, node 22, vercel CLI, gh (arunkpatra), brew, mint. Missing until Phase 1: xcodegen,
swiftformat, swiftlint, xcbeautify, supabase CLI; Docker unknown.

## Next

Phase 1 in a fresh Opus 5.5 session from `resume/001`. Design continues with step 0.4 (Students and classes
boards) in a Fable session when the owner wants it; Phase 2 build needs Phase 1 merged.
