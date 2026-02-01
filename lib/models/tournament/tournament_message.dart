class TournamentMessage {
  final String id;
  final String tournamentId;
  final String userId;
  final String message;
  final String messageType; // 'general', 'announcement', 'system'
  final DateTime createdAt;
  final Map<String, dynamic>? profile;

  TournamentMessage({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.message,
    required this.messageType,
    required this.createdAt,
    this.profile,
  });

  factory TournamentMessage.fromMap(Map<String, dynamic> map) {
    return TournamentMessage(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      message: map['message'] as String,
      messageType: map['message_type'] as String? ?? 'general',
      createdAt: DateTime.parse(map['created_at'] as String),
      profile: map['profile'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'user_id': userId,
      'message': message,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'profile': profile,
    };
  }

  bool get isAnnouncement => messageType == 'announcement';
  bool get isSystem => messageType == 'system';
  bool get isGeneral => messageType == 'general';
  bool get isChat =>
      messageType == 'general'; // Chat messages use 'general' type
  String? get username => profile?['username'] as String?;
  String? get avatarUrl => profile?['avatar_url'] as String?;
}
