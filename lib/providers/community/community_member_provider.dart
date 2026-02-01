import 'package:flutter/material.dart';
import 'package:gamer_flick/models/community/community_member.dart';
import 'package:gamer_flick/services/community/community_member_service.dart';

class CommunityMemberProvider extends ChangeNotifier {
  final CommunityMemberService _service = CommunityMemberService();

  List<CommunityMember> _members = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMembers(String communityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _members = await _service.fetchMembers(communityId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateRole(
      String communityId, String userId, String newRole) async {
    await _service.updateRole(communityId, userId, newRole);
    await loadMembers(communityId);
  }

  Future<void> banMember(String communityId, String userId) async {
    await _service.banMember(communityId, userId);
    await loadMembers(communityId);
  }

  Future<void> unbanMember(String communityId, String userId) async {
    await _service.unbanMember(communityId, userId);
    await loadMembers(communityId);
  }

  Future<void> removeMember(String communityId, String userId) async {
    await _service.removeMember(communityId, userId);
    await loadMembers(communityId);
  }

  Future<bool> isUserMember(String communityId, String userId) async {
    return await _service.isUserMember(communityId, userId);
  }

  Future<CommunityMember?> getUserMembership(
      String communityId, String userId) async {
    return await _service.getUserMembership(communityId, userId);
  }

  Future<bool> isUserMemberOfAnyCommunity(String userId) async {
    return await _service.isUserMemberOfAnyCommunity(userId);
  }

  Future<List<String>> getUserCommunityIds(String userId) async {
    return await _service.getUserCommunityIds(userId);
  }
}
