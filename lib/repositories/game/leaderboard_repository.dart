import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/game/leaderboard_entry.dart';
import 'package:gamer_flick/providers/core/supabase_provider.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class ILeaderboardRepository {
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.overall,
    int limit = 50,
    int offset = 0,
  });
  Future<LeaderboardEntry?> getUserRank(String userId);
  Future<void> updateUserScore(String userId);
  Future<void> onPostCreated(String userId);
  Future<void> onReelCreated(String userId);
  Future<void> onPostLiked(String postUserId);
  Future<void> onReelLiked(String reelUserId);
  Future<void> onCommentAdded(String postUserId);
  Future<void> onCommunityPostCreated(String userId);
  Future<void> onCommunityJoined(String userId);
}

class SupabaseLeaderboardRepository implements ILeaderboardRepository {
  final SupabaseClient _client;
  final ErrorReportingService _errorReportingService;

  SupabaseLeaderboardRepository({
    required SupabaseClient client,
    required ErrorReportingService errorReportingService,
  })  : _client = client,
        _errorReportingService = errorReportingService;
  // Scoring constants
  static const int LIKE_POINTS = 1;
  static const int COMMENT_POINTS = 2;
  static const int SHARE_POINTS = 3;
  static const int SAVE_POINTS = 2;
  static const int VIEWS_POINTS_PER_100 = 1;

  static const int COMMUNITY_POST_POINTS = 5;
  static const int COMMUNITY_COMMENT_POINTS = 3;
  static const int CREATE_COMMUNITY_POINTS = 20;
  static const int EVENT_PARTICIPATION_POINTS = 10;
  static const int COMMUNITY_LIKE_POINTS = 1;

  static const int MATCH_WIN_POINTS = 10;
  static const int MATCH_LOSS_POINTS = 2;
  static const int TOURNAMENT_WINNER_POINTS = 50;
  static const int TOURNAMENT_RUNNER_UP_POINTS = 25;
  static const int HOST_TOURNAMENT_POINTS = 15;

  @override
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardType type = LeaderboardType.overall,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      String typeParam;
      switch (type) {
        case LeaderboardType.overall:
          typeParam = 'overall';
          break;
        case LeaderboardType.content:
          typeParam = 'content';
          break;
        case LeaderboardType.community:
          typeParam = 'community';
          break;
        case LeaderboardType.tournament:
          typeParam = 'tournament';
          break;
      }

      final response = await _client.rpc('get_leaderboard_rankings', params: {
        'p_limit': limit,
        'p_offset': offset,
        'p_type': typeParam,
      });

      final entries = <LeaderboardEntry>[];

      for (final row in response as List) {
        try {
          entries.add(LeaderboardEntry(
            userId: row['user_id'] as String,
            username: row['username'] as String? ?? 'Unknown User',
            avatarUrl: row['avatar_url'] as String?,
            rank: row['rank'] as int,
            totalScore: row['total_score'] as int,
            contentScore: row['content_score'] as int,
            communityScore: row['community_score'] as int,
            tournamentScore: row['tournament_score'] as int,
            detailedMetrics: {},
            lastUpdated: DateTime.parse(row['last_updated'] as String),
          ));
        } catch (e) {
          continue;
        }
      }

