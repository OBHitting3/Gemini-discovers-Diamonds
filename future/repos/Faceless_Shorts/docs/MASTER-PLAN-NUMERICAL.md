# Master Plan — Faceless Shorts Pipeline

**Rule:** No execution until you approve. Plan first, then we build.

---

## Entire plan — numerical order

### Phase 1 — Prerequisites (before any videos)

1. **Config check** — `config/.env` has `GEMINI_API_KEY` and `ELEVENLABS_API_KEY`
2. **Dependencies** — `pip install -r requirements.txt` in `faceless-shorts-mvp/`
3. **Validator** — Run `python3 scripts/setup.py` to confirm folders and keys
4. **YouTube (if uploading)** — One-time: `python3 scripts/auth_youtube.py` then sign in in browser

---

### Phase 2 — Today: Produce videos (existing pipeline)

5. **You confirm:** Path A only, or Path A + Path B
6. **You pick topics:** Use suggested 5, or give your own list
7. **You decide upload:** Yes (YouTube) or No (`--no-upload` = video file only)
8. **I run pipeline** — For each topic: `python3 scripts/run_pipeline.py "Topic"` (or with `--no-upload`)
9. **Output** — Videos land in `output/`; scripts and audio there too
10. **Report** — I tell you what was produced, any errors

---

### Phase 3 — Optional today: Runway + CapCut (manual)

11. **You generate clips** — Runway Gen-3 Alpha, Explore mode (free), paste prompts from `~/Desktop/RUNWAY-BATCH-PLAN.md`
12. **You download** — Save to `Desktop/RUNWAY-CLIPS/`
13. **You assemble** — CapCut: b-roll + text + voiceover → export 9:16 Short
14. **You post** — TikTok / YouTube Shorts manually

---

### Phase 4 — Later: Full temporal pipeline (not built yet)

15. **You pull spec** — Get temporal stitch frame + event timing from Gemini or Google Drive
16. **You save spec** — Drop into repo: `docs/TEMPORAL-STITCH-FRAME-SPEC.md` (or paste into plan)
17. **You confirm plan** — Review `docs/PLAN-BEFORE-WE-START.md`, adjust tool choices (Midjourney vs Pika, Runway vs Pika, etc.)
18. **You say "go"** — I turn the plan into one pipeline spec (triggers, order, inputs/outputs)
19. **I implement** — Build against spec only, using your stack (Runway, Midjourney, Pika, ElevenLabs, etc.)
20. **Observability** — Add correlation_id / status so we see where we are in the flow

---

### Phase 5 — What I’m not doing

21. **No scope creep** — No new tools or steps without putting them in this plan first
22. **No random features** — No "just one more thing" without updating the plan
23. **No execution without approval** — I do not run pipeline, upload, or build until you confirm

---

## Today’s decision point

**Steps 1–4** = prerequisites.  
**Steps 5–10** = produce videos today (Path A).  
**Steps 11–14** = optional manual Path B.  
**Steps 15–20** = later build (full temporal pipeline).  

**Your move:** Confirm steps 5–7 (Path A/B, topics, upload) and I execute steps 8–10.
