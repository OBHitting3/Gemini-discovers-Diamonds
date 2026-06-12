import type { BridgeContext, LLMTarget } from "@/types/bridge-context";

export interface ValidationResult {
  target: LLMTarget["id"];
  valid: boolean;
  errors: string[];
  warnings: string[];
  tokenCount: number;
  tokenLimit: number;
}

export interface ValidationReport {
  allValid: boolean;
  results: ValidationResult[];
  validatedAt: string;
}

const TOKEN_LIMITS: Record<LLMTarget["id"], number> = {
  cursor: 100_000,
  claude: 200_000,
  chatgpt: 128_000,
  gemini: 1_000_000,
};

const FORMAT_REQUIREMENTS: Record<LLMTarget["id"], string[]> = {
  cursor: ["Must export as .cursorrules plain text", "Max 100k tokens"],
  claude: ["Must be valid JSON for Knowledge Base", "Max 200k tokens"],
  chatgpt: [
    "Must fit Custom Instructions format (1500 char limit per field)",
    "Max 128k tokens",
  ],
  gemini: ["Must be valid system prompt text", "Max 1M tokens"],
};

function estimateTokenCount(text: string): number {
  // rough approximation: ~4 chars per token
  return Math.ceil(text.length / 4);
}

function validateCursorFormat(context: BridgeContext): string[] {
  const errors: string[] = [];
  const tokenCount = estimateTokenCount(context.globalContext);
  if (tokenCount > TOKEN_LIMITS.cursor) {
    errors.push(
      `Context too large: ~${tokenCount} tokens exceeds Cursor limit of ${TOKEN_LIMITS.cursor}`
    );
  }
  return errors;
}

function validateClaudeFormat(context: BridgeContext): string[] {
  const errors: string[] = [];
  const tokenCount = estimateTokenCount(context.globalContext);
  if (tokenCount > TOKEN_LIMITS.claude) {
    errors.push(
      `Context too large: ~${tokenCount} tokens exceeds Claude limit of ${TOKEN_LIMITS.claude}`
    );
  }
  return errors;
}

function validateChatGPTFormat(context: BridgeContext): string[] {
  const errors: string[] = [];
  const tokenCount = estimateTokenCount(context.globalContext);
  if (tokenCount > TOKEN_LIMITS.chatgpt) {
    errors.push(
      `Context too large: ~${tokenCount} tokens exceeds ChatGPT limit of ${TOKEN_LIMITS.chatgpt}`
    );
  }
  if (context.globalContext.length > 32_000) {
    errors.push(
      "Custom Instructions field is limited to ~1500 chars visible; consider compressing"
    );
  }
  return errors;
}

function validateGeminiFormat(context: BridgeContext): string[] {
  const errors: string[] = [];
  const tokenCount = estimateTokenCount(context.globalContext);
  if (tokenCount > TOKEN_LIMITS.gemini) {
    errors.push(
      `Context too large: ~${tokenCount} tokens exceeds Gemini limit of ${TOKEN_LIMITS.gemini}`
    );
  }
  return errors;
}

const VALIDATORS: Record<
  LLMTarget["id"],
  (ctx: BridgeContext) => string[]
> = {
  cursor: validateCursorFormat,
  claude: validateClaudeFormat,
  chatgpt: validateChatGPTFormat,
  gemini: validateGeminiFormat,
};

export function validateContextForTargets(
  context: BridgeContext
): ValidationReport {
  const results: ValidationResult[] = context.targets
    .filter((t) => t.enabled)
    .map((target) => {
      const errors = VALIDATORS[target.id](context);
      const warnings: string[] = [];
      const tokenCount = estimateTokenCount(context.globalContext);
      const tokenLimit = TOKEN_LIMITS[target.id];

      if (tokenCount > tokenLimit * 0.8 && tokenCount <= tokenLimit) {
        warnings.push(
          `Approaching token limit: ~${tokenCount}/${tokenLimit} tokens used`
        );
      }

      return {
        target: target.id,
        valid: errors.length === 0,
        errors,
        warnings,
        tokenCount,
        tokenLimit,
        formatRequirements: FORMAT_REQUIREMENTS[target.id],
      };
    });

  return {
    allValid: results.every((r) => r.valid),
    results,
    validatedAt: new Date().toISOString(),
  };
}
