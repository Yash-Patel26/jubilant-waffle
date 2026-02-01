import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../screens/post/comment_screen.dart';
import 'package:video_player/video_player.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/post/post_detail_screen.dart';
import '../../screens/post/create_post_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/core/profile.dart';
import '../../utils/time_utils.dart';
import '../../widgets/shared_content_selection_dialog.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onPostDeleted;

  const PostCard({super.key, required this.post, this.onPostDeleted});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  RealtimeChannel? _likeChannel;
  int _commentCount = 0;
  final User? _currentUser = Supabase.instance.client.auth.currentUser;
  VideoPlayerController? _videoController;

  bool _showHeart = false;
  bool _isLikeInProgress = false;
  bool _isSaved = false;
  bool _isVideoMuted = true;
  bool _isShowingShareDialog = false;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount ?? 0;
    // For now, we'll use a simple approach since likes data isn't loaded
    _isLiked = false;
    _subscribeToLikes();
    _fetchCommentCount();
    _initializeVideoController();
  }

  void _initializeVideoController() {
    final mediaUrl =
        (widget.post.mediaUrls != null && widget.post.mediaUrls!.isNotEmpty)
            ? widget.post.mediaUrls!.first
            : null;

    if (mediaUrl != null &&
        (mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov'))) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
          }
        });
    }
  }

  @override
  void dispose() {
    _likeChannel?.unsubscribe();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    if (widget.post.user == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenWidth < 600 ? screenWidth - 16 : 500,
        ),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: screenWidth < 600 ? 4 : 8,
          ),
          child: Padding(
            padding: EdgeInsets.all(screenWidth < 600 ? 8.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, widget.post.user!),
                const SizedBox(height: 8),
                _buildMedia(),
                _buildActionButtons(context),
                _buildFooter(context, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Profile profile) {
    final avatarUrl = profile
        .profilePicture; // Use the getter that handles both avatar_url and profile_picture_url
    final isOwner = _currentUser?.id == profile.id;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 8.0 : 12.0,
        vertical: isSmallScreen ? 6.0 : 8.0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileScreen(userId: profile.id),
              ),
            ),
            child: CircleAvatar(
              radius: isSmallScreen ? 20 : 24,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(Icons.person, size: isSmallScreen ? 20 : 24)
                  : null,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              profile.username,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isOwner)
            IconButton(
              icon: Icon(
                Icons.more_horiz,
                size: isSmallScreen ? 20 : 24,
              ),
              onPressed: () => _showOptionsBottomSheet(context),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final mediaUrl =
        (widget.post.mediaUrls != null && widget.post.mediaUrls!.isNotEmpty)
            ? widget.post.mediaUrls!.first
            : null;

    if (mediaUrl == null || mediaUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    final isVideo = mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov');

    Widget mediaWidget = isVideo
        ? (_videoController != null && _videoController!.value.isInitialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Make video cover the available box like Instagram
                  FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController!.value.size.width,
                      height: _videoController!.value.size.height,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  if (!_videoController!.value.isPlaying)
                    Container(
                      color: Colors.black26,
                      child: const Icon(Icons.play_circle_fill,
                          color: Colors.white, size: 64),
                    ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _toggleVideoMute,
                      child: Container(
                        padding: EdgeInsets.all(
                            MediaQuery.of(context).size.width < 600 ? 6 : 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width < 600
                                  ? 16
                                  : 20),
                        ),
                        child: Icon(
                          _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size:
                              MediaQuery.of(context).size.width < 600 ? 16 : 20,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: VideoProgressIndicator(
                      _videoController!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      colors: const VideoProgressColors(
                        playedColor: Colors.blueAccent,
                        backgroundColor: Colors.white24,
                        bufferedColor: Colors.white54,
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()))
        : CachedNetworkImage(
            imageUrl: mediaUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize:
                            MediaQuery.of(context).size.width < 600 ? 12 : 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );

    if (isVideo) {
      mediaWidget = VisibilityDetector(
        key: Key('video_${widget.post.id}'),
        onVisibilityChanged: (info) {
          if (!mounted ||
              _videoController == null ||
              !_videoController!.value.isInitialized) {
            return;
          }
          try {
            if (info.visibleFraction > 0.5) {
              if (!_videoController!.value.isPlaying) _videoController!.play();
            } else {
              if (_videoController!.value.isPlaying) _videoController!.pause();
            }
          } catch (e) {
            // ignore
          }
        },
        child: mediaWidget,
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    double aspectRatio = isVideo ? (9 / 16) : (4 / 5);
    if (screenWidth < 400) {
      aspectRatio = 1.0;
    } else if (screenWidth < 600) {
      aspectRatio = isVideo ? (9 / 16) : (4 / 3);
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: GestureDetector(
        onDoubleTap: _onDoubleTapLike,
        onTap: () {
          if (isVideo &&
              _videoController != null &&
              _videoController!.value.isInitialized) {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          } else {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  PostDetailScreen(post: widget.post.toJson()),
            ));
          }
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: mediaWidget,
              ),
            ),
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
                    Shadow(blurRadius: 24, color: Colors.black.withOpacity(0.4))
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final iconSize = isSmallScreen ? 24.0 : 28.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2.0 : 4.0),
      child: Row(
        children: [
          IconButton(
            icon: _isLikeInProgress
                ? SizedBox(
                    width: isSmallScreen ? 16 : 20,
                    height: isSmallScreen ? 16 : 20,
                    child: const CircularProgressIndicator(strokeWidth: 2))
                : Icon(_isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null, size: iconSize),
            onPressed: _isLikeInProgress ? null : _toggleLike,
          ),
          IconButton(
            icon: Icon(FontAwesomeIcons.comment, size: iconSize - 4),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CommentScreen(postId: widget.post.id),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, size: iconSize),
            onPressed: () => _showShareDialog(),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              size: iconSize,
              color: _isSaved ? Colors.blue : null,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme) {
    final caption = widget.post.content ?? '';
    final createdAt = widget.post.createdAt;
    final timeAgo = TimeUtils.formatDateTimeIST(createdAt);

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 8.0 : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_likeCount > 0)
            Text('$_likeCount likes',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 14)),
          if (caption.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 3 : 4),
            RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context)
                    .style
                    .copyWith(fontSize: isSmallScreen ? 13 : 14),
                children: [
                  TextSpan(
                      text: '${widget.post.user?.username ?? 'User'} ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: caption),
                ],
              ),
            ),
          ],
          SizedBox(height: isSmallScreen ? 3 : 4),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PostDetailScreen(post: widget.post.toJson()),
              ),
            ),
            child: Text('View all $_commentCount comments',
                style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: isSmallScreen ? 12 : 13)),
          ),
          SizedBox(height: isSmallScreen ? 3 : 4),
          Text(timeAgo,
              style: TextStyle(
                  color: Colors.grey[600], fontSize: isSmallScreen ? 9 : 10)),
        ],
      ),
    );
  }

  void _subscribeToLikes() {
    final supabase = Supabase.instance.client;
    _likeChannel = supabase
        .channel('public:post_likes:post_id=eq.${widget.post.id}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'post_likes',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'post_id',
            value: widget.post.id,
          ),
          callback: (payload) {
            if (mounted) {
              _fetchLikes();
            }
          },
        )
        .subscribe();
  }

  Future<void> _fetchLikes() async {
    try {
      final likes = await Supabase.instance.client
          .from('post_likes')
          .select('user_id')
          .eq('post_id', widget.post.id);

      final isLikedByCurrentUser =
          likes.any((like) => like['user_id'] == _currentUser?.id);

      if (mounted) {
        setState(() {
          _likeCount = likes.length;
          _isLiked = isLikedByCurrentUser;
        });
      }
    } catch (e) {
      print('Error fetching likes: $e');
    }
  }

  Future<void> _fetchCommentCount() async {
    try {
      final response = await Supabase.instance.client
          .from('comments')
          .select('id')
          .eq('post_id', widget.post.id)
          .count(CountOption.exact);
      if (mounted) {
        setState(() {
          _commentCount = response.count ?? 0;
        });
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _fetchSavedState() async {
    if (_currentUser == null) return;
    try {
      final result = await Supabase.instance.client
          .from('saved_posts')
          .select('id')
          .eq('user_id', _currentUser.id)
          .eq('post_id', widget.post.id)
          .maybeSingle();
      if (mounted) {
        setState(() {
          _isSaved = result != null;
        });
      }
    } catch (e) {
      // handle error
    }
  }

  Future<void> _deletePost() async {
    final supabase = Supabase.instance.client;
    final postId = widget.post.id;
    final mediaUrl =
        (widget.post.mediaUrls != null && widget.post.mediaUrls!.isNotEmpty)
            ? widget.post.mediaUrls!.first
            : null;

    try {
      if (mediaUrl != null) {
        final filePath = mediaUrl.split('/media/').last;
        await supabase.storage.from('posts').remove([filePath]);
      }
      await supabase.from('posts').delete().eq('id', postId);
      widget.onPostDeleted?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete post.')),
        );
      }
    }
  }

  Future<void> _toggleLike() async {
    if (_currentUser == null || _isLikeInProgress) return;
    _isLikeInProgress = true;

    try {
      // First, ensure the user has a profile record
      final profile = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .eq('id', _currentUser.id)
          .maybeSingle();

      if (profile == null) {
        throw Exception(
            'User profile not found. Please complete your profile setup.');
      }

      // Check the current database state to ensure UI is in sync
      final existingLike = await Supabase.instance.client
          .from('post_likes')
          .select('user_id')
          .eq('post_id', widget.post.id)
          .eq('user_id', _currentUser.id)
          .maybeSingle();

      final isCurrentlyLikedInDB = existingLike != null;

      // If UI state doesn't match database state, sync it first
      if (_isLiked != isCurrentlyLikedInDB) {
        print('UI state out of sync with database. Syncing...');
        setState(() {
          _isLiked = isCurrentlyLikedInDB;
          _likeCount = isCurrentlyLikedInDB ? _likeCount + 1 : _likeCount - 1;
        });
        _isLikeInProgress = false;
        return; // Exit early, let user try again
      }

      // Now perform the toggle operation based on current database state
      if (isCurrentlyLikedInDB) {
        // Unlike: remove like from backend
        final result =
            await Supabase.instance.client.from('post_likes').delete().match({
          'user_id': _currentUser.id,
          'post_id': widget.post.id,
        }).select();

        // Check if the delete operation affected any rows
        if (result.isEmpty) {
          print('Warning: Attempted to unlike a post that was not liked');
        }

        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // Like: add like to backend
        await Supabase.instance.client.from('post_likes').insert({
          'user_id': _currentUser.id,
          'post_id': widget.post.id,
        });

        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      print('Error in _toggleLike: $e');

      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _likeCount += _isLiked ? 1 : -1;
        });

        String errorMessage = 'Failed to update like status';
        if (e.toString().contains('profile not found')) {
          errorMessage = 'Please complete your profile setup first';
        } else if (e.toString().contains('duplicate key') ||
            e.toString().contains('23505')) {
          errorMessage = 'You have already liked this post';
          // Refresh the like state from database
          _fetchLikes();
        } else if (e.toString().contains('foreign key')) {
          errorMessage = 'Invalid post or user reference';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isLikeInProgress = false;
    }
  }

  Future<void> _toggleSave() async {
    if (_currentUser == null) return;
    setState(() => _isSaved = !_isSaved);
    try {
      if (_isSaved) {
        await Supabase.instance.client.from('saved_posts').insert({
          'user_id': _currentUser.id,
          'post_id': widget.post.id,
        });
      } else {
        await Supabase.instance.client.from('saved_posts').delete().match({
          'user_id': _currentUser.id,
          'post_id': widget.post.id,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaved = !_isSaved);
      }
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
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        _isVideoMuted = !_isVideoMuted;
        _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      });
    }
  }

  Future<void> _showShareDialog({VoidCallback? onMessageSent}) async {
    if (_isShowingShareDialog) return;
    _isShowingShareDialog = true;
    try {
      // Schedule after frame to avoid navigator lock during button ripple
      await Future<void>.delayed(const Duration(milliseconds: 40));
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => SharedContentSelectionDialog(
          contentId: widget.post.id,
          contentType: 'post',
          onShared: () {
            if (mounted) setState(() {});
            onMessageSent?.call();
          },
        ),
      );
    } finally {
      _isShowingShareDialog = false;
    }
  }

  void _showOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreatePostScreen(existingPost: widget.post),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteConfirmationDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deletePost();
              },
            ),
          ],
        );
      },
    );
  }
}
