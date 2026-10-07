# supabase: rules

- One migration per change in `migrations/`, named `YYYYMMDDHHMMSS_<what>.sql`; never edit a migration that has
  run on the hosted project.
- Every centre table: `id`, `centre_id`, `created_at`, `updated_at` (trigger `set_updated_at`), RLS enabled, a
  policy through `is_member(centre_id)`, and a test in `tests/` that proves isolation. The tenancy tables
  (`centres`, `centre_members`, `profiles`) have their own policies. No policy, no merge. The catalogue
  test in `tests/rls.test.ts` fails when a public table lacks RLS or a policy, or is missing from its list.
- References between centre tables are composite, `(centre_id, x_id)` to `(centre_id, id)`, so a row can never
  point into another centre (foreign keys bypass RLS). Optional ones use `on delete set null (x_id)`.
- Multi-row operations are functions, `security invoker` so RLS applies, `set search_path = ''`; `is_member` is
  the only `security definer`. Migration 0001 revokes anonymous's grants on its tables and functions; Supabase's
  default privileges still grant anon on new ones, so a new table's migration revokes them too (RLS protects
  either way).
- Local: `supabase start` (Docker), `supabase db reset` (migrations and `seed.sql`), Studio at :54323, mail at
  :54324. Keys from `supabase status -o env`. The seed's tutor signs in as `meera@example.com` /
  `tutor-local-1`.
- Types: `supabase gen types typescript --local > types.ts` after every migration; commit it.
- Hosted: project `esowihbxawvoexflekxa`, ap-south-1 (Mumbai), beside the API in `bom1`. Migrations go up after
  the PR is merged: with the CLI logged in (`supabase login`, the owner's account) and the folder linked
  (`supabase link --project-ref esowihbxawvoexflekxa`, no password needed), `supabase db push --dry-run`, then
  `supabase db push`. Moving this
  into CI is a later decision.

Commands: `bun check --only=db` (resets the local database, runs the tests, re-seeds);
`cd supabase && bun test tests`.
