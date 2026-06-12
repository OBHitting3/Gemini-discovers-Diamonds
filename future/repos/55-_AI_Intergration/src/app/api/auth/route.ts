import { NextRequest, NextResponse } from "next/server";

const DASHBOARD_PASSWORD = process.env.DASHBOARD_PASSWORD;
const SESSION_COOKIE = "bridge_session";

export async function POST(req: NextRequest): Promise<NextResponse> {
  if (!DASHBOARD_PASSWORD) {
    return NextResponse.json({ error: "Auth not configured" }, { status: 400 });
  }

  let body: { password?: string };
  try {
    body = (await req.json()) as { password?: string };
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  if (body.password !== DASHBOARD_PASSWORD) {
    return NextResponse.json({ error: "Invalid password" }, { status: 401 });
  }

  const response = NextResponse.json({ ok: true });
  response.cookies.set(SESSION_COOKIE, "authenticated", {
    httpOnly: true,
    secure: process.env.NODE_ENV === "production",
    sameSite: "lax",
    maxAge: 60 * 60 * 24, // 24 hours
    path: "/",
  });
  return response;
}

export async function DELETE(): Promise<NextResponse> {
  const response = NextResponse.json({ ok: true });
  response.cookies.delete(SESSION_COOKIE);
  return response;
}
