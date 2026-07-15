DROP INDEX IF EXISTS idx_drivers_vehicle_plate;

ALTER TABLE drivers
    DROP COLUMN IF EXISTS bank_account_name,
    DROP COLUMN IF EXISTS bank_account_number,
    DROP COLUMN IF EXISTS bank_name,
    DROP COLUMN IF EXISTS vehicle_color,
    DROP COLUMN IF EXISTS vehicle_model,
    DROP COLUMN IF EXISTS vehicle_brand;
