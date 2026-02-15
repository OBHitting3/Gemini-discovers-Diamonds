# Iron Forge CLI Suite

**Industrial-strength command-line toolkit for developer workflows.**

```
  ___                   _____
 |_ _|_ __ ___  _ __   |  ___|__  _ __ __ _  ___
  | || '__/ _ \| '_ \  | |_ / _ \| '__/ _` |/ _ \
  | || | | (_) | | | | |  _| (_) | | | (_| |  __/
 |___|_|  \___/|_| |_| |_|  \___/|_|  \__, |\___|
                                       |___/
```

## Overview

Iron Forge is a modular CLI framework for project scaffolding, build orchestration, configuration management, and system diagnostics. Built with Python 3.10+, Typer, and Rich for a polished developer experience.

## Installation

```bash
pip install -e ".[dev]"
```

This installs two executables: `ironforge` and `forge` (alias).

## Commands

| Command | Description |
|---------|-------------|
| `ironforge init [NAME]` | Scaffold a new project (templates: default, minimal, library) |
| `ironforge build` | Build and package the project |
| `ironforge check` | Run linting and validation checks |
| `ironforge config` | View and manage configuration |
| `ironforge config get KEY` | Get a specific config value |
| `ironforge config set KEY VALUE` | Set a config value |
| `ironforge config path` | Show config file location |
| `ironforge info` | Display system and project diagnostics |

## Global Options

```
--verbose / -v     Enable verbose output
--debug            Enable debug-level logging
--version / -V     Show version and exit
--help             Show help and exit
```

## Quick Start

```bash
# Initialize a new project
ironforge init my-app

# Enter the project
cd my-app

# Run checks
ironforge check

# Build the project
ironforge build

# View project info
ironforge info --full
```

## Project Structure

```
ironforge/
  __init__.py          # Package metadata (__version__, __app_name__)
  cli.py               # Main entry point, command router, global options
  core/
    config.py          # TOML/YAML configuration management
    context.py         # Execution context with logging
    errors.py          # Custom exception hierarchy
  commands/
    init.py            # Project scaffolding
    build.py           # Build orchestration
    check.py           # Linting and validation
    config.py          # Configuration management
    info.py            # System diagnostics
  utils/
    display.py         # Rich terminal output (panels, tables, banners)
    fs.py              # Filesystem utilities
    process.py         # Subprocess execution wrappers
tests/
  test_cli.py          # CLI integration tests (25 tests)
  test_config.py       # Configuration unit tests (12 tests)
  test_context.py      # Context unit tests (8 tests)
  test_errors.py       # Error hierarchy tests (8 tests)
  test_fs.py           # Filesystem utility tests (12 tests)
  test_process.py      # Process utility tests (8 tests)
  test_display.py      # Display utility tests (5 tests)
  test_version.py      # Version metadata tests (3 tests)
```

## Configuration

Iron Forge uses `ironforge.toml` for project configuration:

```toml
[project]
name = "my-app"
version = "0.1.0"
description = "My Iron Forge project."

[build]
target = "dist"
clean_before_build = true
parallel = true

[lint]
enabled = true
fix_on_check = false

[forge]
verbose = false
color = true
log_level = "INFO"
```

Environment variable overrides:
- `IRONFORGE_VERBOSE=true` — Enable verbose mode
- `IRONFORGE_LOG_LEVEL=DEBUG` — Set log level

## Development

```bash
# Install with dev dependencies
pip install -e ".[dev]"

# Run tests
pytest

# Run linter
ruff check ironforge/ tests/

# Format code
ruff format ironforge/ tests/
```

## Tech Stack

- **Python 3.10+** — Runtime
- **Typer** — CLI framework with type hints
- **Rich** — Terminal formatting (panels, tables, progress)
- **PyYAML** — YAML config support
- **TOML** — Native config format
- **pytest** — Test framework (88 tests)
- **Ruff** — Linting and formatting

## License

MIT
