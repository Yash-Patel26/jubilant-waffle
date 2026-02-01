import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:gamer_flick/providers/content/reel_provider.dart';
import 'package:gamer_flick/models/post/reel.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
import 'package:gamer_flick/repositories/reels/reels_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/reel_text_overlay.dart';
import '../../widgets/shared_content_selection_dialog.dart';
import '../../utils/time_utils.dart';

class ReelsScreen extends ConsumerStatefulWidget {
  const ReelsScreen({super.key});

  @override
  ConsumerState<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends ConsumerState<ReelsScreen> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _videoControllers = {};
  final Map<int, bool> _isPlaying = {};
  final Map<int, bool> _isMuted = {};
  final Map<int, bool> _showHeart = {};
  final TextEditingController _sidebarCommentController =
      TextEditingController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    _sidebarCommentController.dispose();
    super.dispose();
  }

  void _initializeVideoController(int index, String videoUrl) async {
    if (videoUrl.isEmpty) return;
    if (_videoControllers[index] != null) {
      _videoControllers[index]!.dispose();
    }
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      _videoControllers[index] = controller;
      await controller.initialize();
      await controller.setLooping(true);
      // Respect current mute state when initializing
      if ((_isMuted[index] ?? false) == true) {
        controller.setVolume(0.0);
      }
      if (mounted) {
        setState(() {
          _isPlaying[index] = false;
          _isMuted[index] = false;
        });
      }
    } catch (e) {
      print('Error initializing video controller for index $index: $e');
    }
  }

  void _cleanupControllersAround(int centerIndex) {
    final allowed = {centerIndex - 1, centerIndex, centerIndex + 1};
    final keysToRemove = _videoControllers.keys
        .where((k) => !allowed.contains(k))
        .toList(growable: false);
    for (final key in keysToRemove) {
      try {
        _videoControllers[key]?.dispose();
      } catch (_) {}
      _videoControllers.remove(key);
      _isPlaying.remove(key);
      _isMuted.remove(key);
      _showHeart.remove(key);
    }
  }

  void _playVideo(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isInitialized) {
      if (_isPlaying[index] == true) {
        controller.pause();
        setState(() {
          _isPlaying[index] = false;
        });
      } else {
        controller.play();
        setState(() {
          _isPlaying[index] = true;
        });
      }
    }
  }

  void _onPageChanged(int index) {
    // Update controllers and state for the new page
    for (int i = 0; i < _videoControllers.length; i++) {
      if (i != index && _videoControllers[i] != null) {
        _videoControllers[i]!.pause();
        _isPlaying[i] = false;
      }
    }
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isInitialized) {
      controller.play();
      setState(() {
        _isPlaying[index] = true;
        _currentIndex = index;
      });
    }

    // Preload neighboring videos and cleanup far ones
    final reels = ref.read(reelProvider).value;
    if (reels != null && reels.isNotEmpty) {
      if (index + 1 < reels.length && _videoControllers[index + 1] == null) {
        _initializeVideoController(index + 1, reels[index + 1].videoUrl);
      }
      if (index - 1 >= 0 && _videoControllers[index - 1] == null) {
        _initializeVideoController(index - 1, reels[index - 1].videoUrl);
      }
      _cleanupControllersAround(index);
    }
  }

  void _toggleMute(int index) {
    final controller = _videoControllers[index];
    if (controller != null && controller.value.isInitialized) {
      final isCurrentlyMuted = _isMuted[index] ?? false;
      controller.setVolume(isCurrentlyMuted ? 1.0 : 0.0);
      setState(() {
        _isMuted[index] = !isCurrentlyMuted;
      });
    }
  }

  void _toggleLike(int index) async {
    try {
      final reels = ref.read(reelProvider).value;
      if (reels == null || index >= reels.length) return;

      final reel = reels[index];
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final success = await ref.read(reelsRepositoryProvider).toggleLike(reel.id, currentUser.id);
      
      if (success) {
        ref.invalidate(reelProvider);
      }
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  void _showComments(int index) {
    final reels = ref.read(reelProvider).value;
    if (reels == null || index >= reels.length) return;

    final reel = reels[index];
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey, width: 0.5)),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getComments(reel.id),
                  builder: (context, snapshot) {
                    final comments = snapshot.data ?? [];

                    return comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text('${reel.commentCount ?? 0} comments',
                                    style: const TextStyle(
                                        fontSize: 16, color: Colors.grey)),
                                const SizedBox(height: 8),
                                const Text(
                                    'No comments yet. Be the first to comment!',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: comments.length,
                            itemBuilder: (context, commentIndex) {
                              final comment = comments[commentIndex];
                              final user =
                                  comment['user'] as Map<String, dynamic>?;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundImage:
                                          user?['profile_picture_url'] != null
                                              ? NetworkImage(
                                                  user!['profile_picture_url'])
                                              : null,
                                      child: user?['profile_picture_url'] ==
                                              null
                                          ? const Icon(Icons.person, size: 16)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                  user?['username'] ??
                                                      'Unknown',
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14)),
                                              const SizedBox(width: 8),
                                              Text(
                                                  _formatTimeAgo(DateTime.parse(
                                                      comment['created_at'])),
                                                  style: const TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 12)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(comment['content'] ?? '',
                                              style: const TextStyle(
                                                  fontSize: 14)),
                                        ],
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Colors.grey, width: 0.5))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) =>
                            _addComment(reel.id, commentController),
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatefulBuilder(
                      builder: (context, setModalState) {
                        return IconButton(
                          onPressed: () async {
                            setModalState(() {});
                            await _addComment(reel.id, commentController);
                          },
                          icon: const Icon(Icons.send),
                          color: Colors.blue,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getComments(String reelId) async {
    return ref.read(reelsRepositoryProvider).getComments(reelId);
  }

  Future<void> _addComment(
      String reelId, TextEditingController controller) async {
    if (controller.text.trim().isEmpty) return;

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final success = await ref.read(reelsRepositoryProvider).addComment(
        reelId,
        currentUser.id,
        controller.text.trim(),
      );

      if (success) {
        controller.clear();
        ref.invalidate(reelProvider);
        if (mounted) setState(() {});
      }
    } catch (e) {
      print('Error adding comment: $e');
    }
  }

  Widget _buildCommentsSidebar(Reel reel) {
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            alignment: Alignment.centerLeft,
            child: const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getComments(reel.id),
              builder: (context, snapshot) {
                final comments = snapshot.data ?? [];
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.chat_bubble_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No comments yet',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final comment = comments[i];
                    final user = comment['user'] as Map<String, dynamic>?;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: user?['profile_picture_url'] != null
                              ? NetworkImage(user!['profile_picture_url'])
                              : null,
                          child: user?['profile_picture_url'] == null
                              ? const Icon(Icons.person, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    user?['username'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTimeAgo(
                                        DateTime.parse(comment['created_at'])),
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(comment['content'] ?? '',
                                  style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _sidebarCommentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) async {
                      await _addComment(reel.id, _sidebarCommentController);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    await _addComment(reel.id, _sidebarCommentController);
                  },
                  icon: const Icon(Icons.send, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareReel(int index) {
    final reels = ref.read(reelProvider).value;
    if (reels == null || index >= reels.length) return;

    final reel = reels[index];
    // Debug log for tracing share dialog entry
    print(
        'ReelsScreen:_shareReel open dialog for reelId=${reel.id} index=$index');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => SharedContentSelectionDialog(
          contentId: reel.id,
          contentType: 'reel',
          onShared: () {
            // Refresh the reel to update share count
            setState(() {});
          },
        ),
      );
    });
  }

  void _showReelOptions(int index) {
    final reels = ref.read(reelProvider).value;
    if (reels == null || index >= reels.length) return;

    final reel = reels[index];
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwner = currentUser?.id == reel.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Reel'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit reel screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Reel',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteReel(reel);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Report Reel'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog(reel);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Reel'),
              onTap: () {
                Navigator.pop(context);
                _shareReel(index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(
                    ClipboardData(text: 'https://yourapp.com/reel/${reel.id}'));
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link copied!')));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(dynamic reel) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Reel'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for reporting this reel:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for report...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reportReel(reel, reasonController.text);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReel(dynamic reel) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      final success = await ref.read(reelsRepositoryProvider).deleteReel(reel.id, currentUser.id);

      if (success) {
        ref.invalidate(reelProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete reel');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reportReel(dynamic reel, String reason) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final success = await ref.read(reelsRepositoryProvider).reportReel(
        reelId: reel.id,
        userId: currentUser.id,
        reason: reason,
        details: '', // Empty details for now
      );

      if (success) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reel reported successfully')),
        );
      } else {
        throw Exception('Failed to report reel');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error reporting reel: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildVideoPlayer(int index, Reel reel) {
    if (_videoControllers[index] != null &&
        _videoControllers[index]!.value.isInitialized) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _playVideo(index),
        onDoubleTap: () async {
          HapticFeedback.lightImpact();
          _toggleLike(index);
          setState(() => _showHeart[index] = true);
          await Future.delayed(const Duration(milliseconds: 650));
          if (mounted) setState(() => _showHeart[index] = false);
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final controller = _videoControllers[index]!;
            final videoSize = controller.value.size;
            return Stack(
              fit: StackFit.expand,
              children: [
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: videoSize.width,
                    height: videoSize.height,
                    child: VideoPlayer(controller),
                  ),
                ),
                if (!_isPlaying[index]!)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _showHeart[index] == true ? 1.0 : 0.0,
                    child: const Icon(Icons.favorite,
                        color: Colors.white, size: 96),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: VideoProgressIndicator(
                    controller,
                    allowScrubbing: true,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    colors: VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white54,
                      backgroundColor: Colors.white24,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _playVideo(index),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(color: Colors.grey[900]),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_outline,
                    size: 64, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  reel.caption ?? 'No caption',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  List<TextOverlayItem>? _parseTextOverlaysFromMetadata(
      Reel reel, Size viewportSize) {
    final metadata = reel.metadata;
    if (metadata == null) return null;
    final overlaysRaw = metadata['text_overlays'];
    if (overlaysRaw is! List) return null;

    final List<TextOverlayItem> items = [];
    for (final item in overlaysRaw) {
      if (item is Map) {
        final map = item.cast<String, dynamic>();
        final String text = (map['text'] ?? '').toString();
        if (text.isEmpty) continue;
        // Support absolute pixel positions and normalized fractions (x,y in 0..1)
        double? top =
            (map['top'] is num) ? (map['top'] as num).toDouble() : null;
        double? left =
            (map['left'] is num) ? (map['left'] as num).toDouble() : null;
        final double? yFrac =
            (map['y'] is num) ? (map['y'] as num).toDouble() : null;
        final double? xFrac =
            (map['x'] is num) ? (map['x'] as num).toDouble() : null;
        if (yFrac != null) top = yFrac * viewportSize.height;
        if (xFrac != null) left = xFrac * viewportSize.width;
        final double? right =
            (map['right'] is num) ? (map['right'] as num).toDouble() : null;
        final double? bottom =
            (map['bottom'] is num) ? (map['bottom'] as num).toDouble() : null;
        final String? styleName = map['style'] as String?;

        final textStyle = switch (styleName) {
          'pink' => ReelTextOverlayStyles.pinkTextStyle,
          'watermark' => ReelTextOverlayStyles.watermarkStyle,
          _ => ReelTextOverlayStyles.whiteTextStyle,
        };

        items.add(TextOverlayItem(
          text: text,
          top: top,
          left: left,
          right: right,
          bottom: bottom,
          textStyle: textStyle,
        ));
      }
    }
    return items.isEmpty ? null : items;
  }

  Widget _buildReelPlayer(Reel reel, int index) {
    if (_videoControllers[index] == null) {
      _initializeVideoController(index, reel.videoUrl);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: Stack(
        children: [
          // Video Player
          _buildVideoPlayer(index, reel),

          // Top/bottom gradients for better text readability
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: true,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [Colors.black54, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Top Bar (responsive)
          Builder(builder: (context) {
            final bool isWide = MediaQuery.of(context).size.width >= 1000;
            if (isWide) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 20,
                child: GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Create new reel')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            } else {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    const Text(
                      'Reels',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    // Only show overflow on mobile; remove duplicate from action rail
                    IconButton(
                      padding: const EdgeInsets.all(6),
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () => _showReelOptions(index),
                    ),
                  ],
                ),
              );
            }
          }),

          // Mute button (responsive)
          Builder(builder: (context) {
            final bool isWide = MediaQuery.of(context).size.width >= 1000;
            if (isWide) {
              return Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 80,
                child: GestureDetector(
                  onTap: () => _toggleMute(index),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted[index] == true
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            } else {
              return Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 72,
                right: 16,
                child: GestureDetector(
                  onTap: () => _toggleMute(index),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isMuted[index] == true
                          ? Icons.volume_off
                          : Icons.volume_up,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              );
            }
          }),

          // Creator info (bottom left) - Instagram-style layout
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 100,
            left: 16,
            right: 80, // Ensure text doesn't overlap with action buttons
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Creator profile row
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: reel.user?['profile_picture_url'] !=
                                null
                            ? NetworkImage(reel.user!['profile_picture_url'])
                            : null,
                        child: reel.user?['profile_picture_url'] == null
                            ? const Icon(Icons.person,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reel.user?['username'] ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 2,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Follow/Unfollow button (owner hidden)
                          _FollowAction(userId: reel.userId),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Caption
                if (reel.caption != null && reel.caption!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: Text(
                      reel.caption!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        shadows: [
                          Shadow(
                            blurRadius: 2,
                            color: Colors.black,
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),

                // Audio information
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.music_note,
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Original Audio',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        shadows: [
                          Shadow(
                            blurRadius: 1,
                            color: Colors.black,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Interaction buttons (right side) - responsive sizing
          Builder(builder: (context) {
            final bool isWide = MediaQuery.of(context).size.width >= 1000;
            final double iconSize = isWide ? 28 : 22;
            final double spacing = isWide ? 20 : 14;
            final double bottomOffset =
                MediaQuery.of(context).padding.bottom + (isWide ? 100 : 84);
            return Positioned(
              bottom: bottomOffset,
              right: 16,
              child: Column(
                children: [
                  _buildInteractionButton(
                    icon: reel.isLiked == true
                        ? Icons.favorite
                        : Icons.favorite_border,
                    count: reel.likeCount ?? 0,
                    onTap: () => _toggleLike(index),
                    isLiked: reel.isLiked == true,
                    iconSize: iconSize,
                    labelFontSize: isWide ? 12 : 10,
                  ),
                  SizedBox(height: spacing),
                  _buildInteractionButton(
                    icon: Icons.chat_bubble_outline,
                    count: reel.commentCount ?? 0,
                    onTap: () => _showComments(index),
                    iconSize: iconSize,
                    labelFontSize: isWide ? 12 : 10,
                  ),
                  SizedBox(height: spacing),
                  _buildInteractionButton(
                    icon: Icons.send,
                    count: reel.shareCount ?? 0,
                    onTap: () => _shareReel(index),
                    iconSize: iconSize,
                    labelFontSize: isWide ? 12 : 10,
                  ),
                  SizedBox(height: spacing),
                  _buildInteractionButton(
                    icon: Icons.bookmark_border,
                    count: 0,
                    onTap: () {},
                    iconSize: iconSize,
                    labelFontSize: isWide ? 12 : 10,
                  ),
                  SizedBox(height: spacing),
                  if (isWide)
                    _buildInteractionButton(
                      icon: Icons.more_vert,
                      count: 0,
                      onTap: () => _showReelOptions(index),
                      iconSize: iconSize,
                      labelFontSize: isWide ? 12 : 10,
                    ),
                ],
              ),
            );
          }),

          // User's profile picture at bottom right (responsive sizing)
          Builder(builder: (context) {
            final bool isWide = MediaQuery.of(context).size.width >= 1000;
            final double size = isWide ? 40 : 32;
            final double radius = isWide ? 18 : 14;
            return Positioned(
              bottom:
                  MediaQuery.of(context).padding.bottom + (isWide ? 20 : 16),
              right: 16,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: radius,
                  backgroundImage: Supabase.instance.client.auth.currentUser
                              ?.userMetadata?['profile_picture_url'] !=
                          null
                      ? NetworkImage(Supabase.instance.client.auth.currentUser!
                          .userMetadata!['profile_picture_url'])
                      : null,
                  child: Supabase.instance.client.auth.currentUser
                              ?.userMetadata?['profile_picture_url'] ==
                          null
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
              ),
            );
          }),

          // Text overlays resolved from metadata, if provided
          if (_parseTextOverlaysFromMetadata(reel, MediaQuery.of(context).size)
              case final overlays?)
            ReelTextOverlay(textOverlays: overlays, isVisible: true),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    bool isLiked = false,
    double iconSize = 28,
    double labelFontSize = 12,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Icon(icon,
                color: isLiked ? Colors.red : Colors.white, size: iconSize),
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: labelFontSize,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      blurRadius: 1,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    } else {
      return count.toString();
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    return TimeUtils.formatTimeAgoIST(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final reelsAsync = ref.watch(reelProvider);

    return reelsAsync.when(
      loading: () => Scaffold(
        backgroundColor: Colors.black,
        body:
            const Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              Text('Error: $err', style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
      data: (reels) {
        if (reels.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_library, size: 64, color: Colors.white),
                  SizedBox(height: 16),
                  Text('No reels to show',
                      style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 1000;
              if (!isWide) {
                return PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  onPageChanged: _onPageChanged,
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    return _buildReelPlayer(reels[index], index);
                  },
                );
              }
              // Wide layout: video on left, comments on right
              return Row(
                children: [
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, left) {
                        final double maxDesiredWidth = 720;
                        final double minDesiredWidth = 420;
                        final double available =
                            left.maxWidth - 48; // padding margins
                        final double targetWidth =
                            available.clamp(minDesiredWidth, maxDesiredWidth);
                        return Center(
                          child: Container(
                            width: targetWidth,
                            height: left.maxHeight,
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: PageView.builder(
                              controller: _pageController,
                              scrollDirection: Axis.vertical,
                              onPageChanged: _onPageChanged,
                              itemCount: reels.length,
                              itemBuilder: (context, index) {
                                return _buildReelPlayer(reels[index], index);
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildCommentsSidebar(reels[_currentIndex]),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _FollowAction extends ConsumerStatefulWidget {
  final String userId;
  const _FollowAction({required this.userId});

  @override
  ConsumerState<_FollowAction> createState() => _FollowActionState();
}

class _FollowActionState extends ConsumerState<_FollowAction> {
  bool _loading = false;
  bool? _isFollowing;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;
    if (currentUser.id == widget.userId) {
      // Owner: hide
      setState(() => _isFollowing = null);
      return;
    }
    final isFollowing = await ref.read(userRepositoryProvider).isFollowing(widget.userId);
    if (mounted) setState(() => _isFollowing = isFollowing);
  }

  Future<void> _toggle() async {
    if (_isFollowing == null) return; // hidden
    setState(() => _loading = true);
    final repo = ref.read(userRepositoryProvider);
    bool ok;
    if (_isFollowing == true) {
      ok = await repo.unfollowUser(widget.userId);
    } else {
      ok = await repo.followUser(widget.userId);
    }
    if (mounted) {
      setState(() {
        _loading = false;
        if (ok) _isFollowing = !(_isFollowing ?? false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFollowing == null) return const SizedBox.shrink();
    final bool following = _isFollowing == true;
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: following ? Colors.white : Colors.transparent,
          border: Border.all(color: Colors.white, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: _loading
            ? const SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(
                following ? 'Unfollow' : 'Follow',
                style: TextStyle(
                  color: following ? Colors.black : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
