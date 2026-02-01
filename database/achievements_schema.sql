-- Achievement System Schema
-- Run this migration to add achievement tables to the database

-- User achievements table (stores unlocked achievements)
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id VARCHAR(100) NOT NULL,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  progress INT DEFAULT 100,
  is_complete BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, achievement_id)
);

-- Achievement progress tracking (for incremental achievements)
CREATE TABLE IF NOT EXISTS achievement_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id VARCHAR(100) NOT NULL,
  current_value INT DEFAULT 0,
  target_value INT NOT NULL,
  last_updated TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, achievement_id)
);

-- Add achievement_points column to profiles if not exists
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'profiles' AND column_name = 'achievement_points'
  ) THEN
    ALTER TABLE profiles ADD COLUMN achievement_points INT DEFAULT 0;
  END IF;
END $$;

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id 
  ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id 
  ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_achievement_progress_user_id 
  ON achievement_progress(user_id);

-- Function to add achievement points
CREATE OR REPLACE FUNCTION add_achievement_points(
  user_uuid UUID,
  points_to_add INT
)
RETURNS VOID AS $$
BEGIN
  UPDATE profiles 
  SET achievement_points = COALESCE(achievement_points, 0) + points_to_add
  WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user achievement stats
CREATE OR REPLACE FUNCTION get_user_achievement_stats(user_uuid UUID)
RETURNS TABLE (
  total_achievements INT,
  total_points INT,
  latest_achievement_id VARCHAR,
  latest_unlocked_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COUNT(*)::INT as total_achievements,
    COALESCE(p.achievement_points, 0)::INT as total_points,
    (SELECT ua.achievement_id FROM user_achievements ua 
     WHERE ua.user_id = user_uuid 
     ORDER BY ua.unlocked_at DESC LIMIT 1) as latest_achievement_id,
    (SELECT ua.unlocked_at FROM user_achievements ua 
     WHERE ua.user_id = user_uuid 
     ORDER BY ua.unlocked_at DESC LIMIT 1) as latest_unlocked_at
  FROM user_achievements a
  LEFT JOIN profiles p ON p.id = user_uuid
  WHERE a.user_id = user_uuid
  GROUP BY p.achievement_points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_progress ENABLE ROW LEVEL SECURITY;

-- Users can view their own achievements
CREATE POLICY "Users can view own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

-- Users can view others' achievements (for profile display)
CREATE POLICY "Anyone can view achievements" ON user_achievements
  FOR SELECT USING (true);

-- Only system can insert achievements (via service)
CREATE POLICY "System can insert achievements" ON user_achievements
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can view their own progress
CREATE POLICY "Users can view own progress" ON achievement_progress
  FOR SELECT USING (auth.uid() = user_id);

-- System can manage progress
CREATE POLICY "System can manage progress" ON achievement_progress
  FOR ALL USING (auth.uid() = user_id);

-- Trigger to update achievement points on new achievement
CREATE OR REPLACE FUNCTION update_achievement_points_trigger()
RETURNS TRIGGER AS $$
DECLARE
  points_map JSONB := '{
    "first_post": 10,
    "content_creator_10": 25,
    "content_creator_50": 50,
    "content_creator_100": 100,
    "viral_post": 100,
    "first_reel": 15,
    "first_tournament": 15,
    "first_win": 25,
    "tournament_champion": 100,
    "tournament_veteran": 50,
    "winning_streak_5": 75,
    "tournament_host": 50,
    "community_member": 10,
    "community_leader": 100,
    "community_founder": 25,
    "active_contributor": 50,
    "social_butterfly": 25,
    "popular": 50,
    "influencer": 100,
    "celebrity": 250,
    "first_friend": 10,
    "daily_streak_7": 25,
    "daily_streak_30": 75,
    "daily_streak_100": 150,
    "leaderboard_top_100": 50,
    "leaderboard_top_10": 150,
    "leaderboard_top_1": 250
  }'::JSONB;
  achievement_points INT;
BEGIN
  -- Get points for this achievement
  achievement_points := COALESCE((points_map->>NEW.achievement_id)::INT, 0);
  
  -- Add points to user
  IF achievement_points > 0 THEN
    UPDATE profiles 
    SET achievement_points = COALESCE(achievement_points, 0) + achievement_points
    WHERE id = NEW.user_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger (drop if exists first)
DROP TRIGGER IF EXISTS trigger_update_achievement_points ON user_achievements;
CREATE TRIGGER trigger_update_achievement_points
  AFTER INSERT ON user_achievements
  FOR EACH ROW
  EXECUTE FUNCTION update_achievement_points_trigger();

-- Grant necessary permissions
GRANT SELECT ON user_achievements TO authenticated;
GRANT SELECT ON achievement_progress TO authenticated;
GRANT INSERT ON user_achievements TO authenticated;
GRANT INSERT, UPDATE ON achievement_progress TO authenticated;
GRANT EXECUTE ON FUNCTION add_achievement_points TO authenticated;
GRANT EXECUTE ON FUNCTION get_user_achievement_stats TO authenticated;
