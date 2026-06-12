# AGENT-A-REPORT — Joshua 7 / Content Shield Hardening

**Agent:** A
**Date:** 2026-02-18
**Branch:** `cursor/full-mvp-codebase-9c12`
**Method:** Tree-of-Thought + Red Team + ASCoT + Beam Search (6-phase)
**Tests:** 73 passing (up from 48) | Lint: clean (ruff)

---

## Executive Summary

The original MVP codebase was functional but had **critical security vulnerabilities**, **logic bugs that caused false negatives**, and **UX gaps** that would frustrate real users. This report documents every finding and every fix.

---

## Phase 1 — Forward Read Findings (26 issues identified)

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | **CRITICAL** | `validators/pii.py` | Raw PII values (emails, SSNs, phones) echoed in API responses via `metadata["value"]` |
| 2 | HIGH | `models.py` | No `max_length` on `ValidationRequest.text` — memory exhaustion DoS possible |
| 3 | HIGH | `api/main.py` | No CORS middleware — frontend consumers blocked |
| 4 | HIGH | `api/routes.py` | No request ID for tracing/audit |
| 5 | HIGH | `validators/brand_voice.py` | `lower.count(pw)` does substring matching — "bro" matches "broken", "browser" |
| 6 | HIGH | `validators/brand_voice.py` | `"yo "` has trailing space — matches "your", "young" via substring |
| 7 | MEDIUM | `api/routes.py` | `_get_engine()` rebuilds `ValidationEngine` on every HTTP request |
| 8 | MEDIUM | `validators/prompt_injection.py` | `prompt_injection_threshold` config read but never used (dead code) |
| 9 | MEDIUM | `engine.py` | No try/except around `validator.validate()` — one crash kills entire request |
| 10 | MEDIUM | `models.py` | No `request_id`, `timestamp`, or `version` in response |
| 11 | MEDIUM | `cli/main.py` | No `--stdin` support for piped input |
| 12 | MEDIUM | `cli/main.py` | `--host/-h` conflicts with Typer's `--help/-h` |
| 13 | MEDIUM | `cli/main.py` | Error messages are bare — no usage examples |
| 14 | MEDIUM | `config.py` | `model_config = {"env_prefix": "J7_"}` — should use `SettingsConfigDict` |
| 15 | MEDIUM | Codebase | Zero logging anywhere |
| 16 | LOW | `config.py` | No validation that YAML is a mapping type |
| 17 | LOW | Root | No `.env.example` file |
| 18 | LOW | Root | No GitHub Actions CI workflow |
| 19 | LOW | `cli/main.py` | `_print_report` has `# noqa: ANN001` instead of proper type hint |
| 20 | LOW | `cli/main.py` | No file size pre-check before reading |
| 21-26 | INFO | Various | Minor: no progress indicator, no async validators, simplified phone regex, no plugin arch |

## Phase 3 — Red Team Attack Findings

| Attack Vector | Impact | Status |
|---------------|--------|--------|
| POST 100MB text body | OOM crash | **FIXED** (max_length=500K) |
| PII exfiltration via API response | Privacy breach — SSNs in JSON | **FIXED** (redacted) |
| Substring false negatives in brand voice | "bro" in "broken" penalizes clean text | **FIXED** (word boundaries) |
| "yo " matches "your" in brand voice | Every "your" penalized as slang | **FIXED** (trailing space removed) |
| `all([])` returns True in Python | 0 validators run → "passed: true" | **FIXED** (Phase 6) |
| 10GB file via CLI --file | OOM before validation | **FIXED** (Phase 6 size check) |
| ValidationError traceback in CLI | Ugly UX for oversized text | **FIXED** (Phase 6 catch) |

## Phase 5 — All Changes Applied

### Security Fixes

| Change | File(s) | Why |
|--------|---------|-----|
| PII values redacted in all findings | `validators/pii.py` | Raw PII was echoed in `metadata["value"]` and `message`. Now uses fixed placeholders (`***@***.***`, `***-***-****`, `***-**-****`) |
| Max text length enforced (500K chars) | `models.py` | `max_length=MAX_TEXT_LENGTH` on `ValidationRequest.text` prevents memory exhaustion |
| CORS middleware added | `api/main.py` | Enables cross-origin API access with `allow_credentials=False` |
| Request ID propagation | `api/main.py`, `routes.py`, `engine.py`, `models.py` | `X-Request-ID` header in/out + `request_id` in response body |
| Response timing header | `api/main.py` | `X-Response-Time-Ms` for performance monitoring |

### Bug Fixes

| Change | File(s) | Why |
|--------|---------|-----|
| Word-boundary regex for brand voice penalties | `validators/brand_voice.py` | `lower.count("bro")` matched "broken". Now uses `\bbro\b` regex |
| Removed trailing space from "yo " | `validators/brand_voice.py` | `"yo "` matched "your", "young". Now `"yo"` with `\b` boundary |
| Removed dead `prompt_injection_threshold` | `validators/prompt_injection.py`, `config.py`, `config/default.yaml` | Config field was read but never used |
| `all([])` → `bool(results) and all(...)` | `engine.py` | 0 validators running now correctly returns `passed=False` |
| Unused `value` parameter in `_redact()` | `validators/pii.py` | Dead parameter removed |

