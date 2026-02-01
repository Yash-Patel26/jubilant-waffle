import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/community/community_notifier.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'community_detail_screen.dart';
import 'package:gamer_flick/providers/community/community_discovery_provider.dart';

class CommunitiesScreen extends ConsumerStatefulWidget {
  const CommunitiesScreen({super.key});

  @override
  ConsumerState<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends ConsumerState<CommunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final bool _showTrending = true;
  bool _showVerified = false;
  bool _showNsfw = false;
  double _minMembers = 1000;
  String _sortBy = 'Trending';
  final String _radius = 'Worldwide';
  bool _smartRecommendations = false;
  final Set<String> _selectedTopics = <String>{};

  final List<String> _topics = [
    'FPS',
    'MOBA',
    'RPG',
    'Mobile',
    'Strategy',
    'Casual',
    'Pro',
    'Dev',
    'IRL',
    'Clips',
    'Esports',
    'Streaming',
    'Competitive',
    'Funny',
    'News',
    'Discussion',
    'Art',
    'Cosplay',
    'Memes',
    'Highlights'
  ];

  final List<String> _sortOptions = [
    'Trending',
    'Popular',
    'New',
    'Most Members',
    'Most Active',
    'Verified Only'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          if (isMobile) {
            // Mobile layout
            return Column(
              children: [
                _buildMobileTopBar(theme),
                Expanded(
                  child: _buildMainContent(),
                ),
              ],
            );
          } else {
            // Desktop layout
            return Column(
              children: [
                _buildTopNavigationBar(),
                Expanded(
                  child: Row(
                    children: [
                      // Main Content Area
                      Expanded(
                        flex: 3,
                        child: _buildMainContent(),
                      ),
                      // Right Sidebar
                      Container(
                        width: 320,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          border: Border(
                            left: BorderSide(color: theme.dividerColor),
                          ),
                        ),
                        child: _buildRightSidebar(),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileTopBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.reddit, color: theme.primaryColor, size: 28),
              const SizedBox(width: 8),
              Text(
                'Communities',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.add, color: theme.primaryColor),
                onPressed: () =>
                    Navigator.pushNamed(context, '/create-community'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search Bar
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search,
                    color: theme.textTheme.bodySmall?.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search communities',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.tune,
                      color: theme.textTheme.bodySmall?.color, size: 20),
                  onPressed: _showFilterDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavigationBar() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          Icon(Icons.reddit, color: theme.primaryColor, size: 32),
          const SizedBox(width: 12),
          Text(
            'Communities',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 24),
          // Search Bar
          Container(
            width: 300,
            height: 40,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                Icon(Icons.search,
                    color: theme.textTheme.bodySmall?.color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search communities',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (_) => _performSearch(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.tune,
                      color: theme.textTheme.bodySmall?.color, size: 20),
                  onPressed: _showFilterDialog,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // View Toggle Icon
          IconButton(
            icon:
                Icon(Icons.grid_view, color: theme.textTheme.bodySmall?.color),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          // Create Community Button
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create'),
            onPressed: () => Navigator.pushNamed(context, '/create-community'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCommunitiesTab(),
        _buildMyCommunitiesTab(),
        _buildExploreTab(),
        _buildRecommendedTab(),
      ],
    );
  }

  Widget _buildCommunitiesTab() {
    final theme = Theme.of(context);
    final communitiesState = ref.watch(communitiesProvider);

    return Column(
      children: [
        // Sort Options
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              Text('Sort by: ', style: theme.textTheme.bodyMedium),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _sortOptions
                        .map((option) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(option),
                                selected: _sortBy == option,
                                onSelected: (selected) {
                                  setState(() {
                                    _sortBy = option;
                                  });
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Communities List
        Expanded(
          child: communitiesState.when(
            data: (communities) {
              final filteredCommunities = communities.where((c) {
                // Apply sorting logic locally for simplicity or use another provider
                if (_sortBy == 'Verified Only' && !c.isVerified) return false;
                if (!_showNsfw && c.isNsfw) return false;
                if (c.memberCount < _minMembers) return false;
                return true;
              }).toList();

              if (filteredCommunities.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.reddit,
                          size: 64,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text(
                        'No communities found',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.textTheme.titleMedium?.color
                              ?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your search or filters',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredCommunities.length,
                itemBuilder: (context, index) {
                  final community = filteredCommunities[index];
                  return _buildCommunityCard(community);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildMyCommunitiesTab() {
    final theme = Theme.of(context);
    final joinedCommunitiesState = ref.watch(joinedCommunitiesProvider);

    return joinedCommunitiesState.when(
      data: (communities) {
        if (communities.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_outlined,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You haven\'t joined any communities yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color:
                          theme.textTheme.titleMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore communities and join the ones you like',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.explore),
                    label: const Text('Explore Communities'),
                    onPressed: () {
                      _tabController.animateTo(0);
                    },
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: communities.length,
          itemBuilder: (context, index) {
            final community = communities[index];
            return _buildCommunityCard(community);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildExploreTab() {
    final theme = Theme.of(context);
    
    // Use trending communities for the explore tab
    final trendingState = ref.watch(trendingCommunitiesProvider);

    return Column(
      children: [
        // Category Pills
        Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _topics.length,
            itemBuilder: (context, index) {
              final topic = _topics[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(topic),
                  selected: _selectedTopics.contains(topic),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTopics.add(topic);
                      } else {
                        _selectedTopics.remove(topic);
                      }
                    });
                  },
                ),
              );
            },
          ),
        ),
        // Trending Communities
        Expanded(
          child: trendingState.when(
            data: (communities) {
              if (communities.isEmpty) {
                return Center(
                  child: Text(
                    'No trending communities yet',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: communities.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _buildCommunityCard(communities[index]),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedTab() {
    final theme = Theme.of(context);
    final recommendedState = ref.watch(recommendedCommunitiesProvider);

    return recommendedState.when(
      data: (communities) {
        if (communities.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.recommend,
                    size: 64,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                const SizedBox(height: 16),
                Text(
                  'No recommendations yet',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.textTheme.titleMedium?.color?.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join some communities to get personalized recommendations',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: communities.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) =>
              _buildCommunityCard(communities[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildRightSidebar() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFiltersSection(),
          const SizedBox(height: 32),
          _buildTopicsSection(),
          const SizedBox(height: 32),
          _buildSuggestedCommunitiesSection(),
          const SizedBox(height: 32),
          _buildSmartRecommendationsSection(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filters',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Show NSFW'),
          subtitle: const Text('Include adult content'),
          value: _showNsfw,
          onChanged: (value) => setState(() => _showNsfw = value),
        ),
        SwitchListTile(
          title: const Text('Verified Only'),
          subtitle: const Text('Show verified communities'),
          value: _showVerified,
          onChanged: (value) => setState(() => _showVerified = value),
        ),
        ListTile(
          title: const Text('Min Members'),
          subtitle: Text('${_minMembers.toInt()}'),
          trailing: SizedBox(
            width: 100,
            child: Slider(
              value: _minMembers,
              min: 0,
              max: 10000,
              divisions: 100,
              onChanged: (value) => setState(() => _minMembers = value),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topics',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _topics
              .map((topic) => FilterChip(
                    label: Text(topic),
                    selected: _selectedTopics.contains(topic),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTopics.add(topic);
                        } else {
                          _selectedTopics.remove(topic);
                        }
                      });
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildSuggestedCommunitiesSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ref.watch(communitiesProvider).when(
              data: (communities) => Column(
                children: communities
                    .take(5)
                    .map((community) => _buildCommunityCard(community))
                    .toList(),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('Failed to load suggestions'),
            ),
      ],
    );
  }

  Widget _buildSmartRecommendationsSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Recommendations',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Enable AI Recommendations'),
          subtitle: const Text('Get personalized community suggestions'),
          value: _smartRecommendations,
          onChanged: (value) => setState(() => _smartRecommendations = value),
        ),
      ],
    );
  }

  Widget _buildCommunityCard(Community community) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: community.imageUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(community.imageUrl!),
                radius: 24,
              )
            : CircleAvatar(
                radius: 24,
                backgroundColor: theme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.reddit, color: theme.primaryColor),
              ),
        title: Wrap(
          spacing: 4,
          children: [
            Text(
              'r/${community.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (community.isVerified)
              Icon(Icons.verified, color: Colors.blue, size: 16),
            if (community.isNsfw)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('NSFW',
                    style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              community.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Text('${community.memberCount} members',
                    style: const TextStyle(fontSize: 12)),
                if (community.onlineCount > 0)
                  Text('${community.onlineCount} online',
                      style: const TextStyle(fontSize: 12)),
                if (community.isVipOnly == true)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VIP',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {
            final isVip = community.isVipOnly == true;
            if (isVip) {
              Navigator.pushNamed(context, '/premium');
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommunityDetailScreen(community: community),
              ),
            );
          },
          child: const Text('View'),
        ),
      ),
    );
  }

  void _performSearch() {
    if (_searchController.text.isNotEmpty) {
      ref.read(communitiesProvider.notifier).search(_searchController.text);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Communities'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Show NSFW'),
              value: _showNsfw,
              onChanged: (value) => setState(() => _showNsfw = value),
            ),
            SwitchListTile(
              title: const Text('Verified Only'),
              value: _showVerified,
              onChanged: (value) => setState(() => _showVerified = value),
            ),
            ListTile(
              title: const Text('Min Members'),
              subtitle: Text('${_minMembers.toInt()}'),
              trailing: SizedBox(
                width: 100,
                child: Slider(
                  value: _minMembers,
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  onChanged: (value) => setState(() => _minMembers = value),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performSearch();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
