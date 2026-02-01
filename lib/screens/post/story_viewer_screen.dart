import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:story_view/story_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:gamer_flick/models/core/user_with_stories.dart';
import 'package:gamer_flick/models/post/story.dart';

class StoryViewerScreen extends StatefulWidget {
  final List<UserWithStories> usersWithStories;
  final int initialUserIndex;

  const StoryViewerScreen({
    super.key,
    required this.usersWithStories,
    required this.initialUserIndex,
  });

  @override
  StoryViewerScreenState createState() => StoryViewerScreenState();
}

class StoryViewerScreenState extends State<StoryViewerScreen> {
  late PageController _pageController;
  final Map<String, StoryController> _storyControllers = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialUserIndex);
    for (var userWithStories in widget.usersWithStories) {
      _storyControllers[userWithStories.user.id] = StoryController();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _storyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.usersWithStories.length,
        itemBuilder: (context, index) {
          final userWithStories = widget.usersWithStories[index];
          final userId = userWithStories.user.id;

          return FutureBuilder<List<Story>>(
            future: _fetchUserStories(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child: CircularProgressIndicator(
                        color: theme.colorScheme.primary));
              }
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.of(context).pop();
                });
                return Center(
                    child: Text("Could not load stories.",
                        style: TextStyle(color: theme.colorScheme.onSurface)));
              }

              final stories = snapshot.data!;

              // Ensure StoryController exists
              if (!_storyControllers.containsKey(userId)) {
                _storyControllers[userId] = StoryController();
              }

              // Debug: Print story data
              print(
                  'Stories for user $userId: ${stories.map((s) => '${s.id}: mediaUrl=${s.mediaUrl}, content=${s.content}').join(', ')}');

              final storyItems = stories
                  .where((story) {
                    // Include stories with either media or text content
                    return (story.mediaUrl?.isNotEmpty == true) ||
                        (story.content.isNotEmpty == true);
                  })
                  .map((story) {
                    final storyController = _storyControllers[userId]!;

                    // Handle text-only stories
                    if (story.content.isNotEmpty == true &&
                        (story.mediaUrl?.isEmpty ?? true)) {
                      return StoryItem.text(
                        title: story.content,
                        backgroundColor: theme.colorScheme.surface,
                        textStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }

                    // Handle media stories
                    String url = story.mediaUrl ?? '';
                    if (url.isEmpty) return null;

                    try {
                      Uri uri = Uri.parse(url);
                      String path = uri.path;
                      String ext = path.split('.').last.toLowerCase();

                      const videoExts = ['mp4', 'webm'];
                      const unsupportedVideoExts = ['mov', 'quicktime'];
                      const imageExts = [
                        'jpg',
                        'jpeg',
                        'png',
                        'gif',
                        'bmp',
                        'webp'
                      ];

                      if (videoExts.contains(ext)) {
                        var videoUrl = url;
                        if (kIsWeb) {
                          videoUrl = '$videoUrl?name=video.mp4';
                        }
                        return StoryItem.pageVideo(
                          videoUrl,
                          key: ValueKey(videoUrl),
                          controller: storyController,
                          duration: const Duration(seconds: 15),
                        );
                      } else if (unsupportedVideoExts.contains(ext)) {
                        return StoryItem.text(
                          title: "Unsupported video format",
                          backgroundColor: theme.colorScheme.surface,
                          textStyle:
                              TextStyle(color: theme.colorScheme.onSurface),
                        );
                      } else if (imageExts.contains(ext)) {
                        return StoryItem.pageImage(
                          key: ValueKey(url),
                          url: url,
                          controller: storyController,
                        );
                      } else {
                        return StoryItem.text(
                          title: "Unsupported media type",
                          backgroundColor: theme.colorScheme.surface,
                          textStyle:
                              TextStyle(color: theme.colorScheme.onSurface),
                        );
                      }
                    } catch (e) {
                      print('Error parsing media URL: $e for URL: $url');
                      // Return null for invalid URLs
                      return null;
                    }
                  })
                  .where((item) => item != null)
                  .cast<StoryItem>()
                  .toList();

              // Check if storyItems is empty after filtering
              if (storyItems.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) Navigator.of(context).pop();
                });
                return Center(
                  child: Text(
                    "No valid stories found.",
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                );
              }

              return GestureDetector(
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity! > 500) {
                    Navigator.of(context).pop();
                  }
                },
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 700,
                    ),
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: StoryView(
                        storyItems: storyItems,
                        controller: _storyControllers[userId]!,
                        onComplete: () {
                          if (index < widget.usersWithStories.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeIn,
                            );
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                        inline: false,
                        repeat: false,
                        onStoryShow: (storyItem, index) {
                          // Optional: Add logging to debug story display
                          print(
                              'Showing story item at index $index: ${storyItem.hashCode}');
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Story>> _fetchUserStories(String userId) async {
    final response = await Supabase.instance.client
        .from('stories')
        .select()
        .eq('user_id', userId)
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: true);
    return (response as List)
        .map((e) => Story.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
