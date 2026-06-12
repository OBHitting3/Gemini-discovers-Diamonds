"use client";

import { useEffect, useState, useCallback } from "react";
import type { AuditEntry } from "@/lib/audit-log";
import ConfigDiffViewer from "./config-diff-viewer";

const PAGE_SIZE = 10;

export default function SyncHistory() {
  const [entries, setEntries] = useState<AuditEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedEntry, setSelectedEntry] = useState<AuditEntry | null>(null);

  const fetchHistory = useCallback(async () => {
    try {
      const res = await fetch(`/api/audit?limit=${PAGE_SIZE}`);
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const data = (await res.json()) as AuditEntry[];
      setEntries(data);
      setError(null);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to load history");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchHistory();
  }, [fetchHistory]);

  if (loading) {
    return (
      <div className="text-sm text-gray-400 animate-pulse">
        Loading sync history...
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-sm text-red-400 border border-red-800 rounded p-3">
        {error}
      </div>
    );
  }

  if (entries.length === 0) {
    return (
      <div className="text-sm text-gray-400 border border-gray-700 rounded p-3">
        No sync history yet. Trigger a sync via POST /api/sync.
      </div>
    );
  }

  return (
    <div className="space-y-3">
      <div className="space-y-1">
        {entries.map((entry, idx) => (
          <button
            key={idx}
            onClick={() =>
              setSelectedEntry(selectedEntry === entry ? null : entry)
            }
            className="w-full text-left border border-gray-700 rounded p-3 hover:border-gray-500 transition-colors"
          >
            <div className="flex items-center justify-between text-sm">
              <div className="flex items-center gap-3">
                <span
                  className={`text-xs px-1.5 py-0.5 rounded font-mono ${
                    entry.action === "sync"
                      ? "bg-blue-900 text-blue-200"
                      : "bg-gray-800 text-gray-300"
                  }`}
                >
                  {entry.action}
                </span>
                <span className="text-gray-300">
                  v{entry.configVersion}
                </span>
                <span className="text-gray-400 text-xs">{entry.target}</span>
              </div>
              <span className="text-xs text-gray-500">
                {new Date(entry.timestamp).toLocaleString()}
              </span>
            </div>
          </button>
        ))}
      </div>

      {selectedEntry?.diff && (
        <div className="mt-2">
          <ConfigDiffViewer
            before=""
            after={selectedEntry.diff}
            title={`v${selectedEntry.configVersion} — ${selectedEntry.action}`}
          />
        </div>
      )}
    </div>
  );
}
