-- Migration: Populate games table with popular games
-- Run this in your Supabase SQL Editor to add games for tournament creation

-- Insert popular games for tournaments
INSERT INTO games (id, name, description, genre, platform, is_active) VALUES
-- Mobile Games
('bgmi-game', 'BGMI (Battlegrounds Mobile India)', 'Popular battle royale game in India', 'Battle Royale', ARRAY['Mobile'], true),
('pubg-mobile', 'PUBG Mobile', 'PlayerUnknown''s Battlegrounds Mobile', 'Battle Royale', ARRAY['Mobile'], true),
('free-fire', 'Free Fire', 'Garena Free Fire - Battle Royale', 'Battle Royale', ARRAY['Mobile'], true),
('cod-mobile', 'Call of Duty Mobile', 'Call of Duty: Mobile', 'FPS', ARRAY['Mobile'], true),
('clash-royale', 'Clash Royale', 'Real-time strategy game', 'Strategy', ARRAY['Mobile'], true),
('clash-clans', 'Clash of Clans', 'Strategy game with base building', 'Strategy', ARRAY['Mobile'], true),

-- PC Games
('valorant', 'Valorant', 'Tactical shooter by Riot Games', 'FPS', ARRAY['PC'], true),
('csgo', 'CS:GO', 'Counter-Strike: Global Offensive', 'FPS', ARRAY['PC'], true),
('fortnite', 'Fortnite', 'Epic Games battle royale', 'Battle Royale', ARRAY['PC', 'Console'], true),
('apex-legends', 'Apex Legends', 'Hero shooter battle royale', 'Battle Royale', ARRAY['PC', 'Console'], true),
('overwatch', 'Overwatch', 'Team-based hero shooter', 'FPS', ARRAY['PC', 'Console'], true),
('league-legends', 'League of Legends', 'MOBA by Riot Games', 'MOBA', ARRAY['PC'], true),
('dota2', 'Dota 2', 'Defense of the Ancients 2', 'MOBA', ARRAY['PC'], true),
('rocket-league', 'Rocket League', 'Soccer with rocket-powered cars', 'Sports', ARRAY['PC', 'Console'], true),
('minecraft', 'Minecraft', 'Sandbox building game', 'Sandbox', ARRAY['PC', 'Console', 'Mobile'], true),

-- Console Games
('fifa24', 'FIFA 24', 'Football simulation game', 'Sports', ARRAY['Console', 'PC'], true),
('nba2k24', 'NBA 2K24', 'Basketball simulation game', 'Sports', ARRAY['Console', 'PC'], true),
('madden24', 'Madden NFL 24', 'American football simulation', 'Sports', ARRAY['Console', 'PC'], true),

-- Cross-Platform
('among-us', 'Among Us', 'Social deduction game', 'Party', ARRAY['PC', 'Mobile'], true),
('fall-guys', 'Fall Guys', 'Battle royale party game', 'Party', ARRAY['PC', 'Console'], true),
('roblox', 'Roblox', 'Game creation platform', 'Platform', ARRAY['PC', 'Mobile'], true)
ON CONFLICT (name) DO NOTHING;

-- Update any existing games to be active
UPDATE games SET is_active = true WHERE is_active IS NULL OR is_active = false; 