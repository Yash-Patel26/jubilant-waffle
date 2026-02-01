import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/models/chat/message.dart';
import 'package:gamer_flick/providers/chat/conversation_providers.dart'; // Re-add this import
import '../../widgets/message_bubble.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? conversationId;
  final String? otherUserId;

  const ChatScreen({
    super.key,
    this.conversationId,
    this.otherUserId,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  String? _selectedConversationId;
  String? _selectedOtherUserId; // Add this to hold the other user's ID
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final bool _isLoading = false;
  final List<Message> _localMessages = []; // For immediate UI updates

  String get _currentUserId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _selectedConversationId = widget.conversationId; // Initialize from widget
    _selectedOtherUserId = widget.otherUserId; // Initialize from widget
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the conversationId or otherUserId has changed
    if (widget.conversationId != oldWidget.conversationId ||
        widget.otherUserId != oldWidget.otherUserId) {
      setState(() {
        _selectedConversationId = widget.conversationId;
        _selectedOtherUserId = widget.otherUserId;
        _localMessages
            .clear(); // Clear local messages when conversation changes
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();
    _scrollToBottom();

    final messagingService = ref.read(messagingServiceProvider);
    await messagingService.sendMessage(
      conversationId: _selectedConversationId!,
      senderId: _currentUserId,
      text: text,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    if (isMobile) {
      return _buildMobileChatScreen();
    } else {
      return _buildDesktopChatScreen();
    }
  }

  Widget _buildMobileChatScreen() {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // Use background color
      appBar: AppBar(
        backgroundColor:
            theme.colorScheme.surface, // Use surface color for AppBar
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0, // Remove elevation for flat, modern look
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: _selectedOtherUserId !=
                null // Use _selectedOtherUserId directly if available
            ? Consumer(builder: (context, ref, child) {
                final otherUserProfile =
                    ref.watch(userProfileProvider(_selectedOtherUserId!));
                return otherUserProfile.when(
                  data: (profile) => Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: profile['avatar_url'] != null
                            ? NetworkImage(profile['avatar_url'])
                            : null,
                        child: profile['avatar_url'] == null
                            ? Text(
                                (profile['username'] as String? ?? 'U')[0]
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile['username'] ?? 'Unknown User',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Online',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  loading: () => Text('Loading...',
                      style: TextStyle(color: theme.colorScheme.onSurface)),
                  error: (error, stack) => Text('Error',
                      style: TextStyle(color: theme.colorScheme.error)),
                );
              })
            : Text('Loading...',
                style: TextStyle(color: theme.colorScheme.onSurface)),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurface),
            onPressed: () {
              // Show more options
            },
          ),
        ],
      ),
      body: _buildChatBody(),
    );
  }

  Widget _buildDesktopChatScreen() {
    return Container(
      color: Theme.of(context).colorScheme.surface, // Use background color
      child: Column(
        children: [
          // Chat Header
          _buildChatHeader(),

          // Chat Messages Area
          Expanded(
            child: _buildChatBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface, // Use surface color for header
        border: Border(
          bottom: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
              width: 1), // Subtle border
        ),
      ),
      child: _selectedOtherUserId !=
              null // Use _selectedOtherUserId directly if available
          ? Consumer(builder: (context, ref, child) {
              final otherUserProfile =
                  ref.watch(userProfileProvider(_selectedOtherUserId!));
              return otherUserProfile.when(
                data: (profile) => Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: profile['avatar_url'] != null
                          ? NetworkImage(profile['avatar_url'])
                          : null,
                      child: profile['avatar_url'] == null
                          ? Text(
                              (profile['username'] as String? ?? 'U')[0]
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile['username'] ?? 'Unknown User',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const Text(
                            'Online',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        // Add more participants or start group chat
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () {
                        // Show chat options menu
                      },
                    ),
                  ],
                ),
                loading: () => const Row(
                  children: [
                    CircleAvatar(),
                    SizedBox(width: 12),
                    Text('Loading...'),
                  ],
                ),
                error: (error, stack) => const Row(
                  children: [
                    CircleAvatar(child: Icon(Icons.error)),
                    SizedBox(width: 12),
                    Text('Error loading user'),
                  ],
                ),
              );
            })
          : const Row(
              children: [
                CircleAvatar(),
                SizedBox(width: 12),
                Text('Loading...'),
              ],
            ),
    );
  }

  Widget _buildChatBody() {
    if (_selectedConversationId == null) {
      return const Center(
        child: Text('Select a conversation to start chatting'),
      );
    }

    final messagesAsync =
        ref.watch(messageListProvider(_selectedConversationId!));

    return Column(
      children: [
        // Messages Area
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              // Deduplicate: Remove local messages that are already present in serverMessages
              final serverMessages = messages;
              final localMessages = _localMessages;
              final filteredLocalMessages = localMessages
                  .where((local) => !serverMessages.any((server) =>
                      server.content == local.content &&
                      server.senderId == local.senderId &&
                      (server.createdAt.difference(local.createdAt).inSeconds)
                              .abs() <
                          5))
                  .toList();

              final allMessages = [...serverMessages, ...filteredLocalMessages];
              allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

              // Mark messages as delivered and seen if they are from others and not already marked
              final messagingService = ref.read(messagingServiceProvider);
              for (final message in allMessages) {
                if (message.senderId != _currentUserId &&
                    !message.isDelivered) {
                  messagingService.updateMessageStatus(
                    messageId: message.id,
                    isDelivered: true,
                    isSeen: true,
                  );
                }
              }

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(bottom: 16.0),
                itemCount: allMessages.length,
                itemBuilder: (context, index) {
                  final message = allMessages[index];
                  final isMyMessage = message.senderId == _currentUserId;

                  return _buildMessageBubble(message, isMyMessage);
                },
              );
            },
            loading: () {
              return const Center(child: CircularProgressIndicator());
            },
            error: (error, stack) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading messages: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh the stream
                        ref.invalidate(
                            messageListProvider(_selectedConversationId!));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Message Input Area
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, bool isMyMessage) {
    return MessageBubble(
      message: message,
      isMyMessage: isMyMessage,
      onTap: () {
        // Handle message tap if needed
      },
    );
  }

  Widget _buildMessageInput() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_circle_outline,
                color: theme.colorScheme.primary,
                size: 28), // Gaming style attachment icon
            onPressed: () {
              // Handle file attachment
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme
                    .surfaceContainerHighest, // Use card color for input background
                borderRadius: BorderRadius.circular(28), // More rounded corners
                border: Border.all(
                  color: theme.colorScheme.primary
                      .withOpacity(0.4), // Accent border
                  width: 1.5, // Slightly thicker border
                ),
              ),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14, // Adjusted vertical padding
                  ),
                ),
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 16,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary, // Primary color for send button
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ], // Add a subtle shadow
            ),
            child: IconButton(
              icon: Icon(
                Icons.send_rounded, // Use a more modern send icon
                color: theme.colorScheme.onPrimary,
                size: 28, // Slightly larger icon
              ),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
