class GameStats {
  final String userId;
  final String gameId;
  final int wins;
  final int losses;
  final int draws;
  final int highestScore;

  GameStats({
    required this.userId,
    required this.gameId,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.highestScore,
  });

  factory GameStats.fromJson(Map<String, dynamic> json) {
    return GameStats(
      userId: json['userId'] as String,
      gameId: json['gameId'] as String,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      draws: json['draws'] as int,
      highestScore: json['highestScore'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'gameId': gameId,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'highestScore': highestScore,
    };
  }
}
