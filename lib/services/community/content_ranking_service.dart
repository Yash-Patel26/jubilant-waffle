import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/community/community_post.dart';
import 'package:gamer_flick/utils/error_handler.dart';

/// Content Ranking Service with Reddit/HackerNews style algorithms
/// Implements hot, rising, controversial, and best sorting with time decay
class ContentRankingService {
  static final ContentRankingService _instance = ContentRankingService._internal();
  factory ContentRankingService() => _instance;
  ContentRankingService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  // === Algorithm Constants ===

  /// Gravity factor for hot ranking (higher = faster decay)
  /// Reddit uses ~1.8, HackerNews uses 1.8
  static const double HOT_GRAVITY = 1.8;

  /// Base time offset (prevents division by zero and gives new posts a boost)
  static const double TIME_OFFSET_HOURS = 2.0;

  /// Minimum score to be considered for trending
  static const int MIN_TRENDING_SCORE = 5;

  /// Rising threshold (engagement velocity per hour)
  static const double RISING_VELOCITY_THRESHOLD = 0.5;

  /// Controversial ratio range (posts with ~50% upvote ratio)
  static const double CONTROVERSIAL_MIN_RATIO = 0.4;
  static const double CONTROVERSIAL_MAX_RATIO = 0.6;

  /// Wilson confidence level for "best" ranking
  static const double WILSON_CONFIDENCE = 1.96; // 95% confidence

  // === Hot Ranking Algorithm ===

  /// Calculate hot score using Reddit-style algorithm
  /// score = (upvotes - downvotes) / (hours_since_post + time_offset)^gravity
  double calculateHotScore({
    required int upvotes,
    required int downvotes,
    required DateTime createdAt,
    int commentCount = 0,
    int viewCount = 0,
  }) {
    final score = upvotes - downvotes;
    final hoursSincePost = DateTime.now().difference(createdAt).inMinutes / 60.0;

    // Apply time decay
    final timeFactor = pow(hoursSincePost + TIME_OFFSET_HOURS, HOT_GRAVITY);

    // Base hot score
    double hotScore = score / timeFactor;

    // Boost for engagement (comments are more valuable)
    final engagementBoost = (commentCount * 0.5) + (viewCount * 0.01);
    hotScore += engagementBoost / timeFactor;

    return hotScore;
  }

  /// Calculate hot score for a post object
  double getPostHotScore(CommunityPost post) {
    return calculateHotScore(
      upvotes: post.upvotes,
      downvotes: post.downvotes,
      createdAt: post.createdAt,
      commentCount: post.commentCount,
      viewCount: post.viewCount,
    );
  }

  // === Rising Algorithm ===

  /// Calculate rising score based on engagement velocity
  /// Measures how fast a post is gaining engagement
  double calculateRisingScore({
    required int upvotes,
    required int downvotes,
    required DateTime createdAt,
    required int commentCount,
    int? previousScore,
    DateTime? previousScoreTime,
  }) {
    final hoursSincePost = DateTime.now().difference(createdAt).inMinutes / 60.0;

    // Prevent division by zero for very new posts
    if (hoursSincePost < 0.1) {
      return upvotes.toDouble(); // Just use raw upvotes for brand new posts
    }

    final currentScore = upvotes - downvotes;
    final totalEngagement = currentScore + commentCount;

    // Velocity = engagement per hour
    final velocity = totalEngagement / hoursSincePost;

    // If we have historical data, calculate acceleration
    if (previousScore != null && previousScoreTime != null) {
      final hoursBetween =
          DateTime.now().difference(previousScoreTime).inMinutes / 60.0;
      if (hoursBetween > 0) {
        final scoreDelta = currentScore - previousScore;
        final acceleration = scoreDelta / hoursBetween;
        // Weight recent acceleration more
        return velocity + (acceleration * 2);
      }
    }

    // Boost newer posts with good velocity
    final recencyBoost = hoursSincePost < 6 ? 1.5 : 1.0;

    return velocity * recencyBoost;
  }

  // === Controversial Algorithm ===

