const fs = require("fs");
const path = require("path");

const root = path.resolve(__dirname);
const manifestPath = path.join(root, "manifest.json");
const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
const failures = [];

if (manifest.name !== "future") {
  failures.push('manifest.name must be "future"');
}

if (!Array.isArray(manifest.repositories) || manifest.repositories.length === 0) {
  failures.push("manifest.repositories must list imported repositories");
}

function walk(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (!entry.isDirectory()) {
      continue;
    }

    if (entry.name === ".git") {
      failures.push(`nested Git metadata found at ${path.relative(root, fullPath)}`);
      continue;
    }

    walk(fullPath);
  }
}

walk(root);

for (const repo of manifest.repositories) {
  const repoPath = path.resolve(path.dirname(root), repo.path);

  if (!repo.fullName) {
    failures.push(`repository entry is missing fullName: ${JSON.stringify(repo)}`);
  }

  if (!repo.importStatus || repo.importStatus === "failed") {
    failures.push(`${repo.fullName || repo.name} has invalid importStatus ${repo.importStatus}`);
  }

  if (!fs.existsSync(repoPath)) {
    failures.push(`${repo.fullName} path is missing: ${repo.path}`);
  }

  if (repo.importStatus !== "empty-no-default-branch" && !repo.importedFileCount) {
    failures.push(`${repo.fullName} must include imported files`);
  }
}

if (failures.length > 0) {
  console.error(failures.join("\n"));
  process.exit(1);
}

console.log(`future manifest is valid: ${manifest.repositories.length} repositories imported.`);
