-- =====================================================
-- GAMERFLICK NOTIFICATIONS, EVENTS & ANALYTICS SCHEMA
-- =====================================================

-- NOTIFICATIONS TABLE
CREATE TABLE notifications (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    type text NOT NULL CHECK (type IN ('like', 'comment', 'follow', 'mention', 'tournament', 'community', 'message', 'system')),
    title text NOT NULL,
    body text NOT NULL,
    data jsonb DEFAULT '{}',
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- EVENTS TABLE
CREATE TABLE events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    title text NOT NULL,
    description text,
    event_type text CHECK (event_type IN ('tournament', 'meetup', 'stream', 'community', 'custom')),
    start_time timestamp with time zone NOT NULL,
    end_time timestamp with time zone,
    location text,
    is_online boolean DEFAULT false,
    max_participants integer,
    current_participants integer DEFAULT 0,
    created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    community_id uuid REFERENCES communities(id) ON DELETE SET NULL,
    tournament_id uuid REFERENCES tournaments(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- EVENT PARTICIPANTS TABLE
CREATE TABLE event_participants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id uuid REFERENCES events(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'declined')),
    joined_at timestamp with time zone DEFAULT now(),
    UNIQUE(event_id, user_id)
);

-- ANALYTICS EVENTS TABLE
CREATE TABLE analytics_events (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    event_type text NOT NULL,
    event_data jsonb DEFAULT '{}',
    session_id text,
    user_agent text,
    ip_address inet,
    created_at timestamp with time zone DEFAULT now()
);

-- USER SESSIONS TABLE
CREATE TABLE user_sessions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    session_id text UNIQUE NOT NULL,
    started_at timestamp with time zone DEFAULT now(),
    ended_at timestamp with time zone,
    duration integer, -- in seconds
    device_info jsonb DEFAULT '{}'
);

-- USER PRESENCE TABLE
CREATE TABLE user_presence (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away', 'busy')),
    last_seen timestamp with time zone DEFAULT now(),
    current_activity text,
    game_id uuid REFERENCES games(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- Indexes for notifications, events, and analytics
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

CREATE INDEX idx_events_event_type ON events(event_type);
CREATE INDEX idx_events_start_time ON events(start_time);
CREATE INDEX idx_events_created_by ON events(created_by);
CREATE INDEX idx_events_community_id ON events(community_id);

CREATE INDEX idx_event_participants_event_id ON event_participants(event_id);
CREATE INDEX idx_event_participants_user_id ON event_participants(user_id);
CREATE INDEX idx_event_participants_status ON event_participants(status);

CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_session_id ON user_sessions(session_id);
CREATE INDEX idx_user_sessions_started_at ON user_sessions(started_at);

CREATE INDEX idx_user_presence_user_id ON user_presence(user_id);
CREATE INDEX idx_user_presence_status ON user_presence(status);
CREATE INDEX idx_user_presence_last_seen ON user_presence(last_seen); 