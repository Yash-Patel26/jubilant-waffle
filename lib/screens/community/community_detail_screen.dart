import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:gamer_flick/providers/community/community_notifier.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gamer_flick/repositories/storage/storage_repository.dart' as storage_repo;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/core/user.dart' as app_models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'community_post_comments_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:gamer_flick/models/community/community_member.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
import 'package:gamer_flick/models/core/profile.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gamer_flick/models/community/community_invite.dart';
import 'community_roles_screen.dart';
import 'community_settings_screen.dart';
import '../post/media_gallery_screen.dart';
import 'package:gamer_flick/services/post/post_service.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gamer_flick/services/notification/enhanced_notification_service.dart';
import 'package:gamer_flick/models/notification/notification_model.dart';
import 'package:gamer_flick/services/community/community_chat_service.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:gamer_flick/models/community/community_chat_message.dart';
import 'package:gamer_flick/providers/user/user_notifier.dart' hide userRepositoryProvider;
import 'package:gamer_flick/repositories/user/user_repository.dart' as user_repo;
import 'package:gamer_flick/models/community/community_post.dart';
import 'package:gamer_flick/providers/community/community_post_notifier.dart';
import 'package:gamer_flick/providers/notification/notification_notifier.dart';
import 'package:gamer_flick/providers/core/storage_provider.dart';
import 'package:gamer_flick/repositories/auth/auth_repository.dart';
import 'package:gamer_flick/providers/community/community_chat_provider.dart';

IconData getNotificationIcon(String iconKey) {
  switch (iconKey) {
    case 'comment':
      return Icons.comment;
    case 'favorite':
      return Icons.favorite;
    case 'person_add':
      return Icons.person_add;
    case 'mail':
      return Icons.mail;
    case 'emoji_events':
      return Icons.emoji_events;

    case 'notifications':
    default:
      return Icons.notifications;
  }
}

Color getNotificationColor(String colorKey) {
  switch (colorKey) {
    case 'green':
      return Colors.green;
    case 'red':
      return Colors.red;
    case 'blue':
      return Colors.blue;
    case 'purple':
      return Colors.purple;
    case 'orange':
      return Colors.orange;
    case 'amber':
      return Colors.amber;
    case 'grey':
    default:
      return Colors.grey;
  }
}

class CommunityDetailScreen extends ConsumerStatefulWidget {
  final Community community;

  const CommunityDetailScreen({super.key, required this.community});

