# Deliverable G — Deployment Steps

## 1. Supabase Project Setup

### Create Project
1. Go to [supabase.com](https://supabase.com) and create a new project.
2. Note down:
   - **Project URL** (e.g., `https://abcdefghijkl.supabase.co`)
   - **Anon Key** (public, safe for client)
   - **Service Role Key** (secret, server-only)

### Run Migrations
Using Supabase CLI:
```bash
# Install CLI
npm install -g supabase

# Login
supabase login

# Link to your project
cd leadlatch/supabase
supabase link --project-ref YOUR_PROJECT_REF

# Run migrations
supabase db push
```

Or manually in the Supabase SQL editor, run in order:
1. `migrations/00001_schema.sql`
2. `migrations/00002_rls_policies.sql`
3. `migrations/00003_seed.sql`
4. `migrations/00004_rpc_functions.sql`

### Deploy Edge Functions
```bash
cd leadlatch/supabase

# Deploy lead-intake
supabase functions deploy lead-intake --no-verify-jwt

# Deploy n8n-event-ingest
supabase functions deploy n8n-event-ingest --no-verify-jwt
```

### Set Edge Function Secrets
```bash
supabase secrets set N8N_WEBHOOK_URL=https://your-n8n.example.com/webhook/lead-created
```

Note: `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are automatically available inside Edge Functions.

### Configure Auth
In the Supabase dashboard:
1. Go to **Authentication > URL Configuration**.
2. Set **Site URL** to `http://localhost:3000` (dev) or your production URL.
3. Add **Redirect URLs**: `http://localhost:3000/auth/callback`, `https://yourdomain.com/auth/callback`.
4. Under **Email Auth**, enable both email/password and magic link.

---

## 2. Environment Variables

### Next.js Web App (`leadlatch/web/.env.local`)

| Variable | Description | Required |
|----------|-------------|----------|
| `NEXT_PUBLIC_SUPABASE_URL` | Supabase project URL | Yes |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Supabase anon (public) key | Yes |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase service role key (server-side only) | Yes |
| `NEXT_PUBLIC_APP_URL` | App base URL (e.g., `http://localhost:3000`) | Yes |

### Supabase Edge Functions (auto-injected + secrets)

| Variable | Description | Auto? |
|----------|-------------|-------|
| `SUPABASE_URL` | Supabase project URL | Yes (auto) |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key | Yes (auto) |
| `N8N_WEBHOOK_URL` | n8n webhook URL for lead-created | Set via `supabase secrets set` |

### n8n Workflow Environment

| Variable | Description |
|----------|-------------|
| `SUPABASE_URL` | Supabase project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | For reading lead status via REST |
| `ORG_WEBHOOK_SECRET` | Per-org secret (from organizations table) |
| `SMTP_HOST` | Email SMTP host |
| `SMTP_USER` | SMTP username |
| `SMTP_PASS` | SMTP password |
| `SLACK_WEBHOOK_URL` | Slack incoming webhook (optional) |

---

## 3. Local Development

### Prerequisites
- Node.js 18+ and npm
- Supabase CLI (`npm install -g supabase`)
- A Supabase project (or local Docker via `supabase start`)

### Setup
```bash
# Clone and enter project
cd leadlatch/web

# Install dependencies
npm install

# Copy environment file and fill in values
cp .env.local.example .env.local
# Edit .env.local with your Supabase credentials

# Start development server
npm run dev
```

The app will be available at `http://localhost:3000`.

### Local Supabase (Optional)
```bash
cd leadlatch/supabase
supabase start  # Starts local Postgres + Auth + Edge Functions

# Local URLs will be printed, use them in .env.local
# Typically:
# SUPABASE_URL=http://localhost:54321
# ANON_KEY=<local-anon-key>
```

### Type Checking
```bash
cd leadlatch/web
npm run type-check
```

### Build
```bash
cd leadlatch/web
npm run build
```

---

## 4. Production Deployment

### Next.js on Vercel
1. Connect GitHub repo to Vercel.
2. Set root directory to `leadlatch/web`.
3. Add environment variables in Vercel dashboard.
4. Deploy.

### Next.js on Other Platforms
```bash
cd leadlatch/web
npm run build
npm start  # Starts production server on port 3000
```

### n8n Setup
1. Self-host n8n or use n8n Cloud.
2. Import the workflow from `leadlatch/n8n/workflow-speed-to-lead.json`.
3. Configure credentials (SMTP, Slack, HTTP Header Auth with org webhook secret).
4. Activate the workflow.
5. Copy the production webhook URL and set it as `N8N_WEBHOOK_URL` in Supabase secrets.

---

## 5. DNS & Custom Domain (Optional)

1. Add your custom domain in the Vercel dashboard.
2. Update Supabase Auth redirect URLs to include the custom domain.
3. Update `NEXT_PUBLIC_APP_URL` to the custom domain.
