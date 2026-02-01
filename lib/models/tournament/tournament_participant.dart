class TournamentParticipant {
  final String id;
  final String tournamentId;
  final String userId;
  final String? teamId;
  final String status; // 'registered', 'confirmed', 'eliminated', 'winner'
  final DateTime createdAt;
  final DateTime? joinedAt;
  final Map<String, dynamic>? profile;
  final Map<String, dynamic>? team;

  TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.userId,
    this.teamId,
    required this.status,
    required this.createdAt,
    this.joinedAt,
    this.profile,
    this.team,
  });

  factory TournamentParticipant.fromMap(Map<String, dynamic> map) {
    return TournamentParticipant(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      teamId: map['team_id'] as String?,
      status: map['status'] as String? ?? 'registered',
      createdAt: DateTime.parse(map['created_at'] as String),
      joinedAt: map['joined_at'] != null
          ? DateTime.parse(map['joined_at'] as String)
          : null,
      profile: map['profile'] as Map<String, dynamic>?,
      team: map['team'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'team_id': teamId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'joined_at': joinedAt?.toIso8601String(),
      'profile': profile,
      'team': team,
    };
  }

  bool get isSolo => teamId == null;
  bool get isTeam => teamId != null;
  bool get isConfirmed => status == 'confirmed';
  bool get isEliminated => status == 'eliminated';
  bool get isWinner => status == 'winner';
  bool get isRegistered => status == 'registered';
  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;
  String? get teamName => team?['name'] as String?;

  // JSON serialization methods
  factory TournamentParticipant.fromJson(Map<String, dynamic> json) =>
      TournamentParticipant.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
