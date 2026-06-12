"""CLI for Joshua 7 content validation."""

import sys

from joshua7.core import run_validation


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: j7 <text>", file=sys.stderr)
        sys.exit(1)

    text = sys.argv[1]
    result = run_validation(text)

    print(str(result))
    for f in result.findings:
        print(f"[{f.validator_id}] {f.message}")

    sys.exit(0 if result.passed else 1)
