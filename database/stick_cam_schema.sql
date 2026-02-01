-- Stick Cam Sessions Table
CREATE TABLE IF NOT EXISTS stick_cam_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    a_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    b_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'matching' CHECK (status IN ('matching', 'connected', 'ended')),
    interests TEXT[] DEFAULT '{}',
    mode TEXT NOT NULL DEFAULT 'video' CHECK (mode IN ('video', 'audio', 'text')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ended_at TIMESTAMP WITH TIME ZONE,
    end_reason TEXT
);

-- Stick Cam Messages Table
CREATE TABLE IF NOT EXISTS stick_cam_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES stick_cam_sessions(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'system')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Stick Cam Presence Table (for typing indicators)
CREATE TABLE IF NOT EXISTS stick_cam_presence (
    session_id UUID REFERENCES stick_cam_sessions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    typing BOOLEAN DEFAULT FALSE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (session_id, user_id)
);

-- WebRTC Signaling Table (for WebRTC connection establishment)
CREATE TABLE IF NOT EXISTS webrtc_signaling (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    session_id UUID REFERENCES stick_cam_sessions(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message_type TEXT NOT NULL CHECK (message_type IN ('offer', 'answer', 'ice-candidate')),
    message_data TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_stick_cam_sessions_status ON stick_cam_sessions(status);
CREATE INDEX IF NOT EXISTS idx_stick_cam_sessions_a_user_id ON stick_cam_sessions(a_user_id);
CREATE INDEX IF NOT EXISTS idx_stick_cam_sessions_b_user_id ON stick_cam_sessions(b_user_id);
CREATE INDEX IF NOT EXISTS idx_stick_cam_sessions_created_at ON stick_cam_sessions(created_at);
CREATE INDEX IF NOT EXISTS idx_stick_cam_messages_session_id ON stick_cam_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_stick_cam_messages_created_at ON stick_cam_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_stick_cam_presence_session_id ON stick_cam_presence(session_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_signaling_session_id ON webrtc_signaling(session_id);
CREATE INDEX IF NOT EXISTS idx_webrtc_signaling_created_at ON webrtc_signaling(created_at);

-- Row Level Security (RLS) Policies
ALTER TABLE stick_cam_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE stick_cam_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE stick_cam_presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE webrtc_signaling ENABLE ROW LEVEL SECURITY;

-- Policies for stick_cam_sessions
DROP POLICY IF EXISTS "Users can view sessions they are part of" ON stick_cam_sessions;
CREATE POLICY "Users can view sessions they are part of" ON stick_cam_sessions
    FOR SELECT USING (
        auth.uid() = a_user_id OR auth.uid() = b_user_id
    );

DROP POLICY IF EXISTS "Users can create sessions" ON stick_cam_sessions;
CREATE POLICY "Users can create sessions" ON stick_cam_sessions
    FOR INSERT WITH CHECK (
        auth.uid() = a_user_id
    );

DROP POLICY IF EXISTS "Users can update sessions they are part of" ON stick_cam_sessions;
CREATE POLICY "Users can update sessions they are part of" ON stick_cam_sessions
    FOR UPDATE USING (
        auth.uid() = a_user_id OR auth.uid() = b_user_id
    );

-- Policies for stick_cam_messages
DROP POLICY IF EXISTS "Users can view messages from sessions they are part of" ON stick_cam_messages;
CREATE POLICY "Users can view messages from sessions they are part of" ON stick_cam_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stick_cam_sessions 
            WHERE id = session_id 
            AND (a_user_id = auth.uid() OR b_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can send messages to sessions they are part of" ON stick_cam_messages;
CREATE POLICY "Users can send messages to sessions they are part of" ON stick_cam_messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM stick_cam_sessions 
            WHERE id = session_id 
            AND (a_user_id = auth.uid() OR b_user_id = auth.uid())
        )
    );

-- Policies for stick_cam_presence
DROP POLICY IF EXISTS "Users can view presence from sessions they are part of" ON stick_cam_presence;
CREATE POLICY "Users can view presence from sessions they are part of" ON stick_cam_presence
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stick_cam_sessions 
            WHERE id = session_id 
            AND (a_user_id = auth.uid() OR b_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can update their own presence" ON stick_cam_presence;
CREATE POLICY "Users can update their own presence" ON stick_cam_presence
    FOR ALL USING (
        user_id = auth.uid()
    );

-- Policies for webrtc_signaling
DROP POLICY IF EXISTS "Users can view signaling from sessions they are part of" ON webrtc_signaling;
CREATE POLICY "Users can view signaling from sessions they are part of" ON webrtc_signaling
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM stick_cam_sessions 
            WHERE id = session_id 
            AND (a_user_id = auth.uid() OR b_user_id = auth.uid())
        )
    );

DROP POLICY IF EXISTS "Users can send signaling to sessions they are part of" ON webrtc_signaling;
CREATE POLICY "Users can send signaling to sessions they are part of" ON webrtc_signaling
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM stick_cam_sessions 
            WHERE id = session_id 
            AND (a_user_id = auth.uid() OR b_user_id = auth.uid())
        )
    );

