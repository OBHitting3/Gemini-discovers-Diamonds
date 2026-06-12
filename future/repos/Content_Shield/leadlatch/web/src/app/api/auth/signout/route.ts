import { NextResponse } from "next/server";
import { createServerSupabase } from "@/lib/supabase/server";

export async function POST() {
  const supabase = await createServerSupabase();
  await supabase.auth.signOut();
  return NextResponse.redirect(new URL("/auth/login", process.env.NEXT_PUBLIC_APP_URL || "http://localhost:3000"));
}
