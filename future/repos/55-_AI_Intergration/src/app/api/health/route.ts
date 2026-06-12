import { NextResponse } from "next/server";
import { spawn } from "child_process";
import type { MCPHealthStatus, MCPServerDefinition, HealthResponse } from "@/types/mcp";

const MCP_SERVERS: MCPServerDefinition[] = JSON.parse(
  process.env.MCP_SERVERS_JSON || "[]"
);

async function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function pingSSEServer(
  serverId: string,
  url: string,
  headers: Record<string, string> = {}
): Promise<MCPHealthStatus> {
  const startTime = Date.now();
  const BASE_DELAY = 500;
  const MAX_ATTEMPTS = 3;

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    try {
      const controller = new AbortController();
      const timeout = setTimeout(() => controller.abort(), 5000);

      const response = await fetch(url, {
        method: "GET",
        headers: { ...headers, Accept: "text/event-stream" },
        signal: controller.signal,
      });
      clearTimeout(timeout);

      if (response.ok || response.status === 200) {
        return {
          serverId,
          status: "healthy",
          latencyMs: Date.now() - startTime,
          lastChecked: new Date().toISOString(),
        };
      }
    } catch (err) {
      if (attempt < MAX_ATTEMPTS - 1) {
        await sleep(BASE_DELAY * Math.pow(2, attempt));
      } else {
        const isTimeout =
          err instanceof Error && err.name === "AbortError";
        return {
          serverId,
          status: isTimeout ? "timeout" : "unhealthy",
          latencyMs: Date.now() - startTime,
          lastChecked: new Date().toISOString(),
        };
      }
    }
  }

  return {
    serverId,
    status: "unhealthy",
    latencyMs: Date.now() - startTime,
    lastChecked: new Date().toISOString(),
  };
}

async function pingStdioServer(
  serverId: string,
  command: string,
  args: string[],
  env: Record<string, string> = {}
): Promise<MCPHealthStatus> {
  const startTime = Date.now();
  const BASE_DELAY = 500;
  const MAX_ATTEMPTS = 3;

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    try {
      await new Promise<void>((resolve, reject) => {
        const child = spawn(command, [...args, "--version"], {
          env: { ...process.env, ...env },
          timeout: 5000,
          stdio: "pipe",
        });

        child.on("close", (code) => {
          if (code === 0 || code === null) {
            resolve();
          } else {
            reject(new Error(`Process exited with code ${code}`));
          }
        });

        child.on("error", reject);

        setTimeout(() => {
          child.kill();
          reject(new Error("timeout"));
        }, 5000);
      });

      return {
        serverId,
        status: "healthy",
        latencyMs: Date.now() - startTime,
        lastChecked: new Date().toISOString(),
      };
    } catch (err) {
      if (attempt < MAX_ATTEMPTS - 1) {
        await sleep(BASE_DELAY * Math.pow(2, attempt));
      } else {
        const isTimeout =
          err instanceof Error && err.message === "timeout";
        return {
          serverId,
          status: isTimeout ? "timeout" : "unhealthy",
          latencyMs: Date.now() - startTime,
          lastChecked: new Date().toISOString(),
        };
      }
    }
  }

  return {
    serverId,
    status: "unhealthy",
    latencyMs: Date.now() - startTime,
    lastChecked: new Date().toISOString(),
  };
}

export async function GET(): Promise<NextResponse> {
  if (MCP_SERVERS.length === 0) {
    const response: HealthResponse = {
      overall: "healthy",
      servers: [],
      checkedAt: new Date().toISOString(),
    };
    return NextResponse.json(response);
  }

  const checks = MCP_SERVERS.map((server) => {
    if (server.transport.type === "sse") {
      return pingSSEServer(
        server.id,
        server.transport.url,
        server.transport.headers
      );
    } else {
      return pingStdioServer(
        server.id,
        server.transport.command,
        server.transport.args,
        server.transport.env
      );
    }
  });

  const servers = await Promise.all(checks);

  const healthyCount = servers.filter((s) => s.status === "healthy").length;
  const overall: HealthResponse["overall"] =
    healthyCount === servers.length
      ? "healthy"
      : healthyCount === 0
      ? "unhealthy"
      : "degraded";

  const response: HealthResponse = {
    overall,
    servers,
    checkedAt: new Date().toISOString(),
  };

  const statusCode = overall === "unhealthy" ? 503 : 200;
  return NextResponse.json(response, { status: statusCode });
}
