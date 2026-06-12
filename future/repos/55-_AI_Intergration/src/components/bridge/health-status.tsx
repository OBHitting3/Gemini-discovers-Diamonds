"use client";

import { useEffect, useState, useCallback } from "react";
import type { HealthResponse, MCPHealthStatus } from "@/types/mcp";

const REFRESH_INTERVAL_MS = 30_000;

function StatusDot({ status }: { status: MCPHealthStatus["status"] }) {
  const colors: Record<MCPHealthStatus["status"], string> = {
    healthy: "bg-green-500",
    unhealthy: "bg-red-500",
    timeout: "bg-yellow-500",
  };
  return (
    <span
      className={`inline-block w-2.5 h-2.5 rounded-full ${colors[status]}`}
      title={status}
    />
  );
}

export default function HealthStatus() {
  const [data, setData] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [lastFetched, setLastFetched] = useState<Date | null>(null);

  const fetchHealth = useCallback(async () => {
    try {
      const res = await fetch("/api/health");
      const json = (await res.json()) as HealthResponse;
      setData(json);
      setError(null);
      setLastFetched(new Date());
    } catch (err) {
      setError(err instanceof Error ? err.message : "Failed to fetch health");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchHealth();
    const interval = setInterval(() => void fetchHealth(), REFRESH_INTERVAL_MS);
    return () => clearInterval(interval);
  }, [fetchHealth]);

  if (loading) {
    return (
      <div className="text-sm text-gray-400 animate-pulse">
        Checking MCP servers...
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-sm text-red-400 border border-red-800 rounded p-3">
        Health check failed: {error}
      </div>
    );
  }

  if (!data || data.servers.length === 0) {
    return (
      <div className="text-sm text-gray-400 border border-gray-700 rounded p-3">
        No MCP servers configured. Set{" "}
        <code className="text-gray-300">MCP_SERVERS_JSON</code> env var to add
        servers.
      </div>
    );
  }

  const overallColor: Record<HealthResponse["overall"], string> = {
    healthy: "text-green-400",
    degraded: "text-yellow-400",
    unhealthy: "text-red-400",
  };

  return (
    <div className="space-y-3">
      <div className="flex items-center justify-between">
        <span className={`text-sm font-semibold ${overallColor[data.overall]}`}>
          Overall: {data.overall.toUpperCase()}
        </span>
        <div className="text-xs text-gray-500 flex items-center gap-2">
          {lastFetched && (
            <span>Last checked: {lastFetched.toLocaleTimeString()}</span>
          )}
          <button
            onClick={() => void fetchHealth()}
            className="text-blue-400 hover:text-blue-300 underline"
          >
            Refresh
          </button>
        </div>
      </div>

      <div className="space-y-2">
        {data.servers.map((server) => (
          <div
            key={server.serverId}
            className="flex items-center justify-between border border-gray-700 rounded p-3 text-sm"
          >
            <div className="flex items-center gap-2">
              <StatusDot status={server.status} />
              <span className="font-medium text-gray-200">
                {server.serverId}
              </span>
            </div>
            <div className="text-xs text-gray-400 space-x-4">
              <span>{server.latencyMs}ms</span>
              <span>
                {new Date(server.lastChecked).toLocaleTimeString()}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
