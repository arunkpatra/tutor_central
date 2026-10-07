-- Onboarding is one screen and one call: the centre, the owner membership and the tutor's name (Phase 2).
-- The function is replaced with a third parameter; migration 0001 is not edited.

drop function public.create_centre(text, text);

create function public.create_centre(p_name text, p_whatsapp text default null, p_display_name text default null)
returns uuid
language plpgsql security invoker set search_path = '' as $$
declare cid uuid;
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode = '42501'; end if;
  insert into public.centres (owner_id, name, whatsapp_number) values (auth.uid(), p_name, p_whatsapp) returning id into cid;
  insert into public.centre_members (centre_id, user_id, role) values (cid, auth.uid(), 'owner');
  insert into public.profiles (user_id, display_name) values (auth.uid(), p_display_name)
    on conflict (user_id) do update set display_name = coalesce(excluded.display_name, public.profiles.display_name);
  return cid;
end $$;

revoke all on function public.create_centre(text, text, text) from public, anon;
grant execute on function public.create_centre(text, text, text) to authenticated;

-- Deferred from the Phase 1 review: Supabase's default privileges grant anon on future tables and functions.
-- RLS protects either way; this closes the door for what later migrations create.
alter default privileges in schema public revoke all on tables from anon;
alter default privileges in schema public revoke all on functions from anon;
-- Execute for PUBLIC on new functions is Postgres's global default, which a per-schema rule cannot remove.
alter default privileges revoke execute on functions from public;
alter default privileges in schema public revoke all on sequences from anon;
