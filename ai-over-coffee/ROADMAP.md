# AI Over Coffee - 6-Week Execution Roadmap
## Iron Forge Studios | Start Date: March 11, 2026

---

## Week 1: Platform MVP (Mar 11 - Mar 17)
**Goal:** Fully functional platform with billing, gating, and email infrastructure.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 1.1 | Provision Webflow site at ironforge.studio | Karl | Domain DNS | NOT STARTED |
| 1.2 | Design landing page (golden-hour palette, large text, CTA) | Karl | 1.1 | NOT STARTED |
| 1.3 | Set up Stripe account + create two products ($25 Morning Coffee / $49 Nightcap) | Karl | None | NOT STARTED |
| 1.4 | Integrate Memberstack with Webflow | Karl | 1.1 | NOT STARTED |
| 1.5 | Connect Memberstack to Stripe (two-tier gating) | Karl | 1.3, 1.4 | NOT STARTED |
| 1.6 | Build protected member dashboard page (episode grid layout) | Karl | 1.4 | NOT STARTED |
| 1.7 | Implement 1080p embedded video player with subtitle toggle | Karl | 1.6 | NOT STARTED |
| 1.8 | Add watched/unwatched episode status tracking | Karl | 1.6 | NOT STARTED |
| 1.9 | Set up Brevo account + verify sending domain | Karl | Domain DNS | NOT STARTED |
| 1.10 | Configure Brevo email templates (Morning Coffee 6 AM / Nightcap 7 PM) | Karl | 1.9 | NOT STARTED |
| 1.11 | Set up Brevo local-time scheduling for both tiers | Karl | 1.10 | NOT STARTED |
| 1.12 | Build welcome email automation (triggers on Stripe payment) | Karl | 1.9, 1.5 | NOT STARTED |
| 1.13 | End-to-end test: signup -> payment -> welcome email -> dashboard access | Karl | All above | NOT STARTED |

**Week 1 Exit Criteria:**
- [ ] A test user can pay $25 via Stripe, receive a welcome email, and access the dashboard
- [ ] A test user can pay $49 via Stripe, receive a welcome email, and access the dashboard
- [ ] Dashboard displays episode grid with embedded player
- [ ] Brevo sends test emails at correct local times

---

## Week 2: First 14 Morning Coffee Episodes (Mar 18 - Mar 24)
**Goal:** 14 finished Morning Coffee episodes uploaded, 7 scheduled for delivery.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 2.1 | Write scripts for episodes 1-7 (shot list format, every VO line has visual call) | Karl | None | NOT STARTED |
| 2.2 | Write scripts for episodes 8-14 | Karl | None | NOT STARTED |
| 2.3 | Generate B-roll for episodes 1-7 via Runway ML | Karl | 2.1 | NOT STARTED |
| 2.4 | Generate B-roll for episodes 8-14 via Runway ML | Karl | 2.2 | NOT STARTED |
| 2.5 | Record VO for episodes 1-7 via ElevenLabs (warm 60-yr male voice) | Karl | 2.1 | NOT STARTED |
| 2.6 | Record VO for episodes 8-14 via ElevenLabs | Karl | 2.2 | NOT STARTED |
| 2.7 | CapCut assembly for episodes 1-7 (warm color grade, 1080p, subtitles) | Karl | 2.3, 2.5 | NOT STARTED |
| 2.8 | CapCut assembly for episodes 8-14 | Karl | 2.4, 2.6 | NOT STARTED |
| 2.9 | QC pass on all 14 episodes (runtime 3-4 min each) | Karl | 2.7, 2.8 | NOT STARTED |
| 2.10 | Master file naming convention applied to all 14 | Karl | 2.9 | NOT STARTED |
| 2.11 | Upload episodes 1-7 to dashboard + generate thumbnails | Karl | 2.10, 1.6 | NOT STARTED |
| 2.12 | Upload episodes 8-14 to dashboard + generate thumbnails | Karl | 2.10, 1.6 | NOT STARTED |
| 2.13 | Schedule episodes 1-7 in Brevo for daily delivery | Karl | 2.11, 1.11 | NOT STARTED |
| 2.14 | Verify 7-episode buffer requirement is met | Karl | 2.13 | NOT STARTED |

