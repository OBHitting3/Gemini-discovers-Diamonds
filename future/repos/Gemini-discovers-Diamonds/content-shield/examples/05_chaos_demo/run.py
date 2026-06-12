"""Run the chaos demo: inject bad content, validate, and report."""

from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

from chaos_agent import mutate
from inject_bad_content import get_bad_samples
from monitor import Monitor

GOOD_TEXTS = [
    "Welcome to our platform. We help teams collaborate effectively.",
    "Read our latest blog post about productivity tips for remote teams.",
    "Thank you for subscribing! Here is your weekly digest.",
]

shield = ContentShield()
mon = Monitor()

# Phase 1: validate known-bad content
print("=== Phase 1: Known-bad content ===")
for content in get_bad_samples():
    result = shield.validate(content)
    mon.record(result.passed, result.issues)
    status = "PASS" if result.passed else "FAIL"
    print(f"  [{status}] {content.text[:50]}...")

# Phase 2: mutate good content with chaos agent
print("\n=== Phase 2: Chaos-mutated content ===")
for text in GOOD_TEXTS:
    mutated = mutate(text, chaos_level=0.7)
    content = Content(text=mutated, content_type=ContentType.MARKETING)
    result = shield.validate(content)
    mon.record(result.passed, result.issues)
    status = "PASS" if result.passed else "FAIL"
    print(f"  [{status}] {mutated[:50]}...")

print(f"\n=== Summary ===\n{mon.summary()}")
