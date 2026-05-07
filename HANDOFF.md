# Palm Springs Paradise — Project Handoff

A complete, accurate technical brief of the Roblox project as it stands. Drop this in your Claude Code session, AI tools will index it, you'll have the same context the original session has.

> **Repo:** `OBHitting3/Gemini-discovers-Diamonds`
> **In-code project name:** Palm Springs Paradise (PSP)
> **Author / studio:** Iron Forge Studios
> **Format:** Rojo v7, Luau (Roblox's Lua variant)

---

## What the game is

A social life-simulation set in stylized mid-century-modern Palm Springs. Players:

- Claim 1 of 4 residential plots and build a single-story MCM home
- Decorate with mid-century furniture, earn a "Vibes Score"
- Tend a shared 16-plot desert garden (plant / water / harvest)
- Run a boutique on El Paseo boulevard (stock / buy / sell, 10% sink)
- Enter poolside fashion runway events (every 10 min, 2 min duration, 5 max)
- Compete on cross-server leaderboards (SunCoins, Prestige, Vibes)
- Participate in weekly auto-rotating themes + the real-world Modernism Week tie-in

Currency: **SunCoins (SC)** + **Prestige** + **Level** (1 per 100 prestige).

---

## Current state

- ~11,000 lines of Luau across 35 source files. Reads cleanly, structured.
- **Not yet published to Roblox.** Game Pass and DevProduct IDs in `GameConfig.lua` are all `0` placeholders.
- DataStore persistence is real. Supabase code is real but in **mock mode** (no creds).
- n8n webhooks are **placeholder** endpoints, not active.
- No automated Roblox-side tests; manual testing via in-chat commands.

---

## Architecture (Rojo v7 — server / client / shared split)

```
src/
├── server/             → ServerScriptService (server-only)
│   ├── init.server.lua             bootstrap, wires services together
│   ├── Services/                   business logic, server-authoritative
│   ├── Builders/                   world/environment construction
│   └── Commands/                   chat-based test commands
├── client/             → StarterPlayerScripts (client-only)
│   ├── init.client.lua             bootstrap
│   ├── Controllers/                input + UI control
│   └── UI/                         ScreenGui templates
├── shared/             → ReplicatedStorage (server + client both require)
│   ├── GameConfig.lua              ALL config + IDs in one place
│   ├── Types.lua                   Luau type definitions
│   ├── ItemCatalog.lua             ~20 furniture, plants, boutique goods, fashion
│   ├── RemoteManager.lua           RemoteEvent/Function registry
│   ├── ProfileServiceWrapper.lua   DataStore wrapper, session-locked
│   ├── SupabaseClient.lua          Supabase REST client (mock mode)
│   ├── WebhookClient.lua           n8n webhook placeholders
│   └── Utilities.lua               shared helpers
└── gui/                → StarterGui
    └── MainHUD.lua                 ScreenGui entry point
```

---

## Server services

| Service | Role | Status |
|---|---|---|
| `EconomyService` | SunCoins / Prestige / Level. ALL currency mutations gated here. Server-validated. `MarketplaceService.ProcessReceipt` handler ready for DevProduct rewards. | Wired. DevProduct IDs are 0 placeholders. |
| `PlotService` | 4 residential plots, claim/build flow, furniture placement | Wired |
| `GardenService` | Shared 16-plot garden. Plant/water/harvest. 5-second growth ticks. Per-player water cooldown. | Wired (rate-limited) |
| `ShopService` | 6 El Paseo storefronts, stock/buy/sell, 10% tax sink | Wired |
| `FashionService` | Auto-cycling runway events: 10-min interval, 2-min duration, 5 max participants, voting, prizes | Wired |
| `EventService` | Weekly auto-rotating themes + Modernism Week tie-in. Fires n8n webhooks on event start/end. | Wired. Webhooks are placeholders. |
| `LeaderboardService` | OrderedDataStore-backed cross-server boards: SunCoins, Prestige, Vibes. 30-second cache. | Wired |
| `GamePassService` | VIP / DoubleCoins / AutoWater pass logic. Auto-water loop runs every 90s for AutoWater holders. | Wired. Pass IDs are 0 placeholders. |
| `PersistenceService` | Coordinates DataStore (hot) + Supabase (cold). 5-min auto-save, 60-s Supabase sync. | Wired. Supabase in mock mode. |

---

## Key constants (`GameConfig.lua`)

**Economy**
- Starting coins: 100; starting prestige: 0
- Plot prices: 500 / 750 / 1000 / 1500 SC
- Storefront rentals: 300 / 300 / 400 / 400 / 500 / 500 SC
- Shop tax sink: 10%
- Fashion prizes: 1st = 200 SC + 50 prestige, 2nd = 100 + 25, 3rd = 50 + 10
- Anti-exploit: 10 transactions/min, max 10,000 coin grant

**Timing**
- Garden: seed→sprout 60 s, sprout→growing 120 s, growing→mature 120 s, no-water→wilt 120 s, wilt→dead 30 s, water cooldown 30 s
- Fashion: 600 s interval, 120 s duration, max 5 participants
- Persistence: 300 s auto-save, 60 s Supabase sync
- Events: 60 s rotation check

**World**
- Terrain size: 400 × 4 × 400 studs
- Plot size: 60 × 60 studs, 4 plots in a grid
- El Paseo runs along Z axis (Z = -120 to +120), road width 12 studs, 6-stud sidewalks per side
- Storefronts: 3 per side of the boulevard
- Geographic latitude: 33.83 (real Palm Springs)

---

## Visual identity (LOCKED — see `.cursor/rules/roblox-mcm.md`)

These rules are enforced cursor-rule-level and must not be violated:

- **Sky:** gradient `#87CEEB → #E0F0FF` with white clouds
- **Lighting:** `ClockTime = 12`, `Brightness = 2`, `Technology = Future` (best mobile)
- **Atmosphere:** color `(135, 206, 235)`, density 0.3
- **Homes:** SINGLE-STORY ONLY, max 12 studs tall, flat or butterfly roof only
- **Every home includes:** turquoise kidney pool, concrete patio, floor-to-ceiling glass, breeze-block screens
- **Accent palette only:** Terracotta `(204,119,34)`, Turquoise `(64,224,208)`, Dusty Pink `(213,166,189)`, Cactus Green `(90,143,82)`
- **NO** orange skies / sunset / golden hour (except surface warmth on buildings + pool water)
- **Night mode:** event-only, auto-reverts
- **Aesthetic:** stylized low-poly, desert sand terrain, palm-lined El Paseo, distant purple-grey San Jacinto / San Gorgonio mountains

---

## 4 home styles (built on demand)

| Style | Architect | Roof | Distinguishing features |
|---|---|---|---|
| The Kaufmann | Richard Neutra | Flat | L-shaped, turquoise kidney pool, breeze-block screen |
| The Frey | Albert Frey | Butterfly | Carport, glass on 3 sides, garden integration |
| The Wexler | Donald Wexler | Flat | Central courtyard, dusty-pink accent wall, 2× breeze screens |
| The Neutra | Richard Neutra | Butterfly | Full glass front, reflecting pool, built-in concrete seating |

---

## Monetization (wired, inactive until publish)

**Game Passes** — `GameConfig.Economy.GamePasses`
- `VIP` — gold name, priority event queue
- `DoubleCoins` — 2× SunCoins on all earnings
- `AutoWater` — auto-water player's plants every 90 s

**Dev Products** — `GameConfig.Economy.DevProducts`
- `SUNCOINS_500` — 500 SC
- `SUNCOINS_1200` — 1,200 SC
- `SUNCOINS_3000` — 3,000 SC

All 6 IDs are currently `0`. After publishing the experience and creating the passes/products in the Roblox creator dashboard, replace the `0`s with the real IDs. The `MarketplaceService.ProcessReceipt` handler (in `EconomyService.lua:44`) will then grant rewards correctly.

---

## Persistence model

- **Hot path** — Roblox DataStore via ProfileService-style wrapper (`ProfileServiceWrapper.lua`). Stores: SunCoins, Prestige, Level, plot ownership, home style, basic inventory. Session-locked. Auto-save every 5 min.
- **Cold path** — Supabase REST via HttpService (`SupabaseClient.lua`). Stores: detailed furniture placement JSON, garden state history, fashion event results, transaction logs, analytics. Batch sync every 60 s.
- **Fallback** — if Supabase is unavailable or unconfigured, DataStore alone keeps the game fully functional (degraded but fully playable).
- **HttpService MUST be enabled** for Supabase or n8n webhooks to work (Game Settings → Security → Allow HTTP Requests).

---

## Test commands (chat, during Play Solo)

```
/help                         show all commands
/claimplot [1-4]              claim a residential plot
/buildhouse [style]           kaufmann | frey | wexler | neutra
/placefurniture [itemId]      place at look position
/claimshop [1-6]              claim El Paseo storefront
/stock [itemId] [qty] [price] stock your shop
/buy [shopId] [itemId]        buy from a player shop
/plant [plantId] [plotIndex]  plant in garden
/water [plotIndex]            water a garden plot
/harvest [plotIndex]          harvest mature plant
/fashion                      start a fashion event immediately
/joinrunway                   join active fashion event
/vote [playerName]            vote in fashion event
/night                        toggle night mode
/coins [amount]               give yourself SC (test)
/prestige [amount]            give yourself prestige (test)
/event [theme]                trigger a theme
/partcount                    show total part count (target < 5,000)
/inventory                    show your inventory
/save                         force save
/status                       show all system statuses
```

---

## Build / run

```bash
rojo build -o PalmSpringsParadise.rbxlx
# Then open the .rbxlx file in Roblox Studio.
# Or for live sync:
rojo serve
# + connect via the Rojo plugin in Studio.
```

macOS convenience scripts present: `setup.command`, `update.command`, `build.command`. On Windows, use `rojo` directly.

---

## Publish checklist (in order)

1. `rojo build -o PalmSpringsParadise.rbxlx`
2. Open in Roblox Studio.
3. File → Publish to Roblox → name: **Palm Springs Paradise**. Start as **Private**.
4. Game Settings:
   - Genre: Town and City
   - Devices: Computer, Phone, Tablet
   - Max players: 40
   - Security → enable **Allow HTTP Requests**
5. In the Roblox creator dashboard, create:
   - 3 Game Passes (VIP, Double Coins, Auto-Water)
   - 3 DevProducts (500 / 1,200 / 3,000 SunCoins)
6. Copy the 6 real IDs into `GameConfig.Economy.GamePasses` and `GameConfig.Economy.DevProducts`. Also update the rewards table in `EconomyService.lua:50-54` so the receipt handler matches the real DevProduct IDs.
7. (Optional) Wire real Supabase URL + anon key into `SupabaseClient.lua`.
8. (Optional) Wire real n8n webhook URL into `WebhookClient.lua`.
9. Upload thumbnail / icon (locked cover image: bright blue sky, MCM villa, turquoise pool).
10. Open Studio → Play Solo. Run `/status` and `/partcount` (should be < 5,000).
11. Switch from Private to Public when ready, or share private invites with collaborators + 2-3 friends to playtest first.

---

## Known incomplete / dev-needed

- 6 monetization IDs at `0` — populate after publish.
- Supabase + n8n are mocked. Game runs fine without them; flip to real when ready.
- "Modernism Week 2026" dates referenced as Feb 12-22 in code/README — verify against `modernismweek.com` before any dated marketing.
- No automated Roblox-side tests, only `/` chat commands.
- Repo name (`Gemini-discovers-Diamonds`) does not match the in-code project name (`Palm Springs Paradise`). Consider renaming the repo or the project so they align.

---

## Companion code in the repo (NOT part of PSP)

- `content-shield/` — separate Python project (AI content validation framework). Not used by PSP. Should probably move to its own repo.
- `server.js`, `package.json`, `package-lock.json`, `test-report.md` — unrelated hello-world experiment with intentionally-preserved bugs. Safe to delete.
- `AUTOMATED_TYCOON_CAPABILITIES.md` — capabilities essay, not part of the build.

---

## File-level entry points (start reading here)

- `default.project.json` — Rojo v7 project config
- `src/server/init.server.lua` — server bootstrap, wires services
- `src/client/init.client.lua` — client bootstrap, wires controllers
- `src/shared/GameConfig.lua` — all constants in one place
- `.cursor/rules/roblox-mcm.md` — locked visual identity rules

---

## Glossary (so the original developer doesn't get lost)

- **Rojo** — tool that turns the `src/` folder into a `.rbxlx` file Roblox Studio opens
- **Luau** — Roblox's flavor of Lua
- **DataStore** — Roblox's built-in cross-server save system
- **OrderedDataStore** — DataStore variant that supports sorted leaderboards
- **HttpService** — Roblox API for outbound HTTP calls (needed for Supabase + n8n)
- **MarketplaceService** — Roblox API for Game Passes, DevProducts, premium
- **RemoteEvent / RemoteFunction** — how server and client talk to each other
- **ScreenGui** — UI container shown to a single player
- **ProfileService pattern** — community-standard DataStore wrapper that prevents data corruption from session conflicts
- **n8n** — open-source workflow automation tool (think Zapier, but self-hostable)
- **Supabase** — open-source Firebase alternative (Postgres + REST API + auth)
