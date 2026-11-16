"""In-memory stand-ins used by the endpoint tests."""

import copy
from datetime import datetime, timezone
from uuid import UUID, uuid4

from app.modules.records.infrastructure.health_record_repository import ConfirmConflict


WORKER_ID = UUID("11111111-1111-1111-1111-111111111111")
OTHER_WORKER_ID = UUID("33333333-3333-3333-3333-333333333333")


class FakeHealthRecordRepository:
    """Same contract as HealthRecordRepository, backed by a dict.
    Class-level storage so every request in a test sees the same data."""

    records: dict = {}

    def __init__(self, db=None):
        pass

    @classmethod
    def reset(cls):
        cls.records = {}

    @classmethod
    def add(cls, worker_id=WORKER_ID, record_status="draft", **fields) -> dict:
        now = datetime.now(timezone.utc)
        record = {
            "id": uuid4(),
            "client_record_id": None,
            "worker_id": worker_id,
            "raw_input": "[Voice recording]",
            "input_language": "Kannada",
            "ai_transcript": None,
            "ai_translated_text": None,
            "ai_suggested_data": None,
            "confirmed_data": None,
            "ai_status": "pending_review",
            "record_status": record_status,
            "version": 1,
            "created_at": now,
            "updated_at": now,
            **fields,
        }
        cls.records[record["id"]] = record
        return record

    def get(self, record_id):
        record = self.records.get(UUID(str(record_id)))
        return copy.deepcopy(record) if record else None

    def get_by_client_id(self, worker_id, client_record_id):
        for record in self.records.values():
            if record["worker_id"] == worker_id and record["client_record_id"] == client_record_id:
                return copy.deepcopy(record)
        return None

    def create(self, worker_id, raw_input, input_language, client_record_id):
        if client_record_id is not None:
            existing = self.get_by_client_id(worker_id, client_record_id)
            if existing:
                return existing, False

        record = self.add(
            worker_id=worker_id,
            raw_input=raw_input,
            input_language=input_language,
            client_record_id=client_record_id,
        )
        return copy.deepcopy(record), True

    def _update(self, record_id, **fields):
        record = self.records[UUID(str(record_id))]
        record.update(fields)
        record["version"] += 1
        return copy.deepcopy(record)

    def save_ai_result(self, record_id, suggested_data, transcript=None, translated_text=None):
        record = self.records[UUID(str(record_id))]
        return self._update(
            record_id,
            ai_suggested_data=suggested_data,
            ai_transcript=transcript if transcript is not None else record["ai_transcript"],
            ai_translated_text=(translated_text if translated_text is not None
                                else record["ai_translated_text"]),
            ai_status="pending_review",
        )

    def mark_ai_failed(self, record_id):
        if self.records[UUID(str(record_id))]["record_status"] != "confirmed":
            self._update(record_id, ai_status="failed")

    def confirm(self, record_id, confirmed_data):
        record = self.records[UUID(str(record_id))]

        if record["record_status"] != "confirmed":
            return self._update(
                record_id, confirmed_data=confirmed_data, record_status="confirmed"
            ), True

        if record["confirmed_data"] == confirmed_data:
            return copy.deepcopy(record), False

        raise ConfirmConflict(copy.deepcopy(record))
