# PC Transfer Kit — Audit & Ingest

**Source (KRLX screenshot):** Explorer path on drive **Transfer (D:)**:

```
D:\PC_Transfer_Kit\PalmSpringsParadise\Users\karl\palm-springs-paradise
```

Map that folder into this repo under `vendor-imports/` using the audit scripts (10-80-10: Karl/Eddie approve before `AssetRegistry` merge).

---

## Quick run (Windows / Cursor)

From repo root (PowerShell):

```powershell
# 1) Audit only — writes reports, does not copy files
powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1

# 2) Custom path if your D: layout differs
powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1 `
  -SourcePath "D:\PC_Transfer_Kit\PalmSpringsParadise\Users\karl\palm-springs-paradise"

# 3) Copy vetted files into vendor-imports taxonomy
powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1 -Apply
```

**Outputs:**

| File | Purpose |
|------|---------|
| `vendor-imports/_manifests/pc-transfer-audit.json` | Machine-readable inventory |
| `vendor-imports/_manifests/pc-transfer-audit.md` | Human summary |
| `vendor-imports/_manifests/import-log.jsonl` | Append-only audit history |

---

## What the audit does

1. Recursively scans the Transfer Kit folder on **D:** (or `-SourcePath`).
2. Classifies each file by extension + path keywords into [01-asset-taxonomy-tree.md](./01-asset-taxonomy-tree.md) folders.
3. Flags **legacy `.lua`** → `legacy-scripts/do-not-ship` (reference only, never ship).
4. Flags files **>50MB** and common junk (`node_modules`, `.git`, `Thumbs.db`).
5. Suggests **slugs** aligned with `AssetRegistry` / `ItemCatalog`.
6. With **`-Apply`**, copies into `vendor-imports/` using naming: `<category>__<slug>__<filename>`.

---

## After audit

| Step | Owner | Action |
|------|-------|--------|
| 1 | Karl/Eddie | Review `pc-transfer-audit.md` warnings |
| 2 | Manus | Upload meshes/audio → Roblox; fill `asset-index.yaml` |
| 3 | Cursor | Mirror slugs in `staging/src/shared/AssetRegistry.lua` |
| 4 | Karl/Eddie | Approve merge per [03-vertical-slice-merge-guide.md](./03-vertical-slice-merge-guide.md) |

---

## macOS / KRLX mount

```bash
export SOURCE="/Volumes/Transfer/PC_Transfer_Kit/PalmSpringsParadise/Users/karl/palm-springs-paradise"
bash staging/scripts/audit-pc-transfer-kit.sh
bash staging/scripts/audit-pc-transfer-kit.sh --apply
```

---

## Cursor task

**Tasks: Run Task** → **Audit: PC Transfer Kit**

---

## Related

- Taxonomy: [01-asset-taxonomy-tree.md](./01-asset-taxonomy-tree.md)
- Place part audit (Remodel): `staging/toolchain/remodel/extract-place.lua`
- In-game part count: Studio chat `/partcount`
