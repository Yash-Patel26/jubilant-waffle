-- =====================================================
-- GAMERFLICK CORE SCHEMA - AUTHENTICATION & USERS
-- =====================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

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

-- FOLLOWS TABLE
CREATE TABLE follows (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    follower_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    following_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(follower_id, following_id)
);

-- Indexes for core tables
CREATE INDEX idx_profiles_username ON profiles(username);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_status ON profiles(status);
CREATE INDEX idx_profiles_last_active ON profiles(last_active);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);
CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id); 