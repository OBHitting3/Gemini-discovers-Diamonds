#!/usr/bin/env bash
# Palm Springs Paradise — PC Transfer Kit audit (macOS / KRLX / Linux)
# Usage:
#   bash staging/scripts/audit-pc-transfer-kit.sh
#   bash staging/scripts/audit-pc-transfer-kit.sh --source "/Volumes/Transfer/.../palm-springs-paradise"
#   bash staging/scripts/audit-pc-transfer-kit.sh --apply

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="${SOURCE:-/Volumes/Transfer/PC_Transfer_Kit/PalmSpringsParadise/Users/karl/palm-springs-paradise}"
APPLY=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SOURCE="$2"; shift 2 ;;
    --apply) APPLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    *) echo "Unknown arg: $1"; exit 1 ;;
  esac
done

MANIFEST_DIR="$ROOT/vendor-imports/_manifests"
INCOMING_ROOT="$ROOT/vendor-imports/_incoming"
PACK_DATE="$(date +%Y-%m-%d)"
PACK_SLUG="${PACK_DATE}_pc-transfer-karl"
TIMESTAMP="$(date -Iseconds)"
JSON_OUT="$MANIFEST_DIR/pc-transfer-audit.json"
MD_OUT="$MANIFEST_DIR/pc-transfer-audit.md"
LOG_OUT="$MANIFEST_DIR/import-log.jsonl"

echo "=== PC Transfer Kit Audit ==="
echo "Repo:   $ROOT"
echo "Source: $SOURCE"

if [[ ! -d "$SOURCE" ]]; then
  echo ""
  echo "ERROR: Source path not found."
  echo "Windows default (from KRLX screenshot):"
  echo "  D:\\PC_Transfer_Kit\\PalmSpringsParadise\\Users\\karl\\palm-springs-paradise"
  echo "Set: SOURCE=/your/mount/path bash staging/scripts/audit-pc-transfer-kit.sh"
  exit 1
fi

mkdir -p "$MANIFEST_DIR"

export AUDIT_SOURCE="$SOURCE" AUDIT_ROOT="$ROOT" AUDIT_PACK_SLUG="$PACK_SLUG"
export AUDIT_TS="$TIMESTAMP" AUDIT_JSON="$JSON_OUT" AUDIT_MD="$MD_OUT"
export AUDIT_LOG="$LOG_OUT" AUDIT_APPLY="$APPLY" AUDIT_DRY_RUN="$DRY_RUN"
export AUDIT_INCOMING="$INCOMING_ROOT"

python3 <<'PY'
import json, os, re, shutil
from pathlib import Path
from collections import defaultdict

source = os.environ["AUDIT_SOURCE"]
root = os.environ["AUDIT_ROOT"]
pack_slug = os.environ["AUDIT_PACK_SLUG"]
ts = os.environ["AUDIT_TS"]
json_out = os.environ["AUDIT_JSON"]
md_out = os.environ["AUDIT_MD"]
log_out = os.environ["AUDIT_LOG"]
apply = os.environ.get("AUDIT_APPLY") == "1"
dry_run = os.environ.get("AUDIT_DRY_RUN") == "1"
incoming_root = os.environ["AUDIT_INCOMING"]
source_path = Path(source)
root_path = Path(root)

ext_map = {
    ".fbx": "furniture/decor", ".blend": "furniture/decor", ".obj": "furniture/decor",
    ".png": "textures/world", ".jpg": "textures/world", ".jpeg": "textures/world",
    ".mp3": "audio/ambience", ".ogg": "audio/ambience", ".wav": "audio/ambience",
    ".rbxl": "places", ".rbxlx": "places", ".lua": "legacy-scripts/do-not-ship",
    ".luau": "legacy-scripts/do-not-ship",
}
hints = [
    (r"kaufmann", "architecture/residential/kaufmann"),
    (r"frey", "architecture/residential/frey"),
    (r"garden|plant|cactus", "plants/cacti"),
    (r"fashion|runway", "fashion/runway-props"),
    (r"audio|sound", "audio/ambience"),
    (r"furniture|eames|chair", "furniture/seating"),
]

