-- =====================================================
-- GAMERFLICK SOCIAL GAMING PLATFORM - COMPLETE SCHEMA
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- AUTHENTICATION & USER MANAGEMENT
-- =====================================================

-- PROFILES TABLE (extends Supabase auth.users)
CREATE TABLE profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username text UNIQUE NOT NULL,
    email text UNIQUE,
    full_name text,
    avatar_url text,
    profile_picture_url text,
    banner_url text,
    bio text,
    location text,
    website text,
    twitter_handle text,
    twitch_handle text,
    youtube_handle text,
    discord_handle text,
    preferred_game text,
    gaming_id text,
    favorite_games text[] DEFAULT '{}',
    gaming_setup text,
    achievements text,
    level integer DEFAULT 1,
    game_stats jsonb DEFAULT '{}',
    is_public boolean DEFAULT true,
    allow_messages boolean DEFAULT true,
    allow_follows boolean DEFAULT true,
    is_verified boolean DEFAULT false,
    status text DEFAULT 'offline' CHECK (status IN ('online', 'offline', 'away')),
    last_active timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- USER SETTINGS TABLE
CREATE TABLE user_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    notification_preferences jsonb DEFAULT '{}',
    privacy_settings jsonb DEFAULT '{}',
    theme_preference text DEFAULT 'system',
    language text DEFAULT 'en',
    timezone text DEFAULT 'UTC',
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- SOCIAL FEATURES
-- =====================================================

-- FOLLOWS TABLE
CREATE TABLE follows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    following_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(follower_id, following_id)
);

-- POSTS TABLE
CREATE TABLE posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text NOT NULL,
    media_urls text[] DEFAULT '{}',
    game_tag text,
    location text,
    is_public boolean DEFAULT true,
    mentions text[] DEFAULT '{}',
    metadata jsonb DEFAULT '{}',
    like_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    view_count integer DEFAULT 0,
    pinned boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- POST LIKES TABLE
CREATE TABLE post_likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(post_id, user_id)
);

-- COMMENTS TABLE (supports nested replies)
CREATE TABLE comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    content text NOT NULL,
    parent_comment_id uuid REFERENCES comments(id) ON DELETE CASCADE,
    like_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- COMMENT LIKES TABLE
CREATE TABLE comment_likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    comment_id uuid REFERENCES comments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(comment_id, user_id)
);

-- SAVED POSTS TABLE
CREATE TABLE saved_posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(user_id, post_id)
);

-- SHARED POSTS TABLE
CREATE TABLE shared_posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    original_post_id uuid REFERENCES posts(id) ON DELETE CASCADE,
    shared_by_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    shared_to_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    message text,
    created_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- STORIES & REELS
-- =====================================================

-- STORIES TABLE
CREATE TABLE stories (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    content text,
    media_url text,
    media_type text CHECK (media_type IN ('image', 'video')),
    duration integer DEFAULT 5,
    created_at timestamp with time zone DEFAULT now(),
    expires_at timestamp with time zone DEFAULT (now() + interval '24 hours')
);

-- STORY VIEWS TABLE
CREATE TABLE story_views (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    story_id uuid REFERENCES stories(id) ON DELETE CASCADE,
    viewer_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    viewed_at timestamp with time zone DEFAULT now(),
    UNIQUE(story_id, viewer_id)
);

