import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/models/community/community_member.dart';
import 'package:gamer_flick/models/community/community_chat_message.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';

abstract class ICommunityRepository {
  Future<List<Community>> fetchCommunities();
  Future<Community?> getCommunityById(String id);
  Future<Community> createCommunity(Community community);
  Future<bool> updateCommunity(Community community);
  Future<bool> deleteCommunity(String id);
  Future<bool> joinCommunity(String communityId, String userId);
  Future<bool> leaveCommunity(String communityId, String userId);
  Future<List<CommunityMember>> getCommunityMembers(String communityId);
  Future<List<CommunityChatMessage>> getCommunityMessages(String communityId, {int limit = 50, int offset = 0});
  Stream<List<CommunityChatMessage>> subscribeToMessages(String communityId);
  Future<List<Community>> searchCommunities({String? query, String? gameCategory, int limit = 20});
  Future<List<Community>> fetchTrendingCommunities({int limit = 10});
  Future<List<Community>> fetchNewestCommunities({int limit = 10});
  Future<List<Community>> fetchPopularCommunities({int limit = 10});
  Future<List<Community>> getRecommendedCommunities(String userId, {int limit = 10});
  Future<List<Community>> getCommunitiesByCategory(String category, {int limit = 20});
  Future<bool> updateCommunitySettings(String communityId, Map<String, dynamic> settings);
  Future<bool> updateMemberRole(String communityId, String userId, String role);
  Future<bool> banMember(String communityId, String userId);
  Future<bool> unbanMember(String communityId, String userId);
  Future<bool> removeMember(String communityId, String userId);
  Future<Map<String, dynamic>> getCommunityStats(String communityId);
}

class SupabaseCommunityRepository implements ICommunityRepository {
  final SupabaseClient _client;
  final NetworkService _networkService;
  final ErrorReportingService _errorReportingService;

  SupabaseCommunityRepository({
    SupabaseClient? client,
    NetworkService? networkService,
    ErrorReportingService? errorReportingService,
  })  : _client = client ?? Supabase.instance.client,
        _networkService = networkService ?? NetworkService(),
        _errorReportingService = errorReportingService ?? ErrorReportingService();

  @override
  Future<List<Community>> fetchCommunities() async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.fetchCommunities',
      operation: () async {
        try {
          final response = await _client
              .from('communities')
              .select()
              .order('created_at', ascending: false);
          return (response as List)
              .map((data) => Community.fromJson(data as Map<String, dynamic>))
              .toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to fetch communities: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<Community?> getCommunityById(String id) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getCommunityById',
      operation: () async {
        try {
          final response = await _client.from('communities').select().eq('id', id).single();
          return Community.fromJson(response);
        } catch (e) {
          _errorReportingService.reportError('Failed to get community by id: $e', null);
          return null;
        }
      },
    );
  }

