#!/usr/bin/env python3
"""
One-time YouTube OAuth: open browser, sign in, save token to config/youtube-oauth.json.
Run from repo root: python scripts/auth_youtube.py
You need config/client_secrets.json (OAuth 2.0 Client ID, Desktop app) from Google Cloud Console.
"""
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
CONFIG_DIR = REPO_ROOT / "config"
SCOPES = ["https://www.googleapis.com/auth/youtube.upload"]


def main() -> int:
    secrets = CONFIG_DIR / "client_secrets.json"
    if not secrets.exists():
        print("Put your OAuth client secrets in config/client_secrets.json")
        print("Get it: Google Cloud Console → APIs & Services → Credentials → Create OAuth 2.0 Client ID (Desktop).")
        return 1
    from google_auth_oauthlib.flow import InstalledAppFlow
    flow = InstalledAppFlow.from_client_secrets_file(str(secrets), SCOPES)
    creds = flow.run_local_server(port=0)
    token_path = CONFIG_DIR / "youtube-oauth.json"
    with open(token_path, "w") as f:
        f.write(creds.to_json())
    print(f"Token saved to {token_path}. You can run the pipeline now.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
