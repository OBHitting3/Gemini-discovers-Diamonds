# Karl — Copy-Paste Prompt Menu

Open **Cursor** chat, paste one block, send. AI builds it into the game.

**After AI says done:** double-click **`Start-PalmSprings.cmd`** (if not already open) → Studio **Rojo Connect** → **Play Solo**.

---

## Economy & rewards

```
Add a chat command /dailybonus that gives 250 SunCoins once per play session. Show a notification when claimed. Add it to /help.
```

```
Double the starting SunCoins for new players from 100 to 200. Update TestCommands if needed.
```

```
Add a /vip command (test only) that sets prestige to 10 and notifies the player. Document in /help.
```

---

## Garden & plants

```
Add a new plant to ItemCatalog called "Desert Rose" — cheap seed, medium grow time, good harvest coins. Wire it into garden planting if not already generic.
```

```
When it is Morning phase, show an extra notification when a player harvests: "Morning harvest bonus!"
```

---

## Shops & El Paseo

```
Add a test command /stockshop that fills the player's shop with 5 random boutique items if they own a shop. Add to /help.
```

```
Lower all default shop listing prices by 10% in GameConfig (or ItemCatalog) and tell me what you changed.
```

---

## Fashion & events

```
During Evening phase only, send a welcome notification when a player joins: "Evening soirée — head to the runway!"
```

```
Add a chat command /runwayinfo that prints the current fashion event theme and participant count.
```

---

## Homes & plots

```
Add /buildhouse shortcut descriptions to /help for kaufmann, frey, wexler, neutra.
```

```
When a player claims plot 1, send a notification with decorating tips for afternoon phase.
```

---

## UI & feel

```
Add a small toast when the day phase changes (client) using the existing DayPhaseController chip — no new art.
```

```
Make the DayPhase chip slightly larger and use terracotta text color from GameConfig.Colors.
```

---

## Fixes (when Play Solo breaks)

```
I pressed Play and nothing built. Here is my Server Output log:
[PASTE OUTPUT HERE]
Fix the error and explain in one sentence what was wrong.
```

```
/coins does not work in Play Solo. Check TestCommands and server bootstrap. Fix with minimal changes.
```

---

## Big ideas (staging first — needs Karl approval to ship)

```
Stage a new server service in staging/ for a weekly "Modernism Week" boost that doubles shop sales. Do NOT merge to src/ yet — document in staging/README what you added.
```

```
Design a new mini-game idea for pool volleyball in staging/docs only — no Luau yet. One page markdown.
```

---

## 3D models (prompt-built — no Blender)

```
Add a new procedural 3D prop: [DESCRIBE SHAPE AND COLORS]. Use slug [snake_case_name]. Register in ProceduralAssetCatalog and PropBuilder. MCM style. Add to /listprops.
```

```
Make /placefurniture [itemId] use the procedural 3D model from PropBuilder instead of a plain box.
```

```
/spawnprop [slug] did not work. Here is Server Output: [PASTE]. Fix PropBuilder or the slug list.
```

```
I want a real downloaded mesh (FBX), not blocks. Write a Manus handoff in staging/manus-handoffs/ for [DESCRIBE ASSET] — do not ask me to upload.
```

**Try now:** `/listprops` then `/spawnprop flamingo_lawn`

**Guide:** [11-karl-prompt-to-3d.md](./11-karl-prompt-to-3d.md)

---

## Hand off to Manus (assets / database)

```
Do not upload yourself. Write a Manus handoff note: list files needed in vendor-imports/_incoming/ for [DESCRIBE ASSET] and what to put in asset-index.yaml.
```

```
Write the exact steps for Manus to enable live Supabase (not mock) for this project — bullet list only, no code for Karl to run.
```

---

## Meta (ask the AI how things work)

```
Explain in simple language what happens when I press Play Solo — 5 bullets max, no jargon.
```

```
What changed in the game since my last git pull? Summarize for a non-programmer.
```
