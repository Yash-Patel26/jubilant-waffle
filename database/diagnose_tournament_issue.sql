-- Diagnostic script for tournament RLS policy issues
-- Run this in your Supabase SQL Editor to identify the problem

-- 1. Check if user is authenticated
SELECT 
    'Authentication Check' as check_type,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN 'PASS: User is authenticated'
        ELSE 'FAIL: User is not authenticated'
    END as result,
    auth.uid() as user_id;

-- 2. Check if user has a profile
SELECT 
    'Profile Check' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid()) THEN 'PASS: User has profile'
        ELSE 'FAIL: User does not have profile'
    END as result,
    (SELECT username FROM profiles WHERE id = auth.uid()) as username;

-- 3. Check RLS status on tournaments table
SELECT 
    'RLS Status' as check_type,
    CASE 
        WHEN rowsecurity THEN 'PASS: RLS is enabled'
        ELSE 'FAIL: RLS is disabled'
    END as result
FROM pg_tables 
WHERE tablename = 'tournaments';

-- 4. Check existing policies on tournaments table
SELECT 
    'Policy Check' as check_type,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'tournaments'
ORDER BY policyname;

-- 5. Check if trigger exists for setting created_by
SELECT 
    'Trigger Check' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_trigger 
            WHERE tgname = 'set_tournament_created_by' 
            AND tgrelid = 'tournaments'::regclass
        ) THEN 'PASS: Trigger exists'
        ELSE 'FAIL: Trigger does not exist'
    END as result;

-- 6. Test tournament creation (this will show the actual error)
-- Uncomment the following lines to test actual tournament creation
/*
INSERT INTO tournaments (
    name, 
    description, 
    type, 
    game, 
    start_date, 
    max_participants
) VALUES (
    'Test Tournament',
    'Test Description',
    'solo',
    'BGMI',
    NOW() + INTERVAL '1 day',
    10
) RETURNING id, name, created_by;
*/ 