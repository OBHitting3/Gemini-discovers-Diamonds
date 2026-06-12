"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";

interface LeadNoteFormProps {
  leadId: string;
  onNoteAdded: () => void;
}

export function LeadNoteForm({ leadId, onNoteAdded }: LeadNoteFormProps) {
  const [text, setText] = useState("");
  const [saving, setSaving] = useState(false);
  const { currentOrg } = useOrg();
  const supabase = createClient();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!text.trim() || !currentOrg) return;

    setSaving(true);

    const {
      data: { user },
    } = await supabase.auth.getUser();

    await supabase.from("lead_events").insert({
      lead_id: leadId,
      org_id: currentOrg.id,
      type: "note",
      source: "app",
      payload: { text: text.trim() },
      created_by: user?.id ?? null,
    });

    setText("");
    setSaving(false);
    onNoteAdded();
  }

  return (
    <form onSubmit={handleSubmit} className="mt-2 flex gap-2">
      <input
        type="text"
        value={text}
        onChange={(e) => setText(e.target.value)}
        placeholder="Type a note..."
        className="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-blue-500 focus:ring-1 focus:ring-blue-500"
      />
      <button
        type="submit"
        disabled={saving || !text.trim()}
        className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
      >
        {saving ? "..." : "Add"}
      </button>
    </form>
  );
}
