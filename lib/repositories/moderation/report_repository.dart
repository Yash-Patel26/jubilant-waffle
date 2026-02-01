import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IReportRepository {
  Future<void> reportContent({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  });
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  });
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  });
  Future<bool> isUserBlocked(String userId, String targetUserId);
  Future<List<String>> getBlockedUserIds(String userId);
}

class SupabaseReportRepository implements IReportRepository {
  final SupabaseClient _client = Supabase.instance.client;

  @override
  Future<void> reportContent({
    required String reporterId,
    required String targetId,
    required String targetType,
    required String reason,
    String? details,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': reporterId,
        'target_id': targetId,
        'target_type': targetType,
        'reason': reason,
        'details': details,
        'status': 'pending',
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {}
  }

  @override
  Future<void> blockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      await _client.from('user_blocks').upsert({
        'blocker_id': blockerId,
        'blocked_id': blockedId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {}
  }

  @override
  Future<void> unblockUser({
    required String blockerId,
    required String blockedId,
  }) async {
    try {
      await _client
          .from('user_blocks')
          .delete()
          .eq('blocker_id', blockerId)
          .eq('blocked_id', blockedId);
    } catch (e) {}
  }

  @override
  Future<bool> isUserBlocked(String userId, String targetUserId) async {
    try {
      final response = await _client
          .from('user_blocks')
          .select('id')
          .eq('blocker_id', userId)
          .eq('blocked_id', targetUserId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<String>> getBlockedUserIds(String userId) async {
    try {
      final response = await _client
          .from('user_blocks')
          .select('blocked_id')
          .eq('blocker_id', userId);
      return (response as List).map((e) => e['blocked_id'] as String).toList();
    } catch (e) {
      return [];
    }
  }
}

final reportRepositoryProvider = Provider<IReportRepository>((ref) {
  return SupabaseReportRepository();
});
