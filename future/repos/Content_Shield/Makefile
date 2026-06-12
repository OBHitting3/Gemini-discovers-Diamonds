.PHONY: install dev test lint format serve docker-build docker-run clean

install:
	pip install -e .

dev:
	pip install -e ".[dev]"

test:
	pytest --tb=short -v

test-cov:
	pytest --cov=joshua7 --cov-report=term-missing

lint:
	ruff check joshua7/ tests/

format:
	ruff format joshua7/ tests/

serve:
	uvicorn joshua7.api.main:app --reload --port 8000

docker-build:
	docker build -t joshua7 .

docker-run:
	docker run -p 8000:8000 joshua7

clean:
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	rm -rf dist build .pytest_cache .ruff_cache .mypy_cache htmlcov .coverage
