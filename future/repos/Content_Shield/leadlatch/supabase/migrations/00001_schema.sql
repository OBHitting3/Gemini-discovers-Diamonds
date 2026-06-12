-- ============================================================
-- LeadLatch — Database Schema (Deliverable B)
-- Migration 00001: Core tables
-- ============================================================

-- Enable required extensions
create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================
-- 1. ORGANIZATIONS
-- ============================================================
create table public.organizations (
  id            uuid primary key default uuid_generate_v4(),
  name          text not null,
  slug          text not null unique,
  webhook_secret text not null default encode(gen_random_bytes(32), 'hex'),
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index idx_organizations_slug on public.organizations(slug);

-- ============================================================
-- 2. MEMBERSHIPS (join table: user <-> org)
-- ============================================================
create type public.member_role as enum ('owner', 'admin', 'member');

create table public.memberships (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  org_id     uuid not null references public.organizations(id) on delete cascade,
  role       public.member_role not null default 'member',
  created_at timestamptz not null default now(),
  unique(user_id, org_id)
);

create index idx_memberships_user on public.memberships(user_id);
create index idx_memberships_org on public.memberships(org_id);

-- ============================================================
-- 3. PROFILES (denormalized user metadata)
-- ============================================================
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 4. LEADS
-- ============================================================
create type public.lead_status as enum ('new', 'working', 'won', 'lost');

create table public.leads (
  id           uuid primary key default uuid_generate_v4(),
  org_id       uuid not null references public.organizations(id) on delete cascade,
  name         text not null,
  email        text,
  phone        text,
  message      text,
  source_url   text,
  utm_source   text,
  utm_medium   text,
  utm_campaign text,
  utm_term     text,
  utm_content  text,
  status       public.lead_status not null default 'new',
  assigned_to  uuid references auth.users(id) on delete set null,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index idx_leads_org on public.leads(org_id);
create index idx_leads_status on public.leads(org_id, status);
create index idx_leads_created on public.leads(org_id, created_at desc);

-- ============================================================
-- 5. LEAD EVENTS (deterministic event log)
-- ============================================================
create type public.lead_event_type as enum (
  'lead.created',
  'lead.status_changed',
  'lead.assigned',
  'note',
  'email.sent',
  'email.opened',
  'email.clicked',
  'sms.sent',
  'call.completed',
  'slack.posted',
  'followup.scheduled',
  'followup.sent',
  'automation.error'
);

create type public.event_source as enum ('app', 'n8n', 'system');

create table public.lead_events (
  id              uuid primary key default uuid_generate_v4(),
  lead_id         uuid not null references public.leads(id) on delete cascade,
  org_id          uuid not null references public.organizations(id) on delete cascade,
  type            public.lead_event_type not null,
  source          public.event_source not null default 'app',
  payload         jsonb not null default '{}',
  idempotency_key text unique,
  created_by      uuid references auth.users(id) on delete set null,
  created_at      timestamptz not null default now()
);

create index idx_lead_events_lead on public.lead_events(lead_id, created_at desc);
create index idx_lead_events_org on public.lead_events(org_id);
create index idx_lead_events_idempotency on public.lead_events(idempotency_key)
  where idempotency_key is not null;

-- ============================================================
-- 6. AUTOMATION RULES
-- ============================================================
create table public.automation_rules (
  id              uuid primary key default uuid_generate_v4(),
  org_id          uuid not null references public.organizations(id) on delete cascade,
  template_name   text not null,
  enabled         boolean not null default true,
  webhook_url     text,
  followup_cadence jsonb not null default '[]',
  config          jsonb not null default '{}',
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index idx_automation_rules_org on public.automation_rules(org_id);

-- ============================================================
-- TRIGGERS: auto-update updated_at
-- ============================================================
create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger trg_organizations_updated
  before update on public.organizations
  for each row execute function public.set_updated_at();

create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

create trigger trg_leads_updated
  before update on public.leads
  for each row execute function public.set_updated_at();

create trigger trg_automation_rules_updated
  before update on public.automation_rules
  for each row execute function public.set_updated_at();

-- ============================================================
-- FUNCTION: auto-create profile on user signup
-- ============================================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'full_name', ''));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
