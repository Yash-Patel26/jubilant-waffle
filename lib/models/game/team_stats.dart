class TeamStats {
  final String teamId;
  final int matchesPlayed;
  final int wins;
  final int losses;
  final int draws;

  TeamStats({
    required this.teamId,
    required this.matchesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
  });

  factory TeamStats.fromJson(Map<String, dynamic> json) {
    return TeamStats(
      teamId: json['teamId'] as String,
      matchesPlayed: json['matchesPlayed'] as int,
      wins: json['wins'] as int,
      losses: json['losses'] as int,
      draws: json['draws'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'teamId': teamId,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'losses': losses,
      'draws': draws,
    };
  }
}
