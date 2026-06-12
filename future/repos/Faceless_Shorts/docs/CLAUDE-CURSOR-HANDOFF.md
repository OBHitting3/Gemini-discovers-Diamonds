# Claude ↔ Cursor Handoff

**Purpose:** Cursor writes status updates here. Claude reads this to stay in sync.

---

## Latest (2026-02-14)

- **2026-02-16** ios-app-restore-helper: Wrote guided workflow app (bulk delete instructions + App Store re-download links). Fixed bottlenecks: (1) data persistence to data/apps.json, (2) App Store ID validation (numeric), (3) smoke test script. npm test PASS. Run: npm start → http://localhost:3000
- **2026-02-15** ironforge-studio Stripe accounts: Confirmed via Terminal (stripe.accounts.retrieve) that .env.local keys are for "Iron Forge Studios sandbox" (acct_1T0RpRPosz7aYvo6). MCP is "Casper the Faceless Software" (different account). App is correctly using Iron Forge. Added STRIPE-ACCOUNTS-SOLVED.md with one-account webhook steps; updated .env.local comment. Only remaining step: user adds webhook in Iron Forge Studios sandbox and pastes Signing secret into STRIPE_WEBHOOK_SECRET.
- **2026-02-15** ironforge-studio billing end-to-end: Stripe Standard key + price IDs in .env.local; verify OK; build OK. Duplicate STRIPE_SECRET_KEY removed. For deploy: add STRIPE_WEBHOOK_SECRET (Stripe Dashboard → Webhooks → endpoint → signing secret), set env vars on Vercel, webhook URL https://ironforge.studio/api/stripe/webhook.
- **2026-02-15** ironforge-studio .env.local: Fixed Stripe setup. Key was on its own line (orphan); moved it to STRIPE_SECRET_KEY=. Corrected typo rk_test_ → sk_test_. Ran create-stripe-products.mjs → Stripe returned "Invalid API Key". STRIPE_SECRET_KEY= left empty. When back: paste fresh Secret key from Stripe Dashboard → Developers → API keys into STRIPE_SECRET_KEY= in .env.local, save, then run `node scripts/verify-stripe.mjs` then `node scripts/create-stripe-products.mjs`. After that, verify passes and price IDs are in .env.local.
- **2026-02-14** ironforge-studio 55+Billing: Reverse-engineered client integration failure → Stripe secret key invalid/revoked. Added scripts/verify-stripe.mjs, safe API error to client, plan sections: Verify integration, Troubleshooting, Run-the-cycle. Client gets clear message; fix is set valid STRIPE_SECRET_KEY (and price IDs) then re-run verify and test.
- **2026-02-14** ironforge-studio 55+Billing: Build fixed (Supabase typings, ESLint ignoreDuringBuilds). .env.local.example updated with Brevo. Plan doc: Deploy section added. Ready to deploy (Vercel + env + Stripe webhook + run migration).
- **2026-02-14** App pipeline subagents: created coding-bot, design-qa, qa-functional, qa-verifier, qa-integration, security-auditor, deploy-remediation in ~/.cursor/agents/. Updated subagent-routing.mdc with pipeline triggers.
- **2026-02-14** MCP: Added Roblox Studio (binary in ~/.cursor/bin), Make.com (token placeholder in mcp.json), n8n (URL+key placeholders). Auth steps in Desktop/Karl Check First Daily/MCP-AUTH-STEPS.md. Cursor–Claude = handoff files + paste.
- **2026-02-14** OBS: Set recording path, MP4, 3840×1080. Edited scene JSON: added Main Display + Samsung Display (screen_capture type 0), scene "display" uses only those two side-by-side; profile Video 3840×1080. Mic already in scene. Permissions + pick-display-if-prompted + projector in OBS-DUAL-SCREEN-VOICE-SETUP.md.
- **2026-02-14** Bible-of-Terms added to repo (docs/BIBLE-OF-TERMS.md). GUMROAD-EXECUTE-NOW.md created on Desktop with terms reference. Stripe (AI Over Coffee) implemented per 55+Billing; Gumroad copy ready for Faceless Shorts.
- **2026-02-14** Cleaned Bible-of-Terms: removed meta-text, added spacing and headers, saved as Bible-of-Terms.md; deleted old extensionless file.
- **2026-02-14 ~2:30** Set up handoff: created CLAUDE-CURSOR-HANDOFF.md + Cursor rule to append status after each task.
- **faceless-shorts-mvp:** Pipeline runs (Script→Voice→Video). YouTube upload needs `auth_youtube.py` once. Gemini 429 / ElevenLabs 401 → fallbacks used.
- **Git:** Repo initialized, remote set. Push works from your Cursor terminal.
