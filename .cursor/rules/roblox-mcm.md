---
alwaysApply: true
---

# Palm Springs Paradise — Locked Visual Identity Rules

## MANDATORY: Single-Story Mid-Century Modern (MCM) Architecture

- ALL homes MUST be strictly single-story — NO two-story elements ANYWHERE
- Roof types: flat-roof OR butterfly-roof ONLY — no gabled, hip, mansard, or peaked roofs
- Maximum building height: 12 studs (including roof)
- Every home MUST include: turquoise kidney pool, concrete patio, floor-to-ceiling glass walls, breeze-block privacy screens
- Pastel accent colors only: terracotta (204, 119, 34), turquoise (64, 224, 208), dusty pink (213, 166, 189), cactus green (90, 143, 82)

## MANDATORY: Bright Blue Daytime Sky

- Sky gradient: #87CEEB (135, 206, 235) to #E0F0FF (224, 240, 255) with soft white clouds
- Lighting.ClockTime = 12 (perpetual bright midday)
- Lighting.Brightness = 2
- Atmosphere.Color = Color3.fromRGB(135, 206, 235)
- NO orange skies, NO sunset, NO golden-hour lighting on the sky
- Golden-hour warmth is allowed ONLY on building surfaces and pool water for visual pop
- Night mode is ONLY available via script toggle during designated events, and must auto-revert

## MANDATORY: Environment Style

- Stylized low-poly aesthetic
- Desert sand terrain base
- Palm-lined El Paseo boulevard as central Main Street
- Distant purple-grey mountain backdrop (San Jacinto / San Gorgonio silhouettes)
- All environments must match: bright blue sky, soft midday sun, relaxed poolside hangout feel

## Technical Constraints

- StreamingEnabled = true on Workspace
- Total part count MUST stay under 5,000
- Mobile-first: target 30fps, 40-player capacity
- CollectionService tags for all modular/prefab instances
- Server-authoritative economy — never trust client values
