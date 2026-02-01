/// Mod Log entry for tracking moderation actions
/// Provides transparency and accountability for community moderation
class ModLogEntry {
  final String id;
  final String communityId;
  final String moderatorId;
  final ModAction action;
  final String? targetUserId;
  final String? targetContentId;
  final ModTargetType? targetType;
  final String? reason;
  final String? details;
  final Map<String, dynamic>? previousState;
  final Map<String, dynamic>? newState;
  final DateTime createdAt;
  final bool isPublic;

  const ModLogEntry({
    required this.id,
    required this.communityId,
    required this.moderatorId,
    required this.action,
    this.targetUserId,
    this.targetContentId,
    this.targetType,
    this.reason,
    this.details,
    this.previousState,
    this.newState,
    required this.createdAt,
    this.isPublic = true,
  });

  factory ModLogEntry.fromJson(Map<String, dynamic> json) {
    return ModLogEntry(
      id: json['id'] as String,
      communityId: json['community_id'] as String,
      moderatorId: json['moderator_id'] as String,
      action: ModAction.values.firstWhere(
        (a) => a.name == json['action'],
        orElse: () => ModAction.other,
      ),
      targetUserId: json['target_user_id'] as String?,
      targetContentId: json['target_content_id'] as String?,
      targetType: json['target_type'] != null
          ? ModTargetType.values.firstWhere(
              (t) => t.name == json['target_type'],
              orElse: () => ModTargetType.other,
            )
          : null,
      reason: json['reason'] as String?,
      details: json['details'] as String?,
      previousState: json['previous_state'] as Map<String, dynamic>?,
      newState: json['new_state'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      isPublic: json['is_public'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'community_id': communityId,
      'moderator_id': moderatorId,
      'action': action.name,
      'target_user_id': targetUserId,
      'target_content_id': targetContentId,
      'target_type': targetType?.name,
      'reason': reason,
      'details': details,
      'previous_state': previousState,
      'new_state': newState,
      'created_at': createdAt.toIso8601String(),
      'is_public': isPublic,
    };
  }

  /// Get a human-readable description of the action
  String get actionDescription {
    final moderator = 'A moderator';
    final target = targetType?.displayName ?? 'content';

    switch (action) {
      case ModAction.removePost:
        return '$moderator removed a post';
      case ModAction.removeComment:
        return '$moderator removed a comment';
      case ModAction.lockPost:
        return '$moderator locked a post';
      case ModAction.unlockPost:
        return '$moderator unlocked a post';
      case ModAction.pinPost:
        return '$moderator pinned a post';
      case ModAction.unpinPost:
        return '$moderator unpinned a post';
      case ModAction.banUser:
        return '$moderator banned a user';
      case ModAction.unbanUser:
        return '$moderator unbanned a user';
      case ModAction.muteUser:
        return '$moderator muted a user';
      case ModAction.unmuteUser:
        return '$moderator unmuted a user';
      case ModAction.setFlair:
        return '$moderator set flair on a post';
      case ModAction.markSpoiler:
        return '$moderator marked a post as spoiler';
      case ModAction.markNsfw:
        return '$moderator marked a post as NSFW';
      case ModAction.enableContestMode:
        return '$moderator enabled contest mode';
      case ModAction.disableContestMode:
        return '$moderator disabled contest mode';
      case ModAction.approvePost:
        return '$moderator approved a post';
      case ModAction.changeUserRole:
        return '$moderator changed a user\'s role';
      case ModAction.updateCommunitySettings:
        return '$moderator updated community settings';
      case ModAction.updateCommunityRules:
        return '$moderator updated community rules';
      case ModAction.addModerator:
        return '$moderator added a new moderator';
      case ModAction.removeModerator:
        return '$moderator removed a moderator';
      case ModAction.warnUser:
        return '$moderator warned a user';
      case ModAction.other:
        return '$moderator performed an action';
    }
  }
}

/// Moderation actions
enum ModAction {
  // Content actions
  removePost,
  removeComment,
  approvePost,
  lockPost,
  unlockPost,
  pinPost,
  unpinPost,
  setFlair,
  markSpoiler,
  markNsfw,
  enableContestMode,
  disableContestMode,

  // User actions
  banUser,
  unbanUser,
  muteUser,
  unmuteUser,
  warnUser,
  changeUserRole,
  addModerator,
  removeModerator,

  // Community actions
  updateCommunitySettings,
  updateCommunityRules,

  // Other
  other,
}

extension ModActionExtension on ModAction {
  String get displayName {
    switch (this) {
      case ModAction.removePost:
        return 'Remove Post';
      case ModAction.removeComment:
        return 'Remove Comment';
      case ModAction.approvePost:
        return 'Approve Post';
      case ModAction.lockPost:
        return 'Lock Post';
      case ModAction.unlockPost:
        return 'Unlock Post';
      case ModAction.pinPost:
        return 'Pin Post';
      case ModAction.unpinPost:
        return 'Unpin Post';
      case ModAction.setFlair:
        return 'Set Flair';
      case ModAction.markSpoiler:
        return 'Mark Spoiler';
      case ModAction.markNsfw:
        return 'Mark NSFW';
      case ModAction.enableContestMode:
        return 'Enable Contest Mode';
      case ModAction.disableContestMode:
        return 'Disable Contest Mode';
      case ModAction.banUser:
        return 'Ban User';
      case ModAction.unbanUser:
        return 'Unban User';
      case ModAction.muteUser:
        return 'Mute User';
      case ModAction.unmuteUser:
        return 'Unmute User';
      case ModAction.warnUser:
        return 'Warn User';
      case ModAction.changeUserRole:
        return 'Change Role';
      case ModAction.addModerator:
        return 'Add Moderator';
      case ModAction.removeModerator:
        return 'Remove Moderator';
      case ModAction.updateCommunitySettings:
        return 'Update Settings';
      case ModAction.updateCommunityRules:
        return 'Update Rules';
      case ModAction.other:
        return 'Other Action';
    }
  }

  ModActionCategory get category {
    switch (this) {
      case ModAction.removePost:
      case ModAction.removeComment:
      case ModAction.approvePost:
      case ModAction.lockPost:
      case ModAction.unlockPost:
      case ModAction.pinPost:
      case ModAction.unpinPost:
      case ModAction.setFlair:
      case ModAction.markSpoiler:
      case ModAction.markNsfw:
      case ModAction.enableContestMode:
      case ModAction.disableContestMode:
        return ModActionCategory.content;

      case ModAction.banUser:
      case ModAction.unbanUser:
      case ModAction.muteUser:
      case ModAction.unmuteUser:
      case ModAction.warnUser:
      case ModAction.changeUserRole:
      case ModAction.addModerator:
      case ModAction.removeModerator:
        return ModActionCategory.user;

      case ModAction.updateCommunitySettings:
      case ModAction.updateCommunityRules:
        return ModActionCategory.community;

      case ModAction.other:
        return ModActionCategory.other;
    }
  }
}

/// Categories of moderation actions
enum ModActionCategory {
  content,
  user,
  community,
  other,
}

extension ModActionCategoryExtension on ModActionCategory {
  String get displayName {
    switch (this) {
      case ModActionCategory.content:
        return 'Content';
      case ModActionCategory.user:
        return 'Users';
      case ModActionCategory.community:
        return 'Community';
      case ModActionCategory.other:
        return 'Other';
    }
  }
}

/// Target type for mod actions
enum ModTargetType {
  post,
  comment,
  user,
  community,
  other,
}

extension ModTargetTypeExtension on ModTargetType {
  String get displayName {
    switch (this) {
      case ModTargetType.post:
        return 'post';
      case ModTargetType.comment:
        return 'comment';
      case ModTargetType.user:
        return 'user';
      case ModTargetType.community:
        return 'community';
      case ModTargetType.other:
        return 'content';
    }
  }
}

/// Mod log filter options
class ModLogFilter {
  final ModAction? action;
  final ModActionCategory? category;
  final String? moderatorId;
  final String? targetUserId;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool includePrivate;

  const ModLogFilter({
    this.action,
    this.category,
    this.moderatorId,
    this.targetUserId,
    this.startDate,
    this.endDate,
    this.includePrivate = false,
  });
}
