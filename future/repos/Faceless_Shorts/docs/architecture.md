# Faceless Shorts Automator – Architecture

## Flow (End-to-End)

```
Topic (text)
    → Make.com trigger (webhook or form)
    → Gemini: script generation
    → ElevenLabs: TTS (MP3)
    → Creatomate/JSON2Video: video assembly (script + voice + visuals)
    → YouTube Data API v3: upload (Short)
    → Done
```

## Components

| Component | Role |
|-----------|------|
| **Make.com** | Orchestration. One scenario: trigger → Gemini → ElevenLabs → video API → YouTube. |
| **Gemini** | Short-form script from topic; keep under ~60s word count. |
| **ElevenLabs** | Text-to-speech; output MP3 for Creatomate. |
| **Creatomate / JSON2Video** | HTTP API: template + script + audio → MP4. Budget ~$0.20–$1 per Short. |
| **YouTube Data API v3** | Upload as Short (title, description, visibility). Default quota ~6 uploads/day. |
| **Python (scripts/setup.py)** | Local validation: env vars, API reachability, quota checks. |

## Data Flow

- **Input:** Single topic string (e.g. from Make.com webhook or form).
- **Output:** Public/unlisted Short on the channel linked to the OAuth token in `config/`.
- **Secrets:** All in `config/` (`.env` for keys, `youtube-oauth.json` for token). Never committed.

## Error Handling

- Make.com: retry on failure; optional DLQ or log route for failed runs.
- YouTube: respect quota; exponential backoff on 403/429.
- Video API: timeouts and fallback message if assembly fails.

## Quotas & Limits

- **YouTube:** Default ~6 uploads/day; request increase in Cloud Console when needed.
- **ElevenLabs:** Depends on plan (characters/month). Unlimited plan = no cap for pipeline use.
- **Gemini:** Free tier rate limits; sufficient for MVP.
- **Creatomate:** Per-video cost; batch if needed.

## Make.com Scenario Blueprint

See `workflows/make-scenario-blueprint.md` for step-by-step build instructions and module order.
