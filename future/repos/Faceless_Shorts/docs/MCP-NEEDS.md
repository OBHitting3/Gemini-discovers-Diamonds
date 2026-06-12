# MCP Needs for Faceless Shorts Pipeline

**Date:** 2026-02-14

---

## What I Have (Already Connected)

| MCP | Purpose |
|-----|---------|
| **Supabase** | Store pipeline state, asset URLs, metadata, content drafts |
| **Stripe** | Gumroad/payments (if you sell the product) |
| **Google Workspace** | Gmail, Calendar, Drive (scripts, outputs) |
| **Browser** | Navigate Runway, Midjourney, etc. for manual steps |
| **Context7** | Docs for libraries |
| **Fetch** | Pull URLs |

---

## What Would Help (You Add)

### 1. Make.com MCP (Recommended)

**Why:** I could trigger your Make scenarios (e.g. "run video assembly," "upload to Drive," "notify Slack").

**How:**
1. Make.com Developer Hub: https://developers.make.com/mcp-server
2. Create MCP token in Make account
3. Add to Cursor MCP config (Settings → MCP → Add server)
4. Cloud-hosted by Make; no local install

**Note:** Scenario run = all plans. View/modify scenarios = paid plans only.

---

### 2. n8n MCP (Recommended)

**Why:** I could trigger n8n workflows (e.g. "run pipeline for topic X," "fetch Runway clip when ready").

**How:**
1. n8n Settings → MCP → enable MCP access
2. Expose specific workflows for MCP
3. Connect Cursor as MCP client
4. Docs: https://docs.n8n.io/advanced-ai/accessing-n8n-mcp-server/

---

## What I Don’t Need MCP For

| Tool | Why no MCP needed |
|------|-------------------|
| **ElevenLabs** | Python SDK in pipeline |
| **Runway** | Manual in browser (or Runway API if you add it) |
| **Midjourney** | Manual in Discord |
| **Pika** | Manual or Pika API |
| **CapCut** | Desktop app; manual assembly |
| **Gemini** | Python SDK in pipeline |

---

## Summary

**Add when you can:**
1. **Make.com MCP** — so I can trigger your Make scenarios
2. **n8n MCP** — so I can trigger your n8n workflows

**Nice-to-have (not urgent):**
- Runway API key (if you want automated clip generation; otherwise manual is fine)

---

## One-Liner

I have Supabase, Google, Stripe, Browser. Add **Make.com MCP** and **n8n MCP** when you’re ready so I can trigger your automation scenarios.
