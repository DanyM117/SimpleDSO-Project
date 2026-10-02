import os
import socket

import psycopg2
from flask import Flask, jsonify

app = Flask(__name__)


def get_db_connection():
    """Establece conexión estricta con TLS hacia PostgreSQL RDS."""
    return psycopg2.connect(
        host=os.environ.get("DB_HOST"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "agent_core"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        sslmode="require",
        connect_timeout=3,
    )


@app.route("/healthz", methods=["GET"])
def healthz():
    """Liveness probe: Valida que el proceso web responda."""
    return jsonify({"status": "healthy"}), 200


@app.route("/ready", methods=["GET"])
def ready():
    """Readiness probe: Valida conectividad activa contra RDS PostgreSQL."""
    try:
        conn = get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT 1;")
        conn.close()
        return jsonify({"status": "ready", "database": "connected"}), 200
    except Exception as exc:  # noqa: BLE001
        return jsonify({"status": "unhealthy", "error": str(exc)}), 503


@app.route("/api/v1/erp/ping", methods=["GET"])
def ping_erp():
    """Valida resolución DNS interna hacia la Hosted Zone privada de Route 53."""
    erp_host = os.environ.get("ERP_HOST", "api.erp.internal")
    try:
        resolved_ip = socket.gethostbyname(erp_host)
        return (
            jsonify(
                {
                    "target": erp_host,
                    "resolved_ip": resolved_ip,
                    "status": "reachable",
                }
            ),
            200,
        )
    except socket.gaierror as exc:
        return jsonify({"target": erp_host, "error": str(exc)}), 502


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)  # nosec B104