**Week 2 Exit Criteria:**
- [ ] 14 Morning Coffee episodes pass QC (3-4 min each, 1080p, subtitles)
- [ ] Episodes 1-7 uploaded to dashboard with thumbnails
- [ ] Episodes 1-7 scheduled in Brevo
- [ ] 7-episode buffer confirmed (episodes 8-14 ready but not scheduled)

---

## Week 3: Launch - Facebook Ads + Daily Delivery (Mar 25 - Mar 31)
**Goal:** Paid members receiving daily Morning Coffee content.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 3.1 | Create Facebook Business Manager account + pixel install on ironforge.studio | Karl | 1.1 | NOT STARTED |
| 3.2 | Design ad creatives (3 variants targeting 55-75 business owners) | Karl | None | NOT STARTED |
| 3.3 | Set up Facebook ad campaigns (interest targeting: small business, entrepreneurship, 55+) | Karl | 3.1, 3.2 | NOT STARTED |
| 3.4 | Launch ads - sign-ups open | Karl | 3.3, 1.13 | NOT STARTED |
| 3.5 | Daily delivery begins (Morning Coffee, 6 AM local) | Karl | 2.13, 3.4 | NOT STARTED |
| 3.6 | Monitor Brevo deliverability (open rates, bounce rates) | Karl | 3.5 | NOT STARTED |
| 3.7 | Monitor Stripe subscription health (failed payments, churns) | Karl | 3.4 | NOT STARTED |
| 3.8 | Daily content pipeline: continue producing episodes 15-21 | Karl | 2.10 | NOT STARTED |
| 3.9 | Upload + schedule next batch to maintain 7-episode buffer | Karl | 3.8 | NOT STARTED |
| 3.10 | Respond to member support inquiries (email/dashboard issues) | Karl | 3.4 | NOT STARTED |

**Week 3 Exit Criteria:**
- [ ] Facebook ads live and generating sign-ups
- [ ] At least 1 paying member receiving daily Morning Coffee episodes
- [ ] Brevo open rate > 40% on first 3 sends
- [ ] 7-episode buffer maintained
- [ ] Episodes 15-21 in production

---

## Week 4: Nightcap Tier Launch (Apr 1 - Apr 7)
**Goal:** Nightcap content production begins, tier 2 members receiving content.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 4.1 | Write scripts for Nightcap episodes 1-7 (5-7 min format) | Karl | None | NOT STARTED |
| 4.2 | Generate B-roll for Nightcap 1-7 via Runway ML | Karl | 4.1 | NOT STARTED |
| 4.3 | Record VO for Nightcap 1-7 via ElevenLabs | Karl | 4.1 | NOT STARTED |
| 4.4 | CapCut assembly for Nightcap 1-7 (warm color grade, 1080p, subtitles) | Karl | 4.2, 4.3 | NOT STARTED |
| 4.5 | QC pass on Nightcap 1-7 (runtime 5-7 min each) | Karl | 4.4 | NOT STARTED |
| 4.6 | Upload Nightcap episodes to dashboard (tier-gated) | Karl | 4.5 | NOT STARTED |
| 4.7 | Schedule Nightcap delivery in Brevo (7 PM local time) | Karl | 4.6 | NOT STARTED |
| 4.8 | Verify tier continuity: Nightcap members also receive Morning Coffee | Karl | 4.7 | NOT STARTED |
| 4.9 | Continue Morning Coffee pipeline (episodes 22-28) | Karl | Ongoing | NOT STARTED |
| 4.10 | Update Facebook ads with Nightcap tier messaging | Karl | 4.7 | NOT STARTED |
| 4.11 | Write Nightcap episodes 8-14 scripts | Karl | 4.1 | NOT STARTED |

