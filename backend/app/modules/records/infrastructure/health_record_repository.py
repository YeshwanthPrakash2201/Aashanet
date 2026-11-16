"""
PostgreSQL access for health records.

Every write increments `version`, so a client can tell whether the
server copy changed since it last looked.
"""

import json
from uuid import UUID

from psycopg import Connection
from psycopg.rows import dict_row


RECORD_COLUMNS = """
    id,
    client_record_id,
    worker_id,
    raw_input,
    input_language,
    ai_transcript,
    ai_translated_text,
    ai_suggested_data,
    confirmed_data,
    ai_status,
    record_status,
    version,
    created_at,
    updated_at
"""


class ConfirmConflict(Exception):
    """The record was already confirmed with different data."""

    def __init__(self, server_record: dict):
        super().__init__("Health record already confirmed with different data")
        self.server_record = server_record


class HealthRecordRepository:

    def __init__(self, db: Connection):
        self.db = db

    def _fetch_one(self, sql: str, params: tuple) -> dict | None:
        with self.db.cursor(row_factory=dict_row) as cursor:
            cursor.execute(sql, params)
            return cursor.fetchone()

    # ----------------------------------------------------------
    # READ
    # ----------------------------------------------------------

    def get(self, record_id: UUID) -> dict | None:
        return self._fetch_one(
            f"SELECT {RECORD_COLUMNS} FROM health_records WHERE id = %s",
            (record_id,),
        )

    def get_by_client_id(self, worker_id: UUID, client_record_id: UUID) -> dict | None:
        return self._fetch_one(
            f"""
            SELECT {RECORD_COLUMNS} FROM health_records
            WHERE worker_id = %s AND client_record_id = %s
            """,
            (worker_id, client_record_id),
        )

    # ----------------------------------------------------------
    # CREATE (idempotent when client_record_id is given)
    # ----------------------------------------------------------

    def create(
        self,
        worker_id: UUID,
        raw_input: str,
        input_language: str | None,
        client_record_id: UUID | None,
    ) -> tuple[dict, bool]:
        """Returns (record, created). When the same worker sends the same
        client_record_id again, the existing record is returned and
        created is False, so retries never make duplicates."""

        record = self._fetch_one(
            f"""
            INSERT INTO health_records (
                id, client_record_id, worker_id, raw_input, input_language
            )
            VALUES (gen_random_uuid(), %s, %s, %s, %s)
            ON CONFLICT (worker_id, client_record_id)
                WHERE client_record_id IS NOT NULL
                DO NOTHING
            RETURNING {RECORD_COLUMNS}
            """,
            (client_record_id, worker_id, raw_input, input_language),
        )
        self.db.commit()

        if record is not None:
            return record, True

        return self.get_by_client_id(worker_id, client_record_id), False

    # ----------------------------------------------------------
    # AI RESULTS
    # ----------------------------------------------------------

    def save_ai_result(
        self,
        record_id: UUID,
        suggested_data: dict,
        transcript: str | None = None,
        translated_text: str | None = None,
    ) -> dict:
        record = self._fetch_one(
            f"""
            UPDATE health_records
            SET ai_transcript = COALESCE(%s, ai_transcript),
                ai_translated_text = COALESCE(%s, ai_translated_text),
                ai_suggested_data = %s,
                ai_status = 'pending_review',
                version = version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING {RECORD_COLUMNS}
            """,
            (transcript, translated_text, json.dumps(suggested_data), record_id),
        )
        self.db.commit()
        return record

    def mark_ai_failed(self, record_id: UUID) -> None:
        """Record that AI processing failed without touching any data the
        worker entered. Confirmed records are never changed."""
        with self.db.cursor() as cursor:
            cursor.execute(
                """
                UPDATE health_records
                SET ai_status = 'failed',
                    version = version + 1,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = %s AND record_status <> 'confirmed'
                """,
                (record_id,),
            )
        self.db.commit()

    # ----------------------------------------------------------
    # CONFIRM (idempotent; conflicting data is rejected)
    # ----------------------------------------------------------

    def confirm(self, record_id: UUID, confirmed_data: dict) -> tuple[dict, bool]:
        """Returns (record, changed).

        * Not yet confirmed  -> saves the data, changed=True.
        * Already confirmed with the same data -> no change, changed=False
          (a retry of a request whose response was lost).
        * Already confirmed with different data -> ConfirmConflict.

        The UPDATE only matches unconfirmed rows, so two simultaneous
        confirmations cannot both win.
        """
        record = self._fetch_one(
            f"""
            UPDATE health_records
            SET confirmed_data = %s,
                record_status = 'confirmed',
                version = version + 1,
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s AND record_status <> 'confirmed'
            RETURNING {RECORD_COLUMNS}
            """,
            (json.dumps(confirmed_data), record_id),
        )
        self.db.commit()

        if record is not None:
            return record, True

        existing = self.get(record_id)

        if existing["confirmed_data"] == confirmed_data:
            return existing, False

        raise ConfirmConflict(existing)
