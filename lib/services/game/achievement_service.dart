import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/game/achievement.dart';
import 'package:gamer_flick/repositories/game/achievement_repository.dart';
import 'package:gamer_flick/repositories/game/leaderboard_repository.dart';
import 'package:gamer_flick/repositories/notification/notification_repository.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Achievement Service for gamification system
/// Handles achievement tracking, unlocking, and progress updates
class AchievementService {
  final IAchievementRepository _achievementRepository;
  final ILeaderboardRepository _leaderboardRepository;
  final INotificationRepository _notificationRepository;
  final SupabaseClient _client = Supabase.instance.client;

  AchievementService(
    this._achievementRepository,
    this._leaderboardRepository,
    this._notificationRepository,
  );

  /// All achievement definitions
  static final Map<String, Achievement> achievements = {
    // Content Achievements
    'first_post': const Achievement(
      id: 'first_post',
      name: 'First Steps',
      description: 'Create your first post',
      icon: '📝',
      points: 10,
      category: AchievementCategory.content,
      rarity: AchievementRarity.common,
      requirements: {'posts': 1},
    ),
    'content_creator_10': const Achievement(
      id: 'content_creator_10',
      name: 'Content Creator',
      description: 'Create 10 posts or reels',
      icon: '🎬',
      points: 25,
      category: AchievementCategory.content,
      rarity: AchievementRarity.uncommon,
      requirements: {'total_content': 10},
    ),
    'content_creator_50': const Achievement(
      id: 'content_creator_50',
      name: 'Prolific Creator',
      description: 'Create 50 posts or reels',
      icon: '🌟',
      points: 50,
      category: AchievementCategory.content,
      rarity: AchievementRarity.rare,
      requirements: {'total_content': 50},
    ),
    'content_creator_100': const Achievement(
      id: 'content_creator_100',
      name: 'Content Machine',
      description: 'Create 100 posts or reels',
      icon: '🏭',
      points: 100,
      category: AchievementCategory.content,
      rarity: AchievementRarity.epic,
      requirements: {'total_content': 100},
    ),
    'viral_post': const Achievement(
      id: 'viral_post',
      name: 'Going Viral',
      description: 'Get 1000 likes on a single post',
      icon: '🔥',
      points: 100,
      category: AchievementCategory.content,
      rarity: AchievementRarity.epic,
      requirements: {'single_post_likes': 1000},
    ),
    'first_reel': const Achievement(
      id: 'first_reel',
      name: 'Reel Deal',
      description: 'Create your first reel',
      icon: '🎥',
      points: 15,
      category: AchievementCategory.content,
      rarity: AchievementRarity.common,
      requirements: {'reels': 1},
    ),

    // Tournament Achievements
    'first_tournament': const Achievement(
      id: 'first_tournament',
      name: 'Tournament Rookie',
      description: 'Join your first tournament',
      icon: '🎮',
      points: 15,
      category: AchievementCategory.tournament,
      rarity: AchievementRarity.common,
      requirements: {'tournaments_joined': 1},
    ),
    'first_win': const Achievement(
      id: 'first_win',
      name: 'First Victory',
      description: 'Win your first tournament match',
      icon: '🏆',
      points: 25,
      category: AchievementCategory.tournament,
      rarity: AchievementRarity.uncommon,
      requirements: {'match_wins': 1},
    ),
    'tournament_champion': const Achievement(
      id: 'tournament_champion',
      name: 'Tournament Champion',
      description: 'Win a tournament',
      icon: '🥇',
      points: 100,
      category: AchievementCategory.tournament,
      rarity: AchievementRarity.epic,
      requirements: {'tournament_wins': 1},
    ),
    'tournament_veteran': const Achievement(
      id: 'tournament_veteran',
      name: 'Tournament Veteran',
      description: 'Participate in 10 tournaments',
      icon: '🛡️',
      points: 50,
      category: AchievementCategory.tournament,
      rarity: AchievementRarity.rare,
      requirements: {'tournaments_joined': 10},
    ),
    'tournament_host': const Achievement(
      id: 'tournament_host',
      name: 'Community Host',
      description: 'Host your first tournament',
      icon: '🎙️',
      points: 50,
      category: AchievementCategory.tournament,
      rarity: AchievementRarity.rare,
      requirements: {'tournaments_hosted': 1},
    ),

    // Social Achievements
    'popular': const Achievement(
      id: 'popular',
      name: 'Popular',
      description: 'Reach 100 followers',
      icon: '👥',
      points: 50,
      category: AchievementCategory.social,
      rarity: AchievementRarity.rare,
      requirements: {'followers': 100},
    ),
    'influencer': const Achievement(
      id: 'influencer',
      name: 'Social Influencer',
      description: 'Reach 1000 followers',
      icon: '📢',
      points: 100,
      category: AchievementCategory.social,
      rarity: AchievementRarity.epic,
      requirements: {'followers': 1000},
    ),
    'celebrity': const Achievement(
      id: 'celebrity',
      name: 'Gaming Celebrity',
      description: 'Reach 10,000 followers',
      icon: '💎',
      points: 250,
      category: AchievementCategory.social,
      rarity: AchievementRarity.legendary,
      requirements: {'followers': 10000},
    ),
    'social_butterfly': const Achievement(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      description: 'Follow 50 other gamers',
      icon: '🦋',
      points: 25,
      category: AchievementCategory.social,
      rarity: AchievementRarity.uncommon,
      requirements: {'following': 50},
    ),

    // Community Achievements
    'community_member': const Achievement(
      id: 'community_member',
      name: 'Community Member',
      description: 'Join your first community',
      icon: '🏘️',
      points: 10,
      category: AchievementCategory.community,
      rarity: AchievementRarity.common,
      requirements: {'communities_joined': 1},
    ),
    'community_founder': const Achievement(
      id: 'community_founder',
      name: 'Community Founder',
      description: 'Create your first community',
      icon: '🏗️',
      points: 50,
      category: AchievementCategory.community,
      rarity: AchievementRarity.rare,
      requirements: {'communities_created': 1},
    ),
    'active_contributor': const Achievement(
      id: 'active_contributor',
      name: 'Active Contributor',
      description: 'Make 50 posts in communities',
      icon: '📈',
      points: 75,
      category: AchievementCategory.community,
      rarity: AchievementRarity.rare,
      requirements: {'community_posts': 50},
    ),

    // Streak Achievements
    'daily_gamer_7': const Achievement(
      id: 'daily_gamer_7',
      name: 'Daily Gamer',
      description: 'Login 7 days in a row',
      icon: '🔥',
      points: 25,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.uncommon,
      requirements: {'login_streak': 7},
    ),
    'daily_gamer_30': const Achievement(
      id: 'daily_gamer_30',
      name: 'Dedicated Gamer',
      description: 'Login 30 days in a row',
      icon: '🧊',
      points: 100,
      category: AchievementCategory.streak,
      rarity: AchievementRarity.epic,
      requirements: {'login_streak': 30},
    ),

    // Gaming Achievements
    'pro_profile': const Achievement(
      id: 'pro_profile',
      name: 'Professional Profile',
      description: 'Complete your gaming profile',
      icon: '💼',
      points: 10,
      category: AchievementCategory.general,
      rarity: AchievementRarity.common,
      requirements: {'profile_complete': true},
    ),
    'verified_gamer': const Achievement(
      id: 'verified_gamer',
      name: 'Verified Pro',
      description: 'Get your profile verified',
      icon: '✅',
      points: 200,
      category: AchievementCategory.general,
      rarity: AchievementRarity.legendary,
      requirements: {'is_verified': true},
    ),

    // Secret Achievements
    'night_owl': const Achievement(
      id: 'night_owl',
      name: 'Night Owl',
      description: 'Make a post between 2:00 AM and 4:00 AM',
      icon: '🦉',
      points: 20,
      category: AchievementCategory.general,
      rarity: AchievementRarity.uncommon,
      isSecret: true,
    ),
  };

