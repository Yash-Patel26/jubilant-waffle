# Database Schema and Migrations

This directory contains the database schema and migration files for the GamerFlick application.

## Quick Setup

1. **Core Schema**: Run `schema.sql` first to create all tables
2. **Populate Games**: Run `migration_populate_games.sql` to add games for tournament creation
3. **Demo Data**: Run `migration_add_demo_games.sql` for additional demo data

## Important Tables

### Games Table
The `games` table is essential for tournament creation. If the tournament creation form shows "Please select a game" error, it means the games table is empty.

**To fix this issue:**
1. Run the `migration_populate_games.sql` file in your Supabase SQL Editor
2. This will add popular games like BGMI, PUBG Mobile, Valorant, etc.

**Manual fix:**
```sql
-- Check if games table has data
SELECT COUNT(*) FROM games WHERE is_active = true;

-- If count is 0, run the migration file or manually insert games
INSERT INTO games (id, name, description, genre, platform, is_active) VALUES
('bgmi-game', 'BGMI (Battlegrounds Mobile India)', 'Popular battle royale game in India', 'Battle Royale', ARRAY['Mobile'], true);
```

## Migration Files

- `schema.sql` - Complete database schema
- `migration_populate_games.sql` - Adds popular games for tournaments
- `migration_add_demo_games.sql` - Adds demo games and leaderboards
- `migration_fix_tournament_rls.sql` - Fixes tournament creation RLS policies
- `migration_fix_tournament_foreign_keys.sql` - Fixes tournament bracket foreign key issues (drops table)
- `migration_fix_tournament_foreign_keys_safe.sql` - Fixes tournament bracket foreign key issues (preserves data)
- `complete_schema.sql` - Alternative complete schema
- `tournaments_schema.sql` - Tournament-specific tables
- `communities_schema.sql` - Community-specific tables
- `messaging_schema.sql` - Messaging system tables
- `social_schema.sql` - Social features tables
- `notifications_events_schema.sql` - Notifications and events
- `storage_policies.sql` - Storage bucket policies

## Troubleshooting

### Tournament Creation Issues

#### RLS Policy Error
**Error**: `PostgrestException(message: new row violates row-level security policy for table "tournaments", code: 42501)`

**Solution**: Run the `migration_fix_tournament_rls.sql` file in your Supabase SQL Editor. This migration:
1. Creates a trigger to automatically set the `created_by` field to the current user's ID
2. Fixes RLS policies to allow authenticated users to create tournaments
3. Ensures proper policies for viewing, updating, and deleting tournaments
4. Sets up profiles table RLS policies

**Manual fix if migration doesn't work:**
```sql
-- Drop and recreate the problematic policy
DROP POLICY IF EXISTS "Authenticated users can create tournaments" ON tournaments;

-- Create a more permissive policy for testing
CREATE POLICY "Allow tournament creation" ON tournaments 
FOR INSERT WITH CHECK (true);

-- Or create a proper policy with trigger
CREATE OR REPLACE FUNCTION set_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_tournament_created_by
    BEFORE INSERT ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION set_created_by();
```

#### Tournament Bracket Foreign Key Error
**Error**: `PostgrestException(message: Could not find a relationship between 'tournament_matches' and 'tournament_participants' in the schema cache, code: PGRST200, details: Searched for a foreign key relationship between 'tournament_matches' and 'tournament_participants' using the hint 'tournament_matches_winner_id_fkey' in the schema 'public', but no matches were found., hint: null)`

**Solution**: Run the `migration_fix_tournament_foreign_keys_safe.sql` file in your Supabase SQL Editor. This migration:
1. Fixes the `winner_id` field in `tournament_matches` table by replacing it with proper foreign key columns
2. Preserves existing data by migrating it to the new structure
3. Creates proper RLS policies for tournament-related tables
4. Creates a view for easier bracket queries

**Alternative (if you don't have important data)**: Run `migration_fix_tournament_foreign_keys.sql` which drops and recreates the table.

**Manual fix:**
```sql
-- Add proper foreign key columns
ALTER TABLE tournament_matches 
ADD COLUMN winner_participant_id uuid REFERENCES tournament_participants(id) ON DELETE SET NULL,
ADD COLUMN winner_team_id uuid REFERENCES tournament_teams(id) ON DELETE SET NULL,
ADD COLUMN winner_type text CHECK (winner_type IN ('participant', 'team', NULL));

-- Drop the problematic winner_id column
ALTER TABLE tournament_matches DROP COLUMN IF EXISTS winner_id;
```

#### Authentication Issues
If you're still getting RLS errors, check:
1. **User is authenticated**: Ensure `auth.uid()` returns a valid user ID
2. **Profile exists**: The user must have a record in the `profiles` table
3. **RLS is enabled**: Verify RLS is enabled on the tournaments table

```sql
-- Check if user has a profile
SELECT * FROM profiles WHERE id = auth.uid();

-- Check RLS status
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'tournaments';

-- Check existing policies
SELECT * FROM pg_policies WHERE tablename = 'tournaments';
```

#### "Please select a game" error
- **Cause**: The tournament creation screen now uses hardcoded games (same as game selection screen)
- **Solution**: Games are now hardcoded and don't require database connection

### Common Issues
- Make sure all tables exist before running migrations
- Check that RLS (Row Level Security) policies are properly configured
- Verify that the `is_active` column is set to `true` for games you want to display
- Ensure the user has a profile record in the `profiles` table
- Check that authentication is working properly (`auth.uid()` returns a valid ID) 