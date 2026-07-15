-- Sprint 7: SOS & Emergency features
-- Extends existing emergency tables + adds new tables

-- Add columns to emergencies for SOS flow
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS emergency_type VARCHAR(30) DEFAULT 'manual';
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS notified_driver_ids JSONB DEFAULT '[]';
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS medical_snapshot JSONB;
ALTER TABLE emergencies ADD COLUMN IF NOT EXISTS ended_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_emergencies_type ON emergencies(emergency_type);
CREATE INDEX IF NOT EXISTS idx_emergencies_ended ON emergencies(ended_at);

-- Emergency responders: track nearby drivers who respond to SOS
CREATE TABLE IF NOT EXISTS emergency_responders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id UUID NOT NULL REFERENCES emergencies(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    response VARCHAR(20) NOT NULL DEFAULT 'pending', -- pending, accepted, declined, arrived
    responded_at TIMESTAMPTZ,
    arrived_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(emergency_id, driver_id)
);
CREATE INDEX IF NOT EXISTS idx_emergency_resp_emergency ON emergency_responders(emergency_id);
CREATE INDEX IF NOT EXISTS idx_emergency_resp_driver ON emergency_responders(driver_id);

-- Emergency feedback: rate experience after resolved
CREATE TABLE IF NOT EXISTS emergency_feedback (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id UUID NOT NULL REFERENCES emergencies(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE(emergency_id, driver_id)
);
CREATE INDEX IF NOT EXISTS idx_emergency_fb_emergency ON emergency_feedback(emergency_id);

-- Driver location cache for nearby driver lookup
CREATE TABLE IF NOT EXISTS driver_locations (
    driver_id UUID PRIMARY KEY REFERENCES drivers(id) ON DELETE CASCADE,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_driver_loc_updated ON driver_locations(updated_at);
