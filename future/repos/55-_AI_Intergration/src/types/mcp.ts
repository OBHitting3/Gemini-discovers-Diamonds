export type MCPTransportType = "sse" | "stdio";

export interface MCPTransportSSE {
  type: "sse";
  url: string;
  headers?: Record<string, string>;
}

export interface MCPTransportStdio {
  type: "stdio";
  command: string;
  args: string[];
  env?: Record<string, string>;
}

export type MCPTransport = MCPTransportSSE | MCPTransportStdio;

export interface MCPHealthStatus {
  serverId: string;
  status: "healthy" | "unhealthy" | "timeout";
  latencyMs: number;
  lastChecked: string;
}

export interface MCPServerDefinition {
  id: string;
  name: string;
  transport: MCPTransport;
  tools: string[];
}

export interface HealthResponse {
  overall: "healthy" | "degraded" | "unhealthy";
  servers: MCPHealthStatus[];
  checkedAt: string;
}
