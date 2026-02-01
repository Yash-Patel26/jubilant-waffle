import 'package:gamer_flick/models/post/post.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/post/shared_posts_service.dart';
import '../../widgets/home/post_card.dart';
import 'post_detail_screen.dart';
import '../../utils/time_utils.dart';
import 'package:gamer_flick/models/post/shared_post.dart';

class SharedPostsScreen extends StatefulWidget {
  const SharedPostsScreen({super.key});

  @override
  State<SharedPostsScreen> createState() => _SharedPostsScreenState();
}

class _SharedPostsScreenState extends State<SharedPostsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SharedPostsService _sharedPostsService = SharedPostsService();

  List<SharedPost> _receivedPosts = [];
  List<SharedPost> _sharedPosts = [];
  bool _isLoadingReceived = true;
  bool _isLoadingShared = true;
  String? _errorReceived;
  String? _errorShared;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSharedPosts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedPosts() async {
    await Future.wait([
      _loadReceivedPosts(),
      _loadPostsSharedByUser(),
    ]);
  }

  Future<void> _loadReceivedPosts() async {
    setState(() {
      _isLoadingReceived = true;
      _errorReceived = null;
    });

    try {
      final posts = await _sharedPostsService.getSharedPostsForUser();
      setState(() {
        _receivedPosts = posts
            .where((post) =>
                post.sharedBy != Supabase.instance.client.auth.currentUser?.id)
            .toList();
        _isLoadingReceived = false;
      });
    } catch (e) {
      setState(() {
        _errorReceived = e.toString();
        _isLoadingReceived = false;
      });
    }
  }

  Future<void> _loadPostsSharedByUser() async {
    setState(() {
      _isLoadingShared = true;
      _errorShared = null;
    });

    try {
      final posts = await _sharedPostsService.getPostsSharedByUser();
      setState(() {
        _sharedPosts = posts;
        _isLoadingShared = false;
      });
    } catch (e) {
      setState(() {
        _errorShared = e.toString();
        _isLoadingShared = false;
      });
    }
  }

  Widget _buildSharedPostCard(Map<String, dynamic> sharedPost) {
    final originalPost = sharedPost['original_post'];
    final sharedByProfile = sharedPost['shared_by_profile'];
    final sharedAt = DateTime.parse(sharedPost['shared_at']);

    final timeAgo = TimeUtils.formatDateTimeIST(sharedAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared by header
          ListTile(
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: sharedByProfile?['profile_picture_url'] != null
                  ? NetworkImage(sharedByProfile['profile_picture_url'])
                  : null,
              child: sharedByProfile?['profile_picture_url'] == null
                  ? Text(
                      sharedByProfile?['username']?[0]?.toUpperCase() ?? '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
            title: Text(
              '${sharedByProfile?['username'] ?? 'Unknown'} shared a post',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              timeAgo,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () => _showSharedPostOptions(sharedPost),
            ),
          ),

          // Original post content
          if (originalPost != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: _buildOriginalPostPreview(originalPost),
            ),
          ] else ...[
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Original post not available',
                style: TextStyle(
                  color: Colors.red,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOriginalPostPreview(Map<String, dynamic> originalPost) {
    try {
      // Convert the map to a Post object
      final post = Post.fromMap(originalPost);

      return PostCard(
        post: post,
        onPostDeleted: () => _loadSharedPosts(),
      );
    } catch (e) {
      // Fallback if Post conversion fails
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (originalPost['content'] != null &&
                originalPost['content'].toString().isNotEmpty)
              Text(
                originalPost['content'].toString(),
                style: const TextStyle(fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            if (originalPost['media_urls'] != null &&
                (originalPost['media_urls'] as List).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    originalPost['media_urls'][0],
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'By ${originalPost['author']?['username'] ?? 'Unknown'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showSharedPostOptions(Map<String, dynamic> sharedPost) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final isOwnSharedPost = sharedPost['shared_by'] == currentUser?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: const Text('View Original Post'),
            onTap: () {
              Navigator.pop(context);
              if (sharedPost['original_post'] != null) {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          PostDetailScreen(post: sharedPost['original_post']),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Unable to view original post')),
                  );
                }
              }
            },
          ),
          if (isOwnSharedPost)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Shared Post',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteSharedPost(sharedPost['id']);
              },
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _deleteSharedPost(String sharedPostId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Shared Post'),
        content:
            const Text('Are you sure you want to delete this shared post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _sharedPostsService.deleteSharedPost(sharedPostId);
        _loadSharedPosts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Shared post deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting shared post: $e')),
          );
        }
      }
    }
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading posts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSharedPosts,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Posts'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Shared'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Received Posts Tab
          RefreshIndicator(
            onRefresh: _loadReceivedPosts,
            child: _isLoadingReceived
                ? const Center(child: CircularProgressIndicator())
                : _errorReceived != null
                    ? _buildErrorState(_errorReceived!)
                    : _receivedPosts.isEmpty
                        ? _buildEmptyState('No shared posts received yet')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _receivedPosts.length,
                            itemBuilder: (context, index) =>
                                _buildSharedPostCard(_receivedPosts[index]
                                    as Map<String, dynamic>),
                          ),
          ),

          // Shared Posts Tab
          RefreshIndicator(
            onRefresh: _loadPostsSharedByUser,
            child: _isLoadingShared
                ? const Center(child: CircularProgressIndicator())
                : _errorShared != null
                    ? _buildErrorState(_errorShared!)
                    : _sharedPosts.isEmpty
                        ? _buildEmptyState('You haven\'t shared any posts yet')
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _sharedPosts.length,
                            itemBuilder: (context, index) =>
                                _buildSharedPostCard(_sharedPosts[index]
                                    as Map<String, dynamic>),
                          ),
          ),
        ],
      ),
    );
  }
}
