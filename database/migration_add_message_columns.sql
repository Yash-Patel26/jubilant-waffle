-- Migration: Add missing columns to messages table
-- Run this in your Supabase SQL Editor

-- Add missing columns to messages table
ALTER TABLE messages 
ADD COLUMN IF NOT EXISTS is_seen boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS is_delivered boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS reactions text[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_pinned boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS shared_content_id uuid,
ADD COLUMN IF NOT EXISTS shared_content_type text;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_is_seen ON messages(is_seen);
CREATE INDEX IF NOT EXISTS idx_messages_is_delivered ON messages(is_delivered);
CREATE INDEX IF NOT EXISTS idx_messages_is_pinned ON messages(is_pinned);

-- Update existing messages to have default values
UPDATE messages 
SET 
    is_seen = false,
    is_delivered = false,
    reactions = '{}',
    is_pinned = false
WHERE is_seen IS NULL OR is_delivered IS NULL OR reactions IS NULL OR is_pinned IS NULL;

-- Add comments for documentation
COMMENT ON COLUMN messages.is_seen IS 'Whether the message has been seen by the recipient';
COMMENT ON COLUMN messages.is_delivered IS 'Whether the message has been delivered to the recipient';
COMMENT ON COLUMN messages.reactions IS 'Array of reaction emojis for the message';
COMMENT ON COLUMN messages.is_pinned IS 'Whether the message is pinned in the conversation';
COMMENT ON COLUMN messages.shared_content_id IS 'ID of shared content (post, reel, etc.)';
COMMENT ON COLUMN messages.shared_content_type IS 'Type of shared content (post, reel, etc.)'; 