# Stage 1: Build dependencies & compilation wheels
FROM python:3.12-alpine3.21 AS builder

WORKDIR /build

RUN apk add --no-cache gcc musl-dev libpq-dev

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Hardened Runtime Container
FROM python:3.12-alpine3.21

# Instalar exclusivamente la librería de enlace en tiempo de ejecución
RUN apk add --no-cache libpq && \
    addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

# Copiar paquetes de Python compilados en el usuario appuser
COPY --from=builder /root/.local /home/appuser/.local
COPY --chown=appuser:appgroup app.py .

ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PORT=5000

USER appuser
EXPOSE 5000

# Gunicorn en ejecución con 2 workers (adecuado para 1 vCPU / t4g.small)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "30", "--access-logfile", "-", "app:app"]