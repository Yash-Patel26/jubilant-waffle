class CommunityMember {
  final String userId;
  final String communityId;
  final String role; // 'member', 'admin', 'moderator'
  final DateTime joinedAt;
  final bool isBanned;

  CommunityMember({
    required this.userId,
    required this.communityId,
    required this.role,
    required this.joinedAt,
    this.isBanned = false,
  });

  factory CommunityMember.fromMap(Map<String, dynamic> map) {
    return CommunityMember(
      userId: map['user_id'] as String,
      communityId: map['community_id'] as String,
      role: map['role'] as String? ?? 'member',
      joinedAt: DateTime.parse(map['joined_at'] as String),
      isBanned: map['is_banned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'community_id': communityId,
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_banned': isBanned,
    };
  }
}
