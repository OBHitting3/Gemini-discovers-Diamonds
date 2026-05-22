# Step-by-Step Install — Windows (Cursor)

Do these **in order**. Each step says **which program** to use.

**Time:** ~25–35 minutes first time.

---

## Step 0 — Open the project in Cursor

| What | Program |
|------|---------|
| Open repo | **Cursor** |

1. **Cursor** → **File → Open Folder**
2. Choose your clone folder, e.g.  
   `C:\Users\YOUR_NAME\Documents\PalmSprings`  
   or open **`PalmSpringsParadise.code-workspace`** (double-click in Explorer).

**If you don’t have the repo yet** — **Step 2** (PowerShell from Start menu OR Cursor terminal):

```powershell
irm https://raw.githubusercontent.com/OBHitting3/Gemini-discovers-Diamonds/cursor/pc-transfer-audit-0002/staging/scripts/step2-clone-windows.ps1 | iex
```

That clones to `%USERPROFILE%\Documents\Roblox\PalmSprings` and checks out `cursor/pc-transfer-audit-0002`.

Manual alternative:

```powershell
mkdir -Force "$env:USERPROFILE\Documents\Roblox"
cd "$env:USERPROFILE\Documents\Roblox"
git clone https://github.com/OBHitting3/Gemini-discovers-Diamonds.git PalmSprings
cd PalmSprings
git checkout cursor/pc-transfer-audit-0002
```

Then **File → Open Folder** → that `PalmSprings` folder.

**Verify:** Explorer sidebar shows `src`, `staging`, `default.project.json`.

---

## Step 1 — Git (if missing)

| What | Program |
|------|---------|
| Install Git | **Browser** → https://git-scm.com/download/win |
| Run installer | **Git for Windows** setup wizard (defaults OK) |
| Verify | **Cursor** → terminal (PowerShell) |

```powershell
git --version
```

---

## Step 2 — Rokit (installs Rojo, Wally, StyLua, etc.)

| What | Program |
|------|---------|
| Install Rokit | **Cursor** → terminal (**PowerShell**) |

```powershell
irm https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | iex
```

Close terminal, open **new** Cursor terminal (so PATH refreshes).

**Verify (Cursor → PowerShell):**

```powershell
rokit --version
```

If `rokit` not found, add to PATH manually:

```powershell
$env:Path += ";$env:USERPROFILE\.rokit\bin"
[Environment]::SetEnvironmentVariable("Path", $env:Path + ";$env:USERPROFILE\.rokit\bin", "User")
```

Restart Cursor, then `rokit --version` again.

---

## Step 3 — Pin and install project CLI tools

| What | Program |
|------|---------|
| All commands | **Cursor** → terminal (PowerShell) |

```powershell
cd $env:USERPROFILE\Documents\Roblox\PalmSprings
# ^ change path to wherever you opened the folder

cmd /c "mklink rokit.toml staging\toolchain\rokit.toml"
cmd /c "mklink wally.toml staging\toolchain\wally.toml"
```

If `mklink` fails (no admin), copy instead:

```powershell
Copy-Item staging\toolchain\rokit.toml rokit.toml -Force
Copy-Item staging\toolchain\wally.toml wally.toml -Force
```

```powershell
rokit install
```

Approve any **trust** prompts.

**Verify:**

```powershell
rojo --version
wally --version
stylua --version
selene --version
```

Or:

```powershell
powershell -ExecutionPolicy Bypass -File staging\scripts\toolchain\verify.ps1
```

---

## Step 4 — Wally + workspace files

| What | Program |
|------|---------|
| Commands | **Cursor** → PowerShell |

```powershell
wally install
powershell -ExecutionPolicy Bypass -File staging\scripts\krlx-workspace-bootstrap.ps1
```

**Verify:** `.vscode` folder exists in project root.

---

## Step 5 — Cursor extensions

| What | Program |
|------|---------|
| UI only | **Cursor** (not terminal) |

1. Popup **Install Recommended Extensions** → **Install**
2. Or **Extensions** (Ctrl+Shift+X): Luau LSP, Rojo, StyLua, Selene

**Verify:** Ctrl+Shift+P → **Tasks: Run Task** → **Rojo: Serve** appears.

---

## Step 6 — Start Rojo (leave running)

| What | Program |
|------|---------|
| Start sync | **Cursor** → PowerShell **or** Run Task |

**Option A:** Ctrl+Shift+P → **Tasks: Run Task** → **Rojo: Serve**

**Option B:** Terminal:

```powershell
cd $env:USERPROFILE\Documents\Roblox\PalmSprings
$env:Path += ";$env:USERPROFILE\.rokit\bin"
rojo serve
```

Leave this running.

---

## Step 7 — Roblox Studio

| What | Program |
|------|---------|
| Game + connect | **Roblox Studio** (Windows app) |

1. Open **Roblox Studio** from Start menu.
2. Open a baseplate or place.
3. **Plugins** → **Rojo** → **Connect** (`localhost:34872`).
4. **Home** → **Game Settings** → **Security** → **Allow HTTP Requests** ✓

**Verify:** Explorer shows synced `ServerScriptService` / `ReplicatedStorage`.

---

## Step 8 — Play test

| What | Program |
|------|---------|
| Play + chat | **Roblox Studio** |

**Play Solo** → **View → Output** → look for server start message.

In game chat:

```
/coins 5000
/claimplot 1
/status
```

---

## Step 9 — Optional (later)

| Tool | Program |
|------|---------|
| **Supabase CLI** | **PowerShell:** `winget install Supabase.CLI` or **Browser** install docs |
| **Blender** | **Browser** → blender.org → Windows installer |
| **.env` secrets** | **Cursor** editor — copy `staging\env\.env.example` → `.env` (never commit) |

---

## Troubleshooting (Windows)

| Problem | Fix |
|---------|-----|
| Scripts blocked | `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` in PowerShell |
| Rokit “not trusted” | Approve prompts, or run: `rokit trust JohnnyMorganz/StyLua rojo-rbx/rojo UpliftGames/wally seaofvoices/darklua rojo-rbx/remodel Kampfkarren/selene` then `rokit install` |
| `rojo` not found | Add `%USERPROFILE%\.rokit\bin` to User PATH, restart Cursor |
| Rojo won’t connect | Allow firewall for `rojo`; confirm `rojo serve` running |
| `mklink` failed | Use `Copy-Item` for rokit.toml / wally.toml (Step 3) |

---

## Program cheat sheet

| Step | Commands in | UI in |
|------|-------------|--------|
| 0, 1–4, 6, 9 CLI | **Cursor → Terminal (PowerShell)** | — |
| 5 | — | **Cursor** |
| 7–8 | — | **Roblox Studio** |
| Git install | **Browser** + installer | — |

**Next:** [05-unified-dev-stack.md](./05-unified-dev-stack.md)
