-- Leaderboard Scores Table Migration
-- This table caches user scores for better performance

-- Create leaderboard_scores table
CREATE TABLE IF NOT EXISTS leaderboard_scores (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content_score INTEGER DEFAULT 0,
    community_score INTEGER DEFAULT 0,
    tournament_score INTEGER DEFAULT 0,
    total_score INTEGER DEFAULT 0,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_leaderboard_scores_user_id ON leaderboard_scores(user_id);
CREATE INDEX IF NOT EXISTS idx_leaderboard_scores_total_score ON leaderboard_scores(total_score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_scores_content_score ON leaderboard_scores(content_score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_scores_community_score ON leaderboard_scores(community_score DESC);
CREATE INDEX IF NOT EXISTS idx_leaderboard_scores_tournament_score ON leaderboard_scores(tournament_score DESC);

-- Create unique constraint on user_id to prevent duplicates
CREATE UNIQUE INDEX IF NOT EXISTS idx_leaderboard_scores_unique_user ON leaderboard_scores(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE leaderboard_scores ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Allow users to read all leaderboard scores (public data)
CREATE POLICY "Allow public read access to leaderboard scores" ON leaderboard_scores
    FOR SELECT USING (true);

-- Allow users to update their own scores
CREATE POLICY "Allow users to update their own scores" ON leaderboard_scores
    FOR UPDATE USING (auth.uid() = user_id);

-- Allow users to insert their own scores
CREATE POLICY "Allow users to insert their own scores" ON leaderboard_scores
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create a function to update leaderboard scores
CREATE OR REPLACE FUNCTION update_leaderboard_score(
    p_user_id UUID,
    p_content_score INTEGER DEFAULT NULL,
    p_community_score INTEGER DEFAULT NULL,
    p_tournament_score INTEGER DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO leaderboard_scores (user_id, content_score, community_score, tournament_score, total_score, last_updated)
    VALUES (
        p_user_id,
        COALESCE(p_content_score, 0),
        COALESCE(p_community_score, 0),
        COALESCE(p_tournament_score, 0),
        COALESCE(p_content_score, 0) + COALESCE(p_community_score, 0) + COALESCE(p_tournament_score, 0),
        NOW()
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
        content_score = COALESCE(p_content_score, leaderboard_scores.content_score),
        community_score = COALESCE(p_community_score, leaderboard_scores.community_score),
        tournament_score = COALESCE(p_tournament_score, leaderboard_scores.tournament_score),
        total_score = COALESCE(p_content_score, leaderboard_scores.content_score) + 
                     COALESCE(p_community_score, leaderboard_scores.community_score) + 
                     COALESCE(p_tournament_score, leaderboard_scores.tournament_score),
        last_updated = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create a function to get leaderboard rankings
CREATE OR REPLACE FUNCTION get_leaderboard_rankings(
    p_limit INTEGER DEFAULT 50,
    p_offset INTEGER DEFAULT 0,
    p_type TEXT DEFAULT 'overall'
)
RETURNS TABLE (
    rank BIGINT,
    user_id UUID,
    username TEXT,
    avatar_url TEXT,
    content_score INTEGER,
    community_score INTEGER,
    tournament_score INTEGER,
    total_score INTEGER,
    last_updated TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ROW_NUMBER() OVER (ORDER BY 
            CASE 
                WHEN p_type = 'content' THEN ls.content_score
                WHEN p_type = 'community' THEN ls.community_score
                WHEN p_type = 'tournament' THEN ls.tournament_score
                ELSE ls.total_score
            END DESC
        ) as rank,
        ls.user_id,
        p.username,
        p.avatar_url,
        ls.content_score,
        ls.community_score,
        ls.tournament_score,
        ls.total_score,
        ls.last_updated
    FROM leaderboard_scores ls
    JOIN profiles p ON ls.user_id = p.id
    ORDER BY 
        CASE 
            WHEN p_type = 'content' THEN ls.content_score
            WHEN p_type = 'community' THEN ls.community_score
            WHEN p_type = 'tournament' THEN ls.tournament_score
            ELSE ls.total_score
        END DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant necessary permissions
GRANT SELECT ON leaderboard_scores TO authenticated;
GRANT INSERT, UPDATE ON leaderboard_scores TO authenticated;

-- Create a trigger to automatically update scores when posts/reels are modified
-- This is optional and can be implemented based on your specific needs

-- Example trigger for posts (you can adapt this for your specific tables)
-- CREATE OR REPLACE FUNCTION trigger_update_leaderboard_on_post()
-- RETURNS TRIGGER AS $$
-- BEGIN
--     -- Update the user's content score when a post is created/updated/deleted
--     PERFORM update_leaderboard_score(NEW.user_id);
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- CREATE TRIGGER update_leaderboard_post_trigger
--     AFTER INSERT OR UPDATE OR DELETE ON posts
--     FOR EACH ROW
--     EXECUTE FUNCTION trigger_update_leaderboard_on_post(); 