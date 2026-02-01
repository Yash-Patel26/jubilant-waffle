import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../profile/profile_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:gamer_flick/providers/chat/conversation_providers.dart';

class ReelDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> reel;
  final bool asDialog;

  const ReelDetailScreen(
      {super.key, required this.reel, this.asDialog = false});

  @override
  ConsumerState<ReelDetailScreen> createState() => _ReelDetailScreenState();
}

class _ReelDetailScreenState extends ConsumerState<ReelDetailScreen> {
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
    print('ReelDetailScreen initialized with reel: ${widget.reel['id']}');
    print('Reel data: ${widget.reel}');
    _initializeData();
    _initializeVideo();
    _fetchComments();
    _loadProfileData();
  }

  void _initializeData() {
    final List<dynamic> likes = widget.reel['reel_likes'] ?? [];
    _likeCount = likes.length;
    _commentCount = widget.reel['reel_comments']?.length ?? 0;

    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _isLiked = likes.any((like) => like['user_id'] == currentUser.id);
    } else {
      _isLiked = false;
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = widget.reel['user_id'];
      if (userId != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('*')
            .eq('id', userId)
            .single();
        setState(() {
          _profileData = response;
        });
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _initializeVideo() {
    final videoUrl = widget.reel['video_url'];
    print('Initializing video with URL: $videoUrl');
    if (videoUrl != null && videoUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          if (mounted) {
            setState(() {
              _isVideoInitialized = true;
            });
            _videoController!.setLooping(true);
            _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
            print('Video initialized successfully');
          }
        }).catchError((error) {
          print('Error initializing video: $error');
        });
    } else {
      print('No video URL provided');
    }
  }

  Future<void> _fetchComments() async {
    try {
      final response = await Supabase.instance.client
          .from('reel_comments')
          .select('*, profiles!reel_comments_user_id_fkey(*)')
          .eq('reel_id', widget.reel['id'])
          .order('created_at', ascending: false);

      setState(() {
        _comments = (response as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoadingComments = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() {
      _isPostingComment = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      await Supabase.instance.client.from('reel_comments').insert({
        'reel_id': widget.reel['id'],
        'user_id': currentUser.id,
        'content': _commentController.text.trim(),
      });

      _commentController.clear();
      await _fetchComments();

      setState(() {
        _commentCount += 1;
        _isPostingComment = false;
      });
    } catch (e) {
      setState(() {
        _isPostingComment = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    }
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
          .eq('reel_id', widget.reel['id'])
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
        // Unlike
        final result =
            await Supabase.instance.client.from('reel_likes').delete().match({
          'user_id': currentUser.id,
          'reel_id': widget.reel['id'],
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
        // Like
        await Supabase.instance.client.from('reel_likes').insert({
          'user_id': currentUser.id,
          'reel_id': widget.reel['id'],
        });

        setState(() {
          _isLiked = true;
          _likeCount += 1;
        });
      }
    } catch (e) {
      print('Error in _toggleLike (reel): $e');

      if (mounted) {
        final theme = Theme.of(context);
        String errorMessage = 'Error updating like';
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
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _refreshLikeState() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final likes = widget.reel['reel_likes'] ?? [];
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

  void _toggleVideoMute() {
    if (_videoController != null) {
      setState(() {
        _isVideoMuted = !_isVideoMuted;
        _videoController!.setVolume(_isVideoMuted ? 0.0 : 1.0);
      });
    }
  }

  void _toggleVideoPlay() {
    if (_videoController != null) {
      setState(() {
        if (_isVideoPlaying) {
          _videoController!.pause();
        } else {
          _videoController!.play();
        }
        _isVideoPlaying = !_isVideoPlaying;
      });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
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
      // Desktop-style two-column layout similar to Instagram
      if (widget.asDialog) {
        return Material(
          type: MaterialType.transparency,
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTap: () {},
              child: _buildWideBody(theme, screenHeight),
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
            icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.more_horiz, color: theme.colorScheme.onSurface),
              onPressed: _showReelOptions,
            ),
          ],
        ),
        body: _buildWideBody(theme, screenHeight),
      );
    }

    // Mobile: Instagram-style full-screen reel with overlay controls
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: _buildFullscreenVideo()),
          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                _buildCircleButton(
                  icon: _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                  onPressed: _toggleVideoMute,
                ),
              ],
            ),
          ),
          // Right action rail
          Positioned(
            right: 12,
            bottom: 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionIcon(
                  icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.redAccent : Colors.white,
                  onPressed: _toggleLike,
                ),
                _buildActionCount('$_likeCount'),
                const SizedBox(height: 12),
                _buildActionIcon(
                  icon: Icons.mode_comment_outlined,
                  color: Colors.white,
                  onPressed: _openCommentsDrawer,
                ),
                _buildActionCount('$_commentCount'),
                const SizedBox(height: 12),
                _buildActionIcon(
                  icon: Icons.send_outlined,
                  color: Colors.white,
                  onPressed: _showShareDialog,
                ),
                const SizedBox(height: 12),
                _buildActionIcon(
                  icon: Icons.more_horiz,
                  color: Colors.white,
                  onPressed: _showReelOptions,
                ),
              ],
            ),
          ),
          // Bottom caption/profile
          Positioned(
            left: 12,
            right: 12,
            bottom: 24,
            child: _buildBottomOverlay(),
          ),
        ],
      ),
    );
  }

  Widget _buildFullscreenVideo() {
    final theme = Theme.of(context);
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    final size = _videoController!.value.size;
    return GestureDetector(
      onTap: _toggleVideoPlay,
      child: ColoredBox(
        color: Colors.black,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleButton(
      {required IconData icon, required VoidCallback onPressed}) {
    return Material(
      color: Colors.white.withOpacity(0.15),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildActionIcon(
      {required IconData icon,
      required Color color,
      required VoidCallback onPressed}) {
    return Material(
      color: Colors.white.withOpacity(0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildActionCount(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withOpacity(0.6),
            Colors.black.withOpacity(0.0)
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_profileData != null)
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _profileData!['avatar_url'] != null
                      ? NetworkImage(_profileData!['avatar_url'])
                      : null,
                  child: _profileData!['avatar_url'] == null
                      ? Text(
                          (_profileData!['username'] ?? 'U')[0].toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  _profileData!['username'] ?? 'Unknown',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          if ((widget.reel['caption'] as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(
              widget.reel['caption'],
              style: const TextStyle(color: Colors.white, fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  // Deprecated in favor of left-side drawer
  // ignore: unused_element
  void _showCommentsSheet() {}

  void _openCommentsDrawer() {
    final theme = Theme.of(context);
    final currentUser = Supabase.instance.client.auth.currentUser;
    showGeneralDialog(
      context: context,
      barrierLabel: 'Comments',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondary) {
        final width = MediaQuery.of(context).size.width;
        final panelWidth = width > 420 ? 420.0 : width * 0.9;
        return Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: panelWidth,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 24,
                    offset: const Offset(8, 0),
                  ),
                ],
              ),
              child: currentUser == null
                  ? const SizedBox.shrink()
                  : SafeArea(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Text(
                                  'Comments',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  color: theme.colorScheme.onSurface,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
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
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      },
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
                child: Center(child: _buildVideo()),
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
    final theme = Theme.of(context);
    if (_profileData == null) {
      return Shimmer.fromColors(
        baseColor: theme.dividerColor,
        highlightColor: theme.colorScheme.surface,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                  radius: 20, backgroundColor: theme.colorScheme.onSurface),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, color: theme.colorScheme.onSurface),
                    const SizedBox(height: 4),
                    Container(height: 12, color: theme.colorScheme.onSurface),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(
                    userId: _profileData!['id'],
                  ),
                ),
              );
            },
            child: CircleAvatar(
              radius: 20,
              backgroundImage: _profileData!['avatar_url'] != null
                  ? NetworkImage(_profileData!['avatar_url'])
                  : null,
              child: _profileData!['avatar_url'] == null
                  ? Text(
                      (_profileData!['username'] ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _profileData!['username'] ?? 'Unknown',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  DateFormat('MMM d, y').format(
                    DateTime.parse(widget.reel['created_at']),
                  ),
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    final theme = Theme.of(context);
    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 400,
        color: theme.colorScheme.surface,
        child: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleVideoPlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 9 / 16,
            child: VideoPlayer(_videoController!),
          ),
          if (!_isVideoPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.shadowColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow,
                color: theme.colorScheme.onSurface,
                size: 48,
              ),
            ),
          // Mute/Unmute Button
          Positioned(
            top: 20,
            right: 20,
            child: GestureDetector(
              onTap: _toggleVideoMute,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.shadowColor.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isVideoMuted ? Icons.volume_off : Icons.volume_up,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              _isLiked ? Icons.favorite : Icons.favorite_border,
              color: _isLiked
                  ? theme.colorScheme.error
                  : theme.colorScheme.onSurface,
              size: 28,
            ),
            onPressed: _toggleLike,
          ),
          Text(
            '$_likeCount',
            style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: Icon(
              FontAwesomeIcons.comment,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              // Scroll to comments
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
          Text(
            '$_commentCount',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(width: 20),
          IconButton(
            icon: const Icon(
              Icons.send_outlined,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _showShareDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLikeCount() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        '$_likeCount likes',
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildCaption() {
    final theme = Theme.of(context);
    final caption = widget.reel['caption'];
    if (caption == null || caption.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 16),
          children: [
            TextSpan(
              text: '${_profileData?['username'] ?? 'Unknown'} ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: caption),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments ($_commentCount)',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingComments)
            Center(
                child:
                    CircularProgressIndicator(color: theme.colorScheme.primary))
          else if (_comments.isEmpty)
            Center(
              child: Text(
                'No comments yet. Be the first to comment!',
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _comments.length,
              itemBuilder: (context, index) {
                final comment = _comments[index];
                final user = comment['profiles'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: user?['avatar_url'] != null
                            ? NetworkImage(user!['avatar_url'])
                            : null,
                        child: user?['avatar_url'] == null
                            ? Text(
                                (user?['username'] ?? 'U')[0].toUpperCase(),
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${user?['username'] ?? 'Unknown'} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(text: comment['content']),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y').format(
                                DateTime.parse(comment['created_at']),
                              ),
                              style: TextStyle(
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              style: TextStyle(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Add a comment...',
                hintStyle: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (_isPostingComment)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.send, color: theme.colorScheme.primary),
              onPressed: _postComment,
            ),
        ],
      ),
    );
  }

  void _showShareDialog() {
    // Share functionality has been removed
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality is not available'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showReelOptions() {
    // final username = _profileData?['username'] ?? 'Unknown';
    // final userId = Supabase.instance.client.auth.currentUser?.id;
    // final postId = widget.reel['id'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reel Options'),
        content: const Text('What would you like to do with this reel?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement delete reel functionality
            },
            child: const Text('Delete Reel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement edit reel functionality
            },
            child: const Text('Edit Reel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement report reel functionality
            },
            child: const Text('Report Reel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement share reel functionality
            },
            child: const Text('Share Reel'),
          ),
        ],
      ),
    );
  }
}
