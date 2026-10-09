# Session 14 (2026-10-09): the Phase 7 boards and the Phase 7 plan

Model: Claude Fable 5.1 (D17), from `resume/013-phase-7-boards-and-plan.md`. Outcome: Phase 0 step 0.8 done (41 boards in
row 10 of the canvas, approved), mirrored into `docs/design/`; `plan/phase-07-plan.md` written with
`superpowers:writing-plans` and approved; `docs/testing/device-tests.md` gained the tester's D1 to D7;
`resume/014-phase-7-build.md` for the Opus 5.5 build. No code.

## What was done, in order

1. Read the rules, the state, the decisions, the Phase 7 scope, the Phase 0 plan, Phase 6's "As built", the Phase 8 scope,
   the design documents, the inventory's account and settings rows, the spec, the runbook, the device tests, the records
   of sessions 12 and 13, the seed, migration 0001 (`delete_centre`, the cascades, `profiles.has_password`), the Settings
   feature, the shell (deep links, the session store, routes, launch states), the auth repository, the cache. Reality
   matched `STATE.md`; the local stack was up.
2. Told the owner what was found and asked the one question that shaped the boards: how an account is deleted. Three
   ways; recommended A (a `security definer` `delete_account()` that deletes `auth.users` for `auth.uid()`, the cascades
   doing the rest) plus Apple token revocation through the API. The owner: "we will go with your recommendations".
3. Drew the 41 boards with one Python generator (a parts library of the Ember tokens: the shell, nav rows, cards, setting
   rows with a line, switch rows, a segmented row, tile rows, fields, buttons, status lines, toasts, dialogs, floating
   sheets, the system alert, a popover with a wheel, the tab bar, student and fee rows, stat tiles, time rows; light twins
   by token-block substitution) and looked at every one rendered by headless Chrome before showing: Settings (dark, light,
   the end, a failed save), Account (dark, light), the password sheet (empty, failed), the password set, sign out (plain,
   with changes pending), Delete account (empty, typed, deleting, failed, done), Teacher reminders (not asked, the ask,
   on, all off, refused, the day picker), Help (closed, an answer), More (dark, light), offline (Today, Students, Fees,
   nothing cached, a write refused, attendance saved here, a fee marked here), back online (sending, sent, a failure),
   Pending changes (the list, a discard), the three notifications on the lock screen, the launch screen, the icon in
   place. Six fixes before showing (a wrapping segment, a popover off the bottom, a toast over the landing's buttons
   replaced by a banner, a wrapping class tile, the home screen's grid behind its wallpaper, the pending rows' wrapping
   titles). The style audit (no broken declaration, every tag closed, no exclamation mark) and the exact-colour count on
   every render passed. Published as row 10 (y 13200, the title note at 12900).
