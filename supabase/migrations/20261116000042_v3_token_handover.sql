-- V3, Phase 18 review (R-app-4): a push token belongs to the tutor who registered it last on that iPhone. A tutor who
-- signed out offline keeps their row (only they may delete it); when another tutor signs in on the same iPhone, iOS
-- hands the app the same token, and the first tutor's row must no longer be sent to. The app also unregisters from
-- APNs at sign-out, so Apple answers 410 for the token and the sender retires it.

create or replace function public.live_tokens(p_user uuid)
returns table (id uuid, token text, environment text) language sql security invoker set search_path = '' as $$
  select t.id, t.token, t.environment from public.device_tokens t
   where t.user_id = p_user and t.retired_at is null
     and not exists (
       select 1 from public.device_tokens o
        where o.token = t.token and o.user_id <> t.user_id and o.retired_at is null and o.last_seen_at > t.last_seen_at)
   order by t.last_seen_at desc;
$$;
