"""CAC tier scoring.

Adapted from NIST ALFUS SP 1011-I-2.0 (Autonomy Levels For Unmanned Systems,
Framework Volume I, Terms and Definitions / Detailed Model). The original
ALFUS framework scores Human Independence (HI), Mission Complexity (MC), and
Environmental Complexity (EC) on continuous axes; we discretise into 5 CAC
tiers per Alpha's mapping for software agents:

  tier 0  - human in the loop on every step (HI < 2)
  tier 1  - mandatory human approval per action  (HI 2-4)
  tier 2  - batch / policy approval, periodic review  (HI 4-6)
  tier 3  - supervised autonomy with sampled review   (HI 6-8)
  tier 4  - full autonomy in a proven narrow domain   (HI 8-10)

This module ships a rules-based scorer keyed on action_type. It is designed
for a future swap to a learned scorer (e.g. an Anthropic classifier) by
preserving the score_action() signature.
"""

from __future__ import annotations

from typing import Any, Mapping

from karl_twin.actions.envelope import CACScore, RiskLevel


# Per-action-type baseline scores. Tuned conservatively: anything that
# touches the network or external accounts starts at tier 1 (human approval
# required) until proven otherwise.
_BASELINES: dict[str, dict[str, float]] = {
    "file.write":      {"HI": 3.0, "MC": 2.0, "EC": 2.0},
    "file.read":       {"HI": 8.0, "MC": 1.0, "EC": 1.0},
    "code.execute":    {"HI": 2.0, "MC": 5.0, "EC": 5.0},
    "shell.execute":   {"HI": 1.0, "MC": 5.0, "EC": 7.0},
    "gmail.send":      {"HI": 1.0, "MC": 3.0, "EC": 6.0},
    "gumroad.fulfill": {"HI": 1.0, "MC": 4.0, "EC": 7.0},
    "memory.write":    {"HI": 6.0, "MC": 2.0, "EC": 2.0},
    "memory.read":     {"HI": 9.0, "MC": 1.0, "EC": 1.0},
    "respond":         {"HI": 9.0, "MC": 1.0, "EC": 1.0},
}


def _tier_from_hi(hi: float) -> int:
    """Map HI score to CAC tier (0..4)."""
    if hi < 2.0:
        return 0
    if hi < 4.0:
        return 1
    if hi < 6.0:
        return 2
    if hi < 8.0:
        return 3
    return 4


def _risk_to_hi_penalty(risk: RiskLevel | str | None) -> float:
    if risk is None:
        return 0.0
    r = risk.value if isinstance(risk, RiskLevel) else str(risk)
    return {
        "low": 0.0,
        "medium": -1.0,
        "high": -2.0,
        "critical": -4.0,
    }.get(r, 0.0)


def _payload_penalty(action_type: str, payload: Mapping[str, Any]) -> tuple[float, float, float]:
    """Heuristic adjustments to (HI, MC, EC) based on payload content.

    Examples: writing outside OUTPUT_DIR penalises HI. Code with network
    calls increases EC. Long instruction text increases MC.
    """
    hi_adj = mc_adj = ec_adj = 0.0

    if action_type == "file.write":
        path = str(payload.get("path", ""))
        if path and not path.startswith(("./", "data/", "data\\")):
            # Out-of-sandbox path is more dangerous.
            hi_adj -= 1.5
            ec_adj += 1.0

    if action_type == "code.execute":
        code = str(payload.get("code", ""))
        if any(keyword in code for keyword in ("requests.", "urllib", "http", "socket", "os.system", "subprocess")):
            ec_adj += 2.0
            hi_adj -= 1.0
        if len(code) > 2000:
            mc_adj += 1.0

    return hi_adj, mc_adj, ec_adj


def score_action(
    action_type: str,
    payload: Mapping[str, Any],
    context: Mapping[str, Any] | None = None,
) -> CACScore:
    """Score an action and return a CACScore.

    Stable signature so a future learned scorer (e.g. fine-tuned classifier)
    can drop in by re-implementing this function.

    Args:
        action_type: e.g. "file.write", "code.execute".
        payload: the action's payload dict (will be inspected, not executed).
        context: optional run context (caller, recent risks, etc.).
    """
    context = context or {}
    base = _BASELINES.get(action_type, {"HI": 2.0, "MC": 5.0, "EC": 5.0})

    hi_adj, mc_adj, ec_adj = _payload_penalty(action_type, payload)
    hi_adj += _risk_to_hi_penalty(context.get("risk_level"))

    HI = max(0.0, min(10.0, base["HI"] + hi_adj))
    MC = max(0.0, min(10.0, base["MC"] + mc_adj))
    EC = max(0.0, min(10.0, base["EC"] + ec_adj))
    tier = _tier_from_hi(HI)

    rationale = (
        f"Baseline for '{action_type}': HI={base['HI']}, MC={base['MC']}, EC={base['EC']}. "
        f"Adjustments HI={hi_adj:+.1f}, MC={mc_adj:+.1f}, EC={ec_adj:+.1f}. "
        f"Final tier={tier} ({'human approval mandatory' if tier <= 1 else 'batch/policy review' if tier <= 3 else 'autonomous (narrow domain)'})."
    )

    return CACScore(HI=HI, MC=MC, EC=EC, tier=tier, rationale=rationale)


def requires_human_approval(score: CACScore) -> bool:
    """Tier 0/1 are mandatory human approval per spec invariants."""
    return score.tier <= 1
