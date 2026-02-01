-- Game Stats and Sessions Schema
-- Run this migration to add game tracking tables

-- Game sessions table (individual play sessions)
CREATE TABLE IF NOT EXISTS game_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  duration_minutes INT DEFAULT 0,
  stats JSONB DEFAULT '{}',
  match_id UUID,
  tournament_id UUID REFERENCES tournaments(id),
  played_at TIMESTAMPTZ DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Aggregate game stats per user per game
CREATE TABLE IF NOT EXISTS game_stats (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  total_playtime_minutes INT DEFAULT 0,
  matches_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  win_rate DECIMAL(5, 2) DEFAULT 0,
  total_kills INT DEFAULT 0,
  total_deaths INT DEFAULT 0,
  total_assists INT DEFAULT 0,
  kda_ratio DECIMAL(6, 2) DEFAULT 0,
  highest_score INT DEFAULT 0,
  average_score DECIMAL(10, 2) DEFAULT 0,
  last_played TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, game_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_game_sessions_user_id ON game_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_game_id ON game_sessions(game_id);
CREATE INDEX IF NOT EXISTS idx_game_sessions_played_at ON game_sessions(played_at DESC);
CREATE INDEX IF NOT EXISTS idx_game_stats_user_id ON game_stats(user_id);
CREATE INDEX IF NOT EXISTS idx_game_stats_game_id ON game_stats(game_id);
CREATE INDEX IF NOT EXISTS idx_game_stats_wins ON game_stats(wins DESC);
CREATE INDEX IF NOT EXISTS idx_game_stats_playtime ON game_stats(total_playtime_minutes DESC);

-- RLS Policies
ALTER TABLE game_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_stats ENABLE ROW LEVEL SECURITY;

-- Users can view their own sessions
CREATE POLICY "Users can view own sessions" ON game_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- Users can insert their own sessions
CREATE POLICY "Users can insert own sessions" ON game_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Anyone can view game stats (for leaderboards)
CREATE POLICY "Anyone can view game stats" ON game_stats
  FOR SELECT USING (true);

-- Users can manage their own stats
CREATE POLICY "Users can manage own stats" ON game_stats
  FOR ALL USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT, INSERT ON game_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON game_stats TO authenticated;
