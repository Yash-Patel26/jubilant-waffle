import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../utils/time_utils.dart';
import '../../widgets/shared_content_selection_dialog.dart';
import '../profile/profile_screen.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> post;
  final bool asDialog;

  const PostDetailScreen(
      {super.key, required this.post, this.asDialog = false});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  late bool _isLiked;
  late int _likeCount;
  late int _commentCount;
  List<Map<String, dynamic>> _comments = [];
  bool _isLoadingComments = true;
  bool _isPostingComment = false;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Video player
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _isVideoPlaying = false;
  bool _isVideoMuted = true; // Start muted by default

  // Profile data
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _initializeVideo();
    _fetchComments();
    _loadProfileData();
  }

  void _initializeData() {
    final List<dynamic> likes = widget.post['post_likes'] ?? [];
    _likeCount = likes.length;
    _commentCount = widget.post['comments']?.length ?? 0;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _isLiked = likes.any((like) => like['user_id'] == currentUser.id);
    } else {
      _isLiked = false;
    }
  }

  Future<void> _loadProfileData() async {
    // If the post already has profile data, use it
    if (widget.post['profiles'] != null) {
      _profileData = widget.post['profiles'];
      return;
    }

    // Otherwise, fetch the profile data for the post's user_id
    try {
      final userId = widget.post['user_id'];
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .single();

        if (mounted) {
          setState(() {
            _profileData = data;
          });
        }
      }
    } catch (e) {
      // No print statement here
    }
  }

  void _initializeVideo() {
    final mediaUrls = widget.post['media_urls'] as List<dynamic>?;
    if (mediaUrls != null && mediaUrls.isNotEmpty) {
      final mediaUrl = mediaUrls.first as String;
      if (mediaUrl.endsWith('.mp4')) {
        _videoController = VideoPlayerController.network(mediaUrl)
          ..initialize().then((_) {
            if (!mounted) return;
            setState(() {
              _isVideoInitialized = true;
              _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
            });
          });
      }
    }
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoadingComments = true);
    try {
      final data = await Supabase.instance.client
          .from('comments')
          .select(
              '*, profile:profiles!user_id(id, username, avatar_url, profile_picture_url)')
          .eq('post_id', widget.post['id'])
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _comments =
              (data as List).map((e) => Map<String, dynamic>.from(e)).toList();
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingComments = false);
        // No print statement here
      }
    }
  }

  Future<void> _toggleLike() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // First, check the current state in the database
      final existingLike = await Supabase.instance.client
          .from('post_likes')
          .select('user_id')
          .eq('post_id', widget.post['id'])
          .eq('user_id', currentUser.id)
          .maybeSingle();

      final isCurrentlyLikedInDB = existingLike != null;

      // If the UI state doesn't match the database state, sync it
      if (_isLiked != isCurrentlyLikedInDB) {
        setState(() {
          _isLiked = isCurrentlyLikedInDB;
          _likeCount = isCurrentlyLikedInDB ? _likeCount + 1 : _likeCount - 1;
        });
      }

      // Now perform the toggle operation
      if (isCurrentlyLikedInDB) {
        // User is unliking the post - DELETE
        await Supabase.instance.client.from('post_likes').delete().match({
          'user_id': currentUser.id,
          'post_id': widget.post['id'],
        });

        setState(() {
          _isLiked = false;
          _likeCount -= 1;
        });
      } else {
        // User is liking the post - INSERT
        await Supabase.instance.client.from('post_likes').insert({
          'user_id': currentUser.id,
          'post_id': widget.post['id'],
        });

        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      // Show error message to user
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like status'),
          backgroundColor: theme.colorScheme.error,
        ),
      );
    }
  }

  Future<void> _postComment() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final commentText = _commentController.text.trim();

    if (currentUser == null || commentText.isEmpty) return;

    setState(() => _isPostingComment = true);
    try {
      await Supabase.instance.client.from('comments').insert({
        'content': commentText,
        'user_id': currentUser.id,
        'post_id': widget.post['id'],
      });

      _commentController.clear();
      await _fetchComments();

      if (mounted) {
        setState(() => _commentCount += 1);
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPostingComment = false);
      }
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return;
    }
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        _isVideoPlaying = false;
      } else {
        _videoController!.play();
        _isVideoPlaying = true;
      }
    });
  }

  void _toggleVideoMute() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        _isVideoMuted = !_isVideoMuted;
        _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      });
    }
  }

  void _showPostOptions() {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwner = currentUser?.id == _profileData?['id'];

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Post'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to edit post screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon!')),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: theme.colorScheme.error),
                title: Text('Delete Post',
                    style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeletePostConfirmation();
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Report Post'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportPostDialog();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Post'),
              onTap: () {
                Navigator.pop(context);
                _showShareDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Link copied to clipboard!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Save Post'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Post saved!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletePostConfirmation() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text(
            'Are you sure you want to delete this post? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePost();
            },
            child: Text('Delete',
                style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showReportPostDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for reporting this post:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Enter reason...',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _reportPost(reasonController.text);
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Verify ownership
      final postData = await Supabase.instance.client
          .from('posts')
          .select('user_id')
          .eq('id', widget.post['id'])
          .single();

      if (postData['user_id'] != currentUser.id) {
        throw Exception('Not authorized to delete this post');
      }

      // Delete related data
      await Supabase.instance.client
          .from('comments')
          .delete()
          .eq('post_id', widget.post['id']);
      await Supabase.instance.client
          .from('post_likes')
          .delete()
          .eq('post_id', widget.post['id']);
      await Supabase.instance.client
          .from('saved_posts')
          .delete()
          .eq('post_id', widget.post['id']);

      // Delete the post
      await Supabase.instance.client
          .from('posts')
          .delete()
          .eq('id', widget.post['id']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted successfully')),
      );

      // Navigate back
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _reportPost(String reason) async {
    try {
      await Supabase.instance.client.from('post_reports').insert({
        'post_id': widget.post['id'],
        'reported_by': Supabase.instance.client.auth.currentUser?.id,
        'reason': reason,
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post reported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error reporting post: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => SharedContentSelectionDialog(
        contentId: widget.post['id'],
        contentType: 'post',
        onShared: () {
          // Refresh the post to update share count
          setState(() {});
        },
      ),
    );
  }

  void _sharePost() {
    final caption = widget.post['caption'] as String? ?? '';
    final mediaUrls = widget.post['media_urls'] as List<dynamic>?;
    final mediaUrl =
        mediaUrls?.isNotEmpty == true ? mediaUrls!.first as String : null;
    final username = _profileData?['username'] ?? 'User';

    String shareText = 'Check out this post by @$username';
    if (caption.isNotEmpty) {
      shareText += ': $caption';
    }

    if (mediaUrl != null && mediaUrl.isNotEmpty) {
      shareText += '\n\nMedia: $mediaUrl';
    }

    // Share.share(shareText, subject: 'Post by @$username'); // This line was removed
  }

  @override
  void dispose() {
    _commentController.dispose();
    _videoController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isWide = screenWidth >= 900;

    if (isWide) {
      final Widget wideBody = _buildWideBody(theme, screenHeight);
      if (widget.asDialog) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {},
              child: wideBody,
            ),
          ),
        );
      }
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.textTheme.titleLarge?.color),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz,
                  color: theme.textTheme.titleLarge?.color),
              onPressed: _showPostOptions,
            ),
          ],
        ),
        body: wideBody,
      );
    }

    // Mobile/tablet: original single-column layout
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface.withOpacity(0),
        elevation: 0,
        leading: IconButton(
          icon:
              Icon(Icons.arrow_back, color: theme.textTheme.titleLarge?.color),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz,
                color: theme.textTheme.titleLarge?.color),
            onPressed: _showPostOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Center(
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
                    _buildHeader(),
                    const SizedBox(height: 8),
                    _buildMedia(),
                    _buildActionButtons(),
                    if (_likeCount > 0) _buildLikeCount(),
                    _buildCaption(),
                    _buildCommentsSection(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildWideBody(ThemeData theme, double screenHeight) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 1200,
          maxHeight: screenHeight * 0.9,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Expanded(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                child: Center(child: _buildMedia()),
              ),
            ),
            SizedBox(
              width: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: _buildHeader(),
                  ),
                  _buildActionButtons(),
                  if (_likeCount > 0) _buildLikeCount(),
                  _buildCaption(),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: _buildCommentsSection(),
                    ),
                  ),
                  _buildCommentInput(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Show loading if profile data is not available yet
    if (_profileData == null) {
      return const SizedBox.shrink();
    }

    final avatarUrl =
        _profileData!['avatar_url'] ?? _profileData!['profile_picture_url'];
    final createdAt = DateTime.parse(widget.post['created_at']);
    final timeAgo = TimeUtils.formatDateTimeIST(createdAt);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwner = currentUser?.id == _profileData!['id'];

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
                builder: (_) => ProfileScreen(userId: _profileData!['id']),
              ),
            ),
            child: CircleAvatar(
              radius: isSmallScreen ? 20 : 24,
              backgroundImage: (avatarUrl != null && avatarUrl != '')
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl == '')
                  ? const Icon(Icons.person, size: 20)
                  : null,
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Expanded(
            child: Text(
              _profileData!['username'] ?? 'Unknown User',
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
              onPressed: () => _showPostOptions(),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final theme = Theme.of(context);
    final mediaUrls = widget.post['media_urls'] as List<dynamic>?;
    if (mediaUrls == null || mediaUrls.isEmpty) return const SizedBox.shrink();

    final mediaUrl = mediaUrls.first as String;
    final isVideo = mediaUrl.endsWith('.mp4') || mediaUrl.endsWith('.mov');

    Widget mediaWidget = isVideo
        ? (_videoController != null && _videoController!.value.isInitialized
            ? Stack(
                alignment: Alignment.center,
                children: [
                  // Make the video cover the available space (Instagram-style)
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
                      color: theme.shadowColor.withOpacity(0.3),
                      child: Icon(Icons.play_circle_fill,
                          color: theme.colorScheme.onSurface, size: 64),
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
                          color: theme.shadowColor.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width < 600
                                  ? 16
                                  : 20),
                        ),
                        child: Icon(
                          _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                          color: theme.colorScheme.onSurface,
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
                      colors: VideoProgressColors(
                        playedColor: theme.colorScheme.primary,
                        backgroundColor:
                            theme.colorScheme.onSurface.withOpacity(0.2),
                        bufferedColor:
                            theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              )
            : const Center(child: CircularProgressIndicator()))
        : Image.network(
            mediaUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : Container(
                    color: theme.dividerColor,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: theme.colorScheme.primary)),
            errorBuilder: (context, error, stackTrace) => Container(
              color: theme.dividerColor,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: theme.colorScheme.error, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'Failed to load image',
                    style: TextStyle(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        fontSize:
                            MediaQuery.of(context).size.width < 600 ? 12 : 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );

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
        onTap: () {
          if (isVideo &&
              _videoController != null &&
              _videoController!.value.isInitialized) {
            setState(() {
              _videoController!.value.isPlaying
                  ? _videoController!.pause()
                  : _videoController!.play();
            });
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: mediaWidget,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_videoController!),
        if (!_isVideoPlaying)
          Icon(
            Icons.play_arrow,
            size: 80,
            color: Colors.white.withOpacity(0.7),
          ),
        // Mute/Unmute Button
        Positioned(
          top: 16,
          right: 16,
          child: GestureDetector(
            onTap: _toggleVideoMute,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final iconSize = isSmallScreen ? 24.0 : 28.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2.0 : 4.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked ? Colors.red : null,
              size: iconSize,
            ),
            onPressed: _toggleLike,
          ),
          IconButton(
            icon: Icon(FontAwesomeIcons.comment, size: iconSize - 4),
            onPressed: () {
              // Scroll to comment input
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.send_outlined, size: iconSize),
            onPressed: _showShareDialog,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.bookmark_border, size: iconSize),
            onPressed: () {
              // TODO: Bookmark functionality
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.0 : 12.0, vertical: 4),
      child: Text(
        '$_likeCount likes',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final caption = widget.post['content'] as String?;
    if (caption == null || caption.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 8.0 : 12.0, vertical: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(fontSize: isSmallScreen ? 13 : 14),
          children: [
            if (_profileData != null) ...[
              TextSpan(
                text: '${_profileData!['username']} ',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
            TextSpan(text: caption),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments ($_commentCount)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingComments)
            _buildCommentsSkeleton()
          else if (_comments.isEmpty)
            _buildEmptyComments()
          else
            _buildCommentsList(),
        ],
      ),
    );
  }

  Widget _buildCommentsSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[600]!,
      child: Column(
        children: List.generate(
            3,
            (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 12,
                              width: 100,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              height: 10,
                              width: double.infinity,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
      ),
    );
  }

  Widget _buildEmptyComments() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.chat_bubble_outline,
              color: Colors.grey[600],
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No comments yet',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to comment!',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return Column(
      children: _comments.map((comment) {
        final profile = comment['profile'] ?? {};
        final username = profile['username'] ?? comment['username'] ?? 'User';
        final avatarUrl =
            profile['avatar_url'] ?? profile['profile_picture_url'];
        final createdAt = DateTime.parse(comment['created_at']);
        final timeAgo = TimeUtils.formatDateTimeIST(createdAt);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: (avatarUrl != null && avatarUrl != '')
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl == null || avatarUrl == '')
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(fontSize: 14),
                      )
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
                          username,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeAgo,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      comment['content'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCommentInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _postComment(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _isPostingComment
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : IconButton(
                    icon: const Icon(Icons.send, color: Colors.blue),
                    onPressed: _postComment,
                  ),
          ],
        ),
      ),
    );
  }
}
