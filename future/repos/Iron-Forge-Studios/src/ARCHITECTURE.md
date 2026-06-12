# Palm Springs Paradise: Steal the Oasis — Architecture

## Project Structure

```
src/
├── default.project.json          # Rojo sync config
├── ServerScriptService/
│   ├── GameInit.server.lua       # Server bootstrap (init order)
│   ├── Services/
│   │   ├── DataService.lua       # DataStore v2, session locking, auto-save
│   │   ├── WorldService.lua      # 2048x2048 world, 7 zones, skybox, props
│   │   ├── EggService.lua        # Egg hatching, rarity rolls, evolution, passive income
│   │   ├── HeistService.lua      # Heist flow, lockpicking, vault, anti-grief
│   │   ├── PlotService.lua       # 32x32 plots, furniture, display pedestals, ratings
│   │   ├── TradeService.lua      # Direct trade, marketplace, cross-server
│   │   ├── MonetizationService.lua # Passes, products, receipt processing, premium
│   │   └── LeaderboardService.lua  # OrderedDataStore boards, physical displays
│   └── Modules/
│       └── RateLimiter.lua       # Per-player rate limiting
├── ReplicatedStorage/
│   ├── Modules/
│   │   ├── Shared/
│   │   │   ├── Constants.lua     # All tuning values, enums, config
│   │   │   ├── Remotes.lua       # Central remote registry
│   │   │   ├── Signal.lua        # Custom event system
│   │   │   └── Util.lua          # Deep copy, weighted random, formatting
│   │   └── Data/
│   │       ├── PlayerDataTemplate.lua  # Player data schema
│   │       ├── IconDatabase.lua        # 50 collectible desert icons
│   │       └── FurnitureDatabase.lua   # 52 mid-century furniture items
│   └── Assets/
│       ├── UI/                   # UI image assets (add here)
│       └── Sounds/               # Sound effect assets (add here)
├── StarterPlayerScripts/
│   ├── ClientInit.client.lua     # Client bootstrap
│   └── Controllers/
│       ├── DataController.lua    # Client data cache, change signals
│       ├── EggController.lua     # Hatch requests, results
│       ├── HeistController.lua   # Heist flow, lockpick input, steal cam
│       ├── PlotController.lua    # Build mode, furniture preview, grid snap
│       ├── TradeController.lua   # Trade flow, marketplace
│       └── UIController.lua      # HUD, action bar, notifications
├── StarterGui/                   # Additional GUI elements
├── ServerStorage/
│   ├── Templates/                # Server-only templates
│   └── FurnitureModels/          # 3D furniture models (add here)
└── Workspace/                    # Runtime-generated world content
```

## Architecture Principles

1. **Server-Authoritative**: All economy mutations (currency, icons, trades, heists) validated server-side
2. **Modular OOP**: Each service owns its domain; clean dependency injection via Init() order
3. **DataStore v2**: Session locking, auto-save (60s), retry with backoff, schema migrations
4. **Rate Limiting**: Per-player limits on all remotes to prevent exploitation
5. **Signal-Driven**: Decoupled inter-service communication via custom Signal module
6. **Client-Server Split**: Controllers mirror services; clients get read-only cached data

## Init Order (Server)
DataService → WorldService → EggService → HeistService → PlotService → TradeService → MonetizationService → LeaderboardService

## Core Loop
Spawn → Free eggs → Hatch at Hot Springs → Passive income → Build oasis → Heist / Get heisted → Trade → Leaderboards

## Key Systems

### Economy: DesertCoins (DC)
- Starting: 500 DC
- Egg costs: 100 / 500 / 2,500 / 10,000 DC
- Passive income from icons: 1–500 DC/min base, multiplied by evolution tier
- 5% trade tax, 1 DC/unique visitor/day

### Rarities (weighted random)
Common 45% → Uncommon 25% → Rare 15% → Epic 8% → Legendary 4% → Mythical 2.9% → SECRET 0.1%

### Evolution Path
Base → Shiny (3 dupes, 2x) → Golden (5, 4x) → Diamond (10, 8x) → Celestial (25, 16x)

### Anti-Grief (Heist)
- 30min fail cooldown, 30min target cooldown, 30min newbie shield
- 10 daily attempts (13 with Heist Master pass)
- 5min server-hop lockout
- Vault: 3 free slots, expandable via Robux

## Next Steps (Phase 2)
- [ ] VFX: Egg hatch particles, heist slow-mo camera, evolution sparkles
- [ ] Sound design: Ambient desert, UI clicks, hatch jingle, heist alarm
- [ ] Advanced UI: Inventory grid, collection book album, trade window detail
- [ ] Events: Coachella Festival (weekly), Desert Night Market, Sandstorm Chase
- [ ] LiveOps: Featured eggs, limited-time icons, seasonal content
- [ ] Analytics: Telemetry hooks, A/B testing framework