  @override
  ConsumerState<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends ConsumerState<CommunityDetailScreen> {
  final Set<String> _selectedMemberIds = {};
  final List<String> _roles = ['member', 'moderator'];

  bool _isJoining = false;
  final bool _joined = false;
  final bool _checkedMembership = false;

  @override
  void initState() {
    super.initState();
    _checkAndShowOnboarding();
  }

  Future<void> _checkAndShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'onboarded_community_${widget.community.id}';
    final hasSeen = prefs.getBool(key) ?? false;
    if (!hasSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => CommunityOnboardingScreen(
            community: widget.community,
            onContinue: () async {
              await prefs.setBool(key, true);
              if (mounted) Navigator.of(context).pop();
            },
          ),
        );
      });
    }
  }

  Future<void> _joinCommunity() async {
    setState(() => _isJoining = true);
    try {
      await ref.read(communitiesProvider.notifier).joinCommunity(widget.community.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community joined successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  Future<void> _leaveCommunity() async {
    setState(() => _isJoining = true);
    try {
      await ref.read(communitiesProvider.notifier).leaveCommunity(widget.community.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the community.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to leave: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  void _showLeaveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Community'),
        content: const Text('Are you sure you want to leave this community?'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.of(context).pop();
              _leaveCommunity();
            },
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final communityId = widget.community.id;
    final user = ref.watch(userProvider).value;
    final currentUser = user?.id;

    final communityAsync = ref.watch(communityDetailProvider(communityId));
    
    return communityAsync.when(
      data: (community) {
        if (community == null) {
          return const Scaffold(
            body: Center(child: Text('Community not found')),
          );
        }

        final membershipAsync = ref.watch(communityMembershipProvider(community.id));
        final joined = membershipAsync.value ?? false;
        final checkedMembership = !membershipAsync.isLoading;

        final membersAsync = ref.watch(communityMembersProvider(community.id));
        final currentMember = membersAsync.value?.firstWhere(
          (m) => m.userId == currentUser,
          orElse: () => CommunityMember(
            userId: currentUser ?? '',
            communityId: community.id,
            role: 'member',
            joinedAt: DateTime.now(),
          ),
        ) ?? CommunityMember(
          userId: currentUser ?? '',
          communityId: community.id,
          role: 'member',
          joinedAt: DateTime.now(),
        );
          final isCreator =
              currentUser != null && community.createdBy == currentUser;
          final isAdmin = currentMember.role == 'admin';
          final canSeeAdminTabs = isCreator || isAdmin;

          // Only show info tab if not a member
          final showAllTabs = checkedMembership && joined;

    final tabs = <Tab>[
      const Tab(icon: Icon(Icons.info_outline), text: 'Info'),
      if (showAllTabs) ...[
        const Tab(icon: Icon(Icons.article), text: 'Posts'),
        const Tab(icon: Icon(Icons.chat_bubble_outline), text: 'Chat'),
        const Tab(icon: Icon(Icons.people_outline), text: 'Members'),
        const Tab(icon: Icon(Icons.photo_library), text: 'Gallery'),
        const Tab(icon: Icon(Icons.notifications), text: 'Notifications'),
        if (canSeeAdminTabs)
          const Tab(
              icon: Icon(Icons.admin_panel_settings),
              text: 'Roles & Permissions'),
        if (canSeeAdminTabs)
          const Tab(icon: Icon(Icons.settings), text: 'Settings'),
      ],
    ];

    final tabViews = <Widget>[
      _buildInfoTab(community),
      if (showAllTabs) ...[
        _buildPostsTab(context, community),
        _buildChatTab(community),
        _buildMembersTab(context, community),
        _buildMediaGalleryTab(community),
        _buildCommunityNotificationsTab(community),
        if (canSeeAdminTabs)
          CommunityRolesScreen(communityId: community.id),
        if (canSeeAdminTabs)
          CommunitySettingsScreen(community: community),
      ],
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(community.name),
          actions: [
            if (canSeeAdminTabs && showAllTabs)
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Community Settings',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommunitySettingsScreen(
                        community: community,
                      ),
                    ),
                  );
                },
              ),
          ],
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(children: tabViews),
      ),
    );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoTab(Community community) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Community Header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      community.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage:
                                  NetworkImage(community.imageUrl!),
                              radius: 32,
                            )
                          : CircleAvatar(
                              radius: 32,
                              backgroundColor:
                                  theme.primaryColor.withOpacity(0.1),
                              child: Icon(Icons.reddit,
                                  color: theme.primaryColor, size: 32),
                            ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'r/${community.name}',
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (community.isVerified)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Icon(Icons.verified,
                                        color: theme.colorScheme.primary,
                                        size: 20),
                                  ),
                                if (community.isNsfw)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.error
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text('NSFW',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: theme.colorScheme.error)),
                                    ),
                                  ),
                              ],
                            ),
                            if (community.displayName != community.name)
                              Text(
                                community.displayName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              '${community.memberCount} members',
                              style: theme.textTheme.bodyMedium,
                            ),
                            if (community.onlineCount > 0)
                              Text(
                                '${community.onlineCount} online',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    community.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (community.game != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.sports_esports,
                            size: 16,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Game: ${community.game}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (community.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: community.tags
                          .map((tag) => Chip(
                                label: Text(tag),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Community Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Stats',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                            'Members', '${community.memberCount}'),
                      ),
                      Expanded(
                        child: _buildStatItem(
                            'Online', '${community.onlineCount}'),
                      ),
                      Expanded(
                        child: _buildStatItem(
                            'Created', _formatDate(community.createdAt)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Community Rules
          if (community.rules != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community Rules',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(community.rules!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Community Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Community Settings',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem('Public', community.isPublic),
                  _buildSettingItem('Allow Images', community.allowImages),
                  _buildSettingItem('Allow Videos', community.allowVideos),
                  _buildSettingItem('Allow Links', community.allowLinks),
                  _buildSettingItem('Allow Polls', community.allowPolls),
                  _buildSettingItem('Require Flair', community.requireFlair),
                  _buildSettingItem('Enable Wiki', community.enableWiki),
                  _buildSettingItem('Enable Mod Log', community.enableModLog),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Join Button
          ref.watch(communityMembershipProvider(community.id)).when(
                data: (joined) => joined
                    ? SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _showLeaveConfirmationDialog,
                          icon: const Icon(Icons.person_remove),
                          label: const Text('Leave Community'),
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isJoining ? null : _joinCommunity,
                          icon: _isJoining
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.person_add),
                          label: _isJoining
                              ? const SizedBox.shrink()
                              : const Text('Join Community'),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem(String label, bool value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color:
                value ? theme.colorScheme.secondary : theme.colorScheme.error,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Widget _buildPostsTab(BuildContext context, Community community) {
    final currentUserId = ref.watch(userProvider).value?.id;
    final postsAsync = ref.watch(communityPostsProvider(CommunityPostParams(communityId: community.id)));

    return postsAsync.when(
      data: (posts) {
        return Column(
          children: [
            Expanded(
              child: posts.isEmpty
                  ? const Center(child: Text('No posts yet.'))
                  : ListView.builder(
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return CommunityPostItem(
                          post: posts[index],
                          communityId: community.id,
                          currentUserId: currentUserId,
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Post'),
                onPressed: () async {
                  final result = await showDialog<_PostDialogResult>(
                    context: context,
                    builder: (context) {
                      String text = '';
                      List<XFile> images = [];
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('New Post'),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Write something...',
                                    ),
                                    onChanged: (val) => text = val,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.image),
                                        label: const Text('Add Image'),
                                        onPressed: () async {
                                          final picker = ImagePicker();
                                          final picked =
                                              await picker.pickMultiImage();
                                          if (picked.isNotEmpty) {
                                            setState(() {
                                              images.addAll(picked);
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  if (images.isNotEmpty)
                                    SizedBox(
                                      height: 80,
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: images
                                              .map(
                                                (img) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                    right: 8.0,
                                                  ),
                                                  child: kIsWeb
                                                      ? Image.network(img.path,
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover)
                                                      : Image.file(
                                                          File(img.path),
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                                label: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(
                                  context,
                                  _PostDialogResult(
                                    text,
                                    images,
                                    List<String>.filled(images.length, ''),
                                  ),
                                ),
                                icon: const Icon(Icons.send),
                                label: const Text('Post'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                  if (result != null && result.text.trim().isNotEmpty) {
                    try {
                      final user = Supabase.instance.client.auth.currentUser;
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You must be logged in to post.'),
                          ),
                        );
                        return;
                      }

                      // Check if user is a member of the community
                      final isMember = await ref.read(communityMembershipProvider(community.id).future);

                      if (!isMember) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'You must be a member of this community to post.'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      // Show loading indicator
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (BuildContext context) {
                          return const AlertDialog(
                            title: Text('Creating Post'),
                            content: Row(
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(width: 20),
                                Text('Creating post...'),
                              ],
                            ),
                          );
                        },
                      );

                      List<String> imageUrls = [];
                      if (result.images.isNotEmpty) {
                        final storageRepo = ref.read(storage_repo.storageRepositoryProvider);
                        for (final img in result.images) {
                          try {
                            final url =
                                await storageRepo.uploadCommunityPostImage(
                              img,
                              user.id,
                              community.id,
                            );
                            imageUrls.add(url);
                          } catch (e) {
                            Navigator.of(context).pop(); // Close loading dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Failed to upload image: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                        }
                      }

                      final post = CommunityPost(
                        id: '', // Supabase will generate
                        communityId: community.id,
                        authorId: user.id,
                        title: result.text
                            .trim()
                            .split('\n')
                            .first, // Use first line as title
                        content: result.text.trim(),
                        imageUrls: imageUrls,
                        imageCaptions: result.captions,
                        createdAt: DateTime.now(),
                        pinned: false,
                      );

                      await ref.read(communityPostsProvider(CommunityPostParams(communityId: community.id)).notifier).createPost(post);

                      Navigator.of(context).pop(); // Close loading dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Post created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      Navigator.of(context)
                          .pop(); // Close loading dialog if still open
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text('Failed to create post: ${e.toString()}'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildChatTab(Community community) {
    return CommunityChatWidget(communityId: community.id);
  }

  Widget _buildMembersTab(BuildContext context, Community community) {
    final membersAsync = ref.watch(communityMembersProvider(community.id));
    final invitesAsync = ref.watch(communityInvitesProvider(community.id));

    return membersAsync.when(
      data: (members) => invitesAsync.when(
        data: (invites) {
          final currentUser = Supabase.instance.client.auth.currentUser;
          final currentMember = members.firstWhere(
            (m) => m.userId == currentUser?.id,
            orElse: () => CommunityMember(
              userId: currentUser?.id ?? '',
              communityId: community.id,
              role: 'member',
              joinedAt: DateTime.now(),
            ),
          );
          final isAdmin = currentMember.role == 'admin';
          final isMod = currentMember.role == 'moderator';

          // --- Search & Filter State ---
          final searchController = TextEditingController();
          String searchQuery = '';
          String roleFilter = 'all';
          String banFilter = 'all';
          String sortOption = 'join_newest'; // default sort
          String selectedRole = 'member';
          final TextEditingController messageController =
              TextEditingController();
          final int messageMaxLength = 200;
          Map<String, bool> resending = {};
          Map<String, DateTime> lastResend = {};
          final Duration resendCooldown = const Duration(seconds: 5);
          final TextEditingController inviteSearchController =
              TextEditingController();
          String inviteStatusFilter = 'all';
          final List<String> inviteStatusOptions = [
            'all',
            'pending',
            'accepted',
            'expired',
            'cancelled',
          ];

          return StatefulBuilder(
            builder: (context, setState) {
              // --- Filtering and sorting logic ---
              String searchQuery =
                  inviteSearchController.text.trim().toLowerCase();
              List<CommunityMember> filteredMembers =
                  members.where((member) {
                bool matchesSearch = true;
                bool matchesRole = true;
                bool matchesBan = true;
                // Search by username or display name (case-insensitive)
                if (searchQuery.isNotEmpty) {
                  matchesSearch = false;
                }
                if (roleFilter != 'all' && member.role != roleFilter) {
                  matchesRole = false;
                }
                if (banFilter == 'banned' && !member.isBanned) {
                  matchesBan = false;
                } else if (banFilter == 'not_banned' && member.isBanned) {
                  matchesBan = false;
                }
                return matchesSearch && matchesRole && matchesBan;
              }).toList();
              // Sorting logic
              filteredMembers.sort((a, b) {
                if (sortOption == 'join_newest') {
                  return b.joinedAt.compareTo(a.joinedAt);
                } else if (sortOption == 'join_oldest') {
                  return a.joinedAt.compareTo(b.joinedAt);
                } else if (sortOption == 'role') {
                  const roleOrder = {'admin': 0, 'moderator': 1, 'member': 2};
                  return (roleOrder[a.role] ?? 3).compareTo(
                    roleOrder[b.role] ?? 3,
                  );
                }
                // name (A-Z)
                return 0;
              });
              List<CommunityInvite> filteredInvites =
                  invites.where((invite) {
                bool matchesStatus = inviteStatusFilter == 'all' ||
                    invite.status == inviteStatusFilter;
                bool matchesSearch = true;
                if (searchQuery.isNotEmpty) {
                  matchesSearch = (invite.inviteeEmail?.toLowerCase().contains(
                                searchQuery,
                              ) ??
                          false) ||
                      (invite.inviteeUserId?.toLowerCase().contains(
                                searchQuery,
                              ) ??
                          false) ||
                      (invite.message?.toLowerCase().contains(
                                searchQuery,
                              ) ??
                          false);
                }
                return matchesStatus && matchesSearch;
              }).toList();
              Map<String, List<CommunityInvite>> groupedInvites = {};
              for (var invite in filteredInvites) {
                groupedInvites.putIfAbsent(invite.status, () => []).add(invite);
              }
              // --- End filtering and sorting logic ---

              String messageText = messageController.text;
              int messageLength = messageText.length;
              bool messageTooLong = messageLength > messageMaxLength;
              String previewText = messageText
                  .replaceAll('{username}', 'gamer123')
                  .replaceAll('{community}', 'GamerFlick');

              return Column(
                children: [
                  if (isAdmin || isMod)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 12,
                        left: 12,
                        right: 12,
                        bottom: 0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.person_add),
                          label: const Text('Invite Members'),
                          onPressed: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => _InviteMembersDialog(
                                communityId: community.id,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  Material(
                    elevation: 2,
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              // Search bar
                              Expanded(
                                child: TextField(
                                  controller: searchController,
                                  decoration: const InputDecoration(
                                    hintText: 'Search members...',
                                    prefixIcon: Icon(Icons.search),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                  onChanged: (val) {
                                    setState(() {
                                      searchQuery = val.trim().toLowerCase();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Role filter
                              DropdownButton<String>(
                                value: roleFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Roles'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'admin',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'moderator',
                                    child: Text('Moderator'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'member',
                                    child: Text('Member'),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    roleFilter = val!;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              // Ban filter
                              DropdownButton<String>(
                                value: banFilter,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'banned',
                                    child: Text('Banned'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'not_banned',
                                    child: Text('Not Banned'),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    banFilter = val!;
                                  });
                                },
                              ),
                              const SizedBox(width: 8),
                              // Sort dropdown
                              DropdownButton<String>(
                                value: sortOption,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'join_newest',
                                    child: Text('Newest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'join_oldest',
                                    child: Text('Oldest'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'role',
                                    child: Text('Role'),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    sortOption = val!;
                                  });
                                },
                                icon: Icon(Icons.sort),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => ref.refresh(communityMembersProvider(community.id).future),
                      child: ListView.builder(
                        itemCount: filteredMembers.length,
                        itemBuilder: (context, index) {
                          final member = filteredMembers[index];
                          return FutureBuilder<Profile?>(
                            future: _fetchProfile(member.userId),
                            builder: (context, snapshot) {
                              final profile = snapshot.data;
                              return ListTile(
                                leading: Stack(
                                  children: [
                                    profile?.profilePicture != null
                                        ? CircleAvatar(
                                            backgroundImage: NetworkImage(
                                              profile!.profilePicture!,
                                            ),
                                          )
                                        : const CircleAvatar(
                                            child: Icon(Icons.person),
                                          ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: _buildStatusDot(profile?.status),
                                    ),
                                  ],
                                ),
                                title: Text(profile?.displayName ?? 'User'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.role +
                                          (member.isBanned ? ' (Banned)' : ''),
                                    ),
                                    if (profile?.lastActive != null)
                                      Text(
                                        _formatLastActive(profile!.lastActive!),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: profile != null
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => ProfileScreen(
                                              userId: profile.id,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                trailing: (isAdmin || isMod) &&
                                        currentUser?.id != member.userId
                                    ? PopupMenuButton<String>(
                                        onSelected: (value) async {
                                          if (value == 'promote') {
                                            await ref.read(communitiesProvider.notifier).updateMemberRole(
                                              community.id,
                                              member.userId,
                                              'moderator',
                                            );
                                          } else if (value == 'demote') {
                                            await ref.read(communitiesProvider.notifier).updateMemberRole(
                                              community.id,
                                              member.userId,
                                              'member',
                                            );
                                          } else if (value == 'ban') {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Ban Member'),
                                                content: const Text(
                                                  'Are you sure you want to ban this member?',
                                                ),
                                                actions: [
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                    icon:
                                                        const Icon(Icons.close),
                                                    label: const Text('Cancel'),
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                    icon: const Icon(
                                                        Icons.block,
                                                        color: Colors.red),
                                                    label: const Text(
                                                      'Ban',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref.read(communitiesProvider.notifier).banMember(
                                                community.id,
                                                member.userId,
                                              );
                                            }
                                          } else if (value == 'unban') {
                                            await ref.read(communitiesProvider.notifier).unbanMember(
                                              community.id,
                                              member.userId,
                                            );
                                          } else if (value == 'remove') {
                                            final confirm =
                                                await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text(
                                                  'Remove Member',
                                                ),
                                                content: const Text(
                                                  'Are you sure you want to remove this member?',
                                                ),
                                                actions: [
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      false,
                                                    ),
                                                    icon:
                                                        const Icon(Icons.close),
                                                    label: const Text('Cancel'),
                                                  ),
                                                  TextButton.icon(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                      context,
                                                      true,
                                                    ),
                                                    icon: const Icon(
                                                        Icons.person_remove,
                                                        color: Colors.red),
                                                    label: const Text(
                                                      'Remove',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref.read(communitiesProvider.notifier).removeMember(
                                                community.id,
                                                member.userId,
                                              );
                                            }
                                          }
                                        },
                                        itemBuilder: (context) {
                                          final items =
                                              <PopupMenuEntry<String>>[];
                                          if (member.role == 'member') {
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'promote',
                                                child: Text(
                                                  'Promote to Moderator',
                                                ),
                                              ),
                                            );
                                          } else if (member.role ==
                                              'moderator') {
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'demote',
                                                child: Text('Demote to Member'),
                                              ),
                                            );
                                          }
                                          if (!member.isBanned) {
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'ban',
                                                child: Text('Ban'),
                                              ),
                                            );
                                          } else {
                                            items.add(
                                              const PopupMenuItem(
                                                value: 'unban',
                                                child: Text('Unban'),
                                              ),
                                            );
                                          }
                                          items.add(
                                            const PopupMenuItem(
                                              value: 'remove',
                                              child: Text(
                                                'Remove from Community',
                                              ),
                                            ),
                                          );
                                          return items;
                                        },
                                      )
                                    : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Future<app_models.User?> _fetchUser(String userId) async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return app_models.User.fromMap(data);
  }

  Future<Profile?> _fetchProfile(String userId) async {
    try {
      return await ref.read(user_repo.userRepositoryProvider).getProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildStatusDot(String? status) {
    Color color;
    String label;
    switch (status) {
      case 'online':
        color = Colors.green;
        label = 'Online';
        break;
      case 'away':
        color = Colors.orange;
        label = 'Away';
        break;
      default:
        color = Colors.grey;
        label = 'Offline';
    }
    return Tooltip(
      message: label,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    if (difference.inMinutes < 1) {
      return 'Active just now';
    } else if (difference.inMinutes < 60) {
      return 'Active ${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return 'Active ${difference.inHours} hr ago';
    } else {
      return 'Active on ${lastActive.year}-${lastActive.month.toString().padLeft(2, '0')}-${lastActive.day.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMediaGalleryTab(Community community) {
    final postsAsync = ref.watch(communityPostsProvider(CommunityPostParams(communityId: community.id)));

    return postsAsync.when(
      data: (posts) {
        final mediaMessages = <Message>[];
        for (final post in posts) {
          for (final url in post.imageUrls) {
            mediaMessages.add(
              Message(
                id: url, // Use URL as a unique id surrogate
                conversationId: '',
                senderId: post.authorId,
                content: '',
                imageUrl: url,
                isSeen: true,
                isDelivered: true,
                reactions: const [],
                createdAt: post.createdAt,
                isPinned: post.pinned,
              ),
            );
          }
        }
        return MediaGalleryScreen(images: mediaMessages);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildCommunityNotificationsTab(Community community) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return notificationsAsync.when(
      data: (allNotifications) {
        final communityNotifications = allNotifications
            .where(
              (n) =>
                  n.relatedId == community.id ||
                  n.metadata['communityId'] == community.id,
            )
            .toList();

        if (communityNotifications.isEmpty) {
          return const Center(
            child: Text('No notifications for this community.'),
          );
        }

        return ListView.builder(
          itemCount: communityNotifications.length,
          itemBuilder: (context, index) {
            final n = communityNotifications[index];
            return ListTile(
              leading: Icon(
                getNotificationIcon(n.type.iconKey),
                color: getNotificationColor(n.type.colorKey),
              ),
              title: Text(n.title),
              subtitle: Text(n.message),
              trailing: n.isRead
                  ? null
                  : const Icon(Icons.circle, color: Colors.blue, size: 12),
              onTap: () {
                ref.read(notificationsProvider.notifier).markAsRead(n.id);
                // Optionally: navigate to related post/chat/etc.
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _PostDialogResult {
  final String text;
  final List<XFile> images;
  final List<String> captions;
  _PostDialogResult(this.text, this.images, this.captions);
}

class _EditPostResult {
  final String text;
  final List<String> imageUrls;
  final List<XFile> newImages;
  final List<String> imageCaptions;
  final List<String> newImageCaptions;
  _EditPostResult(
    this.text,
    this.imageUrls,
    this.newImages,
    this.imageCaptions,
    this.newImageCaptions,
  );
}

class _GalleryMedia {
  final String url;
  final DateTime createdAt;
  final String senderId;
  _GalleryMedia({
    required this.url,
    required this.createdAt,
    required this.senderId,
  });
}

// Invite Members Dialog
class _InviteMembersDialog extends ConsumerStatefulWidget {
  final String communityId;
  const _InviteMembersDialog({
    required this.communityId,
  });
  @override
  ConsumerState<_InviteMembersDialog> createState() => _InviteMembersDialogState();
}

class _InviteMembersDialogState extends ConsumerState<_InviteMembersDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final int _messageMaxLength = 200;
  final Map<String, bool> _resending = {};
  final Map<String, DateTime> _lastResend = {};
  final Duration _resendCooldown = const Duration(seconds: 5);
  bool _isLoading = false;
  String? _error;
  List<Profile> _userSuggestions = [];
  Profile? _selectedUser;
  String? _inviteLink;
  bool _isGeneratingLink = false;
  DateTime? _selectedExpiration;
  String _selectedRole = 'member';
  final List<String> _roles = ['member', 'moderator'];

  @override
  void initState() {
    super.initState();
    _selectedExpiration = DateTime.now().add(const Duration(days: 7));
    Future.microtask(() => _loadOrGenerateInviteLink());
  }

  // Helper to get first matching element or null
  T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  Future<void> _loadOrGenerateInviteLink() async {
    setState(() {
      _isGeneratingLink = true;
    });
    // Find an existing pending invite link
    final invites = ref.read(communityInvitesProvider(widget.communityId)).value ?? [];
    final linkInvite = _firstWhereOrNull(
      invites,
      (i) => i.inviteLinkToken.isNotEmpty && i.status == 'pending',
    );
    if (linkInvite != null) {
      setState(() {
        _inviteLink = _buildInviteUrl(linkInvite.inviteLinkToken);
        _isGeneratingLink = false;
      });
      return;
    }
    // Otherwise, create a new invite link
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');
      
      await ref.read(communitiesProvider.notifier).createInvite(
        communityId: widget.communityId,
        inviterId: user.id,
        role: _selectedRole,
        message: _messageController.text.trim().isEmpty
            ? null
            : _messageController.text.trim(),
      );
      
      final updatedInvites = await ref.refresh(communityInvitesProvider(widget.communityId).future);
      // Find the new invite link
      final newLinkInvite = _firstWhereOrNull(
        updatedInvites,
        (i) => i.inviteLinkToken.isNotEmpty && i.status == 'pending',
      );
      setState(() {
        _inviteLink = newLinkInvite != null
            ? _buildInviteUrl(newLinkInvite.inviteLinkToken)
            : null;
        _isGeneratingLink = false;
      });
    } catch (e) {
      setState(() {
        _isGeneratingLink = false;
      });
    }
  }

  String _buildInviteUrl(String token) {
    // Replace with your actual invite URL base
    return 'https://yourapp.com/invite/$token';
  }

  Future<void> _onUsernameChanged(String value) async {
    if (value.trim().isEmpty) {
      setState(() {
        _userSuggestions = [];
        _selectedUser = null;
      });
      return;
    }
    final results = await ref.read(user_repo.userRepositoryProvider).searchUsers(value.trim());
    setState(() {
      _userSuggestions = results;
      _selectedUser = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yMMMd h:mm a');
    final invitesAsync = ref.watch(communityInvitesProvider(widget.communityId));
    final invites = invitesAsync.value ?? [];
    return AlertDialog(
      title: const Text('Invite Members'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Role picker
            Row(
              children: [
                const Icon(Icons.security),
                const SizedBox(width: 8),
                const Text('Invitee Role:'),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedRole,
                  items: _roles
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(
                            role[0].toUpperCase() + role.substring(1),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRole = val!;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Expiration picker
            Row(
              children: [
                const Icon(Icons.timer),
                const SizedBox(width: 8),
                const Text('Invite Expiration:'),
                const SizedBox(width: 8),
                Text(
                  _selectedExpiration != null
                      ? dateFormat.format(_selectedExpiration!)
                      : 'None',
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Change Expiration',
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedExpiration ??
                          DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(
                          _selectedExpiration ?? DateTime.now(),
                        ),
                      );
                      if (time != null) {
                        setState(() {
                          _selectedExpiration = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Custom invite message
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Personal message (optional)',
                prefixIcon: const Icon(Icons.message),
                hintText:
                    'Example: Hi {username}, join us in {community} for exclusive tournaments!',
                counterText: '${_messageController.text.length}/$_messageMaxLength',
                errorText: _messageController.text.length > _messageMaxLength
                    ? 'Message too long (max $_messageMaxLength chars)'
                    : null,
              ),
              maxLines: null,
              minLines: 2,
              maxLength: _messageMaxLength,
              onChanged: (_) => setState(() {}),
            ),
            if (_messageController.text.length > _messageMaxLength)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Message too long!',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 4),
            const Text(
              'Preview:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: MarkdownBody(
                data: (_messageController.text
                        .replaceAll('{username}', 'gamer123')
                        .replaceAll('{community}', 'GamerFlick'))
                    .isEmpty
                    ? '_No message_'
                    : _messageController.text
                        .replaceAll('{username}', 'gamer123')
                        .replaceAll('{community}', 'GamerFlick'),
                styleSheet: MarkdownStyleSheet(
                  p: const TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Invite by email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Invite by email',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) throw Exception('Not authenticated');
                        await ref.read(communitiesProvider.notifier).createInvite(
                          communityId: widget.communityId,
                          inviterId: user.id,
                          inviteeEmail: _emailController.text.trim(),
                          expiresAt: _selectedExpiration,
                          role: _selectedRole,
                          message: _messageController.text.trim().isEmpty
                              ? null
                              : _messageController.text.trim(),
                        );
                        _emailController.clear();
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                        });
                      }
                      setState(() {
                        _isLoading = false;
                      });
                    },
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.email),
              label: _isLoading
                  ? const SizedBox.shrink()
                  : const Text('Send Email Invite'),
            ),
            const Divider(height: 32),
            // Invite by username (autocomplete)
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Invite by username',
                prefixIcon: Icon(Icons.person_search),
              ),
              onChanged: _onUsernameChanged,
            ),
            if (_userSuggestions.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  itemCount: _userSuggestions.length,
                  itemBuilder: (context, index) {
                    final user = _userSuggestions[index];
                    return ListTile(
                      leading: user.profilePictureUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage(
                                user.profilePictureUrl!,
                              ),
                            )
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user.displayName),
                      subtitle: Text('@${user.username}'),
                      onTap: () {
                        setState(() {
                          _selectedUser = user;
                          _usernameController.text = user.username;
                          _userSuggestions = [];
                        });
                      },
                      selected: _selectedUser?.id == user.id,
                    );
                  },
                ),
              ),
            ElevatedButton.icon(
              onPressed: _isLoading || _selectedUser == null
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                        _error = null;
                      });
                      try {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user == null) throw Exception('Not authenticated');
                        await ref.read(communitiesProvider.notifier).createInvite(
                          communityId: widget.communityId,
                          inviterId: user.id,
                          inviteeUserId: _selectedUser!.id,
                          expiresAt: _selectedExpiration,
                          role: _selectedRole,
                          message: _messageController.text.trim().isEmpty
                              ? null
                              : _messageController.text.trim(),
                        );
                        _usernameController.clear();
                        _selectedUser = null;
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                        });
                      }
                      setState(() {
                        _isLoading = false;
                      });
                    },
              icon: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.person_add),
              label: _isLoading
                  ? const SizedBox.shrink()
                  : const Text('Send Username Invite'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            const SizedBox(height: 16),
            // Shareable invite link section
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                const Text(
                  'Shareable Invite Link',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isGeneratingLink)
              const Center(child: CircularProgressIndicator())
            else if (_inviteLink != null)
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      _inviteLink!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    tooltip: 'Copy Link',
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _inviteLink!),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite link copied!')),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Regenerate Link',
                    onPressed: _isGeneratingLink
                        ? null
                        : () async {
                            // Cancel old link and generate new
                            final linkInvite = _firstWhereOrNull(
                              invites,
                              (i) =>
                                  i.inviteLinkToken.isNotEmpty &&
                                  i.status == 'pending',
                            );
                            if (linkInvite != null) {
                              await ref.read(communitiesProvider.notifier).cancelInvite(
                                widget.communityId,
                                linkInvite.id,
                              );
                            }
                            setState(() {
                              _inviteLink = null;
                            });
                            await _loadOrGenerateInviteLink();
                          },
                  ),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _isGeneratingLink ? null : _loadOrGenerateInviteLink,
                icon: const Icon(Icons.link),
                label: const Text('Generate Invite Link'),
              ),
            if (_selectedExpiration != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Link expires: ${dateFormat.format(_selectedExpiration!)}',
                  style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(),
            const Text(
              'Pending Invites',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: invitesAsync.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: invites.length,
                      itemBuilder: (context, index) {
                        final invite = invites[index];
                        if (invite.status != 'pending') {
                          return const SizedBox.shrink();
                        }
                        return ListTile(
                          leading: invite.inviteeUserId != null &&
                                  invite.status == 'accepted'
                              ? FutureBuilder<Profile?>(
                                  future: _fetchProfile(invite.inviteeUserId!),
                                  builder: (context, snapshot) {
                                    final profile = snapshot.data;
                                    if (profile != null) {
                                      return CircleAvatar(
                                        backgroundImage:
                                            profile.profilePictureUrl != null
                                                ? NetworkImage(
                                                    profile.profilePictureUrl!,
                                                  )
                                                : null,
                                        child: profile.profilePictureUrl == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      );
                                    }
                                    return const CircleAvatar(
                                      child: Icon(Icons.person),
                                    );
                                  },
                                )
                              : const Icon(Icons.mail_outline),
                          title: Text(
                            invite.inviteeEmail ??
                                invite.inviteeUserId ??
                                'Invite Link',
                          ),
                          subtitle: Text(
                            'Role: \\${invite.role ?? 'member'}\nSent: \\${dateFormat.format(invite.createdAt)}\nExpires: \\${invite.expiresAt != null ? dateFormat.format(invite.expiresAt!) : 'Never'}${invite.message != null && invite.message!.isNotEmpty ? '\nMessage: \\${invite.message}' : ''}${invite.status == 'accepted' && invite.acceptedAt != null ? '\nAccepted: \\${dateFormat.format(invite.acceptedAt!)}' : ''}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInviteStatusChip(invite.status),
                              if (invite.status == 'pending')
                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Cancel Invite',
                                  onPressed: () async {
                                    await ref.read(communitiesProvider.notifier).cancelInvite(
                                      widget.communityId,
                                      invite.id,
                                    );
                                  },
                                ),
                              if (invite.status == 'pending')
                                IconButton(
                                  icon: _resending[invite.id] == true
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.refresh,
                                          color: Colors.blue,
                                        ),
                                  tooltip: 'Resend Invite',
                                  onPressed: () async {
                                    final now = DateTime.now();
                                    if (_lastResend[invite.id] != null &&
                                        now.difference(
                                              _lastResend[invite.id]!,
                                            ) <
                                            _resendCooldown) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Please wait before resending.',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _resending[invite.id] = true;
                                    });
                                    try {
                                      await ref.read(communitiesProvider.notifier).resendInvite(
                                        widget.communityId,
                                        invite.id,
                                      );
                                      _lastResend[invite.id] = DateTime.now();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Invite resent!'),
                                        ),
                                      );
                                    } catch (_) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Failed to resend invite.',
                                          ),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      _resending[invite.id] = false;
                                    });
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          label: const Text('Close'),
        ),
      ],
    );
  }

  Future<Profile?> _fetchProfile(String userId) async {
    try {
      return await ref.read(user_repo.userRepositoryProvider).getProfile(userId);
    } catch (_) {
      return null;
    }
  }

  Widget _buildInviteStatusChip(String status) {
    Color color;
    String label;
    IconData icon;
    switch (status) {
      case 'accepted':
        color = Colors.green;
        label = 'Accepted';
        icon = Icons.check_circle;
        break;
      case 'expired':
        color = Colors.grey;
        label = 'Expired';
        icon = Icons.hourglass_disabled;
        break;
      case 'cancelled':
        color = Colors.red;
        label = 'Cancelled';
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.hourglass_empty;
    }
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withOpacity(0.1),
    );
  }
}

class CommunityOnboardingScreen extends StatelessWidget {
  final Community community;
  final VoidCallback onContinue;
  const CommunityOnboardingScreen({
    required this.community,
    required this.onContinue,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      backgroundColor: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.95,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (community.imageUrl != null)
                  CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(community.imageUrl!),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Welcome to \\${community.name}!',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  community.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Community Rules',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // TODO: Replace with real rules if available
                Text(
                  '• Be respectful and inclusive.\n• No spam or self-promotion.\n• Follow the game/community guidelines.\n• Use appropriate channels for topics.\n• Report issues to moderators.',
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Features',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Posts: Share updates, images, and videos.\n• Chat: Real-time group chat.\n• Members: See and connect with others.\n• Gallery: Browse all community media.\n• Roles: Admins, mods, and members.\n• Invites: Bring your friends!\n• More in the tabs above.',
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Get Started',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Introduce yourself in chat.\n• Read pinned posts.\n• Invite friends.\n• Explore the gallery.\n• Check out tournaments or events if available.',
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(180, 48),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CommunityChatWidget extends ConsumerStatefulWidget {
  final String communityId;
  const CommunityChatWidget({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatWidget> createState() => _CommunityChatWidgetState();
}

class _CommunityChatWidgetState extends ConsumerState<CommunityChatWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Subscribe to real-time messages when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityChatProvider(widget.communityId).notifier).subscribe();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    try {
      await ref.read(communityChatProvider(widget.communityId).notifier).sendMessage(text);
      _controller.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(communityChatProvider(widget.communityId));

    return chatAsync.when(
      data: (messages) {
        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(child: Text('No messages yet.'))
                  : ListView.builder(
                      reverse: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[messages.length - 1 - index];
                        return _ChatMessageTile(message: msg);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }
}

class _ChatMessageTile extends ConsumerWidget {
  final CommunityChatMessage message;
  const _ChatMessageTile({required this.message});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(otherUserProfileProvider(message.userId));

    return ListTile(
      leading: userProfileAsync.when(
        data: (profile) => CircleAvatar(
          radius: 16,
          backgroundImage: profile?.profilePicture != null
              ? CachedNetworkImageProvider(profile!.profilePicture!)
              : null,
          child: profile?.profilePicture == null ? const Icon(Icons.person, size: 16) : null,
        ),
        loading: () => const CircleAvatar(radius: 16, child: SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (_, __) => const CircleAvatar(radius: 16, child: Icon(Icons.error, size: 16)),
      ),
      title: userProfileAsync.when(
        data: (profile) => Text(
          profile?.displayName ?? 'User',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
        loading: () => const Text('Loading...', style: TextStyle(fontSize: 13)),
        error: (_, __) => const Text('Error', style: TextStyle(fontSize: 13)),
      ),
      subtitle: Text(message.message),
      trailing: Text(
        DateFormat('h:mm a').format(message.createdAt),
        style: const TextStyle(fontSize: 10, color: Colors.grey),
      ),
      dense: true,
    );
  }
}

class CommunityPostItem extends ConsumerWidget {
  final CommunityPost post;
  final String communityId;
  final String? currentUserId;

  const CommunityPostItem({
    super.key,
    required this.post,
    required this.communityId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(otherUserProfileProvider(post.authorId));
    final voteAsync = ref.watch(userPostVoteProvider(post.id));
    final isAuthor = currentUserId != null && currentUserId == post.authorId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: post.pinned
            ? BorderSide(color: theme.colorScheme.secondary, width: 2)
            : BorderSide.none,
      ),
      elevation: post.pinned ? 6 : 3,
      color: post.pinned ? theme.colorScheme.secondary.withOpacity(0.1) : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            userAsync.when(
              data: (user) => Row(
                children: [
                  if (post.pinned)
                    Icon(Icons.push_pin,
                        color: theme.colorScheme.secondary, size: 20),
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: user?.profilePicture != null
                        ? CachedNetworkImageProvider(user!.profilePicture!)
                        : null,
                    child: user?.profilePicture == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Anonymous',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('yMMMd').format(post.createdAt),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  if (isAuthor || (currentUserId != null))
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        final notifier = ref.read(communityPostsProvider(
                                CommunityPostParams(communityId: communityId))
                            .notifier);
                        if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Post'),
                                  content: const Text(
                                      'Are you sure you want to delete this post?'),
                                  actions: [
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel')),
                                    TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Delete',
                                            style:
                                                TextStyle(color: Colors.red))),
                                  ],
                                ),
                              ) ??
                              false;
                          if (confirm) {
                            await notifier.deletePost(post.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        if (isAuthor)
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (err, stack) => const Text('Error loading author'),
            ),
            const SizedBox(height: 12),
            Text(
              post.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (post.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.content,
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (post.imageUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.imageUrls.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: post.imageUrls[i],
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _VoteSection(post: post, communityId: communityId),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CommunityPostCommentsScreen(postId: post.id),
                      ),
                    );
                  },
                ),
                Text('${post.commentCount ?? 0}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteSection extends ConsumerWidget {
  final CommunityPost post;
  final String communityId;

  const _VoteSection({required this.post, required this.communityId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voteAsync = ref.watch(userPostVoteProvider(post.id));
    final score = post.score;

    return Row(
      children: [
        IconButton(
          icon: Icon(
            voteAsync.value == 1
                ? Icons.keyboard_arrow_up
                : Icons.keyboard_arrow_up_outlined,
            color: voteAsync.value == 1 ? Colors.orange : null,
          ),
          onPressed: () {
            ref
                .read(communityPostsProvider(
                        CommunityPostParams(communityId: communityId))
                    .notifier)
                .votePost(post.id, voteAsync.value == 1 ? 0 : 1);
          },
        ),
        Text('$score', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
          icon: Icon(
            voteAsync.value == -1
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_down_outlined,
            color: voteAsync.value == -1 ? Colors.blue : null,
          ),
          onPressed: () {
            ref
                .read(communityPostsProvider(
                        CommunityPostParams(communityId: communityId))
                    .notifier)
                .votePost(post.id, voteAsync.value == -1 ? 0 : -1);
          },
        ),
      ],
    );
  }
}
