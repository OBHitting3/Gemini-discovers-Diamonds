# Faceless Shorts Automator MVP

**95% automated pipeline for faceless YouTube Shorts.** Topic in → Short uploaded.

## What It Does

1. **Input** a topic (e.g. "Why the sky is blue").
2. **Gemini** writes a Shorts script.
3. **ElevenLabs** turns it into voiceover.
4. **Video** is built from a 9:16 image + audio (default dark background, or use your own image).
5. **YouTube API** uploads it to your channel.

You can run the full pipeline **locally with Python** (no Make.com required). Make.com is optional for no-code automation.

## Quick Start (Use It Yourself)

1. **Setup**
   ```bash
   cd faceless-shorts-mvp
   pip install -r requirements.txt
   ```
2. **Secrets** — the agent creates `config/.env` and uses keys from SETUP-API-KEYS (never paste keys into README). See **`docs/SETUP-API-KEYS.md`**.
3. **YouTube (one-time)** — download OAuth client JSON from Google Cloud Console (Credentials → OAuth 2.0 Client ID, Desktop app) → save as `config/client_secrets.json`. Then run:
   ```bash
   python scripts/auth_youtube.py
   ```
   Sign in in the browser; token is saved to `config/youtube-oauth.json`.
4. **Run a Short**
   ```bash
   python scripts/run_pipeline.py "Why the sky is blue"
   ```
   Output: script → `output/` (audio + video) → upload to YouTube. Use `--no-upload` to only build the video file.

**Optional:** `--image path/to/1080x1920.png` for a custom background.

5. **Validate** — `python scripts/setup.py` checks folders and keys.

## APIs & Credentials

- **Google Gemini** — script generation (free tier OK).
- **ElevenLabs** — TTS.
- **YouTube Data API v3** — OAuth 2.0 Desktop app client ID; token in `config/`.
- **Make.com** — free tier to start.
- **Creatomate / JSON2Video** — video assembly (~$0.20–$1 per Short).

## Folder Structure

```
faceless-shorts-mvp/
├── README.md
├── .gitignore
├── config/           # .env, client_secrets.json, youtube-oauth.json (never commit)
├── docs/
├── scripts/
│   ├── setup.py      # Validator
│   ├── run_pipeline.py   # Topic → Short (script, voice, video, upload)
│   └── auth_youtube.py   # One-time OAuth
├── workflows/        # Make.com blueprints (optional)
├── output/           # Generated audio + video (gitignored)
├── tests/
└── requirements.txt
```

## Docs

- **`docs/BIBLE-OF-TERMS.md`** — Video production, temporal assembly, keyframe, and AI generative terminology for prompts and pipeline specs.
- **`docs/SETUP-API-KEYS.md`** — API key setup.

## Compliance

AI-generated content disclosure is included in the upload description template.

## License

See product terms if purchased; otherwise use at your own risk.
