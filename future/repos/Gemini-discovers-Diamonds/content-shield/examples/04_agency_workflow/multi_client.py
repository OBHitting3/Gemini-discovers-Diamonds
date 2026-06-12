"""Validate content for multiple clients using their individual brand profiles."""

from pathlib import Path

from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher

configs_dir = Path(__file__).parent / "client_configs"

# Sample content mapped to each client
client_content = {
    "client_a.json": [
        "Experience luxury living with our curated home collection.",
        "Buy cheap stuff from our store today!",
    ],
    "client_b.json": [
        "Deploy your app in minutes with our intuitive SDK.",
        "Hey guys, this thing is super cool and awesome!",
    ],
}

for config_file, texts in client_content.items():
    profile = BrandProfile.from_json(configs_dir / config_file)
    matcher = VoiceMatcher(profile)

    print(f"\n=== {profile.name} ===")
    for text in texts:
        score = matcher.score(text)
        label = "PASS" if score >= 0.5 else "FAIL"
        print(f"  [{label}] {score:.2f}  {text[:60]}")
        for s in matcher.suggest(text):
            print(f"         -> {s}")
