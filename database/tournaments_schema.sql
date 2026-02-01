-- =====================================================
-- GAMERFLICK TOURNAMENTS SCHEMA
-- =====================================================

-- TOURNAMENTS TABLE
CREATE TABLE tournaments (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text NOT NULL,
    type text NOT NULL CHECK (type IN ('solo', 'team')),
    game text NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone,
    status text DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'ongoing', 'completed', 'cancelled')),
    max_participants integer NOT NULL,
    current_participants integer DEFAULT 0,
    prize_pool text,
    rules text,
    media_url text,
    created_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT SETTINGS TABLE
CREATE TABLE tournament_settings (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    max_teams integer,
    max_participants_per_team integer,
    allow_spectators boolean DEFAULT true,
    registration_deadline timestamp with time zone,
    check_in_required boolean DEFAULT false,
    check_in_duration integer DEFAULT 15, -- minutes
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT PARTICIPANTS TABLE
CREATE TABLE tournament_participants (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    team_id uuid, -- Will reference tournament_teams(id) when created
    status text DEFAULT 'registered' CHECK (status IN ('registered', 'confirmed', 'eliminated', 'winner')),
    joined_at timestamp with time zone DEFAULT now(),
    checked_in boolean DEFAULT false,
    checked_in_at timestamp with time zone,
    UNIQUE(tournament_id, user_id)
);

-- TOURNAMENT ROLES TABLE
CREATE TABLE tournament_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text NOT NULL CHECK (role IN ('owner', 'admin', 'moderator', 'participant')),
    permissions jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now(),
    UNIQUE(tournament_id, user_id)
);

-- TOURNAMENT TEAMS TABLE
CREATE TABLE tournament_teams (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    name text NOT NULL,
    description text,
    logo_url text,
    captain_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
    member_count integer DEFAULT 0,
    max_members integer DEFAULT 5,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT TEAM MEMBERS TABLE
CREATE TABLE tournament_team_members (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    team_id uuid REFERENCES tournament_teams(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    role text DEFAULT 'member' CHECK (role IN ('captain', 'member')),
    joined_at timestamp with time zone DEFAULT now(),
    UNIQUE(team_id, user_id)
);

-- TOURNAMENT MATCHES TABLE
CREATE TABLE tournament_matches (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    round_number integer NOT NULL,
    match_number integer NOT NULL,
    participant_a_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    participant_b_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
    team_a_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    team_b_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
    winner_id uuid, -- Can reference either participant or team
    status text DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled')),
    scheduled_time timestamp with time zone,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    score_a integer DEFAULT 0,
    score_b integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT MEDIA TABLE
CREATE TABLE tournament_media (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    media_url text NOT NULL,
    media_type text CHECK (media_type IN ('image', 'video', 'highlight')),
    caption text,
    approved boolean DEFAULT false,
    approved_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
    approved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT MESSAGES TABLE
CREATE TABLE tournament_messages (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    user_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
    message text NOT NULL,
    message_type text DEFAULT 'general' CHECK (message_type IN ('general', 'announcement', 'system')),
    created_at timestamp with time zone DEFAULT now()
);

-- TOURNAMENT BRACKETS TABLE
CREATE TABLE tournament_brackets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    tournament_id uuid REFERENCES tournaments(id) ON DELETE CASCADE,
    bracket_type text DEFAULT 'single_elimination' CHECK (bracket_type IN ('single_elimination', 'double_elimination', 'round_robin', 'swiss')),
    bracket_data jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT now()
);

-- Indexes for tournaments
CREATE INDEX idx_tournaments_game ON tournaments(game);
CREATE INDEX idx_tournaments_status ON tournaments(status);
CREATE INDEX idx_tournaments_start_date ON tournaments(start_date);
CREATE INDEX idx_tournaments_created_by ON tournaments(created_by);
CREATE INDEX idx_tournaments_type ON tournaments(type);

CREATE INDEX idx_tournament_participants_tournament_id ON tournament_participants(tournament_id);
CREATE INDEX idx_tournament_participants_user_id ON tournament_participants(user_id);
CREATE INDEX idx_tournament_participants_status ON tournament_participants(status);

CREATE INDEX idx_tournament_roles_tournament_id ON tournament_roles(tournament_id);
CREATE INDEX idx_tournament_roles_user_id ON tournament_roles(user_id);
CREATE INDEX idx_tournament_roles_role ON tournament_roles(role);

CREATE INDEX idx_tournament_teams_tournament_id ON tournament_teams(tournament_id);
CREATE INDEX idx_tournament_teams_captain_id ON tournament_teams(captain_id);

CREATE INDEX idx_tournament_matches_tournament_id ON tournament_matches(tournament_id);
CREATE INDEX idx_tournament_matches_status ON tournament_matches(status);
CREATE INDEX idx_tournament_matches_scheduled_time ON tournament_matches(scheduled_time);

CREATE INDEX idx_tournament_media_tournament_id ON tournament_media(tournament_id);
CREATE INDEX idx_tournament_media_approved ON tournament_media(approved); 