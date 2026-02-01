class SavedPost {
  final String id;
  final String userId;
  final String postId;
  final DateTime createdAt;
  final Map<String, dynamic>? post;

  SavedPost({
    required this.id,
    required this.userId,
    required this.postId,
    required this.createdAt,
    this.post,
  });

  factory SavedPost.fromMap(Map<String, dynamic> map) {
    return SavedPost(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      postId: map['post_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      post: map['post'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'created_at': createdAt.toIso8601String(),
      'post': post,
    };
  }
}
