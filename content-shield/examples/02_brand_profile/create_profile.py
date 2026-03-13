"""Create a brand profile and persist it to JSON."""

from pathlib import Path

from content_shield.brand.profile import BrandProfile

profile = BrandProfile(
    name="Acme Corp",
    voice_attributes=["professional", "warm", "innovative"],
    tone="conversational",
    banned_words=["cheap", "deal", "free trial"],
    required_terminology={
        "clients": "customers",
        "app": "platform",
    },
    target_audience="small business owners",
    industry="SaaS",
)

output = Path(__file__).parent / "my_brand.json"
profile.to_json(output)
print(f"Brand profile saved to {output}")
