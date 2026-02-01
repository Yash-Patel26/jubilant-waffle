import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/home/post_card.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:gamer_flick/models/post/post.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final User? _currentUser = Supabase.instance.client.auth.currentUser;
  late Future<List<Post>> _savedPostsFuture;
  List<Post> _savedPosts = [];

  @override
  void initState() {
    super.initState();
    _savedPostsFuture = _fetchSavedPosts();
  }

  Future<List<Post>> _fetchSavedPosts() async {
    if (_currentUser == null) return [];
    try {
      final savedRows = await Supabase.instance.client
          .from('saved_posts')
          .select('post_id')
          .eq('user_id', _currentUser.id);
      final postIds = savedRows.map((row) => row['post_id']).toList();
      if (postIds.isEmpty) return [];
      
      final postsData = await Supabase.instance.client
          .from('posts')
          .select('*, profiles!posts_user_id_fkey(*), post_likes(*), comments(*)')
          .inFilter('id', postIds);
          
      return (postsData as List).map((data) => Post.fromJson(data)).toList();
    } catch (e) {
      // Handle error
      return [];
    }
  }

  Future<void> _unsavePost(String postId) async {
    if (_currentUser == null) return;
    try {
      await Supabase.instance.client.from('saved_posts').delete().match({
        'user_id': _currentUser.id,
        'post_id': postId,
      });
      if (mounted) {
        setState(() {
          _savedPosts.removeWhere((post) => post.id == postId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post unsaved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error unsaving post: $e')),
        );
      }
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _savedPostsFuture = _fetchSavedPosts();
    });
    await _savedPostsFuture;
  }

  void _confirmUnsave(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsave Post'),
        content: const Text(
            'Are you sure you want to remove this post from your saved posts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unsavePost(postId);
              setState(() {
                _savedPostsFuture = _fetchSavedPosts();
              });
            },
            child: const Text('Unsave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Posts')),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.secondary,
        onRefresh: _refresh,
        child: FutureBuilder<List<Post>>(
          future: _savedPostsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: 6,
                itemBuilder: (context, index) => Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final posts = snapshot.data ?? [];
            _savedPosts = posts;
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/animations/empty_bookmark.json',
                      width: 180,
                      repeat: true,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved posts yet.',
                      style: TextStyle(fontSize: 20, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the bookmark icon on any post to save it here!',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: GridView.builder(
                key: ValueKey(posts.length),
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.7,
                ),
                itemCount: posts.length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return Stack(
                    children: [
                      PostCard(post: post),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.bookmark_remove,
                              color: Colors.red),
                          tooltip: 'Unsave',
                          onPressed: () => _confirmUnsave(post.id),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
