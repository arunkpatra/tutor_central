-- V3, Phase 18: push (D72). The tutor's reminder settings move from the iPhone to the account (plan decision 6), and
-- every push to be sent waits in an outbox the worker's minute tick sends through APNs (decision 7). Both are per tutor
-- and centre, like device_tokens are per tutor. The outbox is written by the platform alone, through named functions.

create table public.reminder_settings (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  class_on boolean not null default true,
  class_minutes smallint not null default 60 check (class_minutes in (5, 10, 15, 30, 60)),
  events_on boolean not null default true,
  event_lead text not null default 'hour1' check (event_lead in ('min15', 'min30', 'hour1', 'day_before')),
  fees_on boolean not null default true,
  fees_day smallint not null default 5 check (fees_day between 1 and 28),
  plan_ready_on boolean not null default true,
  notes_ready_on boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (centre_id, user_id)
);
create trigger reminder_settings_updated before update on public.reminder_settings
  for each row execute function public.set_updated_at();
alter table public.reminder_settings enable row level security;
create policy reminder_settings_self on public.reminder_settings for all to authenticated
  using (user_id = auth.uid() and public.is_member(centre_id))
  with check (user_id = auth.uid() and public.is_member(centre_id));
revoke delete, truncate on public.reminder_settings from authenticated;

-- One row per push. The key is unique per user (`<kind>:<subject>:<when>`), so a plan written again finds its rows.
-- A background push (plan_fetch) carries no words.
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('class', 'event', 'fees', 'plan_ready', 'notes_ready', 'plan_fetch')),
  key text not null check (char_length(key) between 1 and 200),
  due_at timestamptz not null,
  title text check (title is null or char_length(title) <= 200),
  body text check (body is null or char_length(body) <= 400),
  link text check (link is null or char_length(link) <= 200),
  background boolean not null default false,
  state text not null default 'due' check (state in ('due', 'sent', 'failed', 'expired', 'cancelled')),
  sent_at timestamptz,
  apns jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, key),
  check (background or (title is not null and body is not null))
);
create index notifications_due on public.notifications (due_at) where state = 'due';
create index notifications_centre on public.notifications (centre_id, created_at);
create trigger notifications_updated before update on public.notifications for each row execute function public.set_updated_at();
alter table public.notifications enable row level security;
create policy notifications_self_read on public.notifications for select to authenticated
  using (user_id = auth.uid() and public.is_member(centre_id));
revoke insert, update, delete, truncate on public.notifications from authenticated;

-- The plan of a user's pushes of some kinds from a time on: a due row it no longer writes is cancelled, the rows it
-- writes are upserted by key (a cancelled one is due again), a sent, failed or expired row is left as it is. One
-- transaction, so a class moved at 16:00 never has both its old and its new reminder due.
create function public.replace_notifications(p_centre uuid, p_user uuid, p_kinds text[], p_from timestamptz, p_rows jsonb)
returns integer language plpgsql security invoker set search_path = '' as $$
declare v_count integer;
begin
  update public.notifications n set state = 'cancelled'
   where n.user_id = p_user and n.centre_id = p_centre and n.kind = any (p_kinds) and n.state = 'due' and n.due_at >= p_from
     and n.key not in (select r->>'key' from jsonb_array_elements(coalesce(p_rows, '[]')) r);
  insert into public.notifications as n (centre_id, user_id, kind, key, due_at, title, body, link, background)
  select p_centre, p_user, r->>'kind', r->>'key', (r->>'due_at')::timestamptz, r->>'title', r->>'body', r->>'link',
         coalesce((r->>'background')::boolean, false)
    from jsonb_array_elements(coalesce(p_rows, '[]')) r
  on conflict (user_id, key) do update
     set due_at = excluded.due_at, title = excluded.title, body = excluded.body, link = excluded.link,
         background = excluded.background, kind = excluded.kind, centre_id = excluded.centre_id, state = 'due'
   where n.state in ('due', 'cancelled');
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- The rows due now, handed out once: rows due more than 30 minutes ago expire unsent (a reminder for a class already
-- begun helps no one); the rest are marked sent as they are taken, and the sender marks a refusal failed. The tick is
-- the one taker; a crash mid-send loses at most that minute's pushes.
create function public.due_notifications(p_now timestamptz, p_limit integer default 200)
returns setof public.notifications language plpgsql security invoker set search_path = '' as $$
begin
  update public.notifications set state = 'expired'
   where state = 'due' and due_at < p_now - interval '30 minutes';
  return query
  with picked as materialized (
    select n.id from public.notifications n
     where n.state = 'due' and n.due_at <= p_now
     order by n.due_at limit p_limit
     for update skip locked)
  update public.notifications n set state = 'sent', sent_at = now()
    from picked where n.id = picked.id
  returning n.*;
end $$;

create function public.mark_notification(p_id uuid, p_state text, p_apns jsonb)
returns void language sql security invoker set search_path = '' as $$
  update public.notifications set state = p_state, apns = p_apns where id = p_id;
$$;

create function public.live_tokens(p_user uuid)
returns table (id uuid, token text, environment text) language sql security invoker set search_path = '' as $$
  select t.id, t.token, t.environment from public.device_tokens t
   where t.user_id = p_user and t.retired_at is null order by t.last_seen_at desc;
$$;

create function public.retire_token(p_id uuid)
returns void language sql security invoker set search_path = '' as $$
  update public.device_tokens set retired_at = now() where id = p_id and retired_at is null;
$$;

revoke all on function public.replace_notifications(uuid, uuid, text[], timestamptz, jsonb) from public, anon, authenticated;
revoke all on function public.due_notifications(timestamptz, integer) from public, anon, authenticated;
revoke all on function public.mark_notification(uuid, text, jsonb) from public, anon, authenticated;
revoke all on function public.live_tokens(uuid) from public, anon, authenticated;
revoke all on function public.retire_token(uuid) from public, anon, authenticated;
grant execute on function public.replace_notifications(uuid, uuid, text[], timestamptz, jsonb) to service_role;
grant execute on function public.due_notifications(timestamptz, integer) to service_role;
grant execute on function public.mark_notification(uuid, text, jsonb) to service_role;
grant execute on function public.live_tokens(uuid) to service_role;
grant execute on function public.retire_token(uuid) to service_role;
