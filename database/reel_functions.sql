-- =====================================================
-- REEL FUNCTIONS
-- =====================================================

-- Function to increment reel like count
CREATE OR REPLACE FUNCTION increment_reel_like_count(reel_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET like_count = COALESCE(like_count, 0) + 1
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement reel like count
CREATE OR REPLACE FUNCTION decrement_reel_like_count(reel_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET like_count = GREATEST(COALESCE(like_count, 0) - 1, 0)
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- Function to increment reel comment count
CREATE OR REPLACE FUNCTION increment_reel_comment_count(reel_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET comment_count = COALESCE(comment_count, 0) + 1
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- Function to decrement reel comment count
CREATE OR REPLACE FUNCTION decrement_reel_comment_count(reel_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE reels 
  SET comment_count = GREATEST(COALESCE(comment_count, 0) - 1, 0)
  WHERE id = reel_id;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TRIGGERS FOR AUTOMATIC COUNT UPDATES
-- =====================================================

-- Trigger function for reel likes
CREATE OR REPLACE FUNCTION update_reel_like_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment like count when a like is added
    UPDATE reels 
    SET like_count = COALESCE(like_count, 0) + 1
    WHERE id = NEW.reel_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement like count when a like is removed
    UPDATE reels 
    SET like_count = GREATEST(COALESCE(like_count, 0) - 1, 0)
    WHERE id = OLD.reel_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger function for reel comments
CREATE OR REPLACE FUNCTION update_reel_comment_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Increment comment count when a comment is added
    UPDATE reels 
    SET comment_count = COALESCE(comment_count, 0) + 1
    WHERE id = NEW.reel_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    -- Decrement comment count when a comment is removed
    UPDATE reels 
    SET comment_count = GREATEST(COALESCE(comment_count, 0) - 1, 0)
    WHERE id = OLD.reel_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Create triggers
DROP TRIGGER IF EXISTS trigger_update_reel_like_count ON reel_likes;
CREATE TRIGGER trigger_update_reel_like_count
  AFTER INSERT OR DELETE ON reel_likes
  FOR EACH ROW
  EXECUTE FUNCTION update_reel_like_count();

DROP TRIGGER IF EXISTS trigger_update_reel_comment_count ON reel_comments;
CREATE TRIGGER trigger_update_reel_comment_count
  AFTER INSERT OR DELETE ON reel_comments
  FOR EACH ROW
  EXECUTE FUNCTION update_reel_comment_count();

-- =====================================================
-- COMMENTS
-- =====================================================

COMMENT ON FUNCTION increment_reel_like_count(uuid) IS 'Increments the like count for a reel';
COMMENT ON FUNCTION decrement_reel_like_count(uuid) IS 'Decrements the like count for a reel';
COMMENT ON FUNCTION increment_reel_comment_count(uuid) IS 'Increments the comment count for a reel';
COMMENT ON FUNCTION decrement_reel_comment_count(uuid) IS 'Decrements the comment count for a reel';
COMMENT ON FUNCTION update_reel_like_count() IS 'Trigger function to automatically update reel like counts';
COMMENT ON FUNCTION update_reel_comment_count() IS 'Trigger function to automatically update reel comment counts'; 