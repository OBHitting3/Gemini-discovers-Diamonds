# Asset Taxonomy — Palm Springs Paradise

**Status:** PROPOSED — do not move files until Karl/Eddie approve this tree.  
**Scope:** All downloaded Roblox assets (meshes, textures, audio, animations, UI, legacy scripts) plus KarLux-generated manifests.

---

## Design principles

1. **Source vs runtime** — Raw downloads live under `vendor-imports/`; only vetted assets get `rbxassetid` entries in `AssetRegistry` (staged) and Studio `ReplicatedStorage/Assets`.
2. **ID-stable paths** — Folder names use `kebab-case` slugs that match `ItemCatalog` / `AssetRegistry` keys (e.g. `eames_lounge`, not `Chair (1)`).
3. **License lane** — Every pack has `LICENSE.txt` or `SOURCE.md` at pack root before promotion.
4. **No orphan binaries** — Every mesh/sound/texture has a sidecar `.meta.json` (Roblox or KarLux schema) describing intended use, part budget, and CollectionService tags.
5. **Rojo boundary** — Luau stays in `src/`; binary/media stays out of Rojo sync until imported to Roblox (or use Rojo `assets/` with explicit paths in `default.project.json` after approval).

---

## Directory tree (canonical)

```
PalmSprings/                          # repo root (Rojo project)
├── default.project.json
├── src/                              # PRODUCTION Luau (Rojo → DataModel scripts)
├── docs/karlux/                      # Architecture & merge guides (this folder)
├── staging/                          # STAGING Luau + manifests (10-80-10 gate)
│
└── vendor-imports/                   # LOCAL + GIT (LFS) — raw downloaded assets
    ├── _incoming/                    # Drop zone — unprocessed downloads ONLY
    │   └── YYYY-MM-DD_<vendor>_<pack>/ 
    │
    ├── _manifests/                   # Machine + human readable indexes
    │   ├── asset-index.yaml          # Master slug → rbxassetid map (generated)
    │   ├── import-log.jsonl          # Who imported what, when, from where
    │   └── rejection/                # Quarantined assets (license, poly count, style)
    │
    ├── architecture/                 # Buildings, shells, plot shells
    │   ├── residential/
    │   │   ├── kaufmann/
    │   │   ├── frey/
    │   │   ├── wexler/
    │   │   └── neutra/
    │   ├── commercial/
    │   │   └── el-paseo-storefront/
    │   └── community/
    │       ├── desert-garden/
    │       └── fashion-runway/
    │
    ├── furniture/                    # ItemCatalog.Furniture slugs
    │   ├── seating/
    │   ├── tables/
    │   ├── lighting/
    │   ├── decor/
    │   └── outdoor/
    │
    ├── plants/                       # ItemCatalog.Plants
    │   ├── cacti/
    │   ├── succulents/
    │   └── palms/
    │
    ├── fashion/                      # ItemCatalog.Fashion / accessories
    │   ├── tops/
    │   ├── bottoms/
    │   ├── accessories/
    │   └── runway-props/
    │
    ├── boutique/                     # ItemCatalog.Boutique goods
    │   ├── apparel/
    │   ├── home-goods/
    │   └── consumables/
    │
    ├── environment/                # World dressing (non-interactive)
    │   ├── terrain-decals/
    │   ├── vegetation/
    │   ├── props/
    │   └── signage/
    │
    ├── materials/                    # PBR / SurfaceAppearance sources
    │   ├── concrete/
    │   ├── glass/
    │   ├── fabric/
    │   └── desert/
    │
    ├── textures/                     # Image maps (if not embedded in meshes)
    │   ├── ui/
    │   └── world/
    │
    ├── audio/                        # Sounds & music
    │   ├── ambience/
    │   ├── ui/
    │   ├── garden/
    │   ├── fashion/
    │   └── economy/
    │
    ├── animations/                   # R15 / custom rig
    │   ├── emotes/
    │   ├── runway/
    │   └── garden/
    │
    ├── ui/                           # Image labels, icons, fonts
    │   ├── hud/
    │   ├── panels/
    │   └── thumbnails/
    │
    └── legacy-scripts/               # Purchased Lua — REFERENCE ONLY
        └── do-not-ship/              # Never auto-merge; rewrite in src/
```

---

## Roblox Studio mirror (runtime)

After upload to Roblox, mirror logically under **ReplicatedStorage**:

```
ReplicatedStorage/
├── GameConfig          # existing
├── ItemCatalog         # existing
├── AssetRegistry       # NEW after merge — slug → Instance template / id
└── Assets/             # optional folder instances (post-approval)
    ├── Furniture/
    ├── Plants/
    ├── Fashion/
    ├── Audio/
    └── VFX/
```

CollectionService tags (required on spawned instances):

| Tag | Use |
|-----|-----|
| `PSP_Furniture` | Placeable home decor |
| `PSP_Plant` | Garden entities |
| `PSP_ShopGood` | El Paseo inventory |
| `PSP_FashionItem` | Runway / outfit |
| `PSP_Environment` | Static world (no interact) |
| `PSP_ImportedMesh` | Traceability for part audits |

---

## File naming convention

```
<category>__<slug>__<variant>.<ext>
```

Examples:

- `furniture__eames_lounge__default.fbx`
- `audio__garden_water__loop.mp3`
- `furniture__eames_lounge__default.meta.json`

---

## Promotion workflow (10-80-10)

| Step | Owner | Action |
|------|-------|--------|
| 1 | Karl/Eddie | Drop pack into `vendor-imports/_incoming/` |
| 2 | Manus | Validate license, poly count, MCM palette compliance |
| 3 | Manus | Upload to Roblox, record `rbxassetid` in `_manifests/asset-index.yaml` |
| 4 | Cursor | Add slug entry to `staging/.../AssetRegistry.lua` |
| 5 | Karl/Eddie | Approve merge → `src/shared/AssetRegistry.lua` + optional Rojo asset paths |

---

## Mapping to existing code

| Taxonomy folder | Code consumer |
|-----------------|---------------|
| `furniture/*` | `ItemCatalog.Furniture`, `PlotService`, `HomeBuilder` |
| `plants/*` | `ItemCatalog.Plants`, `GardenService`, `GardenBuilder` |
| `boutique/*` | `ItemCatalog.Boutique`, `ShopService` |
| `fashion/*` | `ItemCatalog.Fashion`, `FashionService` |
| `audio/*` | `SoundController` (replace placeholder rbxassetids) |
| `architecture/*` | `*Builder.lua` modules (reduce procedural Part count) |
