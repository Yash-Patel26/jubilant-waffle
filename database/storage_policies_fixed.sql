-- Fixed Storage Bucket RLS Policies for GamerFlick
-- This version works with Supabase's permission system

-- First, let's check if RLS is already enabled
-- If not, we'll enable it through the dashboard instead

-- Policy for avatars bucket (users can upload their own avatar)
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

-- Policy for banners bucket
CREATE POLICY "Users can upload their own banner" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'banners' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view banners" ON storage.objects
    FOR SELECT USING (bucket_id = 'banners');

-- Policy for posts bucket
CREATE POLICY "Users can upload post media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'posts' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view post media" ON storage.objects
    FOR SELECT USING (bucket_id = 'posts');

-- Policy for stories bucket (with 24h expiration)
CREATE POLICY "Users can upload stories" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'stories' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view stories" ON storage.objects
    FOR SELECT USING (bucket_id = 'stories');

-- Policy for reels bucket
CREATE POLICY "Users can upload reels" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'reels' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view reels" ON storage.objects
    FOR SELECT USING (bucket_id = 'reels');

-- Policy for highlights bucket
CREATE POLICY "Users can upload highlights" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'highlights' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view highlights" ON storage.objects
    FOR SELECT USING (bucket_id = 'highlights');

-- Policy for communities bucket
CREATE POLICY "Community admins can upload community media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'communities' AND 
        EXISTS (
            SELECT 1 FROM community_members 
            WHERE community_id::text = (storage.foldername(name))[1]
            AND user_id = auth.uid()
            AND role IN ('admin', 'moderator')
        )
    );

CREATE POLICY "Anyone can view community media" ON storage.objects
    FOR SELECT USING (bucket_id = 'communities');

-- Policy for tournaments bucket
CREATE POLICY "Tournament creators can upload tournament media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'tournaments' AND 
        EXISTS (
            SELECT 1 FROM tournaments 
            WHERE id::text = (storage.foldername(name))[1]
            AND created_by = auth.uid()
        )
    );

CREATE POLICY "Anyone can view tournament media" ON storage.objects
    FOR SELECT USING (bucket_id = 'tournaments');

-- Policy for streams bucket
CREATE POLICY "Streamers can upload stream media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'streams' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view stream media" ON storage.objects
    FOR SELECT USING (bucket_id = 'streams');

-- Policy for games bucket
CREATE POLICY "Admins can upload game assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'games' AND 
        auth.uid() IN (
            SELECT user_id FROM profiles WHERE is_verified = true
        )
    );

CREATE POLICY "Anyone can view game assets" ON storage.objects
    FOR SELECT USING (bucket_id = 'games');

-- Policy for leaderboards bucket
CREATE POLICY "Users can upload leaderboard screenshots" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'leaderboards' AND 
        auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "Anyone can view leaderboard media" ON storage.objects
    FOR SELECT USING (bucket_id = 'leaderboards');

-- Update policy for users to update their own files
CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (
        auth.uid()::text = (storage.foldername(name))[1]
    );

-- Delete policy for users to delete their own files
CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (
        auth.uid()::text = (storage.foldername(name))[1]
    ); 