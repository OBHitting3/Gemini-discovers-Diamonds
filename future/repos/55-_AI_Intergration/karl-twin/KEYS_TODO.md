# TODO: external API keys

Two keys are required for full operation. The system runs without them
(Docker stack, FastAPI, worker, approval UI, admin CLI, event log all
work) but the LLM planner and the E2B code sandbox will fail at call time
until these are populated.

## What to get

| Key | Where | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | https://console.anthropic.com/settings/keys | Click "Create Key", copy `sk-ant-...`. Requires prepay credits ($5 minimum). |
| `E2B_API_KEY` | https://e2b.dev/dashboard?tab=keys | Sign up if needed, copy the `e2b_...` key. Free tier with $100 starter credits. |

## How to install once you have them

```powershell
cd C:\karl-twin
notepad .env
# paste ANTHROPIC_API_KEY=sk-ant-...
# paste E2B_API_KEY=e2b_...
# save, close
```

`.\infra\scripts\start.ps1` will stop printing the yellow REMINDER banner
once both keys are filled in.

## Verify they work

```powershell
.\.venv\Scripts\Activate.ps1
python -c "import os; from karl_twin.identity.secrets import load; load(); print('A:', bool(os.environ.get('ANTHROPIC_API_KEY'))); print('E:', bool(os.environ.get('E2B_API_KEY')))"
python -m karl_twin "write a file that says hello world"
```

The last command exercises the full spec step 20 chain: parse_intent →
interpret → score_cac → plan → propose → approval_gate → execute → verify
→ store_memory → respond.
