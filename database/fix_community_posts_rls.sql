-- FIX COMMUNITY POSTS RLS POLICIES
-- This script adds the missing RLS policies for community_posts and related tables

-- Enable RLS on community_posts table
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for community_posts
CREATE POLICY "Community members can view posts" ON community_posts FOR SELECT USING (
    EXISTS (SELECT 1 FROM community_members WHERE community_members.community_id = community_posts.community_id AND community_members.user_id = auth.uid())
);

CREATE POLICY "Community members can create posts" ON community_posts FOR INSERT WITH CHECK (
    auth.uid() = author_id AND
    EXISTS (SELECT 1 FROM community_members WHERE community_members.community_id = community_posts.community_id AND community_members.user_id = auth.uid())
);

CREATE POLICY "Users can update own posts" ON community_posts FOR UPDATE USING (auth.uid() = author_id);

CREATE POLICY "Users can delete own posts" ON community_posts FOR DELETE USING (auth.uid() = author_id);

-- Enable RLS on community_post_likes table
ALTER TABLE community_post_likes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for community_post_likes
CREATE POLICY "Community members can view likes" ON community_post_likes FOR SELECT USING (
    EXISTS (SELECT 1 FROM community_members cm 
            JOIN community_posts cp ON cm.community_id = cp.community_id 
            WHERE cp.id = community_post_likes.post_id AND cm.user_id = auth.uid())
);

CREATE POLICY "Users can like posts" ON community_post_likes FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike posts" ON community_post_likes FOR DELETE USING (auth.uid() = user_id);

-- Enable RLS on community_post_comments table
ALTER TABLE community_post_comments ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for community_post_comments
CREATE POLICY "Community members can view comments" ON community_post_comments FOR SELECT USING (
    EXISTS (SELECT 1 FROM community_members cm 
            JOIN community_posts cp ON cm.community_id = cp.community_id 
            WHERE cp.id = community_post_comments.post_id AND cm.user_id = auth.uid())
);

CREATE POLICY "Community members can create comments" ON community_post_comments FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    EXISTS (SELECT 1 FROM community_members cm 
            JOIN community_posts cp ON cm.community_id = cp.community_id 
            WHERE cp.id = community_post_comments.post_id AND cm.user_id = auth.uid())
);

CREATE POLICY "Users can update own comments" ON community_post_comments FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own comments" ON community_post_comments FOR DELETE USING (auth.uid() = user_id);

-- Enable RLS on community_members table if not already enabled
ALTER TABLE community_members ENABLE ROW LEVEL SECURITY;

-- Create simplified RLS policies for community_members to avoid infinite recursion
CREATE POLICY "Users can view community members" ON community_members FOR SELECT USING (
    EXISTS (SELECT 1 FROM communities WHERE communities.id = community_members.community_id AND communities.is_public = true)
    OR
    auth.uid() = community_members.user_id
);

CREATE POLICY "Users can join communities" ON community_members FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can leave communities" ON community_members FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Community admins can update members" ON community_members FOR UPDATE USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM community_members cm WHERE cm.community_id = community_members.community_id AND cm.user_id = auth.uid() AND cm.role IN ('admin', 'owner'))
);

-- Verify the policies were created
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('community_posts', 'community_post_likes', 'community_post_comments', 'community_members')
ORDER BY tablename, policyname; 