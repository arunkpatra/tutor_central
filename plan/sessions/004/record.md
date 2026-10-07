# Session 4 (2026-10-07): Phase 2 built and on the owner's phone

Model: Claude Opus 5.5 (D17), from `resume/003-phase-2-build.md`, executing `plan/phase-02-plan.md` inline with
`superpowers:executing-plans` (a ledger of rulings kept outside the repo; the rulings are below). Outcome: PRs #9 to
#21 merged; migration 0002 in production through the new migrate job; build 0.1.0 (3) from `testflight.yml` on
the owner's iPhone, signed in with Apple. Decisions D26 to D30; Phase 8 (website) added.

## What was done, in order

1. Read the rules, state, decisions, scope, plan, design documents. `main` clean and green.
2. PR #9 tokens as Swift (D25) with the document test, proved to bite. PR #10 the Kit and every component; values
   the boards use that the document did not name became tokens. The owner confirmed pictures render on PR pages
   (now in `CLAUDE.md` rule 2, with how to check one without a browser).
3. PR #11 deferred tooling minors. PR #12 migration 0002. The owner asked why migrations were by hand: D26, the
   migrate job (#17), later fixed to read the CLI's JSON line (#20).
4. PR #13 sign-in: Domain, Data, the session gate, fixtures, the landing, email code and password. Live runs against
   the local stack found three bugs (focus lost, a second Supabase client, no keychain unsigned). The owner chose
   the bundle id `in.tutorcentral.app` (D27), iOS 26's floating sheets (D28), the website at tutorcentral.in
   (Phase 8; legal links there).
5. PR #14 onboarding (found: loose line heights, letters in the phone field). PR #15 tabs, Today with real counts,
   deep links, toasts (found: a tile wrapping "₹4,000"). PR #16 Settings.
6. PR #18 the TestFlight lane. App Store Connect needs an icon: an icon board, redrawn at the owner's word (Lucide's
   book on the Ember glow), C3 approved (D29), PR #19.
7. Owner steps, one at a time, each checked from outside: App ID and app record; Supabase Apple; Google web client
   and provider; redirect URL; email. Supabase locked the templates without custom SMTP: Resend from
   tutorcentral.in (D30), DNS at GoDaddy, a test code reached the owner. Supabase secrets; the deploy applied 0002.