def slugify(name: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", Path(name).stem.lower()).strip("_")
    return (s[:48] or "asset_unknown")

def category_for(rel: str, ext: str) -> str:
    low = rel.lower()
    for pat, cat in hints:
        if re.search(pat, low):
            return cat
    return ext_map.get(ext, f"_incoming/{pack_slug}/uncategorized")

entries = []
warnings = []
by_ext = defaultdict(int)
by_cat = defaultdict(int)
total = 0

for path in source_path.rglob("*"):
    if not path.is_file():
        continue
    rel = str(path.relative_to(source_path))
    low_rel = rel.lower()
    if any(x in low_rel for x in ("node_modules", ".git/", "__macosx", "thumbs.db")):
        continue
    ext = path.suffix.lower()
    cat = category_for(rel, ext)
    flags = []
    if ext in (".lua", ".luau"):
        flags.append("LEGACY_LUA_REFERENCE_ONLY")
        warnings.append(f"Legacy Lua: {rel}")
    if path.stat().st_size > 50 * 1024 * 1024:
        flags.append("LARGE_FILE")
        warnings.append(f"Large file: {rel}")
    size = path.stat().st_size
    total += size
    by_ext[ext] += 1
    by_cat[cat] += 1
    entries.append({
        "relativePath": rel,
        "sizeBytes": size,
        "extension": ext,
        "suggestedCategory": cat,
        "suggestedSlug": slugify(path.name),
        "flags": flags,
    })

report = {
    "auditedAt": ts,
    "sourcePath": str(source_path),
    "repoRoot": str(root_path),
    "packSlug": pack_slug,
    "summary": {
        "fileCount": len(entries),
        "totalBytes": total,
        "totalMegabytes": round(total / (1024 * 1024), 2),
        "byExtension": dict(by_ext),
        "byCategory": dict(by_cat),
        "warningCount": len(warnings),
    },
    "warnings": warnings,
    "files": entries,
}

Path(json_out).write_text(json.dumps(report, indent=2), encoding="utf-8")

md_lines = [
    "# PC Transfer Kit Audit",
    "",
    f"| Audited | {ts} |",
    f"| Source | `{source_path}` |",
    f"| Files | {len(entries)} |",
    f"| Size | {round(total/(1024*1024), 2)} MB |",
    "",
    "## By category",
]
for k in sorted(by_cat):
    md_lines.append(f"- `{k}`: {by_cat[k]}")
Path(md_out).write_text("\n".join(md_lines) + "\n", encoding="utf-8")

log_line = json.dumps({
    "at": ts, "action": "audit_and_apply" if apply else "audit_only",
    "sourcePath": str(source_path), "fileCount": len(entries), "packSlug": pack_slug,
})
with open(log_out, "a", encoding="utf-8") as f:
    f.write(log_line + "\n")

if apply:
    copied = 0
    for e in entries:
        src = source_path / e["relativePath"]
        cat = e["suggestedCategory"]
        if cat.startswith("_incoming/"):
            dest_dir = Path(incoming_root) / pack_slug / "uncategorized"
        else:
            dest_dir = root_path / "vendor-imports" / cat
        dest_dir.mkdir(parents=True, exist_ok=True)
        dest = dest_dir / f"{cat.replace('/', '__')}__{e['suggestedSlug']}__{src.name}"
        if dry_run:
            print(f"DRY-RUN: {src} -> {dest}")
        else:
            shutil.copy2(src, dest)
        copied += 1
    print(f"Applied: {copied} files")

print(f"Files: {len(entries)}  Warnings: {len(warnings)}")
print(f"Report: {json_out}")
PY

echo "=== Audit complete ==="
