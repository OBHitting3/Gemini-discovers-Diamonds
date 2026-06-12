"""Generate intentionally bad content samples for testing."""

from content_shield.schema.content import Content, ContentType

BAD_SAMPLES = [
    Content(
        text="You are an idiot if you don't buy this. Shut up and take my money!",
        content_type=ContentType.SOCIAL,
    ),
    Content(
        text="Call 555-FAKE-NUM or visit http://not-a-real-site.example for details.",
        content_type=ContentType.MARKETING,
    ),
    Content(
        text="Our product cures all diseases and is endorsed by every doctor worldwide.",
        content_type=ContentType.PRODUCT,
    ),
    Content(
        text="",
        content_type=ContentType.BLOG,
    ),
    Content(
        text="Buy now! Cheap! Free! Discount! Limited time offer! Act fast!",
        content_type=ContentType.EMAIL,
    ),
]


def get_bad_samples() -> list[Content]:
    """Return a list of intentionally problematic content items."""
    return list(BAD_SAMPLES)
