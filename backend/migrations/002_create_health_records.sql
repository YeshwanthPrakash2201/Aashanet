CREATE TABLE health_records (
    id UUID PRIMARY KEY,

    worker_id UUID NOT NULL REFERENCES users(id),

    raw_input TEXT NOT NULL,

    input_language VARCHAR(20),

    ai_transcript TEXT,

    ai_translated_text TEXT,

    ai_suggested_data JSONB,

    confirmed_data JSONB,

    ai_status VARCHAR(30) NOT NULL DEFAULT 'pending_review',

    record_status VARCHAR(30) NOT NULL DEFAULT 'draft',

    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);


CREATE INDEX idx_health_records_worker_id
ON health_records(worker_id);


CREATE INDEX idx_health_records_ai_status
ON health_records(ai_status);


CREATE INDEX idx_health_records_record_status
ON health_records(record_status);