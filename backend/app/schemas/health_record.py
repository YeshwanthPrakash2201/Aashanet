from pydantic import BaseModel
from typing import Optional


class HealthRecordCreate(BaseModel):
    raw_input: str
    input_language: Optional[str] = None


class HealthRecordResponse(BaseModel):
    id: str
    worker_id: str
    raw_input: str
    input_language: Optional[str]
    ai_status: str
    record_status: str

class HealthRecordConfirm(BaseModel):
    patient_name: Optional[str] = None
    age: Optional[int] = None
    symptoms: list[str] = []
    duration: Optional[str] = None