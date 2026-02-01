-- =====================================================
-- COMMUNITY CHAT MESSAGES FIX
-- =====================================================

-- Create the community_chat_messages table if it doesn't exist
CREATE TABLE IF NOT EXISTS community_chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    message text NOT NULL,
    message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'system')),
    created_at timestamp with time zone DEFAULT now()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_community_chat_messages_community_id ON community_chat_messages(community_id);
CREATE INDEX IF NOT EXISTS idx_community_chat_messages_user_id ON community_chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_community_chat_messages_created_at ON community_chat_messages(created_at);

-- Enable RLS on the table
ALTER TABLE community_chat_messages ENABLE ROW LEVEL SECURITY;

-- RLS Policies for community_chat_messages
CREATE POLICY "Community members can view chat messages" ON community_chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM community_members 
            WHERE community_members.community_id = community_chat_messages.community_id 
            AND community_members.user_id = auth.uid()
            AND community_members.is_banned = false
        )
    );

CREATE POLICY "Community members can send chat messages" ON community_chat_messages
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM community_members 
            WHERE community_members.community_id = community_chat_messages.community_id 
            AND community_members.user_id = auth.uid()
            AND community_members.is_banned = false
        )
        AND auth.uid() = user_id
    );

CREATE POLICY "Users can update their own messages" ON community_chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own messages" ON community_chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Add trigger for updated_at
CREATE TRIGGER update_community_chat_messages_updated_at 
    BEFORE UPDATE ON community_chat_messages 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column(); 