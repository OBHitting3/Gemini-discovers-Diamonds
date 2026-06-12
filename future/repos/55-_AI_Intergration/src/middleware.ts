import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

const DASHBOARD_PASSWORD = process.env.DASHBOARD_PASSWORD;
const SESSION_COOKIE = "bridge_session";
const SESSION_VALUE = "authenticated";

// Routes that never require auth
const PUBLIC_PREFIXES = [
  "/api/health",
  "/api/webhooks",
  "/_next",
  "/favicon.ico",
];

function isPublicRoute(pathname: string): boolean {
  return PUBLIC_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

function isAuthenticated(req: NextRequest): boolean {
  const cookie = req.cookies.get(SESSION_COOKIE);
  return cookie?.value === SESSION_VALUE;
}

export function middleware(req: NextRequest): NextResponse {
  // If no password is set, bypass auth entirely
  if (!DASHBOARD_PASSWORD) {
    return NextResponse.next();
  }

  const { pathname } = req.nextUrl;

  if (isPublicRoute(pathname)) {
    return NextResponse.next();
  }

  // Handle login form POST
  if (pathname === "/login" && req.method === "POST") {
    return NextResponse.next();
  }

  // Already authenticated
  if (isAuthenticated(req)) {
    return NextResponse.next();
  }

  // Redirect to login page
  if (pathname !== "/login") {
    const loginUrl = new URL("/login", req.url);
    loginUrl.searchParams.set("from", pathname);
    return NextResponse.redirect(loginUrl);
  }

  return NextResponse.next();
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico).*)",
  ],
};
