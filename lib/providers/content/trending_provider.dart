import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/services/search/trending_algorithm_service.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/core/user.dart';

/// Provider for the trending algorithm service
final trendingAlgorithmServiceProvider = Provider<TrendingAlgorithmService>((
  ref,
) {
  return TrendingAlgorithmService();
});

/// Provider for trending content stream
final trendingContentStreamProvider = StreamProvider<List<TrendingContent>>((
  ref,
) {
  final trendingService = ref.watch(trendingAlgorithmServiceProvider);
  return trendingService.trendingStream;
});

/// Provider for trending posts (converted from TrendingContent)
final trendingPostsProvider = FutureProvider<List<Post>>((ref) async {
  final trendingContent = await ref.watch(trendingContentStreamProvider.future);

  // Convert TrendingContent to Post objects
  // This would typically involve fetching actual post data from your database
  return trendingContent
      .map(
        (content) => Post(
          id: content.contentId,
          userId: content.creatorId,
          content: content.title,
          mediaUrls: [content.thumbnailUrl],
          isPublic: true,
          createdAt: content.createdAt,
          likeCount: content.metrics.likes,
          commentCount: content.metrics.comments,
          // Add other required fields as needed
        ),
      )
      .toList();
});

/// Provider for trending content by category
final trendingByCategoryProvider =
    FutureProvider.family<List<TrendingContent>, String>((ref, category) async {
      final trendingService = ref.watch(trendingAlgorithmServiceProvider);
      return await trendingService.getTrendingContent(
        category: category,
        limit: 20,
        minStatus: TrendingStatus.rising,
      );
    });

/// Provider for viral content only
final viralContentProvider = FutureProvider<List<TrendingContent>>((ref) async {
  final trendingService = ref.watch(trendingAlgorithmServiceProvider);
  return await trendingService.getTrendingContent(
    limit: 10,
    minStatus: TrendingStatus.viral,
  );
});

/// Provider for trending creators
final trendingCreatorsProvider = FutureProvider<List<User>>((ref) async {
  final trendingContent = await ref.watch(trendingContentStreamProvider.future);

  // Extract unique creators and sort by their trending performance
  final creatorScores = <String, double>{};

  for (final content in trendingContent) {
    final currentScore = creatorScores[content.creatorId] ?? 0.0;
    creatorScores[content.creatorId] =
        currentScore + content.trendingScore.score;
  }

  // Sort creators by their total trending score
  final sortedCreators = creatorScores.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  // Return top creators (this would fetch actual user data from your database)
  return sortedCreators
      .take(10)
      .map(
        (entry) => User(
          id: entry.key,
          username: 'creator_${entry.key}', // Placeholder
          fullName: 'Creator ${entry.key}', // Placeholder
          // Add other required fields as needed
        ),
      )
      .toList();
});

/// Provider for trending categories
final trendingCategoriesProvider = FutureProvider<List<String>>((ref) async {
  final trendingContent = await ref.watch(trendingContentStreamProvider.future);

  // Count content by category
  final categoryCounts = <String, int>{};

  for (final content in trendingContent) {
    if (content.category != null) {
      categoryCounts[content.category!] =
          (categoryCounts[content.category!] ?? 0) + 1;
    }
  }

  // Sort categories by count and return top ones
  final sortedCategories = categoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sortedCategories.take(8).map((entry) => entry.key).toList();
});

/// Provider for real-time trending score updates
final trendingScoreProvider = FutureProvider.family<TrendingScore, String>((
  ref,
  contentId,
) async {
  final trendingService = ref.watch(trendingAlgorithmServiceProvider);

  // This would typically fetch the content data from your database
  // For now, return a placeholder implementation
  final metrics = ContentMetrics(
    views: 1000,
    likes: 150,
    comments: 25,
    shares: 10,
    saves: 5,
  );

  final creator = CreatorProfile(
    creatorId: 'creator_123',
    followers: 50000,
    averageEngagementRate: 0.04,
    postsPerWeek: 5,
    isVerified: true,
    createdAt: DateTime.now().subtract(const Duration(days: 365)),
  );

  return await trendingService.calculateTrendingScore(
    contentId: contentId,
    metrics: metrics,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    creator: creator,
    contentType: ContentType.video,
    category: 'gaming',
  );
});

