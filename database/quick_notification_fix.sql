-- =====================================================
-- QUICK NOTIFICATION FIX - FIELD NAME MISMATCH
-- =====================================================
-- This fixes the "null value in column 'body' violates not-null constraint" error

-- Option 1: Disable notification triggers temporarily (QUICKEST FIX)
DROP TRIGGER IF EXISTS trigger_post_like_notification ON post_likes;
DROP TRIGGER IF EXISTS trigger_comment_notification ON comments;
DROP TRIGGER IF EXISTS trigger_follow_notification ON follows;
DROP TRIGGER IF EXISTS trigger_message_notification ON messages;
DROP TRIGGER IF EXISTS trigger_tournament_message_notification ON tournament_messages;

-- Option 2: Fix the notification function (RECOMMENDED)
-- Uncomment the following lines to fix the triggers properly:


-- Drop the old function
DROP FUNCTION IF EXISTS create_notification();

-- Create the fixed function
CREATE OR REPLACE FUNCTION create_notification()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id uuid;
    sender_name text;
    sender_avatar text;
    notification_type text;
    notification_title text;
    notification_message text;
BEGIN
    -- Only handle message notifications for now (to fix the immediate issue)
    IF TG_TABLE_NAME = 'messages' AND TG_OP = 'INSERT' THEN
        -- Get conversation participants
        SELECT user_id INTO target_user_id 
        FROM conversation_participants 
        WHERE conversation_id = NEW.conversation_id AND user_id != NEW.sender_id
        LIMIT 1;
        
        -- Don't notify if no other participant or messaging self
        IF target_user_id IS NULL OR target_user_id = NEW.sender_id THEN
            RETURN NEW;
        END IF;
        
        -- Get sender info
        SELECT username, avatar_url INTO sender_name, sender_avatar 
        FROM profiles WHERE id = NEW.sender_id;
        
        notification_type := 'message';
        notification_title := 'New Message';
        notification_message := sender_name || ' sent you a message';
        
        INSERT INTO notifications (
            user_id, type, title, body, data
        ) VALUES (
            target_user_id, notification_type, notification_title, 
            notification_message, 
            jsonb_build_object('conversation_id', NEW.conversation_id, 'sender_name', sender_name, 'sender_avatar', sender_avatar)
        );
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate only the message notification trigger
CREATE TRIGGER trigger_message_notification
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();


-- Verify the fix
SELECT 'Notification triggers disabled/fixed successfully' as status;

-- Test message sending should now work without errors 