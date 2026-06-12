"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";
import { OrgSwitcher } from "@/components/org-switcher";

const navItems = [
  { href: "/dashboard", label: "Overview" },
  { href: "/dashboard/leads", label: "Leads" },
  { href: "/dashboard/settings", label: "Settings" },
];

export function DashboardShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();
  const { loading } = useOrg();

  async function handleSignOut() {
    await supabase.auth.signOut();
    router.push("/auth/login");
  }

  if (loading) {
    return (
      <div className="flex min-h-screen items-center justify-center">
        <p className="text-gray-500">Loading...</p>
      </div>
    );
  }

  return (
    <div className="flex min-h-screen">
      <aside className="flex w-56 flex-col border-r border-gray-200 bg-white">
        <div className="border-b border-gray-200 p-4">
          <Link href="/dashboard" className="text-lg font-bold text-blue-600">
            LeadLatch
          </Link>
        </div>
        <div className="border-b border-gray-200 p-3">
          <OrgSwitcher />
        </div>
        <nav className="flex-1 p-2">
          {navItems.map((item) => {
            const isActive =
              item.href === "/dashboard"
                ? pathname === "/dashboard"
                : pathname.startsWith(item.href);
            return (
              <Link
                key={item.href}
                href={item.href}
                className={`block rounded-md px-3 py-2 text-sm font-medium ${
                  isActive
                    ? "bg-blue-50 text-blue-700"
                    : "text-gray-700 hover:bg-gray-100"
                }`}
              >
                {item.label}
              </Link>
            );
          })}
        </nav>
        <div className="border-t border-gray-200 p-3">
          <button
            onClick={handleSignOut}
            className="w-full rounded-md px-3 py-2 text-left text-sm text-gray-600 hover:bg-gray-100"
          >
            Sign Out
          </button>
        </div>
      </aside>
      <main className="flex-1 overflow-auto p-6">{children}</main>
    </div>
  );
}