      return entries;
    } catch (e) {
      return _getLeaderboardFallback(type: type, limit: limit, offset: offset);
    }
  }

  Future<List<LeaderboardEntry>> _getLeaderboardFallback({
    LeaderboardType type = LeaderboardType.overall,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final usersResponse = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .limit(limit)
          .range(offset, offset + limit - 1);

      final users = usersResponse as List;
      
      // Use Future.wait for parallel score calculations to avoid N+1 problem
      final entries = await Future.wait(users.map((user) async {
        try {
          final userId = user['id'] as String;
          
          final scores = await Future.wait([
            _calculateContentScore(userId),
            _calculateCommunityScore(userId),
            _calculateTournamentScore(userId),
          ]);

          final contentScore = scores[0];
          final communityScore = scores[1];
          final tournamentScore = scores[2];

          int totalScore;
          switch (type) {
            case LeaderboardType.overall:
              totalScore = contentScore + communityScore + tournamentScore;
              break;
            case LeaderboardType.content:
              totalScore = contentScore;
              break;
            case LeaderboardType.community:
              totalScore = communityScore;
              break;
            case LeaderboardType.tournament:
              totalScore = tournamentScore;
              break;
          }

          return LeaderboardEntry(
            userId: userId,
            username: user['username'] as String? ?? 'Unknown User',
            avatarUrl: user['avatar_url'] as String?,
            rank: 0, // Will be set after sorting
            totalScore: totalScore,
            contentScore: contentScore,
            communityScore: communityScore,
            tournamentScore: tournamentScore,
            detailedMetrics: await _getDetailedMetrics(userId),
            lastUpdated: DateTime.now(),
          );
        } catch (e) {
          _errorReportingService.reportError('Failed to process user in leaderboard fallback: $e', null);
          return null;
        }
      }));

      // Filter out nulls and sort
      final validEntries = entries.whereType<LeaderboardEntry>().toList();
      validEntries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      
      for (int i = 0; i < validEntries.length; i++) {
        validEntries[i] = validEntries[i].copyWith(rank: offset + i + 1);
      }

      return validEntries;
    } catch (e) {
      _errorReportingService.reportError('Leaderboard fallback failed: $e', null);
      return [];
    }
  }

  @override
  Future<LeaderboardEntry?> getUserRank(String userId) async {
    try {
      final scoreResponse = await _client
          .from('leaderboard_scores')
          .select('*')
          .eq('user_id', userId)
          .single();

      final userResponse = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', userId)
          .single();

      final rankResponse = await _client
          .from('leaderboard_scores')
          .select('user_id')
          .gt('total_score', scoreResponse['total_score'] as int)
          .count(CountOption.exact);

      final rank = rankResponse.count + 1;

      return LeaderboardEntry(
        userId: userId,
        username: userResponse['username'] as String,
        avatarUrl: userResponse['avatar_url'] as String?,
        rank: rank,
        totalScore: scoreResponse['total_score'] as int,
        contentScore: scoreResponse['content_score'] as int,
        communityScore: scoreResponse['community_score'] as int,
        tournamentScore: scoreResponse['tournament_score'] as int,
        detailedMetrics: await _getDetailedMetrics(userId),
        lastUpdated: DateTime.parse(scoreResponse['last_updated'] as String),
      );
    } catch (e) {
      return _getUserRankFallback(userId);
    }
  }

  Future<LeaderboardEntry?> _getUserRankFallback(String userId) async {
    try {
      final userResponse = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', userId)
          .single();

      final contentScore = await _calculateContentScore(userId);
      final communityScore = await _calculateCommunityScore(userId);
      final tournamentScore = await _calculateTournamentScore(userId);

      return LeaderboardEntry(
        userId: userId,
        username: userResponse['username'] as String,
        avatarUrl: userResponse['avatar_url'] as String?,
        rank: 0,
        totalScore: contentScore + communityScore + tournamentScore,
        contentScore: contentScore,
        communityScore: communityScore,
        tournamentScore: tournamentScore,
        detailedMetrics: await _getDetailedMetrics(userId),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateUserScore(String userId) async {
    try {
      final contentScore = await _calculateContentScore(userId);
      final communityScore = await _calculateCommunityScore(userId);
      final tournamentScore = await _calculateTournamentScore(userId);
      final totalScore = contentScore + communityScore + tournamentScore;

      await _client.from('leaderboard_scores').upsert({
        'user_id': userId,
        'content_score': contentScore,
        'community_score': communityScore,
        'tournament_score': tournamentScore,
        'total_score': totalScore,
        'last_updated': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {}
  }

  @override
  Future<void> onPostCreated(String userId) async => updateUserScore(userId);
  @override
  Future<void> onReelCreated(String userId) async => updateUserScore(userId);
  @override
  Future<void> onPostLiked(String postUserId) async => updateUserScore(postUserId);
  @override
  Future<void> onReelLiked(String reelUserId) async => updateUserScore(reelUserId);
  @override
  Future<void> onCommentAdded(String postUserId) async => updateUserScore(postUserId);
  @override
  Future<void> onCommunityPostCreated(String userId) async => updateUserScore(userId);
  @override
  Future<void> onCommunityJoined(String userId) async => updateUserScore(userId);

  Future<int> _calculateContentScore(String userId) async {
    try {
      final postsResponse = await _client
          .from('posts')
          .select('like_count, comment_count, share_count, view_count')
          .eq('user_id', userId);

      final reelsResponse = await _client
          .from('reels')
          .select('like_count, comment_count, share_count, view_count')
          .eq('user_id', userId);

      int totalScore = 0;
      for (final post in postsResponse as List) {
        totalScore += ((post['like_count'] ?? 0) as int) * LIKE_POINTS;
        totalScore += ((post['comment_count'] ?? 0) as int) * COMMENT_POINTS;
        totalScore += ((post['share_count'] ?? 0) as int) * SHARE_POINTS;
        totalScore += (((post['view_count'] ?? 0) as int) / 100).floor() * VIEWS_POINTS_PER_100;
      }
      for (final reel in reelsResponse as List) {
        totalScore += ((reel['like_count'] ?? 0) as int) * LIKE_POINTS;
        totalScore += ((reel['comment_count'] ?? 0) as int) * COMMENT_POINTS;
        totalScore += ((reel['share_count'] ?? 0) as int) * SHARE_POINTS;
        totalScore += (((reel['view_count'] ?? 0) as int) / 100).floor() * VIEWS_POINTS_PER_100;
      }
      return totalScore;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _calculateCommunityScore(String userId) async {
    try {
      int totalScore = 0;
      final communityPostsResponse = await _client
          .from('community_posts')
          .select('id, like_count')
          .eq('author_id', userId);

      for (final post in communityPostsResponse as List) {
        totalScore += COMMUNITY_POST_POINTS;
        totalScore += ((post['like_count'] ?? 0) as int) * COMMUNITY_LIKE_POINTS;
      }

      final createdCommunitiesResponse = await _client
          .from('communities')
          .select('id')
          .eq('created_by', userId);

      totalScore += (createdCommunitiesResponse as List).length * CREATE_COMMUNITY_POINTS;
      return totalScore;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _calculateTournamentScore(String userId) async {
    try {
      int totalScore = 0;
      final matchWinsResponse = await _client
          .from('tournament_matches')
          .select('id')
          .or('player1_id.eq.$userId,player2_id.eq.$userId')
          .eq('winner_id', userId);
      totalScore += (matchWinsResponse as List).length * MATCH_WIN_POINTS;

      final tournamentWinsResponse = await _client
          .from('tournaments')
          .select('id')
          .eq('winner_id', userId)
          .eq('status', 'completed');
      totalScore += (tournamentWinsResponse as List).length * TOURNAMENT_WINNER_POINTS;

      return totalScore;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> _getDetailedMetrics(String userId) async {
    try {
      final metrics = <String, int>{};
      final postsResponse = await _client.from('posts').select('like_count').eq('user_id', userId);
      final reelsResponse = await _client.from('reels').select('like_count').eq('user_id', userId);
      
      metrics['total_likes'] = (postsResponse as List).length + (reelsResponse as List).length;
      metrics['total_posts'] = (postsResponse as List).length;
      metrics['total_reels'] = (reelsResponse as List).length;

      return metrics;
    } catch (e) {
      return {};
    }
  }
}

final leaderboardRepositoryProvider = Provider<ILeaderboardRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseLeaderboardRepository(
    client: client,
    errorReportingService: ErrorReportingService(),
  );
});