  /// Calculate controversial score
  /// High activity + split votes = controversial
  double calculateControversialScore({
    required int upvotes,
    required int downvotes,
    required int commentCount,
  }) {
    final totalVotes = upvotes + downvotes;
    if (totalVotes == 0) return 0;

    final upvoteRatio = upvotes / totalVotes;

    // Most controversial when ratio is around 50%
    final controversyFactor = 1.0 - (2 * (upvoteRatio - 0.5)).abs();

    // Weight by total activity (more votes + comments = more controversial)
    final activityScore = totalVotes + (commentCount * 2);

    return controversyFactor * activityScore;
  }

  /// Check if a post is controversial
  bool isControversial({
    required int upvotes,
    required int downvotes,
    int minVotes = 10,
  }) {
    final totalVotes = upvotes + downvotes;
    if (totalVotes < minVotes) return false;

    final ratio = upvotes / totalVotes;
    return ratio >= CONTROVERSIAL_MIN_RATIO && ratio <= CONTROVERSIAL_MAX_RATIO;
  }

  // === Best/Wilson Score Algorithm ===

  /// Calculate Wilson score lower bound (Reddit's "best" ranking)
  /// Provides statistically confident ranking for posts with few votes
  double calculateWilsonScore({
    required int upvotes,
    required int downvotes,
  }) {
    final n = upvotes + downvotes;
    if (n == 0) return 0;

    final z = WILSON_CONFIDENCE;
    final p = upvotes / n;

    // Wilson score interval formula
    final numerator = p +
        (z * z) / (2 * n) -
        z * sqrt((p * (1 - p) + (z * z) / (4 * n)) / n);
    final denominator = 1 + (z * z) / n;

    return numerator / denominator;
  }

  // === Top Score Algorithm ===

  /// Calculate top score with time window
  double calculateTopScore({
    required int upvotes,
    required int downvotes,
    required DateTime createdAt,
    TopTimeWindow window = TopTimeWindow.all,
  }) {
    // Check if post is within time window
    if (!_isWithinTimeWindow(createdAt, window)) {
      return -1; // Exclude from ranking
    }

    return (upvotes - downvotes).toDouble();
  }

  bool _isWithinTimeWindow(DateTime createdAt, TopTimeWindow window) {
    final now = DateTime.now();
    final postAge = now.difference(createdAt);

    switch (window) {
      case TopTimeWindow.hour:
        return postAge.inHours < 1;
      case TopTimeWindow.day:
        return postAge.inDays < 1;
      case TopTimeWindow.week:
        return postAge.inDays < 7;
      case TopTimeWindow.month:
        return postAge.inDays < 30;
      case TopTimeWindow.year:
        return postAge.inDays < 365;
      case TopTimeWindow.all:
        return true;
    }
  }

  // === Sorting Functions ===

