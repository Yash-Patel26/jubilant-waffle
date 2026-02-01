-- =====================================================
-- GAMERFLICK MESSAGING COMPREHENSIVE FIX
-- =====================================================

-- 1. Fix messages table structure
ALTER TABLE messages ADD COLUMN IF NOT EXISTS content text;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url text;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_content_id uuid;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS shared_content_type text;

-- 2. Drop ALL existing messaging policies to start fresh
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON messages;
DROP POLICY IF EXISTS "Users can view their conversations" ON conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
DROP POLICY IF EXISTS "Users can update conversations they participate in" ON conversations;
DROP POLICY IF EXISTS "Users can view conversation participants" ON conversation_participants;
DROP POLICY IF EXISTS "Users can join conversations" ON conversation_participants;
DROP POLICY IF EXISTS "Users can leave conversations" ON conversation_participants;

-- 3. Temporarily disable RLS to allow conversation creation
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 4. Add missing columns to conversations table if needed
ALTER TABLE conversations ADD COLUMN IF NOT EXISTS last_message text;

-- 5. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id_created_at ON messages(conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);

-- 6. Add foreign key constraints (only if they don't exist)
DO $$
BEGIN
    -- Add foreign key for messages.conversation_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_messages_conversation_id' 
        AND table_name = 'messages'
    ) THEN
        ALTER TABLE messages ADD CONSTRAINT fk_messages_conversation_id 
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
    END IF;

    -- Add foreign key for messages.sender_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_messages_sender_id' 
        AND table_name = 'messages'
    ) THEN
        ALTER TABLE messages ADD CONSTRAINT fk_messages_sender_id 
        FOREIGN KEY (sender_id) REFERENCES profiles(id) ON DELETE SET NULL;
    END IF;

    -- Add foreign key for conversation_participants.conversation_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_conversation_participants_conversation_id' 
        AND table_name = 'conversation_participants'
    ) THEN
        ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_conversation_id 
        FOREIGN KEY (conversation_id) REFERENCES conversations(id) ON DELETE CASCADE;
    END IF;

    -- Add foreign key for conversation_participants.user_id if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'fk_conversation_participants_user_id' 
        AND table_name = 'conversation_participants'
    ) THEN
        ALTER TABLE conversation_participants ADD CONSTRAINT fk_conversation_participants_user_id 
        FOREIGN KEY (user_id) REFERENCES profiles(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 7. Re-enable RLS with simple, permissive policies
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 8. Create simple, permissive policies
-- Conversations: Allow all operations for authenticated users
CREATE POLICY "Allow all conversation operations for authenticated users" ON conversations 
FOR ALL USING (auth.uid() IS NOT NULL);

-- Conversation participants: Allow all operations for authenticated users
CREATE POLICY "Allow all participant operations for authenticated users" ON conversation_participants 
FOR ALL USING (auth.uid() IS NOT NULL);

-- Messages: Allow all operations for authenticated users
CREATE POLICY "Allow all message operations for authenticated users" ON messages 
FOR ALL USING (auth.uid() IS NOT NULL); 