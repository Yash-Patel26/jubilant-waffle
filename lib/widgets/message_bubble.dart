import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/models/chat/message.dart';
import '../screens/post/post_detail_screen.dart'; // Import PostDetailScreen
import '../screens/reels/explore_reels_screen.dart'; // Import ExploreReelsScreen
import 'package:gamer_flick/services/post/post_service.dart'; // Import PostService

class MessageBubble extends ConsumerWidget {
  final Message message;
  final bool isMyMessage;
  final VoidCallback? onTap;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMyMessage,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    Widget content;

    // Handle shared content first
    if (message.hasSharedContent) {
      content = _buildSharedContentBubble(context, theme);
    } else if (message.content.isNotEmpty) {
      content = _buildTextBubble(context, theme);
    } else {
      content = _buildMediaBubble(context, theme);
    }

    return Align(
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMyMessage ? 64 : 16,
          right: isMyMessage ? 16 : 64,
          top: 8,
          bottom: 8,
        ),
        child: content,
      ),
    );
  }

  Widget _buildTextBubble(BuildContext context, ThemeData theme) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
            color: isMyMessage
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
          message.content,
                        style: TextStyle(
              color: isMyMessage
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),
      );
  }

  Widget _buildMediaBubble(BuildContext context, ThemeData theme) {
    return Container(
        padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Media message',
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
      );
    }

  Widget _buildSharedContentBubble(BuildContext context, ThemeData theme) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(
        color: isMyMessage
            ? theme.colorScheme.primary.withOpacity(0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMyMessage
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with content type and icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMyMessage
                  ? theme.colorScheme.primary.withOpacity(0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  message.isSharedPost ? Icons.article : Icons.video_library,
                  size: 20,
                  color: isMyMessage
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  message.isSharedPost ? 'Shared Post' : 'Shared Reel',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isMyMessage
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Content preview
          GestureDetector(
            // Wrap the content preview in GestureDetector
            onTap: () async {
              // Made onTap async
              if (message.sharedContentId != null) {
                if (message.isSharedPost) {
                  // Fetch the full post data
                  final postData = await PostService().getPostById(
                      message.sharedContentId!);
                  if (postData != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: postData.toJson()),
                      ),
                    );
                  }
                } else if (message.isSharedReel) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExploreReelsScreen(
                          initialReelId: message.sharedContentId!),
                    ),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12), // Adjusted padding here
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message text if any
                  if (message.content.isNotEmpty) ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: isMyMessage
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // "Tap to view" section
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          message.isSharedPost
                              ? Icons.article
                              : Icons.video_library,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.isSharedPost
                                ? 'Tap to view post'
                                : 'Tap to view reel',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
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
}
