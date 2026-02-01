class RandomSession {
  final String id;
  final String? aUserId;
  final String? bUserId;
  final String status; // matching, connected, ended
  final DateTime createdAt;
  final DateTime? endedAt;
  final String? endReason;

  RandomSession({
    required this.id,
    required this.aUserId,
    required this.bUserId,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.endReason,
  });

  factory RandomSession.fromMap(Map<String, dynamic> map) {
    return RandomSession(
      id: map['id'] as String,
      aUserId: map['a_user_id'] as String?,
      bUserId: map['b_user_id'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
      endReason: map['end_reason'] as String?,
    );
  }
}

class RandomMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String content;
  final DateTime createdAt;

  RandomMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.content,
    required this.createdAt,
  });

  factory RandomMessage.fromMap(Map<String, dynamic> map) {
    return RandomMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
