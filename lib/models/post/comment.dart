class Comment {
  final String id;
  final String postId;
  final String userId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? parentCommentId;
  final int? likeCount;
  final bool? isLiked;
  final Map<String, dynamic>? profile;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.parentCommentId,
    this.likeCount,
    this.isLiked,
    this.profile,
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'] as String,
      postId: map['post_id'] as String,
      userId: map['user_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      parentCommentId: map['parent_comment_id'] as String?,
      likeCount: map['like_count'] as int? ?? 0,
      isLiked: map['is_liked'] as bool? ?? false,
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  factory Comment.fromJson(Map<String, dynamic> json) => Comment.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'post_id': postId,
      'user_id': userId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'parent_comment_id': parentCommentId,
      'like_count': likeCount,
      'is_liked': isLiked,
      'profile': profile,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  bool get isReply => parentCommentId != null;
  bool get isTopLevel => parentCommentId == null;
  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;
  String? get profilePictureUrl => profile?['profile_picture_url'] as String?;
}
