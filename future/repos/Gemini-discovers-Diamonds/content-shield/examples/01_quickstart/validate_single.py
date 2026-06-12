"""Validate a single piece of content with Content Shield."""

from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

shield = ContentShield()

content = Content(
    text="Our product is the best on the market. Contact us at hello@example.com.",
    content_type=ContentType.MARKETING,
)

result = shield.validate(content)

print(f"Passed: {result.passed}")
print(f"Score:  {result.score}")
for issue in result.issues:
    print(f"  [{issue.severity.value}] {issue.message}")
for suggestion in result.suggestions:
    print(f"  Suggestion: {suggestion}")
