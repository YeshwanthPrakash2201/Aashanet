"""
Endpoint tests for POST /health-records/{record_id}/process-audio.

The database and Gemini are both faked, so this checks the HTTP
behaviour only: status codes, response shape and what gets saved.

Run from the backend folder:
    python -m unittest discover -s tests -t .
"""

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
from tests.fakes import WORKER_ID, FakeHealthRecordRepository as Repo


ANALYSIS = gs.AudioAnalysis(
    transcript="ರವಿ ಕುಮಾರ್ ...",
    english_translation="Ravi Kumar, 35, fever for two days",
    patient_name="Ravi Kumar",
    age=35,
    symptoms=["fever"],
    duration="2 days",
)


class EndpointTestCase(unittest.TestCase):
    """Shared setup: fake repository, fake user lookup, logged-in worker."""

    def setUp(self):
        Repo.reset()
        app.dependency_overrides[get_db] = lambda: object()
        self.addCleanup(app.dependency_overrides.clear)

        for patcher in (
            mock.patch.object(health_records, "HealthRecordRepository", Repo),
            mock.patch.object(
                UserRepository, "get_user_by_username",
                lambda self, username: (WORKER_ID, username, "hash", "asha_worker", "Test", True),
            ),
        ):
            patcher.start()
            self.addCleanup(patcher.stop)

        self.client = TestClient(app)
        self.headers = {
            "Authorization": f"Bearer {create_access_token('asha1', 'asha_worker')}"
        }


class ProcessAudioEndpointTests(EndpointTestCase):

    def setUp(self):
        super().setUp()
        self.record = Repo.add()

    def post(self, filename="note.m4a", content=b"fake audio", language="Kannada"):
        return self.client.post(
            f"/health-records/{self.record['id']}/process-audio",
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
        self.assertEqual(body["version"], 2)

    def test_busy_ai_returns_503_and_marks_record_failed(self):
        with mock.patch.object(health_records, "process_audio",
                               side_effect=gs.GeminiUnavailableError("busy")):
            response = self.post()

        self.assertEqual(response.status_code, 503)
        self.assertIn("busy", response.json()["detail"])
        self.assertEqual(Repo.records[self.record["id"]]["ai_status"], "failed")

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
        Repo.records[self.record["id"]]["record_status"] = "confirmed"

        with mock.patch.object(health_records, "process_audio") as fake:
            response = self.post()

        self.assertEqual(response.status_code, 409)
        fake.assert_not_called()


if __name__ == "__main__":
    unittest.main()
