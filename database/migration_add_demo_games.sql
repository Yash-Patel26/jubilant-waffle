-- Migration: Add demo games and leaderboards
-- Run this in your Supabase SQL Editor

-- Insert demo games
INSERT INTO games (id, name, description, genre, platform, is_active) VALUES
('demo-game-1', 'Demo Game 1', 'A demo game for testing leaderboards', 'Action', ARRAY['PC', 'Mobile'], true),
('demo-game-2', 'Demo Game 2', 'Another demo game for testing', 'Strategy', ARRAY['PC'], true),
('demo-game-3', 'Demo Game 3', 'Third demo game', 'RPG', ARRAY['PC', 'Console'], true)
ON CONFLICT (name) DO NOTHING;

-- Insert demo leaderboards for each game
INSERT INTO leaderboards (id, game_id, name, description, metric, time_period, is_active) VALUES
('demo-leaderboard-1', 'demo-game-1', 'Demo Leaderboard 1', 'Default leaderboard for Demo Game 1', 'score', 'all_time', true),
('demo-leaderboard-2', 'demo-game-2', 'Demo Leaderboard 2', 'Default leaderboard for Demo Game 2', 'score', 'all_time', true),
('demo-leaderboard-3', 'demo-game-3', 'Demo Leaderboard 3', 'Default leaderboard for Demo Game 3', 'score', 'all_time', true)
ON CONFLICT DO NOTHING;

-- Insert some demo leaderboard entries
INSERT INTO leaderboard_entries (leaderboard_id, user_id, score, rank) VALUES
('demo-leaderboard-1', 'fd2523e5-4589-40da-ae4c-59521e210ef5', 1000, 1),
('demo-leaderboard-1', 'fd2523e5-4589-40da-ae4c-59521e210ef5', 950, 2),
('demo-leaderboard-2', 'fd2523e5-4589-40da-ae4c-59521e210ef5', 800, 1),
('demo-leaderboard-3', 'fd2523e5-4589-40da-ae4c-59521e210ef5', 1200, 1)
ON CONFLICT DO NOTHING; 