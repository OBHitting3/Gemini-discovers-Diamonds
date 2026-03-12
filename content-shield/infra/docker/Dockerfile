FROM python:3.12-slim AS base

LABEL maintainer="content-shield"
LABEL description="Content Shield - content quality monitoring and protection"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

RUN groupadd --gid 1000 appuser && \
    useradd --uid 1000 --gid appuser --shell /bin/bash --create-home appuser

WORKDIR /app

FROM base AS builder

RUN pip install --no-cache-dir build

COPY pyproject.toml setup.cfg ./
COPY src/ src/

RUN pip install --no-cache-dir --prefix=/install .

FROM base AS runtime

COPY --from=builder /install /usr/local

COPY src/ src/

USER appuser

EXPOSE 8080

ENTRYPOINT ["python", "-m", "content_shield"]
CMD ["serve", "--host", "0.0.0.0", "--port", "8080"]
