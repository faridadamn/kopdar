ALTER TABLE drivers
    ADD COLUMN IF NOT EXISTS vehicle_brand VARCHAR(100),
    ADD COLUMN IF NOT EXISTS vehicle_model VARCHAR(100),
    ADD COLUMN IF NOT EXISTS vehicle_color VARCHAR(50),
    ADD COLUMN IF NOT EXISTS bank_name VARCHAR(100),
    ADD COLUMN IF NOT EXISTS bank_account_number VARCHAR(100),
    ADD COLUMN IF NOT EXISTS bank_account_name VARCHAR(150);

CREATE INDEX IF NOT EXISTS idx_drivers_vehicle_plate ON drivers (vehicle_plate);
