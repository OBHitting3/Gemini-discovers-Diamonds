import { readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";
import { existsSync } from "fs";

export interface AuditEntry {
  timestamp: string;
  action: string;
  actor: string;
  target: string;
  configVersion: number;
  diff?: string;
}

const DATA_DIR = join(process.cwd(), "src", "data");
const AUDIT_LOG_PATH = join(DATA_DIR, "audit-log.json");

async function ensureDataDir(): Promise<void> {
  if (!existsSync(DATA_DIR)) {
    await mkdir(DATA_DIR, { recursive: true });
  }
}

async function readLog(): Promise<AuditEntry[]> {
  await ensureDataDir();
  try {
    const raw = await readFile(AUDIT_LOG_PATH, "utf-8");
    return JSON.parse(raw) as AuditEntry[];
  } catch {
    return [];
  }
}

export async function logAction(entry: AuditEntry): Promise<void> {
  await ensureDataDir();
  const entries = await readLog();
  entries.push(entry);
  await writeFile(AUDIT_LOG_PATH, JSON.stringify(entries, null, 2), "utf-8");
}

export async function getAuditHistory(limit?: number): Promise<AuditEntry[]> {
  const entries = await readLog();
  const sorted = entries.sort(
    (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
  );
  return limit ? sorted.slice(0, limit) : sorted;
}
