import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/game/game_stats.dart';
import 'package:gamer_flick/models/game/game_session.dart';
import 'package:gamer_flick/repositories/game/game_stats_repository.dart';
import 'package:gamer_flick/services/game/achievement_service.dart';
import 'package:gamer_flick/repositories/game/leaderboard_repository.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Game Stats Service for tracking player statistics and game sessions
class GameStatsService {
  final IGameStatsRepository _gameStatsRepository;
  final AchievementService _achievementService;
  final ILeaderboardRepository _leaderboardRepository;

  GameStatsService(
    this._gameStatsRepository,
    this._achievementService,
    this._leaderboardRepository,
  );

  /// Record a game session
  Future<GameSession?> recordGameSession({
    required String userId,
    required String gameId,
    required Duration playTime,
    required Map<String, dynamic> stats,
    String? matchId,
    String? tournamentId,
  }) async {
    try {
      final sessionData = {
        'user_id': userId,
        'game_id': gameId,
        'duration_minutes': playTime.inMinutes,
        'stats': stats,
        'match_id': matchId,
        'tournament_id': tournamentId,
        'played_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _gameStatsRepository.recordGameSession(sessionData);

      // Update aggregate stats
      await _updateAggregateStats(userId, gameId, playTime, stats);

      // Fetch the newly created session (this might need repository support for fetching a single session)
      final recentSessions = await _gameStatsRepository.getRecentSessions(userId, gameId: gameId, limit: 1);
      if (recentSessions.isNotEmpty) {
        return GameSession.fromJson(recentSessions.first);
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('Failed to record game session', e);
      return null;
    }
  }

  /// Update aggregate game stats for user
  Future<void> _updateAggregateStats(
    String userId,
    String gameId,
    Duration playTime,
    Map<String, dynamic> sessionStats,
  ) async {
    try {
      // Get current stats
      final currentStats = await _gameStatsRepository.getPlayerGameStats(userId, gameId) ?? <String, dynamic>{};

      // Calculate new totals
      final newTotalPlaytime = ((currentStats['total_playtime_minutes'] ?? 0) as int) + playTime.inMinutes;
      final newMatchesPlayed = ((currentStats['matches_played'] ?? 0) as int) + 1;
      final newWins = ((currentStats['wins'] ?? 0) as int) + (sessionStats['won'] == true ? 1 : 0);
      final newLosses = ((currentStats['losses'] ?? 0) as int) + (sessionStats['won'] == false ? 1 : 0);
      final newKills = ((currentStats['total_kills'] ?? 0) as int) + ((sessionStats['kills'] ?? 0) as int);
      final newDeaths = ((currentStats['total_deaths'] ?? 0) as int) + ((sessionStats['deaths'] ?? 0) as int);
      final newAssists = ((currentStats['total_assists'] ?? 0) as int) + ((sessionStats['assists'] ?? 0) as int);

      // Calculate derived stats
      final winRate = newMatchesPlayed > 0 ? (newWins / newMatchesPlayed) * 100 : 0.0;
      final kda = newDeaths > 0 ? ((newKills + newAssists) / newDeaths) : (newKills + newAssists).toDouble();

      // Upsert stats via repository
      await _gameStatsRepository.upsertGameStats({
        'user_id': userId,
        'game_id': gameId,
        'total_playtime_minutes': newTotalPlaytime,
        'matches_played': newMatchesPlayed,
        'wins': newWins,
        'losses': newLosses,
        'win_rate': winRate,
        'total_kills': newKills,
        'total_deaths': newDeaths,
        'total_assists': newAssists,
        'kda_ratio': kda,
        'last_played': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      // Update leaderboard
      await _leaderboardRepository.updateUserScore(userId);

      // Check achievements
      await _achievementService.checkAndAwardAchievements(userId);
    } catch (e) {
      ErrorHandler.logError('Failed to update aggregate stats', e);
    }
  }

  /// Get player's game-specific stats
  Future<Map<String, dynamic>> getPlayerGameStats(String userId, String gameId) async {
    final stats = await _gameStatsRepository.getPlayerGameStats(userId, gameId);
    return stats ?? <String, dynamic>{};
  }

  /// Get all game stats for a player
  Future<List<GameStats>> getAllPlayerStats(String userId) async {
    final response = await _gameStatsRepository.getAllPlayerStats(userId);
    return response.map((data) => GameStats.fromJson(data)).toList();
  }

  /// Get recent game sessions
  Future<List<GameSession>> getRecentSessions(
    String userId, {
    String? gameId,
    int limit = 20,
  }) async {
    final response = await _gameStatsRepository.getRecentSessions(userId, gameId: gameId, limit: limit);
    return response.map((data) => GameSession.fromJson(data)).toList();
  }

  /// Get total playtime across all games
  Future<int> getTotalPlaytimeMinutes(String userId) async {
    final response = await _gameStatsRepository.getAllPlayerStats(userId);
    return response.fold<int>(
      0,
      (sum, stat) => sum + ((stat['total_playtime_minutes'] ?? 0) as int),
    );
  }

  /// Get player's most played game
  Future<Map<String, dynamic>?> getMostPlayedGame(String userId) async {
    final stats = await _gameStatsRepository.getAllPlayerStats(userId);
    if (stats.isEmpty) return null;
    return stats.first; // Already ordered by playtime in repository
  }

  /// Get game leaderboard (top players for a specific game)
  Future<List<Map<String, dynamic>>> getGameLeaderboard(
    String gameId, {
    int limit = 50,
    String sortBy = 'wins', // 'wins', 'win_rate', 'kda_ratio', 'playtime'
  }) async {
    String orderColumn;
    switch (sortBy) {
      case 'wins':
        orderColumn = 'wins';
        break;
      case 'win_rate':
        orderColumn = 'win_rate';
        break;
      case 'kda_ratio':
        orderColumn = 'kda_ratio';
        break;
      case 'playtime':
        orderColumn = 'total_playtime_minutes';
        break;
      default:
        orderColumn = 'wins';
    }

    final response = await _gameStatsRepository.getGameLeaderboard(gameId, limit: limit, orderBy: orderColumn);

    // Add rank
    final List<Map<String, dynamic>> rankedResults = [];
    int rank = 1;
    for (final item in response) {
      rankedResults.add({
        ...item,
        'rank': rank++,
      });
    }

    return rankedResults;
  }

  /// Compare two players' stats for a game
  Future<Map<String, dynamic>> comparePlayersStats(
    String player1Id,
    String player2Id,
    String gameId,
  ) async {
    try {
      final player1Stats = await getPlayerGameStats(player1Id, gameId);
      final player2Stats = await getPlayerGameStats(player2Id, gameId);

      // In a real app, you might want to fetch profiles via profilesRepository
      final client = Supabase.instance.client;
      final profiles = await client
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', [player1Id, player2Id]);

      final profileMap = {for (var p in profiles as List) p['id']: p};

      return {
        'player1': {
          'profile': profileMap[player1Id],
          'stats': player1Stats,
        },
        'player2': {
          'profile': profileMap[player2Id],
          'stats': player2Stats,
        },
        'comparison': {
          'wins_diff': (player1Stats['wins'] ?? 0) - (player2Stats['wins'] ?? 0),
          'win_rate_diff': (player1Stats['win_rate'] ?? 0) - (player2Stats['win_rate'] ?? 0),
          'kda_diff': (player1Stats['kda_ratio'] ?? 0) - (player2Stats['kda_ratio'] ?? 0),
          'playtime_diff': (player1Stats['total_playtime_minutes'] ?? 0) - 
                          (player2Stats['total_playtime_minutes'] ?? 0),
        },
      };
    } catch (e) {
      ErrorHandler.logError('Failed to compare players stats', e);
      return {};
    }
  }

  /// Get win streak for a player in a game
  Future<int> getCurrentWinStreak(String userId, String gameId) async {
    final sessions = await getRecentSessions(userId, gameId: gameId, limit: 50);

    int streak = 0;
    for (final session in sessions) {
      if (session.stats?['won'] == true) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Record a win
  Future<void> recordWin({
    required String userId,
    required String gameId,
    Duration? playTime,
    Map<String, dynamic>? additionalStats,
  }) async {
    await recordGameSession(
      userId: userId,
      gameId: gameId,
      playTime: playTime ?? const Duration(minutes: 15),
      stats: {
        'won': true,
        ...?additionalStats,
      },
    );
  }

  /// Record a loss
  Future<void> recordLoss({
    required String userId,
    required String gameId,
    Duration? playTime,
    Map<String, dynamic>? additionalStats,
  }) async {
    await recordGameSession(
      userId: userId,
      gameId: gameId,
      playTime: playTime ?? const Duration(minutes: 15),
      stats: {
        'won': false,
        ...?additionalStats,
      },
    );
  }
}

final gameStatsServiceProvider = Provider<GameStatsService>((ref) {
  return GameStatsService(
    ref.watch(gameStatsRepositoryProvider),
    ref.watch(achievementServiceProvider),
    ref.watch(leaderboardRepositoryProvider),
  );
});
