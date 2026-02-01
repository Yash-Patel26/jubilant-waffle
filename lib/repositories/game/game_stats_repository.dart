import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IGameStatsRepository {
  Future<void> recordGameSession(Map<String, dynamic> sessionData);
  Future<List<Map<String, dynamic>>> getRecentSessions(
    String userId, {
    String? gameId,
    int limit = 20,
  });
  Future<Map<String, dynamic>?> getPlayerGameStats(String userId, String gameId);
  Future<void> upsertGameStats(Map<String, dynamic> stats);
  Future<List<Map<String, dynamic>>> getAllPlayerStats(String userId);
  Future<List<Map<String, dynamic>>> getGameLeaderboard(
    String gameId, {
    int limit = 50,
    String orderBy = 'total_score',
  });
}

class StubGameStatsRepository implements IGameStatsRepository {
  @override
  Future<void> recordGameSession(Map<String, dynamic> sessionData) async {}

  @override
  Future<List<Map<String, dynamic>>> getRecentSessions(
    String userId, {
    String? gameId,
    int limit = 20,
  }) async =>
      [];

  @override
  Future<Map<String, dynamic>?> getPlayerGameStats(String userId, String gameId) async => null;

  @override
  Future<void> upsertGameStats(Map<String, dynamic> stats) async {}

  @override
  Future<List<Map<String, dynamic>>> getAllPlayerStats(String userId) async => [];

  @override
  Future<List<Map<String, dynamic>>> getGameLeaderboard(
    String gameId, {
    int limit = 50,
    String orderBy = 'total_score',
  }) async =>
      [];
}

final gameStatsRepositoryProvider = Provider<IGameStatsRepository>((ref) {
  return StubGameStatsRepository();
});
