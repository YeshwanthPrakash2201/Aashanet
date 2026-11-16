from typing import Optional
from uuid import UUID

from pydantic import BaseModel, Field


class HealthRecordCreate(BaseModel):
    raw_input: str = Field(min_length=1)
    input_language: Optional[str] = None
    # ID generated on the phone. Sending the same value again returns the
    # existing record instead of creating a duplicate (safe retries).
    client_record_id: Optional[UUID] = None


class HealthRecordResponse(BaseModel):
    id: str
    worker_id: str
    raw_input: str
    input_language: Optional[str]
    ai_status: str
    record_status: str
    client_record_id: Optional[str] = None
    version: int = 1


class HealthRecordConfirm(BaseModel):
    patient_name: Optional[str] = None
    age: Optional[int] = Field(default=None, ge=0, le=120)
    symptoms: list[str] = []
    duration: Optional[str] = None
