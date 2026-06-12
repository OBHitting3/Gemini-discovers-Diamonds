import { NextRequest, NextResponse } from "next/server";
import { createHmac } from "crypto";
import { logAction } from "@/lib/audit-log";

interface AirtableWebhookPayload {
  timestamp: string;
  baseId: string;
  webhookId: string;
  cursor?: number;
}

interface SyncTriggerResult {
  triggered: boolean;
  syncResponse?: unknown;
  error?: string;
}

function verifyAirtableSignature(
  body: string,
  signature: string,
  secret: string
): boolean {
  const hmac = createHmac("sha256", secret)
    .update(body, "utf-8")
    .digest("hex");
  const expected = `hmac-sha256=${hmac}`;
  // Constant-time comparison
  if (expected.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < expected.length; i++) {
    mismatch |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

async function triggerSync(): Promise<SyncTriggerResult> {
  const baseUrl = process.env.NEXTAUTH_URL || "http://localhost:3000";
  try {
    const res = await fetch(`${baseUrl}/api/sync`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        globalContext: process.env.DEFAULT_GLOBAL_CONTEXT || "",
        targets: JSON.parse(process.env.DEFAULT_TARGETS || "[]"),
        version: 0,
        lastSynced: new Date().toISOString(),
      }),
    });
    const data = await res.json();
    return { triggered: true, syncResponse: data };
  } catch (err) {
    return {
      triggered: false,
      error: err instanceof Error ? err.message : "Unknown error",
    };
  }
}

export async function POST(req: NextRequest): Promise<NextResponse> {
  const webhookSecret = process.env.AIRTABLE_WEBHOOK_SECRET;

  const rawBody = await req.text();

  if (webhookSecret) {
    const signature = req.headers.get("x-airtable-content-mac") ?? "";
    if (!verifyAirtableSignature(rawBody, signature, webhookSecret)) {
      return NextResponse.json({ error: "Invalid signature" }, { status: 401 });
    }
  }

  let payload: AirtableWebhookPayload;
  try {
    payload = JSON.parse(rawBody) as AirtableWebhookPayload;
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  await logAction({
    timestamp: new Date().toISOString(),
    action: "airtable-webhook",
    actor: "airtable",
    target: payload.baseId ?? "unknown",
    configVersion: 0,
    diff: JSON.stringify({ cursor: payload.cursor }),
  });

  const syncResult = await triggerSync();

  return NextResponse.json({
    received: true,
    baseId: payload.baseId,
    syncTriggered: syncResult.triggered,
    error: syncResult.error,
  });
}
