import os
import socket

from flask import Flask, jsonify, request

from agent import process_user_turn
from db import get_db_connection, get_session_history, init_db, save_message

app = Flask(__name__)

# Inicializar tablas si la base de datos está disponible
try:
    init_db()
except Exception as exc:  # noqa: BLE001
    app.logger.warning(f"DB init deferred: {exc}")


@app.route("/healthz", methods=["GET"])
def healthz():
    return jsonify({"status": "healthy"}), 200


@app.route("/ready", methods=["GET"])
def ready():
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
    erp_host = os.environ.get("ERP_HOST", "api.erp.internal")
    try:
        resolved_ip = socket.gethostbyname(erp_host)
        return jsonify({"target": erp_host, "resolved_ip": resolved_ip, "status": "reachable"}), 200
    except socket.gaierror as exc:
        return jsonify({"target": erp_host, "error": str(exc)}), 502


@app.route("/api/v1/chat", methods=["POST"])
def chat():
    payload = request.get_json(silent=True) or {}
    session_id = payload.get("session_id")
    user_message = payload.get("message", "").strip()

    if not session_id or not user_message:
        return jsonify({"error": "session_id and message are required"}), 400

    history = get_session_history(session_id, limit=6)
    save_message(session_id, "user", user_message)

    try:
        assistant_reply = process_user_turn(history, user_message)
    except Exception as exc:  # noqa: BLE001
        app.logger.error(f"Error procesando turno: {exc}")
        assistant_reply = "Ocurrió un error al procesar tu consulta. Intenta nuevamente."

    save_message(session_id, "assistant", assistant_reply)

    return jsonify({
        "session_id": session_id,
        "reply": assistant_reply
    }), 200


if __name__ == "__main__":
    port = int(os.environ.get("PORT", "5000"))
    app.run(host="0.0.0.0", port=port)  # nosec B104