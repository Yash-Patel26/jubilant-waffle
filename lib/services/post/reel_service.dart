import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class ReelService {
  static final ReelService _instance = ReelService._internal();
  factory ReelService() => _instance;
  ReelService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // REEL CRUD OPERATIONS
  // =====================================================

  /// Create a new reel
  Future<Reel?> createReel({
    required String caption,
    required String videoUrl,
    String? thumbnailUrl,
    String? gameTag,
    int? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final reelData = {
        'user_id': currentUser.id,
        'caption': caption,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'game_tag': gameTag,
        'duration': duration,
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

  /// Get reels with pagination
  Future<List<Reel>> getReels({
    int limit = 20,
    int offset = 0,
    String? userId,
    String? gameTag,
  }) async {
    try {
      var query = _client.from('reels').select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url,
                profile_picture_url
              )
            ),
            likes:reel_likes(count),
            comments:reel_comments(count)
          ''');

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (gameTag != null) {
        query = query.eq('game_tag', gameTag);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((json) => Reel.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get reels', e);
      return [];
    }
  }

  /// Get a single reel by ID
  Future<Reel?> getReel(String reelId) async {
    try {
      final response = await _client.from('reels').select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url,
                profile_picture_url
              )
            ),
            likes:reel_likes(count),
            comments:reel_comments(count)
          ''').eq('id', reelId).single();

      return Reel.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get reel', e);
      return null;
    }
  }

  /// Update a reel
  Future<bool> updateReel({
    required String reelId,
    String? caption,
    String? gameTag,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (caption != null) updates['caption'] = caption;
      if (gameTag != null) updates['game_tag'] = gameTag;
      if (metadata != null) updates['metadata'] = metadata;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('reels')
          .update(updates)
          .eq('id', reelId)
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to update reel', e);
      return false;
    }
  }

  /// Delete a reel
  Future<bool> deleteReel(String reelId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client
          .from('reels')
          .delete()
          .eq('id', reelId)
          .eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to delete reel', e);
      return false;
    }
  }

  // =====================================================
  // REEL ENGAGEMENT
  // =====================================================

  /// Like a reel
  Future<bool> likeReel(String reelId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client.from('reel_likes').insert({
        'reel_id': reelId,
        'user_id': currentUser.id,
      });

      // Update like count
      await _client
          .rpc('increment_reel_like_count', params: {'reel_id': reelId});

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to like reel', e);
      return false;
    }
  }

  /// Unlike a reel
  Future<bool> unlikeReel(String reelId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await _client
          .from('reel_likes')
          .delete()
          .eq('reel_id', reelId)
          .eq('user_id', currentUser.id);

      // Update like count
      await _client
          .rpc('decrement_reel_like_count', params: {'reel_id': reelId});

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to unlike reel', e);
      return false;
    }
  }

  /// Check if user has liked a reel
  Future<bool> hasLikedReel(String reelId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return false;

      final response = await _client
          .from('reel_likes')
          .select()
          .eq('reel_id', reelId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      ErrorHandler.logError('Failed to check reel like status', e);
      return false;
    }
  }

  // =====================================================
  // REEL SHARING
  // =====================================================

  /// Share a reel with specific users
  Future<bool> shareReel({
    required String reelId,
    required List<String> recipientIds,
    String? message,
  }) async {
    try {
      ErrorHandler.logInfo(
          'shareReel:start reelId=$reelId recipients=${recipientIds.length} hasMessage=${message != null && message.isNotEmpty}');
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Ensure the user has a profile row to satisfy FK (profiles.id)
      try {
        final profile = await _client
            .from('profiles')
            .select('id')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (profile == null) {
          // Create a minimal profile record; username fallback if unknown
          final fallbackUsername =
              '${(currentUser.email ?? 'user').split('@').first}_${currentUser.id.substring(0, 6)}';
          await _client.from('profiles').insert({
            'id': currentUser.id,
            'username': fallbackUsername,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
          ErrorHandler.logInfo(
              'shareReel:created missing profile for user=${currentUser.id} username=$fallbackUsername');
        }
      } catch (e) {
        // If profile creation fails, surface a user-friendly error
        throw Exception('Profile not found. Please complete profile setup.');
      }

      // Create shared_reels entry with a client-generated id to avoid RLS SELECT recursion
      final sharedReelId = const Uuid().v4();
      final shareData = {
        'id': sharedReelId,
        'original_reel_id': reelId,
        'shared_by_id': currentUser.id,
        'message': message,
        'share_type': 'specific',
      };

      await _client.from('shared_reels').insert(shareData);
      ErrorHandler.logInfo(
          'shareReel:inserted shared_reels row id=$sharedReelId');

      // Insert recipients
      if (recipientIds.isNotEmpty) {
        final recipients = recipientIds
            .map((recipientId) => {
                  'shared_reel_id': sharedReelId,
                  'recipient_id': recipientId,
                  'created_at': DateTime.now().toIso8601String(),
                })
            .toList();

        await _client
            .from('shared_reel_recipients')
            .insert(recipients);
        ErrorHandler.logInfo(
            'shareReel:inserted recipients count=${recipients.length}');
      }

      // Update share count on original reel
      await _client
          .rpc('increment_reel_share_count', params: {'reel_id': reelId});
      ErrorHandler.logInfo(
          'shareReel:incremented share_count for reel=$reelId');

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to share reel', e);
      try {
        // Attempt to surface more context if it's a PostgrestException-like error
        ErrorHandler.logWarning('shareReel:detail=${e.toString()}');
      } catch (_) {}
      return false;
    }
  }

  /// Share a reel with all followers
  Future<bool> shareReelWithFollowers({
    required String reelId,
    String? message,
  }) async {
    try {
      ErrorHandler.logInfo('shareReelWithFollowers:start reelId=$reelId');
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
      ErrorHandler.logInfo(
          'shareReelWithFollowers:found followers=${followerIds.length}');

      return await shareReel(
        reelId: reelId,
        recipientIds: followerIds,
        message: message,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to share reel with followers', e);
      return false;
    }
  }

  /// Share a reel with all following users
  Future<bool> shareReelWithFollowing({
    required String reelId,
    String? message,
  }) async {
    try {
      ErrorHandler.logInfo('shareReelWithFollowing:start reelId=$reelId');
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
      ErrorHandler.logInfo(
          'shareReelWithFollowing:found following=${followingIds.length}');

      return await shareReel(
        reelId: reelId,
        recipientIds: followingIds,
        message: message,
      );
    } catch (e) {
      ErrorHandler.logError('Failed to share reel with following', e);
      return false;
    }
  }

  /// Get users that can receive shared reels (followers + following)
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
  // REEL ANALYTICS
  // =====================================================

  /// Increment view count for a reel
  Future<bool> incrementViewCount(String reelId) async {
    try {
      await _client
          .rpc('increment_reel_view_count', params: {'reel_id': reelId});
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to increment reel view count', e);
      return false;
    }
  }

  /// Get reel statistics
  Future<Map<String, dynamic>?> getReelStats(String reelId) async {
    try {
      final response = await _client
          .from('reels')
          .select('like_count, comment_count, share_count, view_count')
          .eq('id', reelId)
          .single();

      return {
        'like_count': response['like_count'] ?? 0,
        'comment_count': response['comment_count'] ?? 0,
        'share_count': response['share_count'] ?? 0,
        'view_count': response['view_count'] ?? 0,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get reel stats', e);
      return null;
    }
  }
}
