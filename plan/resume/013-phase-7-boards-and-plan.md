# Resume 013: Phase 7 (settings, account, notifications, offline, hardening, release candidate), the boards and the plan

Paste this into a new Claude Code session opened on `/Users/arunkpatra/codebase/tutor_central`, model Claude
Fable 5.1 (decision D17: design and planning on Fable; the build goes to Opus 5.5 through the next resume prompt).

---

You are continuing Tutor Central, a native iPhone app for tutors who run small tuition centres. Read, in this
order, before doing anything:
1. `CLAUDE.md`, then `ios/CLAUDE.md`, `api/CLAUDE.md`, `supabase/CLAUDE.md`.
2. `plan/STATE.md`, `plan/SESSIONS.md`, `plan/README.md` (decisions D1 to D36), `plan/ui-polish.md`.
3. `plan/phase-07-settings-and-hardening.md` (the scope), `plan/phase-00-design.md` and `plan/phase-00-plan.md` (step
   0.8 is yours), `plan/phase-06-ai-tools.md` "As built" (what Phase 6 left and why), `plan/phase-08-website.md` (the
   privacy and terms pages the app links).
4. `docs/design/README.md` (including the owner's rule that a board's figures are illustrative), `design-tokens.md`,
   `components.md`, `guidelines.md`, `information-architecture.md`; the Settings, Account, notification and offline
   rows of `docs/reference/functional-inventory.md` (the contract, rule 10); `docs/spec.md`.
5. `docs/runbooks/simulator.md` (D32) and `docs/testing/device-tests.md` (what a tester runs on a real iPhone).
6. The records of the last two sessions: `plan/sessions/012/record.md` (how the Phase 6 boards were drawn, checked and
   approved, and how the plan was written) and `plan/sessions/013/record.md` (Phase 6's build: its rulings, its hand
   run, its review and the minors it deferred show where the last plan was thin).

**What is already true:** Phases 1 to 6 are done (PRs #1 to #62). Build 0.1.0 (9) is on TestFlight; the owner scanned
a register with the phone's camera: "Works". The rest of the device checks are a tester's, logged in
`docs/testing/device-tests.md`. Production: Supabase in Mumbai with migrations 0001 to 0007 (migrations go up only
through `deploy.yml`, D26), the API on Vercel at `6eea8b8` (deployed only through `deploy.yml`, D21), email through
Resend (D30), Claude through the API (D35). What Phase 7 starts from:
- **Settings** (`Features/Settings`): Teaching profile, Parent payments (Phase 5), an "Account" section with "Signed
  in as", Version and Sign out (with its confirmation), and a later row "Reminders and haptics · Phase 7". Haptics
  already play through `DesignSystem/Modifiers/Haptics.swift`, reading a "haptics" setting (default on) that nothing
  writes yet.
- **More** shows Account and Help as later rows ("Phase 7").
- **Deep links** (`AppShell/DeepLink.swift`): `tutorcentral://today`, `student/<id>`, `fees?month=`,
  `attendance?date=&class=`, `event/<id>`, `auth-callback`. Notifications open these.
- **Deleting a centre:** `public.delete_centre(p_centre)` exists since migration 0001 (`security invoker`, owner only,
  cascades). Nothing in the app calls it yet, and nothing deletes the auth user: decide in the plan what "delete
  account permanently" removes (the centre's rows, the profile, the auth user) and how, given the API holds no
  service-role key (D11). That is likely a decision for the owner; ask it once, with a recommendation.
- **Offline:** only the register is cached (`RegisterCache`, JSON in Application Support, `JSONCache` in Data); every
  other list reads live. No write is queued.
- **No local notifications** exist yet; no `docs/release.md`.
- **Legal pages:** the privacy policy and terms are Phase 8's (tutorcentral.in), to be live before the first App
  Store submission. Plan the links so Phase 7 does not wait on them.
- **The canvas:** https://claude.ai/artifact/X3FTU6KXv2V6qxhachXX8D; row 9 holds the 44 Phase 6 boards.

**Your work, two parts, each approved by the owner before the next:**

1. **Phase 0 step 0.8, the Phase 7 boards** (`phase-00-plan.md`): Settings in full (saved marks instead of a Save
   button), Account (email, sign-in methods, set or change password, sign out, delete account with its typed
   confirmation, and what follows), teacher reminders (the notification permission: not asked, asked, refused with Open
   Settings; the class, event and unpaid-fee switches; the day of the month), haptics, About (version and build),
   Help, the offline states (a list from the cache with its age, a write refused, a write queued, a replay that failed
   and what the tutor can do), the notification banners themselves (what each says and where it opens), the launch
   screen, and the app icon in place. Draw every state the scope implies, failures and empty states included: Phase 6
   learned that an unboarded state is a dead end. A new canvas row (row 10), dark for every state board, light for the
   shell-level ones (Settings and Account at least), built from the tokens and the Kit, with the seed's real content
   (`supabase/seed.sql`). Partial sheets are iOS 26's floating sheets (D28). Draw by script and look at each one
   rendered (headless Chrome) before showing, checking the rendered colours against the source. Mirror the approved
   boards into `docs/design/mockups/` and `directions/canvas.json`, list them in `information-architecture.md` with
   their launch states, extend `components.md`, commit as documents (D12).
2. **The Phase 7 plan**, `plan/phase-07-plan.md`, with `superpowers:writing-plans`: tasks in order, tests first
   (Domain and Data against in-memory fakes; the scheduler of notifications against a fake notification centre; the
   write queue's replay and conflict rules as pure logic; RLS tests for any migration), pull-request boundaries, any
   migration and deploy (the database first, D26), the owner's steps (one at a time, checked before the next: the
   TestFlight external group, its Beta App Review, release notes, anything in App Store Connect), a Review Focus, a
   self-review. For each part, say how it is proven:
   - **in the simulator**, by the runbook: local notifications do fire there (schedule one a minute ahead); offline is
     the stopped gateway (`docker stop supabase_kong_tutor_central`); Dynamic Type through `xcrun simctl ui booted
     content_size`; deleting an account against the local stack, confirmed row by row in the database;
   - **by the tester**, added to `docs/testing/device-tests.md` in the same documents commit as the plan: VoiceOver,
     a reminder arriving on a locked phone and opening its link, airplane mode on a real network, launch time and
     scrolling on the oldest iOS 26 iPhone, the release candidate from TestFlight's external group. Keep that document
     lean: only what the simulator cannot show.
   Name the hand run of every write path the build session does before the TestFlight build (D32). Show the plan to the
   owner; on approval, write `plan/resume/014-phase-7-build.md` for an Opus 5.5 session and index it in
   `plan/resume/README.md`.

**Learn from Phase 6's build (session 13's record and its final review):**
- The lint's shapes still hold: no 3-tuples (structs), at most six parameters to a function, files under 400 lines and
  types under 250, lines under 120, no force-unwraps in tests, `@MainActor` fakes and stores, a pure `static func` on a
  view `nonisolated`. Write every test snippet so it compiles as written.
