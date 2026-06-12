#!/usr/bin/env python3
"""
Add ob.hitting.3.tv@gmail.com as OAuth test user via browser automation.
Run: python3 scripts/add_test_user.py
- If Chrome is running with --remote-debugging-port=9222, connects to it (you're logged in).
- Otherwise launches browser; you log in when the page opens, then script continues.
"""
import sys
import time
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
TEST_EMAIL = "ob.hitting.3.tv@gmail.com"
PROJECT_ID = "gen-lang-client-0190198181"
AUDIENCE_URL = f"https://console.cloud.google.com/auth/audience?project={PROJECT_ID}"

def main() -> int:
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("Installing playwright...")
        import subprocess
        subprocess.run([sys.executable, "-m", "pip", "install", "playwright"], check=True)
        subprocess.run([sys.executable, "-m", "playwright", "install", "chromium"], check=True)
        from playwright.sync_api import sync_playwright

    with sync_playwright() as p:
        # Try to connect to existing Chrome with remote debugging (your session)
        try:
            browser = p.chromium.connect_over_cdp("http://localhost:9222")
            print("Connected to your Chrome (you're logged in).")
            page = browser.new_page()
        except Exception as e:
            print("Chrome with --remote-debugging-port=9222 not found.")
            print("To use your existing Google login: quit Chrome, run ./scripts/connect_chrome_debug.sh in a terminal, then run this script again.")
            print("Launching fresh browser - you must log in when the page opens.")
            browser = p.chromium.launch(headless=False)
            page = browser.new_page()
        page.goto(AUDIENCE_URL, wait_until="domcontentloaded", timeout=60000)

        # Wait for page - user may need to log in first
        print("Waiting 45s for page to load... (log in to Google if you see sign-in)")
        page.wait_for_timeout(45000)

        # Look for Test users section and + ADD USERS
        add_clicked = False
        for selector in [
            'button:has-text("ADD USERS")',
            'button:has-text("Add users")',
            'a:has-text("ADD USERS")',
            '[role="button"]:has-text("Add")',
            '[aria-label*="Add user"]',
            'text=+ ADD USERS',
            'span:has-text("ADD USERS")',
            '[data-testid*="add"]',
        ]:
            try:
                btn = page.locator(selector).first
                if btn.is_visible(timeout=3000):
                    btn.click()
                    add_clicked = True
                    print("Clicked Add Users.")
                    break
            except Exception:
                continue

        if not add_clicked:
            print("Could not find Add Users button. Waiting 60s - add manually: scroll to Test users, + ADD USERS, add", TEST_EMAIL)
            page.wait_for_timeout(60000)
            browser.close()
            return 0

        page.wait_for_timeout(2000)

        # Fill email in popup/dialog
        for sel in ['input[type="email"]', 'input[name*="email"]', 'input[placeholder*="email"]']:
            try:
                inp = page.locator(sel).first
                if inp.is_visible(timeout=2000):
                    inp.fill(TEST_EMAIL)
                    print("Filled email.")
                    break
            except Exception:
                continue

        page.wait_for_timeout(1000)

        # Click Add/Save in dialog
        for sel in ['button:has-text("Add")', 'button:has-text("Save")', 'button:has-text("ADD")']:
            try:
                btn = page.locator(sel).first
                if btn.is_visible(timeout=2000):
                    btn.click()
                    print("Clicked Add/Save.")
                    break
            except Exception:
                continue

        page.wait_for_timeout(3000)
        print("Done. Browser stays open 30s - finish manually if needed.")
        page.wait_for_timeout(30000)
        browser.close()
    return 0

if __name__ == "__main__":
    sys.exit(main())