-- REELS TABLE
CREATE TABLE reels (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    caption text,
    video_url text NOT NULL,
    thumbnail_url text,
    game_tag text,
    duration integer,
    metadata jsonb DEFAULT '{}',
    view_count integer DEFAULT 0,
    like_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    share_count integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- REEL LIKES TABLE
CREATE TABLE reel_likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id uuid REFERENCES reels(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(reel_id, user_id)
);

-- REEL COMMENTS TABLE
CREATE TABLE reel_comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    reel_id uuid REFERENCES reels(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- LIVE STREAMING
-- =====================================================

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

-- =====================================================
-- COMMUNITIES
-- =====================================================

-- COMMUNITIES TABLE
CREATE TABLE communities (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text NOT NULL,
    image_url text,
    banner_url text,
    is_public boolean DEFAULT true,
    is_verified boolean DEFAULT false,
    member_count integer DEFAULT 0,
    created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    game text,
    tags text[] DEFAULT '{}',
    rules text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- COMMUNITY MEMBERS TABLE
CREATE TABLE community_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text DEFAULT 'member' CHECK (role IN ('member', 'moderator', 'admin', 'owner')),
    joined_at timestamp with time zone DEFAULT now(),
    is_banned boolean DEFAULT false,
    banned_at timestamp with time zone,
    banned_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    UNIQUE(community_id, user_id)
);

-- COMMUNITY POSTS TABLE
CREATE TABLE community_posts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
    author_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    content text NOT NULL,
    image_urls text[] DEFAULT '{}',
    image_captions text[] DEFAULT '{}',
    like_count integer DEFAULT 0,
    comment_count integer DEFAULT 0,
    pinned boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- COMMUNITY POST LIKES TABLE
CREATE TABLE community_post_likes (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(post_id, user_id)
);

-- COMMUNITY POST COMMENTS TABLE
CREATE TABLE community_post_comments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id uuid REFERENCES community_posts(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);

-- COMMUNITY INVITES TABLE
CREATE TABLE community_invites (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
    invited_by uuid REFERENCES profiles(id) ON DELETE CASCADE,
    invited_user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined')),
    expires_at timestamp with time zone DEFAULT (now() + interval '7 days'),
    created_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- TOURNAMENTS
-- =====================================================

-- TOURNAMENTS TABLE
CREATE TABLE tournaments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text NOT NULL,
    type text NOT NULL CHECK (type IN ('solo', 'team')),
    game text NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone,
    status text DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
    max_participants integer NOT NULL,
    current_participants integer DEFAULT 0,
    prize_pool text,
    rules text,
    media_url text,
    created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT SETTINGS TABLE
CREATE TABLE tournament_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    max_teams integer,
    max_participants_per_team integer,
    allow_spectators boolean DEFAULT true,
    registration_deadline timestamp with time zone,
    check_in_required boolean DEFAULT false,
    check_in_duration integer DEFAULT 15, -- minutes
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT PARTICIPANTS TABLE
CREATE TABLE tournament_participants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    team_id uuid, -- Will reference tournament_teams(id) when created
    status text DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'eliminated', 'winner')),
    joined_at timestamp with time zone DEFAULT now(),
    checked_in boolean DEFAULT false,
    checked_in_at timestamp with time zone,
    UNIQUE(tournament_id, user_id)
);

-- TOURNAMENT TEAMS TABLE
CREATE TABLE tournament_teams (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    logo_url text,
    captain_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    member_count integer DEFAULT 0,
    max_members integer DEFAULT 5,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT TEAM MEMBERS TABLE
CREATE TABLE tournament_team_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id uuid REFERENCES tournament_teams(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text DEFAULT 'member' CHECK (role IN ('captain', 'member')),
    joined_at timestamp with time zone DEFAULT now(),
    UNIQUE(team_id, user_id)
);

-- TOURNAMENT MATCHES TABLE
CREATE TABLE tournament_matches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number integer NOT NULL,
    match_number integer NOT NULL,
    participant_a_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    participant_b_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    team_a_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    team_b_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    winner_id uuid, -- Can reference either participant or team
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    scheduled_time timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    score_a integer DEFAULT 0,
    score_b integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT MEDIA TABLE
CREATE TABLE tournament_media (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    media_url text NOT NULL,
    media_type text CHECK (media_type IN ('image', 'video', 'highlight')),
    caption text,
    approved boolean DEFAULT false,
    approved_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT MESSAGES TABLE
CREATE TABLE tournament_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    message text NOT NULL,
    message_type text DEFAULT 'general' CHECK (message_type IN ('general', 'announcement', 'system')),
    created_at timestamp with time zone DEFAULT now()
);

-- =====================================================
-- MESSAGING & CHAT
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
    is_seen boolean DEFAULT false,
    is_delivered boolean DEFAULT false,
    reactions text[] DEFAULT '{}',
    is_pinned boolean DEFAULT false,
    shared_content_id uuid,
    shared_content_type text,
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

-- =====================================================
-- GAMES
-- =====================================================

-- GAMES TABLE
CREATE TABLE games (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL UNIQUE,
    description text,
    genre text,
    platform text[] DEFAULT '{}',
    image_url text,
    banner_url text,
    release_date date,
    developer text,
    publisher text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);

-- GAME STATS TABLE
CREATE TABLE game_stats (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    game_id uuid REFERENCES games(id) ON DELETE CASCADE,
    stats jsonb DEFAULT '{}',
    level integer DEFAULT 1,
    experience integer DEFAULT 0,
    achievements text[] DEFAULT '{}',
    last_played timestamp with time zone,
    total_playtime integer DEFAULT 0, -- in minutes
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    UNIQUE(user_id, game_id)
);

-- =====================================================
-- NOTIFICATIONS
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

-- =====================================================
-- EVENTS & SCHEDULING
-- =====================================================

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

-- =====================================================
-- ANALYTICS & TRACKING
-- =====================================================

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

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- User and Profile indexes
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_last_active ON profiles(last_active);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);

-- Post indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at);
CREATE INDEX idx_posts_game_tag ON posts(game_tag);
CREATE INDEX idx_posts_is_public ON posts(is_public);
CREATE INDEX idx_posts_like_count ON posts(like_count);
CREATE INDEX idx_posts_comment_count ON posts(comment_count);

-- Comment indexes
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_comment_id ON comments(parent_comment_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);

-- Community indexes
CREATE INDEX idx_communities_name ON communities(name);
CREATE INDEX idx_communities_game ON communities(game);
CREATE INDEX idx_communities_is_public ON communities(is_public);
CREATE INDEX idx_communities_created_at ON communities(created_at);

