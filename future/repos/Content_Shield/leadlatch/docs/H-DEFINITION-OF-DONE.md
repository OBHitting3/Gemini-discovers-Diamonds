# Deliverable H — Definition of Done & Test Plan

## Definition of Done Checklist

### Database & Security
- [ ] All 4 SQL migrations run without error on a fresh Supabase project
- [ ] RLS is enabled on all 6 tables
- [ ] Users can only query leads/events belonging to their organization
- [ ] Service role key bypasses RLS (used by Edge Functions)
- [ ] `idempotency_key` unique constraint prevents duplicate events
- [ ] `handle_new_user()` trigger creates a profile row on signup
- [ ] `set_updated_at()` trigger fires on row updates

### Edge Functions
- [ ] `POST /lead-intake` accepts valid payload and returns `{ ok: true, lead_id }`
- [ ] `POST /lead-intake` rejects missing `name` with 400
- [ ] `POST /lead-intake` rejects missing `x-org-id` header with 400
- [ ] `POST /lead-intake` inserts a `leads` row with status `new`
- [ ] `POST /lead-intake` inserts a `lead_events` row with type `lead.created`
- [ ] `POST /lead-intake` fires the n8n webhook (non-blocking)
- [ ] `POST /n8n-event-ingest` rejects missing/invalid Bearer token with 401/403
- [ ] `POST /n8n-event-ingest` validates event type against allowed enum
- [ ] `POST /n8n-event-ingest` inserts event and returns `{ ok: true }`
- [ ] `POST /n8n-event-ingest` handles duplicate idempotency_key gracefully (returns 200)
- [ ] `POST /n8n-event-ingest` can optionally update lead status

### Web App — Auth
- [ ] User can sign up with email + password
- [ ] User can sign in with email + password
- [ ] User can sign in via magic link
- [ ] Auth callback route exchanges code for session
- [ ] Unauthenticated users are redirected from `/dashboard` to `/auth/login`
- [ ] Authenticated users are redirected from `/auth` to `/dashboard`
- [ ] User can sign out

### Web App — Dashboard
- [ ] Dashboard shows lead count stats per status
- [ ] Org switcher displays all user's organizations
- [ ] Org switcher changes the active org context
- [ ] Org context persists across page reloads (localStorage)

### Web App — Leads
- [ ] Leads list shows all leads for the active org
- [ ] Leads list supports status filter dropdown
- [ ] Leads list supports search by name/email/phone
- [ ] Leads list links to lead detail page
- [ ] Lead detail shows contact info (name, email, phone, message, UTM data)
- [ ] Lead detail shows status badge with dropdown to change status
- [ ] Changing status records a `lead.status_changed` event
- [ ] Lead detail shows event timeline in reverse chronological order
- [ ] Timeline events are color-coded by source (app/n8n/system)
- [ ] User can add a note (creates `note` event in timeline)

### Web App — Settings
- [ ] User can create a new organization
- [ ] Creating an org auto-creates an `owner` membership
- [ ] Settings page shows org info (name, slug, ID, role)
- [ ] Settings page shows the lead-intake endpoint URL and example cURL
- [ ] Settings page shows the webhook secret (revealable)

### n8n Workflow
- [ ] Workflow JSON can be imported into n8n without errors
- [ ] Webhook trigger receives lead payload
- [ ] Email is sent immediately on new lead
- [ ] Event is logged to Supabase after email send
- [ ] Slack notification is posted (when configured)
- [ ] 1-hour follow-up fires if lead is still `new`
- [ ] 24-hour follow-up fires if lead is not `won`/`lost`
- [ ] Idempotency keys prevent duplicate events on workflow retries

### Code Quality
- [ ] TypeScript compiles with zero errors (`tsc --noEmit`)
- [ ] No unused dependencies in `package.json`
- [ ] All environment variables documented in `.env.local.example`

---

## Test Plan

### 1. Integration Tests (Manual via cURL)

#### Test 1.1: Lead Intake — Happy Path
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/lead-intake \
  -H "Content-Type: application/json" \
  -H "x-org-id: <ORG_ID>" \
  -d '{
    "name": "Test Lead",
    "email": "test@example.com",
    "phone": "+15551234567",
    "message": "Integration test lead",
    "source_url": "https://example.com",
    "utm_source": "test"
  }'
```
**Expected:** `200 { "ok": true, "lead_id": "<uuid>" }`

**Verify:**
- Lead appears in `leads` table with status `new`
- `lead_events` has a `lead.created` row for this lead
- n8n webhook received the payload (check n8n execution log)

#### Test 1.2: Lead Intake — Missing Name
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/lead-intake \
  -H "Content-Type: application/json" \
  -H "x-org-id: <ORG_ID>" \
  -d '{"email": "test@example.com"}'
```
**Expected:** `400 { "error": "name is required" }`

