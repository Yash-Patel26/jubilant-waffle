class Reaction {
  final String id;
  final String userId;
  final String? postId;
  final String? commentId;
  final String reactionType;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.userId,
    this.postId,
    this.commentId,
    required this.reactionType,
    required this.createdAt,
  });

  factory Reaction.fromMap(Map<String, dynamic> map) {
    return Reaction(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      postId: map['post_id'] as String?,
      commentId: map['comment_id'] as String?,
      reactionType: map['reaction_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'],
      userId: json['user_id'],
      postId: json['post_id'],
      commentId: json['comment_id'],
      reactionType: json['reaction_type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'comment_id': commentId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'post_id': postId,
      'comment_id': commentId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
