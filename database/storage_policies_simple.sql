-- Simplified Storage Bucket RLS Policies for GamerFlick
-- This version avoids referencing tables that might not exist yet

-- Policy for avatars bucket (users can upload their own avatar)
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'avatars' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

-- Policy for banners bucket
CREATE POLICY "Users can upload their own banner" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'banners' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view banners" ON storage.objects
    FOR SELECT USING (bucket_id = 'banners');

-- Policy for posts bucket
CREATE POLICY "Users can upload post media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'posts' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view post media" ON storage.objects
    FOR SELECT USING (bucket_id = 'posts');

-- Policy for stories bucket (with 24h expiration)
CREATE POLICY "Users can upload stories" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'stories' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view stories" ON storage.objects
    FOR SELECT USING (bucket_id = 'stories');

-- Policy for reels bucket
CREATE POLICY "Users can upload reels" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'reels' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view reels" ON storage.objects
    FOR SELECT USING (bucket_id = 'reels');

-- Policy for highlights bucket
CREATE POLICY "Users can upload highlights" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'highlights' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view highlights" ON storage.objects
    FOR SELECT USING (bucket_id = 'highlights');

-- Policy for communities bucket (simplified - anyone authenticated can upload)
CREATE POLICY "Authenticated users can upload community media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'communities' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "Anyone can view community media" ON storage.objects
    FOR SELECT USING (bucket_id = 'communities');

-- Policy for tournaments bucket (simplified - anyone authenticated can upload)
CREATE POLICY "Authenticated users can upload tournament media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'tournaments' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "Anyone can view tournament media" ON storage.objects
    FOR SELECT USING (bucket_id = 'tournaments');

-- Policy for streams bucket
CREATE POLICY "Users can upload stream media" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'streams' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view stream media" ON storage.objects
    FOR SELECT USING (bucket_id = 'streams');

-- Policy for games bucket (simplified - anyone authenticated can upload)
CREATE POLICY "Authenticated users can upload game assets" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'games' AND 
        auth.role() = 'authenticated'
    );

CREATE POLICY "Anyone can view game assets" ON storage.objects
    FOR SELECT USING (bucket_id = 'games');

-- Policy for leaderboards bucket
CREATE POLICY "Users can upload leaderboard screenshots" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'leaderboards' AND 
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

CREATE POLICY "Anyone can view leaderboard media" ON storage.objects
    FOR SELECT USING (bucket_id = 'leaderboards');

-- Update policy for users to update their own files
CREATE POLICY "Users can update their own files" ON storage.objects
    FOR UPDATE USING (
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    );

-- Delete policy for users to delete their own files
CREATE POLICY "Users can delete their own files" ON storage.objects
    FOR DELETE USING (
        auth.uid()::text = SPLIT_PART(name, '/', 1)
    ); 