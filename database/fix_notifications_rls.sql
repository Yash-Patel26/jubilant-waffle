-- =====================================================
-- FIX NOTIFICATIONS RLS POLICIES
-- =====================================================

-- Enable RLS on notifications table if not already enabled
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate them properly
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;

-- Create comprehensive RLS policies for notifications table
CREATE POLICY "Users can view own notifications" ON notifications 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications 
    FOR UPDATE USING (auth.uid() = user_id);

-- Add the missing INSERT policy
CREATE POLICY "Users can insert own notifications" ON notifications 
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Add policy for system notifications (when user_id is null)
CREATE POLICY "System can insert notifications" ON notifications 
    FOR INSERT WITH CHECK (
        auth.uid() = user_id OR 
        (user_id IS NOT NULL AND auth.uid() = user_id)
    );

-- Add policy for deleting notifications
CREATE POLICY "Users can delete own notifications" ON notifications 
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- ADDITIONAL NOTIFICATION POLICIES FOR DIFFERENT SCENARIOS
-- =====================================================

-- Policy for creating notifications for other users (e.g., when someone likes your post)
CREATE POLICY "Users can create notifications for others" ON notifications 
    FOR INSERT WITH CHECK (
        -- Allow if the current user is creating a notification for themselves
        auth.uid() = user_id OR
        -- Allow if the current user is creating a notification for someone else
        -- (this would be used by the system when someone interacts with your content)
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = user_id 
            AND profiles.allow_notifications = true
        )
    );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'notifications';

-- Check existing policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies 
WHERE tablename = 'notifications';

-- =====================================================
-- ALTERNATIVE APPROACH: DISABLE RLS FOR NOTIFICATIONS
-- =====================================================

-- If the above policies are too restrictive, you can temporarily disable RLS
-- Uncomment the following line to disable RLS on notifications table:
-- ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- GRANT PERMISSIONS
-- =====================================================

-- Grant necessary permissions to the authenticated role
GRANT ALL ON notifications TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- =====================================================
-- TEST NOTIFICATION INSERTION
-- =====================================================

-- Test query to verify notification insertion works
-- (This should be run by an authenticated user)
/*
INSERT INTO notifications (
    user_id, 
    type, 
    title, 
    body, 
    data
) VALUES (
    auth.uid(), 
    'system', 
    'Test Notification', 
    'This is a test notification', 
    '{"test": true}'::jsonb
);
*/ 