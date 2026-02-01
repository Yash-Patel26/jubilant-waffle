import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// ELO Rating Service for competitive matchmaking
/// Based on the standard ELO rating system used in chess and esports
class EloRatingService {
  static final EloRatingService _instance = EloRatingService._internal();
  factory EloRatingService() => _instance;
  EloRatingService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // ELO Configuration
  static const int INITIAL_RATING = 1200;
  static const int MIN_RATING = 100;
  static const int MAX_RATING = 3000;
  
  // K-Factor determines how much ratings change per game
  // Higher K = more volatile, Lower K = more stable
  static const int K_FACTOR_NEW_PLAYER = 40;      // < 30 games
  static const int K_FACTOR_INTERMEDIATE = 32;   // 30-100 games
  static const int K_FACTOR_EXPERIENCED = 24;    // > 100 games
  static const int K_FACTOR_PROVISIONAL = 48;    // < 10 games

  // Rank tiers based on ELO
  static const Map<String, int> RANK_THRESHOLDS = {
    'Bronze': 0,
    'Silver': 1000,
    'Gold': 1200,
    'Platinum': 1400,
    'Diamond': 1600,
    'Master': 1800,
    'Grandmaster': 2000,
    'Champion': 2200,
    'Legend': 2400,
  };

  /// Get player's ELO rating for a game
  Future<int> getPlayerRating(String userId, String gameId) async {
    try {
      final response = await _client
          .from('player_ratings')
          .select('rating')
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .maybeSingle();

      return (response?['rating'] as int?) ?? INITIAL_RATING;
    } catch (e) {
      return INITIAL_RATING;
    }
  }

