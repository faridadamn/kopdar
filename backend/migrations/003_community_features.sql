-- Sprint 6: Community & Forum features
-- Adds missing columns to community tables

-- Add columns to community_posts
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS category VARCHAR(20) NOT NULL DEFAULT 'info';
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS visibility VARCHAR(10) NOT NULL DEFAULT 'all';
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES zones(id);
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS likes_count INT NOT NULL DEFAULT 0;
ALTER TABLE community_posts ADD COLUMN IF NOT EXISTS comments_count INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_posts_category ON community_posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_visibility ON community_posts(visibility);
CREATE INDEX IF NOT EXISTS idx_posts_zone ON community_posts(zone_id);

-- Add parent_id to community_comments for nested replies
ALTER TABLE community_comments ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES community_comments(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_comments_parent ON community_comments(parent_id);

-- Add description to community_reports if not exists
ALTER TABLE community_reports ADD COLUMN IF NOT EXISTS description TEXT;
