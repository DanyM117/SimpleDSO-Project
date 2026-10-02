# Stage 1: Build dependencies & compilation wheels
FROM python:3.12-alpine3.21 AS builder

WORKDIR /build

# Actualizar paquetes base e instalar dependencias de compilación
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache gcc musl-dev libpq-dev

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Hardened Runtime Container
FROM python:3.12-alpine3.21

# Actualizar librerías de sistema (mitiga OpenSSL, musl y zlib) e instalar libpq
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache libpq && \
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

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "30", "--access-logfile", "-", "app:app"]