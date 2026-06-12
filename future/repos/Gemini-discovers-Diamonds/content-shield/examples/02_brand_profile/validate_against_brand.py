"""Load a brand profile and score sample content against it."""

from pathlib import Path

from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher

profile = BrandProfile.from_json(Path(__file__).parent / "my_brand.json")
matcher = VoiceMatcher(profile)

samples = [
    "Welcome to our platform! We're delighted to help you transform your business.",
    "Get this cheap app now for a free trial, clients love it!",
    "Our cutting-edge platform ensures your team can collaborate effectively.",
]

for text in samples:
    score = matcher.score(text)
    suggestions = matcher.suggest(text)
    print(f"\nScore: {score:.2f}  Text: {text[:60]}...")
    for s in suggestions:
        print(f"  -> {s}")
