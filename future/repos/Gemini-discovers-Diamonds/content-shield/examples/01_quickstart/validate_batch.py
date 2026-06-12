"""Validate multiple content items in a single batch."""

from content_shield import ContentShield
from content_shield.schema.content import Content, ContentBatch, ContentType

shield = ContentShield()

batch = ContentBatch(
    items=[
        Content(
            text="Welcome to our store! We have amazing deals for you.",
            content_type=ContentType.MARKETING,
        ),
        Content(
            text="This blog post explains how to configure your dashboard.",
            content_type=ContentType.BLOG,
        ),
        Content(
            text="Hi there! Check out our latest newsletter.",
            content_type=ContentType.EMAIL,
        ),
    ]
)

results = shield.validate_batch(batch.items)

for i, result in enumerate(results):
    print(f"\n--- Item {i + 1} ---")
    print(f"Passed: {result.passed}  Score: {result.score:.2f}")
    if result.issues:
        for issue in result.issues:
            print(f"  [{issue.severity.value}] {issue.message}")
