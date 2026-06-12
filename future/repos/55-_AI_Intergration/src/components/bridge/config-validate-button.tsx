"use client";

import { useState } from "react";
import type { BridgeContext } from "@/types/bridge-context";
import type { ValidationReport } from "@/lib/validation";
import { validateContextForTargets } from "@/lib/validation";

interface ConfigValidateButtonProps {
  context: BridgeContext;
}

export default function ConfigValidateButton({
  context,
}: ConfigValidateButtonProps) {
  const [report, setReport] = useState<ValidationReport | null>(null);
  const [isValidating, setIsValidating] = useState(false);

  async function handleValidate() {
    setIsValidating(true);
    setReport(null);

    // Simulate brief async work (e.g., could call /api/validate in future)
    await new Promise((r) => setTimeout(r, 200));
    const result = validateContextForTargets(context);
    setReport(result);
    setIsValidating(false);
  }

  return (
    <div className="space-y-4">
      <button
        onClick={handleValidate}
        disabled={isValidating}
        className={`px-4 py-2 rounded font-semibold text-white transition-colors ${
          isValidating
            ? "bg-gray-400 cursor-not-allowed"
            : "bg-blue-600 hover:bg-blue-700 active:bg-blue-800"
        }`}
      >
        {isValidating ? "Validating..." : "Validate Config"}
      </button>

      {report && (
        <div className="border rounded p-4 space-y-3">
          <div className="flex items-center gap-2">
            <span
              className={`text-sm font-bold ${
                report.allValid ? "text-green-600" : "text-red-600"
              }`}
            >
              {report.allValid ? "All targets valid" : "Validation failed"}
            </span>
            <span className="text-xs text-gray-400">
              {new Date(report.validatedAt).toLocaleTimeString()}
            </span>
          </div>

          {report.results.map((r) => (
            <div
              key={r.target}
              className={`p-3 rounded text-sm border ${
                r.valid
                  ? "border-green-200 bg-green-50"
                  : "border-red-200 bg-red-50"
              }`}
            >
              <div className="flex justify-between items-center mb-1">
                <span className="font-semibold capitalize">{r.target}</span>
                <span
                  className={`text-xs px-2 py-0.5 rounded-full ${
                    r.valid
                      ? "bg-green-200 text-green-800"
                      : "bg-red-200 text-red-800"
                  }`}
                >
                  {r.valid ? "PASS" : "FAIL"}
                </span>
              </div>

              <div className="text-xs text-gray-600 mb-1">
                ~{r.tokenCount.toLocaleString()} / {r.tokenLimit.toLocaleString()} tokens
              </div>

              {r.errors.length > 0 && (
                <ul className="mt-1 space-y-0.5">
                  {r.errors.map((e, i) => (
                    <li key={i} className="text-red-700 text-xs">
                      ✕ {e}
                    </li>
                  ))}
                </ul>
              )}

              {r.warnings.length > 0 && (
                <ul className="mt-1 space-y-0.5">
                  {r.warnings.map((w, i) => (
                    <li key={i} className="text-yellow-700 text-xs">
                      ⚠ {w}
                    </li>
                  ))}
                </ul>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
