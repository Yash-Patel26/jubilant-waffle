-- Migration: Fix tournament RLS policies
-- Run this in your Supabase SQL Editor to fix tournament creation issues

-- Drop existing policies
DROP POLICY IF EXISTS "Users can create tournaments" ON tournaments;
DROP POLICY IF EXISTS "Authenticated users can create tournaments" ON tournaments;
DROP POLICY IF EXISTS "Tournament creators can update tournaments" ON tournaments;
DROP POLICY IF EXISTS "Tournament creators can delete tournaments" ON tournaments;

-- Create a trigger function to automatically set created_by
CREATE OR REPLACE FUNCTION set_created_by()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by = auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to automatically set created_by on insert
DROP TRIGGER IF EXISTS set_tournament_created_by ON tournaments;
CREATE TRIGGER set_tournament_created_by
    BEFORE INSERT ON tournaments
    FOR EACH ROW
    EXECUTE FUNCTION set_created_by();

-- Create new, more flexible policies
CREATE POLICY "Authenticated users can create tournaments" ON tournaments 
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can view tournaments" ON tournaments 
FOR SELECT USING (true);

CREATE POLICY "Tournament creators can update tournaments" ON tournaments 
FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Tournament creators can delete tournaments" ON tournaments 
FOR DELETE USING (auth.uid() = created_by);

-- Verify RLS is enabled
ALTER TABLE tournaments ENABLE ROW LEVEL SECURITY;

-- Ensure profiles table has RLS policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Create profiles policies if they don't exist
DROP POLICY IF EXISTS "Users can view public profiles" ON profiles;
DROP POLICY IF EXISTS "Users can view own profile" ON profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON profiles;

CREATE POLICY "Users can view public profiles" ON profiles 
FOR SELECT USING (is_public = true);

CREATE POLICY "Users can view own profile" ON profiles 
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON profiles 
FOR UPDATE USING (auth.uid() = id);

-- Test the policy (optional - you can run this to verify)
-- SELECT * FROM tournaments LIMIT 1; 