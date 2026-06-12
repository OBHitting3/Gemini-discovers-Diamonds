"use client";

import { useEffect, useState, useCallback } from "react";
import Link from "next/link";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";
import type { Lead, LeadStatus } from "@/types/database";

const ALL_STATUSES: LeadStatus[] = ["new", "working", "won", "lost"];

export default function LeadsPage() {
  const { currentOrg } = useOrg();
  const [leads, setLeads] = useState<Lead[]>([]);
  const [statusFilter, setStatusFilter] = useState<LeadStatus | "all">("all");
  const [search, setSearch] = useState("");
  const [loading, setLoading] = useState(true);
  const supabase = createClient();

  const loadLeads = useCallback(async () => {
    if (!currentOrg) return;
    setLoading(true);

    let query = supabase
      .from("leads")
      .select("*")
      .eq("org_id", currentOrg.id)
      .order("created_at", { ascending: false })
      .limit(100);

    if (statusFilter !== "all") {
      query = query.eq("status", statusFilter);
    }

    if (search.trim()) {
      query = query.or(
        `name.ilike.%${search}%,email.ilike.%${search}%,phone.ilike.%${search}%`
      );
    }

    const { data } = await query;
    setLeads((data as Lead[]) ?? []);
    setLoading(false);
  }, [currentOrg, statusFilter, search, supabase]);

  useEffect(() => {
    loadLeads();
  }, [loadLeads]);

  if (!currentOrg) {
    return <p className="text-gray-500">Select an organization first.</p>;
  }

  const statusBadge: Record<LeadStatus, string> = {
    new: "bg-blue-100 text-blue-800",
    working: "bg-yellow-100 text-yellow-800",
    won: "bg-green-100 text-green-800",
    lost: "bg-gray-100 text-gray-600",
  };

  return (
    <div>
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Leads</h1>
      </div>

      <div className="mt-4 flex flex-wrap gap-3">
        <input
          type="text"
          placeholder="Search name, email, phone..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          className="rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
        />
        <select
          value={statusFilter}
          onChange={(e) =>
            setStatusFilter(e.target.value as LeadStatus | "all")
          }
          className="rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
        >
          <option value="all">All Statuses</option>
          {ALL_STATUSES.map((s) => (
            <option key={s} value={s}>
              {s.charAt(0).toUpperCase() + s.slice(1)}
            </option>
          ))}
        </select>
      </div>

      <div className="mt-4 overflow-x-auto rounded-lg border border-gray-200 bg-white">
        {loading ? (
          <p className="p-4 text-sm text-gray-500">Loading...</p>
        ) : leads.length === 0 ? (
          <p className="p-4 text-sm text-gray-500">No leads found.</p>
        ) : (
          <table className="w-full text-left text-sm">
            <thead className="border-b border-gray-200 bg-gray-50">
              <tr>
                <th className="px-4 py-3 font-medium">Name</th>
                <th className="px-4 py-3 font-medium">Email</th>
                <th className="px-4 py-3 font-medium">Phone</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium">Source</th>
                <th className="px-4 py-3 font-medium">Created</th>
              </tr>
            </thead>
            <tbody>
              {leads.map((lead) => (
                <tr
                  key={lead.id}
                  className="border-b border-gray-100 hover:bg-gray-50"
                >
                  <td className="px-4 py-3">
                    <Link
                      href={`/dashboard/leads/${lead.id}`}
                      className="font-medium text-blue-600 hover:underline"
                    >
                      {lead.name}
                    </Link>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {lead.email ?? "—"}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {lead.phone ?? "—"}
                  </td>
                  <td className="px-4 py-3">
                    <span
                      className={`inline-block rounded-full px-2 py-0.5 text-xs font-medium ${statusBadge[lead.status]}`}
                    >
                      {lead.status}
                    </span>
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {lead.utm_source ?? "—"}
                  </td>
                  <td className="px-4 py-3 text-gray-600">
                    {new Date(lead.created_at).toLocaleDateString()}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
