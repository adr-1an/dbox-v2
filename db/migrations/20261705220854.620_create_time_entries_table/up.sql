
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE time_entries (
    id BIGSERIAL PRIMARY KEY,

    public_id UUID NOT NULL DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL,
    user_id UUID,
    parent_id UUID,
    external_id VARCHAR(160),

    status VARCHAR(60) NOT NULL DEFAULT 'pending',
    category VARCHAR(120) NOT NULL,
    source VARCHAR(120),
    priority SMALLINT NOT NULL DEFAULT 5,

    amount NUMERIC(18, 6),
    quantity INTEGER,
    score DOUBLE PRECISION,
    confidence REAL,

    ip_address INET,
    country_code CHAR(2),
    currency CHAR(3),

    title VARCHAR(255),
    description TEXT,

    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    tags TEXT[] NOT NULL DEFAULT '{}',

    started_at TIMESTAMPTZ,
    finished_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT uq_time_entries_public_id UNIQUE (public_id),
    CONSTRAINT uq_time_entries_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_time_entries_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_time_entries_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_time_entries_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_time_entries_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_time_entries_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_time_entries_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_time_entries_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_time_entries_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_time_entries_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_time_entries_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_time_entries_tenant_created
    ON time_entries (tenant_id, created_at DESC);

CREATE INDEX idx_time_entries_user_created
    ON time_entries (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_time_entries_status_priority
    ON time_entries (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_time_entries_category_created
    ON time_entries (category, created_at DESC);

CREATE INDEX idx_time_entries_external
    ON time_entries (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_time_entries_metadata_gin
    ON time_entries USING gin (metadata);

CREATE INDEX idx_time_entries_payload_gin
    ON time_entries USING gin (payload);

CREATE INDEX idx_time_entries_tags_gin
    ON time_entries USING gin (tags);

CREATE INDEX idx_time_entries_lower_category
    ON time_entries (lower(category));

CREATE INDEX idx_time_entries_metadata_action
    ON time_entries ((metadata ->> 'action'));

CREATE INDEX idx_time_entries_amount_currency
    ON time_entries (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_time_entries_covering_dashboard
    ON time_entries (
        tenant_id,
        status,
        created_at DESC
    )
    INCLUDE (
        user_id,
        category,
        priority,
        amount,
        currency
    );

CREATE TABLE time_entries_archive (
    LIKE time_entries INCLUDING ALL
);
