
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE teams (
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

    CONSTRAINT uq_teams_public_id UNIQUE (public_id),
    CONSTRAINT uq_teams_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_teams_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_teams_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_teams_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_teams_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_teams_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_teams_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_teams_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_teams_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_teams_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_teams_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_teams_tenant_created
    ON teams (tenant_id, created_at DESC);

CREATE INDEX idx_teams_user_created
    ON teams (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_teams_status_priority
    ON teams (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_teams_category_created
    ON teams (category, created_at DESC);

CREATE INDEX idx_teams_external
    ON teams (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_teams_metadata_gin
    ON teams USING gin (metadata);

CREATE INDEX idx_teams_payload_gin
    ON teams USING gin (payload);

CREATE INDEX idx_teams_tags_gin
    ON teams USING gin (tags);

CREATE INDEX idx_teams_lower_category
    ON teams (lower(category));

CREATE INDEX idx_teams_metadata_action
    ON teams ((metadata ->> 'action'));

CREATE INDEX idx_teams_amount_currency
    ON teams (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_teams_covering_dashboard
    ON teams (
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

CREATE TABLE teams_archive (
    LIKE teams INCLUDING ALL
);
