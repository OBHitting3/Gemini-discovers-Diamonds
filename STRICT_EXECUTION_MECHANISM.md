# Strict Execution Mechanism

## Purpose

This repository may be worked on by autonomous AI agents. “Strict execution” is a working mode intended to:

- Keep changes tightly scoped to the explicit request.
- Prevent invented details and unverified claims from leaking into outputs.
- Require evidence (from the repo, tooling output, or other accessible sources) before decisions are finalized.
- Make work auditable via concrete artifacts (diffs, commits, and command outputs).

This document is **normative**: it defines how work should be performed, not facts about the outside world.

---

## Definitions

- **Request**: The task statement provided by the user (the `user_query`) plus any follow-up instructions.
- **In-scope**: Any work that is directly required to satisfy the request’s deliverables and acceptance criteria.
- **Out-of-scope**: Any additional refactors, cleanups, new features, formatting churn, or speculative enhancements not required by the request.
- **Verified fact**: Information confirmed by (a) repository contents, (b) tool output (tests, lints, commands), or (c) explicitly provided user context.

---

## Core Rules

### 1) Scope control (no scope creep)

- Implement **only** what the request requires.
- Prefer the smallest change that satisfies the request.
- Avoid “drive-by” refactors, renames, or formatting-only changes unless they are necessary to complete the request.

### 2) Verification-first (no fabrication)

- Do not assert facts about the codebase until the relevant files have been inspected.
- Do not claim tests pass unless they were actually executed and passed.
- If required information cannot be verified in the environment, state the limitation and proceed with the smallest safe action that still meets the request.

### 3) Tool-grounded work

- Use repository search and file reads before making edits.
- When changes are made, prefer local verification (tests/lint/build) when available.
- Avoid long-lived processes (watch mode/dev servers) in automated environments.

### 4) Reproducible, auditable outputs

- Every meaningful change must be represented by:
  - A clear diff (tracked in git),
  - A descriptive commit message,
  - And a push to the correct feature branch.

---

## Strict Execution Workflow

### Step A — Parse the request

Extract and write down:

- **Deliverable(s)** (files/features to create/change)
- **Constraints** (branch, tooling constraints, test expectations)
- **Acceptance criteria** (what “done” means)

If the request is underspecified, the agent should:

- Search the repo for conventions, prior work, or related branches/PRs.
- Choose the smallest, most consistent deliverable aligned with existing patterns.
- Explicitly document any assumptions in the final summary (and keep them minimal).

### Step B — Investigate (repo-first)

Minimum investigation before editing:

- Check repository structure.
- Search for related symbols/filenames/keywords.
- Read any relevant files (docs, config, source, tests).

### Step C — Implement minimal change

Implementation rules:

- Keep edits narrowly targeted.
- Do not introduce dependencies unless required.
- Prefer documentation additions when the request is about process/policy rather than runtime behavior.

### Step D — Verify

Verification rules:

- Run existing tests/lint/build if present and applicable.
- If no test/lint framework exists, verify by ensuring:
  - Files are added in the intended location(s),
  - Naming matches repository conventions,
  - Markdown renders reasonably (headings, code fences, links).

### Step E — Commit + push

Git rules:

- Commit logical units of work with descriptive messages.
- Push to the designated feature branch only (no force-push unless explicitly requested).

### Step F — Report completion

Final report should include:

- What was created/changed (file paths).
- Any verification performed (commands run, results).
- Any required follow-ups (only if necessary to complete the request, not “nice to have”).

---

## Decision Logging (Audit Trail)

To keep work auditable without adding extra files:

- Put the “why” in commit messages (briefly).
- In the final summary, list:
  - Key decisions made,
  - Evidence used (e.g., “repo had only README.md; prior branches used doc-only additions”),
  - Any constraints encountered (e.g., missing CI/tests, permission limits).

---

## Safety & Compliance

- Do not add or request secrets in code or docs.
- Do not implement harmful or illegal functionality.
- When a task touches security-sensitive areas (auth, cryptography, payments), require verification via tests and/or minimal, well-scoped changes.

---

## Version History

- **2026-02-15**: Initial strict execution mechanism document added.

