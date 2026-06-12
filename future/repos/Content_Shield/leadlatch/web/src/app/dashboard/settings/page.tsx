"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";
import { useOrg } from "@/lib/org-context";
import type { AutomationRule } from "@/types/database";

export default function SettingsPage() {
  const { currentOrg, currentRole } = useOrg();

  return (
    <div className="max-w-2xl space-y-8">
      <h1 className="text-2xl font-bold">Settings</h1>

      <CreateOrgSection />

      {currentOrg && (
        <>
          <OrgInfoSection />
          <WebhookSection />
          {(currentRole === "owner" || currentRole === "admin") && (
            <InviteMemberSection />
          )}
        </>
      )}
    </div>
  );
}

function CreateOrgSection() {
  const [name, setName] = useState("");
  const [creating, setCreating] = useState(false);
  const [message, setMessage] = useState("");
  const supabase = createClient();

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;

    setCreating(true);
    setMessage("");

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setMessage("Not authenticated");
      setCreating(false);
      return;
    }

    const slug = name
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-|-$/g, "");

    const { data: org, error: orgError } = await supabase
      .from("organizations")
      .insert({ name: name.trim(), slug })
      .select("id")
      .single();

    if (orgError) {
      setMessage(`Error: ${orgError.message}`);
      setCreating(false);
      return;
    }

    const { error: memberError } = await supabase.from("memberships").insert({
      user_id: user.id,
      org_id: org.id,
      role: "owner",
    });

    if (memberError) {
      setMessage(`Org created, but failed to set owner: ${memberError.message}`);
    } else {
      setMessage("Organization created! Reload the page to switch to it.");
      setName("");
    }

    setCreating(false);
  }

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-6">
      <h2 className="text-lg font-semibold">Create Organization</h2>
      <form onSubmit={handleCreate} className="mt-3 flex gap-2">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Organization name"
          className="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm"
          required
        />
        <button
          type="submit"
          disabled={creating}
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700 disabled:opacity-50"
        >
          {creating ? "Creating..." : "Create"}
        </button>
      </form>
      {message && (
        <p className="mt-2 text-sm text-gray-600">{message}</p>
      )}
    </section>
  );
}

function OrgInfoSection() {
  const { currentOrg, currentRole } = useOrg();

  if (!currentOrg) return null;

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-6">
      <h2 className="text-lg font-semibold">Organization</h2>
      <div className="mt-3 space-y-2 text-sm">
        <p>
          <span className="text-gray-500">Name:</span> {currentOrg.name}
        </p>
        <p>
          <span className="text-gray-500">Slug:</span> {currentOrg.slug}
        </p>
        <p>
          <span className="text-gray-500">Your Role:</span>{" "}
          <span className="capitalize">{currentRole}</span>
        </p>
        <p>
          <span className="text-gray-500">Org ID:</span>{" "}
          <code className="rounded bg-gray-100 px-1 py-0.5 text-xs">
            {currentOrg.id}
          </code>
        </p>
      </div>
    </section>
  );
}

function WebhookSection() {
  const { currentOrg } = useOrg();
  const [showSecret, setShowSecret] = useState(false);

  if (!currentOrg) return null;

  const intakeUrl = `${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/lead-intake`;

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-6">
      <h2 className="text-lg font-semibold">Lead Intake Endpoint</h2>
      <div className="mt-3 space-y-3 text-sm">
        <div>
          <span className="text-gray-500">URL:</span>
          <code className="ml-2 block rounded bg-gray-100 p-2 text-xs">
            POST {intakeUrl}
          </code>
        </div>
        <div>
          <span className="text-gray-500">Required Header:</span>
          <code className="ml-2 block rounded bg-gray-100 p-2 text-xs">
            x-org-id: {currentOrg.id}
          </code>
        </div>
        <div>
          <span className="text-gray-500">Webhook Secret (for n8n):</span>
          <div className="mt-1 flex items-center gap-2">
            <code className="flex-1 rounded bg-gray-100 p-2 text-xs">
              {showSecret ? currentOrg.webhook_secret : "••••••••••••••••"}
            </code>
            <button
              onClick={() => setShowSecret(!showSecret)}
              className="text-xs text-blue-600 hover:underline"
            >
              {showSecret ? "Hide" : "Reveal"}
            </button>
          </div>
        </div>
        <div>
          <span className="text-gray-500">Example cURL:</span>
          <pre className="mt-1 overflow-auto rounded bg-gray-100 p-2 text-xs">
{`curl -X POST ${intakeUrl} \\
  -H "Content-Type: application/json" \\
  -H "x-org-id: ${currentOrg.id}" \\
  -d '{"name":"Jane Doe","email":"jane@example.com","phone":"+15551234567","message":"Interested in your service","source_url":"https://example.com/landing","utm_source":"google"}'`}
          </pre>
        </div>
      </div>
    </section>
  );
}

function InviteMemberSection() {
  const { currentOrg } = useOrg();
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");
  const supabase = createClient();

  if (!currentOrg) return null;

  async function handleInvite(e: React.FormEvent) {
    e.preventDefault();
    setMessage(
      "Invitation flow: In production, send an invite email with a signup link that auto-joins the org. For MVP, have the user sign up and manually add them via the memberships table."
    );
    setEmail("");
  }

  return (
    <section className="rounded-lg border border-gray-200 bg-white p-6">
      <h2 className="text-lg font-semibold">Invite Member</h2>
      <form onSubmit={handleInvite} className="mt-3 flex gap-2">
        <input
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="member@example.com"
          className="flex-1 rounded-lg border border-gray-300 px-3 py-2 text-sm"
          required
        />
        <button
          type="submit"
          className="rounded-lg bg-blue-600 px-4 py-2 text-sm font-medium text-white hover:bg-blue-700"
        >
          Invite
        </button>
      </form>
      {message && (
        <p className="mt-2 text-sm text-gray-500">{message}</p>
      )}
    </section>
  );
}
