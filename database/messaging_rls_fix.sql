-- =====================================================
-- GAMERFLICK MESSAGING RLS FIX
-- =====================================================

-- Drop existing messaging policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON messages;

-- Create more permissive messaging policies
CREATE POLICY "Users can view messages in their conversations" ON messages 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_participants.conversation_id = messages.conversation_id 
        AND conversation_participants.user_id = auth.uid()
        AND conversation_participants.left_at IS NULL
    )
);

CREATE POLICY "Users can send messages to their conversations" ON messages 
FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_participants.conversation_id = messages.conversation_id 
        AND conversation_participants.user_id = auth.uid()
        AND conversation_participants.left_at IS NULL
    )
);

-- Add policies for conversations table
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update conversations they participate in" ON conversations;

CREATE POLICY "Users can view their conversations" ON conversations 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_participants.conversation_id = conversations.id 
        AND conversation_participants.user_id = auth.uid()
        AND conversation_participants.left_at IS NULL
    )
);

CREATE POLICY "Users can create conversations" ON conversations 
FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update conversations they participate in" ON conversations 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM conversation_participants 
        WHERE conversation_participants.conversation_id = conversations.id 
        AND conversation_participants.user_id = auth.uid()
        AND conversation_participants.left_at IS NULL
    )
);

-- Add policies for conversation_participants table
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can join conversations" ON conversation_participants;
DROP POLICY IF EXISTS "Users can leave conversations" ON conversation_participants;

CREATE POLICY "Users can view conversation participants" ON conversation_participants 
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM conversation_participants cp2
        WHERE cp2.conversation_id = conversation_participants.conversation_id 
        AND cp2.user_id = auth.uid()
        AND cp2.left_at IS NULL
    )
);

CREATE POLICY "Users can join conversations" ON conversation_participants 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave conversations" ON conversation_participants 
FOR UPDATE USING (auth.uid() = user_id);

-- Ensure the messages table has the correct structure
-- Add any missing columns that might be needed
ALTER TABLE messages ADD COLUMN IF NOT EXISTS content text;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url text;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_content_id uuid;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_content_type text;

-- Update existing messages to use content field if text field exists
UPDATE messages SET content = text WHERE content IS NULL AND text IS NOT NULL; 