#### Test 1.3: Lead Intake — Missing Org ID
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/lead-intake \
  -H "Content-Type: application/json" \
  -d '{"name": "Test"}'
```
**Expected:** `400 { "error": "Missing x-org-id header" }`

#### Test 1.4: n8n Event Ingest — Happy Path
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/n8n-event-ingest \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ORG_WEBHOOK_SECRET>" \
  -d '{
    "lead_id": "<LEAD_ID>",
    "org_id": "<ORG_ID>",
    "type": "email.sent",
    "payload": {"subject": "Test email", "template": "instant_reply"},
    "idempotency_key": "<LEAD_ID>:email.sent:instant_reply"
  }'
```
**Expected:** `200 { "ok": true }`

**Verify:** `lead_events` has a new `email.sent` row with source `n8n`.

#### Test 1.5: n8n Event Ingest — Duplicate Idempotency Key
Run Test 1.4 again with the same `idempotency_key`.

**Expected:** `200 { "ok": true, "deduplicated": true }` or `200 { "ok": true }` (no duplicate row)

**Verify:** Only one `email.sent` row exists for this idempotency key.

#### Test 1.6: n8n Event Ingest — Invalid Token
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/n8n-event-ingest \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer WRONG_TOKEN" \
  -d '{"lead_id": "<LEAD_ID>", "org_id": "<ORG_ID>", "type": "email.sent", "idempotency_key": "test"}'
```
**Expected:** `403 { "error": "Invalid token" }`

#### Test 1.7: n8n Event Ingest — Status Update
```bash
curl -X POST https://<SUPABASE_URL>/functions/v1/n8n-event-ingest \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <ORG_WEBHOOK_SECRET>" \
  -d '{
    "lead_id": "<LEAD_ID>",
    "org_id": "<ORG_ID>",
    "type": "lead.status_changed",
    "payload": {"from": "new", "to": "working"},
    "idempotency_key": "<LEAD_ID>:status:working",
    "new_status": "working"
  }'
```
**Expected:** `200 { "ok": true }` and lead's status is now `working`.

### 2. RLS Tests (via Supabase SQL Editor)

#### Test 2.1: Cross-Org Isolation
1. Create two organizations (Org A, Org B) with different users.
2. Insert a lead into Org A.
3. Query leads as Org B's user.
4. **Expected:** Org B user sees zero leads.

#### Test 2.2: Member Can View Leads
1. Add a user as `member` to an org.
2. Query leads as that user.
3. **Expected:** User sees all leads for that org.

#### Test 2.3: Events Are Append-Only (Client)
1. As a member, try to `UPDATE` or `DELETE` a lead_event.
2. **Expected:** Operation denied by RLS.

### 3. Manual Web App Tests

#### Test 3.1: Full User Journey
1. Open `http://localhost:3000`.
2. Click "Get Started" — should navigate to sign-up form.
3. Enter name, email, password — click Create Account.
4. Confirm email (or check Supabase Auth dashboard for local dev).
5. Sign in with email + password.
6. **Expected:** Redirected to `/dashboard` with "Welcome" prompt.

#### Test 3.2: Create Organization
1. Go to Settings.
2. Enter org name, click Create.
3. **Expected:** Success message. Reload shows org in switcher.

#### Test 3.3: Submit a Lead via cURL
1. Copy the cURL from Settings webhook section.
2. Run it in terminal.
3. Go to Leads page.
4. **Expected:** New lead appears in the list.

#### Test 3.4: Lead Detail & Notes
1. Click on a lead name in the list.
2. **Expected:** Detail page shows contact info and timeline with `lead.created` event.
3. Type a note and click Add.
4. **Expected:** Note appears in timeline with source `app`.

#### Test 3.5: Status Change
1. On lead detail, change status dropdown to "working".
2. **Expected:** Status badge updates. Timeline shows `lead.status_changed` event.

#### Test 3.6: Org Switcher
1. Create a second organization.
2. Use the org switcher dropdown.
3. **Expected:** Leads list changes to show leads for the selected org.

#### Test 3.7: Magic Link Auth
1. Sign out.
2. Enter email and click "Send Magic Link".
3. **Expected:** Success message. Check email for login link.

### 4. n8n End-to-End Test

1. Import `workflow-speed-to-lead.json` into n8n.
2. Configure SMTP and Slack credentials.
3. Set environment variables.
4. Activate the workflow.
5. Submit a test lead via the lead-intake endpoint.
6. **Expected:**
   - Immediate email received.
   - Slack notification posted.
   - `email.sent` event in Supabase.
   - After 1 hour (or reduce for testing), follow-up email if still `new`.

---

## CLEAR_99_10

**YES** — This output is implementable without guessing missing pieces. All SQL migrations, edge function code, Next.js pages, component code, n8n workflow JSON, environment variable lists, and test steps are provided. A developer can clone this repo, set up a Supabase project, fill in environment variables, and have a working MVP.