### UX Improvements

| Change | File(s) | Why |
|--------|---------|-----|
| `--stdin` support | `cli/main.py` | `echo "text" \| joshua7 validate --stdin` now works |
| Mutual exclusion of input sources | `cli/main.py` | Enforces exactly one of `--text`, `--file`, `--stdin` |
| Better error messages | `cli/main.py` | Shows usage examples when no input provided |
| File size pre-check | `cli/main.py` | Rejects files >2MB before reading into memory |
| Graceful ValidationError handling | `cli/main.py` | Catches Pydantic errors, shows clean message |
| `--host` without `-h` shortcut | `cli/main.py` | Avoids `-h`/`--help` conflict |
| Request ID in CLI report | `cli/main.py` | Shows request ID for troubleshooting |
| Comma-formatted text length | `cli/main.py` | `500,000 chars` instead of `500000 chars` |
| `list` subcommand renamed | `cli/main.py` | `joshua7 list` instead of `joshua7 list-validators` |

### Robustness

| Change | File(s) | Why |
|--------|---------|-----|
| Engine catches validator exceptions | `engine.py` | One validator crash no longer kills the entire request |
| Structured logging throughout | All validators, `config.py`, `engine.py`, `api/main.py` | `logging.getLogger(__name__)` in every module |
| YAML config type validation | `config.py` | Rejects non-mapping YAML files gracefully |
| Unknown validators logged | `engine.py` | Warning log when a requested validator name doesn't exist |

### Code Quality

| Change | File(s) | Why |
|--------|---------|-----|
| `SettingsConfigDict` | `config.py` | Replaces plain `dict` for type-safe settings config |
| Proper type hint on `_print_report` | `cli/main.py` | Removed `# noqa: ANN001`, added `ValidationResponse` type |
| 2 new injection patterns | `validators/prompt_injection.py` | Added `forget_everything` and `act_as` detection |
| Pre-compiled positive signal regexes | `validators/brand_voice.py` | `_POSITIVE_SIGNALS` now compiled once at module load |

### Infrastructure

| Change | File(s) | Why |
|--------|---------|-----|
| GitHub Actions CI | `.github/workflows/ci.yml` | Python 3.10/3.11/3.12 matrix + Docker build |
| `.env.example` | `.env.example` | Documents all `J7_` environment variables |

### Test Coverage

| Metric | Before | After |
|--------|--------|-------|
| Total tests | 48 | 73 |
| PII redaction tests | 0 | 4 |
| Word boundary regression tests | 0 | 3 |
| Response metadata tests | 0 | 6 |
| CORS / header tests | 0 | 3 |
| Edge case tests (unicode, single word) | 0 | 4 |
| New injection pattern tests | 0 | 2 |
| Security assertion tests | 0 | 3 |

## Phase 6 — Final Red Team Fixes

| Finding | Fix |
|---------|-----|
| `all([])` returns `True` — 0 validators = "passed" | Changed to `bool(results) and all(r.passed for r in results)` |
| CLI reads arbitrarily large files before validation | Added file size pre-check (`stat().st_size`) |
| Ugly Pydantic traceback on oversized text via CLI | Catches `ValidationError`, shows clean error |
| Unused `value` param in `_redact(pii_type, value)` | Removed parameter |

---

## Verification Pass — Backwards + Forwards (Post Phase 6)

Additional sweep found and fixed 9 more issues:

| # | Severity | Fix |
|---|----------|-----|
| F1 | **HIGH** | `J7_MAX_TEXT_LENGTH` env var was ignored — engine now enforces `settings.max_text_length` as a pre-check |
| F2 | MEDIUM | Eliminated duplicate `_DEFAULT_PHRASES` — `forbidden_phrases.py` now imports from `config.py` |
| F3 | MEDIUM | Brand voice keyword matching switched to `\b` word boundaries (was substring) |
| F4 | MEDIUM | README updated: documents `--stdin`, `--json`, `list`, `.env.example`, PII redaction, request IDs |
| F5 | LOW | Removed `ALL_VALIDATORS` parallel list from `validators/__init__.py` |
| F6 | LOW | CLI pre-checks text length with clean error before Pydantic throws |
| F7 | LOW | Dockerfile `HEALTHCHECK --start-period=10s` prevents false unhealthy on cold start |
| F8 | LOW | Readability always reports `grade_level` in findings (was discarded on pass) |
| F9 | LOW | `test_validator_exception` now mocks an actual throw; added 3 new tests |

**Final counts:** 76 tests passing | 0 lint errors | 4 commits

## Remaining Known Limitations (Accepted for MVP)

1. **No authentication/rate-limiting** — expected to be handled at infrastructure layer (Cloud Run IAM, API Gateway)
2. **Synchronous validators** — adequate for MVP text sizes; async parallelism is a v2 optimization
3. **Phone regex has broad matching** — may flag some non-phone numeric sequences
4. **No plugin architecture** — custom validators require source modification
5. **Brand voice scoring is heuristic** — no NLP/ML model; adequate for v1

---

*Built with faith. Proceeds support St. Jude's Children's Hospital.*
