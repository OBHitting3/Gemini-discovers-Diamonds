# Karl — Prompt to 3D (No Blender Required)

**You describe a thing. Cursor builds it in code. Rojo puts it in Studio.**

You do **not** need Blender, PowerShell, or Roblox upload tools for **Tier 1** props.

---

## Two ways to get 3D in the game

| Tier | What it is | Karl does | Who builds |
|------|------------|-----------|------------|
| **1 — Prompt 3D** | Shapes built from Parts in Luau (`PropBuilder.lua`) | Describe in **Cursor chat** | **Cursor** (automatic) |
| **2 — Imported mesh** | Real `.fbx` / Studio mesh with `rbxassetid` | Describe + optional file drop for Eddie/Manus | **Manus** uploads → manifest |

**Start with Tier 1.** It works today in Play Solo.

---

## Your session (same as always)

1. Double-click **`Start-PalmSprings.cmd`**
2. Studio → **Rojo → Connect**
3. **Play Solo**

---

## Try 3D right now (chat commands)

| Command | What happens |
|---------|----------------|
| `/listprops` | Lists all prompt-built models |
| `/spawnprop flamingo_lawn` | Spawns a pink flamingo in front of you |
| `/spawnprop eames_lounge` | Spawns MCM lounge chair |
| `/placefurniture eames_lounge` | Places on your plot (after `/claimplot`) |

**Available slugs (today):**  
`eames_lounge`, `starburst_clock`, `pool_lounger`, `flamingo_lawn`, `desert_rose_planter`, `palm_planter`, `martini_table`, `breeze_block_column`

---

## What to type in Cursor chat

Use plain English. Include **what**, **style** (MCM / poolside / desert), and **where** (plot, garden, El Paseo).

**Examples:**

> Add a procedural 3D prop: a turquoise pool umbrella on a white base. Slug `pool_umbrella`. Register it in ProceduralAssetCatalog and PropBuilder. Add `/spawnprop pool_umbrella` support.

> Make `/placefurniture starburst_clock` use the procedural starburst model instead of a flat box.

> Queue Tier 2 for Manus: I have a downloaded `.fbx` lounge chair — write the handoff note for `vendor-imports/_incoming/`.

**Copy-paste starters:** [karl-prompt-menu.md](./karl-prompt-menu.md) (section **3D models**)

---

## What Cursor does automatically

1. Adds a builder function in `src/server/Builders/PropBuilder.lua`
2. Registers the slug in `src/shared/ProceduralAssetCatalog.lua`
3. Commits and pushes (cloud agent)
4. You **Play Solo** again — Rojo syncs the new model

---

## Tier 2 — When you need a real mesh file

If you downloaded a model from the web or made one in Blender:

1. Tell Cursor: *“Write a Manus handoff for [describe item]”*
2. Eddie or Manus puts files in `vendor-imports/_incoming/YYYY-MM-DD_pack-name/`
3. After upload, `asset-index.yaml` gets the `rbxassetid`
4. Cursor links it in `AssetRegistry` — game uses the mesh instead of Parts

See `vendor-imports/_incoming/README.md`.

---

## Rules (MCM look)

All procedural props must follow **`.cursor/rules/roblox-mcm.md`**:

- Bright desert palette (turquoise, terracotta, white, dusty pink)
- Low part count per prop (aim &lt; 20 parts)
- Single-story / furniture scale — not skyscrapers

---

## If the prop does not appear

1. `Start-PalmSprings.cmd` still running?
2. Rojo **Connect** → Stop play → **Play** again
3. `/listprops` — is your slug listed?
4. Paste **Output (Server)** into Cursor chat

---

## Eddie / Manus reference

- Procedural code: `PropBuilder.lua`, `ProceduralAssetCatalog.lua`
- Spawn test: `PropSpawnService.lua`, `/spawnprop`
- Lane rules: [02-agent-lane-discipline.md](./02-agent-lane-discipline.md)
