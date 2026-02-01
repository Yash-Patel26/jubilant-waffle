import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/models/community/community_member.dart';
import 'package:gamer_flick/models/community/community_role.dart';
import 'package:gamer_flick/utils/error_handler.dart';
import 'package:gamer_flick/models/community/community_chat_message.dart';

class EnhancedCommunityService {
  static final EnhancedCommunityService _instance =
      EnhancedCommunityService._internal();
  factory EnhancedCommunityService() => _instance;
  EnhancedCommunityService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// Create community with role assignment
  Future<Community> createCommunity({
    required String name,
    required String description,
    required String gameCategory,
    required String createdBy,
    bool isPrivate = false,
    List<String>? tags,
    Map<String, dynamic>? settings,
    List<String>? initialMembers,
  }) async {
    try {
      // Create community
      final communityData = {
        'name': name,
        'description': description,
        'game_category': gameCategory,
        'created_by': createdBy,
        'is_private': isPrivate,
        'tags': tags ?? [],
        'settings': settings ?? {},
        'member_count': 1, // Creator is first member
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await _client
          .from('communities')
          .insert(communityData)
          .select()
          .single();

      final community = Community.fromJson(response);

      // Add creator as owner
      await _addMemberWithRole(
        communityId: community.id,
        userId: createdBy,
        role: 'owner',
      );

      // Add initial members if provided
      if (initialMembers != null) {
        for (final memberId in initialMembers) {
          if (memberId != createdBy) {
            await _addMemberWithRole(
              communityId: community.id,
              userId: memberId,
              role: 'member',
            );
          }
        }
      }

      return community;
    } catch (e) {
      ErrorHandler.logError('Failed to create community', e);
      rethrow;
    }
  }

  /// Add member with specific role
  Future<void> _addMemberWithRole({
    required String communityId,
    required String userId,
    required String role,
  }) async {
    try {
      // Add to community_members table
      await _client.from('community_members').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': role,
        'joined_at': DateTime.now().toUtc().toIso8601String(),
        'status': 'active',
      });

      // Add to community_roles table for role-specific permissions
      await _client.from('community_roles').insert({
        'community_id': communityId,
        'user_id': userId,
        'role': role,
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update member count
      await _client.rpc('increment_community_member_count', params: {
        'community_id': communityId,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to add member with role', e);
      rethrow;
    }
  }

  /// Join community
  Future<void> joinCommunity({
    required String communityId,
    required String userId,
  }) async {
    try {
      // Check if user is already a member
      final existingMember = await _client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember != null) {
        throw Exception('User is already a member of this community');
      }

      // Check if community is private
      final community = await _client
          .from('communities')
          .select('is_private')
          .eq('id', communityId)
          .single();

      if (community['is_private']) {
        // Create join request for private communities
        await _createJoinRequest(communityId, userId);
      } else {
        // Direct join for public communities
        await _addMemberWithRole(
          communityId: communityId,
          userId: userId,
          role: 'member',
        );
      }
    } catch (e) {
      ErrorHandler.logError('Failed to join community', e);
      rethrow;
    }
  }

  /// Create join request for private community
  Future<void> _createJoinRequest(String communityId, String userId) async {
    try {
      await _client.from('community_join_requests').insert({
        'community_id': communityId,
        'user_id': userId,
        'status': 'pending',
        'requested_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to create join request', e);
      rethrow;
    }
  }

  /// Approve join request
  Future<void> approveJoinRequest({
    required String requestId,
    required String approvedBy,
  }) async {
    try {
      // Check if user has permission to approve requests
      final hasPermission = await _hasRolePermission(
        communityId: await _getCommunityIdFromRequest(requestId),
        userId: approvedBy,
        requiredRoles: ['admin', 'owner'],
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to approve join requests');
      }

      // Get request details
      final request = await _client
          .from('community_join_requests')
          .select('community_id, user_id')
          .eq('id', requestId)
          .single();

      // Add member
      await _addMemberWithRole(
        communityId: request['community_id'],
        userId: request['user_id'],
        role: 'member',
      );

      // Update request status
      await _client.from('community_join_requests').update({
        'status': 'approved',
        'approved_by': approvedBy,
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', requestId);
    } catch (e) {
      ErrorHandler.logError('Failed to approve join request', e);
      rethrow;
    }
  }

  /// Reject join request
  Future<void> rejectJoinRequest({
    required String requestId,
    required String rejectedBy,
  }) async {
    try {
      // Check if user has permission to reject requests
      final hasPermission = await _hasRolePermission(
        communityId: await _getCommunityIdFromRequest(requestId),
        userId: rejectedBy,
        requiredRoles: ['admin', 'owner'],
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to reject join requests');
      }

      await _client.from('community_join_requests').update({
        'status': 'rejected',
        'rejected_by': rejectedBy,
        'rejected_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', requestId);
    } catch (e) {
      ErrorHandler.logError('Failed to reject join request', e);
      rethrow;
    }
  }

  /// Get community ID from request
  Future<String> _getCommunityIdFromRequest(String requestId) async {
    final response = await _client
        .from('community_join_requests')
        .select('community_id')
        .eq('id', requestId)
        .single();
    return response['community_id'];
  }

  /// Leave community
  Future<void> leaveCommunity({
    required String communityId,
    required String userId,
  }) async {
    try {
      // Check if user is the owner
      final member = await _client
          .from('community_members')
          .select('role')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      if (member['role'] == 'owner') {
        throw Exception(
            'Owner cannot leave the community. Transfer ownership first.');
      }

      // Remove from community_members
      await _client
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Remove from community_roles
      await _client
          .from('community_roles')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Update member count
      await _client.rpc('decrement_community_member_count', params: {
        'community_id': communityId,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to leave community', e);
      rethrow;
    }
  }

  /// Assign role to member
  Future<void> assignRole({
    required String communityId,
    required String userId,
    required String newRole,
    required String assignedBy,
  }) async {
    try {
      // Check if assigner has permission
      final hasPermission = await _hasRolePermission(
        communityId: communityId,
        userId: assignedBy,
        requiredRoles: ['admin', 'owner'],
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to assign roles');
      }

      // Check if target user is a member
      final isMember = await _client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (isMember == null) {
        throw Exception('User is not a member of this community');
      }

      // Update role in community_members
      await _client
          .from('community_members')
          .update({'role': newRole})
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Update role in community_roles
      await _client.from('community_roles').upsert({
        'community_id': communityId,
        'user_id': userId,
        'role': newRole,
        'assigned_by': assignedBy,
        'assigned_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to assign role', e);
      rethrow;
    }
  }

  /// Remove member from community
  Future<void> removeMember({
    required String communityId,
    required String userId,
    required String removedBy,
  }) async {
    try {
      // Check if remover has permission
      final hasPermission = await _hasRolePermission(
        communityId: communityId,
        userId: removedBy,
        requiredRoles: ['admin', 'owner'],
      );

      if (!hasPermission) {
        throw Exception('Insufficient permissions to remove members');
      }

      // Check if target is owner
      final targetRole = await _client
          .from('community_members')
          .select('role')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .single();

      if (targetRole['role'] == 'owner') {
        throw Exception('Cannot remove the owner from the community');
      }

      // Remove from community_members
      await _client
          .from('community_members')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Remove from community_roles
      await _client
          .from('community_roles')
          .delete()
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Update member count
      await _client.rpc('decrement_community_member_count', params: {
        'community_id': communityId,
      });
    } catch (e) {
      ErrorHandler.logError('Failed to remove member', e);
      rethrow;
    }
  }

  /// Check if user has role permission
  Future<bool> _hasRolePermission({
    required String communityId,
    required String userId,
    required List<String> requiredRoles,
  }) async {
    try {
      final member = await _client
          .from('community_members')
          .select('role')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (member == null) return false;

      return requiredRoles.contains(member['role']);
    } catch (e) {
      return false;
    }
  }

  /// Get community members with roles
  Future<List<CommunityMember>> getCommunityMembers(String communityId) async {
    try {
      final response = await _client.from('community_members').select('''
            *,
            profiles!community_members_user_id_fkey(
              id,
              username,
              display_name,
              avatar_url,
              is_online,
              last_seen
            )
          ''').eq('community_id', communityId).order('joined_at');

      return (response as List)
          .map((member) => CommunityMember.fromMap(member))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get community members', e);
      return [];
    }
  }

  /// Get community roles
  Future<List<CommunityRole>> getCommunityRoles(String communityId) async {
    try {
      final response = await _client.from('community_roles').select('''
            *,
            profiles!community_roles_user_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''').eq('community_id', communityId).order('assigned_at');

      return (response as List)
          .map((role) => CommunityRole.fromMap(role))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get community roles', e);
      return [];
    }
  }

  /// Send community chat message
  Future<void> sendCommunityMessage({
    required String communityId,
    required String senderId,
    required String message,
    String? mediaUrl,
    String? mediaType,
  }) async {
    try {
      // Check if user is a member
      final isMember = await _client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('user_id', senderId)
          .maybeSingle();

      if (isMember == null) {
        throw Exception('Only members can send messages to the community');
      }

      await _client.from('community_chat_messages').insert({
        'community_id': communityId,
        'sender_id': senderId,
        'message': message,
        'media_url': mediaUrl,
        'media_type': mediaType,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed to send community message', e);
      rethrow;
    }
  }

  /// Get community chat messages
  Future<List<CommunityChatMessage>> getCommunityMessages(
    String communityId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('community_chat_messages')
          .select('''
            *,
            sender:profiles!community_chat_messages_sender_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('community_id', communityId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((message) => CommunityChatMessage.fromMap(message))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get community messages', e);
      return [];
    }
  }

  /// Get community with real-time updates
  RealtimeChannel subscribeToCommunity(String communityId) {
    return _client
        .channel('public:communities:id=eq.$communityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'communities',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: communityId,
          ),
          callback: (payload) {
            try {
              final community = Community.fromJson(
                Map<String, dynamic>.from(payload.newRecord),
              );
              // This would typically emit to a stream controller
              print('Community updated: ${community.name}');
            } catch (e) {
              ErrorHandler.logError('Failed to process community update', e);
            }
          },
        )
        .subscribe();
  }

  /// Get community chat messages with real-time updates
  RealtimeChannel subscribeToCommunityMessages(String communityId) {
    return _client
        .channel('public:community_chat_messages:community_id=eq.$communityId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'community_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'community_id',
            value: communityId,
          ),
          callback: (payload) {
            try {
              // This would typically emit to a stream controller
              print('New community message received');
            } catch (e) {
              ErrorHandler.logError(
                  'Failed to process community message update', e);
            }
          },
        )
        .subscribe();
  }

  /// Get community statistics
  Future<Map<String, dynamic>> getCommunityStats(String communityId) async {
    try {
      final members = await getCommunityMembers(communityId);
      final roles = await getCommunityRoles(communityId);
      final messages = await getCommunityMessages(communityId, limit: 1000);

      return {
        'total_members': members.length,
        'active_members': members.where((m) => m.role == 'active').length,
        'roles_distribution': roles.fold<Map<String, int>>({}, (map, role) {
          map[role.name] = (map[role.name] ?? 0) + 1;
          return map;
        }),
        'total_messages': messages.length,
        'recent_activity': messages
            .where((m) => m.createdAt
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
            .length,
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get community stats', e);
      return {};
    }
  }

  /// Search communities with advanced filters
  Future<List<Community>> searchCommunities({
    String? query,
    String? gameCategory,
    bool? isPrivate,
    int? minMembers,
    int? maxMembers,
    List<String>? tags,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var request = _client.from('communities').select('*');

      if (query != null && query.isNotEmpty) {
        request = request.or('name.ilike.%$query%,description.ilike.%$query%');
      }

      if (gameCategory != null) {
        request = request.eq('game_category', gameCategory);
      }

      if (isPrivate != null) {
        request = request.eq('is_private', isPrivate);
      }

      if (minMembers != null) {
        request = request.gte('member_count', minMembers);
      }

      if (maxMembers != null) {
        request = request.lte('member_count', maxMembers);
      }

      if (tags != null && tags.isNotEmpty) {
        request = request.contains('tags', tags);
      }

      final response = await request
          .order('member_count', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((community) => Community.fromJson(community))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search communities', e);
      return [];
    }
  }
}
