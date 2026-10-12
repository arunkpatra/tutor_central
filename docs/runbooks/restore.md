# Restore: the drill and the route back

What a restore of the database is, how it is practised, and what exists to restore from. Phase 17, plan decision 22; D85.

## What exists today

Until Supabase Pro is bought (D85: before the external testing round, a step of its checklist), **no copy of the database
exists anywhere**. Supabase Free keeps no backup the owner can restore. A bad migration or a deletion is final. The drill
below makes a copy for the minutes it runs and deletes it; it proves the route, it is not a backup.

With Pro, the dashboard keeps seven daily backups: Database → Backups → Restore replaces the project's data in place with
the chosen day's. Point-in-time recovery is a further $100 a month, Phase 16's call with the price. When Pro is bought,
this page gains the dashboard's steps and a drill of them.

## When to run the drill

- Once a quarter.
- After any migration that drops or rewrites data (a contract step, D26), before it goes up.
- After a change to the workflow or to `tools/restore-count.sql`.

## The drill

```bash
gh workflow run restore-drill
```

`.github/workflows/restore-drill.yml` (Production environment, about five minutes):

1. Links production and dumps its roles, schema and data with `supabase db dump`, Supabase's documented route to a new
   database.
2. Starts a blank Supabase on the runner (`supabase init`, `supabase start`): Supabase's own auth, storage and vault
   schemas, none of ours, as a new project has them.
3. Restores into it as that database's superuser (`supabase_admin`): the roles, the schema, then the data with triggers
   held off (`session_replication_role = replica`), in one transaction that stops at the first error.
4. Counts every public table on both sides (`tools/restore-count.sql`: the tables there are on each side, so production
   before a deploy's migrations is counted as it stands).

What to read in the run's summary: "Dumped and restored in N s", and the table of each public table's rows in production
and in the restored copy. Every row equal is a pass; a difference fails the run and the table shows where. The dumps stay
in the runner's temporary folder, are never uploaded as an artifact, and are deleted at the end whatever happens.

Why a blank database on the runner and not a scratch cloud project: production's organisation is Vercel-managed
(`vercel_icfg_…`), where the CLI may not create projects, and the free plan allows two. The dump and the restore are the
same either way, and the cloud route is the dashboard's restore once Pro is bought.

## What the first runs taught (session 35)

- The roles' dump grants a parameter (`GRANT SET ON PARAMETER log_min_messages`) only a superuser may: restore as
  `supabase_admin`, not `postgres`.
- `supabase db query -f` resolves the file from the repository's root, not the step's folder: pass an absolute path.
- `supabase db query --linked --output-format json` answers a bare array; `--local` answers `{ "rows": [...] }`.
- A count that names this phase's tables fails on production before its deploy: count the tables there are.

## Log

| Date | Run | Duration | Counts | Read by |
|---|---|---|---|---|
| 2026-10-12 | 38240109619 | 182 s (dump and restore) | 24 tables, every count equal (production at migration 0027) | Session 35 |
