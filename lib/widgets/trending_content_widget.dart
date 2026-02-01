import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/content/trending_provider.dart';
import 'package:gamer_flick/services/search/trending_algorithm_service.dart';

class TrendingContentWidget extends ConsumerStatefulWidget {
  final String? category;
  final TrendingStatus? minStatus;
  final int limit;
  final bool showHeader;
  final VoidCallback? onRefresh;

  const TrendingContentWidget({
    super.key,
    this.category,
    this.minStatus,
    this.limit = 20,
    this.showHeader = true,
    this.onRefresh,
  });

  @override
  ConsumerState<TrendingContentWidget> createState() =>
      _TrendingContentWidgetState();
}

class _TrendingContentWidgetState extends ConsumerState<TrendingContentWidget> {
  @override
  Widget build(BuildContext context) {
    final trendingContentAsync = widget.category != null
        ? ref.watch(trendingByCategoryProvider(widget.category!))
        : ref.watch(trendingContentStreamProvider);

    return trendingContentAsync.when(
      data: (trendingContent) {
        if (trendingContent.isEmpty) {
          return _buildEmptyState();
        }

        // Filter by minimum status if specified
        final filteredContent = widget.minStatus != null
            ? trendingContent.where((content) {
                final score = content.trendingScore;
                return score.trendingStatus.index >= widget.minStatus!.index;
              }).toList()
            : trendingContent;

        if (filteredContent.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) _buildHeader(filteredContent),
            const SizedBox(height: 16),
            _buildTrendingList(filteredContent.take(widget.limit).toList()),
          ],
        );
      },
      loading: () => _buildLoadingState(),
      error: (error, stack) => _buildErrorState(error),
    );
  }

  Widget _buildHeader(List<TrendingContent> content) {
    final viralCount = content
        .where((c) => c.trendingScore.trendingStatus == TrendingStatus.viral)
        .length;
    final trendingCount = content
        .where((c) => c.trendingScore.trendingStatus == TrendingStatus.trending)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔥 Trending Now',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00BFFF),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '$viralCount viral • $trendingCount trending',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
          const Spacer(),
          if (widget.onRefresh != null)
            IconButton(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh trending',
            ),
        ],
      ),
    );
  }

  Widget _buildTrendingList(List<TrendingContent> content) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: content.length,
      itemBuilder: (context, index) {
        final item = content[index];
        return _TrendingContentCard(
          content: item,
          rank: index + 1,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.trending_up,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No trending content yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for trending posts!',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(3, (index) => _buildShimmerCard()),
      ),
    );
  }

  Widget _buildShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load trending content',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try again later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(trendingContentStreamProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _TrendingContentCard extends StatelessWidget {
  final TrendingContent content;
  final int rank;

  const _TrendingContentCard({
    required this.content,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            // Navigate to content detail
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (context) => ContentDetailScreen(content: content),
            // ));
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildRankBadge(),
                const SizedBox(width: 12),
                _buildThumbnail(),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildContentInfo(),
                ),
                _buildTrendingScore(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    IconData badgeIcon;

    switch (content.trendingScore.trendingStatus) {
      case TrendingStatus.viral:
        badgeColor = Colors.red;
        badgeIcon = Icons.local_fire_department;
        break;
      case TrendingStatus.trending:
        badgeColor = Colors.orange;
        badgeIcon = Icons.trending_up;
        break;
      case TrendingStatus.rising:
        badgeColor = Colors.green;
        badgeIcon = Icons.arrow_upward;
        break;
      case TrendingStatus.stable:
        badgeColor = Colors.blue;
        badgeIcon = Icons.remove;
        break;
      case TrendingStatus.low:
        badgeColor = Colors.grey;
        badgeIcon = Icons.arrow_downward;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 16,
          ),
          Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(content.thumbnailUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: content.contentType == ContentType.video
          ? Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: 24,
              ),
            )
          : null,
    );
  }

  Widget _buildContentInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          content.creatorName,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.remove_red_eye,
              size: 12,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(content.metrics.views),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.favorite,
              size: 12,
              color: Colors.grey[500],
            ),
            const SizedBox(width: 4),
            Text(
              _formatNumber(content.metrics.likes),
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrendingScore() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getScoreColor(content.trendingScore.score),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${(content.trendingScore.score * 100).toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _getStatusText(content.trendingScore.trendingStatus),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.9) return Colors.red;
    if (score >= 0.7) return Colors.orange;
    if (score >= 0.5) return Colors.green;
    if (score >= 0.3) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusText(TrendingStatus status) {
    switch (status) {
      case TrendingStatus.viral:
        return 'VIRAL';
      case TrendingStatus.trending:
        return 'TRENDING';
      case TrendingStatus.rising:
        return 'RISING';
      case TrendingStatus.stable:
        return 'STABLE';
      case TrendingStatus.low:
        return 'LOW';
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Trending Categories Widget
class TrendingCategoriesWidget extends ConsumerWidget {
  const TrendingCategoriesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(trendingCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 40,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.toUpperCase()),
                  selected: false,
                  onSelected: (selected) {
                    // Handle category selection
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF00BFFF),
                  labelStyle: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
