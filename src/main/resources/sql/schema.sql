BEGIN;

CREATE TABLE customer (
    customer_id     BIGSERIAL       PRIMARY KEY,
    customer_code   VARCHAR(32)     NOT NULL UNIQUE,
    full_name       VARCHAR(150)    NOT NULL CHECK (btrim(full_name) <> ''),
    email           VARCHAR(255)    NOT NULL UNIQUE CHECK (position('@' IN email) > 1),
    phone_number    VARCHAR(20),
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                                    CHECK (status IN ('ACTIVE', 'SUSPENDED', 'CLOSED')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE account (
    account_id      BIGSERIAL       PRIMARY KEY,
    account_number  VARCHAR(32)     NOT NULL UNIQUE,
    customer_id     BIGINT          NOT NULL REFERENCES customer(customer_id) ON DELETE RESTRICT,
    account_type    VARCHAR(20)     NOT NULL DEFAULT 'SAVINGS'
                                    CHECK (account_type IN ('SAVINGS', 'CHECKING', 'CURRENT')),
    currency_code   CHAR(3)         NOT NULL DEFAULT 'INR'
                                    CHECK (currency_code ~ '^[A-Z]{3}$'),
    balance         NUMERIC(19, 4)  NOT NULL DEFAULT 0.0000
                                    CHECK (balance >= 0.0000),
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE'
                                    CHECK (status IN ('ACTIVE', 'FROZEN', 'CLOSED')),
    version         BIGINT          NOT NULL DEFAULT 0 CHECK (version >= 0),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE transaction (
    txn_pk_id               BIGSERIAL       PRIMARY KEY,
    transaction_id          VARCHAR(64)     NOT NULL UNIQUE,
    txn_type                VARCHAR(20)     NOT NULL
                                            CHECK (txn_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')),
    source_account_id       BIGINT          REFERENCES account(account_id) ON DELETE RESTRICT,
    destination_account_id  BIGINT          REFERENCES account(account_id) ON DELETE RESTRICT,
    amount                  NUMERIC(19, 4)  NOT NULL CHECK (amount > 0.0000),
    currency_code           CHAR(3)         NOT NULL DEFAULT 'INR'
                                            CHECK (currency_code ~ '^[A-Z]{3}$'),
    status                  VARCHAR(20)     NOT NULL
                                            CHECK (status IN ('SUCCESS', 'FAILED', 'REJECTED')),
    failure_reason          VARCHAR(255),
    channel                 VARCHAR(30)     NOT NULL DEFAULT 'API',
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    completed_at            TIMESTAMPTZ,

    CONSTRAINT chk_txn_accounts_by_type CHECK (
        (
            txn_type = 'DEPOSIT'
            AND destination_account_id IS NOT NULL
            AND source_account_id IS NULL
        )
        OR (
            txn_type = 'WITHDRAWAL'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NULL
        )
        OR (
            txn_type = 'TRANSFER'
            AND source_account_id IS NOT NULL
            AND destination_account_id IS NOT NULL
            AND source_account_id <> destination_account_id
        )
    ),
    CONSTRAINT chk_txn_status_reason CHECK (
        (status = 'SUCCESS' AND failure_reason IS NULL)
        OR (status IN ('FAILED', 'REJECTED') AND failure_reason IS NOT NULL AND btrim(failure_reason) <> '')
    )
);

CREATE TABLE transaction_audit (
    audit_id            BIGSERIAL       PRIMARY KEY,
    transaction_id      VARCHAR(64)     NOT NULL,
    txn_pk_id           BIGINT          REFERENCES transaction(txn_pk_id) ON DELETE SET NULL,
    account_id          BIGINT          REFERENCES account(account_id) ON DELETE RESTRICT,
    step_name           VARCHAR(40)     NOT NULL
                                        CHECK (step_name IN (
                                            'RECEIVED',
                                            'VALIDATED',
                                            'IDEMPOTENCY_CHECKED',
                                            'LOCKED',
                                            'APPLIED',
                                            'AUDITED',
                                            'COMMITTED',
                                            'REJECTED',
                                            'FAILED',
                                            'ROLLED_BACK'
                                        )),
    outcome_status      VARCHAR(20)     NOT NULL
                                        CHECK (outcome_status IN ('IN_PROGRESS', 'SUCCESS', 'FAILED', 'REJECTED')),
    balance_before      NUMERIC(19, 4),
    balance_after       NUMERIC(19, 4),
    thread_name         VARCHAR(120)    NOT NULL,
    error_category      VARCHAR(60),
    detail_message      VARCHAR(500),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE failed_transaction (
    failed_id           BIGSERIAL       PRIMARY KEY,
    transaction_id      VARCHAR(64)     NOT NULL,
    txn_pk_id           BIGINT          REFERENCES transaction(txn_pk_id) ON DELETE SET NULL,
    source_account_id   BIGINT          REFERENCES account(account_id) ON DELETE SET NULL,
    dest_account_id     BIGINT          REFERENCES account(account_id) ON DELETE SET NULL,
    txn_type            VARCHAR(20)     NOT NULL
                                        CHECK (txn_type IN ('DEPOSIT', 'WITHDRAWAL', 'TRANSFER')),
    attempted_amount    NUMERIC(19, 4),
    outcome_status      VARCHAR(20)     NOT NULL CHECK (outcome_status IN ('FAILED', 'REJECTED')),
    error_category      VARCHAR(60)     NOT NULL,
    failure_reason      VARCHAR(255)    NOT NULL CHECK (btrim(failure_reason) <> ''),
    thread_name         VARCHAR(120),
    occurred_at         TIMESTAMPTZ     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_account_customer_id
    ON account (customer_id);

CREATE INDEX idx_txn_source_account_created
    ON transaction (source_account_id, created_at DESC)
    WHERE source_account_id IS NOT NULL;

CREATE INDEX idx_txn_dest_account_created
    ON transaction (destination_account_id, created_at DESC)
    WHERE destination_account_id IS NOT NULL;

CREATE INDEX idx_txn_created_type_status
    ON transaction (created_at, txn_type, status)
    INCLUDE (amount);

CREATE INDEX idx_failed_txn_reason_occurred
    ON failed_transaction (failure_reason, error_category, occurred_at DESC);

CREATE INDEX idx_audit_transaction_id_created
    ON transaction_audit (transaction_id, created_at ASC);

CREATE INDEX idx_audit_account_id_created
    ON transaction_audit (account_id, created_at DESC)
    WHERE account_id IS NOT NULL;

COMMIT;