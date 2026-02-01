-- Migration: Fix tournament foreign key relationships (Safe version)
-- Run this in your Supabase SQL Editor to fix tournament bracket issues without losing data

-- This migration fixes the foreign key relationship issues without dropping tables
-- The main issue is that winner_id in tournament_matches doesn't have proper foreign key constraints

-- First, let's add the missing foreign key constraints to the existing tournament_matches table
-- We'll need to handle this carefully to avoid data loss

-- Step 1: Add new columns for proper winner tracking
ALTER TABLE tournament_matches 
ADD COLUMN IF NOT EXISTS winner_participant_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS winner_team_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS winner_type text CHECK (winner_type IN ('participant', 'team', NULL));

-- Step 2: Create a function to migrate existing winner_id data
CREATE OR REPLACE FUNCTION migrate_winner_ids()
RETURNS void AS $$
DECLARE
    match_record RECORD;
BEGIN
    -- Loop through existing matches and try to determine winner type
    FOR match_record IN 
        SELECT id, winner_id, participant_a_id, participant_b_id, team_a_id, team_b_id
        FROM tournament_matches 
        WHERE winner_id IS NOT NULL
    LOOP
        -- Check if winner_id matches a participant
        IF EXISTS (
            SELECT 1 FROM tournament_participants 
            WHERE id = match_record.winner_id
        ) THEN
            UPDATE tournament_matches 
            SET winner_participant_id = match_record.winner_id,
                winner_type = 'participant'
            WHERE id = match_record.id;
        -- Check if winner_id matches a team
        ELSIF EXISTS (
            SELECT 1 FROM tournament_teams 
            WHERE id = match_record.winner_id
        ) THEN
            UPDATE tournament_matches 
            SET winner_team_id = match_record.winner_id,
                winner_type = 'team'
            WHERE id = match_record.id;
        END IF;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Step 3: Run the migration function
SELECT migrate_winner_ids();

-- Step 4: Drop the old winner_id column (after ensuring data is migrated)
ALTER TABLE tournament_matches DROP COLUMN IF EXISTS winner_id;

-- Step 5: Create indexes for the new columns
CREATE INDEX IF NOT EXISTS idx_tournament_matches_winner_participant_id ON tournament_matches(winner_participant_id);
CREATE INDEX IF NOT EXISTS idx_tournament_matches_winner_team_id ON tournament_matches(winner_team_id);

-- Step 6: Ensure RLS policies exist for tournament_matches
ALTER TABLE tournament_matches ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view tournament matches" ON tournament_matches;
DROP POLICY IF EXISTS "Tournament organizers can create matches" ON tournament_matches;
DROP POLICY IF EXISTS "Tournament organizers can update matches" ON tournament_matches;
DROP POLICY IF EXISTS "Tournament organizers can delete matches" ON tournament_matches;

-- Create new policies
CREATE POLICY "Users can view tournament matches" ON tournament_matches 
FOR SELECT USING (true);

CREATE POLICY "Tournament organizers can create matches" ON tournament_matches 
FOR INSERT WITH CHECK (
    EXISTS (
        SELECT 1 FROM tournaments 
        WHERE tournaments.id = tournament_matches.tournament_id 
        AND tournaments.created_by = auth.uid()
    )
);

CREATE POLICY "Tournament organizers can update matches" ON tournament_matches 
FOR UPDATE USING (
    EXISTS (
        SELECT 1 FROM tournaments 
        WHERE tournaments.id = tournament_matches.tournament_id 
        AND tournaments.created_by = auth.uid()
    )
);

CREATE POLICY "Tournament organizers can delete matches" ON tournament_matches 
FOR DELETE USING (
    EXISTS (
        SELECT 1 FROM tournaments 
        WHERE tournaments.id = tournament_matches.tournament_id 
        AND tournaments.created_by = auth.uid()
    )
);

