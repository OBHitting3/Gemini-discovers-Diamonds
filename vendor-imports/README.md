# Vendor Imports — Raw Asset Drop Zone

**Do not commit large binaries without Git LFS.** This folder implements the taxonomy in `docs/karlux/01-asset-taxonomy-tree.md`.

## Quick start (KRLX)

1. Create subfolders per taxonomy doc (or run Manus ingest script).
2. Drop downloads into `_incoming/YYYY-MM-DD_<vendor>_<pack>/`.
3. After QA, Manus moves files into category folders and updates `_manifests/asset-index.yaml`.

## PC Transfer Kit (KRLX drive D:)

Default source path from Explorer:

`D:\PC_Transfer_Kit\PalmSpringsParadise\Users\karl\palm-springs-paradise`

```powershell
powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1
powershell -ExecutionPolicy Bypass -File staging\scripts\audit-pc-transfer-kit.ps1 -Apply
```

See `docs/karlux/08-pc-transfer-kit-audit.md`.

## Current status

Taxonomy folders scaffolded. Run audit on Windows to populate `_manifests/pc-transfer-audit.json` and optionally `-Apply` copies from Transfer (D:).
