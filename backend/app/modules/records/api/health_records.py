import os
import tempfile
from uuid import UUID

from fastapi import (
    APIRouter,
    Depends,
    HTTPException,
    Response,
    UploadFile,
    File,
    Form
)
from fastapi.encoders import jsonable_encoder
from psycopg import Connection

from app.core.auth import get_current_user
from app.infrastructure.db_dependency import get_db

from app.modules.auth.infrastructure.user_repository import UserRepository
from app.modules.records.application.health_record_service import HealthRecordService
from app.modules.records.infrastructure.health_record_repository import (
    ConfirmConflict,
    HealthRecordRepository,
)
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


router = APIRouter(
    prefix="/health-records",
    tags=["Health Records"]
)


# ============================================================
# HELPERS
# ============================================================

def _current_worker(db: Connection, current_user: dict):
    worker = UserRepository(db).get_user_by_username(current_user["sub"])

    if not worker:
        raise HTTPException(status_code=404, detail="Worker not found")

    return worker


def _owned_record(
    repository: HealthRecordRepository,
    record_id: UUID,
    worker,
    action: str,
) -> dict:
    record = repository.get(record_id)

    if not record:
        raise HTTPException(status_code=404, detail="Health record not found")

    if str(record["worker_id"]) != str(worker[0]):
        raise HTTPException(
            status_code=403,
            detail=f"You cannot {action} this record"
        )

    return record


def _reject_if_confirmed(record: dict) -> None:
    if record["record_status"] == "confirmed":
        raise HTTPException(
            status_code=409,
            detail="Health record is already confirmed"
        )


def _base(record: dict) -> dict:
    return {
        "id": str(record["id"]),
        "worker_id": str(record["worker_id"]),
        "client_record_id": (
            str(record["client_record_id"])
            if record["client_record_id"] else None
        ),
        "ai_status": record["ai_status"],
        "record_status": record["record_status"],
        "version": record["version"],
    }


def full_record(record: dict) -> dict:
    """Everything the phone needs to resume or check a record."""
    return {
        **_base(record),
        "raw_input": record["raw_input"],
        "input_language": record["input_language"],
        "transcript": record["ai_transcript"],
        "english": record["ai_translated_text"],
        "ai_suggested_data": record["ai_suggested_data"],
        "confirmed_data": record["confirmed_data"],
        "created_at": jsonable_encoder(record["created_at"]),
        "updated_at": jsonable_encoder(record["updated_at"]),
    }


# ============================================================
# CREATE HEALTH RECORD
#
# Idempotent when `client_record_id` is sent: a retry returns the record
# created the first time (HTTP 200) instead of a duplicate. A brand-new
# record is also returned with 200, as before, so existing app versions
# keep working; the `X-Record-Created` header tells the two apart.
# ============================================================

@router.post(
    "",
    response_model=HealthRecordResponse
)
def create_health_record(
    record: HealthRecordCreate,
    response: Response,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    worker = _current_worker(db, current_user)
    service = HealthRecordService(HealthRecordRepository(db))

    created_record, created = service.create_health_record(
        worker_id=worker[0],
        raw_input=record.raw_input,
        input_language=record.input_language,
        client_record_id=record.client_record_id,
    )

    response.headers["X-Record-Created"] = "true" if created else "false"

    return {
        **_base(created_record),
        "raw_input": created_record["raw_input"],
        "input_language": created_record["input_language"],
    }


# ============================================================
# GET ONE HEALTH RECORD
# Lets the phone check the server copy before retrying or confirming.
# ============================================================

@router.get("/{record_id}")
def get_health_record(
    record_id: UUID,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    worker = _current_worker(db, current_user)
    record = _owned_record(HealthRecordRepository(db), record_id, worker, "view")

    return full_record(record)


# ============================================================
# PROCESS TYPED HEALTH RECORD
# ============================================================

@router.post("/{record_id}/process")
def process_health_record(
    record_id: UUID,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    worker = _current_worker(db, current_user)
    repository = HealthRecordRepository(db)
    record = _owned_record(repository, record_id, worker, "process")
    _reject_if_confirmed(record)

    suggested_data = HealthRecordAIService().process(record["raw_input"])
    updated = repository.save_ai_result(record_id, suggested_data)

    return {
        **_base(updated),
        "raw_input": updated["raw_input"],
        "input_language": updated["input_language"],
        "ai_suggested_data": updated["ai_suggested_data"],
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
    record_id: UUID,
    audio: UploadFile = File(...),
    language: str = Form("Kannada"),
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    worker = _current_worker(db, current_user)
    repository = HealthRecordRepository(db)
    record = _owned_record(repository, record_id, worker, "process")
    _reject_if_confirmed(record)

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
        repository.mark_ai_failed(record_id)
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
        repository.mark_ai_failed(record_id)
        raise HTTPException(
            status_code=502,
            detail="The AI service could not process this audio. "
                   "Please record again or type the details."
        )

    finally:
        if os.path.exists(temp_audio_path):
            os.remove(temp_audio_path)

    updated = repository.save_ai_result(
        record_id,
        analysis.suggested_data(),
        transcript=analysis.transcript,
        translated_text=analysis.english_translation,
    )

    return {
        **_base(updated),
        "transcript": updated["ai_transcript"],
        "english": updated["ai_translated_text"],
        "analyzed": updated["ai_suggested_data"],
    }


# ============================================================
# CONFIRM HEALTH RECORD
#
# Safe to retry: confirming again with the same data returns 200.
# Confirming an already-confirmed record with *different* data returns
# 409 with the server copy, so neither version is silently overwritten.
# ============================================================

@router.post("/{record_id}/confirm")
def confirm_health_record(
    record_id: UUID,
    confirmed_record: HealthRecordConfirm,
    db: Connection = Depends(get_db),
    current_user: dict = Depends(get_current_user)
):
    worker = _current_worker(db, current_user)
    repository = HealthRecordRepository(db)
    _owned_record(repository, record_id, worker, "confirm")

    confirmed_data = {
        "patient_name": confirmed_record.patient_name,
        "age": confirmed_record.age,
        "symptoms": confirmed_record.symptoms,
        "duration": confirmed_record.duration
    }

    try:
        updated, _changed = repository.confirm(record_id, confirmed_data)

    except ConfirmConflict as conflict:
        raise HTTPException(
            status_code=409,
            detail={
                "message": "This record was already confirmed with different details.",
                "server_record": full_record(conflict.server_record),
            }
        )

    return {
        **_base(updated),
        "raw_input": updated["raw_input"],
        "input_language": updated["input_language"],
        "ai_suggested_data": updated["ai_suggested_data"],
        "confirmed_data": updated["confirmed_data"],
    }
