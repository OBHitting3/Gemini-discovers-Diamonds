# Joshua 7 (Content Shield) — Python CLI + API container
FROM python:3.13-slim

WORKDIR /app

# Copy project files
COPY pyproject.toml .
COPY src/ src/

# Install package (editable for dev; for prod we could use pip install .)
RUN pip install --no-cache-dir -e .

# Default: run API server with gunicorn (for Render, Railway, etc.)
# Override with: docker run joshua7 j7 "your text"
ENV PORT=8000
EXPOSE ${PORT}
CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT:-8000} joshua7.api:app"]
