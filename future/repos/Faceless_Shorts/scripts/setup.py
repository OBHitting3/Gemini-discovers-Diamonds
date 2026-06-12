#!/usr/bin/env python3
"""
Faceless Shorts Automator MVP – Setup validator.
Checks: folder structure, .env presence, API keys load, quotas (where possible).
Run from repo root: python scripts/setup.py
"""
import os
import sys
from pathlib import Path

def log(msg: str) -> None:
    print(f"[setup] {msg}")

def main() -> int:
    repo_root = Path(__file__).resolve().parent.parent
    os.chdir(repo_root)

    log("Checking folder structure...")
    required_dirs = ["config", "docs", "scripts", "workflows", "tests"]
    missing = [d for d in required_dirs if not (repo_root / d).is_dir()]
    if missing:
        log(f"Missing directories: {missing}")
        return 1
    log("Folders OK")

    log("Checking config...")
    config_env = repo_root / "config" / ".env"
    if not config_env.exists():
        log("config/.env not found. Add Gemini and ElevenLabs keys (see README).")
        return 1
    log("config/.env present")

    try:
        from dotenv import load_dotenv
        load_dotenv(config_env)
        gemini = os.getenv("GEMINI_API_KEY")
        eleven = os.getenv("ELEVENLABS_API_KEY")
        if not gemini:
            log("GEMINI_API_KEY missing in config/.env")
            return 1
        if not eleven:
            log("ELEVENLABS_API_KEY missing in config/.env")
            return 1
        log("API keys loaded from .env")
    except ImportError:
        log("Run: pip install -r requirements.txt")
        return 1

    log("Checking YouTube OAuth...")
    yt_oauth = repo_root / "config" / "youtube-oauth.json"
    if not yt_oauth.exists():
        log("config/youtube-oauth.json not found. Add after YouTube OAuth setup.")
        # Don't fail; user may add later
    else:
        log("youtube-oauth.json present")

    log("Setup validation complete. Next: build Make.com scenario and run a test Short.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
