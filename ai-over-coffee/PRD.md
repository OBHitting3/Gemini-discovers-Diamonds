# Product Requirements Document
## AI Over Coffee Membership Platform
### Iron Forge Studios

| Field | Value |
|-------|-------|
| **Version** | 1.0 (Final) |
| **Date** | March 10, 2026 |
| **Status** | Approved - Ready for Execution |
| **Owner** | Karl, Iron Forge Studios |
| **Brand** | AI Over Coffee |
| **Domain** | ironforge.studio |

---

## 1. Executive Summary

The AI Over Coffee platform converts existing paid-but-idle Runway ML unlimited credits into a recurring-revenue membership business. It delivers daily, story-driven AI education videos to solo business owners aged 55-75 who still run the companies they built.

**Core Positioning:** _"It's not smarter than you. It's just faster."_

### Revenue Model

| Tier | Name | Price | Content |
|------|------|-------|---------|
| 1 | Morning Coffee | $25/month | 3-4 min daily episodes |
| 2 | Nightcap | $49/month | 5-7 min daily episodes |

**Launch Target:** First paying members receiving content within 6 weeks.

---

## 2. Pillars

### Pillar 1: Objective
Build and operate the private membership platform at ironforge.studio delivering daily videos, two-tier Stripe billing, automated localized email delivery, and a simple, respectful member experience.

### Pillar 2: Background & Assumptions
- **Target Audience:** Solo business owners 55-75 (State Farm agents, realtors, attorneys, shop owners, contractors, trucking, etc.)
- **Validated Assumptions (2026 data):**
  - Facebook is the highest-performing acquisition channel for this demographic
  - Brevo provides best-in-class deliverability and local-time scheduling
  - Optimal Morning Coffee runtime: 3-4 minutes for 55+ retention
  - Sell with stories and insider social currency, never jargon or tutorials

### Pillar 3: Features & User Stories

| ID | Feature | Priority |
|----|---------|----------|
| F-01 | Two-tier Stripe membership ($25/$49 monthly) | P0 |
| F-02 | Protected member dashboard with episode grid | P0 |
| F-03 | Embedded 1080p player with subtitle toggle | P0 |
| F-04 | Watched/unwatched episode status | P1 |
| F-05 | Daily automated emails (6 AM / 7 PM local time) | P0 |
| F-06 | Admin content calendar | P1 |
| F-07 | Batch upload portal | P1 |
| F-08 | Synaptic Relay observability | P2 |
| F-09 | Pain Line alerting | P2 |
| F-10 | Dead-letter queue | P2 |
| F-11 | 8 deterministic fail-fast assertions | P2 |

### Pillar 4: User Experience Flow & Design

**Visual Identity:**
- Warm golden-hour color palette
- Large readable text
- No gamification or progress bars
- Ken Burns-inspired pacing in videos

**User Journey:**
1. Landing page -> Stripe checkout
2. Instant welcome + first 5-episode batch
3. Daily timed emails with one thumbnail and one link
4. Simple dashboard for re-watching

**Video Production Style:**
- B-roll heavy (Runway ML)
- Warm conversational voice (ElevenLabs)
- CapCut assembly
- Ken Burns-inspired pacing

### Pillar 5: Constraints & Dependencies

| Tool | Purpose | Status |
|------|---------|--------|
| Runway ML | Video generation (unlimited) | Paid - Active |
| CapCut | Video assembly | Active |
| ElevenLabs | Voice generation | Active |
| Webflow | Website/platform | To provision |
| Memberstack | Membership gating | To provision |
| Stripe | Billing | To provision |
| Brevo | Email delivery | To provision |

**Production Rules:**
- Always maintain >= 7 episodes buffered
- 70% evergreen content
- Batch sprints of 5-7 episodes

### Pillar 6: Open Questions
None. All items resolved with current 2026 data.

---

## 3. Production Pipeline (Per Episode)

1. Script written to shot list (every VO line has visual call)
2. Runway ML B-roll generation
3. ElevenLabs warm 60-year-old male voice
4. CapCut assembly, warm color grade, 1080p export
5. Single QC pass
6. Master file naming + upload to dashboard + Brevo schedule

---

## 4. Engineering Standards

- OODA-loop engineering philosophy
- Retry playbook for all external service calls
- Dead-letter queue for failed deliveries
- Bit-exact FFmpeg rendering
- 8 fail-fast assertions (defined in Engineering Architecture)
- Permanent 7-episode buffer requirement