/// Provider for trending algorithm statistics
final trendingStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final trendingContent = await ref.watch(trendingContentStreamProvider.future);

  if (trendingContent.isEmpty) {
    return {
      'total_trending': 0,
      'viral_count': 0,
      'average_score': 0.0,
      'top_category': null,
      'engagement_rate': 0.0,
    };
  }

  final viralCount = trendingContent
      .where((c) => c.trendingScore.trendingStatus == TrendingStatus.viral)
      .length;
  final averageScore =
      trendingContent
          .map((c) => c.trendingScore.score)
          .reduce((a, b) => a + b) /
      trendingContent.length;

  // Calculate average engagement rate
  final totalViews = trendingContent
      .map((c) => c.metrics.views)
      .reduce((a, b) => a + b);
  final totalEngagement = trendingContent
      .map((c) => c.metrics.likes + c.metrics.comments + c.metrics.shares)
      .reduce((a, b) => a + b);
  final engagementRate = totalViews > 0 ? totalEngagement / totalViews : 0.0;

  // Find top category
  final categoryCounts = <String, int>{};
  for (final content in trendingContent) {
    if (content.category != null) {
      categoryCounts[content.category!] =
          (categoryCounts[content.category!] ?? 0) + 1;
    }
  }

  final topCategory = categoryCounts.isNotEmpty
      ? categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key
      : null;

  return {
    'total_trending': trendingContent.length,
    'viral_count': viralCount,
    'average_score': averageScore,
    'top_category': topCategory,
    'engagement_rate': engagementRate,
  };
});

/// Provider for trending content refresh
final trendingRefreshProvider = FutureProvider.autoDispose.family<void, void>((
  ref,
  _,
) async {
  final trendingService = ref.watch(trendingAlgorithmServiceProvider);

  // Clear cache to force refresh
  trendingService.clearCache();

  // Trigger a new trending calculation
  await trendingService.getTrendingContent(limit: 20);
});

/// Provider for content trending prediction
final trendingPredictionProvider =
    FutureProvider.family<double, Map<String, dynamic>>((
      ref,
      contentData,
    ) async {
      final trendingService = ref.watch(trendingAlgorithmServiceProvider);

      final metrics = ContentMetrics(
        views: contentData['views'] ?? 0,
        likes: contentData['likes'] ?? 0,
        comments: contentData['comments'] ?? 0,
        shares: contentData['shares'] ?? 0,
        saves: contentData['saves'] ?? 0,
        averageWatchTime: contentData['averageWatchTime'] ?? 0.0,
        duration: contentData['duration'] ?? 0.0,
        viewRetention: contentData['viewRetention'] ?? 0.0,
        averageCommentLength: contentData['averageCommentLength'] ?? 0.0,
      );

      final creator = CreatorProfile(
        creatorId: contentData['creatorId'] ?? 'unknown',
        followers: contentData['followers'] ?? 0,
        averageEngagementRate: contentData['averageEngagementRate'] ?? 0.0,
        postsPerWeek: contentData['postsPerWeek'] ?? 0,
        isVerified: contentData['isVerified'] ?? false,
        createdAt: DateTime.parse(
          contentData['creatorCreatedAt'] ?? DateTime.now().toIso8601String(),
        ),
      );

      final trendingScore = await trendingService.calculateTrendingScore(
        contentId:
            contentData['contentId'] ??
            'temp_${DateTime.now().millisecondsSinceEpoch}',
        metrics: metrics,
        createdAt: DateTime.parse(
          contentData['createdAt'] ?? DateTime.now().toIso8601String(),
        ),
        creator: creator,
        contentType: ContentType.values.firstWhere(
          (e) =>
              e.toString() ==
              'ContentType.${contentData['contentType'] ?? 'video'}',
          orElse: () => ContentType.video,
        ),
        category: contentData['category'],
      );

      return trendingScore.score;
    });
