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
