"use client";

import { useEffect, useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";
import type { LeadStatus } from "@/types/database";

interface StatusCount {
  status: LeadStatus;
  count: number;
}

export default function DashboardOverview() {
  const { currentOrg } = useOrg();
  const [counts, setCounts] = useState<StatusCount[]>([]);
  const [totalLeads, setTotalLeads] = useState(0);
  const supabase = createClient();

  useEffect(() => {
    if (!currentOrg) return;

    async function loadStats() {
      const { count } = await supabase
        .from("leads")
        .select("*", { count: "exact", head: true })
        .eq("org_id", currentOrg!.id);

      setTotalLeads(count ?? 0);

      const statuses: LeadStatus[] = ["new", "working", "won", "lost"];
      const statusCounts: StatusCount[] = [];

      for (const status of statuses) {
        const { count: c } = await supabase
          .from("leads")
          .select("*", { count: "exact", head: true })
          .eq("org_id", currentOrg!.id)
          .eq("status", status);
        statusCounts.push({ status, count: c ?? 0 });
      }

      setCounts(statusCounts);
    }

    loadStats();
  }, [currentOrg, supabase]);

  if (!currentOrg) {
    return <SetupPrompt />;
  }

  const statusColors: Record<LeadStatus, string> = {
    new: "bg-blue-100 text-blue-800",
    working: "bg-yellow-100 text-yellow-800",
    won: "bg-green-100 text-green-800",
    lost: "bg-gray-100 text-gray-600",
  };

  return (
    <div>
      <h1 className="text-2xl font-bold">Dashboard</h1>
      <p className="mt-1 text-sm text-gray-500">{currentOrg.name}</p>

      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-4">
        <div className="rounded-lg border border-gray-200 bg-white p-4">
          <p className="text-sm text-gray-500">Total Leads</p>
          <p className="mt-1 text-3xl font-bold">{totalLeads}</p>
        </div>
        {counts.map((item) => (
          <div
            key={item.status}
            className="rounded-lg border border-gray-200 bg-white p-4"
          >
            <p className="text-sm text-gray-500 capitalize">{item.status}</p>
            <p className="mt-1 text-3xl font-bold">{item.count}</p>
            <span
              className={`mt-2 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${statusColors[item.status]}`}
            >
              {item.status}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

function SetupPrompt() {
  return (
    <div className="flex min-h-[50vh] items-center justify-center">
      <div className="text-center">
        <h2 className="text-xl font-semibold">Welcome to LeadLatch</h2>
        <p className="mt-2 text-gray-500">
          Create your first organization in Settings to get started.
        </p>
      </div>
    </div>
  );
}
