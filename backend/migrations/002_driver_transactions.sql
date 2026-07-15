-- Sprint 2: Driver income/expense tracking
-- Separate from the financial transactions table (which handles deposits, withdrawals, etc.)

CREATE TYPE driver_transaction_type AS ENUM ('income', 'expense');
CREATE TYPE income_platform AS ENUM ('gojek', 'grab', 'shopeefood', 'maxim', 'indrive', 'cash', 'lainnya');
CREATE TYPE expense_category AS ENUM ('bensin', 'makan', 'angsuran', 'servis', 'pulsa', 'parkir', 'kesehatan', 'lainnya');

CREATE TABLE driver_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    type driver_transaction_type NOT NULL,
    category VARCHAR(50) NOT NULL,
    platform VARCHAR(50),
    amount DECIMAL(15,2) NOT NULL,
    commission DECIMAL(15,2) NOT NULL DEFAULT 0,
    net_amount DECIMAL(15,2) NOT NULL,
    notes TEXT,
    receipt_url TEXT,
    order_count INTEGER NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_driver_transactions_driver ON driver_transactions(driver_id);
CREATE INDEX idx_driver_transactions_type ON driver_transactions(type);
CREATE INDEX idx_driver_transactions_created ON driver_transactions(created_at DESC);
CREATE INDEX idx_driver_transactions_platform ON driver_transactions(platform);
