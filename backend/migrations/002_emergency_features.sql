-- Migration: Add emergency responder tracking and driver location support
-- Sprint 7: SOS & Emergency Features

-- Add location column to drivers for nearby driver search
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS location GEOMETRY(Point, 4326);
CREATE INDEX IF NOT EXISTS idx_drivers_location ON drivers USING GIST(location);

-- Add unique constraint on driver_medical.driver_id for upsert support
-- (should already exist if created properly, but ensure it)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'driver_medical_driver_id_key'
    ) THEN
        ALTER TABLE driver_medical ADD CONSTRAINT driver_medical_driver_id_key UNIQUE (driver_id);
    END IF;
END $$;

-- Create emergency_responders table for tracking who responded to an SOS
CREATE TABLE IF NOT EXISTS emergency_responders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id UUID NOT NULL REFERENCES emergencies(id) ON DELETE CASCADE,
    responder_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    responded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(emergency_id, responder_user_id)
);
CREATE INDEX IF NOT EXISTS idx_emergency_responders_emergency ON emergency_responders(emergency_id);
CREATE INDEX IF NOT EXISTS idx_emergency_responders_user ON emergency_responders(responder_user_id);
