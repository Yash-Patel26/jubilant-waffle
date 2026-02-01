import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Karma Service for Reddit-style reputation system
/// Tracks user karma from post and comment engagement
class KarmaService {
  static final KarmaService _instance = KarmaService._internal();
  factory KarmaService() => _instance;
  KarmaService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // === Karma Configuration ===

  /// Points for different actions
  static const int POST_UPVOTE_KARMA = 1;
  static const int POST_DOWNVOTE_KARMA = -1;
  static const int COMMENT_UPVOTE_KARMA = 1;
  static const int COMMENT_DOWNVOTE_KARMA = -1;
  static const int POST_CREATED_KARMA = 1;
  static const int COMMENT_CREATED_KARMA = 1;
  static const int AWARD_RECEIVED_KARMA = 10;

  /// Karma tiers with thresholds
  static const Map<String, int> KARMA_TIERS = {
    'Newcomer': 0,
    'Member': 100,
    'Contributor': 500,
    'Established': 1000,
    'Trusted': 5000,
    'Veteran': 10000,
    'Elite': 25000,
    'Legend': 50000,
  };

  // === Karma Queries ===

  /// Get user's total karma
  Future<UserKarma> getUserKarma(String userId) async {
    try {
      final response = await _client
          .from('user_karma')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Initialize karma for user
        return await _initializeUserKarma(userId);
      }

      return UserKarma.fromJson(response);
    } catch (e) {
      ErrorHandler.logError('Failed to get user karma', e);
      return UserKarma.empty(userId);
    }
  }

  /// Initialize karma record for new user
  Future<UserKarma> _initializeUserKarma(String userId) async {
    try {
      final karma = UserKarma.empty(userId);
      await _client.from('user_karma').insert(karma.toJson());
      return karma;
    } catch (e) {
      return UserKarma.empty(userId);
    }
  }

  /// Get user's karma breakdown by type
  Future<Map<String, int>> getKarmaBreakdown(String userId) async {
    final karma = await getUserKarma(userId);
    return {
      'Post Karma': karma.postKarma,
      'Comment Karma': karma.commentKarma,
      'Award Karma': karma.awardKarma,
      'Total': karma.totalKarma,
    };
  }

  /// Get user's karma tier
  Future<String> getUserKarmaTier(String userId) async {
    final karma = await getUserKarma(userId);
    return getKarmaTier(karma.totalKarma);
  }

  /// Calculate karma tier from points
  String getKarmaTier(int karmaPoints) {
    String tier = 'Newcomer';
    for (final entry in KARMA_TIERS.entries) {
      if (karmaPoints >= entry.value) {
        tier = entry.key;
      }
    }
    return tier;
  }

  /// Get next karma tier and points needed
  KarmaTierProgress getTierProgress(int currentKarma) {
    String currentTier = 'Newcomer';
    String? nextTier;
    int? pointsToNext;

    final tiers = KARMA_TIERS.entries.toList();
    for (int i = 0; i < tiers.length; i++) {
      if (currentKarma >= tiers[i].value) {
        currentTier = tiers[i].key;
        if (i < tiers.length - 1) {
          nextTier = tiers[i + 1].key;
          pointsToNext = tiers[i + 1].value - currentKarma;
        }
      }
    }

    return KarmaTierProgress(
      currentTier: currentTier,
      currentKarma: currentKarma,
      nextTier: nextTier,
      pointsToNext: pointsToNext,
    );
  }

  // === Karma Updates ===

  /// Add karma for a post receiving an upvote
  Future<void> onPostUpvoted(String postAuthorId) async {
    await _addKarma(postAuthorId, KarmaType.post, POST_UPVOTE_KARMA);
  }

  /// Remove karma for a post receiving a downvote
  Future<void> onPostDownvoted(String postAuthorId) async {
    await _addKarma(postAuthorId, KarmaType.post, POST_DOWNVOTE_KARMA);
  }

  /// Add karma for a comment receiving an upvote
  Future<void> onCommentUpvoted(String commentAuthorId) async {
    await _addKarma(commentAuthorId, KarmaType.comment, COMMENT_UPVOTE_KARMA);
  }

  /// Remove karma for a comment receiving a downvote
  Future<void> onCommentDownvoted(String commentAuthorId) async {
    await _addKarma(commentAuthorId, KarmaType.comment, COMMENT_DOWNVOTE_KARMA);
  }

  /// Add karma for creating a post
  Future<void> onPostCreated(String authorId) async {
    await _addKarma(authorId, KarmaType.post, POST_CREATED_KARMA);
  }

  /// Add karma for creating a comment
  Future<void> onCommentCreated(String authorId) async {
    await _addKarma(authorId, KarmaType.comment, COMMENT_CREATED_KARMA);
  }

  /// Add karma for receiving an award
  Future<void> onAwardReceived(String recipientId, int awardValue) async {
    await _addKarma(recipientId, KarmaType.award, awardValue);
  }

  /// Internal method to add karma
  Future<void> _addKarma(String userId, KarmaType type, int amount) async {
    try {
      // Try using RPC first for atomic update
      await _client.rpc('add_user_karma', params: {
        'user_uuid': userId,
        'karma_type': type.name,
        'karma_amount': amount,
      }).onError((error, stackTrace) async {
        // Fallback to manual update
        await _manualKarmaUpdate(userId, type, amount);
      });

      // Log karma change for history
      await _logKarmaChange(userId, type, amount);
    } catch (e) {
      ErrorHandler.logError('Failed to add karma', e);
    }
  }

  /// Manual karma update fallback
  Future<void> _manualKarmaUpdate(
    String userId,
    KarmaType type,
    int amount,
  ) async {
    try {
      final currentKarma = await getUserKarma(userId);

      int newPostKarma = currentKarma.postKarma;
      int newCommentKarma = currentKarma.commentKarma;
      int newAwardKarma = currentKarma.awardKarma;

      switch (type) {
        case KarmaType.post:
          newPostKarma += amount;
          break;
        case KarmaType.comment:
          newCommentKarma += amount;
          break;
        case KarmaType.award:
          newAwardKarma += amount;
          break;
      }

      final newTotal = newPostKarma + newCommentKarma + newAwardKarma;

      await _client.from('user_karma').upsert({
        'user_id': userId,
        'post_karma': newPostKarma,
        'comment_karma': newCommentKarma,
        'award_karma': newAwardKarma,
        'total_karma': newTotal,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      ErrorHandler.logError('Failed manual karma update', e);
    }
  }

  /// Log karma change for history
  Future<void> _logKarmaChange(
    String userId,
    KarmaType type,
    int amount,
  ) async {
    try {
      await _client.from('karma_history').insert({
        'user_id': userId,
        'karma_type': type.name,
        'amount': amount,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent failure for history logging
    }
  }

  // === Vote Reversal ===

  /// Handle vote change (e.g., upvote removed or changed to downvote)
  Future<void> onVoteChanged({
    required String authorId,
    required bool isPost,
    required int previousVote,
    required int newVote,
  }) async {
    final type = isPost ? KarmaType.post : KarmaType.comment;
    final upvoteKarma = isPost ? POST_UPVOTE_KARMA : COMMENT_UPVOTE_KARMA;
    final downvoteKarma = isPost ? POST_DOWNVOTE_KARMA : COMMENT_DOWNVOTE_KARMA;

    // Remove previous vote karma
    if (previousVote == 1) {
      await _addKarma(authorId, type, -upvoteKarma);
    } else if (previousVote == -1) {
      await _addKarma(authorId, type, -downvoteKarma);
    }

    // Add new vote karma
    if (newVote == 1) {
      await _addKarma(authorId, type, upvoteKarma);
    } else if (newVote == -1) {
      await _addKarma(authorId, type, downvoteKarma);
    }
  }

  // === Karma History ===

  /// Get karma history for a user
  Future<List<KarmaHistoryEntry>> getKarmaHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('karma_history')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((data) => KarmaHistoryEntry.fromJson(data as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Get karma gained in last N days
  Future<int> getKarmaGainedInPeriod(
    String userId, {
    int days = 7,
  }) async {
    try {
      final cutoff = DateTime.now().subtract(Duration(days: days));
      final response = await _client
          .from('karma_history')
          .select('amount')
          .eq('user_id', userId)
          .gte('created_at', cutoff.toIso8601String());

      int total = 0;
      for (final entry in response as List) {
        total += (entry['amount'] as int?) ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // === Leaderboard ===

  /// Get karma leaderboard
  Future<List<UserKarma>> getKarmaLeaderboard({
    KarmaType? type,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final orderColumn = switch (type) {
        KarmaType.post => 'post_karma',
        KarmaType.comment => 'comment_karma',
        KarmaType.award => 'award_karma',
        null => 'total_karma',
      };

      final response = await _client
          .from('user_karma')
          .select('''
            *,
            profiles!user_karma_user_id_fkey(
              id,
              username,
              avatar_url
            )
          ''')
          .order(orderColumn, ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((data) => UserKarma.fromJson(data))
          .toList();
    } catch (e) {
      ErrorHandler.logError('Failed to get karma leaderboard', e);
      return [];
    }
  }

  /// Get user's karma rank
  Future<int?> getUserKarmaRank(String userId) async {
    try {
      final karma = await getUserKarma(userId);

      final response = await _client
          .from('user_karma')
          .select('user_id')
          .gt('total_karma', karma.totalKarma);

      return (response as List).length + 1;
    } catch (e) {
      return null;
    }
  }

  // === Karma Requirements ===

  /// Check if user meets karma requirement
  Future<bool> meetsKarmaRequirement(
    String userId,
    int requiredKarma,
  ) async {
    final karma = await getUserKarma(userId);
    return karma.totalKarma >= requiredKarma;
  }

  /// Check if user can post in community (karma-gated)
  Future<bool> canPostInCommunity(
    String userId,
    String communityId,
  ) async {
    try {
      final community = await _client
          .from('communities')
          .select('karma_requirement')
          .eq('id', communityId)
          .single();

      final requirement = community['karma_requirement'] as int? ?? 0;
      return await meetsKarmaRequirement(userId, requirement);
    } catch (e) {
      return true; // Allow by default if check fails
    }
  }
}

/// User karma data
class UserKarma {
  final String oderId;
  final int postKarma;
  final int commentKarma;
  final int awardKarma;
  final int totalKarma;
  final DateTime updatedAt;
  final Map<String, dynamic>? profile;

  const UserKarma({
    required this.oderId,
    required this.postKarma,
    required this.commentKarma,
    required this.awardKarma,
    required this.totalKarma,
    required this.updatedAt,
    this.profile,
  });

  // Alias for backward compatibility
  String get oderId2 => oderId;

  factory UserKarma.empty(String userId) {
    return UserKarma(
      oderId: userId,
      postKarma: 0,
      commentKarma: 0,
      awardKarma: 0,
      totalKarma: 0,
      updatedAt: DateTime.now(),
    );
  }

  factory UserKarma.fromJson(Map<String, dynamic> json) {
    return UserKarma(
      oderId: json['user_id'] as String,
      postKarma: json['post_karma'] as int? ?? 0,
      commentKarma: json['comment_karma'] as int? ?? 0,
      awardKarma: json['award_karma'] as int? ?? 0,
      totalKarma: json['total_karma'] as int? ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      profile: json['profiles'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': oderId,
      'post_karma': postKarma,
      'comment_karma': commentKarma,
      'award_karma': awardKarma,
      'total_karma': totalKarma,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Get karma tier
  String get tier => KarmaService().getKarmaTier(totalKarma);

  /// Get formatted karma display
  String get formattedKarma {
    if (totalKarma >= 1000000) {
      return '${(totalKarma / 1000000).toStringAsFixed(1)}M';
    } else if (totalKarma >= 1000) {
      return '${(totalKarma / 1000).toStringAsFixed(1)}K';
    }
    return totalKarma.toString();
  }
}

/// Karma types
enum KarmaType {
  post,
  comment,
  award,
}

/// Karma history entry
class KarmaHistoryEntry {
  final String id;
  final String oderId;
  final KarmaType type;
  final int amount;
  final DateTime createdAt;

  const KarmaHistoryEntry({
    required this.id,
    required this.oderId,
    required this.type,
    required this.amount,
    required this.createdAt,
  });

  factory KarmaHistoryEntry.fromJson(Map<String, dynamic> json) {
    return KarmaHistoryEntry(
      id: json['id'] as String,
      oderId: json['user_id'] as String,
      type: KarmaType.values.firstWhere(
        (t) => t.name == json['karma_type'],
        orElse: () => KarmaType.post,
      ),
      amount: json['amount'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Karma tier progress
class KarmaTierProgress {
  final String currentTier;
  final int currentKarma;
  final String? nextTier;
  final int? pointsToNext;

  const KarmaTierProgress({
    required this.currentTier,
    required this.currentKarma,
    this.nextTier,
    this.pointsToNext,
  });

  /// Get progress percentage to next tier
  double? get progressPercent {
    if (nextTier == null || pointsToNext == null) return null;

    final currentThreshold = KarmaService.KARMA_TIERS[currentTier] ?? 0;
    final nextThreshold = KarmaService.KARMA_TIERS[nextTier] ?? 0;
    final range = nextThreshold - currentThreshold;

    if (range <= 0) return 100;

    final progress = currentKarma - currentThreshold;
    return (progress / range * 100).clamp(0, 100);
  }
}
