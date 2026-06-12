"""Simulate generating content and validating it before publishing."""

from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType


def generate_content() -> str:
    """Placeholder for an LLM content generation step."""
    return (
        "Discover our revolutionary platform that helps small businesses "
        "streamline operations. Our team ensures every customer receives "
        "world-class support."
    )


def publish(text: str) -> None:
    """Placeholder for a publishing step."""
    print(f"PUBLISHED: {text[:80]}...")


shield = ContentShield()
text = generate_content()

content = Content(text=text, content_type=ContentType.MARKETING)
result = shield.validate(content)

if result.passed:
    publish(text)
else:
    print("Content blocked. Issues found:")
    for issue in result.issues:
        print(f"  [{issue.severity.value}] {issue.message}")
    print("Suggestions:")
    for s in result.suggestions:
        print(f"  -> {s}")
