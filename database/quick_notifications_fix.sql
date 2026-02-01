-- =====================================================
-- QUICK NOTIFICATIONS RLS FIX
-- =====================================================
-- Run this script in your Supabase SQL editor to fix the notifications issue

-- Step 1: Disable RLS on notifications table
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- Step 2: Grant necessary permissions
GRANT ALL ON notifications TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Step 3: Verify the fix
SELECT 'Notifications RLS disabled successfully' as status;

-- Optional: If you want to re-enable RLS later with proper policies, use this:
/*
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON notifications 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications 
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow notification creation" ON notifications 
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can delete own notifications" ON notifications 
    FOR DELETE USING (auth.uid() = user_id);
*/ 