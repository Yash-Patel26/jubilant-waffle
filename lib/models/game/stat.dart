class Stat {
  final String id;
  final String userId;
  final int tournamentsPlayed;
  final int tournamentsWon;
  final int totalKills;
  final double kdRatio;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final int totalLikes;

  Stat({
    required this.id,
    required this.userId,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
    required this.totalKills,
    required this.kdRatio,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.totalLikes = 0,
  });

  factory Stat.fromJson(Map<String, dynamic> json) {
    return Stat(
      id: json['id'],
      userId: json['user_id'],
      tournamentsPlayed: json['tournaments_played'] ?? 0,
      tournamentsWon: json['tournaments_won'] ?? 0,
      totalKills: json['total_kills'] ?? 0,
      kdRatio: (json['kd_ratio'] as num?)?.toDouble() ?? 0.0,
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
    );
  }

  Null get rank => null;

  Null get winRate => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'tournaments_played': tournamentsPlayed,
      'tournaments_won': tournamentsWon,
      'total_kills': totalKills,
      'kd_ratio': kdRatio,
      'posts_count': postsCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'total_likes': totalLikes,
    };
  }
}
