import os

import psycopg2

from psycopg2.extras import RealDictCursor


def get_db_connection():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "agent_core"),
        user=os.environ.get("DB_USER"),
        password=os.environ.get("DB_PASSWORD"),
        sslmode=os.environ.get("DB_SSLMODE", "prefer"),
        connect_timeout=3,
    )


def init_db():
    ddl = """
    CREATE TABLE IF NOT EXISTS conversation_history (
        id SERIAL PRIMARY KEY,
        session_id VARCHAR(64) NOT NULL,
        role VARCHAR(16) NOT NULL,
        content TEXT NOT NULL,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    );
    CREATE INDEX IF NOT EXISTS idx_session ON conversation_history(session_id);

    CREATE TABLE IF NOT EXISTS appointment_locks (
        id SERIAL PRIMARY KEY,
        practitioner_id VARCHAR(64) NOT NULL,
        slot_time TIMESTAMP WITH TIME ZONE NOT NULL,
        customer_phone VARCHAR(32) NOT NULL,
        locked_until TIMESTAMP WITH TIME ZONE NOT NULL,
        status VARCHAR(16) DEFAULT 'LOCKED',
        CONSTRAINT unique_slot_lock UNIQUE (practitioner_id, slot_time)
    );
    """
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(ddl)
        conn.commit()


def save_message(session_id: str, role: str, content: str):
    with get_db_connection() as conn:
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO conversation_history (session_id, role, content) VALUES (%s, %s, %s)",
                (session_id, role, content),
            )
        conn.commit()


def get_session_history(session_id: str, limit: int = 10):
    with (
        get_db_connection() as conn,
        conn.cursor(cursor_factory=RealDictCursor) as cur,
    ):
        cur.execute(
            """
            SELECT role, content FROM conversation_history 
            WHERE session_id = %s 
            ORDER BY created_at ASC LIMIT %s
            """,
            (session_id, limit),
        )
        return cur.fetchall()