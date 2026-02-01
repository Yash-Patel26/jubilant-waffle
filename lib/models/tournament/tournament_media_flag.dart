class TournamentMediaFlag {
  final String id;
  final String tournamentMediaId;
  final String flaggedByUserId;
  final String reason;
  final String status; // 'pending', 'reviewed', 'resolved'
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;
  final String? resolution;
  final Map<String, dynamic>? flaggedByUser;
  final Map<String, dynamic>? reviewedByUser;

  TournamentMediaFlag({
    required this.id,
    required this.tournamentMediaId,
    required this.flaggedByUserId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reviewedAt,
    this.reviewedByUserId,
    this.resolution,
    this.flaggedByUser,
    this.reviewedByUser,
  });

  factory TournamentMediaFlag.fromMap(Map<String, dynamic> map) {
    return TournamentMediaFlag(
      id: map['id'] as String,
      tournamentMediaId: map['tournament_media_id'] as String,
      flaggedByUserId: map['flagged_by_user_id'] as String,
      reason: map['reason'] as String,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['created_at'] as String),
      reviewedAt: map['reviewed_at'] != null
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      reviewedByUserId: map['reviewed_by_user_id'] as String?,
      resolution: map['resolution'] as String?,
      flaggedByUser: map['flagged_by_user'] as Map<String, dynamic>?,
      reviewedByUser: map['reviewed_by_user'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_media_id': tournamentMediaId,
      'flagged_by_user_id': flaggedByUserId,
      'reason': reason,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'reviewed_by_user_id': reviewedByUserId,
      'resolution': resolution,
      'flagged_by_user': flaggedByUser,
      'reviewed_by_user': reviewedByUser,
    };
  }

  bool get isPending => status == 'pending';
  bool get isReviewed => status == 'reviewed';
  bool get isResolved => status == 'resolved';
  String? get flaggedByUsername => flaggedByUser?['username'] as String?;
  String? get reviewedByUsername => reviewedByUser?['username'] as String?;
}
