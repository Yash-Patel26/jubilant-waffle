import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserListMode { followers, following }

class FollowersFollowingScreen extends StatefulWidget {
  final String userId;
  final UserListMode mode;
  final bool showAppBar;
  const FollowersFollowingScreen(
      {super.key,
      required this.userId,
      required this.mode,
      this.showAppBar = true});

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  final Map<String, bool> _isFollowing = {};
  final Map<String, bool> _loading = {};
  String get _currentUserId => _supabase.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      List data;
      if (widget.mode == UserListMode.followers) {
        data = await _supabase
            .from('follows')
            .select(
                'follower_id, profiles:follower_id(id, username, profile_picture_url)')
            .eq('following_id', widget.userId);
        _users = data
            .map((e) => Map<String, dynamic>.from(e['profiles']))
            .cast<Map<String, dynamic>>()
            .toList();
      } else {
        data = await _supabase
            .from('follows')
            .select(
                'following_id, profiles:following_id(id, username, profile_picture_url)')
            .eq('follower_id', widget.userId);
        _users = data
            .map((e) => Map<String, dynamic>.from(e['profiles']))
            .cast<Map<String, dynamic>>()
            .toList();
      }

      // Init follow status map
      final ids = _users
          .map((u) => u['id'])
          .where((id) => id != _currentUserId)
          .toList();
      if (ids.isNotEmpty) {
        final followingRows = await _supabase
            .from('follows')
            .select('following_id')
            .eq('follower_id', _currentUserId)
            .inFilter('following_id', ids);
        final followingSet =
            Set<String>.from(followingRows.map((e) => e['following_id']));
        for (final id in ids) {
          _isFollowing[id] = followingSet.contains(id);
          _loading[id] = false;
        }
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  Future<void> _toggleFollow(String userId) async {
    setState(() => _loading[userId] = true);
    final currentlyFollowing = _isFollowing[userId] ?? false;
    try {
      if (currentlyFollowing) {
        await _supabase.from('follows').delete().match({
          'follower_id': _currentUserId,
          'following_id': userId,
        });
      } else {
        await _supabase.from('follows').insert({
          'follower_id': _currentUserId,
          'following_id': userId,
        });
      }
      setState(() => _isFollowing[userId] = !currentlyFollowing);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading[userId] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.mode == UserListMode.followers ? 'Followers' : 'Following';
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(title: Text(title)) : null,
      body: _users.isEmpty
          ? const Center(child: Text('No users found.'))
          : ListView.separated(
              itemCount: _users.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _users[index];
                final id = user['id'] as String;
                final isSelf = id == _currentUserId;
                final following = _isFollowing[id] ?? false;
                final isLoading = _loading[id] ?? false;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user['profile_picture_url'] != null
                        ? NetworkImage(user['profile_picture_url'])
                        : null,
                    child: user['profile_picture_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user['username'] ?? 'Unknown'),
                  trailing: isSelf
                      ? null
                      : ElevatedButton(
                          onPressed: isLoading ? null : () => _toggleFollow(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: following
                                ? Colors.grey.shade800
                                : Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                following ? Colors.white : Colors.black,
                            minimumSize: const Size(90, 36),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text(following ? 'Unfollow' : 'Follow'),
                        ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FollowersFollowingScreen(
                            userId: id, mode: UserListMode.followers),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
