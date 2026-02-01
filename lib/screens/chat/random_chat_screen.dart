import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gamer_flick/providers/chat/random_chat_provider.dart';
import 'package:gamer_flick/models/chat/random_chat.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RandomChatScreen extends StatelessWidget {
  const RandomChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RandomChatProvider(),
      child: const _RandomChatView(),
    );
  }
}

class _RandomChatView extends StatefulWidget {
  const _RandomChatView();
  @override
  State<_RandomChatView> createState() => _RandomChatViewState();
}

class _RandomChatViewState extends State<_RandomChatView> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _lastMessageCount = 0;
  bool _requeuedAfterEnd = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RandomChatProvider>(context);
    // Auto-scroll to bottom on new messages
    if (provider.messages.length != _lastMessageCount) {
      _lastMessageCount = provider.messages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final bool sessionEnded = provider.session?.status == 'ended';

    // Auto-requeue shortly after disconnect
    if (sessionEnded && !_requeuedAfterEnd) {
      _requeuedAfterEnd = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        provider.next();
        _requeuedAfterEnd = false;
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('You and Stranger'),
        actions: [
          if (provider.session != null) ...[
            TextButton(
              onPressed: () => provider.leave(reason: 'stop'),
              child: const Text('Stop', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => provider.next(),
              child: const Text('Next', style: TextStyle(color: Colors.white)),
            ),
          ],
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) => provider.setMode(v),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'text', child: Text('Text mode')),
              PopupMenuItem(
                  value: 'video', child: Text('Video mode (coming soon)')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.error != null)
            Container(
              color: Colors.red.withOpacity(0.1),
              padding: const EdgeInsets.all(8),
              child: Text(provider.error!,
                  style: const TextStyle(color: Colors.red)),
            ),
          // Status banners
          if (provider.isMatching)
            Container(
              width: double.infinity,
              color: Colors.blue.withOpacity(0.06),
              padding: const EdgeInsets.all(8),
              child: const Text('Finding a random stranger...'),
            )
          else if (sessionEnded)
            Container(
              width: double.infinity,
              color: Colors.red.withOpacity(0.08),
              padding: const EdgeInsets.all(8),
              child: const Text(
                'Stranger disconnected. Reconnecting you to a new chat...',
                style: TextStyle(color: Colors.red),
              ),
            )
          else if (provider.session?.status == 'connected')
            Container(
              width: double.infinity,
              color: Colors.green.withOpacity(0.06),
              padding: const EdgeInsets.all(8),
              child: Text(
                provider.interests.isEmpty
                    ? 'You are now connected to a stranger. Say hi!'
                    : 'Connected. Common interests: ${provider.interests.join(', ')}',
                style: const TextStyle(color: Colors.green),
              ),
            ),
          if (provider.session == null)
            Expanded(
              child: Center(
                child: provider.isMatching
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Looking for someone to chat with...'),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              FilterChip(
                                label: const Text('gaming'),
                                selected: provider.interests.contains('gaming'),
                                onSelected: (v) {
                                  final set = provider.interests.toList();
                                  v ? set.add('gaming') : set.remove('gaming');
                                  provider.setInterests(set);
                                },
                              ),
                              FilterChip(
                                label: const Text('esports'),
                                selected:
                                    provider.interests.contains('esports'),
                                onSelected: (v) {
                                  final set = provider.interests.toList();
                                  v
                                      ? set.add('esports')
                                      : set.remove('esports');
                                  provider.setInterests(set);
                                },
                              ),
                              FilterChip(
                                label: const Text('fps'),
                                selected: provider.interests.contains('fps'),
                                onSelected: (v) {
                                  final set = provider.interests.toList();
                                  v ? set.add('fps') : set.remove('fps');
                                  provider.setInterests(set);
                                },
                              ),
                              FilterChip(
                                label: const Text('rpg'),
                                selected: provider.interests.contains('rpg'),
                                onSelected: (v) {
                                  final set = provider.interests.toList();
                                  v ? set.add('rpg') : set.remove('rpg');
                                  provider.setInterests(set);
                                },
                              ),
                            ],
                          ),
                          if (provider.mode == 'spy') ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: 420,
                              child: TextField(
                                decoration: const InputDecoration(
                                  hintText:
                                      'Enter a question for both strangers (spy mode)',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: provider.setQuestion,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () => provider.startMatching(),
                            icon: const Icon(Icons.shuffle),
                            label: const Text('Start'),
                          ),
                        ],
                      ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  final message = provider.messages[index];
                  return _MessageBubble(
                    message: message,
                    isMe: message.senderId == currentUserId,
                  );
                },
              ),
            ),
          if (provider.session != null)
            _Composer(
              controller: _controller,
              onSend: (text) => provider.send(text),
              isTyping: provider.isTyping,
              setTyping: provider.setTyping,
            ),
        ],
      ),
    );
  }

  void _send(RandomChatProvider provider) {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    provider.send(text);
    _controller.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final RandomMessage message;
  final bool isMe;
  const _MessageBubble({required this.message, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.blue.shade50 : Colors.grey.shade200;
    final align = isMe ? Alignment.centerRight : Alignment.centerLeft;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Align(
        alignment: align,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(message.content),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final bool isTyping;
  final ValueChanged<bool> setTyping;

  const _Composer({
    required this.controller,
    required this.onSend,
    required this.isTyping,
    required this.setTyping,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (text) {
                  final t = text.trim();
                  if (t.isEmpty) return;
                  onSend(t);
                  controller.clear();
                  setTyping(false);
                },
                onChanged: (t) => setTyping(t.isNotEmpty),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {
              final t = controller.text.trim();
              if (t.isEmpty) return;
              onSend(t);
              controller.clear();
              setTyping(false);
            },
          ),
        ],
      ),
    );
  }
}
