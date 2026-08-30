FROM python:3.13-slim AS builder
LABEL maintainer="nimat.razmjo@gmail.com"

ARG DEV=false

WORKDIR /app

COPY requirements.txt requirement.dev.txt ./
RUN pip install --no-cache-dir --user -r requirements.txt && \
    if [ "$DEV" = "true" ]; then pip install --no-cache-dir --user -r requirement.dev.txt; fi

FROM python:3.13-slim
LABEL maintainer="nimat.razmjo@gmail.com"

ENV PYTHONUNBUFFERED=1 \
    HOME=/home/appuser \
    PATH=/home/appuser/.local/bin:$PATH

RUN apt-get update && \
    apt-get install --no-install-recommends -y postgresql-client libpq-dev && \
    rm -rf /var/lib/apt/lists/*

RUN addgroup --system appuser && \
    adduser --system --ingroup appuser --home /home/appuser --shell /bin/bash appuser

WORKDIR /app

COPY --from=builder /root/.local /home/appuser/.local
COPY . .

RUN chown -R appuser:appuser /app /home/appuser

USER appuser

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "--bind", "0.0.0.0:8000"]