# Pain Line Setup

The Pain Line is a quality-trend metric that tracks cumulative content issues over time. When the pain score crosses a threshold, it signals that content quality needs attention.

## Core Concepts

- **PainPoint** -- a single measurement with a timestamp, score (0-100), shield name, and description.
- **PainLineTracker** -- accumulates pain points and computes a rolling aggregate score from the last 10 measurements.
- **Threshold** -- a configurable limit (default 50.0). When the current score exceeds the threshold a warning is logged.

## Basic Usage

```python
from content_shield.dashboard.pain_line import PainLineTracker

tracker = PainLineTracker(threshold=40.0)

# Record pain points after validation
tracker.record("toxicity", score=15.0, description="Minor keyword hit")
tracker.record("brand_voice", score=60.0, description="Off-brand language detected")

print(tracker.current_score)       # rolling average
print(tracker.is_above_threshold)  # True if above 40.0
```

## Querying History

```python
# Last 50 points
history = tracker.get_history(limit=50)

# Filter by shield
brand_issues = tracker.get_by_shield("brand_voice")
```

## Integration with Dashboards

The `dashboard.grafana_generator` module can produce Grafana JSON models from pain line data. Feed the tracker's history into it to visualize trends on a time-series panel.

## Tips

- Set the threshold based on your team's tolerance. Start at 50 and adjust.
- Record a pain point after every `ValidationResult` that has issues.
- Use `tracker.clear()` when you rotate reporting periods.
