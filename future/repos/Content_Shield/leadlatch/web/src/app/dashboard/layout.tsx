import { redirect } from "next/navigation";
import { createServerSupabase } from "@/lib/supabase/server";
import { OrgProvider } from "@/lib/org-context";
import { DashboardShell } from "@/components/dashboard-shell";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createServerSupabase();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  return (
    <OrgProvider>
      <DashboardShell>{children}</DashboardShell>
    </OrgProvider>
  );
}
