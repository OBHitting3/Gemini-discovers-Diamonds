# Deliverable A — Architecture Overview

## System Name
**LeadLatch** — Speed-to-Lead Autopilot

## Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        PUBLIC INTERNET                          │
│                                                                 │
│  ┌──────────────┐    ┌──────────────────┐   ┌───────────────┐  │
│  │  Landing Page │    │  External Forms   │   │  Zapier/API   │  │
│  │  (any site)   │    │  (Webflow, etc.)  │   │  Integrations │  │
│  └──────┬───────┘    └────────┬─────────┘   └──────┬────────┘  │
│         │                     │                     │           │
│         └─────────┬───────────┴─────────────────────┘           │
│                   ▼                                             │
│  ┌────────────────────────────────┐                             │
│  │  Supabase Edge Function        │                             │
│  │  POST /lead-intake             │  (public, rate-limited)     │
│  │  - validates payload           │                             │
│  │  - inserts lead + lead_event   │                             │
│  │  - fires n8n webhook           │                             │
│  └────────────────┬───────────────┘                             │
│                   │                                             │
│         ┌─────────┴──────────┐                                  │
│         ▼                    ▼                                  │
│  ┌─────────────┐    ┌──────────────┐                            │
│  │  Supabase   │    │    n8n       │                            │
│  │  Postgres   │    │  (workflow)  │                            │
│  │  + RLS      │    │             │                             │
│  └──────┬──────┘    │  - send email│                            │
│         │           │  - schedule  │                            │
│         │           │    follow-ups│                            │
│         │           │  - post Slack│                            │
│         │           └──────┬───────┘                            │
│         │                  │                                    │
│         │    ┌─────────────┘                                    │
│         │    ▼                                                  │
│         │  ┌────────────────────────────┐                       │
│         │  │  Supabase Edge Function    │                       │
│         │  │  POST /n8n-event-ingest    │  (API-key secured)    │
│         │  │  - appends lead_events     │                       │
│         │  │  - updates lead status     │                       │
│         │  └────────────────────────────┘                       │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────┐                            │
│  │  Next.js Web App (App Router)   │                            │
│  │  - Auth (magic link / password) │                            │
│  │  - Dashboard: leads list        │                            │
│  │  - Lead detail + timeline       │                            │
│  │  - Org switcher                 │                            │
│  │  - Settings                     │                            │
│  └─────────────────────────────────┘                            │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow

### 1. Lead Capture (Inbound)
1. External form POSTs JSON to `POST /lead-intake` (Supabase Edge Function).
2. Edge function validates required fields, inserts `leads` row (status=new) using service role.
3. Inserts a `lead_events` row (type=`lead.created`, source=`app`).
4. Fires an async HTTP POST to the n8n webhook URL with the full lead payload.
5. Returns `{ ok: true, lead_id }` to the caller.

### 2. Automation (n8n)
1. n8n receives the webhook payload.
2. **Immediate reply node**: sends email via SMTP/SendGrid.
3. **Slack notification node** (optional): posts to a channel.
4. **Wait node**: schedules follow-up cadence (e.g., 1h, 24h, 72h).
5. After each action, n8n calls `POST /n8n-event-ingest` to record the event.
6. Idempotency: n8n includes an `idempotency_key` (lead_id + action + step). The ingest endpoint uses `ON CONFLICT DO NOTHING`.

### 3. Dashboard (Web App)
1. User authenticates via Supabase Auth (magic link or email/password).
2. Middleware validates session and injects org context.
3. Dashboard fetches leads scoped to the user's organization via RLS.
4. Lead detail page shows contact info, event timeline, and note input.
5. Notes are inserted as `lead_events` (type=`note`, source=`app`).

## Tech Stack

| Layer            | Technology                         |
|------------------|------------------------------------|
| Frontend         | Next.js 15 (App Router) + TypeScript |
| Styling          | Tailwind CSS v4                    |
| Auth             | Supabase Auth (magic link + password) |
| Database         | Supabase Postgres                  |
| Row-Level Security | Supabase RLS policies            |
| Edge Functions   | Supabase Edge Functions (Deno/TypeScript) |
| Automation       | n8n (self-hosted or cloud)         |
| Email            | SendGrid / SMTP (via n8n)          |
| Chat             | Slack Incoming Webhook (via n8n)   |

## Key Design Decisions

1. **Multi-tenant via `org_id` foreign key**: Every data table includes `org_id`. RLS policies filter by the user's org memberships.
2. **Event sourcing lite**: All system and human actions produce `lead_events` rows. The timeline is the single source of truth for what happened.
3. **n8n as external orchestrator**: Keeps automation logic outside the app. The app only provides intake and ingest endpoints.
4. **Idempotency**: The `lead_events` table has a unique constraint on `idempotency_key` to prevent duplicate automation events.
5. **Service role isolation**: Edge functions that write data use the service role key. The web client uses the anon key and relies on RLS.
