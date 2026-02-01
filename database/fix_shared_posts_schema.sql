-- Migration: Fix shared_posts table schema
-- Run this in your Supabase SQL Editor

-- Add missing columns to shared_posts table
ALTER TABLE shared_posts 
ADD COLUMN IF NOT EXISTS caption text,
ADD COLUMN IF NOT EXISTS media_url text,
ADD COLUMN IF NOT EXISTS share_type text DEFAULT 'public' CHECK (share_type IN ('public', 'followers', 'specific', 'message'));

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shared_posts_share_type ON shared_posts(share_type);
CREATE INDEX IF NOT EXISTS idx_shared_posts_shared_by ON shared_posts(shared_by_id);
CREATE INDEX IF NOT EXISTS idx_shared_posts_shared_to ON shared_posts(shared_to_id);

-- Create shared_post_recipients table for specific sharing
CREATE TABLE IF NOT EXISTS shared_post_recipients (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    shared_post_id uuid REFERENCES shared_posts(id) ON DELETE CASCADE,
    recipient_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(shared_post_id, recipient_id)
);

-- Add indexes for shared_post_recipients
CREATE INDEX IF NOT EXISTS idx_shared_post_recipients_shared_post_id ON shared_post_recipients(shared_post_id);
CREATE INDEX IF NOT EXISTS idx_shared_post_recipients_recipient_id ON shared_post_recipients(recipient_id);

-- Enable RLS on tables
ALTER TABLE shared_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE shared_post_recipients ENABLE ROW LEVEL SECURITY;

-- RLS Policies for shared_posts
CREATE POLICY "Users can view shared posts they created" ON shared_posts
    FOR SELECT USING (auth.uid() = shared_by_id);

CREATE POLICY "Users can view shared posts shared with them" ON shared_posts
    FOR SELECT USING (
        share_type = 'public' OR 
        share_type = 'followers' OR 
        EXISTS (
            SELECT 1 FROM shared_post_recipients 
            WHERE shared_post_id = shared_posts.id 
            AND recipient_id = auth.uid()
        )
    );

CREATE POLICY "Users can create shared posts" ON shared_posts
    FOR INSERT WITH CHECK (auth.uid() = shared_by_id);

CREATE POLICY "Users can update their own shared posts" ON shared_posts
    FOR UPDATE USING (auth.uid() = shared_by_id);

CREATE POLICY "Users can delete their own shared posts" ON shared_posts
    FOR DELETE USING (auth.uid() = shared_by_id);

-- RLS Policies for shared_post_recipients
CREATE POLICY "Users can view recipients for shared posts they created" ON shared_post_recipients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM shared_posts 
            WHERE id = shared_post_recipients.shared_post_id 
            AND shared_by_id = auth.uid()
        )
    );

CREATE POLICY "Users can view recipients for shared posts shared with them" ON shared_post_recipients
    FOR SELECT USING (recipient_id = auth.uid());

CREATE POLICY "Users can create recipients for their shared posts" ON shared_post_recipients
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM shared_posts 
            WHERE id = shared_post_recipients.shared_post_id 
            AND shared_by_id = auth.uid()
        )
    );

CREATE POLICY "Users can update recipients for shared posts they created" ON shared_post_recipients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM shared_posts 
            WHERE id = shared_post_recipients.shared_post_id 
            AND shared_by_id = auth.uid()
        )
    );

-- Add comments for documentation
COMMENT ON COLUMN shared_posts.caption IS 'Custom caption added when sharing the post';
COMMENT ON COLUMN shared_posts.media_url IS 'Media URL if the shared post has media';
COMMENT ON COLUMN shared_posts.share_type IS 'Type of sharing: public, followers, specific, or message';
COMMENT ON TABLE shared_post_recipients IS 'Recipients for specifically shared posts';

-- Update existing shared_posts to have default values
UPDATE shared_posts 
SET 
    share_type = 'public'
WHERE share_type IS NULL;
