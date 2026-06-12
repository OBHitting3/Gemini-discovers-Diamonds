-- ============================================================
-- LeadLatch — RPC Functions
-- Migration 00004: Server-callable functions
-- ============================================================

-- Idempotent lead event insertion (used by n8n-event-ingest edge function)
-- Uses ON CONFLICT DO NOTHING on the idempotency_key unique constraint.
create or replace function public.insert_lead_event_idempotent(
  p_lead_id uuid,
  p_org_id uuid,
  p_type text,
  p_source text,
  p_payload jsonb,
  p_idempotency_key text
)
returns void as $$
begin
  insert into public.lead_events (lead_id, org_id, type, source, payload, idempotency_key)
  values (p_lead_id, p_org_id, p_type::lead_event_type, p_source::event_source, p_payload, p_idempotency_key)
  on conflict (idempotency_key) do nothing;
end;
$$ language plpgsql security definer;
