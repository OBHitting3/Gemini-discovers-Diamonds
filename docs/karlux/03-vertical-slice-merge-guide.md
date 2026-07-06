# Vertical Slice Merge Guide — Day Phase Core Loop

**Slice:** Tie README game loop (Morning → Afternoon → Evening) to server authority + client HUD prompts.  
**Staged modules:** `staging/src/shared/{DayPhaseConfig,AssetRegistry}.lua`, `CoreLoopService`, `DayPhaseController`.

---

## What this slice adds

The production codebase already has **Plot**, **Garden**, **Fashion**, **Shop**, and **Event** services. It does **not** yet orchestrate the **player-facing day rhythm**:

| Phase | Real-world cue | Gameplay emphasis |
|-------|----------------|-------------------|
| **Morning** | 6:00–11:00 server-local | Garden growth tick boost, shop restock reminders |
| **Afternoon** | 11:00–17:00 | Home decorate / furniture, outfit prep |
| **Evening** | 17:00–22:00 | Fashion events eligible, night toggle allowed |

`CoreLoopService` publishes phase changes; `DayPhaseController` updates HUD hints and gates night mode.

---

## Merge checklist (Eddie / Karl)

- [ ] Review staged Luau for style match with existing services
- [ ] Copy `staging/src/shared/DayPhaseConfig.lua` → `src/shared/DayPhaseConfig.lua`
- [ ] Copy `staging/src/shared/AssetRegistry.lua` → `src/shared/AssetRegistry.lua` (after Manus manifest)
- [ ] Copy `staging/src/server/Services/CoreLoopService.lua` → `src/server/Services/CoreLoopService.lua`
- [ ] Copy `staging/src/client/Controllers/DayPhaseController.lua` → `src/client/Controllers/DayPhaseController.lua`
- [ ] Apply patches in `staging/patches/` to `init.server.lua` and `init.client.lua`
- [ ] Add remote `DayPhaseUpdate` to `GameConfig.Remotes.Events` (patch included)
- [ ] `rojo build` + Play Solo — verify Output for phase transitions
- [ ] Delete or archive `staging/` duplicates after successful Studio test

---

## init.server.lua additions

See [`staging/patches/init.server.snippet.lua`](../../staging/patches/init.server.snippet.lua).

Insert **after** `EventService:init` and **before** `LeaderboardService`.

---

## init.client.lua additions

See [`staging/patches/init.client.snippet.lua`](../../staging/patches/init.client.snippet.lua).

Insert **after** `NightToggleController:init` and wire `DayPhaseController`.

---

## Asset hookup

`AssetRegistry` documents where imported meshes/sounds attach. Until Manus delivers `asset-index.yaml`, placeholders use procedural builders (current behavior).

Example after merge:

```lua
-- In PlotService when placing furniture:
local template = AssetRegistry:getTemplate("eames_lounge")
if template then
    -- clone from ReplicatedStorage.Assets.Furniture
else
    -- fallback: procedural Part from HomeBuilder
end
```

---

## Test in Play Solo

1. `/status` — confirm services running  
2. Watch server log for `[CoreLoopService] Phase → Morning|Afternoon|Evening`  
3. HUD should show phase label + suggested action  
4. `/fashion` during **Evening** — should work; during Morning may show notify (configurable)  
5. `N` night key only honored when `DayPhaseController:isNightAllowed()`
