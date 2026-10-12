-- V3, Phase 18 review (R-db-2): a queued storage deletion goes only once Storage removed its files. 0040's take deleted
-- the rows as it handed them out, so a Storage error left their files for good (an account's three prefixes among them).
-- Now the take marks a row taken; the sweep removes the row after the files (`done_storage_deletion`); a row taken and
-- not done (the sweep failed or was cut off) is handed out again after ten minutes.

alter table public.storage_deletions add column taken_at timestamptz;

create or replace function public.taken_storage_deletions(p_limit integer default 100)
returns setof public.storage_deletions language sql security invoker set search_path = '' as $$
  with picked as materialized (
    select d.id from public.storage_deletions d
     where d.taken_at is null or d.taken_at < now() - interval '10 minutes'
     order by d.created_at limit p_limit for update skip locked)
  update public.storage_deletions d set taken_at = now() from picked where d.id = picked.id returning d.*;
$$;

create function public.done_storage_deletion(p_id uuid)
returns void language sql security invoker set search_path = '' as $$
  delete from public.storage_deletions where id = p_id;
$$;

revoke all on function public.done_storage_deletion(uuid) from public, anon, authenticated;
grant execute on function public.done_storage_deletion(uuid) to service_role;
