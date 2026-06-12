# Video Production Plan — Today (2026-02-14)

**Rule:** Plan first, then execute. You approve before I run anything.

---

## 1. Step-by-Step Process Reminder

### Path A — Existing MVP Pipeline (Automated, Works Now)

| Step | What | Command / Action | Output |
|------|------|------------------|--------|
| 1 | **Topic** | You pick it (e.g. "Why the sky is blue") | — |
| 2 | **Script** | Gemini writes ~150-word Shorts script | `output/` |
| 3 | **Voice** | ElevenLabs TTS | `output/*.mp3` |
| 4 | **Video** | MoviePy: static 9:16 image + audio | `output/*.mp4` |
| 5 | **Upload** | YouTube API (optional) | Short on your channel |

**Run:** `python3 scripts/run_pipeline.py "Topic"`  
**No upload:** `python3 scripts/run_pipeline.py "Topic" --no-upload`

---

### Path B — Runway + CapCut (Manual, For Polished B-Roll)

| Step | What | Where | Output |
|------|------|-------|--------|
| 1 | **Generate clips** | Runway Gen-3 Alpha (Explore mode = free) | 5-sec 9:16 clips |
| 2 | **Download** | → `Desktop/RUNWAY-CLIPS/` | MP4 files |
| 3 | **Voice** | ElevenLabs or record yourself | Audio |
| 4 | **Assemble** | CapCut: b-roll + text + voiceover | Final Short |
| 5 | **Post** | TikTok / YouTube Shorts | Published |

**Prompts:** See `~/Desktop/RUNWAY-BATCH-PLAN.md` (22 prompts ready to paste)

---

### Path C — Full Temporal Pipeline (Not Built Yet)

- Needs: temporal stitch frame spec from Gemini/Drive, plan confirmation
- Handoff says: pull spec → confirm `docs/PLAN-BEFORE-WE-START.md` → say "go" → I write pipeline spec → then build

---

## 2. Plan for Today — Produce Videos

**Goal:** Get real videos shipped today.

**Recommended approach:**

1. **Path A first** — Run the existing pipeline for 3–5 topics. Fast, automated, proves the system works.
2. **Optional Path B** — If you want polished b-roll, generate 2–3 Runway clips using Explore mode (free) and assemble one Short in CapCut.

**Path A topics (suggestions):**
- "Why the sky is blue"
- "How compound interest works"
- "Why we procrastinate"
- "The surprising science of déjà vu"
- "Why dogs tilt their heads"

You can also use your own topics (e.g. from TIKTOK-CONTENT-BRIEFS if they exist).

---

## 3. Prerequisites Checklist

- [ ] `config/.env` has `GEMINI_API_KEY` and `ELEVENLABS_API_KEY`
- [ ] YouTube OAuth done once: `python3 scripts/auth_youtube.py` (if you want uploads)
- [ ] `pip install -r requirements.txt` (in `faceless-shorts-mvp/`)
- [ ] Run validator: `python3 scripts/setup.py`

---

## 4. What I Need From You to Start

1. **Confirm:** Path A only today? Or Path A + Path B?
2. **Topics:** Use my 5 suggestions above, or give me your list.
3. **Upload:** Yes or no? (`--no-upload` = video file only, no YouTube)

Once you confirm, I run the pipeline for each topic and report back.

---

## 5. One-Liner for Today

**Path A:** Confirm topics and upload preference → I run `run_pipeline.py` for each → videos in `output/`.  
**Path B:** You generate Runway clips (prompts ready); I can help with CapCut assembly notes if needed.
