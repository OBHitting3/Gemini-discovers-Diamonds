// LeadLatch — Edge Function: lead-intake
// Public endpoint for form submissions. Inserts lead + event, fires n8n webhook.
// Deploy: supabase functions deploy lead-intake

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization, x-org-id",
};

interface LeadPayload {
  name: string;
  email?: string;
  phone?: string;
  message?: string;
  source_url?: string;
  utm_source?: string;
  utm_medium?: string;
  utm_campaign?: string;
  utm_term?: string;
  utm_content?: string;
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
    const orgId = req.headers.get("x-org-id");
    if (!orgId) {
      return new Response(
        JSON.stringify({ error: "Missing x-org-id header" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const body: LeadPayload = await req.json();

    if (!body.name || typeof body.name !== "string" || body.name.trim() === "") {
      return new Response(
        JSON.stringify({ error: "name is required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const n8nWebhookUrl = Deno.env.get("N8N_WEBHOOK_URL");

    const supabase = createClient(supabaseUrl, serviceRoleKey);

    // Verify the org exists
    const { data: org, error: orgError } = await supabase
      .from("organizations")
      .select("id")
      .eq("id", orgId)
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

    // Insert the lead
    const { data: lead, error: leadError } = await supabase
      .from("leads")
      .insert({
        org_id: orgId,
        name: body.name.trim(),
        email: body.email?.trim() || null,
        phone: body.phone?.trim() || null,
        message: body.message?.trim() || null,
        source_url: body.source_url || null,
        utm_source: body.utm_source || null,
        utm_medium: body.utm_medium || null,
        utm_campaign: body.utm_campaign || null,
        utm_term: body.utm_term || null,
        utm_content: body.utm_content || null,
        status: "new",
      })
      .select("id, created_at")
      .single();

    if (leadError) {
      console.error("Lead insert error:", leadError);
      return new Response(
        JSON.stringify({ error: "Failed to create lead" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Record the lead.created event
    const { error: eventError } = await supabase.from("lead_events").insert({
      lead_id: lead.id,
      org_id: orgId,
      type: "lead.created",
      source: "system",
      payload: {
        name: body.name,
        email: body.email || null,
        phone: body.phone || null,
        source_url: body.source_url || null,
      },
      idempotency_key: `lead.created:${lead.id}`,
    });

    if (eventError) {
      console.error("Event insert error:", eventError);
    }

    // Fire n8n webhook (non-blocking)
    if (n8nWebhookUrl) {
      const webhookPayload = {
        lead_id: lead.id,
        org_id: orgId,
        name: body.name,
        email: body.email || null,
        phone: body.phone || null,
        message: body.message || null,
        source_url: body.source_url || null,
        utm_source: body.utm_source || null,
        utm_medium: body.utm_medium || null,
        utm_campaign: body.utm_campaign || null,
        created_at: lead.created_at,
      };

      // Fire and forget — don't block the response
      fetch(n8nWebhookUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(webhookPayload),
      }).catch((err) => {
        console.error("n8n webhook error:", err);
      });
    }

    return new Response(
      JSON.stringify({ ok: true, lead_id: lead.id }),
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
