"""
Endpoint tests for POST /health-records/{record_id}/process-audio.

The database and Gemini are both faked, so this checks the HTTP
behaviour only: status codes, response shape and what gets saved.

Run from the backend folder:
    python -m unittest discover -s tests -v
"""

import json
import unittest
from unittest import mock

import tests  # noqa: F401  (sets dummy environment variables)

from fastapi.testclient import TestClient

from app.core.security import create_access_token
from app.infrastructure.db_dependency import get_db
from app.main import app
from app.modules.auth.infrastructure.user_repository import UserRepository
from app.modules.records.api import health_records
from app.services import gemini_service as gs


WORKER_ID = "11111111-1111-1111-1111-111111111111"
RECORD_ID = "22222222-2222-2222-2222-222222222222"


class FakeCursor:
    def __init__(self, db):
        self.db = db
        self.result = None

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False

    def execute(self, sql, params):
        self.db.statements.append((" ".join(sql.split()), params))

        if sql.strip().startswith("SELECT"):
            self.result = (RECORD_ID, WORKER_ID, "[Voice recording]", "Kannada", self.db.record_status)
        elif "RETURNING" in sql:
            transcript, english, suggested, record_id = params
            self.result = (record_id, WORKER_ID, transcript, english,
                           json.loads(suggested), "pending_review", self.db.record_status)

    def fetchone(self):
        return self.result


class FakeDB:
    def __init__(self, record_status="draft"):
        self.record_status = record_status
        self.statements = []
        self.commits = 0

    def cursor(self):
        return FakeCursor(self)

    def commit(self):
        self.commits += 1

    def rollback(self):
        pass

    def updates(self):
        return [sql for sql, _ in self.statements if sql.startswith("UPDATE")]


ANALYSIS = gs.AudioAnalysis(
    transcript="ರವಿ ಕುಮಾರ್ ...",
    english_translation="Ravi Kumar, 35, fever for two days",
    patient_name="Ravi Kumar",
    age=35,
    symptoms=["fever"],
    duration="2 days",
)


class ProcessAudioEndpointTests(unittest.TestCase):

    def setUp(self):
        self.db = FakeDB()
        app.dependency_overrides[get_db] = lambda: self.db
        self.addCleanup(app.dependency_overrides.clear)

        patcher = mock.patch.object(
            UserRepository, "get_user_by_username",
            lambda self, username: (WORKER_ID, username, "hash", "asha", "Test", True),
        )
        patcher.start()
        self.addCleanup(patcher.stop)

        self.client = TestClient(app)
        self.headers = {"Authorization": f"Bearer {create_access_token('asha1', 'asha')}"}

    def post(self, filename="note.m4a", content=b"fake audio", language="Kannada"):
        return self.client.post(
            f"/health-records/{RECORD_ID}/process-audio",
            headers=self.headers,
            files={"audio": (filename, content, "audio/mp4")},
            data={"language": language},
        )

    def test_success_returns_fields_the_app_reads(self):
        with mock.patch.object(health_records, "process_audio", return_value=ANALYSIS):
            response = self.post()

        self.assertEqual(response.status_code, 200, response.text)
        body = response.json()
        self.assertEqual(body["transcript"], ANALYSIS.transcript)
        self.assertEqual(body["english"], ANALYSIS.english_translation)
        self.assertEqual(body["analyzed"], {
            "patient_name": "Ravi Kumar", "age": 35,
            "symptoms": ["fever"], "duration": "2 days",
        })
        self.assertEqual(body["ai_status"], "pending_review")

    def test_busy_ai_returns_503_and_marks_record_failed(self):
        with mock.patch.object(health_records, "process_audio",
                               side_effect=gs.GeminiUnavailableError("busy")):
            response = self.post()

        self.assertEqual(response.status_code, 503)
        self.assertIn("busy", response.json()["detail"])
        self.assertTrue(any("ai_status = 'failed'" in sql for sql in self.db.updates()))

    def test_unusable_ai_answer_returns_502(self):
        with mock.patch.object(health_records, "process_audio",
                               side_effect=gs.GeminiProcessingError("bad")):
            response = self.post()

        self.assertEqual(response.status_code, 502)

    def test_unsupported_language_is_rejected_before_calling_ai(self):
        with mock.patch.object(health_records, "process_audio") as fake:
            response = self.post(language="Klingon")

        self.assertEqual(response.status_code, 400)
        fake.assert_not_called()

    def test_unsupported_file_type_is_rejected_before_calling_ai(self):
        with mock.patch.object(health_records, "process_audio") as fake:
            response = self.post(filename="virus.exe")

        self.assertEqual(response.status_code, 415)
        fake.assert_not_called()

    def test_empty_audio_is_rejected(self):
        with mock.patch.object(health_records, "process_audio") as fake:
            response = self.post(content=b"")

        self.assertEqual(response.status_code, 400)
        fake.assert_not_called()

    def test_confirmed_record_cannot_be_reprocessed(self):
        self.db.record_status = "confirmed"

        with mock.patch.object(health_records, "process_audio") as fake:
            response = self.post()

        self.assertEqual(response.status_code, 409)
        fake.assert_not_called()


if __name__ == "__main__":
    unittest.main()
