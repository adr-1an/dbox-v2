
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE content_pages (
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

    CONSTRAINT uq_content_pages_public_id UNIQUE (public_id),
    CONSTRAINT uq_content_pages_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_content_pages_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_content_pages_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_content_pages_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_content_pages_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_content_pages_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_content_pages_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_content_pages_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_content_pages_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_content_pages_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_content_pages_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_content_pages_tenant_created
    ON content_pages (tenant_id, created_at DESC);

CREATE INDEX idx_content_pages_user_created
    ON content_pages (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_content_pages_status_priority
    ON content_pages (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_content_pages_category_created
    ON content_pages (category, created_at DESC);

CREATE INDEX idx_content_pages_external
    ON content_pages (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_content_pages_metadata_gin
    ON content_pages USING gin (metadata);

CREATE INDEX idx_content_pages_payload_gin
    ON content_pages USING gin (payload);

CREATE INDEX idx_content_pages_tags_gin
    ON content_pages USING gin (tags);

CREATE INDEX idx_content_pages_lower_category
    ON content_pages (lower(category));

CREATE INDEX idx_content_pages_metadata_action
    ON content_pages ((metadata ->> 'action'));

CREATE INDEX idx_content_pages_amount_currency
    ON content_pages (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_content_pages_covering_dashboard
    ON content_pages (
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

CREATE TABLE content_pages_archive (
    LIKE content_pages INCLUDING ALL
);
