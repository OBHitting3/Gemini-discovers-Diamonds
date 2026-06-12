# Deliverable F — n8n Workflow Outline

## Workflow: "LeadLatch — Speed-to-Lead Autopilot"

### Trigger

**Webhook Node** (Production URL)
- Method: POST
- Path: `/webhook/lead-created`
- Authentication: None (the edge function calling this is server-side; optionally add Header Auth)

### Expected Webhook Payload

```json
{
  "lead_id": "uuid",
  "org_id": "uuid",
  "name": "Jane Doe",
  "email": "jane@example.com",
  "phone": "+15551234567",
  "message": "Interested in your service",
  "source_url": "https://example.com/landing",
  "utm_source": "google",
  "utm_medium": null,
  "utm_campaign": null,
  "created_at": "2026-02-19T12:00:00Z"
}
```

---

## Node Sequence

```
[1] Webhook Trigger
      │
[2] IF: Has Email?
      ├── Yes ──→ [3] Send Immediate Email
      │                    │
      │              [4] POST Event to Supabase (email.sent)
      │                    │
      │              [5] IF: Has Slack Config?
      │                    ├── Yes ──→ [6] Post to Slack
      │                    │                  │
      │                    │            [7] POST Event (slack.posted)
      │                    │
      │                    └── No ──→ (skip)
      │                    │
      │              [8] Wait 1 hour
      │                    │
      │              [9] Check Lead Status (GET from Supabase)
      │                    │
      │             [10] IF: Status still "new"?
      │                    ├── Yes ──→ [11] Send Follow-up #1
      │                    │                   │
      │                    │            [12] POST Event (followup.sent)
      │                    │                   │
      │                    │            [13] Wait 24 hours
      │                    │                   │
      │                    │            [14] Check Lead Status
      │                    │                   │
      │                    │            [15] IF: Status still "new" or "working"?
      │                    │                   ├── Yes → [16] Send Follow-up #2
      │                    │                   │                │
      │                    │                   │         [17] POST Event (followup.sent)
      │                    │                   │
      │                    │                   └── No → (stop, lead progressed)
      │                    │
      │                    └── No ──→ (stop, lead already progressed)
      │
      └── No ──→ [18] POST Event (automation.error, "no email")
                       │
                 [19] IF: Has Phone? → (future: SMS node)
```

---

## Node Details

### [1] Webhook Trigger
- **Type:** Webhook
- **Method:** POST
- **Response Mode:** Immediately (return 200 to caller)

### [3] Send Immediate Email
- **Type:** Send Email (SMTP or SendGrid)
- **To:** `{{ $json.email }}`
- **Subject:** `Thanks for reaching out, {{ $json.name }}!`
- **Body:** Template with lead name, personalized intro, CTA

### [4] POST Event to Supabase
- **Type:** HTTP Request
- **Method:** POST
- **URL:** `https://<supabase-project>.supabase.co/functions/v1/n8n-event-ingest`
- **Headers:**
  - `Authorization: Bearer {{ $env.ORG_WEBHOOK_SECRET }}`
  - `Content-Type: application/json`
- **Body:**
```json
{
  "lead_id": "{{ $json.lead_id }}",
  "org_id": "{{ $json.org_id }}",
  "type": "email.sent",
  "payload": {
    "subject": "Thanks for reaching out, {{ $json.name }}!",
    "template": "instant_reply"
  },
  "idempotency_key": "{{ $json.lead_id }}:email.sent:instant_reply"
}
```

### [6] Post to Slack
- **Type:** Slack (Send Message)
- **Channel:** `#leads`
- **Message:**
```
🔔 New Lead: {{ $json.name }}
Email: {{ $json.email }}
Phone: {{ $json.phone }}
Source: {{ $json.utm_source }}
```

### [9] Check Lead Status
- **Type:** HTTP Request (or Supabase Node)
- **Method:** GET
- **URL:** `https://<supabase-project>.supabase.co/rest/v1/leads?id=eq.{{ $json.lead_id }}&select=status`
- **Headers:**
  - `apikey: <SUPABASE_SERVICE_ROLE_KEY>`
  - `Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>`

### [11] Send Follow-up #1 (1 hour)
- **Type:** Send Email
- **Subject:** `Quick follow-up — {{ $json.name }}`
- **Idempotency Key:** `{{ $json.lead_id }}:followup.sent:1h`

### [16] Send Follow-up #2 (24 hours)
- **Type:** Send Email
- **Subject:** `Still interested? — {{ $json.name }}`
- **Idempotency Key:** `{{ $json.lead_id }}:followup.sent:24h`

---

## Idempotency Strategy

Every event posted to the `n8n-event-ingest` endpoint includes an `idempotency_key` constructed as:

```
{lead_id}:{event_type}:{step_identifier}
```

Examples:
- `abc-123:email.sent:instant_reply`
- `abc-123:followup.sent:1h`
- `abc-123:followup.sent:24h`
- `abc-123:slack.posted:initial`

The Supabase `lead_events` table has a UNIQUE constraint on `idempotency_key`. The `insert_lead_event_idempotent` RPC function uses `ON CONFLICT DO NOTHING`.

**Result:** If n8n retries a workflow (e.g., due to a transient failure), duplicate events are silently ignored. Each logical action is recorded exactly once.

---

## n8n Environment Variables

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key for REST API calls |
| `ORG_WEBHOOK_SECRET` | Per-org webhook secret for n8n-event-ingest auth |
| `SMTP_HOST` | SMTP server host |
| `SMTP_USER` | SMTP username |
| `SMTP_PASS` | SMTP password |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook URL (optional) |

---

## n8n Workflow JSON (importable)

The workflow can be imported into n8n via JSON. A template file is provided at:
`leadlatch/n8n/workflow-speed-to-lead.json`
