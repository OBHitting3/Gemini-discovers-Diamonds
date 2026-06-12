import { NextRequest, NextResponse } from "next/server";
import { getAuditHistory } from "@/lib/audit-log";

export async function GET(req: NextRequest): Promise<NextResponse> {
  const { searchParams } = new URL(req.url);
  const limitParam = searchParams.get("limit");
  const limit = limitParam ? parseInt(limitParam, 10) : undefined;

  const entries = await getAuditHistory(limit);
  return NextResponse.json(entries);
}
