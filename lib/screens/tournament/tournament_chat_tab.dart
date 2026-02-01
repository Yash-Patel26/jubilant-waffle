import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class TournamentChatTab extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic>? currentUserRole;

  const TournamentChatTab({
    super.key,
    required this.tournamentId,
    this.currentUserRole,
  });

  @override
  _TournamentChatTabState createState() => _TournamentChatTabState();
}

class _TournamentChatTabState extends State<TournamentChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  String? _error;
  late StreamSubscription<List<Map<String, dynamic>>> _messagesSubscription;
  Map<String, dynamic>? _currentUserProfile; // used for avatar/name resolution
  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToMessages();
    _fetchCurrentUserProfile();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messagesSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('tournament_messages')
          .select('''
            *,
            profile:profiles(id, username, avatar_url, full_name)
          ''')
          .eq('tournament_id', widget.tournamentId)
          .order('created_at', ascending: true);

      setState(() {
        _messages.clear();
        _messages.addAll(response.map((e) => Map<String, dynamic>.from(e)));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _subscribeToMessages() {
    _messagesSubscription = Supabase.instance.client
        .from('tournament_messages')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', widget.tournamentId)
        .order('created_at', ascending: true)
        .listen(
          (messages) {
            if (mounted) {
              setState(() {
                _messages.clear();
                _messages
                    .addAll(messages.map((e) => Map<String, dynamic>.from(e)));
              });
            }
          },
          onError: (e) {
            if (mounted) {
              setState(() => _error = e.toString());
            }
          },
        );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to send messages')),
      );
      return;
    }

    try {
      await Supabase.instance.client.from('tournament_messages').insert({
        'tournament_id': widget.tournamentId,
        'user_id': user.id,
        'message': message,
        'message_type':
            'general', // Changed from 'chat' to 'general' to match DB schema
        'created_at': DateTime.now().toIso8601String(),
      });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  Future<void> _sendAnnouncement() async {
    final message = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Send Announcement'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter announcement message...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (message == null || message.trim().isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('tournament_messages').insert({
        'tournament_id': widget.tournamentId,
        'user_id': user.id,
        'message': message.trim(),
        'message_type': 'announcement',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending announcement: $e')),
        );
      }
    }
  }

  bool get _canSendAnnouncements {
    if (widget.currentUserRole == null) return false;
    final permissions =
        widget.currentUserRole!['permissions'] as Map<String, dynamic>?;
    return permissions?['can_post_announcements'] == true;
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're on mobile
    final isMobile = MediaQuery.of(context).size.width < 600;
    final cardPadding = isMobile ? 16.0 : 20.0;
    final horizontalPadding = isMobile ? 12.0 : 16.0;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchMessages,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          // Chat Header
          Container(
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.blue.shade700,
                    size: isMobile ? 20 : 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tournament Chat',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Share strategies, ask questions, and connect with other players',
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 13,
                          color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.7) ??
                              Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.green.shade500,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_messages.length} Online',
                        style: TextStyle(
                          fontSize: isMobile ? 11 : 12,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Chat Messages
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: _messages.isEmpty
                  ? Center(
                      child: Container(
                        padding: EdgeInsets.all(cardPadding),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .shadowColor
                                  .withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: isMobile ? 48 : 64,
                              color: Theme.of(context).dividerColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chat will be more active as more players join',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color ??
                                    Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Share strategies, ask questions, and connect with other players',
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: cardPadding),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final sortedMessages =
                            List<Map<String, dynamic>>.from(_messages)
                              ..sort((a, b) => DateTime.parse(a['created_at'])
                                  .compareTo(DateTime.parse(b['created_at'])));
                        final message = sortedMessages[index];
                        final profile = message['profile'];
                        final isAnnouncement =
                            message['message_type'] == 'announcement';
                        final isCurrentUser = message['user_id'] ==
                            Supabase.instance.client.auth.currentUser?.id;

                        return Container(
                          margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser) ...[
                                _buildAvatar(
                                  profile: profile,
                                  isCurrentUser: false,
                                  isMobile: isMobile,
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: isCurrentUser
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    if (!isCurrentUser)
                                      Row(
                                        children: [
                                          Text(
                                            profile?['full_name'] ??
                                                profile?['username'] ??
                                                'Unknown User',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: isMobile ? 13 : 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                  color: Colors.green.shade200),
                                            ),
                                            child: Text(
                                              'Participant',
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: isMobile ? 9 : 10,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          if (isAnnouncement) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color:
                                                        Colors.orange.shade200),
                                              ),
                                              child: Text(
                                                'ANNOUNCEMENT',
                                                style: TextStyle(
                                                  color: Colors.orange.shade700,
                                                  fontSize: isMobile ? 9 : 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding:
                                          EdgeInsets.all(isMobile ? 10 : 12),
                                      decoration: BoxDecoration(
                                        color: isAnnouncement
                                            ? Colors.orange.shade50
                                            : isCurrentUser
                                                ? Colors.blue.shade50
                                                : Theme.of(context).cardColor,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isAnnouncement
                                              ? Colors.orange.shade200
                                              : isCurrentUser
                                                  ? Colors.blue.shade200
                                                  : Theme.of(context)
                                                      .dividerColor
                                                      .withOpacity(0.3),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .shadowColor
                                                .withOpacity(0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        message['message'],
                                        style: TextStyle(
                                          color: isAnnouncement
                                              ? Colors.orange.shade800
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                          fontSize: isMobile ? 14 : 15,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _getTimeAgo(DateTime.parse(
                                          message['created_at'])),
                                      style: TextStyle(
                                        color: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.color
                                                ?.withOpacity(0.8) ??
                                            Colors.grey,
                                        fontSize: isMobile ? 11 : 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isCurrentUser) ...[
                                const SizedBox(width: 12),
                                _buildAvatar(
                                  profile: profile,
                                  isCurrentUser: true,
                                  isMobile: isMobile,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Message Input
          Container(
            margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
            padding: EdgeInsets.all(cardPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    if (_canSendAnnouncements)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: _sendAnnouncement,
                          icon: Icon(
                            Icons.announcement,
                            color: Colors.orange.shade600,
                            size: isMobile ? 20 : 24,
                          ),
                          tooltip: 'Send Announcement',
                        ),
                      ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: TextStyle(
                            color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.7) ??
                                Colors.grey,
                            fontSize: isMobile ? 14 : 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.blue.shade400),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 10 : 12,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade500, Colors.blue.shade600],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: _sendMessage,
                        icon: Icon(
                          Icons.send,
                          color: Theme.of(context).cardColor,
                        ),
                        tooltip: 'Send Message',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Be respectful and follow tournament guidelines',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.8) ??
                        Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: horizontalPadding),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildAvatar({
    required Map<String, dynamic>? profile,
    required bool isCurrentUser,
    required bool isMobile,
  }) {
    String? avatarUrl = profile?['avatar_url'];
    String displayName =
        profile?['full_name'] ?? profile?['username'] ?? 'Unknown User';
    String initials = _getInitials(displayName);

    // Try to get avatar from Supabase storage if it's a relative path
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      if (!avatarUrl.startsWith('http')) {
        // If it's a storage path, construct the full URL
        try {
          avatarUrl = Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(avatarUrl);
        } catch (e) {
          print('Error getting avatar URL: $e');
          avatarUrl = null;
        }
      }
    }

    return CircleAvatar(
      radius: isMobile ? 18 : 20,
      backgroundColor: isCurrentUser
          ? Colors.blue.shade100
          : Theme.of(context).dividerColor.withOpacity(0.3),
      backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
      child: avatarUrl == null
          ? Text(
              initials.toUpperCase(),
              style: TextStyle(
                color: isCurrentUser
                    ? Colors.blue.shade700
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 14 : 16,
              ),
            )
          : null,
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';

    List<String> parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    } else if (parts.length == 1) {
      return parts[0][0];
    }
    return 'U';
  }

  Future<void> _fetchCurrentUserProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('profiles')
            .select('id, username, avatar_url, full_name')
            .eq('id', user.id)
            .single();

        setState(() {
          _currentUserProfile = response;
        });
      }
    } catch (e) {
      print('Error fetching current user profile: $e');
    }
  }
}
