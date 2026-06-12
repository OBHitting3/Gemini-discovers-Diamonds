-- ============================================================
-- LeadLatch — Seed Data
-- Migration 00003: Default automation rule templates
-- ============================================================

-- This will be inserted per-org when an org is created.
-- Template for the default "speed-to-lead" automation:
-- The app inserts this row when a new org is created.

-- Example followup_cadence JSON structure:
-- [
--   { "delay_minutes": 0,   "action": "email", "template": "instant_reply" },
--   { "delay_minutes": 60,  "action": "email", "template": "followup_1h" },
--   { "delay_minutes": 1440, "action": "email", "template": "followup_24h" },
--   { "delay_minutes": 4320, "action": "email", "template": "followup_72h" }
-- ]

-- No seed data inserted here; the app handles org-specific seeding.
-- This file documents the expected JSON shapes for automation_rules.followup_cadence.
