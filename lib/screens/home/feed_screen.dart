import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/home/post_card.dart';
import 'package:gamer_flick/models/post/post.dart';
import 'package:gamer_flick/models/core/profile.dart';
import 'package:gamer_flick/models/community/community.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  List<Post> _posts = [];
  List<Profile> _users = [];
  List<Community> _communities = [];
  String? _selectedUserId;
  String? _selectedCommunityId;
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _fetchFilters();
    _fetchPosts(reset: true);
    _scrollController.addListener(_onScroll);
    _subscribeRealtime();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _fetchPosts();
    }
  }

  Future<void> _fetchFilters() async {
    try {
      final usersRes = await Supabase.instance.client.from('profiles').select('id, username');
      final communitiesRes = await Supabase.instance.client.from('communities').select('id, name');
      setState(() {
        _users = (usersRes as List).map((e) => Profile.fromJson(e)).toList();
        _communities = (communitiesRes as List).map((e) => Community.fromJson(e)).toList();
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _fetchPosts({bool reset = false}) async {
    if (_isFetchingMore || (!_hasMore && !reset)) return;
    setState(() {
      if (reset) {
        _isLoading = true;
        _posts = [];
        _page = 0;
        _hasMore = true;
      }
      _isFetchingMore = true;
      _error = null;
    });

    try {
      var query = Supabase.instance.client.from('posts').select(
            '*, profiles!posts_user_id_fkey(*), post_likes(*), comments(*)',
          );
      if (_selectedUserId != null) {
        query = query.eq('user_id', _selectedUserId!);
      }
      if (_selectedCommunityId != null) {
        query = query.eq('communityId', _selectedCommunityId!);
      }
      final data = await query
          .order('created_at', ascending: false)
          .range(_page * _pageSize, (_page + 1) * _pageSize - 1);
          
      final newPosts = (data as List).map((e) => Post.fromJson(e)).toList();
      setState(() {
        if (reset) {
          _posts = newPosts;
        } else {
          _posts.addAll(newPosts);
        }
        _isLoading = false;
        _isFetchingMore = false;
        _hasMore = newPosts.length == _pageSize;
        if (_hasMore) _page++;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _subscribeRealtime() {
    _channel = Supabase.instance.client
        .channel('public:posts')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'posts',
          callback: (payload) {
            _fetchPosts(reset: true);
          },
        )
        .subscribe();
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedUserId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'User',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Users')),
                ..._users.map(
                  (u) => DropdownMenuItem(
                    value: u.id,
                    child: Text(u.username),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedUserId = val);
                _fetchPosts(reset: true);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedCommunityId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Community',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Communities'),
                ),
                ..._communities.map(
                  (c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (val) {
                setState(() => _selectedCommunityId = val);
                _fetchPosts(reset: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchPosts(reset: true),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Error: $_error'))
                      : _posts.isEmpty
                          ? const Center(child: Text('No posts yet.'))
                          : ListView.builder(
                              controller: _scrollController,
                              itemCount: _posts.length + (_hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _posts.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 24),
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                }
                                final post = _posts[index];
                                return PostCard(
                                  post: post,
                                  onPostDeleted: () => _fetchPosts(reset: true),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
