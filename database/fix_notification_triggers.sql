-- =====================================================
-- FIX NOTIFICATION TRIGGERS - FIELD NAME MISMATCH
-- =====================================================
-- The issue: Triggers are using 'message' field but schema uses 'body'

-- Drop existing triggers first
DROP TRIGGER IF EXISTS trigger_post_like_notification ON post_likes;
DROP TRIGGER IF EXISTS trigger_comment_notification ON comments;
DROP TRIGGER IF EXISTS trigger_follow_notification ON follows;
DROP TRIGGER IF EXISTS trigger_message_notification ON messages;
DROP TRIGGER IF EXISTS trigger_tournament_message_notification ON tournament_messages;

-- Drop the function
DROP FUNCTION IF EXISTS create_notification();

-- Recreate the function with correct field names
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
    -- Determine which table triggered this
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
                
                notification_type := 'like';
                notification_title := 'New Like';
                notification_message := sender_name || ' liked your post';
                
                INSERT INTO notifications (
                    user_id, type, title, body, data
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, 
                    jsonb_build_object('post_id', NEW.post_id, 'sender_name', sender_name, 'sender_avatar', sender_avatar)
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
                
                notification_type := 'comment';
                notification_title := 'New Comment';
                notification_message := sender_name || ' commented on your post';
                
                INSERT INTO notifications (
                    user_id, type, title, body, data
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, 
                    jsonb_build_object('post_id', NEW.post_id, 'comment_id', NEW.id, 'sender_name', sender_name, 'sender_avatar', sender_avatar)
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
                
                notification_type := 'follow';
                notification_title := 'New Follower';
                notification_message := sender_name || ' started following you';
                
                INSERT INTO notifications (
                    user_id, type, title, body, data
                ) VALUES (
                    NEW.following_id, notification_type, notification_title, 
                    notification_message, 
                    jsonb_build_object('follower_id', NEW.follower_id, 'sender_name', sender_name, 'sender_avatar', sender_avatar)
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
                
                notification_type := 'message';
                notification_title := 'New Message';
                notification_message := sender_name || ' sent you a message';
                
                INSERT INTO notifications (
                    user_id, type, title, body, data
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, 
                    jsonb_build_object('conversation_id', NEW.conversation_id, 'sender_name', sender_name, 'sender_avatar', sender_avatar, 'message_content', NEW.content)
                );
            END IF;
            
        WHEN 'tournament_messages' THEN
            -- Tournament message notification
            IF TG_OP = 'INSERT' THEN
                -- Get tournament participants (excluding sender)
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
                
                notification_type := 'tournament';
                notification_title := 'Tournament Update';
                notification_message := sender_name || ' sent a message in tournament';
                
                INSERT INTO notifications (
                    user_id, type, title, body, data
                ) VALUES (
                    target_user_id, notification_type, notification_title, 
                    notification_message, 
                    jsonb_build_object('tournament_id', NEW.tournament_id, 'sender_name', sender_name, 'sender_avatar', sender_avatar, 'message_content', NEW.message)
                );
            END IF;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the triggers
CREATE TRIGGER trigger_post_like_notification
    AFTER INSERT ON post_likes
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER trigger_comment_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER trigger_follow_notification
    AFTER INSERT ON follows
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER trigger_message_notification
    AFTER INSERT ON messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

CREATE TRIGGER trigger_tournament_message_notification
    AFTER INSERT ON tournament_messages
    FOR EACH ROW
    EXECUTE FUNCTION create_notification();

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Test the triggers by checking if they exist
SELECT 
    trigger_name, 
    event_manipulation, 
    event_object_table, 
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

-- =====================================================
-- ALTERNATIVE: DISABLE NOTIFICATION TRIGGERS TEMPORARILY
-- =====================================================

-- If you want to disable notification triggers temporarily:
/*
DROP TRIGGER IF EXISTS trigger_post_like_notification ON post_likes;
DROP TRIGGER IF EXISTS trigger_comment_notification ON comments;
DROP TRIGGER IF EXISTS trigger_follow_notification ON follows;
DROP TRIGGER IF EXISTS trigger_message_notification ON messages;
DROP TRIGGER IF EXISTS trigger_tournament_message_notification ON tournament_messages;
*/ 