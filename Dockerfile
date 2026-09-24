FROM python:3.12.14-alpine3.23

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY --chown=appuser:appgroup /app .

USER appuser

EXPOSE 5000

CMD [ "python3", "app.py" ]