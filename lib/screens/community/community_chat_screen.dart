import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/community/community_chat_provider.dart';
import 'package:gamer_flick/models/core/user.dart' as app_models;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  final String communityId;
  final String communityName;
  const CommunityChatScreen(
      {super.key, required this.communityId, required this.communityName});

  @override
  ConsumerState<CommunityChatScreen> createState() => _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(communityChatProvider(widget.communityId).notifier).subscribe();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
    final theme = Theme.of(context);
    final chatState = ref.watch(communityChatProvider(widget.communityId));

    return Scaffold(
      appBar: AppBar(title: Text('${widget.communityName} Chat')),
      body: chatState.when(
        data: (messages) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
          
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return FutureBuilder<app_models.User?>(
                      future: _fetchUser(msg.userId),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        final isMe =
                            Supabase.instance.client.auth.currentUser?.id ==
                                msg.userId;
                        String displayName =
                            user?.username ?? user?.displayName ?? 'User';
                        final uuidRegex = RegExp(r'^[0-9a-fA-F-]{36}\$');
                        if (displayName.isEmpty ||
                            uuidRegex.hasMatch(displayName)) {
                          displayName = 'User';
                        }

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? theme.colorScheme.primary.withOpacity(0.15)
                                  : theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundImage:
                                          user?.profilePicture != null
                                              ? CachedNetworkImageProvider(
                                                  user!.profilePicture!)
                                              : null,
                                      child: user?.profilePicture == null
                                          ? const Icon(Icons.person, size: 14)
                                          : null,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      displayName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('h:mm a')
                                          .format(msg.createdAt),
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: theme
                                              .textTheme.bodySmall?.color
                                              ?.withOpacity(0.7)),
                                    ),
                                  ],
                                ),
                                if (msg.message.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(msg.message,
                                      style: theme.textTheme.bodyMedium),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: Stack(
                    children: [
                      Image.file(
                        File(_selectedImage!.path),
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            color: theme.shadowColor.withOpacity(0.5),
                            child: Icon(Icons.close,
                                color: theme.colorScheme.onSurface, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      onPressed: _isUploading ? null : _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed:
                          _isUploading ? null : () => _sendMessage(),
                      child: _isUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Send'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: \\$err')),
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    String? imageUrl;
    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final storageRepo = ref.read(storageRepositoryProvider);
        imageUrl = await storageRepo.uploadCommunityPostImage(
            _selectedImage!, user.id, widget.communityId);
      }
      setState(() {
        _isUploading = false;
        _selectedImage = null;
      });
    }
    if (text.isNotEmpty || imageUrl != null) {
      try {
        await ref.read(communityChatProvider(widget.communityId).notifier)
            .sendMessage(text, imageUrl: imageUrl);
        _controller.clear();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      }
    }
  }
}
