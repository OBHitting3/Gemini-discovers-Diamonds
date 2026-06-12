import { readFile, writeFile, mkdir } from "fs/promises";
import { join } from "path";
import { existsSync } from "fs";
import type { SyncState } from "@/types/bridge-context";

const DATA_DIR = join(process.cwd(), "src", "data");
const SYNC_STATE_PATH = join(DATA_DIR, "sync-state.json");

async function ensureDataDir(): Promise<void> {
  if (!existsSync(DATA_DIR)) {
    await mkdir(DATA_DIR, { recursive: true });
  }
}

const DEFAULT_STATE: SyncState = {
  configVersion: 0,
  lastSynced: "",
  targetStatuses: {},
};

export async function readSyncState(): Promise<SyncState> {
  await ensureDataDir();
  try {
    const raw = await readFile(SYNC_STATE_PATH, "utf-8");
    return JSON.parse(raw) as SyncState;
  } catch {
    return { ...DEFAULT_STATE };
  }
}

export async function writeSyncState(state: SyncState): Promise<void> {
  await ensureDataDir();
  await writeFile(SYNC_STATE_PATH, JSON.stringify(state, null, 2), "utf-8");
}
