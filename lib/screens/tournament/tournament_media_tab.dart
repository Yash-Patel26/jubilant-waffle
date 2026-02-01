import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../utils/time_utils.dart';

class TournamentMediaTab extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic>? currentUserRole;

  const TournamentMediaTab({
    super.key,
    required this.tournamentId,
    this.currentUserRole,
  });

  @override
  _TournamentMediaTabState createState() => _TournamentMediaTabState();
}

class _TournamentMediaTabState extends State<TournamentMediaTab>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _mediaItems = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;
  int _currentTabIndex = 0;

  bool get _canUpload {
    if (widget.currentUserRole == null) {
      return true; // Allow all participants to upload
    }
    final permissions =
        widget.currentUserRole!['permissions'] as Map<String, dynamic>?;
    return permissions?['can_manage_media'] == true ||
        true; // Allow all for now
  }

  bool get _canModerate {
    if (widget.currentUserRole == null) return false;
    final permissions =
        widget.currentUserRole!['permissions'] as Map<String, dynamic>?;
    return permissions?['can_manage_media'] == true;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() => _currentTabIndex = _tabController.index);
    });
    _fetchMedia();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedia() async {
    try {
      final response = await Supabase.instance.client
          .from('tournament_media')
          .select(
              '*, profile:profiles!tournament_media_user_id_fkey(username, avatar_url)')
          .eq('tournament_id', widget.tournamentId)
          .order('created_at', ascending: false);

      setState(() {
        _mediaItems = (response as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAndUploadMedia() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Media'),
        content: const Text('Choose media type to upload.'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.photo),
            label: const Text('Image'),
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          TextButton.icon(
            icon: const Icon(Icons.videocam),
            label: const Text('Video'),
            onPressed: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (source == null) return;

    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (picked == null) return;

    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Add Caption (optional)'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter a caption...'),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    await _uploadMedia(picked, caption);
  }

  Future<void> _uploadMedia(XFile file, String? caption) async {
    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if tournaments bucket is accessible before proceeding
      try {
        await Supabase.instance.client.storage.from('tournaments').list();
      } catch (e) {
        throw Exception(
            'Storage configuration error. Tournaments bucket is not accessible.');
      }

      // Handle file extension properly for web
      String fileExt;
      if (file.path.contains('blob:')) {
        // For web, use mime type to determine extension
        final mimeType = file.mimeType ?? 'image/jpeg';
        if (mimeType.startsWith('image/')) {
          fileExt = mimeType.split('/')[1];
        } else if (mimeType.startsWith('video/')) {
          fileExt = mimeType.split('/')[1];
        } else {
          fileExt = 'jpg'; // fallback
        }
      } else {
        // For mobile, use file path
        fileExt = file.path.split('.').last;
      }

      final filePath =
          '${widget.tournamentId}/media/${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload to Supabase Storage
      final bytes = await file.readAsBytes();
      final storageResponse = await Supabase.instance.client.storage
          .from('tournaments')
          .uploadBinary(filePath, bytes);

      // Always use the storage path and Supabase public URL
      final publicUrl = Supabase.instance.client.storage
          .from('tournaments')
          .getPublicUrl(filePath);

      if (publicUrl.startsWith('blob:') || publicUrl.isEmpty) {
        throw Exception('Invalid media URL: blob URLs cannot be stored.');
      }

      // Save to database
      final insertData = {
        'tournament_id': widget.tournamentId,
        'user_id': user.id,
        'media_url': publicUrl,
        'caption': caption,
        'media_type': fileExt == 'mp4' || fileExt == 'mov' || fileExt == 'avi'
            ? 'video'
            : 'image',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Debug: Log the data being inserted
      print('Inserting tournament media data: $insertData');

      final insertResponse = await Supabase.instance.client
          .from('tournament_media')
          .insert(insertData);

      print('Insert response: $insertResponse');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media uploaded successfully!')),
        );
        _fetchMedia();
      }
    } catch (e) {
      if (mounted) {
        // Debug: Log the full error
        print('Tournament media upload error: $e');
        print('Error type: ${e.runtimeType}');

        String errorMessage = 'Error uploading media';

        // Provide more specific error messages
        if (e.toString().contains('Bucket not found')) {
          errorMessage = 'Storage configuration error. Please contact support.';
        } else if (e.toString().contains('permission')) {
          errorMessage =
              'Permission denied. You may not have access to upload media.';
        } else if (e.toString().contains('network')) {
          errorMessage =
              'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('400')) {
          errorMessage =
              'Bad request error. Please check your data and try again.';
        } else if (e.toString().contains('RLS')) {
          errorMessage = 'Access denied. Row-level security policy violation.';
        } else {
          errorMessage =
              'Error uploading media: ${e.toString().split(':').last.trim()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteMedia(Map<String, dynamic> mediaItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from storage - construct path from media URL
      final mediaUrl = mediaItem['media_url'];
      if (mediaUrl != null && mediaUrl.isNotEmpty) {
        try {
          // Extract the path from the URL
          final uri = Uri.parse(mediaUrl);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 3) {
            // URL format: /storage/v1/object/public/tournaments/{path}
            final storagePath = pathSegments.sublist(3).join('/');
            await Supabase.instance.client.storage
                .from('tournaments')
                .remove([storagePath]);
          }
        } catch (e) {
          // If we can't parse the URL, just continue with database deletion
          print('Could not parse storage path from URL: $e');
        }
      }

      // Delete from database
      await Supabase.instance.client
          .from('tournament_media')
          .delete()
          .eq('id', mediaItem['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media deleted successfully')),
        );
        _fetchMedia();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting media: $e')),
        );
      }
    }
  }

  Future<void> _flagMedia(Map<String, dynamic> mediaItem) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Flag Media'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for flagging this media:'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
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
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Flag'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.trim().isEmpty) return;

    try {
      await Supabase.instance.client.from('tournament_media_flags').insert({
        'media_id': mediaItem['id'],
        'tournament_id': widget.tournamentId,
        'reason': reason.trim(),
        'flagged_by': Supabase.instance.client.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media flagged successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flagging media: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredMedia {
    switch (_currentTabIndex) {
      case 1:
        return _mediaItems.where((m) => m['media_type'] == 'image').toList();
      case 2:
        return _mediaItems.where((m) => m['media_type'] == 'video').toList();
      default:
        return _mediaItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on mobile
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardPadding = isMobile ? 16.0 : 20.0;
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMedia,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Calculate media counts
    final imageCount =
        _mediaItems.where((m) => m['media_type'] == 'image').length;
    final videoCount =
        _mediaItems.where((m) => m['media_type'] == 'video').length;
    final totalCount = _mediaItems.length;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Tournament Media Header
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Colors.purple.shade700,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tournament Media',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share screenshots, highlights, and moments from the tournament',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7) ??
                              Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_canUpload)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.shade500,
                          Colors.purple.shade600
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _pickAndUploadMedia,
                      icon: Icon(
                        Icons.file_upload,
                        size: isMobile ? 16 : 18,
                        color: Theme.of(context).cardColor,
                      ),
                      label: Text(
                        'Upload Media',
                        style: TextStyle(
                          color: Theme.of(context).cardColor,
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 12 : 16,
                          vertical: isMobile ? 8 : 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Media Type Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: isMobile
                ? Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildMediaTypeCard(
                              icon: Icons.camera_alt,
                              title: 'Screenshots',
                              description: 'Epic moments and gameplay shots',
                              count: imageCount,
                              color: Colors.purple,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMediaTypeCard(
                              icon: Icons.videocam,
                              title: 'Highlights',
                              description: 'Best plays and clutch moments',
                              count: videoCount,
                              color: Colors.blue,
                              isMobile: isMobile,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMediaTypeCard(
                              icon: Icons.play_circle_outline,
                              title: 'Live Streams',
                              description: 'Tournament broadcasts',
                              count: 0, // Placeholder for future feature
                              color: Colors.green,
                              isMobile: isMobile,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Container()), // Empty space for balance
                        ],
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildMediaTypeCard(
                          icon: Icons.camera_alt,
                          title: 'Screenshots',
                          description: 'Epic moments and gameplay shots',
                          count: imageCount,
                          color: Colors.purple,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMediaTypeCard(
                          icon: Icons.videocam,
                          title: 'Highlights',
                          description: 'Best plays and clutch moments',
                          count: videoCount,
                          color: Colors.blue,
                          isMobile: isMobile,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMediaTypeCard(
                          icon: Icons.play_circle_outline,
                          title: 'Live Streams',
                          description: 'Tournament broadcasts',
                          count: 0, // Placeholder for future feature
                          color: Colors.green,
                          isMobile: isMobile,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 24),

          // Media Gallery Section
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Header
                  Text(
                    'Media Gallery',
                    style: TextStyle(
                      fontSize: isMobile ? 18 : 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gallery Content
                  Expanded(
                    child: _filteredMedia.isEmpty
                        ? SingleChildScrollView(
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(cardPadding),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .shadowColor
                                          .withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.broken_image,
                                      size: isMobile ? 48 : 64,
                                      color: Theme.of(context).dividerColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No media uploaded yet',
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color ??
                                            Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Flexible(
                                      child: Text(
                                        'Once the tournament begins, participants can share their best moments here',
                                        style: TextStyle(
                                          fontSize: isMobile ? 13 : 14,
                                          color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.8) ??
                                              Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (_canUpload)
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade500,
                                              Colors.blue.shade600
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.blue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton.icon(
                                          onPressed: _pickAndUploadMedia,
                                          icon: Icon(
                                            Icons.file_upload,
                                            size: isMobile ? 16 : 18,
                                            color: Theme.of(context).cardColor,
                                          ),
                                          label: Text(
                                            'Upload First Media',
                                            style: TextStyle(
                                              color:
                                                  Theme.of(context).cardColor,
                                              fontSize: isMobile ? 12 : 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isMobile ? 16 : 20,
                                              vertical: isMobile ? 10 : 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : GridView.builder(
                            padding: EdgeInsets.only(bottom: cardPadding),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 2 : 3,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 1.0,
                            ),
                            itemCount: _filteredMedia.length,
                            itemBuilder: (context, index) {
                              final mediaItem = _filteredMedia[index];
                              return _buildMediaGridItem(mediaItem, isMobile);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required int count,
    required MaterialColor color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 14),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 6 : 8),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color.shade700,
              size: isMobile ? 18 : 22,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: isMobile ? 12 : 13,
                fontWeight: FontWeight.bold,
                color: color.shade800,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Flexible(
            child: Text(
              description,
              style: TextStyle(
                fontSize: isMobile ? 9 : 10,
                color: color.shade600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.bold,
                color: color.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaGridItem(Map<String, dynamic> mediaItem, bool isMobile) {
    return GestureDetector(
      onTap: () => _showMediaDetail(mediaItem),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Image/Video
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(mediaItem['media_url']),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              // Video indicator
              if (mediaItem['media_type'] == 'video')
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.play_arrow,
                      color: Theme.of(context).cardColor,
                      size: isMobile ? 16 : 18,
                    ),
                  ),
                ),

              // Caption overlay
              if (mediaItem['caption'] != null &&
                  mediaItem['caption'].toString().isNotEmpty)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: Text(
                      mediaItem['caption'],
                      style: TextStyle(
                        color: Theme.of(context).cardColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMediaDetail(Map<String, dynamic> mediaItem) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 400,
            maxHeight: 600,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).dividerColor,
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage:
                          mediaItem['profile']?['avatar_url'] != null
                              ? NetworkImage(mediaItem['profile']['avatar_url'])
                              : null,
                      child: mediaItem['profile']?['avatar_url'] == null
                          ? Text(
                              mediaItem['profile']?['username']?[0]
                                      .toUpperCase() ??
                                  'U',
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (mediaItem['profile'] != null &&
                                    mediaItem['profile']['username'] != null &&
                                    mediaItem['profile']['username']
                                        .toString()
                                        .isNotEmpty)
                                ? mediaItem['profile']['username']
                                : 'User',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().format(
                              DateTime.parse(mediaItem['created_at']),
                            ),
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Image/Video content
              Flexible(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(
                    maxHeight: 400,
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(0),
                          bottom: Radius.circular(0),
                        ),
                        child: Image.network(
                          mediaItem['media_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (mediaItem['media_type'] == 'video')
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: Theme.of(context).cardColor,
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Caption section
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption
                    if (mediaItem['caption'] != null &&
                        mediaItem['caption'].toString().isNotEmpty)
                      RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color,
                            fontSize: 14,
                          ),
                          children: [
                            TextSpan(
                              text: ((mediaItem['profile'] != null &&
                                          mediaItem['profile']['username'] !=
                                              null &&
                                          mediaItem['profile']['username']
                                              .toString()
                                              .isNotEmpty)
                                      ? mediaItem['profile']['username']
                                      : 'User') +
                                  ' ',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: mediaItem['caption']),
                          ],
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Timestamp
                    Text(
                      TimeUtils.formatDateTimeIST(
                          DateTime.parse(mediaItem['created_at'])),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 12,
                      ),
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
}
