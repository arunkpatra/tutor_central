# Driving the admin portal locally

How a session runs the admin portal (`admin/`, D78, D94) against the local stack and checks it by hand in the Claude
desktop app's built-in browser, as `simulator.md` does for the app (D32's spirit): a settled page before every click, every
write confirmed in the database. Phase 19's hand runs followed it (`plan/phase-19-plan.md`, Task 16).

## 1. The local stack and the API with its worker

```bash
cd supabase && supabase start && supabase db reset
```

The local API with the worker is `simulator.md` section 12. Without `RESEND_API_KEY` its alert emails go to a sender that
logs them (the API's terminal shows `an alert email (fake sender)` with the text). `ALERT_EMAIL` may be left unset
(`alerts@localhost`).

## 2. `admin/.env.local`

The three variables from the local stack, never a production key (D11):

```bash
cd supabase && supabase status -o env | awk -F= '/^API_URL=/{print "SUPABASE_URL="$2} /^ANON_KEY=/{print "SUPABASE_ANON_KEY="$2} /^SERVICE_ROLE_KEY=/{print "SUPABASE_SERVICE_ROLE_KEY="$2}' > ../admin/.env.local
```

`ADMIN_PREVIEW` is never set here: preview mode is for `bun admin-shots`, with no keys at all.

## 3. A local admin

```bash
bun tools/admin-local.ts admin@example.com
```

It makes the account through the local Auth admin API, prints its password once, and writes the `admin_users` row with the
seed's tutor (`meera@example.com`) as the alert pushes' target. It refuses any stack that is not on this Mac. The seed's
tutor (`meera@example.com` / `tutor-local-1`) is the account a refusal is tried with.

## 4. The portal

```bash
cd admin && bun run dev
```

It serves on http://localhost:3100.

## 5. The built-in browser

Open it with `preview_start` and the URL. After every navigation and every click, read the page (`read_page` or
`get_page_text`) before the next action: a server action redirects, and the next page must be there before it is used.
At phone width: `resize_window` to 390, and back to desktop at the end.

## 6. The second factor's codes

The enrolment page shows the key in groups of four. The code for now:

```bash
bun tools/totp.ts <the key, spaces removed>
```

A code is good for its 30 seconds; type it straight after.

## 7. Confirm every write in the database

```bash
cd supabase && supabase db query --local "select action, centre_id, reason, ip, target from admin_audit order by created_at desc limit 5"
```

Also `alerts` (`key`, `acknowledged_at`, `acknowledged_by`), `jobs` (`state`, `attempts`, `error`) and `notifications`
(`kind = 'alert'`). `supabase db query --local` answers `{ "rows": [...] }`.

## 8. The alert's push to the simulator

`simulator.md` section 13: a Debug build signed in as the seed's tutor, reminders on (a `sandbox` token), the local API
with `APNS_*`. An alert's push row is written by the alerts job and sent on the next minute's tick.

## 9. What not to do

- Never a production key in `admin/.env.local`; never `ADMIN_PREVIEW` with real keys.
- Never run the API's or the database's tests while the local worker runs (`simulator.md` section 13): they share the jobs.
- A failed job made on purpose: a kind no handler runs (`artefact`), queued as the platform with `enqueue_job`
  (`simulator.md` section 12); the runner fails it at once (`no_handler`).
