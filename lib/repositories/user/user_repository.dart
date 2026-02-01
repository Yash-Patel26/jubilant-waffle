import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:gamer_flick/providers/core/supabase_provider.dart';

abstract class IUserRepository {
  Future<Profile?> getProfile(String userId);
  Future<bool> updateProfile(String userId, Map<String, dynamic> updates);
  Future<List<Profile>> searchUsers(String query, {int limit = 20});
  Future<List<Profile>> getFriendSuggestions(String userId, {int limit = 10});
  Future<bool> followUser(String targetUserId);
  Future<bool> unfollowUser(String targetUserId);
  Future<bool> isFollowing(String targetUserId);
  Future<List<Profile>> getFollowers(String userId, {int limit = 20, int offset = 0});
  Future<List<Profile>> getFollowing(String userId, {int limit = 20, int offset = 0});
  Future<Map<String, int>> getFollowCounts(String userId);
  Future<bool> blockUser(String targetUserId);
  Future<bool> unblockUser(String targetUserId);
  Future<List<Profile>> getBlockedUsers(String userId);
  Future<bool> reportUser({
    required String targetUserId,
    required String reason,
    String? description,
  });
  Future<Map<String, dynamic>> getUserStats(String userId);
  Future<List<Map<String, dynamic>>> getUserActivity(String userId, {int limit = 20});
  Future<Map<String, dynamic>> getPreferences(String userId);
  Future<bool> updatePreferences(String userId, Map<String, dynamic> preferences);
  Stream<Profile> subscribeToProfile(String userId);
  Stream<List<Map<String, dynamic>>> subscribeToFollows(String userId);
  Future<List<Profile>> getProfilesByUserIds(List<String> userIds);
  Future<List<Profile>> getSuggestedUsers(String userId, {int limit = 10});
  Future<List<Profile>> getUsersByGame(String game, {int limit = 20});
  Future<void> updateLastActive(String userId);
  Future<bool> deleteAccount(String userId);
}

class SupabaseUserRepository implements IUserRepository {
  final SupabaseClient _client;
  final NetworkService _networkService;
  final ErrorReportingService _errorReportingService;

  SupabaseUserRepository({
    required SupabaseClient client,
    NetworkService? networkService,
    ErrorReportingService? errorReportingService,
  })  : _client = client,
        _networkService = networkService ?? NetworkService(),
        _errorReportingService = errorReportingService ?? ErrorReportingService();

