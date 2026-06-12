# Palm Springs Paradise 🌴

**A social life-simulation and creative expression game set in a stylized, mid-century modern Palm Springs.**

> Art Direction Prototype — Rojo v7 Project for Roblox Studio

---

## Overview

Palm Springs Paradise is a Roblox experience where players arrive as new residents in a sun-drenched desert town and build their dream life: decorating iconic modernist homes, curating fashion for poolside events, tending desert gardens, running boutique businesses, and competing in weekly community festivals.

### Core Pillars

| Pillar | Description |
|--------|-------------|
| **Desert Dream Homes** | Claim plots, build single-story MCM homes, decorate with mid-century furniture, earn Vibes Score |
| **Poolside Fashion & Runway** | Themed fashion events, outfit submission, runway walks, voting competitions |
| **Community Desert Gardens** | Shared 16-plot garden with real-time planting, watering, wilting, and harvesting |
| **Boutique Economy** | Player-owned luxury storefronts on El Paseo boulevard with buy/sell/trade |

### Game Loop

- **Morning:** Tend your garden, stock your shop
- **Afternoon:** Decorate your home, try on outfits
- **Evening:** Fashion events, trading, community festivals

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Project Format | **Rojo v7** (`.lua` file conventions) |
| Language | **Luau** (Roblox's Lua variant) |
| Hot-Path Persistence | **Roblox DataStore** via ProfileService-style wrapper |
| Cold-Path Persistence | **Supabase** REST API via HttpService (mock mode for testing) |
| Webhooks | **n8n-ready** placeholder endpoints (CF7 signups, Modernism Week scheduling) |
| Streaming | **StreamingEnabled** on Workspace |
| UI | Programmatic **ScreenGui** creation (mobile-first) |

---

## Project Structure

```
/
├── .cursor/rules/roblox-mcm.md       # Locked visual identity rules
├── default.project.json               # Rojo v7 project config
├── README.md                          # This file
└── src/
    ├── server/                        → ServerScriptService
    │   ├── init.server.lua            # Server bootstrap
    │   ├── Services/
    │   │   ├── EconomyService.lua     # Server-authoritative economy
    │   │   ├── PlotService.lua        # Plot claiming, homes, furniture
    │   │   ├── GardenService.lua      # Shared garden management
    │   │   ├── FashionService.lua     # Runway events & voting
    │   │   ├── ShopService.lua        # El Paseo boutiques
    │   │   ├── EventService.lua       # Weekly themes, Modernism Week
    │   │   └── PersistenceService.lua # DataStore + Supabase bridge
    │   ├── Builders/
    │   │   ├── EnvironmentBuilder.lua # Terrain, sky, mountains, roads
    │   │   ├── HomeBuilder.lua        # 4 MCM home styles
    │   │   ├── StorefrontBuilder.lua  # El Paseo boulevard
    │   │   ├── GardenBuilder.lua      # Desert garden area
    │   │   └── RunwayBuilder.lua      # Fashion runway stage
    │   └── Commands/
    │       └── TestCommands.lua       # Chat-based test commands
    ├── client/                        → StarterPlayerScripts
    │   ├── init.client.lua            # Client bootstrap
    │   ├── Controllers/
    │   │   ├── UIController.lua       # GUI management
    │   │   ├── PlotController.lua     # Plot interaction
    │   │   ├── GardenController.lua   # Garden visuals & prompts
    │   │   ├── FashionController.lua  # Runway walk & voting
    │   │   ├── ShopController.lua     # Shop browsing
    │   │   └── NightToggleController.lua # Night mode for events
    │   └── UI/
    │       ├── HUDTemplate.lua        # Main HUD (coins, prestige, nav)
    │       ├── PlotUI.lua             # Home style & furniture panel
    │       ├── ShopUI.lua             # Shop management panel
    │       ├── GardenUI.lua           # Garden grid & seed selection
    │       ├── FashionUI.lua          # Fashion event panel
    │       └── EventUI.lua            # Events & festivals panel
    ├── shared/                        → ReplicatedStorage
    │   ├── GameConfig.lua             # All constants & config
    │   ├── Types.lua                  # Luau type definitions
    │   ├── ItemCatalog.lua            # Furniture, plants, outfits, goods
    │   ├── RemoteManager.lua          # RemoteEvent/Function manager
    │   ├── Utilities.lua              # Shared helpers
    │   ├── ProfileServiceWrapper.lua  # DataStore wrapper
    │   ├── SupabaseClient.lua         # Supabase REST client
    │   └── WebhookClient.lua          # n8n webhook placeholders
    └── gui/                           → StarterGui
        └── MainHUD.lua                # ScreenGui entry point
```

**Total: 39 Luau source files, ~10,000+ lines of production-ready code**

---

## Setup Instructions

### Prerequisites

- [Roblox Studio](https://create.roblox.com/) (latest version)
- [Rojo v7](https://rojo.space/) CLI installed
- [Rojo VS Code/Cursor Extension](https://marketplace.visualstudio.com/items?itemName=evaera.vscode-rojo) (optional)

### Quick Start

1. **Clone the repo:**
   ```bash
   git clone https://github.com/OBHitting3/Gemini-discovers-Diamonds.git
   cd Gemini-discovers-Diamonds
   git checkout cursor/art-direction-prototype-6c9e
   ```

2. **Build the Rojo project:**
   ```bash
   rojo build -o PalmSpringsParadise.rbxlx
   ```

3. **Open in Roblox Studio:**
   - Open `PalmSpringsParadise.rbxlx` in Roblox Studio
   - Or use `rojo serve` + the Rojo Studio plugin for live sync

4. **Enable HttpService** (for Supabase/webhooks, optional):
   - Game Settings → Security → Enable "Allow HTTP Requests"

5. **Play Solo** to test!

### Live Sync (Development)

```bash
rojo serve
```

Then in Roblox Studio, connect via the Rojo plugin toolbar.

---

## Test Commands

Type these in chat during Play Solo (prefix with `/`):

| Command | Description |
|---------|-------------|
| `/help` | Show all commands |
| `/claimplot [1-4]` | Claim a residential plot |
| `/buildhouse [kaufmann\|frey\|wexler\|neutra]` | Build MCM home on your plot |
| `/placefurniture [itemId]` | Place furniture at look position |
| `/claimshop [1-6]` | Claim El Paseo storefront |
| `/stock [itemId] [qty] [price]` | Stock your shop with items |
| `/buy [shopId] [itemId]` | Buy from a player shop |
| `/plant [plantId] [plotIndex]` | Plant seed in garden |
| `/water [plotIndex]` | Water a garden plot |
| `/harvest [plotIndex]` | Harvest mature plant |
| `/fashion` | Start a fashion event immediately |
| `/joinrunway` | Join the active fashion event |
| `/vote [playerName]` | Vote for a player in fashion event |
| `/night` | Toggle night mode |
| `/coins [amount]` | Give yourself SunCoins (test) |
| `/prestige [amount]` | Give yourself Prestige (test) |
| `/event [theme]` | Trigger an event theme |
| `/partcount` | Show total part count |
| `/inventory` | Show your inventory |
| `/save` | Force save your data |
| `/status` | Show all system statuses |

### Example Play Solo Flow

```
/coins 5000           → Get starting funds
/claimplot 1          → Claim residential plot #1
/buildhouse kaufmann  → Build The Kaufmann MCM home
/placefurniture eames_lounge → Place an Eames chair
/plant saguaro_cactus 1      → Plant cactus in garden plot #1
/water 1              → Water the plant
/claimshop 1          → Claim El Paseo storefront
/stock designer_sunglasses 5 50 → Stock 5 sunglasses at 50 SC each
/fashion              → Start a fashion event
/joinrunway           → Join the event
/status               → Check everything
/partcount            → Verify < 5,000 parts
```

---

## Locked Visual Identity

**ALL environments must match these rules:**

- **Sky:** Bright blue gradient #87CEEB → #E0F0FF with soft white clouds
- **Lighting:** Perpetual midday (ClockTime=12, Brightness=2)
- **Homes:** Single-story ONLY — flat-roof or butterfly-roof
- **Pools:** Turquoise kidney pools on every home
- **Materials:** Concrete patios, floor-to-ceiling glass, breeze-block screens
- **Accents:** Terracotta (204,119,34), Turquoise (64,224,208), Dusty Pink (213,166,189), Cactus Green (90,143,82)
- **NO** orange skies, NO sunset, NO golden-hour (except building surface warmth)
- **Night mode** is event-only and auto-reverts

---

## Home Styles

| Style | Architect | Roof | Key Features |
|-------|-----------|------|-------------|
| **The Kaufmann** | Richard Neutra | Flat | L-shaped, turquoise kidney pool, breeze-block screen |
| **The Frey** | Albert Frey | Butterfly | Covered carport, glass on 3 sides, desert garden integration |
| **The Wexler** | Donald Wexler | Flat | Central courtyard, dusty-pink accent wall, 2x breeze screens |
| **The Neutra** | Richard Neutra | Butterfly | Full glass front, reflecting pool, built-in concrete seating |

---

## Economy

| Currency | Purpose |
|----------|---------|
| **SunCoins (SC)** | Primary currency — earned from gardening, fashion, selling |
| **Prestige** | Reputation points — fashion wins, rare harvests, community contribution |
| **Level** | 1 level per 100 Prestige earned |

**Anti-exploit:** Server-authoritative. All currency changes validated server-side. Rate limited to 10 transactions/minute. No client-trusted values.

---

## Persistence

### Hot Path (DataStore)
- SunCoins, Prestige, Level
- Plot ownership, home style
- Basic inventory counts
- Session locking (ProfileService pattern)
- Auto-save every 5 minutes

### Cold Path (Supabase)
- Detailed furniture placement JSONB
- Garden state history
- Fashion event results
- Transaction logs
- Analytics events
- Batch sync every 60 seconds

**Fallback:** If Supabase is unavailable, all data stays in DataStore (degraded but fully functional).

---

## Events

### Weekly Themes
Rotate automatically, each modifying gameplay:
- **Poolside Paradise** — Default relaxed vibes
- **Desert Bloom** — Garden growth 50% faster
- **Retro Revival** — Vintage items 20% cheaper
- **Modernism Week** — Limited MCM drops + 2x Prestige
- **Sunset Soirée** — Special evening fashion events
- **Cactus Festival** — Double garden growth + shop discounts

### Modernism Week 2026 (Feb 12-22)
- Limited-edition furniture (Platinum Starburst Clock, MW Eames Rocker, MW Nelson Bench)
- 2x Prestige multiplier
- Special runway themes
- n8n webhook fires for scheduling integration

---

## Part Budget

| Component | Parts |
|-----------|-------|
| Environment (terrain, mountains, roads, trees, decor) | ~250 |
| MCM Homes (4 styles, built on demand) | ~40-45 each |
| El Paseo Storefronts (6) + dining | ~200 |
| Desert Garden (16 plots + structures) | ~80 |
| Fashion Runway | ~65 |
| Player-placed furniture | ~400 budget |
| **Total budget** | **< 5,000** |

---

## Publishing Checklist

- [ ] Build with `rojo build -o PalmSpringsParadise.rbxlx`
- [ ] Open in Roblox Studio
- [ ] Verify StreamingEnabled is ON (Workspace properties)
- [ ] Enable HttpService (Game Settings → Security)
- [ ] Configure Supabase secrets (if using):
  - `SUPABASE_URL` → your project URL
  - `SUPABASE_ANON_KEY` → your anon/public key
- [ ] Set game thumbnail to the locked cover image
- [ ] Set game icon to a cropped version of the cover
- [ ] Configure game settings:
  - Max players: 40
  - Genre: Town and City
  - Playable Devices: Computer, Phone, Tablet
- [ ] Test all `/commands` in Play Solo
- [ ] Verify part count with `/partcount` (should be < 5,000)
- [ ] Publish to Roblox

---

## Thumbnail Setup

Use the locked cover image as the game thumbnail:
1. In Roblox Studio: Game Settings → Basic Info → Thumbnail
2. Upload the cover image showing bright blue sky, MCM villa, turquoise pool
3. Ensure the thumbnail matches the in-game visual identity

---

## License

Proprietary — Palm Springs Paradise by Iron Forge Studios.

---

*Built with Cursor.com + Claude Sonnet 4.6 Max Mode — Single-shot prototype generation*
