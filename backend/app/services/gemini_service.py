"""
Gemini audio processing for health records.

Takes a recorded voice note, asks Gemini for a transcript, an English
translation and the structured patient fields, and returns them as a
validated `AudioAnalysis` object.

Design notes
------------
* Model choice comes from the environment (GEMINI_MODEL and
  GEMINI_FALLBACK_MODELS), so a busy model can be swapped without code
  changes. Measured on this project's sample audio (2026-11-15):
  gemini-3.6-flash answered in ~3 s while gemini-3.8-flash took
  96-300 s because the service was overloaded.
* Every request has a hard timeout and only a couple of SDK retries,
  so a busy model fails fast and the next model in the list is tried,
  instead of the phone waiting for minutes.
* Gemini is asked for JSON matching a schema (structured output), so
  the backend no longer has to parse free text.
* The uploaded audio is deleted from Gemini as soon as processing
  ends; patient recordings should not stay on a third-party service.
* Logs contain model names, timings and error codes only, never the
  transcript or patient details.
"""

import logging
import os
import time
from functools import lru_cache

import httpx
from dotenv import load_dotenv
from google import genai
from google.genai import errors, types
from pydantic import BaseModel, Field, ValidationError, field_validator

load_dotenv()

logger = logging.getLogger(__name__)


# ============================================================
# CONFIGURATION
# ============================================================

DEFAULT_MODEL = "gemini-3.6-flash"
DEFAULT_FALLBACK_MODELS = "gemini-3.8-flash"

GEMINI_MODEL = os.getenv("GEMINI_MODEL", DEFAULT_MODEL).strip()

GEMINI_FALLBACK_MODELS = [
    name.strip()
    for name in os.getenv(
        "GEMINI_FALLBACK_MODELS",
        DEFAULT_FALLBACK_MODELS
    ).split(",")
    if name.strip() and name.strip() != GEMINI_MODEL
]

# Hard limit for one Gemini request, in seconds.
GEMINI_TIMEOUT_SECONDS = int(os.getenv("GEMINI_TIMEOUT_SECONDS", "60"))

# How long to wait for an uploaded file to become usable.
FILE_READY_TIMEOUT_SECONDS = 30

# HTTP status codes that mean "the service is busy, try again/elsewhere".
RETRYABLE_STATUS_CODES = {429, 500, 503, 504}

# Only languages the app actually offers. Anything else is rejected, so
# arbitrary client text never ends up inside the prompt.
SUPPORTED_LANGUAGES = {
    "kannada": "Kannada",
    "kn": "Kannada",
    "hindi": "Hindi",
    "hi": "Hindi",
    "english": "English",
    "en": "English",
}

# File extension -> MIME type for the formats the recorder can produce.
AUDIO_MIME_TYPES = {
    ".m4a": "audio/mp4",
    ".mp4": "audio/mp4",
    ".aac": "audio/aac",
    ".ogg": "audio/ogg",
    ".opus": "audio/ogg",
    ".wav": "audio/wav",
    ".mp3": "audio/mpeg",
    ".flac": "audio/flac",
}


# ============================================================
# ERRORS
# ============================================================

class GeminiError(Exception):
    """Base class for all Gemini processing failures."""


class GeminiConfigurationError(GeminiError):
    """The server is not configured to use Gemini (e.g. no API key)."""


class GeminiUnavailableError(GeminiError):
    """Every configured model was busy, rate limited or timed out."""


class GeminiProcessingError(GeminiError):
    """Gemini rejected the request or returned an unusable answer."""


class UnsupportedLanguageError(ValueError):
    """The requested spoken language is not supported."""


class UnsupportedAudioFormatError(ValueError):
    """The uploaded file is not an audio format Gemini accepts."""


# ============================================================
# RESULT SCHEMA
# ============================================================

class AudioAnalysis(BaseModel):
    transcript: str = Field(
        description="Word-for-word transcript in the spoken language."
    )
    english_translation: str = Field(
        description="Faithful English translation of the transcript."
    )
    patient_name: str | None = Field(
        default=None,
        description="Patient name if spoken, otherwise null."
    )
    age: int | None = Field(
        default=None,
        description="Patient age in years if spoken, otherwise null."
    )
    symptoms: list[str] = Field(
        default_factory=list,
        description="Symptoms mentioned, in English. Empty if none."
    )
    duration: str | None = Field(
        default=None,
        description="How long the symptoms have lasted, e.g. '2 days'."
    )

    @field_validator("patient_name", "duration", mode="before")
    @classmethod
    def blank_to_none(cls, value):
        if isinstance(value, str) and not value.strip():
            return None
        return value.strip() if isinstance(value, str) else value

    @field_validator("age")
    @classmethod
    def plausible_age(cls, value):
        # An implausible age is almost certainly a mis-hearing; leave it
        # empty so the health worker fills it in during review.
        if value is not None and not 0 <= value <= 120:
            return None
        return value

    @field_validator("symptoms", mode="before")
    @classmethod
    def clean_symptoms(cls, value):
        if value is None:
            return []
        return [s.strip() for s in value if isinstance(s, str) and s.strip()]

    def suggested_data(self) -> dict:
        """The fields the health worker reviews and confirms."""
        return {
            "patient_name": self.patient_name,
            "age": self.age,
            "symptoms": self.symptoms,
            "duration": self.duration,
        }


# ============================================================
# HELPERS
# ============================================================

def normalize_language(language: str | None) -> str:
    key = (language or "Kannada").strip().lower()

    if key not in SUPPORTED_LANGUAGES:
        raise UnsupportedLanguageError(
            f"Unsupported language: {language!r}"
        )

    return SUPPORTED_LANGUAGES[key]


