# Blender → Roblox Studio Pipeline

**Tools:** Blender (author) · `vendor-imports/` (storage) · Tarmac or Studio (upload) · Cursor (registry)

---

## Export settings (FBX — recommended)

| Setting | Value | Why |
|---------|-------|-----|
| Scale | Apply transforms; **1 Blender unit = 1 stud** (or 0.01 if using cm workflow — pick one doc-wide) | Prevents giant/tiny meshes in Studio |
| Forward | **-Z Forward** | Roblox-compatible |
| Up | **Y Up** | Matches Studio import |
| Apply Modifiers | On | Consistent mesh |
| Triangulate | Only if needed | Roblox accepts tris |

**KarLux default for this project:** model at real-world cm, export with scale **0.01** so 100cm → 1 stud, OR model directly in studs (1:1). Document your choice on the pack's `SOURCE.md`.

---

## Per-asset checklist

- [ ] File name: `furniture__<slug>__default.fbx` (see asset taxonomy)
- [ ] Tris under budget (furniture ~8–50, architecture shells higher but audited)
- [ ] Materials: prefer Studio **MeshPart** materials or SurfaceAppearance after import
- [ ] MCM palette check against `.cursor/rules/roblox-mcm.md`
- [ ] No two-story geometry for residential homes
- [ ] Drop into `vendor-imports/<category>/...`
- [ ] Manus runs `tarmac sync` OR Studio Asset Manager import
- [ ] Record rbxassetid in `vendor-imports/_manifests/asset-index.yaml`

---

## Blender addons (optional, not required)

| Addon | Use |
|-------|-----|
| **LoopTools** | Clean topology for low-poly MCM |
| **TexTools** | UV for decals |
| **Roblox Blender Plugin** (community) | Preview rig scale — optional |

We do **not** commit `.blend` files to git by default — use **Git LFS** if you must version blends.

---

## Studio import (when not using Tarmac)

1. `rojo serve` connected
2. Home → **Import 3D** → select FBX from `vendor-imports/`
3. Convert to MeshPart, set CollisionFidelity as needed
4. Move to `ReplicatedStorage/Assets/...` in Studio
5. Copy rbxassetid into manifest for Cursor

---

## CollectionService tags (after in-game)

`PSP_Furniture`, `PSP_Plant`, `PSP_ImportedMesh` — applied by `AssetRegistry:applyCollectionTags` after merge.
