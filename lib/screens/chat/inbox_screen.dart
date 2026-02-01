import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/providers/chat/conversation_providers.dart';
import 'chat_screen.dart';
import 'package:gamer_flick/models/chat/conversation.dart';
import '../../utils/time_utils.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen> {
  int _selectedTab = 0; // 0 = Messages, 1 = Requests
  String? _selectedConversationId;
  String? _selectedOtherUserId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Helper method to get the other user ID from conversation participants
  Future<String?> _getOtherUserId(
      String conversationId, String currentUserId) async {
    try {
      final participants = await Supabase.instance.client
          .from('conversation_participants')
          .select('user_id')
          .eq('conversation_id', conversationId);

      final participantIds =
          (participants as List).map((p) => p['user_id'] as String).toList();

      // Return the other participant (not the current user)
      return participantIds.where((id) => id != currentUserId).firstOrNull;
    } catch (e) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your messages.')),
      );
    }

    // Use mobile layout for smaller screens
    if (isMobile) {
      return _buildMobileLayout(userId);
    }

    // Use desktop layout for larger screens (without navigation sidebar)
    return _buildDesktopLayout(userId);
  }

  Widget _buildMobileLayout(String userId) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: const Color(0xFF0A0A0A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          _buildSearchBar(),

          // Tab bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? const Color(0xFF6C7FFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Messages',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedTab == 0 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? const Color(0xFF6C7FFF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Requests',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color:
                              _selectedTab == 1 ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedTab == 0
                ? _buildConversationsList(userId)
                : _buildRequestsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String userId) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('profiles')
          .select('username, avatar_url, profile_picture_url')
          .eq('id', userId)
          .maybeSingle(),
      builder: (context, snapshot) {
        final username = snapshot.data?['username'] ?? 'User';
        final avatarUrl = snapshot.data?['avatar_url'] ??
            snapshot.data?['profile_picture_url'];

        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Row(
            children: [
              // Sidebar with conversation list
              Container(
                width: 370,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  border: Border(
                    right: BorderSide(color: Colors.grey[800]!, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundImage:
                                avatarUrl != null && avatarUrl.isNotEmpty
                                    ? NetworkImage(avatarUrl)
                                    : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              username,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    // Search bar
                    _buildSearchBar(),

                    // Tab bar
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 0),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 0
                                      ? const Color(0xFF6C7FFF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Messages',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 0
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedTab = 1),
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _selectedTab == 1
                                      ? const Color(0xFF6C7FFF)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Requests',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 1
                                        ? Colors.white
                                        : Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildConversationsList(userId)
                          : _buildRequestsList(),
                    ),
                  ],
                ),
              ),

              // Chat area
              Expanded(
                child: _selectedConversationId != null
                    ? ChatScreen(
                        conversationId: _selectedConversationId,
                        otherUserId:
                            _selectedOtherUserId, // Pass the other user ID
                      )
                    : _buildEmptyChatArea(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationsList(String userId) {
    final conversationsAsync = ref.watch(conversationListProvider(userId));

    return conversationsAsync.when(
      data: (conversations) {
        if (conversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations yet.\nStart a conversation with someone!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        // Filter conversations based on search query
        final filteredConversations = conversations.where((conversation) {
          if (_searchQuery.isEmpty) return true;
          // You can add more search criteria here
          return true; // For now, show all conversations
        }).toList();

        if (filteredConversations.isEmpty) {
          return const Center(
            child: Text(
              'No conversations found.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = filteredConversations[index];
            return FutureBuilder<String?>(
              future: _getOtherUserId(conversation.id, userId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ListTile(
                    leading: CircleAvatar(),
                    title: Text('Loading...'),
                  );
                }

                final otherUserId = snapshot.data!;
                final otherUserProfile =
                    ref.watch(userProfileProvider(otherUserId));

                return otherUserProfile.when(
                  data: (profile) => _buildConversationTile(
                    conversation,
                    profile,
                    otherUserId,
                  ),
                  loading: () => const ListTile(
                    leading: CircleAvatar(),
                    title: Text('Loading...'),
                    subtitle: Text('...'),
                  ),
                  error: (error, stack) => ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.error)),
                    title: const Text('Error loading user'),
                    subtitle: Text('$error'),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildRequestsList() {
    return const Center(
      child: Text(
        'No requests yet.',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    Conversation conversation,
    Map<String, dynamic> otherUserProfile,
    String otherUserId,
  ) {
    final isSelected = _selectedConversationId == conversation.id;
    final lastMessage = conversation.lastMessage ?? 'No messages yet';
    final timeAgo = _formatTimeAgo(conversation.updatedAt);
    final isMobile = MediaQuery.of(context).size.width < 800;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: otherUserProfile['avatar_url'] != null
                ? NetworkImage(otherUserProfile['avatar_url'])
                : null,
            child: otherUserProfile['avatar_url'] == null
                ? Text(
                    (otherUserProfile['username'] as String? ?? 'U')[0]
                        .toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                    ),
                  )
                : null,
          ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              otherUserProfile['username'] ?? 'Unknown User',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            timeAgo,
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
            ),
          ),
        ],
      ),
      subtitle: Text(
        lastMessage,
        style: TextStyle(
          color: Colors.grey.shade400,
          fontStyle: FontStyle.normal,
          fontWeight: FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (isMobile) {
          // Navigate to chat screen on mobile
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversation.id,
                otherUserId: otherUserId,
              ),
            ),
          );
        } else {
          // Set selected conversation and other user ID for desktop
          setState(() {
            _selectedConversationId = conversation.id;
            _selectedOtherUserId = otherUserId; // Set the other user ID
          });
        }
      },
      tileColor: isSelected ? const Color(0xFF1A1A1A) : null,
    );
  }

  Widget _buildEmptyChatArea() {
    return Container(
      color: const Color(0xFF0A0A0A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet.\nStart the conversation!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Select a conversation from the sidebar.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    return TimeUtils.formatTimeAgoIST(dateTime);
  }
}
