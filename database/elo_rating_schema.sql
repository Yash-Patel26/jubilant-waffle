-- ELO Rating System Schema
-- Run this migration to add competitive ranking tables

-- Player ratings per game
CREATE TABLE IF NOT EXISTS player_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  rating INT DEFAULT 1200,
  games_played INT DEFAULT 0,
  wins INT DEFAULT 0,
  losses INT DEFAULT 0,
  win_streak INT DEFAULT 0,
  best_win_streak INT DEFAULT 0,
  peak_rating INT DEFAULT 1200,
  last_rating_change INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, game_id)
);

-- Rating history for analytics and graphs
CREATE TABLE IF NOT EXISTS rating_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  old_rating INT NOT NULL,
  new_rating INT NOT NULL,
  rating_change INT NOT NULL,
  opponent_id UUID REFERENCES profiles(id),
  opponent_rating INT,
  won BOOLEAN NOT NULL,
  match_id UUID,
  tournament_id UUID REFERENCES tournaments(id),
  recorded_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_player_ratings_user_id ON player_ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_player_ratings_game_id ON player_ratings(game_id);
CREATE INDEX IF NOT EXISTS idx_player_ratings_rating ON player_ratings(rating DESC);
CREATE INDEX IF NOT EXISTS idx_player_ratings_composite ON player_ratings(game_id, rating DESC);
CREATE INDEX IF NOT EXISTS idx_rating_history_user_id ON rating_history(user_id);
CREATE INDEX IF NOT EXISTS idx_rating_history_game_id ON rating_history(game_id);
CREATE INDEX IF NOT EXISTS idx_rating_history_recorded_at ON rating_history(recorded_at DESC);

-- Function to get rank name from rating
CREATE OR REPLACE FUNCTION get_rank_name(rating INT)
RETURNS TEXT AS $$
BEGIN
  RETURN CASE
    WHEN rating >= 2400 THEN 'Legend'
    WHEN rating >= 2200 THEN 'Champion'
    WHEN rating >= 2000 THEN 'Grandmaster'
    WHEN rating >= 1800 THEN 'Master'
    WHEN rating >= 1600 THEN 'Diamond'
    WHEN rating >= 1400 THEN 'Platinum'
    WHEN rating >= 1200 THEN 'Gold'
    WHEN rating >= 1000 THEN 'Silver'
    ELSE 'Bronze'
  END;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to find matchmaking opponents within rating range
CREATE OR REPLACE FUNCTION find_matchmaking_opponents(
  p_user_id UUID,
  p_game_id UUID,
  p_rating_range INT DEFAULT 100,
  p_limit INT DEFAULT 10
)
RETURNS TABLE (
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  rating INT,
  games_played INT,
  win_rate DECIMAL,
  rank_name TEXT
) AS $$
DECLARE
  player_rating INT;
BEGIN
  -- Get player's current rating
  SELECT COALESCE(pr.rating, 1200) INTO player_rating
  FROM player_ratings pr
  WHERE pr.user_id = p_user_id AND pr.game_id = p_game_id;
  
  IF player_rating IS NULL THEN
    player_rating := 1200;
  END IF;
  
  RETURN QUERY
  SELECT 
    pr.user_id,
    p.username,
    p.avatar_url,
    pr.rating,
    pr.games_played,
    CASE WHEN pr.games_played > 0 
         THEN (pr.wins::DECIMAL / pr.games_played * 100)
         ELSE 0 END as win_rate,
    get_rank_name(pr.rating) as rank_name
  FROM player_ratings pr
  JOIN profiles p ON p.id = pr.user_id
  WHERE pr.game_id = p_game_id
    AND pr.user_id != p_user_id
    AND pr.rating BETWEEN (player_rating - p_rating_range) AND (player_rating + p_rating_range)
  ORDER BY ABS(pr.rating - player_rating)
  LIMIT p_limit;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get game leaderboard with ranks
CREATE OR REPLACE FUNCTION get_game_rating_leaderboard(
  p_game_id UUID,
  p_limit INT DEFAULT 100,
  p_offset INT DEFAULT 0
)
RETURNS TABLE (
  rank INT,
  user_id UUID,
  username TEXT,
  avatar_url TEXT,
  rating INT,
  games_played INT,
  wins INT,
  losses INT,
  win_rate DECIMAL,
  win_streak INT,
  peak_rating INT,
  rank_name TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ROW_NUMBER() OVER (ORDER BY pr.rating DESC)::INT as rank,
    pr.user_id,
    p.username,
    p.avatar_url,
    pr.rating,
    pr.games_played,
    pr.wins,
    pr.losses,
    CASE WHEN pr.games_played > 0 
         THEN (pr.wins::DECIMAL / pr.games_played * 100)
         ELSE 0 END as win_rate,
    pr.win_streak,
    pr.peak_rating,
    get_rank_name(pr.rating) as rank_name
  FROM player_ratings pr
  JOIN profiles p ON p.id = pr.user_id
  WHERE pr.game_id = p_game_id
    AND pr.games_played > 0
  ORDER BY pr.rating DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE player_ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE rating_history ENABLE ROW LEVEL SECURITY;

-- Anyone can view ratings (for leaderboards)
CREATE POLICY "Anyone can view ratings" ON player_ratings
  FOR SELECT USING (true);

-- Users can manage their own ratings (via service)
CREATE POLICY "Users can manage own ratings" ON player_ratings
  FOR ALL USING (auth.uid() = user_id);

-- Users can view their own rating history
CREATE POLICY "Users can view own history" ON rating_history
  FOR SELECT USING (auth.uid() = user_id OR auth.uid() = opponent_id);

-- System can insert rating history
CREATE POLICY "System can insert history" ON rating_history
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT ON player_ratings TO authenticated;
GRANT SELECT, INSERT, UPDATE ON player_ratings TO authenticated;
GRANT SELECT, INSERT ON rating_history TO authenticated;
GRANT EXECUTE ON FUNCTION get_rank_name TO authenticated;
GRANT EXECUTE ON FUNCTION find_matchmaking_opponents TO authenticated;
GRANT EXECUTE ON FUNCTION get_game_rating_leaderboard TO authenticated;
