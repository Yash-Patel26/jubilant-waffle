import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community_invite.dart';

class CommunityInviteService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'community_invites';

  Future<List<CommunityInvite>> fetchInvites(String communityId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('community_id', communityId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((data) => CommunityInvite.fromMap(data as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityInvite> createInvite({
    required String communityId,
    required String inviterId,
    String? inviteeEmail,
    String? inviteeUserId,
    DateTime? expiresAt,
    String? role,
    String? message,
  }) async {
    final response = await _client
        .from(table)
        .insert({
          'community_id': communityId,
          'inviter_id': inviterId,
          'invitee_email': inviteeEmail,
          'invitee_user_id': inviteeUserId,
          'expires_at': expiresAt?.toIso8601String(),
          'status': 'pending',
          'role': role,
          'message': message,
        })
        .select()
        .single();
    return CommunityInvite.fromMap(response);
  }

  Future<void> cancelInvite(String inviteId) async {
    await _client
        .from(table)
        .update({'status': 'cancelled'}).eq('id', inviteId);
  }

  Future<void> resendInvite(String inviteId) async {
    await _client.from(table).update({'status': 'pending'}).eq('id', inviteId);
  }

  Future<void> acceptInvite(String inviteId, String userId) async {
    await _client.from(table).update({
      'status': 'accepted',
      'accepted_at': DateTime.now().toIso8601String(),
      'invitee_user_id': userId,
    }).eq('id', inviteId);
  }

  Future<CommunityInvite?> getInviteByToken(String token) async {
    final response = await _client
        .from(table)
        .select()
        .eq('invite_link_token', token)
        .maybeSingle();
    if (response == null) return null;
    return CommunityInvite.fromMap(response);
  }
}
