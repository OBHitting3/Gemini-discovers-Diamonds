# Cursor Setup — Cheapest Configuration

**Goal:** Run Cursor as inexpensively as possible while keeping AI power.

---

## Option A: Free Cursor + Custom API Keys (Recommended)

| Item | Cost |
|------|------|
| Cursor | **$0** (Hobby/Free plan) |
| OpenAI API (pay-as-you-go) | ~$5–20/mo depending on usage |
| **Total** | **~$5–20/mo** |

### Steps

1. **Stay on Cursor Free** — No upgrade needed.
2. **Get API keys** from one provider:
   - [OpenAI](https://platform.openai.com/api-keys) — GPT-4o, o1, etc.
   - [Anthropic](https://console.anthropic.com/) — Claude models
   - [Google AI Studio](https://aistudio.google.com/) — Gemini
3. **Add in Cursor:** Settings → Models → [Provider] → Paste key → Verify → Enable models.
4. **Restart Cursor.**

Chat and Composer will use your key; you pay only for usage. Tab Completion still uses Cursor’s built-in models (included in Free).

---

## Option B: Free Cursor + DeepSeek (Lowest Cost)

| Item | Cost |
|------|------|
| Cursor | **$0** |
| DeepSeek API (Fireworks.ai) | ~$0.14/1M input tokens |
| **Total** | **~$1–5/mo** for light use |

1. Sign up at [Fireworks.ai](https://fireworks.ai/) or [DeepSeek API](https://platform.deepseek.com/).
2. Add API key in Cursor Settings → Models.
3. Select DeepSeek-v3 or DeepSeek-r1.

---

## Option C: Cursor Pro ($20/mo)

- 500 fast premium requests/month
- Unlimited slow requests
- No custom keys needed (uses Cursor’s models)
- Best if you prefer simplicity over cost-optimization.

---

## What Doesn’t Work Well

- **OpenRouter:** Cursor does not officially support OpenRouter; override base URL can send malformed requests.
- **LiteLLM proxy:** Possible but complex; only worth it for advanced setups.

---

## MCP Setup (This Project)

MCP servers live in `.cursor/mcp.json`. Keys go in env vars, not in the file.

**Example** — add to `.cursor/mcp.json` when you have keys:

```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token" }
    }
  }
}
```

Use a wrapper script or Doppler to inject env vars instead of hardcoding. See `.cursor/mcp.json` in this repo.

---

## Quick Reference

| Action | Location |
|--------|----------|
| Add model API keys | Cursor Settings → Models |
| Add MCP servers | `.cursor/mcp.json` |
| Free tier limit | 50 premium requests/mo (Cursor models only) |
| Custom keys | Unlimited usage at provider’s pricing |

---

*Last updated: Feb 2026*
