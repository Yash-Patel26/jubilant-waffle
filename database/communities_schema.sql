-- =====================================================
-- GAMERFLICK COMMUNITIES SCHEMA
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

-- COMMUNITY CHAT MESSAGES TABLE
CREATE TABLE community_chat_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    community_id uuid REFERENCES communities(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    message text NOT NULL,
    message_type text DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'video', 'system')),
    created_at timestamp with time zone DEFAULT now()
);

-- Indexes for communities
CREATE INDEX idx_communities_name ON communities(name);
CREATE INDEX idx_communities_game ON communities(game);
CREATE INDEX idx_communities_is_public ON communities(is_public);
CREATE INDEX idx_communities_created_at ON communities(created_at);

CREATE INDEX idx_community_members_community_id ON community_members(community_id);
CREATE INDEX idx_community_members_user_id ON community_members(user_id);
CREATE INDEX idx_community_members_role ON community_members(role);

CREATE INDEX idx_community_posts_community_id ON community_posts(community_id);
CREATE INDEX idx_community_posts_author_id ON community_posts(author_id);
CREATE INDEX idx_community_posts_created_at ON community_posts(created_at);

CREATE INDEX idx_community_invites_community_id ON community_invites(community_id);
CREATE INDEX idx_community_invites_invited_user_id ON community_invites(invited_user_id);
CREATE INDEX idx_community_invites_status ON community_invites(status); 