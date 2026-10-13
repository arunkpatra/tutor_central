# Runbook: drive the app in the Simulator against the local stack

How a session signs in, taps, types and takes screenshots it can trust, on the iPhone 17 simulator against local
Supabase. Every step here was measured in session 7 (issue #34); the evidence and the reasons are at the end. Use it
for every hand run, and always before a TestFlight build that changes a write path.

The driver is the Claude Code iOS Simulator tool (`control`: `attach`, `tap`, `text`, `screenshot`) plus
`xcrun simctl`. Nothing else is installed. Coordinates are in points: 402 × 874 on the iPhone 17, origin top left.

## The four rules

1. **Wait 1.5 s after a tap before you look.** A tap lands at once, but a sheet, a push or a dialog animates in; a
   screenshot taken straight after shows the screen before it. The tool's own `screenshot` right after an input is
   early, never stale: wait and look again.
2. **Wait 1 s after `text` before the next tap.** `text` returns before the characters reach the app (about 60 a
   second). A tap sent at once acts on a partial value: a Sign in tap straight after typing the password sent a
   cut-off password (the auth log said `invalid_credentials`; the field later showed all 13 dots).
3. **Type a phone number in two parts: the first 6 digits, wait 1 s, the other 4.** `PhoneWell` rewrites its text
   when the sixth digit adds the group space, and keys injected during the rewrite are lost (10 sent at once, 6
   landed). Pasting the whole number should land too (`PhoneWell` takes a pasted number whole), but session 7 tried
   paste only on a name field.
4. **Look at the screen before every tap, from a settled screenshot scaled to points**, and read the coordinates off
   it. Never tap from memory after the screen changed: a dialog moves up when its field takes the keyboard (the
   student delete dialog's button went from y 537 to 386), and a sheet can sit a few points lower than last time. Take
   the screenshot after every action, a back tap included, or the evidence cannot say which action did what. Confirm
   every write in the database, not only on screen.

One driver at a time: `bun check` and `bun shots` install and launch on the same simulator. Never run them while you
drive.

## 1. Start the local stack

```bash
cd supabase && supabase start
```

`supabase status -o env` prints the keys; `ios/Config/Local.xcconfig` holds `SUPABASE_URL = http:/$()/127.0.0.1:54321`
and the `ANON_KEY`. For a clean register, `supabase db reset` (migrations and `seed.sql`); `bun check`'s db step
ends with the same reset. The seed's tutor is `meera@example.com` / `tutor-local-1`, centre Bright Minds Tuition,
10 students, 2 classes.

## 2. Build a Debug build against it

```bash
cd ios && xcodegen generate --quiet && xcodebuild -project TutorCentral.xcodeproj -scheme TutorCentral -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGN_IDENTITY=- CODE_SIGN_STYLE=Manual DEVELOPMENT_TEAM= PROVISIONING_PROFILE_SPECIFIER= build 2>&1 | xcbeautify --quiet
```

About 30 s cold, 8 s warm. It lands in the default DerivedData, where `bun shots` looks too. Check it reads the local
stack:

```bash
/usr/libexec/PlistBuddy -c "Print :SUPABASE_URL" "$(ls -td ~/Library/Developer/Xcode/DerivedData/TutorCentral-*/Build/Products/Debug-iphonesimulator/TutorCentral.app | head -1)/Info.plist"
```

It prints `http://127.0.0.1:54321`.

## 3. Boot, install, launch (cold)

```bash
xcrun simctl shutdown all; xcrun simctl boot "iPhone 17"; xcrun simctl bootstatus "iPhone 17" -b
```

```bash
xcrun simctl install "iPhone 17" "$(ls -td ~/Library/Developer/Xcode/DerivedData/TutorCentral-*/Build/Products/Debug-iphonesimulator/TutorCentral.app | head -1)" && xcrun simctl launch "iPhone 17" in.tutorcentral.app
```

Measured: shutdown 3 s, boot to ready 5 s, install 4 s. Then `control attach` so the owner can watch (the panel
streams the headless device; the Simulator app need not run). Launched without `--state`, the app talks to the local
stack; with `--state <name>` it opens on the fakes (`bun shots`), which is not a hand run.

The session survives a relaunch and a reboot (seen in session 7: terminate and launch, and a shutdown, boot and
reinstall, both opened on Today signed in). To start signed out, sign out in Settings (section 5).

The first keyboard after a boot can show iOS's one-time "slide to type" tip where the keys are. Tap "Continue"
(201, 829), wait 1.5 s, and the keys and the focused field are back; nothing typed was lost, because nothing was
typed yet.

## 4. A settled screenshot

```bash
sleep 1.5 && xcrun simctl io booted screenshot .shots/run/01-name.png && sips -z 874 402 .shots/run/01-name.png --out .shots/run/view/01-name.png
```

`.shots/` is ignored. The full-size file (1206 × 2622) is the evidence; read the scaled copy, whose pixels are tap
points. Make the folders first (`mkdir -p .shots/run/view`).

## 5. Sign in as the seed's tutor

From the sign-in screen, each step followed by a settled screenshot (section 4) before the next:

| Step | Action | Wait |
|---|---|---|
| 1 | `tap` "Continue with email" (201, 755); the sheet opens with the email field focused | 1.5 s |
| 2 | `text` `meera@example.com` | 1 s |
| 3 | `tap` "Use my password instead" (201, 501); the email carries over, the password field is focused | 1.5 s |
| 4 | `text` `tutor-local-1` | 1 s |
| 5 | `tap` "Sign in" (201, 412) | 3 s |
| 6 | iOS asks "Save Password?": `tap` "Not Now" (127, 547) | 1.5 s |

Today then greets Meera. The coordinates are a start, not a promise: read them off the screenshot each time. If
step 5 shows "That password isn't right", the tap beat the typing (rule 2): tap Sign in again. Confirm in the auth
log:

```bash
docker logs --since 1m supabase_auth_tutor_central 2>&1 | grep '"path":"/token"' | grep -o '"status":[0-9]*\|"error_code":"[a-z_]*"'
```

To sign out: the MN avatar on Today (362, 137), "Sign out", then "Sign out" in the dialog.

## 6. Type into a field and confirm it landed

1. `tap` the field. Wait 1 s for focus and the keyboard; a form's first field is often focused already.
2. `text` the value (a phone number in two parts, rule 3). Wait 1 s.
3. Take a settled screenshot and read the field. A short value reads at the scaled size; for a long one, crop the
   full-size file.

To paste instead: `printf 'Kavya Nair' | xcrun simctl pbcopy booted`, `tap` the focused field again, wait 1.2 s, `tap`
"Paste" in the edit menu. No permission prompt (it is the user's own paste). It takes three taps for one value, so
`text` is the default and paste the fallback.

There is no reliable "clear the field": to start a form again, Cancel and Discard.

### Switches, toasts, Photos and Files (session 11)

- **A switch (iOS 26):** the tool's instant `tap` sometimes does not move it; `tap` with `duration` 0.15 does. Check
  the switch and the row after each tap.
- **An Undo toast stays 8 s.** Tap Undo straight after the action (`sleep 1.5`, then the tap at the toast's place),
  without reading a screenshot in between: a screenshot read can take longer than the toast.
- **A picture in Photos:** `xcrun simctl addmedia booted <file.png>`. A UPI QR can be made on the Mac with Core Image
  (a short Swift script: `CIFilter.qrCodeGenerator`, scaled ×12, a white margin, `NSBitmapImageRep` to PNG).
- **A file saved to Files** ("On My iPhone") lands in the device's `File Provider Storage`: `find
  ~/Library/Developer/CoreSimulator/Devices/<udid> -name 'fees-*.csv' -mmin -5`. Numbers is "Numbers Creator Studio"
  on this Mac; `osascript -e 'tell application "Numbers Creator Studio" to tell table 1 of sheet 1 of front document to
  get {row count, column count}'` reads it back.
- The signed-in session survives an uninstall, a reinstall and `supabase db reset` (the seed keeps the tutor's id).

## 7. Confirm a write in the database

```bash
docker exec supabase_db_tutor_central psql -U postgres -c "select name, class_id, monthly_fee, parent_phone, archived_at from students order by updated_at desc limit 3"
```

```bash
docker exec supabase_db_tutor_central psql -U postgres -c "select name, archived_at from classes order by updated_at desc limit 3"
```

The screen says what the app believes; the row says what reached the server. A hand run checks both.

## 8. Open a deep link

```bash
xcrun simctl openurl booted "tutorcentral://student/$(docker exec supabase_db_tutor_central psql -U postgres -tAc "select id from students where name = 'Riya Sharma'")"
```

Wait 2 s. The links are in `ios/TutorCentralKit/Sources/AppShell/DeepLink.swift` (`today`, `student/<id>`, `fees`,
`attendance`, `event/<id>`); a link opens only once signed in.

## 9. Recover a wedged simulator

Signs: a tap or `text` that changes nothing after 3 s on a settled screen, screenshots that never change, `xcodebuild`
stuck on "Failure collecting diagnostics from simulator", or the smoke test's "Application failed preflight checks".

```bash
xcrun simctl terminate booted in.tutorcentral.app; xcrun simctl shutdown all && xcrun simctl boot "iPhone 17" && xcrun simctl bootstatus "iPhone 17" -b
```

Then `control attach` again. If `simctl` itself hangs, `killall -9 com.apple.CoreSimulator.CoreSimulatorService`
and boot again (not needed in session 7; the reboot above was enough). Before a test run, leave no app running
(`xcrun simctl terminate booted in.tutorcentral.app`). `bun check` passes `-collect-test-diagnostics never`, so a
failing test reports at once instead of after ten minutes.

## 10. The hand run before a TestFlight build

For a build that changes a write path, after `bun check` is green and before `gh workflow run testflight`:
sections 1 to 3 from a cold simulator, sign in (5), then each write the change touches, through the screens, each
confirmed on screen (4) and in the database (7). For the register, the full run is: add a student, edit them, archive,
restore, delete; add a class, move a student into it, archive the class. Keep the screenshots and put them in the
pull request or the issue.

## 11. Share to Tutor Central (Phase 13)

The share extension (`Share/ShareViewController.swift`) writes one text or one image into the app group's `inbox/` and
closes; the app reads the inbox when it next comes to the foreground signed in and opens "Check what was read" on the
School tab (`ShellState.inboxHandoff`).

- **A photo:** `xcrun simctl addmedia booted <file.png>`, then Photos → the picture → Share → Tutor Central in the sheet
  (find the row from a settled screenshot; it can sit in the second row of apps or under More). The extension closes
  by itself.
- **A text:** `printf 'Dear Parents, …' | xcrun simctl pbcopy booted`, then Notes → a new note → Paste → select all →
  Share → Tutor Central.
- Then `xcrun simctl launch booted in.tutorcentral.app` (or tap the app): the app comes to the foreground and reads the
  inbox. Wait 2 s before looking.
- The proof the extension wrote: `find ~/Library/Developer/CoreSimulator/Devices/<udid>/data/Containers/Shared/AppGroup
  -path '*inbox/*' -mmin -5` (the item's JSON and, for a photo, its image); after Add or Back the folder is empty.
- Without the extension: Paste a message from the School tab's "+" reads the pasteboard (`simctl pbcopy` first).
- "Check what was read": the checkbox at a card's left edge ticks or unticks the item; the card's title opens its
  sheet; Add is the footer's button. The query that proves an item:

```bash
docker exec supabase_db_tutor_central psql -U postgres -c "select title, kind, date, end_date, class_level, student_id, source, photo_path, confirmed_at from school_items order by created_at desc limit 5"
```

The waits measured on the hand runs are added here (section 5's way) when the phase's documents are written.

## 12. The worker locally (Phase 17)

The API's worker (`/jobs/tick`, `/jobs/wake`, D71) runs in the local API. `api/.env.local` holds `WORKER_SECRET=local`;
the service key comes from the stack, as the URL and the anon key do:

```bash
cd api && eval "$(cd ../supabase && supabase status -o env | grep -E '^(API_URL|ANON_KEY|SERVICE_ROLE_KEY)=')" && SUPABASE_URL=$API_URL SUPABASE_ANON_KEY=$ANON_KEY SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY AI_FAKE=1 APPLE_FAKE=1 bun run dev
```

- **Queue a job** as the platform (psql has no request claim, so `enqueue_job` refuses it there): PostgREST with the
  service key, `curl -s -X POST "$API_URL/rest/v1/rpc/enqueue_job" -H "apikey: $SERVICE_ROLE_KEY" -H "Authorization:
  Bearer $SERVICE_ROLE_KEY" -H "Content-Type: application/json" -d '{"p_centre": "<centre>", "p_kind": "plan", "p_key":
  "plan:<class>:<day>", "p_input": {"class_id": "<class>", "date": "<day>"}}'`.
- **Run the worker:** `curl -s -H "Authorization: Bearer local" http://127.0.0.1:3000/jobs/tick` answers the run's counts
  (`claimed`, `steps`, `done`, `waiting`, `failed`, `lost`); the tick first queues the hour's sweep.
- **Read it back:** `select kind, state, step, result, error, attempts from jobs`, `select step, attempt, state from
  job_steps`, `select route, status from api_requests order by created_at desc`.
- **The wakes from inside the database:** locally the Vault secrets are absent, so neither the enqueue trigger nor the
  minute's pg_cron calls the API. To prove them, set `worker_url` to `http://host.docker.internal:3000` (the database runs
  in Docker) and `worker_secret` to `local` with `vault.create_secret`, insert a job, and delete the two secrets after
  (session 35: woken and done within a second). Production's are written by the deploy.

## 13. A push to the simulator (Phase 18)

The iPhone 17 simulator on this Mac takes real sandbox pushes from APNs: a Debug build registers a token (`device_tokens`
gets a `sandbox` row after Turn on reminders → Allow), and the local API sends with `api/.env.local`'s `APNS_*` (the token
key; `/jobs/health` answers `apns: true`). The outbox (`notifications`) is sent on each minute's tick, so a row written by a
job arrives within the minute with the local Vault secrets set (section 12).

- **A payload alone**, no APNs: `xcrun simctl push booted in.tutorcentral.app payload.json` with `{"aps": {"alert":
  {"title": "…", "body": "…"}}, "link": "tutorcentral://today"}`.
- **The lock screen:** quit the app (swipe it away) and press the simulator's lock button (the iOS Simulator tool's
  `button` LOCK, or Device → Lock in Simulator.app); after a lock the simulator's panel can look frozen: section 9.
- **Stop the local API with its listener only:** `kill $(lsof -ti :3000 -sTCP:LISTEN)`. A bare `lsof -ti :3000` also lists
  Docker's own backend (the database's pg_net keeps a connection to `host.docker.internal:3000` for the worker's wake), and
  killing it stops Docker Desktop (session 37, three times).
- **A preference planted for a run** (build 27's `reminders` key, say): `xcrun simctl spawn booted defaults write
  in.tutorcentral.app …` writes the simulator's shared domain, which the app never reads. Write to the app's own:
  `defaults write "$(xcrun simctl get_app_container booted in.tutorcentral.app data)/Library/Preferences/in.tutorcentral.app"
  reminders -data <hex>` through `simctl spawn`, with the app quit, and read it back the same way (the file on disk lags
  the preferences daemon).
- **Never run the API's tests during a hand run:** `jobs-db.test.ts` and `platform-db.test.ts` use the local stack; with a
  local worker running, the worker claims the tests' jobs, and the tests clear the jobs table and reset rows the run made.
  Stop the local API first (and expect to set the run's data again).
- **Real models:** start the API without `AI_FAKE=1` only for the run that needs them, and stop it straight after: the
  local schedules queue plan and note jobs by themselves, and a fake call's key replays its fake answer (clear those
  `ai_generations` rows locally first).

## The proof run

Session 7 followed sections 1 to 8 from a cold simulator against a freshly reset seed: signed in through the screens
(first try), then added Kavya Nair (name, fee, parent, phone in two parts), edited her (gender, a note), archived,
restored and deleted her, opened a deep link to Riya Sharma, added Class 9 English (subject, fee, Mon Wed Fri), moved
Dev Kumar into it and archived it (Dev detached, his own fee kept). About 45 taps and `text` calls; every one landed;
every write was seen on screen and in its row. The screenshots are on issue #34.

## Why this way, and what was not used

Measured on the iPhone 17 simulator, iOS 26.4, Xcode 27, in session 7:

| Avenue | What landed |
|---|---|
| `control tap` | Every tap landed. Session 6's "missed tap" was a screenshot taken before the sheet arrived, then a second tap |
| `control text` | Every character landed within about 0.5 s (26 characters between two frames 0.4 s apart). It returns before they all arrive: a tap at once posted a cut-off password. Session 6's "meera@e" was the same race |
| `control screenshot` | Early when taken straight after an input; correct after a wait. `simctl io screenshot` after the waits above was always current |
| The phone field | Digits lost at the group space when sent in one burst; all ten land in two parts (tried twice) |
| Pasteboard (`simctl pbcopy` + Paste) | Lands whole in a name field; three taps per value |
| Hardware keyboard setting | Not a factor: it belongs to the Simulator app, which this setup does not run (the device is booted headless and streamed); the software keyboard is up, and the lost digits come from the app's own rewrite |

Not used:

- **A debug-only local sign-in launch option** (`--local-sign-in`): the owner's call, 2026-10-08. Signing in through
  the screens works every time with the rules above, exercises the real sign-in on every run, and needs no app code
  and no question about rule 5. Revisit if the screens ever flake.
- **AXe and idb:** both would add element lookup by accessibility label and reading a field's value. Neither is
  installed, both are third-party tools on the owner's Mac, and the tool already lands every input once the waits are
  kept. Not needed.
- **XCUITest kept outside `bun check`:** `typeText` waits for delivery and `waitForExistence` settles, so it would be
  the most deterministic driver, but it is a UI test suite (D15 says none), costs a target and its upkeep, and does
  not give the owner a watched run. Not needed while the rules above hold.

## 14. The agents, the maths and the nightly locally (Phase 20)

- **Real models:** `api/.env.local` holds `ANTHROPIC_API_KEY`; start the API without `AI_FAKE`. Restart it after switching
  branches: `bun run dev`'s `--hot` does not reload every module (session 41's API served 11:04's prompts for hours).
- **A planted wrong key:** `AI_FAKE=1 TC_FAKE_SCRIPT=wrong-proof` makes every fake sheet draft and repair carry a proof that
  does not add up, so the agent refuses it after one repair ("Couldn't make it." with Retry; rows draft failed
  `check:question 1`, check, repair, check).
- **A kind switched off:** `insert into public.ai_models (kind, step, model, effort, enabled, set_by) values ('sheet_from_6',
  'draft', 'claude-sonnet-5-5', 'medium', false, 'hand run')` with `supabase db query --local`; within a minute Make shows the
  alert, a plan made again counts that line not made (`{"reason":"paused"}` on its step). Delete the row after.
- **The nightly:** queue `eval_run` with the service key (`enqueue_job`, `p_centre` null, input `{"day": …, "kinds": ["check",
  "placement"]}`) and tick each minute; it waits on Anthropic's batches (about 40 minutes for two kinds) and ends done with its
  result on the job.
- **Cost:** read a run's calls by job id (`ai_generations.job_id`); `bun cost --since` also counts the rows the API's database
  tests leave on the local stack.
- **Never run the API's tests, or `bun check` with the api or db step, during a hand run:** the database tests clear the local
  jobs table (session 41 lost a PDF job and two nightly tries that way).