  /// Get full rating info for a player
  Future<PlayerRating?> getPlayerRatingInfo(String userId, String gameId) async {
    try {
      final response = await _client
          .from('player_ratings')
          .select('*')
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .maybeSingle();

      if (response == null) {
        return PlayerRating(
          oderId: userId,
          gameId: gameId,
          rating: INITIAL_RATING,
          gamesPlayed: 0,
          wins: 0,
          losses: 0,
          winStreak: 0,
          peakRating: INITIAL_RATING,
        );
      }

      return PlayerRating.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// Calculate expected score (probability of winning)
  double _calculateExpectedScore(int playerRating, int opponentRating) {
    return 1 / (1 + pow(10, (opponentRating - playerRating) / 400));
  }

  /// Get K-Factor based on games played
  int _getKFactor(int gamesPlayed, int currentRating) {
    if (gamesPlayed < 10) return K_FACTOR_PROVISIONAL;
    if (gamesPlayed < 30) return K_FACTOR_NEW_PLAYER;
    if (gamesPlayed < 100) return K_FACTOR_INTERMEDIATE;
    return K_FACTOR_EXPERIENCED;
  }

  /// Calculate new ratings after a match
  EloResult calculateNewRatings({
    required int player1Rating,
    required int player2Rating,
    required bool player1Won,
    required int player1GamesPlayed,
    required int player2GamesPlayed,
  }) {
    final expected1 = _calculateExpectedScore(player1Rating, player2Rating);
    final expected2 = _calculateExpectedScore(player2Rating, player1Rating);

    final actual1 = player1Won ? 1.0 : 0.0;
    final actual2 = player1Won ? 0.0 : 1.0;

    final k1 = _getKFactor(player1GamesPlayed, player1Rating);
    final k2 = _getKFactor(player2GamesPlayed, player2Rating);

    var newRating1 = (player1Rating + k1 * (actual1 - expected1)).round();
    var newRating2 = (player2Rating + k2 * (actual2 - expected2)).round();

    // Clamp ratings
    newRating1 = newRating1.clamp(MIN_RATING, MAX_RATING);
    newRating2 = newRating2.clamp(MIN_RATING, MAX_RATING);

    return EloResult(
      player1NewRating: newRating1,
      player2NewRating: newRating2,
      player1Change: newRating1 - player1Rating,
      player2Change: newRating2 - player2Rating,
    );
  }

  /// Record match result and update ratings
  Future<EloResult?> recordMatchResult({
    required String player1Id,
    required String player2Id,
    required String gameId,
    required String winnerId,
    String? matchId,
    String? tournamentId,
  }) async {
    try {
      // Get current ratings
      final player1Info = await getPlayerRatingInfo(player1Id, gameId);
      final player2Info = await getPlayerRatingInfo(player2Id, gameId);

      if (player1Info == null || player2Info == null) {
        return null;
      }

      final player1Won = winnerId == player1Id;

      // Calculate new ratings
      final result = calculateNewRatings(
        player1Rating: player1Info.rating,
        player2Rating: player2Info.rating,
        player1Won: player1Won,
        player1GamesPlayed: player1Info.gamesPlayed,
        player2GamesPlayed: player2Info.gamesPlayed,
      );

      // Update player 1 rating
      await _updatePlayerRating(
        userId: player1Id,
        gameId: gameId,
        newRating: result.player1NewRating,
        ratingChange: result.player1Change,
        won: player1Won,
        currentInfo: player1Info,
      );

      // Update player 2 rating
      await _updatePlayerRating(
        userId: player2Id,
        gameId: gameId,
        newRating: result.player2NewRating,
        ratingChange: result.player2Change,
        won: !player1Won,
        currentInfo: player2Info,
      );

      // Record rating history
      await _recordRatingHistory(
        player1Id: player1Id,
        player2Id: player2Id,
        gameId: gameId,
        player1OldRating: player1Info.rating,
        player2OldRating: player2Info.rating,
        player1NewRating: result.player1NewRating,
        player2NewRating: result.player2NewRating,
        winnerId: winnerId,
        matchId: matchId,
        tournamentId: tournamentId,
      );

      return result;
    } catch (e) {
      ErrorHandler.logError('Failed to record match result', e);
      return null;
    }
  }

  /// Update player rating in database
  Future<void> _updatePlayerRating({
    required String userId,
    required String gameId,
    required int newRating,
    required int ratingChange,
    required bool won,
    required PlayerRating currentInfo,
  }) async {
    try {
      final newWinStreak = won ? currentInfo.winStreak + 1 : 0;
      final newPeakRating = max(newRating, currentInfo.peakRating);

      await _client.from('player_ratings').upsert({
        'user_id': userId,
        'game_id': gameId,
        'rating': newRating,
        'games_played': currentInfo.gamesPlayed + 1,
        'wins': currentInfo.wins + (won ? 1 : 0),
        'losses': currentInfo.losses + (won ? 0 : 1),
        'win_streak': newWinStreak,
        'best_win_streak': max(newWinStreak, currentInfo.bestWinStreak),
        'peak_rating': newPeakRating,
        'last_rating_change': ratingChange,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,game_id');
    } catch (e) {
      ErrorHandler.logError('Failed to update player rating', e);
    }
  }

  /// Record rating history for analytics
  Future<void> _recordRatingHistory({
    required String player1Id,
    required String player2Id,
    required String gameId,
    required int player1OldRating,
    required int player2OldRating,
    required int player1NewRating,
    required int player2NewRating,
    required String winnerId,
    String? matchId,
    String? tournamentId,
  }) async {
    try {
      await _client.from('rating_history').insert([
        {
          'user_id': player1Id,
          'game_id': gameId,
          'old_rating': player1OldRating,
          'new_rating': player1NewRating,
          'rating_change': player1NewRating - player1OldRating,
          'opponent_id': player2Id,
          'opponent_rating': player2OldRating,
          'won': winnerId == player1Id,
          'match_id': matchId,
          'tournament_id': tournamentId,
          'recorded_at': DateTime.now().toIso8601String(),
        },
        {
          'user_id': player2Id,
          'game_id': gameId,
          'old_rating': player2OldRating,
          'new_rating': player2NewRating,
          'rating_change': player2NewRating - player2OldRating,
          'opponent_id': player1Id,
          'opponent_rating': player1OldRating,
          'won': winnerId == player2Id,
          'match_id': matchId,
          'tournament_id': tournamentId,
          'recorded_at': DateTime.now().toIso8601String(),
        },
      ]);
    } catch (e) {
      ErrorHandler.logError('Failed to record rating history', e);
    }
  }

  /// Get rank name from rating
  String getRankFromRating(int rating) {
    String rank = 'Bronze';
    for (final entry in RANK_THRESHOLDS.entries) {
      if (rating >= entry.value) {
        rank = entry.key;
      }
    }
    return rank;
  }

  /// Get rank tier (1-5) within a rank
  int getRankTier(int rating) {
    final rank = getRankFromRating(rating);
    final threshold = RANK_THRESHOLDS[rank] ?? 0;
    final nextThreshold = _getNextThreshold(rank);
    
    if (nextThreshold == null) return 1; // Top rank
    
    final range = nextThreshold - threshold;
    final progress = rating - threshold;
    final tier = 5 - ((progress / range) * 4).floor();
    
    return tier.clamp(1, 5);
  }

  int? _getNextThreshold(String rank) {
    final keys = RANK_THRESHOLDS.keys.toList();
    final index = keys.indexOf(rank);
    if (index < 0 || index >= keys.length - 1) return null;
    return RANK_THRESHOLDS[keys[index + 1]];
  }

  /// Get leaderboard for a game
  Future<List<Map<String, dynamic>>> getGameRatingLeaderboard(
    String gameId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('player_ratings')
          .select('''
            *,
            profiles!player_ratings_user_id_fkey(
              id,
              username,
              display_name,
              avatar_url
            )
          ''')
          .eq('game_id', gameId)
          .gt('games_played', 0)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      final List<Map<String, dynamic>> results = [];
      int rank = offset + 1;
      for (final item in response as List) {
        results.add({
          ...item,
          'rank': rank++,
          'rank_name': getRankFromRating(item['rating'] as int),
          'rank_tier': getRankTier(item['rating'] as int),
        });
      }

      return results;
    } catch (e) {
      ErrorHandler.logError('Failed to get rating leaderboard', e);
      return [];
    }
  }

  /// Find suitable opponents for matchmaking
  Future<List<Map<String, dynamic>>> findMatchmakingOpponents(
    String userId,
    String gameId, {
    int ratingRange = 100,
    int limit = 10,
  }) async {
    try {
      final playerRating = await getPlayerRating(userId, gameId);

      final response = await _client
          .from('player_ratings')
          .select('''
            *,
            profiles!player_ratings_user_id_fkey(
              id,
              username,
              display_name,
              avatar_url,
              is_online
            )
          ''')
          .eq('game_id', gameId)
          .neq('user_id', userId)
          .gte('rating', playerRating - ratingRange)
          .lte('rating', playerRating + ratingRange)
          .order('rating', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      ErrorHandler.logError('Failed to find matchmaking opponents', e);
      return [];
    }
  }

  /// Get player's rating history
  Future<List<Map<String, dynamic>>> getRatingHistory(
    String userId,
    String gameId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('rating_history')
          .select('''
            *,
            opponent:profiles!rating_history_opponent_id_fkey(
              id,
              username,
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .eq('game_id', gameId)
          .order('recorded_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      ErrorHandler.logError('Failed to get rating history', e);
      return [];
    }
  }
}

/// Result of an ELO calculation
class EloResult {
  final int player1NewRating;
  final int player2NewRating;
  final int player1Change;
  final int player2Change;

  const EloResult({
    required this.player1NewRating,
    required this.player2NewRating,
    required this.player1Change,
    required this.player2Change,
  });
}

/// Player rating info
class PlayerRating {
  final String oderId;
  final String gameId;
  final int rating;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int winStreak;
  final int bestWinStreak;
  final int peakRating;
  final int lastRatingChange;

  const PlayerRating({
    required this.oderId,
    required this.gameId,
    required this.rating,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    this.winStreak = 0,
    this.bestWinStreak = 0,
    required this.peakRating,
    this.lastRatingChange = 0,
  });

  // Alias for userId to maintain backward compatibility
  String get userId => oderId;

  double get winRate => gamesPlayed > 0 ? (wins / gamesPlayed) * 100 : 0;

  factory PlayerRating.fromJson(Map<String, dynamic> json) {
    return PlayerRating(
      oderId: json['user_id'] as String,
      gameId: json['game_id'] as String,
      rating: json['rating'] as int? ?? EloRatingService.INITIAL_RATING,
      gamesPlayed: json['games_played'] as int? ?? 0,
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      winStreak: json['win_streak'] as int? ?? 0,
      bestWinStreak: json['best_win_streak'] as int? ?? 0,
      peakRating: json['peak_rating'] as int? ?? EloRatingService.INITIAL_RATING,
      lastRatingChange: json['last_rating_change'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'game_id': gameId,
      'rating': rating,
      'games_played': gamesPlayed,
      'wins': wins,
      'losses': losses,
      'win_streak': winStreak,
      'best_win_streak': bestWinStreak,
      'peak_rating': peakRating,
      'last_rating_change': lastRatingChange,
    };
  }
}
