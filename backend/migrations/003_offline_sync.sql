-- Offline-first sync support.
--
-- client_record_id: UUID generated on the phone when a record is first
--   saved. Unique per worker, so a retried upload returns the existing
--   row instead of creating a duplicate.
-- version: incremented on every server-side change, so the phone can
--   tell whether the server copy changed since it last looked.
--
-- Safe to run on an existing database: only adds columns and an index.

ALTER TABLE health_records
    ADD COLUMN IF NOT EXISTS client_record_id UUID;

ALTER TABLE health_records
    ADD COLUMN IF NOT EXISTS version INTEGER NOT NULL DEFAULT 1;

CREATE UNIQUE INDEX IF NOT EXISTS ux_health_records_worker_client_record
    ON health_records (worker_id, client_record_id)
    WHERE client_record_id IS NOT NULL;
