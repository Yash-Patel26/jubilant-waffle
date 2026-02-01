import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentScreen extends StatefulWidget {
  final String postId;

  const CommentScreen({super.key, required this.postId});

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  late Future<List<dynamic>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void initState() {
    super.initState();
    _commentsFuture = _fetchComments();
  }

  Future<List<dynamic>> _fetchComments() async {
    final data = await Supabase.instance.client
        .from('comments')
        .select(
            '*, profile:profiles!user_id(id, username, avatar_url, profile_picture_url)')
        .eq('post_id', widget.postId)
        .order('created_at', ascending: true);
    return data;
  }

  Future<void> _postComment() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || _commentController.text.isEmpty) {
      return;
    }
    setState(() => _isPosting = true);
    try {
      await Supabase.instance.client.from('comments').insert({
        'post_id': widget.postId,
        'user_id': currentUser.id,
        'content': _commentController.text,
      });
      _commentController.clear();
      setState(() {
        _commentsFuture = _fetchComments();
      });
    } finally {
      setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }
                final comments = snapshot.data!;
                return ListView.builder(
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    final profile = comment['profile'] ?? {};
                    final username = (profile['username'] ??
                            comment['username'] ??
                            'Anonymous')
                        .toString();
                    final avatarUrl =
                        profile['avatar_url'] ?? profile['profile_picture_url'];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: (avatarUrl != null && avatarUrl != '')
                            ? NetworkImage(avatarUrl)
                            : null,
                        child: (avatarUrl == null || avatarUrl == '')
                            ? Text(username.isNotEmpty
                                ? username[0].toUpperCase()
                                : 'A')
                            : null,
                      ),
                      title: Text(username),
                      subtitle: Text(comment['content'] ?? 'No content'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                    ),
                  ),
                ),
                _isPosting
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.0),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _postComment,
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
