-- Sprint 8: Profile, Level System, Referral, and Settings

-- Driver points tracking
CREATE TABLE IF NOT EXISTS driver_points (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID UNIQUE NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    points INTEGER NOT NULL DEFAULT 0,
    level VARCHAR(20) NOT NULL DEFAULT 'bronze',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_driver_points_driver ON driver_points(driver_id);
CREATE INDEX idx_driver_points_level ON driver_points(level);

-- Points history log
CREATE TABLE IF NOT EXISTS points_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    action VARCHAR(50) NOT NULL,
    points INTEGER NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_points_history_driver ON points_history(driver_id);
CREATE INDEX idx_points_history_created ON points_history(created_at);

-- Driver settings
CREATE TABLE IF NOT EXISTS driver_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    driver_id UUID UNIQUE NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    language VARCHAR(10) NOT NULL DEFAULT 'id',
    zone_id VARCHAR(100) NOT NULL DEFAULT '',
    auto_save_enabled BOOLEAN NOT NULL DEFAULT true,
    auto_save_amount INTEGER NOT NULL DEFAULT 10000,
    notifications JSONB NOT NULL DEFAULT '{"community":true,"savings":true,"insurance":true,"advocacy":true,"promotions":false}',
    quiet_hours JSONB NOT NULL DEFAULT '{"enabled":false,"start":"23:00","end":"07:00"}',
    biometric_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_driver_settings_driver ON driver_settings(driver_id);
