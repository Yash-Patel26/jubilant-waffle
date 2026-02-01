class TournamentBracket {
  final String tournamentId;
  final List<BracketRound> rounds;

  TournamentBracket({
    required this.tournamentId,
    required this.rounds,
  });

  factory TournamentBracket.fromJson(Map<String, dynamic> json) {
    return TournamentBracket(
      tournamentId: json['tournamentId'] as String,
      rounds: (json['rounds'] as List)
          .map((e) => BracketRound.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tournamentId': tournamentId,
      'rounds': rounds.map((e) => e.toJson()).toList(),
    };
  }
}

class BracketRound {
  final int roundNumber;
  final List<BracketMatch> matches;

  BracketRound({
    required this.roundNumber,
    required this.matches,
  });

  factory BracketRound.fromJson(Map<String, dynamic> json) {
    return BracketRound(
      roundNumber: json['roundNumber'] as int,
      matches: (json['matches'] as List)
          .map((e) => BracketMatch.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'matches': matches.map((e) => e.toJson()).toList(),
    };
  }
}

class BracketMatch {
  final String matchId;
  final String teamAId;
  final String teamBId;
  final String? winnerId;

  BracketMatch({
    required this.matchId,
    required this.teamAId,
    required this.teamBId,
    this.winnerId,
  });

  factory BracketMatch.fromJson(Map<String, dynamic> json) {
    return BracketMatch(
      matchId: json['matchId'] as String,
      teamAId: json['teamAId'] as String,
      teamBId: json['teamBId'] as String,
      winnerId: json['winnerId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matchId': matchId,
      'teamAId': teamAId,
      'teamBId': teamBId,
      'winnerId': winnerId,
    };
  }
}
