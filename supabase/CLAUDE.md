# supabase: rules

- One migration per change in `migrations/`, named `YYYYMMDDHHMMSS_<what>.sql`; never edit a migration that has
  run on the hosted project.
- Every centre table: `id`, `centre_id`, `created_at`, `updated_at` (trigger `set_updated_at`), RLS enabled, a
  policy through `is_member(centre_id)`, and a test in `tests/` that proves isolation. The tenancy tables
  (`centres`, `centre_members`, `profiles`) have their own policies. No policy, no merge. The catalogue
  test in `tests/rls.test.ts` fails when a public table lacks RLS or a policy, or is missing from its list.
- References between centre tables are composite, `(centre_id, x_id)` to `(centre_id, id)`, so a row can never
  point into another centre (foreign keys bypass RLS). Optional ones use `on delete set null (x_id)`.
- Multi-row operations are functions, `security invoker` so RLS applies, `set search_path = ''`; `is_member`,
  `delete_account`, `wake_worker` and `wake_worker_tick` (0034: Vault is readable by postgres alone) are the only
  `security definer` functions (D37, D83), each with its reason in its migration. Since
  migration 0002, new tables, sequences and functions grant nothing to `anon`, and new functions grant no `PUBLIC`
  execute (in any schema, for functions the `postgres` role creates, extensions' included): every new function
  grants `authenticated` itself, and an extension's functions need explicit grants. The catalogue test probes this.
- Local: `supabase start` (Docker), `supabase db reset` (migrations and `seed.sql`), Studio at :54323, mail at
  :54324. Keys from `supabase status -o env`. The seed's tutor signs in as `meera@example.com` /
  `tutor-local-1`.
- Types: `supabase gen types typescript --local > types.ts` after every migration; commit it.
- Hosted: project `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), beside the API in `bom1`. Migrations reach it only
  through `deploy.yml`'s `migrate` job, before the API (D26); never `supabase db push` by hand. A migration is
  additive while any installed build uses what it would remove (expand now, contract later): the database leads
  the app, and the TestFlight lane refuses a build while migrations are pending. Run it with
  `gh workflow run deploy`; the run's summary shows what was pending and that nothing is after. Migrations 0001 to 0064 are on the hosted project (`plan/STATE.md` names the runs). Its secrets (`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`) are in the GitHub
  environment `Production`. 0001 was the only hand push.

- App Review's demo centre (D51): `gh workflow run seed-review -f email=… -f parent_phone=…` fills an existing account's
  centre with a sample centre (`tools/review-seed.ts`, tested by `tests/review-seed.test.ts`); it refuses a centre that
  already has students. The account itself is made by the owner (Supabase dashboard), never by a script.

- `close_session` (0017) takes an eighth argument, `p_states`, with a default, so build 19's seven-argument call still
  resolves. A second close of the same class and day replaces that session's checks and homework; the app moves a skill's
  state again only for a tap that changed. `record_placement` writes the placement's checks with no session.
- `copy_textbook_chapters` deletes the book chapters a recapture dropped before it moves the student's own chapters
  behind the book's (the unique position would refuse them otherwise).
- `current_date` and `now()` in a psql session are UTC: a hand run's query of the day's plan or session names the IST day
  (`date = '2026-10-11'`) after 18:30 UTC.

Commands: `bun check --only=db` (resets the local database, runs the tests, re-seeds);
`cd supabase && bun test tests`.

- Phase 13: the seed's figures must satisfy the app's rules they are meant to show (Hemanth's Below usual needs two earlier
  marks); `name_plan_group` writes the group and its teach words, not the lines' skill ids.
- Phase 14: a rule that must hold for every writer of a column (the close, the placement, a queued close) is a trigger in the
  database (0025: a changed `track_status` clears `next_step` unless the same update sets it), with a test through the RPC
  the product uses.
- Phase 15: 0026 adds `artefacts.made_from` (null or 'make') and `keep_artefact`'s eighth parameter `p_made_from`; the seed
  keeps three weeks of checks at the Evening batch's closes (the dates relative to `current_date`). 0027: what was written
  about a student goes with them (`ai_generations.student_id` and `message_log` cascade on the student's delete), and a
  progress note needs the parent's consent. A test that inserts into centre A runs before `delete_account`'s test.
- Phase 17 (V3 platform): the platform is the service role (D83): `is_member` is true for its claim, and the platform's
  tables (`jobs`, `job_steps`, `api_requests`, `alerts`, `admin_audit`) are read by members at most (`alerts` and
  `admin_audit` not at all). A table written only through functions holds it with a transaction setting the function sets
  and a trigger that refuses the rest (`tc.jobs` for `jobs`, `tc.gate` for `ai_generations`, `tc.consent` for
  `consent_events`); the platform and a session with no request (psql, the seed, the tests' fixtures) pass. A member
  writes no `ai_generations` row (0035): `start_ai_call` makes it, the API finishes it as the platform, and a finished row
  is final (`ai_generations_finish_once`). `start_ai_call` serialises a centre's calls with an advisory lock, replays a key
  within a day, and reads the allowance from `centres.ai_allowance` (calls a month) and `ai_allowance_paise` (the month's
  cost; 0 is none), which members cannot update. No member queues a job yet (0035).
- The wakes (0034): pg_cron's `wake_worker_minute` gets `/jobs/tick` each minute and a queued job posts `/jobs/wake`,
  through pg_net, with the address and secret the deploy writes to Vault (`worker_url`, `worker_secret`); without them
  both do nothing. Locally the secrets are absent unless a test sets them inside a rolled-back transaction.
- `supabase db query --linked --output-format json` answers a bare array; `--local` answers `{ "rows": [...] }`; `-f`
  resolves its file from the repository's root (the restore drill and `run-job` read either shape).
- Phase 18: consent's withdrawal is `withdraw_consent` (0036; the columns cleared, a `withdrawn` event with how, the
  student's queued note request cancelled); a member asks the server through `request_plan`, `request_note`,
  `request_export` and `cancel_job` (0037), never by writing `jobs`. The account's reminder settings (`reminder_settings`, 0038) are the tutor's own
  row; the push outbox (`notifications`) is written by the platform through named functions and a member reads their own. The schedules (0039): `schedule_plans` and `schedule_note_days` every 15 minutes, `schedule_reminders` at five past
  each hour, with `wake_worker_minute`. Storage (0040): private buckets `pdfs` (5 MB) and `exports` (10 MB) beside
  `photos`; a deleted row with a file queues it in `storage_deletions` (a centre's delete queues its prefixes), which the
  sweep empties. Retention (0041): an export is kept seven days; `trim_platform` deletes notifications after 30 days and
  the sweeps' done jobs after seven.
- Phase 19 (the admin portal, D78, D94): `admin_users` (0046) is the allow-list, keyed by the user, read by no member and
  written by the session with `supabase db query --linked`, never by the portal; its `notify_user_id` and `notify_centre_id`
  name the tutor account whose iPhone gets the alert pushes. The portal reads only through `admin_*` functions (0047, 0048)
  and writes only through `admin_audit_write`, `admin_open_record`, `admin_acknowledge_alert`, `admin_retry_job` and
  `admin_cancel_job`, each writing its own audit row; all are `security invoker` and granted to `service_role` alone (a
  member gets 42501). They never select a parent's number, a photo path, a message's body, or a personal kind's input
  while the student's consent is not current (`admin_call`'s `input_held`); a student's name only through the record,
  answered after its `open_record` row (`admin_record_opened`: ten minutes). `auth.users` is not readable by the platform in
  SQL: the portal asks the Auth admin API for emails. A function of a table's row becomes a PostgREST column of that table
  (the generated types demand it of every row): a helper takes an id. Alerts are raised once by `key` (`raise_alert`);
  `job_kind` has `alerts`; `notifications.kind` has `alert`. Local TOTP is on in `config.toml` (`[auth.mfa.totp]`).
- Phase 20 (D100): `ai_models` (0052) is append-only, read through `ai_models_current()` by the platform alone; its newest row
  per kind and step is current (0056 moved the placement to Sonnet). A call's `agent_step` (draft, check, repair, grade) and
  `tokens_cached`; only a draft counts against the allowance; a check, repair or grade hangs off a live draft of the centre by
  its key's grammar, and one guarding another draft (a step taken again) is a new row (0055). `schedule_evals` queues an
  `eval_run` when called by hand (no cron since 0064, D112); `admin_calls` counts a draft refused after its check (`check:…`) as refused (0054).
- Phase 21 (D106 to D112): 0057 adds the job kind `exam_prep` (one per exam item, `exam:<item>`), `school_items.preparation`
  (the split), `request_exam_prep` (a member's ask wakes a waiting job; 0058 marks the step `woken`), the trigger on a
  confirmed exam in its window, `schedule_exam_preps` (00:10 IST), `generation_feedback` (`edit`, `again`, `replace`) with
  `record_feedback`, and `ai_generations.batched`; 0059 plan_time 00:05 IST and the sweep leaving batched rows for 25 h; 0060
  question sets at high effort; 0061 the Cost page's functions and `admin_call`'s feedback; 0062 `schedule_evals`' weekday
  set; 0063 `start_ai_call` lets the platform's own `eval_run` through the consent gate (built on 0055's body); 0064 removes
  the `schedule_evals` cron (D112).
