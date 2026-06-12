# LeadLatch — Speed-to-Lead Autopilot

Multi-tenant SaaS MVP for capturing, engaging, and converting leads automatically.

## Stack

- **Frontend:** Next.js 15 (App Router) + TypeScript + Tailwind CSS v4
- **Backend:** Supabase (Auth + Postgres + RLS + Edge Functions)
- **Automation:** n8n (event-driven workflows via Webhook)

## Project Structure

```
leadlatch/
├── web/                         # Next.js web application
│   ├── src/
│   │   ├── app/
│   │   │   ├── page.tsx                    # Landing page
│   │   │   ├── layout.tsx                  # Root layout
│   │   │   ├── globals.css                 # Tailwind imports
│   │   │   ├── auth/
│   │   │   │   ├── login/page.tsx          # Login / Signup page
│   │   │   │   └── callback/route.ts       # Auth callback handler
│   │   │   ├── dashboard/
│   │   │   │   ├── layout.tsx              # Dashboard layout (auth guard + org provider)
│   │   │   │   ├── page.tsx                # Overview with stats
│   │   │   │   ├── leads/
│   │   │   │   │   ├── page.tsx            # Leads list + filters
│   │   │   │   │   └── [id]/page.tsx       # Lead detail + timeline + notes
│   │   │   │   └── settings/page.tsx       # Org settings, webhook info, invites
│   │   │   └── api/auth/signout/route.ts   # Server-side signout
│   │   ├── components/
│   │   │   ├── dashboard-shell.tsx         # Sidebar + nav
│   │   │   ├── org-switcher.tsx            # Org dropdown
│   │   │   ├── lead-timeline.tsx           # Event timeline display
│   │   │   └── lead-note-form.tsx          # Note input
│   │   ├── lib/
│   │   │   ├── supabase/
│   │   │   │   ├── client.ts              # Browser Supabase client
│   │   │   │   ├── server.ts              # Server Supabase client
│   │   │   │   └── middleware.ts           # Session refresh middleware
│   │   │   └── org-context.tsx             # React context for org switching
│   │   └── types/
│   │       └── database.ts                 # TypeScript types for all tables
│   ├── package.json
│   ├── tsconfig.json
│   ├── next.config.ts
│   └── .env.local.example
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   ├── 00001_schema.sql               # Tables, enums, triggers
│   │   ├── 00002_rls_policies.sql         # Row Level Security
│   │   ├── 00003_seed.sql                 # Seed data docs
│   │   └── 00004_rpc_functions.sql        # Idempotent insert RPC
│   └── functions/
│       ├── lead-intake/index.ts           # Public lead capture endpoint
│       └── n8n-event-ingest/index.ts      # Secured n8n event writer
├── n8n/
│   └── workflow-speed-to-lead.json        # Importable n8n workflow
└── docs/
    ├── A-ARCHITECTURE.md                  # Architecture overview
    ├── F-N8N-WORKFLOW.md                  # n8n workflow outline
    ├── G-DEPLOYMENT.md                    # Deployment steps
    └── H-DEFINITION-OF-DONE.md            # DoD checklist + test plan
```

## Quick Start

```bash
cd leadlatch/web
npm install
cp .env.local.example .env.local
# Fill in Supabase credentials
npm run dev
```

## Deliverables

| # | Deliverable | Location |
|---|-------------|----------|
| A | Architecture Overview | `docs/A-ARCHITECTURE.md` |
| B | Database Schema SQL | `supabase/migrations/00001_schema.sql` |
| C | RLS Policies | `supabase/migrations/00002_rls_policies.sql` |
| D | Edge Functions | `supabase/functions/` |
| E | Next.js App | `web/src/` |
| F | n8n Workflow Outline | `docs/F-N8N-WORKFLOW.md` + `n8n/` |
| G | Deployment Steps | `docs/G-DEPLOYMENT.md` |
| H | Definition of Done | `docs/H-DEFINITION-OF-DONE.md` |

## License

Proprietary — LeadLatch
