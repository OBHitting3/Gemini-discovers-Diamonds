# Supabase — Palm Springs Paradise (cold path)

**Lane:** Manus owns migrations + dashboard; Cursor owns `SupabaseClient.lua` + `PersistenceService` wiring.

## Tables (initial migration)

| Table | Purpose |
|-------|---------|
| `psp_player_profiles` | Extended profile snapshot (optional mirror) |
| `psp_plot_layouts` | Furniture JSONB per plot |
| `psp_garden_events` | Plant/water/harvest history |
| `psp_fashion_results` | Runway scores and votes |
| `psp_transactions` | Shop economy audit log |
| `psp_analytics` | Lightweight event stream |

Roblox server uses **publishable/anon key** in Secrets with RLS policies scoped by `roblox_user_id` (bigint).

## Setup (KRLX)

```bash
# Install CLI: https://supabase.com/docs/guides/cli
brew install supabase/tap/supabase   # or npm i -g supabase

cd /path/to/PalmSprings
cp staging/env/.env.example .env     # fill SUPABASE_* — never commit .env

# Link project (once)
supabase login
supabase link --project-ref YOUR_PROJECT_REF

# Local stack (optional, for Manus)
supabase start

# Apply migrations to linked project
supabase db push
```

## Roblox production

Game Settings → Security → Allow HTTP Requests  
Secrets: `SUPABASE_URL`, `SUPABASE_ANON_KEY`  
`SupabaseClient.fromSecrets()` in `PersistenceService` — already implemented.

## Mock mode

Play Solo without secrets = mock log only (`/status`, server output).
