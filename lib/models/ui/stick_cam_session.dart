class StickCamSession {
  final String id;
  final String? aUserId;
  final String? bUserId;
  final String status; // matching, connected, ended
  final DateTime createdAt;
  final DateTime? endedAt;
  final String? endReason;
  final List<String> interests;
  final String mode; // video, audio, text

  StickCamSession({
    required this.id,
    required this.aUserId,
    required this.bUserId,
    required this.status,
    required this.createdAt,
    this.endedAt,
    this.endReason,
    this.interests = const [],
    this.mode = 'video',
  });

  factory StickCamSession.fromMap(Map<String, dynamic> map) {
    return StickCamSession(
      id: map['id'] as String,
      aUserId: map['a_user_id'] as String?,
      bUserId: map['b_user_id'] as String?,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at']) : null,
      endReason: map['end_reason'] as String?,
      interests: List<String>.from(map['interests'] ?? []),
      mode: map['mode'] as String? ?? 'video',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'a_user_id': aUserId,
      'b_user_id': bUserId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'end_reason': endReason,
      'interests': interests,
      'mode': mode,
    };
  }
}

class StickCamMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final String messageType; // text, system

  StickCamMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    this.messageType = 'text',
  });

  factory StickCamMessage.fromMap(Map<String, dynamic> map) {
    return StickCamMessage(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      messageType: map['message_type'] as String? ?? 'text',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender_id': senderId,
      'content': content,
      'created_at': createdAt.toIso8601String(),
      'message_type': messageType,
    };
  }
}
