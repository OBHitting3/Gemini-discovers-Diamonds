"use client";

import { useEffect, useState, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";
import { LeadTimeline } from "@/components/lead-timeline";
import { LeadNoteForm } from "@/components/lead-note-form";
import type { Lead, LeadEvent, LeadStatus } from "@/types/database";

const ALL_STATUSES: LeadStatus[] = ["new", "working", "won", "lost"];

export default function LeadDetailPage() {
  const params = useParams();
  const router = useRouter();
  const { currentOrg } = useOrg();
  const supabase = createClient();

  const [lead, setLead] = useState<Lead | null>(null);
  const [events, setEvents] = useState<LeadEvent[]>([]);
  const [loading, setLoading] = useState(true);

  const leadId = params.id as string;

  const loadLead = useCallback(async () => {
    if (!currentOrg) return;

    const { data: leadData } = await supabase
      .from("leads")
      .select("*")
      .eq("id", leadId)
      .eq("org_id", currentOrg.id)
      .single();

    if (!leadData) {
      router.push("/dashboard/leads");
      return;
    }

    setLead(leadData as Lead);

    const { data: eventsData } = await supabase
      .from("lead_events")
      .select("*")
      .eq("lead_id", leadId)
      .eq("org_id", currentOrg.id)
      .order("created_at", { ascending: false });

    setEvents((eventsData as LeadEvent[]) ?? []);
    setLoading(false);
  }, [currentOrg, leadId, router, supabase]);

  useEffect(() => {
    loadLead();
  }, [loadLead]);

  async function updateStatus(newStatus: LeadStatus) {
    if (!lead || !currentOrg) return;

    await supabase
      .from("leads")
      .update({ status: newStatus })
      .eq("id", lead.id)
      .eq("org_id", currentOrg.id);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    await supabase.from("lead_events").insert({
      lead_id: lead.id,
      org_id: currentOrg.id,
      type: "lead.status_changed",
      source: "app",
      payload: { from: lead.status, to: newStatus },
      created_by: user?.id ?? null,
      idempotency_key: `status:${lead.id}:${Date.now()}`,
    });

    loadLead();
  }

  if (loading || !lead) {
    return <p className="text-gray-500">Loading...</p>;
  }

  const statusBadge: Record<LeadStatus, string> = {
    new: "bg-blue-100 text-blue-800",
    working: "bg-yellow-100 text-yellow-800",
    won: "bg-green-100 text-green-800",
    lost: "bg-gray-100 text-gray-600",
  };

  return (
    <div className="max-w-4xl">
      <button
        onClick={() => router.push("/dashboard/leads")}
        className="mb-4 text-sm text-gray-500 hover:text-gray-700"
      >
        &larr; Back to Leads
      </button>

      <div className="rounded-lg border border-gray-200 bg-white p-6">
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-2xl font-bold">{lead.name}</h1>
            <span
              className={`mt-1 inline-block rounded-full px-2 py-0.5 text-xs font-medium ${statusBadge[lead.status]}`}
            >
              {lead.status}
            </span>
          </div>
          <select
            value={lead.status}
            onChange={(e) => updateStatus(e.target.value as LeadStatus)}
            className="rounded-lg border border-gray-300 bg-white px-3 py-1.5 text-sm"
          >
            {ALL_STATUSES.map((s) => (
              <option key={s} value={s}>
                {s.charAt(0).toUpperCase() + s.slice(1)}
              </option>
            ))}
          </select>
        </div>

        <div className="mt-4 grid grid-cols-2 gap-4 text-sm">
          <div>
            <span className="text-gray-500">Email:</span>{" "}
            {lead.email ? (
              <a
                href={`mailto:${lead.email}`}
                className="text-blue-600 hover:underline"
              >
                {lead.email}
              </a>
            ) : (
              "—"
            )}
          </div>
          <div>
            <span className="text-gray-500">Phone:</span>{" "}
            {lead.phone ? (
              <a
                href={`tel:${lead.phone}`}
                className="text-blue-600 hover:underline"
              >
                {lead.phone}
              </a>
            ) : (
              "—"
            )}
          </div>
          {lead.source_url && (
            <div>
              <span className="text-gray-500">Source URL:</span>{" "}
              <span className="text-gray-700">{lead.source_url}</span>
            </div>
          )}
          {lead.utm_source && (
            <div>
              <span className="text-gray-500">UTM Source:</span>{" "}
              <span className="text-gray-700">{lead.utm_source}</span>
            </div>
          )}
          {lead.utm_campaign && (
            <div>
              <span className="text-gray-500">UTM Campaign:</span>{" "}
              <span className="text-gray-700">{lead.utm_campaign}</span>
            </div>
          )}
          <div>
            <span className="text-gray-500">Created:</span>{" "}
            <span className="text-gray-700">
              {new Date(lead.created_at).toLocaleString()}
            </span>
          </div>
        </div>

        {lead.message && (
          <div className="mt-4 rounded-md bg-gray-50 p-3 text-sm text-gray-700">
            <span className="font-medium text-gray-500">Message:</span>
            <p className="mt-1">{lead.message}</p>
          </div>
        )}
      </div>

      <div className="mt-6">
        <h2 className="text-lg font-semibold">Add Note</h2>
        <LeadNoteForm leadId={lead.id} onNoteAdded={loadLead} />
      </div>

      <div className="mt-6">
        <h2 className="text-lg font-semibold">Timeline</h2>
        <LeadTimeline events={events} />
      </div>
    </div>
  );
}
