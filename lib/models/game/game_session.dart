class GameSession {
  final String sessionId;
  final String userId;
  final String gameId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? finalScore;
  final Map<String, dynamic>? stats;

  GameSession({
    required this.sessionId,
    required this.userId,
    required this.gameId,
    required this.startedAt,
    this.endedAt,
    this.finalScore,
    this.stats,
  });

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      sessionId: json['session_id'] as String? ?? json['sessionId'] as String,
      userId: json['user_id'] as String? ?? json['userId'] as String,
      gameId: json['game_id'] as String? ?? json['gameId'] as String,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : DateTime.parse(json['startedAt'] as String),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'] as String)
          : (json['endedAt'] != null ? DateTime.parse(json['endedAt'] as String) : null),
      finalScore: json['final_score'] as int? ?? json['finalScore'] as int?,
      stats: json['stats'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'gameId': gameId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'finalScore': finalScore,
      if (stats != null) 'stats': stats,
    };
  }
}
