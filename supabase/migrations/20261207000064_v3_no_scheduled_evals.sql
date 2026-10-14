-- V3, Phase 21 (D112): no schedule spends on AI calls. The nightly evals are no longer queued by pg_cron; a run is queued
-- by hand (`select public.schedule_evals()` through `supabase db query --linked`, or an eval_run job with its kinds), and the
-- golden sets run locally with `bun evals`. The function stays for the hand.
select cron.unschedule('schedule_evals');
