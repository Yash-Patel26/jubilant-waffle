class SharedPostRecipient {
  final String id;
  final String sharedPostId;
  final String recipientUserId;
  final DateTime createdAt;
  final Map<String, dynamic>? recipient;

  SharedPostRecipient({
    required this.id,
    required this.sharedPostId,
    required this.recipientUserId,
    required this.createdAt,
    this.recipient,
  });

  factory SharedPostRecipient.fromMap(Map<String, dynamic> map) {
    return SharedPostRecipient(
      id: map['id'] as String,
      sharedPostId: map['shared_post_id'] as String,
      recipientUserId: map['recipient_user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      recipient: map['recipient'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shared_post_id': sharedPostId,
      'recipient_user_id': recipientUserId,
      'created_at': createdAt.toIso8601String(),
      'recipient': recipient,
    };
  }

  String? get recipientUsername => recipient?['username'] as String?;
  String? get recipientAvatarUrl => recipient?['avatar_url'] as String?;
}