  /// Sort posts by hot ranking
  List<CommunityPost> sortByHot(List<CommunityPost> posts) {
    final scored = posts.map((p) => MapEntry(p, getPostHotScore(p))).toList();
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Sort posts by rising
  List<CommunityPost> sortByRising(List<CommunityPost> posts) {
    final scored = posts.map((p) {
      final score = calculateRisingScore(
        upvotes: p.upvotes,
        downvotes: p.downvotes,
        createdAt: p.createdAt,
        commentCount: p.commentCount,
      );
      return MapEntry(p, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Sort posts by controversial
  List<CommunityPost> sortByControversial(List<CommunityPost> posts) {
    // Filter to only controversial posts first
    final controversialPosts = posts.where((p) {
      return isControversial(upvotes: p.upvotes, downvotes: p.downvotes);
    }).toList();

    final scored = controversialPosts.map((p) {
      final score = calculateControversialScore(
        upvotes: p.upvotes,
        downvotes: p.downvotes,
        commentCount: p.commentCount,
      );
      return MapEntry(p, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));

    // Include non-controversial posts at the end, sorted by their controversy factor
    final remaining = posts.where((p) {
      return !isControversial(upvotes: p.upvotes, downvotes: p.downvotes);
    }).toList();

    final remainingScored = remaining.map((p) {
      final score = calculateControversialScore(
        upvotes: p.upvotes,
        downvotes: p.downvotes,
        commentCount: p.commentCount,
      );
      return MapEntry(p, score);
    }).toList();

    remainingScored.sort((a, b) => b.value.compareTo(a.value));

    return [
      ...scored.map((e) => e.key),
      ...remainingScored.map((e) => e.key),
    ];
  }

  /// Sort posts by best (Wilson score)
  List<CommunityPost> sortByBest(List<CommunityPost> posts) {
    final scored = posts.map((p) {
      final score = calculateWilsonScore(
        upvotes: p.upvotes,
        downvotes: p.downvotes,
      );
      return MapEntry(p, score);
    }).toList();

    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.map((e) => e.key).toList();
  }

  /// Sort posts by top with time window
  List<CommunityPost> sortByTop(
    List<CommunityPost> posts, {
    TopTimeWindow window = TopTimeWindow.all,
  }) {
    final filtered = posts.where((p) {
      return _isWithinTimeWindow(p.createdAt, window);
    }).toList();

    filtered.sort((a, b) {
      final scoreA = a.upvotes - a.downvotes;
      final scoreB = b.upvotes - b.downvotes;
      return scoreB.compareTo(scoreA);
    });

    return filtered;
  }

  /// Sort posts by new (most recent first)
  List<CommunityPost> sortByNew(List<CommunityPost> posts) {
    final sorted = List<CommunityPost>.from(posts);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Universal sort function
  List<CommunityPost> sortPosts(
    List<CommunityPost> posts,
    SortType sortType, {
    TopTimeWindow topWindow = TopTimeWindow.all,
  }) {
    switch (sortType) {
      case SortType.hot:
        return sortByHot(posts);
      case SortType.newPosts:
        return sortByNew(posts);
      case SortType.rising:
        return sortByRising(posts);
      case SortType.controversial:
        return sortByControversial(posts);
      case SortType.best:
        return sortByBest(posts);
      case SortType.top:
        return sortByTop(posts, window: topWindow);
    }
  }

  // === Database Integration ===

  /// Fetch and sort posts from database with proper ranking
  Future<List<CommunityPost>> fetchSortedPosts(
    String communityId, {
    SortType sortType = SortType.hot,
    TopTimeWindow topWindow = TopTimeWindow.all,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // Build base query
      var query = _client
          .from('community_posts')
          .select('*, profiles!community_posts_author_id_fkey(*), communities(*)')
          .eq('community_id', communityId)
          .eq('removed', false);

      // For 'new' and 'top' we can sort in database for efficiency
      if (sortType == SortType.newPosts) {
        final response = await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        return (response as List)
            .map((data) => CommunityPost.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      // For time-limited top posts, filter by time
      if (sortType == SortType.top && topWindow != TopTimeWindow.all) {
        final cutoffDate = _getWindowCutoffDate(topWindow);
        query = query.gte('created_at', cutoffDate.toIso8601String());

        final response = await query.order('score', ascending: false);

        return (response as List)
            .map((data) => CommunityPost.fromJson(data as Map<String, dynamic>))
            .toList();
      }

      // For complex rankings (hot, rising, controversial, best),
      // fetch more posts and sort in memory
      final response = await query
          .order('created_at', ascending: false)
          .limit(limit * 3); // Fetch extra for better ranking

      final posts = (response as List)
          .map((data) => CommunityPost.fromJson(data as Map<String, dynamic>))
          .toList();

      // Apply ranking algorithm
      final sorted = sortPosts(posts, sortType, topWindow: topWindow);

      // Return paginated results
      final endIndex = (offset + limit).clamp(0, sorted.length);
      final startIndex = offset.clamp(0, sorted.length);

      return sorted.sublist(startIndex, endIndex);
    } catch (e) {
      ErrorHandler.logError('Failed to fetch sorted posts', e);
      return [];
    }
  }

  DateTime _getWindowCutoffDate(TopTimeWindow window) {
    final now = DateTime.now();
    switch (window) {
      case TopTimeWindow.hour:
        return now.subtract(const Duration(hours: 1));
      case TopTimeWindow.day:
        return now.subtract(const Duration(days: 1));
      case TopTimeWindow.week:
        return now.subtract(const Duration(days: 7));
      case TopTimeWindow.month:
        return now.subtract(const Duration(days: 30));
      case TopTimeWindow.year:
        return now.subtract(const Duration(days: 365));
      case TopTimeWindow.all:
        return DateTime(2020); // Beginning of time for the app
    }
  }

  // === Comment Ranking ===

  /// Sort comments with contest mode support
  List<CommunityPostComment> sortComments(
    List<CommunityPostComment> comments, {
    CommentSortType sortType = CommentSortType.best,
    bool contestMode = false,
  }) {
    if (contestMode) {
      // Randomize order in contest mode
      final shuffled = List<CommunityPostComment>.from(comments);
      shuffled.shuffle(Random());
      return shuffled;
    }

    switch (sortType) {
      case CommentSortType.best:
        final scored = comments.map((c) {
          final score = calculateWilsonScore(
            upvotes: c.upvotes,
            downvotes: c.downvotes,
          );
          return MapEntry(c, score);
        }).toList();
        scored.sort((a, b) => b.value.compareTo(a.value));
        return scored.map((e) => e.key).toList();

      case CommentSortType.top:
        final sorted = List<CommunityPostComment>.from(comments);
        sorted.sort((a, b) => b.score.compareTo(a.score));
        return sorted;

      case CommentSortType.newComments:
        final sorted = List<CommunityPostComment>.from(comments);
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return sorted;

      case CommentSortType.old:
        final sorted = List<CommunityPostComment>.from(comments);
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        return sorted;

      case CommentSortType.controversial:
        final sorted = List<CommunityPostComment>.from(comments);
        sorted.sort((a, b) {
          final controversyA = calculateControversialScore(
            upvotes: a.upvotes,
            downvotes: a.downvotes,
            commentCount: 0,
          );
          final controversyB = calculateControversialScore(
            upvotes: b.upvotes,
            downvotes: b.downvotes,
            commentCount: 0,
          );
          return controversyB.compareTo(controversyA);
        });
        return sorted;

      case CommentSortType.qa:
        // Q&A mode: prioritize OP responses and high-score answers
        final sorted = List<CommunityPostComment>.from(comments);
        sorted.sort((a, b) {
          // Stickied comments always first
          if (a.stickied && !b.stickied) return -1;
          if (!a.stickied && b.stickied) return 1;

          // Then by score
          return b.score.compareTo(a.score);
        });
        return sorted;
    }
  }
}

/// Post sort types
enum SortType {
  hot,
  newPosts,
  rising,
  controversial,
  best,
  top,
}

/// Top post time windows
enum TopTimeWindow {
  hour,
  day,
  week,
  month,
  year,
  all,
}

extension TopTimeWindowExtension on TopTimeWindow {
  String get displayName {
    switch (this) {
      case TopTimeWindow.hour:
        return 'Past Hour';
      case TopTimeWindow.day:
        return 'Today';
      case TopTimeWindow.week:
        return 'This Week';
      case TopTimeWindow.month:
        return 'This Month';
      case TopTimeWindow.year:
        return 'This Year';
      case TopTimeWindow.all:
        return 'All Time';
    }
  }
}

/// Comment sort types
enum CommentSortType {
  best,
  top,
  newComments,
  controversial,
  old,
  qa,
}

extension CommentSortTypeExtension on CommentSortType {
  String get displayName {
    switch (this) {
      case CommentSortType.best:
        return 'Best';
      case CommentSortType.top:
        return 'Top';
      case CommentSortType.newComments:
        return 'New';
      case CommentSortType.controversial:
        return 'Controversial';
      case CommentSortType.old:
        return 'Old';
      case CommentSortType.qa:
        return 'Q&A';
    }
  }
}

extension SortTypeExtension on SortType {
  String get displayName {
    switch (this) {
      case SortType.hot:
        return 'Hot';
      case SortType.newPosts:
        return 'New';
      case SortType.rising:
        return 'Rising';
      case SortType.controversial:
        return 'Controversial';
      case SortType.best:
        return 'Best';
      case SortType.top:
        return 'Top';
    }
  }

  String get icon {
    switch (this) {
      case SortType.hot:
        return '🔥';
      case SortType.newPosts:
        return '✨';
      case SortType.rising:
        return '📈';
      case SortType.controversial:
        return '⚡';
      case SortType.best:
        return '🏆';
      case SortType.top:
        return '👑';
    }
  }
}