-- Function to automatically clean up old sessions
CREATE OR REPLACE FUNCTION cleanup_old_stick_cam_sessions()
RETURNS void AS $$
BEGIN
    -- Delete sessions older than 24 hours
    DELETE FROM stick_cam_sessions 
    WHERE created_at < NOW() - INTERVAL '24 hours';
    
    -- Delete messages from deleted sessions (cascade should handle this, but just in case)
    DELETE FROM stick_cam_messages 
    WHERE session_id NOT IN (SELECT id FROM stick_cam_sessions);
    
    -- Delete presence from deleted sessions
    DELETE FROM stick_cam_presence 
    WHERE session_id NOT IN (SELECT id FROM stick_cam_sessions);
    
    -- Delete signaling from deleted sessions
    DELETE FROM webrtc_signaling 
    WHERE session_id NOT IN (SELECT id FROM stick_cam_sessions);
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to clean up old sessions (if using pg_cron extension)
-- SELECT cron.schedule('cleanup-stick-cam-sessions', '0 */6 * * *', 'SELECT cleanup_old_stick_cam_sessions();');

-- Automatically clean up signaling rows when a session ends
CREATE OR REPLACE FUNCTION cleanup_signaling_on_session_end()
RETURNS trigger AS $$
BEGIN
    IF NEW.status = 'ended' AND OLD.status IS DISTINCT FROM 'ended' THEN
        DELETE FROM webrtc_signaling WHERE session_id = NEW.id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cleanup_signaling_on_session_end ON stick_cam_sessions;
CREATE TRIGGER trg_cleanup_signaling_on_session_end
AFTER UPDATE ON stick_cam_sessions
FOR EACH ROW
EXECUTE FUNCTION cleanup_signaling_on_session_end();

-- Function to get matching session
CREATE OR REPLACE FUNCTION find_matching_stick_cam_session(
    p_user_id UUID,
    p_interests TEXT[] DEFAULT '{}',
    p_mode TEXT DEFAULT 'video'
)
RETURNS UUID AS $$
DECLARE
    matching_session_id UUID;
BEGIN
    -- Find a session that matches the criteria
    SELECT id INTO matching_session_id
    FROM stick_cam_sessions
    WHERE status = 'matching'
    AND a_user_id != p_user_id
    AND mode = p_mode
    AND (
        p_interests = '{}' OR 
        interests = '{}' OR 
        interests && p_interests
    )
    ORDER BY created_at ASC
    LIMIT 1;
    
    RETURN matching_session_id;
END;
$$ LANGUAGE plpgsql;

-- Function to connect two users
CREATE OR REPLACE FUNCTION connect_stick_cam_users(
    p_session_id UUID,
    p_b_user_id UUID
)
RETURNS void AS $$
BEGIN
    UPDATE stick_cam_sessions
    SET 
        b_user_id = p_b_user_id,
        status = 'connected',
        updated_at = NOW()
    WHERE id = p_session_id;
END;
$$ LANGUAGE plpgsql;
