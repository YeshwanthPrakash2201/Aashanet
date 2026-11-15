import json
import os
import tempfile

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
from app.services.gemini_service import (
    AUDIO_MIME_TYPES,
    GeminiConfigurationError,
    GeminiProcessingError,
    GeminiUnavailableError,
    UnsupportedLanguageError,
    normalize_language,
    process_audio,
)

from app.schemas.health_record import (
    HealthRecordCreate,
    HealthRecordConfirm,
    HealthRecordResponse
)


# Upper bound for uploaded voice notes (a few minutes of AAC is ~1-3 MB).
MAX_AUDIO_BYTES = 25 * 1024 * 1024


def _mark_ai_failed(db: Connection, record_id: str) -> None:
    """Record that AI processing failed, without touching any data the
    worker has entered. The record stays a draft and can be retried."""
    with db.cursor() as cursor:
        cursor.execute(
            """
            UPDATE health_records
            SET ai_status = 'failed',
                updated_at = CURRENT_TIMESTAMP
            WHERE id = %s
            """,
            (record_id,)
        )

    db.commit()


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
#
# Deliberately a plain `def`: the database and Gemini calls below are
# blocking, so FastAPI must run this in its threadpool rather than on
# the event loop (an `async def` here would stall every other request).
# ============================================================

@router.post("/{record_id}/process-audio")
def process_health_record_audio(
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

    if record[4] == "confirmed":
        raise HTTPException(
            status_code=409,
            detail="Health record is already confirmed"
        )

    audio_bytes = audio.file.read(MAX_AUDIO_BYTES + 1)

    if len(audio_bytes) > MAX_AUDIO_BYTES:
        raise HTTPException(
            status_code=413,
            detail="Audio file is too large"
        )

    if not audio_bytes:
        raise HTTPException(
            status_code=400,
            detail="Audio file is empty"
        )

    # Validate inputs before spending a Gemini call on them.
    try:
        language = normalize_language(language)
    except UnsupportedLanguageError:
        raise HTTPException(
            status_code=400,
            detail="Unsupported language. Use Kannada, Hindi or English."
        )

    suffix = os.path.splitext(
        audio.filename or ".m4a"
    )[1].lower() or ".m4a"

    if suffix not in AUDIO_MIME_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Unsupported audio format"
        )

    with tempfile.NamedTemporaryFile(
        delete=False,
        suffix=suffix
    ) as temp_audio:
        temp_audio.write(audio_bytes)
        temp_audio_path = temp_audio.name

    try:
        # This endpoint is a plain `def`, so it already runs in
        # FastAPI's threadpool; the blocking call is safe here.
        analysis = process_audio(
            temp_audio_path,
            language=language
        )

    except GeminiUnavailableError:
        _mark_ai_failed(db, record_id)
        raise HTTPException(
            status_code=503,
            detail="The AI service is busy right now. "
                   "Your record is saved; please try processing it again in a few minutes."
        )

    except GeminiConfigurationError:
        raise HTTPException(
            status_code=500,
            detail="The AI service is not configured on the server."
        )

    except GeminiProcessingError:
        _mark_ai_failed(db, record_id)
        raise HTTPException(
            status_code=502,
            detail="The AI service could not process this audio. "
                   "Please record again or type the details."
        )

    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

    transcript = analysis.transcript
    english = analysis.english_translation
    analyzed = analysis.suggested_data()

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

