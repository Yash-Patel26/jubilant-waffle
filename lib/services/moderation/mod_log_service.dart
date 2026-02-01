import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:gamer_flick/models/moderation/mod_log.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Mod Log Service for tracking moderation actions
/// Provides transparency and accountability for community moderation
class ModLogService {
  static final ModLogService _instance = ModLogService._internal();
  factory ModLogService() => _instance;
  ModLogService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final _uuid = const Uuid();

  // === Log Entry Creation ===

  /// Log a moderation action
  Future<ModLogEntry?> logAction({
    required String communityId,
    required String moderatorId,
    required ModAction action,
    String? targetUserId,
    String? targetContentId,
    ModTargetType? targetType,
    String? reason,
    String? details,
    Map<String, dynamic>? previousState,
    Map<String, dynamic>? newState,
    bool isPublic = true,
  }) async {
    try {
      // Check if mod logging is enabled for this community
      final community = await _client
          .from('communities')
          .select('enable_mod_log')
          .eq('id', communityId)
          .maybeSingle();

      if (community == null || community['enable_mod_log'] == false) {
        // Mod logging disabled, still return entry but don't persist
        return ModLogEntry(
          id: _uuid.v4(),
          communityId: communityId,
          moderatorId: moderatorId,
          action: action,
          targetUserId: targetUserId,
          targetContentId: targetContentId,
          targetType: targetType,
          reason: reason,
          details: details,
          previousState: previousState,
          newState: newState,
          createdAt: DateTime.now(),
          isPublic: isPublic,
        );
      }

      final entry = ModLogEntry(
        id: _uuid.v4(),
        communityId: communityId,
        moderatorId: moderatorId,
        action: action,
        targetUserId: targetUserId,
        targetContentId: targetContentId,
        targetType: targetType,
        reason: reason,
        details: details,
        previousState: previousState,
        newState: newState,
        createdAt: DateTime.now(),
        isPublic: isPublic,
      );

      await _client.from('mod_logs').insert(entry.toJson());

      return entry;
    } catch (e) {
      ErrorHandler.logError('Failed to log moderation action', e);
      return null;
    }
  }

  // === Convenience Methods for Common Actions ===

  /// Log post removal
  Future<ModLogEntry?> logPostRemoval({
    required String communityId,
    required String moderatorId,
    required String postId,
    required String reason,
    Map<String, dynamic>? postData,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.removePost,
      targetContentId: postId,
      targetType: ModTargetType.post,
      reason: reason,
      previousState: postData,
      newState: {'removed': true},
    );
  }

  /// Log comment removal
  Future<ModLogEntry?> logCommentRemoval({
    required String communityId,
    required String moderatorId,
    required String commentId,
    required String reason,
    Map<String, dynamic>? commentData,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.removeComment,
      targetContentId: commentId,
      targetType: ModTargetType.comment,
      reason: reason,
      previousState: commentData,
      newState: {'removed': true},
    );
  }

  /// Log user ban
  Future<ModLogEntry?> logUserBan({
    required String communityId,
    required String moderatorId,
    required String targetUserId,
    required String reason,
    int? banDurationDays,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.banUser,
      targetUserId: targetUserId,
      targetType: ModTargetType.user,
      reason: reason,
      details: banDurationDays != null
          ? 'Ban duration: $banDurationDays days'
          : 'Permanent ban',
      newState: {
        'is_banned': true,
        'ban_duration_days': banDurationDays,
      },
    );
  }

  /// Log user unban
  Future<ModLogEntry?> logUserUnban({
    required String communityId,
    required String moderatorId,
    required String targetUserId,
    String? reason,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.unbanUser,
      targetUserId: targetUserId,
      targetType: ModTargetType.user,
      reason: reason ?? 'Ban lifted',
      newState: {'is_banned': false},
    );
  }

  /// Log post lock/unlock
  Future<ModLogEntry?> logPostLock({
    required String communityId,
    required String moderatorId,
    required String postId,
    required bool locked,
    String? reason,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: locked ? ModAction.lockPost : ModAction.unlockPost,
      targetContentId: postId,
      targetType: ModTargetType.post,
      reason: reason,
      newState: {'locked': locked},
    );
  }

  /// Log post pin/unpin
  Future<ModLogEntry?> logPostPin({
    required String communityId,
    required String moderatorId,
    required String postId,
    required bool pinned,
    String? reason,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: pinned ? ModAction.pinPost : ModAction.unpinPost,
      targetContentId: postId,
      targetType: ModTargetType.post,
      reason: reason,
      newState: {'pinned': pinned},
    );
  }

  /// Log role change
  Future<ModLogEntry?> logRoleChange({
    required String communityId,
    required String moderatorId,
    required String targetUserId,
    required String previousRole,
    required String newRole,
    String? reason,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.changeUserRole,
      targetUserId: targetUserId,
      targetType: ModTargetType.user,
      reason: reason,
      previousState: {'role': previousRole},
      newState: {'role': newRole},
    );
  }

  /// Log settings update
  Future<ModLogEntry?> logSettingsUpdate({
    required String communityId,
    required String moderatorId,
    required Map<String, dynamic> previousSettings,
    required Map<String, dynamic> newSettings,
    String? details,
  }) async {
    return logAction(
      communityId: communityId,
      moderatorId: moderatorId,
      action: ModAction.updateCommunitySettings,
      targetType: ModTargetType.community,
      details: details,
      previousState: previousSettings,
      newState: newSettings,
      isPublic: false, // Settings changes typically not public
    );
  }

