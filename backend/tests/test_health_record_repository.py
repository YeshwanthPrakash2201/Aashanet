"""
Real-SQL tests for HealthRecordRepository.

Skipped unless TEST_DATABASE_URL is set. Everything runs inside one
transaction that is rolled back at the end, so the database is left
exactly as it was (commits made by the repository are turned into
no-ops for the duration of the test).

    $env:TEST_DATABASE_URL = "postgresql://..."
    python -m unittest tests.test_health_record_repository -v
"""

import os
import unittest
from uuid import uuid4

import tests  # noqa: F401

import psycopg

from app.modules.records.infrastructure.health_record_repository import (
    ConfirmConflict,
    HealthRecordRepository,
)

DATABASE_URL = os.getenv("TEST_DATABASE_URL")


class _NoCommit:
    """Wraps a connection so repository commits do not end the test transaction."""

    def __init__(self, conn):
        self._conn = conn

    def commit(self):
        pass

    def cursor(self, *args, **kwargs):
        return self._conn.cursor(*args, **kwargs)


@unittest.skipUnless(DATABASE_URL, "set TEST_DATABASE_URL to run real-database tests")
class HealthRecordRepositoryTests(unittest.TestCase):

    def setUp(self):
        self.conn = psycopg.connect(DATABASE_URL)
        self.addCleanup(self.conn.close)
        self.addCleanup(self.conn.rollback)

        with self.conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO users (id, username, password_hash, role, full_name)
                VALUES (gen_random_uuid(), %s, 'x', 'asha_worker', 'Repository Test')
                RETURNING id
                """,
                (f"repo_test_{uuid4().hex[:8]}",),
            )
            self.worker_id = cur.fetchone()[0]

        self.repo = HealthRecordRepository(_NoCommit(self.conn))

    def test_create_is_idempotent_per_client_id(self):
        client_id = uuid4()

        first, created_first = self.repo.create(self.worker_id, "note", "Kannada", client_id)
        second, created_second = self.repo.create(self.worker_id, "note", "Kannada", client_id)

        self.assertTrue(created_first)
        self.assertFalse(created_second)
        self.assertEqual(first["id"], second["id"])

        with self.conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM health_records WHERE client_record_id = %s",
                (client_id,),
            )
            self.assertEqual(cur.fetchone()[0], 1)

    def test_records_without_client_id_are_never_merged(self):
        a, _ = self.repo.create(self.worker_id, "note", None, None)
        b, _ = self.repo.create(self.worker_id, "note", None, None)
        self.assertNotEqual(a["id"], b["id"])

    def test_every_write_bumps_version(self):
        record, _ = self.repo.create(self.worker_id, "note", None, uuid4())
        self.assertEqual(record["version"], 1)

        record = self.repo.save_ai_result(record["id"], {"age": 3}, "t", "e")
        self.assertEqual(record["version"], 2)
        self.assertEqual(record["ai_transcript"], "t")

        record, changed = self.repo.confirm(record["id"], {"age": 3})
        self.assertTrue(changed)
        self.assertEqual(record["version"], 3)

    def test_confirm_retry_and_conflict(self):
        record, _ = self.repo.create(self.worker_id, "note", None, uuid4())
        self.repo.confirm(record["id"], {"age": 3})

        again, changed = self.repo.confirm(record["id"], {"age": 3})
        self.assertFalse(changed)

        with self.assertRaises(ConfirmConflict) as ctx:
            self.repo.confirm(record["id"], {"age": 4})

        self.assertEqual(ctx.exception.server_record["confirmed_data"], {"age": 3})
        self.assertEqual(self.repo.get(record["id"])["confirmed_data"], {"age": 3})

    def test_mark_ai_failed_leaves_confirmed_records_alone(self):
        record, _ = self.repo.create(self.worker_id, "note", None, uuid4())
        self.repo.confirm(record["id"], {"age": 3})

        self.repo.mark_ai_failed(record["id"])

        self.assertEqual(self.repo.get(record["id"])["ai_status"], "pending_review")


if __name__ == "__main__":
    unittest.main()