4. The owner approved the set ("Approved"). Mirrored the sources and the index into `docs/design/`, extended
   `components.md` ("Phase 7 parts" and the texts), `information-architecture.md` (the More tab's row, the deep links the
   notifications carry, the 35 launch states, the board table, what the boards settle), `design-tokens.md` ("Numbers in
   code": the password, the reminder leads and the 14-day window, the cache-age words, the queue's rules, the wipe), ticked
   0.8, committed to `main` (D12, `55e1a15`).
5. Proved the deletion mechanism on the local stack before planning it: a probe `security definer` function owned by
   `postgres` deleted the seed's tutor from `auth.users` through PostgREST's `rpc` with her own JWT, and every count went to
   0 (users, identities, centre, members, profile, students, fees, marks); the probe dropped, the seed reset.
6. Read the code the plan extends (the repositories, the fakes, the fee and attendance stores, the toast centre, the
   routes, the API's entry and middleware, the TestFlight lane, the package manifest, the Domain value types) and wrote
   `plan/phase-07-plan.md`: 23 tasks, 8 pull requests, one migration with its RLS test, the API's Apple route with a fake
   client and a client secret signed by Node's `crypto` (no new dependency), Domain's planner, pending changes, cache age
   and account rules with their tests, Data's auth additions, connectivity, cached reads with file protection, the change
   queue and its runner, the notification centre behind a protocol and the delegate, the Settings, Account, password,
   deletion, reminders, Help and Pending changes screens as their stores and parts, the offline reads and the three queued
   writes, the scheduler, hardening (Dynamic Type, VoiceOver, reduced motion, the Kit, error words), the launch screen and
   version 1.0.0, `docs/release.md`, the deploy and the TestFlight builds, thirteen hand runs and six owner steps, the
   tester's tests, a Review Focus of five with the test that pins each, a decisions table (D37 to D40 and sixteen smaller
   ones), a self-review. Committed with the device tests to `main` (`a7f60b6`).
7. The owner approved the plan with one ruling: the polish slice (U6, U7, U9, U16, U24) and Phase 6's minors 1, 6 and 7
   are Phase 8's, not Phase 7's. Recorded in the plan, Phase 8's scope, the polish list, the phase file, `README.md`,
   `STATE.md`. Wrote `resume/014-phase-7-build.md`, indexed it, this record and the owner's messages; committed to `main`.

## Why things are as they are

- **Deletion as a `security definer` function, not the API.** The API holds no service-role key (D11) and Supabase Auth has
  no self-service delete; a function owned by `postgres` may delete from `auth.users`, and 0001's cascades were built for
  exactly this. The function checks `auth.uid()` and deletes only that row. It is the second and last `security definer`
  (D37), with the reason in the file.
- **Apple revocation through the API (D38).** App Store review asks that an app with Sign in with Apple revoke the user's
  token on deletion. Revocation needs a client secret signed with the Sign in with Apple key, which must not be on the
  phone; the API signs it with Node's own `crypto` (ES256), so no dependency is added. The app asks Apple for a fresh
  authorization at deletion time (the code is single-use and short-lived), which doubles as "confirm it's you". Revoke
  first, then delete: a failure leaves the account whole.
- **Deletion is a pushed screen with a typed name, not a dialog.** It needs room to say what goes (the reference app
  explains it too); the typed confirmation follows Phase 3's deletions; the centre's name is what the tutor knows.
- **Settings shows the Appearance choice.** D23 promised a Settings row; the scope did not name it; the boards add it as a
  segmented row (Dark, Light, Match iPhone). "Pending changes" is always on Settings (None or a count) so the queue is never
  hidden.
- **Three writes queue, the rest refuse.** Attendance and Mark paid are the scope's; the absence alert's log joins them
  because WhatsApp itself works offline and a tutor in a basement classroom should still be able to tell a parent. Every
  other write is refused on Save with words that name it and the form kept: a queue for forms would need conflict rules
  no board draws. Last write wins per row, as the scope says; a change the server refuses is failed with its reason and
  stays until discarded, so nothing is lost silently.
- **The offline bar names the cache's time.** "Showing what was last saved" said nothing; the boards say "at 14:10",
  "yesterday at 18:30", "on Mon 5 Oct".
- **Reminders are planned in Domain, scheduled in AppShell.** The planner is pure and tested; the scheduler reads the
  register, the events and the fees that only AppShell holds together; the notification centre sits behind a protocol
  with a fake, so the scheduler is tested without UserNotifications. iOS's 64-pending limit is respected (60 of the
  soonest); ids are stable so a refresh replaces rather than doubles.
- **A notification tap goes through the existing deep-link path.** The delegate is UIKit behind a wrapper (D8) with its
  reason: SwiftUI cannot receive a notification response; an `AppDelegate` sets it before launch finishes.
- **Sign-out wipes the phone (D40).** The Phase 3 open call, closed by the boards: the sign-out dialog says it; caches
  are written with complete file protection. A tutor who shares a phone is protected; a tutor who signs back in reads
  from the network once.
- **Reports and a student's fees have no cache.** Month-wide reads the tutor makes online; two more caches with no board.
  Written in the plan's decisions table and the polish list.
- **The launch screen is always dark.** The app opens dark (D23); a light launch on a light phone would flash into a dark
  app. `UILaunchScreen` with a colour and an image, no storyboard.
- **The release candidate waits for Phase 8's privacy page** only at the Beta App Review step: App Store Connect needs the
  URL for external testing, and the app already links it. Everything up to the internal build proceeds.
- **Boards by generator, checked by headless Chrome, as sessions 8, 10 and 12**; the money-pair lesson is the style audit
  and the exact-colour count on the renders.

## Tried and dropped

- A toast on the sign-in landing after deletion: it covered the email button; a banner under the lead instead.
- A "Match iPhone" segment that wrapped: `white-space: nowrap` and no padding on segments (the Kit's segments gain the
  same rule in code).
- Disabling Tell parent offline: WhatsApp queues its own messages, so the alert works and its log joins the queue.
- A dialog for deletion: too small for what must be said.
- An API-side deletion with the service-role key (C): rule 5.

## Machine

As sessions 8, 10 and 12: Xcode 27, the iPhone 17 simulator, bun, Docker with the local stack, Google Chrome 155 headless
for the renders, Python 3 with Pillow for the contact sheets. The generator (`gen/lib.py`, `gen/boards1.py`,
`gen/boards2.py`, `gen/render.py`, `gen/sheets.py`), the renders and the sheets live in the session's scratchpad; the
canvas and `docs/design/mockups/` hold the real copies.

## Next

The build in a fresh Opus 5.5 session from `resume/014-phase-7-build.md`. Then Phase 8 (the website, with the polish
slice and the three minors).
