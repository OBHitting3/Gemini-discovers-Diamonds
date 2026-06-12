# Plan Before We Start

**Rule:** No execution until this plan is set and you’re good with it. I run the show by having the plan first, then we build.

---

## 1. What We’re Building

- **Product:** Video production system/workflow (any length capable). Uses **your stack** (Runway, Midjourney, Pika, etc.), not generic fallbacks. Does editing, design, assembly. **Current focus:** shorts only (MVP). **Future:** long-form, movie-length — you control duration via sliding scale.
- **Orchestration:** Event timing, triggers, and a clear order of operations so everything runs in the right sequence instead of ad‑hoc steps.
- **Your concepts:** **Temporal stitch frame** and any event/timing/trigger rules you use need to be in the design from the start, not added later.

---

## 2. What I Don’t Yet Have (Need From You or the Codebase)

- **Temporal stitch frame** – Exact definition and how you want it used (e.g. frame boundaries for Runway/Pika, time alignment for voice + video, or something from your Iterative Resilience / Joshua workflow). I’ll treat this as a first‑class part of the pipeline once it’s defined.
- **Event timing & triggers** – What triggers what, in what order, and on what schedule (e.g. “topic in → trigger 1 → script → trigger 2 → image → trigger 3 → video → trigger 4 → upload”). I’ll formalize this into a single timeline/flow.
- **Which tool for which step** – Your preference per step (e.g. Midjourney vs Pika for key art, Runway vs Pika for video, which LLM for script, which voice, etc.) so the plan matches what you actually use.

---

## 3. Proposed Plan Structure (Draft – Adjust This)

| Phase | What | Your stack (candidate) | Triggers / timing |
|-------|------|-------------------------|-------------------|
| A | Script | Gemini Pro / GPT Pro / Perplexity | Trigger: topic in. Output: script. |
| B | Voice | (TBD – ElevenLabs or other from your list) | Trigger: script ready. Output: audio. |
| C | Key visual(s) | Midjourney / Pika Art | Trigger: topic or script. Output: image(s). |
| D | Video | Runway / Pika | Trigger: image + (optional) prompt. Input: stitch frame / duration. Output: video. |
| E | Temporal stitch frame | (Your spec) | When it runs, what it stitches (frames, segments, time ranges), and how it fits between C and D or inside D. |
| F | Final assembly | Python/MoviePy + CapCut | Trigger: video + audio. Output: video (length = your choice). |
| G | Publish | YouTube, TikTok, etc. | Trigger: video ready. |

Event timing and triggers will be written down as one linear (or branched) flow so every step has a clear “when” and “what triggers it.”

---

## 4. Next Steps (Only After You OK the Plan)

1. You confirm or correct this plan (especially temporal stitch frame, event timing, and which tool per step).
2. I turn it into a single **pipeline spec**: triggers, order, inputs/outputs, and where your stitch frame and timing rules live.
3. We implement against that spec only (no random additions).
4. We add observability (e.g. correlation_id / status) so we can see where we are in the flow.

---

## 5. What I’m Not Doing Until the Plan Is Set

- Adding new tools or steps without putting them in this plan.
- Building more of the old Pillow/MoviePy‑only path as the main flow.
- Responding with “just one more feature” without updating the plan first.

---

**Your move:** Confirm or edit this plan (especially temporal stitch frame and event/trigger order). Once you say “go,” the next thing I do is turn it into the pipeline spec and then we build from that.
