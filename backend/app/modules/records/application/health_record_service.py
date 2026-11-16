from uuid import UUID

from app.modules.records.infrastructure.health_record_repository import (
    HealthRecordRepository,
)


class HealthRecordService:

    def __init__(self, repository: HealthRecordRepository):
        self.repository = repository

    def create_health_record(
        self,
        worker_id,
        raw_input: str,
        input_language: str | None = None,
        client_record_id: UUID | None = None,
    ) -> tuple[dict, bool]:
        return self.repository.create(
            worker_id=worker_id,
            raw_input=raw_input,
            input_language=input_language,
            client_record_id=client_record_id,
        )
