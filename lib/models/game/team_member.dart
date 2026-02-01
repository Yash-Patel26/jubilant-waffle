class TeamMember {
  final String id;
  final String teamId;
  final String userId;
  final String role; // 'captain', 'member'
  final DateTime createdAt;
  final Map<String, dynamic>? profile;

  TeamMember({
    required this.id,
    required this.teamId,
    required this.userId,
    required this.role,
    required this.createdAt,
    this.profile,
  });

  factory TeamMember.fromMap(Map<String, dynamic> map) {
    return TeamMember(
      id: map['id'] as String,
      teamId: map['team_id'] as String,
      userId: map['user_id'] as String,
      role: map['role'] as String? ?? 'member',
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'team_id': teamId,
      'user_id': userId,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'profile': profile,
    };
  }

  bool get isCaptain => role == 'captain';
  bool get isMember => role == 'member';
  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;
}
