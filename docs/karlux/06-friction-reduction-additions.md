# Friction-Reduction Additions

Tools you did **not** list explicitly but that remove daily pain when paired with Cursor, VS Code, Studio, Blender, and Supabase.

---

## Added to the staged toolchain (recommended)

| Addition | Problem it solves | Staged location |
|----------|-------------------|-----------------|
| **Selene** | Catches Luau bugs before Play Solo | `staging/toolchain/selene.toml`, Rokit pin |
| **Luau Language Server** | Autocomplete, go-to-def, types in Cursor/VS Code | `.vscode/extensions.json` |
| **Rojo VS Code extension** | Connect/disconnect without Studio menu diving | `.vscode/extensions.json` |
| **Shared `.vscode/` tasks** | One-key `rojo serve`, format, lint | `staging/editor/.vscode/tasks.json` |
| **Git pre-commit hook** | Blocks messy commits (stylua + selene) | `staging/scripts/git/pre-commit` |
| **Git LFS** | Large FBX/PNG in `vendor-imports` without bloating git | `staging/toolchain/gitattributes.snippet` |
| **Supabase CLI + migrations** | Schema drift between Manus DB and game | `staging/supabase/` |
| **`.env.example`** | One place for keys (never commit real `.env`) | `staging/env/.env.example` |
| **GitHub Actions PR check** | CI runs same checks as KRLX | `staging/ci/pr-checks.yml` |
| **Blender export playbook** | Wrong scale = broken imports | `staging/blender/README.md` |
| **Lefthook** (optional) | Cross-platform git hooks vs bash-only | `staging/toolchain/lefthook.yml` |

---

## Consider next (not staged — your call)

| Tool | When it helps | Why not default |
|------|---------------|-----------------|
| **Mantle** | One-command Roblox publish from CI | Needs universe credentials; overlap with Remodel |
| **Moonwave** | Auto API docs for `src/shared` | Nice for scale; not needed for prototype |
| **TestEZ** (Wally) | Unit tests for economy math | Add when stabilizing anti-exploit rules |
| **Open Cloud Assets API** | Bulk mesh upload without Studio | Manus can use instead of Tarmac; pick one primary |
| **Argon** | Alternative sync tool | You already standardized on Rojo — skip |
| **Rotriever** | Older package manager | Superseded by Wally |

---

## Friction you avoid by **not** adding

- **Second sync tool** (Argon + Rojo) — pick Rojo only ✓  
- **Studio cloud as git** — GitHub is truth ✓  
- **Client-trusted economy** — server authority already ✓  
- **service_role key in Roblox** — use anon + tight RLS or server-only RPC ✓  

---

## IDE-specific tips

### Cursor

- Keep `.cursor/rules/roblox-mcm.md` **alwaysApply** for art direction
- Use cloud agent for PRs; local Cursor for `rojo serve` + Studio on KRLX
- Supabase MCP in Cursor for schema work (Manus lane for apply)

### VS Code

- Open same folder; install recommended extensions popup
- Use **Tasks: Run Task → Rojo: Serve** instead of memorizing CLI

### Studio + Blender

- **Single import path:** Blender → `vendor-imports` → Tarmac (not both Tarmac and manual Studio upload for same file)
- Name files with taxonomy slug **before** upload (`furniture__eames_lounge__default.fbx`)

### Supabase

- Run `supabase db advisors` before merging migrations
- Enable RLS on every public table (see Supabase skill security checklist)

---

## Verification

```bash
bash staging/scripts/toolchain/verify.sh      # CLI tools
bash staging/scripts/git/pre-commit          # dry run locally
```

After promoting `.vscode/`, reload window and confirm Luau LSP + Rojo appear in status bar.
