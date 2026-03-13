# Brand Profiles

Brand profiles let you codify a brand's voice, tone, and terminology rules so Content Shield can automatically enforce them.

## Creating a Profile

```python
from content_shield.brand.profile import BrandProfile

profile = BrandProfile(
    name="Acme Corp",
    voice_attributes=["professional", "warm"],
    tone="conversational",
    banned_words=["cheap", "deal"],
    required_terminology={"clients": "customers", "app": "platform"},
    target_audience="small business owners",
    industry="SaaS",
)
```

## Persistence

Save and load profiles as JSON:

```python
profile.to_json("acme.json")
loaded = BrandProfile.from_json("acme.json")
```

## Built-in Templates

The `brand/templates/` directory ships with starter profiles:

- `professional.json`
- `casual.json`
- `luxury.json`
- `technical.json`

## Voice Matching

`VoiceMatcher` scores content against a profile:

```python
from content_shield.brand.voice_matcher import VoiceMatcher

matcher = VoiceMatcher(profile)
score = matcher.score("Welcome! We're glad you're here.")  # 0.0-1.0
suggestions = matcher.suggest("Get this cheap app now!")
```

The matcher evaluates three dimensions:

1. **Banned words** -- each banned word found reduces the score (up to -0.6).
2. **Terminology** -- incorrect terms reduce the score (up to -0.4).
3. **Voice attributes** -- presence of attribute-indicator words adds to the score.

## Supported Voice Attributes

`professional`, `warm`, `friendly`, `formal`, `conversational`, `authoritative`, `luxurious`, `technical`, `empathetic`, `innovative`
