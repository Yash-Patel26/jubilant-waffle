-- =====================================================
-- GAMERFLICK NOTIFICATION TRIGGERS AND FUNCTIONS
-- =====================================================

-- First, let's update the notifications table to match the Flutter model
ALTER TABLE notifications 
ADD COLUMN IF NOT EXISTS message text,
ADD COLUMN IF NOT EXISTS related_id uuid,
ADD COLUMN IF NOT EXISTS sender_id uuid REFERENCES profiles(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS sender_name text,
ADD COLUMN IF NOT EXISTS sender_avatar_url text,
ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}';

-- Update existing records to copy body to message
UPDATE notifications SET message = body WHERE message IS NULL;

-- Create notification trigger function
CREATE OR REPLACE FUNCTION create_notification()
RETURNS TRIGGER AS $$
DECLARE
    notification_type text;
    notification_title text;
    notification_message text;
    target_user_id uuid;
    sender_name text;
    sender_avatar text;
BEGIN
    -- Determine notification type and content based on the table being modified
    CASE TG_TABLE_NAME
        WHEN 'post_likes' THEN
            -- Post like notification
            IF TG_OP = 'INSERT' THEN
                -- Get post owner
                SELECT user_id INTO target_user_id FROM posts WHERE id = NEW.post_id;
                
                -- Don't notify if liking own post
                IF target_user_id = NEW.user_id THEN
                    RETURN NEW;
                END IF;
                
                -- Get liker info
                SELECT username, avatar_url INTO sender_name, sender_avatar 
                FROM profiles WHERE id = NEW.user_id;
                
                notification_type := 'post_like';
                notification_title := 'New Like';
                notification_message := sender_name || ' liked your post';
                
                INSERT INTO notifications (
                    user_id, type, title, message, related_id, sender_id, 
                    sender_name, sender_avatar_url, metadata
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, NEW.post_id, NEW.user_id, 
                    sender_name, sender_avatar, 
                    jsonb_build_object('post_id', NEW.post_id)
                );
            END IF;
            
        WHEN 'comments' THEN
            -- Comment notification
            IF TG_OP = 'INSERT' THEN
                -- Get post owner
                SELECT user_id INTO target_user_id FROM posts WHERE id = NEW.post_id;
                
                -- Don't notify if commenting on own post
                IF target_user_id = NEW.user_id THEN
                    RETURN NEW;
                END IF;
                
                -- Get commenter info
                SELECT username, avatar_url INTO sender_name, sender_avatar 
                FROM profiles WHERE id = NEW.user_id;
                
                notification_type := 'post_comment';
                notification_title := 'New Comment';
                notification_message := sender_name || ' commented on your post';
                
                INSERT INTO notifications (
                    user_id, type, title, message, related_id, sender_id, 
                    sender_name, sender_avatar_url, metadata
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, NEW.post_id, NEW.user_id, 
                    sender_name, sender_avatar, 
                    jsonb_build_object('post_id', NEW.post_id, 'comment_id', NEW.id)
                );
            END IF;
            
        WHEN 'follows' THEN
            -- Follow notification
            IF TG_OP = 'INSERT' THEN
                -- Don't notify if following self
                IF NEW.follower_id = NEW.following_id THEN
                    RETURN NEW;
                END IF;
                
                -- Get follower info
                SELECT username, avatar_url INTO sender_name, sender_avatar 
                FROM profiles WHERE id = NEW.follower_id;
                
                notification_type := 'follow_request';
                notification_title := 'New Follower';
                notification_message := sender_name || ' started following you';
                
                INSERT INTO notifications (
                    user_id, type, title, message, related_id, sender_id, 
                    sender_name, sender_avatar_url, metadata
                ) VALUES (
                    NEW.following_id, notification_type, notification_title, 
                    notification_message, NEW.follower_id, NEW.follower_id, 
                    sender_name, sender_avatar, 
                    jsonb_build_object('follower_id', NEW.follower_id)
                );
            END IF;
            
        WHEN 'messages' THEN
            -- Message notification
            IF TG_OP = 'INSERT' THEN
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
                
                notification_type := 'new_message';
                notification_title := 'New Message';
                notification_message := sender_name || ' sent you a message';
                
                INSERT INTO notifications (
                    user_id, type, title, message, related_id, sender_id, 
                    sender_name, sender_avatar_url, metadata
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, NEW.conversation_id, NEW.sender_id, 
                    sender_name, sender_avatar, 
                    jsonb_build_object('conversation_id', NEW.conversation_id, 'message_id', NEW.id)
                );
            END IF;
            
        WHEN 'tournament_messages' THEN
            -- Tournament message notification
            IF TG_OP = 'INSERT' THEN
                -- Get tournament participants
                SELECT user_id INTO target_user_id 
                FROM tournament_participants 
                WHERE tournament_id = NEW.tournament_id AND user_id != NEW.user_id
                LIMIT 1;
                
                -- Don't notify if no other participant or messaging self
                IF target_user_id IS NULL OR target_user_id = NEW.user_id THEN
                    RETURN NEW;
                END IF;
                
                -- Get sender info
                SELECT username, avatar_url INTO sender_name, sender_avatar 
                FROM profiles WHERE id = NEW.user_id;
                
                notification_type := 'tournament_update';
                notification_title := 'Tournament Update';
                notification_message := sender_name || ' posted in tournament';
                
                INSERT INTO notifications (
                    user_id, type, title, message, related_id, sender_id, 
                    sender_name, sender_avatar_url, metadata
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, NEW.tournament_id, NEW.user_id, 
                    sender_name, sender_avatar, 
                    jsonb_build_object('tournament_id', NEW.tournament_id, 'message_id', NEW.id)
                );
            END IF;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for different tables
DROP TRIGGER IF EXISTS trigger_post_like_notification ON post_likes;
CREATE TRIGGER trigger_post_like_notification
    AFTER INSERT ON post_likes
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

DROP TRIGGER IF EXISTS trigger_comment_notification ON comments;
CREATE TRIGGER trigger_comment_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

DROP TRIGGER IF EXISTS trigger_follow_notification ON follows;
CREATE TRIGGER trigger_follow_notification
    AFTER INSERT ON follows
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

DROP TRIGGER IF EXISTS trigger_message_notification ON messages;
CREATE TRIGGER trigger_message_notification
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

DROP TRIGGER IF EXISTS trigger_tournament_message_notification ON tournament_messages;
CREATE TRIGGER trigger_tournament_message_notification
    AFTER INSERT ON tournament_messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

-- Function to create test notifications
CREATE OR REPLACE FUNCTION create_test_notification(
    target_user_id uuid,
    notification_type text DEFAULT 'system',
    custom_title text DEFAULT 'Test Notification',
    custom_message text DEFAULT 'This is a test notification'
)
RETURNS void AS $$
BEGIN
    INSERT INTO notifications (
        user_id, type, title, message, metadata
    ) VALUES (
        target_user_id, notification_type, custom_title, custom_message,
        jsonb_build_object('test', true, 'created_at', now())
    );
END;
$$ LANGUAGE plpgsql; 