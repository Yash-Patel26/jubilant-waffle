-- Run this script in your Supabase SQL Editor to fix the shared_posts schema issue

-- First, let's check if the tables exist and their current structure
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('shared_posts', 'shared_post_recipients')
ORDER BY table_name, ordinal_position;

-- Now run the migration
\i fix_shared_posts_schema.sql

-- Verify the changes
SELECT table_name, column_name, data_type 
FROM information_schema.columns 
WHERE table_name IN ('shared_posts', 'shared_post_recipients')
ORDER BY table_name, ordinal_position;
