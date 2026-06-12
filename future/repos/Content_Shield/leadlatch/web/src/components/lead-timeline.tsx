"use client";

import type { LeadEvent } from "@/types/database";

const EVENT_LABELS: Record<string, string> = {
  "lead.created": "Lead created",
  "lead.status_changed": "Status changed",
  "lead.assigned": "Lead assigned",
  note: "Note added",
  "email.sent": "Email sent",
  "email.opened": "Email opened",
  "email.clicked": "Email link clicked",
  "sms.sent": "SMS sent",
  "call.completed": "Call completed",
  "slack.posted": "Slack notification",
  "followup.scheduled": "Follow-up scheduled",
  "followup.sent": "Follow-up sent",
  "automation.error": "Automation error",
};

const SOURCE_COLORS: Record<string, string> = {
  app: "border-blue-300 bg-blue-50",
  n8n: "border-purple-300 bg-purple-50",
  system: "border-gray-300 bg-gray-50",
};

export function LeadTimeline({ events }: { events: LeadEvent[] }) {
  if (events.length === 0) {
    return <p className="mt-2 text-sm text-gray-400">No events yet.</p>;
  }

  return (
    <div className="mt-3 space-y-3">
      {events.map((event) => (
        <div
          key={event.id}
          className={`rounded-lg border-l-4 p-3 ${SOURCE_COLORS[event.source] ?? "border-gray-300 bg-gray-50"}`}
        >
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium">
              {EVENT_LABELS[event.type] ?? event.type}
            </span>
            <span className="text-xs text-gray-400">
              {new Date(event.created_at).toLocaleString()}
            </span>
          </div>
          <div className="mt-1 flex items-center gap-2">
            <span className="rounded bg-gray-200 px-1.5 py-0.5 text-xs text-gray-600">
              {event.source}
            </span>
          </div>
          {event.payload &&
            Object.keys(event.payload).length > 0 &&
            renderPayload(event)}
        </div>
      ))}
    </div>
  );
}

function renderPayload(event: LeadEvent) {
  const payload = event.payload;

  if (event.type === "note" && payload.text) {
    return (
      <p className="mt-2 text-sm text-gray-700">{String(payload.text)}</p>
    );
  }

  if (event.type === "lead.status_changed") {
    return (
      <p className="mt-2 text-sm text-gray-600">
        {String(payload.from ?? "?")} → {String(payload.to ?? "?")}
      </p>
    );
  }

  if (event.type === "email.sent" && payload.subject) {
    return (
      <p className="mt-2 text-sm text-gray-600">
        Subject: {String(payload.subject)}
      </p>
    );
  }

  return (
    <pre className="mt-2 max-h-32 overflow-auto rounded bg-gray-100 p-2 text-xs text-gray-600">
      {JSON.stringify(payload, null, 2)}
    </pre>
  );
}