- A call or write the tutor can leave runs in a task its store owns: refused while one runs, Cancel and Back cancel it,
  a late answer is dropped. The queued-write layer is that problem at length: plan its states, its replay order and
  what the tutor sees when a replay fails, each with a test.
- Words meant for a screen that has gone must reach the screen the tutor is on (Phase 6's Undo failed silently after
  the list had popped). Say, for every toast and failure, where it shows.
- An error says what is true: a timeout is not "offline", and "Nothing was used up" is promised only when it is so.
  Review every error's words against what actually happened (the scope's "error wording reviewed").
- A button under fields puts the keyboard away when its result appears in place; a multiline well takes a tap anywhere.
  The hardening task should look for the same in older screens.
- A sheet that builds a form store keeps it in `@State`; a pushed screen's store lives on the shell when its steps are
  separate routes.
- `supabase db reset` ends the signed-in app's session (sign out and in); taps during a push transition are lost
  (screenshot before the next tap); an Undo toast lasts 8 s.

**Carry forward:**
- `plan/ui-polish.md`: U5 to U11 and U13 to U24 are open. Several are hardening's kind (U6, U7 and U9, the keyboard over
  fields and toasts; U16, a toast over a footer; U24, the status bar's glass on pushed screens). Offer them with the
  plan as a polish slice; take none unless the owner says so.
- Phase 6's deferred minors (`plan/sessions/013/record.md`) and Phase 5's (`plan/sessions/011/record.md`) stay the
  owner's; the hardening task may name those it would close (the grapheme and code-point limits, the trunk-0 phone),
  as an offer.
- The open owner calls in `STATE.md` (the register cache on sign-out, Google's mark) are Phase 7's ground (sign-out and
  account deletion): raise them once, in the plan, with a recommendation.
- If the owner or the tester reports anything from build 9, record it in `STATE.md` and the device tests' log; a fix
  is its own pull request in a build session, not part of this one.

**How to work:** one question at a time, only for decisions that are the owner's; decide small things yourself and
write them down. No board, no code; this session writes no code. Documents only go to `main` directly. Update
`STATE.md` and write `plan/sessions/014/record.md` and `owner-messages.md` before you stop.

Start by telling the owner in a few lines what you found and what you will do. Then do it.
