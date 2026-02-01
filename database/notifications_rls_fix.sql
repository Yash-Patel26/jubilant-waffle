-- =====================================================
-- COMPREHENSIVE NOTIFICATIONS RLS FIX
-- =====================================================

-- First, let's check the current state
SELECT 
    schemaname, 
    tablename, 
    rowsecurity 
FROM pg_tables 
WHERE tablename = 'notifications';

-- Check existing policies
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
WHERE tablename = 'notifications';

-- =====================================================
-- STEP 1: DISABLE RLS TEMPORARILY FOR TESTING
-- =====================================================

-- Temporarily disable RLS to allow notifications to work
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- STEP 2: ALTERNATIVE APPROACH - ENABLE RLS WITH PROPER POLICIES
-- =====================================================

-- If you want to keep RLS enabled, use these policies instead:

/*
-- Re-enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DROP POLICY IF EXISTS "Users can view own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can insert own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;
DROP POLICY IF EXISTS "Users can delete own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can create notifications for others" ON notifications;

-- Create comprehensive policies
CREATE POLICY "Enable all operations for authenticated users" ON notifications
    FOR ALL USING (auth.role() = 'authenticated');

-- Or create specific policies for each operation:
CREATE POLICY "Users can view own notifications" ON notifications 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications 
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Allow notification creation" ON notifications 
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Users can delete own notifications" ON notifications 
    FOR DELETE USING (auth.uid() = user_id);
*/

-- =====================================================
-- STEP 3: GRANT NECESSARY PERMISSIONS
-- =====================================================

-- Grant all permissions to authenticated users
GRANT ALL ON notifications TO authenticated;
GRANT USAGE ON SCHEMA public TO authenticated;

-- Grant permissions to the service role (if using service role for notifications)
GRANT ALL ON notifications TO service_role;

-- =====================================================
-- STEP 4: VERIFY THE FIX
-- =====================================================

-- Test notification insertion (run this as an authenticated user)
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
    'This is a test notification to verify RLS fix', 
    '{"test": true, "timestamp": "' || now() || '"}'::jsonb
);
*/

-- =====================================================
-- STEP 5: ALTERNATIVE APPROACH USING TRIGGERS
-- =====================================================

-- If you want to use triggers instead of direct insertion, create this function:

CREATE OR REPLACE FUNCTION create_notification_trigger()
RETURNS TRIGGER AS $$
BEGIN
    -- This function can be called to create notifications
    -- It will have the necessary permissions to bypass RLS
    INSERT INTO notifications (
        user_id,
        type,
        title,
        body,
        data
    ) VALUES (
        NEW.user_id,
        NEW.type,
        NEW.title,
        NEW.body,
        NEW.data
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- STEP 6: UPDATE THE NOTIFICATION SERVICE
-- =====================================================

-- The Flutter notification service should be updated to handle errors gracefully:

/*
// In lib/services/notification_service.dart, update the createNotification method:

Future<void> createNotification({
  required String userUuid,
  required String notificationType,
  required String titleParam,
  required String messageParam,
  String? relatedIdParam,
  String? senderUuid,
  Map<String, dynamic>? metadataParam,
}) async {
  try {
    await _client.from('notifications').insert({
      'user_id': userUuid,
      'type': notificationType,
      'title': titleParam,
      'body': messageParam, // Note: changed from 'message' to 'body' to match schema
      'data': metadataParam ?? {},
      'created_at': DateTime.now().toIso8601String(),
    });
  } catch (e) {
    print('Failed to create notification: $e');
    // Don't throw the error to prevent app crashes
    // You might want to log this to your analytics service
  }
}
*/

-- =====================================================
-- STEP 7: VERIFICATION QUERIES
-- =====================================================

-- Check if notifications table is accessible
SELECT COUNT(*) FROM notifications LIMIT 1;

-- Check if we can insert a test notification
-- (This should be run by an authenticated user)
/*
DO $$
BEGIN
  INSERT INTO notifications (
    user_id, 
    type, 
    title, 
    body, 
    data
  ) VALUES (
    '00000000-0000-0000-0000-000000000000', -- Replace with actual user ID
    'test', 
    'Test Notification', 
    'Test notification body', 
    '{"test": true}'::jsonb
  );
  RAISE NOTICE 'Test notification inserted successfully';
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Failed to insert test notification: %', SQLERRM;
END $$;
*/

-- =====================================================
-- STEP 8: ROLLBACK PLAN
-- =====================================================

-- If you need to rollback and re-enable RLS with strict policies:
/*
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own notifications" ON notifications 
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own notifications" ON notifications 
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notifications" ON notifications 
    FOR DELETE USING (auth.uid() = user_id);

-- For system-generated notifications, you might need to use service role
-- or create a specific policy for system notifications
*/ 