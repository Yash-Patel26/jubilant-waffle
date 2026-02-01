import 'dart:async';
import 'dart:math';
import 'package:gamer_flick/services/core/analytics_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';

/// Trending Algorithm Service that mimics Instagram, YouTube, and TikTok
/// Uses multiple factors to calculate trending scores in real-time
class TrendingAlgorithmService {
  static final TrendingAlgorithmService _instance =
      TrendingAlgorithmService._internal();
  factory TrendingAlgorithmService() => _instance;
  TrendingAlgorithmService._internal();

  final AnalyticsService _analytics = AnalyticsService();
  final ErrorReportingService _errorReporting = ErrorReportingService();

  // Algorithm configuration
  static const double _engagementWeight = 0.35;
  static const double _velocityWeight = 0.25;
  static const double _recencyWeight = 0.20;
  static const double _creatorWeight = 0.15;
  static const double _contentQualityWeight = 0.05;

  // Time decay factors (in hours)
  static const int _velocityWindow = 24; // 24 hours for velocity calculation
  static const int _trendingWindow = 168; // 1 week for trending consideration
  static const double _decayFactor = 0.95; // 5% decay per hour

  // Engagement thresholds
  static const double _minEngagementRate = 0.02; // 2% minimum engagement
  static const int _minViews = 100;
  static const int _minLikes = 10;
  static const int _minComments = 2;
  static const int _minShares = 1;

  // Trending score thresholds
  static const double _trendingThreshold = 0.7;
  static const double _viralThreshold = 0.9;

  // Cache for trending scores
  final Map<String, TrendingScore> _scoreCache = {};
  final Map<String, DateTime> _lastCalculated = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Stream controllers for real-time updates
  final StreamController<List<TrendingContent>> _trendingStreamController =
      StreamController<List<TrendingContent>>.broadcast();

  Stream<List<TrendingContent>> get trendingStream =>
      _trendingStreamController.stream;

