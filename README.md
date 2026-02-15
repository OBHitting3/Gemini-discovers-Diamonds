# Gemini-discovers-Diamonds

## All-Occurrences Replacement Engine

A strict-execution replacement engine that finds and replaces **all occurrences** of patterns across text content and files. Built with full audit trails, backup management, and comprehensive reporting.

### Features

- **Literal string matching** — find and replace exact text, with special characters handled safely
- **Regex-based matching** — full regular expression support including group references
- **Word-boundary matching** — replace whole words only, avoiding partial matches
- **Case-sensitive and case-insensitive** modes
- **Single-file and recursive directory** replacement
- **Dry-run mode** — preview every change without modifying any files
- **Automatic backup creation** — `.bak` files created before each modification
- **SHA-256 integrity hashes** — original and modified content hashes in every result
- **Detailed replacement reports** — line-level granularity with column positions
- **Comprehensive audit logging** — every action timestamped and recorded
- **Binary file detection** — automatically skips non-text files
- **File size limits** — configurable maximum file size to prevent runaway operations
- **Include/exclude filters** — glob-based file pattern filtering
- **Encoding support** — configurable file encoding (defaults to UTF-8)
- **CLI interface** — full command-line tool with all options exposed

### Quick Start

#### Python API

```python
from replace_all import ReplacementEngine, ReplaceConfig, MatchMode

engine = ReplacementEngine()

# Literal replacement in a file
config = ReplaceConfig(find_pattern="old_name", replace_with="new_name")
result = engine.replace_in_file("target.py", config)
print(result.summary())

# Regex replacement across a directory
config = ReplaceConfig(
    find_pattern=r"TODO:\s+.*",
    replace_with="DONE",
    match_mode=MatchMode.REGEX,
    dry_run=True,
)
report = engine.replace_in_directory("./src", config)
print(report.summary())

# Word-boundary replacement (avoids partial matches)
config = ReplaceConfig(
    find_pattern="var",
    replace_with="const",
    match_mode=MatchMode.WORD_BOUNDARY,
)
result, occurrences = engine.replace_in_text("var x; variable y;", config)
# result == "const x; variable y;"
```

#### CLI Usage

```bash
# Literal replacement in a single file
python3 replace_all.py --path myfile.txt --find "old" --replace "new"

# Regex replacement across a directory
python3 replace_all.py --path ./src --find "log\(.*\)" --replace "logger.info()" --mode regex

# Case-insensitive dry run
python3 replace_all.py --path . --find "TODO" --replace "DONE" --no-case --dry-run

# Word-boundary matching with include filter
python3 replace_all.py --path . --find "var" --replace "const" --mode word --include "*.js"

# Skip backups
python3 replace_all.py --path ./src --find "old_api" --replace "new_api" --no-backup
```

### CLI Options

| Option | Description |
|---|---|
| `--path` | File or directory to process (required) |
| `--find` | Pattern to search for (required) |
| `--replace` | Replacement string (required) |
| `--mode` | `literal`, `regex`, or `word` (default: `literal`) |
| `--no-case` | Case-insensitive matching |
| `--dry-run` | Preview changes without writing |
| `--no-backup` | Skip creating `.bak` backup files |
| `--encoding` | File encoding (default: `utf-8`) |
| `--include` | Glob patterns to include (e.g., `*.py *.txt`) |
| `--exclude` | Additional glob patterns to exclude |
| `--no-recursive` | Do not recurse into subdirectories |
| `--follow-symlinks` | Follow symbolic links |
| `-v`, `--verbose` | Enable verbose debug output |

### Running Tests

```bash
python3 -m unittest test_replace_all -v
```

All 84 tests cover:
- Text-level replacement (literal, regex, word-boundary)
- Case-sensitive and case-insensitive matching
- File-level replacement with backup management
- Directory-level recursive replacement
- Dry-run mode
- Edge cases (empty files, binary files, unicode, large files)
- Configuration validation
- Audit logging integrity
- CLI interface end-to-end
- Error handling and recovery

### Architecture

```
replace_all.py
├── ReplaceConfig          — Validated configuration dataclass
├── ReplacementEngine      — Core engine with audit logging
│   ├── replace_in_text()  — Text-level find & replace all
│   ├── replace_in_file()  — File-level with backup & hashing
│   ├── replace_in_directory() — Recursive directory traversal
│   ├── find_all()         — Read-only occurrence scan
│   ├── count_occurrences()— Quick count
│   └── preview_replacement() — Diff-style preview
├── ReplacementReport      — Aggregate reporting
├── FileResult             — Per-file result with metadata
├── Occurrence             — Per-match detail (line, column, text)
└── main()                 — CLI entry point
```
