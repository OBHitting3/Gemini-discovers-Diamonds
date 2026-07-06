-- Palm Springs Paradise — cold-path tables for Supabase REST (PostgREST)
-- Apply via: supabase db push (Manus/Karl after review)
-- RLS: enabled on all tables; Roblox server uses anon key + user-scoped policies

-- Plot furniture layouts (JSONB placements)
create table if not exists public.psp_plot_layouts (
    id uuid primary key default gen_random_uuid(),
    roblox_user_id bigint not null,
    plot_id smallint not null check (plot_id between 1 and 4),
    home_style text,
    layout jsonb not null default '[]'::jsonb,
    updated_at timestamptz not null default now(),
    unique (roblox_user_id, plot_id)
);

-- Garden event history
create table if not exists public.psp_garden_events (
    id uuid primary key default gen_random_uuid(),
    roblox_user_id bigint not null,
    plot_index smallint not null,
    event_type text not null check (event_type in ('plant', 'water', 'harvest', 'wilt', 'dead')),
    plant_id text,
    metadata jsonb default '{}'::jsonb,
    created_at timestamptz not null default now()
);

create index if not exists idx_psp_garden_events_user_time
    on public.psp_garden_events (roblox_user_id, created_at desc);

-- Fashion runway results
create table if not exists public.psp_fashion_results (
    id uuid primary key default gen_random_uuid(),
    event_id text not null,
    roblox_user_id bigint not null,
    theme text,
    score integer default 0,
    placement smallint,
    outfit jsonb default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- Shop transactions (audit)
create table if not exists public.psp_transactions (
    id uuid primary key default gen_random_uuid(),
    roblox_user_id bigint not null,
    counterparty_user_id bigint,
    shop_id smallint,
    item_id text,
    quantity integer not null default 1,
    sun_coins integer not null,
    direction text not null check (direction in ('buy', 'sell', 'tax', 'grant')),
    created_at timestamptz not null default now()
);

-- Analytics / telemetry (batch from game)
create table if not exists public.psp_analytics (
    id uuid primary key default gen_random_uuid(),
    roblox_user_id bigint,
    event_name text not null,
    payload jsonb default '{}'::jsonb,
    created_at timestamptz not null default now()
);

-- RLS
alter table public.psp_plot_layouts enable row level security;
alter table public.psp_garden_events enable row level security;
alter table public.psp_fashion_results enable row level security;
alter table public.psp_transactions enable row level security;
alter table public.psp_analytics enable row level security;

-- Policies: server writes via service role OR scoped anon with roblox_user_id header
-- TODO(Manus): tighten to match your auth model before production.
-- Example read-own-row (adjust when using custom JWT):

create policy "psp_plot_layouts_select_own"
    on public.psp_plot_layouts for select
    using (true);

create policy "psp_plot_layouts_upsert_own"
    on public.psp_plot_layouts for insert
    with check (true);

create policy "psp_garden_events_insert"
    on public.psp_garden_events for insert
    with check (true);

create policy "psp_fashion_results_insert"
    on public.psp_fashion_results for insert
    with check (true);

create policy "psp_transactions_insert"
    on public.psp_transactions for insert
    with check (true);

create policy "psp_analytics_insert"
    on public.psp_analytics for insert
    with check (true);

comment on table public.psp_plot_layouts is 'Cold path: detailed furniture placement per residential plot';
