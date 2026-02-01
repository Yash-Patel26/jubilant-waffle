-- Migration: Add highlights table
-- Run this in your Supabase SQL Editor

-- HIGHLIGHTS TABLE
CREATE TABLE IF NOT EXISTS highlights (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    game_id uuid REFERENCES games(id) ON DELETE SET NULL,
    title text NOT NULL,
    description text,
    video_url text NOT NULL,
    thumbnail_url text,
    duration integer, -- in seconds
    metadata jsonb DEFAULT '{}',
    view_count integer DEFAULT 0,
    like_count integer DEFAULT 0,
    stories text[] DEFAULT '{}', -- Array of story IDs
    cover_story_id uuid, -- ID of the cover story
    name text, -- Alternative name field used by profile screen
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_highlights_user_id ON highlights(user_id);
CREATE INDEX IF NOT EXISTS idx_highlights_game_id ON highlights(game_id);
CREATE INDEX IF NOT EXISTS idx_highlights_created_at ON highlights(created_at);
CREATE INDEX IF NOT EXISTS idx_highlights_view_count ON highlights(view_count);
CREATE INDEX IF NOT EXISTS idx_highlights_like_count ON highlights(like_count);

-- Add comments for documentation
COMMENT ON TABLE highlights IS 'User-created gaming highlights and clips';
COMMENT ON COLUMN highlights.user_id IS 'User who created the highlight';
COMMENT ON COLUMN highlights.game_id IS 'Game associated with the highlight';
COMMENT ON COLUMN highlights.title IS 'Title of the highlight';
COMMENT ON COLUMN highlights.description IS 'Description of the highlight';
COMMENT ON COLUMN highlights.video_url IS 'URL to the highlight video';
COMMENT ON COLUMN highlights.thumbnail_url IS 'URL to the highlight thumbnail';
COMMENT ON COLUMN highlights.duration IS 'Duration of the highlight in seconds';
COMMENT ON COLUMN highlights.metadata IS 'Additional metadata for the highlight';
COMMENT ON COLUMN highlights.view_count IS 'Number of times the highlight has been viewed';
COMMENT ON COLUMN highlights.like_count IS 'Number of likes on the highlight';
COMMENT ON COLUMN highlights.stories IS 'Array of story IDs included in this highlight';
COMMENT ON COLUMN highlights.cover_story_id IS 'ID of the story used as cover for this highlight';
COMMENT ON COLUMN highlights.name IS 'Alternative name for the highlight';

-- Add trigger to update updated_at column
CREATE TRIGGER update_highlights_updated_at 
    BEFORE UPDATE ON highlights 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 