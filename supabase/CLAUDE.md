# supabase: rules

- One migration per change in `migrations/`, named `YYYYMMDDHHMMSS_<what>.sql`; never edit a migration that has
  run on the hosted project.
- Every table: `id`, `centre_id`, `created_at`, `updated_at` (trigger `set_updated_at`), RLS enabled, a policy
  through `is_member(centre_id)`, and a test in `tests/` that proves isolation. No policy, no merge. The catalogue
  test in `tests/rls.test.ts` fails when a public table lacks RLS or a policy, or is missing from its list.
- References between centre tables are composite, `(centre_id, x_id)` to `(centre_id, id)`, so a row can never
  point into another centre (foreign keys bypass RLS). Optional ones use `on delete set null (x_id)`.
- Multi-row operations are functions, `security invoker` so RLS applies, `set search_path = ''`; `is_member` is
  the only `security definer`. Anonymous has no grants on tables or functions.
- Local: `supabase start` (Docker), `supabase db reset` (migrations and `seed.sql`), Studio at :54323, mail at
  :54324. Keys from `supabase status -o env`. The seed's tutor signs in as `meera@example.com` /
  `tutor-local-1`.
- Types: `supabase gen types typescript --local > types.ts` after every migration; commit it.
- Hosted: project `ctxtacacrbkrmctluahk` (Mumbai). Migrations go up with `supabase db push` after the PR is
  merged, run by the owner (the database password is his) until a decision moves it into CI.

Commands: `bun check --only=db` (resets the local database, runs the tests, re-seeds);
`cd supabase && bun test tests`.
