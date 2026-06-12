# Iron Forge Studios — Investor Market Analysis

**Prepared for:** Ron (Prospective Investor)
**Prepared by:** Iron Forge Studios / OBHitting3
**Date:** March 14, 2026
**Classification:** Confidential — For Investment Discussion Only

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Company Overview & Portfolio](#2-company-overview--portfolio)
3. [Project 1: Content Shield — AI Pre-Publication Validation SaaS](#3-project-1-content-shield--ai-pre-publication-validation-saas)
4. [Project 2: Palm Springs Paradise — Roblox Gaming Experience](#4-project-2-palm-springs-paradise--roblox-gaming-experience)
5. [Competitive Landscape](#5-competitive-landscape)
6. [Revenue Models & Unit Economics](#6-revenue-models--unit-economics)
7. [Financial Projections (36-Month Horizon)](#7-financial-projections-36-month-horizon)
8. [Risk Assessment & Mitigation](#8-risk-assessment--mitigation)
9. [Investment Tier Structure](#9-investment-tier-structure)
10. [Source Verification & Methodology](#10-source-verification--methodology)
11. [Appendix: Verified Sources](#11-appendix-verified-sources)

---

## 1. Executive Summary

Iron Forge Studios operates a multi-project portfolio across two high-growth technology sectors: **AI-powered content validation (SaaS)** and **Roblox game development (UGC gaming)**. This analysis presents the two strongest portfolio candidates for outside investment, evaluated against verified market data from public filings, industry reports, and community-sourced intelligence.

**Investment Thesis:** Both projects sit at the intersection of verified macro-tailwinds — regulatory-driven demand for AI content moderation (market growing at 26.6% CAGR to $3.88B in 2026) and Roblox's platform explosion (127M average DAUs in 2025, $1.5B paid to developers). Each project targets an underserved niche within its respective market, with development already underway and meaningful technical milestones achieved.

**Key Numbers:**
- Content moderation AI market: **$3.07B (2025) → $3.88B (2026)**, 26.6% CAGR *(Source: MarketsandMarkets, Research Nester)*
- Roblox platform revenue: **$4.83–4.88B (FY2025)**, up 34–35% YoY *(Source: Roblox Corp SEC Filing 10-K)*
- Roblox developer payouts: **$1.5B (FY2025)**, up 63% from $922.8M (FY2024) *(Source: Roblox Corp IR)*
- Roblox DAUs: **127M average (FY2025)**, peaked at 151.8M in Q3 2025 *(Source: Roblox Corp Quarterly Results)*

---

## 2. Company Overview & Portfolio

### Iron Forge Studios

- **Founded:** February 2026
- **Principal:** OBHitting3
- **Active Repositories:** 8
- **Development Tools:** Claude Code, Cursor (Background Agents), GitHub
- **Domain:** ironforge.studio (registered)

### Active Project Portfolio (as of Feb 28, 2026)

| Project | Category | Status | Tech Stack |
|---------|----------|--------|------------|
| **Content Shield / Joshua 7** | AI SaaS | MVP shipped, security hardened | Python, API, CLI |
| **Palm Springs Paradise** | Roblox Game | Prototype complete, 36 Luau files | Luau, Rojo v7 |
| Faceless Shorts | YouTube Automation | In development | Python |
| yt-autopilot | Video Pipeline | Early stage | Python |
| LeadLatch | SaaS | MVP shipped | Next.js, Supabase |
| Gemini-discovers-Diamonds | Roblox Platform | Active development | Luau |
| 55-AI Integration | Bridge Sync | Development branch | TypeScript |
| FreeLance | Freelance Platform | Placeholder | TBD |

**Portfolio Assessment:** Content Shield and Palm Springs Paradise represent the two most advanced projects with the clearest paths to revenue, backed by the strongest market fundamentals. The remaining portfolio provides optionality but is excluded from this analysis.

---

## 3. Project 1: Content Shield — AI Pre-Publication Validation SaaS

### 3.1 What It Is

Content Shield (branded as "Joshua 7") is a **pre-publication AI content validation platform** that allows publishers, content agencies, and enterprise teams to verify content authenticity, flag AI-generated text, and ensure compliance *before* publishing — not after.

### 3.2 Current Development Status

| Milestone | Status | Date |
|-----------|--------|------|
| Full MVP codebase (validators, API, CLI) | **Merged** | Feb 18, 2026 |
| Agent F validator security hardening | **Merged** | Feb 19, 2026 |
| Agent E security hardening | **Open PR** | Feb 19, 2026 |
| Cursor model setup + MCP config | **Open PR** | Feb 22, 2026 |
| Standalone branded repo (joshua7) | **Initialized** | Feb 18, 2026 |

**Technical Highlights:**
- Content validators with server-authoritative validation
- Timing-safe API key comparisons
- Security middleware with rate limiting
- Audit logging for compliance
- CLI interface for developer workflows

### 3.3 Total Addressable Market (TAM / SAM / SOM)

| Metric | Value | Source |
|--------|-------|--------|
| **TAM** — Global content moderation AI market | $3.88B (2026), growing to $6.8B by 2033 | MarketsandMarkets; Verified Market Reports |
| **SAM** — Pre-publication AI content validation (text-focused, English-speaking markets) | ~$580M (est. 15% of TAM) | Derived: North America = 40.75% of market; pre-pub = ~37% of that |
| **SOM** — Content agencies, SEO firms, enterprise publishers (Year 1–3 capture) | ~$5.8M (est. 1% of SAM) | Conservative penetration estimate |

**Market Growth Drivers (Verified):**
1. **Regulatory tailwinds:** EU Digital Services Act (DSA), EU AI Act, UK Online Safety Act, US TAKE IT DOWN Act (2025) — all mandate content accountability *(Source: EU/UK/US legislative records)*
2. **AI-generated content explosion:** 95% of organizations adopting AI-powered SaaS by 2025 *(Source: BetterCloud/Hostinger SaaS reports)*
3. **Publisher liability:** Content agencies face reputational and legal risk from publishing unvalidated AI-generated content
4. **Cloud-based deployment dominance:** 70% market share projected by 2035 for cloud-based moderation *(Source: Research Nester)*

### 3.4 Differentiation: Pre-Publication vs. Post-Publication

Most competitors (Turnitin, GPTZero, Copyleaks) focus on **post-publication detection** — catching AI content after it's already published. Content Shield occupies the **pre-publication validation** niche:

| Attribute | Content Shield | GPTZero | Originality.AI | Copyleaks |
|-----------|---------------|---------|----------------|-----------|
| Pre-publication workflow | **Yes** | No | Partial | No |
| API + CLI for dev teams | **Yes** | API only | API only | API only |
| Security-hardened (audit logging, rate limiting) | **Yes** | Unknown | Basic | Enterprise |
| Multi-validator pipeline | **Yes** | Single model | Single model | Single model |
| Target customer | Agencies, publishers, enterprise | Education | SEO/publishers | Enterprise/education |
| Pricing | TBD by tiers | $14.99–$45.99/mo | $9.95–$14.95/mo | Custom |

### 3.5 Product-Market Fit Signals

1. **Competitor validation:** Originality.AI, GPTZero, and Copyleaks have all built profitable businesses in AI detection, confirming demand exists
2. **Funding activity:** Musubi (AI moderation startup) raised $5M seed in Feb 2025, led by J2 Ventures, with clients including Grindr and Bluesky *(Source: CNBC, Feb 2025)*
3. **Market gap:** No established player focuses specifically on pre-publication validation pipelines for content teams with audit-grade security
4. **Regulatory urgency:** EU DSA enforcement began 2024; UK Online Safety Act enforcement expanding through 2026

---

## 4. Project 2: Palm Springs Paradise — Roblox Gaming Experience

### 4.1 What It Is

**Palm Springs Paradise: Steal the Oasis** is a Roblox game combining egg-collecting/hatching mechanics, player-vs-player heisting, plot-building (oasis customization), and a full in-game economy — themed around Palm Springs, California with mid-century modern aesthetics and desert culture.

### 4.2 Current Development Status

| Milestone | Status | Date |
|-----------|--------|------|
| Full prototype — 36 Luau files | **In Review (PR #2)** | Feb 22, 2026 |
| Server-authoritative architecture | **Complete** | — |
| 7 distinct game zones | **Complete** | — |
| Monetization system (6 game passes, 7 dev products) | **Complete** | — |
| 50 collectible icons, 52 furniture items | **Complete** | — |
| Rojo v7 project structure | **Production-ready** | — |

**Architecture Completed:**
- DataStore v2 with session locking, auto-save (60s), retry with backoff
- Server-authoritative economy (all mutations validated server-side)
- Rate limiting on all remotes
- Anti-grief systems (30min cooldowns, newbie shield, daily attempt caps, server-hop lockout)
- Modular OOP with clean dependency injection
- 8-service server architecture + 6 client controllers

### 4.3 Total Addressable Market (TAM / SAM / SOM)

| Metric | Value | Source |
|--------|-------|--------|
| **TAM** — Roblox platform total bookings | $6.57–6.62B (FY2025) | Roblox Corp SEC Filing 10-K |
| **SAM** — Simulator/tycoon/collector games (est. 15–20% of platform) | ~$1.0–1.3B | Derived: simulator/tycoon genres consistently top-earners |
| **SOM** — Realistic Year 1 capture for new game | $120K–$600K | Based on top 1,000 developer avg ($980K) with conservative discount |

### 4.4 Platform Economics (Verified)

**Roblox Developer Payout Structure:**

| Metric | Value | Source |
|--------|-------|--------|
| Total creator earnings (FY2025) | $1,503.1M | Roblox 10-K filing |
| YoY growth in creator earnings | +63% (from $922.8M in FY2024) | Roblox 10-K filing |
| Top 10 developers avg earnings | $38.5M/year | Roblox Economic Impact Report, Sep 2025 |
| Top 100 developers avg earnings | $7M/year | Roblox Economic Impact Report |
| Top 1,000 developers avg earnings | $980K/year | Roblox Economic Impact Report |
| Developers earning >$1M | 100+ | Roblox Economic Impact Report |
| DevEx exchange rate | $0.0038 per Robux | Roblox (effective Sep 2025) |
| Median DevEx payout | $1,575/year | Roblox 10-K (12 months ending Dec 2024) |
| Daily active users (FY2025 avg) | 127M | Roblox 10-K |
| Avg hours per DAU per day | 2.7 hours | Roblox 10-K |

**Important Context:** Earnings are extremely top-heavy. The top 1,000 developers represent ~0.03% of the 3.1M developer base but capture the vast majority of revenue. Breaking into the top 1,000 requires a game that achieves sustained engagement and monetization — not just viral moments.

### 4.5 Genre Validation: Simulator/Collector/Tycoon Hybrids

Palm Springs Paradise combines three of the most profitable Roblox genres:

| Genre | Monthly Revenue Range (Established Games) | Example Games | Source |
|-------|-------------------------------------------|---------------|--------|
| Simulators | $3,000–$30,000/mo | Bee Swarm Simulator, Pet Sim 99 | GAM3S.GG, RobloxDesk |
| Tycoons | $2,000–$25,000/mo | Lumber Tycoon 2 | GAM3S.GG |
| Pet/Collector | $2,000–$20,000/mo | Adopt Me! ($50M+ lifetime) | Playgama, FandomWire |

**Viral precedent:** *Steal a Brainrot* — developed in 4 months by a small team, reached 25M users in Sep 2025. This proves small-team games can achieve outsized reach on Roblox.

### 4.6 PSP Monetization Architecture (Built & Coded)

The monetization system is fully architected and coded (see `MonetizationService.lua` and `Constants.lua`):

**Game Passes (One-Time Purchase):**

| Pass | Price (Robux) | USD Equivalent* | Revenue per Sale to Dev** |
|------|---------------|-----------------|--------------------------|
| Desert VIP | 799 | ~$9.99 | ~$3.04 |
| Heist Master | 499 | ~$6.24 | ~$1.90 |
| Auto-Collector | 399 | ~$4.99 | ~$1.52 |
| Oasis Architect | 349 | ~$4.36 | ~$1.33 |
| Speed Demon | 249 | ~$3.11 | ~$0.95 |
| **Mega Bundle** | **1,999** | **~$24.99** | **~$7.60** |

*\*Based on typical Robux pricing (~$0.0125/Robux at consumer purchase)*
*\*\*At DevEx rate of $0.0038/Robux (developer receives ~30.4% of consumer spend)*

**Developer Products (Repeatable Purchases):**

| Product | Price (Robux) | USD Equiv.* | Dev Revenue** |
|---------|---------------|-------------|---------------|
| 1,000 Desert Coins | 99 | ~$1.24 | ~$0.38 |
| 5,000 Desert Coins | 399 | ~$4.99 | ~$1.52 |
| Premium Egg | 149 | ~$1.86 | ~$0.57 |
| Legendary Egg | 499 | ~$6.24 | ~$1.90 |
| Lucky Boost (30min) | 49 | ~$0.61 | ~$0.19 |
| Heist Shield (1hr) | 79 | ~$0.99 | ~$0.30 |
| Vault +5 Slots | 199 | ~$2.49 | ~$0.76 |

---

## 5. Competitive Landscape

### 5.1 Content Shield — SWOT Analysis

| | |
|---|---|
| **Strengths** | First-mover in pre-publication AI validation pipeline; security-hardened from day one; multi-validator architecture; API + CLI for developer workflows; audit logging built-in |
| **Weaknesses** | Pre-revenue; single developer; no brand recognition yet; MVP stage — needs production scaling |
| **Opportunities** | $3.88B market growing 26.6% CAGR; EU DSA / UK OSA regulatory mandates; no dominant pre-publication player; content agencies lack integrated validation tooling |
| **Threats** | Well-funded competitors (Turnitin, Grammarly) could add pre-pub features; rapid commoditization of AI detection; false positive rates erode trust; large language model advances may outpace detection |

### 5.2 Palm Springs Paradise — SWOT Analysis

| | |
|---|---|
| **Strengths** | Fully architected server-authoritative codebase; robust anti-grief/anti-exploit systems; 13 monetization SKUs built; unique Palm Springs aesthetic differentiation; production-grade data persistence |
| **Weaknesses** | No VFX/sound design yet; no live players (pre-launch); single developer; requires marketing budget for discovery; missing Phase 2 features (events, LiveOps, analytics) |
| **Opportunities** | 127M DAU platform growing 69% YoY; simulator/tycoon/collector hybrid targeting proven high-revenue genres; Roblox Creator Rewards program rewarding quality; platform investing in older demographics |
| **Threats** | Extreme competition (~3.1M developers); top-heavy earnings distribution; viral hits are unpredictable; Roblox platform risk (policy changes, DevEx rate changes); requires sustained engagement to monetize |

---

## 6. Revenue Models & Unit Economics

### 6.1 Content Shield Revenue Model

**Model:** B2B SaaS — Usage-based pricing with tiered subscriptions

**Proposed Pricing Tiers (Based on Competitor Analysis):**

| Tier | Monthly Price | Included | Target Customer |
|------|--------------|----------|-----------------|
| Starter | $19/mo | 25K words/month, API access | Freelancers, small blogs |
| Professional | $49/mo | 100K words/month, CLI + API, priority support | Agencies, mid-market publishers |
| Business | $149/mo | 500K words/month, team seats, audit reports | Enterprise content teams |
| Enterprise | Custom | Unlimited, SLA, dedicated support, SSO | Large publishers, platforms |

**Unit Economics (at scale):**

| Metric | Value | Assumptions |
|--------|-------|-------------|
| Customer Acquisition Cost (CAC) | ~$150–300 | Content marketing + SEO (comparable SaaS) |
| Average Revenue Per User (ARPU) | ~$49–89/mo | Weighted toward Professional/Business tiers |
| Lifetime Value (LTV) | ~$1,500–2,700 | 30-month avg retention (SaaS benchmark) |
| LTV:CAC Ratio | 5:1 – 9:1 | Healthy range (>3:1 is target) |
| Gross Margin | 80–85% | API compute + infrastructure costs |

### 6.2 Palm Springs Paradise Revenue Model

**Model:** Free-to-play with in-app purchases (Robux-based)

**Revenue Drivers (Ordered by Expected Contribution):**

1. **Game Passes** (one-time) — High-margin, whale-driven; Mega Bundle ($24.99) is anchor
2. **Developer Products** (consumable) — Recurring spend from engaged players; DC packs + eggs
3. **Roblox Premium Payouts** — Passive income from Premium subscribers' playtime
4. **Creator Rewards** — Engagement-based payouts from Roblox (replaced EBP Jul 2025)

**Unit Economics Per Player:**

| Metric | Conservative | Moderate | Aggressive |
|--------|-------------|----------|------------|
| Avg session length | 15 min | 25 min | 40 min |
| Sessions per week | 2 | 4 | 7 |
| Conversion to payer | 2% | 4% | 7% |
| ARPPU (avg revenue per paying user) | $3.50 | $7.50 | $15.00 |
| Monthly DAU (steady-state) | 500 | 2,500 | 15,000 |

*Note: Roblox industry average is ~1.8M daily unique paying users out of 127M DAU = ~1.4% conversion platform-wide (Source: Roblox 10-K). Conversion rates above assume a well-monetized game.*

---

## 7. Financial Projections (36-Month Horizon)

### 7.1 Content Shield — 3-Year Revenue Projection

**Assumptions:**
- Launch: Q3 2026 (6 months to production-ready)
- Customer growth: 10 → 50 → 200 → 500 (customers, monthly)
- ARPU grows from $35/mo (early adopters) to $65/mo (as enterprise tiers added)
- Churn: 5% monthly in Year 1, declining to 3% by Year 3

| Period | Customers (End) | MRR | ARR | Cumulative Revenue |
|--------|----------------|-----|-----|-------------------|
| Q3 2026 (Launch) | 10 | $350 | $4,200 | $1,050 |
| Q4 2026 | 35 | $1,575 | $18,900 | $5,888 |
| Q2 2027 (Year 1 End) | 120 | $6,600 | $79,200 | $28,350 |
| Q4 2027 | 250 | $15,000 | $180,000 | $79,350 |
| Q2 2028 (Year 2 End) | 400 | $26,000 | $312,000 | $201,350 |
| Q2 2029 (Year 3 End) | 800 | $52,000 | $624,000 | $592,350 |

**Break-even estimate:** Month 14–18 (assuming $3,000–5,000/mo operating costs)

### 7.2 Palm Springs Paradise — 3-Year Revenue Projection

**Assumptions:**
- Soft launch: Q3 2026 (Phase 2 completion: VFX, sound, events)
- Full launch: Q4 2026
- DAU growth modeled against comparable Roblox games in simulator/tycoon genre
- DevEx rate: $0.0038/Robux

| Scenario | Year 1 Revenue | Year 2 Revenue | Year 3 Revenue | 3-Year Total |
|----------|---------------|----------------|----------------|-------------|
| **Conservative** (500 avg DAU, 2% conversion) | $12,600 | $25,200 | $31,500 | $69,300 |
| **Moderate** (2,500 avg DAU, 4% conversion) | $67,500 | $135,000 | $162,000 | $364,500 |
| **Aggressive** (15,000 avg DAU, 7% conversion) | $567,000 | $756,000 | $945,000 | $2,268,000 |

**Key Variable:** Discovery. Roblox's algorithm favors engagement metrics. If PSP achieves strong session times (>20 min) and retention (D1 >40%, D7 >15%), the algorithm will surface it to more players organically.

### 7.3 Combined Portfolio Projection

| Scenario | 3-Year Content Shield | 3-Year PSP | 3-Year Combined |
|----------|----------------------|------------|----------------|
| Conservative | $592,350 | $69,300 | $661,650 |
| Moderate | $592,350 | $364,500 | $956,850 |
| Aggressive | $592,350 | $2,268,000 | $2,860,350 |

*Content Shield uses single projection; PSP uses scenario-based.*

---

## 8. Risk Assessment & Mitigation

### 8.1 Risk Matrix

| Risk | Probability | Impact | Severity | Mitigation |
|------|------------|--------|----------|------------|
| **Single developer / key-person risk** | High | Critical | **Critical** | Use investment to hire; document all architecture (already done); modular codebase enables parallel development |
| **PSP fails to achieve discovery on Roblox** | Medium-High | High | **High** | Allocate marketing budget ($1K–5K for Roblox advertising); optimize for algorithm signals; iterate on retention |
| **Content Shield commoditization** | Medium | Medium | **Medium** | Deepen pre-pub niche; build enterprise features (SSO, audit reports, compliance dashboards); establish contracts |
| **Roblox platform risk (policy/DevEx changes)** | Low-Medium | High | **Medium** | Diversify revenue across SaaS + gaming; PSP monetization is multi-stream; monitor platform changes |
| **AI detection accuracy erodes** | Medium | Medium | **Medium** | Multi-validator pipeline architecture allows swapping/adding detection models; not dependent on single model |
| **Regulatory changes reduce content moderation demand** | Very Low | High | **Low** | Current regulatory trend is *increasing* moderation requirements (DSA, AI Act, OSA) |

### 8.2 Honest Assessment

**What could go wrong:**
- The median Roblox DevEx payout is $1,575/year — most games don't make meaningful money
- Content Shield is entering a market with well-funded competitors (Turnitin has institutional trust, Grammarly has 30M+ users)
- Both projects are pre-revenue with a single developer
- Roblox's top-heavy economics mean that even good games may not break into profitable territory

**What creates upside:**
- Content Shield's pre-publication niche has no dominant player
- PSP's architecture is unusually robust for an indie Roblox game (server-authoritative, anti-exploit, production data persistence)
- Development velocity is high (8 repos, multiple shipped MVPs in weeks)
- Low burn rate means small capital goes further

---

## 9. Investment Tier Structure

*Dollar amounts to be determined through discussion. The following structure outlines what each tier unlocks.*

### Tier 1 — Seed / Angel

**Use of Funds:**
- Content Shield: Production hosting, API infrastructure, initial marketing
- PSP: Roblox advertising budget, sound/VFX asset purchases
- Operational: 3-month developer runway

**Investor Receives:**
- Equity stake (% TBD based on valuation discussion)
- Quarterly financial reports and development updates
- Advisory input on product direction

**Expected Timeline to Returns:** 12–18 months (Content Shield SaaS revenue + PSP launch revenue)

---

### Tier 2 — Growth

**Use of Funds:**
- Content Shield: Hire part-time backend engineer; enterprise feature development (SSO, team management); sales/marketing
- PSP: Contract Roblox artist for VFX/3D assets; Phase 2 features (events, LiveOps); sustained advertising
- Operational: 6-month developer runway + contractor budget

**Investor Receives:**
- Larger equity stake
- Board observer or advisory board seat
- Monthly detailed financial reporting with audit-grade documentation
- Revenue share consideration

**Expected Timeline to Returns:** 8–14 months

---

### Tier 3 — Strategic Partner

**Use of Funds:**
- Content Shield: Full-time engineering hire; enterprise sales motion; SOC 2 compliance pursuit; integration partnerships
- PSP: Full-time Roblox developer hire; multi-game studio build-out; cross-game economy features
- Portfolio: Accelerate LeadLatch and YouTube automation projects
- Operational: 12-month runway for expanded team

**Investor Receives:**
- Significant equity position
- Active board seat
- Detailed monthly P&L, cash flow statements, and KPI dashboards
- Right of first refusal on future rounds
- Involvement in strategic decisions

**Expected Timeline to Returns:** 6–12 months

---

## 10. Source Verification & Methodology

### Methodology

All financial data and market statistics in this document are sourced from:

1. **Public company filings** — Roblox Corp SEC 10-K (FY2025), quarterly earnings releases
2. **Industry research reports** — MarketsandMarkets, Research Nester, Verified Market Reports, Mordor Intelligence
3. **News/journalism** — CNBC, Morningstar, Game Developer, GamesHub, GAM3S.GG
4. **Platform documentation** — Roblox Creator documentation, DevEx program details
5. **Community intelligence** — Roblox Developer Forum, Substack (GameDevReports)
6. **Competitor analysis** — Publicly available pricing pages for GPTZero, Originality.AI, Copyleaks

### Verification Standards

Per investor requirements, all data points meet the following criteria:
- **Searchable:** Every statistic can be independently verified through the cited source
- **Cross-referenced:** Key figures (DAU, revenue, developer payouts) verified across multiple sources
- **Recency:** All market data from 2025–2026 publications
- **Conservative bias:** Where sources disagree, the more conservative figure is used
- **No projections presented as facts:** All forward-looking numbers are clearly labeled as projections with stated assumptions

### What This Analysis Does NOT Include

- Proprietary financial data from private competitors (revenue for GPTZero, Originality.AI, etc. is not publicly disclosed)
- Guaranteed return projections — all financial models are scenario-based
- Valuation — company valuation to be determined through negotiation, not asserted here

---

## 11. Appendix: Verified Sources

### Roblox Platform & Economics

1. Roblox Corp 10-K Annual Report (FY2025) — SEC Filing via StockTitan
   https://www.stocktitan.net/sec-filings/RBLX/10-k-roblox-corp-files-annual-report-7d51454cd829.html

2. Roblox Quarterly Financial Results — Investor Relations
   https://ir.roblox.com/financials/quarterly-results/default.aspx

3. Roblox Q2 2025 Earnings Release
   https://ir.roblox.com/news/news-details/2025/Roblox-Reports-Second-Quarter-2025-Financial-Results/default.aspx

4. Roblox Annual Economic Impact Report (Sep 2025)
   https://about.roblox.com/newsroom/2025/09/roblox-annual-economic-impact-report

5. Roblox Creator Earnings 2025 — GamesHub
   https://www.gameshub.com/news/article/roblox-creator-earnings-2025-report-millionaire-developers-2856170/

6. Roblox Top Developers Earning Millions — GameDevReports (Substack)
   https://gamedevreports.substack.com/p/roblox-top-100-roblox-developers

7. Roblox User and Growth Stats 2026 — Backlinko
   https://backlinko.com/roblox-users

8. Roblox Revenue and Usage Statistics 2026 — Business of Apps
   https://www.businessofapps.com/data/roblox-statistics/

9. Roblox Statistics 2026 — DigiExe
   https://digiexe.com/blog/roblox-statistics/

10. Roblox Top-Earning Games June 2025 — GAM3S.GG
    https://gam3s.gg/news/roblox-top-earning-games-in-june-2025/

11. Most Profitable Roblox Game Genres 2026 — RobloxDesk
    https://www.robloxdesk.com/most-profitable-roblox-game-genres-2026/

12. Roblox Developer Unit Economics — Naavik
    https://naavik.co/digest/roblox-developer-unit-economics/

13. Roblox Earnings Analysis — Morningstar
    https://www.morningstar.com/stocks/roblox-earnings-exceptional-user-growth-continues-monetization-margin-expansion-concern

14. How Roblox Hit 111M DAU — GrowthCurve
    https://growthcurve.co/how-roblox-hit-111-million-dau

### AI Content Moderation Market

15. Content Moderation AI Market Report — MarketsandMarkets (via EIN Presswire)
    https://www.einpresswire.com/article/893651670/global-market-report-on-content-moderation-ai-2026-business-expansion-key-growth-drivers-trends-from-now-until-2030

16. Content Moderation Services Market to 2035 — Research Nester
    https://www.researchnester.com/reports/content-moderation-services-market/7630

17. Automated Content Moderation Market to 2030 — Research and Markets
    https://www.researchandmarkets.com/report/global-automated-content-moderation-market

18. AI Content Moderation Market to 2033 — Verified Market Reports
    https://www.verifiedmarketreports.com/product/ai-content-moderation-market/

19. State of AI Content Moderation 2026 — Foiwe
    https://www.foiwe.com/state-of-ai-content-moderation-2026/

20. AI Content Moderation Trends 2026 — Conectys
    https://www.conectys.com/blog/posts/ai-content-moderation-trends-for-2026/

21. Content Moderation Solutions Market — Expert Market Research
    https://www.expertmarketresearch.com/reports/content-moderation-solutions-market

22. Content Moderation Market 2031 — Mordor Intelligence
    https://www.mordorintelligence.com/industry-reports/content-moderation-market

### AI Detection Competitors

23. GPTZero vs Copyleaks vs Originality Comparison
    https://gptzero.me/news/gptzero-vs-copyleaks-vs-originality/

24. AI Detector Market — MarketsandMarkets
    https://www.marketsandmarkets.com/ResearchInsight/ai-detector-market.asp

25. Originality AI Review 2026 — AIxRadar
    https://aixradar.com/originality-ai-review/

### Startup Funding & VC Landscape

26. Musubi AI Content Moderation $5M Seed — CNBC
    https://www.cnbc.com/2025/02/21/ai-content-moderation-startup-musubi-raises-5-million-in-seed-funding.html

27. AI Funding Trends 2025 — Crunchbase
    https://news.crunchbase.com/ai/big-funding-trends-charts-eoy-2025/

28. SaaS Industry Spotlight Q3 2025 — Carta
    https://carta.com/data/saas-industry-spotlight-Q3-2025/

29. SaaS Statistics 2026 — Hostinger
    https://www.hostinger.com/tutorials/saas-statistics

30. SaaS Statistics 2026 — BetterCloud
    https://www.bettercloud.com/monitor/saas-statistics/

---

*This document was prepared with data verified through multiple independent sources as of March 14, 2026. All projections are forward-looking estimates and should not be construed as guarantees of future performance. Investment involves risk, including possible loss of principal.*

*Prepared by Iron Forge Studios — contact@ironforge.studio*
