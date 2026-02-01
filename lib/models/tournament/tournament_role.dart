class TournamentRole {
  final String id;
  final String tournamentId;
  final String userId;
  final String role; // 'owner', 'moderator', 'participant', 'spectator'
  final Map<String, dynamic> permissions;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? profile;

  TournamentRole({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.updatedAt,
    this.profile,
  });

  factory TournamentRole.fromMap(Map<String, dynamic> map) {
    return TournamentRole(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String,
      permissions: map['permissions'] as Map<String, dynamic>? ?? {},
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'role': role,
      'permissions': permissions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'profile': profile,
    };
  }

  bool get isOwner => role == 'owner';
  bool get isModerator => role == 'moderator';
  bool get isParticipant => role == 'participant';
  bool get isSpectator => role == 'spectator';

  // Permission getters
  bool get canManageTournament =>
      permissions['can_manage_tournament'] == true || isOwner;
  bool get canManageParticipants =>
      permissions['can_manage_participants'] == true || isOwner || isModerator;
  bool get canManageMatches =>
      permissions['can_manage_matches'] == true || isOwner || isModerator;
  bool get canPostAnnouncements =>
      permissions['can_post_announcements'] == true || isOwner || isModerator;
  bool get canDeleteMedia =>
      permissions['can_delete_media'] == true || isOwner || isModerator;
  bool get canFlagMedia =>
      permissions['can_flag_media'] == true || isOwner || isModerator;
  bool get canViewAllMedia =>
      permissions['can_view_all_media'] == true || isOwner || isModerator;

  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;

  // JSON serialization methods
  factory TournamentRole.fromJson(Map<String, dynamic> json) =>
      TournamentRole.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
