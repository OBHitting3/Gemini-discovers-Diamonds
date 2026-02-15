# Iron Forge CLI Suite

**Developer tooling forged in code.** A production-quality command-line interface for project scaffolding, building, and configuration management.

## Features

- **Project Scaffolding** — `ironforge init` creates a structured project with source and build directories, configuration file, and starter code.
- **Build Engine** — `ironforge build` collects source artifacts and produces build output with timing and artifact reports.
- **Status Inspector** — `ironforge status` displays project health checks, file counts, and configuration state (supports `--json` for CI).
- **Clean-up** — `ironforge clean` removes build artifacts with granular control (`--full` for complete removal).
- **Configuration Management** — `ironforge config` provides `get`/`set`/`list`/`path` subcommands with dot-notation keys, supporting both project-level and global (`~/.ironforge/config.toml`) configuration.
- **Rich Terminal Output** — Colour-coded messages, tables, panels, and health-check grids powered by Rich.
- **Structured Error Handling** — Typed exception hierarchy with semantic exit codes.
- **Executable Packaging** — PyInstaller spec included for building standalone binaries.

## Installation

### From source (editable / development)

```bash
pip install -e ".[dev]"
```

### Production install

```bash
pip install .
```

### Standalone executable

```bash
pip install pyinstaller
pyinstaller ironforge.spec
# Output: dist/ironforge
```

## Quick Start

```bash
# Initialise a new project
ironforge init myproject

# Enter the project directory
cd myproject

# Check project status
ironforge status

# Run a build
ironforge build

# View configuration
ironforge config

# Clean build artifacts
ironforge clean -y

# Show version and environment
ironforge version
```

## Commands

| Command   | Description                                 |
|-----------|---------------------------------------------|
| `init`    | Scaffold a new Iron Forge project           |
| `build`   | Build the current project                   |
| `status`  | Show project health and file counts         |
| `clean`   | Remove build artifacts                      |
| `config`  | View/manage project and global config       |
| `version` | Display version and environment details     |

### Global Options

```
-v, --verbose    Enable verbose output
    --debug      Enable debug logging (writes to ~/.ironforge/logs/)
    --no-color   Disable colour output
-V, --version    Show version and exit
-h, --help       Show help and exit
```

### `ironforge init`

```bash
ironforge init [NAME] [OPTIONS]

Options:
  -d, --directory PATH     Target directory (default: cwd)
  --version TEXT            Initial version string (default: 0.1.0)
  --description TEXT        Short project description
  --author TEXT             Author name
  --license TEXT            License identifier (default: MIT)
  -f, --force              Overwrite existing config
```

### `ironforge build`

```bash
ironforge build [OPTIONS]

Options:
  -d, --directory PATH     Project root directory
  --dry-run                Show what would be built without building
```

### `ironforge status`

```bash
ironforge status [OPTIONS]

Options:
  -d, --directory PATH     Project root directory
  --json                   Output as JSON (for CI/scripting)
```

### `ironforge clean`

```bash
ironforge clean [OPTIONS]

Options:
  -d, --directory PATH     Project root directory
  --full                   Remove the entire build directory
  -y, --yes                Skip confirmation prompt
```

### `ironforge config`

```bash
ironforge config                        # Show all config
ironforge config list [--global]        # List all keys
ironforge config get KEY [--global]     # Get a value (dot-notation)
ironforge config set KEY VALUE [--global] # Set a value
ironforge config path [--global]        # Show config file path
```

## Configuration

### Project config (`ironforge.toml`)

Created by `ironforge init` in the project root:

```toml
name = "myproject"
version = "0.1.0"
description = ""
author = ""
license = "MIT"

[build]
output_dir = "dist"
src_dir = "src"
targets = ["default"]
parallel = true
optimization = "standard"
```

### Global config (`~/.ironforge/config.toml`)

User-level defaults applied across all projects:

```toml
default_license = "MIT"
default_author = ""
color = true
verbose = false
editor = ""
profile = "default"
```

## Project Structure

```
src/ironforge/
    __init__.py          # Package metadata (__version__)
    __main__.py          # python -m ironforge entry point
    cli.py               # Click command group + global options
    commands/
        init.py          # ironforge init
        build.py         # ironforge build
        status.py        # ironforge status
        clean.py         # ironforge clean
        config_cmd.py    # ironforge config (get/set/list/path)
        version.py       # ironforge version
    core/
        config.py        # TOML config I/O + Pydantic models
        engine.py        # Build engine, scaffolding, clean logic
    utils/
        errors.py        # Exception hierarchy (exit codes 1-5)
        logging.py       # Structured logging (console + file)
        output.py        # Rich-powered terminal output helpers
tests/
    conftest.py          # Shared fixtures (CliRunner, isolated_runner)
    test_cli_main.py     # Top-level CLI tests
    test_init.py         # Init command tests
    test_build.py        # Build command tests
    test_status.py       # Status command tests
    test_clean.py        # Clean command tests
    test_config.py       # Config model + command tests
    test_engine.py       # Core engine unit tests
    test_errors.py       # Error hierarchy tests
    test_version.py      # Version command tests
```

## Development

```bash
# Install with dev dependencies
pip install -e ".[dev]"

# Run tests
pytest tests/ -v

# Run linter
ruff check src/ tests/

# Auto-format
ruff format src/ tests/

# Or use the Makefile
make dev       # Install editable + dev deps
make test      # Run tests
make lint      # Run linter
make format    # Auto-format
make clean     # Remove build artifacts
make build-exe # Build standalone executable
```

## Entry Points

The package provides two console entry points:

- `ironforge` — primary command name
- `forge` — short alias

Both can also be invoked as a Python module:

```bash
python -m ironforge --help
```

## License

MIT
