-- Account deletion (Phase 7, D37): the signed-in user deletes themselves. The second security definer function beside
-- is_member: deleting from auth.users needs the owner's rights, and only auth.uid() may be deleted. 0001's cascades take
-- the centre, every centre table, the membership, the profile and the identities. Proven on the local stack 2026-10-09.
create function public.delete_account() returns void
language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'sign in first' using errcode = '42501'; end if;
  delete from auth.users where id = auth.uid();
end $$;

revoke all on function public.delete_account() from public, anon;
grant execute on function public.delete_account() to authenticated;
