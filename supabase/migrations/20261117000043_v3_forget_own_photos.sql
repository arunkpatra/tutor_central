-- V3, Phase 18 review (R-db-1): a row's photo is queued for the platform's deletion only when its path is under the
-- row's own centre. `photo_path` is free text a member writes; without this a member of one centre could put another
-- centre's path on their own row, delete the row, and have the sweep (the platform) remove that centre's photo.

create or replace function public.forget_photo() returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists (select 1 from public.centres c where c.id = old.centre_id) then return null; end if;
  perform set_config('tc.forget', 'on', true);
  if old.photo_path is not null and public.photo_centre(old.photo_path) = old.centre_id then
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
