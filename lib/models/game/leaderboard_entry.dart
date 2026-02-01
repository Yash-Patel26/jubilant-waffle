class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatarUrl;
  final int rank;
  final int totalScore;
  final int contentScore;
  final int communityScore;
  final int tournamentScore;
  final Map<String, int> detailedMetrics;
  final DateTime lastUpdated;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.totalScore,
    required this.contentScore,
    required this.communityScore,
    required this.tournamentScore,
    required this.detailedMetrics,
    required this.lastUpdated,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      rank: json['rank'] as int,
      totalScore: json['total_score'] as int,
      contentScore: json['content_score'] as int,
      communityScore: json['community_score'] as int,
      tournamentScore: json['tournament_score'] as int,
      detailedMetrics: Map<String, int>.from(json['detailed_metrics'] ?? {}),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'avatar_url': avatarUrl,
      'rank': rank,
      'total_score': totalScore,
      'content_score': contentScore,
      'community_score': communityScore,
      'tournament_score': tournamentScore,
      'detailed_metrics': detailedMetrics,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  LeaderboardEntry copyWith({
    String? userId,
    String? username,
    String? avatarUrl,
    int? rank,
    int? totalScore,
    int? contentScore,
    int? communityScore,
    int? tournamentScore,
    Map<String, int>? detailedMetrics,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rank: rank ?? this.rank,
      totalScore: totalScore ?? this.totalScore,
      contentScore: contentScore ?? this.contentScore,
      communityScore: communityScore ?? this.communityScore,
      tournamentScore: tournamentScore ?? this.tournamentScore,
      detailedMetrics: detailedMetrics ?? this.detailedMetrics,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

enum LeaderboardType {
  overall,
  content,
  community,
  tournament,
}

extension LeaderboardTypeExtension on LeaderboardType {
  String get displayName {
    switch (this) {
      case LeaderboardType.overall:
        return 'Overall';
      case LeaderboardType.content:
        return 'Content Creators';
      case LeaderboardType.community:
        return 'Community Leaders';
      case LeaderboardType.tournament:
        return 'Tournament Champions';
    }
  }

  String get description {
    switch (this) {
      case LeaderboardType.overall:
        return 'Top players across all categories';
      case LeaderboardType.content:
        return 'Best content creators and influencers';
      case LeaderboardType.community:
        return 'Most active community members';
      case LeaderboardType.tournament:
        return 'Top tournament performers';
    }
  }
}
