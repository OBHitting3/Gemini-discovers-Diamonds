#!/usr/bin/env bash
# Combine voice.md + memory.md into a system prompt and copy it to clipboard.
# Then paste it in Open WebUI -> Settings -> Models -> System Prompt.
set -euo pipefail
cd "$(dirname "$0")"

strip_comments() {
  # Drop lines starting with # and blank lines
  grep -v '^[[:space:]]*#' "$1" 2>/dev/null | sed '/^[[:space:]]*$/d' || true
}

voice_content="$(strip_comments voice.md)"
mem_content="$(strip_comments memory.md)"

[ -z "$voice_content" ] && voice_content="(none yet — paste sample writing into voice.md)"
[ -z "$mem_content" ] && mem_content="(none yet — add facts to memory.md)"

prompt="You are a private assistant for one user. Follow these rules.

# How this user talks
${voice_content}

# Things to remember about this user
${mem_content}

# Behavior
- Mirror this user's tone and pacing. Match their register.
- Do not invent facts about them. If you do not know, ask.
- When they say 'remember this,' confirm it and ask whether to file under voice.md or memory.md.
- Do not import outside knowledge about this user. Only what is in this prompt or in this conversation."

if command -v pbcopy >/dev/null 2>&1; then
  printf "%s" "$prompt" | pbcopy
  echo "System prompt copied to clipboard."
else
  echo "$prompt"
fi

echo
echo "Paste it in Open WebUI:"
echo "  Settings -> Models -> (your model) -> System Prompt"
echo "  (or set per-conversation in the chat's controls)"
echo
read -n 1 -s -r -p "Press any key to close..."
echo
