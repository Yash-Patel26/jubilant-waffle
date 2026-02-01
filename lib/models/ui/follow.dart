class Follow {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime createdAt;
  final Map<String, dynamic>? follower;
  final Map<String, dynamic>? following;

  Follow({
    required this.id,
    required this.followerId,
    required this.followingId,
    required this.createdAt,
    this.follower,
    this.following,
  });

  factory Follow.fromMap(Map<String, dynamic> map) {
    return Follow(
      id: map['id'] as String,
      followerId: map['follower_id'] as String,
      followingId: map['following_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      follower: map['follower'] as Map<String, dynamic>?,
      following: map['following'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'follower_id': followerId,
      'following_id': followingId,
      'created_at': createdAt.toIso8601String(),
      'follower': follower,
      'following': following,
    };
  }

  String? get followerUsername => follower?['username'] as String?;
  String? get followerAvatarUrl => follower?['avatar_url'] as String?;
  String? get followingUsername => following?['username'] as String?;
  String? get followingAvatarUrl => following?['avatar_url'] as String?;

  // JSON serialization methods
  factory Follow.fromJson(Map<String, dynamic> json) => Follow.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