  @override
  Future<Community> createCommunity(Community community) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.createCommunity',
      operation: () async {
        try {
          final response = await _client
              .from('communities')
              .insert(community.toInsertMap())
              .select()
              .single();
          
          final newCommunity = Community.fromJson(response);
          
          // Add creator as owner
          await _client.from('community_members').insert({
            'community_id': newCommunity.id,
            'user_id': community.createdBy,
            'role': 'owner',
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });

          return newCommunity;
        } catch (e) {
          _errorReportingService.reportError('Failed to create community: $e', null);
          rethrow;
        }
      },
    );
  }

  @override
  Future<bool> updateCommunity(Community community) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.updateCommunity',
      operation: () async {
        try {
          await _client.from('communities').update(community.toJson()).eq('id', community.id);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to update community: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> deleteCommunity(String id) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.deleteCommunity',
      operation: () async {
        try {
          await _client.from('communities').delete().eq('id', id);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to delete community: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> joinCommunity(String communityId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.joinCommunity',
      operation: () async {
        try {
          await _client.from('community_members').upsert({
            'community_id': communityId,
            'user_id': userId,
            'role': 'member',
            'joined_at': DateTime.now().toUtc().toIso8601String(),
          });
          
          await _client.rpc('increment_community_member_count', params: {
            'community_id': communityId,
          });
          
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to join community: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> leaveCommunity(String communityId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.leaveCommunity',
      operation: () async {
        try {
          await _client
              .from('community_members')
              .delete()
              .eq('community_id', communityId)
              .eq('user_id', userId);

          await _client.rpc('decrement_community_member_count', params: {
            'community_id': communityId,
          });
          
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to leave community: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<List<CommunityMember>> getCommunityMembers(String communityId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getCommunityMembers',
      operation: () async {
        try {
          final response = await _client.from('community_members').select('''
                *,
                profiles(id, username, avatar_url, full_name)
              ''').eq('community_id', communityId);
          return (response as List).map((data) => CommunityMember.fromMap(data as Map<String, dynamic>)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to get community members: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<List<CommunityChatMessage>> getCommunityMessages(String communityId, {int limit = 50, int offset = 0}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getCommunityMessages',
      operation: () async {
        try {
          final response = await _client
              .from('community_chat_messages')
              .select('''
                *,
                sender:profiles(id, username, avatar_url)
              ''')
              .eq('community_id', communityId)
              .order('created_at', ascending: false)
              .range(offset, offset + limit - 1);
          return (response as List).map((data) => CommunityChatMessage.fromMap(data as Map<String, dynamic>)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to get community messages: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Stream<List<CommunityChatMessage>> subscribeToMessages(String communityId) {
    return _client
        .from('community_chat_messages')
        .stream(primaryKey: ['id'])
        .eq('community_id', communityId)
        .order('created_at', ascending: false)
        .map((response) => (response as List).map((data) => CommunityChatMessage.fromMap(data as Map<String, dynamic>)).toList());
  }

  @override
  Future<List<Community>> searchCommunities({String? query, String? gameCategory, int limit = 20}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.searchCommunities',
      operation: () async {
        try {
          var request = _client.from('communities').select();
          if (query != null && query.isNotEmpty) {
            request = request.or('name.ilike.%$query%,description.ilike.%$query%');
          }
          if (gameCategory != null && gameCategory.isNotEmpty) {
            request = request.eq('game_category', gameCategory);
          }
          final response = await request.limit(limit);
          return (response as List).map((data) => Community.fromJson(data)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to search communities: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<List<Community>> fetchTrendingCommunities({int limit = 10}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.fetchTrendingCommunities',
      operation: () async {
        try {
          final response = await _client
              .from('communities')
              .select()
              .order('member_count', ascending: false)
              .limit(limit);
          return (response as List).map((data) => Community.fromJson(data)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to fetch trending communities: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<List<Community>> fetchNewestCommunities({int limit = 10}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.fetchNewestCommunities',
      operation: () async {
        try {
          final response = await _client
              .from('communities')
              .select()
              .order('created_at', ascending: false)
              .limit(limit);
          return (response as List).map((data) => Community.fromJson(data)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to fetch newest communities: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<List<Community>> fetchPopularCommunities({int limit = 10}) async {
    return fetchTrendingCommunities(limit: limit); // Same logic for now
  }

  @override
  Future<List<Community>> getRecommendedCommunities(String userId, {int limit = 10}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getRecommendedCommunities',
      operation: () async {
        try {
          final userCommunities = await _client
              .from('community_members')
              .select('community_id')
              .eq('user_id', userId);

          final userCommunityIds = (userCommunities as List)
              .map((data) => data['community_id'] as String)
              .toList();

          var request = _client.from('communities').select();
          if (userCommunityIds.isNotEmpty) {
            request = request.not('id', 'in', '(${userCommunityIds.join(',')})');
          }

          final response = await request.order('member_count', ascending: false).limit(limit);
          return (response as List).map((data) => Community.fromJson(data)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to get recommended communities: $e', null);
          return fetchTrendingCommunities(limit: limit);
        }
      },
    );
  }

  @override
  Future<List<Community>> getCommunitiesByCategory(String category, {int limit = 20}) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getCommunitiesByCategory',
      operation: () async {
        try {
          final response = await _client
              .from('communities')
              .select()
              .contains('tags', [category])
              .order('member_count', ascending: false)
              .limit(limit);
          return (response as List).map((data) => Community.fromJson(data)).toList();
        } catch (e) {
          _errorReportingService.reportError('Failed to get communities by category: $e', null);
          return [];
        }
      },
    );
  }

  @override
  Future<bool> updateCommunitySettings(String communityId, Map<String, dynamic> settings) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.updateCommunitySettings',
      operation: () async {
        try {
          await _client.from('communities').update(settings).eq('id', communityId);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to update community settings: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getCommunityStats(String communityId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.getCommunityStats',
      operation: () async {
        try {
          final results = await Future.wait([
            _client.from('community_members').select('id').eq('community_id', communityId).count(CountOption.exact),
            _client.from('community_chat_messages').select('id').eq('community_id', communityId).count(CountOption.exact),
          ]);
          return {
            'member_count': (results[0] as PostgrestFilterBuilder).count,
            'message_count': (results[1] as PostgrestFilterBuilder).count,
          };
        } catch (e) {
          return {'member_count': 0, 'message_count': 0};
        }
      },
    );
  }

  @override
  Future<bool> updateMemberRole(String communityId, String userId, String role) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.updateMemberRole',
      operation: () async {
        try {
          await _client
              .from('community_members')
              .update({'role': role})
              .eq('community_id', communityId)
              .eq('user_id', userId);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to update member role: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> banMember(String communityId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.banMember',
      operation: () async {
        try {
          await _client
              .from('community_members')
              .update({'is_banned': true})
              .eq('community_id', communityId)
              .eq('user_id', userId);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to ban member: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> unbanMember(String communityId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.unbanMember',
      operation: () async {
        try {
          await _client
              .from('community_members')
              .update({'is_banned': false})
              .eq('community_id', communityId)
              .eq('user_id', userId);
          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to unban member: $e', null);
          return false;
        }
      },
    );
  }

  @override
  Future<bool> removeMember(String communityId, String userId) async {
    return _networkService.executeWithRetry(
      operationName: 'CommunityRepository.removeMember',
      operation: () async {
        try {
          await _client
              .from('community_members')
              .delete()
              .eq('community_id', communityId)
              .eq('user_id', userId);
          
          await _client.rpc('decrement_community_member_count', params: {
            'community_id': communityId,
          });

          return true;
        } catch (e) {
          _errorReportingService.reportError('Failed to remove member: $e', null);
          return false;
        }
      },
    );
  }
}
