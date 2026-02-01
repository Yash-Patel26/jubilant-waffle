class PostLike {
  final String id;
  final String postId;
  final String userId;
  final DateTime createdAt;
  final Map<String, dynamic>? profile;

  PostLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
    this.profile,
  });

  factory PostLike.fromMap(Map<String, dynamic> map) {
    return PostLike(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  factory PostLike.fromJson(Map<String, dynamic> json) =>
      PostLike.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'profile': profile,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;
}
