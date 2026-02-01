import 'package:flutter/material.dart';
import 'package:gamer_flick/models/community/community_invite.dart';
import 'package:gamer_flick/services/community/community_invite_service.dart';

class CommunityInviteProvider extends ChangeNotifier {
  final CommunityInviteService _service = CommunityInviteService();

  List<CommunityInvite> _invites = [];
  bool _isLoading = false;
  String? _error;

  List<CommunityInvite> get invites => _invites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInvites(String communityId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _invites = await _service.fetchInvites(communityId);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createInvite({
    required String communityId,
    required String inviterId,
    String? inviteeEmail,
    String? inviteeUserId,
    DateTime? expiresAt,
    String? role,
    String? message,
  }) async {
    try {
      await _service.createInvite(
        communityId: communityId,
        inviterId: inviterId,
        inviteeEmail: inviteeEmail,
        inviteeUserId: inviteeUserId,
        expiresAt: expiresAt,
        role: role,
        message: message,
      );
      await loadInvites(communityId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> cancelInvite(String communityId, String inviteId) async {
    await _service.cancelInvite(inviteId);
    await loadInvites(communityId);
  }

  Future<void> resendInvite(String communityId, String inviteId) async {
    await _service.resendInvite(inviteId);
    await loadInvites(communityId);
  }
}