  /// Calculate trending score for a piece of content
  Future<TrendingScore> calculateTrendingScore({
    required String contentId,
    required ContentMetrics metrics,
    required DateTime createdAt,
    required CreatorProfile creator,
    required ContentType contentType,
    String? category,
  }) async {
    try {
      // Check cache first
      if (_isCacheValid(contentId)) {
        return _scoreCache[contentId]!;
      }

      // Calculate individual score components
      final engagementScore = _calculateEngagementScore(metrics);
      final velocityScore = await _calculateVelocityScore(
        contentId,
        metrics,
        createdAt,
      );
      final recencyScore = _calculateRecencyScore(createdAt);
      final creatorScore = _calculateCreatorScore(creator);
      final qualityScore = _calculateContentQualityScore(metrics, contentType);

      // Calculate weighted composite score
      final compositeScore =
          (engagementScore * _engagementWeight) +
          (velocityScore * _velocityWeight) +
          (recencyScore * _recencyWeight) +
          (creatorScore * _creatorWeight) +
          (qualityScore * _contentQualityWeight);

      // Apply category boost if applicable
      final categoryBoost = _calculateCategoryBoost(category, contentType);
      final finalScore = (compositeScore * (1 + categoryBoost)).clamp(0.0, 1.0);

      // Determine trending status
      final trendingStatus = _determineTrendingStatus(finalScore, metrics);

      final trendingScore = TrendingScore(
        contentId: contentId,
        score: finalScore,
        engagementScore: engagementScore,
        velocityScore: velocityScore,
        recencyScore: recencyScore,
        creatorScore: creatorScore,
        qualityScore: qualityScore,
        trendingStatus: trendingStatus,
        calculatedAt: DateTime.now(),
        categoryBoost: categoryBoost,
      );

      // Cache the result
      _cacheScore(contentId, trendingScore);

      // Track analytics
      await _analytics.trackEvent(
        'trending_score_calculated',
        parameters: {
          'content_id': contentId,
          'final_score': finalScore,
          'trending_status': trendingStatus.toString(),
          'content_type': contentType.toString(),
        },
      );

      return trendingScore;
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'TrendingAlgorithmService.calculateTrendingScore',
        additionalData: {'content_id': contentId},
      );
      rethrow;
    }
  }

  /// Calculate engagement score based on likes, comments, shares, views
  double _calculateEngagementScore(ContentMetrics metrics) {
    if (metrics.views < _minViews) return 0.0;

    // Calculate engagement rate
    final totalEngagement = metrics.likes + metrics.comments + metrics.shares;
    final engagementRate = totalEngagement / metrics.views;

    // Normalize engagement rate (0-1 scale)
    final normalizedEngagement = (engagementRate / 0.1).clamp(
      0.0,
      1.0,
    ); // 10% = perfect score

    // Weight different engagement types
    final likeScore = (metrics.likes / metrics.views) * 0.4;
    final commentScore = (metrics.comments / metrics.views) * 0.3;
    final shareScore = (metrics.shares / metrics.views) * 0.3;

    final weightedEngagement = (likeScore + commentScore + shareScore) / 0.1;
    final finalEngagement = (normalizedEngagement + weightedEngagement) / 2;

    return finalEngagement.clamp(0.0, 1.0);
  }

  /// Calculate velocity score (rate of engagement over time)
  Future<double> _calculateVelocityScore(
    String contentId,
    ContentMetrics metrics,
    DateTime createdAt,
  ) async {
    try {
      final now = DateTime.now();
      int ageInHours = now.difference(createdAt).inHours;

      if (ageInHours == 0) ageInHours = 1; // Prevent division by zero

      // Calculate engagement velocity (engagements per hour)
      final totalEngagement = metrics.likes + metrics.comments + metrics.shares;
      final engagementVelocity = totalEngagement / ageInHours;

      // Normalize velocity (exponential decay for older content)
      final timeDecay = pow(_decayFactor, ageInHours);
      final normalizedVelocity =
          (engagementVelocity * timeDecay) /
          100; // 100 engagements/hour = perfect score

      // Apply view velocity bonus
      final viewVelocity = metrics.views / ageInHours;
      final viewVelocityBonus =
          (viewVelocity / 1000) * 0.2; // 1000 views/hour = 20% bonus

      final finalVelocity = (normalizedVelocity + viewVelocityBonus).clamp(
        0.0,
        1.0,
      );

      return finalVelocity;
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'TrendingAlgorithmService._calculateVelocityScore',
      );
      return 0.0;
    }
  }

  /// Calculate recency score (newer content gets higher scores)
  double _calculateRecencyScore(DateTime createdAt) {
    final now = DateTime.now();
    final ageInHours = now.difference(createdAt).inHours;

    // Exponential decay for recency
    final recencyScore = exp(-ageInHours / 24); // 24-hour half-life
    return recencyScore.clamp(0.0, 1.0);
  }

  /// Calculate creator score based on creator's profile and history
  double _calculateCreatorScore(CreatorProfile creator) {
    double score = 0.0;

    // Follower count factor (logarithmic scale)
    if (creator.followers > 0) {
      final followerScore =
          log(creator.followers) / log(1000000); // 1M followers = 1.0
      score += followerScore * 0.3;
    }

    // Average engagement rate
    if (creator.averageEngagementRate > 0) {
      final engagementScore = (creator.averageEngagementRate / 0.05).clamp(
        0.0,
        1.0,
      ); // 5% = perfect
      score += engagementScore * 0.3;
    }

    // Content consistency (posting frequency)
    if (creator.postsPerWeek > 0) {
      final consistencyScore = (creator.postsPerWeek / 7).clamp(
        0.0,
        1.0,
      ); // 7 posts/week = perfect
      score += consistencyScore * 0.2;
    }

    // Creator verification status
    if (creator.isVerified) {
      score += 0.1;
    }

    // Creator age (longer history = more trust)
    final creatorAgeInDays = DateTime.now()
        .difference(creator.createdAt)
        .inDays;
    final ageScore = (creatorAgeInDays / 365).clamp(
      0.0,
      1.0,
    ); // 1 year = perfect
    score += ageScore * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate content quality score based on metrics and type
  double _calculateContentQualityScore(
    ContentMetrics metrics,
    ContentType contentType,
  ) {
    double score = 0.0;

    // Watch time completion rate (for videos)
    if (contentType == ContentType.video && metrics.averageWatchTime > 0) {
      final completionRate = metrics.averageWatchTime / metrics.duration;
      score += completionRate * 0.4;
    }

    // Share-to-view ratio (viral potential)
    if (metrics.views > 0) {
      final shareRatio = metrics.shares / metrics.views;
      score += (shareRatio * 10).clamp(
        0.0,
        0.3,
      ); // 10% share rate = 30% of quality score
    }

    // Comment quality (longer comments = more engagement)
    if (metrics.comments > 0 && metrics.averageCommentLength > 0) {
      final commentQuality = (metrics.averageCommentLength / 50).clamp(
        0.0,
        0.2,
      ); // 50 chars = 20% of quality
      score += commentQuality;
    }

    // View retention (for videos)
    if (contentType == ContentType.video && metrics.viewRetention > 0) {
      score += metrics.viewRetention * 0.1;
    }

    return score.clamp(0.0, 1.0);
  }

  /// Calculate category boost based on trending categories
  double _calculateCategoryBoost(String? category, ContentType contentType) {
    if (category == null) return 0.0;

    // Define trending categories with their boost values
    const trendingCategories = {
      'gaming': 0.15,
      'esports': 0.20,
      'tournament': 0.25,
      'highlight': 0.10,
      'tutorial': 0.05,
      'review': 0.08,
      'live': 0.30,
      'challenge': 0.12,
    };

    return trendingCategories[category.toLowerCase()] ?? 0.0;
  }

  /// Determine trending status based on score and metrics
  TrendingStatus _determineTrendingStatus(
    double score,
    ContentMetrics metrics,
  ) {
    if (score >= _viralThreshold && metrics.shares > 50) {
      return TrendingStatus.viral;
    } else if (score >= _trendingThreshold) {
      return TrendingStatus.trending;
    } else if (score >= 0.5) {
      return TrendingStatus.rising;
    } else if (score >= 0.3) {
      return TrendingStatus.stable;
    } else {
      return TrendingStatus.low;
    }
  }

  /// Get trending content for a specific category or all content
  Future<List<TrendingContent>> getTrendingContent({
    String? category,
    ContentType? contentType,
    int limit = 20,
    TrendingStatus? minStatus,
  }) async {
    try {
      // This would typically query your database
      // For now, return a placeholder implementation
      final trendingContent = <TrendingContent>[];

      // Sort by trending score and filter
      trendingContent.sort(
        (a, b) => b.trendingScore.score.compareTo(a.trendingScore.score),
      );

      // Apply filters
      final filteredContent = trendingContent
          .where((content) {
            if (category != null && content.category != category) return false;
            if (contentType != null && content.contentType != contentType) {
              return false;
            }
            if (minStatus != null &&
                content.trendingScore.trendingStatus.index < minStatus.index) {
              return false;
            }
            return true;
          })
          .take(limit)
          .toList();

      // Emit to stream for real-time updates
      _trendingStreamController.add(filteredContent);

      return filteredContent;
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'TrendingAlgorithmService.getTrendingContent',
      );
      return [];
    }
  }

  /// Update content metrics and recalculate trending score
  Future<TrendingScore> updateContentMetrics({
    required String contentId,
    required ContentMetrics newMetrics,
  }) async {
    try {
      // Invalidate cache for this content
      _scoreCache.remove(contentId);
      _lastCalculated.remove(contentId);

      // Recalculate trending score
      // This would typically fetch the content data from your database
      // For now, return a placeholder

      await _analytics.trackEvent(
        'content_metrics_updated',
        parameters: {
          'content_id': contentId,
          'new_views': newMetrics.views,
          'new_likes': newMetrics.likes,
          'new_comments': newMetrics.comments,
          'new_shares': newMetrics.shares,
        },
      );

      // Return updated score (placeholder)
      return TrendingScore(
        contentId: contentId,
        score: 0.0,
        engagementScore: 0.0,
        velocityScore: 0.0,
        recencyScore: 0.0,
        creatorScore: 0.0,
        qualityScore: 0.0,
        trendingStatus: TrendingStatus.low,
        calculatedAt: DateTime.now(),
        categoryBoost: 0.0,
      );
    } catch (e) {
      await _errorReporting.reportError(
        e,
        null,
        context: 'TrendingAlgorithmService.updateContentMetrics',
      );
      rethrow;
    }
  }

  /// Cache management
  bool _isCacheValid(String contentId) {
    final lastCalculated = _lastCalculated[contentId];
    if (lastCalculated == null) return false;

    return DateTime.now().difference(lastCalculated) < _cacheExpiry;
  }

  void _cacheScore(String contentId, TrendingScore score) {
    _scoreCache[contentId] = score;
    _lastCalculated[contentId] = DateTime.now();
  }

  /// Clear cache (useful for testing or memory management)
  void clearCache() {
    _scoreCache.clear();
    _lastCalculated.clear();
  }

  /// Dispose resources
  void dispose() {
    _trendingStreamController.close();
  }
}

