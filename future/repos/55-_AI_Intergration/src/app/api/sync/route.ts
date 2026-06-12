import { NextRequest, NextResponse } from "next/server";
import type { BridgeContext, SyncState } from "@/types/bridge-context";
import { generateTargetConfigs } from "@/lib/bridge-router";
import { validateContextForTargets } from "@/lib/validation";
import { readSyncState, writeSyncState } from "@/lib/sync-state";
import { logAction } from "@/lib/audit-log";

interface SyncResponse {
  success: boolean;
  configVersion: number;
  syncedAt: string;
  targets: Array<{
    id: string;
    status: "synced" | "error";
    error?: string;
  }>;
  validationErrors?: string[];
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const context = body as BridgeContext;

  if (!context.globalContext || !Array.isArray(context.targets)) {
    return NextResponse.json(
      { error: "Missing required fields: globalContext, targets" },
      { status: 400 }
    );
  }

  // Validate before syncing
  const validation = validateContextForTargets(context);
  if (!validation.allValid) {
    const errors = validation.results.flatMap((r) =>
      r.errors.map((e) => `[${r.target}] ${e}`)
    );
    return NextResponse.json(
      { error: "Validation failed", details: errors } satisfies {
        error: string;
        details: string[];
      },
      { status: 422 }
    );
  }

  const currentState = await readSyncState();
  const newVersion = currentState.configVersion + 1;
  const syncedAt = new Date().toISOString();

  // Generate per-target configs
  const configs = generateTargetConfigs({ ...context, version: newVersion });

  const targetResults: SyncResponse["targets"] = configs.map((cfg) => ({
    id: cfg.targetId,
    status: "synced" as const,
  }));

  const newState: SyncState = {
    configVersion: newVersion,
    lastSynced: syncedAt,
    targetStatuses: Object.fromEntries(
      targetResults.map((r) => [r.id, r.status === "synced" ? "synced" : "error"])
    ),
  };

  await writeSyncState(newState);

  await logAction({
    timestamp: syncedAt,
    action: "sync",
    actor: "api",
    target: targetResults.map((r) => r.id).join(","),
    configVersion: newVersion,
  });

  const response: SyncResponse = {
    success: true,
    configVersion: newVersion,
    syncedAt,
    targets: targetResults,
  };

  return NextResponse.json(response);
}

export async function GET(): Promise<NextResponse> {
  const state = await readSyncState();
  return NextResponse.json(state);
}