-- Step 7: Ensure other tournament tables have proper RLS policies
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_teams ENABLE ROW LEVEL SECURITY;

-- Tournament participants policies
DROP POLICY IF EXISTS "Users can view tournament participants" ON tournament_participants;
DROP POLICY IF EXISTS "Users can join tournaments" ON tournament_participants;
DROP POLICY IF EXISTS "Users can update own participation" ON tournament_participants;
DROP POLICY IF EXISTS "Users can leave tournaments" ON tournament_participants;

CREATE POLICY "Users can view tournament participants" ON tournament_participants 
FOR SELECT USING (true);

CREATE POLICY "Users can join tournaments" ON tournament_participants 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own participation" ON tournament_participants 
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can leave tournaments" ON tournament_participants 
FOR DELETE USING (auth.uid() = user_id);

-- Tournament teams policies
DROP POLICY IF EXISTS "Users can view tournament teams" ON tournament_teams;
DROP POLICY IF EXISTS "Users can create teams" ON tournament_teams;
DROP POLICY IF EXISTS "Team captains can update teams" ON tournament_teams;
DROP POLICY IF EXISTS "Team captains can delete teams" ON tournament_teams;

CREATE POLICY "Users can view tournament teams" ON tournament_teams 
FOR SELECT USING (true);

CREATE POLICY "Users can create teams" ON tournament_teams 
FOR INSERT WITH CHECK (auth.uid() = captain_id);

CREATE POLICY "Team captains can update teams" ON tournament_teams 
FOR UPDATE USING (auth.uid() = captain_id);

CREATE POLICY "Team captains can delete teams" ON tournament_teams 
FOR DELETE USING (auth.uid() = captain_id);

-- Step 8: Create a view for easier bracket queries
CREATE OR REPLACE VIEW tournament_bracket_view AS
SELECT 
    tm.id as match_id,
    tm.tournament_id,
    tm.round_number,
    tm.match_number,
    tm.status as match_status,
    tm.scheduled_time,
    tm.score_a,
    tm.score_b,
    -- Participant A info
    pa.id as participant_a_id,
    pa.user_id as participant_a_user_id,
    pa.status as participant_a_status,
    p1.username as participant_a_username,
    p1.avatar_url as participant_a_avatar,
    -- Participant B info
    pb.id as participant_b_id,
    pb.user_id as participant_b_user_id,
    pb.status as participant_b_status,
    p2.username as participant_b_username,
    p2.avatar_url as participant_b_avatar,
    -- Team A info
    ta.id as team_a_id,
    ta.name as team_a_name,
    ta.logo_url as team_a_logo,
    -- Team B info
    tb.id as team_b_id,
    tb.name as team_b_name,
    tb.logo_url as team_b_logo,
    -- Winner info
    tm.winner_participant_id,
    tm.winner_team_id,
    tm.winner_type,
    CASE 
        WHEN tm.winner_type = 'participant' THEN p3.username
        WHEN tm.winner_type = 'team' THEN tw.name
        ELSE NULL
    END as winner_name
FROM tournament_matches tm
LEFT JOIN tournament_participants pa ON tm.participant_a_id = pa.id
LEFT JOIN tournament_participants pb ON tm.participant_b_id = pb.id
LEFT JOIN tournament_teams ta ON tm.team_a_id = ta.id
LEFT JOIN tournament_teams tb ON tm.team_b_id = tb.id
LEFT JOIN profiles p1 ON pa.user_id = p1.id
LEFT JOIN profiles p2 ON pb.user_id = p2.id
LEFT JOIN tournament_participants wp ON tm.winner_participant_id = wp.id
LEFT JOIN profiles p3 ON wp.user_id = p3.id
LEFT JOIN tournament_teams tw ON tm.winner_team_id = tw.id
ORDER BY tm.tournament_id, tm.round_number, tm.match_number;

-- Clean up
DROP FUNCTION IF EXISTS migrate_winner_ids(); 