
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE reports (
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

    CONSTRAINT uq_reports_public_id UNIQUE (public_id),
    CONSTRAINT uq_reports_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_reports_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_reports_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_reports_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_reports_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_reports_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_reports_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_reports_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_reports_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_reports_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_reports_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_reports_tenant_created
    ON reports (tenant_id, created_at DESC);

CREATE INDEX idx_reports_user_created
    ON reports (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_reports_status_priority
    ON reports (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_reports_category_created
    ON reports (category, created_at DESC);

CREATE INDEX idx_reports_external
    ON reports (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_reports_metadata_gin
    ON reports USING gin (metadata);

CREATE INDEX idx_reports_payload_gin
    ON reports USING gin (payload);

CREATE INDEX idx_reports_tags_gin
    ON reports USING gin (tags);

CREATE INDEX idx_reports_lower_category
    ON reports (lower(category));

CREATE INDEX idx_reports_metadata_action
    ON reports ((metadata ->> 'action'));

CREATE INDEX idx_reports_amount_currency
    ON reports (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_reports_covering_dashboard
    ON reports (
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

CREATE TABLE reports_archive (
    LIKE reports INCLUDING ALL
);
