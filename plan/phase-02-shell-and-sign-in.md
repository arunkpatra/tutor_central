# Phase 2: Design system, shell, sign-in, onboarding, first TestFlight

**Status:** Not started. **Depends on:** Phase 0 direction and its Phase 2 boards approved; Phase 1 merged.

## Goal

The app a tutor can install from TestFlight: sign in with Apple, Google or an email code, tell us their name
and centre, and land on a Today screen with honest empty states and five working tabs. Everything on screen is
built from the design system, to the boards.

## Scope

1. **Design system in code.** `DesignSystem`: tokens as Swift (colour for both appearances through asset
   catalog colours or dynamic colours, type styles on SF Pro with Dynamic Type, spacing, radius, elevation,
   motion), every component on the Phase 0 component boards with previews, and a Kit screen reachable in
   debug builds that shows every component in every state. A test fails when `docs/design/design-tokens.md`
   and the token source differ.
2. **Shell.** `AppShell`: the session gate (signed out → sign-in; signed in without a centre → onboarding;
   otherwise tabs), the five tabs on iOS 26's tab bar, navigation stacks per tab, sheet presentation, toasts,
   deep-link routing (`tutorcentral://`), foreground refresh hook.
3. **Sign-in.** Native Sign in with Apple exchanged with Supabase; Google through `ASWebAuthenticationSession`;
   email one-time code (request, enter code, resend with a cooldown); password sign-in when the account has
   one; errors in words; session kept in the keychain by `supabase-swift`.
4. **Onboarding.** One screen: your name, centre name, WhatsApp number (E.164, +91 default). Creates the
   centre and membership in one call. Skippable fields marked optional per the board.
5. **Today, empty.** The Today screen built to its board with every section in its empty state; the stat tiles
   read real counts (zero); the AI tools row navigates to a "coming in a later build" board state.
6. **Settings, minimal.** Profile edit (the onboarding fields) and sign out, so a tester can leave.
7. **TestFlight.** App Store Connect record, App Store Connect API key in CI, cloud signing with
   `-allowProvisioningUpdates`, `testflight.yml` archives and uploads on manual trigger; the first build on the
   owner's phone.

## Owner steps

1. App Store Connect: create the app record (bundle id per D19), enable Sign in with Apple on the identifier.
2. Google Cloud: OAuth client for iOS; configure Supabase's Google provider.
3. Supabase: enable Apple and Google providers, email OTP; set the redirect URL scheme.
4. App Store Connect API key for CI; add the secrets.

## Acceptance

- Every screen in this phase matches its board in both appearances; screenshots in the PRs (D7).
- Sign in works with all three methods against the real Supabase project; a wrong code says so in words.
- The Kit shows every component in every state.
- A TestFlight build installs on the owner's phone and signs in.

## As built

(Written when the phase ends.)
