# Staged Toolchain Configs

Promote these files to **repo root** after Karl/Eddie approval (see `docs/karlux/04-roblox-toolchain.md`).

| File | Tool |
|------|------|
| `rokit.toml` | Rokit (preferred pin manager) |
| `aftman.toml` | Aftman (fallback; matches `setup.command`) |
| `wally.toml` | Wally package manifest |
| `stylua.toml` | StyLua formatter |
| `darklua.json` | Release transforms |
| `darklua.dev.json` | Dev (no transforms) |
| `tarmac.toml` | Asset upload + codegen |
| `default.project.snippet.json` | Wally + Rojo merge |
| `remodel/*.lua` | Headless place scripts |
| `generated/GeneratedAssets.lua` | Tarmac output template |

**Scripts:** `staging/scripts/toolchain/verify.sh`, `build-release.sh`
