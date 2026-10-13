-- V3, Phase 20 (D99): a draft refused after its check and one repair carries error_reason `check:<item>`; the tutor read
-- the kind's refusal, so the portal's calls count it as refused (the tiles and the filter), as the chip says. 0047's
-- admin_calls otherwise.
create or replace function public.admin_calls(p_day date, p_centre uuid, p_kind text, p_status text, p_limit int)
returns jsonb language sql stable security invoker set search_path = '' as $$
  with day as (
    select * from public.ai_generations g
     where (p_day is null or (g.created_at at time zone 'Asia/Kolkata')::date = p_day)
       and (p_centre is null or g.centre_id = p_centre)
       and (p_kind is null or g.kind::text = p_kind)
       and (p_status is null or g.status::text = p_status
            or (p_status = 'refused' and (g.error_reason in ('refused', 'unfit') or g.error_reason like 'check:%'))))
  select jsonb_build_object(
    'tiles', (select jsonb_build_object(
        'calls', count(*),
        'failed', count(*) filter (where d.status = 'failed' and coalesce(d.error_reason, '') not in ('refused', 'unfit')
                                     and coalesce(d.error_reason, '') not like 'check:%'),
        'refused', count(*) filter (where d.error_reason in ('refused', 'unfit') or d.error_reason like 'check:%'),
        'median_latency_ms', percentile_cont(0.5) within group (order by d.latency_ms)) from day d),
    'rows', (select coalesce(jsonb_agg(public.admin_call_row(r.id) order by r.created_at desc), '[]'::jsonb)
               from (select * from day order by created_at desc limit p_limit) r));
$$;
