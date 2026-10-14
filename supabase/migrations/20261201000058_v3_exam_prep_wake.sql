-- V3, Phase 21 (D106): a member's ask wakes a waiting exam job and marks its step `woken`, so the job tells a tutor's
-- Try again from its own quarter-hour tick: a mock that was not made is made again only when the tutor asks (made at
-- every tick, a failing mock would be paid for every quarter hour). Otherwise 0057's writer, unchanged.
create or replace function public.exam_prep_enqueue(p_centre uuid, p_item uuid, p_now timestamptz default now())
returns uuid language plpgsql security invoker set search_path = '' as $$
declare
  v_id uuid;
  v_key text := 'exam:' || p_item;
begin
  if not exists (select 1 from public.school_items i
                  where i.centre_id = p_centre and i.id = p_item and i.kind = 'exam' and i.confirmed_at is not null
                    and public.exam_in_window(i.date, i.window_days, p_now)) then
    raise exception 'not_found' using errcode = 'P0001';
  end if;
  perform set_config('tc.jobs', 'on', true);
  update public.jobs j set run_at = now(), step = j.step || '{"woken": true}'::jsonb
   where j.centre_id = p_centre and j.kind = 'exam_prep' and j.idempotency_key like v_key || '%'
     and j.state = 'waiting' and j.run_at > now();
  select j.id into v_id from public.jobs j
   where j.centre_id = p_centre and j.kind = 'exam_prep' and j.idempotency_key like v_key || '%'
     and j.state in ('queued', 'running', 'waiting')
   order by j.created_at desc limit 1;
  if v_id is null then
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, 'exam_prep', v_key, jsonb_build_object('item_id', p_item))
    on conflict do nothing returning id into v_id;
  end if;
  if v_id is null then
    insert into public.jobs (centre_id, kind, idempotency_key, input)
    values (p_centre, 'exam_prep', v_key || ':' || (extract(epoch from clock_timestamp()) * 1000)::bigint,
            jsonb_build_object('item_id', p_item))
    returning id into v_id;
  end if;
  perform set_config('tc.jobs', 'off', true);
  return v_id;
end $$;
