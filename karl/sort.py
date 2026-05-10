#!/usr/bin/env python3
"""
sort.py — Karl's thought sorter.

Karl's rule: a thought is not a decision. The system has to know the difference
before it acts. This script reads any chunk of raw input (a voice memo dump,
a brain dump, a notes file) and uses a local LLM to categorize each piece.

Categories:
  thought   — musing, exploration. NOT a commitment. Log only.
  decision  — a real call Karl has made. Commit.
  task      — something to do. Route to an agent.
  fact      — something true about Karl or his world. Save to memory.
  vent      — processing or emotion. Log. Do NOT act on it.

Usage:
    echo "I'm wondering if I should..." | python karl/sort.py
    python karl/sort.py < notes.txt

Requires Ollama running locally:
    https://ollama.com — install, then `ollama pull llama3.1`
    On KRLX with the RTX 5090, swap MODEL to 'llama3.3:70b' for full quality.
"""

import json
import sys
from pathlib import Path

try:
    import requests
except ImportError:
    print("Install requests first: pip install requests", file=sys.stderr)
    sys.exit(1)

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "llama3.1"  # swap to "llama3.3:70b" on KRLX once it's pulled
OUT_DIR = Path(__file__).parent / "inbox"
CATEGORIES = {"thought", "decision", "task", "fact", "vent"}

PROMPT = """You are Karl's thought sorter. Karl is a high-speed, parallel thinker.
He thinks out loud. A thought is NOT a decision. Categorize the input below
into exactly ONE of:

- thought: musing, exploration, "what if", "I'm wondering". NOT a commitment.
- decision: a real call Karl has made. Phrases like "we're going with", "I'm doing X".
- task: an action Karl wants taken. "Build X", "send Y", "order Z".
- fact: a true statement about Karl, his preferences, his world.
- vent: emotion, frustration, processing. Do NOT act on these.

Respond with ONLY valid JSON, nothing else:
{"category": "<one of the five>", "summary": "<one short sentence>"}

Input:
---
%s
---
"""


def sort(text: str) -> dict:
    response = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL,
            "prompt": PROMPT % text,
            "stream": False,
            "format": "json",
        },
        timeout=120,
    )
    response.raise_for_status()
    return json.loads(response.json()["response"])


def main() -> int:
    text = sys.stdin.read().strip()
    if not text:
        print("No input. Pipe text in: echo 'something' | python sort.py", file=sys.stderr)
        return 1

    try:
        result = sort(text)
    except requests.ConnectionError:
        print("Ollama isn't running. Start it: `ollama serve`", file=sys.stderr)
        return 2

    category = result.get("category", "thought")
    if category not in CATEGORIES:
        category = "thought"
    summary = result.get("summary", "(no summary)")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out_file = OUT_DIR / f"{category}.md"
    with out_file.open("a") as f:
        f.write(f"- {summary}\n  > {text}\n\n")

    print(f"Sorted as: {category}")
    print(f"Saved to:  {out_file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
