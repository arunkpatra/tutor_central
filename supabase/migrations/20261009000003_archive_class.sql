-- Archive a class (Phase 3): it leaves every list and count; its students stay, with no class. Two statements in one
-- transaction, so a function; security invoker, so RLS decides what the caller may touch.

create function public.archive_class(p_class uuid) returns void
language plpgsql security invoker set search_path = '' as $$
declare cid uuid;
begin
  update public.classes set archived_at = coalesce(archived_at, now()) where id = p_class returning centre_id into cid;
  if cid is null then raise exception 'no such class' using errcode = '42501'; end if;
  update public.students set class_id = null where centre_id = cid and class_id = p_class;
end $$;

revoke all on function public.archive_class(uuid) from public, anon;
grant execute on function public.archive_class(uuid) to authenticated;
