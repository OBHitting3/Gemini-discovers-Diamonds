#!/usr/bin/env bash
# Triage station. Walk one file at a time. You decide keep / discard.
# Drop files into ./inbox/ then double-click this.
set -euo pipefail
cd "$(dirname "$0")"

INBOX="inbox"
KEEP="keep"
DISCARD="discard"
mkdir -p "$INBOX" "$KEEP" "$DISCARD"

shopt -s nullglob
files=("$INBOX"/*)
# Filter out .gitkeep
real_files=()
for f in "${files[@]}"; do
  [ "$(basename "$f")" = ".gitkeep" ] && continue
  [ -f "$f" ] && real_files+=("$f")
done

if [ ${#real_files[@]} -eq 0 ]; then
  echo "Inbox is empty."
  echo
  echo "Drop files into:"
  echo "  $(pwd)/$INBOX"
  echo
  read -n 1 -s -r -p "Press any key to close..."
  echo
  exit 0
fi

echo "${#real_files[@]} file(s) to triage."
echo

for f in "${real_files[@]}"; do
  clear || true
  echo "============================================="
  echo "FILE: $(basename "$f")"
  echo "SIZE: $(du -h "$f" | cut -f1)"
  echo "============================================="
  echo
  echo "--- first 40 lines ---"
  head -n 40 "$f" 2>/dev/null || echo "(binary file, no preview)"
  echo
  echo "--- end preview ---"
  echo
  while true; do
    read -n 1 -p "[k]eep   [d]iscard   [s]kip   [q]uit  > " choice
    echo
    case "$choice" in
      k|K) mv "$f" "$KEEP/"; echo "  -> kept"; break ;;
      d|D) mv "$f" "$DISCARD/"; echo "  -> discarded (still on disk in ./discard/, recoverable)"; break ;;
      s|S) echo "  -> skipped (left in inbox for next time)"; break ;;
      q|Q) echo "  -> quit"; exit 0 ;;
      *) echo "  ? press k, d, s, or q" ;;
    esac
  done
done

echo
echo "Inbox done."
echo
read -n 1 -p "Open memory.md to jot notes about what you kept? [y/n] > " open_mem
echo
if [ "$open_mem" = "y" ] || [ "$open_mem" = "Y" ]; then
  open -a TextEdit memory.md 2>/dev/null || open memory.md
fi

read -n 1 -s -r -p "Press any key to close..."
echo
