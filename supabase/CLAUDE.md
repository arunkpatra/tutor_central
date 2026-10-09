# supabase: rules

- One migration per change in `migrations/`, named `YYYYMMDDHHMMSS_<what>.sql`; never edit a migration that has
  run on the hosted project.
- Every centre table: `id`, `centre_id`, `created_at`, `updated_at` (trigger `set_updated_at`), RLS enabled, a
  policy through `is_member(centre_id)`, and a test in `tests/` that proves isolation. The tenancy tables
  (`centres`, `centre_members`, `profiles`) have their own policies. No policy, no merge. The catalogue
  test in `tests/rls.test.ts` fails when a public table lacks RLS or a policy, or is missing from its list.
- References between centre tables are composite, `(centre_id, x_id)` to `(centre_id, id)`, so a row can never
  point into another centre (foreign keys bypass RLS). Optional ones use `on delete set null (x_id)`.
- Multi-row operations are functions, `security invoker` so RLS applies, `set search_path = ''`; `is_member` and
  `delete_account` are the only `security definer` functions (D37), each with its reason in its migration. Since
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
  `gh workflow run deploy`; the run's summary shows what was pending and that nothing is after. Migrations 0001 to
  0007 are on the hosted project. Its secrets (`SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`) are in the GitHub
  environment `Production`. 0001 was the only hand push.

- App Review's demo centre (D51): `gh workflow run seed-review -f email=… -f parent_phone=…` fills an existing account's
  centre with a sample centre (`tools/review-seed.ts`, tested by `tests/review-seed.test.ts`); it refuses a centre that
  already has students. The account itself is made by the owner (Supabase dashboard), never by a script.

Commands: `bun check --only=db` (resets the local database, runs the tests, re-seeds);
`cd supabase && bun test tests`.
