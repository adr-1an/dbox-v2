
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE forms (
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

    CONSTRAINT uq_forms_public_id UNIQUE (public_id),
    CONSTRAINT uq_forms_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_forms_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_forms_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_forms_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_forms_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_forms_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_forms_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_forms_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_forms_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_forms_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_forms_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_forms_tenant_created
    ON forms (tenant_id, created_at DESC);

CREATE INDEX idx_forms_user_created
    ON forms (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_forms_status_priority
    ON forms (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_forms_category_created
    ON forms (category, created_at DESC);

CREATE INDEX idx_forms_external
    ON forms (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_forms_metadata_gin
    ON forms USING gin (metadata);

CREATE INDEX idx_forms_payload_gin
    ON forms USING gin (payload);

CREATE INDEX idx_forms_tags_gin
    ON forms USING gin (tags);

CREATE INDEX idx_forms_lower_category
    ON forms (lower(category));

CREATE INDEX idx_forms_metadata_action
    ON forms ((metadata ->> 'action'));

CREATE INDEX idx_forms_amount_currency
    ON forms (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_forms_covering_dashboard
    ON forms (
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

CREATE TABLE forms_archive (
    LIKE forms INCLUDING ALL
);