/// Data models for the trending algorithm

class TrendingScore {
  final String contentId;
  final double score;
  final double engagementScore;
  final double velocityScore;
  final double recencyScore;
  final double creatorScore;
  final double qualityScore;
  final TrendingStatus trendingStatus;
  final DateTime calculatedAt;
  final double categoryBoost;

  TrendingScore({
    required this.contentId,
    required this.score,
    required this.engagementScore,
    required this.velocityScore,
    required this.recencyScore,
    required this.creatorScore,
    required this.qualityScore,
    required this.trendingStatus,
    required this.calculatedAt,
    required this.categoryBoost,
  });

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'score': score,
    'engagementScore': engagementScore,
    'velocityScore': velocityScore,
    'recencyScore': recencyScore,
    'creatorScore': creatorScore,
    'qualityScore': qualityScore,
    'trendingStatus': trendingStatus.toString(),
    'calculatedAt': calculatedAt.toIso8601String(),
    'categoryBoost': categoryBoost,
  };
}

class ContentMetrics {
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int saves;
  final double averageWatchTime;
  final double duration;
  final double viewRetention;
  final double averageCommentLength;

  ContentMetrics({
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.saves,
    this.averageWatchTime = 0.0,
    this.duration = 0.0,
    this.viewRetention = 0.0,
    this.averageCommentLength = 0.0,
  });

