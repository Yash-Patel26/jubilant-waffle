-- =====================================================
-- GAMERFLICK MESSAGING & CHAT SCHEMA
-- =====================================================

-- CONVERSATIONS TABLE
CREATE TABLE conversations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type text NOT NULL CHECK (type IN ('direct', 'group', 'community')),
    name text, -- For group conversations
    created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- CONVERSATION PARTICIPANTS TABLE
CREATE TABLE conversation_participants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text DEFAULT 'member' CHECK (role IN ('member', 'admin')),
    joined_at timestamp with time zone DEFAULT now(),
    left_at timestamp with time zone,
    UNIQUE(conversation_id, user_id)
);

-- MESSAGES TABLE
CREATE TABLE messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid REFERENCES conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    content text NOT NULL,
    message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'file', 'system')),
    media_url text,
    reply_to_id uuid REFERENCES messages(id) ON DELETE SET NULL,
    is_edited boolean DEFAULT false,
    edited_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- MESSAGE REACTIONS TABLE
CREATE TABLE message_reactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id uuid REFERENCES messages(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    reaction text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(message_id, user_id, reaction)
);

-- LIVE STREAMS TABLE
CREATE TABLE live_streams (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    streamer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    stream_url text NOT NULL,
    thumbnail_url text,
    game_tag text,
    is_live boolean DEFAULT false,
    viewer_count integer DEFAULT 0,
    start_time timestamp with time zone DEFAULT now(),
    end_time timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- STREAM VIEWERS TABLE
CREATE TABLE stream_viewers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id uuid REFERENCES live_streams(id) ON DELETE CASCADE,
    viewer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at timestamp with time zone DEFAULT now(),
    left_at timestamp with time zone,
    UNIQUE(stream_id, viewer_id)
);

-- Indexes for messaging
CREATE INDEX idx_conversations_type ON conversations(type);
CREATE INDEX idx_conversations_created_at ON conversations(created_at);

CREATE INDEX idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);
CREATE INDEX idx_conversation_participants_user_id ON conversation_participants(user_id);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);
CREATE INDEX idx_messages_reply_to_id ON messages(reply_to_id);

CREATE INDEX idx_live_streams_streamer_id ON live_streams(streamer_id);
CREATE INDEX idx_live_streams_is_live ON live_streams(is_live);
CREATE INDEX idx_live_streams_game_tag ON live_streams(game_tag); 