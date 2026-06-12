FROM python:3.12-slim AS base

WORKDIR /app

RUN adduser --disabled-password --gecos "" appuser

COPY pyproject.toml README.md ./
COPY joshua7/ joshua7/
COPY config/ config/

RUN pip install --no-cache-dir .

USER appuser

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

CMD ["uvicorn", "joshua7.api.main:app", "--host", "0.0.0.0", "--port", "8000"]