  // === Log Retrieval ===

  /// Get mod log entries for a community
  Future<List<ModLogEntry>> getModLog({
    required String communityId,
    ModLogFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('mod_logs')
          .select('*')
          .eq('community_id', communityId);

      // Apply filters
      if (filter != null) {
        if (filter.action != null) {
          query = query.eq('action', filter.action!.name);
        }
        if (filter.moderatorId != null) {
          query = query.eq('moderator_id', filter.moderatorId!);
        }
        if (filter.targetUserId != null) {
          query = query.eq('target_user_id', filter.targetUserId!);
        }
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
        if (!filter.includePrivate) {
          query = query.eq('is_public', true);
        }
      } else {
        query = query.eq('is_public', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((data) => ModLogEntry.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get mod log', e);
      return [];
    }
  }

  /// Get mod log with moderator and target user info
  Future<List<Map<String, dynamic>>> getModLogWithDetails({
    required String communityId,
    ModLogFilter? filter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client.from('mod_logs').select('''
            *,
            moderator:profiles!mod_logs_moderator_id_fkey(
              id,
              username,
              avatar_url
            ),
            target_user:profiles!mod_logs_target_user_id_fkey(
              id,
              username,
              avatar_url
            )
          ''').eq('community_id', communityId);

      // Apply filters
      if (filter != null) {
        if (filter.action != null) {
          query = query.eq('action', filter.action!.name);
        }
        if (!filter.includePrivate) {
          query = query.eq('is_public', true);
        }
      } else {
        query = query.eq('is_public', true);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      ErrorHandler.logError('Failed to get mod log with details', e);
      return [];
    }
  }

  /// Get mod actions by a specific moderator
  Future<List<ModLogEntry>> getModeratorActions({
    required String communityId,
    required String moderatorId,
    int limit = 50,
  }) async {
    return getModLog(
      communityId: communityId,
      filter: ModLogFilter(
        moderatorId: moderatorId,
        includePrivate: true,
      ),
      limit: limit,
    );
  }

  /// Get mod actions against a specific user
  Future<List<ModLogEntry>> getUserModHistory({
    required String communityId,
    required String targetUserId,
    int limit = 50,
  }) async {
    return getModLog(
      communityId: communityId,
      filter: ModLogFilter(
        targetUserId: targetUserId,
        includePrivate: true,
      ),
      limit: limit,
    );
  }

  // === Statistics ===

  /// Get mod log statistics for a community
  Future<Map<String, dynamic>> getModLogStatistics({
    required String communityId,
    int daysBack = 30,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysBack));

      final response = await _client
          .from('mod_logs')
          .select('*')
          .eq('community_id', communityId)
          .gte('created_at', cutoffDate.toIso8601String());

      final entries = (response as List)
          .map((data) => ModLogEntry.fromJson(data as Map<String, dynamic>))
          .toList();

      // Calculate statistics
      final actionCounts = <String, int>{};
      final moderatorCounts = <String, int>{};

      for (final entry in entries) {
        final actionKey = entry.action.displayName;
        actionCounts[actionKey] = (actionCounts[actionKey] ?? 0) + 1;
        moderatorCounts[entry.moderatorId] =
            (moderatorCounts[entry.moderatorId] ?? 0) + 1;
      }

      // Count by category
      final categoryCounts = <String, int>{};
      for (final entry in entries) {
        final category = entry.action.category.displayName;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Most active moderators
      final sortedModerators = moderatorCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return {
        'total_actions': entries.length,
        'period_days': daysBack,
        'actions_per_day': (entries.length / daysBack).toStringAsFixed(1),
        'action_counts': actionCounts,
        'category_counts': categoryCounts,
        'top_moderators': sortedModerators.take(5).map((e) {
          return {'moderator_id': e.key, 'action_count': e.value};
        }).toList(),
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get mod log statistics', e);
      return {};
    }
  }

  // === Public Log Access ===

  /// Get public mod log for community members to view
  Future<List<ModLogEntry>> getPublicModLog({
    required String communityId,
    int limit = 25,
  }) async {
    return getModLog(
      communityId: communityId,
      filter: const ModLogFilter(includePrivate: false),
      limit: limit,
    );
  }

  /// Check if a community has mod logging enabled
  Future<bool> isModLogEnabled(String communityId) async {
    try {
      final community = await _client
          .from('communities')
          .select('enable_mod_log')
          .eq('id', communityId)
          .single();

      return community['enable_mod_log'] as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable or disable mod logging for a community
  Future<bool> setModLogEnabled({
    required String communityId,
    required bool enabled,
    required String moderatorId,
  }) async {
    try {
      await _client.from('communities').update({
        'enable_mod_log': enabled,
      }).eq('id', communityId);

      // Log this action
      await logAction(
        communityId: communityId,
        moderatorId: moderatorId,
        action: ModAction.updateCommunitySettings,
        targetType: ModTargetType.community,
        details: enabled ? 'Enabled mod logging' : 'Disabled mod logging',
        newState: {'enable_mod_log': enabled},
        isPublic: false,
      );

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to set mod log enabled', e);
      return false;
    }
  }
}
