class TournamentMatch {
  final String id;
  final String tournamentId;
  final int roundNumber;
  final int matchNumber;
  final String? participantAId;
  final String? participantBId;
  final String? team1Id;
  final String? team2Id;
  final String? winnerId;
  final String status; // 'scheduled', 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? participantA;
  final Map<String, dynamic>? participantB;
  final Map<String, dynamic>? team1;
  final Map<String, dynamic>? team2;
  final Map<String, dynamic>? winner;

  TournamentMatch({
    required this.id,
    required this.tournamentId,
    required this.roundNumber,
    required this.matchNumber,
    this.participantAId,
    this.participantBId,
    this.team1Id,
    this.team2Id,
    this.winnerId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.participantA,
    this.participantB,
    this.team1,
    this.team2,
    this.winner,
  });

  factory TournamentMatch.fromMap(Map<String, dynamic> map) {
    return TournamentMatch(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      roundNumber: map['round_number'] as int,
      matchNumber: map['match_number'] as int,
      participantAId: map['participant_a_id'] as String?,
      participantBId: map['participant_b_id'] as String?,
      team1Id: map['team1_id'] as String?,
      team2Id: map['team2_id'] as String?,
      winnerId: map['winner_id'] as String?,
      status: map['status'] as String? ?? 'scheduled',
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      participantA: map['participant_a'] as Map<String, dynamic>?,
      participantB: map['participant_b'] as Map<String, dynamic>?,
      team1: map['team1'] as Map<String, dynamic>?,
      team2: map['team2'] as Map<String, dynamic>?,
      winner: map['winner'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tournament_id': tournamentId,
      'round_number': roundNumber,
      'match_number': matchNumber,
      'participant_a_id': participantAId,
      'participant_b_id': participantBId,
      'team1_id': team1Id,
      'team2_id': team2Id,
      'winner_id': winnerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'participant_a': participantA,
      'participant_b': participantB,
      'team1': team1,
      'team2': team2,
      'winner': winner,
    };
  }

  bool get isSolo => participantAId != null && participantBId != null;
  bool get isTeam => team1Id != null && team2Id != null;
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isScheduled => status == 'scheduled';
  bool get hasWinner => winnerId != null;

  // JSON serialization methods
  factory TournamentMatch.fromJson(Map<String, dynamic> json) =>
      TournamentMatch.fromMap(json);
  Map<String, dynamic> toJson() => toMap();
}
