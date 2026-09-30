from app.modules.auth.infrastructure.user_repository import UserRepository


class HealthRecordService:

    def __init__(self, repository: UserRepository):
        self.repository = repository

    def create_health_record(
        self,
        worker_id,
        raw_input: str,
        input_language: str | None = None
    ):
        return self.repository.create_health_record(
            worker_id=worker_id,
            raw_input=raw_input,
            input_language=input_language
        )