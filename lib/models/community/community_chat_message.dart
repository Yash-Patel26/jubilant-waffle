class CommunityChatMessage {
  final String id;
  final String communityId;
  final String userId;
  final String message;
  final String messageType;
  final DateTime createdAt;

  CommunityChatMessage({
    required this.id,
    required this.communityId,
    required this.userId,
    required this.message,
    this.messageType = 'text',
    required this.createdAt,
  });

  factory CommunityChatMessage.fromMap(Map<String, dynamic> map) {
    return CommunityChatMessage(
      id: map['id'] as String,
      communityId: map['community_id'] as String,
      userId: map['user_id'] as String,
      message: map['message'] as String,
      messageType: map['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'community_id': communityId,
      'user_id': userId,
      'message': message,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
