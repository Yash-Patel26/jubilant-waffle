-- Migration: Add tournament_roles table
-- This migration adds the missing tournament_roles table that is referenced in the code

-- TOURNAMENT ROLES TABLE
CREATE TABLE IF NOT EXISTS tournament_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('owner', 'admin', 'moderator', 'participant')),
    permissions jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(tournament_id, user_id)
);

-- Indexes for tournament_roles
CREATE INDEX IF NOT EXISTS idx_tournament_roles_tournament_id ON tournament_roles(tournament_id);
CREATE INDEX IF NOT EXISTS idx_tournament_roles_user_id ON tournament_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_tournament_roles_role ON tournament_roles(role); 