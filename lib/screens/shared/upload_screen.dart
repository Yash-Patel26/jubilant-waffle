import 'package:flutter/material.dart';
import '../post/create_post_screen.dart';
import 'package:gamer_flick/services/media/supabase_upload_service.dart';
import '../post/create_story_screen.dart';
import '../../utils/post_creator_helper.dart';
import '../../utils/story_creator_helper.dart';
import '../reels/create_reel_screen.dart';
import '../live/go_live_screen.dart';
import '../post/audio_post_screen.dart';
import '../event/create_event_screen.dart';
import '../games/ai_create_screen.dart';
import '../post/schedule_post_screen.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String selectedPrivacy = 'Public';
  String? hoveredOption;

  final sidebarItems = [
    {'icon': Icons.home, 'label': 'Home', 'active': false},
    {'icon': Icons.movie, 'label': 'Reels', 'active': false},
    {'icon': Icons.cloud_upload, 'label': 'Upload', 'active': true},
    {'icon': Icons.message, 'label': 'Conversations', 'active': false},
    {'icon': Icons.notifications, 'label': 'Notifications', 'active': false},
    {'icon': Icons.search, 'label': 'Search', 'active': false},
    {'icon': Icons.emoji_events, 'label': 'Tournaments', 'active': false},
    {'icon': Icons.group, 'label': 'Communities', 'active': false},
    {'icon': Icons.person, 'label': 'Profile', 'active': false},
    {'icon': Icons.settings, 'label': 'Settings', 'active': false},
  ];

  final createOptions = [
    {
      'id': 'post',
      'title': 'Create a Post',
      'description': 'Share a photo or video to your feed',
      'icon': Icons.grid_3x3,
      'color': Colors.blue,
      'features': ['Photo', 'Video', 'Carousel', 'Text'],
      'isMain': true,
      'screen': CreatePostScreen(
        existingPost: Post(
          id: '',
          userId: '',
          content: '',
          isPublic: true,
          createdAt: DateTime.now(),
        ),
      ),
    },
    {
      'id': 'story',
      'title': 'Add to Your Story',
      'description': 'Share content that disappears in 24 hours',
      'icon': Icons.add,
      'color': Colors.purple,
      'features': ['Photo', 'Video', 'Boomerang', 'Text'],
      'isMain': true,
      'screen': CreateStoryScreen(),
    },
    {
      'id': 'reel',
      'title': 'Create a Reel',
      'description': 'Make a short, engaging video',
      'icon': Icons.videocam,
      'color': Colors.pink,
      'features': ['Video', 'Music', 'Effects', 'Templates'],
      'badge': 'Popular',
      'screen': CreateReelScreen(),
    },
    {
      'id': 'live',
      'title': 'Go Live',
      'description': 'Stream live to your audience',
      'icon': Icons.camera_alt,
      'color': Colors.red,
      'features': ['Live Video', 'Q&A', 'Shopping', 'Guests'],
      'screen': GoLiveScreen(),
    },
    {
      'id': 'audio',
      'title': 'Audio Post',
      'description': 'Share a voice note or podcast',
      'icon': Icons.mic,
      'color': Colors.green,
      'features': ['Voice Note', 'Podcast', 'Music', 'Sound Effects'],
      'badge': 'New',
      'screen': AudioPostScreen(),
    },
    {
      'id': 'event',
      'title': 'Create Event',
      'description': 'Organize and invite people to events',
      'icon': Icons.calendar_today,
      'color': Colors.orange,
      'features': ['Date & Time', 'Location', 'Invites', 'RSVP'],
      'screen': CreateEventScreen(),
    },
  ];

  List<Map<String, dynamic>> get quickActions => [
        {'icon': Icons.image, 'label': 'Photo', 'color': Colors.blue},
        {'icon': Icons.videocam, 'label': 'Video', 'color': Colors.purple},
        {
          'icon': Icons.auto_awesome,
          'label': 'AI Create',
          'color': Colors.pink
        },
        {'icon': Icons.schedule, 'label': 'Schedule', 'color': Colors.orange},
      ];

  final privacyOptions = [
    {'icon': Icons.public, 'label': 'Public', 'description': 'Anyone can see'},
    {'icon': Icons.group, 'label': 'Friends', 'description': 'Friends only'},
    {'icon': Icons.lock, 'label': 'Private', 'description': 'Only you'},
  ];

  void _navigateToCreatePost() async {
    // Show Facebook-style post creator modal
    PostCreatorHelper.showPostCreator(
      context,
      onPostCreated: (postData) async {
        // Handle the created post data
        if (postData['text'].isNotEmpty || postData['media'].isNotEmpty) {
          // Create the post using the existing post service
          await _createPostFromData(postData);
          // Navigate back to home feed to refresh
          Navigator.pop(context, {'refresh': true});
        }
      },
      onClose: () {
        // Handle modal close if needed
      },
    );
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

  void _navigateToCreateReel() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateReelScreen()),
    );
  }

  void _navigateToAICreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AICreateScreen()),
    );
  }

  void _navigateToSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SchedulePostScreen()),
    );
  }

  void _navigateToCreateOption(Map<String, dynamic> option) {
    if (option['id'] == 'story') {
      // Show Facebook-style story creator modal
      StoryCreatorHelper.showStoryCreator(
        context,
        onStoryCreated: (storyData) async {
          // Handle the created story data
          if (storyData['media'].isNotEmpty || storyData['text'].isNotEmpty) {
            // Create the story using the existing story service
            await _createStoryFromData(storyData);
            // Navigate back to home feed to refresh
            Navigator.pop(context, {'refresh': true});
          }
        },
        onClose: () {
          // Handle modal close if needed
        },
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => option['screen'] as Widget),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Create',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Choose what you'd like to create and share with your community",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: Icon(Icons.image, color: theme.colorScheme.primary),
                  label: Text('Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 15),
                    side: BorderSide(color: theme.dividerColor),
                    backgroundColor: theme.cardColor,
                  ),
                  onPressed: _navigateToCreatePost,
                ),
                OutlinedButton.icon(
                  icon:
                      Icon(Icons.videocam, color: theme.colorScheme.secondary),
                  label: Text('Video'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 15),
                    side: BorderSide(color: theme.dividerColor),
                    backgroundColor: theme.cardColor,
                  ),
                  onPressed: _navigateToCreateReel,
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.auto_awesome, color: Colors.pink),
                  label: Text('AI Create'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 15),
                    side: BorderSide(color: theme.dividerColor),
                    backgroundColor: theme.cardColor,
                  ),
                  onPressed: _navigateToAICreate,
                ),
                OutlinedButton.icon(
                  icon: Icon(Icons.schedule, color: Colors.orange),
                  label: Text('Schedule'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    textStyle: const TextStyle(fontSize: 15),
                    side: BorderSide(color: theme.dividerColor),
                    backgroundColor: theme.cardColor,
                  ),
                  onPressed: _navigateToSchedule,
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Privacy Setting
            Text(
              'Default Privacy',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: privacyOptions.map((option) {
                final isSelected =
                    selectedPrivacy == (option['label'] as String);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedPrivacy = option['label'] as String;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: 2,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: theme.colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(option['icon'] as IconData,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6)),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(option['label'] as String,
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500)),
                            Text(option['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7))),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Create Options Grid
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 4
                  : MediaQuery.of(context).size.width > 800
                      ? 3
                      : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: createOptions.map((option) {
                final isHovered = hoveredOption == (option['id'] as String);
                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      hoveredOption = option['id'] as String;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      hoveredOption = null;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: isHovered
                        ? (Matrix4.identity()..scale(1.05))
                        : Matrix4.identity(),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        if (isHovered)
                          BoxShadow(
                            color: theme.shadowColor.withOpacity(0.08),
                            blurRadius: 12,
                          ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: (option['color'] as Color)
                                        .withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(option['icon'] as IconData,
                                      color: Colors.white, size: 24),
                                ),
                                if (option['badge'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: option['badge'] == 'New'
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.pink.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      option['badge'] as String,
                                      style: TextStyle(
                                        color: option['badge'] == 'New'
                                            ? Colors.green
                                            : Colors.pink,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(option['title'] as String,
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(option['description'] as String,
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.textTheme.bodySmall?.color
                                        ?.withOpacity(0.7))),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: (option['features'] as List)
                                  .map<Widget>((feature) => Chip(
                                        label: Text(feature as String,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(fontSize: 11)),
                                        backgroundColor:
                                            theme.dividerColor.withOpacity(0.1),
                                      ))
                                  .toList(),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: () => _navigateToCreateOption(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (option['isMain'] == true)
                                    ? theme.colorScheme.primary
                                    : theme.cardColor,
                                foregroundColor: (option['isMain'] == true)
                                    ? theme.colorScheme.onPrimary
                                    : theme.textTheme.bodyLarge?.color,
                                minimumSize: const Size.fromHeight(36),
                                side: (option['isMain'] == true)
                                    ? null
                                    : BorderSide(color: theme.dividerColor),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Flexible(
                                    child: Text(
                                      'Get Started',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.chevron_right),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 48),
            // Templates Section
            LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 600;
                return isSmallScreen
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Popular Templates',
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Get started quickly with pre-made templates',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withOpacity(0.7))),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Popular Templates',
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(
                                  'Get started quickly with pre-made templates',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.textTheme.bodySmall?.color
                                          ?.withOpacity(0.7))),
                            ],
                          ),
                          OutlinedButton(
                            onPressed: () {},
                            child: const Text('View All'),
                          ),
                        ],
                      );
              },
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
              children: [
                'Story Template',
                'Post Layout',
                'Reel Format',
                'Event Banner',
              ].map((template) {
                return Card(
                  elevation: theme.cardTheme.elevation,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary.withOpacity(0.2),
                                theme.colorScheme.secondary.withOpacity(0.2)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.auto_awesome,
                              color: theme.colorScheme.secondary, size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text(template,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('Ready to use',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7))),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
