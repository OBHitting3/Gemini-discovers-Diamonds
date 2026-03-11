# AI Over Coffee - Risk Register & Dependency Tracker
## Iron Forge Studios | Updated: March 11, 2026

---

## Risk Register

| ID | Risk | Likelihood | Impact | Mitigation | Owner |
|----|------|-----------|--------|------------|-------|
| R-01 | Runway ML unlimited credits revoked or terms change | Low | Critical | Pre-generate 30-day buffer ASAP; identify backup (Pika, Sora) | Karl |
| R-02 | ElevenLabs voice quality inconsistency between batches | Medium | High | Lock voice ID + settings; QC every episode against reference clip | Karl |
| R-03 | Brevo deliverability drops (spam filters, reputation) | Medium | Critical | Warm domain slowly; authenticate SPF/DKIM/DMARC; monitor daily | Karl |
| R-04 | Stripe payment failures on recurring billing | Low | High | Dunning emails via Stripe; retry logic; Pain Line alerts | Karl |
| R-05 | Webflow/Memberstack integration breaks on platform update | Low | High | Pin versions; test after any Webflow publish; maintain staging site | Karl |
| R-06 | Content production bottleneck (Karl is single point of failure) | High | Critical | Maintain 30-day buffer; batch production; document process for handoff | Karl |
| R-07 | Facebook ad account restricted/banned | Medium | High | Diversify: build email list from day 1; test YouTube/LinkedIn backup channels | Karl |
| R-08 | Low initial conversion rate on Facebook ads | Medium | Medium | A/B test 3 creative variants; test different audience segments; iterate weekly | Karl |
| R-09 | Member churn above 8% monthly | Medium | High | Engagement emails; ask churning members for feedback; improve content based on data | Karl |
| R-10 | Domain/DNS misconfiguration delays launch | Low | Medium | Set up DNS early (Week 1 Day 1); verify propagation before proceeding | Karl |
| R-11 | CapCut changes export quality or removes features | Low | Medium | Lock CapCut version; identify DaVinci Resolve as backup editor | Karl |
| R-12 | Subtitle/caption accuracy issues | Medium | Low | Manual review during QC pass; keep subtitle files editable | Karl |

---

## Dependency Map

### External Service Dependencies

```
Landing Page & Dashboard
├── Webflow (hosting + CMS)
│   ├── Memberstack (membership gating)
│   │   └── Stripe (payment processing)
│   └── Custom embed (video player)
│
Email Delivery
├── Brevo (transactional + scheduled emails)
│   ├── DNS (SPF/DKIM/DMARC)
│   └── Stripe webhooks (trigger welcome flow)
│
Content Production
├── Runway ML (B-roll generation)
├── ElevenLabs (voice synthesis)
├── CapCut (assembly + color grade)
└── FFmpeg (bit-exact rendering)
│
Acquisition
└── Facebook Ads Manager
    └── Facebook Pixel (on ironforge.studio)
```

### Critical Path (Week 1)

```
Domain DNS ──┬── Webflow site ── Memberstack ── Stripe ── End-to-end test
             └── Brevo domain verification ── Email templates ─┘
```

If DNS takes > 24 hours to propagate, the entire Week 1 timeline shifts.

### Service Account Inventory

| Service | Account Needed | Auth Method | Status |
|---------|---------------|-------------|--------|
| Webflow | Workspace plan | Email/SSO | TO DO |
| Memberstack | Business plan | API key | TO DO |
| Stripe | Business account | API keys (test + live) | TO DO |
| Brevo | Business plan | API key + SMTP | TO DO |
| Runway ML | Existing unlimited | API key | ACTIVE |
| ElevenLabs | Pro/Scale plan | API key | ACTIVE |
| CapCut | Pro plan | Login | ACTIVE |
| Facebook | Business Manager | Ad account | TO DO |

---

## Single Points of Failure

| SPOF | Impact | Mitigation |
|------|--------|------------|
| Karl (content creator, operator, admin) | Total project halt | Document everything; 30-day buffer buys time; identify contractor backup |
| Runway ML unlimited plan | No new B-roll | Pre-generate buffer; Pika Labs as backup |
| ironforge.studio domain | No platform access | Register backup domain; maintain DNS access |
| Brevo account | No email delivery | Maintain subscriber export; ConvertKit as backup |

---

## Decision Log

| Date | Decision | Rationale | Decided By |
|------|----------|-----------|------------|
| Mar 10, 2026 | Brand locked as "AI Over Coffee" | Market testing complete | Karl |
| Mar 10, 2026 | Two-tier pricing ($25/$49) | Validated against competitor analysis | Karl |
| Mar 10, 2026 | Facebook as primary acquisition | Best ROI for 55-75 demographic (2026 data) | Karl |
| Mar 10, 2026 | Brevo for email delivery | Best local-time scheduling + deliverability | Karl |
| Mar 10, 2026 | 3-4 min Morning Coffee runtime | Optimized for 55+ retention data | Karl |
| Mar 10, 2026 | 70% evergreen content rule | Reduces production pressure, extends content shelf life | Karl |