**Week 4 Exit Criteria:**
- [ ] 7 Nightcap episodes pass QC (5-7 min each)
- [ ] Nightcap members receiving 7 PM delivery
- [ ] Tier continuity confirmed ($49 members get both Morning Coffee AND Nightcap)
- [ ] Morning Coffee 7-episode buffer maintained
- [ ] Nightcap 7-episode buffer established

---

## Week 5: Engineering Observability (Apr 8 - Apr 14)
**Goal:** Full monitoring, alerting, and resilience deployed.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 5.1 | Deploy Synaptic Relay monitoring system | Karl | Platform live | NOT STARTED |
| 5.2 | Configure Pain Line alerting (email delivery failures, payment failures) | Karl | 5.1 | NOT STARTED |
| 5.3 | Implement dead-letter queue for failed email deliveries | Karl | 5.1 | NOT STARTED |
| 5.4 | Implement 8 deterministic fail-fast assertions | Karl | 5.1 | NOT STARTED |
| 5.5 | Set up retry playbook for all external service calls (Stripe, Brevo, Memberstack) | Karl | 5.1 | NOT STARTED |
| 5.6 | Verify bit-exact FFmpeg rendering pipeline | Karl | None | NOT STARTED |
| 5.7 | Test all alerting paths (simulate failures) | Karl | 5.2, 5.3, 5.4 | NOT STARTED |
| 5.8 | Continue daily content production (both tiers) | Karl | Ongoing | NOT STARTED |
| 5.9 | Document runbooks for common failure scenarios | Karl | 5.7 | NOT STARTED |

**Week 5 Exit Criteria:**
- [ ] Synaptic Relay dashboard operational
- [ ] Pain Line alerts firing correctly on simulated failures
- [ ] Dead-letter queue catching and requeueing failed deliveries
- [ ] All 8 fail-fast assertions passing
- [ ] Retry playbook tested against each external service

---

## Week 6: 30-Day Buffer + Analytics (Apr 15 - Apr 21)
**Goal:** Full operational maturity with 30-day content buffer and analytics.

| # | Task | Owner | Dependency | Status |
|---|------|-------|------------|--------|
| 6.1 | Achieve 30-day Morning Coffee episode buffer (30 episodes ready) | Karl | Ongoing production | NOT STARTED |
| 6.2 | Achieve 30-day Nightcap episode buffer (30 episodes ready) | Karl | Ongoing production | NOT STARTED |
| 6.3 | Build analytics dashboard (subscriber count, MRR, churn, open rates) | Karl | Platform live | NOT STARTED |
| 6.4 | Configure weekly analytics report (auto-email to Karl) | Karl | 6.3 | NOT STARTED |
| 6.5 | Review and optimize Facebook ad spend (CPA, ROAS) | Karl | 3.3 | NOT STARTED |
| 6.6 | Conduct first member satisfaction pulse (simple 3-question email survey) | Karl | Members active | NOT STARTED |
| 6.7 | Document full operational playbook (daily/weekly/monthly routines) | Karl | All systems live | NOT STARTED |
| 6.8 | Stakeholder/board readout preparation | Karl | 6.3 | NOT STARTED |

**Week 6 Exit Criteria:**
- [ ] 30-day episode buffer for both tiers
- [ ] Analytics dashboard live with real-time MRR tracking
- [ ] Facebook ad CPA documented and optimized
- [ ] Operational playbook complete
- [ ] Board-ready summary prepared

---

## Key Metrics to Track

| Metric | Target | Frequency |
|--------|--------|-----------|
| Morning Coffee buffer | >= 7 episodes | Daily |
| Nightcap buffer | >= 7 episodes | Daily |
| Email open rate | > 40% | Daily |
| Email deliverability | > 95% | Daily |
| Stripe payment success | > 98% | Daily |
| Subscriber churn (monthly) | < 8% | Weekly |
| MRR | Growth trend | Weekly |
| Facebook CPA | < $30 | Weekly |
| Episode QC pass rate | 100% | Per batch |
