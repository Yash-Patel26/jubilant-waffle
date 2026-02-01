-- Migration: Fix tournament foreign key relationships
-- Run this in your Supabase SQL Editor to fix tournament bracket issues

-- First, let's check the current state of the tournament_matches table
-- The issue is that winner_id doesn't have proper foreign key constraints

-- Drop the existing tournament_matches table if it exists
DROP TABLE IF EXISTS tournament_matches CASCADE;

-- Recreate the tournament_matches table with proper foreign key constraints
CREATE TABLE tournament_matches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number integer NOT NULL,
    match_number integer NOT NULL,
    participant_a_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    participant_b_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    team_a_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    team_b_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    winner_participant_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    winner_team_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    winner_type text CHECK (winner_type IN ('participant', 'team', NULL)),
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    scheduled_time timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    score_a integer DEFAULT 0,
    score_b integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

-- Create indexes for the new table
CREATE INDEX idx_tournament_matches_tournament_id ON tournament_matches(tournament_id);
CREATE INDEX idx_tournament_matches_status ON tournament_matches(status);
CREATE INDEX idx_tournament_matches_scheduled_time ON tournament_matches(scheduled_time);
CREATE INDEX idx_tournament_matches_winner_participant_id ON tournament_matches(winner_participant_id);
CREATE INDEX idx_tournament_matches_winner_team_id ON tournament_matches(winner_team_id);

-- Add RLS policies for tournament_matches
ALTER TABLE tournament_matches ENABLE ROW LEVEL SECURITY;

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

-- Also ensure tournament_participants and tournament_teams have proper RLS policies
ALTER TABLE tournament_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE tournament_teams ENABLE ROW LEVEL SECURITY;

-- Tournament participants policies
CREATE POLICY "Users can view tournament participants" ON tournament_participants 
FOR SELECT USING (true);

CREATE POLICY "Users can join tournaments" ON tournament_participants 
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own participation" ON tournament_participants 
FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can leave tournaments" ON tournament_participants 
FOR DELETE USING (auth.uid() = user_id);

-- Tournament teams policies
CREATE POLICY "Users can view tournament teams" ON tournament_teams 
FOR SELECT USING (true);

CREATE POLICY "Users can create teams" ON tournament_teams 
FOR INSERT WITH CHECK (auth.uid() = captain_id);

CREATE POLICY "Team captains can update teams" ON tournament_teams 
FOR UPDATE USING (auth.uid() = captain_id);

CREATE POLICY "Team captains can delete teams" ON tournament_teams 
FOR DELETE USING (auth.uid() = captain_id);

-- Create a view for easier bracket queries
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