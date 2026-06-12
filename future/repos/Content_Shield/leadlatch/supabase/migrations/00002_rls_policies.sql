-- ============================================================
-- LeadLatch — RLS Policies (Deliverable C)
-- Migration 00002: Row Level Security
-- ============================================================

-- Enable RLS on all tables
alter table public.organizations enable row level security;
alter table public.memberships enable row level security;
alter table public.profiles enable row level security;
alter table public.leads enable row level security;
alter table public.lead_events enable row level security;
alter table public.automation_rules enable row level security;

-- ============================================================
-- Helper: get orgs the current user belongs to
-- ============================================================
create or replace function public.user_org_ids()
returns setof uuid as $$
  select org_id from public.memberships where user_id = auth.uid();
$$ language sql security definer stable;

-- ============================================================
-- ORGANIZATIONS
-- Users can see orgs they belong to.
-- Only owners can update their org.
-- ============================================================
create policy "Members can view their orgs"
  on public.organizations for select
  using (id in (select public.user_org_ids()));

create policy "Owners can update their org"
  on public.organizations for update
  using (
    id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- Insert: any authenticated user can create an org (they become owner via app logic)
create policy "Authenticated users can create orgs"
  on public.organizations for insert
  with check (auth.uid() is not null);

-- ============================================================
-- MEMBERSHIPS
-- Users can see memberships for their orgs.
-- Owners/admins can insert/update memberships.
-- ============================================================
create policy "Members can view org memberships"
  on public.memberships for select
  using (org_id in (select public.user_org_ids()));

create policy "Owners and admins can add members"
  on public.memberships for insert
  with check (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role in ('owner', 'admin')
    )
    -- Also allow self-insert when creating a new org (no membership yet)
    or (user_id = auth.uid())
  );

create policy "Owners can update memberships"
  on public.memberships for update
  using (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role = 'owner'
    )
  );

create policy "Owners can remove members"
  on public.memberships for delete
  using (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- ============================================================
-- PROFILES
-- Users can see profiles of people in their orgs.
-- Users can only update their own profile.
-- ============================================================
create policy "Users can view profiles in their orgs"
  on public.profiles for select
  using (
    id = auth.uid()
    or id in (
      select m.user_id from public.memberships m
      where m.org_id in (select public.user_org_ids())
    )
  );

create policy "Users can update own profile"
  on public.profiles for update
  using (id = auth.uid());

create policy "System can insert profiles"
  on public.profiles for insert
  with check (id = auth.uid());

-- ============================================================
-- LEADS
-- Scoped to org membership. Members can read, admins+ can write.
-- ============================================================
create policy "Members can view org leads"
  on public.leads for select
  using (org_id in (select public.user_org_ids()));

create policy "Admins can insert leads"
  on public.leads for insert
  with check (org_id in (select public.user_org_ids()));

create policy "Admins can update leads"
  on public.leads for update
  using (org_id in (select public.user_org_ids()));

create policy "Owners can delete leads"
  on public.leads for delete
  using (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role = 'owner'
    )
  );

-- ============================================================
-- LEAD EVENTS
-- Scoped to org membership. Read-only for members; app inserts via server.
-- ============================================================
create policy "Members can view org lead events"
  on public.lead_events for select
  using (org_id in (select public.user_org_ids()));

create policy "Members can insert lead events (notes)"
  on public.lead_events for insert
  with check (
    org_id in (select public.user_org_ids())
    and source = 'app'
  );

-- n8n inserts use service role key, bypassing RLS.
-- No update/delete policies: events are append-only.

-- ============================================================
-- AUTOMATION RULES
-- Scoped to org membership.
-- ============================================================
create policy "Members can view automation rules"
  on public.automation_rules for select
  using (org_id in (select public.user_org_ids()));

create policy "Admins can manage automation rules"
  on public.automation_rules for insert
  with check (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role in ('owner', 'admin')
    )
  );

create policy "Admins can update automation rules"
  on public.automation_rules for update
  using (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role in ('owner', 'admin')
    )
  );

create policy "Owners can delete automation rules"
  on public.automation_rules for delete
  using (
    org_id in (
      select org_id from public.memberships
      where user_id = auth.uid() and role = 'owner'
    )
  );