-- Tournament indexes
CREATE INDEX idx_tournaments_game ON tournaments(game);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_start_date ON tournaments(start_date);
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);

-- Story and Reel indexes
CREATE INDEX idx_stories_user_id ON stories(user_id);
CREATE INDEX idx_stories_expires_at ON stories(expires_at);
CREATE INDEX idx_reels_user_id ON reels(user_id);
CREATE INDEX idx_reels_created_at ON reels(created_at);

-- Message indexes
CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_messages_sender_id ON messages(sender_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

-- Notification indexes
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Analytics indexes
CREATE INDEX idx_analytics_events_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_events_type ON analytics_events(event_type);
CREATE INDEX idx_analytics_events_created_at ON analytics_events(created_at);

-- =====================================================
-- TRIGGERS FOR AUTOMATIC UPDATES
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at triggers to relevant tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_communities_updated_at BEFORE UPDATE ON communities FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON tournaments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_reels_updated_at BEFORE UPDATE ON reels FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to update post like count
CREATE OR REPLACE FUNCTION update_post_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET like_count = like_count - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply like count triggers
CREATE TRIGGER update_post_like_count_trigger AFTER INSERT OR DELETE ON post_likes FOR EACH ROW EXECUTE FUNCTION update_post_like_count();
CREATE TRIGGER update_comment_like_count_trigger AFTER INSERT OR DELETE ON comment_likes FOR EACH ROW EXECUTE FUNCTION update_post_like_count();

-- Function to update comment count
CREATE OR REPLACE FUNCTION update_post_comment_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET comment_count = comment_count - 1 WHERE id = OLD.post_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

-- Apply comment count triggers
CREATE TRIGGER update_post_comment_count_trigger AFTER INSERT OR DELETE ON comments FOR EACH ROW EXECUTE FUNCTION update_post_comment_count();

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE communities ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view public profiles" ON profiles FOR SELECT USING (is_public = true OR auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Posts policies
CREATE POLICY "Users can view public posts" ON posts FOR SELECT USING (is_public = true OR auth.uid() = user_id);
CREATE POLICY "Users can create posts" ON posts FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own posts" ON posts FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own posts" ON posts FOR DELETE USING (auth.uid() = user_id);

-- Comments policies
CREATE POLICY "Users can view comments on public posts" ON comments FOR SELECT USING (
    EXISTS (SELECT 1 FROM posts WHERE posts.id = comments.post_id AND (posts.is_public = true OR posts.user_id = auth.uid()))
);
CREATE POLICY "Users can create comments" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (auth.uid() = user_id);

-- Communities policies
CREATE POLICY "Users can view public communities" ON communities FOR SELECT USING (is_public = true);
CREATE POLICY "Users can create communities" ON communities FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Community admins can update communities" ON communities FOR UPDATE USING (
    EXISTS (SELECT 1 FROM community_members WHERE community_members.community_id = communities.id AND community_members.user_id = auth.uid() AND community_members.role IN ('admin', 'owner'))
);

-- =====================================================
-- STORAGE BUCKET REFERENCES
-- =====================================================

-- Note: Supabase Storage buckets should be created separately
-- Recommended buckets:
-- - 'avatars' - for user profile pictures
-- - 'posts' - for post media
-- - 'stories' - for story media
-- - 'reels' - for reel videos
-- - 'communities' - for community images
-- - 'tournaments' - for tournament media
-- - 'streams' - for live stream thumbnails

-- =====================================================
-- VIEWS FOR COMMON QUERIES
-- =====================================================

-- User feed view
CREATE VIEW user_feed AS
SELECT 
    p.*,
    pr.username,
    pr.avatar_url,
    pr.profile_picture_url,
    pr.is_verified
FROM posts p
JOIN profiles pr ON p.user_id = pr.id
WHERE p.is_public = true
ORDER BY p.created_at DESC;

-- Community feed view
CREATE VIEW community_feed AS
SELECT 
    cp.*,
    c.name as community_name,
    c.image_url as community_image,
    pr.username,
    pr.avatar_url,
    pr.profile_picture_url
FROM community_posts cp
JOIN communities c ON cp.community_id = c.id
JOIN profiles pr ON cp.author_id = pr.id
WHERE c.is_public = true
ORDER BY cp.created_at DESC;

-- Tournament participants view
CREATE VIEW tournament_participants_view AS
SELECT 
    tp.*,
    t.name as tournament_name,
    t.game,
    t.status as tournament_status,
    pr.username,
    pr.avatar_url,
    pr.profile_picture_url,
    tt.name as team_name
FROM tournament_participants tp
JOIN tournaments t ON tp.tournament_id = t.id
JOIN profiles pr ON tp.user_id = pr.id
LEFT JOIN tournament_teams tt ON tp.team_id = tt.id;

-- =====================================================
-- SCHEMA COMPLETE
-- =====================================================