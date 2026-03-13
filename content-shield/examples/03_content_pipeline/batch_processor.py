"""Read content from a JSON file, validate each item, and print a report."""

import json
from pathlib import Path

from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

shield = ContentShield()

data_path = Path(__file__).parent / "sample_content.json"
items = json.loads(data_path.read_text())

passed_count = 0
failed_count = 0

for entry in items:
    content = Content(
        text=entry["text"],
        content_type=ContentType(entry["content_type"]),
    )
    result = shield.validate(content)

    status = "PASS" if result.passed else "FAIL"
    if result.passed:
        passed_count += 1
    else:
        failed_count += 1

    print(f"[{status}] {content.text[:50]}...")
    for issue in result.issues:
        print(f"       {issue.severity.value}: {issue.message}")

print(f"\nSummary: {passed_count} passed, {failed_count} failed")
