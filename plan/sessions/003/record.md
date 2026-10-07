# Session 3 (2026-10-07): Phase 2 planned

Model: Claude Fable 5.1 (D17), from `resume/002-phase-2-plan.md`, with `superpowers:writing-plans`. Outcome:
`plan/phase-02-plan.md` approved by the owner; one missing board drawn and approved; decisions D24 and D25;
`resume/003-phase-2-build.md` for the Opus 5.5 build session. Nothing built.

## What was done, in order

1. Read the rules files, the state, the decisions, the Phase 2 scope, Phase 1 "As built", the design documents,
   every Phase 2 and Kit board source, the Phase 2 rows of the inventory, the session 2 record, the existing iOS
   code, the tools and workflows, migration 0001 and the RLS tests, and supabase-swift 2.55.3's auth API in the
   SPM checkout. Reality matched `STATE.md`; `bun check` was green (all cached).
2. Wrote the plan: 17 tasks, 9 pull requests in the order a tutor meets the app (tokens, Kit, deferred minors,
   migration 0002, sign-in, onboarding, tabs and Today, Settings, TestFlight), tests first against in-memory
   fakes, owner steps inside Tasks 9 and 16, a Review Focus of five, a self-review. Small decisions in the
   plan's own table; D24 (TestFlight lane) and D25 (tokens as Swift) numbered.
3. Found one design gap: the Email board's "Use my password instead" leads to a state no board drew. Asked the
   owner (one question); he asked for plain English first, then chose "draw it now" and approved the plan.
4. Drew `P2-Email-Password` (the sheet, and the wrong-password state in a card above it) on the canvas, row 5,
   through the Design artifact's files (`project/P2-Email-Password.dc.html` and the index); mirrored it into
   `docs/design/mockups/` and `directions/canvas.json`; added the board and the `signin-password` launch state to
   `information-architecture.md`. The owner approved the board.
5. Wrote `resume/003-phase-2-build.md`, indexed it, updated `STATE.md` and `README.md`, this record, committed
   the documents to `main` (D12).

## Why things are as they are

- **Sign-in lives in `Features/Onboarding`:** the spec's module list has no sign-in target; sign-in and
  onboarding are one journey ("getting in"), and adding a target would be a deviation from an approved list for
  no gain.
- **Google through a web OAuth client, not an iOS client:** the inventory row says `ASWebAuthenticationSession`
  through Supabase, and supabase-swift's `signInWithOAuth` does exactly that; Supabase's Google provider wants
  a web client id and secret with its own callback as the redirect. The resume prompt's "Google OAuth client for
  iOS" was corrected in the plan's owner step.
- **`create_centre` gets a third parameter in migration 0002:** onboarding asks for the tutor's name and the
  scope says one call; migration 0001 never wrote `profiles.display_name`.
- **The Today board has no AI tools row:** the board is approved as drawn and wins over the scope line; Phase 6's
  Today board draws the row.
- **The Kit is reached by a launch argument and a scheme, not a row:** a debug-only row on Settings would be a
  state the board does not show.
- **Tokens declared with the document's literal strings:** the test can then compare strings, not floats, and a
  drift is a one-line diff.
- **Four board-derived tokens added to the document:** the landing boards use a glow, 24 pt sides and 80 pt top
  that `design-tokens.md` did not name; `docs/design/README.md` says the board wins and the document is fixed.
- **Supabase's built-in mailer:** a few emails an hour; enough for the owner, not for testers. Custom SMTP is an
  owner decision, in `STATE.md`.
- **Resend cooldown 60 s, code expiry 10 minutes:** the board's words ("works for 10 minutes", "Resend in 0:24")
  and Supabase's per-address limit.

## Tried and dropped

- Deferring password sign-in to Phase 7 (would have changed an approved board by a decision): offered, the
  owner chose to draw the board now.
- A `Features/SignIn` target: dropped for the reason above.

## Machine

As session 2. supabase-swift 2.55.3 checked out under DerivedData (`signInWithIdToken`, `signInWithOAuth` with
`ASWebAuthenticationSession`, `signInWithOTP`, `verifyOTP(type: .email)`, `signIn(email:password:)`,
`authStateChanges`, `AuthError.api(message:errorCode:…)` with `otpExpired`, `invalidCredentials`,
`overEmailSendRateLimit`, `validationFailed`).

## Next

The build in a fresh Opus 5.5 session from `resume/003-phase-2-build.md`.
