# Faceless Shorts — What Works, What's Broken

**Date:** 2026-02-14

---

## Working

| Item | Status |
|------|--------|
| Folder structure | OK |
| config/.env | Present, API keys loaded |
| config/client_secrets.json | Present (YouTube OAuth client) |
| Pipeline (Script → Voice → Video) | Runs; produces MP4 |
| Fallbacks | gTTS when ElevenLabs fails; generic script when Gemini 429 |
| Output | `output/*.mp4` created |

---

## Broken / Degraded

| Item | Symptom | Fix |
|------|---------|-----|
| **Gemini** | 429 rate limit → fallback script | Check quota at [Google AI Studio](https://aistudio.google.com/). New key or wait. |
| **ElevenLabs** | 401 / missing_permissions → gTTS fallback | Verify API key at elevenlabs.io; check account tier / permissions. |
| **YouTube upload** | No youtube-oauth.json | Run `python3 scripts/auth_youtube.py` once; sign in in browser. *(Browser may have opened now.)* |
| **Python 3.9** | EOL warnings | Upgrade to Python 3.10+ (`brew install python@3.12`). |
| **google.generativeai** | Deprecated | Migrate to `google.genai` (see [deprecation README](https://github.com/google-gemini/deprecated-generative-ai-python)). |

---

## Git (faceless-shorts-mvp)

- **Local:** Repo initialized, initial commit present.
- **Remote:** `origin` = https://github.com/OBHitting3/Faceless_Shorts.git
- **Push:** If GitHub auth works in your session, run `git push -u origin main`.

---

## Next Actions (in order)

1. **YouTube OAuth:** If browser opened for `auth_youtube.py`, sign in → token saved.
2. **Retry pipeline with upload:** `python3 scripts/run_pipeline.py "Topic"` (no --no-upload).
3. **Fix ElevenLabs:** Check key and permissions.
4. **Fix Gemini:** Check quota or new key.
