# Architecture

## Overview

Content Shield follows a layered architecture:

```
┌─────────────────────────────────────────┐
│              Integrations               │
│  (WordPress, HubSpot, Mailchimp, etc.)  │
├─────────────────────────────────────────┤
│             Shield Runner               │
│  (Orchestrates validation pipeline)     │
├─────────────────────────────────────────┤
│               Shields                   │
│  (Brand Voice, Factual, Legal, etc.)    │
├──────────────┬──────────────────────────┤
│   Analyzers  │       AI Agents          │
│  (Text, URL, │  (Gemini, Claude, GPT)   │
│   Contact)   │                          │
├──────────────┴──────────────────────────┤
│          Brand Profiles                 │
│  (Voice, Terminology, Templates)        │
├─────────────────────────────────────────┤
│           Schema Layer                  │
│  (Events, Content, Metrics, Validation) │
├─────────────────────────────────────────┤
│          Resilience Layer               │
│  (Retry, Circuit Breaker, DLQ)          │
├─────────────────────────────────────────┤
│     Emitters / Collectors / Dashboard   │
│  (Console, Webhook, Pub/Sub, Grafana)   │
└─────────────────────────────────────────┘
```

## Key Design Decisions

1. **Pydantic schemas** for all data models — strict validation at boundaries
2. **Pluggable shields** via base class — easy to add new validation types
3. **Multi-agent routing** — choose the best AI provider per task
4. **Resilience-first** — every external call wrapped in retry + circuit breaker
5. **Event-driven** — all shield results emitted as structured events
