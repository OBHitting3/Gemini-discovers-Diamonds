import type { BridgeContext, LLMTarget } from "@/types/bridge-context";

export interface CompressedConfig {
  targetId: LLMTarget["id"];
  content: string;
  originalTokens: number;
  compressedTokens: number;
  compressionRatio: number;
  truncated: boolean;
}

const TOKEN_BUDGETS: Record<LLMTarget["id"], number> = {
  cursor: 90_000,   // Leave headroom below 100k hard limit
  claude: 180_000,  // Leave headroom below 200k hard limit
  chatgpt: 110_000, // Leave headroom below 128k hard limit
  gemini: 900_000,  // Leave headroom below 1M hard limit
};

function estimateTokens(text: string): number {
  return Math.ceil(text.length / 4);
}

/**
 * Strips redundant whitespace and repeated blank lines from context.
 */
function normalizeWhitespace(text: string): string {
  return text
    .replace(/\r\n/g, "\n")
    .replace(/[ \t]+$/gm, "")          // trailing whitespace per line
    .replace(/\n{3,}/g, "\n\n")        // collapse 3+ blank lines to 2
    .trim();
}

/**
 * Removes common verbose patterns that add tokens without semantic value:
 * - Markdown horizontal rules
 * - Repeated header separators
 * - Excessive bullet padding
 */
function pruneVerbosePatterns(text: string): string {
  return text
    .replace(/^[-=*]{3,}\s*$/gm, "")          // horizontal rules
    .replace(/^#+\s*(---+|===+)\s*$/gm, "")   // header underlines
    .replace(/^\s*[*\-+]\s{2,}/gm, "- ")      // normalize bullet indent
    .replace(/\n{3,}/g, "\n\n")
    .trim();
}

/**
 * Hard-truncates context to fit within token budget, preserving sentence boundaries.
 */
function truncateToTokenBudget(text: string, budget: number): string {
  const currentTokens = estimateTokens(text);
  if (currentTokens <= budget) return text;

  // Approximate char budget: tokens * 4
  const charBudget = budget * 4;
  const truncated = text.slice(0, charBudget);

  // Find last sentence boundary
  const lastPeriod = Math.max(
    truncated.lastIndexOf(". "),
    truncated.lastIndexOf(".\n"),
    truncated.lastIndexOf("! "),
    truncated.lastIndexOf("? ")
  );

  if (lastPeriod > charBudget * 0.8) {
    return truncated.slice(0, lastPeriod + 1) + "\n\n[...truncated to fit token budget]";
  }

  return truncated + "\n\n[...truncated to fit token budget]";
}

export function compressForTarget(
  context: BridgeContext,
  target: LLMTarget
): CompressedConfig {
  const budget = TOKEN_BUDGETS[target.id];
  const originalTokens = estimateTokens(context.globalContext);

  let compressed = normalizeWhitespace(context.globalContext);
  compressed = pruneVerbosePatterns(compressed);

  const afterPruneTokens = estimateTokens(compressed);
  const needsTruncation = afterPruneTokens > budget;

  if (needsTruncation) {
    compressed = truncateToTokenBudget(compressed, budget);
  }

  const compressedTokens = estimateTokens(compressed);

  return {
    targetId: target.id,
    content: compressed,
    originalTokens,
    compressedTokens,
    compressionRatio:
      originalTokens > 0
        ? Math.round((1 - compressedTokens / originalTokens) * 100) / 100
        : 0,
    truncated: needsTruncation,
  };
}

export function compressAllTargets(
  context: BridgeContext
): CompressedConfig[] {
  return context.targets
    .filter((t) => t.enabled)
    .map((target) => compressForTarget(context, target));
}
