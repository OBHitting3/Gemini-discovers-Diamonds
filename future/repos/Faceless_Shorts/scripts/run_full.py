#!/usr/bin/env python3
"""One command: auth if needed, then pipeline with upload."""
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CONFIG = REPO / "config"
TOKEN = CONFIG / "youtube-oauth.json"

def main():
    if not TOKEN.exists():
        print("[run_full] No YouTube token. Opening browser — sign in once.")
        subprocess.run([sys.executable, str(REPO / "scripts" / "auth_youtube.py")], cwd=str(REPO), check=True)
    topic = sys.argv[1] if len(sys.argv) > 1 else "Why the sky is blue"
    subprocess.run([sys.executable, str(REPO / "scripts" / "run_pipeline.py"), topic], cwd=str(REPO), check=True)
    print("[run_full] Done.")

if __name__ == "__main__":
    main()
