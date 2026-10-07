# Phase 2: Design system, shell, sign-in, onboarding, first TestFlight

**Status:** Done (session 4, PRs #9 to #21); a TestFlight build on the owner's phone signed in with Apple. **Depends on:** Phase 0 direction and its Phase 2 boards approved; Phase 1 merged.

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

Session 4, Claude Opus 5.5, from `resume/003-phase-2-build.md`, executing `phase-02-plan.md` inline. Thirteen pull
requests where the plan had nine (#9 to #21): the plan's nine, plus the migration lane (#17, D26) and its fix (#20),
the app icon (#19, D29), and iPhone only (#21).

**What exists.** `DesignSystem`: every token of `design-tokens.md` as Swift, held to the document both ways by
`TokenDocumentTests` (D25); every Kit component; a debug Kit screen opened at five launch states. `Data`: auth,
centre and counts repositories (Supabase and in-memory). `AppShell`: the session gate, fixtures for every board
state, toasts, the five tabs, deep links, the foreground refresh. Features: sign-in (Apple, Google, email code,
password), onboarding, Today empty with real counts, Settings minimal. Migration 0002 in production through
`deploy.yml`'s migrate job. `testflight.yml` uploads build 0.1.0 (n) with cloud signing; build 3 is on the owner's
iPhone. Hosted auth: Apple, Google (a web client), the email code through Resend SMTP from tutorcentral.in.

**Deviations and why** (each a ruling in the session record; numbered decisions in `plan/README.md`):
- D26 (owner): migrations reach production only through `deploy.yml`, never by hand; the TestFlight lane refuses a
  build while migrations are pending. Task 10b added.
- D27 (owner): bundle id `in.tutorcentral.app`, the product's own domain, superseding D19's.
- D28 (owner): partial-height sheets are iOS 26's floating sheets; code entry is a full screen, as its board draws.
- D29 (owner): the app icon, P2-AppIcon C3 (Lucide's open book on the Ember glow).
- D30 (owner): the hosted project's email through Resend SMTP; Supabase locks the templates without custom SMTP.
- Phase 8 added: the website at tutorcentral.in (`/terms`, `/privacy`, which sign-in links).
- Values the boards draw that the document did not name became tokens (document and Swift together); component
  anatomy numbers (chip 28, code well 56, icon button 40, row 56) are named constants on their components.
- Supabase answers a wrong and an expired code alike (`403 otp_expired`): the code screen says "expired" by its own
  clock (600 s since the code was sent). Review Focus 3 holds; tested.
- The Kit opens at five launch states, not two; a screenshot holds one screen.
- The Today board has no AI tools row, so none was built (Phase 6's board draws it). Today's sections stay empty
  even for a seeded centre: Phase 4's boards make them live.
- Simulator builds sign ad hoc (an unsigned build has no keychain, so no session survived a relaunch).
- The App Store Connect API key is Admin: App Manager cannot use cloud-managed distribution certificates.
- Onboarding's intro line got its own token (`intro`, 16/22) instead of approximating it with `body`.

**Bugs found by running the app for real, fixed with tests where there was logic:** focus lost in a loop (shadow
tokens wrapped in one `AnyView` each); a second Supabase client per root (sign-in and reads on different clients);
no keychain in unsigned simulator builds; line heights about 8 pt too loose (`TypeTokenTests`); letters typed into
the phone field (`PhoneWellTests`); "₹4,000" wrapping in a stat tile; the app built for iPad too
(`testTheAppIsForIPhoneOnly`); the migrate job misreading the CLI's prose (`--agent yes`).

**Final review:** no Critical; seven Important, fixed in this session (PRs #22, #23; their CI waited on GitHub
billing); the minors are listed in `plan/sessions/004/record.md`.

**Remains, for later phases or polish:** UI polish (owner, after the first install), including content scrolling
under the status bar on Today; the deferred minors in `STATE.md`; the website (Phase 8) before App Store review.
