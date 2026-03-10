# Multi-stage Dockerfile for targeting-service (Python)
FROM python:3.11-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && rm -rf /var/lib/apt/lists/*
COPY requirements.txt ./
RUN python -m pip install --upgrade pip setuptools wheel \
    && python -m pip wheel --no-cache-dir --wheel-dir /wheels -r requirements.txt

FROM python:3.11-slim
WORKDIR /app
RUN addgroup --system app && adduser --system --group app
COPY --from=builder /wheels /wheels
COPY requirements.txt ./
RUN python -m pip install --upgrade pip \
    && python -m pip install --no-cache-dir --no-index --find-links /wheels -r requirements.txt \
    && rm -rf /wheels /root/.cache
COPY . .
USER app
CMD ["python", "app.py"]
