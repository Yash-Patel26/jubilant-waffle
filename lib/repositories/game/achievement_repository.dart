import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class IAchievementRepository {
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId);
  Future<bool> hasAchievement(String userId, String achievementId);
  Future<void> unlockAchievement(String userId, String achievementId);
  Future<void> updateUserAchievementProgress(
    String userId,
    String achievementId,
    int currentValue,
    int targetValue,
  );
}

class StubAchievementRepository implements IAchievementRepository {
  @override
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async => [];

  @override
  Future<bool> hasAchievement(String userId, String achievementId) async => false;

  @override
  Future<void> unlockAchievement(String userId, String achievementId) async {}

  @override
  Future<void> updateUserAchievementProgress(
    String userId,
    String achievementId,
    int currentValue,
    int targetValue,
  ) async {}
}

final achievementRepositoryProvider = Provider<IAchievementRepository>((ref) {
  return StubAchievementRepository();
});
