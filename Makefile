.PHONY: install dev test lint format clean build-exe help

help: ## Show this help message
	@echo "Iron Forge CLI — Development Commands"
	@echo "======================================"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

install: ## Install the package in production mode
	pip install .

dev: ## Install in editable mode with dev dependencies
	pip install -e ".[dev]"

test: ## Run the test suite
	pytest tests/ -v --tb=short

lint: ## Run linter (ruff)
	ruff check src/ tests/

format: ## Auto-format code (ruff)
	ruff format src/ tests/

clean: ## Remove build artifacts and caches
	rm -rf dist/ build/ *.egg-info src/*.egg-info
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

build-exe: ## Build standalone executable with PyInstaller
	pip install pyinstaller
	pyinstaller ironforge.spec
	@echo "Executable built: dist/ironforge"
