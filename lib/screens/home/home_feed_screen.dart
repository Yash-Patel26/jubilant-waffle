import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/safe_scaffold.dart';
import '../../widgets/home/post_card.dart' as post_card_widget;
import '../../widgets/story_circle.dart';
import '../../widgets/post_card_skeleton.dart';
import '../../widgets/home/tournament_card.dart';
import '../../widgets/home/friend_suggestion_card.dart' as friend_card;
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/game/stat.dart';
import 'package:gamer_flick/models/tournament/tournament.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:gamer_flick/models/core/user_with_stories.dart';
import 'package:gamer_flick/models/post/story.dart';
import 'package:gamer_flick/providers/community/community_discovery_provider.dart';
import 'package:gamer_flick/services/tournament/tournament_service.dart';
import '../../utils/responsive_utils.dart';
import '../post/story_viewer_screen.dart';
import '../post/create_story_screen.dart';
import '../community/communities_screen.dart';
import '../event/create_event_screen.dart';
import '../live/go_live_screen.dart';
import '../reels/reels_screen.dart';
// Removed mobile header-related imports
import '../post/create_post_screen.dart';
import '../../utils/post_creator_helper.dart';
import '../../utils/story_creator_helper.dart';
import 'package:gamer_flick/services/media/supabase_upload_service.dart';

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen>
    with TickerProviderStateMixin {
  late Future<List<Post>> _feedFuture;
  late Future<List<UserWithStories>> _storiesFuture;
  RealtimeChannel? _likesChannel;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _tabAnimationController;

  Stat? userStats;
  Profile? userProfile;
  List<Tournament> upcomingTournaments = [];
  List<Profile> suggestedFriends = [];
  bool _isLoadingTournaments = false;

  // Tab state removed
  final int _selectedTabIndex = 0; // kept for future if needed

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  // Search state removed

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _tabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animationController.forward();
    _tabAnimationController.forward();

    _feedFuture = _getCurrentFeed();
    _storiesFuture = _fetchStories();
    _fetchUserData();
    _subscribeToLikes();
  }

  // Debug method to test stories fetching
  Future<void> _testStoriesFetch() async {
    try {
      print('DEBUG: Testing stories fetch...');

      // Test 1: Check if stories table exists and has data
      final allStories =
          await Supabase.instance.client.from('stories').select('*').limit(10);
      print('DEBUG: Total stories in database: ${allStories.length}');

      if (allStories.isNotEmpty) {
        print('DEBUG: First story data: ${allStories.first}');
      }

      // Test 2: Check if profiles table exists and has data
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, username, avatar_url, profile_picture_url')
          .limit(5);
      print('DEBUG: Total profiles in database: ${profiles.length}');

      if (profiles.isNotEmpty) {
        print('DEBUG: First profile data: ${profiles.first}');
      }

      // Test 3: Check current time vs expires_at
      final now = DateTime.now();
      print('DEBUG: Current time: $now');

      final nonExpiredStories = await Supabase.instance.client
          .from('stories')
          .select('*')
          .gt('expires_at', now.toIso8601String());
      print('DEBUG: Non-expired stories: ${nonExpiredStories.length}');
    } catch (e) {
      print('DEBUG: Error testing stories: $e');
    }
  }

  Future<List<Post>> _getCurrentFeed() async {
    switch (_selectedTabIndex) {
      case 0: // Feed
        return _fetchFeed();
      case 1: // Following
        return _fetchFollowingPosts();
      case 2: // Trending
        return _fetchTrendingPosts();
      case 3: // Live
        return []; // Live streams are handled separately
      default:
        return _fetchFeed();
    }
  }

  // Tab change removed

  void _subscribeToLikes() {
    final supabase = Supabase.instance.client;
    _likesChannel = supabase
        .channel('public:post_likes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          callback: (payload) {
            if (mounted) {
              setState(() {
                _feedFuture = _getCurrentFeed();
              });
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _likesChannel?.unsubscribe();
    _searchController.dispose();
    _animationController.dispose();
    _tabAnimationController.dispose();
    super.dispose();
  }

  // Search functionality
  // Search handlers removed with mobile header

  // Search submit removed

  // Search results state
  // Search state (UI not showing results inline currently)
  // Keeping variables removed to satisfy lints.

  // Search function removed

  // Navigation methods
  // Mobile header navigation removed

  // Notifications nav removed

  // Composer (what's on your mind) card - Facebook-style sizing
  Widget _buildComposer() {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    // Approximate Facebook feed column widths
    final double maxWidth = width >= 1200
        ? 680
        : width >= 992
            ? 600
            : width >= 768
                ? 560
                : width - 16; // small screens: full width with slight inset
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1A1A1A),
                const Color(0xFF2A2A2A),
                const Color(0xFF1A1A1A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF6366F1).withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.15),
                blurRadius: 6,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title bar (profile + what's on your mind) - Facebook compact style
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 16, // More compact profile picture like Facebook
                      backgroundColor: const Color(0xFF1A1A1A),
                      backgroundImage: userProfile?.profilePictureUrl != null
                          ? NetworkImage(userProfile!.profilePictureUrl!)
                          : null,
                      child: userProfile?.profilePictureUrl == null
                          ? Text(
                              userProfile?.displayName.isNotEmpty == true
                                  ? userProfile!.displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 32, // More compact height like Facebook
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF2A2A2A),
                            const Color(0xFF1A1A1A),
                            const Color(0xFF2A2A2A),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6366F1).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        "What's on your mind, gamer?",
                        style: TextStyle(
                          color: const Color(0xFF6366F1).withOpacity(0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8), // More compact spacing
              // Action buttons row - Only 3 options: Create Story, Upload Post, Live
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _composerButton(
                      theme,
                      Icons.emoji_emotions_rounded,
                      'Feeling/Activity',
                      const Color(0xFFEF4444),
                      const Color(0xFFF87171),
                      () => _navigateToCamera()),
                  _composerButton(
                      theme,
                      Icons.photo_rounded,
                      'Photo/Video',
                      const Color(0xFF10B981),
                      const Color(0xFF34D399),
                      () => _navigateToCreatePostFromFeed()),
                  _composerButton(
                      theme,
                      Icons.video_camera_back_rounded,
                      'Live',
                      const Color(0xFFF59E0B),
                      const Color(0xFFFBBF24),
                      () => _navigateToLiveStream()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composerButton(ThemeData theme, IconData icon, String label,
      Color primaryColor, Color secondaryColor, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      constraints: const BoxConstraints(
          minWidth: 84, maxWidth: 100), // More compact like Facebook
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
                vertical: 8, horizontal: 8), // More reduced padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A).withOpacity(0.2),
                  const Color(0xFF2A2A2A).withOpacity(0.2),
                  const Color(0xFF1A1A1A).withOpacity(0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: primaryColor.withOpacity(0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.12),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14, // More compact icon like Facebook
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11, // More compact font like Facebook
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCreatePostFromFeed() async {
    try {
      // Show Facebook-style post creator modal
      PostCreatorHelper.showPostCreator(
        context,
        onPostCreated: (postData) async {
          // Handle the created post data
          if (postData['text'].isNotEmpty || postData['media'].isNotEmpty) {
            // Create the post using the existing post service
            await _createPostFromData(postData);
            // Refresh the posts feed
            _refreshPosts();
          }
        },
        onClose: () {
          // Handle modal close if needed
        },
      );
    } catch (_) {}
  }

  Future<void> _createPostFromData(Map<String, dynamic> postData) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Create post data structure
      final post = {
        'user_id': user.id,
        'content': postData['text'] ?? '',
        'media_urls': [], // Will be populated if media is uploaded
        'is_public': postData['privacy'] == 'Public',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Insert post into database
      final result = await Supabase.instance.client
          .from('posts')
          .insert(post)
          .select('id')
          .single();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<List<Post>> _fetchFeed() async {
    try {
      // Fetch posts with user data
      final response = await Supabase.instance.client
          .from('posts')
          .select(
              '*, profiles!posts_user_id_fkey(id, username, avatar_url, profile_picture_url)')
          .order('created_at', ascending: false)
          .limit(20);

      final posts = (response as List).map((data) {
        try {
          return Post.fromJson(data);
        } catch (e) {
          rethrow;
        }
      }).toList();

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<List<Post>> _fetchFollowingPosts() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return [];

      // Get users that the current user is following
      final followingResponse = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', currentUser.id);

      if (followingResponse.isEmpty) return [];

      final followingIds = (followingResponse as List)
          .map((f) => f['following_id'] as String)
          .toList();

      // Fetch posts from followed users
      final response = await Supabase.instance.client
          .from('posts')
          .select(
              '*, profiles!posts_user_id_fkey(id, username, avatar_url, profile_picture_url)')
          .inFilter('user_id', followingIds)
          .order('created_at', ascending: false)
          .limit(20);

      final posts = (response as List).map((data) {
        try {
          return Post.fromJson(data);
        } catch (e) {
          rethrow;
        }
      }).toList();

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<List<Post>> _fetchTrendingPosts() async {
    try {
      // Fetch posts with high engagement (likes, comments, shares)
      final response = await Supabase.instance.client
          .from('posts')
          .select(
              '*, profiles!posts_user_id_fkey(id, username, avatar_url, profile_picture_url)')
          .gte('like_count', 5) // Posts with at least 5 likes
          .order('like_count', ascending: false)
          .order('created_at', ascending: false)
          .limit(20);

      final posts = (response as List).map((data) {
        try {
          return Post.fromJson(data);
        } catch (e) {
          rethrow;
        }
      }).toList();

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchLiveStreams() async {
    try {
      // Fetch live streams
      final response = await Supabase.instance.client
          .from('live_streams')
          .select(
              '*, profiles!live_streams_streamer_id_fkey(id, username, avatar_url, profile_picture_url)')
          .eq('is_live', true)
          .order('viewer_count', ascending: false)
          .limit(20);

      return (response as List)
          .map((data) => Map<String, dynamic>.from(data))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Unused in current UI; keep for future use but ignore for lints
  // ignore: unused_element
  Future<List<Map<String, dynamic>>> _fetchCommunityPosts() async {
    // This can be refactored later if a CommunityPost model is fully integrated
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return [];

      // Get communities where user is a member using the community_members table
      final communitiesResponse = await Supabase.instance.client
          .from('community_members')
          .select('community_id')
          .eq('user_id', user.id)
          .eq('is_banned', false);

      if (communitiesResponse.isEmpty) return [];
      final communityIds = (communitiesResponse as List)
          .map((c) => c['community_id'] as String)
          .toList();

      final communityPostsResponse = await Supabase.instance.client
          .from('community_posts')
          .select(
              '*, communities!community_posts_community_id_fkey(id, name, image_url), profiles!community_posts_author_id_fkey(*)')
          .inFilter('community_id', communityIds)
          .order('created_at', ascending: false)
          .limit(10);
      return (communityPostsResponse as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<UserWithStories>> _fetchStories() async {
    try {
      final response = await Supabase.instance.client
          .from('stories')
          .select('''
            *,
            profiles!stories_user_id_fkey(
              id,
              username,
              email,
              avatar_url,
              profile_picture_url,
              full_name,
              bio,
              created_at,
              updated_at,
              is_verified,
              status,
              last_active,
              level,
              game_stats
            )
          ''')
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        return [];
      }

      final Map<String, List<Story>> userStoriesMap = {};
      final Map<String, Profile> userProfileMap = {};

      for (var storyData in response) {
        final story = Story.fromJson(storyData);
        final profileData = storyData['profiles'];
        if (profileData != null) {
          final profileMap = Map<String, dynamic>.from(profileData);
          String? avatarUrl =
              profileMap['avatar_url'] ?? profileMap['profile_picture_url'];

          if (avatarUrl != null &&
              avatarUrl.isNotEmpty &&
              !avatarUrl.startsWith('http')) {
            try {
              avatarUrl = Supabase.instance.client.storage
                  .from('avatars')
                  .getPublicUrl(avatarUrl);
            } catch (e) {
              avatarUrl = null;
            }
          }

          final profile = Profile(
            id: profileMap['id'] as String,
            username: profileMap['username'] as String? ?? '',
            email: profileMap['email'] as String? ?? '',
            profilePictureUrl: profileMap['profile_picture_url'] as String?,
            avatarUrl: avatarUrl,
            preferredGame: profileMap['preferred_game'] as String?,
            gamingId: profileMap['gaming_id'] as String?,
            fullName: profileMap['full_name'] as String?,
            bio: profileMap['bio'] as String?,
            createdAt: profileMap['created_at'] != null
                ? DateTime.parse(profileMap['created_at'] as String)
                : null,
            updatedAt: profileMap['updated_at'] != null
                ? DateTime.parse(profileMap['updated_at'] as String)
                : null,
            isVerified: profileMap['is_verified'] as bool? ?? false,
            status: profileMap['status'] as String? ?? 'offline',
            lastActive: profileMap['last_active'] != null
                ? DateTime.parse(profileMap['last_active'] as String)
                : null,
            level: profileMap['level'] as int? ?? 1,
            gameStats: profileMap['game_stats'] as Map<String, dynamic>? ?? {},
          );

          userProfileMap.putIfAbsent(profile.id, () => profile);
          if (userStoriesMap.containsKey(profile.id)) {
            userStoriesMap[profile.id]!.add(story);
          } else {
            userStoriesMap[profile.id] = [story];
          }
        }
      }

      final result = userProfileMap.entries.map((entry) {
        return UserWithStories(
          user: entry.value,
          stories: userStoriesMap[entry.key]!,
        );
      }).toList();

      return result;
    } catch (e) {
      return [];
    }
  }

  // Unused in current UI; keep for future use but ignore for lints
  // ignore: unused_element
  Future<List<Community>> _fetchTrendingCommunities() async {
    try {
      final communities = await ref.read(trendingCommunitiesProvider.future);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // Get user's community memberships
        final userMemberships = await Supabase.instance.client
            .from('community_members')
            .select('community_id')
            .eq('user_id', user.id);

        final userCommunityIds = (userMemberships as List)
            .map((m) => m['community_id'] as String)
            .toSet();

        // Filter out communities where user is already a member
        return communities
            .where((c) => !userCommunityIds.contains(c.id))
            .toList();
      }
      return communities;
    } catch (e) {
      return [];
    }
  }

  Future<void> _fetchUserData() async {
    await _fetchUserStats();
    await _fetchUpcomingTournaments();
    await _fetchSuggestedFriends();
  }

  Future<void> _refresh() async {
    setState(() {
      _isLoadingTournaments = true;
    });

    await Future.wait([
      _refreshFeedData(),
      _refreshStoriesData(),
      _refreshUserData(),
      _refreshTournamentsData(),
      _refreshFriendsData(),
      _refreshPosts(), // Add posts refresh
    ]);

    setState(() {
      _isLoadingTournaments = false;
    });
  }

  Future<void> _refreshFeedData() async {
    setState(() {
      _feedFuture = _getCurrentFeed();
    });
    await _feedFuture; // Wait for the future to complete
  }

  Future<void> _refreshStoriesData() async {
    setState(() {
      _storiesFuture = _fetchStories();
    });
    await _storiesFuture; // Wait for the future to complete
  }

  Future<void> _refreshUserData() async {
    await _fetchUserData();
  }

  Future<void> _refreshTournamentsData() async {
    await _fetchUpcomingTournaments();
  }

  Future<void> _refreshFriendsData() async {
    await _fetchSuggestedFriends();
  }

  Future<void> _refreshPosts() async {
    setState(() {
      _feedFuture = _getCurrentFeed();
    });
    await _feedFuture; // Wait for the future to complete
  }

  Future<void> _fetchUserStats() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // First try to get the profile from the profiles table
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      // If profile exists, use it
      final profile = Profile.fromJson(profileResponse);

      // Calculate stats from existing data instead of using a non-existent stats table
      try {
        // Get post count
        final postsResponse = await Supabase.instance.client
            .from('posts')
            .select('id')
            .eq('user_id', user.id);

        // Get followers count
        final followersResponse = await Supabase.instance.client
            .from('follows')
            .select('id')
            .eq('following_id', user.id);

        // Get following count
        final followingResponse = await Supabase.instance.client
            .from('follows')
            .select('id')
            .eq('follower_id', user.id);

        // Get total likes received by counting likes on user's posts
        final userPostsResponse = await Supabase.instance.client
            .from('posts')
            .select('id')
            .eq('user_id', user.id);

        int totalLikes = 0;
        if ((userPostsResponse as List).isNotEmpty) {
          final postIds = (userPostsResponse as List)
              .map((p) => p['id'] as String)
              .toList();
          final likesResponse = await Supabase.instance.client
              .from('post_likes')
              .select('id')
              .inFilter('post_id', postIds);
          totalLikes = (likesResponse as List).length;
        }

        if (mounted) {
          setState(() {
            userProfile = profile;
            userStats = Stat(
              id: 'calculated',
              userId: user.id,
              postsCount: (postsResponse as List).length,
              followersCount: (followersResponse as List).length,
              followingCount: (followingResponse as List).length,
              totalLikes: totalLikes,
              tournamentsPlayed:
                  0, // Can be calculated from tournament_participants if needed
              tournamentsWon: 0,
              totalKills: 0,
              kdRatio: 0.0,
            );
          });
        }
      } catch (statsError) {
        // If stats calculation fails, create default stats but keep the real profile

        if (mounted) {
          setState(() {
            userProfile = profile;
            userStats = Stat(
              id: 'default',
              userId: user.id,
              postsCount: 0,
              followersCount: 0,
              followingCount: 0,
              totalLikes: 0,
              tournamentsPlayed: 0,
              tournamentsWon: 0,
              totalKills: 0,
              kdRatio: 0.0,
            );
          });
        }
      }
    } catch (e) {
      // If there's still an error, try to get at least the auth user data
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && mounted) {
        setState(() {
          userProfile = Profile(
            id: user.id,
            username: user.userMetadata?['username'] ??
                user.email?.split('@')[0] ??
                'User',
            email: user.email ?? '',
            avatarUrl: user.userMetadata?['avatar_url'],
            profilePictureUrl: user.userMetadata?['avatar_url'],
            createdAt: DateTime.parse(user.createdAt),
            updatedAt: user.lastSignInAt != null
                ? DateTime.parse(user.lastSignInAt!)
                : DateTime.now(),
          );
          userStats = Stat(
            id: 'default',
            userId: user.id,
            tournamentsPlayed: 0,
            tournamentsWon: 0,
            totalKills: 0,
            kdRatio: 0.0,
          );
        });
      }
    }
  }

  Future<void> _fetchUpcomingTournaments() async {
    if (mounted) {
      setState(() {
        _isLoadingTournaments = true;
      });
    }

    try {
      final tournamentService = TournamentService();
      final tournamentsData =
          await tournamentService.getUpcomingTournaments(limit: 5);

      if (mounted) {
        setState(() {
          upcomingTournaments =
              tournamentsData.map((data) => Tournament.fromJson(data)).toList();
          _isLoadingTournaments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingTournaments = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Failed to fetch upcoming tournaments: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchSuggestedFriends() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // First, get the list of users that the current user is already following
      final followingResponse = await Supabase.instance.client
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id);

      final followingIds = (followingResponse as List)
          .map((follow) => follow['following_id'] as String)
          .toList();

      // Add the current user's ID to the exclusion list
      final excludeIds = [...followingIds, user.id];

      // Fetch suggested friends, excluding already followed users
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .not('id', 'in', excludeIds)
          .limit(5);

      if (mounted) {
        setState(() {
          suggestedFriends =
              (response as List).map((data) => Profile.fromJson(data)).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch suggested friends: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleFollowUser(String userId) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;
      await Supabase.instance.client.from('follows').insert({
        'follower_id': currentUser.id,
        'following_id': userId,
      });
      if (mounted) {
        setState(() {
          suggestedFriends.removeWhere((friend) => friend.id == userId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User followed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to follow user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = ResponsiveUtils.isMobile(context);

    return SafeScaffold(
      body: isMobile ? _buildMobileLayout(theme) : _buildDesktopLayout(theme),
    );
  }

  Widget _buildMobileLayout(ThemeData theme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isVerySmallScreen = screenWidth < 320;
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

    return Column(
      children: [
        // Top Header Bar (removed; header handled by HomeScreen)
        const SizedBox.shrink(),

        // Stories/Quick Access Section
        _buildMobileStories(screenWidth, isVerySmallScreen, isSmallScreen),

        // Post Composer Section
        _buildMobileComposer(screenWidth, isVerySmallScreen, isSmallScreen),

        // Main Feed Content Area
        Expanded(
          child: RefreshIndicator(
            color: const Color(0xFF6366F1),
            backgroundColor: const Color(0xFF1A1A1A),
            strokeWidth: 3,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                  horizontal: isVerySmallScreen
                      ? 2
                      : isSmallScreen
                          ? 4
                          : 8),
              child: Column(
                children: [
                  SizedBox(
                      height: isVerySmallScreen
                          ? 2
                          : isSmallScreen
                              ? 4
                              : 8),
                  _buildMobileFeedContent(),
                  SizedBox(
                      height: isVerySmallScreen
                          ? 12
                          : isSmallScreen
                              ? 16
                              : 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileHeader(
      double screenWidth, bool isVerySmallScreen, bool isSmallScreen) {
    final horizontalPadding = isVerySmallScreen
        ? 4.0
        : isSmallScreen
            ? 6.0
            : 12.0;
    final logoSize = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 24.0
            : 28.0;
    final fontSize = isVerySmallScreen
        ? 12.0
        : isSmallScreen
            ? 14.0
            : 16.0;
    final iconSize = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 18.0
            : 20.0;
    final headerHeight = isVerySmallScreen
        ? 44.0
        : isSmallScreen
            ? 50.0
            : 60.0;
    final iconSpacing = isVerySmallScreen
        ? 2.0
        : isSmallScreen
            ? 4.0
            : 6.0;

    return Container(
      height: headerHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
      ),
      child: Row(
        children: [
          // Left Side - App Branding
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular icon with gradient
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(logoSize / 2),
                  ),
                  child: Icon(
                    Icons.sports_esports_rounded,
                    color: Colors.white,
                    size: logoSize * 0.6,
                  ),
                ),
                SizedBox(width: iconSpacing),
                // GamerFlick text
                Flexible(
                  child: Text(
                    'GamerFlick',
                    style: TextStyle(
                      color: const Color(0xFFCCCCCC),
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Right Side - Utility Icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.search,
                    color: const Color(0xFFCCCCCC), size: iconSize),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                    minWidth: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32,
                    minHeight: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.notifications_outlined,
                    color: const Color(0xFFCCCCCC), size: iconSize),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                    minWidth: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32,
                    minHeight: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32),
              ),
              IconButton(
                onPressed: () {},
                icon: Icon(Icons.chat_bubble_outline,
                    color: const Color(0xFFCCCCCC), size: iconSize),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                    minWidth: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32,
                    minHeight: isVerySmallScreen
                        ? 24
                        : isSmallScreen
                            ? 28
                            : 32),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileStories(
      double screenWidth, bool isVerySmallScreen, bool isSmallScreen) {
    // Align stories with the composer card: use same outer margin as composer
    // Composer margin is 2/4/6 → match it for the stories left padding
    final leftPadding = isVerySmallScreen
        ? 2.0
        : isSmallScreen
            ? 4.0
            : 6.0;
    final storySize = isVerySmallScreen
        ? 36.0
        : isSmallScreen
            ? 44.0
            : 48.0;
    final margin = isVerySmallScreen
        ? 2.0
        : isSmallScreen
            ? 3.0
            : 4.0;
    final containerHeight = isVerySmallScreen
        ? 60.0
        : isSmallScreen
            ? 70.0
            : 80.0;
    final verticalPadding = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 10.0
            : 12.0;

    return Container(
      height: containerHeight,
      padding: EdgeInsets.only(
        top: verticalPadding,
        bottom: verticalPadding,
        left: leftPadding,
        right: leftPadding,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _StoryBackgroundPainter(),
            ),
          ),

          // Floating particles effect
          Positioned.fill(
            child: _FloatingParticles(),
          ),

          // Stories content
          FutureBuilder<List<UserWithStories>>(
            future: _storiesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.only(left: leftPadding, right: leftPadding),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(right: margin),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: storySize,
                            height: storySize,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade800,
                                  Colors.grey.shade600,
                                  Colors.grey.shade800,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                // Show a list with the "Your story" tile so user can create even when empty
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      EdgeInsets.only(left: leftPadding, right: leftPadding),
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: margin + 8),
                      child: _buildYourStoryItem(
                          storySize: storySize, showLabel: false),
                    ),
                    // Optional compact hint pill
                    Builder(builder: (_) {
                      final double maxEmptyHeight =
                          containerHeight - (verticalPadding * 2);
                      final double pillHeight =
                          maxEmptyHeight.clamp(20.0, 28.0);
                      return ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: pillHeight),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.auto_awesome,
                                  color: Color(0xFF6366F1), size: 12),
                              SizedBox(width: 6),
                              Text(
                                'No stories yet – be first!',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }

              final usersWithStories = snapshot.data!;
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.only(left: leftPadding, right: leftPadding),
                itemCount: usersWithStories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Container(
                      margin: EdgeInsets.only(right: margin + 8),
                      child: _buildYourStoryItem(storySize: storySize),
                    );
                  }
                  final userWithStories = usersWithStories[index - 1];
                  return Container(
                    margin:
                        EdgeInsets.only(right: margin + 8), // Increased spacing
                    child: Column(
                      children: [
                        StoryCircle(
                          userWithStories: userWithStories,
                          size: storySize,
                          isLive: index == 1, // First real story marked live
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => StoryViewerScreen(
                                usersWithStories: usersWithStories,
                                initialUserIndex: index - 1,
                              ),
                            ));
                          },
                        ),
                        const SizedBox(height: 6),
                        // Username with gradient text
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              Color(0xFF6366F1),
                              Color(0xFF22D3EE),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ).createShader(bounds),
                          child: Text(
                            userWithStories.user.username.length > 10
                                ? '${userWithStories.user.username.substring(0, 10)}...'
                                : userWithStories.user.username,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileComposer(
      double screenWidth, bool isVerySmallScreen, bool isSmallScreen) {
    final margin = isVerySmallScreen
        ? 2.0
        : isSmallScreen
            ? 4.0
            : 6.0;
    final padding = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 10.0;
    final avatarSize = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 24.0
            : 28.0;
    final inputHeight = isVerySmallScreen
        ? 20.0
        : isSmallScreen
            ? 24.0
            : 28.0;
    final buttonHeight = isVerySmallScreen
        ? 16.0
        : isSmallScreen
            ? 20.0
            : 24.0;
    final fontSize = isVerySmallScreen
        ? 8.0
        : isSmallScreen
            ? 10.0
            : 11.0;
    final buttonFontSize = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 9.0;
    final iconSize = isVerySmallScreen
        ? 10.0
        : isSmallScreen
            ? 12.0
            : 14.0;
    final buttonIconSize = isVerySmallScreen
        ? 6.0
        : isSmallScreen
            ? 8.0
            : 10.0;
    final spacing = isVerySmallScreen
        ? 3.0
        : isSmallScreen
            ? 4.0
            : 6.0;
    final buttonSpacing = isVerySmallScreen
        ? 1.0
        : isSmallScreen
            ? 2.0
            : 3.0;

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Row
          Row(
            children: [
              // Avatar
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.white,
                  size: avatarSize * 0.6,
                ),
              ),
              SizedBox(width: spacing),
              // Input field
              Expanded(
                child: Container(
                  height: inputHeight,
                  padding: EdgeInsets.symmetric(
                      horizontal: isVerySmallScreen
                          ? 6
                          : isSmallScreen
                              ? 8
                              : 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(inputHeight / 2),
                  ),
                  child: Center(
                    child: Text(
                      "whats on your mind",
                      style: TextStyle(
                        color: const Color(0xFF888888),
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing),
              // Attachment icon
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(avatarSize / 2),
                  border: Border.all(
                    color: const Color(0xFF6366F1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.attach_file,
                  color: const Color(0xFF6366F1),
                  size: iconSize,
                ),
              ),
            ],
          ),
          SizedBox(
              height: isVerySmallScreen
                  ? 6
                  : isSmallScreen
                      ? 8
                      : 10),
          // Bottom Row - Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildMobileActionButton(
                  'cam',
                  Icons.camera_alt,
                  buttonHeight,
                  buttonFontSize,
                  buttonIconSize,
                  () => _navigateToCamera(),
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: _buildMobileActionButton(
                  'Community',
                  Icons.group,
                  buttonHeight,
                  buttonFontSize,
                  buttonIconSize,
                  () => _navigateToCommunity(),
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: _buildMobileActionButton(
                  'Event',
                  Icons.event,
                  buttonHeight,
                  buttonFontSize,
                  buttonIconSize,
                  () => _navigateToEvents(),
                ),
              ),
              SizedBox(width: buttonSpacing),
              Expanded(
                child: _buildMobileActionButton(
                  'Live',
                  Icons.live_tv,
                  buttonHeight,
                  buttonFontSize,
                  buttonIconSize,
                  () => _navigateToLiveStream(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileActionButton(String label, IconData icon, double height,
      double fontSize, double iconSize, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.transparent,
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                  SizedBox(width: fontSize * 0.2),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Navigation methods for action buttons
  void _navigateToCamera() async {
    print('Opening Facebook-style Story Creator');
    // Show Facebook-style story creator modal
    StoryCreatorHelper.showStoryCreator(
      context,
      onStoryCreated: (storyData) async {
        // Handle the created story data
        if (storyData['media'].isNotEmpty || storyData['text'].isNotEmpty) {
          // Create the story using the existing story service
          await _createStoryFromData(storyData);
          // Refresh the stories feed
          _refreshStories();
        }
      },
      onClose: () {
        // Handle modal close if needed
      },
    );
  }

  Future<void> _createStoryFromData(Map<String, dynamic> storyData) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      String mediaUrl = '';

      // Upload media if present
      if (storyData['media'].isNotEmpty) {
        try {
          // Use the existing SupabaseUploadService for consistent upload handling
          mediaUrl = await SupabaseUploadService.uploadFile(
            file: storyData['media'].first,
            userId: user.id,
            contentType: 'stories',
          );
        } catch (uploadError) {
          print('Media upload failed: $uploadError');
          // Continue with text-only story if upload fails
        }
      }

      // Create story data structure
      final story = {
        'user_id': user.id,
        'content': storyData['text'] ?? '',
        'media_url': mediaUrl,
        'media_type': storyData['type'] == 'Video' ? 'video' : 'image',
        'duration': 5,
        'created_at': DateTime.now().toIso8601String(),
        'expires_at':
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      };

      // Insert story into database
      final result = await Supabase.instance.client
          .from('stories')
          .insert(story)
          .select('id')
          .single();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Story created successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create story: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _navigateToCommunity() {
    print('Navigating to Community Screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CommunitiesScreen(),
      ),
    );
  }

  void _navigateToEvents() {
    print('Navigating to Events Screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CreateEventScreen(),
      ),
    );
  }

  void _navigateToLiveStream() {
    print('Navigating to Live Stream Screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const GoLiveScreen(),
      ),
    );
  }

  void _navigateToReels() {
    print('Navigating to Reels Screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReelsScreen(),
      ),
    );
  }

  Widget _buildMobileFeedContent() {
    // Handle Live tab separately
    if (_selectedTabIndex == 3) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLiveStreams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) => const PostCardSkeleton());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}')));
          }
          final liveStreams = snapshot.data;

          if (liveStreams == null || liveStreams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.live_tv, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("No live streams at the moment. Check back later!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liveStreams.length,
            itemBuilder: (context, index) {
              final stream = liveStreams[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildLiveStreamCard(stream),
              );
            },
          );
        },
      );
    }

    // Handle other tabs (Feed, Following, Trending)
    return FutureBuilder<List<Post>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => const PostCardSkeleton());
        }
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}')));
        }
        final posts = snapshot.data;

        if (posts == null || posts.isEmpty) {
          String emptyMessage =
              "Your feed is empty. Follow some users to see their posts!";
          if (_selectedTabIndex == 1) {
            emptyMessage =
                "You're not following anyone yet. Follow some users to see their posts!";
          } else if (_selectedTabIndex == 2) {
            emptyMessage = "No trending posts at the moment. Check back later!";
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(emptyMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: post_card_widget.PostCard(post: posts[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopLayout(ThemeData theme) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Main Content Area
              Expanded(
                flex: ResponsiveUtils.isTablet(context) ? 2 : 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildComposer(),
                    SizedBox(
                        height:
                            ResponsiveUtils.responsiveSpacing(context) / 10),
                    Expanded(
                      child: RefreshIndicator(
                        color: const Color(0xFF6366F1),
                        backgroundColor: const Color(0xFF1A1A1A),
                        strokeWidth: 3,
                        onRefresh: _refresh,
                        child: SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 720),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Story chips row
                                  if (!ResponsiveUtils.isMobile(context))
                                    _buildStories(),
                                  SizedBox(
                                      height: ResponsiveUtils.responsiveSpacing(
                                              context) /
                                          12),
                                  // Tabs removed
                                  _buildFeedContent(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Right Sidebar
              if (!ResponsiveUtils.isMobile(context))
                Container(
                  width: ResponsiveUtils.isTablet(context) ? 220 : 280,
                  color: theme.colorScheme.surface,
                  child: _buildRightSidebar(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Top header removed for desktop layout; mobile header remains in use.

  // Mobile header removed

  // Category color helper removed

  // Stats cards removed

  // Tabs removed

  Widget _buildStories() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Stack(
        children: [
          // Animated background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _StoryBackgroundPainter(),
            ),
          ),

          // Floating particles effect
          Positioned.fill(
            child: _FloatingParticles(),
          ),

          // Main content
          Column(
            children: [
              const SizedBox(height: 16),
              // Enhanced story section header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF22D3EE),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [],
                      ),
                    ),
                    const Spacer(),
                    // Add story button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 100),
                  child: SizedBox(
                    height: 100,
                    child: RefreshIndicator(
                      onRefresh: () async {
                        _refreshStories();
                      },
                      child: FutureBuilder<List<UserWithStories>>(
                        future: _storiesFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildStoriesSkeleton();
                          } else if (snapshot.hasError ||
                              !snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return _buildEmptyStories();
                          }

                          final usersWithStories = snapshot.data!;
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: usersWithStories.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  child: _buildYourStoryItem(storySize: 72),
                                );
                              }
                              final userWithStories =
                                  usersWithStories[index - 1];
                              return Container(
                                margin: const EdgeInsets.only(right: 16),
                                child: Column(
                                  children: [
                                    StoryCircle(
                                      userWithStories: userWithStories,
                                      size: 72,
                                      isLive:
                                          index == 1, // first real story live
                                      onTap: () {
                                        Navigator.of(context)
                                            .push(MaterialPageRoute(
                                          builder: (context) =>
                                              StoryViewerScreen(
                                                  usersWithStories:
                                                      usersWithStories,
                                                  initialUserIndex: index - 1),
                                        ));
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    // Username with gradient text
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Color(0xFF6366F1),
                                          Color(0xFF22D3EE),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ).createShader(bounds),
                                      child: Text(
                                        userWithStories.user.username.length >
                                                12
                                            ? '${userWithStories.user.username.substring(0, 12)}...'
                                            : userWithStories.user.username,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoriesSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      itemBuilder: (context, index) => Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            // Animated skeleton circle
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1500),
              builder: (context, value, child) {
                return Container(
                  height: 72,
                  width: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.grey.shade800,
                        Colors.grey.shade600,
                        Colors.grey.shade800,
                      ],
                      stops: [0.0, value, 1.0],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStories() {
    return SizedBox(
      height: 100, // Fixed height to match stories section
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: const Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Stories Yet',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Be the first to share!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF22D3EE),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateStoryScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Create',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent() {
    // Handle Live tab separately
    if (_selectedTabIndex == 3) {
      return FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchLiveStreams(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                itemBuilder: (context, index) => const PostCardSkeleton());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: ${snapshot.error}')));
          }
          final liveStreams = snapshot.data;

          if (liveStreams == null || liveStreams.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.live_tv, size: 48, color: Colors.grey),
                    SizedBox(height: 12),
                    Text("No live streams at the moment. Check back later!",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: liveStreams.length,
            itemBuilder: (context, index) {
              final stream = liveStreams[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: _buildLiveStreamCard(stream),
              );
            },
          );
        },
      );
    }

    // Handle other tabs (Feed, Following, Trending)
    return FutureBuilder<List<Post>>(
      future: _feedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 5,
              itemBuilder: (context, index) => const PostCardSkeleton());
        }
        if (snapshot.hasError) {
          return Center(
              child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Error: ${snapshot.error}')));
        }
        final posts = snapshot.data;

        if (posts == null || posts.isEmpty) {
          String emptyMessage =
              "Your feed is empty. Follow some users to see their posts!";
          if (_selectedTabIndex == 1) {
            emptyMessage =
                "You're not following anyone yet. Follow some users to see their posts!";
          } else if (_selectedTabIndex == 2) {
            emptyMessage = "No trending posts at the moment. Check back later!";
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(emptyMessage,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: post_card_widget.PostCard(post: posts[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildRightSidebar() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upcoming Tournaments Section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFFEF4444).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEF4444),
                        Color(0xFFDC2626),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Tournaments',
                        style: TextStyle(
                          color: const Color(0xFFEF4444),
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Join the competition!',
                        style: TextStyle(
                          color: const Color(0xFFEF4444).withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFF59E0B),
                        Color(0xFFEF4444),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'HOT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (_isLoadingTournaments)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(
                  color: const Color(0xFFEF4444),
                  strokeWidth: 3,
                ),
              ),
            )
          else if (upcomingTournaments.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...upcomingTournaments.map((tournament) => TournamentCard(
                        tournament: tournament,
                        onTap: () => _handleTournamentTap(tournament),
                      )),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0A0A0A),
                    Color(0xFF1A1A1A),
                    Color(0xFF0F0F0F),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFEF4444).withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFEF4444),
                          Color(0xFFDC2626),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withOpacity(0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 56,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No upcoming tournaments',
                    style: TextStyle(
                      color: const Color(0xFFEF4444).withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check back later for new tournaments',
                    style: TextStyle(
                      color: const Color(0xFFEF4444).withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),

          // Suggested Friends Section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A),
                  const Color(0xFF2A2A2A),
                  const Color(0xFF1A1A1A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.people_rounded,
                    color: const Color(0xFF10B981),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Suggested Friends',
                        style: TextStyle(
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                          fontSize: 17,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Connect with gamers!',
                        style: TextStyle(
                          color: const Color(0xFF10B981).withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'NEW',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (suggestedFriends.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ...suggestedFriends
                      .map((friend) => friend_card.FriendSuggestionCard(
                            profile: friend,
                            onFollow: () => _handleFollowUser(friend.id),
                          )),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1A1A1A),
                    const Color(0xFF2A2A2A),
                    const Color(0xFF1A1A1A),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      size: 48,
                      color: const Color(0xFF10B981).withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No friend suggestions',
                    style: TextStyle(
                      color: const Color(0xFF10B981).withOpacity(0.8),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'More gamers will appear here soon!',
                    style: TextStyle(
                      color: const Color(0xFF10B981).withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.secondary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  void _handleTournamentTap(Tournament tournament) {
    Navigator.pushNamed(context, '/tournament-details', arguments: tournament);
  }

  Widget _buildLiveStreamCard(Map<String, dynamic> stream) {
    final theme = Theme.of(context);
    final streamer = stream['profiles'] as Map<String, dynamic>?;
    final streamerName = streamer?['username'] ?? 'Unknown';
    final streamTitle = stream['title'] ?? 'Untitled Stream';
    final viewerCount = stream['viewer_count'] ?? 0;
    // final thumbnailUrl = stream['thumbnail_url'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: streamer?['avatar_url'] != null
              ? NetworkImage(streamer!['avatar_url'])
              : null,
          child: streamer?['avatar_url'] == null
              ? Text(streamerName[0].toUpperCase())
              : null,
        ),
        title: Text(
          streamTitle,
          style: TextStyle(
              color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '$streamerName • $viewerCount viewers',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/live-viewer',
            arguments: {'stream': stream},
          );
        },
      ),
    );
  }

  String _formatTournamentStartDate(DateTime startDate) {
    final now = DateTime.now();
    final difference = startDate.difference(now);

    if (difference.inDays > 0) {
      return 'Starts in ${difference.inDays} day${difference.inDays == 1 ? '' : 's'}';
    } else if (difference.inHours > 0) {
      return 'Starts in ${difference.inHours} hour${difference.inHours == 1 ? '' : 's'}';
    } else if (difference.inMinutes > 0) {
      return 'Starts in ${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'}';
    } else {
      return 'Starting now';
    }
  }

  /// Refreshes the stories feed efficiently
  void _refreshStories() {
    setState(() {
      _storiesFuture = _fetchStories();
    });
  }

  // Reusable "Your story" circle (Instagram-style)
  Widget _buildYourStoryItem(
      {required double storySize, bool showLabel = true}) {
    final String? avatar =
        userProfile?.profilePictureUrl ?? userProfile?.avatarUrl;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CreateStoryScreen(),
              ),
            );
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: storySize,
                height: storySize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.25),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: avatar != null && avatar.isNotEmpty
                      ? Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFF1F1F1F),
                            child:
                                const Icon(Icons.person, color: Colors.white70),
                          ),
                        )
                      : Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child:
                              const Icon(Icons.person, color: Colors.white70),
                        ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: storySize * 0.32,
                  height: storySize * 0.32,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                    ),
                    child: const Icon(Icons.add, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(height: 6),
          const Text(
            'Your story',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

// Custom painter for story background pattern
class _StoryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw subtle grid pattern
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    // Draw subtle circular patterns
    final circlePaint = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      60,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      80,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Floating particles widget
class _FloatingParticles extends StatefulWidget {
  @override
  State<_FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<_FloatingParticles>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlesPainter(_animation.value),
        );
      },
    );
  }
}

class _ParticlesPainter extends CustomPainter {
  final double animationValue;

  _ParticlesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 8; i++) {
      final x = (size.width * 0.1) + (size.width * 0.8 * (i / 8.0));
      final y = (size.height * 0.2) +
          (size.height * 0.6 * ((i / 8.0 + animationValue) % 1.0));

      canvas.drawCircle(
        Offset(x, y),
        2 + (i % 3),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
