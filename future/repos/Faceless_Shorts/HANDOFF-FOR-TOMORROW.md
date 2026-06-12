# Handoff for Tomorrow — Faceless Shorts + Pipeline

**Date:** 2026-02-14 (late night)  
**Status:** Done for the night. Everything below is saved; pick up here tomorrow.

---

## 1. Search Done (Desktop + workspace)

- **Searched:** `/Users/karl/Desktop`, workspace, and drive paths for "temporal," "stitch frame," "event timing," "trigger."
- **Found on Desktop:** RUNWAY-BATCH-PLAN.md (Runway clips, 9:16, CapCut assembly), HANDOFF-SUMMARY.md, TONIGHT-PREP, TOMORROW-MORNING.md, Content_Shield and Agentic PM docs, INDUSTRY-TERMS.md (temporal/pipeline terms).
- **Temporal stitch frame:** No standalone spec document found on Desktop or in workspace. In your transcripts you used **"event-driven temporal assembly pipeline"** and **keyframe stitching** — that’s the closest. You said **Gemini’s got it all**; tomorrow pull the temporal stitch frame and event-timing spec from Gemini (or Google Drive) and drop it into this project so the plan can use it.

---

## 2. What’s Saved Right Now

| What | Where |
|------|--------|
| Your stack (Runway, Midjourney, Pika, etc.) | `docs/YOUR-STACK.md` |
| Plan before we start (no build until you OK it) | `docs/PLAN-BEFORE-WE-START.md` |
| Runway batch plan (clips, prompts, CapCut) | `~/Desktop/RUNWAY-BATCH-PLAN.md` |
| Pipeline state | Script → voice (gTTS fallback) → video (MoviePy) works; YouTube upload needs one-time auth |
| Last working output | `output/Why the sky is blue.mp4` (voice + static image) |
| Config | `config/.env` (Gemini + ElevenLabs keys), `config/client_secrets.json` (YouTube OAuth client) |

---

## 3. Tomorrow — First Steps

1. **Get the spec from Gemini/Drive**  
   Pull your **temporal stitch frame** and **event timing / triggers** (whatever you have in Gemini or Drive). Save it into this repo (e.g. `docs/TEMPORAL-STITCH-FRAME-SPEC.md` or paste into the plan).

2. **Confirm the plan**  
   Open `docs/PLAN-BEFORE-WE-START.md`. Adjust temporal stitch frame step, event order, and which tool per step (Midjourney vs Pika, Runway vs Pika, etc.). Say "go" when it’s right.

3. **Then**  
   I turn the plan into one **pipeline spec** (triggers, order, inputs/outputs) and we build from that — using your stack, not generic fallbacks.

---

## 4. Key Paths

- **This project:** `/Users/karl/faceless-shorts-mvp/`
- **Run pipeline (current):** `python3 scripts/run_pipeline.py "Topic"` or `--no-upload` for video only.
- **YouTube auth (one-time):** `python3 scripts/auth_youtube.py` then sign in in browser.
- **Plan / stack:** `docs/PLAN-BEFORE-WE-START.md`, `docs/YOUR-STACK.md`.

---

## 5. One-Liner for Tomorrow

Pull temporal stitch frame + event timing from Gemini (or Drive), save into this repo, confirm `docs/PLAN-BEFORE-WE-START.md`, then say "go" so the pipeline spec gets written and we build with your stack.
