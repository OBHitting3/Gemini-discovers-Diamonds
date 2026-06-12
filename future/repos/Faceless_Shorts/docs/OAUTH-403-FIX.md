# Fix 403: "has not completed the Google verification process"

**Cause:** Your email is not in the OAuth Test users list. Google blocks sign-in until you add yourself.

**Fix (pick one):**

## Option A: Automated (uses your Chrome session)

1. Quit Chrome completely.
2. In Terminal: `./scripts/connect_chrome_debug.sh` (keep it running).
3. In another Terminal: `python3 scripts/add_test_user.py`
4. Script connects to your Chrome, navigates to Audience, tries to click Add. If it finds the button, it fills your email. If not, the page is open — add ob.hitting.3.tv@gmail.com manually (Test users → + ADD USERS).

## Option B: Manual

1. Open: https://console.cloud.google.com/auth/audience?project=gen-lang-client-0190198181
2. Log in if prompted.
3. Scroll to **Test users**.
4. Click **+ ADD USERS**.
5. Enter: ob.hitting.3.tv@gmail.com
6. Click **Add** (or Save).

## Then run auth

```bash
python3 scripts/auth_youtube.py
```

Sign in when the browser opens. Token saves to `config/youtube-oauth.json`.
