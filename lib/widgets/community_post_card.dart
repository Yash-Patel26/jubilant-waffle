import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../screens/community/community_detail_screen.dart';
import 'package:gamer_flick/models/community/community_post.dart';

class CommunityPostCard extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  const CommunityPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onComment,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final community = post.community;
    final author = post.author;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (community != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: (community.imageUrl != null &&
                            community.imageUrl!.isNotEmpty)
                        ? NetworkImage(community.imageUrl!)
                        : null,
                    child: (community.imageUrl == null ||
                            community.imageUrl!.isEmpty)
                        ? const Icon(Icons.group, size: 16)
                        : null,
                  ),
                const SizedBox(width: 8),
                if (author != null)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: (author.avatarUrl != null &&
                            author.avatarUrl!.isNotEmpty)
                        ? NetworkImage(author.avatarUrl!)
                        : null,
                    child:
                        (author.avatarUrl == null || author.avatarUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 16)
                            : null,
                  ),
              ],
            ),
            title: Row(
              children: [
                if (author != null)
                  Expanded(
                    child: Text(
                      author.username,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                if (community != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      community.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              DateFormat.yMMMd().add_jm().format(post.createdAt),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            onTap: () {
              if (community != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CommunityDetailScreen(
                      community: community,
                    ),
                  ),
                );
              }
            },
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          if (post.imageUrls.isNotEmpty)
            SizedBox(
              height: 200,
              width: double.infinity,
              child: PageView.builder(
                itemCount: post.imageUrls.length,
                itemBuilder: (context, index) {
                  return CachedNetworkImage(
                    imageUrl: post.imageUrls[index],
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: onLike,
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: onComment,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: onShare,
                ),
                const Spacer(),
                if (post.pinned)
                  const Icon(
                    Icons.push_pin,
                    color: Colors.orange,
                    size: 20,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
