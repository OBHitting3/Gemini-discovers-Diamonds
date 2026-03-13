# Contributing

## Setup

```bash
git clone https://github.com/content-shield/content-shield.git
cd content-shield
make dev
```

## Workflow

1. Create a feature branch from `main`
2. Write tests first
3. Implement your changes
4. Run `make lint && make test`
5. Submit a pull request

## Code Style

- We use `ruff` for linting and formatting
- Type hints are required on all public APIs
- All shields must extend `BaseShield`