  @override
  Future<Profile?> getProfile(String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getProfile',
      operation: () async {
        try {
          final response = await _client.from('profiles').select('''
                *,
                followers:followers(count),
                following:following(count)
              ''').eq('id', userId).single();

          return Profile.fromJson(response);
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get profile: $e',
            null,
            context: 'UserRepository.getProfile',
            additionalData: {'userId': userId},
          );
          return null;
        }
      },
    );
  }

  @override
  Future<bool> updateProfile(String userId, Map<String, dynamic> updates) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.updateProfile',
      operation: () async {
        try {
          await _client.from('profiles').update(updates).eq('id', userId);
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to update profile: $e',
            null,
            context: 'UserRepository.updateProfile',
            additionalData: {'userId': userId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<List<Profile>> searchUsers(String query, {int limit = 20}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.searchUsers',
      operation: () async {
        try {
          final response = await _client.from('profiles').select('''
                *,
                followers:followers(count),
                following:following(count)
              ''').or('username.ilike.%$query%,full_name.ilike.%$query%').limit(limit);

          return response.map<Profile>((json) => Profile.fromJson(json)).toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to search users: $e',
            null,
            context: 'UserRepository.searchUsers',
            additionalData: {'query': query},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<List<Profile>> getFriendSuggestions(String userId, {int limit = 10}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getFriendSuggestions',
      operation: () async {
        try {
          final response = await _client
              .from('profiles')
              .select('''
                *,
                followers:followers(count),
                following:following(count)
              ''')
              .neq('id', userId)
              .not('id', 'in',
                  '(SELECT following_id FROM followers WHERE follower_id = "$userId")')
              .order('created_at', ascending: false)
              .limit(limit);

          return response.map<Profile>((json) => Profile.fromJson(json)).toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get friend suggestions: $e',
            null,
            context: 'UserRepository.getFriendSuggestions',
            additionalData: {'userId': userId},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<bool> followUser(String targetUserId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.followUser',
      operation: () async {
        try {
          final currentUserId = _client.auth.currentUser?.id;
          if (currentUserId == null) return false;

          await _client.from('followers').insert({
            'follower_id': currentUserId,
            'following_id': targetUserId,
            'created_at': DateTime.now().toIso8601String(),
          });
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to follow user: $e',
            null,
            context: 'UserRepository.followUser',
            additionalData: {'targetUserId': targetUserId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<bool> unfollowUser(String targetUserId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.unfollowUser',
      operation: () async {
        try {
          final currentUserId = _client.auth.currentUser?.id;
          if (currentUserId == null) return false;

          await _client
              .from('followers')
              .delete()
              .eq('follower_id', currentUserId)
              .eq('following_id', targetUserId);
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to unfollow user: $e',
            null,
            context: 'UserRepository.unfollowUser',
            additionalData: {'targetUserId': targetUserId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<bool> isFollowing(String targetUserId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) return false;

      final response = await _client
          .from('followers')
          .select('id')
          .eq('follower_id', currentUserId)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<Profile>> getFollowers(String userId, {int limit = 20, int offset = 0}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getFollowers',
      operation: () async {
        try {
          final response = await _client.from('followers').select('''
                follower:profiles!follower_id(
                  *,
                  followers:followers(count),
                  following:following(count)
                )
              ''').eq('following_id', userId).range(offset, offset + limit - 1);

          return response
              .map<Profile>((json) => Profile.fromJson(json['follower']))
              .toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get followers: $e',
            null,
            context: 'UserRepository.getFollowers',
            additionalData: {'userId': userId},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<List<Profile>> getFollowing(String userId, {int limit = 20, int offset = 0}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getFollowing',
      operation: () async {
        try {
          final response = await _client.from('followers').select('''
                following:profiles!following_id(
                  *,
                  followers:followers(count),
                  following:following(count)
                )
              ''').eq('follower_id', userId).range(offset, offset + limit - 1);

          return response
              .map<Profile>((json) => Profile.fromJson(json['following']))
              .toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get following: $e',
            null,
            context: 'UserRepository.getFollowing',
            additionalData: {'userId': userId},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final followersResponse = await _client
          .from('followers')
          .select('id')
          .eq('following_id', userId)
          .count(CountOption.exact);
      final followingResponse = await _client
          .from('followers')
          .select('id')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      return {
        'followers': followersResponse.count,
        'following': followingResponse.count,
      };
    } catch (e) {
      return {'followers': 0, 'following': 0};
    }
  }

  @override
  Future<bool> blockUser(String targetUserId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.blockUser',
      operation: () async {
        try {
          final currentUserId = _client.auth.currentUser?.id;
          if (currentUserId == null) return false;

          await _client.from('blocked_users').insert({
            'blocker_id': currentUserId,
            'blocked_id': targetUserId,
            'created_at': DateTime.now().toIso8601String(),
          });
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to block user: $e',
            null,
            context: 'UserRepository.blockUser',
            additionalData: {'targetUserId': targetUserId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<bool> unblockUser(String targetUserId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.unblockUser',
      operation: () async {
        try {
          final currentUserId = _client.auth.currentUser?.id;
          if (currentUserId == null) return false;

          await _client
              .from('blocked_users')
              .delete()
              .eq('blocker_id', currentUserId)
              .eq('blocked_id', targetUserId);
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to unblock user: $e',
            null,
            context: 'UserRepository.unblockUser',
            additionalData: {'targetUserId': targetUserId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<List<Profile>> getBlockedUsers(String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getBlockedUsers',
      operation: () async {
        try {
          final response = await _client.from('blocked_users').select('''
                blocked:profiles!blocked_id(
                  *,
                  followers:followers(count),
                  following:following(count)
                )
              ''').eq('blocker_id', userId);

          return response
              .map<Profile>((json) => Profile.fromJson(json['blocked']))
              .toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get blocked users: $e',
            null,
            context: 'UserRepository.getBlockedUsers',
            additionalData: {'userId': userId},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<bool> reportUser({
    required String targetUserId,
    required String reason,
    String? description,
  }) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.reportUser',
      operation: () async {
        try {
          final currentUserId = _client.auth.currentUser?.id;
          if (currentUserId == null) return false;

          await _client.from('user_reports').insert({
            'reporter_id': currentUserId,
            'reported_id': targetUserId,
            'reason': reason,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
          });
          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to report user: $e',
            null,
            context: 'UserRepository.reportUser',
            additionalData: {'targetUserId': targetUserId},
          );
          return false;
        }
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getUserStats',
      operation: () async {
        try {
          final postsCount = await _client.from('posts').select('id').eq('user_id', userId).count(CountOption.exact);
          final followersCount = await _client.from('followers').select('id').eq('following_id', userId).count(CountOption.exact);
          final followingCount = await _client.from('followers').select('id').eq('follower_id', userId).count(CountOption.exact);
          final likesList = await _client.from('post_likes').select('''
                posts!inner(user_id)
              ''').eq('posts.user_id', userId);
          final tournamentsCount = await _client.from('tournament_participants').select('id').eq('user_id', userId).count(CountOption.exact);

          return {
            'posts': postsCount.count,
            'followers': followersCount.count,
            'following': followingCount.count,
            'likes_received': (likesList as List).length,
            'tournaments': tournamentsCount.count,
          };
        } catch (e) {
          return {
            'posts': 0,
            'followers': 0,
            'following': 0,
            'likes_received': 0,
            'tournaments': 0,
          };
        }
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getUserActivity(String userId,
      {int limit = 20}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getUserActivity',
      operation: () async {
        try {
          final results = await Future.wait([
            _client
                .from('posts')
                .select('id, content, media_urls, created_at')
                .eq('user_id', userId)
                .order('created_at', ascending: false)
                .limit(limit),
            _client
                .from('tournament_participants')
                .select('''
                  tournament:tournaments(id, name, game, status),
                  created_at
                ''')
                .eq('user_id', userId)
                .order('created_at', ascending: false)
                .limit(limit),
          ]);

          final activities = <Map<String, dynamic>>[];

          for (final post in results[0] as List) {
            activities.add({
              'type': 'post',
              'data': post,
              'timestamp': post['created_at'],
            });
          }

          for (final tournament in results[1] as List) {
            activities.add({
              'type': 'tournament',
              'data': tournament,
              'timestamp': tournament['created_at'],
            });
          }

          activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
          return activities.take(limit).toList();
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to get user activity: $e',
            null,
            context: 'UserRepository.getUserActivity',
            additionalData: {'userId': userId},
          );
          return [];
        }
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getPreferences(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('notification_settings, privacy_settings, gaming_preferences')
          .eq('id', userId)
          .single();

      return {
        'notification_settings': response['notification_settings'] ?? {},
        'privacy_settings': response['privacy_settings'] ?? {},
        'gaming_preferences': response['gaming_preferences'] ?? {},
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Future<bool> updatePreferences(
      String userId, Map<String, dynamic> preferences) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.updatePreferences',
      operation: () async {
        try {
          await _client.from('profiles').update(preferences).eq('id', userId);
          return true;
        } catch (e) {
          return false;
        }
      },
    );
  }

  @override
  Stream<Profile> subscribeToProfile(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((response) => Profile.fromJson(response.first));
  }

  @override
  Stream<List<Map<String, dynamic>>> subscribeToFollows(String userId) {
    return _client
        .from('followers')
        .stream(primaryKey: ['id'])
        .eq('follower_id', userId)
        .map((response) => List<Map<String, dynamic>>.from(response));
  }

  @override
  Future<List<Profile>> getProfilesByUserIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getProfilesByUserIds',
      operation: () async {
        try {
          final response =
              await _client.from('profiles').select('*').inFilter('id', userIds);
          return (response as List).map((json) => Profile.fromJson(json)).toList();
        } catch (e) {
          return [];
        }
      },
    );
  }

  @override
  Future<bool> deleteAccount(String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.deleteAccount',
      operation: () async {
        try {
          // Comprehensive cascading cleanup
          await Future.wait([
            _client.from('followers').delete().eq('follower_id', userId),
            _client.from('followers').delete().eq('following_id', userId),
            _client.from('posts').delete().eq('user_id', userId),
            _client.from('stories').delete().eq('user_id', userId),
            _client.from('reels').delete().eq('user_id', userId),
            _client.from('comments').delete().eq('user_id', userId),
            _client.from('post_likes').delete().eq('user_id', userId),
            _client.from('saved_posts').delete().eq('user_id', userId),
            _client.from('notifications').delete().eq('user_id', userId),
            _client.from('blocked_users').delete().eq('blocker_id', userId),
            _client.from('blocked_users').delete().eq('blocked_id', userId),
            _client.from('user_reports').delete().eq('reporter_id', userId),
          ]);

          // Finally delete the profile and the auth user
          await _client.from('profiles').delete().eq('id', userId);
          
          // Note: deleting the auth user requires admin privileges or self-deletion if supported
          await _client.auth.admin.deleteUser(userId);

          return true;
        } catch (e) {
          _errorReportingService.reportError(
            'Failed to delete account: $e',
            null,
            context: 'UserRepository.deleteAccount',
            additionalData: {'userId': userId},
          );
          return false;
        }
      },
    );
  }
  @override
  Future<List<Profile>> getSuggestedUsers(String userId, {int limit = 10}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getSuggestedUsers',
      operation: () async {
        try {
          // Logic: Users that current user's following are following
          final followingResponse = await _client
              .from('followers')
              .select('following_id')
              .eq('follower_id', userId);
          
          final followingIds = (followingResponse as List).map((i) => i['following_id']).toList();
          
          if (followingIds.isEmpty) return getFriendSuggestions(userId, limit: limit);

          final response = await _client
              .from('followers')
              .select('''
                profile:profiles!following_id(
                  *,
                  followers:followers(count),
                  following:following(count)
                )
              ''')
              .inFilter('follower_id', followingIds)
              .neq('following_id', userId)
              .not('following_id', 'in', '(${followingIds.join(",")})')
              .limit(limit);

          return (response as List).map<Profile>((json) => Profile.fromJson(json['profile'])).toList();
        } catch (e) {
          return getFriendSuggestions(userId, limit: limit);
        }
      },
    );
  }

  @override
  Future<List<Profile>> getUsersByGame(String game, {int limit = 20}) async {
    return _networkService.executeWithRetry(
      operationName: 'UserRepository.getUsersByGame',
      operation: () async {
        try {
          final response = await _client
              .from('profiles')
              .select('*, followers:followers(count), following:following(count)')
              .contains('favorite_games', [game])
              .eq('is_public', true)
              .limit(limit);

          return response.map<Profile>((json) => Profile.fromJson(json)).toList();
        } catch (e) {
          return [];
        }
      },
    );
  }

  @override
  Future<void> updateLastActive(String userId) async {
    try {
      await _client.from('profiles').update({
        'last_active': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Non-critical
    }
  }
}

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseUserRepository(client: client);
});
