# GamerFlick UX Enhancement Guide

A comprehensive guide to enhancing user experience across all areas of the GamerFlick gaming social platform, combining community/social best practices with mobile platform optimization.

---

## Table of Contents

1. [Onboarding & First-Time User Experience](#1-onboarding--first-time-user-experience)
2. [Social Feed & Content Discovery](#2-social-feed--content-discovery)
3. [Community Experience](#3-community-experience)
4. [Gaming Features & Tournaments](#4-gaming-features--tournaments)
5. [Notifications & Engagement](#5-notifications--engagement)
6. [Performance & Reliability](#6-performance--reliability)
7. [Offline Experience](#7-offline-experience)
8. [Security & Trust](#8-security--trust)
9. [Accessibility](#9-accessibility)
10. [Platform-Specific Optimizations](#10-platform-specific-optimizations)

---

## 1. Onboarding & First-Time User Experience

### 1.1 Progressive Permission Requests

**Problem:** Asking for all permissions upfront overwhelms users and leads to denials.

**Solution:** Request permissions contextually when the feature is needed.

```dart
// lib/services/core/contextual_permission_service.dart
class ContextualPermissionService {
  static final ContextualPermissionService _instance = ContextualPermissionService._internal();
  factory ContextualPermissionService() => _instance;
  ContextualPermissionService._internal();

  /// Show permission request with context explanation
  Future<bool> requestWithContext({
    required BuildContext context,
    required Permission permission,
    required String featureName,
    required String explanation,
    required String iconAsset,
  }) async {
    // Check if already granted
    if (await permission.isGranted) return true;

    // Show contextual bottom sheet explaining why we need this
    final shouldRequest = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _PermissionExplanationSheet(
        featureName: featureName,
        explanation: explanation,
        iconAsset: iconAsset,
      ),
    );

    if (shouldRequest != true) return false;

    final status = await permission.request();
    
    if (status.isPermanentlyDenied) {
      _showSettingsPrompt(context, featureName);
      return false;
    }

    return status.isGranted;
  }

  void _showSettingsPrompt(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Enable $featureName in Settings to use this feature'),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: openAppSettings,
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

class _PermissionExplanationSheet extends StatelessWidget {
  final String featureName;
  final String explanation;
  final String iconAsset;

  const _PermissionExplanationSheet({
    required this.featureName,
    required this.explanation,
    required this.iconAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with gaming glow effect
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.gamingPurple, AppTheme.gamingCyan],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gamingCyan.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.camera_alt, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            'Enable $featureName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            explanation,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Not Now'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  child: const Text('Enable'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

### 1.2 Personalized Onboarding Flow

```dart
// lib/screens/onboarding/personalized_onboarding_screen.dart
class PersonalizedOnboardingScreen extends ConsumerStatefulWidget {
  const PersonalizedOnboardingScreen({super.key});

  @override
  ConsumerState<PersonalizedOnboardingScreen> createState() => _PersonalizedOnboardingScreenState();
}

class _PersonalizedOnboardingScreenState extends ConsumerState<PersonalizedOnboardingScreen> {
  int _currentStep = 0;
  final List<String> _selectedGames = [];
  final List<String> _selectedInterests = [];
  String? _gamingLevel;

  final _steps = [
    'Welcome',
    'Favorite Games',
    'Gaming Level',
    'Interests',
    'Personalized Feed',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeScaffold(
      body: Column(
        children: [
          // Progress indicator
          _buildProgressBar(),
          
          // Step content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentStep(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentStep;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isActive ? AppTheme.gamingCyan : AppTheme.surfaceColor,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFavoriteGamesStep() {
    final popularGames = [
      {'name': 'Valorant', 'icon': '🎯'},
      {'name': 'League of Legends', 'icon': '⚔️'},
      {'name': 'CS2', 'icon': '🔫'},
      {'name': 'Fortnite', 'icon': '🏗️'},
      {'name': 'Apex Legends', 'icon': '🦾'},
      {'name': 'Minecraft', 'icon': '⛏️'},
      {'name': 'GTA V', 'icon': '🚗'},
      {'name': 'Call of Duty', 'icon': '🎖️'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What games do you play?',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Select at least 3 games to personalize your feed',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: popularGames.map((game) {
            final isSelected = _selectedGames.contains(game['name']);
            return _GameChip(
              name: game['name']!,
              icon: game['icon']!,
              isSelected: isSelected,
              onTap: () => _toggleGame(game['name']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _toggleGame(String game) {
    setState(() {
      if (_selectedGames.contains(game)) {
        _selectedGames.remove(game);
      } else {
        _selectedGames.add(game);
      }
    });
  }

  Future<void> _completeOnboarding() async {
    // Save preferences to backend
    await ref.read(userServiceProvider).updateOnboardingPreferences(
      favoriteGames: _selectedGames,
      gamingLevel: _gamingLevel,
      interests: _selectedInterests,
    );

    // Navigate to personalized home
    Navigator.pushReplacementNamed(context, '/Home');
  }
}

class _GameChip extends StatelessWidget {
  final String name;
  final String icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GameChip({
    required this.name,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: isSelected ? AppTheme.gamingPurple : AppTheme.surfaceColor,
          border: Border.all(
            color: isSelected ? AppTheme.gamingCyan : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.gamingCyan.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle, size: 18, color: AppTheme.gamingCyan),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## 2. Social Feed & Content Discovery

### 2.1 Infinite Scroll with Smart Prefetching

```dart
// lib/widgets/feed/smart_feed_list.dart
class SmartFeedList extends ConsumerStatefulWidget {
  final String feedType;
  
  const SmartFeedList({super.key, required this.feedType});

  @override
  ConsumerState<SmartFeedList> createState() => _SmartFeedListState();
}

class _SmartFeedListState extends ConsumerState<SmartFeedList> {
  final ScrollController _scrollController = ScrollController();
  final List<Post> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _page = 0;

  // Prefetch threshold - load more when 70% scrolled
  static const _prefetchThreshold = 0.7;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialPosts();
  }

  void _onScroll() {
    if (!_hasMore || _isLoading) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * _prefetchThreshold;

    if (currentScroll >= threshold) {
      _loadMorePosts();
    }
  }

  Future<void> _loadMorePosts() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final newPosts = await ref.read(feedServiceProvider).fetchPosts(
        type: widget.feedType,
        page: _page + 1,
        limit: 10,
      );

      setState(() {
        _posts.addAll(newPosts);
        _page++;
        _hasMore = newPosts.length == 10;
        _isLoading = false;
      });

      // Prefetch images for next batch
      _prefetchImages(newPosts);
    } catch (e) {
      setState(() => _isLoading = false);
      _showRetrySnackbar();
    }
  }

  void _prefetchImages(List<Post> posts) {
    for (final post in posts) {
      if (post.imageUrls.isNotEmpty) {
        precacheImage(
          CachedNetworkImageProvider(post.imageUrls.first),
          context,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshFeed,
      color: AppTheme.gamingCyan,
      child: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Posts
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= _posts.length) {
                  return _buildLoadingIndicator();
                }
                return _PostCard(
                  post: _posts[index],
                  onVisible: () => _trackImpression(_posts[index].id),
                );
              },
              childCount: _posts.length + (_hasMore ? 1 : 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppTheme.gamingCyan),
        ),
      ),
    );
  }

  Future<void> _refreshFeed() async {
    HapticFeedback.mediumImpact(); // Tactile feedback
    
    setState(() {
      _posts.clear();
      _page = 0;
      _hasMore = true;
    });
    
    await _loadInitialPosts();
  }

  void _trackImpression(String postId) {
    // Analytics tracking for content ranking
    ref.read(analyticsServiceProvider).trackImpression(postId);
  }
}
```

### 2.2 Enhanced Content Interactions

```dart
// lib/widgets/feed/post_interaction_bar.dart
class PostInteractionBar extends StatefulWidget {
  final Post post;
  final Function(int) onVote;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const PostInteractionBar({
    super.key,
    required this.post,
    required this.onVote,
    required this.onComment,
    required this.onShare,
    required this.onSave,
  });

  @override
  State<PostInteractionBar> createState() => _PostInteractionBarState();
}

class _PostInteractionBarState extends State<PostInteractionBar>
    with TickerProviderStateMixin {
  late AnimationController _upvoteController;
  late AnimationController _downvoteController;
  int? _currentVote;

  @override
  void initState() {
    super.initState();
    _upvoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _downvoteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Upvote/Downvote with animation
          _buildVoteSection(),
          
          const SizedBox(width: 20),
          
          // Comments
          _InteractionButton(
            icon: Icons.chat_bubble_outline,
            label: _formatCount(widget.post.commentCount),
            onTap: widget.onComment,
          ),
          
          const Spacer(),
          
          // Share with haptic feedback
          _InteractionButton(
            icon: Icons.share_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              widget.onShare();
            },
          ),
          
          const SizedBox(width: 12),
          
          // Save/Bookmark
          _SaveButton(
            isSaved: widget.post.isSaved,
            onTap: widget.onSave,
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSection() {
    final isUpvoted = _currentVote == 1;
    final isDownvoted = _currentVote == -1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upvote
          _VoteButton(
            icon: Icons.arrow_upward_rounded,
            isActive: isUpvoted,
            activeColor: AppTheme.gamingCyan,
            onTap: () => _handleVote(isUpvoted ? 0 : 1),
          ),
          
          // Score with animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: Text(
              _formatCount(widget.post.score),
              key: ValueKey(widget.post.score),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isUpvoted
                    ? AppTheme.gamingCyan
                    : isDownvoted
                        ? AppTheme.errorColor
                        : AppTheme.textPrimary,
              ),
            ),
          ),
          
          // Downvote
          _VoteButton(
            icon: Icons.arrow_downward_rounded,
            isActive: isDownvoted,
            activeColor: AppTheme.errorColor,
            onTap: () => _handleVote(isDownvoted ? 0 : -1),
          ),
        ],
      ),
    );
  }

  void _handleVote(int vote) {
    // Optimistic update with haptic feedback
    HapticFeedback.selectionClick();
    
    setState(() => _currentVote = vote);
    
    // Trigger animation
    if (vote == 1) {
      _upvoteController.forward().then((_) => _upvoteController.reverse());
    } else if (vote == -1) {
      _downvoteController.forward().then((_) => _downvoteController.reverse());
    }
    
    widget.onVote(vote);
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _VoteButton({
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              size: 22,
              color: isActive ? activeColor : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
```

### 2.3 Double-Tap to Like Animation

```dart
// lib/widgets/feed/double_tap_like_widget.dart
class DoubleTapLikeWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onDoubleTap;
  final bool isLiked;

  const DoubleTapLikeWidget({
    super.key,
    required this.child,
    required this.onDoubleTap,
    required this.isLiked,
  });

  @override
  State<DoubleTapLikeWidget> createState() => _DoubleTapLikeWidgetState();
}

class _DoubleTapLikeWidgetState extends State<DoubleTapLikeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 30),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
      }
    });
  }

  void _handleDoubleTap() {
    if (!widget.isLiked) {
      widget.onDoubleTap();
    }
    
    HapticFeedback.mediumImpact();
    
    setState(() => _showHeart = true);
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          widget.child,
          if (_showHeart)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentPink.withOpacity(0.5),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite,
                        size: 100,
                        color: AppTheme.accentPink,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
```

---

## 3. Community Experience

### 3.1 Real-Time Online Presence

```dart
// lib/services/community/presence_service.dart
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;
  Timer? _heartbeatTimer;

  final _onlineUsersController = StreamController<Map<String, OnlineUser>>.broadcast();
  Stream<Map<String, OnlineUser>> get onlineUsersStream => _onlineUsersController.stream;

  final Map<String, OnlineUser> _onlineUsers = {};

  /// Join community presence channel
  Future<void> joinCommunity(String communityId, String userId) async {
    _presenceChannel = _client.channel(
      'presence:community:$communityId',
      opts: const RealtimeChannelConfig(self: true),
    );

    _presenceChannel!
      .onPresenceSync((payload) {
        _syncPresence(payload);
      })
      .onPresenceJoin((payload) {
        _handleJoin(payload);
      })
      .onPresenceLeave((payload) {
        _handleLeave(payload);
      })
      .subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({
            'user_id': userId,
            'online_at': DateTime.now().toIso8601String(),
            'status': 'online',
          });
        }
      });

    // Start heartbeat to keep presence alive
    _startHeartbeat(userId);
  }

  void _startHeartbeat(String userId) {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _presenceChannel?.track({
        'user_id': userId,
        'online_at': DateTime.now().toIso8601String(),
        'status': 'online',
      });
    });
  }

  void _syncPresence(PresenceSyncPayload payload) {
    _onlineUsers.clear();
    for (final presence in payload.joins.entries) {
      final user = OnlineUser.fromPresence(presence.value);
      _onlineUsers[user.userId] = user;
    }
    _onlineUsersController.add(Map.from(_onlineUsers));
  }

  void _handleJoin(PresenceJoinPayload payload) {
    for (final presence in payload.newPresences) {
      final user = OnlineUser.fromPresence(presence);
      _onlineUsers[user.userId] = user;
    }
    _onlineUsersController.add(Map.from(_onlineUsers));
  }

  void _handleLeave(PresenceLeavePayload payload) {
    for (final presence in payload.leftPresences) {
      _onlineUsers.remove(presence['user_id']);
    }
    _onlineUsersController.add(Map.from(_onlineUsers));
  }

  Future<void> leaveCommunity() async {
    _heartbeatTimer?.cancel();
    await _presenceChannel?.untrack();
    await _presenceChannel?.unsubscribe();
    _onlineUsers.clear();
  }
}

class OnlineUser {
  final String userId;
  final DateTime onlineAt;
  final String status;

  OnlineUser({
    required this.userId,
    required this.onlineAt,
    required this.status,
  });

  factory OnlineUser.fromPresence(Map<String, dynamic> data) {
    return OnlineUser(
      userId: data['user_id'],
      onlineAt: DateTime.parse(data['online_at']),
      status: data['status'] ?? 'online',
    );
  }
}
```

### 3.2 Typing Indicators for Chat

```dart
// lib/widgets/chat/typing_indicator.dart
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  
  const TypingIndicator({super.key, required this.typingUsers});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _dot1;
  late Animation<double> _dot2;
  late Animation<double> _dot3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4)),
    );
    _dot2 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.6)),
    );
    _dot3 = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.4, 0.8)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) return const SizedBox.shrink();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: widget.typingUsers.isNotEmpty ? 1.0 : 0.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // User avatars (max 3)
            _buildAvatarStack(),
            const SizedBox(width: 8),
            // Animated dots
            _buildAnimatedDots(),
            const SizedBox(width: 8),
            // Text
            Text(
              _getTypingText(),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarStack() {
    final displayUsers = widget.typingUsers.take(3).toList();
    return SizedBox(
      width: 20 + (displayUsers.length - 1) * 12,
      height: 20,
      child: Stack(
        children: displayUsers.asMap().entries.map((entry) {
          return Positioned(
            left: entry.key * 12.0,
            child: CircleAvatar(
              radius: 10,
              backgroundColor: AppTheme.gamingPurple,
              child: Text(
                entry.value[0].toUpperCase(),
                style: const TextStyle(fontSize: 10),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAnimatedDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(_dot1.value),
            const SizedBox(width: 3),
            _buildDot(_dot2.value),
            const SizedBox(width: 3),
            _buildDot(_dot3.value),
          ],
        );
      },
    );
  }

  Widget _buildDot(double animation) {
    return Transform.translate(
      offset: Offset(0, -4 * sin(animation * pi)),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.gamingCyan.withOpacity(0.5 + 0.5 * animation),
        ),
      ),
    );
  }

  String _getTypingText() {
    final count = widget.typingUsers.length;
    if (count == 1) {
      return '${widget.typingUsers[0]} is typing';
    } else if (count == 2) {
      return '${widget.typingUsers[0]} and ${widget.typingUsers[1]} are typing';
    } else {
      return '${widget.typingUsers[0]} and ${count - 1} others are typing';
    }
  }
}
```

---

## 4. Gaming Features & Tournaments

### 4.1 Tournament Countdown Timer

```dart
// lib/widgets/tournament/tournament_countdown.dart
class TournamentCountdown extends StatefulWidget {
  final DateTime startTime;
  final VoidCallback? onComplete;

  const TournamentCountdown({
    super.key,
    required this.startTime,
    this.onComplete,
  });

  @override
  State<TournamentCountdown> createState() => _TournamentCountdownState();
}

class _TournamentCountdownState extends State<TournamentCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    setState(() {
      _remaining = widget.startTime.difference(now);
    });

    if (_remaining.isNegative) {
      _timer.cancel();
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return _buildLiveIndicator();
    }

    final days = _remaining.inDays;
    final hours = _remaining.inHours.remainder(24);
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppTheme.gamingPurple.withOpacity(0.3),
            AppTheme.gamingCyan.withOpacity(0.3),
          ],
        ),
        border: Border.all(color: AppTheme.gamingCyan.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(
            'TOURNAMENT STARTS IN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (days > 0) ...[
                _TimeUnit(value: days, label: 'DAYS'),
                _buildSeparator(),
              ],
              _TimeUnit(value: hours, label: 'HRS'),
              _buildSeparator(),
              _TimeUnit(value: minutes, label: 'MIN'),
              _buildSeparator(),
              _TimeUnit(value: seconds, label: 'SEC'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppTheme.gamingCyan,
        ),
      ),
    );
  }

  Widget _buildLiveIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.errorColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.errorColor.withOpacity(0.5),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'LIVE NOW',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;

  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppTheme.surfaceColor,
            boxShadow: [
              BoxShadow(
                color: AppTheme.gamingCyan.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
```

### 4.2 Match Result Animation

```dart
// lib/widgets/tournament/match_result_animation.dart
class MatchResultAnimation extends StatefulWidget {
  final bool isWinner;
  final int scorePlayer;
  final int scoreOpponent;
  final VoidCallback onComplete;

  const MatchResultAnimation({
    super.key,
    required this.isWinner,
    required this.scorePlayer,
    required this.scoreOpponent,
    required this.onComplete,
  });

  @override
  State<MatchResultAnimation> createState() => _MatchResultAnimationState();
}

class _MatchResultAnimationState extends State<MatchResultAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _mainController, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: const Interval(0.0, 0.3)),
    );

    // Play haptic feedback based on result
    if (widget.isWinner) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    _mainController.forward();
    if (widget.isWinner) {
      _particleController.repeat();
    }

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), widget.onComplete);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Particle effects for winner
                if (widget.isWinner) _buildParticles(),
                
                // Result card
                _buildResultCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isWinner
              ? [AppTheme.gamingCyan, AppTheme.gamingPurple]
              : [AppTheme.surfaceColor, AppTheme.backgroundColor],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isWinner
                ? AppTheme.gamingCyan.withOpacity(0.5)
                : Colors.black54,
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Trophy or X icon
          Icon(
            widget.isWinner ? Icons.emoji_events : Icons.close,
            size: 80,
            color: widget.isWinner ? Colors.amber : AppTheme.errorColor,
          ),
          const SizedBox(height: 16),
          
          // Result text
          Text(
            widget.isWinner ? 'VICTORY!' : 'DEFEAT',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              color: widget.isWinner ? Colors.white : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Score
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.scorePlayer}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.isWinner ? Colors.white : AppTheme.gamingCyan,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
              Text(
                '${widget.scoreOpponent}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: widget.isWinner ? Colors.white.withOpacity(0.5) : AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParticles() {
    // Confetti-like particle effect
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return CustomPaint(
          painter: ConfettiPainter(
            progress: _particleController.value,
          ),
          size: const Size(300, 300),
        );
      },
    );
  }
}
```

---

## 5. Notifications & Engagement

### 5.1 Smart Notification Grouping

```dart
// lib/services/notification/notification_grouper.dart
class NotificationGrouper {
  /// Group notifications intelligently
  List<NotificationGroup> groupNotifications(List<NotificationModel> notifications) {
    final groups = <String, List<NotificationModel>>{};
    final singles = <NotificationModel>[];

    for (final notification in notifications) {
      final groupKey = _getGroupKey(notification);
      
      if (groupKey != null) {
        groups.putIfAbsent(groupKey, () => []).add(notification);
      } else {
        singles.add(notification);
      }
    }

    final result = <NotificationGroup>[];

    // Add grouped notifications
    for (final entry in groups.entries) {
      if (entry.value.length >= 2) {
        result.add(NotificationGroup(
          type: _getGroupType(entry.value.first),
          notifications: entry.value,
          summary: _generateSummary(entry.value),
          timestamp: entry.value.first.createdAt,
        ));
      } else {
        singles.addAll(entry.value);
      }
    }

    // Add single notifications
    for (final notification in singles) {
      result.add(NotificationGroup(
        type: notification.type,
        notifications: [notification],
        summary: notification.title,
        timestamp: notification.createdAt,
      ));
    }

    // Sort by timestamp
    result.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return result;
  }

  String? _getGroupKey(NotificationModel notification) {
    switch (notification.type) {
      case 'like':
        return 'likes_${notification.data?['post_id']}';
      case 'comment':
        return 'comments_${notification.data?['post_id']}';
      case 'follow':
        return 'follows_${_getTimeWindow(notification.createdAt)}';
      default:
        return null;
    }
  }

  String _getTimeWindow(DateTime time) {
    // Group within 1-hour windows
    final hour = time.hour;
    final day = time.day;
    return '${day}_$hour';
  }

  String _generateSummary(List<NotificationModel> notifications) {
    final type = notifications.first.type;
    final count = notifications.length;

    switch (type) {
      case 'like':
        final names = notifications
            .take(2)
            .map((n) => n.data?['liker_name'])
            .join(', ');
        if (count > 2) {
          return '$names and ${count - 2} others liked your post';
        }
        return '$names liked your post';
        
      case 'comment':
        return '$count new comments on your post';
        
      case 'follow':
        return '$count new followers';
        
      default:
        return '$count notifications';
    }
  }
}

class NotificationGroup {
  final String type;
  final List<NotificationModel> notifications;
  final String summary;
  final DateTime timestamp;

  NotificationGroup({
    required this.type,
    required this.notifications,
    required this.summary,
    required this.timestamp,
  });

  bool get isGrouped => notifications.length > 1;
}
```

### 5.2 In-App Notification Toast

```dart
// lib/widgets/notification/in_app_notification_toast.dart
class InAppNotificationToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String title,
    required String body,
    String? avatarUrl,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    // Dismiss current if any
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    
    _currentEntry = OverlayEntry(
      builder: (context) => _NotificationToastWidget(
        title: title,
        body: body,
        avatarUrl: avatarUrl,
        onTap: () {
          _currentEntry?.remove();
          _currentEntry = null;
          onTap?.call();
        },
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    overlay.insert(_currentEntry!);

    // Auto dismiss
    Future.delayed(duration, () {
      _currentEntry?.remove();
      _currentEntry = null;
    });
  }
}

class _NotificationToastWidget extends StatefulWidget {
  final String title;
  final String body;
  final String? avatarUrl;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationToastWidget({
    required this.title,
    required this.body,
    this.avatarUrl,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NotificationToastWidget> createState() => _NotificationToastWidgetState();
}

class _NotificationToastWidgetState extends State<_NotificationToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  double _dragOffset = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _controller.forward();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            onVerticalDragUpdate: (details) {
              setState(() {
                _dragOffset += details.delta.dy;
              });
            },
            onVerticalDragEnd: (details) {
              if (_dragOffset < -50) {
                widget.onDismiss();
              } else {
                setState(() => _dragOffset = 0);
              }
            },
            child: Transform.translate(
              offset: Offset(0, _dragOffset.clamp(-100, 0)),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppTheme.surfaceColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: AppTheme.gamingCyan.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      if (widget.avatarUrl != null)
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: CachedNetworkImageProvider(widget.avatarUrl!),
                        )
                      else
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.gamingPurple,
                          child: const Icon(Icons.notifications, color: Colors.white),
                        ),
                      const SizedBox(width: 12),
                      
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.body,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      // Dismiss hint
                      Icon(
                        Icons.keyboard_arrow_up,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

---

## 6. Performance & Reliability

### 6.1 Image Loading with Placeholder

```dart
// lib/widgets/common/optimized_image.dart
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildError(),
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 200),
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppTheme.surfaceColor,
      highlightColor: AppTheme.surfaceColor.withOpacity(0.5),
      child: Container(
        width: width,
        height: height,
        color: AppTheme.surfaceColor,
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: AppTheme.surfaceColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: AppTheme.textSecondary),
          const SizedBox(height: 8),
          Text(
            'Failed to load',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
```

### 6.2 Network Retry with Exponential Backoff

```dart
// lib/services/core/network_service.dart
class NetworkService {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  /// Execute operation with automatic retry and exponential backoff
  Future<T> executeWithRetry<T>({
    required String operationName,
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt >= maxAttempts) {
          ErrorReportingService().reportError(
            '$operationName failed after $maxAttempts attempts: $e',
            null,
            context: operationName,
          );
          rethrow;
        }

        // Check if error is retryable
        if (!_isRetryable(e)) {
          rethrow;
        }

        // Wait with exponential backoff
        await Future.delayed(delay);
        delay *= 2; // Double the delay for next attempt
      }
    }
  }

  bool _isRetryable(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is PostgrestException) {
      // Retry on connection errors, not on validation errors
      return error.code == 'PGRST301' || error.code?.startsWith('5') == true;
    }
    return false;
  }
}
```

---

## 7. Offline Experience

### 7.1 Offline Mode Banner

```dart
// lib/widgets/common/offline_banner.dart
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: ConnectivityService().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOffline = snapshot.data?.contains(ConnectivityResult.none) ?? false;

        return AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          offset: isOffline ? Offset.zero : const Offset(0, -1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: isOffline ? 1 : 0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: AppTheme.warningColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_off, size: 16, color: Colors.black87),
                  const SizedBox(width: 8),
                  const Text(
                    'You\'re offline. Some features may be limited.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
```

### 7.2 Pending Actions Queue

```dart
// lib/services/core/pending_actions_service.dart
class PendingActionsService {
  static final PendingActionsService _instance = PendingActionsService._internal();
  factory PendingActionsService() => _instance;
  PendingActionsService._internal();

  final List<PendingAction> _queue = [];
  bool _isProcessing = false;

  /// Queue an action to be executed when online
  Future<void> queueAction(PendingAction action) async {
    _queue.add(action);
    await _saveQueue();
    
    // Try to process if online
    _processQueue();
  }

  /// Process queued actions
  Future<void> _processQueue() async {
    if (_isProcessing) return;
    if (!await ConnectivityService().isOnline()) return;
    if (_queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty && await ConnectivityService().isOnline()) {
      final action = _queue.first;
      
      try {
        await action.execute();
        _queue.removeAt(0);
        await _saveQueue();
      } catch (e) {
        // If failed, increment retry count
        action.retryCount++;
        if (action.retryCount >= 3) {
          _queue.removeAt(0); // Give up after 3 retries
        }
        break; // Stop processing on error
      }
    }

    _isProcessing = false;
  }

  Future<void> _saveQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _queue.map((a) => a.toJson()).toList();
    await prefs.setString('pending_actions', jsonEncode(jsonList));
  }

  Future<void> loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('pending_actions');
    if (jsonStr != null) {
      final jsonList = jsonDecode(jsonStr) as List;
      _queue.addAll(jsonList.map((j) => PendingAction.fromJson(j)));
    }
    
    // Start processing
    _processQueue();
  }
}

class PendingAction {
  final String type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int retryCount;

  PendingAction({
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Future<void> execute() async {
    switch (type) {
      case 'vote':
        await CommunityPostService().votePost(
          data['postId'],
          data['userId'],
          data['vote'],
        );
        break;
      case 'comment':
        await CommunityPostService().addComment(
          postId: data['postId'],
          userId: data['userId'],
          content: data['content'],
        );
        break;
      // Add more action types...
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'createdAt': createdAt.toIso8601String(),
    'retryCount': retryCount,
  };

  factory PendingAction.fromJson(Map<String, dynamic> json) => PendingAction(
    type: json['type'],
    data: json['data'],
    createdAt: DateTime.parse(json['createdAt']),
    retryCount: json['retryCount'] ?? 0,
  );
}
```

---

## 8. Security & Trust

### 8.1 Content Warning Dialog

```dart
// lib/widgets/moderation/content_warning_dialog.dart
class ContentWarningDialog extends StatelessWidget {
  final String warningType; // 'nsfw', 'spoiler', 'sensitive'
  final VoidCallback onProceed;
  final VoidCallback onCancel;

  const ContentWarningDialog({
    super.key,
    required this.warningType,
    required this.onProceed,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(
            _getIcon(),
            color: _getColor(),
          ),
          const SizedBox(width: 12),
          Text(_getTitle()),
        ],
      ),
      content: Text(
        _getMessage(),
        style: TextStyle(color: AppTheme.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: const Text('Go Back'),
        ),
        ElevatedButton(
          onPressed: onProceed,
          style: ElevatedButton.styleFrom(
            backgroundColor: _getColor(),
          ),
          child: const Text('View Content'),
        ),
      ],
    );
  }

  IconData _getIcon() {
    switch (warningType) {
      case 'nsfw':
        return Icons.visibility_off;
      case 'spoiler':
        return Icons.warning_amber;
      case 'sensitive':
        return Icons.shield;
      default:
        return Icons.info;
    }
  }

  Color _getColor() {
    switch (warningType) {
      case 'nsfw':
        return AppTheme.errorColor;
      case 'spoiler':
        return AppTheme.warningColor;
      case 'sensitive':
        return AppTheme.infoColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  String _getTitle() {
    switch (warningType) {
      case 'nsfw':
        return 'Adult Content';
      case 'spoiler':
        return 'Spoiler Warning';
      case 'sensitive':
        return 'Sensitive Content';
      default:
        return 'Content Warning';
    }
  }

  String _getMessage() {
    switch (warningType) {
      case 'nsfw':
        return 'This content is marked as NSFW (Not Safe For Work). It may contain adult themes.';
      case 'spoiler':
        return 'This content contains spoilers. Viewing may reveal plot details.';
      case 'sensitive':
        return 'This content has been marked as sensitive. It may be disturbing to some viewers.';
      default:
        return 'This content has been flagged for review.';
    }
  }
}
```

---

## 9. Accessibility

### 9.1 Semantic Labels for Gaming UI

```dart
// lib/widgets/accessibility/accessible_game_card.dart
class AccessibleGameCard extends StatelessWidget {
  final Game game;
  final VoidCallback onTap;

  const AccessibleGameCard({
    super.key,
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _buildSemanticLabel(),
      button: true,
      enabled: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // ... card UI
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>[
      game.name,
      '${game.playerCount} active players',
      if (game.isLive) 'Live tournament available',
      if (game.isNew) 'New game',
      'Tap to view details',
    ];
    return parts.join('. ');
  }
}
```

### 9.2 Reduced Motion Support

```dart
// lib/utils/accessibility_utils.dart
class AccessibilityUtils {
  static bool shouldReduceMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  static Duration getAnimationDuration(BuildContext context, Duration normal) {
    if (shouldReduceMotion(context)) {
      return Duration.zero;
    }
    return normal;
  }

  static Curve getAnimationCurve(BuildContext context) {
    if (shouldReduceMotion(context)) {
      return Curves.linear;
    }
    return Curves.easeInOut;
  }
}

// Usage in widget
class AnimatedGameCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final duration = AccessibilityUtils.getAnimationDuration(
      context,
      const Duration(milliseconds: 300),
    );

    return AnimatedContainer(
      duration: duration,
      curve: AccessibilityUtils.getAnimationCurve(context),
      // ... rest of widget
    );
  }
}
```

---

## 10. Platform-Specific Optimizations

### 10.1 Adaptive Layout

```dart
// lib/widgets/layout/adaptive_layout.dart
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1200 && desktop != null) {
          return desktop!;
        } else if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}

// Usage
class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      mobile: _MobileHomeLayout(),
      tablet: _TabletHomeLayout(),
      desktop: _DesktopHomeLayout(),
    );
  }
}
```

### 10.2 Platform-Specific Haptics

```dart
// lib/utils/haptic_utils.dart
class HapticUtils {
  static void onTap() {
    if (Platform.isIOS) {
      HapticFeedback.lightImpact();
    } else if (Platform.isAndroid) {
      HapticFeedback.selectionClick();
    }
  }

  static void onSuccess() {
    if (Platform.isIOS) {
      HapticFeedback.mediumImpact();
    } else if (Platform.isAndroid) {
      HapticFeedback.heavyImpact();
    }
  }

  static void onError() {
    HapticFeedback.vibrate();
  }

  static void onVote() {
    HapticFeedback.selectionClick();
  }

  static void onDoubleTapLike() {
    HapticFeedback.mediumImpact();
  }
}
```

---

## Implementation Priority

| Priority | Feature | Impact | Effort |
|----------|---------|--------|--------|
| 🔴 High | Offline support & pending actions | High | Medium |
| 🔴 High | Smart notification grouping | High | Low |
| 🔴 High | Permission request UX | High | Low |
| 🟡 Medium | Double-tap like animation | Medium | Low |
| 🟡 Medium | Real-time presence | Medium | Medium |
| 🟡 Medium | Typing indicators | Medium | Low |
| 🟢 Low | Match result animations | Low | Medium |
| 🟢 Low | Confetti effects | Low | Medium |

---

## Quick Wins (Implement Today)

1. **Add haptic feedback** to all interactive elements
2. **Implement shimmer loading** for all list items
3. **Add pull-to-refresh** with visual feedback
4. **Enable prefetching** for paginated lists
5. **Show offline banner** when connectivity lost
6. **Group notifications** by type and time

---

## Metrics to Track

- **Time to Interactive (TTI)** - App startup time
- **Feed Scroll FPS** - Should maintain 60fps
- **Error Rate** - Track failed operations
- **Engagement Rate** - Votes, comments, shares per session
- **Retention** - Day 1, Day 7, Day 30
- **Permission Grant Rate** - Track contextual vs upfront requests

---

*This guide combines mobile platform best practices with social gaming UX patterns to create an engaging, performant, and reliable user experience.*
