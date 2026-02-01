-- =====================================================
-- GAMERFLICK SOCIAL FEATURES SCHEMA
-- =====================================================

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

-- Indexes for social features
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at);
CREATE INDEX idx_posts_game_tag ON posts(game_tag);
CREATE INDEX idx_posts_is_public ON posts(is_public);
CREATE INDEX idx_posts_like_count ON posts(like_count);
CREATE INDEX idx_posts_comment_count ON posts(comment_count);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent_comment_id ON comments(parent_comment_id);
CREATE INDEX idx_comments_created_at ON comments(created_at);

CREATE INDEX idx_stories_user_id ON stories(user_id);
CREATE INDEX idx_stories_expires_at ON stories(expires_at);

CREATE INDEX idx_reels_user_id ON reels(user_id);
CREATE INDEX idx_reels_created_at ON reels(created_at); 