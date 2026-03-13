# Brand Profile Examples

Create a brand profile and validate content against it.

## Files

| File | Description |
|------|-------------|
| `create_profile.py` | Build a `BrandProfile` and save it as JSON |
| `validate_against_brand.py` | Load the profile and score content |
| `my_brand.json` | Sample brand profile JSON |

## Usage

```bash
# Create a profile (writes my_brand.json)
python create_profile.py

# Score sample content against the profile
python validate_against_brand.py
```