def audio_mime_type(path: str) -> str:
    extension = os.path.splitext(path)[1].lower()

    if extension not in AUDIO_MIME_TYPES:
        raise UnsupportedAudioFormatError(
            f"Unsupported audio format: {extension or 'none'}"
        )

    return AUDIO_MIME_TYPES[extension]


def build_prompt(language: str) -> str:
    return f"""
You are helping a community health worker in India record a patient visit.
The attached audio is spoken in {language}.

1. transcript: write exactly what was said, in {language}.
2. english_translation: translate the transcript faithfully into English.
3. From what was actually said, extract:
   - patient_name
   - age (in years, as a number)
   - symptoms (a list of short English terms)
   - duration (how long the symptoms have lasted, e.g. "2 days")

Rules:
- Use only information that was spoken. Never guess or invent details.
- If a field was not mentioned, use null (or an empty list for symptoms).
- Do not add diagnoses, advice or anything else.
""".strip()


@lru_cache(maxsize=1)
def get_client() -> genai.Client:
    """Create the Gemini client on first use, not at import time, so a
    missing key fails one request with a clear error instead of
    crashing the whole backend on startup."""
    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        raise GeminiConfigurationError(
            "GEMINI_API_KEY is not configured"
        )

    return genai.Client(
        api_key=api_key,
        http_options=types.HttpOptions(
            timeout=GEMINI_TIMEOUT_SECONDS * 1000,  # milliseconds
            retry_options=types.HttpRetryOptions(
                attempts=2,
                initial_delay=1.0,
                max_delay=4.0,
                http_status_codes=sorted(RETRYABLE_STATUS_CODES),
            ),
        ),
    )


def _wait_until_active(client: genai.Client, uploaded: types.File) -> types.File:
    deadline = time.monotonic() + FILE_READY_TIMEOUT_SECONDS

    while uploaded.state == types.FileState.PROCESSING:
        if time.monotonic() > deadline:
            raise GeminiUnavailableError(
                "Uploaded audio was not ready in time"
            )

        time.sleep(1)
        uploaded = client.files.get(name=uploaded.name)

    if uploaded.state == types.FileState.FAILED:
        raise GeminiProcessingError("Gemini could not read the audio file")

    return uploaded


def _generate(
    client: genai.Client,
    model: str,
    uploaded: types.File,
    prompt: str
) -> AudioAnalysis:
    response = client.models.generate_content(
        model=model,
        contents=[uploaded, prompt],
        config=types.GenerateContentConfig(
            temperature=0,
            response_mime_type="application/json",
            response_schema=AudioAnalysis,
        ),
    )

    if isinstance(response.parsed, AudioAnalysis):
        return response.parsed

    # Fall back to validating the raw text ourselves.
    try:
        return AudioAnalysis.model_validate_json(response.text or "")
    except ValidationError as e:
        raise GeminiProcessingError(
            "Gemini returned a response in an unexpected format"
        ) from e


# ============================================================
# PUBLIC API
# ============================================================

def process_audio(audio_path: str, language: str = "Kannada") -> AudioAnalysis:
    """
    Transcribe, translate and analyse one audio file.

    Blocking: call it from a plain `def` FastAPI endpoint (which runs in
    the threadpool) or via `run_in_threadpool`.

    Raises:
        UnsupportedLanguageError, UnsupportedAudioFormatError
        GeminiConfigurationError
        GeminiUnavailableError   - all models busy / timed out
        GeminiProcessingError    - request rejected / unusable answer
    """
    language = normalize_language(language)
    mime_type = audio_mime_type(audio_path)
    client = get_client()
    prompt = build_prompt(language)
    models = [GEMINI_MODEL, *GEMINI_FALLBACK_MODELS]

    try:
        uploaded = client.files.upload(
            file=audio_path,
            config=types.UploadFileConfig(mime_type=mime_type),
        )
    except (errors.ServerError, httpx.TimeoutException, httpx.TransportError) as e:
        logger.warning("Gemini audio upload failed: %r", e)
        raise GeminiUnavailableError("Could not upload audio to Gemini") from e
    except errors.ClientError as e:
        logger.warning("Gemini rejected audio upload: code=%s", e.code)
        raise GeminiProcessingError("Gemini rejected the audio upload") from e

    try:
        uploaded = _wait_until_active(client, uploaded)
        last_error: Exception | None = None

        for model in models:
            started = time.monotonic()

            try:
                result = _generate(client, model, uploaded, prompt)

                logger.info(
                    "Gemini audio processed: model=%s seconds=%.1f",
                    model,
                    time.monotonic() - started,
                )

                return result

            except errors.APIError as e:
                elapsed = time.monotonic() - started

                if e.code in RETRYABLE_STATUS_CODES:
                    logger.warning(
                        "Gemini model busy: model=%s code=%s seconds=%.1f",
                        model, e.code, elapsed,
                    )
                    last_error = e
                    continue

                logger.warning(
                    "Gemini request rejected: model=%s code=%s status=%s",
                    model, e.code, e.status,
                )
                raise GeminiProcessingError(
                    "Gemini could not process the audio"
                ) from e

            except (httpx.TimeoutException, httpx.TransportError) as e:
                logger.warning(
                    "Gemini request timed out or failed: model=%s seconds=%.1f",
                    model, time.monotonic() - started,
                )
                last_error = e
                continue

        raise GeminiUnavailableError(
            "All Gemini models are busy"
        ) from last_error

    finally:
        try:
            client.files.delete(name=uploaded.name)
        except Exception as e:  # never hide the real result/error
            logger.warning("Could not delete uploaded audio from Gemini: %r", e)
