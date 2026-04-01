"""Generate a summary validation report for all clients."""

import json
from datetime import datetime, timezone
from pathlib import Path

from content_shield import ContentShield
from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher
from content_shield.schema.content import Content, ContentType

shield = ContentShield()
configs_dir = Path(__file__).parent / "client_configs"

# Content to validate per client
client_content = {
    "client_a.json": "Experience our exquisite, curated selection of premium furnishings.",
    "client_b.json": "Configure your API endpoint and deploy with a single command.",
}

report = {
    "generated_at": datetime.now(timezone.utc).isoformat(),
    "clients": [],
}

for config_file, text in client_content.items():
    profile = BrandProfile.from_json(configs_dir / config_file)
    matcher = VoiceMatcher(profile)

    content = Content(text=text, content_type=ContentType.MARKETING)
    result = shield.validate(content)
    voice_score = matcher.score(text)

    report["clients"].append({
        "name": profile.name,
        "text_snippet": text[:60],
        "shield_passed": result.passed,
        "voice_score": round(voice_score, 2),
        "issues": [i.message for i in result.issues],
        "suggestions": matcher.suggest(text),
    })

print(json.dumps(report, indent=2))
