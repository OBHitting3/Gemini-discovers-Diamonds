# OAuth 403 — Handoff for Next Session

**Status:** 403 "has not completed Google verification" — test user not added.

**What’s done:**
- client_secrets.json has correct credentials (Desktop app, project coastal-sunspot)
- add_test_user.py (Playwright) opens Audience page, can’t find Add button (UI differs)
- OAUTH-403-FIX.md documents manual and automated paths

**What must happen:**
1. Add ob.hitting.3.tv@gmail.com as Test user: https://console.cloud.google.com/auth/audience?project=gen-lang-client-0190198181 → Test users → + ADD USERS
2. Run: `python3 scripts/auth_youtube.py` → sign in → token saved

**If Browser MCP is available:** Use it to add the test user (navigate, click, type).

**Scripts:**
- `scripts/add_test_user.py` — Playwright automation (needs Chrome with --remote-debugging-port=9222 for existing session)
- `scripts/connect_chrome_debug.sh` — Start Chrome with debug port
