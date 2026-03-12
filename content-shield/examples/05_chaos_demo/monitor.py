"""Monitor and display validation results during a chaos run."""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass
class MonitorStats:
    """Accumulates stats across validation runs."""

    total: int = 0
    passed: int = 0
    failed: int = 0
    issues_by_severity: dict[str, int] = field(default_factory=dict)

    @property
    def fail_rate(self) -> float:
        return self.failed / self.total if self.total else 0.0


class Monitor:
    """Tracks validation outcomes and prints a live summary."""

    def __init__(self) -> None:
        self.stats = MonitorStats()

    def record(self, passed: bool, issues: list | None = None) -> None:
        self.stats.total += 1
        if passed:
            self.stats.passed += 1
        else:
            self.stats.failed += 1
        for issue in issues or []:
            sev = issue.severity.value
            self.stats.issues_by_severity[sev] = (
                self.stats.issues_by_severity.get(sev, 0) + 1
            )

    def summary(self) -> str:
        lines = [
            f"Total: {self.stats.total}",
            f"Passed: {self.stats.passed}",
            f"Failed: {self.stats.failed}",
            f"Fail rate: {self.stats.fail_rate:.0%}",
        ]
        if self.stats.issues_by_severity:
            lines.append("Issues by severity:")
            for sev, count in sorted(self.stats.issues_by_severity.items()):
                lines.append(f"  {sev}: {count}")
        return "\n".join(lines)
