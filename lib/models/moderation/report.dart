/// Content Report model for flagging inappropriate content
/// Supports posts, comments, users, and communities
class ContentReport {
  final String id;
  final String reporterId;
  final ReportTargetType targetType;
  final String targetId;
  final ReportReason reason;
  final String? customReason;
  final String? description;
  final ReportStatus status;
  final String? communityId;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNotes;
  final ReportAction? actionTaken;

  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    this.customReason,
    this.description,
    this.status = ReportStatus.pending,
    this.communityId,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNotes,
    this.actionTaken,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'] as String,
      reporterId: json['reporter_id'] as String,
      targetType: ReportTargetType.values.firstWhere(
        (t) => t.name == json['target_type'],
        orElse: () => ReportTargetType.post,
      ),
      targetId: json['target_id'] as String,
      reason: ReportReason.values.firstWhere(
        (r) => r.name == json['reason'],
        orElse: () => ReportReason.other,
      ),
      customReason: json['custom_reason'] as String?,
      description: json['description'] as String?,
      status: ReportStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReportStatus.pending,
      ),
      communityId: json['community_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      reviewNotes: json['review_notes'] as String?,
      actionTaken: json['action_taken'] != null
          ? ReportAction.values.firstWhere(
              (a) => a.name == json['action_taken'],
              orElse: () => ReportAction.noAction,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporter_id': reporterId,
      'target_type': targetType.name,
      'target_id': targetId,
      'reason': reason.name,
      'custom_reason': customReason,
      'description': description,
      'status': status.name,
      'community_id': communityId,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by': reviewedBy,
      'review_notes': reviewNotes,
      'action_taken': actionTaken?.name,
    };
  }

  ContentReport copyWith({
    String? id,
    String? reporterId,
    ReportTargetType? targetType,
    String? targetId,
    ReportReason? reason,
    String? customReason,
    String? description,
    ReportStatus? status,
    String? communityId,
    DateTime? createdAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNotes,
    ReportAction? actionTaken,
  }) {
    return ContentReport(
      id: id ?? this.id,
      reporterId: reporterId ?? this.reporterId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      customReason: customReason ?? this.customReason,
      description: description ?? this.description,
      status: status ?? this.status,
      communityId: communityId ?? this.communityId,
      createdAt: createdAt ?? this.createdAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }
}

/// Type of content being reported
enum ReportTargetType {
  post,
  comment,
  user,
  community,
  message,
  reel,
  story,
}

/// Predefined report reasons
enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  violence,
  sexualContent,
  misinformation,
  selfHarm,
  copyright,
  impersonation,
  scam,
  inappropriateContent,
  breakingCommunityRules,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get displayName {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment or Bullying';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.violence:
        return 'Violence or Threats';
      case ReportReason.sexualContent:
        return 'Sexual Content';
      case ReportReason.misinformation:
        return 'Misinformation';
      case ReportReason.selfHarm:
        return 'Self-Harm or Suicide';
      case ReportReason.copyright:
        return 'Copyright Violation';
      case ReportReason.impersonation:
        return 'Impersonation';
      case ReportReason.scam:
        return 'Scam or Fraud';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.breakingCommunityRules:
        return 'Breaking Community Rules';
      case ReportReason.other:
        return 'Other';
    }
  }

  String get description {
    switch (this) {
      case ReportReason.spam:
        return 'Repetitive, unwanted, or promotional content';
      case ReportReason.harassment:
        return 'Targeted attacks or bullying behavior';
      case ReportReason.hateSpeech:
        return 'Content promoting hatred based on identity';
      case ReportReason.violence:
        return 'Threats of violence or dangerous activities';
      case ReportReason.sexualContent:
        return 'Explicit sexual content or nudity';
      case ReportReason.misinformation:
        return 'False or misleading information';
      case ReportReason.selfHarm:
        return 'Content promoting self-harm or suicide';
      case ReportReason.copyright:
        return 'Unauthorized use of copyrighted material';
      case ReportReason.impersonation:
        return 'Pretending to be someone else';
      case ReportReason.scam:
        return 'Attempts to deceive or defraud users';
      case ReportReason.inappropriateContent:
        return 'Content that violates platform guidelines';
      case ReportReason.breakingCommunityRules:
        return 'Violating specific community rules';
      case ReportReason.other:
        return 'Other reasons not listed above';
    }
  }

  int get severity {
    switch (this) {
      case ReportReason.selfHarm:
        return 5; // Highest priority
      case ReportReason.violence:
        return 5;
      case ReportReason.hateSpeech:
        return 4;
      case ReportReason.sexualContent:
        return 4;
      case ReportReason.harassment:
        return 3;
      case ReportReason.scam:
        return 3;
      case ReportReason.impersonation:
        return 3;
      case ReportReason.misinformation:
        return 2;
      case ReportReason.copyright:
        return 2;
      case ReportReason.spam:
        return 1;
      case ReportReason.inappropriateContent:
        return 2;
      case ReportReason.breakingCommunityRules:
        return 2;
      case ReportReason.other:
        return 1;
    }
  }
}

/// Report status
enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
  escalated,
}

extension ReportStatusExtension on ReportStatus {
  String get displayName {
    switch (this) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
      case ReportStatus.escalated:
        return 'Escalated';
    }
  }

  bool get isOpen {
    return this == ReportStatus.pending || this == ReportStatus.underReview;
  }
}

/// Actions that can be taken on reports
enum ReportAction {
  noAction,
  warning,
  contentRemoved,
  temporaryBan,
  permanentBan,
  contentHidden,
  userMuted,
}

extension ReportActionExtension on ReportAction {
  String get displayName {
    switch (this) {
      case ReportAction.noAction:
        return 'No Action Taken';
      case ReportAction.warning:
        return 'Warning Issued';
      case ReportAction.contentRemoved:
        return 'Content Removed';
      case ReportAction.temporaryBan:
        return 'Temporary Ban';
      case ReportAction.permanentBan:
        return 'Permanent Ban';
      case ReportAction.contentHidden:
        return 'Content Hidden';
      case ReportAction.userMuted:
        return 'User Muted';
    }
  }
}

/// User block record
class UserBlock {
  final String id;
  final String blockerId;
  final String blockedUserId;
  final DateTime createdAt;
  final String? reason;

  const UserBlock({
    required this.id,
    required this.blockerId,
    required this.blockedUserId,
    required this.createdAt,
    this.reason,
  });

  factory UserBlock.fromJson(Map<String, dynamic> json) {
    return UserBlock(
      id: json['id'] as String,
      blockerId: json['blocker_id'] as String,
      blockedUserId: json['blocked_user_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blocker_id': blockerId,
      'blocked_user_id': blockedUserId,
      'created_at': createdAt.toIso8601String(),
      'reason': reason,
    };
  }
}
