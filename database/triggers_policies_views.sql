-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.analytics_events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  event_type text NOT NULL,
  event_data jsonb DEFAULT '{}'::jsonb,
  session_id text,
  user_agent text,
  ip_address inet,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT analytics_events_pkey PRIMARY KEY (id),
  CONSTRAINT analytics_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.comment_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  comment_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comment_likes_pkey PRIMARY KEY (id),
  CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id),
  CONSTRAINT comment_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  content text NOT NULL,
  parent_comment_id uuid,
  like_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES public.comments(id),
  CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.communities (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  image_url text,
  banner_url text,
  is_public boolean DEFAULT true,
  is_verified boolean DEFAULT false,
  member_count integer DEFAULT 0,
  created_by uuid,
  game text,
  tags ARRAY DEFAULT '{}'::text[],
  rules text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  is_vip_only boolean DEFAULT false,
  display_name text,
  online_count integer DEFAULT 0,
  is_nsfw boolean DEFAULT false,
  allow_images boolean DEFAULT true,
  allow_videos boolean DEFAULT true,
  allow_links boolean DEFAULT true,
  allow_polls boolean DEFAULT true,
  content_filter text DEFAULT 'medium'::text,
  language text DEFAULT 'en'::text,
  sidebar text,
  wiki text,
  settings jsonb DEFAULT '{}'::jsonb,
  karma_requirement integer DEFAULT 0,
  account_age_requirement integer DEFAULT 0,
  require_flair boolean DEFAULT false,
  allowed_flairs ARRAY DEFAULT '{}'::text[],
  enable_mod_log boolean DEFAULT true,
  enable_wiki boolean DEFAULT false,
  enable_contest_mode boolean DEFAULT false,
  enable_spoilers boolean DEFAULT true,
  sort_type text DEFAULT 'hot'::text,
  default_sort text DEFAULT 'hot'::text,
  CONSTRAINT communities_pkey PRIMARY KEY (id),
  CONSTRAINT communities_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.community_chat_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  community_id uuid,
  user_id uuid,
  message text NOT NULL,
  message_type text DEFAULT 'text'::text CHECK (message_type = ANY (ARRAY['text'::text, 'image'::text, 'video'::text, 'system'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT community_chat_messages_pkey PRIMARY KEY (id),
  CONSTRAINT community_chat_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT community_chat_messages_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id)
);
CREATE TABLE public.community_invites (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  community_id uuid,
  invited_by uuid,
  invited_user_id uuid,
  status text DEFAULT 'pending'::text CHECK (status = ANY (ARRAY['pending'::text, 'accepted'::text, 'declined'::text])),
  expires_at timestamp with time zone DEFAULT (now() + '7 days'::interval),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT community_invites_pkey PRIMARY KEY (id),
  CONSTRAINT community_invites_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id),
  CONSTRAINT community_invites_invited_by_fkey FOREIGN KEY (invited_by) REFERENCES public.profiles(id),
  CONSTRAINT community_invites_invited_user_id_fkey FOREIGN KEY (invited_user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.community_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  community_id uuid,
  user_id uuid,
  role text DEFAULT 'member'::text CHECK (role = ANY (ARRAY['member'::text, 'moderator'::text, 'admin'::text, 'owner'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  is_banned boolean DEFAULT false,
  banned_at timestamp with time zone,
  banned_by uuid,
  CONSTRAINT community_members_pkey PRIMARY KEY (id),
  CONSTRAINT community_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT community_members_banned_by_fkey FOREIGN KEY (banned_by) REFERENCES public.profiles(id),
  CONSTRAINT community_members_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id)
);
CREATE TABLE public.community_post_comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  parent_comment_id uuid,
  is_edited boolean DEFAULT false,
  edited_at timestamp with time zone,
  edit_reason text,
  removed boolean DEFAULT false,
  removal_reason text,
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  score integer DEFAULT 0,
  awards ARRAY DEFAULT '{}'::text[],
  reply_count integer DEFAULT 0,
  locked boolean DEFAULT false,
  stickied boolean DEFAULT false,
  distinguished boolean DEFAULT false,
  CONSTRAINT community_post_comments_pkey PRIMARY KEY (id),
  CONSTRAINT community_post_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT community_post_comments_parent_comment_id_fkey FOREIGN KEY (parent_comment_id) REFERENCES public.community_post_comments(id),
  CONSTRAINT community_post_comments_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id)
);
CREATE TABLE public.community_post_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  vote integer DEFAULT 1 CHECK (vote = ANY (ARRAY['-1'::integer, 0, 1])),
  CONSTRAINT community_post_likes_pkey PRIMARY KEY (id),
  CONSTRAINT community_post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id),
  CONSTRAINT community_post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.community_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  community_id uuid,
  author_id uuid,
  content text NOT NULL,
  image_urls ARRAY DEFAULT '{}'::text[],
  image_captions ARRAY DEFAULT '{}'::text[],
  like_count integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  pinned boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  title text DEFAULT ''::text,
  post_type text DEFAULT 'text'::text,
  link_url text,
  link_domain text,
  poll_data jsonb,
  locked boolean DEFAULT false,
  spoiler boolean DEFAULT false,
  nsfw boolean DEFAULT false,
  contest_mode boolean DEFAULT false,
  stickied boolean DEFAULT false,
  archived boolean DEFAULT false,
  removed boolean DEFAULT false,
  removal_reason text,
  flair text,
  flair_color text,
  upvotes integer DEFAULT 0,
  downvotes integer DEFAULT 0,
  score integer DEFAULT 0,
  view_count integer DEFAULT 0,
  share_count integer DEFAULT 0,
  upvote_ratio double precision DEFAULT 1.0,
  awards ARRAY DEFAULT '{}'::text[],
  metadata jsonb DEFAULT '{}'::jsonb,
  is_edited boolean DEFAULT false,
  edited_at timestamp with time zone,
  edit_reason text,
  CONSTRAINT community_posts_pkey PRIMARY KEY (id),
  CONSTRAINT community_posts_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.profiles(id),
  CONSTRAINT community_posts_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id)
);
CREATE TABLE public.conversation_participants (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid,
  user_id uuid,
  role text DEFAULT 'member'::text CHECK (role = ANY (ARRAY['member'::text, 'admin'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  left_at timestamp with time zone,
  CONSTRAINT conversation_participants_pkey PRIMARY KEY (id),
  CONSTRAINT conversation_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT fk_conversation_participants_user_id FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT fk_conversation_participants_conversation_id FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT conversation_participants_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id)
);
CREATE TABLE public.conversations (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  type text NOT NULL CHECK (type = ANY (ARRAY['direct'::text, 'group'::text, 'community'::text])),
  name text,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  last_message text,
  user1_id uuid,
  user2_id uuid,
  last_message_sender_id uuid,
  CONSTRAINT conversations_pkey PRIMARY KEY (id),
  CONSTRAINT conversations_last_message_sender_id_fkey FOREIGN KEY (last_message_sender_id) REFERENCES public.profiles(id),
  CONSTRAINT conversations_user2_id_fkey FOREIGN KEY (user2_id) REFERENCES public.profiles(id),
  CONSTRAINT conversations_user1_id_fkey FOREIGN KEY (user1_id) REFERENCES public.profiles(id),
  CONSTRAINT conversations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.event_participants (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  event_id uuid,
  user_id uuid,
  status text DEFAULT 'registered'::text CHECK (status = ANY (ARRAY['registered'::text, 'confirmed'::text, 'declined'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT event_participants_pkey PRIMARY KEY (id),
  CONSTRAINT event_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT event_participants_event_id_fkey FOREIGN KEY (event_id) REFERENCES public.events(id)
);
CREATE TABLE public.events (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  event_type text CHECK (event_type = ANY (ARRAY['tournament'::text, 'meetup'::text, 'stream'::text, 'community'::text, 'custom'::text])),
  start_time timestamp with time zone NOT NULL,
  end_time timestamp with time zone,
  location text,
  is_online boolean DEFAULT false,
  max_participants integer,
  current_participants integer DEFAULT 0,
  created_by uuid,
  community_id uuid,
  tournament_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT events_pkey PRIMARY KEY (id),
  CONSTRAINT events_community_id_fkey FOREIGN KEY (community_id) REFERENCES public.communities(id),
  CONSTRAINT events_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id),
  CONSTRAINT events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.follows (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  follower_id uuid,
  following_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT follows_pkey PRIMARY KEY (id),
  CONSTRAINT follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.profiles(id),
  CONSTRAINT follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.game_stats (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  game_id uuid,
  stats jsonb DEFAULT '{}'::jsonb,
  level integer DEFAULT 1,
  experience integer DEFAULT 0,
  achievements ARRAY DEFAULT '{}'::text[],
  last_played timestamp with time zone,
  total_playtime integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT game_stats_pkey PRIMARY KEY (id),
  CONSTRAINT game_stats_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id),
  CONSTRAINT game_stats_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.games (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  description text,
  genre text,
  platform ARRAY DEFAULT '{}'::text[],
  image_url text,
  banner_url text,
  release_date date,
  developer text,
  publisher text,
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT games_pkey PRIMARY KEY (id)
);
CREATE TABLE public.highlights (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  game_id uuid,
  title text NOT NULL,
  description text,
  video_url text NOT NULL,
  thumbnail_url text,
  duration integer,
  metadata jsonb DEFAULT '{}'::jsonb,
  view_count integer DEFAULT 0,
  like_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  stories ARRAY DEFAULT '{}'::text[],
  cover_story_id uuid,
  name text,
  CONSTRAINT highlights_pkey PRIMARY KEY (id),
  CONSTRAINT highlights_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id),
  CONSTRAINT highlights_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.leaderboard_entries (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  leaderboard_id uuid,
  user_id uuid,
  score numeric NOT NULL,
  rank integer,
  previous_rank integer,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT leaderboard_entries_pkey PRIMARY KEY (id),
  CONSTRAINT leaderboard_entries_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT leaderboard_entries_leaderboard_id_fkey FOREIGN KEY (leaderboard_id) REFERENCES public.leaderboards(id)
);
CREATE TABLE public.leaderboard_scores (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  content_score integer DEFAULT 0,
  community_score integer DEFAULT 0,
  tournament_score integer DEFAULT 0,
  total_score integer DEFAULT 0,
  last_updated timestamp with time zone DEFAULT now(),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT leaderboard_scores_pkey PRIMARY KEY (id),
  CONSTRAINT leaderboard_scores_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.leaderboards (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  game_id uuid,
  name text NOT NULL,
  description text,
  metric text NOT NULL,
  time_period text DEFAULT 'all_time'::text CHECK (time_period = ANY (ARRAY['daily'::text, 'weekly'::text, 'monthly'::text, 'all_time'::text])),
  is_active boolean DEFAULT true,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT leaderboards_pkey PRIMARY KEY (id),
  CONSTRAINT leaderboards_game_id_fkey FOREIGN KEY (game_id) REFERENCES public.games(id)
);
CREATE TABLE public.live_streams (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  streamer_id uuid,
  title text NOT NULL,
  description text,
  stream_url text NOT NULL,
  thumbnail_url text,
  game_tag text,
  is_live boolean DEFAULT false,
  viewer_count integer DEFAULT 0,
  start_time timestamp with time zone DEFAULT now(),
  end_time timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT live_streams_pkey PRIMARY KEY (id),
  CONSTRAINT live_streams_streamer_id_fkey FOREIGN KEY (streamer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.message_reactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  message_id uuid,
  user_id uuid,
  reaction text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT message_reactions_pkey PRIMARY KEY (id),
  CONSTRAINT message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(id)
);
CREATE TABLE public.messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  conversation_id uuid,
  sender_id uuid,
  content text NOT NULL,
  message_type text DEFAULT 'text'::text CHECK (message_type = ANY (ARRAY['text'::text, 'image'::text, 'video'::text, 'file'::text, 'system'::text])),
  media_url text,
  reply_to_id uuid,
  is_edited boolean DEFAULT false,
  edited_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  is_seen boolean DEFAULT false,
  is_delivered boolean DEFAULT false,
  reactions ARRAY DEFAULT '{}'::text[],
  is_pinned boolean DEFAULT false,
  shared_content_id uuid,
  shared_content_type text,
  CONSTRAINT messages_pkey PRIMARY KEY (id),
  CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT messages_reply_to_id_fkey FOREIGN KEY (reply_to_id) REFERENCES public.messages(id),
  CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id),
  CONSTRAINT fk_messages_conversation_id FOREIGN KEY (conversation_id) REFERENCES public.conversations(id),
  CONSTRAINT fk_messages_sender_id FOREIGN KEY (sender_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  type text NOT NULL CHECK (type = ANY (ARRAY['like'::text, 'comment'::text, 'follow'::text, 'mention'::text, 'tournament'::text, 'community'::text, 'message'::text, 'system'::text])),
  title text NOT NULL,
  body text NOT NULL,
  data jsonb DEFAULT '{}'::jsonb,
  is_read boolean DEFAULT false,
  read_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  message text,
  related_id uuid,
  sender_id uuid,
  sender_name text,
  sender_avatar_url text,
  metadata jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.profiles(id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.post_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT post_likes_pkey PRIMARY KEY (id),
  CONSTRAINT post_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT post_likes_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.post_shares (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  shared_at timestamp with time zone DEFAULT now(),
  share_platform text,
  CONSTRAINT post_shares_pkey PRIMARY KEY (id),
  CONSTRAINT post_shares_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id),
  CONSTRAINT post_shares_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.post_views (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  post_id uuid,
  user_id uuid,
  viewed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT post_views_pkey PRIMARY KEY (id),
  CONSTRAINT post_views_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.community_posts(id),
  CONSTRAINT post_views_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  content text NOT NULL,
  media_urls ARRAY DEFAULT '{}'::text[],
  game_tag text,
  location text,
  is_public boolean DEFAULT true,
  mentions ARRAY DEFAULT '{}'::text[],
  metadata jsonb DEFAULT '{}'::jsonb,
  like_count integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  view_count integer DEFAULT 0,
  pinned boolean DEFAULT false,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  share_count integer DEFAULT 0,
  CONSTRAINT posts_pkey PRIMARY KEY (id),
  CONSTRAINT posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.profiles (
  id uuid NOT NULL,
  username text NOT NULL UNIQUE,
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
  favorite_games ARRAY DEFAULT '{}'::text[],
  gaming_setup text,
  achievements text,
  level integer DEFAULT 1,
  game_stats jsonb DEFAULT '{}'::jsonb,
  is_public boolean DEFAULT true,
  allow_messages boolean DEFAULT true,
  allow_follows boolean DEFAULT true,
  is_verified boolean DEFAULT false,
  status text DEFAULT 'offline'::text CHECK (status = ANY (ARRAY['online'::text, 'offline'::text, 'away'::text])),
  last_active timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  is_premium boolean DEFAULT false,
  premium_tier text CHECK (premium_tier = ANY (ARRAY['monthly'::text, 'yearly'::text, 'lifetime'::text])),
  premium_expires_at timestamp with time zone,
  premium_since timestamp with time zone,
  allow_4k_streams boolean DEFAULT is_premium,
  unlimited_clips boolean DEFAULT is_premium,
  vip_access boolean DEFAULT is_premium,
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);
CREATE TABLE public.random_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid NOT NULL,
  sender_id uuid NOT NULL,
  content text NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT random_messages_pkey PRIMARY KEY (id),
  CONSTRAINT random_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id),
  CONSTRAINT random_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.random_sessions(id)
);
CREATE TABLE public.random_presence (
  session_id uuid NOT NULL,
  user_id uuid NOT NULL,
  typing boolean NOT NULL DEFAULT false,
  updated_at timestamp with time zone NOT NULL DEFAULT now(),
  CONSTRAINT random_presence_pkey PRIMARY KEY (session_id, user_id),
  CONSTRAINT random_presence_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.random_sessions(id),
  CONSTRAINT random_presence_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.random_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  a_user_id uuid,
  b_user_id uuid,
  status text NOT NULL DEFAULT 'matching'::text CHECK (status = ANY (ARRAY['matching'::text, 'connected'::text, 'ended'::text])),
  created_at timestamp with time zone NOT NULL DEFAULT now(),
  ended_at timestamp with time zone,
  end_reason text,
  interests ARRAY NOT NULL DEFAULT '{}'::text[],
  mode text NOT NULL DEFAULT 'text'::text CHECK (mode = ANY (ARRAY['text'::text, 'video'::text, 'spy'::text])),
  question text,
  CONSTRAINT random_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT random_sessions_a_user_id_fkey FOREIGN KEY (a_user_id) REFERENCES auth.users(id),
  CONSTRAINT random_sessions_b_user_id_fkey FOREIGN KEY (b_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.reel_comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reel_id uuid,
  user_id uuid,
  content text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reel_comments_pkey PRIMARY KEY (id),
  CONSTRAINT reel_comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT reel_comments_reel_id_fkey FOREIGN KEY (reel_id) REFERENCES public.reels(id)
);
CREATE TABLE public.reel_likes (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  reel_id uuid,
  user_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT reel_likes_pkey PRIMARY KEY (id),
  CONSTRAINT reel_likes_reel_id_fkey FOREIGN KEY (reel_id) REFERENCES public.reels(id),
  CONSTRAINT reel_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.reels (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  caption text,
  video_url text NOT NULL,
  thumbnail_url text,
  game_tag text,
  duration integer,
  metadata jsonb DEFAULT '{}'::jsonb,
  view_count integer DEFAULT 0,
  like_count integer DEFAULT 0,
  comment_count integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  share_count integer DEFAULT 0,
  CONSTRAINT reels_pkey PRIMARY KEY (id),
  CONSTRAINT reels_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.saved_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  post_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT saved_posts_pkey PRIMARY KEY (id),
  CONSTRAINT saved_posts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT saved_posts_post_id_fkey FOREIGN KEY (post_id) REFERENCES public.posts(id)
);
CREATE TABLE public.shared_post_recipients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shared_post_id uuid,
  recipient_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shared_post_recipients_pkey PRIMARY KEY (id),
  CONSTRAINT shared_post_recipients_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.shared_posts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  original_post_id uuid,
  shared_by_id uuid,
  message text,
  share_type text DEFAULT 'specific'::text,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shared_posts_pkey PRIMARY KEY (id),
  CONSTRAINT shared_posts_original_post_id_fkey FOREIGN KEY (original_post_id) REFERENCES public.posts(id),
  CONSTRAINT shared_posts_shared_by_id_fkey FOREIGN KEY (shared_by_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.shared_reel_recipients (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  shared_reel_id uuid,
  recipient_id uuid,
  is_read boolean DEFAULT false,
  read_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shared_reel_recipients_pkey PRIMARY KEY (id),
  CONSTRAINT shared_reel_recipients_shared_reel_id_fkey FOREIGN KEY (shared_reel_id) REFERENCES public.shared_reels(id),
  CONSTRAINT shared_reel_recipients_recipient_id_fkey FOREIGN KEY (recipient_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.shared_reels (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  original_reel_id uuid,
  shared_by_id uuid,
  message text,
  share_type text DEFAULT 'specific'::text CHECK (share_type = ANY (ARRAY['public'::text, 'followers'::text, 'specific'::text, 'message'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT shared_reels_pkey PRIMARY KEY (id),
  CONSTRAINT shared_reels_original_reel_id_fkey FOREIGN KEY (original_reel_id) REFERENCES public.reels(id),
  CONSTRAINT shared_reels_shared_by_id_fkey FOREIGN KEY (shared_by_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.stick_cam_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid,
  sender_id uuid,
  content text NOT NULL,
  message_type text NOT NULL DEFAULT 'text'::text CHECK (message_type = ANY (ARRAY['text'::text, 'system'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT stick_cam_messages_pkey PRIMARY KEY (id),
  CONSTRAINT stick_cam_messages_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.stick_cam_sessions(id),
  CONSTRAINT stick_cam_messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id)
);
CREATE TABLE public.stick_cam_presence (
  session_id uuid NOT NULL,
  user_id uuid NOT NULL,
  typing boolean DEFAULT false,
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT stick_cam_presence_pkey PRIMARY KEY (session_id, user_id),
  CONSTRAINT stick_cam_presence_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.stick_cam_sessions(id),
  CONSTRAINT stick_cam_presence_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.stick_cam_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  a_user_id uuid,
  b_user_id uuid,
  status text NOT NULL DEFAULT 'matching'::text CHECK (status = ANY (ARRAY['matching'::text, 'connected'::text, 'ended'::text])),
  interests ARRAY DEFAULT '{}'::text[],
  mode text NOT NULL DEFAULT 'video'::text CHECK (mode = ANY (ARRAY['video'::text, 'audio'::text, 'text'::text])),
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  ended_at timestamp with time zone,
  end_reason text,
  CONSTRAINT stick_cam_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT stick_cam_sessions_a_user_id_fkey FOREIGN KEY (a_user_id) REFERENCES auth.users(id),
  CONSTRAINT stick_cam_sessions_b_user_id_fkey FOREIGN KEY (b_user_id) REFERENCES auth.users(id)
);
CREATE TABLE public.stories (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  content text,
  media_url text,
  media_type text CHECK (media_type = ANY (ARRAY['image'::text, 'video'::text])),
  duration integer DEFAULT 5,
  created_at timestamp with time zone DEFAULT now(),
  expires_at timestamp with time zone DEFAULT (now() + '24:00:00'::interval),
  CONSTRAINT stories_pkey PRIMARY KEY (id),
  CONSTRAINT stories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.story_views (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  story_id uuid,
  viewer_id uuid,
  viewed_at timestamp with time zone DEFAULT now(),
  CONSTRAINT story_views_pkey PRIMARY KEY (id),
  CONSTRAINT story_views_story_id_fkey FOREIGN KEY (story_id) REFERENCES public.stories(id),
  CONSTRAINT story_views_viewer_id_fkey FOREIGN KEY (viewer_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.stream_viewers (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  stream_id uuid,
  viewer_id uuid,
  joined_at timestamp with time zone DEFAULT now(),
  left_at timestamp with time zone,
  CONSTRAINT stream_viewers_pkey PRIMARY KEY (id),
  CONSTRAINT stream_viewers_viewer_id_fkey FOREIGN KEY (viewer_id) REFERENCES public.profiles(id),
  CONSTRAINT stream_viewers_stream_id_fkey FOREIGN KEY (stream_id) REFERENCES public.live_streams(id)
);
CREATE TABLE public.tournament_matches (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  round_number integer NOT NULL,
  match_number integer NOT NULL,
  participant_a_id uuid,
  participant_b_id uuid,
  team_a_id uuid,
  team_b_id uuid,
  winner_participant_id uuid,
  winner_team_id uuid,
  winner_type text CHECK (winner_type = ANY (ARRAY['participant'::text, 'team'::text, NULL::text])),
  status text DEFAULT 'scheduled'::text CHECK (status = ANY (ARRAY['scheduled'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text])),
  scheduled_time timestamp with time zone,
  started_at timestamp with time zone,
  completed_at timestamp with time zone,
  score_a integer DEFAULT 0,
  score_b integer DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  winner_id uuid,
  CONSTRAINT tournament_matches_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_matches_participant_a_id_fkey FOREIGN KEY (participant_a_id) REFERENCES public.tournament_participants(id),
  CONSTRAINT tournament_matches_team_a_id_fkey FOREIGN KEY (team_a_id) REFERENCES public.tournament_teams(id),
  CONSTRAINT tournament_matches_team_b_id_fkey FOREIGN KEY (team_b_id) REFERENCES public.tournament_teams(id),
  CONSTRAINT tournament_matches_winner_participant_id_fkey FOREIGN KEY (winner_participant_id) REFERENCES public.tournament_participants(id),
  CONSTRAINT tournament_matches_winner_team_id_fkey FOREIGN KEY (winner_team_id) REFERENCES public.tournament_teams(id),
  CONSTRAINT tournament_matches_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id),
  CONSTRAINT tournament_matches_participant_b_id_fkey FOREIGN KEY (participant_b_id) REFERENCES public.tournament_participants(id)
);
CREATE TABLE public.tournament_media (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  user_id uuid,
  media_url text NOT NULL,
  media_type text CHECK (media_type = ANY (ARRAY['image'::text, 'video'::text, 'highlight'::text])),
  caption text,
  approved boolean DEFAULT false,
  approved_by uuid,
  approved_at timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_media_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_media_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.profiles(id),
  CONSTRAINT tournament_media_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id),
  CONSTRAINT tournament_media_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.tournament_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  user_id uuid,
  message text NOT NULL,
  message_type text DEFAULT 'general'::text CHECK (message_type = ANY (ARRAY['general'::text, 'announcement'::text, 'system'::text])),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_messages_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_messages_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id),
  CONSTRAINT tournament_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.tournament_participants (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  user_id uuid,
  team_id uuid,
  status text DEFAULT 'registered'::text CHECK (status = ANY (ARRAY['registered'::text, 'confirmed'::text, 'eliminated'::text, 'winner'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  checked_in boolean DEFAULT false,
  checked_in_at timestamp with time zone,
  CONSTRAINT tournament_participants_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_participants_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT tournament_participants_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id)
);
CREATE TABLE public.tournament_roles (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  user_id uuid,
  role text NOT NULL CHECK (role = ANY (ARRAY['owner'::text, 'admin'::text, 'moderator'::text, 'participant'::text])),
  permissions jsonb DEFAULT '{}'::jsonb,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_roles_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_roles_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id),
  CONSTRAINT tournament_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.tournament_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  max_teams integer,
  max_participants_per_team integer,
  allow_spectators boolean DEFAULT true,
  registration_deadline timestamp with time zone,
  check_in_required boolean DEFAULT false,
  check_in_duration integer DEFAULT 15,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_settings_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_settings_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id)
);
CREATE TABLE public.tournament_team_members (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  team_id uuid,
  user_id uuid,
  role text DEFAULT 'member'::text CHECK (role = ANY (ARRAY['captain'::text, 'member'::text])),
  joined_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_team_members_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_team_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id),
  CONSTRAINT tournament_team_members_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.tournament_teams(id)
);
CREATE TABLE public.tournament_teams (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  tournament_id uuid,
  name text NOT NULL,
  description text,
  logo_url text,
  captain_id uuid,
  member_count integer DEFAULT 0,
  max_members integer DEFAULT 5,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournament_teams_pkey PRIMARY KEY (id),
  CONSTRAINT tournament_teams_captain_id_fkey FOREIGN KEY (captain_id) REFERENCES public.profiles(id),
  CONSTRAINT tournament_teams_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id)
);
CREATE TABLE public.tournaments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text NOT NULL,
  type text NOT NULL CHECK (type = ANY (ARRAY['solo'::text, 'team'::text])),
  game text NOT NULL,
  start_date timestamp with time zone NOT NULL,
  end_date timestamp with time zone,
  status text DEFAULT 'upcoming'::text CHECK (status = ANY (ARRAY['upcoming'::text, 'ongoing'::text, 'completed'::text, 'cancelled'::text])),
  max_participants integer NOT NULL,
  current_participants integer DEFAULT 0,
  prize_pool text,
  rules text,
  media_url text,
  created_by uuid,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT tournaments_pkey PRIMARY KEY (id),
  CONSTRAINT tournaments_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_sessions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  session_id text NOT NULL UNIQUE,
  started_at timestamp with time zone DEFAULT now(),
  ended_at timestamp with time zone,
  duration integer,
  device_info jsonb DEFAULT '{}'::jsonb,
  CONSTRAINT user_sessions_pkey PRIMARY KEY (id),
  CONSTRAINT user_sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.user_settings (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  notification_preferences jsonb DEFAULT '{}'::jsonb,
  privacy_settings jsonb DEFAULT '{}'::jsonb,
  theme_preference text DEFAULT 'system'::text,
  language text DEFAULT 'en'::text,
  timezone text DEFAULT 'UTC'::text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT user_settings_pkey PRIMARY KEY (id),
  CONSTRAINT user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id)
);
CREATE TABLE public.webrtc_signaling (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  session_id uuid,
  sender_id uuid,
  message_type text NOT NULL CHECK (message_type = ANY (ARRAY['offer'::text, 'answer'::text, 'ice-candidate'::text])),
  message_data text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT webrtc_signaling_pkey PRIMARY KEY (id),
  CONSTRAINT webrtc_signaling_session_id_fkey FOREIGN KEY (session_id) REFERENCES public.stick_cam_sessions(id),
  CONSTRAINT webrtc_signaling_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES auth.users(id)
);