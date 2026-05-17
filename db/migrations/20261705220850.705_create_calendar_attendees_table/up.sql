
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE calendar_attendees (
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

    CONSTRAINT uq_calendar_attendees_public_id UNIQUE (public_id),
    CONSTRAINT uq_calendar_attendees_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_calendar_attendees_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_calendar_attendees_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_calendar_attendees_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_calendar_attendees_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_calendar_attendees_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_calendar_attendees_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_calendar_attendees_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_calendar_attendees_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_calendar_attendees_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_calendar_attendees_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_calendar_attendees_tenant_created
    ON calendar_attendees (tenant_id, created_at DESC);

CREATE INDEX idx_calendar_attendees_user_created
    ON calendar_attendees (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_calendar_attendees_status_priority
    ON calendar_attendees (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_calendar_attendees_category_created
    ON calendar_attendees (category, created_at DESC);

CREATE INDEX idx_calendar_attendees_external
    ON calendar_attendees (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_calendar_attendees_metadata_gin
    ON calendar_attendees USING gin (metadata);

CREATE INDEX idx_calendar_attendees_payload_gin
    ON calendar_attendees USING gin (payload);

CREATE INDEX idx_calendar_attendees_tags_gin
    ON calendar_attendees USING gin (tags);

CREATE INDEX idx_calendar_attendees_lower_category
    ON calendar_attendees (lower(category));

CREATE INDEX idx_calendar_attendees_metadata_action
    ON calendar_attendees ((metadata ->> 'action'));

CREATE INDEX idx_calendar_attendees_amount_currency
    ON calendar_attendees (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_calendar_attendees_covering_dashboard
    ON calendar_attendees (
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

CREATE TABLE calendar_attendees_archive (
    LIKE calendar_attendees INCLUDING ALL
);
