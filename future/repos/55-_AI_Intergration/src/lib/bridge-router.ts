import type { BridgeContext, LLMTarget } from "@/types/bridge-context";

export interface TargetConfig {
  targetId: LLMTarget["id"];
  format: string;
  content: string;
}

function buildCursorRules(context: BridgeContext): string {
  return `# AI Bridge Sync — Cursor Rules
# Generated: ${new Date().toISOString()}
# Version: ${context.version}

${context.globalContext}
`;
}

function buildClaudeKB(context: BridgeContext): string {
  return JSON.stringify(
    {
      type: "knowledge-base",
      version: context.version,
      generatedAt: new Date().toISOString(),
      content: context.globalContext,
    },
    null,
    2
  );
}

function buildChatGPTInstructions(context: BridgeContext): string {
  const trimmed =
    context.globalContext.length > 1400
      ? context.globalContext.slice(0, 1397) + "..."
      : context.globalContext;
  return trimmed;
}

function buildGeminiPrompt(context: BridgeContext): string {
  return `[System Context — AI Bridge Sync v${context.version}]
${context.globalContext}`;
}

const BUILDERS: Record<LLMTarget["id"], (ctx: BridgeContext) => string> = {
  cursor: buildCursorRules,
  claude: buildClaudeKB,
  chatgpt: buildChatGPTInstructions,
  gemini: buildGeminiPrompt,
};

export function generateTargetConfigs(
  context: BridgeContext
): TargetConfig[] {
  return context.targets
    .filter((t) => t.enabled)
    .map((target) => ({
      targetId: target.id,
      format: target.format,
      content: BUILDERS[target.id](context),
    }));
}
