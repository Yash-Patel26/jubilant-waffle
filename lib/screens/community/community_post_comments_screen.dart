import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/community/community_post_notifier.dart';
import 'package:gamer_flick/models/core/user.dart' as app_models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityPostCommentsScreen extends ConsumerStatefulWidget {
  final String postId;
  const CommunityPostCommentsScreen({super.key, required this.postId});

  @override
  ConsumerState<CommunityPostCommentsScreen> createState() =>
      _CommunityPostCommentsScreenState();
}

class _CommunityPostCommentsScreenState
    extends ConsumerState<CommunityPostCommentsScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // No explicit fetch needed as Riverpod handles it via build()
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<app_models.User?> _fetchUser(String userId) async {
    final data = await Supabase.instance.client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return app_models.User.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(communityPostCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: commentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (comments) {
          return Column(
            children: [
              Expanded(
                child: comments.isEmpty
                    ? const Center(child: Text('No comments yet.'))
                    : ListView.builder(
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return FutureBuilder<app_models.User?>(
                            future: _fetchUser(comment.userId),
                            builder: (context, snapshot) {
                              final user = snapshot.data;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user?.profilePicture != null
                                      ? CachedNetworkImageProvider(
                                          user!.profilePicture!)
                                      : null,
                                  child: user?.profilePicture == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(user?.displayName ?? 'User'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(comment.content),
                                    Text(
                                      DateFormat('yMMMd, h:mm a')
                                          .format(comment.createdAt),
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
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
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final text = _controller.text.trim();
                        if (text.isNotEmpty) {
                          await ref.read(communityPostsProvider(CommunityPostParams(communityId: '')).notifier).addComment(widget.postId, text);
                          _controller.clear();
                        }
                      },
                      child: const Text('Post'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
