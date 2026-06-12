// LeadLatch — Edge Function: n8n-event-ingest
// Secured endpoint for n8n to append lead_events and update lead status.
// Auth: Bearer token must match the org's webhook_secret.
// Deploy: supabase functions deploy n8n-event-ingest

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

const VALID_EVENT_TYPES = [
  "email.sent",
  "email.opened",
  "email.clicked",
  "sms.sent",
  "call.completed",
  "slack.posted",
  "followup.scheduled",
  "followup.sent",
  "automation.error",
  "lead.status_changed",
];

const VALID_STATUSES = ["new", "working", "won", "lost"];

interface EventPayload {
  lead_id: string;
  org_id: string;
  type: string;
  payload?: Record<string, unknown>;
  idempotency_key: string;
  new_status?: string;
}

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Extract Bearer token
    const authHeader = req.headers.get("Authorization");
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return new Response(
        JSON.stringify({ error: "Missing or invalid Authorization header" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }
    const token = authHeader.replace("Bearer ", "");

    const body: EventPayload = await req.json();

    // Validate required fields
    if (!body.lead_id || !body.org_id || !body.type || !body.idempotency_key) {
      return new Response(
        JSON.stringify({
          error: "lead_id, org_id, type, and idempotency_key are required",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!VALID_EVENT_TYPES.includes(body.type)) {
      return new Response(
        JSON.stringify({
          error: `Invalid event type. Must be one of: ${VALID_EVENT_TYPES.join(", ")}`,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify the org exists and the token matches webhook_secret
    const { data: org, error: orgError } = await supabase
      .from("organizations")
      .select("id, webhook_secret")
      .eq("id", body.org_id)
      .single();

    if (orgError || !org) {
      return new Response(
        JSON.stringify({ error: "Organization not found" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (org.webhook_secret !== token) {
      return new Response(JSON.stringify({ error: "Invalid token" }), {
        status: 403,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify the lead belongs to the org
    const { data: lead, error: leadError } = await supabase
      .from("leads")
      .select("id")
      .eq("id", body.lead_id)
      .eq("org_id", body.org_id)
      .single();

    if (leadError || !lead) {
      return new Response(
        JSON.stringify({ error: "Lead not found in this organization" }),
        {
          status: 404,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Insert the event (idempotency via unique constraint — ON CONFLICT DO NOTHING)
    const { error: eventError } = await supabase.rpc("insert_lead_event_idempotent", {
      p_lead_id: body.lead_id,
      p_org_id: body.org_id,
      p_type: body.type,
      p_source: "n8n",
      p_payload: body.payload || {},
      p_idempotency_key: body.idempotency_key,
    });

    if (eventError) {
      console.error("Event insert error:", eventError);
      // If it's a unique violation, that's actually fine (idempotent)
      if (eventError.code === "23505") {
        return new Response(
          JSON.stringify({ ok: true, deduplicated: true }),
          {
            status: 200,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      return new Response(
        JSON.stringify({ error: "Failed to insert event" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Optionally update lead status
    if (body.new_status && VALID_STATUSES.includes(body.new_status)) {
      const { error: updateError } = await supabase
        .from("leads")
        .update({ status: body.new_status })
        .eq("id", body.lead_id)
        .eq("org_id", body.org_id);

      if (updateError) {
        console.error("Lead status update error:", updateError);
      }
    }

    return new Response(
      JSON.stringify({ ok: true }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Unhandled error:", err);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});
