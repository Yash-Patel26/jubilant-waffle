-- Migration: Add missing columns to existing highlights table
-- Run this in your Supabase SQL Editor

-- Add missing columns to existing highlights table
ALTER TABLE highlights 
ADD COLUMN IF NOT EXISTS stories text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS cover_story_id uuid,
ADD COLUMN IF NOT EXISTS name text;

-- Add comments for the new columns
COMMENT ON COLUMN highlights.stories IS 'Array of story IDs included in this highlight';
COMMENT ON COLUMN highlights.cover_story_id IS 'ID of the story used as cover for this highlight';
COMMENT ON COLUMN highlights.name IS 'Alternative name for the highlight';

-- Update existing records to have default values
UPDATE highlights 
SET 
    stories = '{}',
    name = title
WHERE stories IS NULL OR name IS NULL; 