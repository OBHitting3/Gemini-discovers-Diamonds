# Incoming assets (Tier 2 — file-based 3D)

**Karl:** You do **not** need to touch this folder for prompt-built 3D (Tier 1). Use Cursor chat + `/spawnprop` instead.

**Eddie / Manus:** Drop unprocessed packs here:

```
vendor-imports/_incoming/YYYY-MM-DD_vendor_pack-name/
  mesh.fbx
  LICENSE.txt
  SOURCE.md
```

After QA and Roblox upload, Manus updates `vendor-imports/_manifests/asset-index.yaml`.

Cursor then maps slugs in `src/shared/AssetRegistry.lua`.

See `docs/karlux/11-karl-prompt-to-3d.md` and `staging/manus-handoffs/README.md`.