  Map<String, dynamic> toJson() => {
    'views': views,
    'likes': likes,
    'comments': comments,
    'shares': shares,
    'saves': saves,
    'averageWatchTime': averageWatchTime,
    'duration': duration,
    'viewRetention': viewRetention,
    'averageCommentLength': averageCommentLength,
  };
}

class CreatorProfile {
  final String creatorId;
  final int followers;
  final double averageEngagementRate;
  final int postsPerWeek;
  final bool isVerified;
  final DateTime createdAt;

  CreatorProfile({
    required this.creatorId,
    required this.followers,
    required this.averageEngagementRate,
    required this.postsPerWeek,
    required this.isVerified,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'creatorId': creatorId,
    'followers': followers,
    'averageEngagementRate': averageEngagementRate,
    'postsPerWeek': postsPerWeek,
    'isVerified': isVerified,
    'createdAt': createdAt.toIso8601String(),
  };
}

class TrendingContent {
  final String contentId;
  final String title;
  final String creatorId;
  final String creatorName;
  final ContentType contentType;
  final String? category;
  final String thumbnailUrl;
  final DateTime createdAt;
  final TrendingScore trendingScore;
  final ContentMetrics metrics;

  TrendingContent({
    required this.contentId,
    required this.title,
    required this.creatorId,
    required this.creatorName,
    required this.contentType,
    this.category,
    required this.thumbnailUrl,
    required this.createdAt,
    required this.trendingScore,
    required this.metrics,
  });

  Map<String, dynamic> toJson() => {
    'contentId': contentId,
    'title': title,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'contentType': contentType.toString(),
    'category': category,
    'thumbnailUrl': thumbnailUrl,
    'createdAt': createdAt.toIso8601String(),
    'trendingScore': trendingScore.toJson(),
    'metrics': metrics.toJson(),
  };
}

enum TrendingStatus { low, stable, rising, trending, viral }

enum ContentType { video, image, text, live }
