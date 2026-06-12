# Add Your API Keys (10–15 minutes)

Follow these steps so the pipeline can call Gemini, ElevenLabs, and YouTube.

**Rule: API keys in only. Do not hit any other buttons** on the provider sites (no “Create project”, “Enable billing”, or extra toggles unless a step below says so). Just get the key and put it in `config/.env`.

---

## 1. Gemini key

- **Where:** [Google AI Studio – API key](https://aistudio.google.com/app/apikey)
- **Cost:** Free tier is still solid in 2026.
- **You get:** A string like `AIza...`. Keep it secret.

---

## 2. ElevenLabs key

- **Where:** [elevenlabs.io](https://elevenlabs.io) → dashboard (account/settings) → API key.
- **You get:** A string. Keep it secret.

---

## 3. Create `config/.env`

In the project folder, create `config/.env` (copy from `config/.env.example` if you prefer) and add:

```env
GEMINI_API_KEY=your-gemini-key-here
ELEVENLABS_API_KEY=your-elevenlabs-key-here
```

No quotes. One value per line. Save the file.

---

## 4. YouTube OAuth (for uploads)

Two files are involved; don’t mix them up.

| File | What it is | When you get it |
|------|------------|------------------|
| `config/client_secrets.json` | OAuth **client** (ID + secret) from Google | You download this from Google Cloud Console. |
| `config/youtube-oauth.json` | OAuth **token** (after you sign in) | The script creates this when you run `auth_youtube.py`. |

**Steps:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/) → **APIs & Services** → **Credentials**.
2. Enable **YouTube Data API v3** for your project (APIs & Services → Library → search “YouTube Data API v3” → Enable).
3. **Create OAuth 2.0 Client ID** (Credentials → Create Credentials → OAuth client ID).
4. Application type: **Desktop app**. Name it whatever you like (e.g. “Faceless Shorts”).
5. **Download** the JSON. Save it as:
   ```
   config/client_secrets.json
   ```
   (Do **not** rename it to `youtube-oauth.json` — that name is for the token file the script creates.)
6. In the project root, run:
   ```bash
   python scripts/auth_youtube.py
   ```
7. Sign in in the browser when it opens. The script will create `config/youtube-oauth.json` (your token). You’re done for YouTube.

---

## 5. Cursor users

If you use **Cursor** (the AI code editor), open the project folder in Cursor. It’ll help with autocomplete and fixing paste errors when you edit `.env` or config files.

---

## Quick check

From the project root:

```bash
python scripts/setup.py
```

If it reports folders OK, `.env` present, and API keys loaded, you’re ready to run:

```bash
python scripts/run_pipeline.py "Why the sky is blue"
```
