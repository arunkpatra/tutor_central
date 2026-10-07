# Tutor Central: Claude Code context

A native iPhone app for tutors who run a small tuition centre: students, parents, classes, attendance, fees,
AI teaching tools. India first. Supabase behind it, a thin Hono API on Vercel for AI. The spec is
`docs/spec.md`; the plan is `plan/`; read `plan/STATE.md` first, then the phase in hand.

## Hard rules
1. **No board, no approval, no code.** A screen or state is built only to a board the owner approved on the
   design canvas and mirrored in `docs/design/`. A state without a board is designed first, approved, then
   built. Plumbing with nothing on screen may proceed (D6).
2. **Screenshots in every pull request that changes what is seen** (D7): each changed screen and state, both
   appearances where the board has both, taken in the simulator by `tools/shots.ts`, kept on the orphan
   branch `pr-shots` by `tools/pr-shots.ts`, embedded in the description, checked to show on GitHub before
   merge. None is merged without.
3. Style only through design tokens (D10). No raw colour, size, radius, shadow or duration in a view.
4. Swift 6 strict concurrency, SwiftUI only, Observation (D8). Features never import each other.
5. No AI key, no service-role key, no secret in the app or the repo (D11). The API verifies the user's JWT.
6. Row-level security on every table. A new table without a policy and a test does not merge.
7. Bun only on the TypeScript side (D16). Never npm, npx, yarn or pnpm.
8. Dependencies pinned exactly (D14). A new dependency needs a decision.
9. `bun check` before every commit. Code reaches `main` only through a pull request with a green check.
   Documents only go to `main` directly (D12), never mixed with code.
10. Nothing from the reference app is silently dropped: `docs/reference/functional-inventory.md` is the
    contract; a change there needs a numbered decision.
11. The reference screenshots and the rooftop app are references for *capability* and *discipline*. Never copy
    their layouts, colours or copy.

## Start here
`plan/STATE.md` says where the work stands and what is next. `plan/SESSIONS.md` says how a session starts,
works and ends. Update `plan/STATE.md` before you stop. A phase starts with its plan file, shown first.

## Working with the owner
- Be brief. No chatter. Decide small and medium things yourself and say what you decided. Ask only for major
  decisions, one question at a time.
- Build in logical parts and show each one. No long silent stretches.
- Verify your own work before showing it: build it, run it in the simulator, look at the screenshot. Report
  what you ran and what you did not.
- For setup the owner must do himself (Supabase, Vercel, App Store Connect, Google, Anthropic), give one step
  at a time and check each result before the next.
- Decisions in `plan/README.md` are not reopened; a change gets a new number that supersedes the old.
- You may commit, push, open and merge pull requests once the check is green and rule 2 is met.

## Where things are
| Part | Path | Local rules |
|---|---|---|
| iOS app and package | `ios/` | `ios/CLAUDE.md` (from Phase 1) |
| API (Hono on Vercel) | `api/` | `api/CLAUDE.md` (from Phase 1) |
| Database (Supabase) | `supabase/` | `supabase/CLAUDE.md` (from Phase 1) |
| Design: boards, tokens, components, guidelines | `docs/design/` | `docs/design/README.md` |
| Reference app and the functional contract | `docs/reference/` | |
| Spec | `docs/spec.md` | |
| Plan, state, sessions, decisions | `plan/` | `plan/SESSIONS.md` |
| Scripts: check, shots, generation | `tools/` | (from Phase 1) |

## Engineering standard
Production software, not a prototype. Test first where there is logic (Domain, Data, API, RLS). Small units
with one job, named for what they do. Types at every boundary. Errors handled where they can be acted on, in
words the tutor understands. No dead code, no commented-out code, no TODO without an entry in the plan. One
change per pull request, described by what it does and how it was checked.

## Commands
Until Phase 1 lands there are none. Phase 1 adds `bun check`, `bun gen` (XcodeGen and types), `bun shots`,
and documents them here and in each part's `CLAUDE.md`.
