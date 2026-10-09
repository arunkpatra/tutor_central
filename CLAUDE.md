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
   branch `pr-shots` by `tools/pr-shots.ts`, embedded in the description as the table it prints. None is
   merged without. That table's links (`github.com/<repo>/blob/<pr-shots sha>/<folder>/<file>.png?raw=true`)
   render on this private repo's PR pages: the owner saw them on PR #10 (2026-10-07), so a PR page is not
   opened again to check. If a picture is ever in doubt, fetch it with the token, not a browser (the built-in
   browser is not signed in to GitHub): `curl -H "Authorization: token $(gh auth token)"
   https://raw.githubusercontent.com/arunkpatra/tutor_central/<sha>/<folder>/<file>.png` answers 200 image/png.
3. Style only through design tokens (D10). No raw colour, size, radius, shadow or duration in a view.
4. Swift 6 strict concurrency, SwiftUI only, Observation (D8). Features never import each other.
5. No AI key, no service-role key, no secret in the app or the repo (D11). The API verifies the user's JWT.
6. Row-level security on every table. Every centre table also carries `id`, `centre_id`, `created_at`,
   `updated_at`; the tenancy tables (`centres`, `centre_members`, `profiles`) are keyed by the centre and user
   themselves. A new table without a policy and a test does not merge.
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
  what you ran and what you did not. Drive the app against the local stack by `docs/runbooks/simulator.md` (its
  waits are what make taps and typing land). Before any TestFlight build that changes a write path, do that hand run
  of every write the change touches and keep the screenshots (D32).
- For setup the owner must do himself (Supabase, Vercel, App Store Connect, Google, Anthropic), give one step
  at a time and check each result before the next.
- Something on screen that works but could look or read better goes on `plan/ui-polish.md` (one row, its source),
  not into the change in hand. Items are taken when the owner chooses; when your work already touches a screen with
  open items, say so and offer them.
- Decisions in `plan/README.md` are not reopened; a change gets a new number that supersedes the old.
- You may commit, push, open and merge pull requests once the check is green and rule 2 is met.

## Where things are
| Part | Path | Local rules |
|---|---|---|
| iOS app and package | `ios/` | `ios/CLAUDE.md` |
| API (Hono on Vercel) | `api/` | `api/CLAUDE.md` |
| Website, tutorcentral.in (Next.js static export on Vercel) | `web/` | `web/CLAUDE.md` |
| Database (Supabase) | `supabase/` | `supabase/CLAUDE.md` |
| Design: boards, tokens, components, guidelines | `docs/design/` | `docs/design/README.md`; messages to the tutor: `docs/design/feedback.md` |
| Reference app and the functional contract | `docs/reference/` | |
| Spec | `docs/spec.md` | |
| Plan, state, sessions, decisions | `plan/` | `plan/SESSIONS.md` |
| UI polish list: small visual and copy fixes, taken when the owner chooses | `plan/ui-polish.md` | Its "How it works" |
| Scripts: check, shots, web-shots, store-shots, pr-shots, smoke | `tools/` | `CLAUDE.md` Commands |
| Runbooks: driving the app in the simulator against the local stack | `docs/runbooks/` | `docs/runbooks/simulator.md` (D32) |
| Device tests: what a tester checks on a real iPhone (camera, WhatsApp, network, real handwriting), with a log | `docs/testing/device-tests.md` | Its "How to run" |

## Engineering standard
Production software, not a prototype. Test first where there is logic (Domain, Data, API, RLS). Small units
with one job, named for what they do. Types at every boundary. Errors handled where they can be acted on, in
words the tutor understands. No dead code, no commented-out code, no TODO without an entry in the plan. One
change per pull request, described by what it does and how it was checked.

## Commands
| Command | Use |
|---|---|
| `bun check` | Every check in order, stopping at the first failure: format, lint, ios (build and tests on the iPhone 17 simulator), tools, api, web, db. A step whose inputs have not changed since it was last green is not run, and the summary says so; `db` is skipped with a line when local Supabase is down. `--fresh` ignores the cache; `--only=a,b` runs some |
| `bun gen` | Regenerate `ios/TutorCentral.xcodeproj` from `ios/project.yml` |
| `bun shots <state> [--appearance dark\|light\|both]` | Screenshots of the app in the simulator at a launch state, both appearances by default, into `.shots/<state>/` |
| `bun web-shots [--pages /,/privacy] [--widths 1280,390] [--appearance dark\|light\|both]` | Pictures of the website's export (build it first with `bun check --only=web`) by headless Chrome, full page at 2×, into `.shots/web/` (D46) |
| `bun store-shots` | The App Store screenshots: the approved `Store-*` boards rendered with fresh simulator screens (dark, 9:41) at 1206 × 2622 JPEG into `docs/store/screenshots/` (D51); needs the `bun check` build. The listing's words are `docs/store/listing.md` |
| `bun pr-shots <folder> <file>...` | Keep a PR's screenshots on the branch `pr-shots` (never touches your working tree), print the link table |
| `cd supabase && supabase start` | The local database stack (Docker) |
| `cd api && bun run dev` | The API locally |
| `gh workflow run deploy` | Deploy `main`'s head to production: pending migrations first (D26), then the API with its smoke (D21) |
| `gh workflow run testflight` | Archive `main`'s head with cloud signing and upload it to TestFlight (D24); stops while migrations are pending |

CI (`.github/workflows/check.yml`) runs the same check on every pull request and on `main`, except a commit of
documents only (D31): iOS on the `xcode-27` image, api, web and db on Ubuntu (D22).
