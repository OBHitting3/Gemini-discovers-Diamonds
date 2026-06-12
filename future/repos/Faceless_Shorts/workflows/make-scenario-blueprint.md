# Make.com Scenario Blueprint – Faceless Shorts Automator

Build this scenario in Make.com to run the full pipeline. Order of modules below.

## Trigger

- **Webhooks** or **Google Sheets** or **Manual run** (for testing).
- Output: one field `topic` (text), e.g. "Why the sky is blue".

## Module 1: Google Gemini (OpenAI-compatible or HTTP)

- **Action:** Generate content.
- **Input:** Prompt = "Write a YouTube Shorts script (under 60 seconds when read aloud, hook in first 3 seconds) for this topic: {{topic}}. Output only the script, no titles."
- **Output:** map `script` from response text.

## Module 2: ElevenLabs – Text to Speech

- **Action:** Convert text to speech (HTTP or native if available).
- **Input:** `text` = `{{script}}`, voice ID from your ElevenLabs account, output format MP3.
- **Output:** map `audio_url` or `audio_file` (download binary if needed for next step).

## Module 3: Creatomate / JSON2Video (HTTP)

- **Action:** HTTP request to Creatomate (or JSON2Video) API.
- **Input:** Template ID, `script`, `audio` (file from previous step), optional image/background.
- **Output:** map `video_url` or `video_file` (rendered Short MP4).

## Module 4: YouTube – Upload Video

- **Action:** Upload video (use Make.com YouTube module or HTTP to YouTube Data API v3).
- **Input:** 
  - File: `{{video_file}}` or URL (if module supports URL).
  - Title: e.g. "{{topic}} | Short"
  - Description: Include your AI disclosure line (e.g. "Script and voice generated with AI.").
  - Category: 22 (People & Blogs) or as desired.
  - Privacy: public or unlisted.
- **Output:** map `video_id` / `url` for logging.

## Error Handling (Optional)

- Add **Error handler** route: on failure, send to a separate scenario (e.g. log to sheet or email) and/or retry with delay.
- For YouTube 403/429: add retry with 60s delay, max 3 attempts.

## Testing

1. Run scenario manually with `topic` = "Why the sky is blue".
2. Confirm script → TTS → video → upload.
3. Check YouTube channel for the Short and description (AI disclosure).

## Notes

- Store Gemini and ElevenLabs keys in Make.com scenario variables or use `config/.env` values via a small HTTP/script step if you call your own backend; otherwise use Make.com native modules and their credential storage.
- YouTube: use OAuth in Make.com (connect your Google account with YouTube Data API v3 enabled).
