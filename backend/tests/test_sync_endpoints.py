"""
Offline-sync behaviour of the health-record endpoints:
idempotent create, GET by id, safe confirm retries and conflicts.

Run from the backend folder:
    python -m unittest discover -s tests -t .
"""

import unittest
from uuid import uuid4

from app.core.security import create_access_token
from tests.fakes import OTHER_WORKER_ID, FakeHealthRecordRepository as Repo
from tests.test_process_audio_endpoint import EndpointTestCase


CONFIRMED = {"patient_name": "Ravi", "age": 35, "symptoms": ["fever"], "duration": "2 days"}


class CreateIdempotencyTests(EndpointTestCase):

    def create(self, client_record_id=None, raw_input="[Voice recording]"):
        body = {"raw_input": raw_input, "input_language": "Kannada"}
        if client_record_id:
            body["client_record_id"] = client_record_id
        return self.client.post("/health-records", json=body, headers=self.headers)

    def test_same_client_id_twice_returns_same_record(self):
        client_id = str(uuid4())

        first = self.create(client_id)
        second = self.create(client_id)

        self.assertEqual(first.status_code, 200, first.text)
        self.assertEqual(second.status_code, 200, second.text)
        self.assertEqual(first.json()["id"], second.json()["id"])
        self.assertEqual(first.headers["X-Record-Created"], "true")
        self.assertEqual(second.headers["X-Record-Created"], "false")
        self.assertEqual(len(Repo.records), 1)

    def test_different_client_ids_create_different_records(self):
        self.create(str(uuid4()))
        self.create(str(uuid4()))
        self.assertEqual(len(Repo.records), 2)

    def test_old_app_without_client_id_still_works(self):
        response = self.create()

        self.assertEqual(response.status_code, 200)
        self.assertIsNone(response.json()["client_record_id"])
        self.assertEqual(response.json()["version"], 1)

    def test_invalid_client_id_is_rejected(self):
        self.assertEqual(self.create("not-a-uuid").status_code, 422)

    def test_empty_raw_input_is_rejected(self):
        self.assertEqual(self.create(str(uuid4()), raw_input="").status_code, 422)


class GetRecordTests(EndpointTestCase):

    def test_owner_can_read_record(self):
        record = Repo.add(ai_suggested_data={"age": 35})

        response = self.client.get(f"/health-records/{record['id']}", headers=self.headers)

        self.assertEqual(response.status_code, 200, response.text)
        body = response.json()
        self.assertEqual(body["id"], str(record["id"]))
        self.assertEqual(body["ai_suggested_data"], {"age": 35})
        self.assertIn("version", body)

    def test_other_workers_record_is_forbidden(self):
        record = Repo.add(worker_id=OTHER_WORKER_ID)
        response = self.client.get(f"/health-records/{record['id']}", headers=self.headers)
        self.assertEqual(response.status_code, 403)

    def test_unknown_record_is_404(self):
        response = self.client.get(f"/health-records/{uuid4()}", headers=self.headers)
        self.assertEqual(response.status_code, 404)

    def test_malformed_id_is_422_not_500(self):
        response = self.client.get("/health-records/not-a-uuid", headers=self.headers)
        self.assertEqual(response.status_code, 422)

    def test_requires_login(self):
        record = Repo.add()
        response = self.client.get(f"/health-records/{record['id']}")
        self.assertEqual(response.status_code, 401)


class ConfirmTests(EndpointTestCase):

    def confirm(self, record, data=CONFIRMED):
        return self.client.post(
            f"/health-records/{record['id']}/confirm", json=data, headers=self.headers
        )

    def test_first_confirm_saves_data(self):
        record = Repo.add()

        response = self.confirm(record)

        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()["record_status"], "confirmed")
        self.assertEqual(response.json()["confirmed_data"], CONFIRMED)

    def test_retrying_same_confirm_is_safe(self):
        record = Repo.add()
        first = self.confirm(record)
        second = self.confirm(record)

        self.assertEqual(second.status_code, 200, second.text)
        self.assertEqual(first.json()["version"], second.json()["version"])

    def test_confirm_with_different_data_is_a_conflict(self):
        record = Repo.add()
        self.confirm(record)

        response = self.confirm(record, {**CONFIRMED, "age": 36})

        self.assertEqual(response.status_code, 409)
        detail = response.json()["detail"]
        self.assertIn("message", detail)
        self.assertEqual(detail["server_record"]["confirmed_data"], CONFIRMED)
        # The server copy was not overwritten.
        self.assertEqual(Repo.records[record["id"]]["confirmed_data"]["age"], 35)

    def test_cannot_confirm_other_workers_record(self):
        record = Repo.add(worker_id=OTHER_WORKER_ID)
        self.assertEqual(self.confirm(record).status_code, 403)

    def test_implausible_age_is_rejected(self):
        record = Repo.add()
        self.assertEqual(self.confirm(record, {**CONFIRMED, "age": 400}).status_code, 422)


class TypedProcessTests(EndpointTestCase):

    def test_typed_record_is_processed_and_versioned(self):
        record = Repo.add(raw_input="Ramesh is 42 years old and has fever")

        response = self.client.post(f"/health-records/{record['id']}/process", headers=self.headers)

        self.assertEqual(response.status_code, 200, response.text)
        self.assertEqual(response.json()["ai_suggested_data"]["age"], 42)
        self.assertEqual(response.json()["version"], 2)

    def test_confirmed_typed_record_is_not_reprocessed(self):
        record = Repo.add(record_status="confirmed")
        response = self.client.post(f"/health-records/{record['id']}/process", headers=self.headers)
        self.assertEqual(response.status_code, 409)


if __name__ == "__main__":
    unittest.main()
