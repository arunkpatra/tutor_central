-- V3, Phase 18: the server's files (plan decision 20, D90, D92). Two private buckets the platform writes and the centre's
-- members read: `pdfs` (a sheet's, mock's or brief's PDF, `<centre>/<artefact>.pdf`, and a sheet's or mock's form with the
-- answers, `<centre>/<artefact>-key.pdf`) and `exports` (a student's file,
-- `<centre>/<student>/<job>.pdf`). A deleted row's files are queued in `storage_deletions`, which the sweep empties through
-- the Storage API (a row's delete cannot reach Storage itself). A kept sheet, mock or brief queues its PDF's job.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('exports', 'exports', false, 10485760, array['application/pdf']),
       ('pdfs', 'pdfs', false, 5242880, array['application/pdf'])
on conflict (id) do nothing;

create policy exports_member_read on storage.objects for select to authenticated
  using (bucket_id = 'exports' and coalesce(public.is_member(public.photo_centre(name)), false));
create policy pdfs_member_read on storage.objects for select to authenticated
  using (bucket_id = 'pdfs' and coalesce(public.is_member(public.photo_centre(name)), false));

-- The platform's: a member reads none. A row comes only from the triggers below, which set tc.forget for their insert
-- (they run as whoever deleted the row); the platform and a session with no request pass by role.
create table public.storage_deletions (
  id uuid primary key default gen_random_uuid(),
  bucket text not null check (bucket in ('photos', 'pdfs', 'exports')),
  path text not null check (char_length(path) between 1 and 300),
  prefix boolean not null default false,
  why text not null check (char_length(why) between 1 and 40),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger storage_deletions_updated before update on public.storage_deletions
  for each row execute function public.set_updated_at();
alter table public.storage_deletions enable row level security;
create policy storage_deletions_platform_only on public.storage_deletions for select to authenticated using (false);
create policy storage_deletions_from_triggers on public.storage_deletions for insert to authenticated
  with check (current_setting('tc.forget', true) = 'on');
revoke update, delete, truncate on public.storage_deletions from authenticated;

-- A row with a photo, and a printable artefact's PDF. A row deleted with its centre adds nothing: the centre's prefixes
-- cover it (its row is gone by the time the cascade reaches its children).
create function public.forget_photo() returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.centres c where c.id = old.centre_id) then return null; end if;
  perform set_config('tc.forget', 'on', true);
  if old.photo_path is not null then
    insert into public.storage_deletions (bucket, path, why) values ('photos', old.photo_path, tg_table_name);
  end if;
  if tg_table_name = 'artefacts' then  -- nested: `old.kind` is planned only for the artefacts' row
    if old.kind::text in ('sheet', 'mock', 'brief') then
      insert into public.storage_deletions (bucket, path, why) values ('pdfs', old.centre_id || '/' || old.id || '.pdf', 'artefact');
    end if;
    -- A sheet's and a mock's form with the answers (the pdf job writes both).
    if old.kind::text in ('sheet', 'mock') then
      insert into public.storage_deletions (bucket, path, why) values ('pdfs', old.centre_id || '/' || old.id || '-key.pdf', 'artefact');
    end if;
  end if;
  perform set_config('tc.forget', 'off', true);
  return null;
end $$;
create trigger artefacts_forget after delete on public.artefacts for each row execute function public.forget_photo();
create trigger school_items_forget after delete on public.school_items for each row execute function public.forget_photo();
create trigger marks_forget after delete on public.marks for each row execute function public.forget_photo();
create trigger textbooks_forget after delete on public.textbooks for each row execute function public.forget_photo();

create function public.forget_student() returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.centres c where c.id = old.centre_id) then return null; end if;
  perform set_config('tc.forget', 'on', true);
  insert into public.storage_deletions (bucket, path, prefix, why) values ('exports', old.centre_id || '/' || old.id || '/', true, 'student');
  perform set_config('tc.forget', 'off', true);
  return null;
end $$;
create trigger students_forget after delete on public.students for each row execute function public.forget_student();

create function public.forget_centre() returns trigger language plpgsql set search_path = '' as $$
begin
  perform set_config('tc.forget', 'on', true);
  insert into public.storage_deletions (bucket, path, prefix, why)
  select b, old.id || '/', true, 'centre' from unnest(array['photos', 'pdfs', 'exports']) b;
  perform set_config('tc.forget', 'off', true);
  return null;
end $$;
create trigger centres_forget after delete on public.centres for each row execute function public.forget_centre();

-- A kept sheet, mock or brief gets its PDF made on the server (D90), once per artefact.
create function public.queue_pdf() returns trigger language plpgsql set search_path = '' as $$
begin
  perform set_config('tc.jobs', 'on', true);
  insert into public.jobs (centre_id, kind, idempotency_key, input)
  values (new.centre_id, 'pdf', 'pdf:' || new.id, jsonb_build_object('artefact_id', new.id))
  on conflict do nothing;
  perform set_config('tc.jobs', 'off', true);
  return null;
end $$;
create trigger artefacts_queue_pdf after insert on public.artefacts
  for each row when (new.kind in ('sheet', 'mock', 'brief') and new.source = 'made') execute function public.queue_pdf();

-- The sweep's take: each row handed out once and removed in the same statement.
create function public.taken_storage_deletions(p_limit integer default 100)
returns setof public.storage_deletions language sql security invoker set search_path = '' as $$
  with picked as materialized (
    select d.id from public.storage_deletions d order by d.created_at limit p_limit for update skip locked)
  delete from public.storage_deletions d using picked where d.id = picked.id returning d.*;
$$;

revoke all on function public.forget_photo() from public, anon, authenticated;
revoke all on function public.forget_student() from public, anon, authenticated;
revoke all on function public.forget_centre() from public, anon, authenticated;
revoke all on function public.queue_pdf() from public, anon, authenticated;
revoke all on function public.taken_storage_deletions(integer) from public, anon, authenticated;
grant execute on function public.taken_storage_deletions(integer) to service_role;
