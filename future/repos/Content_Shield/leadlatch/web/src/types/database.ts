export type MemberRole = "owner" | "admin" | "member";
export type LeadStatus = "new" | "working" | "won" | "lost";
export type LeadEventType =
  | "lead.created"
  | "lead.status_changed"
  | "lead.assigned"
  | "note"
  | "email.sent"
  | "email.opened"
  | "email.clicked"
  | "sms.sent"
  | "call.completed"
  | "slack.posted"
  | "followup.scheduled"
  | "followup.sent"
  | "automation.error";
export type EventSource = "app" | "n8n" | "system";

export interface Organization {
  id: string;
  name: string;
  slug: string;
  webhook_secret: string;
  created_at: string;
  updated_at: string;
}

export interface Membership {
  id: string;
  user_id: string;
  org_id: string;
  role: MemberRole;
  created_at: string;
}

export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
  created_at: string;
  updated_at: string;
}

export interface Lead {
  id: string;
  org_id: string;
  name: string;
  email: string | null;
  phone: string | null;
  message: string | null;
  source_url: string | null;
  utm_source: string | null;
  utm_medium: string | null;
  utm_campaign: string | null;
  utm_term: string | null;
  utm_content: string | null;
  status: LeadStatus;
  assigned_to: string | null;
  created_at: string;
  updated_at: string;
}

export interface LeadEvent {
  id: string;
  lead_id: string;
  org_id: string;
  type: LeadEventType;
  source: EventSource;
  payload: Record<string, unknown>;
  idempotency_key: string | null;
  created_by: string | null;
  created_at: string;
}

export interface AutomationRule {
  id: string;
  org_id: string;
  template_name: string;
  enabled: boolean;
  webhook_url: string | null;
  followup_cadence: FollowupStep[];
  config: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface FollowupStep {
  delay_minutes: number;
  action: string;
  template: string;
}

export interface MembershipWithOrg extends Membership {
  organizations: Organization;
}
