# Chaos Demo

Test Content Shield resilience by injecting problematic content and observing how shields, retries, and circuit breakers respond.

## Files

| File | Description |
|------|-------------|
| `run.py` | Entry point -- runs the full chaos demo |
| `chaos_agent.py` | Agent that randomly mutates content to introduce issues |
| `inject_bad_content.py` | Generates intentionally bad content samples |
| `monitor.py` | Tracks and displays validation results in real time |

## Usage

```bash
python run.py
```
