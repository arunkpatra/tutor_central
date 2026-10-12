-- V3, Phase 17: observability in our own tables (D77, plan decision 13). `events` is the tutor's activity by kind, never
-- content; `api_requests` is every API request but /health with its request id; `alerts` and `admin_audit` are the
-- platform's alone and empty until Phase 19. A member reads their centre's events and requests; nothing a member writes
-- can be changed or removed (no update or delete policy).

create table public.events (
  id uuid primary key default gen_random_uuid(),
  centre_id uuid not null references public.centres(id) on delete cascade,
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  kind text not null check (kind ~ '^[a-z_]{2,40}$'),
  screen text check (screen is null or char_length(screen) between 1 and 40),
  at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index events_centre_at on public.events (centre_id, at);
create trigger events_updated before update on public.events for each row execute function public.set_updated_at();
alter table public.events enable row level security;
create policy events_member_insert on public.events for insert to authenticated
  with check (public.is_member(centre_id) and user_id = auth.uid());
create policy events_member_read on public.events for select to authenticated using (public.is_member(centre_id));

-- centre_id is null for a request that names no centre (a 401, /account/*): plan decision 3.
create table public.api_requests (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null,
  route text not null check (char_length(route) between 1 and 200),
  method text not null check (char_length(method) between 1 and 10),
  status integer not null,
  latency_ms integer not null check (latency_ms >= 0),
  user_id uuid,
  centre_id uuid references public.centres(id) on delete cascade,
  reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index api_requests_created on public.api_requests (created_at);
create index api_requests_user on public.api_requests (user_id, created_at) where user_id is not null;
create index api_requests_centre on public.api_requests (centre_id, created_at) where centre_id is not null;
create trigger api_requests_updated before update on public.api_requests for each row execute function public.set_updated_at();
alter table public.api_requests enable row level security;
create policy api_requests_member_read on public.api_requests for select to authenticated using (public.is_member(centre_id));

-- An alarm or an admin's action may be the platform's own: centre_id nullable (plan decision 3).
create table public.alerts (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (char_length(kind) between 1 and 60),
  threshold numeric,
  value numeric,
  centre_id uuid references public.centres(id) on delete cascade,
  raised_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index alerts_raised on public.alerts (raised_at);
create trigger alerts_updated before update on public.alerts for each row execute function public.set_updated_at();
alter table public.alerts enable row level security;
create policy alerts_platform_only on public.alerts for select to authenticated using (false);

create table public.admin_audit (
  id uuid primary key default gen_random_uuid(),
  admin_user_id uuid not null,
  action text not null check (char_length(action) between 1 and 60),
  centre_id uuid references public.centres(id) on delete set null,
  target jsonb not null default '{}',
  reason text,
  ip text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index admin_audit_created on public.admin_audit (created_at);
create trigger admin_audit_updated before update on public.admin_audit for each row execute function public.set_updated_at();
alter table public.admin_audit enable row level security;
create policy admin_audit_platform_only on public.admin_audit for select to authenticated using (false);