8. TestFlight: run 1 failed (App Manager key cannot use cloud distribution certificates; Admin key); run 2 failed
   (the app declared iPad: PR #21, a smoke test); run 3 uploaded. Build 3 on the owner's phone.

## Why things are as they are

- **Migrations only through deploy.yml (D26):** the owner's rule; the TestFlight lane refuses a build while a
  migration is pending, so no build ships ahead of its schema; migrations stay additive while builds use them.
- **Expired codes by the store's clock:** Supabase answers wrong and expired codes alike (checked locally).
- **Code entry full screen, sheets floating (D28):** the code board draws a full screen; iOS 26 draws partial sheets
  inset with all corners round; the owner chose native.
- **Tokens for board values; anatomy constants on components:** D10 and D25 forbid raw values in views; components.md
  states the anatomy per component.
- **Simulator builds ad-hoc signed:** an unsigned build has no keychain (no session across launches).
- **One Supabase client per process:** a root re-made by SwiftUI made a second client that never saw the session.
- **Shadows through one fixed structure:** an `AnyView` per token changed a focused well's type and dropped focus.
- **Admin App Store Connect key:** App Manager cannot use cloud-managed distribution certificates.
- **Resend in Tokyo (ap-northeast-1):** the nearest region Resend offers to India.

## Rulings (executor's, recorded in the ledger)

Branches per PR in the main checkout; colour rows that are not colours skipped by the token test; the design-tokens
document among the ios step's inputs; the Kit at five launch states; StatTile built but not in the Kit; schedule and
task rows not built (no board); shadows drawn as CSS draws them; the Kit's group spacing 18 (board 22) and setting
row 14 (Kit list 12); `PUBLIC` execute on new functions revoked schema-less (0002); `otp_expired` mapped to wrong code
and upgraded by the clock; `emitLocalSessionAsInitialSession`; the fake auth's listeners behind a lock; Workspace and
CentreDraft in Domain; three placeholder roots until their tasks; SignInView gets its dependencies from AppShell;
landing buttons their own style; the `book` symbol on the landing logo; the toast host plays no haptic; code entry
pushed full screen; the `groupGap` token; fields' `showsFocus` and `autofocus`; the `intro`, `emptyTitle`,
`eyebrowAccent`, `rowHeading`, `rowLine` tokens and `emptyPadding`, `iconSmall`, `opacityLater`; tile values shrink
to fit; buttons drop side padding when two share a card; a field in error loses its halo; Settings hides the tab
bar; TabsState in AppShell; links without screens say "That opens in a later build."; the TestFlight lane's
database job.

## Deferred minors

- Text injected faster than a person types can lose digits as the phone field inserts its group space (paste and
  typing speed are fine).
- The Kit's calendar does not draw day 11 in text3 as its board does (unexplained on the board).

## Tried and dropped

- `CODE_SIGNING_ALLOWED=NO` for simulator builds (PR #11): no keychain; replaced by ad-hoc signing.
- A `.height` detent measured from the presented sheet: it grew each pass; measured from the content instead.
- The first icon board (three directions): the owner asked for Lucide's book on the Ember glow.
- Merging #20 through the API while GitHub returned 500s: the owner merged it once GitHub recovered.

## Final review

A fresh reviewer (Opus) read the merged range 6d230f0..6b8b19f. Verdict: no Critical; seven Important; with fixes.
The owner chose to fix them in this session, each test-first:

1. Offline after an hour showed sign-in (the keychain read refreshed over the network): fixed, PR #22.
2. The last session's tabs and Today outlived a sign-out (another tutor saw the old greeting): fixed, PR #22.
3. Apple's once-only name could lose a race between two lookups: fixed, PR #22 (and saved to the user's metadata).
4. A wrong code after a resend did not point at the newest email (Review Focus 3's second half): fixed, PR #22.
5. Two quick Settings edits could undo each other: separate column writes, PR #22.
6. A release build without Supabase values ran on the fakes: it now stops at launch; the lane checks, PR #22.
7. Raw sizes in feature views: DesignSystem components and two measure tokens, PR #23 (pixel-identical).

Rulings weighed by the reviewer: agreed with most; disagreed in part with three (the fake's synchronous listener
does not hold for the live repository; no caller plays the error haptic; the anatomy-constant ruling stretched to
feature views, now fixed). Declined to judge (the executor's rulings on each): pixel match to boards (covered by the
PR pictures and the owner); cold launch offline showing cached Today (Phase 7's offline work); deep links before
the gate is ready (Phase 7's notifications); multi-centre users (later phases); Settings keeping the typed value on
failure where the spec says revert (the plan settled it; the owner may want to revisit); the hand-drawn Google mark
against Google's branding rules (the owner's call before App Store review); legal pages not live (Phase 8);
Today's sections empty for a seeded centre (Phase 4).

CI for #22 and #23 could not start at first: GitHub refused the jobs for a failed payment or spending limit. The
owner fixed billing and merged both; `main`'s check is green at `88d9e02`; TestFlight run 4 uploaded build 0.1.0 (4).

## Deferred minors (from the review, for the polish slice or the phase that touches them)

- Phone field: a pasted "0091 96112 99988" is cut at 12 digits; a pasted "+91…" shows its 91 beside the label.
- Non-ASCII digits (Devanagari, "½") pass `isNumber` in the phone and code fields; accept ASCII 0-9 only.
- The resend countdown counts timer ticks; it stalls while the tutor is in Mail. Compute it from `sentAt`.
- Sign-in and onboarding keep their last message, so an identical second failure shows no toast.
- The haptics table: no error haptic on error toasts, no success haptic on "Saved".
- VoiceOver: toasts are not announced; sign-in errors appear only as toasts.
- Dynamic Type: `TypeToken.font` reads `UIFontMetrics` outside SwiftUI; a size change while running does not
  re-render, and line spacing does not scale.
- Shadows re-parse their CSS strings on every render: parse once per token before Phase 4's long lists.
- The live auth repository subscribes to state changes inside a Task (later than the fake does).
- `SessionStore.signOut()` is used only by tests; the foreground refresh can overlap `start()` at launch;
  `.needsOnboarding` is not refreshed on foreground.
- `updateCentre*`/`updateProfile` report "Saved" when RLS matched no row; Today's due total is summed on the
  device and capped by PostgREST's max rows; `isoWeekday` and the Supabase repositories have no tests (a Data
  integration test against the local stack is recommended).
- A centre name over 120 or a display name over 80 hits a check constraint and reads as "check your connection":
  limit the fields; `.other(localizedDescription)` shows developer English.
- `Fixtures.swift` repeats a doc line; the redirect URL's fallback hides a typo; `ios/App/**` (entitlements,
  assets) is not among the ios step's cache inputs.
- From the executor: text injected faster than typing can lose a digit at the phone field's group space; the
  Kit's calendar does not draw day 11 in text3.

## Next

The owner chooses: UI polish, Phase 0 step 0.4, or the website (Phase 8).