  /// Get all achievements
  List<Achievement> getAllAchievements() {
    return achievements.values.toList();
  }

  /// Get achievements by category
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return achievements.values
        .where((a) => a.category == category)
        .toList();
  }

  /// Get user's unlocked achievements
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    try {
      final response = await _achievementRepository.getUserAchievements(userId);

      return response.map((data) {
        final userAchievement = UserAchievement.fromJson(data);
        // Attach achievement definition
        final achievement = achievements[userAchievement.achievementId];
        if (achievement != null) {
          return UserAchievement(
            id: userAchievement.id,
            oderId: userAchievement.oderId,
            achievementId: userAchievement.achievementId,
            unlockedAt: userAchievement.unlockedAt,
            progress: userAchievement.progress,
            isComplete: userAchievement.isComplete,
            achievement: achievement,
          );
        }
        return userAchievement;
      }).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get user achievements', e);
      return [];
    }
  }

  /// Get user's achievement progress
  Future<List<AchievementProgress>> getUserAchievementProgress(String userId) async {
    try {
      final response = await _client
          .from('achievement_progress')
          .select('*')
          .eq('user_id', userId);

      return (response as List)
          .map((data) => AchievementProgress.fromJson(data))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get achievement progress', e);
      return [];
    }
  }

  /// Check if user has achievement
  Future<bool> hasAchievement(String userId, String achievementId) async {
    return _achievementRepository.hasAchievement(userId, achievementId);
  }

  /// Award achievement to user
  Future<bool> awardAchievement(String userId, String achievementId) async {
    try {
      // Check if already has achievement
      if (await hasAchievement(userId, achievementId)) {
        return false;
      }

      final achievement = achievements[achievementId];
      if (achievement == null) {
        return false;
      }

      // Unlock achievement via repository
      await _achievementRepository.unlockAchievement(userId, achievementId);

      // Add points to user profile (this could be shifted to repository too)
      await _addAchievementPoints(userId, achievement.points);

      // Update leaderboard
      await _leaderboardRepository.updateUserScore(userId);

      // Send notification
      await _notificationRepository.createNotification(
        userUuid: userId,
        notificationType: 'achievement',
        titleParam: 'Achievement Unlocked!',
        messageParam: '${achievement.icon} ${achievement.name}',
        metadataParam: {
          'achievement_id': achievementId,
          'achievement_name': achievement.name,
          'achievement_icon': achievement.icon,
          'points': achievement.points,
          'rarity': achievement.rarity.name,
        },
      );

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to award achievement', e);
      return false;
    }
  }

  /// Add achievement points to user
  Future<void> _addAchievementPoints(String userId, int points) async {
    try {
      await _client.rpc('add_achievement_points', params: {
        'user_uuid': userId,
        'points_to_add': points,
      });
    } catch (e) {
      // Fallback: direct update
      try {
        final profile = await _client
            .from('profiles')
            .select('achievement_points')
            .eq('id', userId)
            .single();

        final currentPoints = (profile['achievement_points'] ?? 0) as int;
        await _client.from('profiles').update({
          'achievement_points': currentPoints + points,
        }).eq('id', userId);
      } catch (updateError) {
        ErrorHandler.logError('Failed to add achievement points', updateError);
      }
    }
  }

  /// Update achievement progress
  Future<void> updateProgress(
    String userId,
    String achievementId,
    int currentValue,
    int targetValue,
  ) async {
    try {
      await _achievementRepository.updateUserAchievementProgress(
        userId,
        achievementId,
        currentValue,
        targetValue,
      );

      // Check if achievement is complete
      if (currentValue >= targetValue) {
        await awardAchievement(userId, achievementId);
      }
    } catch (e) {
      ErrorHandler.logError('Failed to update achievement progress', e);
    }
  }

  /// Check and award achievements based on user stats
  Future<List<String>> checkAndAwardAchievements(String userId) async {
    final awarded = <String>[];

    try {
      final stats = await _getUserStats(userId);
      final existingAchievements = (await getUserAchievements(userId))
          .map((a) => a.achievementId)
          .toSet();

      // Check content achievements
      if (!existingAchievements.contains('first_post') && 
          (stats['posts'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'first_post')) {
          awarded.add('first_post');
        }
      }

      if (!existingAchievements.contains('first_reel') && 
          (stats['reels'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'first_reel')) {
          awarded.add('first_reel');
        }
      }

      final totalContent = (stats['posts'] ?? 0) + (stats['reels'] ?? 0);
      if (!existingAchievements.contains('content_creator_10') && 
          totalContent >= 10) {
        if (await awardAchievement(userId, 'content_creator_10')) {
          awarded.add('content_creator_10');
        }
      }

      if (!existingAchievements.contains('content_creator_50') && 
          totalContent >= 50) {
        if (await awardAchievement(userId, 'content_creator_50')) {
          awarded.add('content_creator_50');
        }
      }

      if (!existingAchievements.contains('content_creator_100') && 
          totalContent >= 100) {
        if (await awardAchievement(userId, 'content_creator_100')) {
          awarded.add('content_creator_100');
        }
      }

      // Check social achievements
      if (!existingAchievements.contains('popular') && 
          (stats['followers'] ?? 0) >= 100) {
        if (await awardAchievement(userId, 'popular')) {
          awarded.add('popular');
        }
      }

      if (!existingAchievements.contains('influencer') && 
          (stats['followers'] ?? 0) >= 1000) {
        if (await awardAchievement(userId, 'influencer')) {
          awarded.add('influencer');
        }
      }

      if (!existingAchievements.contains('celebrity') && 
          (stats['followers'] ?? 0) >= 10000) {
        if (await awardAchievement(userId, 'celebrity')) {
          awarded.add('celebrity');
        }
      }

      if (!existingAchievements.contains('social_butterfly') && 
          (stats['following'] ?? 0) >= 50) {
        if (await awardAchievement(userId, 'social_butterfly')) {
          awarded.add('social_butterfly');
        }
      }

      // Check community achievements
      if (!existingAchievements.contains('community_member') && 
          (stats['communities_joined'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'community_member')) {
          awarded.add('community_member');
        }
      }

      if (!existingAchievements.contains('community_founder') && 
          (stats['communities_created'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'community_founder')) {
          awarded.add('community_founder');
        }
      }

      if (!existingAchievements.contains('active_contributor') && 
          (stats['community_posts'] ?? 0) >= 50) {
        if (await awardAchievement(userId, 'active_contributor')) {
          awarded.add('active_contributor');
        }
      }

      // Check tournament achievements
      if (!existingAchievements.contains('first_tournament') && 
          (stats['tournaments_joined'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'first_tournament')) {
          awarded.add('first_tournament');
        }
      }

      if (!existingAchievements.contains('first_win') && 
          (stats['match_wins'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'first_win')) {
          awarded.add('first_win');
        }
      }

      if (!existingAchievements.contains('tournament_champion') && 
          (stats['tournament_wins'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'tournament_champion')) {
          awarded.add('tournament_champion');
        }
      }

      if (!existingAchievements.contains('tournament_veteran') && 
          (stats['tournaments_joined'] ?? 0) >= 10) {
        if (await awardAchievement(userId, 'tournament_veteran')) {
          awarded.add('tournament_veteran');
        }
      }

      if (!existingAchievements.contains('tournament_host') && 
          (stats['tournaments_hosted'] ?? 0) >= 1) {
        if (await awardAchievement(userId, 'tournament_host')) {
          awarded.add('tournament_host');
        }
      }

    } catch (e) {
      ErrorHandler.logError('Failed to check achievements', e);
    }

    return awarded;
  }

  /// Get user stats for achievement checking
  Future<Map<String, int>> _getUserStats(String userId) async {
    final stats = <String, int>{};

    try {
      // Get profile stats
      final profile = await _client
          .from('profiles')
          .select('follower_count, following_count')
          .eq('id', userId)
          .single();

      stats['followers'] = (profile['follower_count'] ?? 0) as int;
      stats['following'] = (profile['following_count'] ?? 0) as int;

      // Get post count
      final posts = await _client
          .from('posts')
          .select('id')
          .eq('user_id', userId);
      stats['posts'] = (posts as List).length;

      // Get reel count
      final reels = await _client
          .from('reels')
          .select('id')
          .eq('user_id', userId);
      stats['reels'] = (reels as List).length;

      // Get community stats
      final communitiesJoined = await _client
          .from('community_members')
          .select('id')
          .eq('user_id', userId);
      stats['communities_joined'] = (communitiesJoined as List).length;

      final communitiesCreated = await _client
          .from('communities')
          .select('id')
          .eq('created_by', userId);
      stats['communities_created'] = (communitiesCreated as List).length;

      final communityPosts = await _client
          .from('community_posts')
          .select('id')
          .eq('author_id', userId);
      stats['community_posts'] = (communityPosts as List).length;

      // Get tournament stats
      try {
        final tournamentsJoined = await _client
            .from('tournament_participants')
            .select('id')
            .eq('user_id', userId);
        stats['tournaments_joined'] = (tournamentsJoined as List).length;

        final tournamentsHosted = await _client
            .from('tournaments')
            .select('id')
            .eq('created_by', userId);
        stats['tournaments_hosted'] = (tournamentsHosted as List).length;

        final matchWins = await _client
            .from('tournament_matches')
            .select('id')
            .eq('winner_id', userId);
        stats['match_wins'] = (matchWins as List).length;

        final tournamentWins = await _client
            .from('tournaments')
            .select('id')
            .eq('winner_id', userId);
        stats['tournament_wins'] = (tournamentWins as List).length;
      } catch (e) {
        // Tournament tables might not exist
        stats['tournaments_joined'] = 0;
        stats['tournaments_hosted'] = 0;
        stats['match_wins'] = 0;
        stats['tournament_wins'] = 0;
      }

    } catch (e) {
      ErrorHandler.logError('Failed to get user stats', e);
    }

    return stats;
  }

  /// Get total achievement points for user
  Future<int> getTotalAchievementPoints(String userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      return userAchievements.fold<int>(
        0,
        (sum, ua) => sum + (ua.achievement?.points ?? 0),
      );
    } catch (e) {
      return 0;
    }
  }

  /// Get achievement completion percentage
  Future<double> getCompletionPercentage(String userId) async {
    try {
      final userAchievements = await getUserAchievements(userId);
      final totalAchievements = achievements.length;
      if (totalAchievements == 0) return 0;
      return (userAchievements.length / totalAchievements) * 100;
    } catch (e) {
      return 0;
    }
  }

  // === Event Hooks ===

  /// Called when user creates a post
  Future<void> onPostCreated(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user creates a reel
  Future<void> onReelCreated(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user joins a community
  Future<void> onCommunityJoined(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user creates a community
  Future<void> onCommunityCreated(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user joins a tournament
  Future<void> onTournamentJoined(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user wins a match
  Future<void> onMatchWon(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user wins a tournament
  Future<void> onTournamentWon(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user hosts a tournament
  Future<void> onTournamentHosted(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user gains a follower
  Future<void> onFollowerGained(String userId) async {
    await checkAndAwardAchievements(userId);
  }

  /// Called when user follows someone
  Future<void> onUserFollowed(String userId) async {
    await checkAndAwardAchievements(userId);
  }
}

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(
    ref.watch(achievementRepositoryProvider),
    ref.watch(leaderboardRepositoryProvider),
    ref.watch(notificationRepositoryProvider),
  );
});
