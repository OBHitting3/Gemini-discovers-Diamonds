"""Minimal HTTP API for Joshua 7 validation. Used for deployment (Render, Railway)."""

from flask import Flask, request, jsonify

from joshua7.core import run_validation

app = Flask(__name__)


@app.route("/health")
def health() -> dict:
    """Health check for deploy platforms."""
    return {"status": "ok", "service": "joshua7"}


@app.route("/validate", methods=["POST"])
def validate() -> tuple[dict, int]:
    """
    Validate content. POST JSON: {"text": "..."}.
    Returns {"passed": bool, "findings": [{"validator_id": str, "message": str, "severity": str}]}.
    """
    data = request.get_json(silent=True) or {}
    text = data.get("text", "")
    if not text:
        return jsonify({"error": "Missing 'text' in JSON body"}), 400

    result = run_validation(text)
    findings = [
        {
            "validator_id": f.validator_id,
            "message": f.message,
            "severity": f.severity,
        }
        for f in result.findings
    ]
    return jsonify({"passed": result.passed, "findings": findings}), 200


def main() -> None:
    """Run the API server (Flask dev server). For production use: gunicorn joshua7.api:app."""
    app.run(host="0.0.0.0", port=int(__import__("os").environ.get("PORT", 8000)))


if __name__ == "__main__":
    main()
