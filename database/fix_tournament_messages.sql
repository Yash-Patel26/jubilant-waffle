-- =====================================================
-- FIX TOURNAMENT MESSAGES MESSAGE_TYPE
-- =====================================================

-- Update any existing tournament messages with 'chat' type to 'general'
UPDATE tournament_messages 
SET message_type = 'general' 
WHERE message_type = 'chat';

-- Verify the constraint is working
-- This should not return any rows if the fix worked
SELECT * FROM tournament_messages 
WHERE message_type NOT IN ('general', 'announcement', 'system');

-- Add comment to document the fix
COMMENT ON TABLE tournament_messages IS 'Tournament messages with types: general (chat), announcement, system'; 