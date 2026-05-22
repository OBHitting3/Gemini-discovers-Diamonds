# Staging Area — KarLux 10-80-10 Gate

**Nothing in this folder is loaded by Rojo** until principals merge into `src/`.

## Contents

```
staging/
├── README.md
├── toolchain/            # Rokit, Wally, StyLua, Selene, Darklua, Tarmac, Remodel
├── editor/               # .vscode + .cursor rules → promote to repo root
├── supabase/             # migrations + config (Manus)
├── blender/              # Blender → Roblox export playbook
├── env/                  # .env.example
├── ci/                   # GitHub Actions PR checks
├── scripts/toolchain/    # verify.sh, build-release.sh
├── scripts/krlx-workspace-bootstrap.sh
├── patches/              # Copy-paste snippets for init.*.lua
└── src/
    ├── shared/
    │   ├── AssetRegistry.lua
    │   └── DayPhaseConfig.lua
    ├── server/Services/
    │   └── CoreLoopService.lua
    └── client/Controllers/
        └── DayPhaseController.lua
```

## Reviewers

- **Karl / Eddie:** approve merge via `docs/karlux/03-vertical-slice-merge-guide.md`
- **Manus:** populate `AssetRegistry` from `vendor-imports/_manifests/asset-index.yaml` before production AssetRegistry merge
