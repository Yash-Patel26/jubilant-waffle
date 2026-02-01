import 'package:flutter/material.dart';
import 'package:gamer_flick/models/community/community_role.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRoleProvider extends ChangeNotifier {
  List<CommunityRole> _roles = [];
  final Map<String, String> _memberRoles = {}; // userId -> role mapping
  bool _isLoading = false;
  String? _error;

  List<CommunityRole> get roles => _roles;
  Map<String, String> get memberRoles => _memberRoles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String getMemberRole(String userId) {
    return _memberRoles[userId] ?? 'member';
  }

  Future<void> loadRoles(String communityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Load predefined roles
      _roles = [
        CommunityRole(
          id: 'admin',
          communityId: communityId,
          name: 'admin',
          isDefault: false,
          permissions: [
            'can_pin_posts',
            'can_ban_members',
            'can_edit_settings',
            'can_create_events'
          ],
        ),
        CommunityRole(
          id: 'moderator',
          communityId: communityId,
          name: 'moderator',
          isDefault: false,
          permissions: ['can_pin_posts', 'can_ban_members'],
        ),
        CommunityRole(
          id: 'member',
          communityId: communityId,
          name: 'member',
          isDefault: true,
          permissions: [],
        ),
      ];

      // Load current member roles
      try {
        // First check if current user is a member
        final currentUserMembership = await client
            .from('community_members')
            .select('role')
            .eq('community_id', communityId)
            .eq('user_id', currentUser.id)
            .maybeSingle();

        if (currentUserMembership == null) {
          throw Exception('You are not a member of this community');
        }

        // Load all member roles
        final membersResponse = await client
            .from('community_members')
            .select('user_id, role')
            .eq('community_id', communityId);

        _memberRoles.clear();
        for (final member in membersResponse as List) {
          _memberRoles[member['user_id'] as String] = member['role'] as String;
        }
      } catch (e) {
        // If we can't load member roles, initialize with empty map
        _memberRoles.clear();
        print('Warning: Could not load member roles: $e');
        _error = 'Could not load member roles: ${e.toString()}';
      }
    } catch (e) {
      _error = 'Failed to load roles: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addRole(CommunityRole role) async {
    // TODO: Add to backend
    _roles.add(role);
    notifyListeners();
  }

  Future<void> updateRole(CommunityRole role) async {
    // TODO: Update in backend
    final idx = _roles.indexWhere((r) => r.id == role.id);
    if (idx != -1) {
      _roles[idx] = role;
      notifyListeners();
    }
  }

  Future<void> deleteRole(String roleId) async {
    // TODO: Delete from backend
    _roles.removeWhere((r) => r.id == roleId);
    notifyListeners();
  }

  Future<void> assignRoleToMember(
      String communityId, String userId, String role) async {
    try {
      _error = null; // Clear previous errors
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if current user has permission to assign roles
      final currentUserRole = await client
          .from('community_members')
          .select('role')
          .eq('community_id', communityId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (currentUserRole == null) {
        throw Exception('You are not a member of this community');
      }

      final currentRole = currentUserRole['role'] as String;
      if (currentRole != 'admin' && currentRole != 'owner') {
        throw Exception('Only admins can assign roles');
      }

      // First check if the member exists
      final existingMember = await client
          .from('community_members')
          .select('id')
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existingMember == null) {
        throw Exception('Member not found in community');
      }

      // Update the role in the database
      await client
          .from('community_members')
          .update({'role': role})
          .eq('community_id', communityId)
          .eq('user_id', userId);

      // Update local state
      _memberRoles[userId] = role;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to assign role: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh roles and member data
  Future<void> refresh(String communityId) async {
    await loadRoles(communityId);
  }
}
