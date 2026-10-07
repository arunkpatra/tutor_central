# Session 1 (2026-10-07): scoping and specification

Model: Claude Fable 5.1 (D17). Outcome: the project is scoped, specified and planned; nothing built.

## What was done

1. Read all 45 reference screenshots; identified the reference app (TuitionPilot, a tuition-centre manager for
   solo tutors in India, running on iOS 26 with Supabase behind it). Renamed them by function into
   `docs/reference/tuitionpilot/` with an inventory, and wrote the feature contract
   `docs/reference/functional-inventory.md`.
2. Extracted the rooftop app's design system ("Dusk") and its session process through an agent, for the
   *discipline* (tokens only, three depths, one accent, radius grows with size, calm motion, screenshots in
   every PR, state and session files), not its look.
3. Asked the owner seven questions in two rounds; answers became D1 to D6. Presented the design in seven
   sections; approved whole.
4. Wrote `docs/spec.md`, `plan/README.md` (phases, D1 to D19), `plan/STATE.md`, `plan/SESSIONS.md`, eight
   phase scope files, root `CLAUDE.md`, `README.md`, `.gitignore`.

## Why things are as they are

- **Supabase-direct (D5)** over a backend-for-frontend: one native client, RLS as the security floor, the least
  code between a tap and the database. The Hono API exists only where a secret or heavy logic is needed (AI).
- **iOS 26 minimum (D1):** the reference screenshots already run on iOS 26; Liquid Glass and the newest
  SwiftUI are the straightest path to a native gold-class feel; TestFlight-only distribution makes reach a
  non-issue for now.
- **WhatsApp deep links (D3):** zero cost, no Meta approval, works on day one; the reference's message quota
  implies server-sent messages, which are a later phase.
- **Subscriptions deferred (D4):** the owner's call. The model carries no limits; a plans phase can be added
  without reshaping tables.
- **Foundation beside design (D6):** the owner wants speed; plumbing shows nothing on screen, so it does not
  break "no board, no code".
- **XcodeGen (D9)** over Tuist: lighter, one YAML, enough for one app and one package.
- **No UI test suites (D15):** the owner's explicit wish; screens are proven by screenshots in PRs instead.

## Tried and dropped

- Asking questions strictly one at a time (the brainstorming skill's default): batched into two rounds of
  three and four because the owner asked for speed and had already supplied most constraints.

## Machine

Xcode 27.0 (27A266a), Swift 6.4, iOS 26.4 and 18.6 simulator runtimes, iPhone 17 Pro booted and attached;
bun 1.3.11, node 22, vercel CLI, gh (logged in as arunkpatra), brew, mint. Missing until Phase 1: xcodegen,
swiftformat, swiftlint, xcbeautify, supabase CLI.

## Next

Phase 0's plan file, then two or three visual directions on the canvas for the owner to choose. Phase 1's plan
beside it.
