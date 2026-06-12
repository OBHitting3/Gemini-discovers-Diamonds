# Run status

**Last full run:** Topic → script → voice → video completed.

- **Script:** Fallback (Gemini 429).
- **Voice:** gTTS (ElevenLabs 401 missing_permissions).
- **Video:** Built and saved to `output/Why the sky is blue.mp4`.
- **Upload:** Skipped (no `config/youtube-oauth.json`). Sign in once via `python3 scripts/auth_youtube.py`, then re-run the pipeline to upload.

**To run again:**  
`cd /Users/karl/faceless-shorts-mvp && python3 scripts/run_pipeline.py "Your topic"`

**To enable upload:**  
Run `python3 scripts/auth_youtube.py`, sign in in the browser, then run the pipeline again.
