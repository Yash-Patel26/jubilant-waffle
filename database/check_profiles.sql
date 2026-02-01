-- =====================================================
-- CHECK PROFILES TABLE
-- =====================================================

-- This script helps you see what users are available in your profiles table

-- Count total profiles
SELECT 
    'Total Profiles' as info,
    COUNT(*) as count
FROM profiles;

-- Show users with usernames
SELECT 
    'Users with Usernames' as info,
    COUNT(*) as count
FROM profiles 
WHERE username IS NOT NULL AND username != '';

-- Show sample of available users
SELECT 
    id,
    username,
    display_name,
    email,
    created_at,
    CASE 
        WHEN avatar_url IS NOT NULL THEN 'Has Avatar'
        ELSE 'No Avatar'
    END as avatar_status
FROM profiles 
WHERE username IS NOT NULL 
AND username != ''
ORDER BY created_at DESC
LIMIT 10;

-- Show users that would be eligible for leaderboard
SELECT 
    'Eligible Users for Leaderboard' as info,
    COUNT(*) as count
FROM profiles 
WHERE username IS NOT NULL 
AND username != ''
AND username != 'admin'
AND username != 'test'; 