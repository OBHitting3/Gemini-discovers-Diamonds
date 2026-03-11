# AI Over Coffee - Weekly Milestone Checklist
## Iron Forge Studios

Use this as your weekly standup tracker. Check items off as completed.

---

## Week 1: Platform MVP (Mar 11 - Mar 17)

### Day 1 (Mar 11) - Infrastructure
- [ ] Purchase/verify ironforge.studio domain
- [ ] Configure DNS (A record, CNAME for www)
- [ ] Create Webflow workspace and site
- [ ] Create Stripe account (business verification)

### Day 2 (Mar 12) - Platform Setup
- [ ] Design landing page in Webflow (golden-hour palette)
- [ ] Create Stripe products: Morning Coffee $25/mo, Nightcap $49/mo
- [ ] Install Memberstack on Webflow site
- [ ] Connect Memberstack plans to Stripe products

### Day 3 (Mar 13) - Dashboard Build
- [ ] Build protected member dashboard page
- [ ] Design episode grid layout with thumbnail slots
- [ ] Implement embedded video player (1080p)
- [ ] Add subtitle toggle functionality

### Day 4 (Mar 14) - Email Infrastructure
- [ ] Create Brevo account
- [ ] Verify sending domain (SPF/DKIM/DMARC)
- [ ] Design Morning Coffee email template (thumbnail + single link)
- [ ] Design Nightcap email template
- [ ] Design welcome email template

### Day 5 (Mar 15) - Automation Wiring
- [ ] Connect Stripe webhooks to Brevo (new subscriber trigger)
- [ ] Configure welcome email automation
- [ ] Set up Morning Coffee schedule (6 AM local time)
- [ ] Set up Nightcap schedule (7 PM local time)

### Day 6-7 (Mar 16-17) - Testing
- [ ] Test $25 signup flow end-to-end
- [ ] Test $49 signup flow end-to-end
- [ ] Verify welcome email delivery
- [ ] Verify daily email scheduling (both tiers)
- [ ] Test video playback on mobile + desktop
- [ ] Fix all issues found in testing

### Week 1 Sign-Off
- [ ] **GATE:** Test user can pay, get email, watch video on dashboard
- [ ] Screenshot/record successful end-to-end test
- [ ] Document any open issues for Week 2

---

## Week 2: First 14 Episodes (Mar 18 - Mar 24)

### Batch 1: Episodes 1-7
- [ ] Scripts 1-7 written (shot list format)
- [ ] Runway ML B-roll generated for 1-7
- [ ] ElevenLabs VO recorded for 1-7
- [ ] CapCut assembly complete for 1-7
- [ ] QC pass: all 7 episodes 3-4 minutes, 1080p, subtitles correct

### Batch 2: Episodes 8-14
- [ ] Scripts 8-14 written
- [ ] Runway ML B-roll generated for 8-14
- [ ] ElevenLabs VO recorded for 8-14
- [ ] CapCut assembly complete for 8-14
- [ ] QC pass: all 7 episodes meet spec

### Upload & Schedule
- [ ] Master file naming applied to all 14
- [ ] Thumbnails created for all 14
- [ ] Episodes 1-7 uploaded to dashboard
- [ ] Episodes 8-14 uploaded to dashboard
- [ ] Episodes 1-7 scheduled in Brevo

### Week 2 Sign-Off
- [ ] **GATE:** 14 episodes QC'd and uploaded
- [ ] **GATE:** 7-episode buffer confirmed
- [ ] Content calendar updated through Week 4

---

## Week 3: Launch (Mar 25 - Mar 31)

### Ads Setup (Day 1-2)
- [ ] Facebook Business Manager account created
- [ ] Facebook Pixel installed on ironforge.studio
- [ ] 3 ad creative variants designed
- [ ] Audience targeting configured (55-75, business owners)
- [ ] Daily budget set

### Launch (Day 3)
- [ ] **LAUNCH DAY:** Ads go live
- [ ] First daily Morning Coffee email sends

### Daily Operations (Day 3-7)
- [ ] Monitor: Ad performance (impressions, clicks, CPA)
- [ ] Monitor: Sign-up conversion rate
- [ ] Monitor: Email open rates
- [ ] Monitor: Stripe payment success
- [ ] Produce episodes 15-21 (maintain buffer)

### Week 3 Sign-Off
- [ ] **GATE:** At least 1 paying member receiving content
- [ ] Ad CPA documented
- [ ] Email open rate documented
- [ ] Buffer at >= 7 episodes
- [ ] Episodes 15-21 in production or complete

---

## Week 4: Nightcap Tier (Apr 1 - Apr 7)

### Nightcap Production
- [ ] Nightcap scripts 1-7 written (5-7 min format)
- [ ] B-roll generated
- [ ] VO recorded
- [ ] Assembly complete
- [ ] QC pass (all 5-7 minutes, 1080p)

### Nightcap Launch
- [ ] Nightcap episodes uploaded to dashboard (tier-gated)
- [ ] Nightcap scheduled in Brevo (7 PM local)
- [ ] **VERIFY:** $49 members get BOTH Morning Coffee AND Nightcap
- [ ] Facebook ads updated with Nightcap messaging

### Ongoing Operations
- [ ] Morning Coffee episodes 22-28 produced
- [ ] Both buffers >= 7 episodes
- [ ] Nightcap scripts 8-14 started

### Week 4 Sign-Off
- [ ] **GATE:** Nightcap tier fully operational
- [ ] **GATE:** Tier continuity confirmed
- [ ] Both content buffers >= 7

---

## Week 5: Engineering Observability (Apr 8 - Apr 14)

### Monitoring Setup
- [ ] Synaptic Relay monitoring deployed
- [ ] Pain Line alerting configured
- [ ] Dead-letter queue implemented
- [ ] 8 fail-fast assertions implemented
- [ ] Retry playbook configured for Stripe, Brevo, Memberstack

### Testing
- [ ] Simulate email delivery failure -> verify dead-letter queue catches it
- [ ] Simulate payment failure -> verify Pain Line alert fires
- [ ] Simulate Memberstack timeout -> verify retry logic works
- [ ] Verify bit-exact FFmpeg rendering

### Documentation
- [ ] Failure scenario runbooks written
- [ ] Alert response procedures documented

### Week 5 Sign-Off
- [ ] **GATE:** All alerts firing correctly on simulated failures
- [ ] **GATE:** Dead-letter queue operational
- [ ] Content production on track (both tiers)

---

## Week 6: Maturity (Apr 15 - Apr 21)

### Buffer Achievement
- [ ] Morning Coffee: 30 episodes ready
- [ ] Nightcap: 30 episodes ready

### Analytics
- [ ] Analytics dashboard built (subscribers, MRR, churn, open rates)
- [ ] Weekly auto-report configured
- [ ] Facebook ad CPA optimized

### Operations
- [ ] Member satisfaction pulse sent (3-question survey)
- [ ] Operational playbook documented (daily/weekly/monthly routines)
- [ ] Board/stakeholder readout prepared

### Week 6 Sign-Off
- [ ] **GATE:** 30-day buffer both tiers
- [ ] **GATE:** Analytics dashboard live
- [ ] **FINAL:** Platform fully operational, documented, and de-risked

---

## Daily Standup Template

```
Date: ___________
Yesterday:
Today:
Blockers:
Buffer Status: MC [__] / NC [__]
```

## Weekly Report Template

```
Week: ___
Subscribers: ___
MRR: $___
Churn: ___%
Email Open Rate: ___%
Buffer: MC [__] / NC [__]
Ad Spend: $___
CPA: $___
Key Wins:
Key Risks:
Next Week Priority:
```
