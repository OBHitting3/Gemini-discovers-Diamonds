# Guide for Agencies

Content Shield supports multi-client workflows common in marketing and content agencies.

## Managing Multiple Clients

Store each client's brand profile as a separate JSON file:

```
client_configs/
  client_a.json
  client_b.json
  client_c.json
```

Load and validate per client:

```python
from content_shield.brand.profile import BrandProfile
from content_shield.brand.voice_matcher import VoiceMatcher

profile = BrandProfile.from_json("client_configs/client_a.json")
matcher = VoiceMatcher(profile)
score = matcher.score(draft_text)
```

## Batch Validation Across Clients

```python
from content_shield import ContentShield
from content_shield.schema.content import Content, ContentType

shield = ContentShield()

for client_file, texts in client_content_map.items():
    profile = BrandProfile.from_json(client_file)
    matcher = VoiceMatcher(profile)
    for text in texts:
        result = shield.validate(
            Content(text=text, content_type=ContentType.MARKETING)
        )
        voice_score = matcher.score(text)
        # Aggregate into your report
```

## Generating Reports

Build a JSON report per client that includes:

- Shield pass/fail status
- Voice alignment score
- List of issues and suggestions

See `examples/04_agency_workflow/report_generator.py` for a working example.

## Recommended Workflow

1. **Onboard** -- create a `BrandProfile` JSON for the new client.
2. **Validate** -- run all drafts through `ContentShield.validate()` and `VoiceMatcher.score()`.
3. **Review** -- share the report with the client or internal reviewers.
4. **Iterate** -- refine the brand profile based on feedback (add banned words, adjust voice attributes).
5. **Monitor** -- use the Pain Line tracker to watch quality trends over time.

## Tips

- Use the built-in brand templates (`brand/templates/`) as starting points when onboarding new clients.
- Automate validation in your CI/CD or content pipeline so nothing ships without a passing score.
- Set per-client quality thresholds -- a luxury brand may need a higher voice score than a casual startup.
