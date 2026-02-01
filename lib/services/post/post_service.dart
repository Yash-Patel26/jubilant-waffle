import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/post/story.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/models/post/comment.dart';
import 'package:gamer_flick/models/post/post_like.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class PostService {
  static final PostService _instance = PostService._internal();
  factory PostService() => _instance;
  PostService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // POST CRUD OPERATIONS
  // =====================================================

  /// Create a new post
  Future<Post?> createPost({
    required String content,
    List<String>? mediaUrls,
    String? gameTag,
    String? location,
    bool isPublic = true,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final postData = {
        'user_id': currentUser.id,
        'content': content,
        'media_urls': mediaUrls ?? [],
        'game_tag': gameTag,
        'location': location,
        'is_public': isPublic,
        'mentions': mentions ?? [],
        'metadata': metadata ?? {},
      };

      final response = await _client.from('posts').insert(postData).select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''').single();

      return Post.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to create post', e);
      return null;
    }
  }

  /// Get posts with pagination
  Future<List<Post>> getPosts({
    int limit = 20,
    int offset = 0,
    String? userId,
    String? gameTag,
    bool? isPublic,
  }) async {
    try {
      var query = _client.from('posts').select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }
      if (gameTag != null) {
        query = query.eq('game_tag', gameTag);
      }
      if (isPublic != null) {
        query = query.eq('is_public', isPublic);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get posts', e);
      return [];
    }
  }

  /// Get user's feed (posts from followed users)
  Future<List<Post>> getUserFeed({int limit = 20, int offset = 0}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      // Get IDs of users that current user follows
      final followingResponse = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = (followingResponse as List)
          .map((item) => item['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      // Get posts from followed users
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .inFilter('user_id', followingIds)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get user feed', e);
      return [];
    }
  }

  /// Get a single post by ID
  Future<Post?> getPostById(String postId) async {
    try {
      final response = await _client.from('posts').select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''').eq('id', postId).single();

      return Post.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get post', e);
      return null;
    }
  }

  /// Update a post
  Future<bool> updatePost({
    required String postId,
    String? content,
    List<String>? mediaUrls,
    String? gameTag,
    String? location,
    bool? isPublic,
    List<String>? mentions,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Verify ownership
      final post = await _client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      if (post['user_id'] != currentUser.id) {
        throw Exception('Not authorized to update this post');
      }

      final updateData = <String, dynamic>{};
      if (content != null) updateData['content'] = content;
      if (mediaUrls != null) updateData['media_urls'] = mediaUrls;
      if (gameTag != null) updateData['game_tag'] = gameTag;
      if (location != null) updateData['location'] = location;
      if (isPublic != null) updateData['is_public'] = isPublic;
      if (mentions != null) updateData['mentions'] = mentions;
      if (metadata != null) updateData['metadata'] = metadata;

      await _client.from('posts').update(updateData).eq('id', postId);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to update post', e);
      return false;
    }
  }

  /// Delete a post
  Future<bool> deletePost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Verify ownership
      final post = await _client
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();

      if (post['user_id'] != currentUser.id) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete related data
      await _client.from('comments').delete().eq('post_id', postId);
      await _client.from('post_likes').delete().eq('post_id', postId);
      await _client.from('saved_posts').delete().eq('post_id', postId);
      await _client
          .from('shared_posts')
          .delete()
          .eq('original_post_id', postId);

      // Delete the post
      await _client.from('posts').delete().eq('id', postId);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to delete post', e);
      return false;
    }
  }

  // =====================================================
  // LIKES & REACTIONS
  // =====================================================

  /// Like a post
  Future<bool> likePost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if already liked
      final existingLike = await _client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingLike != null) {
        throw Exception('Post already liked');
      }

      await _client.from('post_likes').insert({
        'post_id': postId,
        'user_id': currentUser.id,
      });

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to like post', e);
      return false;
    }
  }

  /// Unlike a post
  Future<bool> unlikePost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client
          .from('post_likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to unlike post', e);
      return false;
    }
  }

  /// Check if user has liked a post
  Future<bool> hasLikedPost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final like = await _client
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return like != null;
    } catch (e) {
      ErrorHandler.logError('Failed to check like status', e);
      return false;
    }
  }

  /// Get users who liked a post
  Future<List<Map<String, dynamic>>> getPostLikes(String postId,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('post_likes')
          .select('''
            created_at
          ''')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((item) => {
                'liked_at': item['created_at'],
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get post likes', e);
      return [];
    }
  }

  // =====================================================
  // COMMENTS
  // =====================================================

  /// Add a comment to a post
  Future<Comment?> addComment({
    required String postId,
    required String content,
    String? parentCommentId,
    List<String>? mentions,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final commentData = {
        'post_id': postId,
        'user_id': currentUser.id,
        'content': content,
        'parent_comment_id': parentCommentId,
        'mentions': mentions ?? [],
      };

      final response =
          await _client.from('comments').insert(commentData).select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url
              )
            )
          ''').single();

      return Comment.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to add comment', e);
      return null;
    }
  }

  /// Get comments for a post
  Future<List<Comment>> getComments(String postId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url
              )
            )
          ''')
          .eq('post_id', postId)
          .filter('parent_comment_id', 'is', null) // Only top-level comments
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get comments', e);
      return [];
    }
  }

  /// Get replies to a comment
  Future<List<Comment>> getCommentReplies(String commentId,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('comments')
          .select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url
              )
            )
          ''')
          .eq('parent_comment_id', commentId)
          .order('created_at', ascending: true)
          .limit(limit);

      return (response as List).map((json) => Comment.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get comment replies', e);
      return [];
    }
  }

  /// Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Verify ownership
      final comment = await _client
          .from('comments')
          .select('user_id')
          .eq('id', commentId)
          .single();

      if (comment['user_id'] != currentUser.id) {
        throw Exception('Not authorized to delete this comment');
      }

      await _client.from('comments').delete().eq('id', commentId);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to delete comment', e);
      return false;
    }
  }

  // =====================================================
  // STORIES
  // =====================================================

  /// Create a story
  Future<Story?> createStory({
    required String mediaUrl,
    String? caption,
    String? gameTag,
    Duration? duration,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final storyData = {
        'user_id': currentUser.id,
        'media_url': mediaUrl,
        'caption': caption,
        'game_tag': gameTag,
        'duration': duration?.inSeconds ?? 24 * 3600, // Default 24 hours
        'expires_at': DateTime.now()
            .add(Duration(seconds: duration?.inSeconds ?? 24 * 3600)),
      };

      final response =
          await _client.from('stories').insert(storyData).select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url,
                profile_picture_url
              )
            )
          ''').single();

      return Story.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to create story', e);
      return null;
    }
  }

  /// Get stories for user's feed
  Future<List<Story>> getStoriesFeed() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      // Get stories from followed users
      final followingResponse = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = (followingResponse as List)
          .map((item) => item['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) return [];

      final response = await _client
          .from('stories')
          .select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url,
                profile_picture_url
              )
            )
          ''')
          .inFilter('user_id', followingIds)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get stories feed', e);
      return [];
    }
  }

  /// Get user's own stories
  Future<List<Story>> getUserStories(String userId) async {
    try {
      final response = await _client
          .from('stories')
          .select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url,
                profile_picture_url
              )
            )
          ''')
          .eq('user_id', userId)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      return (response as List).map((json) => Story.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get user stories', e);
      return [];
    }
  }

  // =====================================================
  // REELS
  // =====================================================

  /// Create a reel
  Future<Reel?> createReel({
    required String videoUrl,
    required String thumbnailUrl,
    String? caption,
    String? gameTag,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final reelData = {
        'user_id': currentUser.id,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'caption': caption,
        'game_tag': gameTag,
        'duration': duration?.inSeconds,
        'metadata': metadata ?? {},
      };

      final response = await _client.from('reels').insert(reelData).select('''
            *,
            likes:reel_likes(count),
            comments:reel_comments(count)
          ''').single();

      return Reel.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to create reel', e);
      return null;
    }
  }

  /// Get reels feed
  Future<List<Reel>> getReelsFeed({int limit = 20, int offset = 0}) async {
    try {
      final currentUser = _client.auth.currentUser;

      final response = await _client
          .from('reels')
          .select('''
            *,
            user:profiles!reels_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url,
              profile_picture_url
            ),
            likes:reel_likes(count),
            comments:reel_comments(count)
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final reels =
          (response as List).map((json) => Reel.fromJson(json)).toList();

      // Check if current user has liked each reel
      if (currentUser != null) {
        for (int i = 0; i < reels.length; i++) {
          try {
            final likeCheck = await _client
                .from('reel_likes')
                .select('id')
                .eq('reel_id', reels[i].id)
                .eq('user_id', currentUser.id)
                .maybeSingle();

            // Create a new reel with updated like status
            final updatedReel = Reel(
              id: reels[i].id,
              userId: reels[i].userId,
              caption: reels[i].caption,
              videoUrl: reels[i].videoUrl,
              thumbnailUrl: reels[i].thumbnailUrl,
              gameTag: reels[i].gameTag,
              duration: reels[i].duration,
              metadata: reels[i].metadata,
              createdAt: reels[i].createdAt,
              updatedAt: reels[i].updatedAt,
              viewCount: reels[i].viewCount,
              likeCount: reels[i].likeCount,
              commentCount: reels[i].commentCount,
              shareCount: reels[i].shareCount,
              isLiked: likeCheck != null,
              isSaved: reels[i].isSaved,
              user: reels[i].user,
            );
            reels[i] = updatedReel;
          } catch (e) {
            // Keep original reel if error occurs
          }
        }
      }

      return reels;
    } catch (e) {
      ErrorHandler.logError('Failed to get reels feed', e);
      return [];
    }
  }

  /// Toggle like on a reel
  Future<bool> toggleReelLike(String reelId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if already liked
      final existingLike = await _client
          .from('reel_likes')
          .select('id')
          .eq('reel_id', reelId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client
            .from('reel_likes')
            .delete()
            .eq('reel_id', reelId)
            .eq('user_id', currentUser.id);
      } else {
        // Like
        await _client.from('reel_likes').insert({
          'reel_id': reelId,
          'user_id': currentUser.id,
        });
      }

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to toggle reel like', e);
      return false;
    }
  }

  /// Add comment to a reel
  Future<bool> addReelComment(String reelId, String content) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client.from('reel_comments').insert({
        'reel_id': reelId,
        'user_id': currentUser.id,
        'content': content,
      });

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to add reel comment', e);
      return false;
    }
  }

  /// Get comments for a reel
  Future<List<Map<String, dynamic>>> getReelComments(String reelId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('reel_comments')
          .select('''
            *,
            user:profiles!reel_comments_user_id_fkey(
              id,
              username,
              full_name,
              avatar_url,
              profile_picture_url
            )
          ''')
          .eq('reel_id', reelId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      ErrorHandler.logError('Failed to get reel comments', e);
      return [];
    }
  }

  // =====================================================
  // SAVE & SHARE
  // =====================================================

  /// Save a post
  Future<bool> savePost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if already saved
      final existingSave = await _client
          .from('saved_posts')
          .select()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existingSave != null) {
        throw Exception('Post already saved');
      }

      await _client.from('saved_posts').insert({
        'post_id': postId,
        'user_id': currentUser.id,
      });

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to save post', e);
      return false;
    }
  }

  /// Unsave a post
  Future<bool> unsavePost(String postId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client
          .from('saved_posts')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to unsave post', e);
      return false;
    }
  }

  /// Get saved posts
  Future<List<Post>> getSavedPosts({int limit = 20, int offset = 0}) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return [];

      final response = await _client
          .from('saved_posts')
          .select('''
            post:posts(
              *,
              likes:post_likes(count),
              comments:comments(count)
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((item) => Post.fromJson(item['post']))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get saved posts', e);
      return [];
    }
  }

  /// Share a post
  Future<bool> sharePost({
    required String postId,
    required List<String> recipientIds,
    String? message,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final shareData = {
        'original_post_id': postId,
        'shared_by_id': currentUser.id,
        'message': message,
        'share_type': 'specific',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert the shared post
      final sharedPostResponse = await _client
          .from('shared_posts')
          .insert(shareData)
          .select()
          .single();

      final sharedPostId = sharedPostResponse['id'] as String;

      // Insert recipients
      if (recipientIds.isNotEmpty) {
        final recipients = recipientIds
            .map((recipientId) => {
                  'shared_post_id': sharedPostId,
                  'recipient_id': recipientId,
                  'created_at': DateTime.now().toIso8601String(),
                })
            .toList();

        await _client.from('shared_post_recipients').insert(recipients);
      }

      // Update share count on original post
      await _client.rpc('increment_share_count', params: {'post_id': postId});

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to share post', e);
      return false;
    }
  }

  /// Share a post with all followers
  Future<bool> sharePostWithFollowers({
    required String postId,
    String? message,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get all followers
      final followersResponse = await _client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUser.id);

      final followerIds = (followersResponse as List)
          .map((item) => item['follower_id'] as String)
          .toList();

      if (followerIds.isEmpty) {
        throw Exception('No followers to share with');
      }

      return await sharePost(
        postId: postId,
        recipientIds: followerIds,
        message: message,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to share post with followers', e);
      return false;
    }
  }

  /// Share a post with all following users
  Future<bool> sharePostWithFollowing({
    required String postId,
    String? message,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Get all users that current user is following
      final followingResponse = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      final followingIds = (followingResponse as List)
          .map((item) => item['following_id'] as String)
          .toList();

      if (followingIds.isEmpty) {
        throw Exception('Not following any users');
      }

      return await sharePost(
        postId: postId,
        recipientIds: followingIds,
        message: message,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to share post with following', e);
      return false;
    }
  }

  /// Get users that can receive shared posts (followers + following)
  Future<Map<String, List<Map<String, dynamic>>>> getShareableUsers() async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Debug: Check if follows table exists and has data
      try {
        final followsCheck = await _client.from('follows').select('*').limit(1);
        print('Follows table check: ${followsCheck.length} records found');
      } catch (e) {
        print('Error checking follows table: $e');
        throw Exception('Follows table not accessible: $e');
      }

      // Get followers - first get the follower IDs
      final followersResponse = await _client
          .from('follows')
          .select('follower_id')
          .eq('following_id', currentUser.id);

      print(
          'Followers query result: ${followersResponse.length} followers found');

      // Get following - first get the following IDs
      final followingResponse = await _client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      print(
          'Following query result: ${followingResponse.length} following found');

      final followerIds = (followersResponse as List)
          .map((item) => item['follower_id'] as String)
          .toList();

      final followingIds = (followingResponse as List)
          .map((item) => item['following_id'] as String)
          .toList();

      // Now get the actual user profiles for followers
      List<Map<String, dynamic>> followers = [];
      if (followerIds.isNotEmpty) {
        final followersProfiles = await _client
            .from('profiles')
            .select('id, username, avatar_url, profile_picture_url')
            .inFilter('id', followerIds);

        followers = (followersProfiles as List)
            .map((item) => {
                  'id': item['id'],
                  'username': item['username'],
                  'display_name':
                      item['username'], // Use username as display name
                  'avatar_url':
                      item['avatar_url'] ?? item['profile_picture_url'],
                  'type': 'follower',
                })
            .toList();
      }

      // Now get the actual user profiles for following
      List<Map<String, dynamic>> following = [];
      if (followingIds.isNotEmpty) {
        final followingProfiles = await _client
            .from('profiles')
            .select('id, username, avatar_url, profile_picture_url')
            .inFilter('id', followingIds);

        following = (followingProfiles as List)
            .map((item) => {
                  'id': item['id'],
                  'username': item['username'],
                  'display_name':
                      item['username'], // Use username as display name
                  'avatar_url':
                      item['avatar_url'] ?? item['profile_picture_url'],
                  'type': 'following',
                })
            .toList();
      }

      print(
          'Final result: ${followers.length} followers, ${following.length} following');

      return {
        'followers': followers,
        'following': following,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get shareable users', e);
      print('Detailed error in getShareableUsers: $e');
      return {'followers': [], 'following': []};
    }
  }

  // =====================================================
  // SEARCH & DISCOVERY
  // =====================================================

  /// Search posts
  Future<List<Post>> searchPosts(String query, {int limit = 20}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .or('content.ilike.%$query%,game_tag.ilike.%$query%')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search posts', e);
      return [];
    }
  }

  /// Get trending posts
  Future<List<Post>> getTrendingPosts({int limit = 20}) async {
    try {
      final response = await _client
          .from('posts')
          .select('''
            *,
            likes:post_likes(count),
            comments:comments(count)
          ''')
          .eq('is_public', true)
          .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(days: 7))
                  .toIso8601String())
          .order('likes', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Post.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get trending posts', e);
      return [];
    }
  }

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  /// Subscribe to new posts
  Stream<List<Post>> subscribeToPosts() {
    return _client
        .from('posts')
        .stream(primaryKey: ['id'])
        .eq('is_public', true)
        .order('created_at', ascending: false)
        .map((response) =>
            (response as List).map((json) => Post.fromJson(json)).toList());
  }

  /// Subscribe to post likes
  Stream<List<PostLike>> subscribeToPostLikes(String postId) {
    return _client
        .from('post_likes')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((response) =>
            (response as List).map((json) => PostLike.fromJson(json)).toList());
  }

  /// Subscribe to post comments
  Stream<List<Comment>> subscribeToComments(String postId) {
    return _client
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .map((response) =>
            (response as List).map((json) => Comment.fromJson(json)).toList());
  }

  /// Pin a post
  Future<bool> pinPost(String postId) async {
    try {
      await _client.from('posts').update({'pinned': true}).eq('id', postId);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to pin post', e);
      return false;
    }
  }

  /// Unpin a post
  Future<bool> unpinPost(String postId) async {
    try {
      await _client.from('posts').update({'pinned': false}).eq('id', postId);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to unpin post', e);
      return false;
    }
  }
}
