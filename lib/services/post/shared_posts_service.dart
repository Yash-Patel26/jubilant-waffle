import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/models/post/shared_post.dart';

class SharedPostsService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> testFollowsData() async {
    // Stub method to fix missing method error
    return;
  }

  Future<void> sharePublicly({
    required String originalPostId,
    String? caption,
    String? mediaUrl,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    try {
      await _client.from('shared_posts').insert({
        'original_post_id': originalPostId,
        'shared_by_id': currentUser.id,
        'share_type': 'public',
        'caption': caption,
        'media_url': mediaUrl,
      });
    } catch (e) {
      throw Exception('Failed to share post publicly: $e');
    }
  }

  Future<void> shareWithFollowers({
    required String originalPostId,
    String? caption,
    String? mediaUrl,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    try {
      await _client.from('shared_posts').insert({
        'original_post_id': originalPostId,
        'shared_by_id': currentUser.id,
        'share_type': 'followers',
        'caption': caption,
        'media_url': mediaUrl,
      });
    } catch (e) {
      throw Exception('Failed to share post with followers: $e');
    }
  }

  Future<void> shareWithSpecificPeople({
    required String originalPostId,
    required List<String> recipientIds,
    String? caption,
    String? mediaUrl,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');
    try {
      final sharedPostData = {
        'original_post_id': originalPostId,
        'shared_by_id': currentUser.id,
        'share_type': 'specific',
        'caption': caption,
        'media_url': mediaUrl,
      };
      final sharedPost = await _client
          .from('shared_posts')
          .insert(sharedPostData)
          .select()
          .single();
      final recipients = recipientIds
          .map((recipientId) => {
                'shared_post_id': sharedPost['id'],
                'recipient_id': recipientId,
              })
          .toList();
      await _client.from('shared_post_recipients').insert(recipients);
    } catch (e) {
      throw Exception('Failed to share post with specific people: $e');
    }
  }

  Future<List<SharedPost>> getSharedPostsForUser() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final data = await _client
          .from('shared_posts')
          .select(
              '*, original_post:original_post_id(*, profiles!posts_user_id_fkey(*)), shared_by_profile:shared_by_id(*), recipients:shared_post_recipients(*)')
          .or('shared_by_id.eq.${currentUser.id},recipients.recipient_id.eq.${currentUser.id}')
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => SharedPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch shared posts: $e');
    }
  }

  Future<List<SharedPost>> getPostsSharedByUser() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final data = await _client
          .from('shared_posts')
          .select(
              '*, original_post:original_post_id(*, profiles!posts_user_id_fkey(*)), recipients:shared_post_recipients(*)')
          .eq('shared_by_id', currentUser.id)
          .order('created_at', ascending: false);

      return (data as List)
          .map((e) => SharedPost.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch posts shared by user: $e');
    }
  }

  Future<void> markSharedPostAsRead(String sharedPostId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      await _client
          .from('shared_post_recipients')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('shared_post_id', sharedPostId)
          .eq('recipient_id', currentUser.id);
    } catch (e) {
      throw Exception('Failed to mark shared post as read: $e');
    }
  }

  Future<int> getUnreadSharedPostsCount() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final response = await _client
          .from('shared_post_recipients')
          .select('id')
          .eq('recipient_id', currentUser.id)
          .eq('is_read', false)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('Failed to get unread shared posts count: $e');
    }
  }

  Future<void> deleteSharedPost(String sharedPostId) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final sharedPost = await _client
          .from('shared_posts')
          .select()
          .eq('id', sharedPostId)
          .eq('shared_by_id', currentUser.id)
          .maybeSingle();

      if (sharedPost == null) {
        throw Exception('Shared post not found or access denied');
      }

      await _client.from('shared_posts').delete().eq('id', sharedPostId);
    } catch (e) {
      throw Exception('Failed to delete shared post: $e');
    }
  }

  Future<List<Profile>> getFollowersForSharing() async {
    final currentUser = _client.auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    try {
      final data = await _client
          .from('follows')
          .select('profiles!follows_follower_id_fkey(*)')
          .eq('following_id', currentUser.id);

      final followers = (data as List)
          .map((e) => Profile.fromJson(e['profiles'] as Map<String, dynamic>))
          .toList();

      return followers;
    } catch (e) {
      throw Exception('Failed to fetch followers: $e');
    }
  }

  Future<int> getShareCountForPost(String postId) async {
    try {
      final response = await _client
          .from('shared_posts')
          .select('id')
          .eq('original_post_id', postId)
          .count(CountOption.exact);
      return response.count;
    } catch (e) {
      throw Exception('Failed to get share count: $e');
    }
  }

  Future<Post?> fetchPostById(String postId) async {
    try {
      final data = await _client
          .from('posts')
          .select(
              '*, profiles!posts_user_id_fkey(*), post_likes(*), comments(*)')
          .eq('id', postId)
          .maybeSingle();
      return data != null ? Post.fromJson(data) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Reel?> fetchReelById(String reelId) async {
    try {
      final data = await _client
          .from('reels')
          .select(
              '*, profiles!reels_user_id_fkey(*), reel_likes(*), reel_comments(*)')
          .eq('id', reelId)
          .maybeSingle();
      return data != null ? Reel.fromJson(data) : null;
    } catch (e) {
      return null;
    }
  }
}
