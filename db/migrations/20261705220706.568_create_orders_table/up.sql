
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE orders (
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

    CONSTRAINT uq_orders_public_id UNIQUE (public_id),
    CONSTRAINT uq_orders_tenant_external UNIQUE (tenant_id, external_id),

    CONSTRAINT chk_orders_status CHECK (
        status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'archived')
    ),

    CONSTRAINT chk_orders_priority CHECK (
        priority BETWEEN 1 AND 10
    ),

    CONSTRAINT chk_orders_amount CHECK (
        amount IS NULL OR amount >= 0
    ),

    CONSTRAINT chk_orders_quantity CHECK (
        quantity IS NULL OR quantity >= 0
    ),

    CONSTRAINT chk_orders_confidence CHECK (
        confidence IS NULL OR confidence BETWEEN 0 AND 1
    ),

    CONSTRAINT chk_orders_country_code CHECK (
        country_code IS NULL OR country_code ~ '^[A-Z]{2}$'
    ),

    CONSTRAINT chk_orders_currency CHECK (
        currency IS NULL OR currency ~ '^[A-Z]{3}$'
    ),

    CONSTRAINT chk_orders_json_shapes CHECK (
        jsonb_typeof(metadata) = 'object'
        AND jsonb_typeof(payload) = 'object'
    ),

    CONSTRAINT chk_orders_dates CHECK (
        finished_at IS NULL OR started_at IS NULL OR finished_at >= started_at
    ),

    CONSTRAINT chk_orders_expires CHECK (
        expires_at IS NULL OR expires_at >= created_at
    )
);

CREATE INDEX idx_orders_tenant_created
    ON orders (tenant_id, created_at DESC);

CREATE INDEX idx_orders_user_created
    ON orders (user_id, created_at DESC)
    WHERE user_id IS NOT NULL;

CREATE INDEX idx_orders_status_priority
    ON orders (status, priority DESC, created_at ASC)
    WHERE status IN ('pending', 'processing', 'failed');

CREATE INDEX idx_orders_category_created
    ON orders (category, created_at DESC);

CREATE INDEX idx_orders_external
    ON orders (tenant_id, external_id)
    WHERE external_id IS NOT NULL;

CREATE INDEX idx_orders_metadata_gin
    ON orders USING gin (metadata);

CREATE INDEX idx_orders_payload_gin
    ON orders USING gin (payload);

CREATE INDEX idx_orders_tags_gin
    ON orders USING gin (tags);

CREATE INDEX idx_orders_lower_category
    ON orders (lower(category));

CREATE INDEX idx_orders_metadata_action
    ON orders ((metadata ->> 'action'));

CREATE INDEX idx_orders_amount_currency
    ON orders (currency, amount DESC)
    WHERE amount IS NOT NULL;

CREATE INDEX idx_orders_covering_dashboard
    ON orders (
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

CREATE TABLE orders_archive (
    LIKE orders INCLUDING ALL
);
