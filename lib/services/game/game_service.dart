import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/game/game.dart';
import 'package:gamer_flick/models/post/highlight.dart';
import 'package:gamer_flick/utils/error_handler.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // GAME MANAGEMENT
  // =====================================================

  /// Get all games
  Future<List<Game>> getAllGames({int limit = 50}) async {
    try {
      final response =
          await _client.from('games').select('*').order('name').limit(limit);

      return (response as List).map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get games', e);
      return [];
    }
  }

  /// Get popular games
  Future<List<Game>> getPopularGames({int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get popular games', e);
      return [];
    }
  }

  /// Get game by ID
  Future<Game?> getGameById(String gameId) async {
    try {
      final response =
          await _client.from('games').select('*').eq('id', gameId).single();

      return Game.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get game', e);
      return null;
    }
  }

  /// Search games
  Future<List<Game>> searchGames(String query, {int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .or('name.ilike.%$query%,genre.ilike.%$query%,platforms.cs.{$query}')
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to search games', e);
      return [];
    }
  }

  /// Get games by genre
  Future<List<Game>> getGamesByGenre(String genre, {int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .eq('genre', genre)
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get games by genre', e);
      return [];
    }
  }

  /// Get games by platform
  Future<List<Game>> getGamesByPlatform(String platform,
      {int limit = 20}) async {
    try {
      final response = await _client
          .from('games')
          .select('*')
          .contains('platforms', [platform])
          .order('popularity_score', ascending: false)
          .limit(limit);

      return (response as List).map((json) => Game.fromJson(json)).toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get games by platform', e);
      return [];
    }
  }

  // =====================================================
  // ACHIEVEMENTS
  // =====================================================

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    try {
      final response = await _client.from('user_achievements').select('''
            *,
            achievement:achievement_id(
              id,
              name,
              description,
              icon_url,
              points,
              rarity
            )
          ''').eq('user_id', userId).order('unlocked_at', ascending: false);

      return (response as List)
          .map((item) => {
                'achievement': item['achievement'],
                'unlocked_at': item['unlocked_at'],
                'progress': item['progress'] ?? 100,
              })
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get user achievements', e);
      return [];
    }
  }

  /// Unlock an achievement
  Future<bool> unlockAchievement({
    required String achievementId,
    int progress = 100,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Check if already unlocked
      final existing = await _client
          .from('user_achievements')
          .select()
          .eq('achievement_id', achievementId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (existing != null) {
        // Update progress if higher
        if (progress > (existing['progress'] ?? 0)) {
          await _client
              .from('user_achievements')
              .update({'progress': progress}).eq('id', existing['id']);
        }
        return true;
      }

      // Unlock achievement
      await _client.from('user_achievements').insert({
        'achievement_id': achievementId,
        'user_id': currentUser.id,
        'progress': progress,
        'unlocked_at': DateTime.now().toIso8601String(),
      });

      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to unlock achievement', e);
      return false;
    }
  }

  /// Get achievement progress
  Future<Map<String, dynamic>> getAchievementProgress(
      String achievementId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) return {};

      final response = await _client
          .from('user_achievements')
          .select('progress, unlocked_at')
          .eq('achievement_id', achievementId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      return response ?? {};
    } catch (e) {
      ErrorHandler.logError('Failed to get achievement progress', e);
      return {};
    }
  }

  // =====================================================
  // HIGHLIGHTS & CLIPS
  // =====================================================

  /// Create a highlight
  Future<Highlight?> createHighlight({
    required String gameId,
    required String title,
    required String videoUrl,
    String? thumbnailUrl,
    String? description,
    Duration? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final highlightData = {
        'user_id': currentUser.id,
        'game_id': gameId,
        'title': title,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'description': description,
        'duration': duration?.inSeconds,
        'metadata': metadata ?? {},
      };

      final response =
          await _client.from('highlights').insert(highlightData).select('''
            *,
            user:user_id(
              profiles(
                user_id,
                username,
                display_name,
                avatar_url
              )
            ),
            game:game_id(
              id,
              name,
              genre
            )
          ''').single();

      return Highlight.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to create highlight', e);
      return null;
    }
  }

  /// Get highlights for a game
  Future<List<Highlight>> getGameHighlights(String gameId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('highlights')
          .select('*')
          .eq('game_id', gameId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Highlight.fromJson(json))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get game highlights', e);
      return [];
    }
  }

  /// Get user's highlights
  Future<List<Highlight>> getUserHighlights(String userId,
      {int limit = 20, int offset = 0}) async {
    try {
      final response = await _client
          .from('highlights')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Highlight.fromJson(json))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get user highlights', e);
      return [];
    }
  }

  /// Delete a highlight
  Future<bool> deleteHighlight(String highlightId) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Verify ownership
      final highlight = await _client
          .from('highlights')
          .select('user_id')
          .eq('id', highlightId)
          .single();

      if (highlight['user_id'] != currentUser.id) {
        throw Exception('Not authorized to delete this highlight');
      }

      await _client.from('highlights').delete().eq('id', highlightId);
      return true;
    } catch (e) {
      ErrorHandler.logError('Failed to delete highlight', e);
      return false;
    }
  }

  // =====================================================
  // GAMING STATISTICS
  // =====================================================

  /// Get user gaming statistics
  Future<Map<String, dynamic>> getUserGamingStats(String userId) async {
    try {
      // Get achievements count
      final achievementsCount = await _client
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId);

      // Get highlights count
      final highlightsCount =
          await _client.from('highlights').select('id').eq('user_id', userId);

      return {
        'games_played': 0,
        'total_score': 0,
        'achievements_unlocked': (achievementsCount as List).length,
        'highlights_created': (highlightsCount as List).length,
        'favorite_games': [],
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get gaming stats', e);
      return {};
    }
  }

  /// Get game statistics
  Future<Map<String, dynamic>> getGameStats(String gameId) async {
    try {
      return {
        'total_players': 0,
        'average_score': 0,
        'top_score': 0,
        'leaderboard_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      ErrorHandler.logError('Failed to get game stats', e);
      return {};
    }
  }

  // =====================================================
  // REAL-TIME SUBSCRIPTIONS
  // =====================================================

  /// Subscribe to new highlights
  Stream<List<Highlight>> subscribeToHighlights(String gameId) {
    return _client
        .from('highlights')
        .stream(primaryKey: ['id'])
        .eq('game_id', gameId)
        .order('created_at', ascending: false)
        .map((response) => (response as List)
            .map((json) => Highlight.fromJson(json))
            .toList());
  }
}
