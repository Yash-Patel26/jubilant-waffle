-- =====================================================
-- COMMUNITY FUNCTIONS
-- =====================================================

-- Function to increment community member count
CREATE OR REPLACE FUNCTION increment_community_member_count(community_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET member_count = member_count + 1,
      updated_at = now()
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement community member count
CREATE OR REPLACE FUNCTION decrement_community_member_count(community_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET member_count = GREATEST(member_count - 1, 0),
      updated_at = now()
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Function to sync community member count (useful for data consistency)
CREATE OR REPLACE FUNCTION sync_community_member_count(community_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE communities 
  SET member_count = (
    SELECT COUNT(*) 
    FROM community_members 
    WHERE community_id = $1 AND is_banned = false
  ),
  updated_at = now()
  WHERE id = community_id;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update member count when community_members table changes
CREATE OR REPLACE FUNCTION update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    PERFORM increment_community_member_count(NEW.community_id);
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    PERFORM decrement_community_member_count(OLD.community_id);
    RETURN OLD;
  ELSIF TG_OP = 'UPDATE' THEN
    -- If ban status changed, update count accordingly
    IF OLD.is_banned != NEW.is_banned THEN
      IF NEW.is_banned THEN
        PERFORM decrement_community_member_count(NEW.community_id);
      ELSE
        PERFORM increment_community_member_count(NEW.community_id);
      END IF;
    END IF;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on community_members table
DROP TRIGGER IF EXISTS trigger_update_community_member_count ON community_members;
CREATE TRIGGER trigger_update_community_member_count
  AFTER INSERT OR DELETE OR UPDATE ON community_members
  FOR EACH ROW
  EXECUTE FUNCTION update_community_member_count(); 