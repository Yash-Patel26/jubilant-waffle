import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'reel_detail_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/chat/conversation_providers.dart';
import '../../widgets/shared_content_selection_dialog.dart';

class ExploreReelsScreen extends ConsumerStatefulWidget {
  final String? initialReelId; // Add this parameter

  const ExploreReelsScreen(
      {super.key, this.initialReelId}); // Update constructor

  @override
  ConsumerState<ExploreReelsScreen> createState() => _ExploreReelsScreenState();
}

class _ExploreReelsScreenState extends ConsumerState<ExploreReelsScreen> {
  late final Future<List<Map<String, dynamic>>> _reelsFuture;

  @override
  void initState() {
    super.initState();
    _reelsFuture = _fetchReels();
    // TODO: Implement logic to jump to initialReelId if provided
  }

  Future<List<Map<String, dynamic>>> _fetchReels() async {
    final response = await Supabase.instance.client
        .from('reels')
        .select(
            '*, profiles!reels_user_id_fkey(*), reel_likes(user_id), reel_comments(id)')
        .order('created_at', ascending: false);

    return (response as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Reels'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final reels = snapshot.data;
          if (reels == null || reels.isEmpty) {
            return const Center(child: Text('No reels to show.'));
          }

          return PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: reels.length,
            itemBuilder: (context, index) {
              final reel = reels[index];
              return ReelPlayer(
                reelData: reel,
                onMessageSent: () {
                  if (userId != null) {
                    ref.refresh(conversationListProvider(userId));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ReelPlayer extends StatefulWidget {
  final Map<String, dynamic> reelData;
  final VoidCallback? onMessageSent;
  const ReelPlayer({super.key, required this.reelData, this.onMessageSent});

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late VideoPlayerController _controller;
  bool _isPlaying = true;
  late bool _isLiked;
  late int _likeCount;
  bool _showHeart = false;
  bool _isVideoMuted = true; // Start muted by default

  @override
  void initState() {
    super.initState();
    final List<dynamic> likes = widget.reelData['reel_likes'] ?? [];
    _likeCount = likes.length;
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _isLiked = likes.any((like) => like['user_id'] == currentUser.id);
    } else {
      _isLiked = false;
    }

    _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reelData['video_url']))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
        _controller.setLooping(true);
        _controller.setVolume(_isVideoMuted ? 0.0 : 1.0);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  Future<void> _toggleLike() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // First, ensure the user has a profile record
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (profile == null) {
        throw Exception(
            'User profile not found. Please complete your profile setup.');
      }

      // Check the current database state to ensure UI is in sync
      final existingLike = await Supabase.instance.client
          .from('reel_likes')
          .select('user_id')
          .eq('reel_id', widget.reelData['id'])
          .eq('user_id', currentUser.id)
          .maybeSingle();

      final isCurrentlyLikedInDB = existingLike != null;

      // If UI state doesn't match database state, sync it first
      if (_isLiked != isCurrentlyLikedInDB) {
        print('UI state out of sync with database. Syncing...');
        setState(() {
          _isLiked = isCurrentlyLikedInDB;
          _likeCount = isCurrentlyLikedInDB ? _likeCount + 1 : _likeCount - 1;
        });
        return; // Exit early, let user try again
      }

      // Now perform the toggle operation based on current database state
      if (isCurrentlyLikedInDB) {
        // User is unliking the reel - DELETE
        final result =
            await Supabase.instance.client.from('reel_likes').delete().match({
          'user_id': currentUser.id,
          'reel_id': widget.reelData['id'],
        }).select();

        // Check if the delete operation affected any rows
        if (result.isEmpty) {
          print('Warning: Attempted to unlike a reel that was not liked');
        }

        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // User is liking the reel - INSERT
        await Supabase.instance.client.from('reel_likes').insert({
          'user_id': currentUser.id,
          'reel_id': widget.reelData['id'],
        });

        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      print('Error in _toggleLike (explore reels): $e');

      // Show error message to user
      if (mounted) {
        String errorMessage = 'Failed to update like status';
        if (e.toString().contains('profile not found')) {
          errorMessage = 'Please complete your profile setup first';
        } else if (e.toString().contains('duplicate key') ||
            e.toString().contains('23505')) {
          errorMessage = 'You have already liked this reel';
          // Refresh the like state from database
          _refreshLikeState();
        } else if (e.toString().contains('foreign key')) {
          errorMessage = 'Invalid reel or user reference';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshLikeState() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final likes = widget.reelData['reel_likes'] ?? [];
      final isLikedByCurrentUser =
          likes.any((like) => like['user_id'] == currentUser.id);

      if (mounted) {
        setState(() {
          _likeCount = likes.length;
          _isLiked = isLikedByCurrentUser;
        });
      }
    } catch (e) {
      print('Error refreshing like state: $e');
    }
  }

  Future<void> _triggerHeartAnimation() async {
    setState(() => _showHeart = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _showHeart = false);
  }

  void _onDoubleTapLike() {
    if (!_isLiked) {
      _toggleLike();
    }
    _triggerHeartAnimation();
  }

  void _toggleVideoMute() {
    setState(() {
      _isVideoMuted = !_isVideoMuted;
      _controller.setVolume(_isVideoMuted ? 0.0 : 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: _onDoubleTapLike,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video with proper aspect ratio and responsive design
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio > 0
                    ? _controller.value.aspectRatio
                    : 9 / 16, // Fallback to Instagram Reels aspect ratio
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller),
                    AnimatedOpacity(
                      opacity: _showHeart ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedScale(
                        scale: _showHeart ? 1.5 : 0.8,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.white.withOpacity(0.85),
                          size: 96,
                          shadows: [
                            Shadow(
                              blurRadius: 24,
                              color: Colors.black.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 2),
                  ),
                  child: const Icon(Icons.play_arrow,
                      size: 48, color: Colors.white),
                ),
              ),
            // Mute/Unmute Button - improved positioning
            Positioned(
              top: MediaQuery.of(context).padding.top + 20,
              right: 20,
              child: GestureDetector(
                onTap: _toggleVideoMute,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: Icon(
                    _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            _buildVideoDetails(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoDetails() {
    final profile = widget.reelData['profiles'];
    final username = profile != null ? profile['username'] : 'Unknown';
    final caption = widget.reelData['caption'] ?? '';

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      left: 20,
      right: 100, // Ensure text doesn't overlap with action buttons
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: profile?['profile_picture_url'] != null
                      ? NetworkImage(profile!['profile_picture_url'])
                      : null,
                  child: profile?['profile_picture_url'] == null
                      ? const Icon(Icons.person, color: Colors.white, size: 20)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '@$username',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Follow',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Text(
                caption,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 2, color: Colors.black)],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.music_note, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Original Audio',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  shadows: [
                    Shadow(blurRadius: 1, color: Colors.black),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final commentCount = widget.reelData['reel_comments']?.length ?? 0;

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 120,
      right: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: _isLiked ? Icons.favorite : Icons.favorite_border,
            count: _likeCount,
            onTap: _toggleLike,
            isLiked: _isLiked,
          ),
          const SizedBox(height: 24),
          _buildActionButton(
            icon: Icons.chat_bubble_outline,
            count: commentCount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReelDetailScreen(reel: widget.reelData),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
    bool isLiked = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          shape: BoxShape.circle,
        ),
        child: Column(
          children: [
            Icon(icon, color: isLiked ? Colors.red : Colors.white, size: 28),
            if (count > 0) ...[
              const SizedBox(height: 4),
              Text(
                _formatCount(count),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
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

  void _shareReel() {
    showDialog(
      context: context,
      builder: (context) => SharedContentSelectionDialog(
        contentId: widget.reelData['id'],
        contentType: 'reel',
        onShared: () {
          // Refresh the reel to update share count
          setState(() {});
        },
      ),
    );
  }
}
