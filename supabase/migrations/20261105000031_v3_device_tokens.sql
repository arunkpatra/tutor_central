-- V3, Phase 17: push tokens per user and device (D72), filled in Phase 18. Keyed by the user like `profiles` (plan
-- decision 3): a token is the user's on that device, whichever centre they open. Retired on Apple's 410.

create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  device_id text not null check (char_length(device_id) between 1 and 100),
  token text not null check (char_length(token) between 1 and 400),
  environment text not null check (environment in ('sandbox', 'production')),
  app_build integer,
  last_seen_at timestamptz not null default now(),
  retired_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, device_id)
);
create trigger device_tokens_updated before update on public.device_tokens for each row execute function public.set_updated_at();
alter table public.device_tokens enable row level security;
create policy device_tokens_self on public.device_tokens for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
