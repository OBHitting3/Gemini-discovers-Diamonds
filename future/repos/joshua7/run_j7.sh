#!/usr/bin/env bash
# Run j7 via venv. Usage: ./run_j7.sh "content to validate"
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$SCRIPT_DIR/.venv/bin/j7" "$@"
