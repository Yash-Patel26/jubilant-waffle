import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile_screen.dart';
import '../post/post_detail_screen.dart';
import '../reels/reel_detail_screen.dart';
import '../chat/chat_screen.dart';
import 'package:gamer_flick/services/chat/messaging_service.dart';

import 'followers_following_screen.dart';
import '../settings/settings_screen.dart';
import 'package:gamer_flick/services/post/saved_posts_service.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _profileDataFuture;
  final _supabase = Supabase.instance.client;
  late String _profileUserId;
  List<Map<String, dynamic>> _highlights = [];
  late TabController _tabController;
  List<Map<String, dynamic>> _savedPosts = [];
  List<Map<String, dynamic>> _savedReels = [];
  final SavedPostsService _savedPostsService = SavedPostsService();
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _profileUserId = widget.userId ?? _supabase.auth.currentUser!.id;
    _profileDataFuture = _loadProfileData();
    _loadHighlights();
    _loadSavedContent();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadProfileData() async {
    try {
      final profile = await _supabase
          .from('profiles')
          .select()
          .eq('id', _profileUserId)
          .single();

      final posts = await _supabase
          .from('posts')
          .select(
              '*, profiles!posts_user_id_fkey(*), post_likes(*), comments(*)')
          .eq('user_id', _profileUserId)
          .order('created_at', ascending: false);

      final reels = await _supabase
          .from('reels')
          .select('*, reel_likes(*), reel_comments(*)')
          .eq('user_id', _profileUserId)
          .order('created_at', ascending: false);

      final followerCount = await _supabase
          .from('follows')
          .select()
          .eq('following_id', _profileUserId);

      final followingCount = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', _profileUserId);

      final currentUser = _supabase.auth.currentUser;
      bool isFollowing = false;
      if (currentUser != null && currentUser.id != _profileUserId) {
        final follow = await _supabase
            .from('follows')
            .select()
            .eq('follower_id', currentUser.id)
            .eq('following_id', _profileUserId)
            .maybeSingle();
        isFollowing = follow != null;
      }

      return {
        'profile': profile,
        'posts': posts,
        'reels': reels,
        'follower_count': (followerCount as List).length,
        'following_count': (followingCount as List).length,
        'is_following': isFollowing,
      };
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
      return {
        'profile': null,
        'posts': [],
        'reels': [],
        'follower_count': 0,
        'following_count': 0,
        'is_following': false,
      };
    }
  }

  Future<void> _loadHighlights() async {
    try {
      final highlights = await _supabase
          .from('highlights')
          .select()
          .eq('user_id', _profileUserId)
          .order('created_at', ascending: false);
      setState(() {
        _highlights = (highlights as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _loadSavedContent() async {
    try {
      // Load saved posts only (schema provides saved_posts for posts)
      final savedPosts = await _savedPostsService.getSavedPosts();
      if (!mounted) return;
      setState(() {
        _savedPosts = savedPosts;
        _savedReels = const []; // No separate saved reels table in schema
      });
    } catch (e) {
      // Handle silently to avoid noisy logs in UI
    }
  }

  Future<void> _toggleFollow(bool isCurrentlyFollowing) async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null || currentUser.id == _profileUserId) return;

    try {
      if (isCurrentlyFollowing) {
        await _supabase.from('follows').delete().match({
          'follower_id': currentUser.id,
          'following_id': _profileUserId,
        });
      } else {
        await _supabase.from('follows').insert({
          'follower_id': currentUser.id,
          'following_id': _profileUserId,
        });
      }
      setState(() {
        _profileDataFuture = _loadProfileData();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating follow status: $e')),
        );
      }
    }
  }

  Future<void> _onMessage() async {
    try {
      final messagingService = MessagingService();
      final conversation =
          await messagingService.findOrCreateConversation(_profileUserId);

      if (mounted && conversation != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversation['id'],
            otherUserId: _profileUserId,
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  void _onBackPressed() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _profileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?['profile'] == null) {
            return Center(
              child: Text(
                'Error: ${snapshot.error ?? "Profile not found."}',
              ),
            );
          }

          final data = snapshot.data!;
          final profile = data['profile'];
          final posts = (data['posts'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final reels = (data['reels'] as List)
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          final followerCount = data['follower_count'] as int;
          final followingCount = data['following_count'] as int;
          final isFollowing = data['is_following'] as bool;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _profileDataFuture = _loadProfileData();
              });
              await _loadSavedContent();
            },
            child: Column(
              children: [
                _buildProfileHeader(
                  theme: theme,
                  profile: profile,
                  isFollowing: isFollowing,
                  totalPosts: posts.length + reels.length,
                  followerCount: followerCount,
                  followingCount: followingCount,
                ),
                _buildContentTabs(),
                Expanded(
                  child: _buildContentArea(posts, reels),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader({
    required ThemeData theme,
    required Map<String, dynamic> profile,
    required bool isFollowing,
    required int totalPosts,
    required int followerCount,
    required int followingCount,
  }) {
    final username = profile['username'] ?? 'Unknown User';
    final bio = profile['bio'] ?? '';
    final avatarUrl = profile['avatar_url'] ?? profile['profile_picture_url'];
    final isCurrentUser =
        profile['id'] == Supabase.instance.client.auth.currentUser?.id;

    Widget avatar = CircleAvatar(
      radius: 55,
      backgroundColor: theme.cardColor,
      backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
          ? NetworkImage(avatarUrl.toString())
          : null,
      child: (avatarUrl == null || avatarUrl.toString().isEmpty)
          ? Icon(
              Icons.person,
              size: 55,
              color: theme.iconTheme.color?.withOpacity(0.5),
            )
          : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: avatar),
          const SizedBox(height: 12),
          Text(
            username,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statPill(theme, '$totalPosts', 'posts'),
              const SizedBox(width: 12),
              _statPill(theme, '$followerCount', 'followers'),
              const SizedBox(width: 12),
              _statPill(theme, '$followingCount', 'following'),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.alternate_email, size: 14),
                const SizedBox(width: 6),
                Text(
                  username,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 36,
                child: isCurrentUser
                    ? ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      EditProfileScreen(userProfile: profile),
                                ),
                              )
                              .then((_) => setState(() {
                                    _profileDataFuture = _loadProfileData();
                                  }));
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () => _toggleFollow(isFollowing),
                        icon: Icon(
                          isFollowing ? Icons.check : Icons.person_add,
                          size: 16,
                        ),
                        label: Text(isFollowing ? 'Following' : 'Follow'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
              ),
              if (isCurrentUser) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings),
                  tooltip: 'Settings',
                ),
              ],
            ],
          ),
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              bio,
              style: TextStyle(
                fontSize: 14,
                color: theme.textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _statPill(ThemeData theme, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStatistics(
      ThemeData theme,
      List<Map<String, dynamic>> posts,
      List<Map<String, dynamic>> reels,
      int followerCount,
      int followingCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final totalPosts = posts.length + reels.length;

          if (isMobile) {
            // Mobile layout - horizontal with smaller spacing
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(theme, '$totalPosts', 'Posts', isMobile, null),
                _buildStatItem(theme, '$followerCount', 'Followers', isMobile,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersFollowingScreen(
                        userId: _profileUserId,
                        mode: UserListMode.followers,
                      ),
                    ),
                  );
                }),
                _buildStatItem(theme, '$followingCount', 'Following', isMobile,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersFollowingScreen(
                        userId: _profileUserId,
                        mode: UserListMode.following,
                      ),
                    ),
                  );
                }),
              ],
            );
          } else {
            // Desktop layout - horizontal with more spacing
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(theme, '$totalPosts', 'Posts', isMobile, null),
                _buildStatItem(theme, '$followerCount', 'Followers', isMobile,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersFollowingScreen(
                        userId: _profileUserId,
                        mode: UserListMode.followers,
                      ),
                    ),
                  );
                }),
                _buildStatItem(theme, '$followingCount', 'Following', isMobile,
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FollowersFollowingScreen(
                        userId: _profileUserId,
                        mode: UserListMode.following,
                      ),
                    ),
                  );
                }),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String count, String label,
      bool isMobile, VoidCallback? onTap) {
    final widget = Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 12 : 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: theme.colorScheme.surface.withOpacity(0),
          ),
          child: widget,
        ),
      );
    }

    return widget;
  }

  Widget _buildContentTabs() {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.textTheme.bodySmall?.color,
            indicatorColor: theme.colorScheme.primary,
            indicatorWeight: 2,
            labelStyle: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: isMobile ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(
                icon: Icon(
                  Icons.grid_on,
                  size: isMobile ? 20 : 24,
                ),
                text: 'Posts',
              ),
              Tab(
                icon: Icon(
                  Icons.play_circle_outline,
                  size: isMobile ? 20 : 24,
                ),
                text: 'Reels',
              ),
              Tab(
                icon: Icon(
                  Icons.bookmark_border,
                  size: isMobile ? 20 : 24,
                ),
                text: 'Saved',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContentArea(
      List<Map<String, dynamic>> posts, List<Map<String, dynamic>> reels) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildPostsTab(posts),
        _buildReelsTab(reels),
        _buildSavedTab(),
      ],
    );
  }

  Widget _buildPostsTab(List<Map<String, dynamic>> posts) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: posts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.grid_on,
                        size: 64,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No posts yet.',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final cross = isMobile ? 3 : 4;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final post = posts[index];
                      return _buildPostGridItem(post);
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildReelsTab(List<Map<String, dynamic>> reels) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: reels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reels yet.',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final cross = isMobile ? 3 : 4;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: reels.length,
                    itemBuilder: (context, index) {
                      final reel = reels[index];
                      return _buildReelGridItem(reel);
                    },
                  );
                }),
        ),
      ],
    );
  }

  Widget _buildSavedTab() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _savedPosts.isEmpty && _savedReels.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved posts yet.',
                        style: TextStyle(
                          fontSize: 18,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                )
              : LayoutBuilder(builder: (context, constraints) {
                  final isMobile = constraints.maxWidth < 600;
                  final cross = isMobile ? 3 : 4;
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cross,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _savedPosts.length + _savedReels.length,
                    itemBuilder: (context, index) {
                      if (index < _savedPosts.length) {
                        final post = _savedPosts[index];
                        return _buildPostGridItem(post);
                      } else {
                        final reelIndex = index - _savedPosts.length;
                        final reel = _savedReels[reelIndex];
                        return _buildReelGridItem(reel);
                      }
                    },
                  );
                }),
        ),
      ],
    );
  }

  // Helper: extract a preview image URL for a post
  String? _extractPostPreviewUrl(Map<String, dynamic> post) {
    // Common possibilities across schema revisions
    final dynamic mediaUrls = post['media_urls']; // text[] in schema
    final String? mediaUrl = post['media_url']; // legacy singular
    final String? imageUrl = post['image_url']; // potential legacy

    if (mediaUrls is List && mediaUrls.isNotEmpty) {
      for (final url in mediaUrls) {
        if (url is String && url.trim().isNotEmpty) {
          // Only return if it's an image file, not video
          final lowerUrl = url.toLowerCase();
          if (lowerUrl.contains('.jpg') ||
              lowerUrl.contains('.jpeg') ||
              lowerUrl.contains('.png') ||
              lowerUrl.contains('.gif') ||
              lowerUrl.contains('.webp') ||
              lowerUrl.contains('.bmp')) {
            return url;
          }
        }
      }
    }
    if (mediaUrl != null && mediaUrl.trim().isNotEmpty) {
      final lowerUrl = mediaUrl.toLowerCase();
      if (lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png') ||
          lowerUrl.contains('.gif') ||
          lowerUrl.contains('.webp') ||
          lowerUrl.contains('.bmp')) {
        return mediaUrl;
      }
    }
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final lowerUrl = imageUrl.toLowerCase();
      if (lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png') ||
          lowerUrl.contains('.gif') ||
          lowerUrl.contains('.webp') ||
          lowerUrl.contains('.bmp')) {
        return imageUrl;
      }
    }
    return null;
  }

  // Helper: extract a preview (thumbnail) for a reel
  String? _extractReelPreviewUrl(Map<String, dynamic> reel) {
    final String? thumb = reel['thumbnail_url'];
    final String? video = reel['video_url'];

    // Only return thumbnail, never video URL for image display
    if (thumb != null && thumb.trim().isNotEmpty) {
      // Validate that it's actually an image
      final lowerUrl = thumb.toLowerCase();
      if (lowerUrl.contains('.jpg') ||
          lowerUrl.contains('.jpeg') ||
          lowerUrl.contains('.png') ||
          lowerUrl.contains('.gif') ||
          lowerUrl.contains('.webp') ||
          lowerUrl.contains('.bmp')) {
        return thumb;
      }
    }
    return null;
  }

  Widget _buildPostGridItem(Map<String, dynamic> post) {
    final theme = Theme.of(context);
    final mediaUrl = _extractPostPreviewUrl(post);
    return GestureDetector(
      onTap: () async {
        if (!mounted || _isNavigating) return;
        setState(() {
          _isNavigating = true;
        });
        final isDialog = MediaQuery.of(context).size.width >= 900;
        if (isDialog) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Material(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: PostDetailScreen(post: post, asDialog: true),
                  ),
                ),
              ),
            ),
          );
        } else {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => PostDetailScreen(post: post)),
          );
        }
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: mediaUrl != null
              ? DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading errors silently
                    print('Failed to load post image: $mediaUrl');
                  },
                )
              : null,
          color: mediaUrl == null ? theme.cardColor : null,
        ),
        child: mediaUrl == null
            ? Center(
                child: Icon(
                  Icons.image,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildReelGridItem(Map<String, dynamic> reel) {
    final theme = Theme.of(context);
    final mediaUrl = _extractReelPreviewUrl(reel);
    return GestureDetector(
      onTap: () async {
        if (!mounted || _isNavigating) return;
        setState(() {
          _isNavigating = true;
        });
        final isDialog = MediaQuery.of(context).size.width >= 900;
        if (isDialog) {
          await showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Material(
                color: Colors.black54,
                child: Center(
                  child: GestureDetector(
                    onTap: () {},
                    child: ReelDetailScreen(reel: reel, asDialog: true),
                  ),
                ),
              ),
            ),
          );
        } else {
          await Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(builder: (_) => ReelDetailScreen(reel: reel)),
          );
        }
        if (mounted) {
          setState(() {
            _isNavigating = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: mediaUrl != null
              ? DecorationImage(
                  image: NetworkImage(mediaUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image loading errors silently
                    print('Failed to load reel thumbnail: $mediaUrl');
                  },
                )
              : null,
          color: mediaUrl == null ? theme.cardColor : null,
        ),
        child: mediaUrl == null
            ? Center(
                child: Icon(
                  Icons.video_library,
                  color: theme.iconTheme.color?.withOpacity(0.5),
                ),
              )
            : Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.play_circle_outline,
                      size: 32,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
