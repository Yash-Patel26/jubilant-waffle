import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';

abstract class IReelsRepository {
  Future<List<Reel>> getReelsFeed({int limit = 20, int offset = 0});
  Future<Reel?> createReel({
    required String videoUrl,
    required String thumbnailUrl,
    String? caption,
    String? gameTag,
    Duration? duration,
    Map<String, dynamic>? metadata,
  });
  Future<bool> toggleLike(String reelId, String userId);
  Future<bool> addComment(String reelId, String userId, String content);
  Future<List<Map<String, dynamic>>> getComments(String reelId, {int limit = 20, int offset = 0});
  Future<bool> reportReel({
    required String reelId,
    required String userId,
    required String reason,
    required String details,
  });
  Future<bool> deleteReel(String reelId, String userId);
}

class SupabaseReelsRepository implements IReelsRepository {
  final SupabaseClient _client;
  final NetworkService _networkService;
  final ErrorReportingService _errorReportingService;

  SupabaseReelsRepository({
    SupabaseClient? client,
    NetworkService? networkService,
    ErrorReportingService? errorReportingService,
  })  : _client = client ?? Supabase.instance.client,
        _networkService = networkService ?? NetworkService(),
        _errorReportingService = errorReportingService ?? ErrorReportingService();

  @override
  Future<List<Reel>> getReelsFeed({int limit = 20, int offset = 0}) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.getReelsFeed',
      operation: () async {
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

          final reels = (response as List).map((json) => Reel.fromJson(json)).toList();

          // Check if current user has liked each reel
          if (currentUser != null) {
            final reelIds = reels.map((r) => r.id).toList();
            final likesResponse = await _client
                .from('reel_likes')
                .select('reel_id')
                .eq('user_id', currentUser.id)
                .inFilter('reel_id', reelIds);
            
            final likedReelIds = (likesResponse as List).map((l) => l['reel_id'] as String).toSet();

            for (int i = 0; i < reels.length; i++) {
              if (likedReelIds.contains(reels[i].id)) {
                // Since Reel is immutable (assuming final fields), we'd need a copyWith or recreate it.
                // Recreating for now as per previous logic in PostService.
                reels[i] = Reel(
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
                  isLiked: true,
                  isSaved: reels[i].isSaved,
                  user: reels[i].user,
                );
              }
            }
          }

          return reels;
        } catch (e) {
          _errorReportingService.reportError('Failed to get reels feed: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<Reel?> createReel({
    required String videoUrl,
    required String thumbnailUrl,
    String? caption,
    String? gameTag,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.createReel',
      operation: () async {
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
          _errorReportingService.reportError('Failed to create reel: $e', null);
          return null;
        }
      },
    );
  }

  @override
  Future<bool> toggleLike(String reelId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.toggleLike',
      operation: () async {
        try {
          // Check if already liked
          final existingLike = await _client
              .from('reel_likes')
              .select('id')
              .eq('reel_id', reelId)
              .eq('user_id', userId)
              .maybeSingle();

          if (existingLike != null) {
            // Unlike
            await _client
                .from('reel_likes')
                .delete()
                .eq('reel_id', reelId)
                .eq('user_id', userId);
          } else {
            // Like
            await _client.from('reel_likes').insert({
              'reel_id': reelId,
              'user_id': userId,
              'created_at': DateTime.now().toUtc().toIso8601String(),
            });
          }

          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to toggle reel like: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> addComment(String reelId, String userId, String content) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.addComment',
      operation: () async {
        try {
          await _client.from('reel_comments').insert({
            'reel_id': reelId,
            'user_id': userId,
            'content': content,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to add reel comment: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getComments(String reelId, {int limit = 20, int offset = 0}) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.getComments',
      operation: () async {
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
          _errorReportingService.reportError('Failed to get reel comments: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<bool> reportReel({
    required String reelId,
    required String userId,
    required String reason,
    required String details,
  }) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.reportReel',
      operation: () async {
        try {
          await _client.from('reel_reports').insert({
            'reel_id': reelId,
            'reporter_id': userId,
            'reason': reason,
            'details': details,
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to report reel: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> deleteReel(String reelId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'ReelsRepository.deleteReel',
      operation: () async {
        try {
          // Verify ownership
          final reelData = await _client
              .from('reels')
              .select('user_id')
              .eq('id', reelId)
              .single();

          if (reelData['user_id'] != userId) {
            throw Exception('Not authorized to delete this reel');
          }

          // Delete related data
          await _client.from('reel_comments').delete().eq('reel_id', reelId);
          await _client.from('reel_likes').delete().eq('reel_id', reelId);
          await _client.from('reel_reports').delete().eq('reel_id', reelId);

          // Delete the reel
          await _client.from('reels').delete().eq('id', reelId);

          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to delete reel: $e', null);
          return false;
        }
      },
    );
  }
}
