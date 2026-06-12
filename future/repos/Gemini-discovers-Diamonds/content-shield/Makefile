.PHONY: install dev test lint format type-check clean build

install:
	pip install -e .

dev:
	pip install -e ".[dev,all]"

test:
	pytest --cov=content_shield --cov-report=term-missing

lint:
	ruff check src/ tests/

format:
	ruff format src/ tests/

type-check:
	mypy src/content_shield/

clean:
	rm -rf build/ dist/ *.egg-info .pytest_cache .mypy_cache .ruff_cache
	find . -type d -name __pycache__ -exec rm -rf {} +

build:
	python -m build
