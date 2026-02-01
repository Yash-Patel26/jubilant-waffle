import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/post/post_service.dart';
import 'package:gamer_flick/services/post/reel_service.dart';
import 'package:gamer_flick/utils/error_handler.dart';
import '../extensions/string_extensions.dart';
import 'package:gamer_flick/services/chat/enhanced_messaging_service.dart';

class SharedContentSelectionDialog extends ConsumerStatefulWidget {
  final String contentId;
  final String contentType; // 'post' or 'reel'
  final String? initialMessage;
  final VoidCallback? onShared;

  const SharedContentSelectionDialog({
    super.key,
    required this.contentId,
    required this.contentType,
    this.initialMessage,
    this.onShared,
  });

  @override
  ConsumerState<SharedContentSelectionDialog> createState() =>
      _SharedContentSelectionDialogState();
}

class _SharedContentSelectionDialogState
    extends ConsumerState<SharedContentSelectionDialog> {
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  bool _isLoading = false;
  String? _error;
  Map<String, List<Map<String, dynamic>>> _shareableUsers = {
    'followers': [],
    'following': [],
  };
  late final ScrollController _scrollController;

  late final PostService _postService;
  late final ReelService _reelService;
  late final EnhancedMessagingService _messagingService;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _postService = PostService();
    _reelService = ReelService();
    _messagingService = EnhancedMessagingService();

    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }

    _loadShareableUsers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadShareableUsers() async {
    try {
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_loadShareableUsers start contentType=${widget.contentType} contentId=${widget.contentId}');
      setState(() => _isLoading = true);

      Map<String, List<Map<String, dynamic>>> users;
      if (widget.contentType == 'post') {
        users = await _postService.getShareableUsers();
      } else {
        users = await _reelService.getShareableUsers();
      }

      setState(() {
        _shareableUsers = users;
        _isLoading = false;
      });

      // Check if no users found
      if (users['followers']!.isEmpty && users['following']!.isEmpty) {
        setState(() {
          _error =
              'No followers or following users found. You need to have followers or be following users to share content.';
        });
        ErrorHandler.logWarning(
            'SharedContentSelectionDialog:_loadShareableUsers no users available');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load users: $e';
        _isLoading = false;
      });
      ErrorHandler.logError('Failed to load shareable users', e);
    }
  }

  Future<void> _shareContent() async {
    if (_selectedUserIds.isEmpty) {
      setState(() => _error = 'Please select at least one user to share with');
      return;
    }

    try {
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_shareContent start contentType=${widget.contentType} contentId=${widget.contentId} recipients=${_selectedUserIds.length}');
      setState(() => _isLoading = true);

      bool success;
      if (widget.contentType == 'post') {
        success = await _postService.sharePost(
          postId: widget.contentId,
          recipientIds: _selectedUserIds.toList(),
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      } else {
        success = await _reelService.shareReel(
          reelId: widget.contentId,
          recipientIds: _selectedUserIds.toList(),
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      }

      if (success) {
        // Send messages to each selected user
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_shareContent success; sending messages');
        await _sendSharedContentMessages();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.contentType.capitalize()} shared successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onShared?.call();
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _error = 'Failed to share ${widget.contentType}');
        ErrorHandler.logWarning(
            'SharedContentSelectionDialog:_shareContent backend returned false');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ErrorHandler.logError(
          'SharedContentSelectionDialog:_shareContent error', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSharedContentMessages() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Get current user profile for sender info
      // Ensure profile exists for sender context
      await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', currentUser.id)
          .single();

      for (final userId in _selectedUserIds) {
        // Find or create conversation with this user
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_sendSharedContentMessages ensure conversation with=$userId');
        final conversationId =
            await _getOrCreateConversation(currentUser.id, userId);

        if (conversationId != null) {
          // Send shared content message
          await _messagingService.shareContent(
            conversationId: conversationId,
            senderId: currentUser.id,
            contentId: widget.contentId,
            contentType: widget.contentType,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
          ErrorHandler.logInfo(
              'SharedContentSelectionDialog:sent share message to=$userId');
        } else {
          ErrorHandler.logWarning(
              'SharedContentSelectionDialog:failed to get conversation for=$userId');
        }
      }
    } catch (e) {
      ErrorHandler.logError('Failed to send shared content messages', e);
    }
  }

  Future<String?> _getOrCreateConversation(
      String user1Id, String user2Id) async {
    try {
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_getOrCreateConversation start users=[$user1Id,$user2Id]');
      // Check if conversation already exists by looking at participants
      final existingConversations = await Supabase.instance.client
          .from('conversation_participants')
          .select('conversation_id')
          .inFilter('user_id', [user1Id, user2Id]);

      // Group by conversation_id and find one with both users
      final conversationCounts = <String, int>{};
      for (final conv in existingConversations) {
        final convId = conv['conversation_id'] as String;
        conversationCounts[convId] = (conversationCounts[convId] ?? 0) + 1;
      }

      // Find conversation with both users
      String? existingConversationId;
      for (final entry in conversationCounts.entries) {
        if (entry.value == 2) {
          existingConversationId = entry.key;
          break;
        }
      }

      if (existingConversationId != null) {
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_getOrCreateConversation found existing id=$existingConversationId');
        return existingConversationId;
      }

      // Create new conversation
      final newConversation = await Supabase.instance.client
          .from('conversations')
          .insert({
            'type': 'direct',
            'created_by': user1Id,
            'created_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .select()
          .single();
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_getOrCreateConversation created new id=${newConversation['id']}');

      // Add participants
      await Supabase.instance.client.from('conversation_participants').insert([
        {
          'conversation_id': newConversation['id'],
          'user_id': user1Id,
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        },
        {
          'conversation_id': newConversation['id'],
          'user_id': user2Id,
          'joined_at': DateTime.now().toUtc().toIso8601String(),
        },
      ]);

      return newConversation['id'];
    } catch (e) {
      ErrorHandler.logError('Failed to get or create conversation', e);
      return null;
    }
  }

  Future<void> _shareWithFollowers() async {
    try {
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_shareWithFollowers start contentType=${widget.contentType} contentId=${widget.contentId}');
      setState(() => _isLoading = true);

      bool success;
      if (widget.contentType == 'post') {
        success = await _postService.sharePostWithFollowers(
          postId: widget.contentId,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      } else {
        success = await _reelService.shareReelWithFollowers(
          reelId: widget.contentId,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      }

      if (success) {
        // Send messages to all followers
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_shareWithFollowers success; sending messages');
        await _sendSharedContentMessagesToFollowers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.contentType.capitalize()} shared with all followers!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onShared?.call();
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _error = 'Failed to share with followers');
        ErrorHandler.logWarning(
            'SharedContentSelectionDialog:_shareWithFollowers backend returned false');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ErrorHandler.logError(
          'SharedContentSelectionDialog:_shareWithFollowers error', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSharedContentMessagesToFollowers() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Get current user profile for sender info
      // Ensure profile exists for sender context
      await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', currentUser.id)
          .single();

      // Get all follower IDs
      final followerIds = _shareableUsers['followers']!
          .map((user) => user['id'] as String)
          .toList();

      for (final followerId in followerIds) {
        // Find or create conversation with this follower
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_sendSharedContentMessagesToFollowers ensure conversation with=$followerId');
        final conversationId =
            await _getOrCreateConversation(currentUser.id, followerId);

        if (conversationId != null) {
          // Send shared content message
          await _messagingService.shareContent(
            conversationId: conversationId,
            senderId: currentUser.id,
            contentId: widget.contentId,
            contentType: widget.contentType,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
          ErrorHandler.logInfo(
              'SharedContentSelectionDialog:sent share message to follower=$followerId');
        }
      }
    } catch (e) {
      ErrorHandler.logError(
          'Failed to send shared content messages to followers', e);
    }
  }

  Future<void> _shareWithFollowing() async {
    try {
      ErrorHandler.logInfo(
          'SharedContentSelectionDialog:_shareWithFollowing start contentType=${widget.contentType} contentId=${widget.contentId}');
      setState(() => _isLoading = true);

      bool success;
      if (widget.contentType == 'post') {
        success = await _postService.sharePostWithFollowing(
          postId: widget.contentId,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      } else {
        success = await _reelService.shareReelWithFollowing(
          reelId: widget.contentId,
          message: _messageController.text.trim().isEmpty
              ? null
              : _messageController.text.trim(),
        );
      }

      if (success) {
        // Send messages to all following users
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_shareWithFollowing success; sending messages');
        await _sendSharedContentMessagesToFollowing();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.contentType.capitalize()} shared with all following!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onShared?.call();
          Navigator.of(context).pop();
        }
      } else {
        setState(() => _error = 'Failed to share with following');
        ErrorHandler.logWarning(
            'SharedContentSelectionDialog:_shareWithFollowing backend returned false');
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ErrorHandler.logError(
          'SharedContentSelectionDialog:_shareWithFollowing error', e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendSharedContentMessagesToFollowing() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      // Get current user profile for sender info
      // Ensure profile exists for sender context
      await Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', currentUser.id)
          .single();

      // Get all following user IDs
      final followingIds = _shareableUsers['following']!
          .map((user) => user['id'] as String)
          .toList();

      for (final followingId in followingIds) {
        // Find or create conversation with this following user
        ErrorHandler.logInfo(
            'SharedContentSelectionDialog:_sendSharedContentMessagesToFollowing ensure conversation with=$followingId');
        final conversationId =
            await _getOrCreateConversation(currentUser.id, followingId);

        if (conversationId != null) {
          // Send shared content message
          await _messagingService.shareContent(
            conversationId: conversationId,
            senderId: currentUser.id,
            contentId: widget.contentId,
            contentType: widget.contentType,
            message: _messageController.text.trim().isEmpty
                ? null
                : _messageController.text.trim(),
          );
          ErrorHandler.logInfo(
              'SharedContentSelectionDialog:sent share message to following=$followingId');
        }
      }
    } catch (e) {
      ErrorHandler.logError(
          'Failed to send shared content messages to following', e);
    }
  }

  void _toggleUserSelection(String userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Widget _buildUserList(
      String title, List<Map<String, dynamic>> users, Color typeColor) {
    if (users.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No $title found',
          style: TextStyle(
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...users.map((user) => _buildUserTile(user, typeColor)),
      ],
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, Color typeColor) {
    final isSelected = _selectedUserIds.contains(user['id']);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _toggleUserSelection(user['id']),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor.withOpacity(0.9),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? typeColor.withOpacity(0.7)
                : Theme.of(context).dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: typeColor.withOpacity(0.25),
                    blurRadius: 14,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: user['avatar_url'] != null
                  ? NetworkImage(user['avatar_url'])
                  : null,
              child:
                  user['avatar_url'] == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['display_name'] ?? user['username'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '@${user['username'] ?? 'unknown'}',
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user['type'] ?? 'user',
                style: TextStyle(
                  color: typeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? typeColor : Theme.of(context).dividerColor,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canShare = _selectedUserIds.isNotEmpty && !_isLoading;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 640, maxWidth: 460),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.cyan.withOpacity(0.12),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0EA5EA), Color(0xFF8A2BE2)],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.share, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Share ${widget.contentType.capitalize()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Message input
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Add a message (optional)',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    prefixIcon: const Icon(Icons.message),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: Color(0xFF0EA5EA), width: 1.5),
                    ),
                  ),
                ),
              ),

              // Quick share buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _GradientPillButton(
                        icon: Icons.people,
                        label: 'Followers',
                        colors: const [Color(0xFF22C55E), Color(0xFF16A34A)],
                        onTap: _isLoading ? null : _shareWithFollowers,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _GradientPillButton(
                        icon: Icons.person_add,
                        label: 'Following',
                        colors: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                        onTap: _isLoading ? null : _shareWithFollowing,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Divider(height: 1, color: theme.dividerColor),

              // User selection
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red, size: 48),
                                  const SizedBox(height: 16),
                                  Text(_error!,
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                      onPressed: _loadShareableUsers,
                                      child: const Text('Retry')),
                                ],
                              ),
                            ),
                          )
                        : Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              primary: false,
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Column(
                                children: [
                                  _buildUserList(
                                      'Followers',
                                      _shareableUsers['followers'] ?? [],
                                      const Color(0xFF22C55E)),
                                  _buildUserList(
                                      'Following',
                                      _shareableUsers['following'] ?? [],
                                      const Color(0xFF3B82F6)),
                                ],
                              ),
                            ),
                          ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: canShare
                          ? _GradientPillButton(
                              icon: Icons.send,
                              label:
                                  'Share with ${_selectedUserIds.length} users',
                              colors: const [
                                Color(0xFF0EA5EA),
                                Color(0xFF8A2BE2)
                              ],
                              onTap: _shareContent,
                            )
                          : OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: theme.dividerColor),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text('Select users to share'),
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

class _GradientPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;

  const _GradientPillButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: Ink(
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: colors,
                )
              : null,
          color:
              enabled ? null : Theme.of(context).disabledColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
