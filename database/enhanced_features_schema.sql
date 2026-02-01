-- Enhanced Features Schema
-- Includes: Polls, Reports, Mod Logs, Karma, User Blocks

-- ============================================
-- POLLS SYSTEM
-- ============================================

-- Community Polls table
CREATE TABLE IF NOT EXISTS community_polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  question TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'singleChoice',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  allow_multiple_votes BOOLEAN DEFAULT FALSE,
  show_results_before_voting BOOLEAN DEFAULT FALSE,
  is_anonymous BOOLEAN DEFAULT FALSE,
  total_votes INTEGER DEFAULT 0,
  is_closed BOOLEAN DEFAULT FALSE,
  
  UNIQUE(post_id)
);

-- Poll Options table
CREATE TABLE IF NOT EXISTS poll_options (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES community_polls(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  vote_count INTEGER DEFAULT 0,
  image_url TEXT,
  position INTEGER DEFAULT 0
);

-- Poll Votes table
CREATE TABLE IF NOT EXISTS poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES community_polls(id) ON DELETE CASCADE,
  option_id UUID NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(poll_id, user_id, option_id)
);

-- Indexes for polls
CREATE INDEX IF NOT EXISTS idx_poll_options_poll_id ON poll_options(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_poll_id ON poll_votes(poll_id);
CREATE INDEX IF NOT EXISTS idx_poll_votes_user_id ON poll_votes(user_id);

-- Function to increment poll option votes
CREATE OR REPLACE FUNCTION increment_poll_option_votes(option_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE poll_options
  SET vote_count = vote_count + 1
  WHERE id = option_uuid;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement poll option votes
CREATE OR REPLACE FUNCTION decrement_poll_option_votes(option_uuid UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE poll_options
  SET vote_count = GREATEST(0, vote_count - 1)
  WHERE id = option_uuid;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- CONTENT REPORTING SYSTEM
-- ============================================

-- Content Reports table
CREATE TABLE IF NOT EXISTS content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_type VARCHAR(50) NOT NULL,
  target_id UUID NOT NULL,
  reason VARCHAR(50) NOT NULL,
  custom_reason TEXT,
  description TEXT,
  status VARCHAR(50) DEFAULT 'pending',
  community_id UUID REFERENCES communities(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES profiles(id),
  review_notes TEXT,
  action_taken VARCHAR(50)
);

-- Indexes for reports
CREATE INDEX IF NOT EXISTS idx_reports_status ON content_reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_target ON content_reports(target_type, target_id);
CREATE INDEX IF NOT EXISTS idx_reports_community ON content_reports(community_id);
CREATE INDEX IF NOT EXISTS idx_reports_created ON content_reports(created_at DESC);

-- User Blocks table
CREATE TABLE IF NOT EXISTS user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  reason TEXT,
  
  UNIQUE(blocker_id, blocked_user_id)
);

-- Index for user blocks
CREATE INDEX IF NOT EXISTS idx_user_blocks_blocker ON user_blocks(blocker_id);

-- ============================================
-- MOD LOG SYSTEM
-- ============================================

-- Mod Logs table
CREATE TABLE IF NOT EXISTS mod_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id UUID NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  action VARCHAR(50) NOT NULL,
  target_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  target_content_id UUID,
  target_type VARCHAR(50),
  reason TEXT,
  details TEXT,
  previous_state JSONB,
  new_state JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  is_public BOOLEAN DEFAULT TRUE
);

-- Indexes for mod logs
CREATE INDEX IF NOT EXISTS idx_mod_logs_community ON mod_logs(community_id);
CREATE INDEX IF NOT EXISTS idx_mod_logs_moderator ON mod_logs(moderator_id);
CREATE INDEX IF NOT EXISTS idx_mod_logs_target_user ON mod_logs(target_user_id);
CREATE INDEX IF NOT EXISTS idx_mod_logs_created ON mod_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_mod_logs_action ON mod_logs(action);

-- ============================================
-- KARMA SYSTEM
-- ============================================

-- User Karma table
CREATE TABLE IF NOT EXISTS user_karma (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  post_karma INTEGER DEFAULT 0,
  comment_karma INTEGER DEFAULT 0,
  award_karma INTEGER DEFAULT 0,
  total_karma INTEGER DEFAULT 0,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- Karma History table
CREATE TABLE IF NOT EXISTS karma_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  karma_type VARCHAR(50) NOT NULL,
  amount INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for karma
CREATE INDEX IF NOT EXISTS idx_karma_user ON user_karma(user_id);
CREATE INDEX IF NOT EXISTS idx_karma_total ON user_karma(total_karma DESC);
CREATE INDEX IF NOT EXISTS idx_karma_history_user ON karma_history(user_id);
CREATE INDEX IF NOT EXISTS idx_karma_history_created ON karma_history(created_at DESC);

-- Function to add user karma
CREATE OR REPLACE FUNCTION add_user_karma(
  user_uuid UUID,
  karma_type VARCHAR(50),
  karma_amount INTEGER
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO user_karma (user_id, post_karma, comment_karma, award_karma, total_karma, updated_at)
  VALUES (user_uuid, 0, 0, 0, 0, NOW())
  ON CONFLICT (user_id) DO NOTHING;

  IF karma_type = 'post' THEN
    UPDATE user_karma
    SET post_karma = post_karma + karma_amount,
        total_karma = total_karma + karma_amount,
        updated_at = NOW()
    WHERE user_id = user_uuid;
  ELSIF karma_type = 'comment' THEN
    UPDATE user_karma
    SET comment_karma = comment_karma + karma_amount,
        total_karma = total_karma + karma_amount,
        updated_at = NOW()
    WHERE user_id = user_uuid;
  ELSIF karma_type = 'award' THEN
    UPDATE user_karma
    SET award_karma = award_karma + karma_amount,
        total_karma = total_karma + karma_amount,
        updated_at = NOW()
    WHERE user_id = user_uuid;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- ============================================
-- PRESENCE SYSTEM
-- ============================================

-- Presence table (fallback for when Realtime is unavailable)
CREATE TABLE IF NOT EXISTS presence (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_online BOOLEAN DEFAULT FALSE,
  status VARCHAR(50) DEFAULT 'offline',
  last_seen TIMESTAMPTZ DEFAULT NOW(),
  custom_status TEXT,
  
  UNIQUE(user_id)
);

-- Typing indicators table
CREATE TABLE IF NOT EXISTS typing (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_typing BOOLEAN DEFAULT FALSE,
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(conversation_id, user_id)
);

-- Indexes for presence
CREATE INDEX IF NOT EXISTS idx_presence_user ON presence(user_id);
CREATE INDEX IF NOT EXISTS idx_presence_online ON presence(is_online);
CREATE INDEX IF NOT EXISTS idx_typing_conversation ON typing(conversation_id);

-- ============================================
-- ADDITIONAL COMMUNITY COLUMNS
-- ============================================

-- Add karma_requirement to communities if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'communities' AND column_name = 'karma_requirement'
  ) THEN
    ALTER TABLE communities ADD COLUMN karma_requirement INTEGER DEFAULT 0;
  END IF;
END $$;

-- Add enable_mod_log to communities if not exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'communities' AND column_name = 'enable_mod_log'
  ) THEN
    ALTER TABLE communities ADD COLUMN enable_mod_log BOOLEAN DEFAULT TRUE;
  END IF;
END $$;

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS on new tables
ALTER TABLE community_polls ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_options ENABLE ROW LEVEL SECURITY;
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE content_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE mod_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_karma ENABLE ROW LEVEL SECURITY;
ALTER TABLE karma_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE presence ENABLE ROW LEVEL SECURITY;
ALTER TABLE typing ENABLE ROW LEVEL SECURITY;

-- Polls: Anyone can read, authenticated users can create/vote
CREATE POLICY "Polls are viewable by everyone" ON community_polls
  FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create polls" ON community_polls
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Poll options: Public read
CREATE POLICY "Poll options are viewable by everyone" ON poll_options
  FOR SELECT USING (true);

CREATE POLICY "Poll options can be created with polls" ON poll_options
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Poll votes: Users can manage their own votes
CREATE POLICY "Users can see all votes" ON poll_votes
  FOR SELECT USING (true);

CREATE POLICY "Users can vote" ON poll_votes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their votes" ON poll_votes
  FOR DELETE USING (auth.uid() = user_id);

-- Reports: Users can create, only moderators can view all
CREATE POLICY "Users can create reports" ON content_reports
  FOR INSERT WITH CHECK (auth.uid() = reporter_id);

CREATE POLICY "Users can view their own reports" ON content_reports
  FOR SELECT USING (auth.uid() = reporter_id OR auth.uid() = reviewed_by);

-- User blocks: Users manage their own blocks
CREATE POLICY "Users can view their blocks" ON user_blocks
  FOR SELECT USING (auth.uid() = blocker_id);

CREATE POLICY "Users can create blocks" ON user_blocks
  FOR INSERT WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can remove blocks" ON user_blocks
  FOR DELETE USING (auth.uid() = blocker_id);

-- Mod logs: Public logs viewable by all, private by moderators
CREATE POLICY "Public mod logs are viewable" ON mod_logs
  FOR SELECT USING (is_public = true OR auth.uid() = moderator_id);

CREATE POLICY "Moderators can create logs" ON mod_logs
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Karma: Public read, system write
CREATE POLICY "Karma is public" ON user_karma
  FOR SELECT USING (true);

CREATE POLICY "Users can update their karma" ON user_karma
  FOR ALL USING (auth.uid() IS NOT NULL);

-- Karma history: Users see their own
CREATE POLICY "Users see their karma history" ON karma_history
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can create karma history" ON karma_history
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- Presence: Users manage their own
CREATE POLICY "Presence is public" ON presence
  FOR SELECT USING (true);

CREATE POLICY "Users manage their presence" ON presence
  FOR ALL USING (auth.uid() = user_id);

-- Typing: Users in conversation can see
CREATE POLICY "Typing is visible to conversation participants" ON typing
  FOR SELECT USING (true);

CREATE POLICY "Users manage their typing status" ON typing
  FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- TRIGGERS
-- ============================================

-- Trigger to update poll total_votes when votes change
CREATE OR REPLACE FUNCTION update_poll_total_votes()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE community_polls
    SET total_votes = total_votes + 1
    WHERE id = NEW.poll_id;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE community_polls
    SET total_votes = GREATEST(0, total_votes - 1)
    WHERE id = OLD.poll_id;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_poll_vote_count ON poll_votes;
CREATE TRIGGER trigger_poll_vote_count
  AFTER INSERT OR DELETE ON poll_votes
  FOR EACH ROW
  EXECUTE FUNCTION update_poll_total_votes();

-- Trigger to auto-close expired polls
CREATE OR REPLACE FUNCTION close_expired_polls()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE community_polls
  SET is_closed = TRUE
  WHERE expires_at IS NOT NULL 
    AND expires_at < NOW() 
    AND is_closed = FALSE;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;
