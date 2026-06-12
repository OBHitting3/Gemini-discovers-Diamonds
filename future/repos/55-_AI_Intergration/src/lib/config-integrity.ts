import { createHash } from "crypto";
import { readFile, readdir, writeFile } from "fs/promises";
import { join } from "path";

export interface ConfigManifest {
  version: number;
  generatedAt: string;
  hashes: Record<string, string>;
}

export interface IntegrityReport {
  valid: boolean;
  checkedAt: string;
  results: Array<{
    file: string;
    status: "ok" | "modified" | "missing";
    expected?: string;
    actual?: string;
  }>;
}

export interface SecretScanResult {
  file: string;
  line: number;
  match: string;
  pattern: string;
}

const SECRET_PATTERNS: Array<{ name: string; regex: RegExp }> = [
  { name: "AWS Access Key", regex: /AKIA[0-9A-Z]{16}/g },
  { name: "AWS Secret Key", regex: /(?i:aws.{0,20}secret.{0,20})['"=:\s]+([A-Za-z0-9/+=]{40})/g },
  { name: "Generic API Key", regex: /(?i:api[_-]?key)['"=:\s]+['"]([A-Za-z0-9_\-]{20,})['"]/g },
  { name: "Bearer Token", regex: /bearer\s+[A-Za-z0-9\-._~+/]+=*/gi },
  { name: "Generic Password", regex: /(?i:password)['"=:\s]+['"]([^'"]{8,})['"]/g },
  { name: "Generic Token", regex: /(?i:token)['"=:\s]+['"]([A-Za-z0-9_\-]{20,})['"]/g },
  { name: "Private Key Header", regex: /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/g },
  { name: "Slack Token", regex: /xox[baprs]-[A-Za-z0-9-]+/g },
  { name: "GitHub Token", regex: /ghp_[A-Za-z0-9]{36}/g },
  { name: "OpenAI Key", regex: /sk-[A-Za-z0-9]{48}/g },
  { name: "Anthropic Key", regex: /sk-ant-[A-Za-z0-9\-]{90,}/g },
];

async function hashFile(filePath: string): Promise<string> {
  const content = await readFile(filePath, "utf-8");
  return createHash("sha256").update(content).digest("hex");
}

export async function signConfigManifest(
  configDir: string
): Promise<ConfigManifest> {
  const entries = await readdir(configDir);
  const jsonFiles = entries.filter((f) => f.endsWith(".json"));

  const hashes: Record<string, string> = {};
  for (const file of jsonFiles) {
    const filePath = join(configDir, file);
    hashes[file] = await hashFile(filePath);
  }

  const manifest: ConfigManifest = {
    version: 1,
    generatedAt: new Date().toISOString(),
    hashes,
  };

  const manifestPath = join(configDir, "manifest.json");
  await writeFile(manifestPath, JSON.stringify(manifest, null, 2), "utf-8");

  return manifest;
}

export async function verifyConfigIntegrity(
  configDir: string,
  manifest: ConfigManifest
): Promise<IntegrityReport> {
  const results: IntegrityReport["results"] = [];

  for (const [file, expectedHash] of Object.entries(manifest.hashes)) {
    const filePath = join(configDir, file);
    try {
      const actualHash = await hashFile(filePath);
      results.push({
        file,
        status: actualHash === expectedHash ? "ok" : "modified",
        expected: expectedHash,
        actual: actualHash,
      });
    } catch {
      results.push({
        file,
        status: "missing",
        expected: expectedHash,
      });
    }
  }

  return {
    valid: results.every((r) => r.status === "ok"),
    checkedAt: new Date().toISOString(),
    results,
  };
}

export async function detectInlineSecrets(
  configPath: string
): Promise<SecretScanResult[]> {
  const content = await readFile(configPath, "utf-8");
  const lines = content.split("\n");
  const findings: SecretScanResult[] = [];

  lines.forEach((line, idx) => {
    for (const { name, regex } of SECRET_PATTERNS) {
      const freshRegex = new RegExp(regex.source, regex.flags.replace("g", "") + "g");
      let match: RegExpExecArray | null;
      while ((match = freshRegex.exec(line)) !== null) {
        findings.push({
          file: configPath,
          line: idx + 1,
          match: match[0].slice(0, 20) + "...[REDACTED]",
          pattern: name,
        });
      }
    }
  });

  return findings;
}
