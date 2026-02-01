import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community_member.dart';

class CommunityMemberService {
  final SupabaseClient _client = Supabase.instance.client;
  final String table = 'community_members';

  Future<List<CommunityMember>> fetchMembers(String communityId) async {
    final response = await _client
        .from(table)
        .select()
        .eq('community_id', communityId)
        .order('joined_at', ascending: true);
    return (response as List)
        .map((data) => CommunityMember.fromMap(data as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRole(
      String communityId, String userId, String newRole) async {
    await _client.from(table).update({'role': newRole}).match({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  Future<void> banMember(String communityId, String userId) async {
    await _client.from(table).update({'is_banned': true}).match({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  Future<void> unbanMember(String communityId, String userId) async {
    await _client.from(table).update({'is_banned': false}).match({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  Future<void> removeMember(String communityId, String userId) async {
    await _client.from(table).delete().match({
      'community_id': communityId,
      'user_id': userId,
    });
  }

  Future<bool> isUserMember(String communityId, String userId) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<CommunityMember?> getUserMembership(
      String communityId, String userId) async {
    try {
      final response = await _client
          .from(table)
          .select()
          .eq('community_id', communityId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null ? CommunityMember.fromMap(response) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isUserMemberOfAnyCommunity(String userId) async {
    try {
      final response = await _client
          .from(table)
          .select('id')
          .eq('user_id', userId)
          .limit(1)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> getUserCommunityIds(String userId) async {
    try {
      final response = await _client
          .from(table)
          .select('community_id')
          .eq('user_id', userId);
      return (response as List)
          .map((data) => data['community_id'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
