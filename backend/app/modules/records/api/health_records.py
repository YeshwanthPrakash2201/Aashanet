import json

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    UploadFile,
    File,
    Form
)
from psycopg import Connection

from app.core.auth import get_current_user
from app.infrastructure.db_dependency import get_db

from app.modules.auth.infrastructure.user_repository import UserRepository
from app.modules.records.application.health_record_service import HealthRecordService
from app.modules.ai.application.health_record_ai_service import HealthRecordAIService

from app.schemas.health_record import (
    HealthRecordCreate,
    HealthRecordConfirm,
    HealthRecordResponse
)


router = APIRouter(
    prefix="/health-records",
    tags=["Health Records"]
)


# ============================================================
# CREATE HEALTH RECORD
# ============================================================

@router.post(
    "",
    response_model=HealthRecordResponse
)
def create_health_record(
    record: HealthRecordCreate,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    repository = UserRepository(db)

    service = HealthRecordService(repository)

    worker = repository.get_user_by_username(
        current_user["sub"]
    )

    created_record = service.create_health_record(
        worker_id=worker[0],
        raw_input=record.raw_input,
        input_language=record.input_language
    )

    return {
        "id": str(created_record[0]),
        "worker_id": str(created_record[1]),
        "raw_input": created_record[2],
        "input_language": created_record[3],
        "ai_status": created_record[4],
        "record_status": created_record[5]
    }


# ============================================================
# PROCESS TYPED HEALTH RECORD
# ============================================================

@router.post("/{record_id}/process")
def process_health_record(
    record_id: str,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    repository = UserRepository(db)
    ai_service = HealthRecordAIService()

    with db.cursor() as cursor:
        cursor.execute(
            """
            SELECT
                id,
                worker_id,
                raw_input,
                input_language,
                ai_status,
                record_status
            FROM health_records
            WHERE id = %s
            """,
            (record_id,)
        )

        record = cursor.fetchone()

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Health record not found"
        )

    worker = repository.get_user_by_username(
        current_user["sub"]
    )

    if not worker:
        raise HTTPException(
            status_code=404,
            detail="Worker not found"
        )

    if str(record[1]) != str(worker[0]):
        raise HTTPException(
            status_code=403,
            detail="You cannot process this record"
        )

    suggested_data = ai_service.process(
        record[2]
    )

    suggested_data_json = json.dumps(
        suggested_data
    )

    with db.cursor() as cursor:
        cursor.execute(
            """
            UPDATE health_records
            SET
                ai_suggested_data = %s,
                ai_status = 'pending_review',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING
                id,
                worker_id,
                raw_input,
                input_language,
                ai_suggested_data,
                ai_status,
                record_status
            """,
            (
                suggested_data_json,
                record_id
            )
        )

        updated_record = cursor.fetchone()

    db.commit()

    return {
        "id": str(updated_record[0]),
        "worker_id": str(updated_record[1]),
        "raw_input": updated_record[2],
        "input_language": updated_record[3],
        "ai_suggested_data": updated_record[4],
        "ai_status": updated_record[5],
        "record_status": updated_record[6]
    }


# ============================================================
# PROCESS AUDIO HEALTH RECORD USING GEMINI
# ============================================================

@router.post("/{record_id}/process-audio")
async def process_health_record_audio(
    record_id: str,
    audio: UploadFile = File(...),
    language: str = Form("Kannada"),
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    repository = UserRepository(db)

    worker = repository.get_user_by_username(
        current_user["sub"]
    )

    if not worker:
        raise HTTPException(
            status_code=404,
            detail="Worker not found"
        )

    with db.cursor() as cursor:
        cursor.execute(
            """
            SELECT
                id,
                worker_id,
                raw_input,
                input_language,
                record_status
            FROM health_records
            WHERE id = %s
            """,
            (record_id,)
        )

        record = cursor.fetchone()

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Health record not found"
        )

    if str(record[1]) != str(worker[0]):
        raise HTTPException(
            status_code=403,
            detail="You cannot process this record"
        )

    audio_bytes = await audio.read()

    if not audio_bytes:
        raise HTTPException(
            status_code=400,
            detail="Audio file is empty"
        )

    import tempfile
    import os

    suffix = os.path.splitext(
        audio.filename or ".m4a"
    )[1]

    with tempfile.NamedTemporaryFile(
        delete=False,
        suffix=suffix
    ) as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name

    try:
        from app.services.gemini_service import process_audio

        result = process_audio(
            temp_audio_path,
            language=language
        )

    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

    transcript = ""
    english = ""
    analyzed = {}

    if "ENGLISH:" in result:

        transcript_part, remaining = result.split(
            "ENGLISH:",
            1
        )

        transcript = transcript_part.replace(
            "TRANSCRIPT:",
            ""
        ).strip()

        if "ANALYZED:" in remaining:

            english_part, analyzed_part = remaining.split(
                "ANALYZED:",
                1
            )

            english = english_part.strip()

            for line in analyzed_part.strip().splitlines():

                if ":" not in line:
                    continue

                key, value = line.split(
                    ":",
                    1
                )

                key = key.strip().lower().replace(
                    " ",
                    "_"
                )

                value = value.strip()

                if key == "patient_name":

                    analyzed["patient_name"] = (
                        value or None
                    )

                elif key == "age":

                    try:
                        analyzed["age"] = int(value)

                    except ValueError:
                        analyzed["age"] = None

                elif key == "symptoms":

                    analyzed["symptoms"] = [
                        symptom.strip()
                        for symptom in value.split(",")
                        if symptom.strip()
                    ]

                elif key == "duration":

                    analyzed["duration"] = (
                        value or None
                    )

    with db.cursor() as cursor:
        cursor.execute(
            """
            UPDATE health_records
            SET
                ai_transcript = %s,
                ai_translated_text = %s,
                ai_suggested_data = %s,
                ai_status = 'pending_review',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING
                id,
                worker_id,
                ai_transcript,
                ai_translated_text,
                ai_suggested_data,
                ai_status,
                record_status
            """,
            (
                transcript,
                english,
                json.dumps(analyzed),
                record_id
            )
        )

        updated_record = cursor.fetchone()

    db.commit()

    return {
        "id": str(updated_record[0]),
        "worker_id": str(updated_record[1]),
        "transcript": updated_record[2],
        "english": updated_record[3],
        "analyzed": updated_record[4],
        "ai_status": updated_record[5],
        "record_status": updated_record[6]
    }


# ============================================================
# CONFIRM HEALTH RECORD
# ============================================================

@router.post("/{record_id}/confirm")
def confirm_health_record(
    record_id: str,
    confirmed_record: HealthRecordConfirm,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    repository = UserRepository(db)

    worker = repository.get_user_by_username(
        current_user["sub"]
    )

    if not worker:
        raise HTTPException(
            status_code=404,
            detail="Worker not found"
        )

    with db.cursor() as cursor:
        cursor.execute(
            """
            SELECT
                id,
                worker_id,
                ai_status,
                record_status
            FROM health_records
            WHERE id = %s
            """,
            (record_id,)
        )

        record = cursor.fetchone()

    if not record:
        raise HTTPException(
            status_code=404,
            detail="Health record not found"
        )

    if str(record[1]) != str(worker[0]):
        raise HTTPException(
            status_code=403,
            detail="You cannot confirm this record"
        )

    if record[3] == "confirmed":
        raise HTTPException(
            status_code=400,
            detail="Health record is already confirmed"
        )

    confirmed_data = {
        "patient_name": confirmed_record.patient_name,
        "age": confirmed_record.age,
        "symptoms": confirmed_record.symptoms,
        "duration": confirmed_record.duration
    }

    confirmed_data_json = json.dumps(
        confirmed_data
    )

    with db.cursor() as cursor:
        cursor.execute(
            """
            UPDATE health_records
            SET
                confirmed_data = %s,
                record_status = 'confirmed',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            RETURNING
                id,
                worker_id,
                raw_input,
                input_language,
                ai_suggested_data,
                confirmed_data,
                ai_status,
                record_status
            """,
            (
                confirmed_data_json,
                record_id
            )
        )

        updated_record = cursor.fetchone()

    db.commit()

    return {
        "id": str(updated_record[0]),
        "worker_id": str(updated_record[1]),
        "raw_input": updated_record[2],
        "input_language": updated_record[3],
        "ai_suggested_data": updated_record[4],
        "confirmed_data": updated_record[5],
        "ai_status": updated_record[6],
        "record_status": updated_record[7]
    }

